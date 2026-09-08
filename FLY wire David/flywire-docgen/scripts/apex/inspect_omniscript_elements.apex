for (OmniProcessElement element : [
    SELECT Id, Name, Type, PropertySetConfig
    FROM OmniProcessElement
    WHERE OmniProcessId = '0jNhG0000000umzUAA'
]) {
    System.debug(LoggingLevel.ERROR, 'ELEMENT|' + element.Name + '|' + element.Type + '|' + element.PropertySetConfig);
}
