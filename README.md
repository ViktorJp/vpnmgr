# vpnmgr
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/50f9c2244ef74cefb3da37448dd69848)](https://www.codacy.com/manual/jackyaz/vpnmgr?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/vpnmgr&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/vpnmgr.svg?branch=master)](https://travis-ci.com/jackyaz/vpnmgr)

## v2.0.0
### Updated on 2020-07-25
## About
The concept for this script was originally developed by [@h0me5k1n](https://github.com/h0me5k1n/asusmerlin-nvpnmgr)

Easy management of your VPN Client connections for various VPN providers on AsusWRT-Merlin.

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

[**PayPal donation**](https://paypal.me/jackyaz21)

[**Buy me a coffee**](https://www.buymeacoffee.com/jackyaz)

![Web UI](https://puu.sh/GaMl6/58ab6cb489.png)

![Menu UI](https://puu.sh/GaMkn/db5388acba.png)

## Supported firmware versions
You must be running firmware Merlin 384.15/384.13_4 or Fork 43E5 (or later) [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/)

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/vpnmgr/master/vpnmgr.sh" -o "/jffs/scripts/vpnmgr" && chmod 0755 /jffs/scripts/vpnmgr && /jffs/scripts/vpnmgr install
```

## Usage
vpnmgr adds a tab to the WebUI in the VPN area.

Otherwise, to launch the vpnmgr menu, use:
```sh
vpnmgr
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/vpnmgr
```

## Updating
Launch vpnmgr and select option u

## Help
Please post about any issues and problems here: [vpnmgr on SNBForums](https://www.snbforums.com/threads/vpnmgr-manage-and-update-vpn-client-configurations-for-nordvpn-and-pia.64930/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
