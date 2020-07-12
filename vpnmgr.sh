#!/bin/sh

###################################################
##                                               ##
## __   __ _ __   _ __   _ __ ___    __ _  _ __  ##
## \ \ / /| '_ \ | '_ \ | '_ ` _ \  / _` || '__| ##
##  \ V / | |_) || | | || | | | | || (_| || |    ##
##   \_/  | .__/ |_| |_||_| |_| |_| \__, ||_|    ##
##        | |                        __/ |       ##
##        |_|                       |___/        ##
##                                               ##
##       https://github.com/jackyaz/vpnmgr       ##
##              forked from h0me5k1n             ##
###################################################

########         Shellcheck directives     ########
# shellcheck disable=SC2018
# shellcheck disable=SC2019
###################################################

### Start of script variables ###
readonly SCRIPT_NAME="vpnmgr"
readonly SCRIPT_VERSION="v2.0.0"
readonly SCRIPT_BRANCH="PIA"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/""$SCRIPT_NAME""/""$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_CONF="$SCRIPT_DIR/config"
readonly OVPN_ARCHIVE_DIR="$SCRIPT_DIR/ovpn"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
GLOBAL_VPN_NO=""
GLOBAL_VPN_PROVIDER=""
GLOBAL_VPN_PROT=""
GLOBAL_VPN_TYPE=""
GLOBAL_CRU_DAYNUMBERS=""
GLOBAL_CRU_HOURS=""
GLOBAL_CRU_MINS=""
GLOBAL_COUNTRY_NAME=""
GLOBAL_COUNTRY_ID=""
GLOBAL_CITY_NAME=""
GLOBAL_CTIY_ID=""
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

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

###################################

Set_Version_Custom_Settings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "vpnmgr_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$SCRIPT_VERSION" != "$(grep "vpnmgr_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/vpnmgr_version_local.*/vpnmgr_version_local $SCRIPT_VERSION/" "$SETTINGSFILE"
					fi
				else
					echo "vpnmgr_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
				fi
			else
				echo "vpnmgr_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "vpnmgr_version_server" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "vpnmgr_version_server" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/vpnmgr_version_server.*/vpnmgr_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "vpnmgr_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "vpnmgr_version_server $2" >> "$SETTINGSFILE"
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
			Update_File "vpnmgr_www.asp"
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
		Update_File "vpnmgr_www.asp"
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
	elif [ "$1" = "vpnmgr_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			if [ -f "$SCRIPT_DIR/$1" ]; then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyPage~d" /tmp/menuTree.js
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage" 2>/dev/null
			fi
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME""_startup" /jffs/scripts/services-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup &"' # '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME""_startup"'/d' /jffs/scripts/services-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup"' # '"$SCRIPT_NAME""_startup &" >> /jffs/scripts/services-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/services-start
				echo "" >> /jffs/scripts/services-start
				echo "/jffs/scripts/$SCRIPT_NAME startup"' # '"$SCRIPT_NAME""_startup &" >> /jffs/scripts/services-start
				chmod 0755 /jffs/scripts/services-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME""_startup" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME""_startup"'/d' /jffs/scripts/services-start
				fi
			fi
		;;
	esac
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME service_event"' "$1" "$2" &'' # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

Auto_Cron(){
	case $1 in
		create)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME""_countrydata")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_countrydata"
			fi
		
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME""_cacheddata")
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_cacheddata" "0 0 * * * /jffs/scripts/$SCRIPT_NAME refreshcacheddata"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME""_cacheddata")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_cacheddata"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Get_WebUI_Page () {
	for i in 1 2 3 4 5 6 7 8 9 10; do
		page="$SCRIPT_WEBPAGE_DIR/user$i.asp"
		if [ ! -f "$page" ] || [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		fi
	done
	MyPage="none"
}

Mount_WebUI(){
	Get_WebUI_Page "$SCRIPT_DIR/vpnmgr_www.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output "true" "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		exit 1
	fi
	Print_Output "true" "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
	cp -f "$SCRIPT_DIR/vpnmgr_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
	echo "VPN Manager" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
	if [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
		if [ ! -f "/tmp/menuTree.js" ]; then
			cp -f "/www/require/modules/menuTree.js" "/tmp/"
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		sed -i "/url: \"Advanced_OpenVPNClient_Content.asp\", tabName:/a {url: \"$MyPage\", tabName: \"VPN Manager\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
}

Validate_Number(){
	if [ "$2" -eq "$2" ] 2>/dev/null; then
		return 0
	else
		formatted="$(echo "$1" | sed -e 's/|/ /g')"
		if [ -z "$3" ]; then
			Print_Output "false" "$formatted - $2 is not a number" "$ERR"
		fi
		return 1
	fi
}

Conf_FromSettings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	TMPFILE="/tmp/vpnmgr_settings.txt"
	if [ -f "$SETTINGSFILE" ]; then
		if [ "$(grep "vpnmgr_" $SETTINGSFILE | grep -v "version" -c)" -gt 0 ]; then
			Print_Output "true" "Updated settings from WebUI found, merging into $SCRIPT_CONF" "$PASS"
			cp -a "$SCRIPT_CONF" "$SCRIPT_CONF.bak"
			grep "vpnmgr_" "$SETTINGSFILE" | grep -v "version" > "$TMPFILE"
			sed -i "s/vpnmgr_//g;s/ /=/g" "$TMPFILE"
			while IFS='' read -r line || [ -n "$line" ]; do
				SETTINGNAME="$(echo "$line" | cut -f1 -d'=')"
				SETTINGVALUE="$(echo "$line" | cut -f2- -d'=' | sed "s/=/ /g")"
				SETTINGVPNNO="$(echo "$SETTINGNAME" | cut -f1 -d'_' | sed 's/vpn//g')"
				if echo "$SETTINGNAME" | grep -q "usn"; then
					nvram set vpn_client"$SETTINGVPNNO"_username="$SETTINGVALUE"
				elif echo "$SETTINGNAME" | grep -q "pwd"; then
					nvram set vpn_client"$SETTINGVPNNO"_password="$SETTINGVALUE"
				else
					sed -i "s/$SETTINGNAME=.*/$SETTINGNAME=$SETTINGVALUE/" "$SCRIPT_CONF"
				fi
			done < "$TMPFILE"
			grep 'vpnmgr_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~vpnmgr_~d" "$SETTINGSFILE"
			mv "$SETTINGSFILE" "$SETTINGSFILE.bak"
			cat "$SETTINGSFILE.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "$SETTINGSFILE.bak"
			nvram commit
			Print_Output "true" "Merge of updated settings from WebUI completed successfully" "$PASS"
		else
			Print_Output "false" "No updated settings from WebUI found, no merge into $SCRIPT_CONF necessary" "$PASS"
		fi
	fi
}

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$OVPN_ARCHIVE_DIR" ]; then
		mkdir -p "$OVPN_ARCHIVE_DIR"
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
	
	ln -s "$SCRIPT_DIR/config"  "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	ln -s "$SCRIPT_DIR/vpncountrydata" "$SCRIPT_WEB_DIR/vpncountrydata.htm" 2>/dev/null
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

