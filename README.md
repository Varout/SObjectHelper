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


## Available Functions

### Static Functions

| Function                                 | Return Type   | Description                                                           |
|:-----------------------------------------|:--------------|:----------------------------------------------------------------------|
| `SObjectHelper.getSetOfOrgSObjects();`   | `Set<String>` | A set of all SObjects in the Salesforce Org. Including setup objects. |
| `SObjectHelper.orgUsesPersonAccounts();` | `Boolean`     | Returns true if the Salesforce Org uses Person Accounts.              |


### Public Non-Static Functions
| Function                                 | Expected Params                 | Return Type   | Description                                                                                                                                                                                                                     |
|:-----------------------------------------|:--------------------------------|:--------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `createQueryStringForRelatedSObject();`  | `String`                        | `String`      | Creates a query string for lookup fields on the current object. e.g `Contact.Account`. If the field is a standard Salesforce field it should have 'Id' on the end, and if it is a custom field it should have '__c' on the end. |
| `createQueryStringForRelatedSObjects();` | `Set<String>` or `List<String>` | `String`      | Same as above, but for getting for multiple lookups at once. See **Quick How To Use** for an example.                                                                                                                           |
| `getDefaultRecordTypeId();`              | None                            | `Id`          | Returns the default record type Id for the User on the current SObject.                                                                                                                                                         |

### Public Variables

| Name                    | Type                                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|:------------------------|:------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| selectAllString         | `String`                                  | Contains a comma separated string with all available fields on the object.  e.g "Id, Name, CreatedDate, CreatedById,..." to achieve the equivalent of `SELECT * FROM SObject` in Salesforce.                                                                                                                                                                                                                                                         |
| mapRecordTypeNameToId   | `Map<String, Id>`                         | The Key (String) is the DeveloperName of the record type. The Value (Id) is the Salesforce Id value for that record type.                                                                                                                                                                                                                                                                                                                            |
| mapDevNameToType        | `Map<String, String>`                     | The Key (String) is the DeveloperName of a field on the SObject. The Value (String) is the data type of the field.                                                                                                                                                                                                                                                                                                                                   |
| mapPicklistValues       | `Map<String, List<Schema.PicklistEntry>>` | The Key (String) is the name of a picklist field on the SObject. The Value (List<PicklistEntry>) is a list of PicklistEntry records for the picklist. Which can be used to populate a picklist with available options. More information: <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_PicklistEntry.htm#apex_class_Schema_PicklistEntry" target="_blank">Salesforce: Schema.PicklistEntry</a> |
| mapRelatedSObjectFields | `Map<String, Set<String>>`                | The Key (String) is the name of the SObject. The Values are the field names for all fields on that SObject.                                                                                                                                                                                                                                                                                                                                          |


## Quick How To Use

** Inititalise **

```Java
SObjectHelper accountHelper = new SObjectHelper('Account');
```

```Java
SObjectHelper customObjectHelper = new SObjectHelper('MyCustomObject__c');
```


** Field String **

For the main SObject that the helper has been initiated with, this will return all fields for only that object:

```Java
String accountFields = accountHelper.selectAllString;
```

To get fields for all or specific objects that have Lookups or Master-Detail Lookups on this SObject:

```Java
String contactFieldsOnAccount = accountHelper.createQueryStringForRelatedSObject('ContactId');
```

```Java
String customObjectFieldsOnAccount = accountHelper.createQueryStringForRelatedSObject('CustomObject__c');
```

You can group multiple objects at time in a Set or List

```Java
List<String> sobjs = new List<String>{'ContactId', 'CustomObject__c'};
```

```Java
String queryString = accountHelper.createQueryStringForRelatedObjects(sobjs);
```

_Example_

```Java
SObjectHelper contractHelper = new SObjectHelper('Contract');
Set<String> testSet = new Set<String>{'AccountId', 'CustoObj__c'};

String queryString = '';
queryString += 'SELECT ' + contractHelper.selectAllString + ',\n';
queryString += contractHelper.createQueryStringForRelatedSObjects(testSet) + '\n';
queryString += ' FROM Contract';

List<SObject> theResults = Database.query(queryString);
```


## Schema.Picklist (Picklist Entry Methods)
SObject detail taken from the Salesforce documentation page: <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_PicklistEntry.htm#apex_class_Schema_PicklistEntry" target="_blank">Salesforce: Schema.PicklistEntry</a>

The following are methods for PicklistEntry. All are instance methods.

- getLabel(): `String`

Returns the display name of this item in the picklist.


- getValue(): `String`

Returns the value of this item in the picklist.


- isActive(): `Boolean`

Returns true if this item must be displayed in the drop-down list for the picklist field in the user interface, false otherwise.


- isDefaultValue(): `Boolean`

Returns true if this item is the default value for the picklist, false otherwise. Only one item in a picklist can be designated as the default.
