trigger TourTrigger on Tour__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    TriggerDispatcher.run(new TourTriggerHandler(), 'TourTrigger');
}