Conf_Exists(){
	if [ -f "$SCRIPT_CONF" ]; then
		dos2unix "$SCRIPT_CONF"
		chmod 0644 "$SCRIPT_CONF"
		sed -i -e 's/"//g' "$SCRIPT_CONF"
		if [ "$(wc -l < "$SCRIPT_CONF")" -eq 45 ]; then
			for i in 1 2 3 4 5; do
				sed -i '/^vpn'"$i"'_schmins=.*/a vpn'"$i"'_cityid=0' "$SCRIPT_CONF"
				sed -i '/^vpn'"$i"'_schmins=.*/a vpn'"$i"'_countryid=0' "$SCRIPT_CONF"
				sed -i '/^vpn'"$i"'_schmins=.*/a vpn'"$i"'_cityname=' "$SCRIPT_CONF"
				sed -i '/^vpn'"$i"'_schmins=.*/a vpn'"$i"'_countryname=' "$SCRIPT_CONF"
			done
		fi
		if [ "$(wc -l < "$SCRIPT_CONF")" -eq 65 ]; then
			for i in 1 2 3 4 5; do
				sed -i '/^vpn'"$i"'_managed=.*/a vpn'"$i"'_provider=NordVPN' "$SCRIPT_CONF"
			done
		fi
		return 0
	else
		for i in 1 2 3 4 5; do
			{
				echo "##### VPN Client $i #####"
				echo "vpn$i""_managed=false"
				echo "vpn$i""_provider=NordVPN"
				echo "vpn$i""_protocol=UDP"
				echo "vpn$i""_type=Standard"
				echo "vpn$i""_schenabled=false"
				echo "vpn$i""_schdays=*"
				echo "vpn$i""_schhours=0"
				echo "vpn$i""_schmins=$i"
				echo "vpn$i""_countryname="
				echo "vpn$i""_cityname="
				echo "vpn$i""_countryid=0"
				echo "vpn$i""_cityid=0"
				echo "#########################"
			} >> "$SCRIPT_CONF"
		done
		return 1
	fi
}

# use to create content of vJSON variable; $1 VPN type, $2 VPN protocol, $3 country id
getRecommendedServers(){
	curlstring="https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$1&filters\[servers_technologies\]\[identifier\]=$2"
	if [ "$3" != "0" ]; then
		curlstring="$curlstring&filters\[country_id\]=$3"
	fi
	curlstring="$curlstring&limit=1"
	/usr/sbin/curl -fsL --retry 3 "$curlstring" | jq -r -e '.[] // empty'
}

getServersforCity(){
	/usr/sbin/curl -fsL --retry 3 "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$1&filters\[servers_technologies\]\[identifier\]=$2&filters\[country_id\]=$3&limit=2500" | jq -r -e ' [ .[] | select(.locations[].country.city.id=='"$4"')][0] // empty'
}

getCountryData(){
	Print_Output "true" "Refreshing NordVPN country data..." "$PASS"
	/usr/sbin/curl -fsL --retry 3 "https://api.nordvpn.com/v1/servers/countries" | jq -r > /tmp/vpncountrydata
	countrydata="$(cat /tmp/vpncountrydata)"
	[ -z "$countrydata" ] && Print_Output "true" "Error, country data from NordVPN failed to download" "$ERR" && return 1
	if [ -f "$SCRIPT_DIR/vpncountrydata" ]; then
		if ! diff -q /tmp/vpncountrydata "$SCRIPT_DIR/vpncountrydata" >/dev/null 2>&1; then
			mv /tmp/vpncountrydata "$SCRIPT_DIR/vpncountrydata"
			Print_Output "true" "Changes detected in NordVPN country data found, updating now" "$PASS"
			Create_Symlinks
		else
			Print_Output "true" "No changes in NordVPN country data" "$WARN"
		fi
	else
		mv /tmp/vpncountrydata "$SCRIPT_DIR/vpncountrydata"
		Create_Symlinks
		Print_Output "true" "No previous NordVPN country data found, updating now" "$PASS"
	fi
}

getCountryNames(){
	echo "$1" | jq -r -e '.[] | .name // empty'
}

getCountryID(){
	echo "$1" | jq -r -e '.[] | select(.name=="'"$2"'") | .id // empty'
}

getCityCount(){
	echo "$1" | jq -r -e '.[] | select(.name=="'"$2"'") | .cities | length // empty'
}

getCityNames(){
	echo "$1" | jq -r -e '.[] | select(.name=="'"$2"'") | .cities[] | .name // empty'
}

getCityID(){
	echo "$1" | jq -r -e '.[] | select(.name=="'"$2"'") | .cities[] | select(.name=="'"$3"'") | .id // empty'
}

getIP(){
	echo "$1" | jq -r -e '.station // empty'
}

getHostname(){
	echo "$1" | jq -r -e '.hostname // empty'
}

getOVPNcontents(){
	/usr/sbin/curl -fsL --retry 3 "https://downloads.nordcdn.com/configs/files/ovpn_$2/servers/$1"
}

getPort(){
	echo "$1" | grep "^remote " | cut -f3 -d' '
}

getCipher(){
	echo "$1" | grep "^cipher " | cut -f2 -d' '
}

getAuthDigest(){
	echo "$1" | grep "^auth " | cut -f2 -d' '
}

getClientCA(){
	echo "$1" | awk '/<ca>/{flag=1;next}/<\/ca>/{flag=0}flag' | sed '/^#/ d'
}

getClientCRT(){
	echo "$1" | awk '/<tls-auth>/{flag=1;next}/<\/tls-auth>/{flag=0}flag' | sed '/^#/ d'
}

getConnectState(){
	nvram get vpn_client"$1"_state
}

getOVPNArchives(){
	Print_Output "true" "Refreshing OpenVPN file archives..." "$PASS"
	
	### PIA ###
	# Standard UDP
	Download_File https://www.privateinternetaccess.com/openvpn/openvpn.zip /tmp/pia_udp_standard.zip
	# Standard TCP
	Download_File https://www.privateinternetaccess.com/openvpn/openvpn-tcp.zip /tmp/pia_tcp_standard.zip
	# Strong UDP
	Download_File https://www.privateinternetaccess.com/openvpn/openvpn-strong.zip /tmp/pia_udp_strong.zip
	# Strong TCP
	Download_File https://www.privateinternetaccess.com/openvpn/openvpn-strong-tcp.zip /tmp/pia_tcp_strong.zip
	###########
	
	FILES="/tmp/pia*.zip"
	archiveschanged="false"
	for f in $FILES; do
		if [ -f "$f" ]; then
			if [ -f "$OVPN_ARCHIVE_DIR/$(basename $f)" ]; then
				remotemd5="$(md5sum "$f")"
				localmd5="$(md5sum "$OVPN_ARCHIVE_DIR/$(basename $f)")"
				if [ "$localmd5" != "$remotemd5" ]; then
					mv "$f" "$OVPN_ARCHIVE_DIR/$(basename $f)"
					archiveschanged="true"
				else
					rm -f "$f"
				fi
			else
				mv "$f" "$OVPN_ARCHIVE_DIR/$(basename $f)"
				archiveschanged="true"
			fi
		fi
	done
	
	if [ "$archiveschanged" = "true" ]; then
		Print_Output "true" "Changes detected in OpenVPN file archives, local copies updated" "$PASS"
	else
		Print_Output "true" "No changes in OpenVPN file archives" "$WARN"
	fi
}

