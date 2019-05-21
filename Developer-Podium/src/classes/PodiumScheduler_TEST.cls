/**
 * Created by admin on 4/5/18.
 */

@IsTest
private class PodiumScheduler_TEST {

    @IsTest static void testPodiumCallout() {
        Integer numRecords = 3;
        List<Account> accounts = TestDataFactory_Opportunity.makeAccounts(numRecords, true);
        List<Contact> contacts = TestDataFactory_Opportunity.makeContacts(accounts, true);
        TestDataFactory_Opportunity.makeOpportunityWithBuyers(contacts, true);

        for (Opportunity op : [SELECT Id, CreatedDate FROM Opportunity]) {
            Datetime dt = Datetime.now().addDays( -1 );
            Test.setCreatedDate(op.Id, dt);
        }

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new Podium_WebService_Mock());
            PodiumCallout.doPodiumProcess();
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name, Podium_Survey__c, Podium_Responses__c
            FROM Opportunity WHERE Podium_Survey__c = TRUE];
        System.assertEquals(false, opps[0].Podium_Ready__c = false);
        System.assert(opps[0].Podium_Survey__c = true, 'Field should be updated after processing');

    }

    @IsTest static void testPodiumCalloutInitial() {
        Integer numRecords = 3;
        List<Account> accounts = TestDataFactory_Opportunity.makeAccounts(numRecords, true);
        List<Contact> contacts = TestDataFactory_Opportunity.makeContacts(accounts, true);
        TestDataFactory_Opportunity.makeOpportunityWithBuyers(contacts, true);

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
        System.assertEquals(false, opps[2].Podium_Ready__c = false);
        System.assert(opps[0].Podium_Survey__c = true, 'Field should be updated after processing');

    }

    @IsTest static void testPodiumSchedulable() {

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new Podium_WebService_Mock());
            String jobId = System.schedule('Podium Test', PodiumScheduler.CRON_EXP, new PodiumScheduler());
        Test.stopTest();

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(PodiumScheduler.CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
    }

}