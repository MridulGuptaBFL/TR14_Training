public with sharing class PreferenceColor {
    @AuraEnabled(cacheable=true) //cacheable for better performance
    public static String getUserColor() {
        Preference__c pref = Preference__c.getInstance(UserInfo.getUserId());
        if(pref != null && pref.Colour__c != null) return pref.Colour__c;
        pref = Preference__c.getInstance(UserInfo.getProfileId());
        if(pref != null && pref.Colour__c != null) return pref.Colour__c;
        pref = Preference__c.getOrgDefaults();
        if(pref != null && pref.Colour__c != null) return pref.Colour__c;
        return 'white'; // fallback
    }
}