ListVPNClients(){
	printf "VPN client list:\\n\\n"
	for i in 1 2 3 4 5; do
		VPN_CLIENTDESC="$(nvram get vpn_client"$i"_desc)"
		MANAGEDSTATE=""
		CONNECTSTATE=""
		SCHEDULESTATE=""
		if [ "$(grep "vpn""$i""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
			MANAGEDSTATE="Managed"
		elif [ "$(grep "vpn""$i""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			MANAGEDSTATE="Unmanaged"
		fi
		if [ "$(getConnectState "$i")" = "2" ]; then
			CONNECTSTATE="Active"
		else
			CONNECTSTATE="Inactive"
		fi
		if [ "$(grep "vpn""$i""_schenabled" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
			SCHEDULESTATE="Scheduled"
		elif [ "$(grep "vpn""$i""_schenabled" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			SCHEDULESTATE="Unscheduled"
		fi
		COUNTRYNAME="$(grep "vpn""$i""_countryname" "$SCRIPT_CONF" | cut -f2 -d"=")"
		[ -z "$COUNTRYNAME" ] && COUNTRYNAME="None"
		CITYNAME="$(grep "vpn""$i""_cityname" "$SCRIPT_CONF" | cut -f2 -d"=")"
		[ -z "$CITYNAME" ] && CITYNAME="None"
		printf "%s.    %s (%s, %s and %s)\\n" "$i" "$VPN_CLIENTDESC" "$MANAGEDSTATE" "$CONNECTSTATE" "$SCHEDULESTATE"
		printf "      Chosen country: %s - Preferred city: %s\\n\\n" "$COUNTRYNAME" "$CITYNAME"
	done
	printf "\\n"
}

#shellcheck disable=SC2140
UpdateVPNConfig(){
	ISUNATTENDED=""
	if [ "$1" = "unattended" ]; then
		ISUNATTENDED="true"
		shift
	fi
	VPN_NO="$1"
	VPN_PROVIDER="$(grep "vpn""$VPN_NO""_provider" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_PROT_SHORT="$(grep "vpn""$VPN_NO""_protocol" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_PROT="openvpn_""$(echo "$VPN_PROT_SHORT" | tr "A-Z" "a-z")"
	VPN_TYPE_SHORT="$(grep "vpn""$VPN_NO""_type" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_TYPE=""
	if [ "$VPN_TYPE_SHORT" = "Double" ]; then
		VPN_TYPE="legacy_""$(echo "$VPN_TYPE_SHORT" | tr "A-Z" "a-z")""_vpn"
	else
		VPN_TYPE="legacy_""$(echo "$VPN_TYPE_SHORT" | tr "A-Z" "a-z")"
	fi
	VPN_COUNTRYID="$(grep "vpn""$VPN_NO""_countryid" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_COUNTRYNAME="$(grep "vpn""$VPN_NO""_countryname" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_CITYID="$(grep "vpn""$VPN_NO""_cityid" "$SCRIPT_CONF" | cut -f2 -d"=")"
	VPN_CITYNAME="$(grep "vpn""$VPN_NO""_cityname" "$SCRIPT_CONF" | cut -f2 -d"=")"
	vJSON=""
	
	Print_Output "true" "Retrieving recommended VPN server using NordVPN API with below parameters" "$PASS"
	if [ "$VPN_COUNTRYID" = "0" ]; then
		Print_Output "true" "Protocol: $VPN_PROT_SHORT - Type: $VPN_TYPE_SHORT" "$PASS"
		vJSON="$(getRecommendedServers "$VPN_TYPE" "$VPN_PROT" "$VPN_COUNTRYID")"
	else
		if [ "$VPN_CITYID" = "0" ]; then
			Print_Output "true" "Protocol: $VPN_PROT_SHORT - Type: $VPN_TYPE_SHORT - Country: $VPN_COUNTRYNAME" "$PASS"
			vJSON="$(getRecommendedServers "$VPN_TYPE" "$VPN_PROT" "$VPN_COUNTRYID")"
		else
			Print_Output "true" "Protocol: $VPN_PROT_SHORT - Type: $VPN_TYPE_SHORT - Country: $VPN_COUNTRYNAME - City: $VPN_CITYNAME" "$PASS"
			vJSON="$(getServersforCity "$VPN_TYPE" "$VPN_PROT" "$VPN_COUNTRYID" "$VPN_CITYID")"
			if [ -z "$vJSON" ]; then
				Print_Output "true" "No VPN servers found for $VPN_CITYNAME, removing filter for city" "$WARN"
				vJSON="$(getRecommendedServers "$VPN_TYPE" "$VPN_PROT" "$VPN_COUNTRYID")"
				if [ -z "$vJSON" ]; then
					Print_Output "true" "No VPN servers found for $VPN_COUNTRYNAME, removing filter for country" "$WARN"
					vJSON="$(getRecommendedServers "$VPN_TYPE" "$VPN_PROT" "0")"
				fi
			fi
		fi
	fi
	
	[ -z "$vJSON" ] && Print_Output "true" "Error contacting NordVPN API" "$ERR" && return 1
	OVPN_IP="$(getIP "$vJSON")"
	[ -z "$OVPN_IP" ] && Print_Output "true" "Could not determine IP for VPN server" "$ERR" && return 1
	OVPN_HOSTNAME="$(getHostname "$vJSON")"
	[ -z "$OVPN_HOSTNAME" ] && Print_Output "true" "Could not determine hostname for VPN server" "$ERR" && return 1
	#shellcheck disable=SC2018
	#shellcheck disable=SC2019
	OVPN_HOSTNAME_SHORT="$(echo "$OVPN_HOSTNAME" | cut -f1 -d'.' | tr "a-z" "A-Z")"
	OVPNFILE="$OVPN_HOSTNAME.$(echo "$VPN_PROT" | cut -f2 -d"_").ovpn"
	OVPN_DETAIL="$(getOVPNcontents "$OVPNFILE" "$(echo "$VPN_PROT" | cut -f2 -d"_")")"
	[ -z "$OVPN_DETAIL" ] && Print_Output "true" "Error downloading VPN server ovpn file" "$ERR" && return 1
	OVPN_PORT="$(getPort "$OVPN_DETAIL")"
	[ -z "$OVPN_PORT" ] && Print_Output "true" "Error determining port for VPN server" "$ERR" && return 1
	OVPN_CIPHER="$(getCipher "$OVPN_DETAIL")"
	[ -z "$OVPN_CIPHER" ] && Print_Output "true" "Error determining cipher for VPN server" "$ERR" && return 1
	OVPN_AUTHDIGEST="$(getAuthDigest "$OVPN_DETAIL")"
	[ -z "$OVPN_AUTHDIGEST" ] && Print_Output "true" "Error determining auth digest for VPN server" "$ERR" && return 1
	CLIENT_CA="$(getClientCA "$OVPN_DETAIL")"
	[ -z "$CLIENT_CA" ] && Print_Output "true" "Error determing VPN server Certificate Authority certificate" "$ERR" && return 1
	CRT_CLIENT_STATIC="$(getClientCRT "$OVPN_DETAIL")"
	[ -z "$CRT_CLIENT_STATIC" ] && Print_Output "true" "Error determing VPN client certificate" "$ERR" && return 1
	EXISTING_IP="$(nvram get vpn_client"$VPN_NO"_addr)"
	
	if [ "$OVPN_IP" != "$EXISTING_IP" ]; then
		Print_Output "true" "Updating VPN client $VPN_NO to new $VPN_PROVIDER server" "$PASS"
		
		if [ -z "$(nvram get vpn_client"$VPN_NO"_addr)" ]; then
			nvram set vpn_client"$VPN_NO"_adns="3"
			nvram set vpn_client"$VPN_NO"_enforce="1"
		fi
		
		nvram set vpn_client"$VPN_NO"_addr="$OVPN_IP"
		nvram set vpn_client"$VPN_NO"_port="$OVPN_PORT"
		if [ "$VPN_PROT_SHORT" = "TCP" ]; then
			nvram set vpn_client"$VPN_NO"_proto="tcp-client"
		elif [ "$VPN_PROT_SHORT" = "UDP" ]; then
			nvram set vpn_client"$VPN_NO"_proto="udp"
		fi
		nvram set vpn_client"$VPN_NO"_desc="$VPN_PROVIDER $OVPN_HOSTNAME_SHORT $VPN_TYPE_SHORT $VPN_PROT_SHORT"
		
		nvram set vpn_client"$VPN_NO"_cipher="$OVPN_CIPHER"
		nvram set vpn_client"$VPN_NO"_comp="-1"
		nvram set vpn_client"$VPN_NO"_connretry="-1"
		nvram set vpn_client"$VPN_NO"_crypt="tls"
		nvram set vpn_client"$VPN_NO"_digest="$OVPN_AUTHDIGEST"
		nvram set vpn_client"$VPN_NO"_fw="1"
		nvram set vpn_client"$VPN_NO"_hmac="1"
		nvram set vpn_client"$VPN_NO"_if="tun"
		nvram set vpn_client"$VPN_NO"_nat="1"
		nvram set vpn_client"$VPN_NO"_ncp_ciphers="AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC"
		nvram set vpn_client"$VPN_NO"_ncp_enable="1"
		nvram set vpn_client"$VPN_NO"_reneg="0"
		nvram set vpn_client"$VPN_NO"_tlsremote="0"
		nvram set vpn_client"$VPN_NO"_userauth="1"
		nvram set vpn_client"$VPN_NO"_useronly="0"
		
		vpncustomoptions='remote-random
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ping 15
ping-restart 0
ping-timer-rem
remote-cert-tls server
persist-key
persist-tun
reneg-sec 0
fast-io
disable-occ
mute-replay-warnings
auth-nocache
sndbuf 524288
rcvbuf 524288
push "sndbuf 524288"
push "rcvbuf 524288"
pull-filter ignore "auth-token"
pull-filter ignore "ifconfig-ipv6"
pull-filter ignore "route-ipv6"'

	if [ "$VPN_PROT_SHORT" = "UDP" ]; then
		vpncustomoptions="$vpncustomoptions
explicit-exit-notify 3"
	fi
		
		vpncustomoptionsbase64="$(echo "$vpncustomoptions" | head -c -1 | openssl base64 -A)"
		
		if [ "$(/bin/uname -m)" = "aarch64" ]; then
			nvram set vpn_client"$VPN_NO"_cust2="$(echo "$vpncustomoptionsbase64" | cut -c0-255)"
			nvram set vpn_client"$VPN_NO"_cust21="$(echo "$vpncustomoptionsbase64" | cut -c256-510)"
			nvram set vpn_client"$VPN_NO"_cust22="$(echo "$vpncustomoptionsbase64" | cut -c511-765)"
		elif [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
			nvram set vpn_client"$VPN_NO"_cust2="$vpncustomoptionsbase64"
		else
			nvram set vpn_client"$VPN_NO"_custom="$vpncustomoptions"
		fi
		
		if [ "$ISUNATTENDED" = "true" ]; then
			if [ -z "$(nvram get vpn_client"$VPN_NO"_username)" ]; then
				Print_Output "true" "No username set for VPN client $VPN_NO" "$WARN"
			fi
			
			if [ -z "$(nvram get vpn_client"$VPN_NO"_password)" ]; then
				Print_Output "true" "No password set for VPN client $VPN_NO" "$WARN"
			fi
		else
			if [ -z "$(nvram get vpn_client"$VPN_NO"_username)" ]; then
				printf "\\n\\e[1mNo username set for VPN client %s\\e[0m\\n" "$VPN_NO"
				printf "Please enter username:    "
				read -r "vpnusn"
				nvram set vpn_client"$VPN_NO"_username="$vpnusn"
				printf "\\n"
			fi
			
			if [ -z "$(nvram get vpn_client"$VPN_NO"_password)" ]; then
				printf "\\n\\e[1mNo password set for VPN client %s\\e[0m\\n" "$VPN_NO"
				printf "Please enter password:    "
				read -r "vpnpwd"
				nvram set vpn_client"$VPN_NO"_password="$vpnpwd"
				printf "\\n"
			fi
		fi
		
		nvram commit
		
		echo "$CLIENT_CA" > /jffs/openvpn/vpn_crt_client"$VPN_NO"_ca
		echo "$CRT_CLIENT_STATIC" > /jffs/openvpn/vpn_crt_client"$VPN_NO"_static
		
		if nvram get vpn_clientx_eas | grep -q "$VPN_NO"; then
			service restart_vpnclient"$VPN_NO" >/dev/null 2>&1
		fi
		Print_Output "true" "VPN client $VPN_NO updated successfully ($OVPN_HOSTNAME_SHORT $VPN_TYPE_SHORT $VPN_PROT_SHORT)" "$PASS"
	else
		Print_Output "true" "VPN client $VPN_NO is already using the recommended server" "$WARN"
	fi
}

ManageVPN(){
	VPN_NO="$1"
	
	if [ -z "$(nvram get vpn_client"$VPN_NO"_username)" ] && [ -z "$(nvram get vpn_client"$VPN_NO"_password)" ]; then
		Print_Output "false" "No username or password set for VPN client $VPN_NO, cannot enable management" "$ERR"
		return 1
	fi
	
	if [ "$(grep "vpn""$VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
		printf "\\n"
		Print_Output "false" "VPN client $VPN_NO is already managed by $SCRIPT_NAME" "$WARN"
	elif [ "$(grep "vpn""$VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
		Print_Output "true" "Enabling management of VPN client $VPN_NO" "$PASS"
		sed -i 's/^vpn'"$VPN_NO"'_managed.*$/vpn'"$VPN_NO"'_managed=true/' "$SCRIPT_CONF"
		Print_Output "true" "Management of VPN client $VPN_NO successfully enabled" "$PASS"
	fi
}

UnmanageVPN(){
	VPN_NO="$1"
	
	if [ "$(grep "vpn""$VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
		Print_Output "true" "Removing management of VPN client $VPN_NO" "$PASS"
		sed -i 's/^vpn'"$VPN_NO"'_managed.*$/vpn'"$VPN_NO"'_managed=false/' "$SCRIPT_CONF"
		CancelScheduleVPN "$VPN_NO"
		Print_Output "true" "Management of VPN client $VPN_NO successfully removed" "$PASS"
	elif [ "$(grep "vpn""$VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
		printf "\\n"
		Print_Output "false" "VPN client $VPN_NO is not managed by $SCRIPT_NAME" "$WARN"
	fi
}

ScheduleVPN(){
	VPN_NO="$1"
	CRU_DAYNUMBERS="$(grep "vpn""$VPN_NO""_schdays" "$SCRIPT_CONF" | cut -f2 -d"=" | sed 's/Sun/0/;s/Mon/1/;s/Tues/2/;s/Wed/3/;s/Thurs/4/;s/Fri/5/;s/Sat/6/;')"
	CRU_HOURS="$(grep "vpn""$VPN_NO""_schhours" "$SCRIPT_CONF" | cut -f2 -d"=")"
	CRU_MINUTES="$(grep "vpn""$VPN_NO""_schmins" "$SCRIPT_CONF" | cut -f2 -d"=")"
	
	Print_Output "true" "Configuring scheduled update for VPN client $VPN_NO" "$PASS"
	
	if cru l | grep -q "$SCRIPT_NAME$VPN_NO"; then
		cru d "$SCRIPT_NAME""_VPN""$VPN_NO"
	fi
	
	cru a "$SCRIPT_NAME""_VPN""$VPN_NO" "$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO"
	
	if [ -f /jffs/scripts/services-start ]; then
		sed -i "/$SCRIPT_NAME""_VPN""$VPN_NO/d" /jffs/scripts/services-start
		echo "cru a $SCRIPT_NAME""_VPN""$VPN_NO \"$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO\" # $SCRIPT_NAME" >> /jffs/scripts/services-start
	else
		echo "#!/bin/sh" >> /jffs/scripts/services-start
		echo "cru a $SCRIPT_NAME""_VPN""$VPN_NO \"$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO\" # $SCRIPT_NAME" >> /jffs/scripts/services-start
		chmod 755 /jffs/scripts/services-start
	fi
	
	Print_Output "true" "Scheduled update created for VPN client $VPN_NO" "$PASS"
}

CancelScheduleVPN(){
	VPN_NO="$1"
	SCHEDULESTATE=""
	if ! cru l | grep -q "#$SCRIPT_NAME""_VPN""$VPN_NO#"; then
		SCHEDULESTATE="Unscheduled"
	else
		SCHEDULESTATE="Scheduled"
	fi
	if [ "$SCHEDULESTATE" = "Scheduled" ]; then
		Print_Output "true" "Removing scheduled update for VPN client $VPN_NO" "$PASS"
		
		if cru l | grep -q "$SCRIPT_NAME""_VPN""$VPN_NO"; then
			cru d "$SCRIPT_NAME""_VPN""$VPN_NO"
		fi
		
		if grep -q "$SCRIPT_NAME""_VPN""$VPN_NO" /jffs/scripts/services-start; then
			sed -i "/$SCRIPT_NAME""_VPN""$VPN_NO/d" /jffs/scripts/services-start
		fi
		
		Print_Output "true" "Scheduled update cancelled for VPN client $VPN_NO" "$PASS"
	else
		printf "\\n"
		Print_Output "false" "No schedule to cancel for VPN client $VPN_NO" "$WARN"
	fi
}

Shortcut_vpnmgr(){
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
	ScriptHeader
	ListVPNClients
	printf "Choose options as follows:\\n"
	printf "    - VPN client [1-5]\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	exitmenu=""
	vpnnum=""
	
	while true; do
		printf "\\n\\e[1mPlease enter the VPN client number (1-5):\\e[0m    "
		read -r "vpn_choice"
		
		if [ "$vpn_choice" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Number "" "$vpn_choice" "silent"; then
			printf "\\n\\e[31mPlease enter a valid number (1-5)\\e[0m\\n"
		else
			if [ "$vpn_choice" -lt 1 ] || [ "$vpn_choice" -gt 5 ]; then
				printf "\\n\\e[31mPlease enter a number between 1 and 5\\e[0m\\n"
			else
				vpnnum="$vpn_choice"
				printf "\\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		GLOBAL_VPN_NO="$vpnnum"
		return 0
	else
		printf "\\n"
		Print_Output "false" "VPN client selection cancelled" "$WARN"
		return 1
	fi
}

SetVPNParameters(){
	exitmenu=""
	vpnnum=""
	vpnprovider=""
	vpnprot=""
	vpntype=""
	countrydata=""
	choosecountry=""
	choosecity=""
	countryname=""
	countryid="0"
	cityname=""
	cityid="0"
	
	while true; do
		printf "\\n\\e[1mPlease enter the VPN client number (1-5):\\e[0m    "
		read -r "vpn_choice"
		
		if [ "$vpn_choice" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Number "" "$vpn_choice" "silent"; then
			printf "\\n\\e[31mPlease enter a valid number (1-5)\\e[0m\\n"
		else
			if [ "$vpn_choice" -lt 1 ] || [ "$vpn_choice" -gt 5 ]; then
				printf "\\n\\e[31mPlease enter a number between 1 and 5\\e[0m\\n"
			else
				vpnnum="$vpn_choice"
				printf "\\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease select a VPN provider:\\e[0m\\n"
			printf "    1. NordVPN\\n"
			printf "    2. Private Internet Access (PIA)\\n\\n"
			printf "Choose an option:    "
			read -r "provmenu"
			
			case "$provmenu" in
				1)
					vpnprovider="NordVPN"
					printf "\\n"
					break
				;;
				2)
					vpnprovider="PIA"
					printf "\\n"
					break
				;;
				e)
					exitmenu="exit"
					break
				;;
				*)
					printf "\\n\\e[31mPlease enter a valid choice (1-2)\\e[0m\\n"
				;;
			esac
		done
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		if [ "$vpnprovider" = "NordVPN" ]; then
			while true; do
				printf "\\n\\e[1mPlease select a VPN Type:\\e[0m\\n"
				printf "    1. Standard\\n"
				printf "    2. Double\\n"
				printf "    3. P2P\\n\\n"
				printf "Choose an option:    "
				read -r "typemenu"
				
				case "$typemenu" in
					1)
						vpntype="legacy_standard"
						printf "\\n"
						break
					;;
					2)
						vpntype="legacy_double_vpn"
						printf "\\n"
						break
					;;
					3)
						vpntype="legacy_p2p"
						printf "\\n"
						break
					;;
					e)
						exitmenu="exit"
						break
					;;
					*)
						printf "\\n\\e[31mPlease enter a valid choice (1-3)\\e[0m\\n"
					;;
				esac
			done
		elif [ "$vpnprovider" = "PIA" ]; then
			while true; do
				printf "\\n\\e[1mPlease select a VPN Type:\\e[0m\\n"
				printf "    1. Standard\\n"
				printf "    2. Strong\\n\\n"
				printf "Choose an option:    "
				read -r "typemenu"
				
				case "$typemenu" in
					1)
						vpntype="standard"
						printf "\\n"
						break
					;;
					2)
						vpntype="strong"
						printf "\\n"
						break
					;;
					e)
						exitmenu="exit"
						break
					;;
					*)
						printf "\\n\\e[31mPlease enter a valid choice (1-3)\\e[0m\\n"
					;;
				esac
			done
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease select a VPN protocol:\\e[0m\\n"
			printf "    1. UDP\\n"
			printf "    2. TCP\\n\\n"
			printf "Choose an option:    "
			read -r "protmenu"
			
			case "$protmenu" in
				1)
					vpnprot="openvpn_udp"
					printf "\\n"
					break
				;;
				2)
					vpnprot="openvpn_tcp"
					printf "\\n"
					break
				;;
				e)
					exitmenu="exit"
					break
				;;
				*)
					printf "\\n\\e[31mPlease enter a valid choice (1-2)\\e[0m\\n"
				;;
			esac
		done
	fi
	
	if [ "$vpnprovider" = "NordVPN" ]; then
		if [ "$exitmenu" != "exit" ]; then
			while true; do
				printf "\\n\\e[1mWould you like to select a country (y/n)?\\e[0m    "
				read -r "country_select"
				
				if [ "$country_select" = "e" ]; then
					exitmenu="exit"
					break
				elif [ "$country_select" = "n" ] || [ "$country_select" = "N" ]; then
					choosecountry="false"
					break
				elif [ "$country_select" = "y" ] || [ "$country_select" = "Y" ]; then
					choosecountry="true"
					break
				else
					printf "\\n\\e[31mPlease enter y or n\\e[0m\\n"
				fi
			done
		fi
		
		if [ "$choosecountry" = "true" ]; then
			countrydata="$(cat "$SCRIPT_DIR/vpncountrydata")"
			[ -z "$countrydata" ] && Print_Output "true" "Error, country data from NordVPN is missing" "$ERR" && return 1
			LISTCOUNTRIES="$(getCountryNames "$countrydata")"
			COUNTCOUNTRIES="$(echo "$LISTCOUNTRIES" | wc -l)"
			while true; do
				printf "\\n\\e[1mPlease select a country:\\e[0m\\n"
				COUNTER="1"
				#shellcheck disable=SC2039
				IFS=$'\n'
				for COUNTRY in $LISTCOUNTRIES; do
					printf "    %s. %s\\n" "$COUNTER" "$COUNTRY"
					COUNTER=$((COUNTER+1))
				done
				unset IFS
				
				printf "Choose an option:    "
				read -r "country_choice"
				
				if [ "$country_choice" = "e" ]; then
					exitmenu="exit"
					break
				elif ! Validate_Number "" "$country_choice" "silent"; then
					printf "\\n\\e[31mPlease enter a valid number (1-%s)\\e[0m\\n" "$COUNTCOUNTRIES"
				else
					if [ "$country_choice" -lt 1 ] || [ "$country_choice" -gt "$COUNTCOUNTRIES" ]; then
						printf "\\n\\e[31mPlease enter a number between 1 and %s\\e[0m\\n" "$COUNTCOUNTRIES"
					else
						countryname="$(echo "$LISTCOUNTRIES" | sed -n "$country_choice"p)"
						countryid="$(getCountryID "$countrydata" "$countryname")"
						printf "\\n"
						break
					fi
				fi
			done
		
			if [ "$exitmenu" != "exit" ]; then
				citycount="$(getCityCount "$countrydata" "$countryname")"
				if [ "$citycount" -eq "1" ]; then
					cityname="$(getCityNames "$countrydata" "$countryname")"
					cityid="$(getCityID "$countrydata" "$countryname" "$cityname")"
				elif [ "$citycount" -gt "1" ]; then
					while true; do
						printf "\\n\\e[1mWould you like to select a city (y/n)?\\e[0m    "
						read -r "city_select"
						
						if [ "$city_select" = "e" ]; then
							exitmenu="exit"
							break
						elif [ "$city_select" = "n" ] || [ "$city_select" = "N" ]; then
							choosecity="false"
							break
						elif [ "$city_select" = "y" ] || [ "$city_select" = "Y" ]; then
							choosecity="true"
							break
						else
							printf "\\n\\e[31mPlease enter y or n\\e[0m\\n"
						fi
					done
				fi
			fi
			
			if [ "$choosecity" = "true" ]; then
				LISTCITIES="$(getCityNames "$countrydata" "$countryname")"
				COUNTCITIES="$(echo "$LISTCITIES" | wc -l)"
				while true; do
					printf "\\n\\e[1mPlease select a city:\\e[0m\\n"
					COUNTER="1"
					#shellcheck disable=SC2039
					IFS=$'\n'
					for CITY in $LISTCITIES; do
						printf "    %s. %s\\n" "$COUNTER" "$CITY"
						COUNTER=$((COUNTER+1))
					done
					unset IFS
					
					printf "Choose an option:    "
					read -r "city_choice"
					
					if [ "$city_choice" = "e" ]; then
						exitmenu="exit"
						break
					elif ! Validate_Number "" "$city_choice" "silent"; then
						printf "\\n\\e[31mPlease enter a valid number (1-%s)\\e[0m\\n" "$COUNTCITIES"
					else
						if [ "$city_choice" -lt 1 ] || [ "$city_choice" -gt "$COUNTCITIES" ]; then
							printf "\\n\\e[31mPlease enter a number between 1 and %s\\e[0m\\n" "$COUNTCITIES"
						else
							cityname="$(echo "$LISTCITIES" | sed -n "$city_choice"p)"
							cityid="$(getCityID "$countrydata" "$countryname" "$cityname")"
							printf "\\n"
							break
						fi
					fi
				done
			fi
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		GLOBAL_VPN_NO="$vpnnum"
		GLOBAL_VPN_PROVIDER="$vpnprovider"
		GLOBAL_VPN_PROT="$vpnprot"
		GLOBAL_VPN_TYPE="$vpntype"
		GLOBAL_COUNTRY_NAME="$countryname"
		GLOBAL_COUNTRY_ID="$countryid"
		GLOBAL_CITY_NAME="$cityname"
		GLOBAL_CTIY_ID="$cityid"
		return 0
	else
		return 1
	fi
}

