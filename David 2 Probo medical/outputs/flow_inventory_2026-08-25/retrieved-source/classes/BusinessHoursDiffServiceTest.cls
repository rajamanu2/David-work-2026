@IsTest
private class BusinessHoursDiffServiceTest {

    @IsTest
    static void testValidBusinessHoursDiff() {

        // Default Business Hours always exist in an org
        BusinessHours bh =
            [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        BusinessHoursDiffService.Request req =
            new BusinessHoursDiffService.Request();
        req.businessHoursId = bh.Id;
        req.startDate = System.now().addHours(-4);
        req.endDate   = System.now();

        List<Long> results =
            BusinessHoursDiffService.diff(
                new List<BusinessHoursDiffService.Request>{ req }
            );

        System.assertEquals(1, results.size(),
            'One result should be returned');
        System.assert(results[0] > 0,
            'Business hours diff should be greater than zero');
    }

    @IsTest
    static void testInvalidInputsReturnZero() {

        BusinessHoursDiffService.Request req =
            new BusinessHoursDiffService.Request();
        req.businessHoursId = null;
        req.startDate = null;
        req.endDate = null;

        List<Long> results =
            BusinessHoursDiffService.diff(
                new List<BusinessHoursDiffService.Request>{ req }
            );

        System.assertEquals(0L, results[0],
            'Invalid input should return 0');
    }
}