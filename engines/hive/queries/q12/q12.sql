--"INTEL CONFIDENTIAL"
--Copyright 2015  Intel Corporation All Rights Reserved.
--
--The source code contained or described herein and all documents related to the source code ("Material") are owned by Intel Corporation or its suppliers or licensors. Title to the Material remains with Intel Corporation or its suppliers and licensors. The Material contains trade secrets and proprietary and confidential information of Intel or its suppliers and licensors. The Material is protected by worldwide copyright and trade secret laws and treaty provisions. No part of the Material may be used, copied, reproduced, modified, published, uploaded, posted, transmitted, distributed, or disclosed in any way without Intel's prior express written permission.
--
--No license under any patent, copyright, trade secret or other intellectual property right is granted to or conferred upon you by disclosure or delivery of the Materials, either expressly, by implication, inducement, estoppel or otherwise. Any license under such intellectual property rights must be express and approved by Intel in writing.


--Find all customers who viewed items of a given category on the web
--in a given month and year that was followed by an in-store purchase of an item from the same category in the three
--consecutive months.

-- Resources
--Result  --------------------------------------------------------------------
--keep result human readable
set hive.exec.compress.output=false;
set hive.exec.compress.output;

DROP TABLE IF EXISTS ${hiveconf:RESULT_TABLE};
CREATE TABLE ${hiveconf:RESULT_TABLE} (
	u_id    BIGINT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
STORED AS ${env:BIG_BENCH_hive_default_fileformat_result_table}  LOCATION '${hiveconf:RESULT_DIR}';

INSERT INTO TABLE ${hiveconf:RESULT_TABLE}
SELECT DISTINCT   wcs_user_sk --Find all customers
FROM 
(  -- web_clicks viewed items in date range with items from specified categories
  SELECT  wcs_user_sk, 
          wcs_click_date_sk 
  FROM  web_clickstreams, item 
  WHERE wcs_click_date_sk between 37134 and  (37134 + 30) --in a given month and year 
  AND i_category IN (${hiveconf:q12_i_category_IN})  -- filter given category 
  AND wcs_item_sk = i_item_sk 
  AND wcs_user_sk IS NOT NULL
  AND wcs_sales_sk IS NULL --only views, not purchases
) webInRange,
(  -- store sales in date range with items from specified categories
  SELECT  ss_customer_sk,
          ss_sold_date_sk
  FROM store_sales, item
  WHERE ss_sold_date_sk between 37134 and  (37134 + 90) -- in the three consecutive months.
  AND i_category IN (${hiveconf:q12_i_category_IN})  -- filter given category 
  AND ss_item_sk = i_item_sk 
  AND ss_customer_sk IS NOT NULL
) storeInRange
-- join web and store
WHERE wcs_user_sk = ss_customer_sk
AND wcs_click_date_sk < ss_sold_date_sk -- buy AFTER viewed on website
ORDER BY 	wcs_user_sk 
;