# TopRecordsFinder

This project's main intention is to findout the closest top 3 records from existing records. It should show top 3 records based on what page you are on. If the record type is lead then there should be top3 records on screen. Top records will be decided by different criteria.
1. Industry type should match.
2. It should be closest distance from current address.
3. The revenue should be close the current record. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

For geolocation Account and Lead need to activate data validation rule to make sure address is right
Instructions are here 
https://help.salesforce.com/articleView?id=data_dot_com_clean_add_geocode_information_to_all_records.htm&type=0

Also to see the top record you need to go accountPage visualforce page(in case of account).

https://c.na59.visual.force.com/apex/leadPage?id=00Q...

There should be lead field which keep track of last top results category.
Field name: LastTopResultCategory__c

There is custom setting in salesforce ```topResultSettings```. This will allow to change the limit.
This custom setting have different fields which you can set according to `profile`.
```boxRange__c``` for box range. (Default value = 15)
```distanceRange__c``` for distance range. (Default value = 1)
```revenueRange__c``` for revenue range. (Default value = 1000)
```	sicRange__c``` for sic code range. (Default value = 1)
```skuRange__c ``` for product sku range. (Default value = 1)

```record_display_limit__c``` for displaying record limit. (Default value = 3)

### Installing

You need to add all the .cls files, .page files and also need to add jquery lib.
1. topResultFinder.cls should go in apex classes.
2. accountPage.page, boxTracker.page should go in apex page
3. jquery lib file should go in static resource file

### Implementation
Enable VF for standard layout:
1. Go to Setup.
2. On the Quick Search look for "Buttons, Links, and Actions" under the lead object.
3. Look for "View" and edit.
4. Select for Override View: leadPage and Save.