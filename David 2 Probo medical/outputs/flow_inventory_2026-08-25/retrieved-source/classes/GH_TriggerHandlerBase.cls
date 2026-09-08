/**
 * This is GrowthHeroes-provided base class providing standardized TriggerHandling functionality
 */
public abstract class GH_TriggerHandlerBase {

    /*
        To use,
        1) extend this class
        2) override the protected abstract methods below
        3) instantiate your extension class
        4) call the run() method

        public class SampleTriggerHandler extends GH_TriggerHandlerBase {

            protected override void beforeInsert() {}
            protected override void beforeUpdate(){}
            protected override void beforeDelete(){}
            protected override void afterInsert(){}
            protected override void afterUpdate(){}
            protected override void afterDelete(){}
            protected override void afterUndelete(){}
        }

        then in your trigger

        trigger SampleTrigger on thisObject (before insert) {

            SampleTriggerHandler th = new SampleTriggerHandler();
            th.run();
        }

     */

    /***************************************
     * context methods - override these in your derived class
     ***************************************/

    // context-specific methods for override
    protected abstract void beforeInsert();
    protected abstract void beforeUpdate();
    protected abstract void beforeDelete();
    protected abstract void afterInsert();
    protected abstract void afterUpdate();
    protected abstract void afterDelete();
    protected abstract void afterUndelete();

    /***************************************
     * context attributes - these are available to use in your derived class
     ***************************************/

    protected List<SObject> oldList;
    protected Map<Id, SObject> oldMap;
    protected List<SObject> newList;
    protected Map<Id, SObject> newMap;

    // constructor
    public GH_TriggerHandlerBase() {
        this.setTriggerContext();
    }

    /***************************************
     * public instance methods
     ***************************************/

    // main method that will be called during execution
    public void run() {
        System.debug(System.LoggingLevel.INFO, 'Start class / method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());

        try{
            if (!validateRun()) {
                System.debug('Trigger can not be run');
                return;
            }
        } catch (Exception e){
            System.debug('Exception in TriggerHandler: ' + e.getMessage());
            return;
        }

        try{
            addToLoopCount();
        } catch(Exception e){
            System.debug('Exception in TriggerHandler: ' + e.getMessage());
            return;
        }

        // dispatch to the correct handler method
        switch on Trigger.operationType {

            when BEFORE_INSERT {
                doBeforeInsert();
            }
            when AFTER_INSERT {
                doAfterInsert();
            }
            when BEFORE_UPDATE {
                doBeforeUpdate();
            }
            when AFTER_UPDATE {
                doAfterUpdate();
            }
            when BEFORE_DELETE {
                doBeforeDelete();
            }
            when AFTER_DELETE {
                doAfterDelete();
            }
            when AFTER_UNDELETE {
                doAfterUndelete();
            }
        }
        System.debug(System.LoggingLevel.INFO, 'end class / method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    /********************
     * Private methods
     *************************/

    @TestVisible
    private void doBeforeInsert() {
        System.debug(System.LoggingLevel.INFO, 'Start ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        beforeInsert();
        System.debug(System.LoggingLevel.INFO, 'End '  + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doAfterInsert() {
        System.debug(System.LoggingLevel.INFO, 'Start ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        afterInsert();
        System.debug(System.LoggingLevel.INFO, 'End ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doBeforeUpdate() {
        System.debug(System.LoggingLevel.INFO, 'Start class / method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        beforeUpdate();
        System.debug(System.LoggingLevel.INFO, 'End class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doAfterUpdate() {
        System.debug(System.LoggingLevel.INFO, 'Start class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        afterUpdate();
        System.debug(System.LoggingLevel.INFO, 'End class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doBeforeDelete() {
        System.debug(System.LoggingLevel.INFO, 'Start class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        beforeDelete();
        System.debug(System.LoggingLevel.INFO, 'End class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doAfterDelete() {
        System.debug(System.LoggingLevel.INFO, 'Start class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        afterDelete();
        System.debug(System.LoggingLevel.INFO, 'End class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private void doAfterUndelete() {
        System.debug(System.LoggingLevel.INFO, 'Start class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        afterUndelete();
        System.debug(System.LoggingLevel.INFO, 'End class/method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }


    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if (!Trigger.isExecuting && !Test.isRunningTest()) {
            System.debug('Trigger handler called outside of Trigger execution');
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        } else if (GH_CodeUtils.isFlagSet(getHandlerName())) {
            System.debug('Trigger bypassed - flag is set: ' + getHandlerName());
            return false;
        } else {
            return true;
        }
    }

    @TestVisible
    private void setTriggerContext() {
        System.debug('Start class / method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
        // assuming we are in a trigger, set up the protected attributes
        if (Trigger.isExecuting) {
            newList = Trigger.new;
            newMap = Trigger.newMap;
            oldList = Trigger.old;
            oldMap = Trigger.oldMap;
        }
        System.debug('End class / method ' + GH_CodeUtils.getClassName() + '/' + GH_CodeUtils.getMethodName());
    }

    @TestVisible
    private String getHandlerName() {
        System.debug('Handler name: ' + String.valueOf(this).substring(0, String.valueOf(this).indexOf(':')));
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }


    // this is not used by us
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!GH_TriggerHandlerBase.loopCountMap.containsKey(handlerName)) {
            GH_TriggerHandlerBase.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            GH_TriggerHandlerBase.loopCountMap.get(handlerName).setMax(max);
        }
    }

    // this is not used by us
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }


    /***************************************
     * private instancemethods and attributes
     ***************************************/

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
    }


    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        System.debug('addToLoopCount got handler name: ' + handlerName);
        if (GH_TriggerHandlerBase.loopCountMap != null
                && GH_TriggerHandlerBase.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = GH_TriggerHandlerBase.loopCountMap.get(handlerName).increment();
            System.debug('addToLoopCount exceeded: ' + exceeded);
            if (exceeded) {
                Integer max = GH_TriggerHandlerBase.loopCountMap != null && GH_TriggerHandlerBase.loopCountMap.containsKey(handlerName)
                        ? GH_TriggerHandlerBase.loopCountMap.get(handlerName).max : 0;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }


    /***************************************
     * inner classes
     ***************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            if (this.count == null) {
                count = 0;
            }
            this.count++;
            System.debug('increment is working with ' + this.count);
            return this.exceeded();
        }

        public Boolean exceeded() {
            System.debug('exceeded is working with ' + this.max);
            if (this.max < 0) {
                return false;
            }
            if (this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // exception class
    @TestVisible
    private class TriggerHandlerException extends Exception {
    }

}