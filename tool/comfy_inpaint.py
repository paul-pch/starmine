#!/usr/bin/env python3
"""Retouche une zone rectangulaire d'une image via l'API locale de ComfyUI (Qwen-Image-2.1).

Usage, avec le serveur ComfyUI lancé et le Python de son environnement (Pillow) :
  ~/ComfyUI/.venv/bin/python tool/comfy_inpaint.py <source.png> <serie> <code> \
      --box X0 Y0 X1 Y1 --prompt "ce que la zone doit montrer" [--denoise 0.85]

Sans `--box`, toute l'image est retouchée, sauf les zones protégées par `--keep-box X0 Y0 X1 Y1` et
`--keep-ellipse CX CY RX RY`, répétables. Génère une image par seed. Hors de la zone, adoucie sur ses
bords, chaque résultat reste identique au pixel près à la source. Sorties dans `~/ComfyUI/output/starmine_test/<serie>/` : les PNG et
`run.json`.
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from comfy_series import OUTPUT, call, fetch, wait_for

COMFY_INPUT = Path.home() / "ComfyUI" / "input"
FEATHER = 8


def workflow(source, mask, prompt, seed, denoise, prefix):
    """Mêmes modèle et réglages que comfy_series.py, à partir de l'image source masquée."""
    return {
        "unet": {"class_type": "UNETLoader", "inputs": {
            "unet_name": "qwen_image_2.1_int8_convrot.safetensors", "weight_dtype": "default"}},
        "cache": {"class_type": "QwenImage21Cache", "inputs": {
            "model": ["unet", 0], "device": "auto", "dtype": "default"}},
        "clip": {"class_type": "CLIPLoader", "inputs": {
            "clip_name": "qwen3vl_8b_int8_convrot.safetensors", "type": "qwen_image", "device": "default"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_2.1_vae_bf16.safetensors"}},
        "encode": {"class_type": "TextEncodeQwenImage21", "inputs": {
            "clip": ["clip", 0], "prompt": prompt, "negative_prompt": "", "resolution": 1024}},
        "image": {"class_type": "LoadImage", "inputs": {"image": source}},
        "mask": {"class_type": "LoadImageMask", "inputs": {"image": mask, "channel": "red"}},
        "latent": {"class_type": "VAEEncode", "inputs": {"pixels": ["image", 0], "vae": ["vae", 0]}},
        "masked": {"class_type": "SetLatentNoiseMask", "inputs": {
            "samples": ["latent", 0], "mask": ["mask", 0]}},
        "sample": {"class_type": "KSampler", "inputs": {
            "model": ["cache", 0], "positive": ["encode", 0], "negative": ["encode", 1],
            "latent_image": ["masked", 0], "seed": seed, "steps": 25, "cfg": 1,
            "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}},
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0], "filename_prefix": prefix}},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source", type=Path)
    parser.add_argument("series")
    parser.add_argument("code")
    parser.add_argument("--box", type=int, nargs=4, metavar=("X0", "Y0", "X1", "Y1"))
    parser.add_argument("--keep-box", type=int, nargs=4, action="append", default=[],
                        metavar=("X0", "Y0", "X1", "Y1"))
    parser.add_argument("--keep-ellipse", type=int, nargs=4, action="append", default=[],
                        metavar=("CX", "CY", "RX", "RY"))
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--denoise", type=float, default=0.85)
    parser.add_argument("--seeds", type=int, nargs="+", default=[4242, 7777])
    args = parser.parse_args()

    original = Image.open(args.source).convert("RGB")
    if not args.box and not (args.keep_box or args.keep_ellipse):
        parser.error("donner --box, ou au moins une zone protégée")
    mask = Image.new("L", original.size, 0 if args.box else 255)
    draw = ImageDraw.Draw(mask)
    if args.box:
        draw.rectangle(args.box, fill=255)
    for box in args.keep_box:
        draw.rectangle(box, fill=0)
    for cx, cy, rx, ry in args.keep_ellipse:
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=0)
    source_name = f"starmine_inpaint_{args.code}_source.png"
    mask_name = f"starmine_inpaint_{args.code}_mask.png"
    original.save(COMFY_INPUT / source_name)
    mask.save(COMFY_INPUT / mask_name)
    feathered = mask.filter(ImageFilter.GaussianBlur(FEATHER))

    out = OUTPUT / args.series
    out.mkdir(parents=True, exist_ok=True)
    run_path = out / "run.json"
    log = json.loads(run_path.read_text(encoding="utf-8")) if run_path.exists() else []
    for seed in args.seeds:
        prefix = f"starmine_test/{args.series}/raw-{args.code}-{seed}"
        graph = workflow(source_name, mask_name, args.prompt, seed, args.denoise, prefix)
        prompt_id = call("/prompt", {"prompt": graph})["prompt_id"]
        entry = wait_for(prompt_id)
        generated = fetch(entry["outputs"]["save"]["images"][0])
        result = Image.composite(generated, original, feathered)
        target = out / f"{args.code}-{seed}.png"
        result.save(target)
        changed = ImageChops.difference(result, original).getbbox()
        print(f"{target}: zone modifiée {changed}", flush=True)
        log.append({"code": f"{args.code}-{seed}", "source": str(args.source), "box": args.box,
                    "keep_box": args.keep_box, "keep_ellipse": args.keep_ellipse,
                    "denoise": args.denoise, "seed": seed, "prompt": args.prompt,
                    "prompt_id": prompt_id, "file": target.name})
    run_path.write_text(json.dumps(log, indent=1, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
