/**
 * Created by admin on 3/28/18.
 */

global with sharing class PodiumCallout {

    global class podiumProcessException extends Exception {}

    @InvocableMethod(Label='Podium Callout')
    global static void doPodiumProcess() {
        podiumProcess();
    }

    @Future(Callout=true) global static void podiumProcess() {
        //JSONGenerator msgBody;
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Opportunity> opps = [SELECT Id, Name,
                Store_Location__r.Podium_Id__c,
                Buyer_Contact__r.MobilePhone,
                Buyer_Contact__r.Email,
                Buyer_Contact__r.FirstName,
                Buyer_Contact__r.LastName,
                Podium_Survey__c,
                Podium_Responses__c,
                Podium_Ready__c
            FROM Opportunity
            WHERE
                Podium_Ready__c = TRUE
                AND Podium_Survey__c = FALSE
                AND Podium_Responses__c = NULL
                AND Store_Location__r.Podium_Id__c != NULL
                AND (Buyer_Contact__r.MobilePhone != '' OR Buyer_Contact__r.Email != '')
            LIMIT 90 ];
        // there is an issue running the process with higher limits.  This thresh-hold seems admissible
        // solution:
        //          completed process flag on an object that fires a trigger (Process Builder/Flow that would call Apex.

        try {
            for (Opportunity opp : opps) {

                /* JSONGenerator msgBody = JSON.createGenerator(true);
                msgBody.writeStartObject();
                msgBody.writeStringField('locationId', String.valueOf(opp.Store_Location__r.Podium_Id__c));
                msgBody.writeStringField('phoneNumber', opp.Buyer_Contact__r.MobilePhone);
                msgBody.writeStringField('email', opp.Buyer_Contact__r.Email);
                msgBody.writeStringField('firstName', opp.Buyer_Contact__r.FirstName);
                msgBody.writeStringField('lastName', opp.Buyer_Contact__r.LastName);
                msgBody.writeStringField('senderEmail', 'apiuser@usauto-sales.com');
                msgBody.writeStringField('preventSend', 'false');
                msgBody.writeStringField('test', 'false');
                msgBody.writeEndObject();*/

                /*****************************************
                 * start: -- //HttpResponse hr = putPodium(msgBody);
                 ****************************************/

                String msgBody = '{"locationId":"' + String.valueOf(opp.Store_Location__r.Podium_Id__c) + '","phoneNumber":"' +
                        opp.Buyer_Contact__r.MobilePhone + '","email":"' +
                        opp.Buyer_Contact__r.Email + '","firstName":"' +
                        opp.Buyer_Contact__r.FirstName + '","lastName":"' +
                        opp.Buyer_Contact__r.LastName + '","senderEmail":"apiuser@usauto-sales.com"' +
                        ',"preventSend": false,"test": false }';

                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://platform.podium.com/api/v2/review_invitations');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                request.setHeader('Authorization', 'a05fda4a270211e0b06aa8daf5287205');
                request.setTimeout(120000);
                request.setBody(msgBody);
                HttpResponse response = http.send(request);

                // track all status codes on the request.  adding new field PodiumResponse__c
                opp.Podium_Responses__c = response.getStatus();
                opp.Podium_Ready__c = false;
                if (response.getStatusCode() != 201) {
                    System.debug('Unexpected Return Code: ' +
                            response.getStatusCode() + ' ' + response.getStatus() + ' ~~~ MsgBody: ' + msgBody);
                } else {
                    System.debug('Podium Response Body: ' + response.getStatusCode() + ' ~~~ ' + response.getBody());
                    opp.Podium_Survey__c = true;
                }

                oppsToUpdate.add(opp);
                /*****************************************
                 * end
                 ****************************************/
            }

        } catch(CalloutException e) {
            throw new podiumProcessException('ERROR: ' + e.getMessage()
                    + ' ~~~ ' + e.getLineNumber() + ' ~~~ ' + e.getCause() + ' ~~~ ' + e.getTypeName()
            + ' ~~~ ' + e.getStackTraceString() );
        } catch(Exception e) {
            throw new podiumProcessException('Generic Exception: ' + e.getMessage() + ' ~~~ ' + e.getLineNumber()
                    + ' ~~~ ' + e.getCause() + ' ~~~ ' + e.getTypeName()
                    + ' ~~~ ' + e.getStackTraceString() );
        } finally {
            if (oppsToUpdate.size() != 0) {
                update oppsToUpdate;

            }
        }
    }

}