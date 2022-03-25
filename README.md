# Gitpod Single Instance

An experimental repository for getting [Gitpod](https://gitpod.io) installed on a single-instance

This may well be renamed, refactored, made into an official Gitpod guide or canned
in future dependent upon what can be achieved.

[![asciicast](https://asciinema.org/a/vV3Ri83DamHjvTmSR1Xca12ED.svg)](https://asciinema.org/a/vV3Ri83DamHjvTmSR1Xca12ED)

## Intention

The intention for this repo is to find a way of achieving:
 - installing Gitpod on a single-instance machine
 - use the [Gitpod Installer](https://github.com/gitpod-io/gitpod/tree/main/installer)

## Stacks

- Support Linux/Mac
- Windows should be supported, even if necessary to use [WSL](https://docs.microsoft.com/en-us/windows/wsl/install)
- Preferrably use k3s

[k3d](https://docs.microsoft.com/en-us/windows/wsl/install) is the preferred stack
as it can be automated and supports all the required stacks. If this cannot be made
to support Gitpod, this must be done using a technology that supports full automation.

## Goal(s)

Ultimately, This will be automated as a "cURL to Bash" type script, eg:

```shell
curl -o- https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/tree/main/install.sh | bash
```

## Contributions Are Welcome!

Whilst this is in the `develop` branch, this repo should be considered volatile
as experiments pass or fail. If/when this moves to a `main` branch, this will then
be considered production-ready.

Please check the [NOTES.md](./NOTES.md) file for where this project currently
stands. If making contributions, please add something to this file.

## Linux - Getting Started 

1. Spin up a system with Ubuntu 20.04.
2. Install Docker, kubectl, k3d, and Helm on the system.
3. Clone this repository to your system. Go into the cloned respository - `cd gitpod-single-instance`
4. Build the k3s Docker image by running - `docker build -t k3s .`
5. Edit the `certificate.yaml` file, specifically the domains in the `dnsNames` section.
6. Update the `domain:` in config.yaml.
7. Open `out.yaml` and replace all instances of `simonemms.com` with your domain.
8. Run `./run.sh`. It'll take a few moments to deploy the new Kubernetes cluster.
