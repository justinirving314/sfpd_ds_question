from sodapy import Socrata
import pandas as pd
import geopandas as gpd
from shapely.geometry import shape

def pull_opensf_data(site, 
                     endpoint, 
                     app_token, 
                     api_key_id, 
                     api_secret_key,
                     pulltype,
                     filters = None):
    """
        Arguments: 
            site: sf data website
            app_token: app_token created during set-up. 
            api_key_id: api key id created during set-up
            api_secret_key: secret api key created during set-up

        Results:
            all_records: a pandas dataframe of all records returned by the API pulls

    """
    #set limit and offset and create empty dataframe
    all_records = pd.DataFrame()
    limit = 40000
    offset = 0

    # Example authenticated client (needed for non-public datasets):
    client = Socrata(site,
                     app_token,
                     username=api_key_id,
                     password=api_secret_key)

    while True:
        results = client.get(endpoint, limit = limit, offset = offset, where=filters)
        
        #If there are no results leave the loop
        if not results:
            break

        #If results exist convert to dataframe and concat with existing running total dataframe
        results_df = pd.DataFrame.from_records(results)
        all_records = pd.concat([all_records, results_df], ignore_index=True)

        #Added an input in case we just want one sample of data instead of whole set
        if pulltype == 'test':
            break

        #Add the limit amount to the offset to keep cycling through the data
        offset += limit


    # Convert to pandas DataFrame
    
    
    return all_records


def extract_coordinates(df, key_col, col_name):

    all_incident = []
    all_long = []
    all_lat = []
    for index, row in df.iterrows():
        cur_point = row[col_name]
        try:
            cur_incident = row[key_col]
            cur_long = row[col_name]['coordinates'][0]
            cur_lat = row[col_name]['coordinates'][1]
            all_incident.append(cur_incident)
            all_long.append(cur_long)
            all_lat.append(cur_lat)
        except Exception as e:
            #continue
            continue 
        
    new_coor = pd.DataFrame({key_col:all_incident, 'lat':all_lat,'long':all_long})
    merged_df = pd.merge(df, new_coor, on=key_col, how='left')
    merged_df.drop(columns=[col_name], inplace=True)

    return merged_df

def shape_extract(x):
    try:
        # Code that may raise an exception
        return shape(x)
    except Exception as e:
        return None
