global class Validator_Class {
	// These are used to prevent triggers from looping too many times. 
	// Some are boolean so code only runs once; some are integers if code needs 
	// to run more than once but still needs a limit placed

    private static Set<String> codeHasRun = new Set<String>();

    public static void setFlag(String theFlag){
        GH_CodeUtils.setFlag(theFlag);
    }

    public static Boolean isFlagSet(String theFlag){
        return GH_CodeUtils.isFlagSet(theFlag);
    }

    public static Integer assetBeforeInsert = 0;
    public static Integer assetAfterInsert = 0;
    public static Integer assetBeforeUpdate = 0;
    public static Integer assetAfterUpdate = 0;
    
    private static boolean passProductItemTrigger = false;
    public static void SetByPassProductItemTrigger(boolean flag) {
        passProductItemTrigger = flag;
    }
    public static boolean ByPassProductItemTrigger() {
        return passProductItemTrigger;
    }
    
    
    private static boolean passReviewTrigger = false;
    public static void SetByPassReviewTrigger(boolean flag) {
        passReviewTrigger = flag;
    }
    public static boolean ByPassReviewTrigger() {
        return passReviewTrigger;
    }

    private static boolean passOppTrigger = false;
    public static void SetByPassOppTrigger(boolean flag) {
        passOppTrigger = flag;
    }
    public static Boolean ByPassOppTrigger() {
        return passOppTrigger;
    }

    private static boolean passRMATrigger = false;
    public static void SetByPassRMATrigger(boolean flag) {
        passRMATrigger = flag;
    }
    public static Boolean ByPassRMATrigger() {
        return passRMATrigger;
    }

    // JMAY: Everything below here is for retro use and will eventually be removed

	// Used in BeforeUpdateOpportunity trigger
    private static integer AlreadyDone1 = 0;
    
    public static integer hasAlreadyDone1(){
        return AlreadyDone1;
    }
    
    public static void setAlreadyDone1(){
        AlreadyDone1 += 1;
    }
    
    public static void resetAlreadyDone1(){
        AlreadyDone1 = 0;
    }

    // UpdateOpportunity trigger
    private static integer AlreadyDone3 = 0;
    
    public static integer hasAlreadyDone3(){
        return AlreadyDone3;
    }
    
    public static void setAlreadyDone3(){
        AlreadyDone3 += 1;
    }
    
      // UpdateOpportunity trigger - marked sold
    private static boolean AlreadyDone4 = false;
    
    public static boolean hasAlreadyDone4(){
        return AlreadyDone4;
    }
    
    public static void setAlreadyDone4(){
        AlreadyDone4 = true;
    }
    
  /*  public static void resetAlreadyDone3(){
        AlreadyDone3 = false;
    }*/

    //used for update for WO trigger
    private static integer AlreadyDone9 = 0;
    
    public static integer hasAlreadyDone9(){
        return AlreadyDone9;
    }
    
    public static void setAlreadyDone9(){
        AlreadyDone9 += 1;
    }
    
   
    
     //used for update for update product repair trigger
    private static integer AlreadyDone10 = 0;
    
    public static integer hasAlreadyDone10(){
        return AlreadyDone10;
    }
    
    public static void setAlreadyDone10(){
        AlreadyDone10 += 1;
    }
    //used for update for update product repair trigger
    private static integer AlreadyDone11 = 0;
    
    public static integer hasAlreadyDone11(){
        return AlreadyDone11;
    }
    
    public static void setAlreadyDone11(){
        AlreadyDone11 += 1;
    }
    //Used for CreateApprovedRepairs trigger
    
    private static integer AlreadyDone14 = 0;
    
 /*   public static integer hasAlreadyDone14(){
        return AlreadyDone14;
    }*/
    
    public static void setAlreadyDone14(){
        AlreadyDone14 += 1;
    }
   
    //Used for RMAUpdate trigger
    
    private static integer AlreadyDone15 = 0;
    
    public static integer hasAlreadyDone15(){
        return AlreadyDone15;
    }
    
    public static void setAlreadyDone15(){
        AlreadyDone15 += 1;
    }
    
    public static void resetAlreadyDone15(){
        AlreadyDone15 = 0;
    }

	// CreateApprovedRepairs trigger    
    private static integer AlreadyDone16 = 0;
    
    public static integer hasAlreadyDone16(){
        return AlreadyDone16;
    }
    
    public static void setAlreadyDone16(){
        AlreadyDone16 += 1;
    }
    
     // new count for update RMA
    private static integer AlreadyDone17 = 0;
    
    public static integer hasAlreadyDone17(){
        return AlreadyDone17;
    }
    
    public static void setAlreadyDone17(){
        AlreadyDone17 += 1;
    }
    
/*
    public static void resetAlreadyDone17(){
        AlreadyDone17 = 0;
    }
*/

}