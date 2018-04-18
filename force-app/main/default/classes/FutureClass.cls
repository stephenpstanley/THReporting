global with sharing class FutureClass {
    
    @Future   
    public static void DeleteBadgesFuture(List<ID> IDsToDelete){
        integer badges = IDsToDelete.size();
        list<Trailhead_Badge__c> RecordsToDelete = [Select ID from Trailhead_Badge__c where Contact__c in :IDsToDelete];

        try {
            Delete RecordsToDelete;
            system.Debug(Badges + ' badge attempt records deleted');
        } catch(DmlException e) {
            System.debug('The following exception has occurred while trying to delete badge attempt records: ' + e.getMessage());
        }
    }
    
}