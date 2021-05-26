# Ansible Configs
My personal Ansible set up.

## Bootstrap new system
```bash
bash -c "$(wget -O- ansible.borcean.xyz)"
```

## Compatibility
The primary target is the latest Fedora release, however `base` and `workstation` plays are generally compatible with the following:

| Distro | Release |
| --- | --- |
| Arch | N/A |
| CentOS | Stream 8 |
| Debian | 10 (Buster)<sup>1</sup>, 11 (Bullseye)<sup>2</sup> |
| Fedora | 33, 34 |
| openSUSE | Leap 15.2, Leap 15.3 |
| | Tumbleweed |
| Ubuntu | 20.04 (Focal), 20.10 (Groovy), 21.04 (Hirsute) |


<sup>1</sup>Debian Buster requires `ansible_python_interpreter: "/usr/bin/python"`.

<sup>2</sup>Debian Bullseye VPN client fails to connect.

##
Based upon [Jay LaCroix's](https://github.com/LearnLinuxTV/personal_ansible_desktop_configs) set up.