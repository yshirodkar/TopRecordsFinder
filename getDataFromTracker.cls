global with sharing class getDataFromTracker {

    public getDataFromTracker(ApexPages.StandardController stdController) {}


    /**
     * This function is used to get the last Top results
     *
     * @param String record_id Record id
     *
     * @return Map<String, Map<String, String>> accResults Top results and their orders.
     */
    @RemoteAction
    global static Map<String, Map<String, String>> tracker_Controller(String record_id){
        Lead main_lead = [SELECT LastTopResultCategory__c FROM Lead WHERE Id=:record_id];
        String last_cat = main_lead.LastTopResultCategory__c;
        String soql = 'SELECT Relates_To__c, Miles__c, Category__c, Order__c FROM Top_Account_Tracker__c WHERE Related_Lead__c = \''+record_id+'\' AND Category__c = \''+last_cat+'\' AND Order__c > 0';
        System.debug('query = ' + soql);
        List<Top_Account_Tracker__c> queryResult = database.query(soql);
        String ids;
        Map<String, Map<String, String>> accResults = new Map<String, Map<String, String>>();
        Integer countOrder = 0;
        for(Top_Account_Tracker__c results: queryResult) {
            Map<String, String> accGetDetails = new Map<String, String>();
            ids = results.Relates_To__c; 
            String cat = results.Category__c;
            accGetDetails.put('cat', results.Category__c);
            accGetDetails.put('rank', String.valueOf(results.Order__c));
            String accDetails = 'SELECT Name, Industry, AnnualRevenue FROM Account WHERE id = \''+ids+'\'';
            System.debug('accDetails: ' + accDetails);
            List<account> queryResultAccount = database.query(accDetails);
            system.debug('queryResultAccount: ' + queryResultAccount);
            for(account ResultsAcc: queryResultAccount) {
                accGetDetails.put('Name',ResultsAcc.Name);
                accGetDetails.put('Industry',ResultsAcc.Industry);
                accGetDetails.put('Revenue',string.valueof(ResultsAcc.AnnualRevenue));
            }
            accResults.put(string.valueof(countOrder), accGetDetails);
            System.debug('acc res'+accResults);
            countOrder++;
        }
        //system.debug('here i was = ' + accResults);
        return accResults;    
    }
}