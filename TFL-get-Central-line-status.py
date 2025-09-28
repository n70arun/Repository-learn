from IPython.display import display
from IPython.core.display import HTML
import json
import requests
import pandas as pd

def get_json_data(in_api_url):
    # Get the JSON data from the API
    response = requests.get(in_api_url)
    if response.status_code == 200:
        return response.json()
    else:
        print("Error fetching data from API")
        return None
def get_train_data():
    train_details_json = get_json_data("https://api.tfl.gov.uk/Line/central/Arrivals")
    df = pd.DataFrame({
        'destinationName': [station['destinationName'].replace(" Underground", "") for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1'],
        'expectedArrival': [station['expectedArrival'] for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1'],
        'timeToStation': [round(station['timeToStation'] / 60, 2) for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1'],
        'currentLocation': [station['currentLocation'] for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1'],
        'towards': [station['towards'] for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1'],
        'platformName': [station['platformName'] for station in train_details_json if station['stationName'] == 'Redbridge Underground Station' and station['platformName'] == 'Outer Rail - Platform 1']
    })
    display(HTML(df.to_html(index=False)))

def get_running_status():
    train_details_json = get_json_data("https://api.tfl.gov.uk/Line/central/Status")
    v_status = train_details_json[0]['lineStatuses'][0]['statusSeverityDescription']
    return v_status

v_running_status = get_running_status()
print("                                Service Status: " +  v_running_status)
print("=====================================================================================================")
get_train_data()