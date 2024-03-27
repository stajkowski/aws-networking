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

printf "# Initializing PKI\n"
./easyrsa init-pki

printf "# Building CA, Server, and Client Certs\n"
echo -ne "\n" | ./easyrsa build-ca nopass
yes yes | ./easyrsa build-server-full server nopass
yes yes | ./easyrsa build-client-full client.domain.tld nopass

printf "###########################################\n"
printf "## Copy Certs to Parent DIR ###############\n"
printf "###########################################\n\n"

printf "# Copying ca.crt to parent VPN directory\n"
cp pki/ca.crt ../../

printf "# Copying client.domain.tld.crt to parent VPN directory\n"
cp pki/issued/client.domain.tld.crt ../../

printf "# Copying server.crt to parent VPN directory\n"
cp pki/issued/server.crt ../../

printf "# Copying client.domain.tld.key to parent VPN directory\n"
cp pki/private/client.domain.tld.key ../../

printf "# Copying server.key to parent VPN directory\n"
cp pki/private/server.key ../../

printf "###########################################\n"
printf "## Cleanup Easy-RSA #######################\n"
printf "###########################################\n\n"

printf "# Removing /config/vpn/easy-rsa \n"
rm -rf ../../easy-rsa