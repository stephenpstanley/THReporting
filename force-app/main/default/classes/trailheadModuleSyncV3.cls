public class trailheadModuleSyncV3 {
    
    public static TH_SessionID__c TH = TH_SessionID__c.getOrgDefaults();
    
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
    public static void PopulateModules(){
        
        //     Syncs the badges in the Trailhead system with a local copy in this org
        //     There is (currently) a API limit of 50 records at a time so this method needs to make multiple calls to get all the badges
        //     You can stack up to 100 http callouts in one future method so we are currently limited to 5000 modules.  If this limit is hit
        //     then raise an error and the job will stop, alerting the developer.  
        //     Total_count is returned from the http callout and if this is > 100 * the API limit, then we need to raise an error
        //          
        //     At that point some redesign work will be required using limits and offsets
        //     See API defintion here: https://api.trailhead.salesforce.com/#!/Module/post_v1_search_modules
        
        
        Boolean debugOn = FALSE;
        Boolean debugL0 = FALSE;
        Boolean debugL1 = TRUE;
        Boolean debugL2 = FALSE;
        Integer APIRecordLimit = StacticVariables.TH_API_Recordlimit;
        Integer totalCount = APIRecordLimit; // initialise at a known value > 0 to ensure at least one http request is made 
        
        // Identifier added to Trailhead Module to signifiy that it is a Salesforce Internal Module
        String SFDCinternalID = '15';
        String SFDCInternalTitle = 'Salesforce Employee';
        Integer TimeTotal = 0;
        Integer PointsTotal = 0;
        
        // Create a holding collection for the list of modules retrieved
        List<Trailhead_Module__c> ModuleList = New List<Trailhead_Module__c>();
        
        // Get the SID to use - if you get a 402 assert error then you need to update the Custom Setting SID value: TH_SessionID
        
        String SID = TH.Access_Token__c;
        // create a new HttpRequest object
        HttpRequest req = new HttpRequest();
        
        List<String> EndPointList = new List<String> {};  //Each endpoint retreives a different type of badge
            EndpointList.Add('https://api.trailhead.salesforce.com/v1/superbadges');
        EndpointList.Add('https://api.trailhead.salesforce.com/v1/projects');
        EndPointList.Add('https://api.trailhead.salesforce.com/v1/modules');
        EndPointList.Add('https://api.trailhead.salesforce.com/v1/badges');
        
        String sSuperbadge = 'Superbadge';
        String sProject = 'Th::Project';
        String sModule = 'Th::Module';
        String sPeerAssessment = 'PeerAssessment';
        
        List<String> ModuleTypeList = new List<String> {}; //Matching badge type for endpoints listed above
            ModuleTypeList.Add(sSuperbadge);
        ModuleTypeList.Add(sProject);
        ModuleTypeList.Add(sModule);
        ModuleTypeList.Add(sPeerAssessment);
        
        
        // extend timeout to 20 seconds for slow responses
        req.setTimeout(20000);
        
        // create new response object for collecting the callout results
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        // fill in the necessary settings for calling out to the Trailhead API:
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setHeader('X-API-Key', '9ee1bee15f49805ce41eb37ed5f26528');
        // set the access token from the same org
        req.setHeader('Authorization', 'Bearer '+ sid);
        
        system.debug('EndpointList.size()=' + EndpointList.size() +' , ModuleTypeList.size()=' + ModuleTypeList.size());
        
        
        String Endpoint;
        String ModuleType;
        for (integer url=0;  url< EndpointList.size() ; url++) { // SET BACK TO starting value = 0 when fixed
            Endpoint = EndPointList[url];
            ModuleType = ModuleTypeList[url];
            System.debug('Processing ' + ModuleType + 's');            
            for (integer y=0; y<totalCount; y=y+APIRecordLimit) {
                if (debugL2) system.debug('y=' + y + ' totalcount=' + totalcount + ' APIRecordLimit=' + APIRecordLimit + ' Endpoint:' + Endpoint + ' ModuleType' + ModuleType );
                
                // try to callout to the Trailhead API Rest API and if it doesn't work, catch the errors for debugging
                try {
                    req.setEndpoint(Endpoint + '?offset=' + String.ValueOf(y) + '&limit=' + String.ValueOf(APIRecordLimit));
                    // send the http request and collect it in a response - give it 10 chances to succeed if it gets a 403 error
                    // 
                    res = sendRequest(req);
                    
                    System.debug('request: '+ req.toString());
                    System.debug('http response: '+ res.toString());
                    System.debug('res.getBody(): ' + res.getBody());
                    
                    // make sure the callout got an expected response 
                    System.assertEquals(200, res.getStatusCode());
                    
                    // serialize the resulting String into a map of name-value pairs (String-Object)
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 
                    System.debug('Body of response (jsonMap): '+ jsonMap);
                    
                    // get the total_count from the map
                    totalCount = (Integer)jsonMap.get('total_count');   
                    System.debug('totalcount:' + totalCount);
                    
                    If (totalCount >0) {  // only decode the rest of the response if there are records to process
                        //Do the decoding and create the ModuleList list entry to be upserted at the end of this method
                        //Extract the details from the user record with points total, country and Trailhead rank so the contact can be updated at the end of this method
                        //                        
                        // Decode the Modules
                        if (ModuleType == sModule) {
                            fromJSONModules obj = fromJSONModules.parse(res.getBody());
                            for (integer i=0; i<obj.data.size() ; i++) {
                                Trailhead_Module__c TB= new Trailhead_Module__c();
                                TB.Trailhead_ID__c =  ModuleType + '-' + obj.data[i].id; 
                                TB.Title__c  =  obj.data[i].title; 
                                TB.Direct_Link__c  =  obj.data[i].web_url; 
                                TB.Archived__c  =  obj.data[i].archived; 
                                TB.Description__c  =  obj.data[i].description_html; 
                                TB.badge_icon_url__c  =  obj.data[i].badge_icon; 
                                TB.created__c  =  obj.data[i].created_at; 
                                TB.updated__c  =  obj.data[i].updated_at; 
                                TB.Type__c  =  sModule;
                                TB.Points_Available__c = 0;
                                TB.Estimated_Time_mins__c = 0;
                                for (integer j=0; j< obj.data[i].units.size(); j++ ) {
                                    TB.Points_Available__c = TB.Points_Available__c + obj.data[i].units[j].total_points;
                                    TB.Estimated_Time_mins__c = TB.Estimated_Time_mins__c + obj.data[i].units[j].challenge_time;
                                }
                                TB.Salesforce_Internal__c = FALSE;
                                for (integer j=0; j< obj.data[i].roles.size(); j++ ) {
                                    if (obj.data[i].roles[j].Title == SFDCInternalTitle || obj.data[i].roles[j].ID == SFDCinternalID) {
                                        TB.Salesforce_Internal__c = TRUE;
                                    }
                                }                                
                                ModuleList.add(TB); 
                            }
                        }
                        //                        
                        // Decode the Projects
                        if (ModuleType == sProject) {
                            fromJSONProjects obj = fromJSONProjects.parse(res.getBody());
                            for (integer i=0; i<obj.data.size() ; i++) {
                                Trailhead_Module__c TB= new Trailhead_Module__c();
                                TB.Trailhead_ID__c =  ModuleType + '-' +obj.data[i].id; 
                                TB.Title__c  =  obj.data[i].title; 
                                TB.Direct_Link__c  =  obj.data[i].web_url; 
                                TB.Archived__c  =  obj.data[i].archived; 
                                TB.Description__c  =  obj.data[i].description_html; 
                                TB.badge_icon_url__c  =  obj.data[i].badge_icon; 
                                TB.created__c  =  obj.data[i].created_at; 
                                TB.updated__c  =  obj.data[i].updated_at; 
                                TB.Type__c  =  sModule;
                                TB.Points_Available__c = 0;
                                TB.Estimated_Time_mins__c = 0;
                                for (integer j=0; j< obj.data[i].steps.size(); j++ ) {
                                    TB.Points_Available__c = TB.Points_Available__c + obj.data[i].steps[j].total_points;
                                    TB.Estimated_Time_mins__c = TB.Estimated_Time_mins__c + obj.data[i].steps[j].challenge_time;
                                }
                                TB.Salesforce_Internal__c = FALSE;
                                for (integer j=0; j< obj.data[i].roles.size(); j++ ) {
                                    if (obj.data[i].roles[j].Title == SFDCInternalTitle || obj.data[i].roles[j].ID == SFDCinternalID) {
                                        TB.Salesforce_Internal__c = TRUE;
                                    }
                                }                                
                                ModuleList.add(TB); 
                            }
                        }                        
                        //                        
                        // Decode the SuperBadges
                        if (ModuleType == sSuperbadge) {
                            fromJSONSuperBadges obj = fromJSONSuperBadges.parse(res.getBody());
                            system.debug('Superbadge obj: ' + obj);
                            for (integer i=0; i<obj.data.size() ; i++) {
                                Trailhead_Module__c TB= new Trailhead_Module__c();
                                TB.Trailhead_ID__c =  ModuleType + '-' +obj.data[i].id; 
                                TB.Title__c  =  obj.data[i].title; 
                                TB.Direct_Link__c  =  obj.data[i].web_url; 
                                TB.Archived__c  =  obj.data[i].archived; 
                                TB.Description__c  =  obj.data[i].description; 
                                TB.badge_icon_url__c  =  obj.data[i].badge_icon; 
                                TB.created__c  =  obj.data[i].created_at; 
                                TB.updated__c  =  obj.data[i].updated_at; 
                                TB.Type__c  =  sSuperbadge;
                                TB.Points_Available__c = obj.data[i].completion_points;
                                TB.Estimated_Time_mins__c = NULL;
                                TB.Salesforce_Internal__c = FALSE;
                                for (integer j=0; j< obj.data[i].prerequisites.size(); j++ ) { // Superbadges have pre-requisites
                                    for (integer k=0; k<obj.data[i].prerequisites[j].roles.size(); k++ ) { // Preequisites have Roles - roles can be SF internal
                                        // If any of the pre-reqs have roles that are internal, then the whole SuperBadge must be internal, otherwise you can't start it
                                        if (obj.data[i].prerequisites[j].roles[k].Title == SFDCInternalTitle || obj.data[i].prerequisites[j].roles[k].ID == SFDCinternalID) {
                                            TB.Salesforce_Internal__c = TRUE;
                                        }
                                    }
                                }                                
                                ModuleList.add(TB); 
                            }
                        }
                        //                        
                        // Decode the Peer Assessment Badges
                        if (ModuleType == sPeerAssessment) {
                            system.debug('Parsing res.getBody()' + res.getBody());
                            fromJSONBadges obj = fromJSONBadges.parse(res.getBody());
                            system.debug('Peer Asessment obj: ' + obj);
                            system.debug('total count: ' + obj.total_count);
                                for (integer j=0; j<obj.data.peer_assesment_badges.size(); j++) {
                                    Trailhead_Module__c TB = new Trailhead_Module__c();
                                    TB.Trailhead_ID__c =  ModuleType + '-' +obj.data.peer_assesment_badges[j].id; 
                                    TB.Title__c  =  obj.data.peer_assesment_badges[j].badge_title; 
                                    TB.created__c  =  obj.data.peer_assesment_badges[j].created_at; 
                                    TB.updated__c  =  obj.data.peer_assesment_badges[j].updated_at; 
                                    TB.Description__c  =  obj.data.peer_assesment_badges[j].message;                                     
                                    TB.badge_icon_url__c  =  obj.data.peer_assesment_badges[j].badge_icon; 
                                    TB.Type__c  =  sPeerAssessment;
                                    TB.Points_Available__c = 0;
                                    TB.Estimated_Time_mins__c = 0;                                    
                                    TB.Salesforce_Internal__c = TRUE;
                                    ModuleList.add(TB); 
                                } 
                        }
                    }  
                } catch(System.CalloutException e) {
                    System.debug('Callout error: '+ e);
                    System.debug(res.toString());
                }    
            }
        }
        // Upsert the decoded badges and updated user records - based on matching the external ID field
        If (debugon || debugL0 || debugL1) {
            for (Integer i = 0; i < ModuleList.size(); i++) {
                System.debug('ModuleList(' + i + ')= ' + ModuleList[i].Type__c + ': ' + ModuleList[i].title__c + ', ' + ModuleList[i].Trailhead_ID__c);
            }
        }
        upsert ModuleList Trailhead_Module__c.Trailhead_ID__c;
        
    }
    
    public static HttpResponse sendRequest(HttpRequest req) {
        Integer statusCode = null;
        while(statusCode != 200) {
	        HttpResponse res = new Http().send(req);
        	statusCode = res.getStatusCode();
            
            if (statusCode == 401) {
            	updateAccessToken();
            }
        
            if (statusCode == 403) {
                sleep(1000); // milliseconds to give the Trailhead API a chance to recover
            }
        }
        return null;
    }
    
    public static Boolean updateAccessToken() {
        HttpRequest accessTokenRequest = new HttpRequest();
        accessTokenRequest.setMethod('POST');
        accessTokenRequest.setEndpoint('https://login.salesforce.com/services/oauth2/token');
        accessTokenRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        accessTokenRequest.setBody(String.format('grant_type=refresh_token&client_id={0}&client_secret={1}&refresh_token={2}', new String[] {
            '3MVG9szVa2RxsqBZvguUaoCckJg5fUyiNjVSukS_fi8k9Va0QQAFpPlnAXQfsMp7rmdogI7xagAbd9qEpdqgM',
            '903046927929323182',
            TH.Refresh_Token__c
        }));
        
        HttpResponse res = new Http().send(accessTokenRequest);
        
        System.assert(false, accessTokenRequest.getBody());
        
        return true;
    }

}