CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
--concatenating--
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202205`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202206`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202207`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202208`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202209`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202210`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202211`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202212`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202301`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202302`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202303`
  UNION ALL
  SELECT *
  FROM `japanese-grammar-276308.divvy_project_mana.divvy_tripdata_202304`;

---Duplicate check

SELECT
  ride_id, COUNT(*) AS id_count
FROM
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
GROUP BY
 ride_id
HAVING
  id_count > 1;

---Classic and docked are the same
UPDATE 
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET 
  rideable_type = 'classic_bike'
WHERE 
  rideable_type = 'docked_bike';

---remove non-customer stations
CREATE OR REPLACE TABLE 
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT
  *
FROM
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
WHERE
  start_station_name <> 'DIVVY CASSETTE REPAIR MOBILE STATION' AND
  start_station_name <> 'Lyft Driver Center Private Rack' AND 
  start_station_name <> '351' AND 
  start_station_name <> 'Base - 2132 W Hubbard Warehouse' AND 
  start_station_name <> 'Hubbard Bike-checking (LBS-WH-TEST)' AND 
  start_station_name <> 'WEST CHI-WATSON';

---adding ride_length
ALTER TABLE
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
ADD COLUMN
  ride_length INT;

UPDATE
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET
  ride_length = TIMESTAMP_DIFF(ended_at, started_at, MINUTE)
WHERE
  ride_length IS NULL;

---we could make an inference that these are truly missing and use their bike_ids to check where they went missing and if they were found, but not the objective of this project.
SELECT*
FROM 
(SELECT *
FROM
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
  WHERE
      ride_length >= 1440
)
WHERE
  end_lng IS NULL AND end_lat IS NULL AND end_station_name IS NULL AND end_station_id IS NULL;

---Less than one minute = error
---&
---More than one day = missing [LIMITATION]
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
  SELECT *

  FROM
    `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
  
  WHERE
    ride_length >= 1 AND ride_length <= 1440
    ;


---missing id and station name
---make a reference for JOIN using lat and lng
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,
       CONCAT(CAST(start_lat AS STRING), ', ', CAST(start_lng AS STRING)) AS start_lat_lng
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;


---Self joining to fill in empty start_station_name where lat/lng are exact matches
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
  SELECT
     t1.*, IF(t1.start_station_name IS NULL, t2.start_station_name, t1.start_station_name) AS start_station_name_v1
  FROM 
    `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t1
  LEFT JOIN
    (
      SELECT
        DISTINCT start_station_name, start_lat_lng
      FROM
        `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
      WHERE
        start_station_name IS NOT NULL AND start_lat_lng IS NOT NULL
    ) AS t2
      ON
        t1.start_lat_lng = t2.start_lat_lng;


---the same for start_station_id
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT
 t1.*, IF(t1.start_station_id IS NULL, t2.start_station_id, t1.start_station_id) AS start_station_id_v1
FROM 
    `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t1
LEFT JOIN
  (
    SELECT
      DISTINCT start_station_id, start_lat_lng
    FROM
      `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t2
    WHERE
      start_station_id IS NOT NULL AND start_lat_lng IS NOT NULL
  ) AS t2
  ON
    t1.start_lat_lng = t2.start_lat_lng;


---REPEAT above for end_station_id and end_station_name


---make a reference for JOIN using lat and lng
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,
       CONCAT(CAST(end_lat AS STRING), ', ', CAST(end_lng AS STRING)) AS end_lat_lng
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;

---Self joining to fill in empty end_station_name where lat/lng are exact matches
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
  SELECT
     t1.*, IF(t1.end_station_name IS NULL, t2.end_station_name, t1.end_station_name) AS end_station_name_v1
  FROM 
    `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t1
  LEFT JOIN
    (
      SELECT
        DISTINCT end_station_name, end_lat_lng
      FROM
        `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
      WHERE
        end_station_name IS NOT NULL AND end_lat_lng IS NOT NULL
    ) AS t2
      ON
        t1.end_lat_lng = t2.end_lat_lng;
