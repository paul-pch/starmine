#!/usr/bin/env python3
"""Prépare l'image de départ d'une retouche : agrandit une zone sur place, sans toucher au reste.

Sert à donner plus de place à l'élément central d'une image, sans agrandir son socle. Une passe du
modèle (`source`, `denoise` dans le fichier de série) harmonise ensuite le montage.

  ~/ComfyUI/.venv/bin/python tool/comfy_grow.py <entrée.png> <sortie.png> \\
      --box GAUCHE HAUT DROITE BAS --anchor X Y --scale 1.25

`--anchor` est le point qui ne bouge pas, en général le bas de l'élément, là où il touche son socle. Les
bords de la zone sont fondus, sauf ceux qui touchent le bord de l'image et le bas, côté ancrage.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

FEATHER = 24


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("--box", type=int, nargs=4, required=True, metavar=("GAUCHE", "HAUT", "DROITE", "BAS"))
    parser.add_argument("--anchor", type=int, nargs=2, required=True, metavar=("X", "Y"))
    parser.add_argument("--scale", type=float, default=1.25)
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGB")
    left, top, right, bottom = args.box
    anchor_x, anchor_y = args.anchor
    piece = image.crop(args.box)
    size = (round(piece.width * args.scale), round(piece.height * args.scale))
    piece = piece.resize(size, Image.LANCZOS)
    x = round(anchor_x - (anchor_x - left) * args.scale)
    y = round(anchor_y - (anchor_y - top) * args.scale)

    # Le dépassement au-delà du cadre garde le masque plein pour que le flou ne morde pas sur ces bords.
    margin_left = -FEATHER * 2 if left <= 0 else FEATHER
    margin_right = FEATHER * 2 if right >= image.width else -FEATHER
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rectangle(
        (margin_left, FEATHER, size[0] - 1 + margin_right, size[1] + FEATHER * 2), fill=255
    )
    mask = mask.filter(ImageFilter.GaussianBlur(FEATHER / 2.4))

    image.paste(piece, (x, y), mask)
    args.target.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.target)
    print(f"{args.target} : zone de {size[0]} × {size[1]} px placée en ({x}, {y})")


if __name__ == "__main__":
    main()
