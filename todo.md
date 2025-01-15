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
- +1.1.0 | Deploy Script
- +1.0.0 | Working VPN + Tested LAN Gaming + Manual Deploy + Manual Config

## Milestones

- [ ] (E) Announce release for +1.0.0 @docs
- [ ] (D) Verify LAN gaming works with Fly.io for Castle Crusaders @test
- [ ] (D) Verify LAN gaming works with Fly.io for Age of Empires @test
- [ ] (C) Verify LAN gaming works with Fly.io for Diablo II @test
- [ ] (C) Verify LAN gaming works with Fly.io for Minecraft @test
- [ ] (B) Verify VPN works with Fly.io for web browsing @test
- [ ] (B) Verify VPN works with Fly.io for ping command @test
- [ ] (A) Refactor project to consume https://github.com/siomiz/SoftEtherVPN/ @code
- [ ] ~~ (A) Fix VPN internet connection @code @test ~~
- [x] (B) 2025-01-11 Verify VPN works with Fly.io using Windows VPN client @test
- [x] (A) 2025-01-11 Draft secrets deployment to Fly.io @code
- [x] (A) 2025-01-11 Fix deployment to Fly.io https://community.fly.io/t/docker-image-works-locally-but-not-on-fly-io-getting-command-not-found/23387 @code
- [x] (B) 2025-01-08 Draft manual deploy instructions in `README.md` @docs @code
- [x] (A) 2025-01-07 Verify VPN works with `nix run .#start container` for web browsing @test
- [x] (A) 2025-01-07 Verify VPN works with `nix run .#start container` for ping command @test
- [x] (A) 2025-01-07 Verify VPN works with `nix run .#start container` using Windows VPN client @test
- [x] (A) 2025-01-07 Draft script `nix run .#start container` @code
- [x] (A) 2025-01-07 Draft SoftEther server .env secrets loading @code
- [x] (A) 2025-01-06 Draft manual config instructions in `README.md` @docs
- [x] (A) 2025-01-06 Verify VPN works with `nix run .#start native` for web browsing @test
- [x] (A) 2025-01-06 Verify VPN works with `nix run .#start native` for ping command @test
- [x] (A) 2025-01-06 Verify VPN works with `nix run .#start native` using Windows VPN client @test
- [x] (A) 2024-12-22 Draft SoftEther server config @code
- [x] (A) 2024-12-21 Draft SoftEther server install @code
- [x] (A) 2024-12-18 Draft script `nix run .#start native` @code
- [x] (A) 2024-12-18 Draft script `nix run .#help` @code @docs
- [x] (A) 2024-12-18 Draft Nix code structure for +1.0.0 @code
- [x] (A) 2024-12-17 Draft `todo.md` for +1.0.0 @docs
- [x] (A) 2024-12-17 Draft `README.md` for +1.0.0 @docs
