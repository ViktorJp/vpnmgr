#!/bin/sh

#########################################################
##                                                     ##
##  _ __ __   __ _ __   _ __   _ __ ___    __ _  _ __  ##
## | '_ \\ \ / /| '_ \ | '_ \ | '_ ` _ \  / _` || '__| ##
## | | | |\ V / | |_) || | | || | | | | || (_| || |    ##
## |_| |_| \_/  | .__/ |_| |_||_| |_| |_| \__, ||_|    ##
##              | |                        __/ |       ##
##              |_|                       |___/        ##
##                                                     ##
##         https://github.com/jackyaz/nvpnmgr          ##
##                                                     ##
#########################################################


### Start of script variables ###
readonly SCRIPT_NAME="nvpnmgr"
readonly SCRIPT_VERSION="v0.0.1"
readonly SCRIPT_BRANCH="master"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/""$SCRIPT_NAME""/""$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

# Load standard variables and helper script
#shellcheck disable=SC1091
. /usr/sbin/helper.sh

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	fi
}

Firmware_Version_Check(){
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]; then
			Print_Output "true" "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output "true" "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			if [ -z "$1" ]; then
				exit 1
			else
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}

Set_Version_Custom_Settings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "nvpnmgr_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$SCRIPT_VERSION" != "$(grep "nvpnmgr_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/nvpnmgr_version_local.*/nvpnmgr_version_local $SCRIPT_VERSION/" "$SETTINGSFILE"
					fi
				else
					echo "nvpnmgr_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
				fi
			else
				echo "nvpnmgr_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "nvpnmgr_version_server" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "nvpnmgr_version_server" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/nvpnmgr_version_server.*/nvpnmgr_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "nvpnmgr_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "nvpnmgr_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

Update_Check(){
	doupdate="false"
	localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings "server" "$serverver"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]; then
			doupdate="md5"
			Set_Version_Custom_Settings "server" "$serverver-hotfix"
		fi
	fi
	echo "$doupdate,$localver,$serverver"
}

Update_Version(){
	if [ -z "$1" ] || [ "$1" = "unattended" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output "true" "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output "true" "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File "shared-jy.tar.gz"
		
		if [ "$isupdate" != "false" ]; then
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			if [ -z "$1" ]; then
				exec "$0" "setversion"
			elif [ "$1" = "unattended" ]; then
				exec "$0" "setversion" "unattended"
			fi
			exit 0
		else
			Print_Output "true" "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output "true" "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File "shared-jy.tar.gz"
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
		chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0" "setversion"
		elif [ "$2" = "unattended" ]; then
			exec "$0" "setversion" "unattended"
		fi
		exit 0
	fi
}

Update_File(){
	if [ "$1" = "shared-jy.tar.gz" ]; then
		if [ ! -f "$SHARED_DIR/$1.md5" ]; then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output "true" "New version of $1 downloaded" "$PASS"
			fi
		fi
	else
		return 1
	fi
}

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
}