---the same for end_station_id
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT
 t1.*, IF(t1.end_station_id IS NULL, t2.end_station_id, t1.end_station_id) AS end_station_id_v1
FROM 
    `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t1
LEFT JOIN
  (
    SELECT
      DISTINCT end_station_id, end_lat_lng
    FROM
      `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS t2
    WHERE
      end_station_id IS NOT NULL AND end_lat_lng IS NOT NULL
  ) AS t2
  ON
    t1.end_lat_lng = t2.end_lat_lng;

---START STATION check for remaining nulls
SELECT *
FROM (
  SELECT 
    started_at, 
    ended_at, 
    start_station_name_v1,
    start_station_id_v1, 
    start_lat_lng,
    ROW_NUMBER() OVER (PARTITION BY start_station_name_v1 ORDER BY started_at) AS row_num
  FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` 
  WHERE
    start_lat_lng IS NOT NULL AND
    start_station_name_v1 = start_station_id_v1
) 
;
---410 and Oakwood Beach are from specific dates
---Oakwood is an event, 410 is unknown
---find the ids
SELECT
  DISTINCT start_station_id
FROM
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
WHERE
  start_station_name = 'Divvy Valet - Oakwood Beach' OR start_station_name = '410';
---looks like they don't exist so leave as is unless necessary

---END STATION check for remaining nulls
SELECT *
FROM (
  SELECT 
    ended_at, 
    ended_at, 
    end_station_name_v1,
    end_station_id_v1, 
    end_lat_lng,
    ROW_NUMBER() OVER (PARTITION BY end_station_name_v1 ORDER BY ended_at) as row_num
  FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` 
  WHERE
    end_lat_lng IS NOT NULL AND
    end_station_name_v1 = end_station_id_v1
) 
;
---Remove non-customer rides
CREATE OR REPLACE TABLE 
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT
  *
FROM
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
WHERE
  end_station_name_v1 <> 'DIVVY CASSETTE REPAIR MOBILE STATION' AND
  end_station_name_v1 <> 'Lyft Driver Center Private Rack' AND 
  end_station_name_v1 <> '351' AND 
  end_station_name_v1 <> 'Base - 2132 W Hubbard Warehouse' AND 
  end_station_name_v1 <> 'Hubbard Bike-checking (LBS-WH-TEST)' AND 
  end_station_name_v1 <> 'WEST CHI-WATSON';
---Now all that remains is 410 and Oakwood Beach


---Remove all duplicates that were created in this process (LEFT JOIN with un-unique lat_lng)
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *
FROM (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY ride_id) AS row_num
  FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
) 
WHERE row_num = 1;
---delete row_num so next is smooth
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT 
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at, 
    start_station_name, 
    start_station_id, 
    end_station_name, 
    end_station_id, 
    start_lat, 
    start_lng, 
    end_lat, 
    end_lng, 
    member_casual, 
    ride_length, 
    start_lat_lng, 
    start_station_name_v1, 
    start_station_id_v1,
    end_station_name_v1,
    end_station_id_v1,
    end_lat_lng
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;


---Undocked electric bikes CAN mean locked with chain
UPDATE 
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET 
  start_station_name_v1 = 'bike_lock'
WHERE 
  start_station_name_v1 IS NULL AND rideable_type = 'electric_bike';





-------------[FROM HERE PREP FOR ANALYSIS]


-------------------Flow map----------------------

--- Making a table for Flow map viz
---finding common start and end pairs
---making a view of the strings to compare
CREATE OR REPLACE VIEW `japanese-grammar-276308.divvy_project_mana.rides_view` AS
SELECT *,
  CONCAT(
    CAST(ROUND(start_lat, 4) AS STRING),
    ' , ',
    CAST(ROUND(start_lng, 4) AS STRING)
  ) AS start_lat_lng_round,
  CONCAT(
    CAST(ROUND(end_lat, 4) AS STRING),
    ' , ',
    CAST(ROUND(end_lng, 4) AS STRING)
  ) AS end_lat_lng_round
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;

