# Wireguard Admin Scripts
#### Both of the scripts is copied and developed out from https://github.com/davidgross/ - so all creds to David Gross :)

First time I'm uploading anything, so be nice 😄

Scripts to provision clients for Wireguard. Written to run on the same Linux computer as the Wireguard server.
Focus is on daily use of the basics - add and delete peers/clients.

There are mainly 2 bash scripts to help you administer your wireguard instance:
- add-client.sh
- delete-client.sh
- last-ip.txt

### Pre requirements
1. Wireguard, installed on server and basic wg0 is configured.
2. qrencode, for more ease of use when generating and distributing client configurations.


##### add-client
###### Description
Script to generate client keys and config files as well as setup it up on the wireguard server.
The script also makes a check if your client name already is in use.
It generates a qr code in the terminal for easy setup on a mobile phone.
All client configurations is stored on the server, by default under '/etc/wireguard/clients/'.

###### Variables
```bash
WG_DIR='/etc/wireguard'
SERVER_ADDRESS='dns or ip'
SERVER_PORT='51820'
SERVER_WG_IF='wg0'
SERVER_PUBLIC_KEY='server_public.key'
SERVER_PUB_KEY=$(cat $WG_DIR/$SERVER_PUBLIC_KEY)
CLIENT_WG_IF='wg0'
CLIENT_DIR='/etc/wireguard/clients'
CLIENT_IP='192.168.6.'
WG_TEMPLATE=$WG_DIR/wg0-template.conf
```

##### delete-client
###### Description
Script to delete the client from the wireguard server. It also deletes any previously generated and stored configuration files such as public/private key and wg0.conf-file.


###### Variables
```bash
WG_DIR='/etc/wireguard'
CLIENT_DIR='/etc/wireguard/clients'
SERVER_WG_CONF='wg0.conf'
SERVER_WG_IF='wg0'
ARRAY_FILE='/tmp/WG_array'
WG_DELETE_PEER='/tmp/WG_delete_peer'
```



#### Contributing
Since this is my first public display of any code I've written - please give feedback.
Feel free to copy and use whatever you need in your own script. :smiley:
