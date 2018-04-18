Global with sharing class trailheadSyncControllerBulk implements Schedulable{

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

    @future
    public static void IFTTTMessageParse(List<ID> IFTTTContactIDs, List<Decimal> Badgecount) {
        // Check to see if any new badges have been obtained by contacts in those accounts for which we are doing IFTTT NOtifications
        List<String> Incomplete = new List<String>{'Queued', 'Preparing', 'Processing'};
        
        // Ensure that all the future jobs that are invoked to do the badge synching have completed before checking badge counts
        // 
        Integer RetryCount = 0;
        List<AsyncApexJob> AAJ = new List<AsyncApexJob>();
        While  (RetryCount <25) {
            AAJ = ([Select ID, CompletedDate, MethodName, Status 
                                From AsyncApexJob
                                Where Status in :Incomplete
                                and MethodName = 'PopulateBadges']);
            If (AAJ.Size() == 0) break;
            System.Debug(AAJ.Size() + ' future jobs pending, retry # ' + RetryCount);
            for (integer i=0;i<AAJ.Size();i++) {System.debug(AAJ[i].ID + ' ' + AAJ[i].MethodName +' ' + AAJ[i].Status);}
            sleep(1500); 
            RetryCount++;
        } 
        System.debug('Wait/retry count = ' + String.ValueOf(RetryCount));
        
        // Check to see if any of the contacts we are monitoring have earned new badges and add the details to IFTTTMessage
        List<Contact> IFTTTNotifyContactsAfter = ([Select Full_Name__c, Total_Badge_Count__c From Contact 
                                                   where  ID in :IFTTTContactIDs
                                                    order by SFDCID__c]);     
        String IFTTTMessage = '';
        for (integer i=0;i<IFTTTContactIDs.Size(); i++) {
            if (IFTTTNotifyContactsAfter[i].Total_Badge_Count__c > BadgeCount[i]) {
                IFTTTMessage = IFTTTMessage + ' ' + IFTTTNotifyContactsAfter[i].Full_Name__c + ': ' +
                                String.ValueOf(IFTTTNotifyContactsAfter[i].Total_Badge_Count__c - BadgeCount[i]);
            System.debug('New badge obtained by ' + IFTTTNotifyContactsAfter[i].Full_Name__c + 
                         ' previous count = ' + BadgeCount[i] +
                         ' new count = ' + IFTTTNotifyContactsAfter[i].Total_Badge_Count__c );
            } else {
                System.debug('Badge count for ' + IFTTTNotifyContactsAfter[i].Full_Name__c + ' is unchanged. Before: ' + BadgeCount[i] +
                            ' After: '+ IFTTTNotifyContactsAfter[i].Total_Badge_Count__c);
            }
        }
        if (IFTTTMessage != '') { // Then we found some new badges in the for loop above and added the details to IFTTTMessage
            IFTTT_Message__c EM = new IFTTT_Message__c();
            EM.IFTTT_Message__c = TRUE;
            EM.Severity__c = 'Badge';
            EM.Message_Text__c = 'New badges obtained: ' + IFTTTMessage ;
            EM.Message_Source__c = 'trailheadSyncController.IFTTTMessageParse';
            Insert EM;
        } else {
            system.debug('No new badges obtained by monitored contacts in this sync run');
        }
    }
    
    global void execute(SchedulableContext SC) {
        Boolean MessageLogging = FALSE ; // If TRUE, it writes a message to the IFTTT_Messages table with details of the name of the job scheduled
        Integer MinutesInterval = 59; //Minutes
        Integer HoursInterval = 23; //Hours - interval beteeen jobs running is the combo of hours and minutes
        String jobID;
        Integer APIRecordLimit = StacticVariables.TH_API_Recordlimit;
        Integer CalloutLimit = StacticVariables.TH_CalloutLimit;
        // CalloutCapLimit may be significantly less than the 100 that is allowed by the platform to prevent running out of CPU, DML etc.
        Integer CallOutCapLimit = 12 ;
        CalloutLimit = Math.Min(CallOutCapLimit,CalloutLimit); // use the lower of the two values
        
        List<String> Incomplete = new List<String>{'Queued', 'Preparing', 'Processing'};
            
        Last_TH_API_Call__c LC = Last_TH_API_Call__c.getOrgDefaults();
        Datetime SyncSince = LC.Sync_Since_Date_Time__c; // This is the Since date to use in the case of an incremental sync of all sync'ed contacts
        LC.Start_Date_Time__c = Datetime.now(); // Get the time that this job started as this will be written to the Last_API_CAll Custom Setting
        Decimal ms = LC.Start_Date_Time__c.getTime();  // The start time in milliseconds so we can also save the run time     
        
        // Check to see if the prior scheduled job and all its callouts have completed.
        // If not, then don't run again now, but wait for the next scheduled run
        // 
        List<AsyncApexJob> AAJ = new List<AsyncApexJob>();
        AAJ = ([Select ID, CompletedDate, MethodName, Status 
                From AsyncApexJob
                Where Status in :Incomplete
                and MethodName in ('PopulateBadges','IFTTTMessageParse') ]);
        Integer RunningProcesses = AAJ.Size() ;
        
        
        If(RunningProcesses == 0) { // otherwise just reschedule the job as the previous run has not completed
            
            //Call the ModuleSync job to ensure that we have the latest list of modules for the later
            //jobs to match retrieved badges against
            //
            trailheadModuleSyncV2.PopulateModules();
            
            List<Contact> SyncContacts = ([Select ID, email, SFDCID__c, Contact.Badge_Notify_via_IFTTT__c, Total_Badge_Count__c 
                                           From Contact where Monitor_Trailhead_badges__c = True 
                                           and SFDCID__c != ''
                                           order by SFDCID__c]);
            List<ID> IFTTTNotifyContactIDs = new List<ID>();
            List<Decimal> IFTTTContactBadgeCounts = new List<Decimal>();
            
            For (integer i=0; i<SyncContacts.size(); i++){
                // Add the contacts that should be IFTTT notified to the list to be passed to the IFTTTMessage
                // method
                If (SyncContacts[i].Badge_Notify_via_IFTTT__c == True) {
                    IFTTTNotifyContactIDs.Add(SyncContacts[i].ID);
                    IFTTTContactBadgeCounts.Add(SyncContacts[i].Total_Badge_Count__c);
                }
            }
            
            Integer IDsLeftToPopulate = SyncContacts.Size();
            List<String> BadgePopList = new List<String>();
            if (SyncContacts.size() >0) {
                for (integer i=0; i <= SyncContacts.Size()/APIRecordLimit*CalloutLimit; i++) { 
                    // Trailhead API retrieve limit is initally just 50 contact records but we can use multiple callouts
                    // Call the sync job repeatedly, 50 x CalloutLimit emails at a time
                    for (integer j=0; j<math.min(APIRecordLimit*CalloutLimit,IDsLeftToPopulate); j++){
                        BadgePopList.add(SyncContacts[j + APIRecordLimit*CalloutLimit*i].SFDCID__c);
                    }
                    if (BadgePopList.size() >0) { 
                        trailheadSyncV5.PopulateBadges(BadgePopList,TRUE,SyncSince);  
                        /*   PopulateBadges(    List<String> IDstoSync, (list of emails of users to sync badges for)
Boolean incrementalSync, (if true, then checking for existing users, if false, checking for a newly sync'ed user)
DateTime SyncSince) (If IncrementalSync, the dateTime of the last successful sync job - limits the data returned)
*/
                        
                        System.debug('incremental Sync ' + BadgePopList.size() + ' Contacts to sync badges for: ' + BadgePopList);
                        IDsLeftToPopulate = IDsLeftToPopulate - BadgePopList.size();
                        BadgePopList.Clear();
                    }
                }
            }  
            
            IFTTTMessageParse(IFTTTNotifyContactIDs, IFTTTContactBadgeCounts);
            
            // update the custom setting with most recent run stats and results
            LC.End_Date_Time__c = Datetime.now();
            LC.Sync_Since_Date_Time__c = LC.Start_Date_Time__c;
            Decimal me = LC.End_Date_Time__c.getTime();
            LC.Run_Time_Seconds__c = (Me - Ms)/1000;
            System.debug('Run time - RunStartMS: ' + Ms + ' RunEndMS: ' + Me + ' elapsed=' + (Me-ms) + 'ms');
            LC.Users_returned__c = SyncContacts.Size(); 
            LC.CPU_Seconds_Used__c = (decimal)Limits.getCpuTime()/1000; //CPU Time is in mS and is an integer so need to cast it before saving
            upsert LC;
        } else {
            for (integer i=0;i<AAJ.Size();i++) {System.debug(AAJ[i].ID + ' ' + AAJ[i].MethodName +' ' + AAJ[i].Status);}
            System.Debug(AAJ.Size() + ' future jobs pending, so skipping processing stage ');
            IFTTT_Message__c m = new IFTTT_Message__c();
            m.IFTTT_Message__c = False;
            m.Message_Source__c = 'Class: trailheadSyncControllerBulk.Execute';
            m.Severity__c = 'Delay';
            m.Message_Text__c = String.ValueOf(DateTime.now()) + ' - skipped trailheadSyncController.Execute as ' + RunningProcesses + ' still queued or executing';
            insert m;
        }
        
        // 
        String second = string.valueOf(system.now().second());

        String minute = string.valueOf(math.mod((system.now().minute() + MinutesInterval),60));
        system.debug('Minute: ' + minute);
      
        String hour;
        if (integer.Valueof(minute) - MinutesInterval < 0) {
            hour = string.valueOf( math.mod((HoursInterval + system.now().hour() +1),24));
        } else {
            hour = string.valueOf(math.mod((HoursInterval + system.now().hour()),24));
        }
        system.debug('hour: ' + hour);
        
        String day;
        if ((hour == '0') && (integer.Valueof(minute) - MinutesInterval < 0) || (integer.ValueOf(hour) - HoursInterval < 0)) {
            day = string.valueOf(system.now().AddDays(1).day());
        } else {
            day = string.valueOf(system.now().day());
            system.debug('day: ' + day);
        }
        String month;
        if ((day=='1') && (hour == '0') && (integer.Valueof(minute) - Minutesinterval < 0) 
            						|| (day=='1') && (integer.ValueOf(hour) - HoursInterval < 0)) {
            month = string.valueOf(math.mod((system.now().month() + 1),12));
        } else {
            month = string.valueOf(system.now().month());            
        }
        system.debug('month: ' + month);
        
        
        String year;
        if ((month=='1') && (day=='1') && (hour == '0') && (integer.Valueof(minute) - MinutesInterval < 0) 
        							|| (month=='1') && (day=='1') && (integer.ValueOf(hour) - HoursInterval < 0)){
            year = string.valueOf(system.now().year()+1);
        } else {
            year = string.valueOf(system.now().year());
        }
        system.debug('year: ' + year);
        
        String strJobName = 'Trailhead Badge Refresh (bulk) -' + year + '-' + month + '-' + day + '-' + hour + '-' + minute + '-' + second ;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.Debug('About to submit.  JobName: ' + strJobName + ' Schedule: ' +  strSchedule);
        
        //delete all completed jobs from the queue that finished over 1 hour ago (units are days) just to keep things tidy
        Datetime CleanupTime = system.now()-1;
        for(CronTrigger delCron: [SELECT Id, StartTime FROM CronTrigger Where StartTime < :CleanupTime and State = 'DELETED']) {  
            System.debug('Job to clean up: ' + delCron);
            System.abortJob(delCron.Id);
        }
        
        if (MessageLogging){
            IFTTT_Message__c m = new IFTTT_Message__c();
            m.IFTTT_Message__c = False;
            m.Message_Source__c = 'global class scheduledTest implements Schedulable{';
            //m.Severity__c = 'Information';
            m.Message_Text__c = 'Scheduled Job: \r ID: ' + jobID + '\r Name: ' + strJobname + '\r Schedule: ';
            insert m;
        }
        
        jobID = System.schedule(strJobName, strSchedule, new trailheadSyncControllerBulk());
        
    }
}