Create_Symlinks(){
	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

# use to create content of vJSON variable
getRecommended(){
	curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$VPNTYPE&filters\[servers_technologies\]\[identifier\]=${VPNPROT}&limit=1" || errorcheck
}

# use to create content of OVPN_IP variable
getIP(){
	echo "$1" | jq -e '.[].station // empty' | tr -d '"'
}

# use to create content of OVPN_HOSTNAME variable
getHostname(){
	echo "$1" | jq -e '.[].hostname // empty' | tr -d '"'
}

# use to create content of OVPNFILE variable
getOVPNFilename(){
	echo "$1.$2.ovpn"
}

# use to create content of OVPN_DETAIL variable
getOVPNcontents(){
	curl -s "https://downloads.nordcdn.com/configs/files/ovpn_$2/servers/$1" || errorcheck
}

# use to create content of CLIENT_CA variable
getClientCA(){
	echo "$1" | awk '/<ca>/{flag=1;next}/<\/ca>/{flag=0}flag' | sed '/^#/ d'
}

# use to create content of CRT_CLIENT_STATIC variable
getClientCRT(){
	echo "$1" | awk '/<tls-auth>/{flag=1;next}/<\/tls-auth>/{flag=0}flag' | sed '/^#/ d'
}

# use to create content of EXISTING_NAME variable
getConnName(){
	nvram get vpn_client"$1"_desc
}

# EXISTING_NAME check - it must contain "NordVPN"
checkConnName(){
	EXISTING_NAME="$(getConnName)"
	STR_COMPARE="NordVPN"
	if [ "$EXISTING_NAME" != "Client $1" ]; then
		if echo "$EXISTING_NAME" | grep -v "$STR_COMPARE" >/dev/null 2>&1; then
			logger -st "$SCRIPT_NAME addon" "decription must contain NordVPN (VPNClient$1)..."
			errorcheck
		fi
	fi
}

# use to create content of EXISTING_IP variable
getServerIP(){
	nvram get vpn_client"$1"_addr
}

# use to create content of CONNECTSTATE variable - set to 2 if the VPN is connected
getConnectState(){
	nvram get vpn_client"$1"_state
}

# configure VPN
setVPN(){
	VPN_NO="$1"
	echo "updating VPN Client connection $VPN_NO now..."
	
	vJSON="$(getRecommended)"
	OVPN_IP="$(getIP "$vJSON")"
	OVPN_HOSTNAME="$(getHostname "$vJSON")"
	OVPNFILE="$(getOVPNFilename "$OVPN_HOSTNAME" "$VPNPROT_SHORT")"
	OVPN_DETAIL="$(getOVPNcontents "$OVPNFILE" "$VPNPROT_SHORT")"
	CLIENT_CA="$(getClientCA "$OVPN_DETAIL")"
	CRT_CLIENT_STATIC="$(getClientCRT "$OVPN_DETAIL")"
	EXISTING_NAME="$(getConnName "$VPN_NO")"
	EXISTING_IP="$(getServerIP "$VPN_NO")"
	CONNECTSTATE="$(getConnectState "$VPN_NO")"
	
	[ -z "$OVPN_IP" ] || [ -z "$OVPN_HOSTNAME" ] || [ -z "$CLIENT_CA" ] || [ -z "$CRT_CLIENT_STATIC" ] || [ -z "$CONNECTSTATE" ] && errorcheck
	# check that new VPN server IP is different
	if [ "$OVPN_IP" != "$EXISTING_IP" ]; then
		echo "changing VPN Client connection $VPN_NO to $OVPN_HOSTNAME"
		nvram set vpn_client"$VPN_NO"_addr="$OVPN_IP"
		nvram set vpn_client"$VPN_NO"_desc="$OVPN_HOSTNAME"
		echo "$CLIENT_CA" > /jffs/openvpn/vpn_crt_client"$VPN_NO"_ca
		echo "$CRT_CLIENT_STATIC" > /jffs/openvpn/vpn_crt_client"$VPN_NO"_static
		nvram commit
		# restart if connected - 2 is "connected"
		if [ "$CONNECTSTATE" = "2" ]; then
			service stop_vpnclient"$VPN_NO"
			sleep 3
			service start_vpnclient"$VPN_NO"
		fi
		echo "complete"
	else
		echo "recommended server for VPN Client connection $VPN_NO is already the recommended server - $OVPN_HOSTNAME"
	fi
}

# check for entries, connection state and schedule entry
listEntries(){
	echo "VPN Client List:"
	# from 1 to 5
	for i in 1 2 3 4 5; do
		VPN_CLIENTDESC="$(nvram get vpn_client"$i"_desc | grep NordVPN)"
		if [ -n "$VPN_CLIENTDESC" ]; then
			CONNECTSTATE=""
			SCHEDULESTATE=""
			if [ "$(getConnectState "$i")" = "2" ]; then
				CONNECTSTATE="Active"
			else
				CONNECTSTATE="Inactive"
			fi
			if ! cru l | grep "#$SCRIPT_NAME$i" >/dev/null 2>&1; then
				SCHEDULESTATE="Unscheduled"
			else
				SCHEDULESTATE="Scheduled"
			fi
			echo "$i. $VPN_CLIENTDESC ($CONNECTSTATE and $SCHEDULESTATE)"
		else
			echo "$i. No NordVPN entry found"
		fi
	done
}

# getCRONentry(){
# 	cru l | grep "$SCRIPT_NAME$1" | sed 's/ sh.*//'
# 	[ $? -ne 0 ] && echo "Not found"
# }
#
# setCRONentry(){
# 	echo "Scheduling VPN Client connection $VPN_NO updating..."
# 	[ -z "$VPN_NO" ] || [ -z "$VPNPROT" ] || [ -z "$VPNTYPE" ] && errorcheck
# 	[ -z "$CRU_MINUTE" ] || [ -z "$CRU_HOUR" ] || [ -z "$CRU_DAYNUMBERS" ] && errorcheck
# 	# add new cru entry
# 	if cru l | grep "${SCRIPT_NAME}${VPN_NO}" >/dev/null 2>&1; then
# 		# replace existing
# 		cru d ${SCRIPT_NAME}${VPN_NO}
# 		cru a ${SCRIPT_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh $SCRIPT_REPO/$SCRIPT_NAME setcron ${VPN_NO} ${VPNPROT} ${VPNTYPE}"
# 	else
# 		# or add new if not exist
# 		cru a ${SCRIPT_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh $SCRIPT_REPO/$SCRIPT_NAME setcron ${VPN_NO} ${VPNPROT} ${VPNTYPE}"
# 	fi
# 	# add persistent cru entry to /jffs/scripts/services-start for restarts
# 	if cat /jffs/scripts/services-start | grep "${SCRIPT_NAME}${VPN_NO}" >/dev/null 2>&1; then
# 		# remove and replace existing
# 		sed -i "/${SCRIPT_NAME}${VPN_NO}/d" /jffs/scripts/services-start
# 		echo "cru a ${SCRIPT_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh $SCRIPT_REPO/$SCRIPT_NAME setcron ${VPN_NO} ${VPNPROT} ${VPNTYPE}\"" >> /jffs/scripts/services-start
# 	else
# 		# or add new if not exist
# 		echo "cru a ${SCRIPT_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh $SCRIPT_REPO/$SCRIPT_NAME setcron ${VPN_NO} ${VPNPROT} ${VPNTYPE}\"" >> /jffs/scripts/services-start
# 	fi
# 	am_settings_set nvpn_cron${VPN_NO} 1
# 	am_settings_set nvpn_cronstr${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS}"
# 	echo "complete"
# }
#
# delCRONentry(){
# 	echo "removing VPN Client connection $VPN_NO schedule entry..."
# 	[ -z "$VPN_NO" ] || [ -z "$SCRIPT_NAME" ] && errorcheck
# 	# remove cru entry
# 	if cru l | grep "${SCRIPT_NAME}${VPN_NO}" >/dev/null 2>&1; then
# 		# remove existing
# 		cru d ${SCRIPT_NAME}${VPN_NO}
# 	fi
# 	# remove persistent cru entry from /jffs/scripts/services-start for restarts
# 	if cat /jffs/scripts/services-start | grep "${SCRIPT_NAME}${VPN_NO}" >/dev/null 2>&1; then
# 		# remove and replace existing
# 		sed -i "/${SCRIPT_NAME}${VPN_NO}/d" /jffs/scripts/services-start
# 	fi
# 	am_settings_set nvpn_cron${VPN_NO}
# 	am_settings_set nvpn_cronstr${VPN_NO}
# 	echo "complete"
# }

UpdateVPN(){
	VPN_NO="$1"
	checkConnName "$VPN_NO"
	logger -st "$SCRIPT_NAME addon" "Updating to recommended NordVPN server (VPNClient$VPN_NO)..."
	setVPN "$VPN_NO"
	logger -st "$SCRIPT_NAME addon" "Update complete (VPNClient$VPN_NO - server $OVPN_HOSTNAME - type $VPNTYPE)"
}

# ScheduleVPN(){
# 	VPN_NO="$1"
# 	checkConnName "$VPN_NO"
# 	CRU_MINUTE="$3"
# 	CRU_HOUR="$4"
# 	CRU_DAYNUMBERS="$5"
#
# 	# default options 5:25am on Mondays and Thursdays
# 	[ -z "$CRU_MINUTE" ] && CRU_MINUTE=25
# 	[ -z "$CRU_HOUR" ] && CRU_HOUR=5
# 	[ -z "$CRU_DAYNUMBERS" ] && CRU_DAYNUMBERS=1,4
#
# 	logger -st "$SCRIPT_NAME addon" "Configuring scheduled update to recommended NordVPN server (VPNClient$VPN_NO)..."
# 	setCRONentry
# 	logger -st "$SCRIPT_NAME addon" "Scheduling complete (VPNClient$VPN_NO - type $VPNTYPE)"
# }
#
# CancelVPN(){
# 	checkConnName
# 	[ -z "$1" ] && errorcheck
# 	logger -st "$SCRIPT_NAME addon" "Removing scheduled update to recommended NordVPN server (VPNClient$1)..."
# 	delCRONentry
# 	logger -st "$SCRIPT_NAME addon" "Removal of schedule complete (VPNClient$1)"
# }

Shortcut_nvpnmgr(){
	case $1 in
		create)
			if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]; then
				ln -s /jffs/scripts/"$SCRIPT_NAME" /opt/bin
				chmod 0755 /opt/bin/"$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f /opt/bin/"$SCRIPT_NAME"
			fi
		;;
	esac
}

