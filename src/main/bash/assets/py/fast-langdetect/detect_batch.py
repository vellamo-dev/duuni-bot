#!/usr/bin/env python3
"""Detect en/fi/sv/Unknown for many text files with a single model load.

Reads `slug<TAB>text_path` lines from stdin and prints `slug<TAB>language`
lines to stdout. The fasttext model is loaded exactly once.
"""

import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", module="urllib3")

from fast_langdetect import LangDetectConfig, LangDetector

ACCEPTED = {"en", "fi", "sv"}
MINIMUM_SCORE = 0.80


def language_of(detector, text):
    cleaned = " ".join(text.split())
    if not cleaned:
        return "Unknown"
    found = detector.detect(cleaned, k=1)
    if not found:
        return "Unknown"
    lang = found[0].get("lang", "")
    score = float(found[0].get("score", 0))
    if lang in ACCEPTED and score >= MINIMUM_SCORE:
        return lang
    return "Unknown"


def main():
    if len(sys.argv) != 2:
        print("Usage: detect_batch.py <model>", file=sys.stderr)
        return 1
    model_path = sys.argv[1]
    detector = LangDetector(LangDetectConfig(custom_model_path=model_path))
    for line in sys.stdin:
        line = line.rstrip("\n")
        if not line:
            continue
        slug, text_path = line.split("\t", 1)
        try:
            text = Path(text_path).read_text(encoding="utf-8")
        except OSError:
            print(f"{slug}\tUnknown")
            continue
        print(f"{slug}\t{language_of(detector, text)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
