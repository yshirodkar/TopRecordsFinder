public class leadOverrideCon {
   String recordId;
   
public leadoverrideCon(ApexPages.StandardController 
       controller) {recordId = controller.getId();}

public PageReference redirect() {
  Profile p = [select name from Profile where id = 
               :UserInfo.getProfileId()];
                  System.debug('Starting: ' + p);
  if ('Lead Gen - Theo'.equals(p.name)) 
      {
       PageReference customPage =  Page.leadPage;
       customPage.setRedirect(true);
       customPage.getParameters().put('id', recordId);
       return customPage;
      } else {
          return null; //otherwise stay on the same page
      }
   }
}