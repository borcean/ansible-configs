#!/bin/bash

# Options
REPO="https://github.com/borcean/ansible-configs.git"
BRANCH=dev
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

# Update OS and install Ansible on supported distros
OS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }' | sed 's/"//g')

if [[ "$OS" == fedora ]]; then
    dnf upgrade  --refresh -y
    if [[ "$(awk '/^VERSION_ID=/' /etc/*-release | awk -F'=' '{ print ($2) }' | sed 's/"//g')" -gt 34 ]]; then
        dnf install ansible-core git -y --allowerasing
    else
        dnf install ansible git -y
    fi
elif [[ "$OS" == centos ]]; then
    dnf upgrade --refresh -y
    if [[ "$(awk '/^VERSION_ID=/' /etc/*-release | awk -F'=' '{ print ($2) }' | sed 's/"//g')" == 8 ]]; then
        dnf install centos-release-ansible-29 -y
        dnf install ansible git -y
    elif [[ "$(awk '/^VERSION_ID=/' /etc/*-release | awk -F'=' '{ print ($2) }' | sed 's/"//g')" == 9 ]]; then
        dnf install ansible-core git -y
    fi
elif [[ "$OS" == arch ]]; then
    pacman -Syu
    pacman -S --noconfirm --needed ansible git
elif [[ "$OS" == opensuse-tumbleweed ]] || [[ "$OS" == opensuse-leap ]]; then
    zypper --non-interactive dup
    zypper --non-interactive install ansible git-core
elif [[ "$OS" == debian ]] || [[ "$OS" == ubuntu ]]; then
    # Check if Debian Buster, if so use Ansible PPA
    if [[ "$(awk '/^VERSION_ID=/' /etc/*-release | awk -F'=' '{ print ($2) }' | sed 's/"//g')" == 10 ]]; then
        echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main" >  /etc/apt/sources.list.d/ansible.list
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    fi
    apt update
    apt full-upgrade -y
    apt install ansible git -y
else
    if ! confirm "Unsupported distro detected, continue anyways?  y/n: "; then
        exit
    fi
fi

# Update and fix existing flatpak installs
if command -v flatpak &> /dev/null; then
    flatpak update -y
    flatpak repair
fi

# Test VM set up
if [[ "$(hostnamectl --static)" == hydrogen.borcean.xyz ]]; then
    if [[ "$OS" == debian ]]; then
        apt install spice-vdagent -y
    elif [[ "$OS" == arch ]]; then
        pacman -S --noconfirm --needed spice-vdagent xf86-video-qxl
    fi
    systemctl enable serial-getty@ttyS0.service
fi

# Clean Ansible cache
rm -rf /root/.ansible/

# Install collections/roles from Ansible Galaxy
wget -O /tmp/requirements.yml "$REQUIREMENTS"
ansible-galaxy collection install -r /tmp/requirements.yml --force

# Ansible pull command
echo -e "\n"
if [[ "$OS" == debian ]] && [[ "$(awk '/^VERSION_ID=/' /etc/*-release | awk -F'=' '{ print ($2) }' | sed 's/"//g')" == 10 ]]; then
    ansible-pull --vault-password-file="$VAULT_FILE" -e 'ansible_python_interpreter=/usr/bin/python' -U "$REPO" -C "$BRANCH"
else
    ansible-pull --vault-password-file="$VAULT_FILE" -U "$REPO" -C "$BRANCH"
fi

# Offer restart after ansible pull finished
if confirm "Reboot system now?  y/n: "; then
    systemctl reboot
fi