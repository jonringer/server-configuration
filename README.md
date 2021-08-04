# Ringer's server

To add yourself, please add the following to `configuration.nix`:

```
  users.users.<name> = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
    ];
  };
```

