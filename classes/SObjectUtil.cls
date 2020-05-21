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

    final private Set<String> ENUM_PICKLISTS = new Set<String>{'PICKLIST', 'MULTIPICKLIST'};
    //  Salesforce ENUM information: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
    final private Set<String> ENUM_FIELD_TYPES = new Set<String>{
        'ADDRESS', 'ANYTYPE', 'BASE64', 'BOOLEAN', 'COMBOBOX', 'CURRENCY',
        'DATACATEGORYGROUPREFERENCE', 'DATE', 'DATETIME', 'DOUBLE', 'EMAIL',
        'ENCRYPTEDSTRING', 'ID', 'INTEGER', 'LONG', 'MULTIPICKLIST', 'PERCENT',
        'PHONE', 'PICKLIST', 'REFERENCE', 'STRING', 'TEXTAREA', 'TIME', 'URL'
    };

    private SObjectType theSObjectDescribe { get; private set; }

    public String selectAllString { get; private set; }
    public Map<String, Id>     mapRecordTypeNameToId { get; private set; }
    public Map<String, String> mapDevNameToType { get; private set; }
    //  Schema.PicklistEntry function information: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_PicklistEntry.htm#apex_class_Schema_PicklistEntry
    public Map<String, List<Schema.PicklistEntry>> mapPicklistValues { get; private set; }

    public SObjectUtil(String sObjectType) {
        try {
            this.theSObjectDescribe = Schema.getGlobalDescribe().get(sObjectType);
        } catch (Exception e) {
            throw new SObjectUtilException('An error occurred: ' + e.getMessage());
        }
        if (this.theSObjectDescribe == null) {
            String errorString = '';
            errorString += 'The SObject: "' + sObjectType + '" does not exist in this org. ';
            errorString += 'If you are using a custom object, remember to add the __c at the end. ';
            throw new SObjectUtilException(errorString);
        }

        try {
            this.populateMapFieldInformation(sObjectType);
            this.populateMapRecordTypes(sObjectType);
        } catch (Exception e) {
            throw new SOBjectUtilException('An error occurred: ' + e.getMessage());
        }
    }

    /*  ****************************************  */
    /*             Private Functions              */
    /*  ****************************************  */

    /**
     * Populates the public variable in the class: mapDevNameToType
     * @param   String. API Name of the SObject to populate field
     *          name and type inforation for.
     */
    private void populateMapFieldInformation(String theSObjectType) {
        this.mapDevNameToType = new Map<String, String>();
        this.mapPicklistValues = new Map<String, List<Schema.PicklistEntry>>();
        Map<String, Schema.SObjectField> mapAccFields = this.theSObjectDescribe.getDescribe().fields.getMap();

        for (String fieldKey : mapAccFields.keySet()) {
            //  Populdate map of FieldName to FieldType
            String fieldName = mapAccFields.get(fieldKey).getDescribe().getName();
            String fieldType = String.valueOf(mapAccFields.get(fieldKey).getDescribe().getType());
            this.mapDevNameToType.put(fieldName, fieldType);

            //  Populate map of FieldName to PicklistValues for any picklist field type
            if (this.ENUM_PICKLISTS.contains(fieldType.toUpperCase())) {
                this.mapPicklistValues.put(fieldName, mapAccFields.get(fieldKey).getDescribe().getPicklistValues());
            }
        }

        //  Populate select all string used for a wildcard SOQL selector query
        this.selectAllString = String.join(new List<String>(this.mapDevNameToType.keySet()), ', ');
    }

    /**
     * Populates the public variable in the class: mapRecordTypeNameToId
     * @param   String. API Name of the SObject to populate Record Type
     *          information for.
     */
    private void populateMapRecordTypes(String theSObjectType) {
        this.mapRecordTypeNameToId = new Map<String, Id>();

        for (RecordType rt : this.queryRecordTypes(theSObjectType)) {
            this.mapRecordTypeNameToId.put(rt.DeveloperName, rt.Id);
        }
    }

    /**
     * Uses a SOQL query to get all record types for the given sobject
     * @param   String. Name of the SObject to query record types for
     * @return  List<RecordType>
     */
    private List<RecordType> queryRecordTypes(String theSObjectType) {
        return [
            SELECT Id, Name, DeveloperName, IsActive, SObjectType, Description
            FROM RecordType
            WHERE SObjectType = :theSObjectType
        ];
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