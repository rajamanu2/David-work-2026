public class cAuthURIForEval {

    // hardcoded URL fixed

    public String AuthenticationURI='';
    public cAuthURIForEval(String Clientkey,String redirect_uri)
    {
        this(Clientkey, redirect_uri, null);
    }

    public cAuthURIForEval(String Clientkey, String redirect_uri, String evaluationId)
    {
        String key = EncodingUtil.urlEncode(Clientkey,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        
        //Authentication URL to authenticate the app created by Application Designer to connect to google
        //when ever any rest api connection is made 
        //1. get the AuthenticationToken for an App (to be identified that this is the app being used for the connection)

        String sfURL = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/AuthenticationGoogleDrive';
        system.debug('SF URL is: ' + sfURL);

        String stateValue = 'url=' + sfURL;
        if (String.isNotBlank(evaluationId)) {
            stateValue += '&evaluationId=' + evaluationId;
        }

         String  authuri = 'https://accounts.google.com/o/oauth2/auth?'+
            'client_id='+key+
            '&response_type=code'+
            '&scope=https://www.googleapis.com/auth/drive'+
            '&redirect_uri='+uri+
            '&state=' + EncodingUtil.urlEncode(stateValue, 'UTF-8') +
            '&login_hint=probomedical@gmail.com&' + 
            'access_type=offline';

        system.debug('Auth URI is: ' + authuri);

        AuthenticationURI = authuri;
        //security_token%3D138r5719ru3e1%26url%3D
    }
}