SetScheduleParameters(){
	exitmenu=""
	vpnnum=""
	crudays=""
	cruhours=""
	crumins=""
	
	while true; do
		printf "\\n\\e[1mPlease enter the VPN client number (1-5):\\e[0m    "
		read -r "vpn_choice"
		
		if [ "$vpn_choice" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Number "" "$vpn_choice" "silent"; then
			printf "\\n\\e[31mPlease enter a valid number (1-5)\\e[0m\\n"
		else
			if [ "$vpn_choice" -lt 1 ] || [ "$vpn_choice" -gt 5 ]; then
				printf "\\n\\e[31mPlease enter a number between 1 and 5\\e[0m\\n"
			else
				vpnnum="$vpn_choice"
				printf "\\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		if [ "$(grep "vpn""$vpnnum""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			Print_Output "false" "VPN client $vpnnum is not managed, cannot enable schedule" "$ERR"
			return 1
		fi
		while true; do
			printf "\\n\\e[1mPlease choose which day(s) to update VPN configuration (0-6, * for every day, or comma separated days):\\e[0m    "
			read -r "day_choice"
			
			if [ "$day_choice" = "e" ]; then
				exitmenu="exit"
				break
			elif [ "$day_choice" = "*" ]; then
				crudays="$day_choice"
				printf "\\n"
				break
			else
				crudaystmp="$(echo "$day_choice" | sed "s/,/ /g")"
				crudaysvalidated="true"
				for i in $crudaystmp; do
					if ! Validate_Number "" "$i" "silent"; then
						printf "\\n\\e[31mPlease enter a valid number (0-6) or comma separated values\\e[0m\\n"
						crudaysvalidated="false"
						break
					else
						if [ "$i" -lt 0 ] || [ "$i" -gt 6 ]; then
							printf "\\n\\e[31mPlease enter a number between 0 and 6 or comma separated values\\e[0m\\n"
							crudaysvalidated="false"
							break
						fi
					fi
				done
				if [ "$crudaysvalidated" = "true" ]; then
					crudays="$day_choice"
					printf "\\n"
					break
				fi
			fi
		done
	fi
		
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease choose which hour(s) to update VPN configuration (0-23, * for every hour, or comma separated hours):\\e[0m    "
			read -r "hour_choice"
			
			if [ "$hour_choice" = "e" ]; then
				exitmenu="exit"
				break
			elif [ "$hour_choice" = "*" ]; then
				cruhours="$hour_choice"
				printf "\\n"
				break
			else
				cruhourstmp="$(echo "$hour_choice" | sed "s/,/ /g")"
				cruhoursvalidated="true"
				for i in $cruhourstmp; do
					if ! Validate_Number "" "$i" "silent"; then
						printf "\\n\\e[31mPlease enter a valid number (0-23) or comma separated values\\e[0m\\n"
						cruhoursvalidated="false"
						break
					else
						if [ "$i" -lt 0 ] || [ "$i" -gt 23 ]; then
							printf "\\n\\e[31mPlease enter a number between 0 and 23 or comma separated values\\e[0m\\n"
							cruhoursvalidated="false"
							break
						fi
					fi
				done
				if [ "$cruhoursvalidated" = "true" ]; then
					cruhours="$hour_choice"
					printf "\\n"
					break
				fi
			fi
		done
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease choose which minutes(s) to update VPN configuration (0-59, * for every minute, or comma separated minutes):\\e[0m    "
			read -r "min_choice"
			
			if [ "$min_choice" = "e" ]; then
				exitmenu="exit"
				break
			elif [ "$min_choice" = "*" ]; then
				crumins="$min_choice"
				printf "\\n"
				break
			else
				cruminstmp="$(echo "$min_choice" | sed "s/,/ /g")"
				cruminsvalidated="true"
				for i in $cruminstmp; do
					if ! Validate_Number "" "$i" "silent"; then
						printf "\\n\\e[31mPlease enter a valid number (0-59) or comma separated values\\e[0m\\n"
						cruminsvalidated="false"
						break
					else
						if [ "$i" -lt 0 ] || [ "$i" -gt 59 ]; then
							printf "\\n\\e[31mPlease enter a number between 0 and 59 or comma separated values\\e[0m\\n"
							cruminsvalidated="false"
							break
						fi
					fi
				done
				if [ "$cruminsvalidated" = "true" ]; then
					crumins="$min_choice"
					printf "\\n"
					break
				fi
			fi
		done
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		GLOBAL_VPN_NO="$vpnnum"
		GLOBAL_CRU_DAYNUMBERS="$crudays"
		GLOBAL_CRU_HOURS="$cruhours"
		GLOBAL_CRU_MINS="$crumins"
		return 0
	else
		return 1
	fi
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
	printf "\\e[1m###################################################\\e[0m\\n"
	printf "\\e[1m##                                               ##\\e[0m\\n"
	printf "\\e[1m## __   __ _ __   _ __   _ __ ___    __ _  _ __  ##\\e[0m\\n"
	printf "\\e[1m## \ \ / /| '_ \ | '_ \ | '_   _ \  / _  || '__| ##\\e[0m\\n"
	printf "\\e[1m##  \ V / | |_) || | | || | | | | || (_| || |    ##\\e[0m\\n"
	printf "\\e[1m##   \_/  | .__/ |_| |_||_| |_| |_| \__, ||_|    ##\\e[0m\\n"
	printf "\\e[1m##        | |                        __/ |       ##\\e[0m\\n"
	printf "\\e[1m##        |_|                       |___/        ##\\e[0m\\n"
	printf "\\e[1m##                                               ##\\e[0m\\n"
	printf "\\e[1m##               %s on %-9s             ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                               ##\\e[0m\\n"
	printf "\\e[1m##       https://github.com/jackyaz/vpnmgr       ##\\e[0m\\n"
	printf "\\e[1m##                                               ##\\e[0m\\n"
	printf "\\e[1m###################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    List VPN client configurations\\n\\n"
	printf "2.    Update configuration for a managed VPN client\\n\\n"
	printf "3.    Enable management for a VPN client\\n"
	printf "4.    Disable management for a VPN client\\n\\n"
	
	printf "\\e[1m###########         NordVPN only        ###########\\e[0m\\n\\n"
	printf "5.    Search for new recommended server\\n"
	printf "6.    Update schedule for a VPN client\\n"
	printf "7.    Enable a scheduled VPN client update\\n"
	printf "8.    Delete a scheduled VPN client update\\n\\n"
	printf "\\e[1m###################################################\\e[0m\\n\\n"
	printf "r.    Refresh cached data from VPN providers\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m###################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				Menu_ListVPN
				PressEnter
				break
			;;
			2)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_UpdateVPN
				fi
				PressEnter
				break
			;;
			3)
				printf "\\n"
				Menu_ManageVPN
				PressEnter
				break
			;;
			4)
				printf "\\n"
				Menu_UnmanageVPN
				PressEnter
				break
			;;
			5)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_SearchVPN
				fi
				PressEnter
				break
			;;
			6)
				printf "\\n"
				Menu_ScheduleVPN
				PressEnter
				break
			;;
			7)
				printf "\\n"
				Menu_EnableScheduleVPN
				PressEnter
				break
			;;
			8)
				printf "\\n"
				Menu_CancelScheduleVPN
				PressEnter
				break
			;;
			r)
				printf "\\n"
				getCountryData
				getOVPNArchives
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

