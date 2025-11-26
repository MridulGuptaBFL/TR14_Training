/**
 * @author Your name
 * @email your email
 *  @created date 10-10-2022
 * @desc Test class for QueryBuilderController Apex class. 
 //      Validates all controller methods with flexible assertions. 

 */

@IsTest 
 private class QueryBuilderControllerTest { 

  
	/**
	 * setupTestData
     * @description Creates test data for validating SOQL execution.
     * @author Your Name
     * @param  recordId             :   lens configurator Id 
     * @param  applicableBrand      :   brand
     * @return Return Value
     */
     private static void setupTestData() { 
         List<Account> accs = new List<Account>(); 
         for (Integer i = 0; i < 5; i++) { 
             accs.add(new Account(Name = 'Test Account ' + i)); 
         } 
         insert accs; 
     } 

    // ------------------------------------------------------------------------ 
     // TEST 1: getAllSObjects() 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testGetAllSObjects() { 
         Test.startTest(); 
         List<String> objs = QueryBuilderController.getAllSObjects(); 
         Test.stopTest(); 

        System.assert(!objs.isEmpty(), 'SObject list should not be empty'); 
         System.assert(objs.contains('Account'), 'Account should exist in SObject list'); 
     } 

  

    // ------------------------------------------------------------------------ 
     // TEST 2: getFields() with valid object 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testGetFields_ValidObject() { 
         Test.startTest(); 
         List<String> fields = QueryBuilderController.getFields('Account'); 
         Test.stopTest(); 

        System.assert(fields.size() > 0, 'Field list should not be empty'); 
         System.assert(fields.contains('Name'), 'Field list should include Name'); 
     } 

  

    // ------------------------------------------------------------------------ 
     // TEST 3: getFields() with invalid object 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testGetFields_InvalidObject() { 
         Test.startTest(); 
         List<String> fields = QueryBuilderController.getFields('InvalidObject__c'); 
         Test.stopTest(); 

        System.assertEquals(0, fields.size(), 'Invalid object should return empty list'); 
     } 

  
    // ------------------------------------------------------------------------ 
     // TEST 4: executeSoql() with valid query 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testExecuteSoql_Valid() { 
         setupTestData(); 
         String query = 'SELECT Id, Name FROM Account LIMIT 5'; 

        Test.startTest(); 
         QueryBuilderController.QueryResult qr = QueryBuilderController.executeSoql(query); 
         Test.stopTest(); 

        System.assert(!qr.columns.isEmpty(), 'Columns should not be empty'); 
         System.assert(!qr.rows.isEmpty(), 'Rows should not be empty'); 
         System.assert(qr.columns.contains('Name'), 'Column list should include Name'); 
     } 

  

    // ------------------------------------------------------------------------ 
     // TEST 5: executeSoql() with empty query 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testExecuteSoql_Empty() { 
         Test.startTest(); 
         try { 
             QueryBuilderController.executeSoql(''); 
             System.assert(false, 'Expected exception for empty query'); 
         } catch (Exception ex) { 
             String msg = ex.getMessage().toLowerCase(); 
             System.debug(' Empty Query Exception: ' + msg); 

  

            Boolean expected =  
                 msg.contains('soql query is empty') || 
                 msg.contains('empty') || 
                 msg.contains('script-thrown exception'); 

  

            System.assert(expected, 'Unexpected message for empty SOQL: ' + msg); 
         } 
         Test.stopTest(); 
     } 

     // ------------------------------------------------------------------------ 
     // TEST 6: executeSoql() with invalid query 
     // ------------------------------------------------------------------------ 
     @IsTest 
     static void testExecuteSoql_Invalid() { 
         Test.startTest(); 
         try { 
             QueryBuilderController.executeSoql('SELECT NonexistentField FROM Account'); 
             System.assert(false, 'Expected invalid SOQL exception'); 
         } catch (Exception ex) { 
             String msg = ex.getMessage().toLowerCase(); 
             System.debug(' Invalid SOQL Exception: ' + msg);
			 Boolean expected = 
                 msg.contains('invalid soql') || 
                 msg.contains('no such column') || 
                 msg.contains('unexpected token') || 
                 msg.contains('invalid field') || 
                 msg.contains('script-thrown exception');
			 System.assert(expected, 'Unexpected message for invalid SOQL: ' + msg); 
         } 
         Test.stopTest(); 
     } 
 }