/*

Create a final table for fire inspections that includes additional information from the assessor
and violation tables. We are going to use this information to look at trends in the rate of violations
by different factors. We are only including open and completed inspections, not pending or expired.
We can also look at R2 inspections in this data based on inspection_type_desc and R2_flag.

It should be noted that violations are not linked in R2 inspection_numbers specifically and are filed under different inspection numbers
This should be investigated further down the road.

*/

DROP TABLE IF EXISTS fire_inspections_prod;

CREATE TABLE fire_inspections_prod AS

WITH inspections_cte AS (
SELECT r.parcel_number, r.inspection_number, r.inspection_type_description, r.inspection_start_date,
r.inspection_status, r.complaint_number, r.neighborhood_district, 
LAG(r.inspection_start_date) OVER(PARTITION BY r.parcel_number ORDER BY r.inspection_start_date ASC) AS last_inspection_date,
EXTRACT(DAY FROM r.inspection_start_date - LAG(r.inspection_start_date) OVER(PARTITION BY r.parcel_number ORDER BY r.inspection_start_date ASC))/365 AS years_last_inspection,	
ap.r2_flag, ap.sffd_r2_flag, ap.use_definition, ap.property_class_code_definition, ap.number_of_units, ap.total_units_new, ap.zoning_code, ap.construction_type, 
ap.status_code, ap.current_property_age, ap.property_age_bin
FROM fire_inspection_raw r
LEFT JOIN
	assessor_prod ap
	ON r.parcel_number = ap.parcel_number
WHERE r.inspection_type_description NOT IN ('Complaint Inspection','DBI Inspection')), --remove information on HIS inspections from this set

violations_cte AS (
SELECT parcel_number, inspection_number, violation_date, close_date, corrective_action, status
FROM fire_violations_raw
WHERE inspection_number IS NOT NULL),

final_cte AS (
SELECT DISTINCT i.parcel_number, i.inspection_number, i.inspection_type_description, i.inspection_start_date,
i.inspection_status, i.complaint_number, i.neighborhood_district, 
i.last_inspection_date,i.years_last_inspection,	
i.r2_flag, i.sffd_r2_flag, i.use_definition, i.property_class_code_definition, i.number_of_units, i.total_units_new,i.zoning_code, i.construction_type, 
i.status_code, i.current_property_age, i.property_age_bin,
CASE WHEN v.parcel_number IS NOT NULL THEN 1
	ELSE 0 END AS violation_flag,
v.violation_date, v.close_date, v.corrective_action, v.status,
MAX(dbi.violation_flag) AS dbi_violation_flag --was there a dbi violation between SFFD inspections
FROM inspections_cte i
LEFT JOIN 
	violations_cte v
	ON i.inspection_number = v.inspection_number
LEFT JOIN 
	(SELECT * 
	FROM dbi_inspections_prod
	ORDER BY parcel_number ASC, violation_date DESC) dbi
	ON i.parcel_number = dbi.parcel_number
	AND i.inspection_start_date > dbi.violation_date
	AND  i.last_inspection_date <= dbi.violation_date
	
WHERE LOWER(i.inspection_status) IN ('completed', 'open/follow-up needed') -- exclude expired and pending
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
ORDER BY i.parcel_number, inspection_start_date)

select *
from final_cte;