Menu_ListVPN(){
	ScriptHeader
	ListVPNClients
}

Menu_UpdateVPN(){
	ScriptHeader
	ListVPNClients
	printf "Choose options as follows:\\n"
	printf "    - VPN client [1-5]\\n"
	printf "    - VPN provider (pick from list)\\n"
	printf "    - type of VPN (pick from list)\\n"
	printf "    - protocol (pick from list)\\n"
	printf "    - country/city of VPN Server (pick from list)\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	if SetVPNParameters; then
		VPN_PROT_SHORT="$(echo "$GLOBAL_VPN_PROT" | cut -f2 -d'_' | tr "a-z" "A-Z")"
		VPN_TYPE_SHORT="$(echo "$GLOBAL_VPN_TYPE" | cut -f2 -d'_')"
		if [ "$VPN_TYPE_SHORT" = "p2p" ]; then
			VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | tr "a-z" "A-Z")"
		else
			VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')"
		fi
		
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_managed.*$/vpn'"$GLOBAL_VPN_NO"'_managed=true/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_provider.*$/vpn'"$GLOBAL_VPN_NO"'_provider='"$GLOBAL_VPN_PROVIDER"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_type.*$/vpn'"$GLOBAL_VPN_NO"'_type='"$VPN_TYPE_SHORT"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_protocol.*$/vpn'"$GLOBAL_VPN_NO"'_protocol='"$VPN_PROT_SHORT"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_countryname.*$/vpn'"$GLOBAL_VPN_NO"'_countryname='"$GLOBAL_COUNTRY_NAME"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_countryid.*$/vpn'"$GLOBAL_VPN_NO"'_countryid='"$GLOBAL_COUNTRY_ID"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_cityname.*$/vpn'"$GLOBAL_VPN_NO"'_cityname='"$GLOBAL_CITY_NAME"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_cityid.*$/vpn'"$GLOBAL_VPN_NO"'_cityid='"$GLOBAL_CTIY_ID"'/' "$SCRIPT_CONF"
		UpdateVPNConfig "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client update cancelled" "$WARN"
	fi
	Clear_Lock
}

