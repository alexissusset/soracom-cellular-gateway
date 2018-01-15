# Resin.io based internet connection sharing code

Allows a raspberry pi to, for example, share a connection using a Cellular dongle with Soracom SIM card  
  
# Configuration  
1. In order to share a Cellular connection, you have the following two options:
    1. Share over Ethernet, simply add the ETH_SHARE=1 variable in resin config and your Ethernet based sharing configuration will be added
    1. Share over WiFi, add WIFI_NETWORK=<network name> and WIFI_PASSWORD=<Wifi WPA2 password> variable in resin config and your WiFi based sharing configuration will be added  
  
# Limitations  
Once a WiFi or Ethernet based connection sharing has been added, it will not be updated