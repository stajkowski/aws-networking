#!/bin/bash

# This script will run live integration tests
printf "## Initializing integration test\n\n"
terraform init
printf "## Validating terraform-aws-networking module\n\n"
terraform validate
printf "## Running live integration tests\n\n"
terraform test -filter=tests/integration_live.tftest.hcl