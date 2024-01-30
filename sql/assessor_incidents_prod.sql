/*

This table links fire_incidents to assessor data. We want to understand rates of incidents across types of factors and because
there isn't a sample (investigation) associated with the incidents, we need to join to all properties so rates are normalized
by total number of properties in a group.

*/

DROP TABLE IF EXISTS assessor_incidents_prod;

CREATE TABLE assessor_incidents_prod AS

WITH cte AS (
SELECT DISTINCT ap.*, 
CASE WHEN fp.parcel_number IS NOT NULL THEN 1
	ELSE 0 END AS fire_incident_flag, 
MAX(fatality_flag) AS fatality_flag, MAX(injury_flag) AS injury_flag, MAX(bldg_fire_flag) AS bldg_fire_flag,
MAX(fip.violation_flag) AS prev_fire_vio, MAX(dbi.violation_flag) AS prev_dbi_vio
FROM assessor_prod ap
LEFT JOIN
	(SELECT *
	FROM fire_incidents_prod 
	WHERE bldg_fire_flag = 1) fp
	ON ap.parcel_number = fp.parcel_number
	
LEFT JOIN
	(SELECT parcel_number, violation_flag
	FROM fire_inspections_prod) fip
	ON ap.parcel_number = fip.parcel_number

LEFT JOIN
	(SELECT parcel_number, violation_flag
	FROM dbi_inspections_prod) dbi
	ON ap.parcel_number = dbi.parcel_number

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

SELECT *
FROM cte
ORDER BY parcel_number;