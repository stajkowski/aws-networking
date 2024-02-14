#!/bin/bash

# This script will determine if formatting wasn't completed before pushing
printf "###########################################\n"
printf "## CHECKING FOR MISSED FORMATTING #########\n"
printf "###########################################\n\n"

if [[ $(terraform fmt -recursive -check) ]]; then
  printf "## Please format before pushing with 'terraform fmt -recursive' in the root directory\n\n"
  exit 1
else
  printf "## No formatting changes detected\n\n"
  exit 0
fi