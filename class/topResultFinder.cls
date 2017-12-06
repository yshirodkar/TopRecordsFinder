/** 
 * This file is get called from top_results.component.
*/
global with sharing class topResultFinder {

    /**
     * Static integer value
     **/
    static Integer LIMIT_CONST = 3;

    /**
     * Getter Setter
     **/
    global String currentRecordId {get;set;}


    /**
     * Constructor
     **/
    public topResultFinder() {}
    /**
     * Constructor
     **/
    public topResultFinder(ApexPages.StandardController stdController) {
        currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
        setLimitConst();
    }

    /**
     * This function set the custom setting for record limit.
     **/
    private static void setLimitConst () {
        topResultSettings__c trs = topResultSettings__c.getValues(userinfo.getProfileId());
        try {
            Integer limit_size = (Integer)trs.record_display_limit__c;
            LIMIT_CONST = limit_size;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to LIMIT = 3.');
            LIMIT_CONST = 3;
        }
    }

    /**
     * This function is used to get the top results of records which are pretty close to the current displayed record
     *
     * @param String object_type Object type.
     * @param String record_id Record id
     * @param Map<String, String> filters Filters key and value
     *        e.g. ('revenue' : '200', 'industry' : 'paper')
     * @return Map<String, String> result Top results and their orders.
     */
    @RemoteAction
    global static Map<String, Map<String, String>> getTopResults(String object_type,
        String record_id,
        Map<string,string>filters
    ) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> top_list = new Map<String, Map<String, String>>(); 
        String cat = filters.get('order_by');
        Boolean upsert_success;
        setLimitConst();
        object_type.toLowerCase();
        if (object_type.length() > 0
            && (object_type == 'lead' || object_type == 'account')) {
            if (filters.size() > 0) {
                    result = filterResultsAccount (record_id, filters);
                    top_list = result;
            }
        }
        // Upserting the top records.
        if (!top_list.isEmpty()) {
            upsert_success = upsert_records(top_list, record_id, cat);
            if (upsert_success) {
                System.debug('Upsert the records successfuly.');
            }
        }
        return top_list;
    }

    /**
     * This function is used to filter the Account
     *
     * @param String account_id Account Id.
     * @param Map<String, String> filters Filters key and value
     *        e.g. ('revenue' : '200', 'industry' : 'paper')
     * @return Map<String, Map<String,String>> sorted_results
     */
    private static Map<String, Map<String,String>> filterResultsAccount (String account_id, Map<string,string>filters) {
        
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
            if (filters.containsKey('revenue') && (filters.get('revenue') != '' && filters.get('revenue') != null)) {
                List<String> parts = filters.get('revenue').split('.', 2);
                System.debug('list '+ parts[1]);
                String rev = parts[parts.size()-1];
                if (rev.length() > 0)
                parent_revenue =  Integer.valueof(rev);
            }
            Integer boxes_per_day = 0;
            if (filters.containsKey('boxes') && (filters.get('boxes') != '' && filters.get('boxes') != null)) {
                boxes_per_day = Integer.valueof(filters.get('boxes'));
            }

            Integer sic_code = 0;
            if (filters.containsKey('sic') && (filters.get('sic') != '' && filters.get('sic') != null)) {
                sic_code = Integer.valueof(filters.get('sic'));
            }

            Integer products = 0;
            if (filters.containsKey('products') && (filters.get('products') != '' && filters.get('products') != null)) {
                products = Integer.valueof(filters.get('products'));
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
            String object_type  = 'account';
            String distance_val = getDistanceString(object_type, lat, lng);
            String soql_query   = getMainSOQLString(object_type);

            soql_query += getWhereForSOQL(object_type, distance_val, filters);
            //if ((filters.containsKey('order_by') &&
            //    (filters.get('order_by') == 'distance' || filters.get('order_by') == 'industry')) ||
            //    !filters.containsKey('order_by')
            //) {
            //    soql_query += ' ORDER BY '+distance_val+ ' ASC LIMIT '+LIMIT_CONST;
            //}

            System.debug('query'+ soql_query);
            List<Account> account_results = database.query(soql_query);
            String industry_name = filters.get('industry');
            // Result calculation
            Integer order = 1;
            for (Account record: account_results) {
                Map<String, String> record_to_send = new Map<String, String>();
                //distance calulcation
                try {
                    Location new_loc = record.BillingAddress;
                    String dist = getDistanceFromParentRecord(from_loc, new_loc);
    
                    //revenue calculation
                    String revenue_diff = String.valueof(parent_revenue);
                    if (record.Actual_Revenue_Commitment__c > 0) {
                        revenue_diff = String.valueof(Math.abs(record.Actual_Revenue_Commitment__c - parent_revenue));
                    }
                    String boxes_per_day_diff = String.valueof(boxes_per_day);
                    if (record.Boxes_Per_Day__c > 0) {
                        boxes_per_day_diff = String.valueof(Math.abs(record.Boxes_Per_Day__c - boxes_per_day));   
                    }
                    String sic_diff = String.valueof(sic_code);
                    if (record.sic != '' && record.sic != null) {
                        sic_diff = String.valueof(Math.abs(Integer.valueof(record.sic) - boxes_per_day));
                    }
                    String product_num_diff = String.valueof(products);
                    if (record.Total_Box_SKUs__c >0) {
                        product_num_diff = String.valueof(Math.abs(record.Total_Box_SKUs__c - products));
                    }
                    record_to_send.put('id', record.id);
                    record_to_send.put('name', record.name);
                    record_to_send.put('industry', industry_name);
                    record_to_send.put('dist', dist);
                    record_to_send.put('city', record.BillingCity);
                    record_to_send.put('state', record.BillingState);
                    record_to_send.put('revenue', revenue_diff);
                    record_to_send.put('revenue_actual', String.valueof(record.Actual_Revenue_Commitment__c));
                    record_to_send.put('boxes', boxes_per_day_diff);
                    record_to_send.put('boxes_actual', String.valueof(record.Boxes_Per_Day__c));
                    record_to_send.put('sic', sic_diff);
                    record_to_send.put('sic_actual', String.valueof(record.sic));
                    record_to_send.put('product', product_num_diff);
                    record_to_send.put('product_actual', String.valueof(record.Total_Box_SKUs__c));

                    //put the calculated values to result
                    result.put(String.valueof(order), record_to_send);
                    order++;
                } catch (Exception e) {
                    System.debug('There is exception for getting record');
                }
            }

            if (result.containsKey('1')) {
                sorted_results = getRecordsFromAlgo(result);
                sorted_results = addAssets(sorted_results);
            }
        } else {
            error.put('success', '0');
            error.put('message', 'Industry not selected.');
            result.put('Success', error);
        }

        System.debug('sorted results'+ sorted_results);

        return sorted_results;
    }

    /**
     * This function is to get Score from recordScore.cls
     *
     * @param Map<String, Map<String, String>> records Records.
     * @return Map<String, Map<String, String>> result Return result map with score values.
     */
    private static Map<String, Map<String, String>> getRecordsFromAlgo(Map<String, Map<String, String>> records) {
        Map<String, Map<String, String>> id_score_map = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> tmp_map = new Map<String, String>();
        List<Integer> score_list = new List<Integer>();
        id_score_map = recordScore.getRecordScore(records);

        Integer rank = 0;
        for (String record_rank : id_score_map.keySet()) {
            Map<String, String> tmp_record = new Map<String, String>();
            tmp_record = id_score_map.get(record_rank);
            Integer score = Integer.valueOf(tmp_record.get('score'));
            score_list.add(score);
            tmp_map.put(record_rank, String.valueOf(score));
        }
        score_list.sort();
        List<Integer>reverse_score = new List<Integer>();
        for (Integer i = score_list.size() - 1; i >= 0; i--) {
            reverse_score.add(score_list[i]);
        }
        Integer list_count = 1;
        for (Integer value_key: reverse_score) {
            if (list_count > LIMIT_CONST) {
                break;
            }

            for (String order_by_key: tmp_map.keySet()) {
                if (tmp_map.get(order_by_key) == String.valueOf(value_key)) {
                    result.put(string.valueOf(list_count), id_score_map.get(order_by_key));
                    tmp_map.remove(order_by_key);
                    break;
                }
            }
            list_count++;
        }

        return result;
    }

    /**
     * This function is to get asset details
     *
     * @param Map<String, Map<String, String>> sorted_results Sorted results value.
     * @return Map<String, Map<String, String>> return_val Return result map with asset value.
     */
    private static Map<String, Map<String, String>> addAssets (Map<String, Map<String, String>>sorted_results) {
        Map<String, Map<String, String>> return_val = new Map<String, Map<String, String>>();
        for (String current_order: sorted_results.keySet()) {
            Map<String, String> tmp_record_details = sorted_results.get(current_order);
            String account_id = tmp_record_details.get('id');
            String asset_val = getDataFromTracker.getAssetDetails(account_id);
            tmp_record_details.put('asset', asset_val);
            return_val.put(current_order, tmp_record_details);
        }
        return return_val;
    }

    /**
     * This function is used to get Address Latitude and Longitude
     *
     * @param String record_id Record Id
     * @return List<SObject> address_lat_lng Address Latitude and Longitude values.
     */
    private static List<SObject> getAddress (String record_id) {
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
     * @return String object_type Object Type.
     */
    private static String getObjectType (Id record_id) {
        String object_type = String.valueOf(record_id.getsobjecttype()).toLowerCase();
        return object_type;
    }

    /**
     * This function is used to get distance calculation string
     *
     * @param String object_type Object Type
     * @param Decimal Lat Latitude
     * @param Decimal Lng Longitude
     * @return String distance_string Distance calculation string.
     */
    private static String getDistanceString (String object_type, Decimal lat, Decimal lng) {
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
     * @return String sql_string Main SOQL query string.
     */
    private static String getMainSOQLString (String object_type) {
        String sql_string = '';
        if (object_type == 'account') {
            sql_string = 'SELECT Id, Name, BillingAddress, BillingCity, BillingState, Actual_Revenue_Commitment__c,' +
             ' Sic, Boxes_Per_Day__c, Total_Box_SKUs__c FROM Account WHERE ';
        } else if (object_type == 'lead') {
            sql_string = 'SELECT Id, Name, Address, City, AnnualRevenue, SIC_Code__c FROM Lead WHERE ';
        }
        return sql_string;
    }

    /**
     * This function is used to get where condition for SOQL query
     *
     * @param String object_type Object Type
     * @param String distance_val Distance calcuation string
     * @param Map<String, String> filters Filter key and value (e.g. {'industry':'paper'})
     * @return String soql_query Where condition string.
     */
    private static String getWhereForSOQL (String object_type, String distance_val, Map<String, String>filters) {
        String soql_query = '';
        if (object_type == 'account') {
            soql_query += ' industry = \''+ String.valueOf(filters.get('industry')) +'\' ';
            soql_query += 'AND '+ distance_val;
            if (String.isNotEmpty(filters.get('distance')) && String.isNotBlank(filters.get('distance'))) {
                soql_query += ' < '+filters.get('distance');
            } else {
                soql_query += '< 500';
            }
            soql_query += ' AND type = \'Paying Customer\' AND Install_Date__c <= TODAY AND (NOT contract_term__c LIKE \'%z-Fold%\')';
        } else if (object_type == 'lead') {

        }

        return soql_query;
    }

    /**
     * This function is used to calculate the distance.
     *
     * @param Location from_loc From location details
     * @param Location new_loc New location details
     * @return String dist Distance value.
     */
    private static String getDistanceFromParentRecord (Location from_loc, Location new_loc) {
        Double new_lat = new_loc.latitude;
        Double new_lon = new_loc.longitude;
        Location to_loc = Location.newInstance(new_lat, new_lon);

        String dist = String.valueof(Math.ceil(from_loc.getDistance(to_loc, 'mi')));
        return dist;
    }

    /**
     * This function is used to sort the records.
     *
     * @param Map<String, Map<String, String>> records Records which needs to sort
     * @param String order_by Sorting key
     * @return Map<String, Map<String, String>> result Sorted result.
     */    
    private static Map<String, Map<String, String>> getSortedRecords (Map<String, Map<String, String>> records,
        String order_by
    ) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<String, String> order_by_map = new Map<String, String>();
        List<Integer> field_value_list = new List<Integer>();

        for(String current_order: records.keySet()) {
            Map<String, String> record = new Map<String, String>(records.get(current_order));
            order_by_map.put(current_order, record.get(order_by));
            field_value_list.add(Integer.valueOf(record.get(order_by)));
        }

        field_value_list.sort();

        Integer list_count = 1;
        for (Integer value_key: field_value_list) {
            if (list_count > LIMIT_CONST) {
                break;
            }
            System.debug('order_by '+ order_by_map);
            for (String order_by_key: order_by_map.keySet()) {
                if (order_by_map.get(order_by_key) == String.valueOf(value_key)) {
                    result.put(string.valueOf(list_count), records.get(order_by_key));
                    order_by_map.remove(order_by_key);
                    break;
                }
            }
            list_count++;
        }
        return result;
    }

    /**
     * This function is used to upsert the records to object.
     *
     * @param Map<String, Map<String, String>> records Records which needs to upsert
     * @param String main_record_id Record id
     * @param String cat Category name
     *
     * @return Boolean success
     */ 
    private static Boolean upsert_records(Map<String, Map<String, String>> records,
        String main_record_id,
        String cat
    ) {
        Boolean success = false;
        Integer order = 1;
        Lead main_lead = [SELECT Name FROM Lead WHERE Id =:main_record_id LIMIT 1];
        main_lead.LastTopResultCategory__c = cat;
        update main_lead;
        for(String record_key: records.keySet()){
            Map<String, String> value_to_update = records.get(record_key);
            String related_object_id = value_to_update.get('id');
            String dist = value_to_update.get('dist');
            String soql = 'SELECT Id FROM Top_Account_tracker__c WHERE Related_Lead__c = \''+main_record_id+
                '\' AND Order__c = '+order+' LIMIT 1';
            System.debug('soql query '+soql);
            List<Account> account_name = [SELECT Name FROM Account WHERE id =: related_object_id LIMIT 1];
            List<Top_Account_tracker__c> check_id = database.query(soql);
            Top_Account_Tracker__c top_record;
            if (!check_id.isEmpty()) {
                  Id existed_id = check_id[0].Id;
                top_record = new Top_Account_Tracker__c(Id = existed_id);
            } else {
                top_record = new Top_Account_Tracker__c();
            }

            String tmp_name = account_name[0].Name;
            Integer tmp_score = Integer.valueOf(value_to_update.get('score'));
            top_record.Score__c = tmp_score;
            top_record.Name = tmp_name;
            top_record.Relates_To__c = related_object_id;
            top_record.Miles__c = Decimal.valueOf(dist);
            top_record.Related_Lead__c  = main_record_id;
            top_record.Order__c = order;
            top_record.Category__c = cat;
            System.debug('object ' + top_record);
            if (!check_id.isEmpty()) {
                update top_record;
            } else {
                insert top_record;
            }
            order++;
        }
       
        return success;
   }

}