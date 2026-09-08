/*
 * Passfort Util class to handle all the business logic
 * Test class: PassfortTest 
 * */
public without sharing class PassfortUtil {
    
    public static PassfortProfileProcessingWrapper updateAccout(String profileId, Passfort_Webhook_Log__c log) {
        PassfortProfileProcessingWrapper wrapper = new PassfortProfileProcessingWrapper();

        String logMessage ='';
        try{
            System.debug('PassfortUtil.updateAccout()');
            String accountIds = '';
            if(profileId != null && profileId != '') {
                
                //Get profile data FROM passfort
                HttpResponse profileRespone = Passfort.getProfileDetails(profileId);
                if(profileRespone.getStatusCode() != 200) {
                    throw new PassfortWebhook.RequestBodyException('\nprofileRespone status code.'+profileRespone.getStatusCode()+'body: '+profileRespone.getBody().tostring());
                }
                
                PassfortProfile PassfortProfileVar;
                PassfortProfileVar = PassfortProfile.parse( profileRespone.getBody().tostring());
                
                System.debug('PassfortProfileVar id: '+ PassfortProfileVar.id);

                List<Account> accountList = new List<Account>();
                accountList = [SELECT id , Name, Passfort_Profile_Id__c FROM Account WHERE Passfort_Profile_Id__c  =: profileId ];
                if(accountList.size() == 0) {
                    System.debug('Account for profileId ' + profileId + ' does not exists in Salesforce');
                    if(PassfortProfileVar.collected_data != null) {
                        if(PassfortProfileVar.collected_data.custom_fields_data != null) {
                            if(PassfortProfileVar.collected_data.custom_fields_data.s_company_id != null) {
                                accountList = [SELECT id , Name, Passfort_Profile_Id__c FROM Account 
                                               WHERE id  =: PassfortProfileVar.collected_data.custom_fields_data.s_company_id ];
                            }
                        }
                    }
                }

                if(accountList.size() == 0) {
                    logMessage = '\n Account for profileId ' + profileId + ' does not exists in Salesforce';
                } else if(accountList.size() == 1) {
                    System.debug('Account for profileId '+ profileId + ': ' + accountList[0].Id);
                    
                    Account profileAccount = new Account();
                    profileAccount = accountList[0];
                    profileAccount.Passfort_Profile_Id__c = PassfortProfileVar.id;
                    profileAccount.KYC_Risk_Level__c = PassfortProfileVar?.risk?.overall_risk?.category;
                    profileAccount.KYC_Risk_Score__c = PassfortProfileVar?.risk?.overall_risk?.score;
                    if(PassfortProfileVar.tags != null) {
                        String profileTags ='';
                        for(PassfortProfile.TagsClass tagForVar : PassfortProfileVar.tags) {
                            profileTags = profileTags + tagForVar.Name;
                            profileTags = profileTags + ',';
                        }
                        if(profileTags !='') {
                            profileAccount.KYC_Tags__c  = profileTags;
                        }
                    }
                    if(PassfortProfileVar?.collected_data?.custom_fields_data?.d_qa != null) {
                        profileAccount.KYC_QA__c = PassfortProfileVar.collected_data.custom_fields_data.d_qa;
                    }
                    if(PassfortProfileVar?.collected_data?.custom_fields_data?.d_qa != null) {
                        profileAccount.KYC_QC__c = PassfortProfileVar.collected_data.custom_fields_data.s_qc ;
                    }

                    profileAccount.Acc_Bypass_DateTime__c = Datetime.now();
                    
                    wrapper.acct = profileAccount;
                    logMessage = logMessage + '\n Account found: '+ accountList[0].Id;
                    logMessage = logMessage + '\nUpdated Account Id: '+ accountList[0].Id;
                    
                    //Upsert KYC records
                    if(PassfortProfileVar.applications!= null ) {
                        if(PassfortProfileVar.applications.size() > 0) {
                            List<String> applicationIdList = new List<String>();
                            for(PassfortProfile.ApplicationsClass application :  PassfortProfileVar.applications) {
                                applicationIdList.add(application.id);
                            }
                            //Get existing KYC records
                            List<KYC_Application__c> kycAppExistingList = new List<KYC_Application__c>();
                            kycAppExistingList = [SELECT Id ,Application_ID__c, Account__c
                                                  FROM KYC_Application__c 
                                                  WHERE Application_ID__c IN: applicationIdList AND Account__c =: profileAccount.Id];
                            Map<String, KYC_Application__c> passforAppIdVsKYCRecordMap = new Map<String, KYC_Application__c>();
                            for(KYC_Application__c kycForVar: kycAppExistingList) {
                                passforAppIdVsKYCRecordMap.put(kycForVar.Application_ID__c, kycForVar);
                            }
                            List<KYC_Application__c> kycAppToUpsertList = new List<KYC_Application__c>();

                            String registeredAddress  = '';
                            PassfortProfile.AddressClass registeredAddressvar;
                            List<PassfortProfile.AddressesClass> addresses = PassfortProfileVar?.collected_data?.metadata?.addresses;
                            if (addresses != null && !addresses.isEmpty()) {
                                for(PassfortProfile.AddressesClass currentAddress : addresses) {
                                    if(currentAddress.address != null && currentAddress.type == 'registered_address') {
                                        registeredAddress =  currentAddress?.address?.original_freeform_address+' ' + currentAddress?.address?.country;
                                        registeredAddressvar = currentAddress?.address;
                                    }
                                }                                    
                            }

                            String legalName = PassfortProfileVar.collected_data?.metadata?.name;
                            String companyNumber = PassfortProfileVar.collected_data?.metadata?.companyNumber;
                            
                            for(PassfortProfile.ApplicationsClass application :  PassfortProfileVar.applications) {
                                //Get custom fields from collections
                                Map<String, string> componenetCustomFieldsMap = new map<String,string>();
                                if(application?.risk?.breakdown?.components != null) {
                                    for(PassfortProfile.ComponentsClass componentForVar : application.risk.breakdown.components) {
                                        if(componentForVar.category.type == 'CUSTOM_FIELD') {
                                            componenetCustomFieldsMap.put(componentForVar.category.custom_field_name, componentForVar.input_value);
                                        }else if(componentForVar.category.type == 'COUNTRY_OF_INCORPORATION') {
                                            componenetCustomFieldsMap.put('COUNTRY_OF_INCORPORATION', componentForVar.input_value);
                                        }
                                    }
                                }
                                
                                KYC_Application__c kycVar = new KYC_Application__c();
                                if(passforAppIdVsKYCRecordMap.get(application.id) != null) {
                                    kycVar.Id = passforAppIdVsKYCRecordMap.get(application.id).Id;
                                }
                                kycVar.Account__c = profileAccount?.Id;
                                kycVar.Application_ID__c = application?.id;
                                kycVar.Status__c = application?.status;
                                kycVar.Flag__c = application?.flag;
                                kycVar.Product_Name__c = application?.product?.name;
                                kycVar.Application_decided_with_STP__c = application?.product?.automatically_approve;
                                
                                if (legalName != null && legalName != '') {
                                    kycVar.Company_Legal_Name__c = legalName;
                                }
                                if (companyNumber != null && companyNumber != '') {
                                    kycVar.Company_Number__c = companyNumber;
                                }
                                if (registeredAddress != null && registeredAddress != '') {
                                    kycVar.Company_Registered_Address__c = registeredAddress.length() > 255 ? registeredAddress.substring(0, 255) : registeredAddress;
                                    kycVar.Company_Registered_Country__c = registeredAddressvar?.country;
                                    kycVar.Company_Registered_State__c = registeredAddressvar?.state_province;
                                    kycVar.Company_Registered_Locality__c = registeredAddressvar?.locality;
                                    kycVar.Company_Registered_Postal_Code__c = registeredAddressvar?.postal_code;
                                    kycVar.Company_Registered_Route__c = registeredAddressvar?.route;
                                    kycVar.Company_Registered_Street_Number__c   = registeredAddressvar?.street_number;
                                }

                                if (PassfortProfileVar.collected_data?.metadata?.incorporation_date != null) {
                                    try {
                                        Date pfDate = Date.valueof(PassfortProfileVar.collected_data?.metadata?.incorporation_date);
                                        if (pfDate.year() < 1700) {
                                            pfDate = pfDate.addYears(1700 - pfDate.year());
                                        }
                                        kycVar.Orbis_Incorporation_Date__c = pfDate;
                                    } catch (Exception e) {
                                        // throw new PassfortWebhook.RequestBodyException('Couldn\'t parse orbis incorporation date value: ' + PassfortProfileVar.collected_data?.metadata?.incorporation_date);
                                        System.debug('Couldn\'t parse orbis incorporation date value: ' + PassfortProfileVar.collected_data?.metadata?.incorporation_date);
                                    }
                                }

                                if (PassfortProfileVar.collected_data?.metadata?.tax_ids != null) {
                                    List<PassfortProfile.TaxId> taxIds = PassfortProfileVar.collected_data?.metadata?.tax_ids;
                                    if (!taxIds.isEmpty()) {
                                        kycVar.Orbis_Tax_ID__c = taxIds[0].value;
                                    }
                                }
                                
                                //check assignments
                                if(application.assignments != null) {
                                    for( PassfortProfile.AssignmentsClass assignmentForVar : application.assignments) {
                                        if(assignmentForVar.assignee != null) {
                                            kycVar.KYC_Assignee__c  = assignmentForVar.assignee.name;
                                        }
                                    }
                                }
                                
                                //from collected_data
                                kycVar.Flywire_Entity__c = PassfortProfileVar.collected_data.custom_fields_data.s_flywire_entity; 
                                kycVar.Vertical__c = PassfortProfileVar.collected_data.custom_fields_data.s_vertical; 
                                
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_trading_name  != null) {
                                    kycVar.Trading_Name__c = PassfortProfileVar.collected_data.custom_fields_data.s_trading_name ; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_1_d_trading_name_2 != null) {
                                    kycVar.X2nd_Trading_Name__c = PassfortProfileVar.collected_data.custom_fields_data.s_1_d_trading_name_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_website_url  != null) {
                                    String websiteString = PassfortProfileVar.collected_data.custom_fields_data.s_website_url;
                                    kycVar.Website__c = websiteString.length() > 255 ? websiteString.substring(0, 255) : websiteString;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.d_incorporation_date != null) {
                                    try {
                                        Date pfDate = Date.valueof(PassfortProfileVar.collected_data.custom_fields_data.d_incorporation_date);
                                        if (pfDate.year() < 1700) {
                                            pfDate = pfDate.addYears(1700 - pfDate.year());
                                        }
                                        kycVar.Incorportation_Date__c = pfDate;
                                    } catch (Exception e) {
                                        // throw new PassfortWebhook.RequestBodyException('Couldn\'t parse incorporation date value: ' + PassfortProfileVar.collected_data.custom_fields_data.d_incorporation_date);
                                        System.debug('Couldn\'t parse incorporation date value: ' + PassfortProfileVar.collected_data.custom_fields_data.d_incorporation_date);
                                    }
                                }
                                String emailString = PassfortProfileVar.collected_data.custom_fields_data.s_contact_email_address;
                                if( emailString != null && EmailValidator.isValidEmail(emailString)) {
                                    kycVar.Contact_Email_Address__c = emailString;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_entity_type != null) {
                                    kycVar.Entity_Type__c = PassfortProfileVar.collected_data.custom_fields_data.s_entity_type; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_1_n_tax_id_number != null) {
                                    kycVar.Tax_ID_Number__c = PassfortProfileVar.collected_data.custom_fields_data.s_1_n_tax_id_number;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_web_review != null) {
                                    kycVar.Website_Reviewed__c = PassfortProfileVar.collected_data.custom_fields_data.s_web_review;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_verify_open_loop != null) {
                                    kycVar.Open_Loop_Verified__c = PassfortProfileVar.collected_data.custom_fields_data.s_verify_open_loop;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_bo_at_25 != null) {
                                    kycVar.Business_Owner_at_25__c = PassfortProfileVar.collected_data.custom_fields_data.s_bo_at_25;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_address_check_select != null) {
                                    kycVar.Business_Address_Reviewed__c = PassfortProfileVar.collected_data.custom_fields_data.s_address_check_select;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_mlro_delegate_high_risk != null) {
                                    kycVar.MLRO_Delegate_High_Risk_Approver__c = PassfortProfileVar.collected_data.custom_fields_data.s_mlro_delegate_high_risk;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_estimated_number_of_students_payers_annually != null) {
                                    kycVar.Est_Number_of_Annual_Payers__c = PassfortProfileVar.collected_data.custom_fields_data.n_estimated_number_of_students_payers_annually;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_purpose_of_payments != null) {
                                    String purposeOfPayments = PassfortProfileVar.collected_data.custom_fields_data.s_purpose_of_payments;
                                    if (purposeOfPayments.length() > 255) {
                                        purposeOfPayments = purposeOfPayments.substring(0,255);
                                    }
                                    kycVar.Purpose_of_Payments__c = purposeOfPayments;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_currency_selection_payment_ss != null) {
                                    kycVar.Currency__c = PassfortProfileVar.collected_data.custom_fields_data.s_currency_selection_payment_ss;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_maximum_payment_size_2 != null) {
                                    kycVar.Max_Payment_Size__c = PassfortProfileVar.collected_data.custom_fields_data.n_maximum_payment_size_2;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_project_value_of_payments_2 != null) {
                                    kycVar.Projected_Value_Payments_Next_12_Months__c = PassfortProfileVar.collected_data.custom_fields_data.n_project_value_of_payments_2;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_total_value_of_payments_2 != null) {
                                    kycVar.Total_Value_Payments_Past_12_Months__c = PassfortProfileVar.collected_data.custom_fields_data.n_total_value_of_payments_2;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_typical_payment_size_1 != null) {
                                    kycVar.Typical_Payment_Size__c = PassfortProfileVar.collected_data.custom_fields_data.n_typical_payment_size_1;
                                }
                                try {
                                    if( PassfortProfileVar.collected_data.custom_fields_data.s_transaction_1_1 != null) {
                                        kycVar.Country_1_Transaction_Percent__c = Decimal.valueof(PassfortProfileVar.collected_data.custom_fields_data.s_transaction_1_1.replace('%', '').replace(',', '.').trim());
                                    }
                                    if( PassfortProfileVar.collected_data.custom_fields_data.s_transaction_1 != null) {
                                        kycVar.Country_2_Transaction_Percent__c = Decimal.valueof(PassfortProfileVar.collected_data.custom_fields_data.s_transaction_1.replace('%', '').replace(',', '.').trim());
                                    }
                                    if( PassfortProfileVar.collected_data.custom_fields_data.s_transaction_3 != null) {
                                        kycVar.Country_3_Transaction_Percent__c = Decimal.valueof(PassfortProfileVar.collected_data.custom_fields_data.s_transaction_3.replace('%', '').replace(',', '.').trim());
                                    }
                                    if( PassfortProfileVar.collected_data.custom_fields_data.s_transaction_4 != null) {
                                        kycVar.Country_4_Transaction_Percent__c = Decimal.valueof(PassfortProfileVar.collected_data.custom_fields_data.s_transaction_4.replace('%', '').replace(',', '.').trim());
                                    }
                                    if( PassfortProfileVar.collected_data.custom_fields_data.s_transaction_5 != null) {
                                        kycVar.Country_5_Transaction_Percent__c = Decimal.valueof(PassfortProfileVar.collected_data.custom_fields_data.s_transaction_5.replace('%', '').replace(',', '.').trim());
                                    }
                                } catch (Exception e) {
                                    // throw new PassfortWebhook.RequestBodyException('Couldn\'t parse decimal value');
                                    System.debug('Couldn\'t parse decimal value');
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_bank_account_name != null) {
                                    kycVar.Bank_Account_Name__c = PassfortProfileVar.collected_data.custom_fields_data.s_bank_account_name;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_bank_bic_swift_code != null) {
                                    kycVar.Bank_BIC_SWIFT_Code__c = PassfortProfileVar.collected_data.custom_fields_data.s_bank_bic_swift_code;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_bank_iban != null) {
                                    kycVar.Bank_IBAN__c = PassfortProfileVar.collected_data.custom_fields_data.s_bank_iban;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_money_moved_annually_2 != null) {
                                    kycVar.Annual_Money_Moved_Credit_Cards__c = PassfortProfileVar.collected_data.custom_fields_data.n_money_moved_annually_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_money_moved_annually_debit_cards != null) {
                                    kycVar.Annual_Money_Moved_Debit_Cards__c = PassfortProfileVar.collected_data.custom_fields_data.n_money_moved_annually_debit_cards; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_1 != null) {
                                    kycVar.Advance_Payment_1_Type_Accepted__c = PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_other_text_1 != null) {
                                    kycVar.Other_Advance_Payments_1__c = PassfortProfileVar.collected_data.custom_fields_data.s_other_text_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_1 != null) {
                                    kycVar.Advance_Payments_1_Processing_Volume__c = PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_how_far_in_advance_1 != null) {
                                    kycVar.Advance_Payments_1_Days_Accepted_Final__c = PassfortProfileVar.collected_data.custom_fields_data.n_how_far_in_advance_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_2 != null) {
                                    kycVar.Advance_Payment_2_Type_Accepted__c = PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_other_text_2 != null) {
                                    kycVar.Other_Advance_Payments_2__c = PassfortProfileVar.collected_data.custom_fields_data.s_other_text_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_2 != null) {
                                    kycVar.Advance_Payments_2_Processing_Volume__c = PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_how_far_in_advance_3 != null) {
                                    kycVar.Advance_Payments_2_Days_Accepted_Final__c = PassfortProfileVar.collected_data.custom_fields_data.n_how_far_in_advance_3; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_credit_card_payments != null) {
                                    kycVar.Will_Process_Credit_Card_Payments__c = PassfortProfileVar.collected_data.custom_fields_data.s_credit_card_payments; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_advance_payments != null) {
                                    kycVar.Accept_Advance_Payments__c = PassfortProfileVar.collected_data.custom_fields_data.s_advance_payments; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_2_1 != null) {
                                    kycVar.Final_One_Time_1_Payment_Purpose__c = PassfortProfileVar.collected_data.custom_fields_data.s_advance_payment_types_2_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_other_text_3 != null) {
                                    kycVar.Final_One_Time_1_Other_Payments__c = PassfortProfileVar.collected_data.custom_fields_data.s_other_text_3; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_1 !=null) {
                                    kycVar.Final_One_Time_1_Processing_Volume__c = PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_1 != null) {
                                    kycVar.Final_One_Time_1_Payment_Collection__c = PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_1; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_final_payments != null) {
                                    kycVar.Final_One_Time_2_Payment_Purpose__c = PassfortProfileVar.collected_data.custom_fields_data.s_final_payments; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_other_text_final_2 != null) {
                                    kycVar.Final_One_Time_2_Other_Payments__c = PassfortProfileVar.collected_data.custom_fields_data.s_other_text_final_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_2 != null) {
                                    kycVar.Final_One_Time_2_Processing_Volume__c = PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_2 != null) {
                                    kycVar.Final_One_Time_2_Payment_Collection__c = PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_2; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_final_payments_3 != null) {
                                    kycVar.Final_One_Time_3_Payment_Purpose__c = PassfortProfileVar.collected_data.custom_fields_data.s_final_payments_3; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_other_text_final_3 != null) {
                                    kycVar.Final_One_Time_3_Other_Payments__c = PassfortProfileVar.collected_data.custom_fields_data.s_other_text_final_3; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_3 != null) {
									kycVar.Final_One_Time_3_Processing_Volume__c = PassfortProfileVar.collected_data.custom_fields_data.n_percentage_volume_other_3;
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_3 != null) {
                                    kycVar.Final_One_Time_3_Payment_Collection__c = PassfortProfileVar.collected_data.custom_fields_data.n_payment_collection_3; 
                                }
                                if( PassfortProfileVar.collected_data.custom_fields_data.s_terms_and_conditions_url != null) {
                                    String refundCancellationTerms = PassfortProfileVar.collected_data.custom_fields_data.s_terms_and_conditions_url;
                                    if (refundCancellationTerms.length() > 255) {
                                        refundCancellationTerms = refundCancellationTerms.substring(0,255);
                                    }
                                    kycVar.Refund_Cancellation_Terms__c = refundCancellationTerms;
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.m_payment_months != null) {
                                    kycVar.Peak_Processing_Months__c = string.join(PassfortProfileVar.collected_data.custom_fields_data.m_payment_months,','); 
                                }
                                
                                if(PassfortProfileVar.collected_data.custom_fields_data.m_countries_of_final_destinations_2 != null) {
                                    String countriesOfFinalDestination = string.join(PassfortProfileVar.collected_data.custom_fields_data.m_countries_of_final_destinations_2,',');
                                    if (countriesOfFinalDestination.length() > 255) {
                                        countriesOfFinalDestination = countriesOfFinalDestination.substring(0,255);
                                    }
                                    kycVar.Countries_of_Final_Destination__c = countriesOfFinalDestination;
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.m_currency_selection_credit != null) {
                                    kycVar.Credit_Card_Currency__c = string.join(PassfortProfileVar.collected_data.custom_fields_data.m_currency_selection_credit,','); 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_declaration != null) {
                                    kycVar.Customer_Declaration__c = PassfortProfileVar.collected_data.custom_fields_data.s_declaration; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_phone_number != null) {
                                    kycVar.Phone_number__c  = PassfortProfileVar.collected_data.custom_fields_data.s_phone_number; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_prohibited_ownership != null) {
                                    kycVar.Prohibited_Ownership__c = PassfortProfileVar.collected_data.custom_fields_data.s_prohibited_ownership; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_prohibited_services != null) {
                                    kycVar.Prohibited_Services__c = PassfortProfileVar.collected_data.custom_fields_data.s_prohibited_services; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_3_d_verified_bank_details != null) {
                                    kycVar.Verified_Bank_Details__c = PassfortProfileVar.collected_data.custom_fields_data.s_3_d_verified_bank_details; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_reduction != null) {
                                    kycVar.Risk_Calibration__c = PassfortProfileVar.collected_data.custom_fields_data.s_reduction; 
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_charity_reg_number != null) {
                                    kycVar.Charity_Registration_Number__c = PassfortProfileVar.collected_data.custom_fields_data.s_charity_reg_number;
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_product != null) {
                                    kycVar.Flywire_Product__c = PassfortProfileVar.collected_data.custom_fields_data.s_product;
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.m_kyc_review_status_applied != null) {
                                    List<String> reviewStatuses = PassfortProfileVar.collected_data.custom_fields_data.m_kyc_review_status_applied;
                                    String reviewStatusesMultipicklist = '';
                                    for (String currentReviewStatus : reviewStatuses) {
                                        reviewStatusesMultipicklist += currentReviewStatus + ';';
                                    }
                                    reviewStatusesMultipicklist.removeEnd(';');
                                    kycVar.Application_Review_Status__c = reviewStatusesMultipicklist;
                                }
                                if(PassfortProfileVar.collected_data.custom_fields_data.s_batch_tag != null) {
                                    kycVar.Batch_Tag__c = PassfortProfileVar.collected_data.custom_fields_data.s_batch_tag;
                                }                               
                                
                                //from componenetCustomFieldsMap
                                if(componenetCustomFieldsMap.get('s_sic_code') != null) {
                                    kycVar.SIC_Code__c = componenetCustomFieldsMap.get('s_sic_code'); 
                                }
                                if(componenetCustomFieldsMap.get('s_complex_structure') != null) {
                                    kycVar.Complex_Structure__c = componenetCustomFieldsMap.get('s_complex_structure'); 
                                }
                                if(componenetCustomFieldsMap.get('s_tansaction_representation_country_1') != null ) {
                                    kycVar.Country_1_Transaction_Representation__c = componenetCustomFieldsMap.get('s_tansaction_representation_country_1'); 
                                }
                                if(componenetCustomFieldsMap.get('s_tansaction_representation_country_2') != null ) {
                                    kycVar.Country_2_Transaction_Representation__c = componenetCustomFieldsMap.get('s_tansaction_representation_country_2'); 
                                }
                                if(componenetCustomFieldsMap.get('s_tansaction_representation_country_3') != null ) {
                                    kycVar.Country_3_Transaction_Representation__c = componenetCustomFieldsMap.get('s_tansaction_representation_country_3'); 
                                }
                                if(componenetCustomFieldsMap.get('s_tansaction_representation_country_4') != null ) {
                                    kycVar.Country_4_Transaction_Representation__c = componenetCustomFieldsMap.get('s_tansaction_representation_country_4'); 
                                }
                                if(componenetCustomFieldsMap.get('s_transaction_representation_country_5') != null ) {
                                    kycVar.Country_5_Transaction_Representation__c = componenetCustomFieldsMap.get('s_transaction_representation_country_5'); 
                                }
                                //
                                if(componenetCustomFieldsMap.get('s_regulatory_status') != null ) {
                                    kycVar.Regulatory_Status__c  = componenetCustomFieldsMap.get('s_regulatory_status'); 
                                }
                                if(componenetCustomFieldsMap.get('s_delivery_channel') != null ) {
                                    kycVar.Delivery_channel__c  = componenetCustomFieldsMap.get('s_delivery_channel'); 
                                }
                                if(componenetCustomFieldsMap.get('s_transaction_representation_country_5') != null ) {
                                    kycVar.Country_5_Transaction_Representation__c = componenetCustomFieldsMap.get('s_transaction_representation_country_5'); 
                                }
                                
                                if(componenetCustomFieldsMap.get('COUNTRY_OF_INCORPORATION') != null ) {
                                    kycVar.Country_of_Incorporation__c  = componenetCustomFieldsMap.get('COUNTRY_OF_INCORPORATION'); 
                                }

                                if (application?.history != null) {
                                    for (PassfortProfile.cls_history currentHistory : application.history) {
                                        if (currentHistory.status == 'APPROVED') {
                                            try {
                                                kycVar.First_Decision_Date__c = Datetime.valueOf(currentHistory.statusDate);
                                            } catch (Exception e) {
                                                // throw new PassfortWebhook.RequestBodyException('Couldn\'t parse status history date value: ' + currentHistory.statusDate);
                                                System.debug('Couldn\'t parse status history date value: ' + currentHistory.statusDate);
                                            }
                                            break;
                                        }
                                    }
                                }

                                if (application?.risk?.breakdown?.components != null && !application?.risk?.breakdown?.components.isEmpty()) {
                                    for (PassfortProfile.ComponentsClass riskComponents : application.risk.breakdown.components) {
                                        if (riskComponents.name == 'Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Pep Risk') {
                                            kycVar.PEP_Risk__c = riskComponents.input_value;
                                        }
                                    }
                                }
                                
                                kycAppToUpsertList.add(kycVar);
                            }
                            if(!kycAppToUpsertList.isEmpty()) {
                                wrapper.apps.addAll(kycAppToUpsertList);
                            }
                        }
                    }

                } else {
                    for(Account accountForVar : accountList) {
                        accountIds = accountIds + accountForVar.Id;
                    }
                    throw new PassfortWebhook.RequestBodyException('Too many accounts found.\n'+accountIds);
                }
            }
            
        }catch(Exception e) {
            throw new PassfortWebhook.RequestBodyException('Error in updating Account/KYC record.\n'+e.getMessage()+'\n StackTraceString: \n'+e.getStackTraceString());
        }
        wrapper.logMessage = logMessage;
        return wrapper;
    }

    public class PassfortProfileProcessingWrapper {
        public String logMessage;
        public Account acct = null;
        public List<KYC_Application__c> apps = new List<KYC_Application__c>();
    }
}