---making a table with top 10 of each member type
---casuals
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS
SELECT member_casual, start_lat_lng_round, end_lat_lng_round, COUNT(*) AS num_occurrences
FROM `japanese-grammar-276308.divvy_project_mana.rides_view`
WHERE member_casual = 'casual'
GROUP BY member_casual, start_lat_lng_round, end_lat_lng_round
ORDER BY num_occurrences DESC
LIMIT 10;

---members
CREATE OR REPLACE VIEW `japanese-grammar-276308.divvy_project_mana.common_route_member` AS
SELECT member_casual, start_lat_lng_round, end_lat_lng_round, COUNT(*) AS num_occurrences
FROM `japanese-grammar-276308.divvy_project_mana.rides_view`
WHERE member_casual = 'member'
GROUP BY member_casual, start_lat_lng_round, end_lat_lng_round
ORDER BY num_occurrences DESC
LIMIT 10;
---combine them
INSERT INTO `japanese-grammar-276308.divvy_project_mana.member_route_all`
SELECT * FROM `japanese-grammar-276308.divvy_project_mana.common_route_member`;
---add column for start_station_name_v1
ALTER TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all`
ADD COLUMN
  start_station_name_v1 STRING;

---insert most likely start_station_name_v1
---make view of distinct start_station_name_v1 and order by count

CREATE OR REPLACE VIEW `japanese-grammar-276308.divvy_project_mana.first_appearance` AS
SELECT
  start_station_name_v1, start_lat_lng_round, count
FROM
  (
    SELECT
      start_station_name_v1, start_lat_lng_round, count,
        ROW_NUMBER() OVER (PARTITION BY start_lat_lng_round ORDER BY count DESC) AS row_number
    FROM
      (
        SELECT
          start_station_name_v1, start_lat_lng_round, COUNT(*) AS count
        FROM
          `japanese-grammar-276308.divvy_project_mana.rides_view`
        GROUP BY start_station_name_v1, start_lat_lng_round
      )
  )

WHERE
  row_number = 1
ORDER BY count DESC;


---add these to member_route_all
UPDATE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS CRA
SET CRA.start_station_name_v1 = CCS.start_station_name_v1
FROM
  `japanese-grammar-276308.divvy_project_mana.first_appearance` AS CCS
WHERE CRA.start_lat_lng_round = CCS.start_lat_lng_round;

----------Do same for end
---add column for end_station_name_v1
ALTER TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all`
ADD COLUMN
  end_station_name_v1 STRING;

---insert most likely end_station_name_v1
---make view of distinct end_station_name_v1 and order by count

CREATE OR REPLACE VIEW `japanese-grammar-276308.divvy_project_mana.first_appearance_end` AS
SELECT
  end_station_name_v1, end_lat_lng_round, count
FROM
  (
    SELECT
      end_station_name_v1, end_lat_lng_round, count,
        ROW_NUMBER() OVER (PARTITION BY end_lat_lng_round ORDER BY count DESC) AS row_number
    FROM
      (
        SELECT
          end_station_name_v1, end_lat_lng_round, COUNT(*) AS count
        FROM
          `japanese-grammar-276308.divvy_project_mana.rides_view`
        GROUP BY end_station_name_v1, end_lat_lng_round
      )
  )

WHERE
  row_number = 1
ORDER BY count DESC;


---add these to member_route_all
UPDATE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS CRA
SET CRA.end_station_name_v1 = CCS.end_station_name_v1
FROM
  `japanese-grammar-276308.divvy_project_mana.first_appearance_end` AS CCS
WHERE CRA.end_lat_lng_round = CCS.end_lat_lng_round;


