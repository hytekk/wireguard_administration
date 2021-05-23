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
                echo -e "${RED}You need to run this script as root\nStart with sudo ./make-install.sh${NC}"
                exit 1
        fi
}

function go_nogo {
	while true; do
        read -p "$(echo -e "Are you sure you want to set these values as default variables? ")" yn
        case $yn in
                [Yy]* ) WG_PREKEY='YES';
		set_variables;
                break;;
                [Nn]* ) echo -e "You chose to abort the installation.";
                exit 1;;
                * ) echo "Please answer Y or N.";;
        esac
	done
}

function set_variables {
	mkdir -p $CLIENT_DIR
        echo $CLIENT_IP | awk -F'.' '{printf "%d.%d.%d.%d", $1, $2, $3, $4 -1}' > $CLIENT_DIR/last-ip.txt	
	#echo $SERVER_IP > $CLIENT_DIR/last-ip.txt
	cp clients/wg0-template-prekey.conf $CLIENT_DIR
        cp clients/wg0-template.conf $CLIENT_DIR
	cat add-client-template.sh | sed -e 's/;SRV_ADDRESS;/'"\'$SERVER_ADDRESS\'"'/' | sed -e 's|;SRV_WG_DIR;|'"\'$WG_DIR\'"'|' | sed -e 's|;SRV_IP;|'"\'$SERVER_IP\'"'|' | sed -e 's|;SRV_PORT;|'"\'$SERVER_PORT\'"'|'  | sed -e 's|;SRV_WG_IF;|'"\'$SERVER_WG_IF\'"'|' | sed -e 's|;SRV_PUBLIC_KEY;|'"\'$SERVER_PUBLIC_KEY\'"'|' | sed -e 's|;CL_WG_IF;|'"\'$CLIENT_WG_IF\'"'|' | sed -e 's|;CL_DIR;|'"\'$CLIENT_DIR\'"'|' | sed -e 's|;CL_IP;|'"\'$LAST_IP.\'"'|' | sed -e 's|;SRV_WG_REREAD;|'"\'$WG_REREAD\'"'|' | sed -e 's|;SRV_WG_PREKEY;|'"\'$WG_PREKEY\'"'|'| sed -e 's/;CL_DNS;/'"\'$CLIENT_DNS\'"'/' > /usr/local/bin/add-client.sh
	cat delete-client-template.sh | sed -e 's|;SRV_WG_DIR;|'"\'$WG_DIR\'"'|' | sed -e 's|;SRV_WG_IF;|'"\'$SERVER_WG_IF\'"'|' | sed -e 's|;CL_DIR;|'"\'$CLIENT_DIR\'"'|' > /usr/local//bin/delete-client.sh
	chmod +x /usr/local/bin/add-client.sh
	chmod +x /usr/local/bin/delete-client.sh
	echo -e "${RED}${BOLD}DONE${NC}${normal}"
	chmod -R 600 $CLIENT_DIR
}

# Variables
function add_variables {
	echo "Enter path to wireguard configuration (/etc/wireguard/)"
	read WG_DIR
	WG_DIR=${WG_DIR:-/etc/wireguard/}
	
	echo "Enter your server's public ip or FQDN (127.0.0.1)"
	read SERVER_ADDRESS
	SERVER_ADDRESS=${SERVER_ADDRESS:-127.0.0.1}
	
	echo "Enter the server's IP (192.168.5.1)"
	read SERVER_IP
	SERVER_IP=${SERVER_IP:-192.168.5.1}
	
	echo "Enter wireguard server port (51820)"
	read SERVER_PORT
	SERVER_PORT=${SERVER_PORT:-51820}
	
	echo "Enter your server wg interface (wg0)"
	read SERVER_WG_IF
	SERVER_WG_IF=${SERVER_WG_IF:-wg0}
	
	echo "Enter your server's name of the public key, must be in wireguard path (server_public.key)"
	read SERVER_PUBLIC_KEY
	SERVER_PUBLIC_KEY=${SERVER_PUBLIC_KEY:-server_public.key}
	
	echo "Enter path where client configurations should be saved (/etc/wireguard/clients/)"
	read CLIENT_DIR
	CLIENT_DIR=${CLIENT_DIR:-/etc/wireguard/clients/}
	
	echo "Enter your client wg interface (wg0)"
	read CLIENT_WG_IF
	CLIENT_WG_IF=${CLIENT_WG_IF:-wg0}
	
	echo "Enter the first client's IP (192.168.5.2)"
	read CLIENT_IP
	CLIENT_IP=${CLIENT_IP:-192.168.5.2}
	LAST_IP=$(echo $CLIENT_IP | awk -F'.' '{print $1,$2,$3}' OFS='.')
	
	echo "Enter default choice when adding a peer with preshared key. YES means restart wireguard service as to reload the wireguard config. (YES)"
	read WG_REREAD
	WG_REREAD=${WG_REREAD:-YES}
	
	echo "Enter default choice when adding a peer as to add a preshared key. YES means to use preshared key by default. (YES)"
	read WG_PREKEY
	WG_PREKEY=${WG_PREKEY:-YES}

	echo "Enter your preferred DNS, comma-separated (1.1.1.1,8.8.4.4)"
	read CLIENT_DNS
	CLIENT_DNS=${CLIENT_DNS:-1.1.1.1,8.8.4.4}

}

# Show user configurations
function show_config {
	echo -e "${ORANGE}${BOLD}DEFAULT VARIABLES${NC}${normal}"
	echo -e " - server directory: $WG_DIR"
	echo -e " - server wg interface name: $SERVER_WG_IF"
	echo -e " - server public IP/FQDN: $SERVER_ADDRESS"
	echo -e " - server wg IP: $SERVER_IP"
	echo -e " - server port: $SERVER_PORT"
	echo -e " - server wg interface name: $SERVER_WG_IF"
	echo -e " - server public key name: $SERVER_PUBLIC_KEY"
	echo -e " - server restart: $WG_REREAD"
	echo -e " - using preshared key: $WG_PREKEY"
	echo -e " - client directory: $CLIENT_DIR"
	echo -e " - client wg interface name: $CLIENT_WG_IF"
	echo -e " - next client wg IP: $CLIENT_IP"
}

echo -e "This script makes it easier to configure the add-client.sh by asking the user to define variables. Default values in brackets ( )"
isRoot
add_variables
show_config
go_nogo
