---
title: Fly VPN Devlog
author: [ Matthew T. C. Boyea ]
lang: en
date: December, 2024
subject: project
keywords: [ nix, docker, sstp, vpn, server, fly, fly.io, project, docs, code, test, history, log ]
default_: report
---

## Goals

- +1.2.0 | Remote Config Script
- +1.1.0 | Initial Deploy Script
- +1.0.0 | Working VPN + Tested LAN Gaming + Manual Deploy + Manual Config

## Milestones

- [ ] (A) Announce release for +1.0.0 @docs
- [ ] (C) Make server backup its files every 10 minutes by default @code
- [ ] (B) Document how to play each game in `README.md` @docs
- [ ] (D) Verify LAN gaming works with Fly.io for Age of Empires II @test
- [ ] (C) Verify LAN gaming works with Fly.io for Diablo II @test
- [ ] (C) Verify LAN gaming works with Fly.io for Minecraft @test
- [ ] (B) Re-write `README.md` and `nix run .#help` to reflect new usage @docs @code
- [ ] (E) Generate fly.toml using Nix like at https://github.com/LutrisEng/nix-fly-template/blob/main/fly.nix @code
- [ ] (A) Draft `nix run .#deploy` scripts `server`, `secrets`, and `all` @code
- [ ] (A) Verify VPN works with Fly.io using Windows VPN client @test
- [x] (B) 2025-01-28 Re-write `README.md` and `nix run .#help` to reflect new usage @docs @code
- [x] (A) 2025-01-24 Setup volumes to persist the server configuration @code
- [x] (A) 2025-01-23 Fix `nix run .#deploy`for new image @code
- [x] (A) 2025-01-23 Verify VPN works with `nix run .#start` using Windows VPN client @test
- [x] (A) 2025-01-23 Verify VPN works with `nix run .#start` using SoftEther VPN client @test
- [x] (A) 2025-01-23 Refactor server to inject server config code into https://github.com/siomiz/SoftEtherVPN/ @code
- [x] (A) 2025-01-18 Get https://github.com/siomiz/SoftEtherVPN/ working locally @code
- [ ] ~~ (A) Fix VPN internet connection @code @test ~~
- [x] (B) 2025-01-11 Verify VPN connects to Fly.io using Windows VPN client @test
- [x] (A) 2025-01-11 Draft secrets deployment to Fly.io @code
- [x] (A) 2025-01-11 Fix deployment to Fly.io https://community.fly.io/t/docker-image-works-locally-but-not-on-fly-io-getting-command-not-found/23387 @code
- [x] (B) 2025-01-08 Draft manual deploy instructions in `README.md` @docs @code
- [x] (A) 2025-01-07 Verify VPN connects to `nix run .#start container` using Windows VPN client @test
- [x] (A) 2025-01-07 Draft script `nix run .#start container` @code
- [x] (A) 2025-01-07 Draft SoftEther server .env secrets loading @code
- [x] (A) 2025-01-06 Draft manual config instructions in `README.md` @docs
- [x] (A) 2025-01-06 Verify VPN connects to `nix run .#start native` using Windows VPN client @test
- [x] (A) 2024-12-22 Draft SoftEther server config @code
- [x] (A) 2024-12-21 Draft SoftEther server install @code
- [x] (A) 2024-12-18 Draft script `nix run .#start native` @code
- [x] (A) 2024-12-18 Draft script `nix run .#help` @code @docs
- [x] (A) 2024-12-18 Draft Nix code structure for +1.0.0 @code
- [x] (A) 2024-12-17 Draft `todo.md` for +1.0.0 @docs
- [x] (A) 2024-12-17 Draft `README.md` for +1.0.0 @docs
