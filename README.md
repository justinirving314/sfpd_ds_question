# San Francisco Police Department Data Practice Problem
## Purpose
The purpose of this analysis is to understand if R-2 properties that could be considered "high-risk" can be identified using the available data and priotiized in the inspections.
R-2 properties are categorized as certain types of residential units, multi-family units, and hotels with greater than 3 units per parcel.
## Data Ingestion and Cleaning
Data is pulled using the Socrata API using the endpoints for the different datasources listed in the problem statement. There are various other
data sources available which could be useful in this analysis and may be added in the future.

After the data is pulled using the API's in Python, it is uploaded to a local Postgres database for additional cleaning, joining, feature engineering,
and transformations.

The production data is then used as the source for the final analysis which is conducted in a Jupyter notebook using Python.
