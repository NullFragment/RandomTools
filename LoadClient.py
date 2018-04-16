"""
Moved from DeleteDuplicatesFromLibray file into this one as a function.
"""

from gmusicapi import Mobileclient
from getpass import getpass


def load_client():
    """
    Loads the client for the Google Play Music API
    :return: client reference
    """
    client = Mobileclient()
    logged_in = client.login(input('Username:'), getpass(), Mobileclient.FROM_MAC_ADDRESS)
    return client