SetVPNClient(){
	printf "\\n\\e[1mPlease select a VPN client connection (x to cancel): \\e[0m"
	read -r "VPN_NO"
	if [ "$VPN_NO" = "x" ]; then
		printf "previous operation cancelled"
	elif [ -z "$VPN_NO" ]; then
		printf "you must specify a valid VPN client"
	fi
	# validate VPN_NO here (must be a number from 1 to 5 have "NordVPN" in the name)
}

SetVPNProtocol(){
	printf "\\n\\e[1mPlease select a VPN protocol (x to cancel): \\e[0m\\n"
	printf "   1. UDP\\n"
	printf "   2. TCP\\n"
	read -r "menu"

	while true; do
		case "$menu" in
			1)
				VPNPROT="openvpn_udp"
				VPNPROT_SHORT="$(echo "$VPNPROT" | cut -f2 -d'_')"
				break
			;;
			2)
				VPNPROT="openvpn_tcp"
				VPNPROT_SHORT="$(echo "$VPNPROT" | cut -f2 -d'_')"
				break
			;;
			x)
				printf "previous operation cancelled"
				break
			;;
			*)
				printf "you must choose a protocol option"
				break
			;;
		esac
	done
	if [ -z "$VPNPROT" ]; then
		printf "you must choose a protocol option"
	fi
}

