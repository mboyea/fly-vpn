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

#### Install Software

First, copy the repository.

- [Clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) from GitHub to your computer.

Because Nix manages all packages, it is the only dependency required to be installed manually.

- [Install Nix](https://nixos.org/download/).
- [Enable Flakes](https://nixos.wiki/wiki/Flakes).

Now you're ready to use the project!

### Scripts

Scripts can be run from within the project directories using any shell with Nix installed and Flakes enabled.
See [#### Install Software](#install-software).

| Command | Description |
|:--- |:--- |
| `nix run` | Alias for `.#help` |
| `nix run .#help` | Print this helpful information |
| `nix run .#start` | Alias for `.#start native` |
| `nix run .#start native` | Start the server natively on your machine |
| `nix run .#start container` | Start the server in a container on your machine |
| `nix develop` | Start a dev shell with all project dependencies installed |

## FAQ

### What is this for?

You can have all your friends connect to this VPN simultaneously.
When everyone's connected, LAN multiplayer games should allow you to play together.

Fly doesn't charge you when your app isn't computing anything.
So when you're not using the VPN, it's not costing you money.

### How does it work?

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

### How to contribute?

This project doesn't support community contributions to the code base right now.
You are free to post Issues in this repository, and if enough interest is generated, a process for community pull requests will be provided.

We are not currently receiving donations.
There is no way to fund the project at this time, but if enough interested is generated, a process for donations will be provided.

Feel free to fork, just be sure to [read the license](./LICENSE.md).
