#!/bin/bash

# Terraform AWS Nuke
wget -c https://github.com/rebuy-de/aws-nuke/releases/download/v2.25.0/aws-nuke-v2.25.0-linux-amd64.tar.gz -O - | tar -xz -C $PWD
mv $PWD/aws-nuke-v2.25.0-linux-amd64 $PWD/aws-nuke