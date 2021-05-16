#!/bin/bash

# Set up colorization
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
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

echo -e "\e[0mThis script helps you add a peer."
isRoot

# Variables
WG_DIR='/etc/wireguard'
SERVER_ADDRESS='dns or ip'
SERVER_PORT='51820'
SERVER_WG_IF='wg0'
SERVER_PUBLIC_KEY='server_public.key'
SERVER_PUB_KEY=$(cat $WG_DIR/$SERVER_PUBLIC_KEY)
CLIENT_WG_IF='wg0'
CLIENT_DIR='/etc/wireguard/clients'
CLIENT_IP='192.168.5.'
WG_TEMPLATE=$CLIENT_DIR/wg0-template.conf
LAST_IP=$CLIENT_DIR/last-ip.txt
CLIENT_NAME=''
CLIENTS=($(wg show $SERVER_WG_IF peers | awk '{print $2}' | tr -d '()' | sed '/^[[:blank:]]*$/d'))

# Let user know the configuration
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
        echo -e "usage: add-client.sh CLIENT-NAME\n"
else
	CLIENT_NAME="$1"
	check_peer_name
	echo -e "Creating client config: $1"
        mkdir -p $CLIENT_DIR/$1
        wg genkey | tee $CLIENT_DIR/$1/$1.priv | wg pubkey > $CLIENT_DIR/$1/$1.pub
        key=$(cat $CLIENT_DIR/$1/$1.priv)
        pubkey=$(cat $CLIENT_DIR/$1/$1.pub)
        IP="$CLIENT_IP"$(expr $(cat $CLIENT_DIR/last-ip.txt | tr "." " " | awk '{print $4}') + 1)
	cat $WG_TEMPLATE | sed -e 's/;CLIENT_IP;/'"$IP"'/' | sed -e 's|;CLIENT_KEY;|'"$key"'|' | sed -e 's|;SERVER_PUB_KEY;|'"$SERVER_PUB_KEY"'|' | sed -e 's|;SERVER_ADDRESS;|'"$SERVER_ADDRESS"'|' | sed -e 's|;SERVER_PORT;|'"$SERVER_PORT"'|' | sed -e 's|;ALLOWED_IPS;|'"$IP"'|' > $CLIENT_DIR/$1/$CLIENT_WG_IF.conf
        echo $IP > $LAST_IP
        echo -e "${GREEN}Created config!${NC}"
        wg set $SERVER_WG_IF peer $(cat $CLIENT_DIR/$1/$1.pub) allowed-ips $IP/32
        echo -e "${GREEN}Adding peer to server's wg conf file${NC}"
	echo -e "\n# $1" >> $WG_DIR/$SERVER_WG_IF.conf
	echo -e "[Peer]" >> $WG_DIR/$SERVER_WG_IF.conf
	echo -e "PublicKey = $pubkey # $1"  >> $WG_DIR/$SERVER_WG_IF.conf
	echo -e "AllowedIPs = $IP/32" >> $WG_DIR/$SERVER_WG_IF.conf
        qrencode -t ansiutf8 < $CLIENT_DIR/$1/$CLIENT_WG_IF.conf
        qrencode -t png -o "$CLIENT_DIR/$1/${1}_wg0.png"  < $CLIENT_DIR/$1/$CLIENT_WG_IF.conf
	echo -e "${GREEN}You can now connect to wireguard with your newly added client${NC}."
fi
