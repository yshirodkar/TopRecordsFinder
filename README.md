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

https://c.na59.visual.force.com/apex/accountPage?Id=001f4000005YxYk

There should be lead field which keep track of last top results category.
Field name: LastTopResultCategory__c

### Installing

You need to add all the .cls files, .page files and also need to add jquery lib.
1. topResultFinder.cls should go in apex classes.
2. accountPage.page, boxTracker.page should go in apex page
3. jquery lib file should go in static resource file

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```


## License

This project is licensed under the xxxx

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
