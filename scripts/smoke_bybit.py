#!/usr/bin/env python3
"""Bybit V5 Testnet smoke: public market + optional authenticated reads / tiny order."""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pybit.exceptions import FailedRequestError, InvalidRequestError
from pybit.unified_trading import HTTP

from common import env_flag, fail_geo, load_env, looks_like_geo_error, print_egress, refuse_mainnet


def _handle_error(context: str, exc: BaseException) -> None:
    detail = str(exc)
    status = getattr(exc, "status_code", None)
    if status == 403 or looks_like_geo_error(detail):
        fail_geo(context, detail)
    print(f"ERROR [{context}]: {detail}", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    load_env()
    refuse_mainnet()
    print_egress("Egress")

    # Always testnet in this harness.
    session = HTTP(testnet=True, api_key=None, api_secret=None)

    print("Bybit Testnet: fetching BTCUSDT orderbook (public)...")
    try:
        book = session.get_orderbook(category="linear", symbol="BTCUSDT", limit=5)
    except (FailedRequestError, InvalidRequestError, OSError) as exc:
        _handle_error("public get_orderbook", exc)

    ret = book.get("retCode") if isinstance(book, dict) else None
    if ret not in (0, None) and ret != "0":
        msg = book.get("retMsg", book) if isinstance(book, dict) else book
        if looks_like_geo_error(str(msg)):
            fail_geo("public get_orderbook", str(msg))
        print(f"ERROR [public get_orderbook]: {msg}", file=sys.stderr)
        return 1

    result = book.get("result", book) if isinstance(book, dict) else book
    print(f"OK public orderbook: {result}")

    api_key = os.getenv("BYBIT_API_KEY", "").strip()
    api_secret = os.getenv("BYBIT_API_SECRET", "").strip()
    if not api_key or not api_secret:
        print(
            "SKIP auth: set BYBIT_API_KEY / BYBIT_API_SECRET in .env "
            "(keys from https://testnet.bybit.com)."
        )
        print("Bybit public smoke passed.")
        return 0

    auth = HTTP(testnet=True, api_key=api_key, api_secret=api_secret)
    print("Bybit Testnet: wallet balance (authenticated)...")
    try:
        bal = auth.get_wallet_balance(accountType="UNIFIED")
    except (FailedRequestError, InvalidRequestError, OSError) as exc:
        _handle_error("get_wallet_balance", exc)

    ret = bal.get("retCode") if isinstance(bal, dict) else None
    if ret not in (0, None) and ret != "0":
        msg = bal.get("retMsg", bal) if isinstance(bal, dict) else bal
        if looks_like_geo_error(str(msg)):
            fail_geo("get_wallet_balance", str(msg))
        print(f"ERROR [get_wallet_balance]: {msg}", file=sys.stderr)
        return 1
    print(f"OK wallet: retCode={ret} retMsg={bal.get('retMsg') if isinstance(bal, dict) else ''}")

    if env_flag("BYBIT_SMOKE_PLACE_ORDER"):
        print("Bybit Testnet: placing tiny BTCUSDT market Buy (smoke)...")
        try:
            order = auth.place_order(
                category="linear",
                symbol="BTCUSDT",
                side="Buy",
                orderType="Market",
                qty="0.001",
            )
        except (FailedRequestError, InvalidRequestError, OSError) as exc:
            _handle_error("place_order", exc)
        print(f"OK order: {order}")
    else:
        print("SKIP place_order (set BYBIT_SMOKE_PLACE_ORDER=1 to enable).")

    print("Bybit smoke passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
