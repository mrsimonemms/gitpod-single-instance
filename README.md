# Gitpod single-instance

An experimental repository for getting [Gitpod](https://gitpod.io) installed on a single-instance

This may well be renamed, refactored, made into an official Gitpod guide or canned
in future dependent upon what can be achieved.

# Intention

The intention for this repo is to find a way of achieving:
 - installing Gitpod on a single-instance machine
 - use the [Gitpod Installer](https://github.com/gitpod-io/gitpod/tree/main/installer)

# Stacks

- Support Linux/Mac
- Windows should be supported, even if necessary to use [WSL](https://docs.microsoft.com/en-us/windows/wsl/install)
- Preferrably use k3s

[k3d](https://docs.microsoft.com/en-us/windows/wsl/install) is the preferred stack
as it can be automated and supports all the required stacks. If this cannot be made
to support Gitpod, this must be done using a technology that supports full automation.

# Intention

Ultimately, This will be automated as a "cURL to Bash" type script, eg:

```shell
curl -o- https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/tree/main/install.sh | bash
```

# Contributions welcome

Whilst this is in the `develop` branch, this repo should be considered volatile
as experiments pass or fail. If/when this moves to a `main` branch, this will then
be considered production-ready.

Please check the [NOTES.md](./NOTES.md) file for where this project currently
stands. If making contributions, please add something to this file.
