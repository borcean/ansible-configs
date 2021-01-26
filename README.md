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
| CentOS | Stream 8 |
| Debian | 10 (Buster)<sup>1</sup>, 11 (Bullseye)<sup>2</sup> |
| Fedora | 33 |
| openSUSE | Leap 15.2 |
| | Tumbleweed |
| Ubuntu | 20.10 (Groovy) |


<sup>1</sup>Debian Buster requires `ansible_python_interpreter: "/usr/bin/python"`.

<sup>2</sup>Debian Bullseye will fail on initial provision upon first invocation of `dconf` module, subsequent runs initiated by `ansible-pull.service` will pass.

##
Based upon [Jay LaCroix's](https://github.com/LearnLinuxTV/personal_ansible_desktop_configs) set up.