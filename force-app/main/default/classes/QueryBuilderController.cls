/**
 * @author Your name
 * @email your email
 *  @created date 24-10-2025
 * @desc 			//Backend Apex controller for Query Builder LWC. 
					//Fetches all objects 
					//Fetches accessible fields for selected object 
					//Executes dynamic SOQL and returns rows + columns 
 */
 
 
/**
	Method Level Comment
     * @description 
     * @author Your Name
     * @param  recordId             :   lens configurator Id 
     * @param  applicableBrand      :   brand
     * @return Return Value
     */



 
public with sharing class QueryBuilderController { 
 
    // Fetches all SObjects in the org (standard + custom) 
    // Excludes Custom Settings and deprecated/hidden objects 

    @AuraEnabled(cacheable=true) 
    public static List<String> getAllSObjects() { 
        List<String> objects = new List<String>(); 
 

        // Loop through all global describe objects 
        for (Schema.SObjectType t : Schema.getGlobalDescribe().Values()) { 
            Schema.DescribeSObjectResult r = t.getDescribe(); 
 

            // Only include non-Custom Setting and visible objects 
            if (!r.isCustomSetting() && !r.isDeprecatedAndHidden()) { 
                objects.add(r.getName()); 
            } 
        } 
 
        // Sort alphabetically 
        objects.sort(); 
        return objects;    // List<String> of SObject API names sorted alphabetically 
    } 


    // Returns all accessible fields for a given object 
    @AuraEnabled(cacheable=true) 
    public static List<String> getFields(String objectName) { // objectName - API name of the selected object 
        List<String> fields = new List<String>(); 
        if (String.isBlank(objectName)) return fields; 
 

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName); 

        if (objType == null) return fields; 

        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap(); 
 
        for (String f : fieldMap.keySet()) { 
            Schema.DescribeFieldResult fd = fieldMap.get(f).getDescribe(); 
            // Only include accessible fields (removes isQueryable check) 
            if (fd.isAccessible()) { 
                fields.add(fd.getName()); 
            } 
        } 
        fields.sort(); 
        return fields; //List<String> of field API names sorted alphabetically 
    }


	
    //Wrapper for returning SOQL results to LWC 
    //Contains columns and rows 
    public class QueryResult { 
        @AuraEnabled public List<String> columns;             // Column names 
        @AuraEnabled public List<Map<String, Object>> rows;  // Row data as list of maps 
 
        public QueryResult() { 
            columns = new List<String>(); 
            rows = new List<Map<String, Object>>(); 
        } 
   } 

 
    //Executes a dynamic SOQL query and returns QueryResult 
    @AuraEnabled 
    public static QueryResult executeSoql(String soql) { 
        QueryResult qr = new QueryResult(); 

        try { 
            // Validate query 
            if (String.isBlank(soql)) 
                throw new AuraHandledException('SOQL query is empty'); 
            

            // Execute SOQL 
            List<SObject> results = Database.query(soql); 

            // Return empty result if no records 
            if (results.isEmpty()) return qr; 
 
            // Collect all populated column names 
            Set<String> colSet = new Set<String>(); 
            for (SObject r : results) { 
                colSet.addAll(r.getPopulatedFieldsAsMap().keySet()); 
            } 

            // Sort and store column names 
            qr.columns = new List<String>(colSet); 
            qr.columns.sort(); 

            // Store row data 
            for (SObject r : results)
                qr.rows.add(r.getPopulatedFieldsAsMap()); 
            
 
            return qr; 
 
        } catch (Exception ex) { 
            throw new AuraHandledException('Invalid SOQL: ' + ex.getMessage()); 
        } 
    } 
}