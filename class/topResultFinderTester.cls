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
            Industry = 'Furniture');
        insert account_test;
        String accountid = String.valueOf(account_test.Id);
        Map<String,String> filters = new Map<String,String>{
            'industry' => 'Furniture',
            'revenue' => '400'
        };
        Map<String, Map<String, String>> result_val = topResultFinder.getTopResults(
            'account',
            accountid, filters);
    }
}
