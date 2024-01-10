public class TrailheadSyncV6 { // syncs by call the Trailhead API with SFDCID's instead of emails - uses refresh token
    
    
    public static void sleep(Long milliSeconds)
    {
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        do
        {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliSeconds);
    }
    
    @Future(callout=true)    
    public static void PopulateBadges(List<String> RequestedIDs, Boolean IncrementalSync, Datetime SyncSince){
        // Parameters:
        //     RequestedIDs:
        //       List of Strings containing SFIDs of the Trailhead users to sync. Number of records submitted to the API must
        //       be limited to the max number of records that the Trailhead API will return, currently 50.  As a result this class
        //       needs to be called multiple times with batches of (currently) 50 contacts at a time
        //     
        //     IncrementalSync: 
        //       If TRUE then add "Since" : "<date of last sync>" to the JSON request - allows for batch scheduled updates to do less work
        //       If FALSE then sync the entire badge inventory for the contact.  Used when a user(s) are first sync'ed as they have no existing badge records 
        
        // The Trailhead user record has a linked list of orgid and userids.  To find the userID you have to find the list item that matches org62's user record
        String org62='00D000000000062EAA';
        // Constants that are used to identify the badge type
        String superbadgeName = 'Superbadge';
        String moduleName = 'Th::Module';
        String projectName = 'Th::Project';
        String PeerAssesmentName = 'PeerAssessment';
        
        
        // Confirm that the maximum of records for the API has not been exceeded
        // 
        Integer APILimit = StacticVariables.TH_API_Recordlimit;
        Integer CalloutLimit = StacticVariables.TH_CalloutLimit;
        System.Debug('Passed in - IncrementalSync: ' + IncrementalSync + ' Count of Requested Contacts: ' + RequestedIDs.size())    ;
        System.assert(RequestedIDs.size() <= APIlimit * CalloutLimit, 'Too many Contacts passed to PopulateBadges method');		
        
        Integer totalCount = APILimit; // initialise at a known value > 0 to ensure at least one http request is made 
        
        Boolean detailedLogging = FALSE;
        //Can skip syncing certain types of badges by setting these variables to TRUE
        Boolean skipModules = False;
        Boolean skipProjects = False;
        Boolean skipSuperbadges = False;
        
        // They Oauth key to the Trailhead API which gets combined with the SID below
        String TrailheadAPIKey = '<redacted>';
        // Get the SID to use - if you get a 402 assert error then you need to update the Custom Setting SID value: TH_SessionID
        TH_SessionID__c TH = TH_SessionID__c.getOrgDefaults();
        String SID = TH.SID__c;
        
        Last_TH_API_Call__c LC = Last_TH_API_Call__c.getOrgDefaults();
        
        LC.Start_Date_Time__c = Datetime.now(); // Get the time that this job started as this will be written to the Last_API_CAll Custom Setting
        Decimal ms = LC.Start_Date_Time__c.getTime();  // The start time in milliseconds so we can also save the run time
        
        //Get an up to date map of modules so we can get the ID's for the related module for each
        //badge record returned.  V2 is used if there is no match for the first attempt in the exception handler
        //
        List<Trailhead_Module__c> Modules = ([Select ID, Name, Title__c, Type__c, Trailhead_ID__c, Direct_Link__c from Trailhead_Module__c Order by Title__c]);
        Map<String, Trailhead_Module__c> ModuleMap = new Map<String, Trailhead_Module__c>();
        Map<String, Trailhead_Module__c> ModuleMapV2 = new Map<String, Trailhead_Module__c>();
        
        
        for(integer i = 0; i < Modules.size(); i++){
            ModuleMap.put(Modules[i].Trailhead_ID__c,Modules[i]);
            // System.Debug('ModuleMap Key "' + Modules[i].Trailhead_ID__c +'" , value: ' + Modules[i].Trailhead_ID__c + ' type:' + Modules[i].Type__c + ' title:' + Modules[i].Title__c);
            ModuleMapV2.put(Modules[i].Type__c + '-' + Modules[i].Title__c.normalizeSpace(), Modules[i]);
            // System.Debug('ModuleMap V2: ' + Modules[i].Type__c + '-' + Modules[i].Title__c.normalizeSpace());
        }
        
        // Get the user list into a list as we will need their details later
        List<Contact> ContactsList = new List<Contact>();
        ContactsList = ([Select ID, email, TrailheadID__c, Last_TH_Sync_Since_Date__c, Badge_Notify_via_IFTTT__c,
                         MailingCountry, Trailhead_Points__c, Trailhead_Rank__c, Public_Profile_Page__c, SFDCID__c,
                         Badges_In_Progress__c, Modules_Completed__c, Peer_Assessments_Completed__c, Projects_Completed__c, 
                         Superbadges_Completed__c, Total_Badge_Count__c
                         From Contact 
                         where Monitor_Trailhead_badges__c = True
                         and SFDCID__c in :RequestedIDs
                         order by ID]); 
        
        Map<String, Object> JRM = New Map<String, Object>(); //JSON Request Map object
        JRM.put('sfids',RequestedIDs);
        If (IncrementalSync) {JRM.put('since', SyncSince);} //If there is no value in the custom setting then sync for all time
        System.debug('Request Body Text: ' + JRM);
        system.debug('Looking for badges for contacts: '+ ContactsList );
        // 
        
        // Create a holding collection for the list of badges retrieved
        List<Trailhead_Badge__c> TBList = New List<Trailhead_Badge__c>();
        integer this_contact;
        
        // Create holding collections for the COntact field values retrieved to postpone
        // selecting the contact record for update and to minimise contact record lock duration
        List<String> ThTrailheadIDList = new List<String>();
        List<String> ThRankList = new List<String>();
        List<String> ThCountryList = new List<String>();
        List<Long> ThPointsList = new List<Long>();
        List<String> ThProfileURLList = new List<String>();
        List<ID> ContactIDList = new List<ID>();
        Map<ID,integer> ContactIndexMap = new Map<ID,integer>(); // map the Contact's id to its place in the list of contacts passed in
        Map<ID,integer>ResultsIDMap = new Map<ID,integer>(); // map the Contact's id to its place in the list records retrieved from the callout
        
        
        // create a new HttpRequest object
        HttpRequest req = new HttpRequest();
        
        // extend timeout to 20 seconds for slow responses
        req.setTimeout(20000);
        
        // create new response object for collecting the callout results
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        // fill in the necessary settings for calling out to the Trailhead API:
        String Endpoint = 'https://api.trailhead.salesforce.com/v1/search/users';
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setHeader('X-API-Key', TrailheadAPIKey);
        req.setBody(JSON.serialize(JRM, TRUE));
        req.setHeader('Authorization', 'Bearer '+ SID);
        
        for (integer y=0; y<totalCount; y=y+APILimit) {
            System.debug('<><><><><><><><><><><> Initiating callout number: ' + String.ValueOf((y/50)+1) + ' y=' + y + ' totalcount=' + totalcount);
            // try to callout to the Trailhead API Rest API and if it doesn't work, catch the errors for debugging
            try {
                req.setEndpoint(Endpoint + '?offset=' + String.ValueOf(y) + '&limit=' + String.ValueOf(APILimit));
                
                // send the http request and collect it in a response - give it 10 chances to succeed unless it gets a 403 error
                // 
                For (integer z=0; z<20; z++)  {
                    res = http.send(req);
                    if (res.getStatusCode() != 403) {
                        system.debug('http request succeeded on try #' + String.ValueOf(z+1));
                        break;
                    }
                    sleep(1000); // milliseconds to give the Trailhead API a chance to recover
                }
                
                // output to the logs in case you want to view the results
                System.debug('complete request: ' + req.toString());
                system.debug('req.body deserialised: ' + JSON.deserializeUntyped(req.getBody()));
                system.debug('req.body: ' + req.getbody());
                
                system.debug('http request: ' + req.toString());
                System.debug('http response: '+ res.toString());
                
                // make sure the callout got an expected response 
                
                System.assertEquals(200, res.getStatusCode());
                
                
                // serialize the resulting String into a map of name-value pairs (String-Object)
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
                System.Debug('Body of Request: '+ requestMap);
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 
                System.debug('Body of response: '+ jsonMap);
                
                // get the total_count from the map
                totalCount = (Integer)jsonMap.get('total_count');  
                system.debug('>>> ' + totalCount + ' user records returned from callout');
                
                If (totalCount >0) {  // only decode the rest of the response if there are records to process
                    //Do the decoding and create the TBList list entry to be upserted near the end of this method
                    //Extract the details from the user record with points total, country and Trailhead rank so the contact can be updated at the end of this method
                    
                    fromJSONBadgesAchieved obj = fromJSONBadgesAchieved.parse(res.getBody());
                    
                    system.debug('User count: ' + obj.data.size());
                    for (integer row=0 ; row<obj.data.size() ; row++){
                        if (detailedLogging) {
                            System.debug ('Contact email:' + obj.data[row].email);
                            System.debug ('Contact TH rank:' + obj.data[row].rank);
                            System.debug ('Contact TH points:' + obj.data[row].total_points);
                            System.debug ('Contact country:' + obj.data[row].country);
                        }
                        //Find which contact in the ContactsList Collection this user record relates
                        // to and assign the contact field details to holding lists
                        for (Integer index = 0; index < ContactsList.size(); index++) {
                            for (integer i=0; i<obj.data[row].salesforce_ids.size(); i++ ){
                                if (detailedLogging) {
                                    system.debug('user: '+ ContactsList[index].email );
                                    system.debug('org_id: ' + obj.data[row].salesforce_ids[i].org_id + ' vs: ' + org62);
                                    system.debug('org IDs Match? ' + (obj.data[row].salesforce_ids[i].org_id == org62));
                                    system.debug('user_id: '+ obj.data[row].salesforce_ids[i].user_id + ' vs: ' + ContactsList[index].SFDCID__c);
                                    system.debug('user IDs Match? ' + (obj.data[row].salesforce_ids[i].user_id == ContactsList[index].SFDCID__c));
                                }
                                if (obj.data[row].salesforce_ids[i].org_id == org62 && obj.data[row].salesforce_ids[i].user_id == ContactsList[index].SFDCID__c) { 
                                    system.debug('Setting holding list values: index=' + index + ' '+ ' which looks up to  ' + ContactsList[index].email);
                                    ThTrailheadIDList.add(obj.data[row].id);
                                    ThRankList.add(obj.data[row].rank);
                                    ThCountryList.add(obj.data[row].country);
                                    ThPointsList.add(obj.data[row].total_points);
                                    ThProfileURLList.add(obj.data[row].profile_url);
                                    ContactIndexMap.put(ContactsList[index].id,index);
                                    ResultsIDMap.put(ContactsList[index].id,row);
                                    ContactIDList.add(ContactsList[index].ID);
                                    ContactsList[index].Badges_in_Progress__c = 0; //zero this value out as we will recalc it in the aggregate section later
                                    this_contact = index;
                                }
                            }  
                        }
                        
                        system.debug ('Module count: ' + obj.data[row].modules.size());
                        For (integer j=0 ; j<obj.data[row].modules.size() ; j++ ) {
                            Trailhead_Badge__c TB = new Trailhead_Badge__c();
                            TB.Badge_ID__c = obj.data[row].modules[j].id; 
                            TB.Title__c = obj.data[row].modules[j].Title; 
                            TB.web_url__c = obj.data[row].modules[j].web_url; 
                            TB.Completed__c = obj.data[row].modules[j].completed;
                            TB.status__c = obj.data[row].modules[j].status;
                            TB.First_attempted_at__c = obj.data[row].modules[j].first_attempted_at;
                            TB.Last_attempted_at__c = obj.data[row].modules[j].last_attempted_at;
                            TB.Finished_at__c = obj.data[row].modules[j].finished_at;
                            TB.type__c = obj.data[row].modules[j].type;
                            TB.Contact__c = ContactsList[this_contact].ID;
                            TB.TH_External_ID__c = ( TB.type__c + '-' + obj.data[row].id + '-' + TB.Badge_ID__c);
                            // Push the decoded Module data onto the list of Trailhead badges extracted
                            TBlist.add(TB);
                        }
                        
                        system.debug ('Project count: ' + obj.data[row].projects.size());
                        For (integer j=0 ; j<obj.data[row].projects.size() ; j++ ) {                    
                            Trailhead_Badge__c TB = new Trailhead_Badge__c();
                            TB.Badge_ID__c = obj.data[row].projects[j].id; 
                            TB.Title__c = obj.data[row].projects[j].Title; 
                            TB.web_url__c = obj.data[row].projects[j].web_url; 
                            TB.Completed__c = obj.data[row].projects[j].completed;
                            TB.status__c = obj.data[row].projects[j].status;
                            TB.First_attempted_at__c = obj.data[row].projects[j].first_attempted_at;
                            TB.Last_attempted_at__c = obj.data[row].projects[j].last_attempted_at;
                            TB.Finished_at__c = obj.data[row].projects[j].finished_at;
                            TB.type__c = obj.data[row].projects[j].type;                        
                            TB.Contact__c = ContactsList[this_contact].ID;
                            TB.TH_External_ID__c = ( TB.type__c + '-' + obj.data[row].id + '-' + TB.Badge_ID__c);
                            // Push the decoded Project data onto the list of Trailhead badges extracted
                            TBlist.add(TB);
                        }
                        
                        system.debug ('Superbadge count: ' + obj.data[row].superbadges.size());
                        For (integer j=0 ; j<obj.data[row].superbadges.size() ; j++ ) { 
                            Trailhead_Badge__c TB = new Trailhead_Badge__c();
                            TB.Badge_ID__c = obj.data[row].superbadges[j].id; 
                            TB.Title__c = obj.data[row].superbadges[j].Title; 
                            TB.web_url__c = obj.data[row].superbadges[j].web_url; 
                            TB.status__c = obj.data[row].superbadges[j].status;
                            TB.First_attempted_at__c = obj.data[row].superbadges[j].first_attempted_at;
                            TB.Last_attempted_at__c = obj.data[row].superbadges[j].last_attempted_at;
                            TB.Finished_at__c = obj.data[row].superbadges[j].finished_at; // may be null so ensure it's tested
                            TB.Completed__c = (TB.status__c == 'Completed'); // For some reason the API does not have this boolean for Superbadges
                            TB.type__c = superbadgeName; // for projects and modules this is in the dataset but not for superbadges
                            TB.Contact__c = ContactsList[this_contact].ID;
                            TB.TH_External_ID__c = ( TB.type__c + '-' + obj.data[row].id + '-' + TB.Badge_ID__c);
                            // Push the decoded Superbadge data onto the list of Trailhead badges extracted
                            TBlist.add(TB);
                        }
                        
                        system.debug ('(Peer Assessment) Badge count: ' + obj.data[row].badges.peer_assesment_badges.size());
                        For (integer k=0; k<obj.data[row].badges.peer_assesment_badges.size(); k++) {
                            Trailhead_Badge__c TB = new Trailhead_Badge__c();
                            TB.Badge_ID__c = obj.data[row].badges.peer_assesment_badges[k].id; 
                            TB.Title__c = obj.data[row].badges.peer_assesment_badges[k].badge_title; 
                            TB.First_attempted_at__c = obj.data[row].badges.peer_assesment_badges[k].created_at;  //there are no first attempted dates in Peer Assessment badges so using this instead
                            TB.Last_attempted_at__c = obj.data[row].badges.peer_assesment_badges[k].updated_at; //there are no last attempted dates in Peer Assessment badges so using this instead
                            TB.Finished_at__c = obj.data[row].badges.peer_assesment_badges[k].finished_at; 
                            TB.Completed__c = (TB.Finished_At__c != NULL);
                            IF (TB.Completed__c) TB.Status__c = 'Completed';
                            TB.type__c = PeerAssesmentName; // for projects and modules this is in the dataset but not for Peer Assessment Badges
                            TB.Contact__c = ContactsList[this_contact].ID;
                            TB.TH_External_ID__c = ( TB.type__c + '-' + obj.data[row].id + '-' + TB.Badge_ID__c);
                            // Push the decoded Superbadge data onto the list of Trailhead badges extracted
                            TBlist.add(TB);
                        }
                    }
                    if (detailedLogging) for (integer z = 0; z<TBList.size(); z++) system.debug (z + ': Contact: ' + TBList[z].contact__c + ' Ext ID: ' + TBList[z].TH_External_ID__c + '  New Badge: ' + TBList[z]);                    
                }
                
            } catch(System.CalloutException e) {
                System.debug('Callout error: '+ e);
                System.debug(res.toString());
            }  
            
        } // y loop     
        
        // Populate the lookup to the parent badge record and commit the badges and contacts changes to the database
        
        // Add the Lookup to the Module record from the badge record based on title
        string tmp; //This holds the module type concatenated to the moduleID to create foreign key lookup to the Trailhead_Modules
        For (integer i=0; i< TBList.Size(); i++) {
            try { 
                tmp = TBList[i].Type__c + '-' + TBList[i].Badge_ID__c;
                TBlist[i].Trailhead_Module__c = ModuleMap.get(tmp).ID;
                // This should work every time so there should be no need to debug trace this unless it fails to match first time around
                // system.debug('ModuleMap key used:' + ModuleMap.get(tmp).ID + ' for Module: ' + TBList[i].Title__c);
                
            } catch(Exception e) {
                System.debug('System pointer exception caught  '+ e);
                System.debug('Trying to match: '+ TBList[i] + ' trying ModuleMapV2 key: ' + TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace());                        }
            if 	(!ModuleMap.ContainsKey(tmp) 
                 && ModuleMapV2.containsKey(TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace())) {
                     System.debug(' Match to ModuleMapV2 instead of ModuleMap as we couldnt find a matching key in ModuleMap');
                     TBlist[i].Trailhead_Module__c = ModuleMapV2.get(TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace()).ID;
                     System.debug('ModuleMapV2 key used:' + TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace());
                 }
            if (!ModuleMap.ContainsKey(tmp) &&
                !ModuleMapV2.containsKey(TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace())) {
                    System.debug(' No module found for badge' + TBList[i]);
                    System.debug(' ModuleMap key: ' + tmp );
                    System.debug(' ModuleMapV2 key:' + TBList[i].Type__c + '-' + TBList[i].Title__c.normalizeSpace());
                }            
            
        }
        
        // Upsert the decoded badges and updated user records - based on matching the external ID field
        
        if (TBlist.size() > 0) {
            upsert TBlist Trailhead_Badge__c.TH_External_ID__c;
            system.debug('Upserting ' + TBlist.size() + ' badge records');
        } else {
            system.debug('No records returned from Trailhed API, so nothing to commit to the database');
        }
        
        //only update the Last sync time when doing an incremental Sync 
        if (IncrementalSync) {  
            for (Integer i = 0; i < ContactsList.size(); i++) {
                ContactsList[i].Last_TH_Sync_Since_Date__c = LC.Start_Date_Time__c;
                //System.Debug('Setting last Sync time for ' + ContactsList[i].email + ' to ' + SyncSince);  
            }
        }
        
        // This section does the calculations required to replace the roll up summaries on the contact record
        // I stoppped using Rollup summaries because they were causing record locking due to the length
        // of time for which the contact record was locked.  The APEX batch size of 200 caused locks when there
        // were >200 badges associated with a contact
        // 
        
        if (TBlist.size() > 0) {
            
            for (integer q=0; q<ContactIDList.size(); q++){
                system.debug('row: ' + q + ' '+ ContactIDList[q] + ' ' + ThRankList[q] + ' ' + ThCountryList[q] + ' ' + ThPointsList[q]);
            }
            system.debug('ContactIndexMap' + ContactIndexMap);
            system.debug('ContactIndexMap' + ContactIndexMap);
            
            // Get badge counts only for contacts that have been rerieved by the callout (i.e. those in the ID holding list)
            List<AggregateResult> result = new List<AggregateResult> ([select Contact__c, Type__c, Completed__c, count(ID) cnt 
                                                                       From Trailhead_Badge__c where Contact__c in :ContactIDList group by ROLLUP (Contact__c, Type__c, Completed__c) 
                                                                       Order by Contact__c NULLS last]);
            for (integer i=0; i<result.size(); i++){
                System.debug('Aggregate Result row ' + i +' : ' + result[i]);
            }
            integer ContactIndex ;
            integer ResultIndex;
            
            For (integer k=0; k<result.size()-1; k++) { // the last time through, Contact__c is null so don't use that row
                
                ContactIndex = ContactIndexMap.get((ID)result[k].get('Contact__c'));
                    system.debug('ContactIndexMap: ' + ContactIndexMap );
                    system.debug('ResultsIDMap:  ' + ResultsIDMap );
                System.debug('ContactIndex derivation. k: ' + k + ' result[k].get(Contact__c): ' + result[k].get('Contact__c') + ' ContactIndex: ' + ContactIndex);
                ResultIndex = ResultsIDMap.get((ID)result[k].get('Contact__c'));  
                System.debug('ResultIndex derivation. k: ' + k + ' result[k].get(Contact__c): ' + result[k].get('Contact__c') +  ' ResultIndex: ' + ResultIndex);
                // Retrieve the contact attributes form the holding lists
                ContactsList[ContactIndex].TrailheadID__c = ThTrailheadIDList[ResultIndex]; 
                ContactsList[ContactIndex].Trailhead_Rank__c = ThRankList[ResultIndex] ;
                ContactsList[ContactIndex].MailingCountry =  ThCountryList[ResultIndex] ;
                ContactsList[ContactIndex].Trailhead_Points__c = ThPointsList[ResultIndex];
                ContactsList[ContactIndex].Public_Profile_Page__c = ThProfileURLList[ResultIndex];
                system.debug(ContactsList[ContactIndex].email + ' ' + ContactsList[ContactIndex].Trailhead_Rank__c + ' ' + ContactsList[ContactIndex].MailingCountry + ' ' + ContactsList[ContactIndex].Trailhead_Points__c);
                //if (detailedLogging) 
                system.debug('Contact ID: ' + result[k].get('Contact__c') + 
                             ' Type: ' + result[k].get('Type__c') + ' Completed: ' + result[k].get('Completed__c') + ' count: ' + (integer)result[k].get('cnt'));
                If ((string)result[k].get('Type__c') == superbadgeName && (boolean)result[k].get('Completed__c') == TRUE ) {
                    system.debug('Assigning ' + (integer)result[k].get('cnt') + ' superbadges to ' + ContactsList[ContactIndex].email);
                    ContactsList[ContactIndex].Superbadges_Completed__c = (integer)result[k].get('cnt');
                }
                If ((string)result[k].get('Type__c') == moduleName && (boolean)result[k].get('Completed__c') == TRUE ) {
                    system.debug('Assigning ' + (integer)result[k].get('cnt') + ' modules to ' + ContactsList[ContactIndex].email);                    
                    ContactsList[ContactIndex].Modules_Completed__c = (integer)result[k].get('cnt');
                }
                If ((string)result[k].get('Type__c') == projectName && (boolean)result[k].get('Completed__c') != TRUE ) {
                    system.debug('Assigning ' + (integer)result[k].get('cnt') + ' projects to ' + ContactsList[ContactIndex].email);
                    ContactsList[ContactIndex].Projects_Completed__c = (integer)result[k].get('cnt');
                }
                If ((string)result[k].get('Type__c') == PeerAssesmentName && (boolean)result[k].get('Completed__c') != TRUE ) {
                    system.debug('Assigning ' + (integer)result[k].get('cnt') + ' Peer Assessments to ' + ContactsList[ContactIndex].email);
                    ContactsList[ContactIndex].Peer_Assessments_Completed__c = (integer)result[k].get('cnt');
                }                
                If ((boolean)result[k].get('Completed__c') == FALSE) {
                    ContactsList[ContactIndex].Badges_In_Progress__c = ContactsList[ContactIndex].Badges_In_Progress__c + (integer)result[k].get('cnt');
                    system.debug('added ' + (integer)result[k].get('cnt') + ' ' + (string)result[k].get('Type__c') + ' incomplete badges to make running total= ' + ContactsList[ContactIndex].Badges_In_Progress__c);
                }
                ContactsList[ContactIndex].Total_Badge_Count__c =  // Using ternary operator so if the vaue is NULL, it gets added as Zero, if not, add the value
                    ((ContactsList[ContactIndex].Superbadges_Completed__c == null) ? 0 : ContactsList[ContactIndex].Superbadges_Completed__c)
                    + ((ContactsList[ContactIndex].Modules_Completed__c == null) ? 0 : ContactsList[ContactIndex].Modules_Completed__c)
                    + ((ContactsList[ContactIndex].Projects_Completed__c == null) ? 0 : ContactsList[ContactIndex].Projects_Completed__c)
                    + ((ContactsList[ContactIndex].Peer_Assessments_Completed__c == null) ? 0 : ContactsList[ContactIndex].Peer_Assessments_Completed__c);
            }
            
            update ContactsList;
            //if (detailedLogging) 
            System.debug(ContactsList);      
        }
    }
    
    
}
