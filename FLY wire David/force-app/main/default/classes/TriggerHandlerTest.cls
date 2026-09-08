/*
	File Name		: TriggerHandlerTest.cls
	@description	: Test for TriggerHandler
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021      RS @ATG					Created
*/

@isTest
private class TriggerHandlerTest {
	
	@isTest static void testHandlerLoopCountMethods() {
		//Can't run meaningful assertions since all getter methods are within the inner class.  These getter methods are validated in later tests
		TriggerHandler handler = new TriggerHandler();
		TriggerHandler.LoopCount loopCount = new TriggerHandler.LoopCount();
		handler.setMaxLoopCount(10);
		handler.setMaxLoopCount(3);
		handler.clearMaxLoopCount();
	}

	@isTest static void testContextSpecificOverrideMethods(){
		//Nothing to assert
		TriggerHandler handler = new TriggerHandler();
		handler.beforeInsert();
		handler.afterInsert();
		handler.beforeUpdate();
		handler.afterUpdate();
		handler.beforeDelete();
		handler.afterDelete();
		handler.afterUndelete();
	}

	@isTest static void testSetTriggerContext(){
		TriggerHandler handler = new TriggerHandler();
		handler.setTriggerContext('before insert', true);
		System.assert(handler.context.name() == 'BEFORE_INSERT');
		handler.run();

		handler.setTriggerContext('before update', true);
		System.assert(handler.context.name() == 'BEFORE_UPDATE');
		handler.run();

		handler.setTriggerContext('before delete', true);
		System.assert(handler.context.name() == 'BEFORE_DELETE');
		handler.run();

		handler.setTriggerContext('after insert', true);
		System.assert(handler.context.name() == 'AFTER_INSERT');
		handler.run();

		handler.setTriggerContext('after update', true);
		System.assert(handler.context.name() == 'AFTER_UPDATE');
		handler.run();

		handler.setTriggerContext('after delete', true);
		System.assert(handler.context.name() == 'AFTER_DELETE');
		handler.run();

		handler.setTriggerContext('after undelete', true);
		System.assert(handler.context.name() == 'AFTER_UNDELETE');
		handler.run();
	}

	@isTest static void testLoopCountExceed() {
		TriggerHandler handler = new TriggerHandler();
		TriggerHandler.LoopCount loopCount = new TriggerHandler.LoopCount();
		handler.setMaxLoopCount(1);
		handler.addToLoopCount();

		Boolean except = false;
		try{
			handler.addToLoopCount();
		}catch(Exception e){
			except = true;
		}
		System.assert(except == true);
	}

	@isTest static void testValidateRun() {
		TriggerHandler handler = new TriggerHandler();

		Boolean except = false;
		try{
			handler.validateRun();
		}catch(Exception e){
			except = true;
		}
		System.assert(except == true);

		TriggerHandler.bypass(handler.getHandlerName());
		handler.setTriggerContext('before insert', true);
		Boolean except2 = false;
		try{
			System.debug(handler);
			handler.validateRun();
		}catch(Exception e){
			except2 = true;
		}
		System.assert(except2 == false);

	}

	@isTest static void testLoopInnerMethods() {
		TriggerHandler.LoopCount loopCount = new TriggerHandler.LoopCount(10);
		System.assert(loopCount.getMax() == 10);
		System.assert(loopCount.getCount() == 0);

		loopCount.setMax(3);
		System.assert(loopCount.getMax() == 3);
	}

	@isTest static void testBypass() {
		TriggerHandler.bypass('Test');
		//System.assert(TriggerHandler.bypassedHandlers.contains('Test'));
	}

	@isTest static void clearBypass() {
		TriggerHandler.bypass('Test');
		TriggerHandler.clearBypass('Test');
		//System.assert(!TriggerHandler.bypassedHandlers.contains('Test'));
	}

	@isTest static void isBypassed() {
		TriggerHandler.bypass('Test');
		System.assert(TriggerHandler.isBypassed('Test'));
	}

	@isTest static void clearAllBypasses() {
		TriggerHandler.bypass('Test');
		TriggerHandler.bypass('Test2');
		TriggerHandler.clearAllBypasses();
		//System.assert(TriggerHandler.bypassedHandlers.size() == 0);
	}
	
}