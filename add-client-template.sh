#!/bin/bash

# Set up colorization
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[34m'
ITALIC='\e[3mitalic\e[0m'
NC='\033[0m' # No Color
BOLD='\e[1m'
normal='\e[0m'
BLINK='\e[5m'
NB='\e[25m' # No BLINK

# Check user is running as root
function isRoot {
        if [ "${EUID}" -ne 0 ]; then
                echo -e "${RED}You need to run this script as root${NC}"
                exit 1
        fi
}

# To populate wg show command with peer name
function wg {

	WG_COLOR_MODE=always command wg "$@" | sed -e "$(while read -r tag eq key hash name; do [ "$tag" == "PublicKey" ] && echo "s#$key#$key ($name)#;"; done < /etc/wireguard/wg0.conf)"

}

# Function to check if peer name already is in use
function check_peer_name {
	for i in "${CLIENTS[@]}"; do
   		if [ "$i" == "$CLIENT_NAME" ] ; then
        	echo -e "${RED}${BLINK}Peer name already in use. Please choose another name! ${NC}${NB}"; exit;
    	fi
	done
}

function wg_prekey {
	if [ $WG_PREKEY = 'YES' ]
	then
		echo -e "Prekey enabled."
	        wg genpsk > $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.psk
		prekey=$(cat $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.psk)
		client_route
		cat $WG_TEMPLATE_PREKEY | sed -e 's/;CLIENT_IP;/'"$IP"'/' | sed -e 's|;CLIENT_KEY;|'"$key"'|' | sed -e 's|;CLIENT_DNS;|'"$CLIENT_DNS"'|' | sed -e 's|;SERVER_PUB_KEY;|'"$SERVER_PUB_KEY"'|' | sed -e 's|;SERVER_ADDRESS;|'"$SERVER_ADDRESS"'|' | sed -e 's|;SERVER_PORT;|'"$SERVER_PORT"'|' | sed -e 's|;ALLOWED_IPS;|'"$IPN"'|' | sed -e 's|;PREKEY;|'"$prekey"'|' > $CLIENT_DIR/$CLIENT_NAME/$CLIENT_WG_IF.conf
	        wg_server
		echo -e "PresharedKey = $prekey"  >> $WG_DIR/$SERVER_WG_IF.conf
		wg_reload
	else
		echo -e "${ORANGE}Prekey not being used.${NC}"
		client_route
		cat $WG_TEMPLATE | sed -e 's/;CLIENT_IP;/'"$IP"'/' | sed -e 's|;CLIENT_KEY;|'"$key"'|' | sed -e 's|;CLIENT_DNS;|'"$CLIENT_DNS"'|' | sed -e 's|;SERVER_PUB_KEY;|'"$SERVER_PUB_KEY"'|' | sed -e 's|;SERVER_ADDRESS;|'"$SERVER_ADDRESS"'|' | sed -e 's|;SERVER_PORT;|'"$SERVER_PORT"'|' | sed -e 's|;ALLOWED_IPS;|'"$IPN"'|' > $CLIENT_DIR/$CLIENT_NAME/$CLIENT_WG_IF.conf
		wg_server
	fi
}

function wg_client {
	echo -e "Creating client config: $CLIENT_NAME"
	mkdir -p $CLIENT_DIR/$CLIENT_NAME
	wg genkey | tee $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.priv | wg pubkey > $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.pub
	key=$(cat $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.priv)
	pubkey=$(cat $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.pub)
	echo -e "${GREEN}Created config!${NC}"
	wg set $SERVER_WG_IF peer $(cat $CLIENT_DIR/$CLIENT_NAME/$CLIENT_NAME.pub) allowed-ips $IP/32
	chmod -R 600 $CLIENT_DIR/$CLIENT_NAME
}

function wg_server {
	echo -e "${GREEN}Adding peer to server's wg conf file${NC}"
        echo -e "\n# $CLIENT_NAME" >> $WG_DIR/$SERVER_WG_IF.conf
	echo -e "[Peer]" >> $WG_DIR/$SERVER_WG_IF.conf
        echo -e "PublicKey = $pubkey # $CLIENT_NAME"  >> $WG_DIR/$SERVER_WG_IF.conf
	echo -e "AllowedIPs = $IP/32" >> $WG_DIR/$SERVER_WG_IF.conf
}

function wg_readkey {
	while true; do
	read -p "$(echo -e "For enhanced security you should use a preshared key for each client. Do you wish to use a preshared key? ")" yn
	case $yn in
		[Yy]* ) WG_PREKEY='YES';
		break;;
		[Nn]* ) WG_PREKEY='NO';
		break;;
		* ) echo "Please answer Y or N.";;
	esac
	done
}

