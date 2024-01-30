/*
This query creates an final assessor table with logic for binning property ages
This table also drops columns that did not seem like they'd be useful for the purposes of this analysis
*/
DROP TABLE IF EXISTS assessor_prod;

CREATE TABLE assessor_prod AS

SELECT parcel_number, use_definition, property_class_code_definition, year_property_built, number_of_units,
zoning_code, construction_type, lot_code, status_code, assessor_neighborhood, analysis_neighborhood,
assessor_neighborhood_code, total_units_new, current_property_age, r2_flag, sffd_r2_flag,
CASE WHEN current_property_age > 100 THEN '>100'
	 WHEN current_property_age <= 100 AND current_property_age > 75 THEN '75 - 100'
	 WHEN current_property_age <= 75 AND current_property_age > 50 THEN '50 - 75'
	 WHEN current_property_age <= 50 AND current_property_age > 25 THEN '25 - 50'
	 WHEN current_property_age <=25 THEN '<25' 
	 ELSE 'Unknown' END AS property_age_bin,
CONCAT(lat,'-',long) AS property_location
FROM assessor_int;

