#!/usr/bin/env python3
"""Exporte en WebP les images `validated` de `art/registry.yaml` (spec 11).

Usage : python3 tool/export_visuals.py
Dépendances : Pillow et PyYAML. Lit chaque `master`, écrit son `build` aux dimensions du `format`,
qualité 80. Les masters sont locaux, ignorés par Git. Échoue si un master manque, et signale les
WebP de `assets/visuels/` absents du registre.
"""
import sys
from pathlib import Path

import yaml
from PIL import Image, UnidentifiedImageError

REPO = Path(__file__).resolve().parent.parent
REGISTRY = REPO / "art" / "registry.yaml"
BUILD_DIR = REPO / "assets" / "visuels"
QUALITY = 80


def dimensions(fmt):
    """`1:1 512` donne 512 × 512 ; `4:3 640x480` donne 640 × 480."""
    size = fmt.split()[1]
    if "x" in size:
        width, height = size.split("x")
        return int(width), int(height)
    return int(size), int(size)


def main():
    images = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))["images"]
    validated = [e for e in images if e["status"] == "validated"]
    errors = []
    total = 0
    for entry in validated:
        master = REPO / entry["master"]
        build = REPO / entry["build"]
        try:
            with Image.open(master) as image:
                resized = image.convert("RGB").resize(dimensions(entry["format"]), Image.LANCZOS)
        except (FileNotFoundError, UnidentifiedImageError) as error:
            errors.append(f"{entry['id']} : master illisible ({error})")
            continue
        resized.save(build, "WEBP", quality=QUALITY, method=6)
        total += build.stat().st_size

    expected = {REPO / e["build"] for e in validated}
    for orphan in sorted(set(BUILD_DIR.glob("*.webp")) - expected):
        errors.append(f"{orphan.name} : absent du registre ou non validé")

    print(f"{len(validated) - len(errors)} WebP exportés, {total / 1024 / 1024:.2f} Mo")
    for error in errors:
        print(f"ERREUR {error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
