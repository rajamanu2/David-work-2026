/**
 * This is GrowthHeroes-provided class providing common logging methods
 */
public without sharing class GH_Logger {

    public static void error(Object msg){
        debug(System.LoggingLevel.ERROR, msg);
    }

    public static void warn(Object msg){
        debug(System.LoggingLevel.WARN, msg);
    }

    public static void info(Object msg){
        debug(System.LoggingLevel.INFO, msg);
    }

    public static void debug(Object msg){
        debug(System.LoggingLevel.DEBUG, msg);
    }

    public static void fine(Object msg){
        debug(System.LoggingLevel.FINE, msg);
    }

    public static void finer(Object msg){
        debug(System.LoggingLevel.FINER, msg);
    }

    public static void finest(Object msg){
        debug(System.LoggingLevel.FINEST, msg);
    }

    public static void debug(System.LoggingLevel level, Object msg){
        System.debug(level, msg);
    }

}