# Ringer's server

To add yourself, please add the following to `configuration.nix`:

```nix
  users.users.<name> = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
    ];
  };
```

## Local configuration

To connect to the build machine, you will need to add this to your `~/.ssh/confg`:
```
Host jonringer
  HostName <will be sent to you>
  Port <will be sent to you>
  User alice
  IdentitiesOnly yes
  IdentityFile /home/alice/.ssh/id_rsa
  ForwardAgent yes # enables use of local ssh agent (e.g. for github)
  RemoteForward /run/user/$remote_uid/gnupg/S.gpg-agent /run/user/$uid/gnupg/S.gpg-agent.extra # for gpg signing (optional)
```

You will need to replace `alice`, `$remote_uid`, and `$uid`. (change host name if you want)

After applying the changes, you should be able to do:
```bash
ssh jonringer
```
To sign in.
