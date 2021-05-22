#!/bin/bash

# Check user is running as root
function isRoot {
	if [ "${EUID}" -ne 0 ]; then
		echo -e "${RED}You need to run this script as root${NC}"
		exit 1
	fi
}

# Function to remove peer from the running wireguard server
function wg_delete {
	PEER_DELETE=$(cat $WG_DELETE_PEER | grep -i $item | awk '{print $2}');
	wg set $SERVER_WG_IF peer $PEER_DELETE remove;
	rm $CLIENT_DIR/$item/*;
	rmdir $CLIENT_DIR/$item;
	echo -e "${BOLD}${RED}DELETED $item${NC}${NORMAL}";
	wg_reload;
	exit 1
}

function wg_reload {
        while true; do
        read -p "$(echo -e "\nWhen you have deleted a client you should reload the configuration to the wireguard server.\nDo you wish to ${RED}${BLINK}restart wireguard now${NC}${NB} (eg quick restart) or manually do it later? ")" yn
        case $yn in
                [Yy]* ) WG_REREAD='YES';
                #wg setconf $SERVER_WG_IF $WG_DIR/$SERVER_WG_CONF;
                systemctl restart wg-quick@wg0.service;
                break;;
                [Nn]* ) WG_REREAD='NO';
                break;;
                * ) echo "Please answer Y or N.";;
        esac
        done
}

# Function to remove peer from the wireguard server's config file
function deleting {
	sed -i "/^# ${item}/,/^$/d" $WG_DIR/$SERVER_WG_CONF;
	wg_delete;
}

# To populate wg show command with peer name
function wg {

	WG_COLOR_MODE=always command wg "$@" | sed -e "$(while read -r tag eq key hash name; do [ "$tag" == "PublicKey" ] && echo "s#$key#$key ($name)#;"; done < /etc/wireguard/wg0.conf)"

}
function wg_running {
         if systemctl is-active --quiet wg-quick@wg0.service; then
                 #echo "running"
                 echo -e ""
         else
                 echo -e "Wireguard needs to be running for this script to work."
                 exit 1
         fi
}

# Set up colorization
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color
BOLD='\e[1m'
NORMAL='\e[0m'
BLINK='\e[5m'
NB='\e[25m' # No BLINK

echo -e "${ORANGE}THIS SCRIPT ASSISTS YOU IN DELETING A CLIENT (PEER).${NC}"
wg_running
isRoot

# Variables
WG_DIR=;SRV_WG_DIR;
CLIENT_DIR=;CL_DIR;
SERVER_WG_IF=;SRV_WG_IF;
SERVER_WG_CONF=;SRV_WG_IF;.conf
ARRAY_FILE='/tmp/WG_array'
WG_DELETE_PEER='/tmp/WG_delete_peer'

# Basic commands to list peers and insert to array
echo -e "QUIT" > $ARRAY_FILE
wg show $SERVER_WG_IF peers | awk '{print $2}' | sed 's/(//' | sed 's/)//' | sed '/^[[:blank:]]*$/d' >> $ARRAY_FILE
wg show $SERVER_WG_IF | grep -i 'peer' | awk '{print $3 " " $2}' | awk -F'\t' '$1' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" > $WG_DELETE_PEER

# New line, so as to separate each peer when parsed below
IFS=$'\n'

# Declare the array
WG_PEERS=()
while read WG_PEER; do
	WG_PEERS+=($WG_PEER);
done < $ARRAY_FILE

menu_from_array () {

select item; do
# Check the selected menu item number
if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ];
then
	if [ "$REPLY" == "1" ];
	then
		echo "EXIT"; break
	fi
	echo -e "The selected peer to be deleted is ${GREEN}$item${NC}"
	while true; do
        read -p "$(echo -e "Do you wish to ${RED}${BLINK}remove $item${NC}${NB}? ")" yn
   	case $yn in
        	[Yy]* ) deleting; #echo -e "Deleting $item";
		break;;
        	[Nn]* ) exit;;
        	* ) echo "Please answer yes or no.";;
    	esac
	done
else
	echo "Wrong selection: Select any number from 1-$#"
fi
done
}

# Call the subroutine to create the menu
menu_from_array "${WG_PEERS[@]}"
