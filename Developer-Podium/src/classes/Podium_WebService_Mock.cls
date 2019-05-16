/**
 * Created by admin on 4/5/18.
 */

@IsTest
global class Podium_WebService_Mock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('https://platform.podium.com/api/v2/review_invitations', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(201);
        return res;
    }
}