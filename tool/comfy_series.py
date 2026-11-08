#!/usr/bin/env python3
"""Génère une série d'images de test via l'API locale de ComfyUI (Qwen-Image-2.1).

Usage, avec le serveur ComfyUI lancé et le Python de son environnement (Pillow) :
  ~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/<serie>.json

La série donne les seeds et, pour chaque image, un `id`, un `subject` et un `detail`, insérés dans
le prompt de `art/style/base_prompt.md`. Chaque image est générée sur chaque seed. Sorties dans
`~/ComfyUI/output/starmine_test/<serie>/` : les PNG, `run.json` et une planche `sheet_512.png`.
"""
import argparse
import io
import json
import re
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
SIZE = 1024
SHEET_CELL = 512


def load_template():
    match = re.search(r"```text\n(.+?)\n```", BASE_PROMPT.read_text(encoding="utf-8"), re.DOTALL)
    if not match:
        sys.exit(f"aucun bloc text dans {BASE_PROMPT}")
    return match.group(1)


def workflow(prompt, seed, prefix):
    """Réglages du template ComfyUI image_qwen_image_2_1_t2i, réécriture de prompt désactivée."""
    return {
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
            "width": SIZE, "height": SIZE, "batch_size": 1}},
        "sample": {"class_type": "KSampler", "inputs": {
            "model": ["cache", 0], "positive": ["encode", 0], "negative": ["encode", 1],
            "latent_image": ["latent", 0], "seed": seed, "steps": 25, "cfg": 1,
            "sampler_name": "euler", "scheduler": "simple", "denoise": 1}},
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0], "filename_prefix": prefix}},
    }


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
    sheet = Image.new("RGB", (columns * SHEET_CELL, len(rows) * SHEET_CELL), "black")
    for row, cells in enumerate(rows):
        for column, (label, image) in enumerate(cells):
            thumb = image.resize((SHEET_CELL, SHEET_CELL), Image.LANCZOS)
            draw = ImageDraw.Draw(thumb)
            draw.rectangle((0, 0, 8 + 7 * len(label), 16), fill="black")
            draw.text((4, 2), label, fill="white")
            sheet.paste(thumb, (column * SHEET_CELL, row * SHEET_CELL))
    sheet.save(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("series", type=Path)
    args = parser.parse_args()

    series = json.loads(args.series.read_text(encoding="utf-8"))
    template = load_template()
    name = series["series"]
    out = OUTPUT / name
    out.mkdir(parents=True, exist_ok=True)

    rows, log = [], []
    for item in series["images"]:
        prompt = template.format(subject=item["subject"], detail=item["detail"])
        cells = []
        for seed in series["seeds"]:
            started = time.time()
            prefix = f"starmine_test/{name}/{item['id']}_s{seed}"
            prompt_id = call("/prompt", {"prompt": workflow(prompt, seed, prefix)})["prompt_id"]
            entry = wait_for(prompt_id)
            cells.append((f"{item['id']} {seed}", fetch(entry["outputs"]["save"]["images"][0])))
            elapsed = round(time.time() - started, 1)
            print(f"{item['id']} seed={seed}: {elapsed}s", flush=True)
            log.append({"id": item["id"], "seed": seed, "seconds": elapsed,
                        "prompt_id": prompt_id, "prompt": prompt})
        rows.append(cells)
    (out / "run.json").write_text(json.dumps(log, indent=1, ensure_ascii=False), encoding="utf-8")
    contact_sheet(rows, len(series["seeds"]), out / "sheet_512.png")
    print(f"planche : {out / 'sheet_512.png'}")


if __name__ == "__main__":
    main()
