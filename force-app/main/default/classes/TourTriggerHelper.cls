public with sharing class TourTriggerHelper {
    public static void selfUpdate(List<Tour__c> tours, Map<Id, Tour__c> oldToursIndexedById ) {
        for (Tour__c tour : tours) {
            // In the Opportunity they want to have a total count of Completed Tours (consider all tours which at some point completed the goal “Tour Completed”, do not use the Completed Goals field as a criteria because it can move to a different goal further in the process)
            //  Set Status as Completed when Completed Goal moves to Tour Completed
            if ((oldToursIndexedById.get(tour.Id).Completed_Goals__c != tour.Completed_Goals__c &&   tour.Completed_Goals__c == Constants.TOUR_CG_TOUR_COMPLETED) || (tour.Completed_On__c == null && (tour.Completed_Goals__c == Constants.TOUR_CG_PROPOSAL_GENERATED || tour.Completed_Goals__c == Constants.TOUR_CG_CLIENT_COMMITMENT))) {
                tour.Completed_On__c = Datetime.now();
                tour.Status__c = Constants.TOUR_STATUS_COMPLETED;
            }
        }
    }
    public static void opportunityRelatedUpdate(List<Tour__c> tours, Map<Id, Tour__c> oldToursIndexedById ) {
        Set<Id> relatedOpportunitiesIdsSet = new Set<Id>();

        for (Tour__c tour : tours) {
            relatedOpportunitiesIdsSet.add(tour.Opportunity__c);
        }

        Map<Id, Opportunity> opportunitiesIndexedById = new Map<Id, Opportunity>([SELECT Id, StageName, Best_Sales_Agent__c FROM Opportunity WHERE Id IN :relatedOpportunitiesIdsSet WITH USER_MODE FOR UPDATE]);

        //Find the agent with more completed tour per opportunity, without persist data - the Sales agent who got the most Completed tours (this agent will receive some compensation).
        Map<Id, AggregateResult> aggregateResultIndexedByOpportunityId = new Map<Id, AggregateResult>();
        List<AggregateResult> groupedResults = [SELECT COUNT(Id) tours, Agent_Attribution__c agent, Opportunity__c opportunity FROM Tour__c WHERE Completed_on__c != null AND Opportunity__c IN :relatedOpportunitiesIdsSet WITH SYSTEM_MODE GROUP BY Opportunity__c, Agent_Attribution__c ORDER BY COUNT(Id) DESC];
        for (AggregateResult ar : groupedResults) {
            if (
                aggregateResultIndexedByOpportunityId.containsKey((Id)ar.get('opportunity'))
                &&
                Integer.valueOf(aggregateResultIndexedByOpportunityId.get((Id)ar.get('opportunity')).get('tours')) < Integer.valueOf(ar.get('tours'))
            ) {
                aggregateResultIndexedByOpportunityId.put((Id)ar.get('opportunity'), ar);
                opportunitiesIndexedById.get((Id)ar.get('opportunity')).Best_Sales_Agent__c = (Id)ar.get('agent');
            } else if (!aggregateResultIndexedByOpportunityId.containsKey((Id)ar.get('opportunity'))) {
                aggregateResultIndexedByOpportunityId.put((Id)ar.get('opportunity'), ar);
                opportunitiesIndexedById.get((Id)ar.get('opportunity')).Best_Sales_Agent__c = (Id)ar.get('agent');
            }
        }

        for (Tour__c tour : tours) {
            Opportunity relatedOpportunity = opportunitiesIndexedById.get(tour.Opportunity__c);
            // When the tour gets the “Completed Goals” field updated to “Proposal Generated” the “Discount offered” field value will be synched with a similar field in the related Opportunity.
            if (
                oldToursIndexedById.get(tour.Id).Completed_Goals__c != tour.Completed_Goals__c
                &&
                tour.Completed_Goals__c == Constants.TOUR_CG_PROPOSAL_GENERATED
            ) {
                relatedOpportunity.Discount_Offered__c = tour.Discount_Offered__c;
                // Opportunity will automatically move stages from “Tour completed” to “Ready for Commitment” when  one of the completed tours is updated with the “Proposal Generated” completed goal
                // After “Ready for Commitment” the amount will be populated
                if (relatedOpportunity.StageName == Constants.OPPORTUNITY_STAGE_TOUR_COMPLETED) {
                    relatedOpportunity.StageName = Constants.OPPORTUNITY_STAGE_READY_COMMITMENT;
                    relatedOpportunity.Amount = tour.Proposal_Value__c;
                }
            }
            // Opportunity will automatically move stages from “New” stage to “Tour completed” when a tour is marked as Completed.
            if (
                oldToursIndexedById.get(tour.Id).Status__c != tour.Status__c
                &&
                tour.Status__c == Constants.TOUR_STATUS_COMPLETED
                &&
                relatedOpportunity.StageName == Constants.OPPORTUNITY_STAGE_NEW
            ) {
                relatedOpportunity.StageName = Constants.OPPORTUNITY_STAGE_TOUR_COMPLETED;
            }
            opportunitiesIndexedById.put(tour.Opportunity__c, relatedOpportunity);
        }
        Database.update(opportunitiesIndexedById.values(), true, AccessLevel.USER_MODE);
    }
}
