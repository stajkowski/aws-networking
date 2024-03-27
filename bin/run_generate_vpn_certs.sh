#!/bin/bash

# This script will generate certs into /config/vpn
# utilizing EASY-RSA.  Ensure GIT is installed prior
# to running this script.
printf "###########################################\n"
printf "## Generating Certs #######################\n"
printf "###########################################\n\n"

printf "# Creating /config/vpn directory\n"
mkdir -p ./config/vpn && cd ./config/vpn

printf "# Cloning Easy-RSA\n"
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3

#printf "# Init vars file\n"
#<<EOF>> vars cat
#set_var EASYRSA_REQ_COUNTRY	"US"
#set_var EASYRSA_REQ_PROVINCE	"California"
#set_var EASYRSA_REQ_CITY	"San Francisco"
#set_var EASYRSA_REQ_ORG	"Copyleft Certificate Co"
#set_var EASYRSA_REQ_EMAIL	"me@example.net"
#set_var EASYRSA_REQ_OU		"My Organizational Unit"
#EOF

printf "# Initializing PKI\n"
./easyrsa init-pki

printf "# Building CA, Server, and Client Certs\n"
echo -ne "vpn.local\n" | ./easyrsa build-ca nopass
yes yes | ./easyrsa build-server-full server.vpn.local nopass
yes yes | ./easyrsa build-client-full client.vpn.local nopass

printf "###########################################\n"
printf "## Copy Certs to Parent DIR ###############\n"
printf "###########################################\n\n"

printf "# Copying ca.crt to parent VPN directory\n"
cp pki/ca.crt ../../

printf "# Copying client.vpn.local.crt to parent VPN directory\n"
cp pki/issued/client.vpn.local.crt ../../client.crt

printf "# Copying server.vpn.local.crt to parent VPN directory\n"
cp pki/issued/server.vpn.local.crt ../../server.crt

printf "# Copying client.vpn.local.key to parent VPN directory\n"
cp pki/private/client.vpn.local.key ../../client.key

printf "# Copying server.vpn.local.key to parent VPN directory\n"
cp pki/private/server.vpn.local.key ../../server.key

printf "###########################################\n"
printf "## Cleanup Easy-RSA #######################\n"
printf "###########################################\n\n"

printf "# Removing /config/vpn/easy-rsa \n"
rm -rf ../../easy-rsa