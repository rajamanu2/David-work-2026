/**
 * This is GrowthHeroes-provided test class providing test coverage for the GHTriggerHandlerBase class
 */
@isTest
private class GH_TriggerHandlerBase_Test {

    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';

    private static String lastMethodCalled;

    private static GH_TriggerHandlerBase_Test.TestHandler handler;

    static {
        handler = new GH_TriggerHandlerBase_Test.TestHandler();
    }

    /***************************************
     * unit tests
     ***************************************/


    // instance method tests

    // private method tests

    @isTest
    static void testGetHandlerName() {
        System.assertEquals('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }

    // test virtual methods

    @isTest
    static void testVirtualMethods() {
        handler.beforeInsert();
        handler.beforeUpdate();
        handler.beforeDelete();
        handler.afterInsert();
        handler.afterUpdate();
        handler.afterDelete();
        handler.afterUndelete();
    }

    @isTest
    static void testrun() {
        handler.run();
    }

    @isTest
    static void testPrivateMethods() {
        handler.dobeforeInsert();
        handler.dobeforeUpdate();
        handler.dobeforeDelete();
        handler.doafterInsert();
        handler.doafterUpdate();
        handler.doafterDelete();
        handler.doafterUndelete();
    }

    @isTest
    static void testLoopCount() {
        GH_TriggerHandlerBase.LoopCount lc = new GH_TriggerHandlerBase.LoopCount();
        lc.increment();
        GH_TriggerHandlerBase.LoopCount lc2 = new GH_TriggerHandlerBase.LoopCount(4);
        lc.setMax(10);
        lc.getCount();
        lc.getMax();
        lc2.exceeded();

    }

    // test implementation of the TriggerHandler

    private class TestHandler extends GH_TriggerHandlerBase {

        public override void beforeInsert() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'beforeInsert';
        }

        public override void  beforeUpdate() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'beforeUpdate';
        }

        public override void beforeDelete() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'beforeDelete';
        }

        public override void afterInsert() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'afterInsert';
        }

        public override void afterUpdate() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'afterUpdate';
        }

        public override void afterDelete() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'afterDelete';
        }

        public override void afterUndelete() {
            GH_TriggerHandlerBase_Test.lastMethodCalled = 'afterUndelete';
        }

    }

}