SetVPNType(){
	printf "\\n\\e[1mPlease select a VPN Type (x to cancel): \\e[0m\\n"
	printf "   1. Standard VPN (default)\\n"
	printf "   2. Double VPN\\n"
	printf "   3. P2P\\n"
	read -r "menu"
	
	while true; do
		case "$menu" in
			1)
				VPNTYPE="legacy_standard"
				break
			;;
			2)
				VPNTYPE="legacy_double_vpn"
				break
			;;
			3)
				VPNTYPE="legacy_p2p"
				break
			;;
			x)
				printf "previous operation cancelled"
				break
			;;
			*)
				VPNTYPE="legacy_standard"
				break
			;;
		esac
	done
	if [ -z "$VPNTYPE" ]; then
		printf "type not set or previous operation cancelled"
	fi
}

SetDays(){
	printf "\\n\\e[1mPlease choose update day/s (x to cancel - blank for every day): \\e[0m"
	read -r "CRU_DAYNUMBERS"
	if [ "$CRU_DAYNUMBERS" = "x" ]; then
		printf "previous operation cancelled"
	elif [ -z "$CRU_DAYNUMBERS" ]; then
		CRU_DAYNUMBERS="*"
		printf "\\n\\e[1mSet to every day\\e[0m\\n"
	fi
	# validate DAYS here (must be a number from 0 to 7 or these numbers separated by comma/s)
}

