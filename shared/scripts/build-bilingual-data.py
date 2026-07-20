#!/usr/bin/env python3
"""Build the static English string table used by the BiG Lab HTML pages.

The source documents stay Japanese. English strings are generated locally through
Ollama, cached by their exact Japanese source text, and bundled into one JavaScript
file so the language switch also works when a page is opened with ``file://``.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from bs4 import BeautifulSoup, Comment


ROOT = Path(__file__).resolve().parent.parent.parent
HTML_DIRS = [
    ROOT / "shared" / "website" / "pages",
    ROOT / "microneedle-drug-delivery" / "website-pages",
    ROOT / "corneal-3d-bioprinting" / "website-pages",
    ROOT / "photopolymer-biomaterials" / "website-pages",
]
CACHE_PATH = ROOT / "shared" / "website" / "assets" / "bilingual-cache.json"
OUTPUT_PATH = ROOT / "shared" / "website" / "assets" / "bilingual-data.js"
MODEL = "qwen2.5:3b"
OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
GOOGLE_TRANSLATE_URL = "https://translate.googleapis.com/translate_a/single"
JAPANESE_RE = re.compile(r"[\u3040-\u30ff\u3400-\u9fff々〆ヵヶ]")
TRANSLATABLE_ATTRIBUTES = ("alt", "aria-label", "content", "placeholder", "title")
SKIP_PARENTS = {"script", "style", "noscript"}
MAX_PARALLEL_BATCHES = 4
PAGE_STATIC_TRANSLATIONS = {
    "photopolymer-biomaterials-review.html": {
        "横スクロール可能な表": "Horizontally scrollable table",
        "論文": "Paper",
        "論文本文に基づく内容": "Content based on the source paper",
        "統合": "Synthesis",
        "4論文を横断した統合解釈": "Integrated interpretation across the four papers",
        "提案": "Proposal",
        "BIGで議論するための提案": "Proposal for discussion at BIG",
    }
}
PAGE_JAVASCRIPT_SOURCES = {
    "research-superpowers.html": ROOT / "shared" / "website" / "assets" / "research-superpowers.js",
}


def clean_string(value: str) -> str:
    return value.strip()


def normalize_english(value: str) -> str:
    return re.sub(r"\s*・\s*", " / ", value.strip())


def extract_page_strings(path: Path) -> list[str]:
    soup = BeautifulSoup(path.read_text(encoding="utf-8"), "html.parser")
    strings: OrderedDict[str, None] = OrderedDict()

    for node in soup.find_all(string=True):
        if isinstance(node, Comment) or (node.parent and node.parent.name in SKIP_PARENTS):
            continue
        value = clean_string(str(node))
        if value and JAPANESE_RE.search(value):
            strings[value] = None

    for tag in soup.find_all(True):
        for attribute in TRANSLATABLE_ATTRIBUTES:
            value = tag.get(attribute)
            if isinstance(value, str):
                value = clean_string(value)
                if value and JAPANESE_RE.search(value):
                    strings[value] = None

    return list(strings)


def extract_javascript_strings(path: Path) -> list[str]:
    """Extract the visible capability-card strings from the small local data object."""
    source = path.read_text(encoding="utf-8")
    values = re.findall(
        r"\b(?:summary|input|transform|output|example|guardrail):\s*\"([^\"]+)\"",
        source,
    )
    return list(OrderedDict.fromkeys(value for value in values if JAPANESE_RE.search(value)))


def load_cache() -> dict[str, str]:
    if not CACHE_PATH.exists():
        return {}
    data = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Translation cache must be an object: {CACHE_PATH}")
    return {str(key): normalize_english(str(value)) for key, value in data.items()}


def save_cache(cache: dict[str, str]) -> None:
    CACHE_PATH.write_text(
        json.dumps(cache, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def request_translations(items: list[tuple[str, str]], attempt: int = 1) -> dict[str, str]:
    if len(items) == 1:
        item_id, source_text = items[0]
        prompt = (
            "Translate this Japanese website text into natural, concise English. Preserve "
            "proper nouns, biomedical terms, citations, numbers, file paths, email addresses, "
            "inline code, and tokens such as $title$ or @[folder]. Output only the English "
            "translation with no quotes or commentary.\n\nTEXT:\n" + source_text
        )
        payload = {
            "model": MODEL,
            "stream": False,
            "keep_alive": "15m",
            "options": {"temperature": 0, "num_ctx": 4096},
            "messages": [
                {
                    "role": "system",
                    "content": "You are a meticulous Japanese-to-English scientific translator.",
                },
                {"role": "user", "content": prompt},
            ],
        }
        request = urllib.request.Request(
            OLLAMA_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=900) as response:
                result = json.load(response)
            translated = str(result["message"]["content"]).strip()
            if not translated:
                raise ValueError("Empty model response")
            return {item_id: translated}
        except (KeyError, TypeError, ValueError, json.JSONDecodeError, urllib.error.URLError) as error:
            if attempt < 3:
                print(f"  Retrying single string after: {error}", file=sys.stderr, flush=True)
                time.sleep(attempt)
                return request_translations(items, attempt + 1)
            raise

    source = {item_id: text for item_id, text in items}
    prompt = (
        "Translate every value in the JSON object from Japanese into natural, concise "
        "English for a biomedical research website. Preserve proper nouns, technical "
        "terms, citations, numbers, file paths, email addresses, inline code, and tokens "
        "such as $title$ or @[folder]. Keep already-English portions natural. Return one "
        "valid JSON object with exactly the same keys and translated string values. Do not "
        "add commentary and do not omit any key.\n\nINPUT:\n"
        + json.dumps(source, ensure_ascii=False)
    )
    payload = {
        "model": MODEL,
        "stream": False,
        "format": "json",
        "keep_alive": "15m",
        "options": {"temperature": 0, "num_ctx": 4096},
        "messages": [
            {
                "role": "system",
                "content": "You are a meticulous Japanese-to-English scientific translator.",
            },
            {"role": "user", "content": prompt},
        ],
    }
    request = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=900) as response:
            result = json.load(response)
        translated = json.loads(result["message"]["content"])
        if not isinstance(translated, dict):
            raise ValueError("Model response is not a JSON object")
        missing = [item_id for item_id in source if not str(translated.get(item_id, "")).strip()]
        if missing:
            raise ValueError("Missing translation keys: " + ", ".join(missing))
        return {item_id: str(translated[item_id]).strip() for item_id in source}
    except (KeyError, TypeError, ValueError, json.JSONDecodeError, urllib.error.URLError) as error:
        if len(items) > 1:
            middle = len(items) // 2
            print(f"  Retrying split batch after: {error}", file=sys.stderr, flush=True)
            return {
                **request_translations(items[:middle]),
                **request_translations(items[middle:]),
            }
        if attempt < 3:
            print(f"  Retrying single string after: {error}", file=sys.stderr, flush=True)
            time.sleep(attempt)
            return request_translations(items, attempt + 1)
        raise


def request_google_translations(
    items: list[tuple[str, str]], attempt: int = 1
) -> dict[str, str]:
    markers = [(item_id, f"⟪BGL{item_id.upper()}⟫") for item_id, _ in items]
    joined = "".join(
        marker + "\n" + source + "\n"
        for (item_id, source), (_, marker) in zip(items, markers)
    ) + "⟪BGLEND⟫"
    payload = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "ja",
            "tl": "en",
            "dt": "t",
            "q": joined,
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        GOOGLE_TRANSLATE_URL,
        data=payload,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "BiG-Lab-bilingual-builder/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            result = json.load(response)
        translated_text = "".join(part[0] or "" for part in result[0])
        marker_matches = list(re.finditer(r"⟪BGL(S\d+|END)⟫", translated_text, re.I))
        translated: dict[str, str] = {}
        for index, match in enumerate(marker_matches):
            marker_id = match.group(1).lower()
            if marker_id == "end":
                continue
            end = marker_matches[index + 1].start() if index + 1 < len(marker_matches) else len(translated_text)
            value = translated_text[match.end():end].strip()
            if value:
                translated[marker_id] = value
        missing = [item_id for item_id, _ in items if not translated.get(item_id)]
        if missing:
            raise ValueError("Missing translation keys: " + ", ".join(missing))
        return {item_id: translated[item_id] for item_id, _ in items}
    except (IndexError, TypeError, ValueError, json.JSONDecodeError, urllib.error.URLError) as error:
        if len(items) > 1:
            middle = len(items) // 2
            print(f"  Retrying split Google batch after: {error}", file=sys.stderr, flush=True)
            return {
                **request_google_translations(items[:middle]),
                **request_google_translations(items[middle:]),
            }
        if attempt < 3:
            print(f"  Retrying Google string after: {error}", file=sys.stderr, flush=True)
            time.sleep(attempt)
            return request_google_translations(items, attempt + 1)
        raise


def make_batches(strings: list[str], provider: str) -> list[list[tuple[str, str]]]:
    if provider == "ollama":
        return [[(f"s{index}", value)] for index, value in enumerate(strings)]

    batches: list[list[tuple[str, str]]] = []
    current: list[tuple[str, str]] = []
    current_chars = 0
    for index, value in enumerate(strings):
        item = (f"s{index}", value)
        if current and current_chars + len(value) > 3_500:
            batches.append(current)
            current = []
            current_chars = 0
        current.append(item)
        current_chars += len(value)
    if current:
        batches.append(current)
    return batches


def write_bundle(pages: dict[str, list[str]], cache: dict[str, str]) -> None:
    data = {
        page_name: {source: cache[source] for source in strings if source in cache}
        for page_name, strings in pages.items()
    }
    encoded = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    OUTPUT_PATH.write_text(
        "/* Generated by build-bilingual-data.py. Do not edit by hand. */\n"
        f"window.BIG_LAB_ENGLISH={encoded};\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--provider",
        choices=("ollama", "google"),
        default="ollama",
        help="Translation engine. Ollama keeps source text local; Google is faster.",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="Regenerate every translation instead of reusing the cache.",
    )
    args = parser.parse_args()

    pages = {
        path.name: extract_page_strings(path)
        for html_dir in HTML_DIRS
        for path in sorted(html_dir.glob("*.html"))
    }
    review_page = "photopolymer-biomaterials-review.html"
    review_strings = pages.get(review_page, [])
    for source in list(review_strings):
        if not re.search(r"\[(?:論文|統合|提案)\]", source):
            continue
        for fragment in re.split(r"\[(?:論文|統合|提案)\]", source):
            fragment = clean_string(fragment)
            if fragment and JAPANESE_RE.search(fragment) and fragment not in review_strings:
                review_strings.append(fragment)
    for page_name, javascript_path in PAGE_JAVASCRIPT_SOURCES.items():
        pages.setdefault(page_name, []).extend(
            source
            for source in extract_javascript_strings(javascript_path)
            if source not in pages.get(page_name, [])
        )
    for page_name, static_translations in PAGE_STATIC_TRANSLATIONS.items():
        pages.setdefault(page_name, []).extend(
            source for source in static_translations if source not in pages.get(page_name, [])
        )
    all_strings = list(OrderedDict.fromkeys(value for values in pages.values() for value in values))
    cache = {} if args.refresh else load_cache()
    for static_translations in PAGE_STATIC_TRANSLATIONS.values():
        cache.update(static_translations)
    save_cache(cache)
    missing = [value for value in all_strings if value not in cache]
    print(
        f"Found {len(all_strings)} unique Japanese strings across {len(pages)} pages; "
        f"{len(missing)} need translation.",
        flush=True,
    )

    batches = make_batches(missing, args.provider)
    translated_count = 0
    with ThreadPoolExecutor(max_workers=MAX_PARALLEL_BATCHES) as executor:
        translate_batch = (
            request_google_translations if args.provider == "google" else request_translations
        )
        pending = {
            executor.submit(translate_batch, batch): (batch_index, batch)
            for batch_index, batch in enumerate(batches, 1)
        }
        for future in as_completed(pending):
            batch_index, batch = pending[future]
            translated = future.result()
            for item_id, source in batch:
                cache[source] = translated[item_id]
                translated_count += 1
            save_cache(cache)
            if args.provider == "google" or translated_count % 25 == 0 or translated_count == len(missing):
                print(
                    f"Translated {translated_count}/{len(missing)} new strings "
                    f"(latest batch {batch_index}/{len(batches)}).",
                    flush=True,
                )

    write_bundle(pages, cache)
    print(
        f"Wrote {OUTPUT_PATH.name} with {sum(len(values) for values in pages.values())} page strings "
        f"({translated_count} newly translated).",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
