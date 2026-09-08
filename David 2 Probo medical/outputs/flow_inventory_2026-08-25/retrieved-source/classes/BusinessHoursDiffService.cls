public with sharing class BusinessHoursDiffService {

    @InvocableMethod(
        label='Calculate Business Hours Difference'
        description='Returns the difference in milliseconds between two DateTime values using Business Hours'
    )
    public static List<Long> diff(List<Request> requests) {

        List<Long> results = new List<Long>();

        for (Request r : requests) {

            // Defensive check to avoid runtime exceptions
            if (
                r.businessHoursId != null &&
                r.startDate != null &&
                r.endDate != null &&
                r.endDate > r.startDate
            ) {
                results.add(
                    BusinessHours.diff(
                        r.businessHoursId,
                        r.startDate,
                        r.endDate
                    )
                );
            } else {
                // Return 0 ms if inputs are invalid
                results.add(0L);
            }
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String businessHoursId;

        @InvocableVariable(required=true)
        public Datetime startDate;

        @InvocableVariable(required=true)
        public Datetime endDate;
    }
}