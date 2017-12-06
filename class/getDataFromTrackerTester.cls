@isTest
private class getDataFromTrackerTester {

    public static testMethod void tracker_Controller()
    {
                Account account_test = new Account(
            Name = 'Test UVU',
            BillingState = 'Utah',
            BillingCity = 'Orem',
            BillingStreet = '800 W University Pkwy',
            BillingCountry = 'United States',
            BillingLatitude = 40.279456,
            BillingLongitude = -111.715167,
            Install_Date__c = Date.newInstance(2017, 11, 05),
            Type = 'Paying Customer',
            Industry = 'Mission Critical');
        insert account_test;
        String accountid = String.valueOf(account_test.Id);
        Map<String,String> filters = new Map<String,String>{
            'industry' => 'Mission Critical',
            'revenue' => '400',
            'order_by' => 'revenue'
        };
        Lead lead_test = new Lead(
            LastName = 'Test UVU',
            Company = 'Utah snow exports',
            Latitude = 40.279456,
            Longitude = -111.715167,
            LastTopResultCategory__c = 'revenue');
        Asset test_asset = new Asset(
            AccountId = account_test.Id,
            Name = 'Test Asset',
            Product2Id = '01t50000003Vi2z'
        );
        
        System.debug('acc id '+ account_test.Id);
        insert test_asset;
        insert lead_test;
        String leadid = String.valueOf(lead_test.Id);
        
        Map<String, Map<String, String>> result_val = topResultFinder.getTopResults(
            'Account',
            leadid, filters);
        Map<String, Map<String, String>> result_val_test = getDataFromTracker.tracker_Controller(leadid);
    }
}