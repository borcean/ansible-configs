# ansible
My personal Ansible configuration

```
bash -c "$(curl -L ansible.borcean.xyz)"
```

TODO:

base:
- [x] system_setup
    - [x] ansible
        - [x] ansible-pull systemd timer
        - [x] ansible vault
- [ ] User jeffrey
    - [x] vault - private key
    - [x] fish shell
        - [x] set as default shell
        - [x] Install Oh My Fish
        - [x] Install fish theme bobthefish
        - [x] omf update

workstation:
- [x] repositories
    - [x] RPM Fusion
    - [x] Google Chrome
    - [x] VS Code
- [x] packages
    - [x] google-chrome-stable
    - [x] code
    - [x] vlc
- [x] FlatPak
    - [x] Flathub
        - [x] Discord
        - [x] Minecraft
        - [x] Steam

thinkpad:
- [x] tlp
    - [x] repository tlp
    - [x] install tlp akmod-acpi_call
    - [x] configure charge thresholds
- [x] configuration
    - [x] bluetooth - ControllerMode = bredr

Based upon [Jay LaCroix's](https://github.com/LearnLinuxTV/personal_ansible_desktop_configs) set up.
