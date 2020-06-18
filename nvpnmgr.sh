#!/bin/sh




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
}

# use to create content of vJSON variable
getRecommended(){
	curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$VPNTYPE&filters\[servers_technologies\]\[identifier\]=${VPNPROT}&limit=1" || errorcheck
}

# use to create content of OVPN_IP variable
getIP(){
	# check vJSON variable contents exist
	[ -z "$vJSON" ] && errorcheck
	echo "$vJSON" | jq -e '.[].station // empty' | tr -d '"'
}

# use to create content of OVPN_HOSTNAME variable
getHostname(){
	[ -z "$vJSON" ] && errorcheck
	echo "$vJSON" | jq -e '.[].hostname // empty' | tr -d '"'
}

# use to create content of OVPNFILE variable
getOVPNFilename(){
	[ -z "$OVPN_HOSTNAME" ] || [ -z "$VPNPROT_SHORT" ] && errorcheck
	echo "$OVPN_HOSTNAME.$VPNPROT_SHORT.ovpn"
}

# use to create content of OVPN_DETAIL variable
getOVPNcontents(){
	[ -z "$OVPNFILE" ] || [ -z "$VPNPROT_SHORT" ] && errorcheck
	curl -s "https://downloads.nordcdn.com/configs/files/ovpn_$VPNPROT_SHORT/servers/$OVPNFILE" || errorcheck
}

# use to create content of CLIENT_CA variable
getClientCA(){
	[ -z "$OVPN_DETAIL" ] && errorcheck
	echo "$OVPN_DETAIL" | awk '/<ca>/{flag=1;next}/<\/ca>/{flag=0}flag' | sed '/^#/ d'
}

# use to create content of CRT_CLIENT_STATIC variable
getClientCRT(){
	[ -z "$OVPN_DETAIL" ] && errorcheck
	echo "$OVPN_DETAIL" | awk '/<tls-auth>/{flag=1;next}/<\/tls-auth>/{flag=0}flag' | sed '/^#/ d'
}

# use to create content of EXISTING_NAME variable
getConnName(){
	[ -z "$VPN_NO" ] && errorcheck
	nvram get vpn_client"$VPN_NO"_desc
}

# EXISTING_NAME check - it must contain "nordvpn"
checkConnName(){
	[ -z "$VPN_NO" ] && errorcheck
	EXISTING_NAME="$(getConnName)"
	STR_COMPARE="nordvpn"
	if [ "$EXISTING_NAME" != "Client $VPN_NO" ]; then
		if echo "$EXISTING_NAME" | grep -v "$STR_COMPARE" >/dev/null 2>&1; then
			logger -st "$MY_ADDON_NAME addon" "decription must contain nordvpn (VPNClient$VPN_NO)..."
			errorcheck
		fi
	fi
}

# use to create content of EXISTING_IP variable
getServerIP(){
	[ -z "$VPN_NO" ] && errorcheck
	nvram get vpn_client"$VPN_NO"_addr
}

# use to create content of CONNECTSTATE variable - set to 2 if the VPN is connected
getConnectState(){
	[ -z "$VPN_NO" ] && errorcheck
	nvram get vpn_client"$VPN_NO"_state
}

# configure VPN
setVPN(){
	echo "updating VPN Client connection $VPN_NO now..."
	
	vJSON="$(getRecommended)"
	OVPN_IP="$(getIP)"
	OVPN_HOSTNAME="$(getHostname)"
	OVPNFILE="$(getOVPNFilename)"
	OVPN_DETAIL="$(getOVPNcontents)"
	CLIENT_CA="$(getClientCA)"
	CRT_CLIENT_STATIC="$(getClientCRT)"
	EXISTING_NAME="$(getConnName)"
	EXISTING_IP="$(getServerIP)"
	CONNECTSTATE="$(getConnectState)"
	
	[ -z "$OVPN_IP" ] || [ -z "$OVPN_HOSTNAME" ] || [ -z "$VPN_NO" ] && errorcheck
	[ -z "$CLIENT_CA" ] || [ -z "$CRT_CLIENT_STATIC" ] && errorcheck
	[ -z "$CONNECTSTATE" ] && errorcheck
	# check that new VPN server IP is different
	if [ "$OVPN_IP" != "$EXISTING_IP" ]; then
		echo "changing VPN Client connection $VPN_NO to $OVPN_HOSTNAME"
		nvram set vpn_client${VPN_NO}_addr=${OVPN_IP}
		nvram set vpn_client${VPN_NO}_desc=${OVPN_HOSTNAME}
		echo "$CLIENT_CA" > /jffs/openvpn/vpn_crt_client${VPN_NO}_ca
		echo "${CRT_CLIENT_STATIC}" > /jffs/openvpn/vpn_crt_client${VPN_NO}_static
		nvram commit
		# restart if connected - 2 is "connected"
		if [ "$CONNECTSTATE" = "2" ]; then
			service stop_vpnclient${VPN_NO}
			sleep 3
			service start_vpnclient${VPN_NO}
		fi
		echo "complete"
	else
		echo "recommended server for VPN Client connection $VPN_NO is already the recommended server - $OVPN_HOSTNAME"
	fi
}

