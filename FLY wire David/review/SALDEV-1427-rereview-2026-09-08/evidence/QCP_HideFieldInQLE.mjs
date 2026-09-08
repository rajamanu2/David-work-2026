export function isFieldVisibleForObject(fieldName, line, conn, objectName) {
    if (
        objectName === "QuoteLine__c" &&
        (
            fieldName === "Usage_Rate_Amt__c" ||
            fieldName === "Adjusted_Rate_Amount__c" ||
            fieldName === "Usage_Rate__c" ||
            fieldName === "Adjusted_Rate_Percent__c"
        )
    ) {
        // If Requires_Usage_Type__c is checked, show ALL fields
        if (line.Requires_Usage_Type__c === true) {
            return true;
        }

        // show fields based on Rate_Type and Usage_Type
        if (line.Rate_Type__c === "Usage") {
            switch (line.Usage_Type__c) {
                case "Amount":
                    return (
                        fieldName === "Usage_Rate_Amt__c" ||
                        fieldName === "Adjusted_Rate_Amount__c"
                    );

                case "Percent":
                    return (
                        fieldName === "Usage_Rate__c" ||
                        fieldName === "Adjusted_Rate_Percent__c"
                    );

                case "Both":
                    return (
                        fieldName === "Usage_Rate_Amt__c" ||
                        fieldName === "Adjusted_Rate_Amount__c" ||
                        fieldName === "Usage_Rate__c" ||
                        fieldName === "Adjusted_Rate_Percent__c"
                    );

                default:
                    return false;
            }
        } else {
            return false;
        }
    }

    if (objectName === "QuoteLine__c" && fieldName === "Payer__c") {
        if (!((line.SBQQ__ProductCode__c === "FWCCY1000" && line.Vertical2__c === "Education" && line.Non_Local_Currency__c === "No" && line.Account_Country__c === "United States") || (line.SBQQ__ProductCode__c === "FWSFS1600" || line.SBQQ__ProductCode__c === "FWPAY1700" || line.SBQQ__ProductCode__c === "FWPAY1800") || (line.Account_Country__c === "Australia" || line.Account_Country__c === "Japan" || line.Account_Country__c === "Singapore") || (line.SBQQ__ProductCode__c === "FWCCY1000" && line.Account_Country__c === "Canada"))) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "Last_12_Months_Payment_Plans__c") {
        if (line.SBQQ__ProductCode__c !== "FWSFS1600") {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && (fieldName === "MPP_Card_Usage_Included__c" || fieldName === "Actual_12_Months_Tuition_CC_Vol__c")) {
        if (line.SBQQ__ProductCode__c !== "FWPAY1700" && line.SBQQ__ProductCode__c !== "FWPAY1800") {
            return false;
        }
    }

const pCode = line.SBQQ__ProductCode__c;
const vertical = line.Vertical2__c;
const transType = line.Transaction_Type__c;
const usageType = line.Usage_Type__c;
const payMethod = line.Payment_Method__c;
const isARR = line.Requires_ARR_Fields_Completion__c === true;

if (fieldName === "Utilization__c") {
    if (pCode === "FWPAY2700") return isARR;
    
    // SALDEV-1345 / SALDEV-1171: Always displays true (now isARR) for EDU Domestic Payments (% Utilization)
    if (vertical === "Education" && ["FWCCY1000", "FWXB1000"].includes(pCode)) return isARR;

    // SALDEV-1313 & SALDEV-1331 Changes for B2B
    if (vertical === "B2B") {
        // SALDEV-1345: New explicit rules when isARR is true
        if (isARR && pCode === "FWXB1000") {
            if (transType === "FX") return isARR; // SALDEV-1345
            if (transType === "Same Currency" && usageType === "Amount") return isARR; // SALDEV-1345
            if (transType === "Same Currency" && usageType === "Percent") return isARR; // SALDEV-1345
        }

        // SALDEV-1345: Domestic Payment (FWCCY1000) updates
        if (pCode === "FWCCY1000") {
            if (["Amount", "Percent", "Both"].includes(usageType)) return isARR; // SALDEV-1345
        }

        // SALDEV-1313: Cross Border Matrix (FWXB1000) - Fallback/Legacy
        if (pCode === "FWXB1000") {
            if (transType === "FX") return isARR;
            if (transType === "Same Currency" && ["Amount", "Percent", "Both"].includes(usageType)) return isARR;
        }
    }
    return false;
}

if (fieldName === "Estimated_Volume__c") {
    if (vertical !== "B2B") return false;

    // SALDEV-1345: Completely hide Estimated Volume for B2B Domestic Payments (FWCCY1000)
    if (pCode === "FWCCY1000") {
        return false;
    }

    // SALDEV-1345: Isolated B2B Vertical Updates (Only tracks for FWXB1000 now)
    if (isARR) {
        if (pCode === "FWXB1000" && transType === "FX") return true; // Rule 1
        if (pCode === "FWXB1000" && transType === "Same Currency" && usageType === "Amount") return true; // Rule 2
        if (transType === "Same Currency" && usageType === "Percent") return true; // Rule 3
    }

    if (pCode === "FWXB1000" && transType === "Same Currency" && usageType === "Amount") {
        return true;
    }

    return false; 
}

if (fieldName === "Est_Annual_MM__c") {
    if (pCode === "FWFA-1100") return true;
    if (vertical === "Travel" && ["FWCCY1000", "FWXB1000"].includes(pCode)) return isARR;

    // SALDEV-1345: Isolated B2B Vertical Updates
    if (vertical === "B2B") {
        if (isARR) {
            // Cross Border Matrix (FWXB1000) Rules
            if (pCode === "FWXB1000" ||  pCode === "FWCCY1000") {
                if (transType === "FX") return true; 
                if (transType === "Same Currency" && ["Amount", "Percent"].includes(usageType)) return true; 
            }
            
            // Domestic Payment Matrix (FWCCY1000) Rules
            if (pCode === "FWCCY1000") {
return true;
            }
        }
        
        // Return false for any other B2B variations that didn't explicitly match true above
        return false;
    }
    return false;
}

if (fieldName === "Annual_Number_of_Domestic_Transactions__c") {
    if (["Travel", "Healthcare"].includes(vertical)) return false;

    // SALDEV-1345: Updated Domestic Payment Matrix (FWCCY1000) Requirements
    if (vertical === "B2B" && pCode === "FWCCY1000") {
        if (usageType === "Amount" && isARR) return true;
        if (usageType === "Percent" && isARR) return true; 
        return false; 
    }

    if (vertical === "B2B" && pCode === "FWXB1000") return false;

    // Education Matrix Constraint
    if (vertical === "Education") {
        if (pCode === "FWXB1000") return false; 
        
        if (pCode === "FWCCY1000" && isARR) {
            if (["Amount", "Percent"].includes(usageType)) return true;
        }
        return false; 
    }
}


// GATEKEEPER AREA: SURCHARGING & ARR FIELDS (EDUCATION)

const isAmountRelevantField = ["Annual_No_Surcharge_Transactions__c"].includes(fieldName);
const isPercentRelevantField = ["Annual_Total_CC_Volume__c", "Annual_Total_Surcharge_Volume__c", "Annual_Total_Domestic_Volume__c"].includes(fieldName); 

if (isAmountRelevantField || isPercentRelevantField) {
    if (vertical !== "Education" || pCode !== "FWCCY1000" || !isARR) return false;

    if (fieldName === "Annual_Total_Domestic_Volume__c" || fieldName === "Annual_Total_CC_Volume__c") {
        if (["Amount", "Percent"].includes(usageType)) return true; 
    }

    if (isAmountRelevantField) {
        if (usageType === "Amount" && line.Surcharging__c === "Yes") {
            return true;
        }
        return false;
    }
    
    if (isPercentRelevantField) {
        if (fieldName === "Annual_Total_Surcharge_Volume__c") {
            if (usageType === "Percent" && line.Surcharging__c === "Yes") {
                return true;
            }
            return false;
        }
    }
    return false;
}
    if (
        objectName === "QuoteLine__c" &&
        (fieldName === "Payment_Method__c" ||
        fieldName === "Transaction_Type__c" ||
        fieldName === "CC_Country__c" ||
        fieldName === "Non_Local_Currency__c" ||
        fieldName === "Transaction_Currency__c" ||
        fieldName === "Attribute_Code__c" ||
        fieldName === "Surcharging__c" ||
        fieldName === "Vertical2__c")
    ) {
        if (line.SBQQ__ProductCode__c !== "FWCCY1000" && line.SBQQ__ProductCode__c !== "FWXB1000") {
            return false;
        }
    }

    if (objectName === "QuoteLine__c" && fieldName === "No_International_Payers__c") {
        const pCode = line.SBQQ__ProductCode__c;
        const vertical = line.Vertical2__c;
        const arrCompleted = line.Requires_ARR_Fields_Completion__c === true;

        const isPayProductVisible = (pCode === "FWPAY2700" && arrCompleted);

        const isLegacyRequirementMet = (
            vertical === "Education" &&
            pCode === "FWXB1000" &&
            arrCompleted
        );

        if (!isPayProductVisible && !isLegacyRequirementMet) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && (fieldName === "Avg_FX_Trans_Amt__c" || fieldName === "FX_XB_Outgoing_PYMTS__c")) {
        if (
            (line.SBQQ__ProductCode__c !== "FWAP1000" ||
            !(line.Vertical2__c === "Education" && (line.Account_Country__c === "Canada" || line.Account_Country__c === "United Kingdom")) &&
            !(line.Vertical2__c === "Travel" && line.Ship_To_Account_Region__c === "EMEA"))
        ) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "Client_Home_CCY_XB_PYMNTS__c") {
        if (
            (line.SBQQ__ProductCode__c !== "FWAP1100" ||
            !(line.Vertical2__c === "Education" && (line.Account_Country__c === "Canada" || line.Account_Country__c === "United Kingdom")) &&
            !(line.Vertical2__c === "Travel" && line.Ship_To_Account_Region__c === "EMEA"))
        ) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "DOM_Outgoing_PYMTS__c") {
        if (
            (line.SBQQ__ProductCode__c !== "FWAP1200" ||
            !(line.Vertical2__c === "Education" && (line.Account_Country__c === "Canada" || line.Account_Country__c === "United Kingdom")) &&
            !(line.Vertical2__c === "Travel" && line.Ship_To_Account_Region__c === "EMEA"))
        ) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "BPS_Upcharge__c") {
        if (line.Vertical2__c !== "Healthcare" || line.SBQQ__ProductCode__c !== "FWHC1330") {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && (fieldName === "Per_Transaction_Upcharge__c" || fieldName === "No_Processed_Volume__c")) {
        if (line.Vertical2__c !== "Healthcare" || line.SBQQ__ProductCode__c !== "FWHC1310") {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "Interchange_Rate__c") {
        if (line.Vertical2__c !== "Healthcare" || line.SBQQ__ProductCode__c !== "FWHC1320") {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "Processed_Volume_Amount__c") {
        if (line.Vertical2__c !== "Healthcare" || (line.SBQQ__ProductCode__c !== "FWHC1320" && line.SBQQ__ProductCode__c !== "FWHC1330")) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && fieldName === "Expected_of_Apps_per_Year__c") {
        if (
            line.SBQQ__ProductCode__c !== "FWSL3000" &&
            line.SBQQ__ProductCode__c !== "FWSL3010" &&
            line.SBQQ__ProductCode__c !== "FWSL3020"
        ) {
            return false;
        }
    }
    
    /* Show Partner fields on QLE Drawer */
    if (objectName === "QuoteLine__c" && (fieldName === "Partner_Type__c" || fieldName === "Refer_Resell_Partner__c")) {
        // Show fields ONLY when the Product says Partner Required
        if (line.Partner_Required__c === true) {
            return true; 
        } else {
            return false; 
        }
    }

    if (objectName === "QuoteLine__c" && fieldName === "Rate_Details__c") {
        const groupB = ["FWCCY1000", "FWXB1000"];
        const isTieredPricingVisible = line.Tiered_Pricing__c === true;

        const isGroupBVisible =
            groupB.includes(line.SBQQ__ProductCode__c) &&
            line.Vertical2__c === "B2B" &&
            line.Transaction_Type__c === "Same Currency" &&
            line.Surcharging__c === "No" &&
            line.Transaction_Currency__c === "USD" &&
            line.Payment_Method__c === "MC/Visa Debit";

        if (!(isTieredPricingVisible || isGroupBVisible)) {
            return false;
        }
    }

    if (objectName === "QuoteLine__c" && fieldName === "One_Door__c") {
        if ((
            line.Vertical2__c !== "Education" ||
            line.SBQQ__ProductCode__c !== "FWXB1000" ||
            line.Account_Country__c !== "United Kingdom" ||
            !line.Requires_ARR_Fields_Completion__c
        )) {
            return false;
        }
    }
    
    if (objectName === "QuoteLine__c" && (fieldName === "International_Sponsor__c" || fieldName === "Yearly_Invoiced_Sent__c" || fieldName === "Total_Flows__c")) {
        if (line.Vertical2__c !== "Education" || line.SBQQ__ProductCode__c !== "FWSI1200") {
            return false;
        }
    }

    if (
        objectName === "QuoteLine__c" && 
        (
            fieldName === "Price_Rules_Fired__c" || 
            fieldName === "Usage_Key__c" || 
            fieldName === "Usage_Key_Lookup__c" || 
            fieldName === "Quote_Regional_Availability__c" || 
            fieldName === "Regional_Availability__c" || 
            fieldName === "Region_Match__c" || 
            fieldName === "Region_Match_Update__c" || 
            fieldName === "Vertical2__c"
        )
    ) {
        if (line.Debug_Mode__c === false) {
            return false;
        }
    }

    return true;
}

/**
 * CANONICAL FIELD CONFIGURATION (SALDEV-1371 / SALDEV-1427)
 * Centralized ARR field list to avoid cross-script drift.
 */
const ARR_FIELDS_TO_NULL = [
    'DOM_Outgoing_PYMTS__c', 'Utilization__c', 'Actual_12_Months_Tuition_CC_Vol__c',
    'Annual_Number_of_Domestic_Transactions__c', 'Annual_No_Surcharge_Transactions__c',
    'Annual_Total_CC_Volume__c', 'Annual_Total_Surcharge_Volume__c', 'Avg_FX_Trans_Amt__c',
    'BPS_Upcharge__c', 'Client_Home_CCY_XB_PYMNTS__c', 'Domestic_Sponsor__c',
    'Est_Annual_MM__c', 'Estimated_Volume__c', 'Expected_of_Apps_per_Year__c',
    'FX_XB_Outgoing_PYMTS__c', 'International_Sponsor__c', 'Interchange_Rate__c',
    'Last_12_Months_Payment_Plans__c', 'MPP_Card_Usage_Included__c', 'No_International_Payers__c',
    'One_Door__c', 'Per_Transaction_Upcharge__c', 'No_Processed_Volume__c',
    'Total_Flows__c', 'Yearly_Invoiced_Sent__c'
];

/**
 * ============================================================================
 * FUNCTION: onBeforeCalculate
 * ============================================================================
 * SALDEV-1371 / SALDEV-1351 / SALDEV-1427:
 * Runs immediately before CPQ calculation passes.
 * Clears NetSuite integration IDs and ARR input fields on unsaved new lines 
 * ONLY if the line or parent group was cloned, preventing unexpected Flow 
 * calculations while preserving net-new user input.
 */
export function onBeforeCalculate(quoteModel, quoteLineModels) {

    const arrFieldsToNull = ARR_FIELDS_TO_NULL;

    if (quoteLineModels && quoteLineModels.length > 0) {
        quoteLineModels.forEach(function(line) {
            const rec = line.record;
            if (!rec) return;

            const parentGroupObj = line.parentGroup || {};
            const parentGroupRec = parentGroupObj.record || {};

            const isClonedGroup = parentGroupRec.SBQQ__Source__c != null || parentGroupObj.SBQQ__Source__c != null;
            const isClonedLine = rec.SBQQ__Source__c != null || line.SBQQ__Source__c != null;
            const isNewUnsavedLine = rec.SBQQ__Existing__c === false;

            if (isNewUnsavedLine) {
                // Always clear integration and tracking IDs on unsaved lines
                rec['NS_ID__c'] = null;
                rec['Opportunity_Line_Id__c'] = null;

                // ONLY clear ARR fields if the line or group was CLONED!
                if (isClonedGroup || isClonedLine) {
                    arrFieldsToNull.forEach(function(fieldApi) {
                        rec[fieldApi] = null;
                    });
                }
            }
        });
    }

    return Promise.resolve();
}

/**
 * Global list of read-only fields across the QLE.
 */
const readOnlyFields = [
    'Price_Rules_Fired__c',
    'Usage_Rate__c',
    'Usage_Rate_Amt__c',
    'Attribute_Code__c',
    'ARR_Field_Error__c',
    'Line_Description__c',
    'Account_Country__c',
    'Requires_Usage_Type__c',
    'Regional_Availability__c',
    'Quote_Regional_Availability__c',
    'Region_Match__c',
    'Region_Match_Update__c',
    'Vertical2__c',
    'SBQQ__ListPrice__c',
    'External_Description__c'
];


// SALDEV-1427: Quantity & Price-related fields permitted for edit in Stepped-Up Groups
// Permitted fields for editing on Amendment lines and Downstream Ramped Groups
const editableRampingFields = new Set([
    'SBQQ__Quantity__c',
    'Quoted_Price__c',
    'Adjusted_Rate_Amount__c',
    'Adjusted_Rate_Percent__c',
    'Usage_Rate__c',
    'Usage_Rate_Amt__c',
    'Rate_Details__c',
    'Price_Change__c'
]);

export function isFieldEditable(fieldName, line) {
    if (!line) return true;

    // Resolve record object across Table and Line Drawer contexts
    const rec = line.record || line;

    // 1. Global Read-Only Fields Guard
    if (typeof readOnlyFields !== 'undefined' && readOnlyFields.includes(fieldName)) {
        return false;
    }

    // --- LINE-LEVEL AMENDMENT & CONTRACTED LINE IDENTIFIERS ---
    // CPQ populates these native fields on Amendment/Renewal Quote Lines
    const isExistingLine = rec.SBQQ__Existing__c === true || rec.SBQQ__Existing__c === 'true';
    
    const isUpgradedOrContracted = 
        rec.SBQQ__UpgradedSubscription__c != null || line.SBQQ__UpgradedSubscription__c != null ||
        rec.SBQQ__UpgradedContractLine__c != null || line.SBQQ__UpgradedContractLine__c != null ||
        rec.SBQQ__RenewedSubscription__c != null || line.SBQQ__RenewedSubscription__c != null ||
        rec.SBQQ__SubscribedAsset__c != null || line.SBQQ__SubscribedAsset__c != null ||
        rec.SBQQ__PriorQuantity__c != null || line.SBQQ__PriorQuantity__c != null;

    const isAmendmentLineType = 
        rec.Quote_Line_Type__c === 'Amendment' || 
        rec.Quote_Line_Type__c === 'Renewal' ||
        rec.Quote_Line_Type__c === 'Quantity Increase' ||
        rec.Quote_Line_Type__c === 'Quantity Reduction';

    // Ramping / Step-Up Group Evaluation
    const lineGroupRec = rec.SBQQ__Group__r || line.SBQQ__Group__r || {};
    const parentGroupObj = line.parentGroup || {};
    const parentGroupRec = parentGroupObj.record || {};
    const groupNumber = lineGroupRec.SBQQ__Number__c || line.SBQQ__GroupNumber__c || parentGroupRec.SBQQ__Number__c || 1;

    const isRampingEnabled = lineGroupRec.Allow_Product_Ramping__c === true || 
                             parentGroupRec.Allow_Product_Ramping__c === true || 
                             parentGroupObj.Allow_Product_Ramping__c === true || 
                             rec.Allow_Product_Ramping__c === true;

    const isGroupCloned = (lineGroupRec.SBQQ__Source__c != null) || 
                          (parentGroupRec.SBQQ__Source__c != null) || 
                          (rec.SBQQ__SourceGroup__c != null) || 
                          (groupNumber > 1 && isRampingEnabled);

    // --- RULE 1: STRICT LOCK FOR ALL AMENDMENT / RENEWAL / CONTRACTED LINES ---
    // If the line is an Amendment/Renewal or Existing contracted line AND NOT an active Stepped-Up Group:
    if (isExistingLine || isUpgradedOrContracted || isAmendmentLineType) {
        if (!isRampingEnabled) {
            if (fieldName !== 'SBQQ__Quantity__c') {
                return false; // Strictly locks everything except Quantity!
            }
            return true;
        }
    }

    // --- RULE 2: RATE DETAILS RESTRICTION ---
    if (fieldName === 'Rate_Details__c') {
        if (isRampingEnabled && (isGroupCloned || (rec.SBQQ__Source__c != null))) {
            return true;
        }
        return !isExistingLine && !isUpgradedOrContracted && !isAmendmentLineType;
    }

    // --- RULE 3: DOWNSTREAM STEPPED-UP RAMPED GROUPS (Group Number > 1) ---
    if (isRampingEnabled && isGroupCloned) {
        if (fieldName === 'Ship_To_Account__c' || fieldName === 'Transaction_Currency__c') {
            return false;
        }

        if (typeof editableRampingFields !== 'undefined' && !editableRampingFields.has(fieldName)) {
            return false;
        }

        return true;
    }

    // --- RULE 4: DEFAULT EDITABLE FOR NET-NEW LINES IN GROUP 1 ---
    return true;
}

/**
 * Locks Start/End Date editing on Quote Line Groups directly.
 */
export function isGroupFieldEditable(fieldName, groupModelRecord) {
    if (fieldName === 'SBQQ__StartDate__c' || fieldName === 'SBQQ__EndDate__c') {
        return false;
    }
    return true;
}

/**
 * Collects ALL lines belonging to the same Root Bundle.
 */
function getBundlePricingValue(line, allLines) {
const isExisting = line.record.SBQQ__Existing__c;

function findRootParentInline(l) {
    var current = l;
    while (current && current.parentItem) {
        current = current.parentItem;
    }
    return current;
}

const rootParent = findRootParentInline(line); // Find the absolute top parent

// Filter allLines to find every line that shares this same root parent
const relatedLines = allLines.filter(function(l) {
return findRootParentInline(l) === rootParent &&
l.record.SBQQ__Existing__c === isExisting;
});

// Sort and join all prices into one "Master Bundle String"
return relatedLines
.sort((a, b) => (a.record.SBQQ__ProductCode__c > b.record.SBQQ__ProductCode__c ? 1 : -1))
.map(function(l) {
return getPricingValue(l.record);
}).join('|');
}

/**
 * Extracts and formats the effective pricing value string for bundle comparison.
 */
function getPricingValue(rec) {
if (!rec) return "0.000000";

// Prioritize Live Edits from the QLE drawer
if (rec.Adjusted_Rate_Amount__c != null) return Number(rec.Adjusted_Rate_Amount__c).toFixed(6);
if (rec.Adjusted_Rate_Percent__c != null) return Number(rec.Adjusted_Rate_Percent__c).toFixed(6);

// Standard Pricing Methods
if (rec.Tiered_Pricing__c === true) return (rec.Rate_Details__c || 'EMPTY_TIER').trim();
if (rec.Rate_Type__c === 'Fixed') return Number(rec.Quoted_Price__c || 0).toFixed(6);

// Fallback for N/A / Blank NS Usage Rates
if (rec.NS_Usage_Rate__c == null || rec.Usage_Type__c === 'N/A') {
return "BLANK_OR_NA";
}

return Number(rec.NS_Usage_Rate__c).toFixed(6);
}

/**
 * ============================================================================
 * FUNCTION: onAfterCalculate
 * ============================================================================
 * Main post-calculation orchestrator for validations, pairing rules, 
 * duplicate checking, and bundle sync.
 */
export async function onAfterCalculate(quoteModel, quoteLineModels) {
checkRequiredApprovals(quoteModel, quoteLineModels);
checkDuplicateQuoteLineUSLoanProduct(quoteModel, quoteLineModels);
checkDuplicateQuoteLineProduct(quoteModel, quoteLineModels);//SALDEV-1328
requireARROnOneLinePerShipTo(quoteLineModels, 'FWXB1000');
requireARROnOneLinePerShipTo(quoteLineModels, 'FWCCY1000');
requireARROnOneLinePerShipTo(quoteLineModels, 'FWPAY2700');
checkFeeConflictByShipTo(quoteModel, quoteLineModels);
clearAdjustedRatesOnPaymentMethodChange(quoteLineModels); //SALDEV-723
checkIdenticalSurchargePairRule(quoteModel, quoteLineModels); //SALDEV-973
checkCancelCloneSameUsageRate(quoteModel, quoteLineModels);
validateAmexPairing(quoteModel,quoteLineModels); //SALDEV_1193
checkPaymentAndCountryMatrixRules(quoteModel, quoteLineModels);

const type = quoteModel.record.SBQQ__Type__c;

if (type === 'Renewal' || type === 'Amendment'){

// Sync bundle children first
syncBundleChildrenWithParent(quoteLineModels);

// Run cancel-clone pricing check
checkCancelCloneNoRateChange(quoteModel, quoteLineModels);
}
validateDuplicateProductsAnyQty(quoteModel, quoteLineModels)

//SALDEV-959
//handleAccountCascadeAndValidation(quoteLineModels)
}

/**
 * Cascates zero-quantity cancellation state from parent bundles down to child lines.
 */
function syncBundleChildrenWithParent(quoteLineModels) {

if (!quoteLineModels || !quoteLineModels.length) return;

quoteLineModels.forEach(function(parentLine){

const parentRec = parentLine.record;

if (!parentRec) return;

// Parent bundle
if (!parentLine.parentItem && parentRec.SBQQ__Bundle__c === true) {

const parentQty = Number(parentRec.SBQQ__Quantity__c || 0);

if (parentQty === 0) {

quoteLineModels.forEach(function(childLine){

if (childLine.parentItem === parentLine) {

childLine.record.SBQQ__Quantity__c = 0;

}

});

}
}

});
}

/**
 * ============================================================================
 * FUNCTION: validateAmexPairing
 * ============================================================================
 * SALDEV-1441: Amex Gateway QLE Warning & Product Rule Flagging.
 * Ensures Domestic (FWCCY1000) and Cross-Border (FWXB1000) Amex Gateway lines 
 * are properly paired with matching configuration attributes per validation context.
 */
function validateAmexPairing(
    quoteModel,
    quoteLineModels
) {
    // Always reset both Product Rule flags.
    quoteModel.record[
        'Trigger_Amex_Line_Creation__c'
    ] = false;

    quoteModel.record[
        'Amex_Attributes_Mismatched__c'
    ] = false;

    if (!quoteLineModels || !quoteLineModels.length) {
        return;
    }

    const amexLinesByContext = new Map();

    quoteLineModels.forEach(function(line) {
        const rec = line.record;

        if (!rec) {
            return;
        }

        // Ignore deleted and inactive lines.
        if (
            rec.SBQQ__IsDeleted__c === true ||
            Number(rec.SBQQ__Quantity__c || 0) <= 0
        ) {
            return;
        }

        const paymentMethod =
            (rec.Payment_Method__c || '').trim();

        if (paymentMethod !== 'Amex Gateway') {
            return;
        }

        const productCode =
            rec.SBQQ__ProductCode__c || '';

        if (
            productCode !== 'FWCCY1000' &&
            productCode !== 'FWXB1000'
        ) {
            return;
        }

        const validationContext =
            getValidationContext(line);

        const shipTo =
            rec.Ship_To_Account__c || 'NO_SHIP_TO';

        const pairingKey = [
            validationContext,
            shipTo
        ].join('|');

        if (!amexLinesByContext.has(pairingKey)) {
            amexLinesByContext.set(pairingKey, {
                domestic: [],
                crossBorder: []
            });
        }

        const bucket =
            amexLinesByContext.get(pairingKey);

        if (productCode === 'FWCCY1000') {
            bucket.domestic.push(rec);
        }

        if (productCode === 'FWXB1000') {
            bucket.crossBorder.push(rec);
        }
    });

    amexLinesByContext.forEach(function(bucket) {
        const domesticCount =
            bucket.domestic.length;

        const crossBorderCount =
            bucket.crossBorder.length;

        const hasMissingPair =
            domesticCount === 0 ||
            crossBorderCount === 0 ||
            domesticCount !== crossBorderCount;

        if (hasMissingPair) {
            quoteModel.record[
                'Trigger_Amex_Line_Creation__c'
            ] = true;

            // Missing products take priority over attribute comparison.
            return;
        }

        const unmatchedCrossBorder =
            bucket.crossBorder.slice();

        bucket.domestic.forEach(function(domLine) {
            const domAttributeKey =
                getAmexAttributeKey(domLine);

            const matchingXBIndex =
                unmatchedCrossBorder.findIndex(
                    function(xbLine) {
                        return (
                            getAmexAttributeKey(xbLine) ===
                            domAttributeKey
                        );
                    }
                );

            if (matchingXBIndex === -1) {
                quoteModel.record[
                    'Amex_Attributes_Mismatched__c'
                ] = true;

                return;
            }

            // Prevent the same XB line from satisfying multiple DOM lines.
            unmatchedCrossBorder.splice(
                matchingXBIndex,
                1
            );
        });

        if (unmatchedCrossBorder.length > 0) {
            quoteModel.record[
                'Amex_Attributes_Mismatched__c'
            ] = true;
        }
    });
}

/**
 * Traverses parent items to locate the absolute top-level root line model.
 */
function getRootLine(line) {
    let currentLine = line;

    while (currentLine && currentLine.parentItem) {
        currentLine = currentLine.parentItem;
    }

    return currentLine || line;
}

/**
 * Resolves the effective parent group model across direct or root parent relationships.
 */
function getEffectiveGroupModel(line) {
    if (line && line.parentGroup) {
        return line.parentGroup;
    }

    const rootLine = getRootLine(line);

    if (rootLine && rootLine.parentGroup) {
        return rootLine.parentGroup;
    }

    return null;
}

/**
 * Evaluates whether product ramping (Step-Up) is active on the line or parent group context.
 */
function isStepUpLine(line) {
    const rec = line.record || {};
    const rootLine = getRootLine(line);
    const rootRec = rootLine.record || {};
    const groupModel = getEffectiveGroupModel(line) || {};
    const groupRec  = groupModel.record || {};
    const lineGroupRec  = rec.SBQQ__Group__r || {};
    const rootGroupRec  = rootRec.SBQQ__Group__r || {};

    return (
        groupModel.Allow_Product_Ramping__c === true ||
        groupRec.Allow_Product_Ramping__c === true ||
        lineGroupRec.Allow_Product_Ramping__c === true ||
        rootGroupRec.Allow_Product_Ramping__c === true ||
        rec.Group_Allow_Product_Ramping__c === true ||
     rootRec.Group_Allow_Product_Ramping__c === true
    );
}

/**
 * Resolves the explicit or draft group identity for validation scoping.
 */
function getGroupIdentity(line) {
    const rec = line.record || {};
    const rootLine = getRootLine(line);
    const rootRec = rootLine.record || {};
    const groupModel = getEffectiveGroupModel(line) || {};
    const groupRec = groupModel.record || {};
    const lineGroupRec = rec.SBQQ__Group__r || {};
    const rootGroupRec = rootRec.SBQQ__Group__r || {};

    const groupIndex =
        line.groupIndex !== undefined
            ? line.groupIndex
            : rootLine.groupIndex;

    return (
        groupRec.Id ||
        groupModel.key ||
        groupModel.id ||
        lineGroupRec.Id ||
        rootGroupRec.Id ||
        rec.SBQQ__Group__c ||
        rootRec.SBQQ__Group__c ||
        'DRAFT_GROUP_' + groupIndex
    );
}

/**
 * Constructs validation context string ('NON_STEP_UP' vs 'STEP_UP|<GroupId>').
 */
function getValidationContext(line) {
    if (!isStepUpLine(line)) {
        return 'NON_STEP_UP';
    }

    return 'STEP_UP|' + getGroupIdentity(line);
}

/**
 * Builds composite attribute key for Amex Gateway pairing validation.
 */
function getAmexAttributeKey(rec) {
    return [
        rec.Payment_Method__c || '',
        rec.Transaction_Currency__c || '',
        rec.Transaction_Type__c || '',
        rec.Surcharging__c || '',
        rec.Non_Local_Currency__c || ''
    ]
        .map(function(value) {
            return value.toString().trim();
        })
        .join('|');
}

/**
 * ============================================================================
 * FUNCTION: checkCancelCloneNoRateChange
 * ============================================================================
 * SALDEV-1349 / SALDEV-1404:
 * Validates cancellation clones on Amendments/Renewals. If a cancellation line 
 * (Qty 0) and active line (Qty > 0) have identical bundle pricing and no Payer 
 * modification session is active, flags 'Cancel_Clone_No_Rate_Change__c'.
 */
function checkCancelCloneNoRateChange(quoteModel, quoteLineModels){

    // Skip for Healthcare vertical
    if (quoteModel.record.Vertical_Text__c === 'Healthcare') {
        return;
    }
    quoteModel.record.Cancel_Clone_No_Rate_Change__c = false;

    if (!quoteLineModels || quoteLineModels.length < 2) {
        return;
    }

    const EXCLUDED_PRODUCTS = new Set(['FWCCY1000','FWXB1000']);
    // SALDEV-1349: Target flat-rate payer items directly
    const TARGET_PAYER_PRODUCTS = new Set(['FWPAY1700', 'FWPAY1800', 'FWSFS1600']);


    // SALDEV-1349: Scan the entire quote line collection first. If any matching quote as an active Payer Modification session.
  
    let isPayerModificationSession = false;

    for (let x = 0; x < quoteLineModels.length; x++) {
        const lineX = quoteLineModels[x];
        if (!lineX.record || !TARGET_PAYER_PRODUCTS.has(lineX.record.SBQQ__ProductCode__c)) continue;

        // Stepup pricing [SALDEV-1404]: Skip StepUp lines during Payer Modification scan
        const groupRecX = (lineX.parentGroup && lineX.parentGroup.record) ? lineX.parentGroup.record : (lineX.record.SBQQ__Group__r || {});
        if (groupRecX.Allow_Product_Ramping__c === true || lineX.record.Allow_Product_Ramping__c === true) {
            continue;
        }

        for (let y = x + 1; y < quoteLineModels.length; y++) {
            const lineY = quoteLineModels[y];
            if (!lineY.record || lineX.record.SBQQ__ProductCode__c !== lineY.record.SBQQ__ProductCode__c) continue;

            // Stepup pricing [SALDEV-1404]: Skip if paired line is in a StepUp Group
            const groupRecY = (lineY.parentGroup && lineY.parentGroup.record) ? lineY.parentGroup.record : (lineY.record.SBQQ__Group__r || {});
            if (groupRecY.Allow_Product_Ramping__c === true || lineY.record.Allow_Product_Ramping__c === true) {
                continue;
            }

            if ((lineX.record.Ship_To_Account__c || '') !== (lineY.record.Ship_To_Account__c || '')) continue;

            const pX = (lineX.record.Payer__c || '').toString().trim();
            const pY = (lineY.record.Payer__c || '').toString().trim();

            if (pX !== pY) {
                isPayerModificationSession = true;
                break;
            }
        }
        if (isPayerModificationSession) break;
    }

    // SALDEV-1349: If a payer modification is actively happening on the target products,
    // terminate the function here to prevent sibling lines from triggering false duplicate locks.
    if (isPayerModificationSession) {
        return; 
    }
    

    for (let i = 0; i < quoteLineModels.length; i++) {

        const lineA = quoteLineModels[i];
        const recA = lineA.record;
        if (!recA) continue;

        // Stepup pricing [SALDEV-1404]: Safely evaluate StepUp status for Line A
        const groupRecA = (lineA.parentGroup && lineA.parentGroup.record) ? lineA.parentGroup.record : (recA.SBQQ__Group__r || {});
        if (groupRecA.Allow_Product_Ramping__c === true || recA.Allow_Product_Ramping__c === true) {
            continue;
        }

        if (EXCLUDED_PRODUCTS.has(recA.SBQQ__ProductCode__c)) continue;

        for (let j = i + 1; j < quoteLineModels.length; j++) {

            const lineB = quoteLineModels[j];
            const recB = lineB.record;
            if (!recB) continue;

            // Stepup pricing [SALDEV-1404]: Safely evaluate StepUp status for Line B
            const groupRecB = (lineB.parentGroup && lineB.parentGroup.record) ? lineB.parentGroup.record : (recB.SBQQ__Group__r || {});
            if (groupRecB.Allow_Product_Ramping__c === true || recB.Allow_Product_Ramping__c === true) {
                continue;
            }

            if (EXCLUDED_PRODUCTS.has(recB.SBQQ__ProductCode__c)) continue;

            // Must be same product
            if (recA.SBQQ__ProductCode__c !== recB.SBQQ__ProductCode__c) continue;

            // Same Ship To
            if ((recA.Ship_To_Account__c || '') !== (recB.Ship_To_Account__c || '')) continue;

            // Same Currency
            if ((recA.Transaction_Currency__c || '') !== (recB.Transaction_Currency__c || '')) continue;

            const qtyA = Number(recA.SBQQ__Quantity__c || 0);
            const qtyB = Number(recB.SBQQ__Quantity__c || 0);

            const isCancelClone =
                (qtyA === 0 && qtyB > 0) ||
                (qtyB === 0 && qtyA > 0);

            if (!isCancelClone) continue;

            const pricingA = getBundlePricingValue(lineA, quoteLineModels);
            const pricingB = getBundlePricingValue(lineB, quoteLineModels);

            if (pricingA === pricingB) {
                quoteModel.record.Cancel_Clone_No_Rate_Change__c = true;
                return;
            }
        }
    }
}

/**
 * ============================================================================
 * FUNCTION: validateDuplicateProductsAnyQty
 * ============================================================================
 * Throws a QLE blocking error if duplicate active lines (Qty >= 1) exist for 
 * the same Product, Bundle Parent, Ship To, Attribute, and Payer within unramped 
 * groups or across ramped vs unramped groups.
 */
function validateDuplicateProductsAnyQty(quoteModel, quoteLineModels) {
    // 1. Skip for Healthcare vertical
    if (quoteModel.record && quoteModel.record.Vertical_Text__c === 'Healthcare') {
        return;
    }

    const signatureMap = new Map();

    // Helper function to extract ramping flag safely
    const isRamping = (line) => {
        const rec = line.record || {};
        const parentGroupObj = line.parentGroup || {};
        const parentGroupRec = parentGroupObj.record || {};
        const lineGroupRec = rec.SBQQ__Group__r || {};

        return parentGroupObj.Allow_Product_Ramping__c === true ||
               parentGroupRec.Allow_Product_Ramping__c === true ||
               lineGroupRec.Allow_Product_Ramping__c === true ||
               rec.Allow_Product_Ramping__c === true;
    };

    // Helper function to resolve Bundle Parent Key
    const getBundleParentKey = (line) => {
        const rec = line.record || {};
        return rec.SBQQ__RequiredBy__c || 
               (rec.SBQQ__RequiredBy__r ? rec.SBQQ__RequiredBy__r.Id : null) || 
               (line.parentItem ? (line.parentItem.key || line.parentItem.id) : null) || 
               'Standalone';
    };

    // Helper function to resolve Group ID
    const getGroupId = (line) => {
        const rec = line.record || {};
        const parentGroupObj = line.parentGroup || {};
        const parentGroupRec = parentGroupObj.record || {};
        const lineGroupRec = rec.SBQQ__Group__r || {};

        return parentGroupRec.Id || 
               parentGroupObj.key || 
               parentGroupObj.id || 
               parentGroupRec.Name || 
               lineGroupRec.Id || 
               rec.SBQQ__Group__c || 
               ('Group_' + (line.groupIndex !== undefined ? line.groupIndex : 'Draft'));
    };

    // --- 1. INTRA-GROUP & STANDARD SIGNATURE MAPPING ---
    quoteLineModels.forEach(function(line) {
        const rec = line.record;
        if (!rec || rec.SBQQ__IsDeleted__c === true) return;

        const productCode = rec.SBQQ__ProductCode__c || '';
        if (productCode === 'FWCCY1000' || productCode === 'FWXB1000') return;

        const qty = Number(rec.SBQQ__Quantity__c || 0);
        if (qty < 1) return;

        const isThisGroupRamping = isRamping(line);
        const groupId = getGroupId(line);
        const bundleParentKey = getBundleParentKey(line);

        let signatureParts = [
            productCode,
            bundleParentKey,
            rec.Ship_To_Account__c || 'NoShipTo',
            rec.Attribute_Code__c || 'NoAttr',
            rec.Payer__c || 'NoPayer'
        ];

        // Append groupId ONLY if ramping is enabled on THIS group
        if (isThisGroupRamping) {
            signatureParts.push(groupId);
        }

        const signature = signatureParts.join('|');
        const count = signatureMap.get(signature) || 0;
        signatureMap.set(signature, count + 1);
    });

    // Check intra-group/standard signature matches
    signatureMap.forEach(function(count) {
        if (count > 1) {
            throw new Error(
                'Only one active line is allowed for the same Product and Ship To Account. Please update the Ship To Account on the duplicate line.'
            );
        }
    });

    // --- 2. CROSS-GROUP EVALUATION (Unramped vs Unramped AND Ramped vs Unramped) ---
    quoteLineModels.forEach(function(line) {
        const rec = line.record;
        if (!rec || rec.SBQQ__IsDeleted__c === true) return;

        const productCode = rec.SBQQ__ProductCode__c || '';
        if (productCode === 'FWCCY1000' || productCode === 'FWXB1000') return;

        const qty = Number(rec.SBQQ__Quantity__c || 0);
        if (qty < 1) return;

        const isThisGroupRamping = isRamping(line);

        const baseSignature = [
            productCode,
            getBundleParentKey(line),
            rec.Ship_To_Account__c || 'NoShipTo',
            rec.Attribute_Code__c || 'NoAttr',
            rec.Payer__c || 'NoPayer'
        ].join('|');

        let matchFound = false;

        quoteLineModels.forEach(function(otherLine) {
            if (line === otherLine || matchFound) return;
            const oRec = otherLine.record;
            if (!oRec || oRec.SBQQ__IsDeleted__c === true) return;

            const oQty = Number(oRec.SBQQ__Quantity__c || 0);
            if (oQty < 1) return;

            const oProductCode = oRec.SBQQ__ProductCode__c || '';
            if (oProductCode === 'FWCCY1000' || oProductCode === 'FWXB1000') return;

            const isOtherGroupRamping = isRamping(otherLine);

            // EVALUATION CRITERIA:
            // 1. Both lines in UNRAMPED groups (Unramped vs Unramped)
            // 2. ONE line in a RAMPED group and ONE line in an UNRAMPED group (Ramped vs Unramped)
            // (Note: Ramped vs Ramped is ignored to allow step-up ramping)
            if (!isThisGroupRamping || !isOtherGroupRamping) {
                const otherBaseSig = [
                    oProductCode,
                    getBundleParentKey(otherLine),
                    oRec.Ship_To_Account__c || 'NoShipTo',
                    oRec.Attribute_Code__c || 'NoAttr',
                    oRec.Payer__c || 'NoPayer'
                ].join('|');

                if (baseSignature === otherBaseSig) {
                    matchFound = true;
                }
            }
        });

        if (matchFound) {
            throw new Error(
                'Only one active line is allowed for the same Product and Ship To Account. A duplicate exists between a Ramped and Unramped Group.'
            );
        }
    });
}
/**
 * ============================================================================
 * FUNCTION: checkCancelCloneSameUsageRate
 * ============================================================================
 * SALDEV-1349: Checks if cancelled lines (Qty 0) and active lines (Qty > 0) 
 * share the exact same usage rate key (including Payer__c). Flags 
 * 'Cancel_Clone_Same_Usage_Rate__c' if matching pairs exist.
 */
function checkCancelCloneSameUsageRate(quoteModel, quoteLineModels) {

quoteModel.record.Cancel_Clone_Same_Usage_Rate__c = false;

var usageMap = new Map();

quoteLineModels.forEach(function(line) {

var rec = line.record;

if (
rec.SBQQ__ProductCode__c !== 'FWCCY1000' &&
rec.SBQQ__ProductCode__c !== 'FWXB1000'
) {
return;
}

// Use centralized effective price logic
var effectiveRate = getEffectivePrice(rec);

var key = [
rec.Ship_To_Account__c || '',
rec.Attribute_Code__c || '',
rec.Transaction_Currency__c || '',
rec.Payment_Method__c || '',
rec.Payer__c || ' ', //SALDEV-1349: Included Payer__c in the uniqueness key.
Number(effectiveRate).toFixed(6)
].join('|');

var entry = usageMap.get(key) || { hasCancelled: false, hasActive: false };

var qty = Number(rec.SBQQ__Quantity__c || 0);

if (qty === 0) {
entry.hasCancelled = true;
} else if (qty > 0) {
entry.hasActive = true;
}

usageMap.set(key, entry);
});

usageMap.forEach(function(entry) {
if (entry.hasCancelled && entry.hasActive) {
quoteModel.record.Cancel_Clone_Same_Usage_Rate__c = true;
}
});
}

//============================================================================
 /* FUNCTION: checkDuplicateQuoteLineUSLoanProduct
 * ============================================================================
 * SALDEV-1441: Evaluates duplicate FAD US Loan Product (FWFA-1000) instances 
 * per Ship To Account independently within each validation context / Step-Up group.
 */
function checkDuplicateQuoteLineUSLoanProduct(quoteModel, quoteLineModels) {
    // This Quote field drives the "Duplicate FAD US Loan Product" Product Rule.
    quoteModel.record.IsDupUSLoanProdAdded__c = false;

    if (!quoteLineModels || !quoteLineModels.length) {
        return;
    }

    const FA_CODE = 'FWFA-1000';
    const PAYMENT_CODES = new Set(['FWXB1000', 'FWCCY1000']);

    // Key: validation context + Ship To Account
    // Value: FAD count and corresponding DOM/XB payment count in that context.
    const fadByContextAndShipTo = new Map();

    quoteLineModels.forEach(function(line) {
        const rec = line.record;

        if (
            !rec ||
            rec.SBQQ__IsDeleted__c === true ||
            Number(rec.SBQQ__Quantity__c || 0) <= 0
        ) {
            return;
        }

        const productCode = rec.SBQQ__ProductCode__c || '';

        // Only FAD, Domestic Payments and Cross Border Payments matter here.
        if (productCode !== FA_CODE && !PAYMENT_CODES.has(productCode)) {
            return;
        }

        const shipTo = rec.Ship_To_Account__c;

        // Preserve the existing behavior for lines without a Ship To Account.
        if (!shipTo) {
            return;
        }

        const validationContext = getValidationContext(line);
        const validationKey = [validationContext, shipTo].join('|');

        if (!fadByContextAndShipTo.has(validationKey)) {
            fadByContextAndShipTo.set(validationKey, {
                fadCount: 0,
                paymentCount: 0
            });
        }

        const bucket = fadByContextAndShipTo.get(validationKey);

        if (productCode === FA_CODE) {
            bucket.fadCount += 1;
        }

        if (PAYMENT_CODES.has(productCode)) {
            bucket.paymentCount += 1;
        }
    });

    fadByContextAndShipTo.forEach(function(bucket) {
        // A context is invalid when:
        // 1. FAD occurs more than once for the same Ship To, or
        // 2. FAD has no corresponding active DOM/XB for the same Ship To.
        if (
            bucket.fadCount > 1 ||
            (bucket.fadCount === 1 && bucket.paymentCount < 1)
        ) {
            quoteModel.record.IsDupUSLoanProdAdded__c = true;
        }
    });
}

/**
 * Validates identical surcharge pair configurations across Surcharging="Yes" and "No" lines.
 */
function checkIdenticalSurchargePairRule(quoteModel, quoteLineModels) {
// Default: assume no validation
quoteModel.record.Surcharge_Pair__c = false;

var nonSurchargeMap = new Map();
var hasViolation = false;
var hasYesLine = false;

// Define the target product codes
var targetProducts = ['FWCCY1000', 'FWXB1000'];

// Build map for lines with Surcharging = "No"
quoteLineModels.forEach(function(line) {
var productCode = line.record.SBQQ__ProductCode__c || '';

// Skip all lines except target products
if (targetProducts.indexOf(productCode) === -1) return;

var surchVal = (line.record.Surcharging__c || '').toString().toLowerCase();

if (surchVal === 'yes' || surchVal === 'true') {
hasYesLine = true; // track if we have any "Yes" lines at all
}

if (surchVal === 'no' || surchVal === 'false' || surchVal === '') {
var validationContext = getValidationContext(line);
var key =
validationContext + '|' +
productCode + '|' +
(line.record.Payment_Method__c || '') + '|' +
(line.record.CC_Country__c || '') + '|' +
(line.record.Non_Local_Currency__c || '') + '|' +
(line.record.Transaction_Type__c || '') + '|' +
(line.record.Usage_Type__c || '') + '|' +
(line.record.Transaction_Currency__c || '') + '|' +
(line.record.Ship_To_Account__c || '');
nonSurchargeMap.set(key, true);
}
});

// If there’s no “Yes” line, skip the rest
if (!hasYesLine) {
quoteModel.record.Surcharge_Pair__c = false;
return;
}

// For each "Yes" line, check if identical "No" line exists
quoteLineModels.forEach(function(line) {
var productCode = line.record.SBQQ__ProductCode__c || '';
if (targetProducts.indexOf(productCode) === -1) return;

var surchVal = (line.record.Surcharging__c || '').toString().toLowerCase();
if (surchVal === 'yes' || surchVal === 'true') {
var validationContext = getValidationContext(line);
var key =
validationContext + '|' +
productCode + '|' +
(line.record.Payment_Method__c || '') + '|' +
(line.record.CC_Country__c || '') + '|' +
(line.record.Non_Local_Currency__c || '') + '|' +
(line.record.Transaction_Type__c || '') + '|' +
(line.record.Usage_Type__c || '') + '|' +
(line.record.Transaction_Currency__c || '') + '|' +
(line.record.Ship_To_Account__c || '');

if (!nonSurchargeMap.has(key)) {
hasViolation = true;
}
}
});

// Only flag violation if needed
quoteModel.record.Surcharge_Pair__c = hasViolation;
}

/**
 * Clears Adjusted Rate fields when Payment Method changes, forcing Attribute Code re-lookup.
 */
function clearAdjustedRatesOnPaymentMethodChange(quoteLineModels) {
quoteLineModels.forEach(line => {
const oldPM = line.record.Previous_Payment_Method__c;
const currentPM = line.record.Payment_Method__c;

// Keep track of whether the PM actually changed
const paymentMethodChanged = oldPM && oldPM !== currentPM;

if (paymentMethodChanged) {
// Case 1: Payment Method changed → clear both
line.record.Adjusted_Rate_Amount__c = null;
line.record.Adjusted_Rate_Percent__c = null;

// CLEAR ATTRIBUTE CODE FORCE RELOOKUP

if (
    line.record.SBQQ__ProductCode__c === 'FWCCY1000'
    ||
    line.record.SBQQ__ProductCode__c === 'FWXB1000'
) {

    line.record.Attribute_Code__c = null;
}


} else {
// Case 2: Payment Method same → clear only invalid ones
if (line.record.Usage_Type__c === "Amount") {
// User is allowed to enter Amount, so leave it
line.record.Adjusted_Rate_Percent__c = null;
} else if (line.record.Usage_Type__c === "Percent") {
// User is allowed to enter Percent, so leave it
line.record.Adjusted_Rate_Amount__c = null;
}
// If "Both", do nothing (both are valid)
}

// Always snapshot Payment Method at the end
line.record.Previous_Payment_Method__c = currentPM;
});
}

/**
 * Determines visible usage fields based on Rate_Type and Usage_Type.
 */
function getVisibleUsageFields(line) {
if (line.Rate_Type__c !== "Usage") return [];

switch (line.Usage_Type__c) {
case "Amount":
return ["Usage_Rate_Amt__c", "Adjusted_Rate_Amount__c"];
case "Percent":
return ["Usage_Rate__c", "Adjusted_Rate_Percent__c"];
case "Both":
return ["Usage_Rate_Amt__c", "Adjusted_Rate_Amount__c", "Usage_Rate__c", "Adjusted_Rate_Percent__c"];
default:
return [];
}
}

/**
 * Ensures only one type of fee product (Service vs Contingency) exists per Ship To Account.
 */
function checkFeeConflictByShipTo(quoteModel, quoteLineModels) {
// Reset flag
quoteModel.record.HCFeeConflict__c = false;

// Map ShipTo → { service: true/false, contingency: true/false }
let shipToFeeMap = new Map();

quoteLineModels.forEach(function(line) {
let productCode = line.record.SBQQ__ProductCode__c;
let shipTo = line.record.Ship_To_Account__c;

if (!shipTo) return; // Skip if ShipTo is blank

// Adjust codes to match your Service Fee and Contingency Fee product codes
if (productCode === 'FWSFEE1000' || productCode === 'FWCFEE1000') {
let feeStatus = shipToFeeMap.get(shipTo) || { service: false, contingency: false };

if (productCode === 'FWSFEE1000') {
feeStatus.service = true;
}
if (productCode === 'FWCFEE1000') {
feeStatus.contingency = true;
}

// Save back to map
shipToFeeMap.set(shipTo, feeStatus);

// Check violation
if (feeStatus.service && feeStatus.contingency) {
quoteModel.record.HCFeeConflict__c = true;
}
}
});
}

/**
 * Checks for duplicate payment method configurations within and across Step-Up groups.
 */
function checkDuplicateQuoteLineProduct(quoteModel, quoteLineModels) {
    quoteModel.record['IsSamePaymentMethodAdded__c'] = false;
    let uniqueProdMap = new Map();

    const isRamping = (line) => {
        const rec = line.record || {};
        const parentGroupObj = line.parentGroup || {};
        const parentGroupRec = parentGroupObj.record || {};
        const lineGroupRec = rec.SBQQ__Group__r || {};

        return parentGroupObj.Allow_Product_Ramping__c === true ||
               parentGroupRec.Allow_Product_Ramping__c === true ||
               lineGroupRec.Allow_Product_Ramping__c === true ||
               rec.Allow_Product_Ramping__c === true;
    };

    const getGroupId = (line) => {
        const rec = line.record || {};
        const parentGroupObj = line.parentGroup || {};
        const parentGroupRec = parentGroupObj.record || {};
        const lineGroupRec = rec.SBQQ__Group__r || {};

        return parentGroupRec.Id || 
               parentGroupObj.key || 
               parentGroupObj.id || 
               parentGroupRec.Name || 
               lineGroupRec.Id || 
               rec.SBQQ__Group__c || 
               ('Group_' + (line.groupIndex !== undefined ? line.groupIndex : 'Draft'));
    };

    quoteLineModels.forEach(function(line) {
        const rec = line.record;
        if (!rec || rec.SBQQ__IsDeleted__c === true) return;

        const subType = rec.SBQQ__SubscriptionType__c || rec.SBQQ__ProductSubscriptionType__c;
        if (subType === 'One-time') return;
        if (rec.SBQQ__ProductCode__c !== 'FWCCY1000' && rec.SBQQ__ProductCode__c !== 'FWXB1000') return;

        const currentQty = Number(rec.SBQQ__Quantity__c || 0);
        if (currentQty <= 0) return;

        const isStepUpGroup = isRamping(line);
        const groupId = getGroupId(line);

        let baseComboParts = [
            rec.SBQQ__ProductCode__c || '',
            rec.Ship_To_Account__c || '',
            rec.Transaction_Currency__c || '',
            rec.Payment_Method__c || '',
            rec.Transaction_Type__c || '',
            rec.CC_Country__c || '',
            rec.Surcharging__c || '',
            rec.Non_Local_Currency__c || '',
            rec.Payer__c || 'NoPayer'
        ];

        let baseComboKey = baseComboParts.join('|');

        // --- 1. CROSS-GROUP EVALUATION (Unramped vs Unramped AND Ramped vs Unramped) ---
        let crossGroupMatch = false;

        quoteLineModels.forEach(function(otherLine) {
            if (line === otherLine || crossGroupMatch) return;
            const oRec = otherLine.record;
            if (!oRec || oRec.SBQQ__IsDeleted__c === true) return;

            const oSubType = oRec.SBQQ__SubscriptionType__c || oRec.SBQQ__ProductSubscriptionType__c;
            if (oSubType === 'One-time') return;
            if (oRec.SBQQ__ProductCode__c !== 'FWCCY1000' && oRec.SBQQ__ProductCode__c !== 'FWXB1000') return;
            if (Number(oRec.SBQQ__Quantity__c || 0) <= 0) return;

            const isOtherGroupRamping = isRamping(otherLine);

            // Trigger match if:
            // - Both are Unramped OR
            // - One is Ramped and the other is Unramped
            if (!isStepUpGroup || !isOtherGroupRamping) {
                const otherBaseKey = [
                    oRec.SBQQ__ProductCode__c || '',
                    oRec.Ship_To_Account__c || '',
                    oRec.Transaction_Currency__c || '',
                    oRec.Payment_Method__c || '',
                    oRec.Transaction_Type__c || '',
                    oRec.CC_Country__c || '',
                    oRec.Surcharging__c || '',
                    oRec.Non_Local_Currency__c || '',
                    oRec.Payer__c || 'NoPayer'
                ].join('|');

                if (baseComboKey === otherBaseKey) {
                    crossGroupMatch = true;
                }
            }
        });

        if (crossGroupMatch) {
            quoteModel.record['IsSamePaymentMethodAdded__c'] = true;
        }

        // --- 2. INTRA-GROUP & RAMPED GROUP EVALUATION ---
        let comboParts = [...baseComboParts];
        if (isStepUpGroup) {
            comboParts.push(groupId);
        }

        let prodCombination = comboParts.join('|');

        if (uniqueProdMap.has(prodCombination)) {
            quoteModel.record['IsSamePaymentMethodAdded__c'] = true;
        } else {
            uniqueProdMap.set(prodCombination, true);
        }
    });
}

/**
 * ============================================================================
 * FUNCTION: checkPaymentAndCountryMatrixRules
 * ============================================================================
 * SALDEV-1347 / SALDEV-1441:
 * Validates CC Country Twin rules (Locally Issued vs Non-Locally Issued) and 
 * MC/Visa Matrix rules (Credit vs Debit quad-pairings) per validation context.
 */
function checkPaymentAndCountryMatrixRules(quoteModel, quoteLineModels) {
    if (!quoteLineModels) return;

    // Reset both Product Rule flags to false on initial load/calculation loop
    quoteModel.record['Is_Identical_CC_Country_Exist__c'] = false; // True fires Country Rule
    quoteModel.record['Is_MC_Visa_Pair_Exist__c'] = false;         // True fires MC/Visa Rule

    if (!quoteLineModels.length) return;

    const targetProducts = ['FWCCY1000', 'FWXB1000'];
    const mcVisaMethods = ['MC/Visa Credit', 'MC/Visa Debit'];

    let countryTwinError = false;
    let mcVisaMatrixError = false;

    // SALDEV-1441:
    // Keep non-Step-Up lines in one quote-wide context, but validate every
    // Step-Up group independently. getValidationContext() also resolves the
    // effective group of nested bundle children through their root line.
    //
    // Core grouping map:
    // ValidationContext + Product + ShipTo + Currency + TransactionType
    const matrixGroups = {};

    // 1. Populate the operational combinations matrix
    quoteLineModels.forEach(line => {
        const currentRec = line.record;
        if (!currentRec || currentRec.SBQQ__IsDeleted__c === true || Number(currentRec.SBQQ__Quantity__c || 0) <= 0) return;

        const productCode = (currentRec.SBQQ__ProductCode__c || '').trim();
        const paymentMethod = (currentRec.Payment_Method__c || '').trim();
        const ccCountry = (currentRec.CC_Country__c || '').trim();
        const shipTo = (currentRec.Ship_To_Account__c || '');
        const currency = (currentRec.Transaction_Currency__c || '');
        const transType = (currentRec.Transaction_Type__c || '').trim();

        if (targetProducts.includes(productCode)) {
            const validationContext = getValidationContext(line);
            const groupKey = [
                validationContext,
                productCode,
                shipTo,
                currency,
                transType
            ].join('|');

            if (!matrixGroups[groupKey]) {
                matrixGroups[groupKey] = [];
            }
            matrixGroups[groupKey].push({
                rec: currentRec,
                payment: paymentMethod,
                country: ccCountry,
                qty: Number(currentRec.SBQQ__Quantity__c || 0)
            });
        }
    });

    // 2. Structural evaluation loop for each unique bucket group
    for (const key in matrixGroups) {
        if (!matrixGroups.hasOwnProperty(key)) continue;

        const lines = matrixGroups[key];

        // --- SUB-RULE 1: COUNTRY TWIN CROSS-CHECK ---
        lines.forEach(item => {
            if (item.country === 'Locally Issued') {
                const hasNonLocalTwin = lines.some(twin => 
                    twin.country === 'Non-Locally Issued' && 
                    twin.payment === item.payment && 
                    twin.qty === item.qty
                );
                if (!hasNonLocalTwin) countryTwinError = true;
            }
            if (item.country === 'Non-Locally Issued') {
                const hasLocalTwin = lines.some(twin => 
                    twin.country === 'Locally Issued' && 
                    twin.payment === item.payment && 
                    twin.qty === item.qty
                );
                if (!hasLocalTwin) countryTwinError = true;
            }
        });

        // --- SUB-RULE 2: MC/VISA MATRIX PAIRING MATRIX (Credit vs Debit) ---
        const hasMcVisa = lines.some(item => mcVisaMethods.includes(item.payment));

        if (hasMcVisa) {
            const usesAllWildcard = lines.some(item => item.country.toLowerCase() === 'all');

            if (usesAllWildcard) {
                const credits = lines.filter(item => item.payment === 'MC/Visa Credit' && item.country.toLowerCase() === 'all');
                const debits = lines.filter(item => item.payment === 'MC/Visa Debit' && item.country.toLowerCase() === 'all');

                if (credits.length !== debits.length || credits.length === 0) {
                    mcVisaMatrixError = true;
                } else {
                    for (let i = 0; i < credits.length; i++) {
                        if (credits[i].qty !== debits[i].qty) {
                            mcVisaMatrixError = true;
                            break;
                        }
                    }
                }
            } else {
                let creditLocalCount = 0;
                let debitLocalCount = 0;
                let creditNonLocalCount = 0;
                let debitNonLocalCount = 0;

                let baseQty = -1;
                let qtyMismatch = false;

                lines.forEach(item => {
                    if (!mcVisaMethods.includes(item.payment)) return;

                    if (baseQty === -1) {
                        baseQty = item.qty;
                    } else if (item.qty !== baseQty) {
                        qtyMismatch = true;
                    }

                    if (item.payment === 'MC/Visa Credit' && item.country === 'Locally Issued') creditLocalCount++;
                    if (item.payment === 'MC/Visa Debit' && item.country === 'Locally Issued') debitLocalCount++;
                    if (item.payment === 'MC/Visa Credit' && item.country === 'Non-Locally Issued') creditNonLocalCount++;
                    if (item.payment === 'MC/Visa Debit' && item.country === 'Non-Locally Issued') debitNonLocalCount++;
                });

                // If any quadrant configuration is missing or duplicated, mark it as an error
                if (
                    creditLocalCount !== 1 || 
                    debitLocalCount !== 1 || 
                    creditNonLocalCount !== 1 || 
                    debitNonLocalCount !== 1 ||
                    qtyMismatch
                ) {
                    mcVisaMatrixError = true;
                }
            }
        }
    }

    // 3. Update the fields based on findings (Setting true forces Product Rules to fire)
    if (countryTwinError) {
        quoteModel.record['Is_Identical_CC_Country_Exist__c'] = true;
    }
    if (mcVisaMatrixError) {
        quoteModel.record['Is_MC_Visa_Pair_Exist__c'] = true; // Sets to TRUE to trip your Validation Rule!
    }
}

/**
 * ============================================================================
 * FUNCTION: checkRequiredApprovals
 * ============================================================================
 * BOPI-773: Checks Exception Pricing and Revenue Approval requirements for 
 * non-MoR products and discounted domestic lines.
 */
function checkRequiredApprovals(quoteModel, quoteLineModels) {
quoteModel.record.Requires_Exception_Pricing_Approval__c = false;
quoteModel.record.Requires_Revenue_Approval__c = false;

let containsFreeXB = false;
let containsFreeDOM = false;
let discountedDomNotBankTransfer = false;

for (const line of quoteLineModels) {
if (['New', 'Quantity Increase', 'Quantity Reduction'].includes(line.record.Quote_Line_Type__c)) {
if (line.record.Exception_Pricing__c === true) {
quoteModel.record.Requires_Exception_Pricing_Approval__c = true;
}
// BOPI-773 Products where Flywire is NOT MoR should require approval
if (['FWPAY1700','FWPAY1900'].includes(line.record.SBQQ__ProductCode__c)) {
quoteModel.record.Requires_Revenue_Approval__c = true;
} else if (line.record.Rev_Share__c === true) {
quoteModel.record.Requires_Revenue_Approval__c = true;
}

const usageRateAmt = line.record.Usage_Rate_Amt__c;
const usageRatePrct = line.record.Usage_Rate__c;
const adjustedRateAmt = line.record.Adjusted_Rate_Amount__c;
const adjustedRatePrct = line.record.Adjusted_Rate_Percent__c;

// BOPI-773 For a quote that contains both the free version of XB and DOM line item,
// if the DOM line uses the 'Bank Transfer' payment method and is discounted,
// that discounted DOM line does not require an approval
if (line.record.SBQQ__ProductCode__c === 'FWXB1000' && !containsFreeXB) {
if (!usageRateAmt && !usageRatePrct) {
if (!adjustedRateAmt && !adjustedRatePrct) {
containsFreeXB = true;
}
}
}
if (line.record.SBQQ__ProductCode__c === 'FWCCY1000' && line.record.Payment_Method__c === 'Bank Transfer') {
if (adjustedRateAmt === 0 || adjustedRatePrct > 0) {
containsFreeDOM = true;
}
}
// BOPI-773 If there is free XB and free DOM Bank Transfer but there are also
// other Domestic lines with > 20% discount then it requires approval
if (line.record.SBQQ__ProductCode__c === 'FWCCY1000' && line.record.Payment_Method__c !== 'Bank Transfer') {
if (adjustedRatePrct || adjustedRateAmt) {
const adjustedRatePrctDiscount = 1 - (adjustedRatePrct / usageRatePrct);
const adjustedRateAmtDiscount = 1 - (adjustedRateAmt / usageRateAmt);

if (adjustedRatePrctDiscount > 0.2 || adjustedRateAmtDiscount > 0.2) {
discountedDomNotBankTransfer = true;
} else {
discountedDomNotBankTransfer = false;
}
}
}
}
}

if (discountedDomNotBankTransfer) {
quoteModel.record.DOM_Discount_Requires_Approval__c = discountedDomNotBankTransfer;
} else {
quoteModel.record.DOM_Discount_Requires_Approval__c = !(containsFreeXB && containsFreeDOM);
}
}

/**
 * Ensures ARR completion is required on exactly one line per Ship To Account for target products.
 */
function requireARROnOneLinePerShipTo(quoteLineModels, productCode) {
const sameProductlinesPerShipTo = new Map();
// Group quote lines by Ship_To_Account__c
for (const line of quoteLineModels) {
if (line.record.SBQQ__ProductCode__c === productCode && line.record.Quote_Line_Type__c === 'New') {
if (!sameProductlinesPerShipTo.has(line.record.Ship_To_Account__c)) {
sameProductlinesPerShipTo.set(line.record.Ship_To_Account__c, [line.record]);
}
else {
sameProductlinesPerShipTo.get(line.record.Ship_To_Account__c)
.push(line.record);
}
}
}
// Ensure only one line per Ship_To_Account__c has Requires_ARR_Fields_Completion__c set to true
for (const [shipTo, lines] of sameProductlinesPerShipTo) {
let firstLine = null;
// Find an existing line that already has Requires_ARR_Fields_Completion__c = true
for (const line of lines) {
if (line.Requires_ARR_Fields_Completion__c) {
firstLine = line;
break;
}
}
// If no existing line has it set, pick the first available one
if (!firstLine && lines.length > 0) {
firstLine = lines[0];
}
// Now set/reset values
for (const line of lines) {
line.Requires_ARR_Fields_Completion__c = (line === firstLine);
}
}
}

/**
 * Evaluates the effective active rate across adjusted and baseline rate fields.
 */
const getEffectivePrice = (rec) => {

if (rec.Adjusted_Rate_Amount__c != null) {
return Number(rec.Adjusted_Rate_Amount__c);
}

if (rec.Adjusted_Rate_Percent__c != null) {
return Number(rec.Adjusted_Rate_Percent__c);
}

if (rec.Usage_Rate__c != null) {
return Number(rec.Usage_Rate__c);
}

if (rec.Usage_Rate_Amt__c != null) {
return Number(rec.Usage_Rate_Amt__c);
}

return 0;
}

/**
 * SALDEV-959: Handles Ship To Account cascading from parent bundles down to child lines.
 */
function handleAccountCascadeAndValidation(quoteLineModels) {
    if (!quoteLineModels || !quoteLineModels.length) return;

    quoteLineModels.forEach(function(currentLine) {
        const currentRec = currentLine.record;
        if (!currentRec) return;

        if (currentRec.SBQQ__Bundle__c === true) {
            
            const currentAccount = currentRec.Ship_To_Account__c;

            if (currentAccount !== currentRec.Parent_Ship_to_Account__c) {
                
                cascadeToDescendants(currentLine, currentAccount, quoteLineModels);
            }
        }
    });
}

/**
 * SALDEV-959: Helper function to recursively cascade Ship To Account updates to nested descendants.
 */
function cascadeToDescendants(parentModel, newAccountValue, allModels) {
    allModels.forEach(function(childLine) {
        
        if (childLine.parentItem === parentModel) {
            
            childLine.record.Ship_To_Account__c = newAccountValue;

            if (childLine.record.SBQQ__Bundle__c === true) {
                cascadeToDescendants(childLine, newAccountValue, allModels);
            }
        }
    });
}