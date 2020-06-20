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
##                forked from h0me5k1n                 ##
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
GLOBAL_VPN_NO=""
GLOBAL_VPN_PROT=""
GLOBAL_VPN_TYPE=""
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

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
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
	/usr/sbin/curl -fsL --retry 3 "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=$1&filters\[servers_technologies\]\[identifier\]=$2&limit=1"
}

# use to create content of OVPN_IP variable
getIP(){
	echo "$1" | jq -e '.[].station // empty' | tr -d '"'
}

# use to create content of OVPN_HOSTNAME variable
getHostname(){
	echo "$1" | jq -e '.[].hostname // empty' | tr -d '"'
}

# use to create content of OVPN_DETAIL variable
getOVPNcontents(){
	/usr/sbin/curl -fsL --retry 3 "https://downloads.nordcdn.com/configs/files/ovpn_$2/servers/$1"
}

# use to create content of OVPN_PORT variable
getPort(){
	echo "$1" | grep "^remote " | cut -f3 -d' '
}

# use to create content of OVPN_CIPHER variable
getCipher(){
	echo "$1" | grep "^cipher " | cut -f2 -d' '
}

# use to create content of OVPN_AUTHDIGEST variable
getAuthDigest(){
	echo "$1" | grep "^auth " | cut -f2 -d' '
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

# use to create content of EXISTING_IP variable
getServerIP(){
	nvram get vpn_client"$1"_addr
}

# use to create content of CONNECTSTATE variable - set to 2 if the VPN is connected
getConnectState(){
	nvram get vpn_client"$1"_state
}

ListVPNClients(){
	printf "VPN client List:\\n\\n"
	for i in 1 2 3 4 5; do
		VPN_CLIENTDESC="$(nvram get vpn_client"$i"_desc)"
		CONNECTSTATE=""
		SCHEDULESTATE=""
		if [ "$(getConnectState "$i")" = "2" ]; then
			CONNECTSTATE="Active"
		else
			CONNECTSTATE="Inactive"
		fi
		if ! cru l | grep -q "#$SCRIPT_NAME""_VPN""$i#"; then
			SCHEDULESTATE="Unscheduled"
		else
			SCHEDULESTATE="Scheduled"
		fi
		printf "%s.    %s (%s and %s)\\n" "$i" "$VPN_CLIENTDESC" "$CONNECTSTATE" "$SCHEDULESTATE"
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
	VPN_PROT="$2"
	VPN_PROT_SHORT="$(echo "$VPN_PROT" | cut -f2 -d'_')"
	VPN_TYPE="$3"
	VPN_TYPE_SHORT="$(echo "$VPN_TYPE" | cut -f2 -d'_')"
	Print_Output "true" "Retrieving recommended VPN server using NordVPN API" "$PASS"
	
	vJSON="$(getRecommended "$VPN_TYPE" "$VPN_PROT")"
	[ -z "$vJSON" ] && Print_Output "true" "Error contacting NordVPN API" "$ERR" && return 1
	OVPN_IP="$(getIP "$vJSON")"
	[ -z "$OVPN_IP" ] && Print_Output "true" "Could not determine IP for recommended VPN server" "$ERR" && return 1
	OVPN_HOSTNAME="$(getHostname "$vJSON")"
	[ -z "$OVPN_HOSTNAME" ] && Print_Output "true" "Could not determine hostname for recommended VPN server" "$ERR" && return 1
	#shellcheck disable=SC2018
	#shellcheck disable=SC2019
	OVPN_HOSTNAME_SHORT="$(echo "$OVPN_HOSTNAME" | cut -f1 -d'.' | tr "a-z" "A-Z")"
	OVPNFILE="$OVPN_HOSTNAME.$VPN_PROT_SHORT.ovpn"
	OVPN_DETAIL="$(getOVPNcontents "$OVPNFILE" "$VPN_PROT_SHORT")"
	[ -z "$OVPN_DETAIL" ] && Print_Output "true" "Error downloading VPN server ovpn file" "$ERR" && return 1
	OVPN_PORT="$(getPort "$OVPN_DETAIL")"
	[ -z "$OVPN_PORT" ] && Print_Output "true" "Error determining port for recommended VPN server" "$ERR" && return 1
	OVPN_CIPHER="$(getCipher "$OVPN_DETAIL")"
	[ -z "$OVPN_CIPHER" ] && Print_Output "true" "Error determining cipher for recommended VPN server" "$ERR" && return 1
	OVPN_AUTHDIGEST="$(getAuthDigest "$OVPN_DETAIL")"
	[ -z "$OVPN_AUTHDIGEST" ] && Print_Output "true" "Error determining auth digest for recommended VPN server" "$ERR" && return 1
	CLIENT_CA="$(getClientCA "$OVPN_DETAIL")"
	[ -z "$CLIENT_CA" ] && Print_Output "true" "Error determing VPN server Certificate Authority certificate" "$ERR" && return 1
	CRT_CLIENT_STATIC="$(getClientCRT "$OVPN_DETAIL")"
	[ -z "$CRT_CLIENT_STATIC" ] && Print_Output "true" "Error determing VPN client certificate" "$ERR" && return 1
	EXISTING_IP="$(getServerIP "$VPN_NO")"
	CONNECTSTATE="$(getConnectState "$VPN_NO")"
	
	if [ "$OVPN_IP" != "$EXISTING_IP" ]; then
		Print_Output "true" "Updating VPN client $VPN_NO to recommended NordVPN server" "$PASS"
		
		#shellcheck disable=SC2018
		#shellcheck disable=SC2019
		VPN_PROT_SHORT="$(echo "$VPN_PROT_SHORT" | tr "a-z" "A-Z")"
		if [ "$VPN_TYPE_SHORT" = "p2p" ]; then
			#shellcheck disable=SC2018
			#shellcheck disable=SC2019
			VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | tr "a-z" "A-Z")"
		else
			VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')"
		fi
		
		nvram set vpn_client"$VPN_NO"_addr="$OVPN_IP"
		nvram set vpn_client"$VPN_NO"_port="$OVPN_PORT"
		if [ "$VPN_PROT_SHORT" = "TCP" ]; then
			nvram set vpn_client"$VPN_NO"_proto="tcp-client"
		elif [ "$VPN_PROT_SHORT" = "UDP" ]; then
			nvram set vpn_client"$VPN_NO"_proto="udp"
		fi
		nvram set vpn_client"$VPN_NO"_desc="NordVPN $OVPN_HOSTNAME_SHORT $VPN_TYPE_SHORT $VPN_PROT_SHORT"
		
		nvram set vpn_client"$VPN_NO"_adns="3"
		nvram set vpn_client"$VPN_NO"_cipher="$OVPN_CIPHER"
		nvram set vpn_client"$VPN_NO"_comp="-1"
		nvram set vpn_client"$VPN_NO"_connretry="-1"
		nvram set vpn_client"$VPN_NO"_crypt="tls"
		nvram set vpn_client"$VPN_NO"_digest="$OVPN_AUTHDIGEST"
		nvram set vpn_client"$VPN_NO"_enforce="1"
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
		
		if [ "$(/bin/uname -m)" = "aarch64" ]; then
			nvram set vpn_client"$VPN_NO"_cust2="cmVtb3RlLXJhbmRvbQp0dW4tbXR1IDE1MDAKdHVuLW10dS1leHRyYSAzMgptc3NmaXggMTQ1MApwaW5nIDE1CnBpbmctcmVzdGFydCAwCnBpbmctdGltZXItcmVtCnJlbW90ZS1jZXJ0LXRscyBzZXJ2ZXIKcGVyc2lzdC1rZXkKcGVyc2lzdC10dW4KcmVuZWctc2VjIDAKZGlzYWJsZS1vY2MKbXV0ZS1yZXBsYXktd2FybmluZ3MKYXV0aC1"
			nvram set vpn_client"$VPN_NO"_cust21="ub2NhY2hlCnNuZGJ1ZiA1MjQyODgKcmN2YnVmIDUyNDI4OApwdXNoICJzbmRidWYgNTI0Mjg4IgpwdXNoICJyY3ZidWYgNTI0Mjg4IgpwdWxsLWZpbHRlciBpZ25vcmUgImF1dGgtdG9rZW4iCnB1bGwtZmlsdGVyIGlnbm9yZSAiaWZjb25maWctaXB2NiIKcHVsbC1maWx0ZXIgaWdub3JlICJyb3V0ZS1pcHY2Ig=="
		elif [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
			nvram set vpn_client"$VPN_NO"_cust2="cmVtb3RlLXJhbmRvbQp0dW4tbXR1IDE1MDAKdHVuLW10dS1leHRyYSAzMgptc3NmaXggMTQ1MApwaW5nIDE1CnBpbmctcmVzdGFydCAwCnBpbmctdGltZXItcmVtCnJlbW90ZS1jZXJ0LXRscyBzZXJ2ZXIKcGVyc2lzdC1rZXkKcGVyc2lzdC10dW4KcmVuZWctc2VjIDAKZGlzYWJsZS1vY2MKbXV0ZS1yZXBsYXktd2FybmluZ3MKYXV0aC1ub2NhY2hlCnNuZGJ1ZiA1MjQyODgKcmN2YnVmIDUyNDI4OApwdXNoICJzbmRidWYgNTI0Mjg4IgpwdXNoICJyY3ZidWYgNTI0Mjg4IgpwdWxsLWZpbHRlciBpZ25vcmUgImF1dGgtdG9rZW4iCnB1bGwtZmlsdGVyIGlnbm9yZSAiaWZjb25maWctaXB2NiIKcHVsbC1maWx0ZXIgaWdub3JlICJyb3V0ZS1pcHY2Ig=="
		else
			nvram set vpn_client"$VPN_NO"_custom='remote-random
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ping 15
ping-restart 0
ping-timer-rem
explicit-exit-notify 3
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
		
		if [ "$CONNECTSTATE" = "2" ]; then
			service stop_vpnclient"$VPN_NO" >/dev/null 2>&1
			sleep 3
			service start_vpnclient"$VPN_NO" >/dev/null 2>&1
		fi
		Print_Output "true" "VPN client $VPN_NO updated successfully ($OVPN_HOSTNAME_SHORT $VPN_TYPE_SHORT $VPN_PROT_SHORT)" "$PASS"
	else
		Print_Output "true" "VPN client $VPN_NO is already using the recommended server" "$WARN"
	fi
}

ScheduleVPN(){
	VPN_NO="$1"
	VPN_PROT="$2"
	VPN_PROT_SHORT="$(echo "$VPN_PROT" | cut -f2 -d'_')"
	VPN_TYPE="$3"
	VPN_TYPE_SHORT="$(echo "$VPN_TYPE" | cut -f2 -d'_')"
	CRU_DAYNUMBERS="$4"
	CRU_HOURS="$5"
	CRU_MINUTES="$6"
	
	Print_Output "true" "Configuring scheduled update for VPN client $VPN_NO" "$PASS"
	
	if cru l | grep -q "$SCRIPT_NAME$VPN_NO"; then
		cru d "$SCRIPT_NAME""_VPN""$VPN_NO"
	fi
	
	cru a "$SCRIPT_NAME""_VPN""$VPN_NO" "$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO $VPN_PROT $VPN_TYPE"
	
	if [ -f /jffs/scripts/services-start ]; then
		sed -i "/$SCRIPT_NAME""_VPN""$VPN_NO/d" /jffs/scripts/services-start
		echo "cru a $SCRIPT_NAME""_VPN""$VPN_NO \"$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO $VPN_PROT $VPN_TYPE\" # $SCRIPT_NAME" >> /jffs/scripts/services-start
	else
		echo "#!/bin/sh" >> /jffs/scripts/services-start
		echo "cru a $SCRIPT_NAME""_VPN""$VPN_NO \"$CRU_MINUTES $CRU_HOURS * * $CRU_DAYNUMBERS /jffs/scripts/$SCRIPT_NAME updatevpn $VPN_NO $VPN_PROT $VPN_TYPE\" # $SCRIPT_NAME" >> /jffs/scripts/services-start
		chmod 755 /jffs/scripts/services-start
	fi
	
	#shellcheck disable=SC2018
	#shellcheck disable=SC2019
	VPN_PROT_SHORT="$(echo "$VPN_PROT_SHORT" | tr "a-z" "A-Z")"
	if [ "$VPN_TYPE_SHORT" = "p2p" ]; then
		#shellcheck disable=SC2018
		#shellcheck disable=SC2019
		VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | tr "a-z" "A-Z")"
	else
		VPN_TYPE_SHORT="$(echo "$VPN_TYPE_SHORT" | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')"
	fi
	Print_Output "true" "Scheduled update created for VPN client $VPN_NO ($VPN_TYPE_SHORT $VPN_PROT_SHORT)" "$PASS"
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
		Print_Output "true" "No schedule to cancel for VPN client $VPN_NO" "$WARN"
	fi
}

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

