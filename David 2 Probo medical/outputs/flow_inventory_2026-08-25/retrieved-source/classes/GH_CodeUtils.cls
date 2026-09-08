/**
 * This is GrowthHeroes-provided base class providing common utility methods
 */
global class GH_CodeUtils {

    private static Set<String> activeFlagStrings = new Set<String>();

    global static Boolean isFlagSet(String flag){
        return (flag != null ? GH_CodeUtils.activeFlagStrings.contains(flag.toLowerCase().trim()) : false);
    }

    global static void setFlag(String flag){
        if (flag != null) { GH_CodeUtils.activeFlagStrings.add(flag.toLowerCase().trim());}
    }

    global static void clearFlag(String flag){
        if (flag != null) { GH_CodeUtils.activeFlagStrings.remove(flag.toLowerCase().trim());}
    }

    global static void clearAllFlags(){
        GH_CodeUtils.activeFlagStrings.clear();
    }

    /**
     * This method returns the name of the currently-executing Apex class
     *
     * @return - the current Apex class name
     */
    public static String getClassName(){

        String info = new DmlException().getStackTraceString().substringAfter('\n');

        if (info.startsWith('Class.')){
            info = info.substringAfter('Class.');
        }
        return info.substringBefore(':').substringBeforeLast('.');
    }

    /**
     * This method returns the name of the currently-executing Apex method
     *
     * @return - the current Apex method name
     */
    public static String getMethodName(){
        String info = new DmlException().getStackTraceString().substringAfter('\n');

        return info.substringBefore(':').substringAfterLast('.');
    }

}