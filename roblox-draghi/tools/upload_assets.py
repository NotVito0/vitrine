#!/usr/bin/env python3
"""Carica immagini PNG su Roblox con Open Cloud e scrive gli ID in src/shared/Config/Art.lua.

Uso:  python3 tools/upload_assets.py <USER_ID> <cartella con i png> [--type Image|Decal]
Ogni file nome.png diventa Art.Icons.nome = "rbxassetid://ID".
Le immagini nuove passano la moderazione di Roblox: per qualche minuto possono non vedersi.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://apis.roblox.com/assets/v1"


def call(method, url, body=None, content_type=None):
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("x-api-key", os.environ.get("ROBLOX_API_KEY", "proxy-injected"))
    if content_type:
        req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as err:
        return err.code, err.read().decode("utf-8", "replace")


def upload(user_id, path, asset_type):
    name = os.path.splitext(os.path.basename(path))[0]
    request = {
        "assetType": asset_type,
        "displayName": "DES " + name,
        "description": "Dragon Elements Sim UI",
        "creationContext": {"creator": {"userId": str(user_id)}},
    }
    boundary = uuid.uuid4().hex
    with open(path, "rb") as f:
        data = f.read()
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(request)}\r\n"
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{name}.png\"\r\nContent-Type: image/png\r\n\r\n"
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
    status, result = call("POST", API + "/assets", body, "multipart/form-data; boundary=" + boundary)
    if status != 200:
        raise RuntimeError(f"{name}: {status} {result}")
    op = result.get("path") or result.get("operationId")
    op_id = op.split("/")[-1]
    for _ in range(30):
        status, result = call("GET", f"{API}/operations/{op_id}")
        if status == 200 and result.get("done"):
            return name, result["response"]["assetId"]
        time.sleep(2)
    raise RuntimeError(f"{name}: upload did not finish")


def main():
    user_id, folder = sys.argv[1], sys.argv[2]
    asset_type = sys.argv[sys.argv.index("--type") + 1] if "--type" in sys.argv else "Decal"
    ids = {}
    for file in sorted(os.listdir(folder)):
        if file.endswith(".png"):
            name, asset_id = upload(user_id, os.path.join(folder, file), asset_type)
            ids[name] = asset_id
            print(name, asset_id)
    art = os.path.join(ROOT, "src", "shared", "Config", "Art.lua")
    # Tiene le immagini già caricate e aggiunge (o aggiorna) quelle nuove.
    if os.path.exists(art):
        import re
        with open(art) as f:
            for name, value in re.findall(r"\t(\w+) = (\d+),", f.read()):
                ids.setdefault(name, int(value))
    lines = [
        "-- Immagini dell'interfaccia caricate su Roblox (generate da tools/upload_assets.py).",
        "-- Sono ID di Decal: il server li converte in ID di immagine all'avvio (vedi ArtService).",
        "local Art = {}",
        "",
        "Art.Decals = {",
    ]
    for name in sorted(ids):
        lines.append(f'\t{name} = {ids[name]},')
    lines += ["}", "", "return Art", ""]
    with open(art, "w") as f:
        f.write("\n".join(lines))
    print("Scritto", art)


if __name__ == "__main__":
    main()
