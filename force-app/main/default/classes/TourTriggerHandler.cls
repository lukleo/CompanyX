public with sharing class TourTriggerHandler implements TriggerHandlerInterface {

    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;

    //Check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return TriggerDisabled;
    }

    public void beforeInsert(List<sObject> newList) {

    }

    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {

    }

    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        TourTriggerHelper.selfUpdate((List<Tour__c>)newList, (Map<Id, Tour__c>)oldMap);
    }

    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        TourTriggerHelper.opportunityRelatedUpdate((List<Tour__c>)newList, (Map<Id, Tour__c>)oldMap);
    }

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {

    }

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {

    }

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {

    }

}