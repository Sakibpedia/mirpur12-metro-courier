#!/usr/bin/env python3
"""Convert the real Mirpur 12, Dhaka OSM extract into compact game map data.

Input : assets/maps/mirpur12_overpass.json (Overpass API, ODbL 1.0)
Output: assets/maps/mirpur12.json + assets/maps/mirpur12_osm.png
"""
import json, math, pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "assets" / "maps"
SRC = MAPS / "mirpur12_overpass.json"
OUT = MAPS / "mirpur12.json"
PNG = MAPS / "mirpur12_osm.png"

CENTER_LAT, CENTER_LON = 23.8251043, 90.3706719
MX = 111320.0 * math.cos(math.radians(CENTER_LAT))
MY = 110540.0
WIDTH = {"motorway": 16, "trunk": 13, "primary": 11, "primary_link": 8,
    "secondary": 9, "secondary_link": 7, "tertiary": 7, "residential": 4.5,
    "living_street": 3.6, "service": 2.8, "unclassified": 4, "path": 1.2,
    "footway": 1.2, "track": 2.0}
SHELTER_KINDS = {"clinic", "hospital", "school", "pharmacy", "water_point"}


def xy(lat, lon):
    return [(lon - CENTER_LON) * MX, -(lat - CENTER_LAT) * MY]


def main():
    raw = json.loads(SRC.read_text(encoding="utf-8"))
    roads, buildings, amenities, shelters = [], [], [], []
    for e in raw["elements"]:
        tags = e.get("tags", {})
        geom = e.get("geometry", [])
        if e["type"] == "way" and "highway" in tags and len(geom) > 1:
            pts = [[round(v, 2) for v in xy(p["lat"], p["lon"])] for p in geom]
            roads.append({"pts": pts, "w": WIDTH.get(tags["highway"], 3.0),
                "kind": tags["highway"], "name": tags.get("name", "")})
        elif e["type"] == "way" and "building" in tags and len(geom) > 2:
            pts = [[round(v, 2) for v in xy(p["lat"], p["lon"])] for p in geom]
            try:
                levels = int(tags.get("building:levels", 0)) or max(2, int(float(tags.get("height", 9)) / 3))
            except (ValueError, TypeError):
                levels = 4
            buildings.append({"pts": pts, "floors": max(2, min(20, levels)),
                "kind": tags["building"], "name": tags.get("name", "")})
        elif e["type"] == "node" and "amenity" in tags:
            p = xy(e["lat"], e["lon"])
            item = {"p": [round(v, 2) for v in p], "kind": tags["amenity"],
                "name": tags.get("name", "")}
            amenities.append(item)
            if tags["amenity"] in SHELTER_KINDS:
                shelters.append(item)

    out = {"attribution": "OpenStreetMap contributors (ODbL 1.0) - Mirpur 12, Dhaka",
        "center": [CENTER_LAT, CENTER_LON], "roads": roads, "buildings": buildings,
        "amenities": amenities, "shelters": shelters}
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    size, scale = 2048, 1.55
    img = Image.new("RGB", (size, size), (10, 20, 24))
    d = ImageDraw.Draw(img)
    def px(p):
        return (size / 2 + p[0] * scale, size / 2 + p[1] * scale)
    for b in buildings:
        d.polygon([px(p) for p in b["pts"]], fill=(54, 50, 44))
    for r in roads:
        pts = [px(p) for p in r["pts"]]
        d.line(pts, fill=(22, 34, 40), width=max(2, int(r["w"] * scale)))
        d.line(pts, fill=(90, 120, 130), width=1)
    for a in shelters:
        x, y = px(a["p"])
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(240, 190, 90))
    img.save(PNG, optimize=True)

    names = sorted({r["name"] for r in roads if r["name"]})
    print("roads", len(roads), "named", len(names), "buildings", len(buildings),
        "amenities", len(amenities), "shelters", len(shelters))
    print("json KB", OUT.stat().st_size // 1024, "png KB", PNG.stat().st_size // 1024)


if __name__ == "__main__":
    main()
