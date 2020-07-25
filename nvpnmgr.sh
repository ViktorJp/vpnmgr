#!/bin/sh

/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/vpnmgr/master/vpnmgr.sh" -o "/jffs/scripts/vpnmgr" && chmod 0755 /jffs/scripts/vpnmgr && /jffs/scripts/vpnmgr
