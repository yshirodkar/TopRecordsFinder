@isTest
private class leadOverrideConTest {
    static Integer LIMIT_CONST = 3;

    public static testMethod void getTopResults()
    {
        leadOverrideCon loc = new leadOverrideCon();
        loc.redirect();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Lead Gen - Theo'];
        
        User u1 = new User(Alias = 'standt1',
            Country='United Kingdom',
            EmailEncodingKey='UTF-8',
            Email='demo1@randomdemodomain.com',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='a@c.org');
        insert u1;
        System.runAs(u1){
            loc.redirect();
        }
    }
}