SetHours(){
	printf "\\n\\e[1mPlease choose update hour/s (x to cancel): \\e[0m"
	read -r "CRU_HOUR"
	if [ "$CRU_HOUR" = "x" ]; then
		printf "previous operation cancelled"
	elif [ -z "$CRU_HOUR" ]; then
		printf "you must specify a valid hour or hours separated by comma"
	fi
	# validate HOURS here (must be a number from 0 to 23)
}

SetMinutes(){
	printf "\\n\\e[1mPlease choose update minute/s (x to cancel): \\e[0m"
	read -r "CRU_MINUTE"
	if [ "$CRU_MINUTE" = "x" ]; then
		printf "previous operation cancelled"
	elif [ -z "$CRU_MINUTE" ]; then
		printf "you must specify a valid minute or minutes separated by comma"
	fi
	# validate MINUTES here (must be a number from 0 to 59)
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r "key"
		case "$key" in
			*)
				break
			;;
		esac
	done
	return 0
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	printf "\\e[1m##                                                     ##\\e[0m\\n"
	printf "\\e[1m##  _ __ __   __ _ __   _ __   _ __ ___    __ _  _ __  ##\\e[0m\\n"
	printf "\\e[1m## | '_  \\ \ / /| '_ \ | '_ \ | '_   _ \  / _  || '__| ##\\e[0m\\n"
	printf "\\e[1m## | | | |\ V / | |_) || | | || | | | | || (_| || |    ##\\e[0m\\n"
	printf "\\e[1m## |_| |_| \_/  | .__/ |_| |_||_| |_| |_| \__, ||_|    ##\\e[0m\\n"
	printf "\\e[1m##              | |                        __/ |       ##\\e[0m\\n"
	printf "\\e[1m##              |_|                       |___/        ##\\e[0m\\n"
	printf "\\e[1m##                                                     ##\\e[0m\\n"
	printf "\\e[1m##                  %s on %-9s                ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                     ##\\e[0m\\n"
	printf "\\e[1m##         https://github.com/jackyaz/nvpnmgr          ##\\e[0m\\n"
	printf "\\e[1m##                                                     ##\\e[0m\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    Check for available NordVPN VPN client configurations\\n"
	printf "2.    Update a VPN client configuration now\\n"
	printf "3.    Schedule a VPN client configuration update\\n"
	printf "d.    Delete a scheduled VPN client configuration update\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m##########################################################\\e[0m\\n"
	printf "\\n"
	
	VPN_NO=
	VPNPROT=
	VPNTYPE=
	CRU_HOUR=
	CRU_DAYNUMBERS=
	CRU_MINUTE=
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock "menu"; then
					ListMenu
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				if Check_Lock "menu"; then
					UpdateNowMenu
				fi
				PressEnter
				break
			;;
			3)
				printf "\\n"
				if Check_Lock "menu"; then
					ScheduleUpdateMenu
				fi
				PressEnter
				break
			;;
			4)
				printf "\\n"
				if Check_Lock "menu"; then
					DeleteScheduleMenu
				fi
				PressEnter
				break
			;;
			u)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_ForceUpdate
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
					read -r "confirm"
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	ScriptHeader
	MainMenu
}

UpdateNowMenuHeader(){
	printf "   Choose options as follows:\\n"
	printf "     VPN client [1-5]\\n"
	printf "     protocol to use (pick from list)\\n"
	printf "     type to use (pick from list)\\n"
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
}

# ScheduleUpdateMenuHeader(){
# 	printf "   Choose options as follows:\\n"
# 	printf "     VPN client [1-5]\\n"
# 	printf "     protocol to use (pick from list)\\n"
# 	printf "     type to use (pick from list)\\n"
# 	printf "     day/s to update [0-7]\\n"
# 	printf "     hour/s to update [0-23]\\n"
# 	printf "     minute/s to update [0-59]\\n"
# 	printf "\\n"
# 	printf "\\e[1m############################################################\\e[0m\\n"
# }
#
# DeleteScheduleMenuHeader(){
# 	printf "   Choose schedule entry to delete:\\n"
# 	printf "     VPN client [1-5]\\n"
# 	printf "\\n"
# 	printf "\\e[1m############################################################\\e[0m\\n"
# }

