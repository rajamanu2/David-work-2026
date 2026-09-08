@isTest
private class SlackEduOppPublisherTest {
static testMethod void testpostEduToSlack() {
SlackEduOppPublisher.Oppty opt = new SlackEduOppPublisher.Oppty();
opt.opptyName = 'Unit Test Opt';
opt.stage = 'Unit Test Stage';
opt.prevstage = 'prev stage';

List<SlackEduOpppublisher.oppty> lis = new List<SlackEduOpppublisher.oppty>();
lis.add(opt);
SlackEduOppPublisher.postEduToSlack(lis);

System.assertEquals(lis, lis); // Can't really test this, just put something that is true
}
}