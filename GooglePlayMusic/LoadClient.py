"""
Moved from DeleteDuplicatesFromLibray file into this one as a function.
"""
from gmusicapi import Mobileclient
from gmusicapi.exceptions import InvalidDeviceId
import os
import appdirs

def load_client():
    """
    Loads the client for the Google Play Music API
    :return: client reference
    """
    client = Mobileclient()
    if(not os.path.exists(client.OAUTH_FILEPATH)):
        credentials = client.perform_oauth()
        
    ## Yes this is bad.
    ## No, I don't feel bad.
    try:
        client.oauth_login("")
    except InvalidDeviceId as e:
            client.oauth_login(e.valid_device_ids[0])
    return client
