/*
 * JSON Parser for Profiel JSON object from passfort. 
 * Test class: PassfortTest 
 * 
 *  https://developer.passfort.com/api#tag/Profiles/paths/~1profiles~1%7Bprofile_id%7D/get
 * */
public class PassfortProfile{
	public String id;
    public CollectedDataClass collected_data; 
    public ApplicationsClass[] applications;
    public ProfileRiskClass risk;
	//public String creation_date;	
	//public String role;	//INDIVIDUAL_CUSTOMER
	//public cls_verified_data verified_data;
	public ChecksClass[] checks;
	//public cls_collection_steps[] collection_steps;
	//public String display_name;	//String
	//public cls_task_types[] task_types;
	//public cls_tasks[] tasks;
	//public cls_events[] events;
	//public String category;	//CUSTOMER
	//public cls_document_images[] document_images;
	public TagsClass[] tags;
	//public cls_unresolved_event_types[] unresolved_event_types;
	//public cls_task_progress task_progress;
	//public boolean has_associates;
	//public boolean has_collection_steps;
	//public cls_linked_to linked_to;
    
    public class ProfileRiskClass{
        Public OverallRiskClass overall_risk;
    }
    
    public class TagsClass{
        Public String name;
        Public String id;
        Public boolean is_automatic;
    }
	public class CollectedDataClass {
		public CustomFieldsDataClass custom_fields_data;
		public String customer_ref;	
		public cls_documents[] documents;
		public cls_external_refs external_refs;
		public cls_fraud_detection fraud_detection;
		public String entity_type;	//INDIVIDUAL or COMPANY
		public cls_personal_details personal_details;
		public cls_address_history[] address_history;
		public cls_banking_details banking_details;
		public cls_contact_details contact_details;
		public cls_ip_location ip_location;
		public cls_documents_metadata[] documents_metadata;
		public MetadataClass metadata;
		public OfficersClass officers;
	}
	public class CustomFieldsDataClass {
        public String s_address_check;	
        public String s_delivery_channel;	
        public String s_entity_type;	
        public String s_flywire_entity;	
        public String s_product;	
        public String s_regulatory_status;	
        public String s_sic_code;	
        public String s_transactions;	
        public String s_website_review;	
        public String s_company_id;	
        public String s_vertical;
        public String d_review_date;
        public String s_batch_tag;
        public String d_incorporation_date;
        public Decimal n_estimated_number_of_students_payers_annually;
        public Decimal n_how_far_in_advance_1;
        public Decimal n_maximum_payment_size_2;
        public Decimal n_money_moved_annually_2;
        public Decimal n_money_moved_annually_debit_cards;
        public Decimal n_payment_collection_1;
        public Decimal n_percentage_volume_1;
        public Decimal n_percentage_volume_other_1;
        public Decimal n_project_value_of_payments_2;
        public Decimal n_total_value_of_payments_2;
        public Decimal n_typical_payment_size_1	;
        public String s_trading_name;
        public String s_1_d_trading_name_2;
        public String s_advance_payment_types_1;
        public String s_advance_payment_types_2_1;
        public String s_bank_account_name;
        public String s_bank_bic_swift_code;
        public String s_bank_iban;
        public String s_contact_email_address;
        public String s_credit_card_payments;
        public String s_advance_payments;
        public String s_currency_selection_payment_ss;
		public String s_web_review;
        public String s_website_url;
        public String s_verify_open_loop;
        public String s_purpose_of_payments;
        public String s_transaction_1_1;
        public String s_terms_and_conditions_url;
        public list<String> m_payment_months;
        public list<String> m_countries_of_final_destinations_2;
        public list<String> m_currency_selection_credit;
        public String s_advance_payment_types_2;
        public String s_other_text_2;
        public String s_other_text_3;
        public decimal n_percentage_volume_2;
        public decimal n_how_far_in_advance_3;
        public String s_final_payments;
        public String s_other_text_final_2;
        public decimal n_percentage_volume_other_2;
        public decimal n_payment_collection_2;
        public String s_final_payments_3;
        public String s_other_text_final_3;
        public decimal n_percentage_volume_other_3;
        public decimal n_payment_collection_3;
        public String s_address_check_select;
        public String s_1_n_tax_id_number;
        public String s_bo_at_25;
        public String s_mlro_delegate_high_risk;
        public String s_transaction_1;
        public String s_transaction_3;
        public String s_transaction_4;
        public String s_transaction_5;
        public String s_other_text_1;
        public String s_declaration;
        public String s_phone_number;
        public String s_prohibited_ownership;
        public String s_prohibited_services;
        public String s_3_d_verified_bank_details;
        public String s_reduction;
        public String d_qa;
        public String s_charity_reg_number;
        public String s_qc;
		public String[] m_kyc_review_status_applied;
	}
	public class cls_documents {
		public String id;	//01234567-89ab-cdef-0123-456789abcdef
		public String category;	//PROOF_OF_IDENTITY
		public String document_type;	//PASSPORT
		public cls_extracted_data extracted_data;
		public cls_verification_result verification_result;
		public cls_files[] files;
		public cls_images[] images;
	}
	public class cls_extracted_data {
		public String issuer;	//String
		public String issuing_country;	//GBR
		public String number1;	//String
		public String issued;	//1992-11-24
		public String expiry;	//1992-11-24
		public cls_personal_details personal_details;
		public cls_address_history[] address_history;
		public String mrz1;	//String
		public String mrz2;	//String
		public String mrz3;	//String
		public cls_result result;
		public String external_service;	//String
		public String external_ref;	//String
	}
	public class cls_personal_details {
		public cls_name name;
		public String dob;	//1992
		public String nationality;	//GBR
		public String gender;	//M
		public cls_national_identity_number national_identity_number;
	}
	public class cls_name {
		public String title;	//String
		public String[] given_names;
		public String family_name;	//String
		public String[] alt_family_names;
	}
    
