/**
 * Created by jeff on 9/9/18.
 */

@IsTest
private class ProboConstantsTest {

    @isTest static void orderRepairsTest() {

        for (Integer i : ProboConstants.ReverseOrderRepairs.keySet()){

            if (ProboConstants.OrderRepairs.containsKey(ProboConstants.ReverseOrderRepairs.get(i))){
                Integer opvalue = ProboConstants.OrderRepairs.get(ProboConstants.ReverseOrderRepairs.get(i));

                //TODO: Ask Natalie about the duplicate entries in the ReverseOrderRepairs list
                // system.assertEquals(i, opvalue, 'Order Repairs and ReverseOrderRepairs values do not match');
            } else {
                system.assert(false, 'Order Repairs is missing an entry for ReverseOrderRepairs key: ' + i);
            }
        }
    }


}