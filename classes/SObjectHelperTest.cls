/**
 * @class:   SObjectHelperTest.cls
 * @author:  Jason Auger
 * @github:  https://github.com/Varout/SObjectHelper
 * @desc:    Test class for SObjectHelper.cls
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
@isTest
private class SObjectHelperTest {
    static Set<String> PREFERRED_SOBJECTS = new Set<String>{'Account', 'Contact', 'Case', 'Lead', 'Opportunity', 'Order', 'Product2'};

    /*  ****************************************  */
    /*            Unit Test Functions             */
    /*  ****************************************  */

    /**
     * Check to see if the org uses Person Accounts by using two different methods
     * and then check against what the helper class returns
     */
    @isTest
    static void testOrgUsesPersonAccounts() {
        Boolean paCheckMethodOne = null;
        try {
            SObject testObject = new Account();
            testObject.get('isPersonAccount');
            // If we got here without an exception, set to true.
            paCheckMethodOne = true;
        } catch(Exception ee) {
            // An exception was generated trying to access the isPersonAccount field
            // so person accounts aren't enabled; set to false.
            paCheckMethodOne = false;
        }

        Boolean paCheckMethodTwo = Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');

        Boolean paCheckHelperClass = SObjectHelper.orgUsesPersonAccounts();

        System.assertEquals(paCheckHelperClass, paCheckMethodOne);
        System.assertEquals(paCheckHelperClass, paCheckMethodTwo);
    }


    /**
     * Tests getting all SObjects in an org from the static function
     */
    @isTest
    static void testGetSetOfOrgSObjects() {
        //  Populate the set
        Set<String> orgSObjects = SObjectHelper.getSetOfOrgSObjects();

        //  We know there are standard objects, so the set should have at least one entry
        System.assert(orgSObjects.size() > 0);
        //  We also know there are a list of standard Salesforce objects which can be checked
        //  to see if they are in the set, but in the unlikely event they change, they won't
        //  be checked here

        System.debug(orgSObjects);
        //  Check that the queries list contains at least all the SObjects in the preferred list
        for (String sObj : PREFERRED_SOBJECTS) {
            System.debug(sObj);
            System.assert(orgSObjects.contains(sObj));
        }
    }


    /**
     * Tests to see that we can successfully create a helper instance for a valid SObject,
     * and that an error is thrown when trying to create a helper instance for an invalid object
     */
    @isTest
    static void testConstructorSuccessAndFail() {
        String sObjectAPINameToTest = null;
        Set<String> retrievedSObjs = SObjectHelper.getSetOfOrgSObjects();
        for (String sObj : PREFERRED_SOBJECTS) {
            if (retrievedSObjs.contains(sObj)) {
                sObjectAPINameToTest = sObj;
                break;
            }
        }
        System.assertNotEquals(null, sObjectAPINameToTest);

        Boolean resultOfPassTest = null;
        String exceptionPass = '';
        try {
            SObjectHelper helperTestPass = SObjectHelper.get(sObjectAPINameToTest);
            resultOfPassTest = true;
        } catch (Exception e) {
            resultOfPassTest = false;
            exceptionPass = e.getMessage();
        }
        System.assertEquals(true, resultOfPassTest, 'Could not create SObjectHelper class for SObject: ' + sObjectAPINameToTest + '. Error: ' + exceptionPass);

        String sObjFail = sObjectAPINameToTest + '__Fail';
        Boolean resultOfFailTest = null;
        try {
            SObjectHelper helperTestFail = SObjectHelper.get(sObjFail);
            resultOfFailTest = true;
        } catch (Exception e) {
            resultOfFailTest = false;
        }
        System.assertEquals(false, resultOfFailTest, 'The SObjectHelper class was successfully created for: ' + sObjFail + ' when it should have failed.');
    }


    /**
     * Tests that the record type map is appropriately set to null when no record types are set
     * for a given SObject in the org
     */
    @isTest
    static void testPopulateMapRecordTypesZero() {
        String sObjectAPINameToTest = null;
        Set<String> sObjectsWithRts = getSObjectsWithRecordTypes();
        Set<String> retrievedSObjs = SObjectHelper.getSetOfOrgSObjects();

        //  All SObjects in the sObjectsWithRts should be in retrievedSObjs
        for (String sObjToRemove : sObjectsWithRts) {
            if (retrievedSObjs.contains(sObjToRemove)) {
                retrievedSObjs.remove(sObjToRemove);
            }
        }

        //  Get random SObject
        Integer randomSObjectNumber = Integer.valueOf(Math.random() * (retrievedSObjs.size() - 1));
        Integer indexCount = 0;
        for (String sObjectName : retrievedSObjs) {
            if (indexCount == randomSObjectNumber) {
                sObjectAPINameToTest = sObjectName;
            }
            indexCount++;
        }

        //  Get the info and do the asserts
        SObjectHelper testSObjHelper = SObjectHelper.get(sObjectAPINameToTest);
        Integer testSObjHelperRtSize = testSObjHelper.mapRecordTypeNameToId.keySet().size();
        List<RecordType> querySObjRts = [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = :sObjectAPINameToTest
        ];

        System.assertEquals(querySObjRts.size(), testSObjHelper.mapRecordTypeNameToId.keySet().size());
        for (RecordType rt : querySObjRts) {
            System.assert(testSObjHelper.mapRecordTypeNameToId.keySet().contains(rt.Name));
            System.assertEquals(rt.Id, testSObjHelper.mapRecordTypeNameToId.get(rt.Name));
        }
    }


    /**
     * Tests that the record type map is appropriately populated when an SObject has more than
     * one record type
     */
    @isTest
    static void testPopulateMapRecordTypesMultiple() {
        String sObjectAPINameToTest = null;
        Set<String> sObjectsWithRts = getSObjectsWithRecordTypes();

        if (!sObjectsWithRts.isEmpty()) {

            Integer randomSObjectNumber = Integer.valueOf(Math.random() * (sObjectsWithRts.size() - 1));
            Integer indexCount = 0;
            for (String sObjectName : sObjectsWithRts) {
                if (indexCount == randomSObjectNumber) {
                    sObjectAPINameToTest = sObjectName;
                }
                indexCount++;
            }

            for (String sObj : PREFERRED_SOBJECTS) {
                if (sObjectsWithRts.contains(sObj)) {
                    sObjectAPINameToTest = sObj;
                    break;
                }
            }
            System.assertNotEquals(null, sObjectAPINameToTest);

            //  Do the asserts
            SObjectHelper testSObjHelper = SObjectHelper.get(sObjectAPINameToTest);
            Integer testSObjHelperRtSize = testSObjHelper.mapRecordTypeNameToId.keySet().size();
            List<RecordType> querySObjRts = [
                SELECT Id, Name
                FROM RecordType
                WHERE SObjectType = :sObjectAPINameToTest
            ];

            System.assertEquals(querySObjRts.size(), testSObjHelper.mapRecordTypeNameToId.keySet().size());
            for (RecordType rt : querySObjRts) {
                System.assert(testSObjHelper.mapRecordTypeNameToId.keySet().contains(rt.Name));
                System.assertEquals(rt.Id, testSObjHelper.mapRecordTypeNameToId.get(rt.Name));
            }

        } else {
            //  Can't really be tested if no objects have Record Types set up
        }
    }


    /**
     * Tests to see that the select all string generated by the helper contains all the same fields
     * as manually queried from the org
     */
    @isTest
    static void testSelectAllString() {
        String sObjectAPINameToTest = null;
        Set<String> sObjectsWithRts = getSObjectsWithRecordTypes();
        for (String sObj : PREFERRED_SOBJECTS) {
            if (sObjectsWithRts.contains(sObj)) {
                sObjectAPINameToTest = sObj;
                break;
            }
        }
        System.assertNotEquals(null, sObjectAPINameToTest, 'No SObject to test.'); //  Make sure there is an object to test

        SObjectHelper sObjToTest = SObjectHelper.get(sObjectAPINameToTest);
        System.assertNotEquals(null, sObjToTest);   //  Make sure the new object is not a null value

        List<String> sObjFieldList = new List<String>();
        sObjFieldList = sObjToTest.selectAllString.split(', ');
        SObject sObjInstance = Schema.getGlobalDescribe().get(sObjectAPINameToTest).newSObject() ;

        Integer countSuccess = 0;
        Integer countFail = 0;
        for (String field : sObjFieldList) {
            try {
                sObjInstance.get(field);
                countSuccess += 1;
            } catch (Exception e) {
                countFail += 1;
            }
        }

        System.assertEquals(0, countFail);  //  Make sure there are no field mismatches
        System.assertEquals(sObjFieldList.size(), countSuccess);    //  Make sure the success count is the same as the list size

        //  Make a query to check it does not fail
        List<SObject> queryResults = null;
        String queryTestString = '';
        Boolean querySuccess = null;
        String queryErrorString = '';
        try {
            queryTestString += 'SELECT ' + sObjToTest.selectAllString + ' ';
            queryTestString += 'FROM ' + sObjectAPINameToTest + ' ';
            queryResults = Database.query(queryTestString);
            querySuccess = true;
        } catch (Exception e) {
            querySuccess = false;
            queryErrorString = e.getMessage();
        }
        System.assert(querySuccess, 'The query was unsuccessful. ' + queryErrorString); //  Test the query worked correctly with all fields
    }


    /**
     * Tests the select all string functions for other lookups on the object
     * Using Contract as the SObject as there are fields that need to be filtered out
     * and are stored in the map: evilObjectFieldNames
     */
    @isTest
    static void testSelectAllStringRelatedObject() {
        String sObjectNameToTest = 'Contract';
        SObjectHelper contractHelper = SObjectHelper.get(sObjectNameToTest);

        //  We know that by default the address fields that are queried using Schema.SObjectType.getDescribe()
        //  have both billing and shipping fields, however you may not be able to query the shipping fields
        System.assertNotEquals(null, contractHelper.selectAllString);
        System.assert(contractHelper.selectAllString.containsIgnoreCase('billingaddress'));
        System.assert(!contractHelper.selectAllString.containsIgnoreCase('ShippingAddress'));

        //  Next we want to make sure that we can get the fields for a lookup on Contract
        //  Account should be a default lookup field on Contract, but we need to use AccountId
        //  for the field name
        String accountLookupQueryString = contractHelper.createQueryStringForRelatedSObject('AccountId');
        System.assertNotEquals(null, accountLookupQueryString);

        Set<String> setObjects = new Set<String>{'AccountId', 'OwnerId'};
        List<String> listObjects = new List<String>{'AccountId', 'OwnerId'};
        System.assertEquals(contractHelper.createQueryStringForRelatedSObjects(setObjects), contractHelper.createQueryStringForRelatedSObjects(listObjects));
    }


    /**
     * Tests that the required fields set is populated, all all fields in the set are
     * also listed as keys in SObjectHelper.mapDevNameToType. Using the Account SObject
     * at a minimum the following fields are required: Id, Name, OwnerId, CreatedById,
     * CreatedDate, LastModifiedById, LastModifiedDate
     */
    @isTest
    static void testRequiredFieldsSet() {
        SObjectHelper accountHelper = SObjectHelper.get('Account');

        Integer expectedRequiredFields = accountHelper.fieldsRequired.size();
        Integer countedExistingFields = 0;

        for (String field : accountHelper.mapDevNameToType.keySet()) {
            if (accountHelper.fieldsRequired.contains(field)) {
                countedExistingFields += 1 ;
            }
        }

        System.assertNotEquals(null, accountHelper.fieldsRequired);
        System.assertNotEquals(0, expectedRequiredFields);
        System.assert(accountHelper.fieldsRequired.contains('Id'));
        System.assert(accountHelper.fieldsRequired.contains('Name'));
        System.assertEquals(expectedRequiredFields, countedExistingFields);
    }


    /**
     * Tests the query string for lookup fields on a standard SObject
     */
    @isTest
    static void testLookupQueryStringPopulate() {
        //  Setup
        SObjectHelper contractHelper = SObjectHelper.get('Contract');
        String sObjectNameFail = 'Account';
        String sObjectNamePass = 'AccountId';

        //  Test
        String returnStringFail = contractHelper.createQueryStringForRelatedSObject(sObjectNameFail);
        String returnStringPass = contractHelper.createQueryStringForRelatedSObject(sObjectnamePass);

        //  Assert
        System.assertEquals('', returnStringFail);
        System.assert(returnStringPass.length() > 0);
        System.assert(returnStringPass.contains(sObjectNamePass.removeEndIgnoreCase('Id')));
    }


    /**
     * This is a hard one to successfully test as it depends on whether or not the object
     * in the org has any fields that are marked as unique
     */
    @isTest
    static void testUniqueFieldsSet() {
        SObjectHelper accountHelper = SObjectHelper.get('Account');

        Integer expectedUniqueFields = accountHelper.fieldsUnique.size();
        Integer countedExistingFields = 0;

        for (String field : accountHelper.mapDevNameToType.keySet()) {
            if (accountHelper.fieldsUnique.contains(field)) {
                countedExistingFields += 1 ;
            }
        }

        System.assertNotEquals(null, accountHelper.fieldsUnique);
        System.assertEquals(expectedUniqueFields, countedExistingFields);
    }


    /**
     * Tests to make sure the correct record type Id fields are being populated
     */
    @isTest
    static void testGetDefaultRecordTypeId() {
        SObjectHelper accountHelper = SObjectHelper.get('Account');
        SObjectHelper contactHelper = SObjectHelper.get('Contact');

        System.assertNotEquals(null, accountHelper.getDefaultRecordTypeId());
        System.assertNotEquals(null, accountHelper.recordTypeIdDefault);
        System.assertNotEquals(null, accountHelper.recordTypeIdMaster);

        System.assertNotEquals(null, contactHelper.getDefaultRecordTypeId());
        System.assertNotEquals(null, contactHelper.recordTypeIdDefault);
        System.assertNotEquals(null, contactHelper.recordTypeIdMaster);
    }


    /*  ****************************************  */
    /*             Private Functions              */
    /*  ****************************************  */

    /**
     * Queries and returns a Set of Strings, which are SObject API Names
     */
    private static Set<String> getSObjectsWithRecordTypes() {
        List<AggregateResult> rtAggRes = [
            SELECT SObjectType
            FROM RecordType
            GROUP BY SObjectType
        ];
        Set<String> sObjectsWithRts = new Set<String>();
        for (AggregateResult ar : rtAggRes) {
            sObjectsWithRts.add(String.valueOf(ar.get('SObjectType')));
        }
        return sObjectsWithRts;
    }
}