#!/usr/bin/env python3
"""Binance USDT-M Futures Testnet smoke via direct HTTPS (avoids spot Client.ping)."""

from __future__ import annotations

import hashlib
import hmac
import os
import sys
import time
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import fail_geo, load_env, looks_like_geo_error, print_egress, refuse_mainnet

FUTURES_TESTNET = "https://testnet.binancefuture.com"


def _request(
    method: str,
    path: str,
    *,
    params: dict[str, Any] | None = None,
    api_key: str = "",
    api_secret: str = "",
    signed: bool = False,
    timeout: float = 20.0,
) -> Any:
    params = dict(params or {})
    headers: dict[str, str] = {}
    if signed:
        if not api_key or not api_secret:
            raise ValueError("signed request requires API key and secret")
        params.setdefault("timestamp", int(time.time() * 1000))
        query = urlencode(params, doseq=True)
        signature = hmac.new(
            api_secret.encode("utf-8"),
            query.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        params["signature"] = signature
        headers["X-MBX-APIKEY"] = api_key
    elif api_key:
        headers["X-MBX-APIKEY"] = api_key

    url = f"{FUTURES_TESTNET}{path}"
    resp = requests.request(method, url, params=params, headers=headers, timeout=timeout)
    text = resp.text
    if resp.status_code == 403 or looks_like_geo_error(text):
        fail_geo(f"{method} {path}", f"HTTP {resp.status_code}: {text[:500]}")
    try:
        data = resp.json()
    except ValueError:
        data = {"raw": text}
    if resp.status_code >= 400:
        detail = data if isinstance(data, dict) else text
        msg = str(detail)
        if looks_like_geo_error(msg):
            fail_geo(f"{method} {path}", msg)
        raise RuntimeError(f"HTTP {resp.status_code}: {detail}")
    if isinstance(data, dict):
        code = data.get("code")
        msg = str(data.get("msg", ""))
        if code not in (None, 0, "0") and looks_like_geo_error(msg):
            fail_geo(f"{method} {path}", msg)
    return data


def main() -> int:
    load_env()
    refuse_mainnet()
    print_egress("Egress")

    print("Binance Futures Testnet: ping (public)...")
    try:
        ping = _request("GET", "/fapi/v1/ping")
    except RuntimeError as exc:
        if looks_like_geo_error(str(exc)):
            fail_geo("futures_ping", str(exc))
        print(f"ERROR [futures_ping]: {exc}", file=sys.stderr)
        return 1
    print(f"OK ping: {ping}")

    print("Binance Futures Testnet: BTCUSDT ticker (public)...")
    try:
        ticker = _request("GET", "/fapi/v1/ticker/price", params={"symbol": "BTCUSDT"})
    except RuntimeError as exc:
        if looks_like_geo_error(str(exc)):
            fail_geo("futures_symbol_ticker", str(exc))
        print(f"ERROR [futures_symbol_ticker]: {exc}", file=sys.stderr)
        return 1
    print(f"OK ticker: {ticker}")

    api_key = os.getenv("BINANCE_API_KEY", "").strip()
    api_secret = os.getenv("BINANCE_API_SECRET", "").strip()
    if not api_key or not api_secret:
        print(
            "SKIP auth: set BINANCE_API_KEY / BINANCE_API_SECRET in .env "
            "(keys from https://testnet.binancefuture.com)."
        )
        print("Binance public smoke passed.")
        return 0

    print("Binance Futures Testnet: account (authenticated)...")
    try:
        account = _request(
            "GET",
            "/fapi/v2/account",
            api_key=api_key,
            api_secret=api_secret,
            signed=True,
        )
    except RuntimeError as exc:
        if looks_like_geo_error(str(exc)):
            fail_geo("futures_account", str(exc))
        print(f"ERROR [futures_account]: {exc}", file=sys.stderr)
        return 1

    assets = account.get("assets") if isinstance(account, dict) else None
    can_trade = account.get("canTrade") if isinstance(account, dict) else None
    print(f"OK account: canTrade={can_trade} assets_count={len(assets or [])}")
    print("Binance smoke passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
