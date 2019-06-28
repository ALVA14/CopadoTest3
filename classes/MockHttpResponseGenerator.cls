/*------------------------------------------------------------------------
Author:      Pavel Usoltsev
Company      Salesforce
Description: A test class created to mock responses from external services
Test Class:  SMSTextHandler_Test

History
7/28/18    Pavel Usoltsev    Initial Version
----------------------------------------------------------------------------*/
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {

    private String body;
    private Integer statusCode;

    global MockHttpResponseGenerator(String body) {
        this.body = body;
        this.statusCode = 200;
    }

    global MockHttpResponseGenerator(String body, Integer statusCode) {
        this.body = body;
        this.statusCode = statusCode;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(statusCode);
        return res;
    }
}