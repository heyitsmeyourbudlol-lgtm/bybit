"""Shared helpers for testnet smoke scripts."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from typing import Any

import requests
from dotenv import load_dotenv


GEO_HINT_PATTERNS = (
    re.compile(r"\bgeo\b", re.I),
    re.compile(r"restricted", re.I),
    re.compile(r"\bregion\b", re.I),
    re.compile(r"\bcountry\b", re.I),
    re.compile(r"not available in your", re.I),
    re.compile(r"\bforbidden\b", re.I),
    re.compile(r"access denied", re.I),
    re.compile(r"\busa\b", re.I),
    re.compile(r"from the usa", re.I),
    re.compile(r"eligibility", re.I),
    re.compile(r"\bip rate limit\b", re.I),
    re.compile(r"your ip is from", re.I),
)


def load_env() -> None:
    # Prefer repo-root .env regardless of cwd.
    root = Path(__file__).resolve().parent.parent
    load_dotenv(root / ".env", override=False)
    load_dotenv(override=False)


def refuse_mainnet() -> None:
    """Exit unless ALLOW_MAINNET=1 when a caller tries to enable mainnet."""
    if os.getenv("ALLOW_MAINNET", "0").strip() in {"1", "true", "TRUE", "yes", "YES"}:
        return
    # Scripts in this repo always force testnet; this is a belt-and-suspenders check.
    if os.getenv("FORCE_MAINNET", "0").strip() in {"1", "true", "TRUE"}:
        print(
            "Refusing mainnet: set ALLOW_MAINNET=1 only if you intentionally override.",
            file=sys.stderr,
        )
        sys.exit(2)


def get_egress_info(timeout: float = 10.0) -> dict[str, Any]:
    """Return public IP and coarse geo fields (tries multiple providers)."""
    errors: list[str] = []

    # 1) ipapi.co
    try:
        resp = requests.get("https://ipapi.co/json/", timeout=timeout)
        if resp.status_code == 200:
            data = resp.json()
            if data.get("ip") and not data.get("error"):
                return {
                    "ip": data.get("ip"),
                    "country": data.get("country_name") or data.get("country"),
                    "country_code": data.get("country_code"),
                    "city": data.get("city"),
                    "region": data.get("region"),
                    "org": data.get("org"),
                }
        errors.append(f"ipapi.co HTTP {resp.status_code}")
    except Exception as exc:  # noqa: BLE001
        errors.append(f"ipapi.co {exc}")

    # 2) ip-api.com (HTTP; fine for this smoke harness)
    try:
        resp = requests.get(
            "http://ip-api.com/json/?fields=status,message,country,countryCode,regionName,city,query,org",
            timeout=timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        if data.get("status") == "success":
            return {
                "ip": data.get("query"),
                "country": data.get("country"),
                "country_code": data.get("countryCode"),
                "city": data.get("city"),
                "region": data.get("regionName"),
                "org": data.get("org"),
            }
        errors.append(f"ip-api.com {data.get('message')}")
    except Exception as exc:  # noqa: BLE001
        errors.append(f"ip-api.com {exc}")

    # 3) IP only
    try:
        resp = requests.get("https://api.ipify.org?format=json", timeout=timeout)
        resp.raise_for_status()
        ip = resp.json().get("ip")
        if ip:
            return {
                "ip": ip,
                "country": None,
                "country_code": None,
                "city": None,
                "region": None,
                "org": None,
            }
    except Exception as exc:  # noqa: BLE001
        errors.append(f"ipify {exc}")

    raise RuntimeError("; ".join(errors) or "all egress lookups failed")


def print_egress(prefix: str = "Egress") -> dict[str, Any]:
    try:
        info = get_egress_info()
    except Exception as exc:  # noqa: BLE001 — smoke path prints and continues context
        print(f"{prefix}: lookup failed ({exc})")
        return {}
    cc = info.get("country_code") or "?"
    print(
        f"{prefix}: {info.get('ip')} "
        f"({info.get('city')}, {info.get('region')}, {info.get('country')} [{cc}])"
    )
    if cc == "US":
        print(
            "WARNING: egress looks US-based — Bybit/Binance testnets may geo-block you.",
            file=sys.stderr,
        )
    return info


def looks_like_geo_error(message: str) -> bool:
    return any(p.search(message) for p in GEO_HINT_PATTERNS)


def fail_geo(context: str, detail: str) -> None:
    print_egress("Egress at failure")
    print(f"GEO/ACCESS FAILURE [{context}]: {detail}", file=sys.stderr)
    sys.exit(1)


def env_flag(name: str, default: str = "0") -> bool:
    return os.getenv(name, default).strip() in {"1", "true", "TRUE", "yes", "YES"}