SetVPNParameters(){
	exitmenu=""
	vpnnum=""
	vpnprot=""
	vpntype=""
	
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
	
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease select a VPN Type:\\e[0m\\n"
			printf "    1. Standard VPN\\n"
			printf "    2. Double VPN\\n"
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
	fi
	
	if [ "$exitmenu" != "exit" ]; then
		GLOBAL_VPN_NO="$vpnnum"
		GLOBAL_VPN_PROT="$vpnprot"
		GLOBAL_VPN_TYPE="$vpntype"
		return 0
	else
		return 1
	fi
}

SetScheduleParameters(){
	exitmenu=""
	crudays=""
	cruhours=""
	crumins=""
	
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
	
	if [ "$exitmenu" != "exit" ]; then
		while true; do
			printf "\\n\\e[1mPlease choose which hour(s) to update VPN configuration (0-23, * for every day, or comma separated hours):\\e[0m    "
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
			printf "\\n\\e[1mPlease choose which minutes(s) to update VPN configuration (0-59, * for every day, or comma separated minutes):\\e[0m    "
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
	printf "\\e[1m##                forked from h0me5k1n                 ##\\e[0m\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    List VPN client configurations\\n"
	printf "2.    Update a VPN client configuration now\\n"
	printf "3.    Schedule a VPN client configuration update\\n"
	printf "4.    Delete a scheduled VPN client configuration update\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
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
				Menu_ScheduleVPN
				PressEnter
				break
			;;
			4)
				printf "\\n"
				Menu_CancelScheduleVPN
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
	printf "    - protocol to use (pick from list)\\n"
	printf "    - type of VPN to use (pick from list)\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	if SetVPNParameters; then
		UpdateVPNConfig "$GLOBAL_VPN_NO" "$GLOBAL_VPN_PROT" "$GLOBAL_VPN_TYPE"
	else
		printf "\\n"
		Print_Output "true" "VPN client update cancelled" "$WARN"
	fi
	Clear_Lock
}