---splitting the lat_lng columns
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS
SELECT
SPLIT(start_lat_lng_round, ' , ')[OFFSET(0)] AS start_lat_round,
SPLIT(start_lat_lng_round, ' , ')[OFFSET(1)] AS start_lng_round,
SPLIT(end_lat_lng_round, ' , ')[OFFSET(0)] AS end_lat_round,
SPLIT(end_lat_lng_round, ' , ')[OFFSET(1)] AS end_lng_round,
num_occurrences, start_station_name_v1, end_station_name_v1, member_casual
FROM
  `japanese-grammar-276308.divvy_project_mana.member_route_all`;

CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS
SELECT
  CAST(start_lat_round AS FLOAT64) AS start_lat_round,
  CAST(start_lng_round AS FLOAT64) AS start_lng_round,
  CAST(end_lat_round AS FLOAT64) AS end_lat_round,
  CAST(end_lng_round AS FLOAT64) AS end_lng_round,
  num_occurrences,
  start_station_name_v1,
  end_station_name_v1,
  member_casual
FROM
  `japanese-grammar-276308.divvy_project_mana.member_route_all`;

---adding same start and end station status for a filter so the flow map in Power BI doesn't error
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.member_route_all` AS
SELECT *,
       IF(start_station_name_v1 = end_station_name_v1, 'T', 'F') AS station_match
FROM `japanese-grammar-276308.divvy_project_mana.member_route_all`;


-----------------flow map ready--------------

/*
THIS PROVED USELESS AS POWER BI COULD NOT HANDLE THE AMOUNT OF DATA IT HAD TO RELATE TO


---making dates table for separate tables
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.dates` AS
SELECT DISTINCT started_at, start_at_month_name, start_at_dayofweek, started_at_hour, started_at_month, started_at_day, started_at_dayofmonth, season, season_number
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
ORDER BY started_at, started_at_month, started_at_dayofmonth, started_at_day, started_at_hour;

---Adding days and hours to table

CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,
       MOD(EXTRACT(DAYOFWEEK FROM started_at) + 5, 7) + 1 AS started_at_day,
       EXTRACT(MONTH FROM started_at) AS started_at_month,
       EXTRACT(HOUR FROM started_at) AS started_at_hour,
       MOD(EXTRACT(DAYOFWEEK FROM ended_at) + 5, 7) + 1 AS ended_at_day,
       EXTRACT(MONTH FROM started_at) AS ended_at_month,
       EXTRACT(DAY FROM started_at) AS started_at_dayofmonth,
       EXTRACT(HOUR FROM ended_at) AS ended_at_hour,
       FORMAT_TIMESTAMP('%A', started_at) AS start_at_dayofweek,
       FORMAT_TIMESTAMP('%A', ended_at) AS ended_at_dayofweek,
       FORMAT_TIMESTAMP('%B', started_at) AS start_at_month_name,
       FORMAT_TIMESTAMP('%B', ended_at) AS ended_at_month_name
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;
*/

CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,

       EXTRACT(DAY FROM started_at) AS started_at_dayofmonth
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;



----Adding Seasons----
ALTER TABLE
  `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
ADD COLUMN season STRING;

UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET season = 'Winter'
WHERE started_at_month = 1 OR started_at_month = 2 OR started_at_month = 12;

UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET season = 'Spring'
WHERE started_at_month = 3 OR started_at_month = 4 OR started_at_month = 5;

UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET season = 'Summer'
WHERE started_at_month = 6 OR started_at_month = 7 OR started_at_month = 8;

UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET season = 'Fall'
WHERE started_at_month = 9 OR started_at_month = 10 OR started_at_month = 11;

---Add season_number
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,
  CASE 
    WHEN season = 'Winter' THEN 1
    WHEN season = 'Spring' THEN 2
    WHEN season = 'Summer' THEN 3
    WHEN season = 'Fall' THEN 4
    ELSE NULL
  END as season_number
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;

---------------Seasons ready----------------------------------

------------------------medians----------------------------
/* month_day means daily medians of each month. VS day_medians means overall per day median*/
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT *,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, start_at_month_name, started_at_day, started_at_hour) AS day_hour_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, started_at_hour) AS hour_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER  (PARTITION BY member_casual, start_at_month_name, started_at_day) AS month_day_medians, 
PERCENTILE_CONT(ride_length, 0.5) OVER  (PARTITION BY member_casual, started_at_day) AS day_medians, 
PERCENTILE_CONT(ride_length, 0.5) OVER  (PARTITION BY member_casual, start_at_month_name) AS month_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER  (PARTITION BY member_casual, season_number) AS seasonal_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, rideable_type, start_at_month_name) AS rideable_month_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, rideable_type, start_at_month_name, start_at_dayofweek) AS rideable_month_day_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, rideable_type, start_at_dayofweek) AS rideable_day_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, rideable_type, start_at_month_name, start_at_dayofweek, started_at_hour) AS rideable_day_hour_medians,
PERCENTILE_CONT(ride_length, 0.5) OVER(PARTITION BY member_casual, rideable_type, started_at_hour) AS rideable_hour_medians
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`;

