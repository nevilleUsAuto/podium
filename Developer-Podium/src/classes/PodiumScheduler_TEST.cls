/**
 * Created by admin on 4/5/18.
 */

@IsTest
private class PodiumScheduler_TEST {

    @TestSetup static void init() {

        Integer numRecords = 3;

        List<Account> accounts = TestDataFactory_Opportunity.makeAccounts(numRecords, true);
        List<Contact> contacts = TestDataFactory_Opportunity.makeContacts(accounts, true);

        TestDataFactory_Opportunity.makeOpportunityWithBuyers(contacts, true);
        /*Integer rollingDate = 2;

        for (Opportunity op : opps) {
            Datetime dt = Datetime.now().addDays( -(rollingDate--) );
            Test.setCreatedDate(op.Id, dt);
        }
        //System.debug('Show Opportunities: ' + [SELECT Id, CreatedDate, Name FROM Opportunity]);
        update opps;*/
    }

    @IsTest static void testPodiumCallout() {
        for (Opportunity op : [SELECT Id, CreatedDate FROM Opportunity]) {
            Datetime dt = Datetime.now().addDays( -1 );
            Test.setCreatedDate(op.Id, dt);
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Podium_WebService_Mock());
        PodiumCallout.doPodiumProcess();

        Test.stopTest();
    }

    @IsTest static void testPodiumSchedulable() {
        Test.setMock(HttpCalloutMock.class, new Podium_WebService_Mock());
        Test.startTest();
            String jobId = System.schedule('Podium Test', PodiumScheduler.CRON_EXP, new PodiumScheduler());
        Test.stopTest();

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(PodiumScheduler.CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
    }


    @IsTest static void testPodiumCalloutInitial() {
        Datetime st = Datetime.newInstance( (System.today()).addDays(-7), Time.newInstance(0,0,0,0) );
        Datetime et = Datetime.newInstance( (System.today().addDays(3)), Time.newInstance(23,59,59,0) );

        List<Datetime> dtRange = new List<Datetime>{ st, et };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Podium_WebService_Mock());
        PodiumCalloutInitial.doPodiumProcess(dtRange);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name,
                Store_Location__r.Podium_Id__c,
                Buyer_Contact__r.MobilePhone,
                Buyer_Contact__r.Email,
                Buyer_Contact__r.FirstName,
                Buyer_Contact__r.LastName,
                Podium_Survey__c, Podium_Responses__c FROM Opportunity WHERE Podium_Survey__c = TRUE];
        System.debug('the opportunities: ' + opps);
        System.assertEquals(3, opps.size(),'Expecting only 3 populated Podium Records');

    }


}