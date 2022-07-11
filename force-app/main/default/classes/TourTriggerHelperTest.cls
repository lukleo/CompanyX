@isTest
public with sharing class TourTriggerHelperTest {
    @TestSetup
    static void setup() {
        UserRole northEastRole = [SELECT Id FROM UserRole WHERE Name = 'Sales North-East Agent'];
        User northAgent = DataFactory.createUser('Sales Agent Profile', 'NorthAgent');
        northAgent.UserRoleId = northEastRole.Id;
        insert northAgent;

        System.runAs(northAgent) {
            Account account = DataFactory.createAccount('Client X');
            insert account;

            Opportunity opportunity = DataFactory.createOpportunity(account.Id);
            insert opportunity;

            Tour__c tour = DataFactory.createTour(opportunity.Id, northAgent.Id);
            insert tour;
        }
    }

    @isTest
    public static void whenUpdateATourToCompletedThenUpdateItAndRelatedOpportunity() {
        List<Tour__c> toursToUpdate = [SELECT Id, Opportunity__c FROM Tour__c WHERE Completed_on__c = null];
        User user = [SELECT Id FROM User WHERE UserName = 'NorthAgent@testorg.com'];
        Test.startTest();
        System.runAs(user) {
            for (Tour__c tourToUpdate : toursToUpdate) {
                tourToUpdate.Completed_Goals__c = Constants.TOUR_CG_TOUR_COMPLETED;
            }
            update toursToUpdate;
        }
        Test.stopTest();
        Opportunity opportunityUpdated = [SELECT Id, Completed_Tours__c, Best_Sales_Agent__c, (SELECT Id, Status__c, Completed_On__c FROM Tours__r WHERE Id = :toursToUpdate[0].Id) FROM Opportunity WHERE Id = :toursToUpdate[0].Opportunity__c];
        System.assert(opportunityUpdated.Completed_Tours__c > 0);
        System.assert(opportunityUpdated.Best_Sales_Agent__c != null);
        System.assert(opportunityUpdated.Tours__r[0].Completed_On__c != null);
        System.assertEquals(Constants.TOUR_STATUS_COMPLETED,opportunityUpdated.Tours__r[0].Status__c, 'Tour was not marked as Completed');
    }

    @isTest
    public static void whenUpdateATourToProposalGeneratesThenUpdateRelatedOpportunity() {
        List<Tour__c> toursToUpdate = [SELECT Id, Opportunity__c FROM Tour__c WHERE Completed_on__c = null];

        Opportunity opportunityToSetAsCompleted = [SELECT Id FROM Opportunity WHERE Id = :toursToUpdate[0].Opportunity__c];
        opportunityToSetAsCompleted.StageName = Constants.OPPORTUNITY_STAGE_TOUR_COMPLETED;
        update opportunityToSetAsCompleted;

        User user = [SELECT Id FROM User WHERE UserName = 'NorthAgent@testorg.com'];
        Test.startTest();
        System.runAs(user) {
            for (Tour__c tourToUpdate : toursToUpdate) {
                tourToUpdate.Completed_Goals__c = Constants.TOUR_CG_PROPOSAL_GENERATED;
                tourToUpdate.Discount_Offered__c = 0.1;
                tourToUpdate.Proposal_Value__c = 1000;
            }
            update toursToUpdate;
        }
        Test.stopTest();
        Opportunity opportunityUpdated = [SELECT Id, StageName, Amount, Discount_Offered__c, Completed_Tours__c, Best_Sales_Agent__c, (SELECT Id, Status__c, Completed_On__c FROM Tours__r WHERE Id = :toursToUpdate[0].Id) FROM Opportunity WHERE Id = :toursToUpdate[0].Opportunity__c];
        System.assertEquals(Constants.OPPORTUNITY_STAGE_READY_COMMITMENT, opportunityUpdated.StageName, 'Opportinity was not updated to Ready for Commitment');
        System.assert(opportunityUpdated.Amount == 1000);
        System.assert(opportunityUpdated.Discount_Offered__c == 0.1);
        System.assert(opportunityUpdated.Completed_Tours__c > 0);
        System.assert(opportunityUpdated.Best_Sales_Agent__c != null);
        System.assert(opportunityUpdated.Tours__r[0].Completed_On__c != null);
        System.assertEquals(Constants.TOUR_STATUS_COMPLETED,opportunityUpdated.Tours__r[0].Status__c, 'Tour was not marked as Completed');
    }
}
