#!/usr/bin/env fontforge

import os
import sys

import fontforge
import psMat


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_PATH = os.path.join(ROOT, "qml", "fonts", "bootstrap-icons.ttf")
ICON_SPECS = (
    (0xF000, "wrench_2", os.path.join(ROOT, "assets", "wrench_2.svg")),
    (0xF001, "wrench_3", os.path.join(ROOT, "assets", "wrench_3.svg")),
)
PADDING = 18


def normalize_glyph(font, glyph):
    glyph.removeOverlap()
    glyph.correctDirection()

    xmin, ymin, xmax, ymax = glyph.boundingBox()
    if xmax <= xmin or ymax <= ymin:
        raise RuntimeError("Imported glyph has an empty bounding box")

    target_size = font.em - 2 * PADDING
    scale = min(target_size / (xmax - xmin), target_size / (ymax - ymin))
    glyph.transform(psMat.scale(scale))

    xmin, ymin, xmax, ymax = glyph.boundingBox()
    x_shift = (font.em - (xmax - xmin)) / 2 - xmin
    y_shift = (font.em - (ymax - ymin)) / 2 - ymin
    glyph.transform(psMat.translate(x_shift, y_shift))
    glyph.width = font.em


def main():
    if not os.path.exists(FONT_PATH):
        raise FileNotFoundError(FONT_PATH)

    font = fontforge.open(FONT_PATH)

    for codepoint, glyph_name, svg_path in ICON_SPECS:
        if not os.path.exists(svg_path):
            raise FileNotFoundError(svg_path)

        glyph = font.createChar(codepoint, glyph_name)
        glyph.clear()
        glyph.importOutlines(svg_path)
        normalize_glyph(font, glyph)

    font.generate(FONT_PATH)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"update_bootstrap_icons.py failed: {exc}", file=sys.stderr)
        sys.exit(1)
