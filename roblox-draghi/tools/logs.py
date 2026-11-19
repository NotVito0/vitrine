#!/usr/bin/env python3
"""Legge il registro degli errori del gioco (DataStore Diagnostics_v1, chiave "log") con Open Cloud.

Uso:  python3 tools/logs.py <UNIVERSE_ID> [--clear]
"""
import datetime
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://apis.roblox.com/datastores/v1/universes/{u}/standard-datastores/datastore/entries/entry"


def call(method, url):
    req = urllib.request.Request(url, method=method)
    req.add_header("x-api-key", os.environ.get("ROBLOX_API_KEY", "proxy-injected"))
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as err:
        return err.code, err.read().decode("utf-8", "replace")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    universe = sys.argv[1]
    url = API.format(u=universe) + "?" + urllib.parse.urlencode({"datastoreName": "Diagnostics_v1", "entryKey": "log"})
    if "--clear" in sys.argv:
        print(call("DELETE", url))
        return
    status, body = call("GET", url)
    if status != 200:
        print("Nessun registro (ancora):", status, body[:200])
        return
    data = json.loads(body)
    when = datetime.datetime.fromtimestamp(data.get("Updated", 0), datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    print("Aggiornato:", when, "| voci:", len(data.get("Entries", [])))
    for e in data.get("Entries", []):
        last = datetime.datetime.fromtimestamp(e["Last"], datetime.timezone.utc).strftime("%H:%M")
        print(f"\n[{e['Side']}] x{e['Count']} v{e.get('Version')} ultimo {last}\n  {e['Msg']}")
        if e.get("Trace"):
            print("  " + e["Trace"].replace("\n", "\n  "))


if __name__ == "__main__":
    main()