	public class cls_national_identity_number {
		public String ESP;	//X0123456L
		public String MEX;	//ABCD012345EF9
		public String BRA;	//09932330078
		public String CAN;	//099323300
		public String ARG;	//10563145-8
		public String AUS;	//M0993353
		public String AUT;	//U12345678
		public String BEL;	//1234567890
		public String CHE;	//s0004156
		public String CHN;	//RRRRRRYYYYMMDDSSSC
		public String CZE;	//1234567890
		public String DNK;	//DDMMYY-0000
		public String EGY;	//11111111111111
		public String FIN;	//12345678
		public String FRA;	//XX123456789
		public String DEU;	//123456789
		public String GRC;	//123456789
		public String HKG;	//X123456(A)
		public String HUN;	//12345678
		public String IND;	//AAAPL1234C
		public String IRL;	//1234567T
		public String ITA;	//SSSNNNYYMDDZZZZX
		public String JPN;	//xxxxxxxxxxx
		public String JOR;	//XXXXXXXXXXXXXX
		public String KWT;	//xxxxxxxxxxxx
		public String LUX;	//12345678
		public String MYS;	//YYMMDD-SS-123G
		public String MLT;	//12345678
		public String NLD;	//123456789B01
		public String NZL;	//VV123456
		public String OMN;	//xxxxxxxxx
		public String PRT;	//123456789
		public String ROU;	//GYYMMDDZZSSSC
		public String RUS;	//AAAABBBBBBCC
		public String SAU;	//xxxxxxxxxx
		public String SGP;	//S/T-XXXXXXXC
		public String ZAF;	//YYMMDDSSSSCAZ
		public String SWE;	//YYMMDD-NNGC
		public String TUR;	//11111111111
		public String GBR;	//123456789
		public String USA;	//123-45-6789
		public String property1;	//String
		public String property2;	//String
	}
	public class cls_address_history {
		public cls_address address;
		public String start_date;	//1999-03
		public String end_date;	//1999-03
	}
	public class cls_address {
		public String type;	//STRUCTURED
		public String country;	//GBR
		public String state_province;	//CA
		public String county;	//Middlesex
		public String postal_code;	//W1 2ZT
		public String locality;	//London
		public String route;	//Crown Street
		public String street_number;	//38
		public String premise;	//Princelet House
		public String subpremise;	//Flat C
		public String original_freeform_address;	//Flat C, Princelet House, 38, Crown Street, London, London, Middlesex, W1 2ZT
		public cls_original_structured_address original_structured_address;
		public Decimal longitude;	//0
		public Decimal latitude;	//0
	}
	class cls_original_structured_address {
	}
	class cls_result {
		public String provider_name;	//String
		public String review_date;	//2017-02-08 15:16:01
		public cls_provider_information[] provider_information;
		public boolean image_checks_passed;
		public cls_image_checks[] image_checks;
		public boolean document_type_passed;
		public boolean forgery_checks_passed;
		public cls_forgery_checks[] forgery_checks;
		public cls_field_checks[] field_checks;
		public boolean all_passed;
		public String error_reason;	//String
	}
	class cls_provider_information {
		public String id;	//String
		public String name;	//String
		public String value;	//String
		public boolean api_only;
	}
	class cls_image_checks {
		public String category;	//String
		public String type;	//String
		public String result;	//PASS
	}
	class cls_forgery_checks {
		public String category;	//String
		public String type;	//String
		public String result;	//PASS
	}
	class cls_field_checks {
		public String field;	//FIELD_GIVEN_NAMES
		public String result;	//CHECK_UNCERTAIN
	}
	class cls_verification_result {
		public String provider_name;	//String
		public String review_date;	//2017-02-08 15:16:01
		public cls_provider_information[] provider_information;
		public boolean image_checks_passed;
		public cls_image_checks[] image_checks;
		public boolean document_type_passed;
		public boolean forgery_checks_passed;
		public cls_forgery_checks[] forgery_checks;
		public cls_field_checks[] field_checks;
		public boolean all_passed;
		public String error_reason;	//String
	}
	class cls_files {
		public String file_id;	//01234567-89ab-cdef-0123-456789abcdef
		public String type;	//LIVE_VIDEO
		public String reference;	//String
	}
	class cls_images {
		public String id;	//01234567-89ab-cdef-0123-456789abcdef
		public String provider_reference;	//String
		public String image_type;	//FRONT
		public String upload_date;	//2017-02-08 15:16:01
		public String file_id;	//01234567-89ab-cdef-0123-456789abcdef
	}
	class cls_external_refs {
		public JumioNetverifyClass jumio_netverify;
		public String generic;	//String
	}
    class JumioNetverifyClass{}
	class cls_fraud_detection {
		public String database_type;	//CIFAS
		public String search_reference;	//String
		public Integer match_count;	//0
		public cls_matches[] matches;
	}
	class cls_matches {
		public String database_type;	//CIFAS
		public String id;	//String
		public String reporting_company;	//String
		public String case_type;	//String
		public String product;	//String
		public boolean do_not_filter;
		public String supply_date;	//1992-11-24
		public String application_date;	//1992-11-24
		public String claim_date;	//1992-11-24
		public FilingReasonClass filing_reason;
	}
    class FilingReasonClass{}
	class cls_banking_details {
		public cls_bank_accounts[] bank_accounts;
	}
	class cls_bank_accounts {
		public String country;	//GBR
		public String type;	//UK_ACCOUNT
		public String sort_code;	//String
		public String account_number;	//String
	}
	class cls_contact_details {
		public String phone_number;	//String
		public String email;	//String
	}
	class cls_ip_location {
		public String ip_address;	//String
		public String country;	//GBR
		public cls_coordinates coordinates;
		public String proxy;	//ANONYMOUS
		public String continent;	//AF
		public String region;	//String
		public String city;	//String
	}
	class cls_coordinates {
		public Integer longitude;	//0
		public Integer latitude;	//0
		public String name;	//String
	}
	class cls_documents_metadata {
		public String document_type;	//PASSPORT
		public String number1;	//String
		public String issue_number;	//String
		public String country_code;	//GBR
		public String issuing_state;	//String
		public String version;	//String
		public String expiry;	//1992-11-24
	}
	class VerifiedDataClass {
		public CustomFieldsDataClass custom_fields_data;
		public String customer_ref;	//String
		public cls_documents[] documents;
		public cls_external_refs external_refs;
		public cls_fraud_detection fraud_detection;
		public String entity_type;	//INDIVIDUAL
		public cls_personal_details personal_details;
		public cls_address_history[] address_history;
		public cls_banking_details banking_details;
		public cls_contact_details contact_details;
		public cls_ip_location ip_location;
		public cls_documents_metadata[] documents_metadata;
	}
	public class ChecksClass {
        public OutputDataClass output_data;
        public String check_type;
		public String decision;
	}
    
