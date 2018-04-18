public with sharing class ContactTriggerClass {
    
    public static void After_Insert(list<Contact> NewContacts){
        list<String> addList = new list<String>{}; // list of contact email addresses to add their badges to
            dateTime syncSince = dateTime.now();// The value of syncSince doesn't matter as we are doing a full sync - but it is a mandatory parameter
        
        for (integer i=0 ; i<NewContacts.size() ; i++) {
            if (NewContacts[i].Monitor_Trailhead_Badges__c) 
                // New contact with Monitor Badges = TRUE so sync their badges
                addList.add(NewContacts[i].SFDCID__c); 
        }
        // If there are any new contacts with Monitor Badges = TRUE, add them to the "add list"
        if (addList.size()>0) trailheadsyncV5.PopulateBadges(addList, FALSE, syncSince);
    }
    
    public static void Before_Update(list<Contact> OldContacts, list<Contact> NewContacts){
        // If Monitor Badges is now FALSE and was TRUE, then zero the badge counts
        for (integer i=0 ; i<NewContacts.size() ; i++) {
            if (OldContacts[i].Monitor_Trailhead_Badges__c && NewContacts[i].Monitor_Trailhead_Badges__c == FALSE) {
                NewContacts[i].Total_Badge_Count__c = 0;
                NewContacts[i].Superbadges_Completed__c = 0;                
                NewContacts[i].Projects_Completed__c = 0;                
                NewContacts[i].Modules_Completed__c = 0;                
                NewContacts[i].Badges_in_progress__c = 0; 
                NewContacts[i].Peer_Assessments_Completed__c = 0; 
            }
        }
    }        
    
    public static void After_Update(list<Contact> OldContacts, list<Contact> NewContacts){
        list<String> addList = new list<String>{}; // list of contact email addresses to add their badges to
            list<ID> deleteList = new list<ID>{}; //list of contact IDs whose badges should be deleted
                dateTime syncSince = dateTime.now();// The value of syncSince doesn't matter as we are doing a full sync - but it is a mandatory parameter
        Integer DML_Limit = Limits.getLimitDMLRows();
        Integer DMLHeadroom = 2500; // how far to stay away from the DML limit to prevent the process runniung out of heap size
        
        for (integer i=0 ; i<NewContacts.size() ; i++) {
            // If Monitor Badges is now TRUE and was FALSE, then add these contacts to the "add list"
            if (NewContacts[i].Monitor_Trailhead_Badges__c && OldContacts[i].Monitor_Trailhead_Badges__c == FALSE) 
                addList.add(NewContacts[i].SFDCID__c); 
            
            // If Monitor Badges is now FALSE and was TRUE, then add these contacts to the "delete list" and zero the badge counts
            if (OldContacts[i].Monitor_Trailhead_Badges__c && NewContacts[i].Monitor_Trailhead_Badges__c == FALSE) {
                deleteList.add(NewContacts[i].ID);     
            }
        }
        
        // If we have any additional contacts to sync, then do a badge sync
        if (addList.size() > 0) {
            system.debug('Submitting ' + addList.size() + ' contacts to have their badges synced');
            trailheadsyncV5.PopulateBadges(addList, FALSE, syncSince);
        }
        // If we have any additional contacts to stop syncing, then delete their related badges
        if (deleteList.size()>0) {
            list<Trailhead_Badge__c> TBD = [Select ID from Trailhead_Badge__c WHERE Contact__c in :deleteList];
            
            // It's quite likely when deleting or stopping syncing a large number of contacts 
            // that the 10k DML limit will be broken so we have to split the badges to be deleted into batches of under
            // 10,000 records and use @future to batch them up if there are too many to delete in one go
            
            If (TBD.size() <= (DML_Limit - Limits.getDMLRows() - DMLHeadroom )) {
                System.debug('Deleting ' + TBD.size() + ' badge records immediately');
                try {
                    Delete TBD;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while trying to delete badge attempt records: ' + e.getMessage());
                }        
            } else {
                for (integer i = 0 ; i < TBD.Size() ; i=i + DML_Limit - DMLHeadroom) { 
                    List<ID> BadgesToDelete = New list<ID>{};
                        for (integer j = i;  j < math.min((TBD.size()-i), i+ DML_Limit - DMLHeadroom); j++) {
                            BadgesToDelete.add(TBD[j].ID);
                        }
                    System.debug('Submitting future job to delete badges from ' + i + ' record count= ' + BadgesToDelete.size());
                    FutureClass.DeleteBadgesFuture(BadgesToDelete);
                }
            }
            
        }
    }
     
}