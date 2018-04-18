({
    
    checkForChanges: function(component) {
        var refreshInterval = component.get("v.refreshInterval");
        var refreshProgress = component.get("v.refreshProgress");
        
        if  (refreshProgress == 0) {
            console.log('Fetching future jobs now...');        
            
            // specify apex method for fetching the waiting and executing list of jobs.
            var action = component.get('c.getFutureJobs');
            action.setParams({ "refreshTimer": refreshInterval }); //the jobs returned include any that finished in the last 2 refreshIntervals
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if (state === 'SUCCESS') {
                    //set response value in AttRecordList attribute on component.
                    component.set('v.JobList', actionResult.getReturnValue());
                    component.set('v.JobCount', actionResult.getReturnValue().length);                    
                    console.log(actionResult.getReturnValue().length + ' jobs found');
                    
                    // 1. Create a map that will map Status to count of jobs with that status
                    var statusMap = new Map();
                    // 2. Iterate through the ReturnValue and
                    // 	if there is a record in the map with that key value, add 1 to that map element,
                    // 	if there isn't a record in the map with that key value, create a record with a count=1 
                    for(var i = 0, size = actionResult.getReturnValue().length; i < size ; i++){
                        if (statusMap.has(actionResult.getReturnValue()[i].Status))  {
                            var tmpStatus=actionResult.getReturnValue()[i].Status;
                            statusMap.set(tmpStatus, statusMap.get(tmpStatus) + 1);
                            console.log("Status:" + tmpStatus + " count:" + statusMap.get(tmpStatus));
                        } else {
                            statusMap.set(actionResult.getReturnValue()[i].Status, 1);
                            console.log("Status:" + actionResult.getReturnValue()[i].Status + " count: initialise at 1");
                        }
                    }
                    //Now that the results have been summarised, populate the repective attribute or set to zero
                    console.log("Set (or zero out) the attributes: ");
                    if (statusMap.has('Queued') ) {
                        component.set('v.QueuedCount',statusMap.get('Queued'));
                        component.set('v.Queuedpct',Math.trunc(statusMap.get('Queued')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.QueuedCount',0);
                        component.set('v.Queuedpct',0);                            
                    }
                    if (statusMap.has('Preparing') ) {
                        component.set('v.PreparingCount',statusMap.get('Preparing'));
                        component.set('v.Preparingpct',Math.trunc(statusMap.get('Preparing')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.PreparingCount',0);
                        component.set('v.Preparingpct',0);
                    }   
                    if (statusMap.has('Processing') ) {
                        component.set('v.ProcessingCount',statusMap.get('Processing'));
                        component.set('v.Processingpct',Math.trunc(statusMap.get('Processing')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.ProcessingCount',0);
                        component.set('v.Processingpct',0);                            
                    }
                    if (statusMap.has('Completed')) {
                        component.set('v.CompletedCount',statusMap.get('Completed'));
                        component.set('v.Completedpct',Math.trunc(statusMap.get('Completed')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.CompletedCount',0);
                        component.set('v.Completedpct',0);                            
                    }
                    if (statusMap.has('Aborted'))  {
                        component.set('v.AbortedCount',statusMap.get('Aborted'));
                        component.set('v.Abortedpct',Math.trunc(statusMap.get('Aborted')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.AbortedCount',0);
                        component.set('v.Abortedpct',0);                            
                    }
                    if (statusMap.has('Failed') ) {
                        component.set('v.FailedCount',statusMap.get('Failed'));
                        component.set('v.Failedpct',Math.trunc(statusMap.get('Failed')/actionResult.getReturnValue().length*100));                            
                    } else {
                        component.set('v.FailedCount',0);
                        component.set('v.Failedpct',0);                            
                    }
//                    if (actionResult.getReturnValue().length>0 ){
 //                       debugger;
  //                  }
                } else {
                    var toastEvent = $A.get("e.force:showToast"); 
                    var toastMessage = "Something went wrong with the call to get the future jobs";
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": toastMessage
                    });
                    toastEvent.fire();
                }
            })
            
            $A.enqueueAction(action);
            
        }
        
        refreshProgress++;
        component.set("v.refreshProgressPCT",Math.trunc(refreshProgress/refreshInterval *100));
        if (refreshProgress == refreshInterval) {
            component.set("v.refreshProgress",0);
        } else {
            component.set("v.refreshProgress",refreshProgress);
        }
        
    },
    
})