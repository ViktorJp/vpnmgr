#!/bin/sh

# USAGE
#
# to check for and list current scheduled update entries
#  scriptname list
# to manually trigger an update
#  scriptname update [1|2|3|4|5] [openvpn_udp|openvpn_tcp] [null|double|p2p]
# to schedule updates using cron/cru
#  scriptname schedule [1|2|3|4|5] [openvpn_udp|openvpn_tcp] [minute] [hour] [day numbers] [null|double|p2p]
# to cancel schedule updates using cron/cru
#  scriptname cancel [1|2|3|4|5]

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
# load standard variables and helper script
. /usr/sbin/helper.sh

# addon name
MY_ADDON_NAME=nordvpnmanager
# control script
MY_ADDON_SCRIPT=nordvpnmanager.sh
# addon page
#MY_ADDON_PAGE=NordVPNManager.asp
# tab name
#MY_ADDON_TAB="NordVPN Manager"
# Github repo name
GIT_REPO="asusmerlin-nvpnmgr"
# Github repo branch - modify to pull different branch
# (fetch will overwrite local changes)
GIT_REPO_BRANCH=master
# Github dir
GITHUB_DIR="https://raw.githubusercontent.com/jackyaz/$GIT_REPO/$GIT_REPO_BRANCH"
# Local repo dir
LOCAL_REPO="/jffs/scripts/$MY_ADDON_NAME"

# functions
errorcheck(){
	echo "$SCRIPTSECTION reported an error..."
	logger -t "$MY_ADDON_NAME addon" "$SCRIPTSECTION reported an error"
	exit 1
}

# use to create content of vJSON variable
getRecommended(){
	curl -s -m 5 "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$VPNTYPE&filters\[servers_technologies\]\[identifier\]=${VPNPROT}&limit=1" || errorcheck
}

# use to create content of OVPN_IP variable
getIP(){
	# check vJSON variable contents exist
	[ -z "$vJSON" ] && errorcheck
	echo $vJSON | jq -e '.[].station // empty' | tr -d '"'
}

# use to create content of OVPN_HOSTNAME variable
getHostname(){
	[ -z "$vJSON" ] && errorcheck
	echo $vJSON | jq -e '.[].hostname // empty' | tr -d '"'
}

# use to create content of OVPNFILE variable
getOVPNFilename(){
	[ -z "$OVPN_HOSTNAME" ] || [ -z "$VPNPROT_SHORT" ] && errorcheck
	echo ${OVPN_HOSTNAME}.${VPNPROT_SHORT}.ovpn
}

# use to create content of OVPN_DETAIL variable
getOVPNcontents(){
	[ -z "$OVPNFILE" ] || [ -z "$VPNPROT_SHORT" ] && errorcheck
	curl -s -m 5 "https://downloads.nordcdn.com/configs/files/ovpn_$VPNPROT_SHORT/servers/$OVPNFILE" || errorcheck
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
	nvram get vpn_client${VPN_NO}_desc
}

# EXISTING_NAME check - it must contain "nordvpn"
checkConnName(){
	[ -z "$VPN_NO" ] && errorcheck
	EXISTING_NAME=$(getConnName)
	STR_COMPARE=nordvpn
	if echo $EXISTING_NAME | grep -v $STR_COMPARE >/dev/null 2>&1; then
		logger -t "$MY_ADDON_NAME addon" "decription must contain nordvpn (VPNClient$VPN_NO)..."
		errorcheck
	fi
}

# use to create content of EXISTING_IP variable
getServerIP(){
	[ -z "$VPN_NO" ] && errorcheck
	nvram get vpn_client${VPN_NO}_addr
}

# use to create content of CONNECTSTATE variable - set to 2 if the VPN is connected
getConnectState(){
	[ -z "$VPN_NO" ] && errorcheck
	nvram get vpn_client${VPN_NO}_state
}

