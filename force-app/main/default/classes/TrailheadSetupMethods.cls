public with sharing class TrailheadSetupMethods {
    
    public static void V3updateAccessToken() {
        // This was used to test the version that tried to use a refresh token
        trailheadModuleSyncV3.updateAccessToken();
    }
    
    public static void refreshAllModules() {    
        //The next line populates the Modules object
        trailheadModuleSyncV2.PopulateModules();
    }
    
    public static void purgeALLIFTTTMessage () {
        // The next line deletes all record from IFTTT_Messages__c 
        delete [select Name from IFTTT_Message__c limit 10000];
    }
    
    public static void purgeIFTTTBadgeMessage () {
        // The next line deletes all badge records from IFTTT_Messages__c 
        delete [select Name from IFTTT_Message__c where Severity__c != 'Badge' limit 10000];
    }
    
    public static void sync5contacts () {
        list<String> SyncGRoup = new list<String> {'00530000009MJfLAAW', '00530000009MinKAAS', '00530000009Mad2AAC', '00530000009MkeFAAS', '00530000009MHHCAA4'};
            string inputString = '2018-03-04T05:50:00.000Z';
        dateTime syncSince = DateTime.ValueofGmt(inputString.replace('T', ' '));
        trailheadsyncV5.PopulateBadges(syncGroup, FALSE, syncSince);
    }
    
    public static void sync1contact () {
        list<string> syncGroup = new list<string> {'00530000007Pj3bAAC'};  // Cindy Wild
            string inputString = '2018-03-04T05:50:00.000Z';
        dateTime syncSince = DateTime.ValueofGmt(inputString.replace('T', ' '));
        trailheadsyncV5.PopulateBadges(syncGroup, FALSE, syncSince);
    }
    
    public static void sync15contacts () {    
        list<String> syncGroup = new list<String> {'00530000007QmjrAAC','00530000001fvNWAAY','0053000000BPAVfAAP','00530000004vIluAAE','00530000008xVuRAAU','00530000004xEdQAAU','00530000000rv7jAAA','00530000004vlaLAAQ','0050M00000D0bQLQAZ','0053000000C0Lh2AAF','0053000000C01tNAAR','00530000009Lz8CAAS','00530000009jS09AAE','00530000009MR5fAAG','00530000009kPdAAAU'};
            dateTime syncSince = dateTime.now();      
        trailheadsyncV5.PopulateBadges(syncGroup, FALSE, syncSince);
    }
    
    public static void syncAll () {
        // From here to the end re-submits the batch job to run in 1 minute
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String hour = string.valueOf(system.now().hour());
        String minute = string.valueOf(system.now().minute() + 1);
        String second = string.valueOf(system.now().second());
        String year = string.valueOf(system.now().year());
        
        String strJobName = 'Job-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new trailheadSyncControllerBulk());
    }
    
    
    
    public static void submitKeepAlive () {
        // From here to the next comment line re-submits the job that tries to keep the OAuth token alive
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String hour = string.valueOf(system.now().hour());
        String minute = string.valueOf(system.now().minute() + 1);
        String second = string.valueOf(system.now().second());
        String year = string.valueOf(system.now().year());
        
        String strJobName = 'Job-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new trailheadKeepAliveV2());
    }
    
    public static void submitSync0700 () {
        
        // From here to the next comment re-submits the batch job that syncs contacts to run at 07:00 tomorrow
        String day = string.valueOf(system.now().day()+1);
        String month = string.valueOf(system.now().month());
        String hour = string.valueOf(7);
        String minute = string.valueOf(0);
        String second = string.valueOf(0);
        String year = string.valueOf(system.now().year());
        
        String strJobName = 'Job-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new trailheadSyncControllerBulk());
        
    }
    
    
    
    
}