public with sharing class DataFactory {
    public static User createUser(String aProfileName, String aName) {
        Profile lProfile = [SELECT Id FROM Profile WHERE Name = :aProfileName];
        return new User(
        Alias = aName.left(8),
        Email = aName + '@testorg.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = lProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = aName + '@testorg.com'
        );
    }
    public static Account createAccount(String aName) {
        return new Account(
        Name = aName
        );
    }
    public static Opportunity createOpportunity(Id accountId) {
        return new Opportunity(
        StageName = Constants.OPPORTUNITY_STAGE_NEW,
        Name = 'Test Opportunity',
        CloseDate = Date.Today(),
        AccountId = accountId
        );
    }
    public static Tour__c createTour(Id opportunityId, Id agentId) {
        return new Tour__c(
        Opportunity__c = opportunityId,
        Agent_Attribution__c = agentId,
        Status__c = Constants.TOUR_STATUS_ACTIVE
        );
    }
}
