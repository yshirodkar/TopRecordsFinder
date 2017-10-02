/** 
 * This class is used to rate the score for each record based on scoring algorith.
*/
global with sharing class recordScore {

    public recordScore() {}

    private static Map<String, String> distance_score_map {get; set;}

    /**
     * This function is used to get the score for record.
     * @param Map<String, Map<String, String>> record Record information for score calculation
     * @return Map<String, String> Record Id and it's score.
     */
    public static Map<String, String> getRecordScore (Map<String, Map<String, String>>record) {

        Map<String, String> score_result = new Map<String, String>();
        Set<String> record_ids = record.keySet();
        for (String record_id : record_ids) {
            Map<String, String> record_vals = new Map<String, String>(record.get(record_id));
            String difference_val = record_vals.get('dist');
            Integer distance_score = getDistanceScore(difference_val);
            //Integer revenue_score = getRevenueScore();
            //Integer box_per_day_score = getBoxPerDayScore();
            //Integer sic_score = getSicScore();
            //Integer product_sku_score = getProductSKUScore();
            //Integer total_score = distance_score + revenue_score +
            //  box_per_day_score + sic_score + product_sku_score;
            //score_result.put(record_id, String.valueOf(total_score));
            //
         }
        return score_result;
    }

    /**
    * This function is used to get the score for Distance.
    * @param String distance Distance value
    * @return Integer Score value.
    */
    private static Integer getDistanceScore(String distance) {
        Integer score = 0;
        if (String.isNotEmpty(distance)) {
            // This section will get the score from mapped variable (distance_score_map).
        }
        return score;
    }

    /**
    * This function is used to set the Distance and it's score mapping
    * @return Map<String, String> Distance Score mapping
    */
    private static void setDistanceScoreMap() {
        Set<String> dist_keySets = distance_score_map.keySet();
        if (dist_keySets.size() > 0) {
            // If the values for score mapping is not set. This section should set the value.
            // Value will be stored in 'distance_score_map'. 
        }
    }
}