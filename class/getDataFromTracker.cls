global with sharing class getDataFromTracker {


    public getDataFromTracker(ApexPages.StandardController stdController) {}

    public getDataFromTracker() {}
    /**
     * This function is used to get the last Top results
     *
     * @param String record_id Record id
     * @return Map<String, Map<String, String>> accResults Top results and their orders.
     */
    @RemoteAction
    global static Map<String, Map<String, String>> tracker_Controller(String record_id){
        Map<String, Map<String, String>> accResults = new Map<String, Map<String, String>>();
        Map<String, String> response_message = new Map<String, String>();
        response_message.put('success', 'false');
        response_message.put('message', 'No Record Id');
        accResults.put('success', response_message);
        if (record_id.length() > 0) {
            Lead main_lead = [SELECT LastTopResultCategory__c FROM Lead WHERE Id=:record_id];
            String last_cat = main_lead.LastTopResultCategory__c;
            String soql = 'SELECT Relates_To__c, Miles__c, Category__c, Order__c FROM Top_Account_Tracker__c WHERE Related_Lead__c = \''+
                record_id+'\' AND Category__c = \''+last_cat+'\' AND Order__c > 0';
            System.debug('query = ' + soql);
            List<Top_Account_Tracker__c> queryResult = database.query(soql);
            String ids;
            Integer countOrder = 0;
            for(Top_Account_Tracker__c results: queryResult) {
                Map<String, String> accGetDetails = new Map<String, String>();
                ids = results.Relates_To__c; 
                String cat = results.Category__c;
                accGetDetails.put('cat', results.Category__c);
                accGetDetails.put('rank', String.valueOf(results.Order__c));
                accGetDetails.put('dist', String.valueOf(results.Miles__c));
                String accDetails = 'SELECT Id, Name, Industry, Actual_Revenue_Commitment__c, BillingCity, BillingState,'+
                    ' Sic, Boxes_Per_Day__c, Total_Box_SKUs__c FROM Account WHERE id = \''+
                    ids+'\'';
                System.debug('accDetails: ' + accDetails);
                List<account> queryResultAccount = database.query(accDetails);
                system.debug('queryResultAccount: ' + queryResultAccount);

                for(account ResultsAcc: queryResultAccount) {
                    String rev, box, sic, sku;
                    Decimal annual_rev = ResultsAcc.Actual_Revenue_Commitment__c;
                    String sic_val = ResultsAcc.Sic;
                    String asset_val = getAssetDetails(ResultsAcc.Id);
                    Decimal boxes_val = ResultsAcc.Boxes_Per_Day__c;
                    Decimal sku_val = ResultsAcc.Total_Box_SKUs__c;
                    rev = String.valueOf(annual_rev);
                    box = String.valueOf(boxes_val);
                    sic = sic_val;
                    sku = String.valueOf(sku_val);
                    accGetDetails.put('id', ResultsAcc.Id);
                    accGetDetails.put('name', ResultsAcc.Name);
                    accGetDetails.put('city', ResultsAcc.BillingCity);
                    accGetDetails.put('state', ResultsAcc.BillingState);
                    accGetDetails.put('industry', ResultsAcc.Industry);
                    accGetDetails.put('revenue_actual', rev);
                    accGetDetails.put('sic_actual', sic);
                    accGetDetails.put('boxes_actual', box);
                    accGetDetails.put('product_actual', sku);
                    accGetDetails.put('asset', asset_val);
                }
                accResults.put(string.valueof(countOrder), accGetDetails);
                System.debug('acc res'+accResults);
                countOrder++;
            }
            if (countOrder == 0) {
                response_message.put('success', 'false');
                response_message.put('message', 'No previous Records');
                accResults.put('success', response_message);
            }
        }
        system.debug('here i was = ' + accResults);
        return accResults;
    }

    /**
     * This function is used to get the asset related to account
     *
     * @param String account_id Account id
     * @return String asset count and its code. (e.g 2-1018, 1-611)
     */
    public static String getAssetDetails(String account_id) {
        String return_val = '';
        if (String.isNotEmpty(account_id)) {
            String soql = 'SELECT Id, Name, product2.productcode FROM asset WHERE AccountId =  \''+account_id+'\'';
            List<Asset> asset_list = database.query(soql);
            Map<String, Map<String, String>> productcode_and_count = new Map<String, Map<String, String>>();
            for (Asset asset_val : asset_list) {
                System.debug('Asset val '+ asset_val);
                if (productcode_and_count.containsKey(asset_val.Product2Id)) {
                    Map<String, String> temp_val_replace = productcode_and_count.get(asset_val.Product2Id);
                    String asset_count = String.valueOf(Integer.valueof(temp_val_replace.get('count')) + 1);
                    temp_val_replace.put('count', asset_count);
                    productcode_and_count.put(asset_val.Product2Id, temp_val_replace);
                } else {
                    soql = 'SELECT ProductCode FROM Product2 WHERE Id = \''+asset_val.Product2Id+'\' LIMIT 1';
                    List<Product2> product_code = database.query(soql);
                    if (product_code.size() > 0) {
                        Product2 tmp_prod = product_code[0];
                        String product_code_val = tmp_prod.ProductCode;
                        System.debug('product val '+ product_code_val);
                        Map<String, String> temp_count_n_name = new Map<String, String>{
                            'productcode' => product_code_val,
                            'count' => '1'};
                        productcode_and_count.put(asset_val.Product2Id, temp_count_n_name);
                    }
                }
            }
            for (String asset_key : productcode_and_count.keySet()) {
                Map<String, String> temp_count_n_name = new Map<String, String> (productcode_and_count.get(asset_key));
                return_val += ' Name: ' + temp_count_n_name.get('productcode') + ', Quantity: ' + temp_count_n_name.get('count') + ';';
            }
            return_val = return_val.removeEnd(';');
        }
        return return_val;
    }
}