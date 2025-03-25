public class C360AuthController {
 
    private static String className = 'C360AuthController';
    public String dc_token;
    public String token_endpoint;
   
    public C360AuthController() {
        // use default DataSpace
        initToken(null);
    }

    public C360AuthController(String dataSpaceName) {
        initToken(dataSpaceName);
    }

    private void initToken(String dataSpaceName) {
        System.debug(LoggingLevel.DEBUG, className + ' > initToken - dataSpaceName: ' + dataSpaceName);

        String token = getAccessToken();
        String dctoken = getDataCloudToken(token, dataSpaceName);
        this.dc_token = dctoken;

        System.debug(LoggingLevel.DEBUG, className + ' > initToken - dataCloudToken retrieved: ' + String.isNotEmpty(this.dc_token));
    }

    public static List<C360AuthSetting__mdt> getAllRecords() {
        return [ SELECT DeveloperName, MasterLabel, jwt_aud__c, jwt_exp__c, jwt_iss__c,jwt_sub__c, key__c, token_endpoint__c  
                	FROM C360AuthSetting__mdt 
                	WHERE MasterLabel = 'C360 Auth Settings'
                	LIMIT 1];
    }
 
    public string getAccessToken() {
        String token, iss, sub, aud, exp, key, token_endpoint, access_token;
        List<C360AuthSetting__mdt> eass =  getAllRecords();
        for(C360AuthSetting__mdt eas : eass ) {
            if(eas.MasterLabel.equals('C360 Auth Settings')) {
                iss = eas.jwt_iss__c;
                sub = eas.jwt_sub__c;
                aud = eas.jwt_aud__c;
                exp = eas.jwt_exp__c;
                key = eas.key__c;
                this.token_endpoint = eas.token_endpoint__c;
            }
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getAccessToken - token_endpoint: ' + this.token_endpoint);

        String keyContents = key;
        keyContents = keyContents.replace('-----BEGIN PRIVATE KEY-----', '');
        keyContents = keyContents.replace('-----END PRIVATE KEY-----', '');
        keyContents = keyContents.replace('\n', '');
        //System.debug(LoggingLevel.DEBUG, className + ' > getAccessToken - keyContents: ' + keyContents);
        try{
            // Get a new token
            JWT jwt = new JWT('RS256');
            //jwt.cert = 'JWTCert'; // Uncomment this if you used a Salesforce certificate to sign up for an Einstein Platform account
            jwt.pkcs8 = keyContents; // Comment this if you are using jwt.cert
            //jwt.cert = keyContents;
            jwt.iss = iss;
            jwt.sub = sub;
            jwt.aud = aud;
            jwt.exp = exp;
            token_endpoint = aud;            
			access_token = JWTBearerFlow.getAccessToken(token_endpoint, jwt);            
        } catch(Exception ex) {
            System.debug(LoggingLevel.ERROR, className + ' > getAccessToken - ' + ex.getMessage());
			System.debug(LoggingLevel.ERROR, className + ' > getAccessToken - cause: ' + ex.getCause());
			System.debug(LoggingLevel.ERROR, className + ' > getAccessToken - stackTrace: ' + ex.getStackTraceString());
        }
        return access_token;
    }

    private String getDataCloudToken(String core_token) {
        // use the default DataSpace
        return getDataCloudToken(core_token, null);
    }

    private String getDataCloudToken(String core_token, String dataSpaceName) {
        System.debug(LoggingLevel.DEBUG, className + ' > getDataCloudToken - core_token (exists): ' + String.isNotEmpty(core_token) + ', dataSpaceName: ' + dataSpaceName);

        String tokenEndPoint = this.token_endpoint;
        String parm_grantType = 'grant_type=' + EncodingUtil.urlEncode('urn:salesforce:grant-type:external:cdp', 'UTF-8');
        String parm_subjectToken = '&subject_token=' + EncodingUtil.urlEncode(core_token, 'UTF-8');
        String parm_subjectTokeType = '&subject_token_type=' + EncodingUtil.urlEncode('urn:ietf:params:oauth:token-type:access_token', 'UTF-8');
        String body = parm_grantType + parm_subjectToken + parm_subjectTokeType;

        if (String.isNotEmpty(dataSpaceName)) {
            String parm_dataSpace = '&dataspace=' + EncodingUtil.urlEncode(dataSpaceName, 'UTF-8');
            System.debug(LoggingLevel.DEBUG, className + ' > getDataCloudToken - dataSpace: ' + parm_dataSpace);
            body += parm_dataSpace;
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getDataCloudToken - body: ' + body);
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        Http http = new Http();               
        HTTPResponse res = http.send(req);
        String access_token;
        if (res.getStatusCode() == 200) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getDataCloudToken - access_token retrieved: ' + String.isNotEmpty(access_token));
        return access_token;                      
    }

}