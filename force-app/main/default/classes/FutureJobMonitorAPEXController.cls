public class FutureJobMonitorAPEXController {
    
    @AuraEnabled
    public Static List<sObject> getFutureJobs (integer refreshTimer) {
        integer recent = 2 * integer.valueof(refreshTimer);
        datetime recentJobsTime = Datetime.now().addSeconds(-recent); 
        String queryString ='SELECT MethodName,  Status, ExtendedStatus, CreatedDate, CompletedDate FROM AsyncApexJob ';
        queryString = queryString + ' where JobType=\'Future\' and ((Status!=\'Completed\' and CreatedDate = TODAY) ';
        queryString = queryString + ' OR (Status = \'Completed\' and CompletedDate > :recentJobsTime )) order by CreatedDate DESC';
        System.debug('queryString:' + queryString);
        system.debug('recentJobsTime: ' + recentJobsTime);
        return Database.query(queryString);
    }
    
}