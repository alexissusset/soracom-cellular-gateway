"""
Script that checks if Ethernet network sharing connection is present
If not, it will add it and reboot the device
"""

import NetworkManager
import uuid
import sys
import requests
from os import getenv

# Check to see if there's already a Ethernet Sharing connection, exit if there is
for conn in NetworkManager.Settings.ListConnections():
    settings = conn.GetSettings()['connection']
    if settings['id'] == 'soracom-eth-ap':
    	print("Ethernet sharing connection already exists, exiting")
    	sys.exit()

# Add Ethernet connection
soracom_connection = {
     'connection': {'id': 'soracom-eth-ap',
                    'type': '802-3-ethernet',
                    'uuid': str(uuid.uuid4())},
     'ipv4': {'method': 'shared'},
     'ipv6': {'method': 'ignore'}
}

NetworkManager.Settings.AddConnection(soracom_connection)

# Connection has been added, reboot node to reset GSM Modem and establish connection
print("Ethernet sharing connection successfully added, rebooting to make sure everything runs smoothly")
url = "{0}/v1/reboot?apikey=".format(getenv('RESIN_SUPERVISOR_ADDRESS')) + "{0}".format(getenv('RESIN_SUPERVISOR_API_KEY'))
requests.post(url)
