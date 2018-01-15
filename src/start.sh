#!/bin/bash
# Setting DBUS addresss so that we can talk to Modem Manager
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/host/run/dbus/system_bus_socket"

# Setup logging function
function log {
	if [[ "${CONSOLE_LOGGING}" == "1" ]]; then
		echo "[$(date --rfc-3339=seconds)]: $*" >>/data/soracom.log;
		echo "$*";
	else
    	echo "[$(date --rfc-3339=seconds)]: $*" >>/data/soracom.log;
    fi
}

# Handling SIGINT or SIGTERM
exit_script() {
    log "shutting down start script"
	if [[ -n "${PROXY+x}" ]]; then
		log `/etc/init.d/squid3 stop`
	fi
    trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
}

# Check if CONSOLE_LOGGING is set, otherwise indicate that logging is going to /data/soracom.log
if [[ "${CONSOLE_LOGGING}" == "1" ]]; then
	echo "CONSOLE_LOGGING is set to 1, logging to console and /data/soracom.log"
else
	echo "CONSOLE_LOGGING isn't set to 1, logging to /data/soracom.log"
fi

# Start Linux watchdog
log "`service watchdog start`"

# Add Soracom Network Manager connection
log `python soracom.py`

if [[ -n "${WIFI_NETWORK+x}" && -n "${WIFI_PASSWORD+x}" ]]; then
	# Add Wifi AP connection
	log `python wifishare.py`
fi

if [[ -n "${ETH_SHARE+x}" ]]; then
	# Add Ethernet Sharing connection
	log `python ethshare.py`
fi

# Start Squid Transparent proxy if $PROXY variable is set
if [[ -n "${PROXY+x}" ]]; then
	# Start Squid Proxy
	log `/etc/init.d/squid3 start`
	# Make sure traffic is redirected to Squid
	ls /sys/class/net | grep -q wlan0
	if [[ $? -eq 0 ]]; then
		log `iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 3128`
## Needs Squid SSL cert		log `iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 3128`
	fi
	ls /sys/class/net | grep -q eth0
	if [[ $? -eq 0 ]]; then
		log `iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128`
## Needs Squid SSL cert		log `iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 3128`
	fi

fi

# Makign sure we have a clean exit when receiving SIGINT or SIGTERM
trap exit_script SIGINT SIGTERM

# Run connection check script every 500 seconds
# If Cellular Mode wasn't working, the device will reboot every 15mins until it works
while :
do
	# If a mmcli compatible modem is present, log signal quality
	mmcli -L | grep -q Modem
	if [ $? -eq 0 ]; then
		MODEM_NUMBER=`mmcli -L | grep Modem | head -1 | sed -e 's/\//\ /g' | awk '{print $5}'`
		mmcli -m ${MODEM_NUMBER} | grep state | grep -q connected
		if [ $? -eq 0 ]; then
			# Log signal quality
			if [[ -n "${MODEM_NUMBER+x}" ]]; then
				log "`mmcli -m ${MODEM_NUMBER} | grep 'access tech' | sed -e \"s/'//g\" | sed -e \"s/|//g\" | sed -e \":a;s/^\([[:space:]]*\)[[:space:]]//g\"`"
				log "`mmcli -m ${MODEM_NUMBER} | grep 'operator name' | sed -e \"s/'//g\" | sed -e \"s/|//g\" | sed -e ':a;s/^\([[:space:]]*\)[[:space:]]//g'`"
				log "`mmcli -m ${MODEM_NUMBER} | grep quality | sed -e \"s/'//g\" | awk '{print $2 " " $3 " " $4}'`%"
				log `mmcli -m ${MODEM_NUMBER} --command="AT+CSQ"`
			fi
		fi
	fi
	sleep 500;
	# Rotate log files
	log `logrotate /usr/src/app/logrotate.conf`
	# Check if internet connectivity is working, reboot if it isn't
	log `/usr/src/app/reconnect.sh`
done
