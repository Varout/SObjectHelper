# SObjectHelper

## What's It About?

I wanted to be able to get certain bits of information on the fly using code with Salesforce. I was doing a lot of work with picklists at the time and wanted to put something together to help get the information I needed, faster.
This helper class is used to get information about an SObject, essentially making it easier to get information from the `Schema` object. Including:
- Record types: Id and DeveloperName
- Picklists, and the options available for each picklist (normal and multi)
- A list of the object's fields and their types
- A string with all fields on the object separated by commas, so that the equivalent to `SELECT * FROM SObject` can be used
- A string with all fields for SObjects that are lookups on the selected SObject
- A set of required fields and fields that need to have unique values

The helper also gets information about available SObjects and if the Salesforce Org uses Person Accounts.


## Files

| File Name             | Description          |
|:----------------------|:---------------------|
| SObjectHelper.cls     | The helper class.    |
| SObjectHelperTest.cls | The unit test class. |


## Repo Wiki

More information can be found [here](https://github.com/Varout/SObjectHelper/wiki).