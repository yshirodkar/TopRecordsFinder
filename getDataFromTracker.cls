global with sharing class getDataFromTracker {
    public getDataFromTracker(ApexPages.StandardController stdController) {}
    @RemoteAction
    global static Map<string,Map<string,string>> tracker_Controller(string id){
        string tat = 'select Relates_To__c, Miles__c, Category__c, Order__c from Top_Account_Tracker__c where Related_Lead__c = \''+id+'\' and Order__c > 0';
        System.debug('query ='+tat);
        List<Top_Account_Tracker__c> queryResult = database.query(tat);
        string ids;
        Map<string,Map<string,string>> accResults = new Map<string,Map<string,string>>();
       integer countOrder = 0;
        for(Top_Account_Tracker__c results: queryResult) {
            Map<string,string> accGetDetails = new Map<string,string>();
            ids = results.Relates_To__c; 
            String cat = results.Category__c;
            //String order_num = results.Order__c;
            accGetDetails.put('cat',results.Category__c);
            accGetDetails.put('rank',String.valueOf(results.Order__c));
            string accDetails = 'select Name, Industry, AnnualRevenue from Account where id = \''+ids+'\'';
            system.debug('accDetails: ' + accDetails);
            List<account> queryResultAccount = database.query(accDetails);
            system.debug('queryResultAccount: ' + queryResultAccount);
            for(account ResultsAcc: queryResultAccount) {
                accGetDetails .put('Name',ResultsAcc.Name);
                accGetDetails .put('Industry',ResultsAcc.Industry);
                accGetDetails .put('Revenue',string.valueof(ResultsAcc.AnnualRevenue));
            }
            accResults.put(string.valueof(countOrder), accGetDetails);
            System.debug('acc res'+accResults);
            countOrder++;
        }
        system.debug('here i was = ' + accResults);
        return accResults;    
    }
}