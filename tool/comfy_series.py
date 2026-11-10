#!/usr/bin/env python3
"""Génère une série d'images de test via l'API locale de ComfyUI (Qwen-Image-2.1).

Usage, avec le serveur ComfyUI lancé et le Python de son environnement (Pillow) :
  ~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/<serie>.json

La série donne les seeds, des `variants` facultatives et, pour chaque image, un `id`, un `subject`
et un `detail`, insérés dans le prompt de `art/style/base_prompt.md`. Les valeurs par défaut de
`view`, `site` et `state` viennent de cette base ; une variante ou une image peut les remplacer.
Une série peut désigner une autre charte avec `base`, chemin relatif à la racine du dépôt. Une variante
ou une image peut limiter ses seeds avec `seeds`, quand sa `source` vient d'une seule seed.
Une série peut donner `size`, `[largeur, hauteur]` en pixels (multiples de 16), pour un format non carré ;
par défaut 1024 × 1024.

Une série peut s'itérer : ajouter une entrée à `images`, avec son propre `variant`, puis relancer. Un code
déjà présent dans `run.json` n'est pas régénéré ; galerie et planche montrent tous les essais.
Une variante ou une image peut aussi donner `source`, image de départ relative au dossier de sortie,
et `denoise`, part de l'image transformée, de 0 à 1. Chaque image est générée pour chaque variante et chaque seed. Sorties
dans `~/ComfyUI/output/starmine_test/<serie>/` : les PNG, `run.json`, une planche `sheet_512.png`
et une galerie `index.html` où chaque image porte un code à citer pour la sélectionner.
"""
import argparse
import html
import io
import json
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw

SERVER = "http://127.0.0.1:8188"
REPO = Path(__file__).resolve().parent.parent
BASE_PROMPT = REPO / "art" / "style" / "base_prompt.md"
OUTPUT = Path.home() / "ComfyUI" / "output" / "starmine_test"
COMFY_INPUT = Path.home() / "ComfyUI" / "input"
SIZE = 1024
SHEET_CELL = 512


def load_base(path=BASE_PROMPT):
    """Renvoie le gabarit du bloc `text` et les valeurs par défaut données par les autres blocs."""
    blocks = dict(re.findall(r"```(\w+)\n(.+?)\n```", path.read_text(encoding="utf-8"), re.DOTALL))
    if "text" not in blocks:
        sys.exit(f"aucun bloc text dans {path}")
    template = blocks.pop("text")
    return template, blocks


def workflow(prompt, seed, prefix, source=None, denoise=1, size=(SIZE, SIZE)):
    """Réglages du template ComfyUI image_qwen_image_2_1_t2i, réécriture de prompt désactivée.

    Avec `source`, nom d'une image du dossier d'entrée de ComfyUI, on part de cette image.
    """
    graph = {
        "unet": {"class_type": "UNETLoader", "inputs": {
            "unet_name": "qwen_image_2.1_int8_convrot.safetensors", "weight_dtype": "default"}},
        "cache": {"class_type": "QwenImage21Cache", "inputs": {
            "model": ["unet", 0], "device": "auto", "dtype": "default"}},
        "clip": {"class_type": "CLIPLoader", "inputs": {
            "clip_name": "qwen3vl_8b_int8_convrot.safetensors", "type": "qwen_image", "device": "default"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_2.1_vae_bf16.safetensors"}},
        "encode": {"class_type": "TextEncodeQwenImage21", "inputs": {
            "clip": ["clip", 0], "prompt": prompt, "negative_prompt": "", "resolution": SIZE}},
        "latent": {"class_type": "EmptyLatentImage", "inputs": {
            "width": size[0], "height": size[1], "batch_size": 1}},
        "sample": {"class_type": "KSampler", "inputs": {
            "model": ["cache", 0], "positive": ["encode", 0], "negative": ["encode", 1],
            "latent_image": ["latent", 0], "seed": seed, "steps": 25, "cfg": 1,
            "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}},
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0], "filename_prefix": prefix}},
    }
    if source:
        graph["image"] = {"class_type": "LoadImage", "inputs": {"image": source}}
        graph["latent"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["image", 0], "vae": ["vae", 0]}}
    return graph


def load_source(source):
    """Copie une image de `OUTPUT` dans le dossier d'entrée de ComfyUI et renvoie son nom."""
    if not source:
        return None
    path = OUTPUT / source
    if not path.is_file():
        sys.exit(f"image source introuvable : {path}")
    name = "starmine_source_" + source.replace("/", "_")
    shutil.copyfile(path, COMFY_INPUT / name)
    return name


