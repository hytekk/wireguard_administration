# Wireguard Admin Scripts
#### Both of the scripts is copied and developed out from https://github.com/davidgross/ - so all creds to David Gross :)

First time I'm uploading anything, so be nice 😄

Scripts to provision clients for Wireguard. Written to run on the same Linux computer as the Wireguard server.
Focus is on daily use of the basics - add and delete peers/clients.

There are mainly 1 bash script and 2 template scripts to help you administer your wireguard instance:
- make_install.sh - let's user configure with their own ip's, file paths and more
- add-client-template.sh
- delete-client-template.sh

The make_install.sh generates two scripts:
- add-client.sh
- delete-client.sh

And last but not least a directory containing:
- last-ip.txt - to keep state of last used wireguard ip
- wg0-template.conf - template to generate wg0.conf to peer
- wg0-template-prekey.conf - template to generate wg0.conf to peer with preshared key

### Pre requirements
1. Wireguard, installed on server and basic wg0 is configured.
2. qrencode, for more ease of use when generating and distributing client configurations.

##### add-client
###### Description
Script to generate client keys and config files as well as setup it up on the wireguard server.
The script also makes a check if your client name already is in use.
It generates a qr code in the terminal for easy setup on a mobile phone. It also saves a qr png for a more portable use.
All client configurations is stored on the server, by default under '/etc/wireguard/clients/'.

###### Variable Examples
```bash
WG_DIR='/etc/wireguard'
SERVER_ADDRESS='public ip'
SERVER_PORT='51820'
SERVER_WG_IF='wg0'
SERVER_PUBLIC_KEY='server_public.key'
SERVER_PUB_KEY=$(cat $WG_DIR/$SERVER_PUBLIC_KEY)
CLIENT_WG_IF='wg0'
CLIENT_DIR='/etc/wireguard/clients'
CLIENT_IP='192.168.5.' # Last octet is automagically filled with correct IP based on the file last-ip.txt
WG_TEMPLATE=$WG_DIR/wg0-template.conf
WG_TEMPLATE_PREKEY=$CLIENT_DIR/wg0-template-prekey.conf
LAST_IP=$CLIENT_DIR/last-ip.txt
CLIENT_NAME=''
CLIENTS=($(wg show $SERVER_WG_IF peers | awk '{print $2}' | tr -d '()' | sed '/^[[:blank:]]*$/d'))
WG_REREAD='YES'
WG_PREKEY='YES'
```

##### delete-client
###### Description
Script to delete the client from the wireguard server. It also deletes any previously generated and stored configuration files such as public/private key and wg0.conf-file.


###### Variable Examples
```bash
WG_DIR='/etc/wireguard'
CLIENT_DIR='/etc/wireguard/clients'
SERVER_WG_CONF='wg0.conf'
SERVER_WG_IF='wg0'
ARRAY_FILE='/tmp/WG_array'
WG_DELETE_PEER='/tmp/WG_delete_peer'
```

#### Contributing
Since this is my first public display of any code I've written - I'm open to feedback.
Feel free to copy and use whatever you need in your own script. :smiley:
