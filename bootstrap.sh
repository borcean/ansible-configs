#!/bin/bash

# Options
REPO="https://github.com/borcean/ansible-configs.git"
VAULT_FILE=/root/.ansible_vault_key

# Check if run as root
if [ "$(id -u)" != "0" ]; then
   echo "Must be run as root, exiting..." 1>&2
   exit 1
fi

# Get Ansible Vault password
set_vault_password () {

   get_vault_password () {
      echo -e "\nPlease enter vault password: "
      read -s -p "Password: " PASS1
      printf '\n'
      read -s -p "Confirm password: " PASS2
      printf '\n'
   }
   
   get_vault_password

   if [ "$PASS1" == "$PASS2" ]; then
      touch "$VAULT_FILE"
      chmod 0600 "$VAULT_FILE"
      echo "$PASS1" > "$VAULT_FILE"
   else
      echo -e "\nVault passwords do not match, try again..."
      get_vault_password
   fi
}

if [ -f "$VAULT_FILE" ]; then
    echo -e "\nAnsible vault key exists at $VAULT_FILE\n"
else 
   set_vault_password
fi

# Detect if supported distro
OS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')

if [[ "$OS" == fedora ]]; then
   dnf update -y
   dnf install ansible -y
elif [[ "$OS" == opensuse ]]; then
    echo "OpenSUSE is not fully supported, continuing in 10 seconds..."
    sleep 30
    zypper install ansible -y
else
   echo "Unsupported distro detected, continuing in 10 seconds..."
   sleep 30
fi

# Ansible pull command
ansible-pull --vault-password-file="$VAULT_FILE" -U $REPO