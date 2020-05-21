# SObjectUtil

## What's It About?

I wanted to be able to get certain bits of information on the fly using code with Salesforce. I was doing a lot of work with picklists at the time and wanted to put something together to help get the information I needed, faster.
This util class helps to get most useful information about an SObject. Including:
- Record types: Id and DeveloperName
- Picklists, and the options available for each picklist (normal and multi)
- A list of the object's fields and their types
- A string with all fields on the object separated by commas, so that the equivalent to `SELECT * FROM SObject` can be used

The util also gets information about available SObjects and if the Salesforce Org uses Person Accounts.

## Files

| File Name           | Description          |
|:--------------------|:---------------------|
| SObjectUtil.cls     | The utility class.   |
| SObjectUtilTest.cls | The unit test class. |

## Available Functions

### Static Functions

| Function                               | Return Type   | Description                                                           |
|:---------------------------------------|:--------------|:----------------------------------------------------------------------|
| `SObjectUtil.getSetOfOrgSObjects();`   | `Set<String>` | A set of all SObjects in the Salesforce Org. Including setup objects. |
| `SObjectUtil.orgUsesPersonAccounts();` | `Boolean`     | Returns true if the Salesforce Org uses Person Accounts.              |

### Public Variables

| Name                  | Type                                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|:----------------------|:------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| selectAllString       | `String`                                  | Contains a comma separated string with all available fields on the object.  e.g "Id, Name, CreatedDate, CreatedById,..." to achieve the equivalent of `SELECT * FROM SObject` in Salesforce.                                                                                                                                                                                                                                                         |
| mapRecordTypeNameToId | `Map<String, Id>`                         | The Key (String) is the DeveloperName of the record type. The Value (Id) is the Salesforce Id value for that record type.                                                                                                                                                                                                                                                                                                                            |
| mapDevNameToType      | `Map<String, String>`                     | The Key (String) is the DeveloperName of a field on the SObject. The Value (String) is the data type of the field.                                                                                                                                                                                                                                                                                                                                   |
| mapPicklistValues     | `Map<String, List<Schema.PicklistEntry>>` | The Key (String) is the name of a picklist field on the SObject. The Value (List<PicklistEntry>) is a list of PicklistEntry records for the picklist. Which can be used to populate a picklist with available options. More information: <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_PicklistEntry.htm#apex_class_Schema_PicklistEntry" target="_blank">Salesforce: Schema.PicklistEntry</a> |

## Quick How To Use

Say we want to use Account as an example

** Inititalise **
```SObjectUtil accountUtil = new SObjectUtil('Account');```

** Field String **
```String accountFields = accountUtil.selectAllString;```

## Schema.Picklist (Picklist Entry Methods)
SObject detail taken from the Salesforce documentation page
The following are methods for PicklistEntry. All are instance methods.

- getLabel()
`String`. Returns the display name of this item in the picklist.
- getValue()
`String`. Returns the value of this item in the picklist.
- isActive()
`Boolean`. Returns true if this item must be displayed in the drop-down list for the picklist field in the user interface, false otherwise.
- isDefaultValue()
`Boolean`. Returns true if this item is the default value for the picklist, false otherwise. Only one item in a picklist can be designated as the default.