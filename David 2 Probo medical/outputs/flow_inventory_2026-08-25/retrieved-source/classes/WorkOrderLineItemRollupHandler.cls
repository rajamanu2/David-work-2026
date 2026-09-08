public with sharing class WorkOrderLineItemRollupHandler {

    // Work Order record type gating (kept as-is)
    private static final String FSL_WO_RECORDTYPE_DEVNAME = 'FSL_Work_Order';

    // Field set API names on WorkOrderLineItem
    private static final String FS_LABOR_TRAVEL = 'FSL_Labor_Travel_Table';
    private static final String FS_PARTS_PROBE  = 'FSL_Parts_Probe_Table';

    private static Id fslWorkOrderRtIdCache;
    private static List<Schema.FieldSetMember> laborTravelFsCache;
    private static List<Schema.FieldSetMember> partsProbeFsCache;

    // Currency symbol cache
    private static Map<String, String> currencySymbolByIsoCache = new Map<String, String>();

    // Shared table styling
    private static final String HEADER_CELL_STYLE = 'background-color:#e0e0e0; font-weight:bold;';
    private static final String ALT_ROW_STYLE = 'background-color:#f3f3f3;';

    public static void rebuildWorkOrderTables(
        List<WorkOrderLineItem> triggerRows,
        Map<Id, WorkOrderLineItem> triggerMap,
        Map<Id, WorkOrderLineItem> oldMapForUpdate,
        System.TriggerOperation op
    ) {
        Set<Id> candidateWoIds = collectCandidateWorkOrderIds(triggerRows, triggerMap, oldMapForUpdate, op);
        rebuildWorkOrderTablesByWorkOrderIds(candidateWoIds);
    }

    public static void enqueueRebuildWorkOrderTables(
        List<WorkOrderLineItem> triggerRows,
        Map<Id, WorkOrderLineItem> triggerMap,
        Map<Id, WorkOrderLineItem> oldMapForUpdate,
        System.TriggerOperation op
    ) {
        Set<Id> candidateWoIds = collectCandidateWorkOrderIds(triggerRows, triggerMap, oldMapForUpdate, op);
        if (candidateWoIds.isEmpty()) return;

        // Async cannot enqueue async; when already async, run inline.
        if (System.isFuture() || System.isBatch() || System.isQueueable()) {
            rebuildWorkOrderTablesByWorkOrderIds(candidateWoIds);
            return;
        }

        rebuildWorkOrderTablesAsync(new List<Id>(candidateWoIds));
    }


    @future
    public static void rebuildWorkOrderTablesAsync(List<Id> workOrderIds) {
        if (workOrderIds == null || workOrderIds.isEmpty()) return;
        rebuildWorkOrderTablesByWorkOrderIds(new Set<Id>(workOrderIds));
    }

    public static void rebuildWorkOrderTablesByWorkOrderIds(Set<Id> candidateWoIds) {
        if (candidateWoIds.isEmpty()) return;

        // --- Filter to ONLY FSL Work Orders ---
        Id fslRtId = getFslWorkOrderRecordTypeId();
        if (fslRtId == null) return;

        // Include CurrencyIsoCode so we can render correct currency symbol for rollups
        List<WorkOrder> fslWorkOrders = [
            SELECT Id, CurrencyIsoCode, Labor_Travel_Table__c, Parts_Probe_Table__c
            FROM WorkOrder
            WHERE Id IN :candidateWoIds
              AND RecordTypeId = :fslRtId
        ];
        if (fslWorkOrders.isEmpty()) return;

        Set<Id> fslWoIds = new Set<Id>();
        Map<Id, String> woCurrencyById = new Map<Id, String>();
        for (WorkOrder wo : fslWorkOrders) {
            fslWoIds.add(wo.Id);
            woCurrencyById.put(wo.Id, wo.CurrencyIsoCode);
        }
        
        // --- Visits (Service Appointments) per Work Order ---
        Map<Id, List<ServiceAppointment>> saByWo = new Map<Id, List<ServiceAppointment>>();
        
        for (ServiceAppointment sa : [
            SELECT Id, Work_Order__c, ParentRecordId, AppointmentNumber, Subject,
                   ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            WHERE (Work_Order__c IN :fslWoIds OR ParentRecordId IN :fslWoIds)
            ORDER BY ActualStartTime ASC
        ]) {
            Id woId = (sa.Work_Order__c != null) ? sa.Work_Order__c : sa.ParentRecordId;
            if (woId == null) continue;
        
            if (!saByWo.containsKey(woId)) saByWo.put(woId, new List<ServiceAppointment>());
            saByWo.get(woId).add(sa);
}


        // Pull field sets (order preserved)
        List<Schema.FieldSetMember> laborFs = getFieldSetMembersCached(true);
        List<Schema.FieldSetMember> partsFs = getFieldSetMembersCached(false);

        // --- Labor/Travel rollups + Parts/Probe detail rows ---
        Map<Id, Decimal> laborQty = new Map<Id, Decimal>();
        Map<Id, Decimal> laborAmt = new Map<Id, Decimal>();
        Map<Id, Decimal> travelQty = new Map<Id, Decimal>();
        Map<Id, Decimal> travelAmt = new Map<Id, Decimal>();
        Map<Id, List<WorkOrderLineItem>> nonLtByWo = new Map<Id, List<WorkOrderLineItem>>();

        // Ensure we can read fields needed for rendering + Labor/Travel classification
        String woliSelect = buildSelectClause(
            partsFs,
            new List<String>{
                'Id',
                'WorkOrderId',
                'CurrencyIsoCode',
                'Quantity',
                'TotalPrice',
                'Type_Intent__c',
                'Line_Type__c',
                'Line_Intent__c'
            }
        );
        String woliSoql =
            'SELECT ' + woliSelect +
            ' FROM WorkOrderLineItem' +
            ' WHERE WorkOrderId IN :fslWoIds' +
            ' AND (Line_Intent__c = NULL OR Line_Intent__c NOT IN (\'Unused\', \'DOA\', \'Repair Canceled\'))' +
            ' AND (Line_Type__c != \'Part Return\' OR Line_Intent__c = \'Exchange\')' +
            ' ORDER BY CreatedDate ASC';

        for (WorkOrderLineItem w : Database.query(woliSoql)) {
            String lineType = getLaborTravelType(w);
            if (lineType == 'Labor' || lineType == 'Travel') {
                Decimal qty = (Decimal) w.get('Quantity');
                Decimal amt = (Decimal) w.get('TotalPrice');
                qty = (qty == null) ? 0 : qty;
                amt = (amt == null) ? 0 : amt;

                if (lineType == 'Labor') {
                    laborQty.put(w.WorkOrderId, (laborQty.containsKey(w.WorkOrderId) ? laborQty.get(w.WorkOrderId) : 0) + qty);
                    laborAmt.put(w.WorkOrderId, (laborAmt.containsKey(w.WorkOrderId) ? laborAmt.get(w.WorkOrderId) : 0) + amt);
                } else {
                    travelQty.put(w.WorkOrderId, (travelQty.containsKey(w.WorkOrderId) ? travelQty.get(w.WorkOrderId) : 0) + qty);
                    travelAmt.put(w.WorkOrderId, (travelAmt.containsKey(w.WorkOrderId) ? travelAmt.get(w.WorkOrderId) : 0) + amt);
                }
            } else {
                if (!nonLtByWo.containsKey(w.WorkOrderId)) {
                    nonLtByWo.put(w.WorkOrderId, new List<WorkOrderLineItem>());
                }
                nonLtByWo.get(w.WorkOrderId).add(w);
            }
        }

        // --- Apply updates ---
        List<WorkOrder> updates = new List<WorkOrder>();

        for (WorkOrder wo : fslWorkOrders) {
            Decimal lq = laborQty.containsKey(wo.Id) ? laborQty.get(wo.Id) : 0;
            Decimal la = laborAmt.containsKey(wo.Id) ? laborAmt.get(wo.Id) : 0;
            Decimal tq = travelQty.containsKey(wo.Id) ? travelQty.get(wo.Id) : 0;
            Decimal ta = travelAmt.containsKey(wo.Id) ? travelAmt.get(wo.Id) : 0;

            Decimal lRate = (lq != 0) ? (la / lq) : 0;
            Decimal tRate = (tq != 0) ? (ta / tq) : 0;

            String woIso = woCurrencyById.get(wo.Id);

            List<ServiceAppointment> visits = saByWo.containsKey(wo.Id) ? saByWo.get(wo.Id) : new List<ServiceAppointment>();
            
            String laborTravelHtml = buildLaborTravelWithVisitsHtml(
                laborFs,
                woIso,
                visits,
                lq, la, lRate,
                tq, ta, tRate
            );


            List<WorkOrderLineItem> nonLtLines =
                nonLtByWo.containsKey(wo.Id) ? nonLtByWo.get(wo.Id) : new List<WorkOrderLineItem>();

            String partsProbeHtml = buildDetailHtmlFromFieldSet(partsFs, nonLtLines);

            Boolean changed = false;
            WorkOrder woUpdate = new WorkOrder(Id = wo.Id);

            if (wo.Labor_Travel_Table__c != laborTravelHtml) {
                woUpdate.Labor_Travel_Table__c = laborTravelHtml;
                changed = true;
            }
            if (wo.Parts_Probe_Table__c != partsProbeHtml) {
                woUpdate.Parts_Probe_Table__c = partsProbeHtml;
                changed = true;
            }

            if (changed) updates.add(woUpdate);
        }

        if (!updates.isEmpty()) update updates;
    }

    private static Set<Id> collectCandidateWorkOrderIds(
        List<WorkOrderLineItem> triggerRows,
        Map<Id, WorkOrderLineItem> triggerMap,
        Map<Id, WorkOrderLineItem> oldMapForUpdate,
        System.TriggerOperation op
    ) {
        Set<Id> candidateWoIds = new Set<Id>();

        if (triggerRows != null) {
            for (WorkOrderLineItem row : triggerRows) {
                if (row != null && row.WorkOrderId != null) candidateWoIds.add(row.WorkOrderId);
            }
        }

        if (op == System.TriggerOperation.AFTER_UPDATE && oldMapForUpdate != null && triggerMap != null) {
            for (Id rowId : triggerMap.keySet()) {
                WorkOrderLineItem oldRow = oldMapForUpdate.get(rowId);
                if (oldRow != null && oldRow.WorkOrderId != null) candidateWoIds.add(oldRow.WorkOrderId);
            }
        }

        return candidateWoIds;
    }

    // -------------------------
    // Record Type Helper (SOQL cached)
    // -------------------------
    private static Id getFslWorkOrderRecordTypeId() {
        if (fslWorkOrderRtIdCache != null) return fslWorkOrderRtIdCache;

        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'WorkOrder'
              AND DeveloperName = :FSL_WO_RECORDTYPE_DEVNAME
            LIMIT 1
        ];
        fslWorkOrderRtIdCache = (rts.isEmpty()) ? null : rts[0].Id;
        return fslWorkOrderRtIdCache;
    }

    // -------------------------
    // Field Set Helpers
    // -------------------------
    private static List<Schema.FieldSetMember> getFieldSetMembersCached(Boolean laborTravel) {
        if (laborTravel) {
            if (laborTravelFsCache != null) return laborTravelFsCache;
            laborTravelFsCache = getFieldSetMembers(FS_LABOR_TRAVEL);
            return laborTravelFsCache;
        } else {
            if (partsProbeFsCache != null) return partsProbeFsCache;
            partsProbeFsCache = getFieldSetMembers(FS_PARTS_PROBE);
            return partsProbeFsCache;
        }
    }
    
    private static String buildLaborTravelWithVisitsHtml(
        List<Schema.FieldSetMember> laborCols,
        String currencyIsoCode,
        List<ServiceAppointment> visits,
        Decimal laborQty, Decimal laborAmt, Decimal laborRate,
        Decimal travelQty, Decimal travelAmt, Decimal travelRate
        ) {
            if (laborCols == null) laborCols = new List<Schema.FieldSetMember>();
            if (visits == null) visits = new List<ServiceAppointment>();
        
            String visitsHtml = buildVisitsTableHtml(visits);
        
            // Only consider Labor/Travel as "has values" if there is anything to show
            Boolean hasLaborTravelValues =
                (laborQty != null && laborQty != 0) ||
                (travelQty != null && travelQty != 0) ||
                (laborAmt != null && laborAmt != 0) ||
                (travelAmt != null && travelAmt != 0);
        
            String laborTravelHtml = buildLaborTravelHtmlFromFieldSet_HeaderOnlyWhenEmpty(
                laborCols,
                currencyIsoCode,
                hasLaborTravelValues,
                laborQty, laborAmt, laborRate,
                travelQty, travelAmt, travelRate
            );
        
            // Put visits table above labor/travel table
            // Both methods will render headers even if no rows; so just concatenate.
            return visitsHtml + '<br/>' + laborTravelHtml;
        }

  private static String buildVisitsTableHtml(List<ServiceAppointment> visits) {
        if (visits == null) visits = new List<ServiceAppointment>();
    
        String html =
            '<table style="width:100%; border-collapse:collapse;" border="1" cellpadding="6">' +
                '<thead><tr>' +
                    '<th align="left" style="' + HEADER_CELL_STYLE + '">Visit</th>' +
                    '<th align="left" style="' + HEADER_CELL_STYLE + '">Start</th>' +
                    '<th align="left" style="' + HEADER_CELL_STYLE + '">End</th>' +
                '</tr></thead>' +
                '<tbody>';
    
        // Only render rows if there are values
        if (!visits.isEmpty()) {
            Integer rowIndex = 0;
            for (ServiceAppointment sa : visits) {
                String label = !String.isBlank(sa.AppointmentNumber) ? sa.AppointmentNumber : (!String.isBlank(sa.Subject) ? sa.Subject : 'Visit');
                html +=
                    '<tr' + rowStyleAttr(rowIndex) + '>' +
                        '<td>' + esc(label) + '</td>' +
                        '<td>' + esc(formatDateTime(sa.ActualStartTime)) + '</td>' +
                        '<td>' + esc(formatDateTime(sa.ActualEndTime)) + '</td>' +
                    '</tr>';
                rowIndex++;
            }
        }
    
        html += '</tbody></table>';
        return html;
    }

    private static String formatDateTime(Datetime dt) {
        if (dt == null) return '';
        // Example format; adjust if you prefer a different display
        // Uses running user's locale/timezone
        return dt.format('M/d/yyyy h:mm a');
    }


    private static List<Schema.FieldSetMember> getFieldSetMembers(String fieldSetName) {
        Map<String, Schema.FieldSet> fsMap = Schema.SObjectType.WorkOrderLineItem.FieldSets.getMap();
        Schema.FieldSet fs = (fsMap == null) ? null : fsMap.get(fieldSetName);
        return (fs == null) ? new List<Schema.FieldSetMember>() : fs.getFields();
    }


    private static String getColumnHeaderLabel(Schema.FieldSetMember member) {
        if (member == null) return '';

        String fieldPath = member.getFieldPath();
        String memberLabel = member.getLabel();
        if (
            fieldPath == 'Type_Intent__c' ||
            memberLabel == 'Status' ||
            memberLabel == 'Status & Type'
        ) {
            return 'Status & Type';
        }

        return memberLabel;
    }

    private static String buildSelectClause(List<Schema.FieldSetMember> members, List<String> alwaysInclude) {
        Set<String> seen = new Set<String>();
        List<String> fields = new List<String>();

        for (String f : alwaysInclude) {
            if (!String.isBlank(f) && !seen.contains(f)) {
                seen.add(f);
                fields.add(f);
            }
        }

        for (Schema.FieldSetMember m : members) {
            if (m == null) continue;
            String path = m.getFieldPath();
            if (String.isBlank(path)) continue;
            if (!seen.contains(path)) {
                seen.add(path);
                fields.add(path);
            }
        }

        return String.join(fields, ', ');
    }

    // -------------------------
    // HTML Builders
    // -------------------------

    // Labor/Travel = two “virtual” rows; columns entirely driven by field set order.
    private static String buildLaborTravelHtmlFromFieldSet_HeaderOnlyWhenEmpty(
        List<Schema.FieldSetMember> cols,
        String currencyIsoCode,
        Boolean hasValues,
        Decimal laborQty, Decimal laborAmt, Decimal laborRate,
        Decimal travelQty, Decimal travelAmt, Decimal travelRate
    ) {
        if (cols == null) cols = new List<Schema.FieldSetMember>();
    
        String html =
            '<table style="width:100%; border-collapse:collapse;" border="1" cellpadding="6">' +
                '<thead><tr>';
    
        for (Schema.FieldSetMember c : cols) {
            html += '<th align="left" style="' + HEADER_CELL_STYLE + '">' + esc(getColumnHeaderLabel(c)) + '</th>';
        }
    
        html += '</tr></thead><tbody>';
    
        // Only render rows if there are values
        if (hasValues) {
            // Row 1: Labor
            html += '<tr' + rowStyleAttr(0) + '>';
            for (Schema.FieldSetMember c : cols) {
                String path = c.getFieldPath();
                Object val = getLaborTravelValueForField(path, 'Labor', laborQty, laborAmt, laborRate);
                html += '<td>' + esc(formatForDisplay(path, val, currencyIsoCode)) + '</td>';
            }
            html += '</tr>';
    
            // Row 2: Travel
            html += '<tr' + rowStyleAttr(1) + '>';
            for (Schema.FieldSetMember c : cols) {
                String path = c.getFieldPath();
                Object val = getLaborTravelValueForField(path, 'Travel', travelQty, travelAmt, travelRate);
                html += '<td>' + esc(formatForDisplay(path, val, currencyIsoCode)) + '</td>';
            }
            html += '</tr>';
        }
    
        html += '</tbody></table>';
        return html;
    }


    // Parts/Probe = detail rows from actual WOLIs; columns driven by field set order.
    private static String buildDetailHtmlFromFieldSet(List<Schema.FieldSetMember> cols, List<WorkOrderLineItem> rows) {
        if (cols == null) cols = new List<Schema.FieldSetMember>();
        if (rows == null) rows = new List<WorkOrderLineItem>();

        Integer colCount = cols.size();
        if (colCount == 0) {
            return '<table border="1" cellpadding="6" style="width:100%; border-collapse:collapse;">' +
                   '<tbody><tr><td style="font-style:italic;">No fields configured in field set.</td></tr></tbody></table>';
        }

        String html =
            '<table style="width:100%; border-collapse:collapse;" border="1" cellpadding="6">' +
                '<thead><tr>';

        for (Schema.FieldSetMember c : cols) {
            html += '<th align="left" style="' + HEADER_CELL_STYLE + '">' + esc(getColumnHeaderLabel(c)) + '</th>';
        }

        html += '</tr></thead><tbody>';

        if (rows.isEmpty()) {
            html += '<tr><td colspan="' + String.valueOf(colCount) + '" style="font-style:italic;">No rows found.</td></tr>';
        } else {
            Integer rowIndex = 0;
            for (WorkOrderLineItem r : rows) {
                String iso = (String) r.get('CurrencyIsoCode');
                html += '<tr' + rowStyleAttr(rowIndex) + '>';
                for (Schema.FieldSetMember c : cols) {
                    String path = c.getFieldPath();
                    Object rawVal = getValueByPath(r, path);
                    html += '<td>' + esc(formatForDisplay(path, rawVal, iso)) + '</td>';
                }
                html += '</tr>';
                rowIndex++;
            }
        }

        html += '</tbody></table>';
        return html;
    }

    // -------------------------
    // Value helpers
    // -------------------------
    private static Object getLaborTravelValueForField(String fieldPath, String lineType, Decimal qty, Decimal total, Decimal rate) {
        if (String.isBlank(fieldPath)) return null;

        if (fieldPath == 'Type_Intent__c') return lineType;
        if (fieldPath == 'Line_Type__c') return lineType;
        if (fieldPath == 'Quantity') return qty;
        if (fieldPath == 'TotalPrice') return total;

        // If field set includes UnitPrice or a custom "rate" field, populate with computed rate
        if (fieldPath == 'UnitPrice') return rate;
        if (fieldPath == 'Price_Per_Hour__c' || fieldPath == 'Price_Per_Hour') return rate;

        return null;
    }

    private static String getLaborTravelType(WorkOrderLineItem row) {
        if (row == null) return null;

        String normalizedTypeIntent = normalizeLaborTravelToken((String) row.get('Type_Intent__c'));
        if (normalizedTypeIntent != null) return normalizedTypeIntent;

        String normalizedLineType = normalizeLaborTravelToken((String) row.get('Line_Type__c'));
        if (normalizedLineType != null) return normalizedLineType;

        return null;
    }

    private static String normalizeLaborTravelToken(String value) {
        if (String.isBlank(value)) return null;

        String normalized = value.trim().toLowerCase();
        if (normalized == 'labor') return 'Labor';
        if (normalized == 'travel') return 'Travel';

        return null;
    }

    private static Object getValueByPath(SObject sobj, String fieldPath) {
        if (sobj == null || String.isBlank(fieldPath)) return null;

        // Always source the status/type display value from Type_Intent__c
        // even when a legacy field-set column path is still present.
        if (fieldPath == 'Line_Type__c') {
            return sobj.get('Type_Intent__c');
        }

        if (!fieldPath.contains('.')) {
            return sobj.get(fieldPath);
        }

        List<String> parts = fieldPath.split('\\.');
        SObject cur = sobj;

        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (cur == null) return null;
            cur = cur.getSObject(parts[i]);
        }

        if (cur == null) return null;
        return cur.get(parts[parts.size() - 1]);
    }

    // -------------------------
    // Currency + formatting
    // -------------------------
    private static String formatForDisplay(String fieldPath, Object rawVal, String currencyIsoCode) {
        if (rawVal == null) return '';

        // Only attempt describe for direct fields on WorkOrderLineItem
        if (fieldPath != null && !fieldPath.contains('.')) {
            Schema.SObjectField sf = Schema.SObjectType.WorkOrderLineItem.fields.getMap().get(fieldPath);
            if (sf != null) {
                Schema.DescribeFieldResult d = sf.getDescribe();
                Schema.DisplayType t = d.getType();

                if (t == Schema.DisplayType.Currency) {
                    Decimal dv;
                    try { dv = (Decimal) rawVal; } catch (Exception e) { return String.valueOf(rawVal); }
                    String symbol = getCurrencySymbolOrIsoPrefix(currencyIsoCode);
                    return symbol + String.valueOf(dv.setScale(2));
                }

                if (t == Schema.DisplayType.Double || t == Schema.DisplayType.Percent) {
                    Decimal dv;
                    try { dv = (Decimal) rawVal; } catch (Exception e) { return String.valueOf(rawVal); }
                    return String.valueOf(dv.setScale(2));
                }

                if (t == Schema.DisplayType.Integer) return String.valueOf(rawVal);
                if (t == Schema.DisplayType.Date) return String.valueOf((Date) rawVal);
                if (t == Schema.DisplayType.Datetime) return String.valueOf((Datetime) rawVal);
                if (t == Schema.DisplayType.Boolean) return ((Boolean) rawVal) ? 'Yes' : 'No';
            }
        }

        return String.valueOf(rawVal);
    }

    private static String getCurrencySymbolOrIsoPrefix(String isoCode) {
        if (String.isBlank(isoCode)) isoCode = UserInfo.getDefaultCurrency();
        if (String.isBlank(isoCode)) return '$'; // final fallback
    
        // Cache lookup
        if (currencySymbolByIsoCache.containsKey(isoCode)) {
            return currencySymbolByIsoCache.get(isoCode);
        }
    
        // Minimal ISO -> Symbol map (extend as needed)
        Map<String, String> mapIsoToSymbol = new Map<String, String>{
            'USD' => '$',
            'CAD' => '$',
            'AUD' => '$',
            'NZD' => '$',
            'EUR' => '€',
            'GBP' => '£',
            'JPY' => '¥',
            'CNY' => '¥',
            'RMB' => '¥',
            'INR' => '₹',
            'KRW' => '₩',
            'BRL' => 'R$',
            'MXN' => '$',
            'CHF' => 'CHF ',
            'SEK' => 'kr ',
            'NOK' => 'kr ',
            'DKK' => 'kr ',
            'PLN' => 'zł ',
            'ZAR' => 'R ',
            'SGD' => '$',
            'HKD' => '$'
        };
    
        String prefix = mapIsoToSymbol.containsKey(isoCode)
            ? mapIsoToSymbol.get(isoCode)
            : (isoCode + ' '); // if unknown, show ISO code as prefix
    
        currencySymbolByIsoCache.put(isoCode, prefix);
        return prefix;
    }


    // -------------------------
    // Escaping
    // -------------------------
    private static String esc(String s) {
        if (String.isBlank(s)) return '';
        String out = s;
        out = out.replace('&', '&amp;');
        out = out.replace('<', '&lt;');
        out = out.replace('>', '&gt;');
        out = out.replace('"', '&quot;');
        out = out.replace('\'', '&#39;');
        return out;
    }

    private static String rowStyleAttr(Integer rowIndex) {
        if (rowIndex == null || Math.mod(rowIndex, 2) == 0) return '';
        return ' style="' + ALT_ROW_STYLE + '"';
    }
}