/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Harvest_Work_OrderTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Harvest_Work_OrderTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Harvest_Work_Order__c());
    }
}