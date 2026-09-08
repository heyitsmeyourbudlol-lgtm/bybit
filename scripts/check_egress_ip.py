#!/usr/bin/env python3
"""Print this host's public egress IP / country (expect non-US on London EC2)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import print_egress


def main() -> int:
    info = print_egress("Public egress")
    if not info:
        return 1
    print(json.dumps(info, indent=2))
    cc = info.get("country_code")
    if cc == "US":
        print(
            "Expected non-US egress for this workaround. "
            "Run this on the eu-west-2 EC2 instance.",
            file=sys.stderr,
        )
        return 2
    print("OK: egress does not look US-based.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
