@isTest
private class getDataFromTrackerTester {

    public static testMethod void tracker_Controller()
    {
        Account lead_test = new Lead(
            LastName = 'Test UVU',
            Company = 'Utah snow exports');
        insert lead_test;
        String leadid = String.valueOf(lead_test.Id);
        Map<String, Map<String, String>> result_val = getDataFromTracker.tracker_Controller(leadid);
    }
}
