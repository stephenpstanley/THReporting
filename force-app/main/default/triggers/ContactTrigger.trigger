trigger ContactTrigger on Contact (after insert, before update, after update) {
    
    List<Contact> newContactList = Trigger.New;
    List<Contact> oldContactList = Trigger.Old;
    
    if (trigger.isinsert && trigger.isAfter){
        ContactTriggerClass.After_Insert(newContactList);
    }
    
    if (trigger.isupdate && trigger.isBefore){
        ContactTriggerClass.Before_Update(oldContactList,newContactList); 
    }
    
    if (trigger.isupdate && trigger.isAfter){
        ContactTriggerClass.After_Update(oldContactList,newContactList); 
    }   
    
}