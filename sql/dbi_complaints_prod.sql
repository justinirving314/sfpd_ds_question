/*
If time permitted, I would do addition NLP on the complaint_description field.
I am going to look for specific keywords related to electrical, fire, and safety as a simple REGEX
method of flagging certain complaints.

We may want to consider bringing any active DBI complaints into the fire_inspection_prod table and
fire_incidents_prod table. 

One of our goals should be to bring these data sets together so DBI inspections and Fire Inspections
are prioritized when there's an active complain in the other system and vice versa. 
It might be beneficial to prioritize fire inspections when a complaint has to do with fire hazard.

Also, the complaint data could be improved with the webform having selectors instead of just free
text. NLP could improve the use of this, but multi-select for complaint type would be good as well.

*/


/*
The DBI inspections data set seems to include some routine inspections but mostly includes complaints. 
Unclear if the R-2 routine inspections are all covered here or not but we will take a look later.


*/

DROP TABLE IF EXISTS dbi_inspections_prod;

CREATE TABLE dbi_inspections_prod AS

WITH dbi_complaints_cte AS (
SELECT r.complaint_number, r.date_filed, r.date_abated, r.parcel_number, r.assigned_division, r.nov_type, 
CASE WHEN LOWER(complaint_description) LIKE '%electric%' THEN 1 ELSE 0 END AS electrical_flag,
CASE WHEN LOWER(complaint_description) LIKE '%safety%' THEN 1 ELSE 0 END AS safety_flag,
CASE WHEN LOWER(complaint_description) LIKE '%illegal%' THEN 1 ELSE 0 END AS nopermit_flag, --could improve this one a bit
CASE WHEN LOWER(complaint_description) LIKE '%hazard%' THEN 1 ELSE 0 END AS hazard_flag,
CASE WHEN LOWER(complaint_description) LIKE '%fire%' OR
	 LOWER(complaint_description) LIKE '%smoke%' THEN 1 ELSE 0 END AS fire_flag,
ap.r2_flag, ap.sffd_r2_flag, ap.use_definition, ap.property_class_code_definition, ap.number_of_units, ap.zoning_code, ap.construction_type, 
ap.status_code, ap.current_property_age, ap.property_age_bin
FROM dbi_inspections_raw r
LEFT JOIN
	assessor_prod ap
	ON r.parcel_number = ap.parcel_number
),

/*
Remove line items from violations and just flag the different violation types.
Would be good to have more structured data on hazard type or need to do more NLP on text fields.
*/

dbi_violations_cte as (
SELECT parcel_number, complaint_number, date_filed, status,
COUNT(DISTINCT CASE WHEN nov_category_description IN ('smoke detection section','fire section') THEN complaint_number ELSE NULL END) AS fire_hazard_flag,
COUNT(DISTINCT CASE WHEN nov_category_description IN ('building section', 'interior surfaces section') THEN complaint_number ELSE NULL END) AS bldg_hazard_flag,
COUNT(DISTINCT CASE WHEN nov_category_description IN ('plumbing and electrical section') THEN complaint_number ELSE NULL END) AS plum_elec_hazard_flag,
COUNT(DISTINCT CASE WHEN nov_category_description IN ('hco', 'other section','sanitation section','lead section') THEN complaint_number ELSE NULL END) AS other_hazard_flag
FROM dbi_violations_raw
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4),

dbi_inspections_cte AS (
SELECT DISTINCT co.complaint_number, co.date_filed, co.date_abated, co.parcel_number, co.assigned_division, co.nov_type, 
co.electrical_flag,co.safety_flag,co.nopermit_flag, co.hazard_flag,co.fire_flag,
LAG(co.date_filed) OVER(PARTITION BY co.parcel_number ORDER BY co.date_filed ASC) AS last_inspection_date,
CASE WHEN v.complaint_number IS NOT NULL THEN 1 ELSE 0 END AS violation_flag,
v.date_filed AS violation_date, v.status, v.fire_hazard_flag,v.bldg_hazard_flag,v.plum_elec_hazard_flag,v.other_hazard_flag,
co.r2_flag, co.sffd_r2_flag, co.use_definition, co.property_class_code_definition, co.number_of_units, co.zoning_code, co.construction_type, 
co.status_code, co.current_property_age, co.property_age_bin
FROM dbi_complaints_cte co
LEFT JOIN
	dbi_violations_cte v
	ON co.complaint_number = v.complaint_number
ORDER BY co.complaint_number, co.date_filed),

final_cte AS (
SELECT DISTINCT 
dbi.complaint_number, dbi.date_filed, dbi.date_abated, dbi.parcel_number, dbi.assigned_division, 
dbi.nov_type, dbi.electrical_flag,dbi.safety_flag,dbi.nopermit_flag, dbi.hazard_flag,
dbi.fire_flag,dbi.last_inspection_date,dbi.violation_flag,
dbi.violation_date, dbi.status, dbi.fire_hazard_flag,dbi.bldg_hazard_flag,
dbi.plum_elec_hazard_flag,dbi.other_hazard_flag,dbi.r2_flag, dbi.sffd_r2_flag, dbi.use_definition, 
dbi.property_class_code_definition, dbi.number_of_units, dbi.zoning_code, dbi.construction_type, 
dbi.status_code, dbi.current_property_age, dbi.property_age_bin, 
MAX(fi.violation_flag) AS sffd_violation_flag
FROM dbi_inspections_cte dbi
LEFT JOIN -- Connect SFFD violations that fall between successive HIS violations as another flag
	(SELECT * 
	FROM fire_inspections_prod) fi
	ON fi.parcel_number = dbi.parcel_number
	AND dbi.date_filed >= fi.inspection_start_date
	AND dbi.last_inspection_date <= fi.inspection_start_date
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
ORDER BY 29 DESC)

SELECT *
FROM final_cte 