    public class OutputDataClass {
        public MetadataClass metadata;
    }
    
    public class MetadataClass {
        public String incorporation_date;
        public String name;
		public String companyNumber;
        public AddressesClass[] addresses;
        public TaxId[] tax_ids;
    }

    public class AddressesClass {
        public AddressClass address;
        public String type;
    }

    public class AddressClass {
        public String type;
        public String original_freeform_address;
        public String country;
        public String locality;
        public String route;
        public String postal_code;
        public String street_number;
        public String state_province;
    }

	public class TaxId {
		public String tax_id_type;
		public String value;
	}
    
	class cls_collection_steps {
	}
	public class ApplicationsClass {
		public String id;	//String
		public ProductClass product;
		public String associated_role;	//AUTHORIZED_PERSON
		public String status;	//APPLIED
		public String flag;	//AUTOMATING
		public cls_required_tasks[] required_tasks;
		public cls_history[] history;
		public cls_flag_history[] flag_history;
		public cls_approval_blockers[] approval_blockers;
		public boolean hidden;
		public String will_expire_at;	//String
		public ApplicationRiskClass risk;
		public String[] decision_reasons;
        public AssignmentsClass[] assignments;
	}
    public class AssignmentsClass{
        public String assignments;
        public AssigneeClass assignee;
    }
    public class AssigneeClass{
        public String name;
        public String id;
        public String email;
    }
	public class ProductClass {
		public String id;	
		public String alias;
		public String name;	
		public boolean automatically_apply;
		public boolean automatically_approve;
		public boolean is_deleted;
		public boolean is_deletable;
		public cls_risk_models risk_models;
	}
	class cls_risk_models {
		public IndividualClass INDIVIDUAL;
		public CompanyClass COMPANY;
	}
    class IndividualClass {
	}
    class CompanyClass {
	}
	class cls_required_tasks {
        public String alias;
        public String id;
        public String name;
        public String task_type;
	}
	public class cls_history {
        public String status;
		public Datetime statusDate;
	}
	class cls_flag_history {
        public String flag;
        public String status;
	}
	class cls_approval_blockers {
	}
	public class ApplicationRiskClass {
		public cls_risk_model risk_model;
		public boolean is_pending;
		public cls_overall overall;
		public String expiry;	
		public cls_thresholds thresholds;
        public BreakdownClass breakdown;
	}