# check for entries, connection state and schedule entry
listEntries(){
	echo "VPN CLient List:"
	# from 1 to 5
	for VPN_NO in 1 2 3 4 5; do
		VPN_CLIENTDESC="$(nvram get vpn_client${VPN_NO}_desc | grep nordvpn)"
		if [ ! -z "$VPN_CLIENTDESC" ]; then
			if [ "$(getConnectState)" = "2" ]; then
				CONNECTSTATE=ACTIVE
			else
				CONNECTSTATE=INACTIVE
			fi
			cru l | grep "#${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1
			if [ $? -ne 0 ]; then
				SCHEDULESTATE=UNSCHEDULED
			else
				SCHEDULESTATE=SCHEDULED
			fi
			echo "$VPN_NO. ${VPN_CLIENTDESC} (${CONNECTSTATE} and ${SCHEDULESTATE})"
		else
			echo "$VPN_NO. no nordvpn entry found"
		fi
	done
}

getCRONentry(){
	[ -z "$VPN_NO" ] || [ -z "$MY_ADDON_NAME" ] && errorcheck
	cru l | grep "${MY_ADDON_NAME}${VPN_NO}" | sed 's/ sh.*//'
	[ $? -ne 0 ] && echo NOTFOUND
}

setCRONentry(){
	echo "scheduling VPN Client connection $VPN_NO updating..."
	[ -z "$VPN_NO" ] || [ -z "$MY_ADDON_NAME" ] || [ -z "$SCRIPTPATH" ] || [ -z "$MY_ADDON_SCRIPT" ] || [ -z "$VPNPROT" ] || [ -z "$VPNTYPE" ] && errorcheck
	[ -z "$CRU_MINUTE" ] || [ -z "$CRU_HOUR" ] || [ -z "$CRU_DAYNUMBERS" ] && errorcheck
	# add new cru entry
	if cru l | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# replace existing
		cru d ${MY_ADDON_NAME}${VPN_NO}
		cru a ${MY_ADDON_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE}"
	else
		# or add new if not exist
		cru a ${MY_ADDON_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE}"
	fi
	# add persistent cru entry to /jffs/scripts/services-start for restarts
	if cat /jffs/scripts/services-start | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# remove and replace existing
		sed -i "/${MY_ADDON_NAME}${VPN_NO}/d" /jffs/scripts/services-start
		echo "cru a ${MY_ADDON_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE}\"" >> /jffs/scripts/services-start
	else
		# or add new if not exist
		echo "cru a ${MY_ADDON_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE}\"" >> /jffs/scripts/services-start
	fi
	am_settings_set nvpn_cron${VPN_NO} 1
	am_settings_set nvpn_cronstr${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS}"
	echo "complete"
}

delCRONentry(){
	echo "removing VPN Client connection $VPN_NO schedule entry..."
	[ -z "$VPN_NO" ] || [ -z "$MY_ADDON_NAME" ] && errorcheck
	# remove cru entry
	if cru l | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# remove existing
		cru d ${MY_ADDON_NAME}${VPN_NO}
	fi
	# remove persistent cru entry from /jffs/scripts/services-start for restarts
	if cat /jffs/scripts/services-start | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# remove and replace existing
		sed -i "/${MY_ADDON_NAME}${VPN_NO}/d" /jffs/scripts/services-start
	fi
	am_settings_set nvpn_cron${VPN_NO}
	am_settings_set nvpn_cronstr${VPN_NO}
	echo "complete"
}

