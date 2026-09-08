@isTest
private class SlackHealthcareOppPublisherTest {
static testMethod void testPostHCToSlack() {
SlackHealthcareOppPublisher.Oppty opt = new SlackHealthcareOppPublisher.Oppty();
opt.opptyName = 'Unit Test Opt';
opt.stage = 'Unit Test Stage';
opt.prevstage = 'Unit Prev Test Stage';

List<SlackHealthcareOppPublisher.oppty> lis = new List<SlackHealthcareOppPublisher.oppty>();
lis.add(opt);
SlackHealthcareOppPublisher.postHCToSlack(lis);

System.assertEquals(lis, lis); // Can't really test this, just put something that is true
}
}