    public class OverallRiskClass {
        public String category;	
        public Double score;
    }
    
    public class BreakdownClass {
		public list<CategoryGroupingClass> category_grouping;
        public list<ComponentsClass> components;
	}

    public class CategoryGroupingClass{
		public Decimal combined_score;
		public CategoryGroupingGroupConfig group_config;
	}

	public class CategoryGroupingGroupConfig {
		public String name;
		public String operator;
	}

    public class ComponentsClass{
        public String input_value;
		public String name;
        public ComponentCategoryClass category;
    }
    public class ComponentCategoryClass{
        public String custom_field_name;
        public String type;
    }
	class cls_risk_model {
		public String id;	
		public String version;
	}
	class cls_overall {
		public Double score;	
		public String level;	
	}
	class cls_thresholds {
		public Double low_medium;	//0
		public Double medium_high;	//0
	}
	class cls_task_types {
            public List<String> taskTypeList;

	}
	class cls_tasks {
	}
	class cls_events {
	}
	class cls_document_images {
	}
	class cls_unresolved_event_types {
	}
	class cls_task_progress {
		public Integer completed_count;	
		public Integer total_count;	
	}
	class cls_linked_to {
		//public String id;
	}

	public class OfficersClass {
		public List<OfficerTypeClass> directors;
		public List<OfficerTypeClass> other;
		public List<OfficerTypeClass> partners;
		public List<OfficerTypeClass> resigned;
		public List<OfficerTypeClass> secretaries;
		public List<OfficerTypeClass> trustees;
	}