# configure VPN
setVPN(){
	echo "updating VPN Client connection $VPN_NO now..."
	vJSON=$(getRecommended)
	OVPN_IP=$(getIP)
	OVPN_HOSTNAME=$(getHostname)
	OVPNFILE=$(getOVPNFilename)
	OVPN_DETAIL=$(getOVPNcontents)
	CLIENT_CA=$(getClientCA)
	CRT_CLIENT_STATIC=$(getClientCRT)
	EXISTING_NAME=$(getConnName)
	EXISTING_IP=$(getServerIP)
	CONNECTSTATE=$(getConnectState)
	
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
	[ -z "$VPN_NO" ] || [ -z "$MY_ADDON_NAME" ] || [ -z "$SCRIPTPATH" ] || [ -z "$MY_ADDON_SCRIPT" ] || [ -z "$VPNPROT" ] || [ -z "$VPNTYPE_PARAM" ] && errorcheck
	[ -z "$CRU_MINUTE" ] || [ -z "$CRU_HOUR" ] || [ -z "$CRU_DAYNUMBERS" ] && errorcheck
	# add new cru entry
	if cru l | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# replace existing
		cru d ${MY_ADDON_NAME}${VPN_NO}
		cru a ${MY_ADDON_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE_PARAM}"
	else
		# or add new if not exist
		cru a ${MY_ADDON_NAME}${VPN_NO} "${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE_PARAM}"
	fi
	# add persistent cru entry to /jffs/scripts/services-start for restarts
	if cat /jffs/scripts/services-start | grep "${MY_ADDON_NAME}${VPN_NO}" >/dev/null 2>&1; then
		# remove and replace existing
		sed -i "/${MY_ADDON_NAME}${VPN_NO}/d" /jffs/scripts/services-start
		echo "cru a ${MY_ADDON_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE_PARAM}\"" >> /jffs/scripts/services-start
	else
		# or add new if not exist
		echo "cru a ${MY_ADDON_NAME}${VPN_NO} \"${CRU_MINUTE} ${CRU_HOUR} * * ${CRU_DAYNUMBERS} sh ${SCRIPTPATH}/${MY_ADDON_SCRIPT} update ${VPN_NO} ${VPNPROT} ${VPNTYPE_PARAM}\"" >> /jffs/scripts/services-start
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

# ----------------
# ----------------
# ----------------

UpdateVPN(){
	checkConnName
	logger -t "$MY_ADDON_NAME addon" "Updating to recommended NORDVPN server (VPNClient$1)..."
	setVPN
	logger -t "$MY_ADDON_NAME addon" "Update complete (VPNClient$1 - server $OVPN_HOSTNAME - type $VPNTYPE_PARAM)"
}

ScheduleVPN(){
	checkConnName
	CRU_MINUTE=$4
	CRU_HOUR=$5
	CRU_DAYNUMBERS=$6
	
	# default options 5:25am on Mondays and Thursdays
	[ -z "$CRU_MINUTE" ] && CRU_MINUTE=25
	[ -z "$CRU_HOUR" ] && CRU_HOUR=5
	[ -z "$CRU_DAYNUMBERS" ] && CRU_DAYNUMBERS=1,4
	
	# CRON entry format = 5 5 * * 1,3,5 sh /jffs/scripts/asusvpn-autoselectbest.sh #autoselectvpn#
	# command to add (in /jffs/scripts/services-start) cru a autoselectvpn "5 5 * * 1,3,5 sh /jffs/scripts/asusvpn-autoselectbest.sh"
	
	# cru command syntax to add, list, and delete cron jobs
	# id – Unique ID for each cron job.
	# min – Minute (0-59)
	# hour – Hours (0-23)
	# day – Day (0-31)
	# month – Month (0-12 [12 is December])
	# week – Day of the week(0-7 [7 or 0 is Sunday])
	# command – Script or command name to schedule.
	
	logger -t "$MY_ADDON_NAME addon" "Configuring scheduled update to recommended NORDVPN server (VPNClient$VPN_NO)..."
	setCRONentry
	logger -t "$MY_ADDON_NAME addon" "Scheduling complete (VPNClient$VPN_NO - type $VPNTYPE_PARAM)"
}

CancelVPN(){
	checkConnName
	[ -z "$1" ] && errorcheck
	logger -t "$MY_ADDON_NAME addon" "Removing scheduled update to recommended NORDVPN server (VPNClient$1)..."
	delCRONentry
	logger -t "$MY_ADDON_NAME addon" "Removal of schedule complete (VPNClient$1)"
}

# default variables for this script
OPTIONCHECK=0

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
	OPTIONCHECK=1
	RETURNTEXT="$1"
	ScriptHeader
	UpdateNowMenuHeader
}

