#!/usr/bin/env python3
"""Prepara el arte de inicio de Velyntora sin la compresión extrema usada en el prototipo."""
from pathlib import Path
from PIL import Image

TARGET = (960, 700)
QUALITY = 80

def convert(source: Path, target: Path) -> None:
    with Image.open(source) as image:
        image = image.convert("RGB")
        image.thumbnail(TARGET, Image.Resampling.LANCZOS)
        image.save(target, "WEBP", quality=QUALITY, method=6)
        print(f"{source.name} -> {target.name}: {image.width}x{image.height}, {target.stat().st_size} bytes")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("drawing", type=Path)
    parser.add_argument("animation", type=Path)
    parser.add_argument("--output", type=Path, default=Path("app/src/main/res/drawable-nodpi"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    convert(args.drawing, args.output / "start_drawing.webp")
    convert(args.animation, args.output / "start_animation.webp")
