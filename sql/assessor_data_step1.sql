/*
This query creates an updated assessor table with custom R-2 flag and the number of units 
per physical area (used in R-2 flag and included in table output for reference)
*/
DROP TABLE IF EXISTS assessor_int;

CREATE TABLE assessor_int AS
/*
This CTE calculates the number of units on overlapping the same parcel
This makes sure that parcels that correspond to buildings with many units
where the parcels are different get flagged as R-2 (e.g. condo buildings with)
many units
*/
WITH new_units AS (
SELECT 
	CONCAT(lat,'-',long) AS lat_long, 
	SUM(
		CASE WHEN number_of_units = 0 THEN 1
			ELSE number_of_units END) AS total_units_new
/*
Number of units shows up as zero for the suites in condo buildings
Would want more background here from someone in City but for now if zero 
I'm going to assume one unit when 0 which likely overcounts but good enough for now
	*/
FROM assessor_raw
GROUP BY 1),

sffd_units AS (
SELECT DISTINCT parcel_number
FROM 
	fire_inspection_raw 
WHERE inspection_type_description = 'R2 Company Inspection'
)

SELECT b.*, 
n.total_units_new,
2024 - CAST(year_property_built AS INT) AS current_property_age,
CASE WHEN
	n.total_units_new >= 3 
	AND (LOWER(use_definition) = 'multi-family residential'
	OR (LOWER(use_definition) = 'commercial hotel'
			  AND property_class_code_definition LIKE '%SRO')
	OR (LOWER(use_definition) LIKE '%single%'
			AND LOWER(property_class_code_definition) LIKE '%condo%')
			) THEN 1 
			ELSE 0 END AS R2_FLAG,

CASE WHEN sffd.parcel_number IS NOT NULL THEN 1 
	ELSE 0 END AS sffd_r2_flag
/*
I checked the different use and property class fields and the supplemental information on the SF Data
site but could not find a clear cut code for R-2 as defined in the problem statement. If this were
work I would reach out to SMEs and figure out what code (if any) has already been written to define
R-2's or where the definition is located. However, since time was limited here, I used the problem
statement to write my own definition of R-2s using the updated units/parcel area I created in the 
previous step. While a better method likely exists this seems reasonable for now.


I am going to also add the DISTINCT parcels that have "R2 Company Inspection" as an inspection type in the
incidents table.
*/
FROM 
	assessor_raw b
LEFT JOIN
	new_units n
	ON CONCAT(b.lat,'-',b.long) = n.lat_long
LEFT JOIN
	sffd_units sffd
	ON b.parcel_number = sffd.parcel_number


ORDER BY parcel_number;
