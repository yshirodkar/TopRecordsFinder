@isTest
private class topResultFinderTester {
    static Integer LIMIT_CONST = 3;

    public static testMethod void getTopResults()
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
        insert lead_test;
        String leadid = String.valueOf(lead_test.Id);
        
        Map<String, Map<String, String>> result_val = topResultFinder.getTopResults(
            'Account',
            leadid, filters);
    }
}