This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

Contents:
- [`marp`](https://marp.app/)-based slides (compiled from `md` to `html` via `marp.sh`)
- `signet_genesis_node.sh` script that automates the deployment of the workshop signet environment.

`signet_genesis_node.sh` is responsible for:
- Deploy a local signet.
- Mine 16 blocks as bootstrapping for the SRI pool.

Then, the audience is expected to follow the steps highlighted in the slides.
The slides can be served via:
```
cd html
python3 -m http.server 8888
```