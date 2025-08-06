#!/usr/bin/env python3

import sys
import json
import lz4.block as lb
from uuid import uuid4

OUTPUT_FILE = "search.json.mozlz4"

BUILT_IN = {
    "Google": {
        "id": "google",
        "_name": "Google",
        "_metaData": {"order": 1, "alias": "g"},
    },
    "百度": {
        "id": "baidu",
        "_name": "百度",
        "_metaData": {"order": 2, "alias": "bd"},
    },
    "Bing": {
        "id": "bing",
        "_name": "Bing",
        "_metaData": {"order": 3, "alias": "bing"},
    },
    "DuckDuckGo": {
        "id": "ddg",
        "_name": "DuckDuckGo",
        "_metaData": {"order": 4, "alias": "ddg"},
    },
    "维基百科": {
        "id": "wikipedia-zh-CN",
        "_name": "维基百科",
        "_metaData": {"order": 5, "alias": "wk"}
    }
}


def build_firefox_search_json(engines):
    engine_entries = []
    base_order = len(BUILT_IN.keys())
    for i, engine in enumerate(engines):
        name = engine["name"]
        keyword = engine["keyword"]
        if name in BUILT_IN:
            entry = BUILT_IN[name]
            entry["_isAppProvided"] = True
            entry["_metaData"]["alias"] = keyword
            del BUILT_IN[name]
        else:
            url = engine["url"].replace("%s", "{searchTerms}")
            entry = {
                "id": str(uuid4()),
                "_name": name,
                "_loadPath": "[user]",
                "_metaData": {"alias": keyword, "order": i+base_order},
                "_urls": [
                    {"params": [], "rels": [], "template": url}
                ]
            }
        engine_entries.append(entry)

    for engine in BUILT_IN.values():
        engine["_isAppProvided"] = True
        engine_entries.append(engine)

    search_config = {
        "version": 12,
        "engines": engine_entries,
        "metaData": {
            "useSavedOrder": True,
            "appDefaultEngineId": "google"
        }
    }
    return search_config


def write_mozlz4(data, output_file):
    compressed = lb.compress(data.encode("utf-8"))
    with open(output_file, "wb") as f:
        f.write(b"mozLz40\0" + compressed)


def main(filePath):
    with open(filePath, "r", encoding="utf-8") as f:
        input_engines = json.load(f)
    firefox_json = build_firefox_search_json(input_engines)
    firefox_json_str = json.dumps(
        firefox_json, indent=None, separators=(",", ":"))
    write_mozlz4(firefox_json_str, OUTPUT_FILE)
    print(f"✅ {OUTPUT_FILE}")


if __name__ == "__main__":
    main(sys.argv[1])
