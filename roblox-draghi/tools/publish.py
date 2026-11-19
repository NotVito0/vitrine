#!/usr/bin/env python3
"""Pubblica il gioco su Roblox con Open Cloud (senza Roblox Studio).

Uso:  python3 tools/publish.py <PLACE_ID> [--saved]
  --saved   salva la versione senza pubblicarla (i giocatori non la vedono ancora)

La chiave API va nell'intestazione x-api-key. In una sessione cloud di Claude la mette il proxy;
altrove impostare la variabile ROBLOX_API_KEY.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://apis.roblox.com"


def request(method, url, data=None, content_type=None):
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("x-api-key", os.environ.get("ROBLOX_API_KEY", "proxy-injected"))
    if content_type:
        req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as err:
        return err.code, err.read().decode("utf-8", "replace")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args or not args[0].isdigit():
        print(__doc__)
        sys.exit(1)
    place_id = args[0]
    version_type = "Saved" if "--saved" in sys.argv else "Published"

    status, body = request("GET", f"{API}/universes/v1/places/{place_id}/universe")
    if status != 200:
        print("Non trovo l'esperienza di questo Place ID:", status, body)
        sys.exit(1)
    universe_id = json.loads(body)["universeId"]
    print("Esperienza (universe):", universe_id)

    out = os.path.join(ROOT, "build", "DragonElementsSim.rbxlx")
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "build_place.py"), out], check=True)
    with open(out, "rb") as f:
        content = f.read()

    url = f"{API}/universes/v1/{universe_id}/places/{place_id}/versions?versionType={version_type}"
    status, body = request("POST", url, content, "application/xml")
    if status != 200:
        print("Pubblicazione fallita:", status, body)
        sys.exit(1)
    print("Pubblicato! Versione:", json.loads(body).get("versionNumber"))


if __name__ == "__main__":
    main()
