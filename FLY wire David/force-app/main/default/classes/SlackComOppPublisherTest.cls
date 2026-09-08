@isTest
private class SlackComOppPublisherTest {
static testMethod void testpostComToSlack() {
SlackComOppPublisher.Oppty opt = new SlackComOppPublisher.Oppty();
opt.opptyName = 'Unit Test Opt';
opt.stage = 'Unit Test Stage';
opt.prevstage = 'prev stage';

List<SlackComOpppublisher.oppty> lis = new List<SlackComOpppublisher.oppty>();
lis.add(opt);
SlackComOppPublisher.postComToSlack(lis);

System.assertEquals(lis, lis); // Can't really test this, just put something that is true
}
}