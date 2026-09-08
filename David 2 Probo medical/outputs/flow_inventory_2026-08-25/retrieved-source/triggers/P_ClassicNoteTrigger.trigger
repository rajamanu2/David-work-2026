trigger P_ClassicNoteTrigger on Note (after insert) {

    P_ClassicNoteTriggerHandler th = new P_ClassicNoteTriggerHandler();
    th.run();
}