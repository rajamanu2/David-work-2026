/**
 * This is GrowthHeroes-provided class providing test coverage for GHLogger
 */
@IsTest
private class GH_Logger_Test {

    @isTest static void errorTest() {
        GH_Logger.error('Help');
    }

    @isTest static void warnTest() {
        GH_Logger.warn('Help');
    }

    @isTest static void infoTest() {
        GH_Logger.info('Help');
    }

    @isTest static void debugTest() {
        GH_Logger.debug('Help');
    }

    @isTest static void fineTest() {
        GH_Logger.fine('Help');
    }

    @isTest static void finerTest() {
        GH_Logger.finer('Help');
    }

    @isTest static void finestTest() {
        GH_Logger.finest('Help');
    }

}