	public class OfficerTypeClass {
		public PassfortProfile linked_profile;
	}

	public static PassfortProfile parse(String json){
		PassfortProfile passfortProfile = (PassfortProfile) System.JSON.deserialize(json, PassfortProfile.class);

		String companyNumber = setCompanyNumber(json, passfortProfile);
		if (passfortProfile?.collected_data?.metadata != null) {
			passfortProfile.collected_data.metadata.companyNumber = companyNumber;
		}

		if (passfortProfile.applications != null && !passfortProfile.applications.isEmpty()) {
		List<PassfortProfile.cls_history> appStatusHistory = setHistoryDates(json, passfortProfile);

			if (passfortProfile.applications[0] != null) {
				passfortProfile.applications[0].history = appStatusHistory;
			}
		}

		return passfortProfile;
	}

	private static String setCompanyNumber(String jsonString, PassfortProfile passfortProfile) {

		Map<String,Object> passfortProfileUntyped = (Map<String,Object>) JSON.deserializeUntyped(jsonString);

		Map<String,Object> collectedData = new Map<String,Object>();
		if (passfortProfileUntyped.containsKey('collected_data')) {
			collectedData = (Map<String,Object>) passfortProfileUntyped.get('collected_data');
		}

		Map<String,Object> metadata = new Map<String,Object>();
		if (collectedData != null && collectedData.containsKey('metadata')) {
			metadata = (Map<String,Object>) collectedData.get('metadata');
		}

		String companyNumber = '';			
		if (metadata != null && metadata.containsKey('number')) {
			companyNumber = (String) metadata.get('number');
		}

		return companyNumber;
	}

	private static List<PassfortProfile.cls_history> setHistoryDates(String jsonString, PassfortProfile passfortProfile) {
		
		String statusHistories = '';
		statusHistories = '[' + jsonString.substringBetween('"history":[', '],') + ']';

		JSONParser parser = JSON.createParser(statusHistories);

		List<PassfortProfile.cls_history> appStatusHistory = new List<PassfortProfile.cls_history>();
        
        Datetime statusDate = null;
        String status = null;
        
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                switch on parser.getText() {
                    when 'date' {
                    parser.nextToken();
						statusDate = Datetime.valueOf(parser.getText());
                    }
                    when 'status' {
                        parser.nextToken();
                        status = parser.getText();
                    }
                }
            }
            
            if(status != null && statusDate != null) {
				PassfortProfile.cls_history currentHistory = new PassfortProfile.cls_history();
				currentHistory.statusDate = statusDate;
				currentHistory.status = status;
				appStatusHistory.add(currentHistory);
                statusDate = null;
                status = null; 
            }
        }

		return appStatusHistory;
	}
}