UpdateVPN(){
	checkConnName
	logger -st "$MY_ADDON_NAME addon" "Updating to recommended NORDVPN server (VPNClient$1)..."
	setVPN
	logger -st "$MY_ADDON_NAME addon" "Update complete (VPNClient$1 - server $OVPN_HOSTNAME - type $VPNTYPE)"
}

ScheduleVPN(){
	checkConnName
	CRU_MINUTE=$3
	CRU_HOUR=$4
	CRU_DAYNUMBERS=$5
	
	# default options 5:25am on Mondays and Thursdays
	[ -z "$CRU_MINUTE" ] && CRU_MINUTE=25
	[ -z "$CRU_HOUR" ] && CRU_HOUR=5
	[ -z "$CRU_DAYNUMBERS" ] && CRU_DAYNUMBERS=1,4
	
	logger -st "$MY_ADDON_NAME addon" "Configuring scheduled update to recommended NORDVPN server (VPNClient$VPN_NO)..."
	setCRONentry
	logger -st "$MY_ADDON_NAME addon" "Scheduling complete (VPNClient$VPN_NO - type $VPNTYPE)"
}

CancelVPN(){
	checkConnName
	[ -z "$1" ] && errorcheck
	logger -st "$MY_ADDON_NAME addon" "Removing scheduled update to recommended NORDVPN server (VPNClient$1)..."
	delCRONentry
	logger -st "$MY_ADDON_NAME addon" "Removal of schedule complete (VPNClient$1)"
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

ReturnToMainMenu(){
	PressEnter
	ScriptHeader
	UpdateNowMenuHeader
}

SetVPNClient(){
	printf "\\n\\e[1mPlease select a VPN client connection (x to cancel): \\e[0m"
	read -r "VPN_NO"
	if [ "$VPN_NO" = "x" ]; then
		printf "previous operation cancelled"
		ReturnToMainMenu
	elif [ -z "$VPN_NO" ]; then
		printf "you must specify a valid VPN client"
		ReturnToMainMenu
	fi
	# validate VPN_NO here (must be a number from 1 to 5 have "nordvpn" in the name)
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
				ReturnToMainMenu
				break
			;;
			*)
				printf "you must choose a protocol option"
				ReturnToMainMenu
				break
			;;
		esac
	done
	if [ -z "$VPNPROT" ]; then
		printf "you must choose a protocol option"
		ReturnToMainMenu
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
				ReturnToMainMenu
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
		ReturnToMainMenu
	fi
}

SetDays(){
	printf "\\n\\e[1mPlease choose update day/s (x to cancel - blank for every day): \\e[0m"
	read -r "CRU_DAYNUMBERS"
	if [ "$CRU_DAYNUMBERS" = "x" ]; then
		printf "previous operation cancelled"
		ReturnToMainMenu
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
		ReturnToMainMenu
	elif [ -z "$CRU_HOUR" ]; then
		printf "you must specify a valid hour or hours separated by comma"
		ReturnToMainMenu
	fi
	# validate HOURS here (must be a number from 0 to 23)
}

SetMinutes(){
	printf "\\n\\e[1mPlease choose update minute/s (x to cancel): \\e[0m"
	read -r "CRU_MINUTE"
	if [ "$CRU_MINUTE" = "x" ]; then
		printf "previous operation cancelled"
		ReturnToMainMenu
	elif [ -z "$CRU_MINUTE" ]; then
		printf "you must specify a valid minute or minutes separated by comma"
		ReturnToMainMenu
	fi
	# validate MINUTES here (must be a number from 0 to 59)
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
	printf "\\e[1m##                   $MY_ADDON_NAME Menu                  ##\\e[0m\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "   1. Check for available NordVPN VPN client connections\\n"
	printf "   2. Update a VPN client connection NOW\\n"
	printf "   3. Schedule a VPN client connection update\\n"
	printf "   d. Delete a scheduled VPN client connection update\\n"
	printf "   u. Update $MY_ADDON_NAME\\n"
	printf "   x. Exit $MY_ADDON_NAME menu\\n\\n"
	printf "   z. Uninstall $MY_ADDON_NAME\\n"
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
	
	VPN_NO=
	VPNPROT=
	VPNTYPE=
	CRU_HOUR=
	CRU_DAYNUMBERS=
	CRU_MINUTE=
	
	while true; do
		printf "\\nChoose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				# check for connections
				ListMenu
				break
			;;
			2)
				printf "\\n"
				# configure now
				UpdateNowMenu
				break
			;;
			3)
				printf "\\n"
				# configure schedule
				ScheduleUpdateMenu
				break
			;;
			d)
				printf "\\n"
				# remove schedule
				DeleteScheduleMenu
				break
			;;
			u)
				printf "\\n"
				# update script from github
				"$LOCAL_REPO/install.sh"
				PressEnter
				break
			;;
			x)
				ScriptHeader
				printf "\\n\\e[1mThanks for using $MY_ADDON_NAME!\\e[0m\\n\\n\\n"
				exit 0
			;;
			z)
				printf "\\n\\e[1mAre you sure you want to uninstall $MY_ADDON_NAME (Y to confirm)?\\e[0m "
				read -r "confirm"
				if [ "$confirm" = "Y" ]
				then
					echo "Uninstalling $MY_ADDON_NAME..."
					# remove script
					Addon_Uninstall
					exit 0
				else
					printf "Uninstall of $MY_ADDON_NAME cancelled"
					ReturnToMainMenu
				fi
			;;
			*)
				printf "Please choose a valid option"
				ReturnToMainMenu
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

