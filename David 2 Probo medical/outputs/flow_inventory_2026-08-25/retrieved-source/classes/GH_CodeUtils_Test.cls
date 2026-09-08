/**
 * This is GrowthHeroes-provided test class providing test coverage for the CodeUtils class
 */
@IsTest
private class GH_CodeUtils_Test {

    @isTest static void setAndCheckFlag() {
        GH_CodeUtils.setFlag('ThisIsATest');
        system.assertequals(true, GH_CodeUtils.isFlagSet('ThisIsATest'));
    }

    @isTest
    static void clearAndCheckFlag() {
        GH_CodeUtils.setFlag('ThisIsATest');
        system.assertequals(true, GH_CodeUtils.isFlagSet('ThisIsATest'));
        GH_CodeUtils.clearFlag('ThisIsATest');
        system.assertequals(false, GH_CodeUtils.isFlagSet('ThisIsATest'));
    }

    @IsTest
    static void clearAllAndCheckFlag() {
        GH_CodeUtils.setFlag('ThisIsATest');
        system.assertequals(true, GH_CodeUtils.isFlagSet('ThisIsATest'));
        GH_CodeUtils.clearAllFlags();
        system.assertequals(false, GH_CodeUtils.isFlagSet('ThisIsATest'));
    }

    @IsTest
    static void getMethodNameTest(){
        System.assertEquals('getMethodNameTest', GH_CodeUtils.getMethodName(), 'GH_CodeUtils getMethodName doesn\'t work');
    }

    @IsTest
    static void getClassNameTest(){
        System.assertEquals('GH_CodeUtils_Test', GH_CodeUtils.getClassName(), 'GH_CodeUtils getClassName doesn\'t work');
    }

}