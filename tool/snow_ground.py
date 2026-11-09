"""Recolore en neige le sol brun d'une image, sans toucher aux pixels neutres (miroirs, tour)."""
import sys

import numpy as np
from PIL import Image, ImageFilter

source, target, top = sys.argv[1], sys.argv[2], int(sys.argv[3])
image = np.asarray(Image.open(source).convert("RGB")).astype(np.float32)
red, green, blue = image[..., 0], image[..., 1], image[..., 2]
warmth = red - blue
luminance = 0.299 * red + 0.587 * green + 0.114 * blue

# Sol brun : chaud et pas trop clair. Les miroirs sont neutres et clairs, les supports neutres et sombres.
weight = np.clip((warmth - 6) / 12, 0, 1) * np.clip((185 - luminance) / 30, 0, 1)
weight[: top] = 0
weight[:, :][: top + 30] *= np.linspace(0, 1, top + 30)[:, None]
smooth = Image.fromarray((weight * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
weight = np.asarray(smooth).astype(np.float32)[..., None] / 255

shade = np.clip(luminance / 130, 0, 1)[..., None] ** 0.65
shadow = np.array([108, 116, 134], dtype=np.float32)
light = np.array([243, 240, 238], dtype=np.float32)
snow = shadow + (light - shadow) * shade

result = image * (1 - weight) + snow * weight
Image.fromarray(result.clip(0, 255).astype(np.uint8)).save(target)
