#!/usr/bin/env python3
"""Crea un file .rbxlx (gioco Roblox) da src/, senza bisogno di Rojo.

Uso:  python3 tools/build_place.py [file di uscita]
Il file si apre con un doppio clic in Roblox Studio.

Regole (le stesse di Rojo):
  cartella            -> Folder
  Nome.server.lua     -> Script
  Nome.client.lua     -> LocalScript
  Nome.lua            -> ModuleScript
"""
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

# Dove va ogni cartella di src/ nel gioco.
MAPPING = [
    ("ReplicatedStorage", None, "shared", "Shared"),
    ("ServerScriptService", None, "server", "Server"),
    ("StarterPlayer", "StarterPlayerScripts", "client", "Client"),
    ("ReplicatedFirst", None, "first", "First"),
]

counter = 0


def ref():
    global counter
    counter += 1
    return f"RBX{counter:08d}"


def cdata(text):
    # "]]>" chiuderebbe il blocco CDATA: lo spezziamo.
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(cls, name, children="", source=None):
    props = f'<string name="Name">{escape(name)}</string>'
    if source is not None:
        props += f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>'
    return f'<Item class="{cls}" referent="{ref()}"><Properties>{props}</Properties>{children}</Item>'


def build_dir(path, name):
    children = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            children.append(build_dir(full, entry))
        elif entry.endswith(".lua"):
            with open(full, encoding="utf-8") as f:
                source = f.read()
            if entry.endswith(".server.lua"):
                children.append(item("Script", entry[: -len(".server.lua")], source=source))
            elif entry.endswith(".client.lua"):
                children.append(item("LocalScript", entry[: -len(".client.lua")], source=source))
            else:
                children.append(item("ModuleScript", entry[: -len(".lua")], source=source))
    return item("Folder", name, "".join(children))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "DragonElementsSim.rbxlx")
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    services = []
    for service, sub, folder, name in MAPPING:
        content = build_dir(os.path.join(SRC, folder), name)
        if sub:
            content = item(sub, sub, content)
        services.append(item(service, service, content))
    xml = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        + "".join(services)
        + "</roblox>"
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Creato:", out)


if __name__ == "__main__":
    main()
