@isTest
private class NoWorkingDays_TestClass{

    @isTest static void mytest(){
     Integer repairLeadTime=20;
     Date inputDate=system.Today();
     NoWorkingDays.workingDays(inputDate,repairLeadTime);
      NoWorkingDays.betweenWorkingDays(inputDate);
     }
}