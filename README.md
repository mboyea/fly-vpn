---
title: Fly VPN
author: [ Matthew T. C. Boyea ]
lang: en
subject: server
keywords: [ nix, docker, sstp, vpn, server, fly, fly.io ]
default_: report
---
## A SoftEther SSTP VPN Server, hosted by Fly.io

This is a scale-to-zero VPN server that Windows' built-in VPN client can connect to by IP address + username + password.

Questions? [Read the FAQ](#faq).

### Get Started

#### Install Server

First, copy the repository.

- [Clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) from GitHub to your computer.

Because Nix manages all packages, it is the only dependency required to be installed manually.

- [Install Nix](https://nixos.org/download/).
- [Enable Flakes](https://nixos.wiki/wiki/Flakes).

Now you are ready to configure the server!

#### Configure Server

The VPN server must be configured by a secret file named `.env`. Modify the `.env` file in the root directory of this repository, and declare the following settings:

`.env`

```sh
SOFTETHER_PASS="password"
USER_PASS_PAIRS="user1:password user2:password user3:password"
HUB_NAME="flyvpn"
HUB_PASS="password"
```

Now you are ready to deploy the server!

#### Deploy to Fly.io

- [Make a Fly.io account](https://fly.io/dashboard). Link your payment method in the account.
- Run `nix develop` to open a shell with access to development tools (like `flyctl`).
- Run `flyctl auth login`
- Run `touch .env` to make file named `.env`
- Determine your `<unique_app_name>`.
- Set `app = '<unique_app_name>'` in `fly.toml`.
- Add line `FLY_APP_NAME="<unique_app_name>"` to `.env`.
- Add line `PRODUCTION_CN="<unique_app_name>.fly.dev"` to `.env`.
- Run `flyctl launch --no-deploy --ha=false --name <unique_app_name>`
- Run `flyctl tokens create deploy` to generate your `<fly_api_token>`.
- Add line `FLY_API_TOKEN="<fly_api_token>"` to `.env`.
- Run `nix run .#deploy`

#### Update a Client Certificate (Windows 10)

- Start the server.
- Find the location of the `.crt` file provided by the server CLI on startup. It is at `/var/lib/softether/vpnserver/cn.txt` by default.
- Download the `.crt` file to the client's Windows 10 computer.
- Double click the `.crt` file to open it with Crypto Shell Extensions.
- Click `Install Certificate...`.
- Select `Local Machine`.
- Click `Next`.
- Click `Yes`.
- Select `Place all certificates in the following store`.
- Click `Browse...`.
- Select `Trusted Root Certification Authorities`.
- Click `OK` to give Administrator Privileges.
- Click `Next`.
- Click `Finish`.

#### Connect a Client (Windows 10)

- Open Windows 10 Settings.
- Click `Network & Internet`.
- Click `VPN`.
- Click `Add a VPN connection`.
  ![Screenshot of an example VPN connection.](docs/screenshots/windows-10-add-a-vpn-connection.png)
- Select `Windows (built-in)` under "VPN provider".
- Name the VPN under "Connection name".
- Put the common name (CN) of the server under "Server name or address". The common name of your server is given by the server on startup alongside the `.crt` file. It will be either an IP address or a DNS URL.
- Write your `<username>` under "User name".
- Write your `<password>@flyvpn` under "Password".
- Click `Save`.
- Click the VPN connection you just made and select `Connect`.

#### Scripts

Scripts can be run from within the project directories using any shell with Nix installed and Flakes enabled.
See [#### Install Server](#install-server).

| Command                     | Description |
|:--- |:--- |
| `nix run`                   | Alias for `.#help` |
| `nix run .#help`            | Print this helpful information |
| `nix run .#start`           | Alias for `.#start native` |
| `nix run .#start native`    | Start the server natively on your machine |
| `nix run .#start container` | Start the server in a container on your machine |
| `nix run .#deploy`          | Alias for `.#deploy all` |
| `nix run .#deploy server`   | Deploy just the server to Fly.io |
| `nix run .#deploy secrets`  | Deploy just the secrets to Fly.io |
| `nix run .#deploy all`      | Deploy the server & secrets to Fly.io |
| `nix develop`               | Start a dev shell with all project dependencies installed |

### FAQ

#### What is this for?

You can have all your friends connect to this VPN simultaneously.
When everyone's connected, LAN multiplayer games should allow you to play together.
Now you can have LAN parties online, and nobody has to install or pay for a proprietary VPN client.

Fly doesn't charge you when your app isn't computing anything.
So when you're not using the VPN, it's not costing you money.

#### How does it work?

[Nix (the package manager)](https://nixos.org/) uses [declarative scripting](https://en.wikipedia.org/wiki/Declarative_programming) to:

- Install and lock dependencies.
- Compile the server into a production-ready package.
- Build the package into a [Docker image](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/).
- Deploy the Docker image to [Fly.io](https://fly.io/).

[SoftEther (the VPN server)](https://www.softether.org/) provides a tunnel through which devices may route their internet connections.
Devices can connect to this VPN using any client software that supports the SSTP protocol, *including the VPN client built-in to Microsoft Windows*.
When multiple devices connect to the VPN at the same time, they can connect with each other over LAN, as if they were plugged into the same switch.

The SSTP protocol uses TLS instead of UDP, meaning that all traffic is encrypted by default.
Another benefit of TLS is that the server can use a "shared" IP address, whereas UDP would require a "static" IP address.
Fly.io would charge extra for you to reserve a static IPv4 address, and many ISP networks don't support IPv6 in 2025.
So it is cheapest to host a VPN server that uses SSTP+TLS.

Fly.io provides a great hosting service that allows you to run Docker images on a distributed computing network as if they were a VPS.
The platform enables you to create extremely cost-effective low-latency servers.
If you are interested in how they achieve this, [check out the Fly.io docs](https://fly.io/docs/reference/architecture/).

If you have any questions, please first do your best to read the code and understand it, starting at the entrypoint of the program in `flake.nix`.
If you have any errors, first try to identify why the error occurs and fix it yourself.
Then if you still can't figure it out, or if you think you have something valuable to share, please post a GitHub Issue to this repository.
Other users may benefit from community sharing.

#### How to contribute?

This project doesn't support community contributions to the code base right now.
You are free to post Issues in this repository, and if enough interest is generated, a process for community pull requests will be provided.

We are not currently receiving donations.
There is no way to fund the project at this time, but if enough interested is generated, a process for donations will be provided.

Feel free to fork, just be sure to [read the license](./LICENSE.md).

### Potential TODO Tasks

1

I should perform a refactor to hide secrets on the production server.
Right now, those secrets are baked into the Docker image and are exposed in the nix store.
Rather than baking them into environment variables in the server image, the secrets should be provided by the environment.
So the `.#start` script should load .env itself, and pass that environment to the running executable.

- For `.#start native`, this is passed directly with Bash.
- For `.#start container`, this is passed through podman.
- For `.#deploy`, this is passed through Fly Secrets.

This would enable secrets like USER_PASS_PAIRS to be updated independently of the server image.
(As it stands, when USER_PASS_PAIRS is updated, all clients must update their certs and that is inconvenient)
This would also enable me to add `.env` to `.gitignore` again.
This would also enable me to remove `env.nix`.

2

Add the following.

- echo "  .#deploy | Deploy the server and secrets to Fly.io"
- echo "  .#deploy server | Deploy the server to Fly.io"
- echo "  .#deploy secrets | Deploy the secrets to Fly.io"

3

consider generating fly.toml using Nix like https://github.com/LutrisEng/nix-fly-template/blob/main/fly.nix
this refactor could enable us to pull in FLY_APP_NAME from .env automatically

4

- PRODUCTION_CN should DEFAULT TO $FLY_APP_NAME.fly.dev
