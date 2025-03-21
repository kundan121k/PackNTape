({
    
    doInit : function(component, event, helper) {

        component.set('v.redirectURI','https://d30000001hbw8eac--dev.sandbox.lightning.force.com/lightning/n/QuickBooks_Connector');

        console.log('redirectUri>>>>',component.get('v.redirectURI'));

        var sURL = window.location.href;

        if(sURL.split('code=')[1] != null){

            component.set('v.isNotAuth',false);

            helper.completeAuthHelper(component, event, helper);

        }

        else{

            component.set('v.isNotAuth',true);

            component.set('v.isAuth',false);

        }

    },

    authorizeController : function(component, event, helper) {

        helper.authorizeHelper(component, event, helper);

    },

})