function client_route {
	while true; do
        read -p "$(echo -e "\nDefault is to route all the traffic through the VPN. Do you want to route all the traffic through the VPN (Y) or just the IP (N)? ")" yn
        case $yn in
                #[Yy]* ) CLIENT_ROUTE='YES';
                [Yy]* ) echo -e "All traffic is going to be rooted.";
		IPN='0.0.0.0/0';
                break;;
                #[Nn]* ) CLIENT_ROUTE='NO';
                [Nn]* ) echo -e "Only $IP\/32 is going to be routed.";
		IPN=$(echo $IP | awk -F'.' '{printf "%d.%d.%d.%d", $1, $2, $3, 0}'  ; printf '/24');
                break;;
                * ) echo "Please answer Y or N.";;
        esac
        done
}

function wg_reload {
	while true; do
	read -p "$(echo -e "\nWhen you have added a client with preshared key you need to reload the configuration for the wireguard server.\nDo you wish to ${RED}${BLINK}restart wireguard now${NC}${NB} (eg quick restart) or manually do it later? ")" yn
	case $yn in
		[Yy]* ) WG_REREAD='YES';
		#wg setconf $SERVER_WG_IF $WG_DIR/$SERVER_WG_IF.conf;
		systemctl restart wg-quick@wg0.service;
		break;;
		[Nn]* ) WG_REREAD='NO';
		break;;
		* ) echo "Please answer Y or N.";;
	esac
	done
}

function wg_running {
        if systemctl is-active --quiet wg-quick@wg0.service; then
                echo -e ""
        else
                echo -e "Wireguard needs to be running for this script to work."
                exit 1
        fi
}

echo -e "${ORANGE}THIS SCRIPT ASSISTS YOU ADDING A CLIENT (PEER).${NC}"
wg_running
isRoot

# Variables
WG_DIR=;SRV_WG_DIR;
SERVER_ADDRESS=;SRV_ADDRESS;
SERVER_IP=;SRV_IP;
SERVER_PORT=;SRV_PORT;
SERVER_WG_IF=;SRV_WG_IF;
SERVER_PUBLIC_KEY=;SRV_PUBLIC_KEY;
SERVER_PUB_KEY=$(cat $WG_DIR/$SERVER_PUBLIC_KEY)
CLIENT_WG_IF=;CL_WG_IF;
CLIENT_DIR=;CL_DIR;
CLIENT_IP=;CL_IP;
CLIENT_DNS=;CL_DNS;
CLIENT_ROUTE='YES'
WG_TEMPLATE=$CLIENT_DIR/wg0-template.conf
WG_TEMPLATE_PREKEY=$CLIENT_DIR/wg0-template-prekey.conf
LAST_IP=$CLIENT_DIR/last-ip.txt
CLIENT_NAME=''
CLIENTS=($(wg show $SERVER_WG_IF peers | awk '{print $2}' | tr -d '()' | sed '/^[[:blank:]]*$/d'))
WG_REREAD=;SRV_WG_REREAD;
WG_PREKEY=;SRV_WG_PREKEY;

# Let the user know the configuration
echo -e "\nWireguard directory: ${GREEN}$WG_DIR${NC}"
echo -e "Server ip address: ${RED}$SERVER_ADDRESS${NC}"
echo -e "Server ip port: ${RED}$SERVER_PORT${NC}"
echo -e "Server wg interface: ${RED}$SERVER_WG_IF\n${NC}"
echo -e " "
echo -e "Client directory: ${GREEN}$CLIENT_DIR${NC}"
echo -e "Client IP network: ${GREEN}${CLIENT_IP}0${NC}"
echo -e "Client wg interface: ${RED}$CLIENT_WG_IF${NC}"
which qrencode | grep -o qrencode > /dev/null && echo -e "qrencode installed? ${GREEN}YES ${NC} (qrencode for peer will be shown at the end)\n\n" || echo "qrencode installed? ${RED}NO${NC} (qrencode will ${ORANGE}NOT${NC} be printed in terminal!\n\n"

# Add client to running wireguard as well as insert into wg-config file
if [ $# -eq 0 ]
then
        echo -e "usage: ./add-client.sh CLIENT-NAME\n"
else
	CLIENT_NAME="$1"
	check_peer_name
	IP="$CLIENT_IP"$(expr $(cat $CLIENT_DIR/last-ip.txt | tr "." " " | awk '{print $4}') + 1)
	echo $IP > $LAST_IP
	wg_readkey
	wg_client
	wg_prekey
	qrencode -t ansiutf8 < "$CLIENT_DIR/$CLIENT_NAME/$CLIENT_WG_IF.conf"
	qrencode -t png -o "$CLIENT_DIR/$CLIENT_NAME/${1}_wg0.png"  < $CLIENT_DIR/$1/$CLIENT_WG_IF.conf
        chmod -R 600 $CLIENT_DIR/$CLIENT_NAME
	echo -e "${GREEN}You can now connect to Wireguard with your newly added client${NC}."
fi
