/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A class for receiving data from external systems
Inputs:
Test Class:  SMSTextHandler_Test

History
7/22/18    Sudipta Karmakar   Initial Version
------------------------------------------------------------*/
public class RequestDataReceiver {

    public enum REQUEST_METHOD {
        GET, POST, PUT
    }

    public static final Integer OK_STATUS = 200;
    public static final Integer NOT_FOUND_STATUS = 400;
    private static final Integer TIMEOUT = 60000;

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Function to make request and get response from the external API.
    Inputs:      url - string url to call
                 method - string method (GET, POST)
                 userName - user name for basic authorization
                 password - password
                 headers - map of required headers
                 body - string body to sending
    Returns:     response - string
                 empty string - in case any errors
    Created:     7/22/18
    ------------------------------------------------------------*/
    public static String receive(String url, String method, String userName, String password, Map<String, String> headers, String body) {
        HttpRequest request = buildRequest(url, method.toUpperCase(), userName, password, body, headers);
        HttpResponse response = makeRequest(request);
        return handleResponse(response);
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Function to make request and get response from the external API.
    Inputs:      url - string url to call
                 method - string method (GET, POST)
                 userName - user name for basic authorization
                 password - password
                 headers - map of required headers
                 body - string body to sending
    Returns:     response - HttpResponse
    Created:     01/17/19
    ------------------------------------------------------------*/
    public static HttpResponse receiveHttp(String url, String method, String userName, String password, Map<String, String> headers, String body) {
        HttpRequest request = buildRequest(url, method.toUpperCase(), userName, password, body, headers);
        return makeRequestHttp(request);
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Function to make request and get response from the external API.
    Inputs:      url - string url to call
                 method - string method (GET, POST)
                 userName - user name for basic authorization
                 password - password
    Returns:     response - string
                 empty string - in case any errors
    Created:     7/22/18
    ------------------------------------------------------------*/
    public static String receive(String url, String method, String userName, String password) {
        return receive(url, method, userName, password, null, null);
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Function to make request and get response from the external API.
    Inputs:      url - string url to call
                 method - string method (GET, POST)
                 userName - user name for basic authorization
                 password - password
    Returns:     response - HttpResponse
    Created:     01/17/19
    ------------------------------------------------------------*/
    public static HttpResponse receiveHttp(String url, String method, String userName, String password) {
        return receiveHttp(url, method, userName, password, null, null);
    }

    public static HttpResponse receiveHttpFAAFailed(String url, String method, String userName, String password) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('failed');
        res.setStatusCode(503);
        return res;
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Build request from received parameters
    Inputs:      url - string url to call
                 method - string method (GET, POST)
                 userName - user name for basic authorization
                 password - password
                 headers - map of required headers
                 body - string body to sending
    Returns:     request - HttpRequest
    Created:     7/22/18
    ------------------------------------------------------------*/
    public static HttpRequest buildRequest(String url, String method, String userName, String password, String body, Map<String, String> headers) {
        HttpRequest request = new HttpRequest();
        request.setTimeout(TIMEOUT);

        if (headers != null) {
            for (String hkey : headers.keySet()) {
                request.setHeader(hkey, headers.get(hkey));
            }
        }

        Blob headerValue = Blob.valueOf(userName + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

        request.setHeader('Authorization', authorizationHeader);

        request.setEndpoint(url);
        request.setMethod(method);

        if (body != null && body.length() > 0) {
            request.setBody(body);
        }

        System.debug('REQUEST: ' + request);
        return request;
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Try to send request
    Inputs:      request - string url to call
    Returns:     response - HttpResponse
                 null - in case any errors or the status is not 200
    Created:     7/22/18
    ------------------------------------------------------------*/
    public static HttpResponse makeRequest(HttpRequest request) {
        HttpResponse response;

        Http http = new Http();

        try {
            response = http.send(request);

        } catch (Exception e) {
            System.debug('Callout error: ' + e);
        }

        if (response != null && response.getStatusCode() != OK_STATUS) {
            response = null;
        }

        return response;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Try to send request
    Inputs:      request - string url to call
    Returns:     response - HttpResponse
    Created:     01/17/19
    ------------------------------------------------------------*/
    public static HttpResponse makeRequestHttp(HttpRequest request) {
        HttpResponse response;

        Http http = new Http();

        try {
            response = http.send(request);

        } catch (Exception e) {
            System.debug('Callout error: ' + e);
        }

        return response;
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Try to send request
    Inputs:      response - received from API request
    Returns:     response - string HttpResponse body
                 empty string - in case the response is null
    Created:     7/22/18
    ------------------------------------------------------------*/
    public static String handleResponse(HttpResponse response) {
        return response != null ? response.getBody() : '';
    }

}