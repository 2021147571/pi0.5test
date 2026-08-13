#!/usr/bin/env python3
"""Extract conservative LIBERO result counts from an openpi evaluation log."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


PATTERNS = {
    "total_episodes": [r"Total episodes:\s*(\d+)", r"total episodes[^0-9]*(\d+)"],
    "total_successes": [r"Total successes:\s*(\d+)", r"# successes:\s*(\d+)"],
    "success_rate": [
        r"Overall success rate:\s*([0-9.]+)",
        r"Total success rate:\s*([0-9.]+)",
        r"Current total success rate:\s*([0-9.]+)",
    ],
}


def last_match(text: str, patterns: list[str], cast):
    matches: list[str] = []
    for pattern in patterns:
        matches.extend(re.findall(pattern, text, flags=re.IGNORECASE))
    return cast(matches[-1]) if matches else None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("log", type=Path)
    parser.add_argument("--output", type=Path, default=Path("results/summary.json"))
    args = parser.parse_args()

    text = args.log.read_text(encoding="utf-8", errors="replace")
    result = {
        "source_log": str(args.log),
        "total_episodes": last_match(text, PATTERNS["total_episodes"], int),
        "total_successes": last_match(text, PATTERNS["total_successes"], int),
        "success_rate": last_match(text, PATTERNS["success_rate"], float),
    }
    if result["success_rate"] is None and result["total_episodes"]:
        successes = result["total_successes"]
        if successes is not None:
            result["success_rate"] = successes / result["total_episodes"]
    if result["total_successes"] is None and result["total_episodes"] and result["success_rate"] is not None:
        result["total_successes"] = round(result["success_rate"] * result["total_episodes"])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