ListMenu(){
	ScriptHeader
	
	listEntries
	printf "\\n"
	PressEnter
}

UpdateNowMenu(){
	ScriptHeader
	UpdateNowMenuHeader
	
	SetVPNClient
	SetVPNProtocol
	SetVPNType
	
	UpdateVPN "$VPN_NO" "$VPNPROT" "$VPNTYPE"
	PressEnter
	
	printf "Update VPN complete (%s)" "$VPNTYPE"
}

# ScheduleUpdateMenu(){
# 	ScriptHeader
# 	ScheduleUpdateMenuHeader
#
# 	SetVPNClient
# 	SetVPNProtocol
# 	SetVPNType
# 	SetDays
# 	SetHours
# 	SetMinutes
#
# 	ScheduleVPN "$VPN_NO" "$VPNPROT" "$CRU_MINUTE" "$CRU_HOUR" "$CRU_DAYNUMBERS" "$VPNTYPE"
# 	PressEnter
#
# 	printf "Scheduled VPN update complete ($VPNTYPE)"
# }
#
# DeleteScheduleMenu(){
# 	ScriptHeader
# 	DeleteScheduleMenuHeader
#
# 	SetVPNClient
#
# 	CancelVPN "$VPN_NO"
# 	PressEnter
#
# 	printf "Delete VPN schedule complete"
# }

Check_Requirements(){
	CHECKSFAILED="false"
	
	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output "true" "Custom JFFS Scripts enabled" "$WARN"
	fi
	
	if [ ! -f "/opt/bin/opkg" ]; then
		Print_Output "true" "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if ! Firmware_Version_Check "install" ; then
		Print_Output "true" "Unsupported firmware version detected" "$ERR"
		Print_Output "true" "$SCRIPT_NAME requires Merlin 384.15/384.13_4 or Fork 43E5 (or later)" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		Print_Output "true" "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install jq
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output "true" "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by h0me5k1n and JackYaz"
	sleep 1
	
	Print_Output "true" "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output "true" "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	Create_Dirs
	Create_Symlinks
	
	Update_File "shared-jy.tar.gz"
	
	Shortcut_nvpnmgr create
	Clear_Lock
}

Menu_Update(){
	Update_Version
	Clear_Lock
}

Menu_ForceUpdate(){
	Update_Version force
	Clear_Lock
}

Menu_Uninstall(){
	Print_Output "true" "Removing $SCRIPT_NAME..." "$PASS"
	
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -rf "$SCRIPT_DIR" 2>/dev/null
	
	Shortcut_nvpnmgr delete
	
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

if [ -z "$1" ]; then
	Create_Dirs
	Set_Version_Custom_Settings "local"
	Create_Symlinks
	Shortcut_nvpnmgr create
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	#schedulevpn)
	#	ScheduleVPN "$VPN_NO" "$VPNPROT" "$CRU_MINUTE" "$CRU_HOUR" "$CRU_DAYNUMBERS" "$VPNTYPE"
	#;;
	develop)
		Check_Lock
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="develop"/' "/jffs/scripts/$SCRIPT_NAME"
		Clear_Lock
		exec "$0" "update"
		exit 0
	;;
	stable)
		Check_Lock
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="master"/' "/jffs/scripts/$SCRIPT_NAME"
		Clear_Lock
		exec "$0" "update"
		exit 0
	;;
	update)
		Check_Lock
		Update_Version "unattended"
		Clear_Lock
		exit 0
	;;
	forceupdate)
		Check_Lock
		Update_Version "force" "unattended"
		Clear_Lock
		exit 0
	;;
	setversion)
		Check_Lock
		Set_Version_Custom_Settings "local"
		Set_Version_Custom_Settings "server" "$SCRIPT_VERSION"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	checkupdate)
		Check_Lock
		#shellcheck disable=SC2034
		updatecheckresult="$(Update_Check)"
		Clear_Lock
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	*)
		echo "Command not recognised, please try again"
		exit 1
	;;
esac
