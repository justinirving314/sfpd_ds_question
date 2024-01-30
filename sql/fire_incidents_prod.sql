/*
This will be our production fire incidents table.
We would like to join with assessor information as well as some information about previous fire and dbi violations. We will left join to assessor
so we can check rates of incidents based on overall number of properties with those characteristics.

Create new flags for fatalities and injuries (small numbers and highest safety risk)

This information will be joined to the entire assessor set so we can see if any factors correspond to increased likelihood of fire

*/


DROP TABLE IF EXISTS fire_incidents_prod;

CREATE TABLE fire_incidents_prod AS

WITH cte AS (
SELECT parcel_number, incident_number, incident_date, number_of_alarms, action_taken_primary,
CASE WHEN (CAST(fire_fatalities AS INT) > 0 OR CAST(civilian_fatalities AS INT) > 0) THEN 1 ELSE 0 END as fatality_flag,
CASE WHEN (CAST(fire_injuries AS INT) > 0 OR CAST(civilian_injuries AS INT) > 0) THEN 1 ELSE 0 END as injury_flag,
CASE WHEN primary_situation IN ('111 - Building fire', '111 Building fire') THEN 1 ELSE 0 END AS bldg_fire_flag,
primary_situation

FROM fire_incidents_raw)

SELECT *
FROM cte 