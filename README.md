This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

Contents:
- [`marp`](https://marp.app/)-based slides (compiled from `md` to `html` via `marp.sh`)
- a [nix flake](https://nixos.wiki/wiki/Flakes) that automates the deployment of the workshop environment.

The nix flake is responsible for:
- Deploy a local signet.
- Mine 16 blocks as bootstrapping for the SRI pool.
- Deploy a local `electrs` + `mempool` so the audience can explore the blockchain.

Then, the audience is expected to follow the steps highlighted in the slides.

Assuming you have a system with nix flakex enabled, you can deploy the flake via:
```
$ nix develop
```