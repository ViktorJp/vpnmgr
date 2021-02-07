# vpnmgr
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/f73bdf3124904744b1844b4099f77bfe)](https://www.codacy.com/gh/jackyaz/vpnmgr/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/vpnmgr&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/vpnmgr.svg?branch=master)](https://travis-ci.com/jackyaz/vpnmgr)

## v2.2.0
### Updated on 2021-02-07
## About
The concept for this script was originally developed by [@h0me5k1n](https://github.com/h0me5k1n/asusmerlin-nvpnmgr)

Easy management of your VPN Client connections for various VPN providers on AsusWRT-Merlin.

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

[**PayPal donation**](https://paypal.me/jackyaz21)

[**Buy me a coffee**](https://www.buymeacoffee.com/jackyaz)

## Supported firmware versions
You must be running firmware Merlin 384.15/384.13_4 or Fork 43E5 (or later) [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/)

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/vpnmgr/master/vpnmgr.sh" -o "/jffs/scripts/vpnmgr" && chmod 0755 /jffs/scripts/vpnmgr && /jffs/scripts/vpnmgr install
```

## Usage
vpnmgr adds a tab to VPN menu of the WebUI.

Otherwise, to launch the vpnmgr menu, use:
```sh
vpnmgr
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/vpnmgr
```

## Screenshots

![WebUI](https://puu.sh/HevUo/0600bbea5c.png)

![CLI UI](https://puu.sh/HevPC/4f5ddfc3d6.png)

## Help
Please post about any issues and problems here: [Asuswrt-Merlin AddOns on SNBForums](https://www.snbforums.com/forums/asuswrt-merlin-addons.60/)
