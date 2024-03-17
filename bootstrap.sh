#!/bin/bash

# Options
REPO="https://github.com/borcean/ansible-configs.git"
BRANCH=coreos
VAULT_FILE=/root/.ansible_vault_key
INVENTORY="https://raw.githubusercontent.com/borcean/ansible-configs/"$BRANCH"/hosts"
REQUIREMENTS="https://raw.githubusercontent.com/borcean/ansible-configs/"$BRANCH"/requirements.yml"

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

    if [ "$(curl -s "$INVENTORY" | grep -m 1 "$HOSTNAME")" == "$HOSTNAME" ]; then
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

# Wait for rpm-ostree to be idle before installing updates
echo "Waiting for rpm-ostree idle state"
until rpm-ostree status | grep "State: idle"; do sleep 1; echo -n "." ; done;

# Update OS and install Ansible on supported distros
OS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }' | sed 's/"//g')

if [[ "$OS" == fedora ]]; then
    if ! command -v ansible &> /dev/null; then
        rpm-ostree install ansible
    fi
    if ! command -v ansible &> /dev/null; then
        echo "Transactional package install requires reboot. Restart provision after boot."
        if confirm "Reboot system now?  y/n: "; then
            systemctl reboot
        fi
    fi
else
    if ! confirm "Unsupported distro detected, continue anyways?  y/n: "; then
        exit
    fi
fi

# Test VM set up
if [[ "$(hostnamectl --static)" == hydrogen.borcean.xyz ]]; then
    systemctl enable serial-getty@ttyS0.service
fi

# Clean Ansible cache
rm -rf /root/.ansible/

# Install collections/roles from Ansible Galaxy
curl -sS "$REQUIREMENTS" -o /tmp/requirements.yml
ansible-galaxy collection install -r /tmp/requirements.yml --force
ansible-galaxy role install -r /tmp/requirements.yml --force
rm /tmp/requirements.yml

# Ansible pull command
echo -e "\n"
ansible-pull --vault-password-file="$VAULT_FILE" -U "$REPO" -C "$BRANCH"

# Offer restart after ansible pull finished
if confirm "Reboot system now?  y/n: "; then
    systemctl reboot
fi