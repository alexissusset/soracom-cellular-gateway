"""
Script that checks if WiFi network sharing connection is present
If not, it will add it and reboot the device
"""

import NetworkManager
import uuid
import sys
import requests
from os import getenv

# Check to see if there's already a WiFi Sharing connection, exit if there is
for conn in NetworkManager.Settings.ListConnections():
    settings = conn.GetSettings()['connection']
    if settings['id'] == 'soracom-wifi-ap':
    	print("Wifi sharing connection already exists, exiting")
    	sys.exit()

# Add WiFi connection
soracom_connection = {
     '802-11-wireless': {'mode': 'ap',
                         'security': '802-11-wireless-security',
                         'ssid': getenv('WIFI_NETWORK')},
     '802-11-wireless-security': {'auth-alg': 'open',
     							  'key-mgmt': 'wpa-psk',
     							  'psk': getenv('WIFI_PASSWORD')},
     'connection': {'id': 'soracom-wifi-ap',
                    'type': '802-11-wireless',
                    'uuid': str(uuid.uuid4())},
     'ipv4': {'method': 'shared'},
     'ipv6': {'method': 'ignore'}
}

NetworkManager.Settings.AddConnection(soracom_connection)

# Connection has been added, reboot node to reset GSM Modem and establish connection
print("Wifi sharing connection successfully added, rebooting to make sure everything runs smoothly")
url = "{0}/v1/reboot?apikey=".format(getenv('RESIN_SUPERVISOR_ADDRESS')) + "{0}".format(getenv('RESIN_SUPERVISOR_API_KEY'))
requests.post(url)