def call(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(
        SERVER + path, data=data, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit(f"HTTP {error.code} sur {path} : {error.read().decode()[:3000]}")


def wait_for(prompt_id, timeout=600):
    deadline = time.time() + timeout
    while time.time() < deadline:
        entry = call(f"/history/{prompt_id}").get(prompt_id)
        status = (entry or {}).get("status", {})
        if status.get("status_str") == "error":
            sys.exit(json.dumps(status, indent=1)[:3000])
        if status.get("completed"):
            return entry
        time.sleep(0.5)
    sys.exit(f"délai dépassé pour {prompt_id}")


def fetch(image):
    query = urllib.parse.urlencode(
        {"filename": image["filename"], "subfolder": image["subfolder"], "type": image["type"]}
    )
    with urllib.request.urlopen(f"{SERVER}/view?{query}", timeout=120) as response:
        return Image.open(io.BytesIO(response.read())).convert("RGB")


def contact_sheet(rows, columns, target):
    """Cellules de 512 px de large, hauteur selon le format des images."""
    first = rows[0][0][1]
    cell_h = round(SHEET_CELL * first.height / first.width)
    sheet = Image.new("RGB", (columns * SHEET_CELL, len(rows) * cell_h), "black")
    for row, cells in enumerate(rows):
        for column, (label, image) in enumerate(cells):
            thumb = image.resize((SHEET_CELL, cell_h), Image.LANCZOS)
            draw = ImageDraw.Draw(thumb)
            draw.rectangle((0, 0, 8 + 7 * len(label), 16), fill="black")
            draw.text((4, 2), label, fill="white")
            sheet.paste(thumb, (column * SHEET_CELL, row * cell_h))
    sheet.save(target)


def gallery(name, entries, columns, target):
    """Page locale : images en taille réelle au clic, code à citer sous chacune."""
    cells = "".join(
        f'<figure><a href="{html.escape(entry["file"])}" target="_blank">'
        f'<img src="{html.escape(entry["file"])}" loading="lazy" alt="{html.escape(entry["code"])}"></a>'
        f'<figcaption>{html.escape(entry["code"])}</figcaption></figure>'
        for entry in entries
    )
    target.write_text(
        f"""<!doctype html><meta charset="utf-8"><title>{html.escape(name)}</title>
<style>
body {{ background: #15171a; color: #eee; font: 15px system-ui; margin: 16px; }}
main {{ display: grid; gap: 12px; grid-template-columns: repeat({columns}, minmax(0, 512px)); }}
figure {{ margin: 0; }} img {{ width: 100%; display: block; }}
figcaption {{ padding: 6px 0; font-family: monospace; user-select: all; }}
</style><h1>{html.escape(name)}</h1><main>{cells}</main>
""",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("series", type=Path)
    args = parser.parse_args()

    series = json.loads(args.series.read_text(encoding="utf-8"))
    template, defaults = load_base(REPO / series["base"]) if "base" in series else load_base()
    name = series["series"]
    out = OUTPUT / name
    out.mkdir(parents=True, exist_ok=True)

    run_path = out / "run.json"
    log = json.loads(run_path.read_text(encoding="utf-8")) if run_path.exists() else []
    done = {entry["code"] for entry in log}
    for variant in series.get("variants", [{}]):
        for item in series["images"]:
            tag = {**variant, **item}.get("variant", "")
            try:
                prompt = template.format(**{**defaults, **variant, **item})
            except KeyError as missing:
                sys.exit(f"champ {missing} absent de {args.series} pour {item['id']}")
            for seed in {**variant, **item}.get("seeds", series["seeds"]):
                building = item["id"].split(".")[1]
                code = "-".join(part for part in (tag, building, str(seed)) if part)
                if code in done:
                    print(f"{code}: déjà généré", flush=True)
                    continue
                started = time.time()
                prefix = f"starmine_test/{name}/{code}"
                source = {**variant, **item}.get("source")
                denoise = {**variant, **item}.get("denoise", 1)
                graph = workflow(prompt, seed, prefix, load_source(source), denoise, series.get("size", (SIZE, SIZE)))
                prompt_id = call("/prompt", {"prompt": graph})["prompt_id"]
                entry = wait_for(prompt_id)
                saved = entry["outputs"]["save"]["images"][0]
                elapsed = round(time.time() - started, 1)
                print(f"{code}: {elapsed}s", flush=True)
                log.append({"code": code, "id": item["id"], "variant": tag, "seed": seed,
                            "source": source, "denoise": denoise, "seconds": elapsed, "prompt_id": prompt_id, "file": saved["filename"],
                            "prompt": prompt})
                run_path.write_text(json.dumps(log, indent=1, ensure_ascii=False), encoding="utf-8")
    columns = len(series["seeds"])
    cells = [(entry["code"], Image.open(out / entry["file"]).convert("RGB")) for entry in log]
    rows = [cells[start:start + columns] for start in range(0, len(cells), columns)]
    contact_sheet(rows, columns, out / "sheet_512.png")
    gallery(name, log, columns, out / "index.html")
    print(f"galerie : {out / 'index.html'}")
    print(f"planche : {out / 'sheet_512.png'}")


if __name__ == "__main__":
    main()
