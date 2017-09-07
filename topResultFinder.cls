/** 
 * This file is get called from top_results.component.
*/
global with sharing class topResultFinder {

     static final Integer LIMIT_CONST = 3;

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
    public topResultFinder(ApexPages.StandardController stdController) {}

    @RemoteAction
    global static Map<String, Map<String, String>> getTopResults(String object_type, String record_id, Map<string,string>filters) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> top_list = new Map<String, Map<String, String>>(); 
        Map<string, string> test_filters = new Map<String, String>(); //for testing
        object_type.toLowerCase();
        if (object_type.length() > 0
            && (object_type == 'lead' || object_type == 'account')) {
            if (filters.size() > 0) {
                    //record_id = '001f4000005YxYk';
                    test_filters.putAll(filters); //for testing
                    //test_filters.put('order_by', 'revenue');
                    result = filterResultsAccount (record_id, test_filters);
                    top_list = result;
            }
        }
        //if (!top_list.isEmpty()) {
        //    upsert_records(top_list);
        //}
        return top_list;
    }

    public static Map<String, Map<String,String>> filterResultsLead (String lead_id, Map<string,string>filters) {

        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();

        return result;
    }

    public static Map<String, Map<String,String>> filterResultsAccount (String account_id, Map<string,string>filters) {
        
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> sorted_results = new Map<String, Map<String, String>>();
        Map<String, String> error = new Map<String, String>();
        System.debug('filters'+ filters);

        if (filters.containsKey('industry') &&
            String.isNotEmpty(filters.get('industry')) &&
            String.isNotBlank(filters.get('industry'))
        ) {
            // Getting revenue value
            Integer parent_revenue = 0;
            if (filters.containsKey('revenue')) {
                parent_revenue =  Integer.valueof(filters.get('revenue'));
            }
            Integer boxes_per_day = 0;
            if (filters.containsKey('boxes')) {
                boxes_per_day = Integer.valueof(filters.get('boxes'));
            }

            //Getting address data
            List<SObject> account_address = getAddress(account_id);
            
            String object_type_check  = getObjectType((ID)account_id);
            //Getting geolocation values
            Decimal lat, lng;
            if (object_type_check == 'account') {
                lat         = (Decimal)account_address[0].get('BillingLatitude');
                lng         = (Decimal)account_address[0].get('BillingLongitude');   
            } else if (object_type_check == 'lead') {
                lat         = (Decimal)account_address[0].get('Latitude');
                lng         = (Decimal)account_address[0].get('Longitude');   
            }
            Location from_loc   = Location.newInstance(lat ,lng);

            // Formatting distance calculation
            //String object_type  = getObjectType((ID)account_id);
            String object_type  = 'account';
            String distance_val = getDistanceString(object_type, lat, lng);
            String soql_query   = getMainSOQLString(object_type);

            soql_query += getWhereForSOQL(object_type, distance_val, filters);
            //soql_query += ' AND Id NOT IN (\''+account_id+'\')';
            if ((filters.containsKey('order_by') && filters.get('order_by') == 'distance') ||
                !filters.containsKey('order_by')) {
                soql_query += ' ORDER BY '+distance_val+ ' ASC LIMIT '+LIMIT_CONST;
            }

            System.debug('query'+ soql_query);
            List<Account> account_results = database.query(soql_query);

            // Result calculation
            Integer order = 1;
            for (Account record: account_results) {
                Map<String, String> record_to_send = new Map<String, String>();

                //distance calulcation
                Location new_loc = record.BillingAddress;
                String dist = getDistanceFromParentRecord(from_loc, new_loc);

                //revenue calculation
                String revenue_diff = String.valueof(parent_revenue);
                if (record.AnnualRevenue > 0) {
                    revenue_diff = String.valueof(Math.abs(record.AnnualRevenue - parent_revenue));
                }
                String boxes_per_day_diff = String.valueof(boxes_per_day);
                if (record.Boxes_Per_Day__c > 0) {
                    boxes_per_day_diff = String.valueof(Math.abs(record.Boxes_Per_Day__c - boxes_per_day));   
                }

                record_to_send.put('id', record.id);
                record_to_send.put('Name', record.name);
                record_to_send.put('dist', dist);
                record_to_send.put('revenue', revenue_diff);
                record_to_send.put('boxes', boxes_per_day_diff);

                //put the calculated values to result
                result.put(String.valueof(order), record_to_send);
                order++;
            }

            if (filters.containsKey('order_by') && filters.get('order_by') != 'distance') {
                sorted_results = getSortedRecords(result, filters.get('order_by'));
            } else {
                sorted_results = result;
            }
            //System.debug('sorter_ '+sorted_results);// for testing
        } else {
            error.put('success', '0');
            error.put('message', 'Industry not selected.');
            result.put('Success', error);
        }
        System.debug('result '+ result);
        return sorted_results;
    }

    /**
     * This function is used to get Address Latitude and Longitude
     *
     * @param String record_id Record Id
     *
     * @return List<SObject> address_lat_lng Address Latitude and Longitude values.
     */
    public static List<SObject> getAddress (String record_id) {
        String object_type = getObjectType((ID)record_id);
        String soql_query = '';
        if (object_type == 'account') {
            soql_query = 'SELECT BillingLatitude, BillingLongitude'+
                ' FROM Account WHERE Id = \''+record_id+'\' LIMIT 1';
        } else if (object_type == 'lead') {
            soql_query = 'SELECT Latitude, Longitude'+
                ' FROM Lead WHERE Id = \''+record_id+'\' LIMIT 1';
        }

        List<SObject> address_lat_lng = database.query(soql_query);
        return address_lat_lng;
    }

    /**
     * This function is used to get Object Type
     *
     * @param Id record_id Record Id
     *
     * @return String object_type Object Type.
     */
    public static String getObjectType (Id record_id) {
        String object_type = String.valueOf(record_id.getsobjecttype()).toLowerCase();
        return object_type;
    }

    /**
     * This function is used to get distance calculation string
     *
     * @param String object_type Object Type
     * @param Decimal Lat Latitude
     * @param Decimal Lng Longitude
     *
     * @return String distance_string Distance calculation string.
     */
    public static String getDistanceString (String object_type, Decimal lat, Decimal lng) {
        String address_key = 'Address';
        if (object_type == 'account') {
            address_key = 'BillingAddress';
        }
        String distance_string = 'DISTANCE('+address_key+', GEOLOCATION(' + lat + ', ' + lng + ' ), \'mi\')';
        return distance_string;
    }

    /**
     * This function is used to get Select statement string
     *
     * @param String object_type Object Type
     *
     * @return String sql_string Main SOQL query string.
     */
    public static String getMainSOQLString (String object_type) {
        String sql_string = '';
        if (object_type == 'account') {
            sql_string = 'SELECT Id, Name, BillingAddress, AnnualRevenue, Boxes_Per_Day__c FROM Account WHERE ';
        } else if (object_type == 'lead') {
            sql_string = 'SELECT Id, Name, Address, AnnualRevenue FROM Lead WHERE ';
        }
        return sql_string;
    }

    /**
     * This function is used to get where condition for SOQL query
     *
     * @param String object_type Object Type
     * @param String distance_val Distance calcuation string
     * @param Map<String, String> filters Filter key and value (e.g. {'industry':'paper'})
     *
     * @return String soql_query Where condition string.
     */
    public static String getWhereForSOQL (String object_type, String distance_val, Map<String, String>filters) {
        String soql_query = '';
        if (object_type == 'account') {
            soql_query += ' industry = \''+ String.valueOf(filters.get('industry')) +'\' ';
            soql_query += 'AND '+ distance_val;
            if (String.isNotEmpty(filters.get('distance')) && String.isNotBlank(filters.get('distance'))) {
                soql_query += ' < '+filters.get('distance');
            } else {
                soql_query += '< 500';
            }
        } else if (object_type == 'lead') {

        }

        return soql_query;
    }

    /**
     * This function is used to calculate the distance.
     *
     * @param Location from_loc From location details
     * @param Location new_loc New location details
     *
     * @return String dist Distance value.
     */
    public static String getDistanceFromParentRecord (Location from_loc, Location new_loc) {
        Double new_lat = new_loc.latitude;
        Double new_lon = new_loc.longitude;
        Location to_loc = Location.newInstance(new_lat, new_lon);

        String dist = String.valueof(from_loc.getDistance(to_loc, 'mi'));
        return dist;
    }

    /**
     * This function is used to sort the records.
     *
     * @param Map<String, Map<String, String>> records Records which needs to sort
     * @param String order_by Sorting key
     *
     * @return Map<String, Map<String, String>> result Sorted result.
     */    
    public static Map<String, Map<String, String>> getSortedRecords (Map<String, Map<String, String>> records, String order_by) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> order_by_map = new Map<String, String>();
        List<String> field_value_list = new List<String>();
        for(String current_order: records.keySet()) {
            Map<String, String> record = new Map<String, String>(records.get(current_order));
            //System.debug('val '+ records.get(keys));
            order_by_map.put(record.get(order_by), current_order);
            field_value_list.add(record.get(order_by));
        }

        field_value_list.sort();
        //field_value_list.addAll(Integer.valueOf(test_sorting_map.get('revenue_diff')));
        //System.debug('list looks '+ field_value_list);
        Integer list_count = 1;
        for (String value_key: field_value_list) {
            if (list_count > LIMIT_CONST) {
                break;
            }
            System.debug(' sorted order '+order_by_map.get(value_key));
            result.put(string.valueOf(list_count), records.get(order_by_map.get(value_key)));
            //order_by_map.remove(value_key);
            list_count++;
        }
        return result;
    }

    //protected static upsert_records(Map<>) {
    //
    //}
}