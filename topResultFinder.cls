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
    public topResultFinder(ApexPages.StandardController stdController) {}

    @RemoteAction
    global static Map<String, Map<String, String>> getTopResults(String object_type, String record_id, Map<string,string>filters) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> top_list = new Map<String, Map<String, String>>(); 
        object_type.toLowerCase();
        if (object_type.length() > 0
            && (object_type == 'lead' || object_type == 'account')) {
            if (filters.size() > 0) {
                if (object_type == 'lead') {
                    result = filterResultsLead(record_id, filters);
                } else {
                    //String record_id = '001f4000005YxYk';
                    result = filterResultsAccount (record_id, filters);
                    top_list = result;
                }
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
        Map<String, String> error = new Map<String, String>();
        System.debug('filters'+ filters);

        if (filters.containsKey('industry') &&
            String.isNotEmpty(filters.get('industry')) &&
            String.isNotBlank(filters.get('industry'))
        ) {
            // Getting revenue value
            Integer parent_revenue = 0;
            if (filters.containsKey('AnnualRevenue')) {
                parent_revenue =  Integer.valueof(filters.get('AnnualRevenue'));
            }

            //Getting address data
            List<SObject> account_address = getAddress(account_id);

            //Getting geolocation values
            Decimal lat         = (Decimal)account_address[0].get('BillingLatitude');
            Decimal lng         = (Decimal)account_address[0].get('BillingLongitude');
            Location from_loc   = Location.newInstance(lat ,lng);

            // Formatting distance calculation
            String object_type  = getObjectType((ID)account_id);
            String distance_val = getDistanceString(object_type, lat, lng);
            String soql_query   = getMainSOQLString(object_type);

            soql_query += getWhereForSOQL(object_type, distance_val, filters);
            soql_query += ' AND Id NOT IN (\''+account_id+'\')';
            soql_query += ' ORDER BY '+distance_val+ ' ASC LIMIT 3';
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

                record_to_send.put('id', record.id);
                record_to_send.put('Name', record.name);
                record_to_send.put('dist', dist);
                record_to_send.put('revenue_diff', revenue_diff);

                //put the calculated values to result
                result.put(String.valueof(order), record_to_send);
                order++;
            }
        } else {
            error.put('success', '0');
            error.put('message', 'Industry not selected.');
            result.put('Success', error);
        }
        System.debug('result '+ result);
        return result;
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
            sql_string = 'SELECT Id, Name, BillingAddress, AnnualRevenue FROM Account WHERE ';
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
    //protected static upsert_records(Map<>) {
    //
    //}
}