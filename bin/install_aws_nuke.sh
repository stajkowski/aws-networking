#!/bin/bash

# Terraform AWS Nuke
wget -c https://github.com/rebuy-de/aws-nuke/releases/download/v2.25.0/aws-nuke-v2.25.0-linux-amd64.tar.gz -O - | tar -xz -C $HOME/.local/bin
mv $HOME/.local/bin/aws-nuke-v2.25.0-linux-amd64 $HOME/.local/bin/aws-nuke