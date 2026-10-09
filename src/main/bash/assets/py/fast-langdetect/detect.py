#!/usr/bin/env python3
"""Detect en, fi, or sv from an extracted plain-text file. Otherwise Unknown."""

import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", module="urllib3")

from fast_langdetect import LangDetectConfig, LangDetector

ACCEPTED = {"en", "fi", "sv"}
MINIMUM_SCORE = 0.80


def language_of(text, model_path):
    cleaned = " ".join(text.split())
    if not cleaned:
        return "Unknown"
    detector = LangDetector(LangDetectConfig(custom_model_path=model_path))
    found = detector.detect(cleaned, k=1)
    if not found:
        return "Unknown"
    lang = found[0].get("lang", "")
    score = float(found[0].get("score", 0))
    if lang in ACCEPTED and score >= MINIMUM_SCORE:
        return lang
    return "Unknown"


def main():
    if len(sys.argv) != 3:
        print("Usage: detect.py <model> <text-file>", file=sys.stderr)
        return 1
    model_path, text_path = sys.argv[1], sys.argv[2]
    text = Path(text_path).read_text(encoding="utf-8")
    print(language_of(text, model_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
