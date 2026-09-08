public with sharing class FslTechnicianOnlineController {

    private static Id resolveWorkOrderId(ServiceAppointment sa) {
        if (sa == null) {
            return null;
        }

        if (sa.Work_Order__c != null) {
            return sa.Work_Order__c;
        }

        if (sa.ParentRecordId != null &&
            String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
            return sa.ParentRecordId;
        }

        return null;
    }

    // DTOs
    public class AppointmentDTO {
        @AuraEnabled public Id appointmentId;
        @AuraEnabled public String workTypeName;
        @AuraEnabled public String workOrderSubject;
        @AuraEnabled public String systemSerialNumber;
        @AuraEnabled public String serviceSiteName;
        @AuraEnabled public String lineItemSystem;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountNameFreeText;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String poNumber;
        @AuraEnabled public String contactName;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public Datetime schedStart;
        @AuraEnabled public Datetime schedEnd;
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String workOrderStatus;
        @AuraEnabled public Boolean waitingForPoNumber;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public Datetime workOrderCreatedDate;
        @AuraEnabled public Id workOrderCreatedById;
        @AuraEnabled public Datetime workOrderLastModifiedDate;
        @AuraEnabled public Id workOrderLastModifiedById;
        @AuraEnabled public Datetime serviceAppointmentLastModifiedDate;
        @AuraEnabled public Id serviceAppointmentLastModifiedById;
        @AuraEnabled public String serviceAppointmentTrackingNumber;
        @AuraEnabled public String latestServiceAppointmentTrackingNumber;
        @AuraEnabled public String workOrderTrackingNumber;
        @AuraEnabled public String opportunityTrackingNumber;
        @AuraEnabled public String billingType;
        @AuraEnabled public String opportunityNumber;
        @AuraEnabled public Integer completedVisitCount;
        @AuraEnabled public Integer serviceAppointmentCount;
        @AuraEnabled public Integer unscheduledServiceAppointmentCount;
        @AuraEnabled public List<Datetime> visitScheduleDates;
        @AuraEnabled public List<Id> visitAppointmentIds;

        @AuraEnabled public String reporterContactInfo;
        @AuraEnabled public String makeModel;
        @AuraEnabled public String description;
        @AuraEnabled public String workOrderDescription;

        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String shippingAttn;
        @AuraEnabled public String shippingSiteName;
        @AuraEnabled public String shippingStreet;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingPostalCode;
        @AuraEnabled public String shippingCountry;

        @AuraEnabled public Boolean isMyAssignment;
        @AuraEnabled public Boolean isCrewAssignment;
        @AuraEnabled public Boolean allPartsEnRoute;
        @AuraEnabled public Boolean somePartsEnRoute;
        @AuraEnabled public Boolean hasQuoteAttachment;
        @AuraEnabled public Boolean latestReturnVisitRequired;
        @AuraEnabled public String quoteAttachmentDownloadUrl;
        @AuraEnabled public Id quoteAttachmentDocumentId;
        @AuraEnabled public String opportunityRecordType;
        @AuraEnabled public String opportunityStage;
        @AuraEnabled public Date dateProbeReceivedForRepairEval;
        @AuraEnabled public Date dateQuoteSentToCustomer;
        @AuraEnabled public Date nextServiceDate;
        @AuraEnabled public String loanerTrackingNumber;
        @AuraEnabled public List<QuoteLineItemDTO> quoteLineItems;
        @AuraEnabled public String trackingNumber;

        @AuraEnabled public Id serviceCrewId;
        @AuraEnabled public List<CrewMemberDTO> crewMembers;
    }

    public class QuoteLineItemDTO {
        @AuraEnabled public Id lineItemId;
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String productName;
        @AuraEnabled public String description;
        @AuraEnabled public String trackingNumber;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public String lineType;
    }

    public class CrewMemberDTO {
        @AuraEnabled public Id serviceResourceId;
        @AuraEnabled public String name;
    }

    public class ServiceResourceOption {
        @AuraEnabled public Id serviceResourceId;
        @AuraEnabled public String name;
        @AuraEnabled public Id userId;
    }

    public class AddressUpdateResult {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public Id serviceAppointmentId;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String shippingAttn;
        @AuraEnabled public String shippingSiteName;
        @AuraEnabled public String shippingStreet;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingPostalCode;
        @AuraEnabled public String shippingCountry;
        @AuraEnabled public String fullAddress;
    }

    public class AddressBookEntry {
        @AuraEnabled public Id addressId;
        @AuraEnabled public Id locationId;
        @AuraEnabled public String name;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String stateCode;
        @AuraEnabled public String country;
        @AuraEnabled public String countryCode;
        @AuraEnabled public String postalCode;
    }

    public class AccountNameUpdateResult {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String accountNameFreeText;
    }

    public class ReporterContactUpdateResult {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String reporterContactInfo;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
    }

    public class PoNumberUpdateResult {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String poNumber;
    }

    public class ResourceAbsenceDTO {
        @AuraEnabled public Id absenceId;
        @AuraEnabled public Id resourceId;
        @AuraEnabled public Datetime start;
        @AuraEnabled public Datetime endTime;
        @AuraEnabled public String description;
        @AuraEnabled public String type;
    }

    // Unscheduled Work Orders for tray
    public class UnscheduledWorkOrderDTO {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean waitingForPoNumber;
        @AuraEnabled public String workTypeName;
        @AuraEnabled public String systemSerialNumber;
        @AuraEnabled public String serviceSiteName;
        @AuraEnabled public String lineItemSystem;
        @AuraEnabled public String poNumber;
        @AuraEnabled public Datetime workOrderCreatedDate;
        @AuraEnabled public Id workOrderCreatedById;
        @AuraEnabled public Datetime workOrderLastModifiedDate;
        @AuraEnabled public Id workOrderLastModifiedById;
        @AuraEnabled public Integer serviceAppointmentCount;
        @AuraEnabled public Integer unscheduledServiceAppointmentCount;
        @AuraEnabled public Integer completedVisitCount;
        @AuraEnabled public List<Datetime> visitScheduleDates;
        @AuraEnabled public List<Id> visitAppointmentIds;
        @AuraEnabled public Boolean allServiceAppointmentsReturnRequired;
        @AuraEnabled public Boolean hasUnscheduledNonReturnAppointment;
        @AuraEnabled public Boolean hasAnyReturnVisitRequired;
        @AuraEnabled public Boolean needsReturnVisitScheduling;
        @AuraEnabled public Boolean hasCrewAssignment;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountNameFreeText;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String opportunityRecordType;
        @AuraEnabled public Boolean hasQuoteAttachment;
        @AuraEnabled public String quoteAttachmentDownloadUrl;
        @AuraEnabled public Id quoteAttachmentDocumentId;
        @AuraEnabled public String makeModel;
        @AuraEnabled public String reporterContactInfo;
        @AuraEnabled public String description;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public List<QuoteLineItemDTO> quoteLineItems;
        @AuraEnabled public String latestServiceAppointmentTrackingNumber;
        @AuraEnabled public String workOrderTrackingNumber;
        @AuraEnabled public String opportunityTrackingNumber;
        @AuraEnabled public String billingType;
        @AuraEnabled public String opportunityNumber;
        @AuraEnabled public String opportunityStage;
        @AuraEnabled public Date dateProbeReceivedForRepairEval;
        @AuraEnabled public Date dateQuoteSentToCustomer;
        @AuraEnabled public String shippingAttn;
        @AuraEnabled public String shippingSiteName;
        @AuraEnabled public String shippingStreet;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingPostalCode;
        @AuraEnabled public String shippingCountry;
        @AuraEnabled public Date nextServiceDate;
        @AuraEnabled public String loanerTrackingNumber;
    }

    public class TransferRequestDTO {
        @AuraEnabled public Id transferRequestId;
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public String workOrderSubject;
        @AuraEnabled public String accountName;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String requestedByName;
        @AuraEnabled public String targetName;
        @AuraEnabled public Datetime acceptedOn;
        @AuraEnabled public Datetime rejectedOn;
        @AuraEnabled public String rejectionReason;
    }

    public class DebugInfo {
        @AuraEnabled public Id currentUserId;
        @AuraEnabled public List<Id> serviceResourceIds;
        @AuraEnabled public List<Id> absenceResourceIds;
        @AuraEnabled public List<Id> assignedResourceIds;
        @AuraEnabled public List<Id> serviceAppointmentIds;
        @AuraEnabled public List<Id> serviceCrewIds;
        @AuraEnabled public List<Id> workOrderIds;
        @AuraEnabled public Integer length;
        @AuraEnabled public Integer absenceCount;
        @AuraEnabled public String note;
    }

    public class AppointmentResult {
        @AuraEnabled public List<AppointmentDTO> appointments;
        @AuraEnabled public List<UnscheduledWorkOrderDTO> unscheduledWorkOrders;
        @AuraEnabled public List<TransferRequestDTO> transferRequests;
        @AuraEnabled public List<TransferRequestDTO> submittedTransferRequests;
        @AuraEnabled public List<ResourceAbsenceDTO> absences;
        @AuraEnabled public List<HistoryItemDTO> historyItems;
        @AuraEnabled public DebugInfo debug;
        @AuraEnabled public String userTimeZoneId;
        @AuraEnabled public Boolean isManager;
        @AuraEnabled public List<UserPickerOption> teamMembers;
        @AuraEnabled public Id viewingUserId;
    }

    public class UserPickerOption {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
    }

    public class HistoryItemDTO {
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String workTypeName;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id relatedWorkOrderId;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public String systemSerialNumber;
        @AuraEnabled public String workOrderSubject;
        @AuraEnabled public String workOrderStatus;
        @AuraEnabled public String opportunityNumber;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String opportunityStage;
        @AuraEnabled public String opportunityRecordType;
        @AuraEnabled public Datetime opportunityCreatedDate;
        @AuraEnabled public String relatedWorkOrderNumber;
        @AuraEnabled public String relatedWorkOrderSubject;
        @AuraEnabled public String relatedWorkOrderStatus;
        @AuraEnabled public String relatedWorkOrderTrackingNumber;
        @AuraEnabled public String relatedWorkOrderSystemSerialNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountNameFreeText;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String trackingNumber;
        @AuraEnabled public Datetime lastModifiedDate;
    }

    public class LineItemForReturnDTO {
        @AuraEnabled public Id lineItemId;
        @AuraEnabled public String partName;
        @AuraEnabled public String serialNumber;
    }

    public class DeletedWoliDTO {
        @AuraEnabled public Id lineItemId;
        @AuraEnabled public String partName;
        @AuraEnabled public String partNumber;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String lineType;
        @AuraEnabled public String serialNumber;
    }


    @AuraEnabled
    public static AppointmentResult getMyAppointmentsOnline(
        Id targetUserId,
        Boolean includeHistory
    ) {
        return getMyAppointmentsOnlineScoped(targetUserId, includeHistory, null);
    }

    @AuraEnabled
    public static AppointmentResult getMyAppointmentsOnlineScoped(
        Id targetUserId,
        Boolean includeHistory,
        String dataScope
    ) {
        AppointmentResult wrapper  = new AppointmentResult();
        DebugInfo dbg              = new DebugInfo();
        wrapper.debug              = dbg;

        Id effectiveUserId = (targetUserId != null)
            ? targetUserId
            : UserInfo.getUserId();
        Set<Id> srLookupIds = new Set<Id>();
        if (effectiveUserId != null) {
            srLookupIds.add(effectiveUserId);
        }
        Id viewerUserId = UserInfo.getUserId();

        wrapper.userTimeZoneId     = UserInfo.getTimeZone().getID();

        dbg.currentUserId          = UserInfo.getUserId();
        dbg.serviceResourceIds     = new List<Id>();
        dbg.absenceResourceIds     = new List<Id>();
        dbg.assignedResourceIds    = new List<Id>();
        dbg.serviceAppointmentIds  = new List<Id>();
        dbg.serviceCrewIds         = new List<Id>();
        dbg.workOrderIds           = new List<Id>();
        dbg.note                   = '';
        dbg.absenceCount           = 0;

        wrapper.teamMembers = new List<UserPickerOption>();

        for (User u : [
            SELECT Id, Name
            FROM User
            WHERE ManagerId = :UserInfo.getUserId()
            ORDER BY Name
        ]) {
            UserPickerOption opt = new UserPickerOption();
            opt.userId = u.Id;
            opt.name   = u.Name;
            wrapper.teamMembers.add(opt);
        }

        wrapper.isManager = !wrapper.teamMembers.isEmpty();
        wrapper.viewingUserId = effectiveUserId;

        // 1) ServiceResource for this user
        List<ServiceResource> srs = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId IN :srLookupIds
               OR Id IN :srLookupIds
        ];

        for (ServiceResource sr : srs) {
            dbg.serviceResourceIds.add(sr.Id);
        }

        if (srs.isEmpty()) {
            dbg.note   = 'No ServiceResource found for user.';
            wrapper.appointments = new List<AppointmentDTO>();
            wrapper.unscheduledWorkOrders = new List<UnscheduledWorkOrderDTO>();
            wrapper.absences = new List<ResourceAbsenceDTO>();
            wrapper.historyItems = (includeHistory == true)
                ? buildHistoryItems(effectiveUserId)
                : new List<HistoryItemDTO>();
            List<Engineer_Transfer_Request__c> pendingRequests =
                getPendingTransferRequests(effectiveUserId);
            wrapper.transferRequests = buildTransferRequests(pendingRequests);
            wrapper.submittedTransferRequests =
                buildSubmittedTransferRequests(effectiveUserId);
            dbg.length = 0;
            return wrapper;
        }

        Set<Id> userSrIds = new Set<Id>();
        for (ServiceResource sr : srs) {
            userSrIds.add(sr.Id);
        }

        // ServiceResource for the *active* user; used for showing absences
        Set<Id> absenceSrIds = new Set<Id>();
        for (ServiceResource sr : [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId IN :srLookupIds
               OR Id IN :srLookupIds
        ]) {
            absenceSrIds.add(sr.Id);
        }

        wrapper.absences = new List<ResourceAbsenceDTO>();
        if (!absenceSrIds.isEmpty()) {
            // Pull a wide absence window so that future-dated time off is visible
            // even if it extends beyond the current 2-week calendar view. Managers
            // and techs commonly schedule vacation months in advance, so we include
            // two years of future absences and one year of history for context.
            Datetime windowStart = System.now().addDays(-365);
            Datetime windowEnd = System.now().addDays(365 * 2);

            for (ResourceAbsence ra : [
                SELECT Id,
                       ResourceId,
                       Start,
                       End,
                       Description,
                       Type
                FROM ResourceAbsence
                WHERE ResourceId IN :absenceSrIds
                AND End >= :windowStart
                AND Start <= :windowEnd
                ORDER BY Start ASC
            ]) {
                ResourceAbsenceDTO dto = new ResourceAbsenceDTO();
                dto.absenceId   = ra.Id;
                dto.resourceId  = ra.ResourceId;
                dto.start       = ra.Start;
                dto.endTime     = ra.End;
                dto.description = ra.Description;
                dto.type        = ra.Type;
                wrapper.absences.add(dto);
                dbg.absenceCount++;
                dbg.absenceResourceIds.add(ra.ResourceId);
            }
        }

        // 2) Service crews that this user is a member of
        Set<Id> crewIds = new Set<Id>();
        for (ServiceCrewMember scm : [
            SELECT ServiceCrewId
            FROM ServiceCrewMember
            WHERE ServiceResourceId IN :userSrIds
        ]) {
            if (scm.ServiceCrewId != null) {
                crewIds.add(scm.ServiceCrewId);
                dbg.serviceCrewIds.add(scm.ServiceCrewId);
            }
        }

        // 3) AssignedResource rows tied to this user / crews
        Set<Id> saIds = new Set<Id>();
        Map<Id, Boolean> isMyBySa   = new Map<Id, Boolean>();
        Map<Id, Boolean> isCrewBySa = new Map<Id, Boolean>();
        Map<Id, Id> crewIdBySa      = new Map<Id, Id>();

        for (AssignedResource ar : [
            SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceCrewId
            FROM AssignedResource
            WHERE (ServiceResourceId IN :userSrIds
                   OR ServiceCrewId IN :crewIds)
        ]) {
            dbg.assignedResourceIds.add(ar.Id);

            if (ar.ServiceAppointmentId == null) continue;

            saIds.add(ar.ServiceAppointmentId);

            if (ar.ServiceResourceId != null && userSrIds.contains(ar.ServiceResourceId)) {
                isMyBySa.put(ar.ServiceAppointmentId, true);
            }
            if (ar.ServiceCrewId != null && crewIds.contains(ar.ServiceCrewId)) {
                isCrewBySa.put(ar.ServiceAppointmentId, true);

                if (!crewIdBySa.containsKey(ar.ServiceAppointmentId)) {
                    crewIdBySa.put(ar.ServiceAppointmentId, ar.ServiceCrewId);
                }
            }
        }

        dbg.serviceAppointmentIds.addAll(saIds);

        Map<Id, String> opportunityRecordTypeByWo = new Map<Id, String>();
        Map<Id, Id> quoteDocIdByWo = new Map<Id, Id>();
        Set<Id> workOrdersWithAttachment = new Set<Id>();
        Map<Id, String> quoteDownloadByWo = new Map<Id, String>();
        Set<Id> workOrdersWithThisTech = new Set<Id>();
        Map<Id, Integer> completedVisitsByWo = new Map<Id, Integer>();
        Map<Id, Integer> serviceAppointmentCountByWo = new Map<Id, Integer>();

        if (saIds.isEmpty()) {
            dbg.note   = 'No AssignedResource / ServiceAppointment rows for these resources / crews.';
            List<Engineer_Transfer_Request__c> pendingRequests =
                getPendingTransferRequests(effectiveUserId);
            Set<Id> pendingTransferWoIds = extractWorkOrderIds(pendingRequests);
            wrapper.appointments = new List<AppointmentDTO>();
            wrapper.unscheduledWorkOrders = buildUnscheduledWorkOrders(
                workOrdersWithThisTech,
                userSrIds,
                crewIds,
                effectiveUserId,
                pendingTransferWoIds,
                workOrdersWithAttachment,
                quoteDownloadByWo,
                quoteDocIdByWo,
                opportunityRecordTypeByWo,
                completedVisitsByWo
            );
            assignQuoteLineItems(
                wrapper.appointments,
                wrapper.unscheduledWorkOrders
            );
            wrapper.historyItems = (includeHistory == true)
                ? buildHistoryItems(effectiveUserId)
                : new List<HistoryItemDTO>();
            wrapper.transferRequests = buildTransferRequests(pendingRequests);
            wrapper.submittedTransferRequests =
                buildSubmittedTransferRequests(effectiveUserId);
            dbg.length = 0;
            return wrapper;
        }

        // 4) ServiceAppointments
    List<ServiceAppointment> appts = [
        SELECT Id,
            ParentRecordId,
            SchedStartTime,
            SchedEndTime,
            WorkType.Name,
            Subject,
            Description,
            Work_Order__c,
            Work_Order__r.Status,
            Work_Order__r.Waiting_for_PO_Number__c,
            Work_Order__r.Tracking_Number__c,
            Work_Order__r.Loaner_Needed__c,
            Work_Order__r.Billing_Type__c,
            Work_Order__r.AccountId,
            Work_Order__r.Account.Name,
            Work_Order__r.Account_Name_Free_Text__c,
            Work_Order__r.PO_Number__c,
            Work_Order__r.ContactId,
            Work_Order__r.Contact.Name,
            Work_Order__r.Contact.Phone,
            Work_Order__r.Contact.Email,
            Work_Order__r.Billing_Contact_Name__c,
            Work_Order__r.Contact_Phone__c,
            Work_Order__r.Contact_Email__c,
            Work_Order__r.CreatedDate,
            Work_Order__r.CreatedById,
            Work_Order__r.LastModifiedDate,
            Work_Order__r.LastModifiedById,
            Work_Order__r.Opportunity__c,
                Work_Order__r.Opportunity__r.RecordType.Name,
                Work_Order__r.Opportunity__r.Name,
                Work_Order__r.Opportunity__r.StageName,
                Work_Order__r.Opportunity__r.Tracking__c,
                Work_Order__r.Opportunity__r.Opportunity_Number__c,
                Work_Order__r.Date_Probe_Received_for_Repair_Eval__c,
                Work_Order__r.Date_Quote_Sent_to_Customer__c,
                Work_Order__r.RecordType.Name,
                Work_Order__r.Next_Service_Date__c,
                Work_Order__r.Make_Model__c,
                Work_Order__r.Reporter_Contact_Info__c,
                Work_Order__r.Description,
                Work_Order__r.System_Serial_Number__c,
                Work_Order__r.Service_Site_Name__c,
                Work_Order__r.Line_Item_System__c,
            Work_Order__r.WorkOrderNumber,
            Work_Order__r.Attn__c,
            Work_Order__r.Shipping_Site_Name__c,
            Work_Order__r.Shipping_Street__c,
            Work_Order__r.Shipping_City__c,
            Work_Order__r.Shipping_State__c,
            Work_Order__r.Shipping_Country__c,
            Work_Order__r.Shipping_Postal_Code__c,
            AccountId,
            Account.Name,
            Street,
            City,
            State,
            PostalCode,
            Country,
            Shipping_Address__Street__s,
            Shipping_Address__City__s,
            Shipping_Address__StateCode__s,
            Shipping_Address__CountryCode__s,
            Shipping_Address__PostalCode__s,
            Tracking_Number__c,
            Return_Visit_Required__c,
            CreatedDate,
            LastModifiedDate,
            LastModifiedById
            FROM ServiceAppointment
            WHERE Id IN :saIds
            AND Status != 'Canceled'
            ORDER BY SchedStartTime ASC
            LIMIT 200
        ];

        Map<Id, Datetime> latestSaCreatedByWo = new Map<Id, Datetime>();
        Map<Id, String> latestSaTrackingByWo = new Map<Id, String>();
        Map<Id, Boolean> latestSaReturnVisitRequiredByWo = new Map<Id, Boolean>();
        Map<Id, String> latestLoanerTrackingByWo = new Map<Id, String>();
        Map<Id, List<Datetime>> visitScheduleDatesByWo = new Map<Id, List<Datetime>>();
        Map<Id, List<Id>> visitAppointmentIdsByWo = new Map<Id, List<Id>>();
        Map<Id, Integer> unscheduledSaCountByWo = new Map<Id, Integer>();

        // 5) Work Orders referenced by these appointments
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, List<Id>> workOrdersByOpportunity = new Map<Id, List<Id>>();


        for (ServiceAppointment sa : appts) {
            Id workOrderId = resolveWorkOrderId(sa);
            if (workOrderId != null) {
                workOrderIds.add(workOrderId);

                if (sa.Work_Order__r != null && sa.Work_Order__r.Opportunity__c != null) {
                    Id oppId = sa.Work_Order__r.Opportunity__c;
                    opportunityIds.add(oppId);

                    List<Id> relatedWorkOrders = workOrdersByOpportunity.containsKey(oppId)
                        ? workOrdersByOpportunity.get(oppId)
                        : new List<Id>();
                    if (!relatedWorkOrders.contains(workOrderId)) {
                        relatedWorkOrders.add(workOrderId);
                    }
                    workOrdersByOpportunity.put(oppId, relatedWorkOrders);

                    if (sa.Work_Order__r.Opportunity__r != null &&
                        sa.Work_Order__r.Opportunity__r.RecordType != null) {
                        opportunityRecordTypeByWo.put(
                            workOrderId,
                            sa.Work_Order__r.Opportunity__r.RecordType.Name
                        );
                    }
                }
            }
            if (workOrderId != null) {
                Datetime latestCreated = latestSaCreatedByWo.get(workOrderId);
                if (latestCreated == null || sa.CreatedDate > latestCreated) {
                    latestSaCreatedByWo.put(workOrderId, sa.CreatedDate);
                    latestSaTrackingByWo.put(workOrderId, sa.Tracking_Number__c);
                    latestSaReturnVisitRequiredByWo.put(
                        workOrderId,
                        sa.Return_Visit_Required__c == true
                    );
                }
            }
        }
        dbg.workOrderIds.addAll(workOrderIds);

        if (!workOrderIds.isEmpty()) {
            for (ServiceAppointment woSa : [
                SELECT Id,
                    Work_Order__c,
                    ParentRecordId,
                    SchedStartTime,
                    SchedEndTime,
                    CreatedDate,
                    AppointmentNumber
                FROM ServiceAppointment
                WHERE (
                    Work_Order__c IN :workOrderIds
                    OR ParentRecordId IN :workOrderIds
                )
                AND Status != 'Canceled'
                ORDER BY CreatedDate ASC, Id ASC
            ]) {
                Id workOrderId = resolveWorkOrderId(woSa);
                if (workOrderId == null) continue;

                List<Id> visitAppointmentIds = visitAppointmentIdsByWo.containsKey(workOrderId)
                    ? visitAppointmentIdsByWo.get(workOrderId)
                    : new List<Id>();
                visitAppointmentIds.add(woSa.Id);
                visitAppointmentIdsByWo.put(workOrderId, visitAppointmentIds);

                Datetime visitScheduleDate = woSa.SchedStartTime;
                List<Datetime> visitScheduleDates = visitScheduleDatesByWo.containsKey(workOrderId)
                    ? visitScheduleDatesByWo.get(workOrderId)
                    : new List<Datetime>();
                visitScheduleDates.add(visitScheduleDate);
                visitScheduleDatesByWo.put(workOrderId, visitScheduleDates);

                Boolean isScheduled =
                    woSa.SchedStartTime != null || woSa.SchedEndTime != null;
                if (!isScheduled) {
                    Integer unscheduledCount = unscheduledSaCountByWo.containsKey(workOrderId)
                        ? unscheduledSaCountByWo.get(workOrderId)
                        : 0;
                    unscheduledSaCountByWo.put(workOrderId, unscheduledCount + 1);
                }
            }
        }

        if (!workOrderIds.isEmpty()) {
            for (Loaner__c loaner : [
                SELECT Work_Order__c,
                    Tracking_Number__c,
                    CreatedDate
                FROM Loaner__c
                WHERE Work_Order__c IN :workOrderIds
                ORDER BY CreatedDate DESC
            ]) {
                if (loaner.Work_Order__c == null ||
                    latestLoanerTrackingByWo.containsKey(loaner.Work_Order__c)) {
                    continue;
                }

                latestLoanerTrackingByWo.put(
                    loaner.Work_Order__c,
                    loaner.Tracking_Number__c
                );
            }
        }

        if (!workOrderIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT Work_Order__c woId,
                    COUNT_DISTINCT(Id) cnt
                FROM ServiceAppointment
                WHERE Work_Order__c IN :workOrderIds
                GROUP BY Work_Order__c
            ]) {
                Id woId = (Id) ar.get('woId');
                Decimal countDecimal = (Decimal) ar.get('cnt');
                Integer count = (countDecimal != null) ? countDecimal.intValue() : 0;
                if (woId != null && count != null) {
                    serviceAppointmentCountByWo.put(woId, count);
                }
            }
        }

        // Track Work Orders with an attachment (for quote tracking)


        if (!workOrderIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.FileExtension,
                    ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :workOrderIds
            ]) {
                if (cdl.LinkedEntityId != null) {
                    workOrdersWithAttachment.add(cdl.LinkedEntityId);

                    if (cdl.ContentDocument != null &&
                        String.isNotBlank(cdl.ContentDocument.LatestPublishedVersionId) &&
                        !quoteDownloadByWo.containsKey(cdl.LinkedEntityId)) {

                        quoteDownloadByWo.put(
                            cdl.LinkedEntityId,
                            '/sfc/servlet.shepherd/document/download/' +
                                cdl.ContentDocumentId
                        );

                        if (cdl.ContentDocumentId != null) {
                            quoteDocIdByWo.put(
                                cdl.LinkedEntityId,
                                cdl.ContentDocumentId
                            );
                        }
                    }
                }
            }
        }

        // Track completed visits for this technician on each Work Order
        if (!workOrderIds.isEmpty() && (!userSrIds.isEmpty() || !crewIds.isEmpty())) {
            Set<String> completedStatuses = new Set<String>{
                'Completed',
                'Completed WO'
            };

            for (AggregateResult ar : [
                SELECT Work_Order__c woId,
                    COUNT_DISTINCT(Id) cnt
                FROM ServiceAppointment
                WHERE Work_Order__c IN :workOrderIds
                AND Status IN :completedStatuses
                AND Id IN (
                    SELECT ServiceAppointmentId
                    FROM AssignedResource
                    WHERE (ServiceResourceId IN :userSrIds
                        OR ServiceCrewId IN :crewIds)
                )
                GROUP BY Work_Order__c
            ]) {
                Id woId = (Id) ar.get('woId');
                Decimal countDecimal = (Decimal) ar.get('cnt');
                Integer count = (countDecimal != null) ? countDecimal.intValue() : 0;
                if (woId != null && count != null) {
                    completedVisitsByWo.put(woId, count);
                }
            }
        }

        if (!opportunityIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.FileExtension,
                    ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :opportunityIds
            ]) {
                if (cdl.LinkedEntityId != null &&
                    workOrdersByOpportunity.containsKey(cdl.LinkedEntityId)) {

                    for (Id woId : workOrdersByOpportunity.get(cdl.LinkedEntityId)) {
                        workOrdersWithAttachment.add(woId);

                        if (cdl.ContentDocument != null &&
                            String.isNotBlank(cdl.ContentDocument.LatestPublishedVersionId) &&
                            !quoteDownloadByWo.containsKey(woId)) {

                            quoteDownloadByWo.put(
                                woId,
                                '/sfc/servlet.shepherd/document/download/' +
                                    cdl.ContentDocumentId
                            );

                            if (cdl.ContentDocumentId != null) {
                                quoteDocIdByWo.put(
                                    woId,
                                    cdl.ContentDocumentId
                                );
                            }
                        }
                    }
                }
            }
        }

        // Parts info
        Map<Id, Integer> totalLinesByWo   = new Map<Id, Integer>();
        Map<Id, Integer> enRouteByWo      = new Map<Id, Integer>();

        if (!workOrderIds.isEmpty()) {
            for (WorkOrderLineItem woli : [
                SELECT Id, WorkOrderId, Line_Type__c
                FROM WorkOrderLineItem
                WHERE WorkOrderId IN :workOrderIds
            ]) {
                if (woli.WorkOrderId == null) continue;

                Integer total = totalLinesByWo.containsKey(woli.WorkOrderId)
                    ? totalLinesByWo.get(woli.WorkOrderId) : 0;
                totalLinesByWo.put(woli.WorkOrderId, total + 1);

                if (woli.Line_Type__c == 'Part En-Route') {
                    Integer shipped = enRouteByWo.containsKey(woli.WorkOrderId)
                        ? enRouteByWo.get(woli.WorkOrderId) : 0;
                    enRouteByWo.put(woli.WorkOrderId, shipped + 1);
                }
            }
        }

        // Crew members for crews on these appointments
        Set<Id> crewIdsForAppointments = new Set<Id>();
        for (Id saId : saIds) {
            if (crewIdBySa.containsKey(saId)) {
                crewIdsForAppointments.add(crewIdBySa.get(saId));
            }
        }

        Map<Id, List<CrewMemberDTO>> crewMembersByCrew = new Map<Id, List<CrewMemberDTO>>();
        if (!crewIdsForAppointments.isEmpty()) {
            for (ServiceCrewMember scm : [
                SELECT Id,
                       ServiceCrewId,
                       ServiceResourceId,
                       ServiceResource.Name
                FROM ServiceCrewMember
                WHERE ServiceCrewId IN :crewIdsForAppointments
            ]) {
                if (scm.ServiceCrewId == null || scm.ServiceResourceId == null) continue;

                List<CrewMemberDTO> listForCrew = crewMembersByCrew.get(scm.ServiceCrewId);
                if (listForCrew == null) {
                    listForCrew = new List<CrewMemberDTO>();
                    crewMembersByCrew.put(scm.ServiceCrewId, listForCrew);
                }

                CrewMemberDTO cmd = new CrewMemberDTO();
                cmd.serviceResourceId = scm.ServiceResourceId;
                cmd.name = (scm.ServiceResource != null ? scm.ServiceResource.Name : null);
                listForCrew.add(cmd);
            }
        }

        // 6) Build Appointment DTOs
        List<AppointmentDTO> results = new List<AppointmentDTO>();
        String normalizedDataScope = String.isBlank(dataScope)
            ? 'all'
            : dataScope.toLowerCase();

        for (ServiceAppointment sa : appts) {
            String workTypeName = (sa.WorkType == null) ? null : sa.WorkType.Name;
            String normalizedWorkTypeName = String.isBlank(workTypeName)
                ? null
                : workTypeName.toLowerCase();
            String statusName = (sa.Work_Order__r != null) ? sa.Work_Order__r.Status : null;

            Boolean isPreventativeMaintenance =
                normalizedWorkTypeName != null &&
                (normalizedWorkTypeName == 'ppm' ||
                 normalizedWorkTypeName.contains('preventative maintenance') ||
                 normalizedWorkTypeName.contains('preventive maintenance'));
            Boolean isHistoryOrRecentStatus = statusName == 'Completed WO' || statusName == 'Completed';
            Boolean hasScheduleForScope = sa.SchedStartTime != null || sa.SchedEndTime != null;

            if (normalizedDataScope == 'salesandservice') {
                if (isPreventativeMaintenance || isHistoryOrRecentStatus) {
                    continue;
                }
            } else if (normalizedDataScope == 'preventativemaintenance') {
                if (!isPreventativeMaintenance) {
                    continue;
                }
            } else if (normalizedDataScope == 'recent') {
                if (isPreventativeMaintenance) {
                    continue;
                }
            } else if (normalizedDataScope == 'history') {
                continue;
            } else if (normalizedDataScope == 'calendar') {
                if (!hasScheduleForScope) {
                    continue;
                }
            }
            AppointmentDTO dto        = new AppointmentDTO();
            Id workOrderId            = resolveWorkOrderId(sa);
            dto.appointmentId         = sa.Id;
            dto.workTypeName          = (sa.WorkType == null) ? null : sa.WorkType.Name;
            String opportunityName =
                (sa.Work_Order__r != null && sa.Work_Order__r.Opportunity__r != null)
                    ? sa.Work_Order__r.Opportunity__r.Name
                    : null;
            dto.workOrderSubject      = String.isBlank(opportunityName)
                ? sa.Subject
                : opportunityName;
            dto.workOrderNumber      = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.WorkOrderNumber
                : null;
            dto.systemSerialNumber    = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.System_Serial_Number__c
                : null;
            dto.serviceSiteName       = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Service_Site_Name__c
                : null;
            dto.lineItemSystem        = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Line_Item_System__c
                : null;
            dto.poNumber = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.PO_Number__c
                : null;

            dto.description           = sa.Description;
            dto.workOrderDescription  = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Description
                : null;
            dto.workOrderId           = workOrderId;
            dto.workOrderStatus       = (sa.Work_Order__r != null)
                                        ? sa.Work_Order__r.Status : null;
            dto.waitingForPoNumber = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Waiting_for_PO_Number__c
                : false;
            dto.serviceAppointmentTrackingNumber = sa.Tracking_Number__c;
            dto.workOrderCreatedDate = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.CreatedDate
                : null;
            dto.workOrderCreatedById = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.CreatedById
                : null;
            dto.workOrderLastModifiedDate = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.LastModifiedDate
                : null;
            dto.workOrderLastModifiedById = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.LastModifiedById
                : null;
            dto.serviceAppointmentLastModifiedDate = sa.LastModifiedDate;
            dto.serviceAppointmentLastModifiedById = sa.LastModifiedById;
            dto.latestServiceAppointmentTrackingNumber = (workOrderId != null &&
                latestSaTrackingByWo.containsKey(workOrderId))
                    ? latestSaTrackingByWo.get(workOrderId)
                    : null;
            dto.workOrderTrackingNumber = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Tracking_Number__c
                : null;
            dto.billingType = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Billing_Type__c
                : null;
            dto.opportunityTrackingNumber = (sa.Work_Order__r != null &&
                sa.Work_Order__r.Opportunity__r != null)
                    ? sa.Work_Order__r.Opportunity__r.Tracking__c
                    : null;
            dto.opportunityNumber = (sa.Work_Order__r != null &&
                sa.Work_Order__r.Opportunity__r != null)
                    ? sa.Work_Order__r.Opportunity__r.Opportunity_Number__c
                    : null;
            dto.opportunityStage = (sa.Work_Order__r != null &&
                sa.Work_Order__r.Opportunity__r != null)
                    ? sa.Work_Order__r.Opportunity__r.StageName
                    : null;
            dto.dateProbeReceivedForRepairEval = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Date_Probe_Received_for_Repair_Eval__c
                : null;
            dto.dateQuoteSentToCustomer = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Date_Quote_Sent_to_Customer__c
                : null;
            dto.nextServiceDate = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Next_Service_Date__c
                : null;
            dto.loanerTrackingNumber = (sa.Work_Order__r != null &&
                sa.Work_Order__r.Loaner_Needed__c == 'w/ Loaner' &&
                workOrderId != null &&
                latestLoanerTrackingByWo.containsKey(workOrderId))
                    ? latestLoanerTrackingByWo.get(workOrderId)
                    : null;
            dto.trackingNumber =
                dto.latestServiceAppointmentTrackingNumber != null
                    ? dto.latestServiceAppointmentTrackingNumber
                    : (dto.workOrderTrackingNumber != null
                        ? dto.workOrderTrackingNumber
                        : ((dto.billingType != null &&
                            dto.billingType.toLowerCase() == 'warranty')
                            ? dto.serviceAppointmentTrackingNumber
                            : (dto.opportunityTrackingNumber != null
                            ? dto.opportunityTrackingNumber
                            : dto.serviceAppointmentTrackingNumber)));
            dto.completedVisitCount   = (workOrderId != null &&
                completedVisitsByWo.containsKey(workOrderId))
                    ? completedVisitsByWo.get(workOrderId)
                    : 0;
            dto.serviceAppointmentCount = (workOrderId != null &&
                serviceAppointmentCountByWo.containsKey(workOrderId))
                    ? serviceAppointmentCountByWo.get(workOrderId)
                    : 0;
            dto.unscheduledServiceAppointmentCount = (workOrderId != null &&
                unscheduledSaCountByWo.containsKey(workOrderId))
                    ? unscheduledSaCountByWo.get(workOrderId)
                    : 0;
            dto.visitScheduleDates = (workOrderId != null &&
                visitScheduleDatesByWo.containsKey(workOrderId))
                    ? new List<Datetime>(visitScheduleDatesByWo.get(workOrderId))
                    : new List<Datetime>();
            dto.visitAppointmentIds = (workOrderId != null &&
                visitAppointmentIdsByWo.containsKey(workOrderId))
                    ? new List<Id>(visitAppointmentIdsByWo.get(workOrderId))
                    : new List<Id>();

            // Account resolution
            if (sa.AccountId != null && sa.Account != null) {
                dto.accountId   = sa.AccountId;
                dto.accountName = sa.Account.Name;
            } else if (sa.Work_Order__r != null && sa.Work_Order__r.Account != null) {
                dto.accountId   = sa.Work_Order__r.AccountId;
                dto.accountName = sa.Work_Order__r.Account.Name;
            } else {
                dto.accountId   = null;
                dto.accountName = null;
            }
            dto.accountNameFreeText = (sa.Work_Order__r != null)
                ? (sa.Work_Order__r.AccountId != null
                    ? sa.Work_Order__r.Account_Name_Free_Text__c
                    : sa.Work_Order__r.Service_Site_Name__c)
                : null;

            dto.contactId = (sa.Work_Order__r != null) ? sa.Work_Order__r.ContactId : null;
            if (sa.Work_Order__r != null) {
                dto.contactName = firstNonBlank(
                    (sa.Work_Order__r.Contact != null) ? sa.Work_Order__r.Contact.Name : null,
                    sa.Work_Order__r.Billing_Contact_Name__c
                );
                dto.contactPhone = firstNonBlank(
                    (sa.Work_Order__r.Contact != null) ? sa.Work_Order__r.Contact.Phone : null,
                    sa.Work_Order__r.Contact_Phone__c
                );
                dto.contactEmail = firstNonBlank(
                    (sa.Work_Order__r.Contact != null) ? sa.Work_Order__r.Contact.Email : null,
                    sa.Work_Order__r.Contact_Email__c
                );
            }

            dto.schedStart = sa.SchedStartTime;
            dto.schedEnd   = sa.SchedEndTime;

            dto.makeModel           = (sa.Work_Order__r != null)
                                      ? sa.Work_Order__r.Make_Model__c : null;
            dto.reporterContactInfo = (sa.Work_Order__r != null)
                                      ? sa.Work_Order__r.Reporter_Contact_Info__c : null;

            dto.street      = sa.Street;
            dto.city        = sa.City;
            dto.state       = sa.State;
            dto.postalCode  = sa.PostalCode;
            dto.country     = sa.Country;
            dto.shippingAttn = (sa.Work_Order__r != null)
                ? sa.Work_Order__r.Attn__c
                : null;
            dto.shippingSiteName = (sa.Work_Order__r != null)
                ? firstNonBlank(
                    sa.Work_Order__r.Shipping_Site_Name__c,
                    sa.Work_Order__r.Service_Site_Name__c
                )
                : null;
            String shippingStreet = sa.Shipping_Address__Street__s;
            String shippingCity = sa.Shipping_Address__City__s;
            String shippingState = sa.Shipping_Address__StateCode__s;
            String shippingCountry = sa.Shipping_Address__CountryCode__s;
            String shippingPostalCode = sa.Shipping_Address__PostalCode__s;

            if (String.isBlank(shippingStreet) && sa.Work_Order__r != null) {
                shippingStreet = sa.Work_Order__r.Shipping_Street__c;
            }
            if (String.isBlank(shippingCity) && sa.Work_Order__r != null) {
                shippingCity = sa.Work_Order__r.Shipping_City__c;
            }
            if (String.isBlank(shippingState) && sa.Work_Order__r != null) {
                shippingState = sa.Work_Order__r.Shipping_State__c;
            }
            if (String.isBlank(shippingCountry) && sa.Work_Order__r != null) {
                shippingCountry = sa.Work_Order__r.Shipping_Country__c;
            }
            if (String.isBlank(shippingPostalCode) && sa.Work_Order__r != null) {
                shippingPostalCode = sa.Work_Order__r.Shipping_Postal_Code__c;
            }

            dto.shippingStreet = shippingStreet;
            dto.shippingCity = shippingCity;
            dto.shippingState = shippingState;
            dto.shippingCountry = shippingCountry;
            dto.shippingPostalCode = shippingPostalCode;

            Boolean isMy   = isMyBySa.containsKey(sa.Id);
            Boolean isCrew = isCrewBySa.containsKey(sa.Id);

            dto.isCrewAssignment = isCrew;
            dto.isMyAssignment   = isMy && !isCrew;

            Boolean hasSchedule =
                (sa.SchedStartTime != null) || (sa.SchedEndTime != null);

            // Track WOs where this tech already has a scheduled appointment
            if ((isMy || isCrew) && hasSchedule && workOrderId != null) {
                workOrdersWithThisTech.add(workOrderId);
            }

            dto.serviceCrewId = crewIdBySa.containsKey(sa.Id)
                ? crewIdBySa.get(sa.Id) : null;

            if (dto.serviceCrewId != null &&
                crewMembersByCrew.containsKey(dto.serviceCrewId)) {
                dto.crewMembers = crewMembersByCrew.get(dto.serviceCrewId);
            } else {
                dto.crewMembers = new List<CrewMemberDTO>();
            }

            if (workOrderId != null &&
                totalLinesByWo.containsKey(workOrderId)) {

                Integer total   = totalLinesByWo.get(workOrderId);
                Integer shipped = enRouteByWo.containsKey(workOrderId)
                    ? enRouteByWo.get(workOrderId) : 0;

                dto.allPartsEnRoute =
                    (total != null && total > 0 && shipped != null && shipped == total);
                dto.somePartsEnRoute =
                    (total != null && shipped != null && shipped > 0 && shipped < total);
            } else {
                dto.allPartsEnRoute  = false;
                dto.somePartsEnRoute = false;
            }

            Boolean hasAttachment =
                (workOrderId != null && workOrdersWithAttachment.contains(workOrderId));

            dto.quoteAttachmentDownloadUrl = (workOrderId != null &&
                quoteDownloadByWo.containsKey(workOrderId))
                    ? quoteDownloadByWo.get(workOrderId)
                    : null;
            dto.quoteAttachmentDocumentId = (workOrderId != null &&
                quoteDocIdByWo.containsKey(workOrderId))
                    ? quoteDocIdByWo.get(workOrderId)
                    : null;

            dto.hasQuoteAttachment = hasAttachment ||
                (dto.workOrderStatus == 'Quote Attached');

            dto.latestReturnVisitRequired = (workOrderId != null &&
                latestSaReturnVisitRequiredByWo.containsKey(workOrderId))
                    ? latestSaReturnVisitRequiredByWo.get(workOrderId)
                    : sa.Return_Visit_Required__c == true;

            dto.opportunityRecordType = (workOrderId != null &&
                opportunityRecordTypeByWo.containsKey(workOrderId))
                    ? opportunityRecordTypeByWo.get(workOrderId)
                    : null;

            results.add(dto);
        }

        List<Engineer_Transfer_Request__c> pendingRequests =
            getPendingTransferRequests(effectiveUserId);
        Set<Id> pendingTransferWoIds = extractWorkOrderIds(pendingRequests);

        List<UnscheduledWorkOrderDTO> unscheduledWorkOrders = buildUnscheduledWorkOrders(
            workOrdersWithThisTech,
            userSrIds,
            crewIds,
            effectiveUserId,
            pendingTransferWoIds,
            workOrdersWithAttachment,
            quoteDownloadByWo,
            quoteDocIdByWo,
            opportunityRecordTypeByWo,
            completedVisitsByWo
        );
        assignQuoteLineItems(results, unscheduledWorkOrders);

        wrapper.appointments = results;
        wrapper.unscheduledWorkOrders = unscheduledWorkOrders;
        wrapper.historyItems = (includeHistory == true)
            ? buildHistoryItems(effectiveUserId)
            : new List<HistoryItemDTO>();
        wrapper.transferRequests = buildTransferRequests(pendingRequests);
        wrapper.submittedTransferRequests =
            buildSubmittedTransferRequests(effectiveUserId);
        dbg.length = results.size();
        if (String.isBlank(dbg.note)) {
            dbg.note = 'Online fetch succeeded.';
        }

        return wrapper;
    }

    @AuraEnabled
    public static List<HistoryItemDTO> getHistoryItems(Id targetUserId) {
        Id effectiveUserId = (targetUserId != null)
            ? targetUserId
            : UserInfo.getUserId();
        return buildHistoryItems(effectiveUserId);
    }

    private static List<HistoryItemDTO> buildHistoryItems(Id ownerUserId) {
        List<HistoryItemDTO> items = new List<HistoryItemDTO>();

        if (ownerUserId == null) {
            return items;
        }

        String ownerFullName;
        List<User> owners = [
            SELECT Name
            FROM User
            WHERE Id = :ownerUserId
            LIMIT 1
        ];
        if (!owners.isEmpty()) {
            ownerFullName = owners[0].Name;
        }

        List<WorkOrder> completedWorkOrders = [
            SELECT Id,
                WorkOrderNumber,
                WorkType.Name,
                System_Serial_Number__c,
                Subject,
                Status,
                Tracking_Number__c,
                Billing_Type__c,
                AccountId,
                Account.Name,
                Account_Name_Free_Text__c,
                Street,
                City,
                State,
                PostalCode,
                Country,
                LastModifiedDate,
                RecordType.Name,
                Opportunity__c,
                Opportunity__r.Name,
                Opportunity__r.Opportunity_Number__c,
                Opportunity__r.StageName,
                Opportunity__r.RecordType.Name,
                Opportunity__r.Tracking__c,
                Opportunity__r.CreatedDate
            FROM WorkOrder
            WHERE OwnerId = :ownerUserId
            AND Status IN ('Completed WO', 'Closed')
            AND RecordType.Name = 'FSL Work Order'
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];

        for (WorkOrder wo : completedWorkOrders) {
            HistoryItemDTO dto = new HistoryItemDTO();
            dto.workOrderId = wo.Id;
            dto.workOrderNumber = wo.WorkOrderNumber;
            dto.workTypeName = (wo.WorkType != null) ? wo.WorkType.Name : null;
            dto.systemSerialNumber = wo.System_Serial_Number__c;
            dto.workOrderStatus = wo.Status;
            dto.accountName = (wo.Account != null) ? wo.Account.Name : null;
            dto.accountNameFreeText = wo.Account_Name_Free_Text__c;
            dto.street = wo.Street;
            dto.city = wo.City;
            dto.state = wo.State;
            dto.postalCode = wo.PostalCode;
            dto.country = wo.Country;
            dto.lastModifiedDate = wo.LastModifiedDate;
            dto.trackingNumber = wo.Tracking_Number__c;

            if (wo.Opportunity__r != null) {
                dto.opportunityId = wo.Opportunity__c;
                dto.opportunityNumber = wo.Opportunity__r.Opportunity_Number__c;
                dto.opportunityName = wo.Opportunity__r.Name;
                dto.opportunityStage = wo.Opportunity__r.StageName;
                dto.opportunityRecordType = (wo.Opportunity__r.RecordType != null)
                    ? wo.Opportunity__r.RecordType.Name
                    : null;
                if (String.isBlank(dto.trackingNumber)) {
                    dto.trackingNumber = wo.Opportunity__r.Tracking__c;
                }
                dto.opportunityCreatedDate = wo.Opportunity__r.CreatedDate;
            }

            String opportunityName = (wo.Opportunity__r != null)
                ? wo.Opportunity__r.Name
                : null;
            dto.workOrderSubject = String.isBlank(opportunityName)
                ? wo.Subject
                : opportunityName;

            items.add(dto);
        }

        String opportunityHistoryQuery = 'SELECT Id, ' +
            'Name, ' +
            'Opportunity_Number__c, ' +
            'StageName, ' +
            'RecordType.Name, ' +
            'Tracking__c, ' +
            'System_Serial_Number__c, ' +
            'Related_Work_Order__c, ' +
            'Related_Work_Order__r.WorkOrderNumber, ' +
            'Related_Work_Order__r.Subject, ' +
            'Related_Work_Order__r.Status, ' +
            'Related_Work_Order__r.Tracking_Number__c, ' +
            'Related_Work_Order__r.System_Serial_Number__c, ' +
            'AccountId, ' +
            'Account.Name, ' +
            'Account.BillingStreet, ' +
            'Account.BillingCity, ' +
            'Account.BillingState, ' +
            'Account.BillingPostalCode, ' +
            'Account.BillingCountry, ' +
            'LastModifiedDate, ' +
            'CreatedDate ' +
            'FROM Opportunity ' +
            'WHERE Opportunity_Number__c != null ' +
            'AND StageName = \'Closed Won\' ' +
            'AND Id NOT IN (SELECT Opportunity__c FROM WorkOrder WHERE Opportunity__c != null AND Status != \'Canceled\') ';
        opportunityHistoryQuery +=
            'AND (OwnerId = :ownerUserId ' +
            'OR Field_Service_Engineer__c = :ownerFullName ' +
            'OR Field_Service_Engineer_2__c = :ownerFullName ' +
            'OR Field_Service_Engineer_3__c = :ownerFullName ' +
            'OR Field_Service_Engineer_4__c = :ownerFullName ' +
            'OR Rep__c = :ownerFullName) ';
        opportunityHistoryQuery += 'ORDER BY LastModifiedDate DESC LIMIT 200';
        List<Opportunity> opportunityHistory = Database.query(opportunityHistoryQuery);

        for (Opportunity opp : opportunityHistory) {
            HistoryItemDTO dto = new HistoryItemDTO();
            dto.opportunityId = opp.Id;
            dto.opportunityNumber = opp.Opportunity_Number__c;
            dto.opportunityName = opp.Name;
            dto.opportunityStage = opp.StageName;
            dto.opportunityRecordType = (opp.RecordType != null)
                ? opp.RecordType.Name
                : null;
            dto.opportunityCreatedDate = opp.CreatedDate;
            dto.accountName = (opp.Account != null) ? opp.Account.Name : null;
            dto.street = (opp.Account != null) ? opp.Account.BillingStreet : null;
            dto.city = (opp.Account != null) ? opp.Account.BillingCity : null;
            dto.state = (opp.Account != null) ? opp.Account.BillingState : null;
            dto.postalCode = (opp.Account != null) ? opp.Account.BillingPostalCode : null;
            dto.country = (opp.Account != null) ? opp.Account.BillingCountry : null;
            dto.trackingNumber = opp.Tracking__c;
            dto.systemSerialNumber = opp.System_Serial_Number__c;
            dto.lastModifiedDate = opp.LastModifiedDate;
            if (opp.Related_Work_Order__r != null) {
                dto.relatedWorkOrderId = opp.Related_Work_Order__c;
                dto.relatedWorkOrderNumber =
                    opp.Related_Work_Order__r.WorkOrderNumber;
                dto.relatedWorkOrderSubject =
                    opp.Related_Work_Order__r.Subject;
                dto.relatedWorkOrderStatus =
                    opp.Related_Work_Order__r.Status;
                dto.relatedWorkOrderTrackingNumber =
                    opp.Related_Work_Order__r.Tracking_Number__c;
                dto.relatedWorkOrderSystemSerialNumber =
                    opp.Related_Work_Order__r.System_Serial_Number__c;
            }
            items.add(dto);
        }

        return items;
    }

    private static List<Engineer_Transfer_Request__c> getPendingTransferRequests(
        Id targetUserId
    ) {
        if (targetUserId == null) {
            return new List<Engineer_Transfer_Request__c>();
        }

        return [
            SELECT Id,
                Work_Order_to_Transfer__c,
                Work_Order_to_Transfer__r.WorkOrderNumber,
                Work_Order_to_Transfer__r.Subject,
                Work_Order_to_Transfer__r.Account.Name,
                Work_Order_to_Transfer__r.Street,
                Work_Order_to_Transfer__r.City,
                Work_Order_to_Transfer__r.State,
                Work_Order_to_Transfer__r.PostalCode,
                Work_Order_to_Transfer__r.Country,
                CreatedBy.Name,
                Transfer_Work_Order_To_Engineer__r.Name,
                Accepted_on__c,
                Date_Rejected_On__c,
                Rejected_Reason__c
            FROM Engineer_Transfer_Request__c
            WHERE Transfer_Work_Order_To_Engineer__c = :targetUserId
            AND Accepted_on__c = null
            AND Date_Rejected_On__c = null
            ORDER BY CreatedDate ASC
        ];
    }

    private static List<TransferRequestDTO> buildTransferRequests(
        List<Engineer_Transfer_Request__c> requests
    ) {
        List<TransferRequestDTO> dtos = new List<TransferRequestDTO>();

        for (Engineer_Transfer_Request__c req : requests) {
            TransferRequestDTO dto = new TransferRequestDTO();
            dto.transferRequestId = req.Id;
            dto.workOrderId = req.Work_Order_to_Transfer__c;
            dto.workOrderNumber = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.WorkOrderNumber
                : null;
            dto.workOrderSubject = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.Subject
                : null;
            dto.accountName = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.Account.Name
                : null;
            dto.street = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.Street
                : null;
            dto.city = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.City
                : null;
            dto.state = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.State
                : null;
            dto.postalCode = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.PostalCode
                : null;
            dto.country = req.Work_Order_to_Transfer__r != null
                ? req.Work_Order_to_Transfer__r.Country
                : null;
            dto.requestedByName = req.CreatedBy != null ? req.CreatedBy.Name : null;
            dto.targetName = req.Transfer_Work_Order_To_Engineer__r != null
                ? req.Transfer_Work_Order_To_Engineer__r.Name
                : null;
            dto.acceptedOn = req.Accepted_on__c;
            dto.rejectedOn = req.Date_Rejected_On__c;
            dto.rejectionReason = req.Rejected_Reason__c;
            dtos.add(dto);
        }

        return dtos;
    }

    private static List<Engineer_Transfer_Request__c> getSubmittedTransferRequests(
        Id requesterUserId
    ) {
        if (requesterUserId == null) {
            return new List<Engineer_Transfer_Request__c>();
        }

        return [
            SELECT Id,
                Work_Order_to_Transfer__c,
                Work_Order_to_Transfer__r.WorkOrderNumber,
                Work_Order_to_Transfer__r.Subject,
                Work_Order_to_Transfer__r.Account.Name,
                Work_Order_to_Transfer__r.Street,
                Work_Order_to_Transfer__r.City,
                Work_Order_to_Transfer__r.State,
                Work_Order_to_Transfer__r.PostalCode,
                Work_Order_to_Transfer__r.Country,
                Transfer_Work_Order_To_Engineer__r.Name,
                Accepted_on__c,
                Date_Rejected_On__c,
                Rejected_Reason__c,
                CreatedDate,
                CreatedBy.Name
            FROM Engineer_Transfer_Request__c
            WHERE CreatedById = :requesterUserId
            ORDER BY CreatedDate DESC
        ];
    }

    private static List<TransferRequestDTO> buildSubmittedTransferRequests(
        Id requesterUserId
    ) {
        List<Engineer_Transfer_Request__c> requests =
            getSubmittedTransferRequests(requesterUserId);
        return buildTransferRequests(requests);
    }

    private static Set<Id> extractWorkOrderIds(
        List<Engineer_Transfer_Request__c> requests
    ) {
        Set<Id> woIds = new Set<Id>();

        for (Engineer_Transfer_Request__c req : requests) {
            if (req.Work_Order_to_Transfer__c != null) {
                woIds.add(req.Work_Order_to_Transfer__c);
            }
        }

        return woIds;
    }

    /**
     * Build the list of work orders that:
     *  - are owned by the current user
     *  - are NOT in one of the closed statuses
     *  - do NOT already have this technician on an appointment (direct or crew)
     */
    private static List<UnscheduledWorkOrderDTO> buildUnscheduledWorkOrders(
        Set<Id> workOrdersWithThisTech,
        Set<Id> userSrIds,
        Set<Id> crewIds,
        Id ownerUserId,
        Set<Id> pendingTransferWorkOrderIds,
        Set<Id> workOrdersWithAttachment,
        Map<Id, String> quoteDownloadByWo,
        Map<Id, Id> quoteDocIdByWo,
        Map<Id, String> opportunityRecordTypeByWo,
        Map<Id, Integer> completedVisitsByWo
    ) {
        // Work Orders that are effectively "closed" from the technician perspective
        Set<String> closedStatuses = new Set<String>{
            'Completed WO',
            'Closed',
            'Cannot Complete',
            'Canceled',
            'Closed - Submitted'
        };

        List<UnscheduledWorkOrderDTO> dtos = new List<UnscheduledWorkOrderDTO>();

        // 1) Start with Work Orders owned by the current user, not closed,
        //    and not already associated to this tech or their crew
        List<WorkOrder> candidates = [
            SELECT Id,
                WorkOrderNumber,
                Subject,
                Status,
                Waiting_for_PO_Number__c,
                WorkType.Name,
                Tracking_Number__c,
                Loaner_Needed__c,
                Billing_Type__c,
                AccountId,
                Account.Name,
                Account_Name_Free_Text__c,
                Service_Site_Name__c,
                ContactId,
                Contact.Name,
                Contact.Phone,
                Contact.Email,
                Billing_Contact_Name__c,
                Contact_Phone__c,
                Contact_Email__c,
                CreatedDate,
                CreatedById,
                LastModifiedDate,
                LastModifiedById,
                Opportunity__c,
                Opportunity__r.RecordType.Name,
                Opportunity__r.Name,
                Opportunity__r.StageName,
                Opportunity__r.Tracking__c,
                Opportunity__r.Opportunity_Number__c,
                Date_Probe_Received_for_Repair_Eval__c,
                Date_Quote_Sent_to_Customer__c,
                RecordType.Name,
                Next_Service_Date__c,
                Description,
                Make_Model__c,
                Reporter_Contact_Info__c,
                System_Serial_Number__c,
                Line_Item_System__c,
                PO_Number__c,
                Attn__c,
                Shipping_Site_Name__c,
                Shipping_Street__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Country__c,
                Shipping_Postal_Code__c,
                Street,
                City,
                State,
                PostalCode,
                Country
            FROM WorkOrder
            WHERE OwnerId = :ownerUserId
            AND Status NOT IN :closedStatuses
            AND Id NOT IN :workOrdersWithThisTech
            LIMIT 200
        ];

        if (candidates.isEmpty()) {
            return dtos;
        }

        // Collect candidate Work Order Ids
        Set<Id> candidateWoIds = new Set<Id>();
        Set<Id> candidateOppIds = new Set<Id>();
        Map<Id, List<Id>> candidateWoByOpp = new Map<Id, List<Id>>();
        for (WorkOrder wo : candidates) {
            if (pendingTransferWorkOrderIds != null
                && pendingTransferWorkOrderIds.contains(wo.Id)) {
                // Pending transfer to this technician; keep it out of the unscheduled list
                // until the request is accepted or rejected.
                continue;
            }
            candidateWoIds.add(wo.Id);

            if (wo.Opportunity__c != null) {
                candidateOppIds.add(wo.Opportunity__c);

                List<Id> related = candidateWoByOpp.containsKey(wo.Opportunity__c)
                    ? candidateWoByOpp.get(wo.Opportunity__c)
                    : new List<Id>();
                if (!related.contains(wo.Id)) {
                    related.add(wo.Id);
                }
                candidateWoByOpp.put(wo.Opportunity__c, related);

                if (wo.Opportunity__r != null && wo.Opportunity__r.RecordType != null) {
                    opportunityRecordTypeByWo.put(
                        wo.Id,
                        wo.Opportunity__r.RecordType.Name
                    );
                }
            }
        }

        // Treat these Service Appointment statuses as closed for scheduling
        Set<String> saClosedStatuses = new Set<String>{
            'Completed',
            'Completed WO',
            'Closed',
            'Cannot Complete',
            'Canceled',
            'Closed - Submitted'
        };

        // 2) Query open ServiceAppointments for those Work Orders
        Map<Id, Id> saIdToWoId = new Map<Id, Id>();

        Map<Id, Boolean> saHasSchedule = new Map<Id, Boolean>();

        Map<Id, Integer> saCountByWo = new Map<Id, Integer>();
        Map<Id, Integer> unscheduledSaCountByWo = new Map<Id, Integer>();
        Map<Id, Boolean> allReturnRequiredByWo = new Map<Id, Boolean>();
        Map<Id, Boolean> hasReturnRequiredByWo = new Map<Id, Boolean>();
        Map<Id, Boolean> hasUnscheduledNonReturnByWo = new Map<Id, Boolean>();
        // Track total Service Appointments and whether the most recently created
        // appointment requested a return visit.
        Map<Id, Datetime> latestSaCreatedByWo = new Map<Id, Datetime>();
        Map<Id, Boolean> latestSaReturnVisitByWo = new Map<Id, Boolean>();
        Map<Id, String> latestSaTrackingNumberByWo = new Map<Id, String>();
        Map<Id, String> latestLoanerTrackingByWo = new Map<Id, String>();
        Map<Id, List<Datetime>> visitScheduleDatesByWo = new Map<Id, List<Datetime>>();
        Map<Id, List<Id>> visitAppointmentIdsByWo = new Map<Id, List<Id>>();

        for (ServiceAppointment sa : [
            SELECT Id,
                Work_Order__c,
                ParentRecordId,
                Return_Visit_Required__c,
                CreatedDate,
                Tracking_Number__c
            FROM ServiceAppointment
            WHERE (
                Work_Order__c IN :candidateWoIds
                OR ParentRecordId IN :candidateWoIds
            )
        ]) {
            Id workOrderId = resolveWorkOrderId(sa);
            if (workOrderId == null) continue;

            Datetime currentLatest = latestSaCreatedByWo.get(workOrderId);
            if (currentLatest == null || sa.CreatedDate > currentLatest) {
                latestSaCreatedByWo.put(workOrderId, sa.CreatedDate);
                latestSaReturnVisitByWo.put(
                    workOrderId,
                    sa.Return_Visit_Required__c == true
                );
                latestSaTrackingNumberByWo.put(
                    workOrderId,
                    sa.Tracking_Number__c
                );
            }
        }

        List<ServiceAppointment> candidateSAs = [
            SELECT Id,
                Work_Order__c,
                ParentRecordId,
                Status,
                SchedStartTime,
                SchedEndTime,
                Return_Visit_Required__c,
                CreatedDate,
                AppointmentNumber
            FROM ServiceAppointment
            WHERE (
                Work_Order__c IN :candidateWoIds
                OR ParentRecordId IN :candidateWoIds
            )
            ORDER BY CreatedDate ASC, Id ASC
        ];

        if (!candidateWoIds.isEmpty()) {
            for (Loaner__c loaner : [
                SELECT Work_Order__c,
                    Tracking_Number__c,
                    CreatedDate
                FROM Loaner__c
                WHERE Work_Order__c IN :candidateWoIds
                ORDER BY CreatedDate DESC
            ]) {
                if (loaner.Work_Order__c == null ||
                    latestLoanerTrackingByWo.containsKey(loaner.Work_Order__c)) {
                    continue;
                }

                latestLoanerTrackingByWo.put(
                    loaner.Work_Order__c,
                    loaner.Tracking_Number__c
                );
            }
        }

        for (ServiceAppointment sa : candidateSAs) {
            Id workOrderId = resolveWorkOrderId(sa);
            if (workOrderId == null) continue;

            Integer count = saCountByWo.containsKey(workOrderId)
                ? saCountByWo.get(workOrderId)
                : 0;
            saCountByWo.put(workOrderId, count + 1);

            Boolean returnRequired = sa.Return_Visit_Required__c == true;
            Boolean isScheduled =
                (sa.SchedStartTime != null) || (sa.SchedEndTime != null);

            Boolean allReturnRequired = allReturnRequiredByWo.containsKey(workOrderId)
                ? allReturnRequiredByWo.get(workOrderId)
                : true;
            allReturnRequiredByWo.put(workOrderId, allReturnRequired && returnRequired);

            if (returnRequired) {
                hasReturnRequiredByWo.put(workOrderId, true);
            }

            if (!isScheduled) {
                Integer unscheduledCount = unscheduledSaCountByWo.containsKey(workOrderId)
                    ? unscheduledSaCountByWo.get(workOrderId)
                    : 0;
                unscheduledSaCountByWo.put(workOrderId, unscheduledCount + 1);

                if (!returnRequired) {
                    hasUnscheduledNonReturnByWo.put(workOrderId, true);
                }
            }

            if (!saClosedStatuses.contains(sa.Status)) {
                saIdToWoId.put(sa.Id, workOrderId);
                saHasSchedule.put(sa.Id, isScheduled);
            }

            Datetime visitScheduleDate = sa.SchedStartTime;
            List<Datetime> visitScheduleDates = visitScheduleDatesByWo.containsKey(workOrderId)
                ? visitScheduleDatesByWo.get(workOrderId)
                : new List<Datetime>();
            visitScheduleDates.add(visitScheduleDate);
            visitScheduleDatesByWo.put(workOrderId, visitScheduleDates);

            List<Id> visitAppointmentIds = visitAppointmentIdsByWo.containsKey(workOrderId)
                ? visitAppointmentIdsByWo.get(workOrderId)
                : new List<Id>();
            visitAppointmentIds.add(sa.Id);
            visitAppointmentIdsByWo.put(workOrderId, visitAppointmentIds);
        }

        if (!candidateWoIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :candidateWoIds
            ]) {
                if (cdl.LinkedEntityId == null) continue;

                workOrdersWithAttachment.add(cdl.LinkedEntityId);

                if (cdl.ContentDocument != null &&
                    String.isNotBlank(cdl.ContentDocument.LatestPublishedVersionId) &&
                    !quoteDownloadByWo.containsKey(cdl.LinkedEntityId)) {

                    quoteDownloadByWo.put(
                        cdl.LinkedEntityId,
                        '/sfc/servlet.shepherd/document/download/' +
                            cdl.ContentDocumentId
                    );

                    if (cdl.ContentDocumentId != null) {
                        quoteDocIdByWo.put(
                            cdl.LinkedEntityId,
                            cdl.ContentDocumentId
                        );
                    }
                }
            }
        }

        if (!candidateOppIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :candidateOppIds
            ]) {
                if (cdl.LinkedEntityId == null ||
                    !candidateWoByOpp.containsKey(cdl.LinkedEntityId)) {
                    continue;
                }

                for (Id woId : candidateWoByOpp.get(cdl.LinkedEntityId)) {
                    workOrdersWithAttachment.add(woId);

                    if (cdl.ContentDocument != null &&
                        String.isNotBlank(cdl.ContentDocument.LatestPublishedVersionId) &&
                        !quoteDownloadByWo.containsKey(woId)) {

                        quoteDownloadByWo.put(
                            woId,
                            '/sfc/servlet.shepherd/document/download/' +
                                cdl.ContentDocumentId
                        );

                        if (cdl.ContentDocumentId != null) {
                            quoteDocIdByWo.put(
                                woId,
                                cdl.ContentDocumentId
                            );
                        }
                    }
                }
            }
        }

        // 3) For those ServiceAppointments, see which have any AssignedResource rows
        Set<Id> workOrdersWithNonCrewAssignment = new Set<Id>();
        Set<Id> workOrdersWithCrewAssignment     = new Set<Id>();

        if (!saIdToWoId.isEmpty()) {
            for (AssignedResource ar : [
                SELECT ServiceAppointmentId,
                    ServiceCrewId,
                    ServiceResource.ResourceType,
                    ServiceResource.RelatedRecordId
                FROM AssignedResource
                WHERE ServiceAppointmentId IN :saIdToWoId.keySet()
            ]) {
                Id woId = saIdToWoId.get(ar.ServiceAppointmentId);
                if (woId != null) {
                    Boolean isCrewLike =
                        ar.ServiceCrewId != null ||
                        (ar.ServiceResource != null &&
                            (ar.ServiceResource.ResourceType == 'Crew' ||
                             ar.ServiceResource.ResourceType == 'ServiceCrew' ||
                             String.valueOf(ar.ServiceResource.RelatedRecordId).startsWith('00G')));

                    if (isCrewLike) {
                        workOrdersWithCrewAssignment.add(woId);
                    } else {
                        Boolean hasSchedule = saHasSchedule.containsKey(ar.ServiceAppointmentId)
                            ? saHasSchedule.get(ar.ServiceAppointmentId)
                            : false;

                        if (hasSchedule) {
                            workOrdersWithNonCrewAssignment.add(woId);
                        }
                    }
                }
            }
        }

        // 4) Build DTOs only for Work Orders that:
        //    - are owned by the user
        //    - are not closed
        //    - are not already on this tech calendar (workOrdersWithThisTech)
        //    - do not have any open ServiceAppointment with an assigned individual resource
        //      (but allow ones already placed with a crew/queue so they can be picked up)
        for (WorkOrder wo : candidates) {
            if (workOrdersWithNonCrewAssignment.contains(wo.Id)) {
                // Already has an open Service Appointment with assigned resources
                // so it should not appear as needs scheduling
                continue;
            }

            UnscheduledWorkOrderDTO dto = new UnscheduledWorkOrderDTO();
            dto.workOrderId     = wo.Id;
            dto.workOrderNumber = wo.WorkOrderNumber;
            String workOrderOpportunityName =
                (wo.Opportunity__r != null) ? wo.Opportunity__r.Name : null;
            dto.subject         = String.isBlank(workOrderOpportunityName)
                ? wo.Subject
                : workOrderOpportunityName;
            dto.status          = wo.Status;
            dto.waitingForPoNumber = wo.Waiting_for_PO_Number__c;
            dto.workTypeName    = (wo.WorkType != null ? wo.WorkType.Name : null);
            dto.systemSerialNumber = wo.System_Serial_Number__c;
            dto.serviceSiteName = wo.Service_Site_Name__c;
            dto.lineItemSystem = wo.Line_Item_System__c;
            dto.poNumber = wo.PO_Number__c;
            dto.workOrderCreatedDate = wo.CreatedDate;
            dto.workOrderCreatedById = wo.CreatedById;
            dto.workOrderLastModifiedDate = wo.LastModifiedDate;
            dto.workOrderLastModifiedById = wo.LastModifiedById;
            dto.serviceAppointmentCount = saCountByWo.containsKey(wo.Id)
                ? saCountByWo.get(wo.Id)
                : 0;
            dto.visitScheduleDates = visitScheduleDatesByWo.containsKey(wo.Id)
                ? new List<Datetime>(visitScheduleDatesByWo.get(wo.Id))
                : new List<Datetime>();
            dto.visitAppointmentIds = visitAppointmentIdsByWo.containsKey(wo.Id)
                ? new List<Id>(visitAppointmentIdsByWo.get(wo.Id))
                : new List<Id>();
            dto.unscheduledServiceAppointmentCount =
                unscheduledSaCountByWo.containsKey(wo.Id)
                    ? unscheduledSaCountByWo.get(wo.Id)
                    : 0;
            dto.allServiceAppointmentsReturnRequired =
                allReturnRequiredByWo.containsKey(wo.Id)
                    ? allReturnRequiredByWo.get(wo.Id)
                    : false;
            dto.hasUnscheduledNonReturnAppointment =
                hasUnscheduledNonReturnByWo.containsKey(wo.Id)
                    ? hasUnscheduledNonReturnByWo.get(wo.Id)
                    : false;
            dto.hasAnyReturnVisitRequired = hasReturnRequiredByWo.containsKey(wo.Id) ? hasReturnRequiredByWo.get(wo.Id): false;
            dto.needsReturnVisitScheduling = latestSaReturnVisitByWo.containsKey(wo.Id) ? latestSaReturnVisitByWo.get(wo.Id) : false;
            dto.hasCrewAssignment = workOrdersWithCrewAssignment.contains(wo.Id);
            dto.accountId       = wo.AccountId;
            dto.accountName     = (wo.Account != null ? wo.Account.Name : null);
            dto.accountNameFreeText = (wo.AccountId != null)
                ? wo.Account_Name_Free_Text__c
                : wo.Service_Site_Name__c;
            dto.contactId       = wo.ContactId;
            dto.contactName = firstNonBlank(
                (wo.Contact != null) ? wo.Contact.Name : null,
                wo.Billing_Contact_Name__c
            );
            dto.contactPhone = firstNonBlank(
                (wo.Contact != null) ? wo.Contact.Phone : null,
                wo.Contact_Phone__c
            );
            dto.contactEmail = firstNonBlank(
                (wo.Contact != null) ? wo.Contact.Email : null,
                wo.Contact_Email__c
            );
            dto.opportunityRecordType = (wo.Opportunity__c != null &&
                opportunityRecordTypeByWo.containsKey(wo.Id))
                    ? opportunityRecordTypeByWo.get(wo.Id)
                    : null;
            dto.recordTypeName   = wo.RecordType != null ? wo.RecordType.Name : null;
            dto.workOrderTrackingNumber = wo.Tracking_Number__c;
            dto.billingType = wo.Billing_Type__c;
            dto.opportunityTrackingNumber = (wo.Opportunity__r != null)
                ? wo.Opportunity__r.Tracking__c
                : null;
            dto.opportunityNumber = (wo.Opportunity__r != null)
                ? wo.Opportunity__r.Opportunity_Number__c
                : null;
            dto.opportunityStage = (wo.Opportunity__r != null)
                ? wo.Opportunity__r.StageName
                : null;
            dto.dateProbeReceivedForRepairEval =
                wo.Date_Probe_Received_for_Repair_Eval__c;
            dto.dateQuoteSentToCustomer = wo.Date_Quote_Sent_to_Customer__c;
            dto.nextServiceDate = wo.Next_Service_Date__c;
            dto.completedVisitCount = completedVisitsByWo.containsKey(wo.Id)
                ? completedVisitsByWo.get(wo.Id)
                : 0;
            dto.hasQuoteAttachment =
                workOrdersWithAttachment != null &&
                workOrdersWithAttachment.contains(wo.Id);
            dto.quoteAttachmentDownloadUrl = (wo.Id != null &&
                quoteDownloadByWo != null && quoteDownloadByWo.containsKey(wo.Id))
                    ? quoteDownloadByWo.get(wo.Id)
                    : null;
            dto.quoteAttachmentDocumentId = (wo.Id != null &&
                quoteDocIdByWo != null && quoteDocIdByWo.containsKey(wo.Id))
                    ? quoteDocIdByWo.get(wo.Id)
                    : null;
            dto.makeModel        = wo.Make_Model__c;
            dto.reporterContactInfo = wo.Reporter_Contact_Info__c;
            dto.description      = wo.Description;
            dto.street          = wo.Street;
            dto.city            = wo.City;
            dto.state           = wo.State;
            dto.postalCode      = wo.PostalCode;
            dto.country         = wo.Country;
            dto.shippingAttn    = wo.Attn__c;
            dto.shippingSiteName = firstNonBlank(
                wo.Shipping_Site_Name__c,
                wo.Service_Site_Name__c
            );
            dto.shippingStreet  = wo.Shipping_Street__c;
            dto.shippingCity    = wo.Shipping_City__c;
            dto.shippingState   = wo.Shipping_State__c;
            dto.shippingPostalCode = wo.Shipping_Postal_Code__c;
            dto.shippingCountry = wo.Shipping_Country__c;
            dto.latestServiceAppointmentTrackingNumber =
                latestSaTrackingNumberByWo.containsKey(wo.Id)
                    ? latestSaTrackingNumberByWo.get(wo.Id)
                    : null;
            dto.loanerTrackingNumber = (wo.Loaner_Needed__c == 'w/ Loaner' &&
                latestLoanerTrackingByWo.containsKey(wo.Id))
                    ? latestLoanerTrackingByWo.get(wo.Id)
                    : null;
            dtos.add(dto);
        }

        return dtos;
    }

    private static void assignQuoteLineItems(
        List<AppointmentDTO> appointments,
        List<UnscheduledWorkOrderDTO> unscheduledWorkOrders
    ) {
        Set<Id> woIds = new Set<Id>();

        if (appointments != null) {
            for (AppointmentDTO dto : appointments) {
                if (dto != null && dto.workOrderId != null) {
                    woIds.add(dto.workOrderId);
                }
            }
        }

        if (unscheduledWorkOrders != null) {
            for (UnscheduledWorkOrderDTO dto : unscheduledWorkOrders) {
                if (dto != null && dto.workOrderId != null) {
                    woIds.add(dto.workOrderId);
                }
            }
        }

        if (woIds.isEmpty()) {
            return;
        }

        Map<Id, List<QuoteLineItemDTO>> quoteLineItemsByWo =
            fetchQuoteLineItems(woIds);

        if (appointments != null) {
            for (AppointmentDTO dto : appointments) {
                Id woId = dto != null ? dto.workOrderId : null;
                dto.quoteLineItems =
                    (woId != null && quoteLineItemsByWo.containsKey(woId))
                        ? quoteLineItemsByWo.get(woId)
                        : new List<QuoteLineItemDTO>();
            }
        }

        if (unscheduledWorkOrders != null) {
            for (UnscheduledWorkOrderDTO dto : unscheduledWorkOrders) {
                Id woId = dto != null ? dto.workOrderId : null;
                dto.quoteLineItems =
                    (woId != null && quoteLineItemsByWo.containsKey(woId))
                        ? quoteLineItemsByWo.get(woId)
                        : new List<QuoteLineItemDTO>();
            }
        }
    }

    private static Map<Id, List<QuoteLineItemDTO>> fetchQuoteLineItems(
        Set<Id> workOrderIds
    ) {
        Map<Id, List<QuoteLineItemDTO>> itemsByWo =
            new Map<Id, List<QuoteLineItemDTO>>();

        if (workOrderIds == null || workOrderIds.isEmpty()) {
            return itemsByWo;
        }

        for (WorkOrderLineItem woli : [
            SELECT Id,
                WorkOrderId,
                Line_Type__c,
                Product2.Name,
            	Part_Name_D__c,
                Description,
                Quantity,
                UnitPrice,
                Tracking__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :workOrderIds
            AND Line_Type__c NOT IN (
                'Labor',
                'Travel'
            )
        ]) {
            if (woli.WorkOrderId == null) continue;

            if (!itemsByWo.containsKey(woli.WorkOrderId)) {
                itemsByWo.put(woli.WorkOrderId, new List<QuoteLineItemDTO>());
            }

            QuoteLineItemDTO dto = new QuoteLineItemDTO();
            dto.lineItemId = woli.Id;
            dto.workOrderId = woli.WorkOrderId;
            dto.productName = woli.Part_Name_D__c;
            dto.description = woli.Description;
            dto.quantity = woli.Quantity;
            dto.unitPrice = woli.UnitPrice;
            dto.lineType = woli.Line_Type__c;
            dto.trackingNumber = woli.Tracking__c;

            itemsByWo.get(woli.WorkOrderId).add(dto);
        }

        return itemsByWo;
    }




    @AuraEnabled
    public static void rescheduleAppointment(Id appointmentId, Datetime newStart) {
        if (appointmentId == null || newStart == null) {
            throw new AuraHandledException('Appointment ID and new start time are required.');
        }

        ServiceAppointment sa = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            LIMIT 1
            FOR UPDATE
        ];

        Datetime oldStart = sa.SchedStartTime;
        Datetime oldEnd   = sa.SchedEndTime;

        Long durationMs;
        if (oldStart != null && oldEnd != null) {
            durationMs = oldEnd.getTime() - oldStart.getTime();
        } else {
            durationMs = 60L * 60L * 1000L; // 1 hour default
        }

        sa.SchedStartTime = newStart;
        sa.SchedEndTime   = Datetime.newInstance(newStart.getTime() + durationMs);
        sa.Status         = 'Dispatched';

        update sa;
    }

    @AuraEnabled
    public static void updateAppointmentEnd(Id appointmentId, Datetime newEnd) {
        if (appointmentId == null || newEnd == null) {
            throw new AuraHandledException('Appointment ID and new end time are required.');
        }

        ServiceAppointment sa = [
            SELECT Id, SchedStartTime
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            LIMIT 1
            FOR UPDATE
        ];

        Datetime startTime = sa.SchedStartTime;

        if (startTime != null && newEnd.getTime() <= startTime.getTime()) {
            // Enforce a minimum 15-minute duration
            newEnd = Datetime.newInstance(startTime.getTime() + (15 * 60 * 1000));
        }

        sa.SchedEndTime = newEnd;
        update sa;
    }

    @AuraEnabled
    public static void assignCrewAppointment(Id serviceAppointmentId, Id serviceResourceId) {
        if (serviceAppointmentId == null || serviceResourceId == null) {
            throw new AuraHandledException('Service Appointment and Service Resource are required.');
        }

        ServiceAppointment sa = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            FOR UPDATE
        ];

        Datetime originalStart = sa.SchedStartTime;
        Datetime originalEnd   = sa.SchedEndTime;

        if (originalStart == null || originalEnd == null) {
            throw new AuraHandledException(
                'This appointment is not currently scheduled. Please schedule it before assigning.'
            );
        }

        List<AssignedResource> existingArs = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :serviceAppointmentId
            FOR UPDATE
        ];

        if (!existingArs.isEmpty()) {
            delete existingArs;
        }

        ServiceAppointment saUpdate = new ServiceAppointment(
            Id = sa.Id,
            SchedStartTime = originalStart,
            SchedEndTime   = originalEnd
        );
        update saUpdate;

        AssignedResource newAr = new AssignedResource(
            ServiceAppointmentId = serviceAppointmentId,
            ServiceResourceId    = serviceResourceId
        );
        insert newAr;
    }

    /**
     * Create a new Service Appointment from an owned Work Order at the given start time,
     * and assign it to the current user's ServiceResource.
     */
    @AuraEnabled
    public static Id createAppointmentForWorkOrder(
        Id workOrderId,
        Datetime startDateTimeIso,
        Datetime endDateTimeIso,
        Id targetUserId
    ) {
        if (workOrderId == null || startDateTimeIso == null) {
            throw new AuraHandledException('Work Order and start date/time are required.');
        }

        Id owningUserId = (targetUserId != null)
            ? targetUserId
            : UserInfo.getUserId();

        // Current user's ServiceResource
        ServiceResource sr = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :owningUserId
            LIMIT 1
        ];

        WorkOrder wo = [
            SELECT Id,
                   Subject,
                   AccountId,
                   Street,
                   City,
                   State,
                   PostalCode,
                   Country
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        Integer durationMs = 6 * 60 * 60 * 1000; // 6 hour default
        if (endDateTimeIso != null && endDateTimeIso.getTime() > startDateTimeIso.getTime()) {
            durationMs = Integer.valueOf(endDateTimeIso.getTime() - startDateTimeIso.getTime());
        }

        ServiceAppointment sa = new ServiceAppointment(
            Work_Order__c  = wo.Id,
            Subject        = wo.Subject,
            Street         = wo.Street,
            City           = wo.City,
            State          = wo.State,
            PostalCode     = wo.PostalCode,
            Country        = wo.Country,
            ParentRecordId = wo.Id,
            Status         = 'New'
        );
        insert sa;

        Datetime endDateTime = startDateTimeIso.addSeconds(durationMs / 1000);

        ServiceAppointment saTimeUpdate = new ServiceAppointment(
            Id              = sa.Id,
            SchedStartTime  = startDateTimeIso,
            SchedEndTime    = endDateTime,
            Status          = 'Scheduled'
        );
        update saTimeUpdate;

        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId    = sr.Id
        );
        insert ar;

        ServiceAppointment saStatusUpdate = new ServiceAppointment(
            Id      = sa.Id,
            Status  = 'Dispatched'
        );
        update saStatusUpdate;

        return sa.Id;
    }

    @AuraEnabled
    public static void unassignAppointment(Id appointmentId) {
        if (appointmentId == null) {
            throw new AuraHandledException('Appointment ID is required.');
        }

        List<AssignedResource> ars = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointmentId
            FOR UPDATE
        ];

        if (!ars.isEmpty()) {
            delete ars;
        }

        ServiceAppointment sa = new ServiceAppointment(Id = appointmentId);
        delete sa;
    }

    @AuraEnabled
    public static void updateResourceAbsence(
        Id absenceId,
        Datetime startDateTimeIso,
        Datetime endDateTimeIso
    ) {
        if (absenceId == null) {
            throw new AuraHandledException('Absence ID is required.');
        }

        if (startDateTimeIso == null || endDateTimeIso == null) {
            throw new AuraHandledException('Start and End date/time are required.');
        }

        if (endDateTimeIso.getTime() <= startDateTimeIso.getTime()) {
            throw new AuraHandledException('End time must be after start time.');
        }

        ResourceAbsence ra = [
            SELECT Id
            FROM ResourceAbsence
            WHERE Id = :absenceId
            LIMIT 1
            FOR UPDATE
        ];

        ra = new ResourceAbsence(
            Id = ra.Id,
            Start = startDateTimeIso,
            End = endDateTimeIso
        );

        update ra;
    }

    @AuraEnabled
    public static void deleteResourceAbsence(Id absenceId) {
        if (absenceId == null) {
            throw new AuraHandledException('Absence ID is required.');
        }

        ResourceAbsence ra = [
            SELECT Id
            FROM ResourceAbsence
            WHERE Id = :absenceId
            LIMIT 1
            FOR UPDATE
        ];

        delete ra;
    }

    @AuraEnabled
    public static AddressUpdateResult updateWorkOrderAddress(
        Id workOrderId,
        Id serviceAppointmentId,
        String street,
        String city,
        String state,
        String postalCode,
        String country
    ) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String cleanStreet = String.isNotBlank(street) ? street.trim() : '';
        String cleanCity = String.isNotBlank(city) ? city.trim() : '';
        String cleanState = String.isNotBlank(state) ? state.trim() : '';
        String cleanPostal = String.isNotBlank(postalCode) ? postalCode.trim() : '';
        String cleanCountry = String.isNotBlank(country)
            ? country.trim()
            : 'United States';

        if (String.isBlank(cleanStreet) || String.isBlank(cleanCity) ||
            String.isBlank(cleanState) || String.isBlank(cleanPostal) ||
            String.isBlank(cleanCountry)) {
            throw new AuraHandledException(
                'Street, City, State, Postal Code, and Country are required to schedule.'
            );
        }

        String translatedState = translateStateAbbreviation(cleanState);

        WorkOrder wo = [
            SELECT Id
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo = new WorkOrder(
            Id = wo.Id,
            Street = cleanStreet,
            City = cleanCity,
            State = translatedState,
            PostalCode = cleanPostal,
            Country = cleanCountry
        );

        update wo;

        if (serviceAppointmentId != null) {
            ServiceAppointment sa = [
                SELECT Id
                FROM ServiceAppointment
                WHERE Id = :serviceAppointmentId
                LIMIT 1
                FOR UPDATE
            ];

            sa = new ServiceAppointment(
                Id = sa.Id,
                Street = cleanStreet,
                City = cleanCity,
                State = translatedState,
                PostalCode = cleanPostal,
                Country = cleanCountry
            );

            update sa;
        }

        List<String> parts = new List<String>();
        for (String part : new List<String>{ cleanStreet, cleanCity, translatedState, cleanPostal, cleanCountry }) {
            if (String.isNotBlank(part)) {
                parts.add(part);
            }
        }

        AddressUpdateResult result = new AddressUpdateResult();
        result.workOrderId = workOrderId;
        result.serviceAppointmentId = serviceAppointmentId;
        result.street = cleanStreet;
        result.city = cleanCity;
        result.state = translatedState;
        result.postalCode = cleanPostal;
        result.country = cleanCountry;
        result.fullAddress = String.join(parts, ', ');

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<AddressBookEntry> getUserAddressBook() {
        String userName = UserInfo.getName();

        if (String.isBlank(userName)) {
            return new List<AddressBookEntry>();
        }

        List<SObject> locations = [
            SELECT Id, Name
            FROM Location
            WHERE Name = :userName
        ];
        
        if (locations.isEmpty()) {
            return new List<AddressBookEntry>();
        }
        
        Id locationId = (Id) locations[0].get('Id');

        if (locations.isEmpty()) {
            return new List<AddressBookEntry>();
        }

        List<SObject> addresses = [
            SELECT Id,
                   ParentId,
                   Name__c,
                   Street,
                   City,
                   State,
                   StateCode,
                   Country,
                   CountryCode,
                   PostalCode
            FROM Address
            WHERE ParentId = :locationId
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
        
        List<AddressBookEntry> results = new List<AddressBookEntry>();
        
        for (SObject addr : addresses) {
            AddressBookEntry entry = new AddressBookEntry();
        
            entry.addressId   = (Id)     addr.get('Id');
            entry.locationId  = (Id)     addr.get('ParentId');
            entry.name        = (String) addr.get('Name__c');
            entry.street      = (String) addr.get('Street');
            entry.city        = (String) addr.get('City');
            entry.state       = (String) addr.get('State');
            entry.stateCode   = (String) addr.get('StateCode');
            entry.country     = (String) addr.get('Country');
            entry.countryCode = (String) addr.get('CountryCode');
            entry.postalCode  = (String) addr.get('PostalCode');
        
            results.add(entry);
        }
        
        return results;
    }

    @AuraEnabled
    public static AddressUpdateResult updateWorkOrderShippingAddress(
        Id workOrderId,
        Id serviceAppointmentId,
        Id locationId,
        Id addressId,
        String attn,
        String shippingSiteName,
        String street,
        String city,
        String state,
        String postalCode,
        String country,
        String countryCode
    ) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String cleanAttn = String.isNotBlank(attn) ? attn.trim() : '';
        String cleanShippingSiteName = String.isNotBlank(shippingSiteName)
            ? shippingSiteName.trim()
            : '';
        String cleanStreet = String.isNotBlank(street) ? street.trim() : '';
        String cleanCity = String.isNotBlank(city) ? city.trim() : '';
        String cleanState = String.isNotBlank(state) ? state.trim().toUpperCase() : '';
        String cleanPostal = String.isNotBlank(postalCode) ? postalCode.trim() : '';
        String cleanCountry = String.isNotBlank(country) ? country.trim() : '';
        String cleanCountryCode = String.isNotBlank(countryCode)
            ? countryCode.trim()
            : cleanCountry;

        if (String.isBlank(cleanStreet) || String.isBlank(cleanCity) ||
            String.isBlank(cleanState) || String.isBlank(cleanPostal) ||
            (String.isBlank(cleanCountry) && String.isBlank(cleanCountryCode))) {
            throw new AuraHandledException(
                'Street, City, State, Postal Code, and Country are required to ship.'
            );
        }

        translateStateAbbreviation(cleanState);

        WorkOrder wo = [
            SELECT Id, Service_Site_Name__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        String normalizedShippingSiteName = String.isNotBlank(cleanShippingSiteName)
            ? cleanShippingSiteName
            : wo.Service_Site_Name__c;

        wo = new WorkOrder(
            Id = wo.Id,
            Attn__c = cleanAttn,
            Shipping_Site_Name__c = normalizedShippingSiteName,
            Shipping_Street__c = cleanStreet,
            Shipping_City__c = cleanCity,
            Shipping_State__c = cleanState,
            Shipping_Postal_Code__c = cleanPostal,
            Shipping_Country__c = String.isNotBlank(cleanCountry) ? cleanCountry : cleanCountryCode,
            Shipping_Location__c = locationId,
            Shipping_Address__c = addressId
        );

        update wo;

        if (serviceAppointmentId != null) {
            ServiceAppointment sa = [
                SELECT Id
                FROM ServiceAppointment
                WHERE Id = :serviceAppointmentId
                LIMIT 1
                FOR UPDATE
            ];

            sa = new ServiceAppointment(
                Id = sa.Id,
                Shipping_Address__Street__s = cleanStreet,
                Shipping_Address__City__s = cleanCity,
                Shipping_Address__StateCode__s = cleanState,
                Shipping_Address__CountryCode__s = cleanCountryCode,
                Shipping_Address__PostalCode__s = cleanPostal,
                Shipping_Location__c = locationId,
                Ship_to_Address__c = addressId
            );

            update sa;
        }

        List<String> parts = new List<String>();
        for (String part : new List<String>{ cleanStreet, cleanCity, cleanState, cleanPostal, cleanCountry }) {
            if (String.isNotBlank(part)) {
                parts.add(part);
            }
        }

        AddressUpdateResult result = new AddressUpdateResult();
        result.workOrderId = workOrderId;
        result.serviceAppointmentId = serviceAppointmentId;
        result.shippingAttn = cleanAttn;
        result.shippingSiteName = normalizedShippingSiteName;
        result.shippingStreet = cleanStreet;
        result.shippingCity = cleanCity;
        result.shippingState = cleanState;
        result.shippingPostalCode = cleanPostal;
        result.shippingCountry = String.isNotBlank(cleanCountry) ? cleanCountry : cleanCountryCode;
        result.fullAddress = String.join(parts, ', ');

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getStateAbbreviation(String stateName) {
        String cleanName = String.isNotBlank(stateName) ? stateName.trim() : '';

        if (String.isBlank(cleanName)) {
            return '';
        }

        if (cleanName.length() == 2) {
            return cleanName.toUpperCase();
        }

        List<StateTranslation__mdt> translations = [
            SELECT State_Abbreviation__c
            FROM StateTranslation__mdt
            WHERE State_Name__c = :cleanName
            LIMIT 1
        ];

        if (translations.isEmpty() ||
            String.isBlank(translations[0].State_Abbreviation__c)) {
            return '';
        }

        return translations[0].State_Abbreviation__c.trim().toUpperCase();
    }

    @AuraEnabled
    public static AccountNameUpdateResult updateWorkOrderAccountName(
        Id workOrderId,
        String accountName
    ) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String cleanName = String.isNotBlank(accountName)
            ? accountName.trim()
            : '';

        if (String.isBlank(cleanName)) {
            throw new AuraHandledException('Account name is required.');
        }

        WorkOrder wo = [
            SELECT Id, AccountId
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        if (wo.AccountId != null) {
            throw new AuraHandledException(
                'An account is already associated with this work order.'
            );
        }

        wo = new WorkOrder(
            Id = wo.Id,
            Account_Name_Free_Text__c = cleanName
        );

        update wo;

        AccountNameUpdateResult result = new AccountNameUpdateResult();
        result.workOrderId = wo.Id;
        result.accountNameFreeText = cleanName;
        return result;
    }

    @AuraEnabled
    public static ReporterContactUpdateResult updateWorkOrderReporterContactInfo(
        Id workOrderId,
        String reporterContactInfo
    ) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String cleanReporter = String.isNotBlank(reporterContactInfo)
            ? reporterContactInfo.trim()
            : '';

        if (String.isBlank(cleanReporter)) {
            throw new AuraHandledException('Reporter contact info is required.');
        }

        WorkOrder wo = [
            SELECT Id,
                ContactId,
                Contact.Name,
                Contact.Phone,
                Contact.Email,
                Reporter_Contact_Info__c,
                Billing_Contact_Name__c,
                Contact_Phone__c,
                Contact_Email__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        if (wo.ContactId != null) {
            throw new AuraHandledException(
                'Reporter contact info can only be added when no contact is set.'
            );
        }

        ReporterContactDetails parsedReporter = parseReporterContactInfo(cleanReporter);
        String nextBillingName = String.isNotBlank(parsedReporter.name)
            ? parsedReporter.name
            : wo.Billing_Contact_Name__c;
        String nextBillingPhone = String.isNotBlank(parsedReporter.phone)
            ? parsedReporter.phone
            : wo.Contact_Phone__c;
        String nextBillingEmail = String.isNotBlank(parsedReporter.email)
            ? parsedReporter.email
            : wo.Contact_Email__c;

        wo = new WorkOrder(
            Id = wo.Id,
            Reporter_Contact_Info__c = cleanReporter,
            Billing_Contact_Name__c = nextBillingName,
            Contact_Phone__c = nextBillingPhone,
            Contact_Email__c = nextBillingEmail
        );

        update wo;

        ReporterContactUpdateResult result = new ReporterContactUpdateResult();
        result.workOrderId = wo.Id;
        result.reporterContactInfo = cleanReporter;
        result.contactName = firstNonBlank(
            (wo.Contact != null) ? wo.Contact.Name : null,
            nextBillingName
        );
        result.contactPhone = firstNonBlank(
            (wo.Contact != null) ? wo.Contact.Phone : null,
            nextBillingPhone
        );
        result.contactEmail = firstNonBlank(
            (wo.Contact != null) ? wo.Contact.Email : null,
            nextBillingEmail
        );
        return result;
    }

    private class ReporterContactDetails {
        public String name;
        public String phone;
        public String email;
    }

    private static ReporterContactDetails parseReporterContactInfo(String reporterContactInfo) {
        ReporterContactDetails details = new ReporterContactDetails();
        if (String.isBlank(reporterContactInfo)) {
            return details;
        }

        String raw = reporterContactInfo.trim();
        Pattern emailPattern = Pattern.compile(
            '(?i)([A-Z0-9._%+\\-]+@[A-Z0-9.\\-]+\\.[A-Z]{2,})'
        );
        Matcher emailMatcher = emailPattern.matcher(raw);
        if (emailMatcher.find()) {
            details.email = emailMatcher.group(1);
            raw = raw.replace(emailMatcher.group(1), ' ');
        }

        Pattern phonePattern = Pattern.compile('(\\+?[0-9][0-9()\\-\\.\\s]{6,}[0-9])');
        Matcher phoneMatcher = phonePattern.matcher(raw);
        if (phoneMatcher.find()) {
            details.phone = phoneMatcher.group(1).trim();
            raw = raw.replace(phoneMatcher.group(1), ' ');
        }

        String remaining = raw.replace('|', ' ')
            .replace(',', ' ')
            .replace(';', ' ')
            .replace(':', ' ')
            .trim();
        details.name = String.isNotBlank(remaining) ? remaining : null;
        return details;
    }

    private static String firstNonBlank(String preferred, String fallback) {
        return String.isNotBlank(preferred) ? preferred : fallback;
    }

    @AuraEnabled
    public static PoNumberUpdateResult updateWorkOrderPoNumber(
        Id workOrderId,
        String poNumber
    ) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String cleanPoNumber = String.isNotBlank(poNumber)
            ? poNumber.trim()
            : '';

        if (String.isBlank(cleanPoNumber)) {
            throw new AuraHandledException('PO Number is required.');
        }

        WorkOrder wo = [
            SELECT Id, Opportunity__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        List<SObject> toUpdate = new List<SObject>{
            new WorkOrder(
                Id = wo.Id,
                PO_Number__c = cleanPoNumber
            )
        };

        if (wo.Opportunity__c != null) {
            toUpdate.add(new Opportunity(
                Id = wo.Opportunity__c,
                Customer_PO__c = cleanPoNumber
            ));
        }

        update toUpdate;

        PoNumberUpdateResult result = new PoNumberUpdateResult();
        result.workOrderId = wo.Id;
        result.opportunityId = wo.Opportunity__c;
        result.poNumber = cleanPoNumber;
        return result;
    }

    @AuraEnabled
    public static String updateWorkOrderServiceSiteName(Id workOrderId, String serviceSiteName) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }
        String cleanName = String.isNotBlank(serviceSiteName) ? serviceSiteName.trim() : '';
        update new WorkOrder(Id = workOrderId, Service_Site_Name__c = cleanName);
        return cleanName;
    }

    @TestVisible
    private static String translateStateAbbreviation(String stateAbbreviation) {
        String cleanAbbreviation = String.isNotBlank(stateAbbreviation)
            ? stateAbbreviation.trim().toUpperCase()
            : '';

        if (String.isBlank(cleanAbbreviation)) {
            return cleanAbbreviation;
        }

        if (cleanAbbreviation.length() != 2) {
            throw new AuraHandledException('Please enter the two-letter state abbreviation.');
        }

        List<StateTranslation__mdt> translations = [
            SELECT State_Name__c
            FROM StateTranslation__mdt
            WHERE State_Abbreviation__c = :cleanAbbreviation
            LIMIT 1
        ];

        if (translations.isEmpty() || String.isBlank(translations[0].State_Name__c)) {
            throw new AuraHandledException('State abbreviation "' + cleanAbbreviation + '" is not recognized.');
        }

        return translations[0].State_Name__c;
    }

    @AuraEnabled
    public static List<ServiceResourceOption> getTerritoryResources(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, ServiceTerritoryId
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        if (wo.ServiceTerritoryId == null) {
            return new List<ServiceResourceOption>();
        }

        List<ServiceResourceOption> options = new List<ServiceResourceOption>();
        for (ServiceTerritoryMember stm : [
            SELECT Id, ServiceResourceId, ServiceResource.Name
                , ServiceResource.RelatedRecordId
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId = :wo.ServiceTerritoryId
            AND EffectiveStartDate != null
            AND EffectiveStartDate <= :Date.today()
            AND (EffectiveEndDate = null OR EffectiveEndDate >= :Date.today())
            ORDER BY ServiceResource.Name
        ]) {
            if (stm.ServiceResourceId == null) continue;

            // Only include resources that are linked to a User (not crews/queues)
            Id relatedId = (stm.ServiceResource != null)
                ? stm.ServiceResource.RelatedRecordId
                : null;

            if (relatedId == null || relatedId.getSObjectType() != User.sObjectType) {
                continue;
            }

            ServiceResourceOption opt = new ServiceResourceOption();
            opt.serviceResourceId = stm.ServiceResourceId;
            opt.name = (stm.ServiceResource != null) ? stm.ServiceResource.Name : null;
            opt.userId = relatedId;
            options.add(opt);
        }

        return options;
    }

    @AuraEnabled
    public static void requestRescheduleToResource(
        Id workOrderId,
        Id serviceResourceId
    ) {
        if (workOrderId == null || serviceResourceId == null) {
            throw new AuraHandledException(
                'Work Order and Service Resource are required to request a reschedule.'
            );
        }

        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE Id = :serviceResourceId
            LIMIT 1
        ];

        WorkOrder wo = [
            SELECT Id, OwnerId
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        if (sr.RelatedRecordId != null) {
            wo.OwnerId = sr.RelatedRecordId;
            update wo;
        }

        Set<String> closedStatuses = new Set<String>{
            'Completed',
            'Completed WO',
            'Closed',
            'Cannot Complete',
            'Canceled',
            'Closed - Submitted'
        };

        List<ServiceAppointment> openAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Work_Order__c = :workOrderId
            AND Status NOT IN :closedStatuses
            FOR UPDATE
        ];

        if (openAppointments.isEmpty()) {
            return;
        }

        Set<Id> openApptIds = new Set<Id>();
        for (ServiceAppointment sa : openAppointments) {
            openApptIds.add(sa.Id);
        }

        List<AssignedResource> ars = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :openApptIds
        ];

        if (!ars.isEmpty()) {
            delete ars;
        }

        for (ServiceAppointment sa : openAppointments) {
            sa.Status = 'Canceled';
            sa.SchedStartTime = null;
            sa.SchedEndTime = null;
        }

        update openAppointments;
    }

    @AuraEnabled
    public static void cancelWorkOrder(Id workOrderId, String reason) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required to cancel.');
        }

        String trimmedReason = (reason == null) ? '' : reason.trim();
        if (String.isBlank(trimmedReason)) {
            throw new AuraHandledException('Cancellation reason is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status, Tech_Support_Notes__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Canceled';
        wo.Tech_Support_Notes__c = trimmedReason;
        update wo;

        Set<String> closedStatuses = new Set<String>{
            'Completed',
            'Completed WO',
            'Closed',
            'Cannot Complete',
            'Canceled',
            'Closed - Submitted'
        };

        List<ServiceAppointment> openAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Work_Order__c = :workOrderId
            AND Status NOT IN :closedStatuses
            FOR UPDATE
        ];

        if (openAppointments.isEmpty()) {
            return;
        }

        Set<Id> openApptIds = new Set<Id>();
        for (ServiceAppointment sa : openAppointments) {
            openApptIds.add(sa.Id);
            sa.Status = 'Canceled';
            sa.SchedStartTime = null;
            sa.SchedEndTime = null;
        }

        List<AssignedResource> ars = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :openApptIds
        ];

        if (!ars.isEmpty()) {
            delete ars;
        }

        update openAppointments;
    }

    @AuraEnabled
    public static void markWorkOrderReadyForClose(Id workOrderId, String notes) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status, Tech_Support_Notes__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        String trimmedNotes = (notes == null) ? '' : notes.trim();

        wo.Status = 'Ready for Close';

        if (!String.isBlank(trimmedNotes)) {
            if (String.isBlank(wo.Tech_Support_Notes__c)) {
                wo.Tech_Support_Notes__c = trimmedNotes;
            } else {
                wo.Tech_Support_Notes__c = String.join(new List<String>{
                    wo.Tech_Support_Notes__c,
                    'Ready for Close Notes: ' + trimmedNotes
                }, '\n\n');
            }
        }

        update wo;
    }

    @AuraEnabled
    public static void submitCustomWorkOrderRequest(Id workOrderId, String notes) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        String trimmedNotes = (notes == null) ? '' : notes.trim();
        if (String.isBlank(trimmedNotes)) {
            throw new AuraHandledException('Custom request notes are required.');
        }

        WorkOrder wo = [
            SELECT Id, Status, Work_Order_Notes__c, Opportunity__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Update Needed';
        wo.Work_Order_Notes__c = trimmedNotes;
        update wo;

        if (wo.Opportunity__c != null) {
            Opportunity opp = [
                SELECT Id, Rep_Notes__c
                FROM Opportunity
                WHERE Id = :wo.Opportunity__c
                LIMIT 1
                FOR UPDATE
            ];
            opp.Rep_Notes__c = trimmedNotes;
            update opp;
        }
    }

    @AuraEnabled
    public static List<LineItemForReturnDTO> getWorkOrderLineItemsForReturn(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }
        List<LineItemForReturnDTO> items = new List<LineItemForReturnDTO>();
        for (WorkOrderLineItem woli : [
            SELECT Id, Part_Name_D__c, Serial_No_D__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :workOrderId
            AND Line_Type__c NOT IN ('Labor', 'Travel')
        ]) {
            LineItemForReturnDTO dto = new LineItemForReturnDTO();
            dto.lineItemId = woli.Id;
            dto.partName = woli.Part_Name_D__c;
            dto.serialNumber = woli.Serial_No_D__c;
            items.add(dto);
        }
        return items;
    }

    @AuraEnabled
    public static void markWorkOrderItemsForReturn(Id workOrderId, String itemsJson) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }
        if (String.isBlank(itemsJson)) {
            throw new AuraHandledException('Return items are required.');
        }

        List<Object> rawItems = (List<Object>) JSON.deserializeUntyped(itemsJson);

        String noteBody = 'The following items need to be returned:\n\n';
        for (Object rawItem : rawItems) {
            Map<String, Object> itemMap = (Map<String, Object>) rawItem;
            String partName = (String) itemMap.get('partName');
            String serialNumber = (String) itemMap.get('serialNumber');
            String reason = (String) itemMap.get('reason');

            String line = '';
            if (String.isNotBlank(partName)) {
                line += partName;
            }
            if (String.isNotBlank(serialNumber)) {
                line += ' (Serial: ' + serialNumber + ')';
            }
            if (String.isNotBlank(reason)) {
                line += ' - ' + reason;
            }
            noteBody += '• ' + line + '\n';
        }

        WorkOrder wo = [
            SELECT Id, Status, Work_Order_Notes__c, Opportunity__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Update Needed';
        wo.Work_Order_Notes__c = noteBody;
        update wo;

        if (wo.Opportunity__c != null) {
            Opportunity opp = [
                SELECT Id, Rep_Notes__c
                FROM Opportunity
                WHERE Id = :wo.Opportunity__c
                LIMIT 1
                FOR UPDATE
            ];
            opp.Rep_Notes__c = noteBody;
            update opp;
        }
    }

    @AuraEnabled
    public static void markWorkOrderQuoteSent(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Quote Sent';
        wo.Date_Quote_Sent_to_Customer__c = Date.today();
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderPendingApproval(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Pending Approval';
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderPoAttached(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Ready to Ship';
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderWaitingForPo(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Waiting_for_PO_Number__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Waiting_for_PO_Number__c = true;
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderRepairApproved(Id workOrderId, String notes) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status, Work_Order_Notes__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Repair Approved';
        if (String.isNotBlank(notes)) {
            wo.Work_Order_Notes__c = notes.trim();
        }
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderExchangeApproved(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Exchange Approved';
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderRepairDeclined(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Repair Declined';
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderConfirmedShipping(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Ready to Ship';
        update wo;
    }

    @AuraEnabled
    public static void markWorkOrderCancelSale(Id workOrderId, String notes) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }
        if (String.isBlank(notes)) {
            throw new AuraHandledException('A reason for canceling the sale is required.');
        }

        WorkOrder wo = [
            SELECT Id, Status, Work_Order_Notes__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
            FOR UPDATE
        ];

        wo.Status = 'Cancel Sale';
        wo.Work_Order_Notes__c = notes;
        update wo;
    }

    @AuraEnabled
    public static void createEngineerTransferRequest(
        Id workOrderId,
        Id targetUserId
    ) {
        if (workOrderId == null || targetUserId == null) {
            throw new AuraHandledException(
                'Work Order and target technician are required to submit a transfer request.'
            );
        }

        List<Engineer_Transfer_Request__c> existing = [
            SELECT Id
            FROM Engineer_Transfer_Request__c
            WHERE Work_Order_to_Transfer__c = :workOrderId
            AND Transfer_Work_Order_To_Engineer__c = :targetUserId
            AND Accepted_on__c = null
            AND Date_Rejected_On__c = null
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            return;
        }

        Engineer_Transfer_Request__c req = new Engineer_Transfer_Request__c();
        req.Work_Order_to_Transfer__c = workOrderId;
        req.Transfer_Work_Order_To_Engineer__c = targetUserId;

        insert req;
    }

    @AuraEnabled
    public static void acceptEngineerTransferRequest(
        Id transferRequestId,
        Id targetOwnerId
    ) {
        if (transferRequestId == null) {
            throw new AuraHandledException('Transfer Request Id is required to accept.');
        }

        Engineer_Transfer_Request__c req = [
            SELECT Id,
                Work_Order_to_Transfer__c,
                Transfer_Work_Order_To_Engineer__c
            FROM Engineer_Transfer_Request__c
            WHERE Id = :transferRequestId
            LIMIT 1
            FOR UPDATE
        ];

        Id currentUserId = UserInfo.getUserId();
        Id targetUserId = req.Transfer_Work_Order_To_Engineer__c;

        if (currentUserId != targetUserId) {
            User targetUser = targetUserId != null
                ? [SELECT Id, ManagerId FROM User WHERE Id = :targetUserId LIMIT 1]
                : null;

            Boolean isManagerActingForTarget =
                targetUser != null && targetUser.ManagerId == currentUserId;

            if (!isManagerActingForTarget) {
                throw new AuraHandledException(
                    'You are not authorized to accept this request.'
                );
            }
        }

        req.Accepted_on__c = Datetime.now();
        req.Date_Rejected_On__c = null;
        req.Rejected_Reason__c = null;
        update req;

        if (req.Work_Order_to_Transfer__c == null) {
            return;
        }

        WorkOrder wo = [
            SELECT Id
            FROM WorkOrder
            WHERE Id = :req.Work_Order_to_Transfer__c
            LIMIT 1
            FOR UPDATE
        ];

        Id effectiveOwnerId = req.Transfer_Work_Order_To_Engineer__c != null
            ? req.Transfer_Work_Order_To_Engineer__c
            : currentUserId;

        if (targetOwnerId != null && targetOwnerId == req.Transfer_Work_Order_To_Engineer__c) {
            effectiveOwnerId = targetOwnerId;
        }

        wo.OwnerId = effectiveOwnerId;
        update wo;

        Set<String> closedStatuses = new Set<String>{
            'Completed',
            'Completed WO',
            'Closed',
            'Cannot Complete',
            'Canceled',
            'Closed - Submitted'
        };

        List<ServiceAppointment> openAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Work_Order__c = :req.Work_Order_to_Transfer__c
            AND Status NOT IN :closedStatuses
            FOR UPDATE
        ];

        if (openAppointments.isEmpty()) {
            return;
        }

        Set<Id> openApptIds = new Set<Id>();
        for (ServiceAppointment sa : openAppointments) {
            openApptIds.add(sa.Id);
        }

        List<AssignedResource> ars = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :openApptIds
        ];

        if (!ars.isEmpty()) {
            delete ars;
        }

        for (ServiceAppointment sa : openAppointments) {
            sa.Status = 'Canceled';
            sa.SchedStartTime = null;
            sa.SchedEndTime = null;
        }

        update openAppointments;
    }

    @AuraEnabled
    public static void rejectEngineerTransferRequest(
        Id transferRequestId,
        String reason
    ) {
        if (transferRequestId == null) {
            throw new AuraHandledException('Transfer Request Id is required to reject.');
        }

        if (String.isBlank(reason)) {
            throw new AuraHandledException('A rejection reason is required.');
        }

        Engineer_Transfer_Request__c req = [
            SELECT Id,
                Transfer_Work_Order_To_Engineer__c
            FROM Engineer_Transfer_Request__c
            WHERE Id = :transferRequestId
            LIMIT 1
            FOR UPDATE
        ];

        Id currentUserId = UserInfo.getUserId();
        Id targetUserId = req.Transfer_Work_Order_To_Engineer__c;

        if (currentUserId != targetUserId) {
            User targetUser = targetUserId != null
                ? [SELECT Id, ManagerId FROM User WHERE Id = :targetUserId LIMIT 1]
                : null;

            Boolean isManagerActingForTarget =
                targetUser != null && targetUser.ManagerId == currentUserId;

            if (!isManagerActingForTarget) {
                throw new AuraHandledException(
                    'You are not authorized to reject this request.'
                );
            }
        }

        req.Date_Rejected_On__c = Datetime.now();
        req.Rejected_Reason__c = reason;
        req.Accepted_on__c = null;

        update req;
    }

    @AuraEnabled
    public static List<DeletedWoliDTO> getDeletedWorkOrderLineItems(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order Id is required.');
        }
        List<DeletedWoliDTO> items = new List<DeletedWoliDTO>();
        for (WorkOrderLineItem woli : [
            SELECT Id, Part_Name_D__c, Part_Number_D__c, Description, Quantity, Line_Type__c, Serial_No_D__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :workOrderId
            AND IsDeleted = true
            ALL ROWS
        ]) {
            DeletedWoliDTO dto = new DeletedWoliDTO();
            dto.lineItemId = woli.Id;
            dto.partName = woli.Part_Name_D__c;
            dto.partNumber = woli.Part_Number_D__c;
            dto.description = woli.Description;
            dto.quantity = woli.Quantity;
            dto.lineType = woli.Line_Type__c;
            dto.serialNumber = woli.Serial_No_D__c;
            items.add(dto);
        }
        return items;
    }

    @AuraEnabled
    public static void undeleteWorkOrderLineItems(List<Id> lineItemIds) {
        if (lineItemIds == null || lineItemIds.isEmpty()) {
            throw new AuraHandledException('At least one line item is required.');
        }
        List<WorkOrderLineItem> items = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE Id IN :lineItemIds
            AND IsDeleted = true
            ALL ROWS
        ];
        Database.undelete(items, false);
    }

    public class RmaDTO {
        @AuraEnabled public Id rmaId;
        @AuraEnabled public String rmaName;
        @AuraEnabled public String rmaType;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public Id workOrderId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String assetProductName;
        @AuraEnabled public String loanerProbeModel;
        @AuraEnabled public String rmaTracking;
        @AuraEnabled public String engineerRmaTracking;
        @AuraEnabled public Datetime createdDate;
    }

    // RMA records are not owned by the technician; query runs without sharing
    // so OWD does not block visibility for the engineer filter.
    private without sharing class RmaSelector {
        public List<RMA__c> getOpenRmasForEngineer(String engineerName) {
            return [
                SELECT Id, Name, RMA_Type__c,
                       Work_Order__r.WorkOrderNumber, Work_Order__c,
                       Opportunity_Name__c, Account_Name__c,
                       RMA_Item_Serial_Number__c, RMA_Asset_Product_Name__c,
                       Loaner_Probe_Model__c,
                       RMA_Tracking__c, Engineer_RMA_Tracking__c,
                       CreatedDate
                FROM RMA__c
                WHERE Opportunity__r.Field_Service_Engineer__c = :engineerName
                AND Date_RMA_Item_Received__c = null
                AND CreatedDate >= 2026-01-01T00:00:00Z
                AND Loaner_changed_to_sale__c = false
                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
        }
    }

    @TestVisible private static String rmaEngineerNameOverride;

    @AuraEnabled
    public static List<RmaDTO> getRmasForCurrentEngineer() {
        String currentUserName = rmaEngineerNameOverride != null ? rmaEngineerNameOverride : UserInfo.getName();
        List<RMA__c> rmas = new RmaSelector().getOpenRmasForEngineer(currentUserName);
        List<RmaDTO> dtos = new List<RmaDTO>();
        for (RMA__c rma : rmas) {
            RmaDTO dto = new RmaDTO();
            dto.rmaId = rma.Id;
            dto.rmaName = rma.Name;
            dto.rmaType = rma.RMA_Type__c;
            dto.workOrderNumber = rma.Work_Order__r != null ? rma.Work_Order__r.WorkOrderNumber : null;
            dto.workOrderId = rma.Work_Order__c;
            dto.opportunityName = rma.Opportunity_Name__c;
            dto.accountName = rma.Account_Name__c;
            dto.serialNumber = rma.RMA_Item_Serial_Number__c;
            dto.assetProductName = rma.RMA_Asset_Product_Name__c;
            dto.loanerProbeModel = rma.Loaner_Probe_Model__c;
            dto.rmaTracking = rma.RMA_Tracking__c;
            dto.engineerRmaTracking = rma.Engineer_RMA_Tracking__c;
            dto.createdDate = rma.CreatedDate;
            dtos.add(dto);
        }
        return dtos;
    }

    @AuraEnabled
    public static void updateEngineerRmaTracking(Id rmaId, String trackingNumber) {
        update new RMA__c(
            Id = rmaId,
            Engineer_RMA_Tracking__c = String.isBlank(trackingNumber) ? null : trackingNumber.trim()
        );
    }
}