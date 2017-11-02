/** 
 * This class is used to rate the score for each record based on scoring algorith.
*/
global with sharing class recordScore {

    static Integer DIST_PRIORITY_SCORE = 10;
    static Integer REV_PRIORITY_SCORE = 5;
    static Integer BOX_PRIORITY_SCORE = 3;
    static Integer SIC_PRIORITY_SCORE = 2;
    static Integer SKU_PRIORITY_SCORE = 1;

    public recordScore() { }

    /**
     * This function set the custom setting for record limit.
     **/
    private static void setPriorityConst () {
        topResultSettings__c trs = topResultSettings__c.getValues(userinfo.getProfileId());
        try {
            DIST_PRIORITY_SCORE = (Integer)trs.distancePriorityScore__c;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to DIST_PRIORITY_SCORE = 10.');
            DIST_PRIORITY_SCORE = 10;
        }
        try {
            REV_PRIORITY_SCORE = (Integer)trs.revenuePriorityScore__c;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to REV_PRIORITY_SCORE = 10.');
            REV_PRIORITY_SCORE = 5;
        }
        try {
            BOX_PRIORITY_SCORE = (Integer)trs.boxPriorityScore__c;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to BOX_PRIORITY_SCORE = 3.');
            BOX_PRIORITY_SCORE = 3;
        }
        try {
            SIC_PRIORITY_SCORE = (Integer)trs.sicPriorityScore__c;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to SIC_PRIORITY_SCORE = 2.');
            SIC_PRIORITY_SCORE = 2;
        }
        try {
            SKU_PRIORITY_SCORE = (Integer)trs.skuPriorityScore__c;
        } catch (Exception e) {
            System.debug('No value set for custom setting. Default goes to SKU_PRIORITY_SCORE = 1.');
            SKU_PRIORITY_SCORE = 1;
        }
    }
    /**
     * This function is used to get the score for record.
     * @param Map<String, Map<String, String>> record Record information for score calculation
     * @return Map<String, String> Record Id and it's score.
     */
    public static Map<String, Map<String, String>> getRecordScore (Map<String, Map<String, String>>record) {
        setPriorityConst();
        Map<String, Map<String, String>> score_result = new Map<String, Map<String, String>>();
        Set<String> record_ids = record.keySet();
        topResultSettings__c trs = topResultSettings__c.getValues(userinfo.getProfileId());
        Integer revenue_range = (Integer)trs.revenueRange__c;
        Integer distance_range = (Integer)trs.distanceRange__c;
        Integer box_range = (Integer)trs.boxRange__c;
        Integer sic_range = (Integer)trs.sicRange__c;
        Integer sku_range = (Integer)trs.skuRange__c;
        Integer score_rank = 0;
        for (String record_id : record_ids) {
            Map<String, String> record_vals = new Map<String, String>(record.get(record_id));
            String record_sf_id = record_vals.get('id');
            String score_para_val = record_vals.get('dist');
            Integer distance_score = (getDistanceScore(score_para_val, distance_range)) * DIST_PRIORITY_SCORE;
            record_vals.put('dist_score', String.valueOf(distance_score));
            score_para_val = record_vals.get('revenue');
            Integer revenue_score = (getRevenueScore(score_para_val, revenue_range)) * REV_PRIORITY_SCORE;
            record_vals.put('revenue_score', String.valueOf(revenue_score));
            score_para_val = record_vals.get('boxes');
            Integer box_score = (getBoxScore(score_para_val, box_range)) * BOX_PRIORITY_SCORE;
            record_vals.put('box_score', String.valueOf(box_score));
            score_para_val = (record_vals.get('sic')).length() > 0 ?  record_vals.get('sic'): '0';
            Integer sic_score = (getSicScore(score_para_val, sic_range)) * SIC_PRIORITY_SCORE;
            record_vals.put('sic_score', String.valueOf(sic_score));
            score_para_val = record_vals.get('product');
            Integer product_sku_score = (getProductSKUScore(score_para_val, sku_range)) * SKU_PRIORITY_SCORE;
            record_vals.put('sku_score', String.valueOf(product_sku_score));
            Integer total_score = distance_score + revenue_score + box_score + sic_score + product_sku_score;
            Map<String, String> tmp_record_score = new Map<String, String>();
            tmp_record_score.put('id', record_sf_id);
            record_vals.put('score', String.valueOf(total_score));
            score_result.put(String.valueOf(score_rank), record_vals);
            score_rank++;
         }
        return score_result;
    }

    /**
    * This function is used to get the score for Distance.
    * @param String distance Distance difference value
    * @param Integer distance_range Distance range value.
    * @return Integer Score value.
    */
    private static Integer getDistanceScore(String distance, Integer distance_range) {
        Integer score = 0;
        Long dist = Long.valueOf(distance);
        if (distance_range > 0) {
            score = getScoreMap(distance_range, dist);
        } else {
            score = getScoreMap(1, dist);
        }
        return score;
    }

    /**
    * This function is used to get the score for Revenue.
    * @param String revenue Revenue difference value
    * @param Integer revenue_range Revenue range value
    * @return Integer Score value.
    */
    private static Integer getRevenueScore(String revenue, Integer revenue_range) {
        Integer score = 0;
        Long rev = Long.valueOf(revenue);
        if (revenue_range > 0) {
            score = getScoreMap(revenue_range, rev);
        } else {
            score = getScoreMap(1000, rev);
        }
        return score;
    }

    /**
    * This function is used to get the score for Boxes per day.
    * @param String boxes Boxes per day difference value
    * @param Integer box_range Boxes per day range value
    * @return Integer Score value.
    */
    private static Integer getBoxScore(String boxes, Integer box_range) {
        Integer score = 0;
        Long box = Long.valueOf(boxes);
        if (box_range > 0) {
            score = getScoreMap(box_range, box);
        } else {
            score = getScoreMap(15, box);
        }
        return score;
    }

    /**
    * This function is used to get the score for SIC code.
    * @param String sic Sic difference value
    * @param Integer sic_range Sic range value
    * @return Integer Score value.
    */
    private static Integer getSicScore(String sic, Integer sic_range) {
        Integer score = 0;
        Long sic_int = Long.valueOf(sic);
        if (sic_range > 0) {
            score = getScoreMap(sic_range, sic_int);
        } else {
            score = getScoreMap(1, sic_int);
        }
        return score;
    }

    /**
    * This function is used to get the score for Product SKU code.
    * @param String sku Product SKU difference value
    * @param Integer sku_range SKU range value
    * @return Integer Score value.
    */
    private static Integer getProductSKUScore(String sku, Integer sku_range) {
        Integer score = 0;
        Long sku_int = Long.valueOf(sku);
        if (sku_range > 0) {
            score = getScoreMap(sku_range, sku_int);
        } else {
            score = getScoreMap(1, sku_int);
        }
        return score;
    }

    /**
    * This function is used to get the score.
    * @param Integer start_diff Range map difference calculator value. This value decide the
    *                           exponential range starting point.
    * @param Long param_val Parameter value for which we are calculating the score.
    * @return Integer Score value.
    */
    private static Integer getScoreMap(Integer start_diff, Long param_val) {
        Long high_end = start_diff;
        Long low_end = 0;
        Integer score = 0;
        if (start_diff > 0) {
            for (score = 10; score>=0 ; score--) {
                if (param_val > low_end && param_val < high_end) {
                    return score;
                }
                low_end = high_end;
                start_diff = start_diff*2;
                high_end = low_end + start_diff;
            }
        }
        if (score < 0) {
            score = 0;
        }
        return score;
    }
}