--------------medians ready------------------------------------

------------------ln(B) - ln(A)....(percentage change per date)------------------------

---ride count
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT 
  Table1.*,
  Table2.monthly_count_change
FROM 
`japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS Table1
FULL OUTER JOIN 
  (SELECT member_casual, monthly_count_change, started_at_month
FROM 
(
SELECT
 started_at_month, member_casual,
(LN(ride_count) - LN(LAG(ride_count, 1) OVER (PARTITION BY member_casual ORDER BY started_at_month)))*100 AS monthly_count_change
FROM
(
SELECT  started_at_month, member_casual, COUNT(ride_id) AS ride_count
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`

GROUP BY  started_at_month, member_casual
)
ORDER BY started_at_month
)) AS Table2 
ON 
  Table1.member_casual = Table2.member_casual AND 
  Table1.started_at_month = Table2.started_at_month
ORDER BY member_casual;


---per month median length % change
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT 
  Table1.*,
  Table2.monthly_length_change
FROM 
`japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS Table1
FULL OUTER JOIN 
  (SELECT member_casual, monthly_length_change, started_at_month
FROM 
(
SELECT
 started_at_month, member_casual, month_medians,
(LN(month_medians) - LN(LAG(month_medians, 1) OVER (PARTITION BY member_casual ORDER BY started_at_month)))*100 AS monthly_length_change
FROM
(
SELECT  started_at_month, member_casual, month_medians
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`

GROUP BY  started_at_month, member_casual, month_medians
)
ORDER BY started_at_month
)) AS Table2 
ON 
  Table1.member_casual = Table2.member_casual AND 
  Table1.started_at_month = Table2.started_at_month
ORDER BY member_casual;


---make total length % changes
CREATE OR REPLACE TABLE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS
SELECT 
  Table1.*,
  Table2.monthly_tot_length_change
FROM 
`japanese-grammar-276308.divvy_project_mana.cyclistic_combined` AS Table1
FULL OUTER JOIN 
  (SELECT member_casual, monthly_tot_length_change, started_at_month
FROM 
(
SELECT
start_at_month_name, started_at_month, member_casual,
(LN(length_tot) - LN(LAG(length_tot, 1) OVER (PARTITION BY member_casual ORDER BY started_at_month)))*100 AS monthly_tot_length_change
FROM
(
SELECT start_at_month_name, started_at_month, member_casual, SUM(ride_length) AS length_tot
FROM `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`

GROUP BY start_at_month_name, started_at_month, member_casual
)
ORDER BY started_at_month
)) AS Table2 
ON 
  Table1.member_casual = Table2.member_casual AND 
  Table1.started_at_month = Table2.started_at_month
ORDER BY started_at_month, member_casual;
---converting nulls to zero
UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET monthly_length_change = 0 WHERE started_at_month = 1;
UPDATE `japanese-grammar-276308.divvy_project_mana.cyclistic_combined`
SET monthly_tot_length_change = 0 WHERE started_at_month = 1;

-----------------Percentage change ready-------------------------