Menu_SearchVPN(){
	if SetVPNClient; then
		if [ "$(grep "vpn""$GLOBAL_VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			Print_Output "false" "VPN client $GLOBAL_VPN_NO is not managed, cannot search for new server" "$ERR"
			return 1
		fi
		UpdateVPNConfig "unattended" "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN server search cancelled" "$WARN"
	fi
	Clear_Lock
}

Menu_ManageVPN(){
	if SetVPNClient; then
		ManageVPN "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client management enabling cancelled" "$WARN"
	fi
}

Menu_UnmanageVPN(){
	if SetVPNClient; then
		UnmanageVPN "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client management removal cancelled" "$WARN"
	fi
}

Menu_ScheduleVPN(){
	ScriptHeader
	ListVPNClients
	printf "Choose options as follows:\\n"
	printf "    - VPN client [1-5]\\n"
	printf "    - day(s) to update [0-6]\\n"
	printf "    - hour(s) to update [0-23]\\n"
	printf "    - minute(s) to update [0-59]\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	if SetScheduleParameters; then
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_managed.*$/vpn'"$GLOBAL_VPN_NO"'_managed=true/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_schenabled.*$/vpn'"$GLOBAL_VPN_NO"'_schenabled=true/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_schdays.*$/vpn'"$GLOBAL_VPN_NO"'_schdays='"$(echo "$GLOBAL_CRU_DAYNUMBERS" | sed 's/0/Sun/;s/1/Mon/;s/2/Tues/;s/3/Wed/;s/4/Thurs/;s/5/Fri/;s/6/Sat/;')"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_schhours.*$/vpn'"$GLOBAL_VPN_NO"'_schhours='"$GLOBAL_CRU_HOURS"'/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_schmins.*$/vpn'"$GLOBAL_VPN_NO"'_schmins='"$GLOBAL_CRU_MINS"'/' "$SCRIPT_CONF"
		ScheduleVPN "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client update scheduling cancelled" "$WARN"
	fi
}

Menu_EnableScheduleVPN(){
	if SetVPNClient; then
		if [ "$(grep "vpn""$GLOBAL_VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			Print_Output "false" "VPN client $GLOBAL_VPN_NO is not managed, cannot enable schedule" "$ERR"
			return 1
		fi
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_managed.*$/vpn'"$GLOBAL_VPN_NO"'_managed=true/' "$SCRIPT_CONF"
		sed -i 's/^vpn'"$GLOBAL_VPN_NO"'_schenabled.*$/vpn'"$GLOBAL_VPN_NO"'_schenabled=true/' "$SCRIPT_CONF"
		ScheduleVPN "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client schedule enabling cancelled" "$WARN"
	fi
}

Menu_CancelScheduleVPN(){
	if SetVPNClient; then
		if [ "$(grep "vpn""$GLOBAL_VPN_NO""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
			Print_Output "false" "VPN client $GLOBAL_VPN_NO is not managed, cannot cancel schedule" "$ERR"
			return 1
		fi
		sed -i 's/^vpn'"$VPN_NO"'_schenabled.*$/vpn'"$VPN_NO"'_schenabled=false/' "$SCRIPT_CONF"
		CancelScheduleVPN "$GLOBAL_VPN_NO"
	else
		printf "\\n"
		Print_Output "false" "VPN client schedule cancellation cancelled" "$WARN"
	fi
}

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
		opkg install p7zip
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
	
	Process_Upgrade
	
	Create_Dirs
	Conf_Exists
	Create_Symlinks
	Auto_Cron create 2>/dev/null
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	
	Update_File "vpnmgr_www.asp"
	Update_File "shared-jy.tar.gz"
	
	getCountryData
	getOVPNArchives
	
	Shortcut_vpnmgr create
	Clear_Lock
}

Menu_Startup(){
	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings "local"
	Create_Symlinks
	Auto_Cron create 2>/dev/null
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_vpnmgr create
	Mount_WebUI
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
	
	Auto_Cron delete 2>/dev/null
	Auto_Startup delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -rf "$SCRIPT_DIR" 2>/dev/null
	
	Shortcut_vpnmgr delete
	
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$1" = "service_event" ]; then
		if [ -n "$2" ] && [ "$(echo "$3" | grep -c "$SCRIPT_NAME")" -eq 0 ]; then
			exit 0
		fi
	fi
	if [ "$(nvram get ntp_ready)" = "0" ]; then
		ntpwaitcount="0"
		Check_Lock
		while [ "$(nvram get ntp_ready)" = "0" ] && [ "$ntpwaitcount" -lt "300" ]; do
			ntpwaitcount="$((ntpwaitcount + 1))"
			if [ "$ntpwaitcount" = "60" ]; then
				Print_Output "true" "Waiting for NTP to sync..." "$WARN"
			fi
			sleep 1
		done
		if [ "$ntpwaitcount" -ge "300" ]; then
			Print_Output "true" "NTP failed to sync after 5 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output "true" "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready(){
	if [ "$1" = "service_event" ]; then
		if [ -n "$2" ] && [ "$(echo "$3" | grep -c "$SCRIPT_NAME")" -eq 0 ]; then
			exit 0
		fi
	fi
	
	if [ ! -f "/opt/bin/opkg" ] && ! echo "$@" | grep -wqE "(install|uninstall|update|forceupdate)"; then
		Check_Lock
		sleepcount=1
		while [ ! -f "/opt/bin/opkg" ] && [ "$sleepcount" -le 10 ]; do
			Print_Output "true" "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f "/opt/bin/opkg" ]; then
			Print_Output "true" "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output "true" "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}
### ###

Process_Upgrade(){
	if grep -q "^nvpnmgr" /jffs/addons/custom_settings.txt; then
		sed -i "s/nvpnmgr/vpnmgr/g" /jffs/addons/custom_settings.txt
	fi
	if grep -q "nvpnmgr" "/var/spool/cron/crontabs/$USER"; then
		sed -i "s/nvpnmgr/vpnmgr/g" "/var/spool/cron/crontabs/$USER"
	fi
	if [ -d /jffs/addons/nvpnmgr.d ]; then
		mv /jffs/addons/nvpnmgr.d /jffs/addons/vpnmgr.d
	fi
	if [ -f /jffs/addons/vpnmgr.d/nvpnmgr_www.asp ]; then
		rm -f /jffs/addons/vpnmgr.d/nvpnmgr_www.asp
	fi
	if [ -f /jffs/addons/vpnmgr.d/nvpncountrydata ]; then
		rm -f /jffs/addons/vpnmgr.d/nvpncountrydata
	fi
	if [ -f /opt/bin/nvpnmgr ]; then
		rm -f /opt/bin/nvpnmgr
	fi
	if [ -f /jffs/scripts/nvpnmgr ]; then
		mv /jffs/scripts/nvpnmgr /jffs/scripts/vpnmgr
		exec /jffs/scripts/vpnmgr
		exit 1
	fi
}

NTP_Ready "$@"
Entware_Ready "$@"

if [ -z "$1" ]; then
	if [ ! -f /opt/bin/7z ]; then
		opkg update
		opkg install p7zip
	fi
	Process_Upgrade
	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings "local"
	Auto_Cron create 2>/dev/null
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_vpnmgr create
	if [ ! -f "$SCRIPT_DIR/vpncountrydata" ]; then
		getCountryData
	fi
	if [ "$(ls -l $OVPN_ARCHIVE_DIR | wc -l)" -lt "4" ]; then
		getOVPNArchives
	fi
	
	Create_Symlinks
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
	updatevpn)
		UpdateVPNConfig "unattended" "$2"
		exit 0
	;;
	refreshcacheddata)
		getCountryData
		getOVPNArchives
		exit 0
	;;
	startup)
		Check_Lock
		Print_Output "true" "Sleeping for 30s before running startup routine" ""
		sleep 30
		Menu_Startup
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Check_Lock
			Conf_FromSettings
			for i in 1 2 3 4 5; do
				if [ "$(grep "vpn""$i""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
					ManageVPN "$i"
					if [ "$(grep "vpn""$i""_schenabled" "$SCRIPT_CONF" | cut -f2 -d"=")" = "true" ]; then
						ScheduleVPN "$i"
					elif [ "$(grep "vpn""$i""_schenabled" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
						CancelScheduleVPN "$i"
					fi
					UpdateVPNConfig "unattended" "$i"
				elif [ "$(grep "vpn""$i""_managed" "$SCRIPT_CONF" | cut -f2 -d"=")" = "false" ]; then
					UnmanageVPN "$i"
				fi
			done
			Clear_Lock
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME""refreshcacheddata" ]; then
			getCountryData
			getOVPNArchives
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME""checkupdate" ]; then
			Check_Lock
			updatecheckresult="$(Update_Check)"
			Clear_Lock
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME""doupdate" ]; then
			Check_Lock
			Update_Version "force" "unattended"
			Clear_Lock
			exit 0
		fi
		exit 0
	;;
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