Menu_ScheduleVPN(){
	ScriptHeader
	ListVPNClients
	printf "Choose options as follows:\\n"
	printf "    - VPN client [1-5]\\n"
	printf "    - protocol to use (pick from list)\\n"
	printf "    - type of VPN to use (pick from list)\\n"
	printf "    - day(s) to update [0-6]\\n"
	printf "    - hour(s) to update [0-23]\\n"
	printf "    - minute(s) to update [0-59]\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	if SetVPNParameters; then
			SetScheduleParameters
			ScheduleVPN "$GLOBAL_VPN_NO" "$GLOBAL_VPN_PROT" "$GLOBAL_VPN_TYPE" "$GLOBAL_CRU_DAYNUMBERS" "$GLOBAL_CRU_HOURS" "$GLOBAL_CRU_MINS"
	else
		printf "\\n"
		Print_Output "true" "VPN client update scheduling cancelled" "$WARN"
	fi
}

Menu_CancelScheduleVPN(){
	ScriptHeader
	ListVPNClients
	printf "Choose options as follows:\\n"
	printf "    - VPN client [1-5]\\n"
	printf "\\n"
	printf "\\e[1m#########################################################\\e[0m\\n"
	
	exitmenu=""
	cancelnum=""
	
	while true; do
		printf "\\n\\e[1mPlease enter the VPN client number (1-5):\\e[0m    "
		read -r "cancel_choice"
		
		if [ "$cancel_choice" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Number "" "$cancel_choice" "silent"; then
			printf "\\n\\e[31mPlease enter a valid number (1-5)\\e[0m\\n"
		else
			if [ "$cancel_choice" -lt 1 ] || [ "$cancel_choice" -gt 5 ]; then
				printf "\\n\\e[31mPlease enter a number between 1 and 5\\e[0m\\n"
			else
				cancelnum="$cancel_choice"
				printf "\\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		CancelScheduleVPN "$cancelnum"
	else
		printf "\\n"
		Print_Output "true" "VPN client schedule cancellation cancelled" "$WARN"
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
	updatevpn)
		UpdateVPNConfig "unattended" "$2" "$3" "$4"
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
