public with sharing class TourTriggerHelper {
    public static void selfUpdate(List<Tour__c> tours, Map<Id, Tour__c> oldToursIndexedById ) {
        for (Tour__c tour : tours) {
            if (
                oldToursIndexedById.get(tour.Id).Completed_Goals__c != tour.Completed_Goals__c
                &&
                tour.Completed_Goals__c == Constants.TOUR_CG_TOUR_COMPLETED
            ) {
                tour.Completed_On__c = Datetime.now();
            }
        }
    }
    public static void opportunityRelatedUpdate(List<Tour__c> tours, Map<Id, Tour__c> oldToursIndexedById ) {
        Set<Id> relatedOpportunitiesIdsSet = new Set<Id>();

        for (Tour__c tour : tours) {
            relatedOpportunitiesIdsSet.add(tour.Opportunity__c);
        }

        Map<Id, Opportunity> opportunitiesIndexedById = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity WHERE Id IN :relatedOpportunitiesIdsSet WITH USER_MODE FOR UPDATE]);

        // Map<Id, List<Tour__c>> toursIndexedByOpportunityId = new Map<Id, List<Tour__c>>();
        // for (Tour__c tour : tours) {
        //     relatedOpportunitiesIdsSet.add(tour.Opportunity__c);
        //     if (toursIndexedByOpportunityId.keySet().contains(tour.Opportunity__c)) {
        //         toursIndexedByOpportunityId.get(tour.Opportunity__c).add(tour);
        //     } else {
        //         toursIndexedByOpportunityId.put(tour.Opportunity__c, new List<Tour__c>{tour});
        //     }
        // }
        // List<Opportunity> relatedOpportunities = [SELECT Id FROM Opportunity WHERE Id IN :relatedOpportunitiesIdsSet WITH USER_MODE FOR UPDATE];

        // //Find the agent with more completed tour per opportunity, without persist data
        // List<AggregateResult> groupedResults = [SELECT COUNT(Id) tours, Agent_Attribution__c agent, Opportunity__c opportunity FROM Tour__c WHERE Completed_on__c != null GROUP BY Opportunity__c, Agent_Attribution__c ORDER BY COUNT(Id) DESC];
        // for (AggregateResult ar : groupedResults) {
        //     Id salesAgent = ar.get('agent');
        // }

        // Map<Id, List<Opportunity>> opportunitiesIndexedByTourId = new Map<Id, List<Opportunity>>();
        // for (Opportunity opportunity : relatedOpportunities) {

        // }
        for (Tour__c tour : tours) {
            Opportunity relatedOpportunity = opportunitiesIndexedById.get(tour.Opportunity__c);
            if (
                oldToursIndexedById.get(tour.Id).Completed_Goals__c != tour.Completed_Goals__c
                &&
                tour.Completed_Goals__c == Constants.TOUR_CG_PROPOSAL_GENERATED
            ) {
                relatedOpportunity.Discount_Offered__c = tour.Discount_Offered__c;
                if (relatedOpportunity.StageName == Constants.OPPORTUNITY_STAGE_TOUR_COMPLETED) {
                    relatedOpportunity.StageName = Constants.OPPORTUNITY_STAGE_READY_COMMITMENT;
                }
                opportunitiesIndexedById.put(tour.Opportunity__c, relatedOpportunity);
            }
        }
        Database.update(opportunitiesIndexedById.values(), true, AccessLevel.USER_MODE);
    }
}