ScheduleUpdateMenuHeader(){
	printf "   Choose options as follows:\\n"
	printf "     VPN client [1-5]\\n"
	printf "     protocol to use (pick from list)\\n"
	printf "     type to use (pick from list)\\n"
	printf "     day/s to update [0-7]\\n"
	printf "     hour/s to update [0-23]\\n"
	printf "     minute/s to update [0-59]\\n"
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
}

DeleteScheduleMenuHeader(){
	printf "   Choose schedule entry to delete:\\n"
	printf "     VPN client [1-5]\\n"
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
}

ListMenu(){
	ScriptHeader
	
	listEntries
	printf "\\n"
	PressEnter
	
	ReturnToMainMenu
}

UpdateNowMenu(){
	ScriptHeader
	UpdateNowMenuHeader
	
	SetVPNClient
	SetVPNProtocol
	SetVPNType
	
	UpdateVPN "$VPN_NO" "$VPNPROT" "$VPNTYPE"
	PressEnter
	
	printf "Update VPN complete ($VPNTYPE)"
	ReturnToMainMenu
}

ScheduleUpdateMenu(){
	ScriptHeader
	ScheduleUpdateMenuHeader
	
	SetVPNClient
	SetVPNProtocol
	SetVPNType
	SetDays
	SetHours
	SetMinutes
	
	ScheduleVPN "$VPN_NO" "$VPNPROT" "$CRU_MINUTE" "$CRU_HOUR" "$CRU_DAYNUMBERS" "$VPNTYPE"
	PressEnter
	
	printf "Scheduled VPN update complete ($VPNTYPE)"
	ReturnToMainMenu
}

DeleteScheduleMenu(){
	ScriptHeader
	DeleteScheduleMenuHeader
	
	SetVPNClient
	
	CancelVPN "$VPN_NO"
	PressEnter
	
	printf "Delete VPN schedule complete"
	ReturnToMainMenu
}

Addon_Install(){
	# Check this is an Asus Merlin router
	if ! nvram get buildinfo | grep merlin >/dev/null 2>&1; then
		echo "This script is only supported on an Asus Router running Merlin firmware!"
		exit 5
	fi
	
	# Does the firmware support addons?
	if ! nvram get rc_support | grep -q am_addons; then
		echo "This firmware does not support addons!"
		logger "$MY_ADDON_NAME addon" "This firmware does not support addons!"
		exit 5
	fi
	
	# Check jffs is enabled
	if [ "$(nvram get jffs2_on)" != 1 ]; then
		echo "This addon requires jffs to be enabled!"
		logger "$MY_ADDON_NAME addon" "This addon requires jffs to be enabled!"
		exit 5
	fi
	
	# create local repo folder
	mkdir -p "$LOCAL_REPO"
	
	echo "installation complete..."
	Clear_Lock
}

Addon_Uninstall(){
	printf "Uninstalling $MY_ADDON_NAME has not yet been tested...\\n"
#	printf "Uninstalling $MY_ADDON_NAME..."
#	cd ~
#	rm -f "$LOCAL_REPO" 2>/dev/null
#	printf "Uninstall of $MY_ADDON_NAME completed"
}

if [ -z "$1" ]; then
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Addon_Install
		exit 0
	;;
	*)
		Check_Lock
		echo "Command not recognised, please try again"
		Clear_Lock
		exit 1
	;;
esac
