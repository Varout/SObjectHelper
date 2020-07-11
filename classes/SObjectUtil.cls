/**
 * @class:   SObjectUtil.cls
 * @test:    SObjectUtilTest.cls
 * @author:  Jason Auger
 * @desc:    The aim of this class is to make it easier to get the needed infromation from SObjects
 *           without having to go into the finer details of working with the Schema object and 
 *           the array of get/describe functions that go with it.
 * @licence: Copyright (c) 2020, Jason Auger
 *           Permission is hereby granted, free of charge, to any person obtaining a copy
 *           of this software and associated documentation files (the "Software"), to deal
 *           in the Software without restriction, including without limitation the rights
 *           to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *           copies of the Software, and to permit persons to whom the Software is
 *           furnished to do so, subject to the following conditions:
 *           
 *           The above copyright notice and this permission notice shall be included in all
 *           copies or substantial portions of the Software.
 *           
 *           THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *           IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *           FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *           AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *           LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *           OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *           SOFTWARE.
 */
public with sharing class SObjectUtil {

    public class SObjectUtilException extends Exception{}

    final private Set<String> ENUM_LOOKUPS = new Set<String>{'REFERENCE'};
    final private Set<String> ENUM_PICKLISTS = new Set<String>{'PICKLIST', 'MULTIPICKLIST'};
    //  Salesforce ENUM information: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
    final private Set<String> ENUM_FIELD_TYPES = new Set<String>{
        'ADDRESS', 'ANYTYPE', 'BASE64', 'BOOLEAN', 'COMBOBOX', 'CURRENCY',
        'DATACATEGORYGROUPREFERENCE', 'DATE', 'DATETIME', 'DOUBLE', 'EMAIL',
        'ENCRYPTEDSTRING', 'ID', 'INTEGER', 'LONG', 'MULTIPICKLIST', 'PERCENT',
        'PHONE', 'PICKLIST', 'REFERENCE', 'STRING', 'TEXTAREA', 'TIME', 'URL'
    };
    public Map<String, Set<String>> evilObjectFieldNames = new Map<String, Set<String>>();

    private SObjectType theSObjectDescribe { get; private set; }
    public Id recordTypeIdDefault { get; private set; }
    public Id recordTypeIdMaster { get; private set; }
    public Set<String> setLookupDevNames { get; set; }
    public String selectAllString { get; private set; }                 //  A comma separated string of all fields on the SObject. Intended to act as * for SOQL queries
    public Set<String> fieldsRequired { get; private set; }             //  The DeveloperNames of required fields on the SObject level
    public Set<String> fieldsUnique { get; private set; }               //  The DeveloperNames of fields that need to be unique to create or update a record
    public Map<String, Id> mapRecordTypeNameToId { get; private set; }  //  Maps the DeveloperName of a record type to its Id
    public Map<String, String> mapDevNameToType { get; private set; }   //  Maps the DeveloperName of a field to its field type (See: ENUM_FIELD_TYPES)
    //  Schema.PicklistEntry function information: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_PicklistEntry.htm#apex_class_Schema_PicklistEntry
    public Map<String, List<Schema.PicklistEntry>> mapPicklistValues { get; private set; }  //  Maps the DeveloperName of a picklist or multipicklist to its PicklistEntry vales
    public Map<String, Set<String>> mapLookupDevNameToFields { get; private set; }          //  Maps the DeveloperName of a lookup field to a Set of strings which are the DeveloperNames of fields on the related SObject (Not automatically populated)

    public Map<String, Set<String>> mapRelatedSObjectFields { get; private set; }           //  Used for Lookups and MD-Lookups. Maps lookup field name to the set of fields on that object
    public Map<String, String> mapFieldNameToSObjectType { get; private set; }              //  Maps the looup field name to the SObject


    public SObjectUtil(String reqSObjectType) {
        //  Some standard SObjects don't like certain fields to be queried
        //  Will likely be added to over time. Is public in case fields are found
        //  with an object and they can be added to the filter here
        this.evilObjectFieldNames.put('Contract', new Set<String>{
            'ShippingStreet', 'ShippingCity', 'ShippingState', 'ShippingPostalCode', 'ShippingCountry', 'ShippingLatitude', 
            'ShippingLongitude', 'ShippingGeocodeAccuracy', 'ShippingAddress', 'Name'});
    

        //  Now back to normal
        Map<String, Schema.SObjectType> mapOrgSchema = Schema.getGlobalDescribe();
        try {
            this.theSObjectDescribe = Schema.getGlobalDescribe().get(reqSObjectType);
        } catch (Exception e) {
            throw new SObjectUtilException('An error occurred: ' + e.getMessage());
        }
        if (this.theSObjectDescribe == null) {
            String errorString = '';
            errorString += 'The SObject: "' + reqSObjectType + '" does not exist in this org. ';
            errorString += 'If you are using a custom object, remember to add the __c at the end. ';
            throw new SObjectUtilException(errorString);
        }

        this.setLookupDevNames = new Set<String>();
        this.fieldsUnique      = new Set<String>();
        this.fieldsRequired    = new Set<String>();
        this.mapDevNameToType          = new Map<String, String>();
        this.mapPicklistValues         = new Map<String, List<Schema.PicklistEntry>>();
        this.mapLookupDevNameToFields  = new Map<String, Set<String>>();
        this.mapRelatedSObjectFields   = new Map<String, Set<String>>();
        this.mapFieldNameToSObjectType = new Map<String, String>();
        
        //  Populate data for the main SObject
        try {
            this.populateMapFieldInformation(reqSObjectType);
            this.populateRecordTypeInformation(reqSObjectType);
        } catch (Exception e) {
            throw new SOBjectUtilException('Could not set up data for SObject: ' + reqSObjectType + '. An error occurred: ' + e.getMessage());
        }
    }


    /*  ****************************************  */
    /*             Private Functions              */
    /*  ****************************************  */

    /**
     * Populates the public variables: 
     * - mapDevNameToType
     * - requiredFields
     * @param   String. API Name of the SObject to populate field name and type inforation for.
     */
    private void populateMapFieldInformation(String theSObjectType) {
        Map<String, Schema.SObjectField> mapAccFields = this.theSObjectDescribe.getDescribe().fields.getMap();

        for (String fieldKey : mapAccFields.keySet()) {
            //  Populdate map of FieldName to FieldType
            String fieldName = mapAccFields.get(fieldKey).getDescribe().getName();

            if (this.evilObjectFieldNames.containsKey(theSObjectType) && this.evilObjectFieldNames.get(theSObjectType).contains(fieldName)) {
                continue;
            }

            String fieldType = String.valueOf(mapAccFields.get(fieldKey).getDescribe().getType());
            this.mapDevNameToType.put(fieldName, fieldType);

            //  Populates set of unique fields on the SObject
            if (mapAccFields.get(fieldKey).getDescribe().isUnique()) {
                this.fieldsUnique.add(mapAccFields.get(fieldKey).getDescribe().getName());
            }

            //  Populates set of required fields on the SObject level
            if (!mapAccFields.get(fieldKey).getDescribe().isNillable()) {
                this.fieldsRequired.add(mapAccFields.get(fieldKey).getDescribe().getName());
            }

            //  Populate map of FieldName to PicklistValues for any picklist field type
            if (this.ENUM_PICKLISTS.contains(fieldType.toUpperCase())) {
                this.mapPicklistValues.put(fieldName, mapAccFields.get(fieldKey).getDescribe().getPicklistValues());
            }

            //  Populate set of Lookup and Master-Detail fields on the SObject
            if (this.ENUM_LOOKUPS.contains(fieldType.toUpperCase())) {
                if (mapAccFields.get(fieldKey).getDescribe().isNamePointing()) {
                    //  isNamePointing(): If getDescribe points to more than one object
                    //  Example of this is the lookup can look to: User, Group
                    for (Schema.SObjectType sot : mapAccFields.get(fieldKey).getDescribe().getReferenceTo()) {
                        this.populateRelatedSObjectInformation(fieldName, sot);
                    }
                } else {
                    this.populateRelatedSObjectInformation(fieldName, mapAccFields.get(fieldKey).getDescribe().getReferenceTo()[0]);
                }
            }
        }

        //  Populate select all string used for a wildcard SOQL selector query
        this.selectAllString = String.join(new List<String>(this.mapDevNameToType.keySet()), ', ');
    }


    /**
     * Populates the map of SObject Name to a set of field API names for each object the
     * requested SObject has lookups for
     * @param   Schema.SobjectType. The SObject to populate the fields for
     */
    private void populateRelatedSObjectInformation(String theFieldName, Schema.SObjectType theSObject) {
        //  We don't want to know about RecordType
        if (theFieldName == 'RecordTypeId') {
            return;
        }

        //  Store map for fields, sobject name, and field name
        String sObjectName = theSObject.getDescribe().getName();
        this.mapFieldNameToSObjectType.put(theFieldName, sObjectName);
        if (!this.mapRelatedSObjectFields.keySet().contains(sObjectName)) {
            // System.debug('Populating related field information for: ' + sObjectName);
            Set<String> flds = theSObject.getDescribe().fields.getMap().keySet();

            //  Remove any nasty fields listed above so we don't run into any issues while querying
            if (this.evilObjectFieldNames.containsKey(sObjectName)) {
                for (String fd : flds) {
                    if (this.evilObjectFieldNames.get(sObjectName).contains(fd)) {
                        flds.remove(fd);
                    }
                }
            }

            this.mapRelatedSObjectFields.put(sObjectName, flds);
        }
    }


    /**
     * Uses the Schema class to get information about Record Types for the SObject. Also popultes
     * Ids for the default record type Id for the user, and the master record type Id to fall back on
     * @param   String. The name of the SObject
     */
    private void populateRecordTypeInformation(String theSObjectType) {
        this.mapRecordTypeNameToId = new Map<String, Id>();
        Schema.DescribeSObjectResult sObjectResult = null;

        try {
            List<Schema.DescribeSObjectResult> tempSObjResults = Schema.describeSObjects(new List<String>{theSObjectType});
            sObjectResult = tempSObjResults[0];
        } catch (Exception e) {
            System.debug('SObjectUtil: Could not populate record types using Schema for: ' + theSObjectType);
            System.debug(e.getMessage());
            return;
        }

        for (Schema.RecordTypeInfo rti : sObjectResult.getRecordTypeInfos()) {
            //  Default record type for the user running the code
            if (rti.isDefaultRecordTypeMapping()) {
                this.recordTypeIdDefault = rti.getRecordTypeId();
            }
            //  Default record type for the SObject. Used as a fall back
            if (rti.isMaster()) {
                this.recordTypeIdMaster = rti.getRecordTypeId();
            }
            //  Populate the map for DeveloperName to RecordTypeId
            if (rti.getDeveloperName() != 'Master') {   //  Don't need as this isn't returned when using SOQL
                this.mapRecordTypeNameToId.put(rti.getDeveloperName(), rti.getRecordTypeId());
            }
        }
    }


    /*  ****************************************  */
    /*             Public Functions               */
    /*  ****************************************  */

    /**
     * Creates a query string for lookup fields on the current object
     * @param   String. The field related to the sobject lookup to create a query string for
     *                  - If it is a standard lookup, then the field name will end with 'Id'
     *                  - If it is a custom lookup, then the field name will end with '__c'
     * @return  String. The query string for the SObject
     */
    public String createQueryStringForRelatedSObject(String passedSObjFieldName) {
        //  Handle if the sobject lookup doesn't exist
        if (!this.mapFieldNameToSObjectType.containsKey(passedSObjFieldName)) {
            return '';
        }

        String sObjectName = this.mapFieldNameToSObjectType.get(passedSObjFieldName);
        String queryString = '';
        for (String fieldName : this.mapRelatedSObjectFields.get(sObjectName)) {
            queryString += passedSObjFieldName.replace('__c', '__r').removeEndIgnoreCase('id') + '.' + fieldName.capitalize() + ',';
        }
        return queryString.removeEnd(',');
    }


    /**
     * Same as above, but accepts Set<String>
     */
    public String createQueryStringForRelatedSObjects(Set<String> sObjectNames) {
        String queryString = '';
        for (String sObj : sObjectNames) {
            queryString += this.createQueryStringForRelatedSObject(sObj) + ',';
        }
        return queryString.removeEnd(',');
    }


    /**
     * Same as above, but accepts List<String>
     */
    public String createQueryStringForRelatedSObjects(List<String> sObjectNames) {
        Set<String> setSObjectNames = new Set<String>();
        setSObjectNames.addAll(sObjectNames);
        return this.createQueryStringForRelatedSObjects(setSObjectNames);
    }


    /**
     * Returns the default record type Id for the user. If none is found,
     * returns the Master record type Id. Returns null if both aren't populated
     * @return  Id. The record type Id
     */
    public Id getDefaultRecordTypeId() {
        if (this.recordTypeIdDefault != null) {
            return this.recordTypeIdDefault;
        } else if (this.recordTypeIdMaster != null) {
            return this.recordTypeIdMaster;
        }
        //  I don't really expect this to ever happen, just a catch-all
        return null;
    }


    /*  ****************************************  */
    /*          Public Static Functions           */
    /*  ****************************************  */

    /**
     * Gets the developer name for all standard and custom objects
     * in the current Salesforce org
     * @return  Set<String>.
     */
    public static Set<String> getSetOfOrgSObjects() {
        Set<String> sObjects = new Set<String>();
        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            sObjects.add(String.valueOf(sObjType));
        }
        return sObjects;
    }


    /**
     * Checks to see if Person Accounts are enabled in the current org
     * @return  Boolean. Returns true if the current org uses Person Accounts
     */
    public static Boolean orgUsesPersonAccounts() {
        return Schema.SObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    }
}