SetVPNClient(){
	printf "\\n\\e[1mPlease select a VPN client connection (x to cancel): \\e[0m"
	read -r "VPN_NO"
	if [ "$VPN_NO" = "x" ]; then
		OPTIONCHECK=1
		ReturnToMainMenu "previous operation cancelled"
	elif [ -z "$VPN_NO" ]; then
		ReturnToMainMenu "you must specify a valid VPN client"
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
				# check for connections
				VPNPROT=openvpn_udp
				VPNPROT_SHORT="$(echo "$VPNPROT" | cut -f2 -d'_')"
				break
			;;
			2)
				# configure now
				VPNPROT=openvpn_tcp
				VPNPROT_SHORT="$(echo "$VPNPROT" | cut -f2 -d'_')"
				break
			;;
			x)
				ReturnToMainMenu "previous operation cancelled"
				break
			;;
			*)
				ReturnToMainMenu "you must choose a protocol option"
				break
			;;
		esac
	done
	
	if [ -z "$VPNPROT" ]; then
		ReturnToMainMenu "you must choose a protocol option"
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
				# check for connections
				VPNTYPE=standard
				break
			;;
			2)
				# configure now
				VPNTYPE=double
				break
			;;
			3)
				# configure now
				VPNTYPE=p2p
				break
			;;
			x)
				ReturnToMainMenu "previous operation cancelled"
				break
			;;
			*)
				VPNTYPE=standard
				break
			;;
		esac
	done
	if [ -z "$VPNTYPE" ]; then
		ReturnToMainMenu "type not set or previous operation cancelled"
	fi
}

SetDays(){
	printf "\\n\\e[1mPlease choose update day/s (x to cancel - blank for every day): \\e[0m"
	read -r "CRU_DAYNUMBERS"
	if [ "$CRU_DAYNUMBERS" = "x" ]; then
		ReturnToMainMenu "previous operation cancelled"
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
		ReturnToMainMenu "previous operation cancelled"
	elif [ -z "$CRU_HOUR" ]; then
		ReturnToMainMenu "you must specify a valid hour or hours separated by comma"
	fi
	# validate HOURS here (must be a number from 0 to 23)
}

SetMinutes(){
	printf "\\n\\e[1mPlease choose update minute/s (x to cancel): \\e[0m"
	read -r "CRU_MINUTE"
	if [ "$CRU_MINUTE" = "x" ]; then
		OPTIONCHECK=1
		ReturnToMainMenu "previous operation cancelled"
	elif [ -z "$CRU_MINUTE" ]; then
		ReturnToMainMenu "you must specify a valid minute or minutes separated by comma"
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
		if [ "$OPTIONCHECK" = "1" ]
		then
			printf "$RETURNTEXT\\n"
			OPTIONCHECK=0
		else
			printf "\\n"
		fi
		printf "Choose an option:    "
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
					ReturnToMainMenu "Uninstall of $MY_ADDON_NAME cancelled"
				fi
			;;
			*)
				ReturnToMainMenu "Please choose a valid option"
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
	
	ReturnToMainMenu "Update VPN complete ($VPNTYPE)"
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
	
	ReturnToMainMenu "Scheduled VPN update complete ($VPNTYPE)"
}

DeleteScheduleMenu(){
	ScriptHeader
	DeleteScheduleMenuHeader
	
	SetVPNClient
	
	CancelVPN "$VPN_NO"
	PressEnter
	
	ReturnToMainMenu "Delete VPN schedule complete"
}

Addon_Install(){
	# use to download the files from github
	
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
	
	echo "installation complete... visit https://github.com/h0me5k1n/asusmerlin-nvpnmgr for CLI usage information or run \"nvpnmgr-menu.sh\" for menu driven configuration."
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