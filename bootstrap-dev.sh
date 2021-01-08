#!/bin/bash

# Options
REPO="https://github.com/borcean/ansible-configs.git"
BRANCH=dev
VAULT_FILE=/root/.ansible_vault_key
INVENTORY="https://raw.githubusercontent.com/borcean/ansible-configs/main/hosts"

confirm() {
    PROMPT="$1"
    while true; do 
        read -r -p "$PROMPT" CHOICE
            if [[ $CHOICE =~ ^[Yy]$ ]]; then
                return 0
            elif [[ "$CHOICE" =~ ^[Nn]$ ]]; then
                return 1
            fi
    done
}

check_hostname () {

    HOSTNAME="$(hostnamectl --static)"

    if [ "$(wget -qO- "$INVENTORY" | grep -m 1 "$HOSTNAME")" == "$HOSTNAME" ]; then
        echo -e "Host "$HOSTNAME" found in inventory."
    else 
        echo -e "Host "$HOSTNAME" not found in inventory."
        if confirm "Change hostname now?  y/n: "; then
            read -p "New hostname: " NEW_HOSTNAME
            hostnamectl set-hostname "$NEW_HOSTNAME"
            check_hostname 
        fi
    fi
}

# Check if run as root
if [ "$(id -u)" != "0" ]; then
   echo "Must be run as root, exiting..." 1>&2
   exit 1
fi

# Check if hostname is in inventory
check_hostname

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
    if confirm "OpenSUSE is not fully supported, continue anyways?  y/n: "; then
        zypper dup -y
        zypper install ansible -y
    else
        exit
    fi
elif [[ "$OS" == debian ]] || [[ "$OS" == ubuntu ]]; then 
    apt update
    apt dist-upgrade -y
    apt install ansible git -y
else
    if ! confirm "Unsupported distro detected, continue anyways?  y/n: "; then
        exit
    fi
fi

# Install SPICE agent if running Debian test VM
if [[ "$OS" == debian ]] && [[ "$(hostnamectl --static)" == hydrogen.borcean.xyz ]]; then
    apt install spice-vdagent -y
fi

# Ansible pull command
ansible-pull --vault-password-file="$VAULT_FILE" -U "$REPO" -C "$BRANCH"

# Offer restart after ansible pull finished
if confirm "Reboot system now?  y/n: "; then
    systemctl reboot
fi