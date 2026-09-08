# Bybit / Binance Testnet via AWS Free Tier (London)

Run exchange **testnet** API calls from a **non-US IP** so US home-network geo-blocks do not break Bybit Testnet or Binance Futures Testnet.

This repo is a minimal harness: Free Tier EC2 in `eu-west-2` (London) + Python smoke scripts. **Testnet only** (not mainnet, not Bybit Demo Trading).

## A–Z checklist

### A. Prerequisites (laptop, once)

1. AWS account + a [billing alarm](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html). Free Tier still bills overages.
2. Install [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and configure credentials with EC2 permissions:
   ```bash
   aws configure
   # Prefer region eu-west-2 when prompted, or export AWS_REGION=eu-west-2
   ```
3. Create **Bybit Testnet** API keys at [testnet.bybit.com](https://testnet.bybit.com) (not mainnet Demo / `api-demo.bybit.com`).
4. Optional: Binance Futures Testnet keys at [testnet.binancefuture.com](https://testnet.binancefuture.com).
5. Copy env template and fill keys (never commit `.env`):
   ```bash
   cp .env.example .env
   ```

Free Tier note: eligible instance types depend on when your AWS account was created (pre/post 15 Jul 2025). In the console for **London (`eu-west-2`)**, pick an AMI/instance type marked **Free tier eligible**. Default script type is `t3.micro`; override if needed:

```bash
INSTANCE_TYPE=t2.micro ./deploy/launch_ec2.sh
```

### B. Launch Free Tier EC2 (London)

```bash
chmod +x deploy/*.sh
./deploy/launch_ec2.sh
```

The script:

- Uses region `eu-west-2`
- Creates/reuses an SSH security group locked to **your public IP `/32`**
- Creates/reuses a key pair under `~/.ssh/bybit-testnet-key.pem`
- Launches Ubuntu 24.04, writes `deploy/.instance.env`

SSH (use the IP printed by the script):

```bash
ssh -i ~/.ssh/bybit-testnet-key.pem ubuntu@<PUBLIC_IP>
```

### C. Bootstrap the box

From the **laptop**:

```bash
./deploy/sync.sh
```

On the **EC2** instance:

```bash
cd ~/bybit
bash deploy/bootstrap.sh
source .venv/bin/activate
```

`sync.sh` copies `.env` if present locally. Otherwise edit `~/bybit/.env` on the box.

### D. Prove the geo workaround

On EC2 (venv activated):

```bash
python scripts/check_egress_ip.py    # expect non-US (typically GB)
python scripts/smoke_bybit.py        # public; + auth if keys set
python scripts/smoke_binance.py      # optional
```

Optional tiny Bybit testnet order:

```bash
BYBIT_SMOKE_PLACE_ORDER=1 python scripts/smoke_bybit.py
```

Scripts treat geo / 403-style failures as hard errors and print egress IP. They refuse mainnet unless `ALLOW_MAINNET=1` (leave off).

Optional control check from your US laptop (same scripts): if home IP is blocked, that documents why the VPS exists.

### E. Day-to-day loop

```bash
# laptop: edit code, then
./deploy/sync.sh

# EC2
ssh -i ~/.ssh/bybit-testnet-key.pem ubuntu@<PUBLIC_IP>
cd ~/bybit && source .venv/bin/activate
python scripts/smoke_bybit.py
```

**Save Free Tier hours** — stop when idle:

```bash
./deploy/teardown.sh stop
./deploy/teardown.sh start   # refreshes PUBLIC_IP in deploy/.instance.env
```

Tear down when finished:

```bash
./deploy/teardown.sh terminate   # kill instance, keep SG + key
./deploy/teardown.sh destroy     # terminate + delete SG + AWS key pair
```

After `start`, public IP usually changes — use the refreshed `deploy/.instance.env` or re-run `sync.sh` after updating IP.

### F. Safety / cost

| Guard | Detail |
|-------|--------|
| SSH | Port 22 from your IP only; no app ports |
| Secrets | `.gitignore` covers `.env`, `*.pem`, `deploy/.instance.env` |
| Network | Prefer **stopped** instances when not testing |
| Trading | Testnet only; `ALLOW_MAINNET` defaults off |

## Local install (optional, no EC2)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then edit
python scripts/smoke_bybit.py
```

Public endpoints may still work from the US; authenticated testnet often does not — that is expected.

## Layout

| Path | Purpose |
|------|---------|
| `scripts/check_egress_ip.py` | Public IP / country check |
| `scripts/smoke_bybit.py` | Bybit V5 Testnet smoke |
| `scripts/smoke_binance.py` | Binance Futures Testnet smoke |
| `deploy/launch_ec2.sh` | Create Free Tier London EC2 |
| `deploy/bootstrap.sh` | On-box Python venv + deps |
| `deploy/sync.sh` | rsync project + `.env` to EC2 |
| `deploy/teardown.sh` | stop / start / terminate / destroy |

## Demo Trading footnote

Bybit **Demo Trading** (`demo=True`, `api-demo.bybit.com`) is a separate mainnet paper product. This harness targets **Testnet** (`testnet=True`, `api-testnet.bybit.com`) — the path that commonly needs a non-US VPS from US home connections.
