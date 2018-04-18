({
    doInit: function(component, event, helper){
        console.log(" doInit: Starting timer");
        var timerID = setInterval(function(){helper.checkForChanges(component);}, 1000);
        component.set("v.timerID", timerID);
        console.log("timerID:" + timerID);
    },
    
    handleLocationChange: function(component, event, helper) {
        console.log("Navigated away: Kill timer: " + component.get("v.timerID") + " and destroy component");
        clearInterval(component.get("v.timerID"));
        component.destroy();
    },
    
    btnTimer: function(component, event, helper) {
        var timerRunning = component.get("v.timerRunning");
        console.log("timerRunning:" + timerRunning);
        if (timerRunning == "YES") {
            console.log("Pause timer: " + component.get("v.timerID"));
            clearInterval(component.get("v.timerID"));
            component.set("v.timerBtnVariant","success" );        
            component.set("v.timerBtnLabel","Restart" );        
            component.set("v.timerRunning","NO" );
        } else {
            console.log("Restart timer: ");
            component.set("v.timerBtnVariant","brand" );        
            component.set("v.timerBtnLabel","Pause" );        
            component.set("v.timerRunning","YES" );
            var timerID = setInterval(function(){helper.checkForChanges(component);}, 1000);
            component.set("v.timerID", timerID);    
                    console.log("timerID:" + timerID);

        }
        
    },
    
    
    
    
    
})