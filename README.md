# Ansible Configs
My personal Ansible set up.

## Bootstrap new system
```bash
bash -c "$(wget -O- ansible.borcean.xyz)"
```

## Compatibility

| Distro | Release |
| --- | --- |
| Debian | 11 (Bullseye)<sup>&dagger;</sup> |
| Fedora | 33 |
| openSUSE | Tumbleweed |
| Ubuntu | 20.10 (Groovy) |

<sup>&dagger;</sup>Debian will fail on initial provision upon first invocation of `dconf` module, subsequent runs initiated by `ansible-pull.service` will pass.


##
Based upon [Jay LaCroix's](https://github.com/LearnLinuxTV/personal_ansible_desktop_configs) set up.