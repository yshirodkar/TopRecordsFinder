/** 
 * This file is get called from top_results.component.
*/
global with sharing class topResultFinder {
    /**
     * This function is used to get the top results of records which are pretty close to the current displayed record
     *
     * @param String object_type What object type results are expected (Right now we just support Lead & Account)
     * @param String industry_type This value decide what industry type we are looking for
     * @param Map<String, Map<String,String>> filters What filters we are going to use and what is it's priority and value
     *                                        e.g. ('Revenue'=> ('Priority' => '1', 'Value' => '200'))
     *
     * 
     * @return Map<String, String> result Top results and their orders.
     */
    @RemoteAction
    global static Map<String, Map<String, String>> getTopResults(Id object_id, Map<string,string>filters) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> top_list = new Map<String, Map<String, String>>();
        String object_id_string = (String)object_id;

        if (object_type.length() > 0
            && (object_id_string.startsWith('00Q'))) {
            if (filters.size() > 0) {
                result = filterReults(object_id, filters);
            } else {
                result = distanceFilter(industry_filter_records);
            }
        } else if (object_type.length() > 0
            && (object_id_string.startsWith('001'))) {
            if (filters.size() > 0) {
                result = filterReults(object_id, filters);
            } else {
                result = distanceFilter(industry_filter_records);
            }
        }
        return top_list;
    }

    /**
     * This function is used to get the top results from lead/Account based on what id passed
     * It has default distance to 500mil if filter doesn't pass any value.
     * 
     * @param Id object_id Object Id which is used to get the current data information
     * @param Map<String, String> filters This variable should pass all the filter data
     *                          (e.g {'industry' = 'Agriculture', 'distance' = '500', 'AnnualRevenue'= '100000'}).
     *
     * @return Map<String, Map<String, String>> result Result will be top records with their filtered values and order.
     *                          (e.g. {1={Name=Bertha Boxer, dist=0.0, id=00Qf4000002H52CEAS, revenue_diff=900650000}})
    */
    public static Map<String, Map<String,String>> filterReults (object_id, Map<string,string>filters) {
        
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> error = new Map<String, String>();
        System.debug('filters: '+ filters);
        //Id object_id =  '00Qf4000002H52C';

        Integer revenue =  Integer.valueof(filters.get('AnnualRevenue'));
        String soql_query = 'SELECT Latitude, Longitude FROM Lead WHERE Id = \''+object_id+'\' LIMIT 1';
        List<SObject> lead_address_stats = database.query(soql_query);
        
        Decimal lat = (Decimal)lead_address_stats[0].get('Latitude');
        Decimal lng = (Decimal)lead_address_stats[0].get('Longitude');
        String distance_val = 'DISTANCE(Address, GEOLOCATION(' + lat + ', ' + lng + ' ), \'mi\')';
        soql_query = 'SELECT Id, Name, Address, AnnualRevenue FROM LEAD WHERE ';
        if (String.isNotEmpty(filters.get('industry')) && String.isNotBlank(filters.get('industry'))) {
            soql_query += ' industry = \''+ String.valueOf(filters.get('industry')) +'\' ';
        } else {
            error.put('success', '0');
            error.put('message', 'Industry not selected.');
            result.put('Success', error);
        }
        soql_query += 'AND '+ distance_val;
        if (String.isNotEmpty(filters.get('distance')) && String.isNotBlank(filters.get('distance'))) {
            soql_query += ' < '+filters.get('distance');
        } else {
            soql_query += '< 500';
        }
        soql_query += ' ORDER BY '+distance_val+ ' ASC';
        
        List<Lead> lead_address_stats_result = database.query(soql_query);
        System.debug('Result from query '+lead_address_stats_result);
        Location from_loc = Location.newInstance(lat ,lng);
        Integer order = 1;
        for (LEAD record: lead_address_stats_result) {
            Location loc = record.Address;
            Double new_lat = loc.latitude;
            Double new_lon = loc.longitude;
            Location to_loc = Location.newInstance(new_lat, new_lon);
            String dist = String.valueof(from_loc.getDistance(to_loc, 'mi'));
            String revenue_diff = String.valueof(Math.abs(record.AnnualRevenue - revenue));
            Map<String, String> record_send = new Map<String, String>();
            record_send.put('id', record.id);
            record_send.put('Name', record.name);
            record_send.put('dist', dist);
            record_send.put('revenue_diff', revenue_diff);
            result.put(String.valueof(order), record_send);
            order++;
        }

        return result;
    }
    
    public static Map<String, Map<String,String>> distanceFilter (sObject industry_filter_records) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        
        
        return result;
    }
}