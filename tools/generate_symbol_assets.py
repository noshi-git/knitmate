#!/usr/bin/env python3
"""Audit official GIF sources and generate app PNG assets (Step 0 + Step 1)."""

from __future__ import annotations

import json
import math
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "official_symbols_source"
OUTPUT_DIR = ROOT / "assets" / "symbols"
MANIFEST_PATH = ROOT / "tools" / "symbol_asset_manifest.json"
CONTACT_SHEET_PATH = ROOT / "tools" / "symbol_assets_contact_sheet.png"

CANVAS_SIZE = 256
CONTENT_PADDING_RATIO = 0.14  # matches StitchSymbolMetrics.padding
INK_ALPHA_THRESHOLD = 8

SYMBOLS: list[dict[str, object]] = [
    {"no": 1, "storageIndex": 1, "id": "single_crochet"},
    {"no": 2, "storageIndex": 2, "id": "double_crochet"},
    {"no": 3, "storageIndex": 3, "id": "treble_crochet"},
    {"no": 4, "storageIndex": 4, "id": "slip_stitch"},
    {"no": 5, "storageIndex": 5, "id": "chain"},
    {"no": 6, "storageIndex": 6, "id": "half_double_crochet"},
    {"no": 7, "storageIndex": 7, "id": "single_crochet_inc2"},
    {"no": 8, "storageIndex": 8, "id": "single_crochet_inc3"},
    {"no": 9, "storageIndex": 9, "id": "single_crochet_dec2"},
    {"no": 10, "storageIndex": 10, "id": "half_double_crochet_inc2"},
    {"no": 11, "storageIndex": 11, "id": "half_double_crochet_dec2"},
    {"no": 12, "storageIndex": 12, "id": "double_crochet_inc2"},
    {"no": 13, "storageIndex": 13, "id": "double_crochet_dec2"},
    {"no": 14, "storageIndex": 14, "id": "treble_crochet_inc2"},
    {"no": 15, "storageIndex": 15, "id": "treble_crochet_dec2"},
    {"no": 16, "storageIndex": 16, "id": "single_crochet_front_post"},
    {"no": 17, "storageIndex": 17, "id": "single_crochet_back_post"},
    {"no": 18, "storageIndex": 18, "id": "single_crochet_ch1_single_crochet"},
    {"no": 19, "storageIndex": 19, "id": "single_crochet_ch2_single_crochet"},
    {"no": 20, "storageIndex": 20, "id": "rib_single_crochet"},
    {"no": 21, "storageIndex": 21, "id": "reverse_single_crochet"},
    {"no": 22, "storageIndex": 22, "id": "twisted_single_crochet"},
    {"no": 23, "storageIndex": 23, "id": "picot"},
    {"no": 24, "storageIndex": 24, "id": "half_double_crochet_cluster3"},
    {"no": 25, "storageIndex": 25, "id": "half_double_crochet_front_post"},
    {"no": 26, "storageIndex": 26, "id": "half_double_crochet_back_post"},
    {"no": 27, "storageIndex": 27, "id": "crossed_double_crochet"},
    {"no": 28, "storageIndex": 28, "id": "double_crochet_cluster3"},
    {"no": 29, "storageIndex": 29, "id": "double_crochet_popcorn5"},
    {"no": 30, "storageIndex": 30, "id": "double_crochet_front_post"},
    {"no": 31, "storageIndex": 31, "id": "double_crochet_back_post"},
    {"no": 32, "storageIndex": 32, "id": "ring_stitch"},
    {"no": 33, "storageIndex": 33, "id": "double_crochet_shell5_in_stitch"},
    {"no": 34, "storageIndex": 34, "id": "double_crochet_shell5_over_stitches"},
    {"no": 35, "storageIndex": 35, "id": "attach_yarn"},
    {"no": 36, "storageIndex": 36, "id": "cut_yarn"},
]


def find_source_file(storage_index: int) -> Path | None:
    candidates = [
        SOURCE_DIR / f"{storage_index:02d}.gif",
        SOURCE_DIR / f"{storage_index}.gif",
    ]
    for path in candidates:
        if path.is_file():
            return path
    return None


def load_first_frame(path: Path) -> Image.Image:
    with Image.open(path) as gif:
        gif.seek(0)
        return gif.convert("RGBA")


def luminance(r: int, g: int, b: int) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def detect_background_color(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    corner_samples: list[tuple[int, int, int]] = []
    w, h = rgba.size
    points = [
        (0, 0),
        (w - 1, 0),
        (0, h - 1),
        (w - 1, h - 1),
        (w // 2, 0),
        (w // 2, h - 1),
        (0, h // 2),
        (w - 1, h // 2),
    ]
    pixels = rgba.load()
    for x, y in points:
        r, g, b, _ = pixels[x, y]
        corner_samples.append((r, g, b))

    counter = Counter(corner_samples)
    bg = counter.most_common(1)[0][0]

    # Fallback: most common fully opaque color in the image.
    if len(counter) > 1:
        all_colors = Counter(
            (pixels[x, y][0], pixels[x, y][1], pixels[x, y][2])
            for x in range(w)
            for y in range(h)
            if pixels[x, y][3] > 200
        )
        if all_colors:
            bg = all_colors.most_common(1)[0][0]
    return bg


def rgba_to_black_alpha(image: Image.Image) -> Image.Image:
    """Convert source pixels to black RGB with alpha from ink density.

    White background -> alpha 0
    Black ink -> alpha 255
    Gray anti-aliased edge -> intermediate alpha
    """
    src = image.convert("RGBA")
    bg = detect_background_color(src)
    bg_lum = luminance(*bg)
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    src_px = src.load()
    out_px = out.load()

    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src_px[x, y]
            if a == 0:
                continue

            lum = luminance(r, g, b)
            # Distance from background luminance toward black.
            if bg_lum <= 1:
                ink = 255 - lum
            else:
                ink = max(0.0, min(255.0, (bg_lum - lum) / bg_lum * 255.0))

            # Preserve source GIF alpha when present.
            ink = ink * (a / 255.0)
            alpha = int(round(max(0.0, min(255.0, ink))))
            if alpha <= 0:
                continue
            out_px[x, y] = (0, 0, 0, alpha)

    return out


def ink_bbox(image: Image.Image, threshold: int = INK_ALPHA_THRESHOLD) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    return bbox


def analyze_antialiasing(image: Image.Image) -> dict[str, int | bool]:
    alpha_channel = image.getchannel("A")
    hist = alpha_channel.histogram()
    mid_count = sum(hist[10:246])
    min_alpha = 255
    max_alpha = 0
    for value, count in enumerate(hist):
        if count == 0:
            continue
        if value > INK_ALPHA_THRESHOLD:
            min_alpha = min(min_alpha, value)
            max_alpha = max(max_alpha, value)
    return {
        "hasGrayAntialiasing": mid_count > 0,
        "intermediateAlphaPixels": mid_count,
        "minInkAlpha": min_alpha if max_alpha > 0 else 0,
        "maxInkAlpha": max_alpha,
    }


def audit_symbol(entry: dict[str, object]) -> dict[str, object]:
    storage_index = int(entry["storageIndex"])
    source_path = find_source_file(storage_index)
    record: dict[str, object] = {
        "no": entry["no"],
        "storageIndex": storage_index,
        "id": entry["id"],
        "sourceFile": source_path.name if source_path else None,
        "sourcePath": str(source_path.relative_to(ROOT)).replace("\\", "/")
        if source_path
        else None,
        "outputFile": f"{entry['id']}.png",
        "outputPath": f"assets/symbols/{entry['id']}.png",
        "anomalies": [],
    }

    if source_path is None:
        record["anomalies"].append("source GIF not found")
        return record

    frame = load_first_frame(source_path)
    converted = rgba_to_black_alpha(frame)
    bbox = ink_bbox(converted)
    bg = detect_background_color(frame)
    aa = analyze_antialiasing(converted)

    record.update(
        {
            "sourceSize": {"width": frame.width, "height": frame.height},
            "backgroundColor": {"r": bg[0], "g": bg[1], "b": bg[2]},
            "inkBbox": None
            if bbox is None
            else {
                "left": bbox[0],
                "top": bbox[1],
                "right": bbox[2],
                "bottom": bbox[3],
                "width": bbox[2] - bbox[0],
                "height": bbox[3] - bbox[1],
            },
            "hasGrayAntialiasing": aa["hasGrayAntialiasing"],
            "intermediateAlphaPixels": aa["intermediateAlphaPixels"],
            "minInkAlpha": aa["minInkAlpha"],
            "maxInkAlpha": aa["maxInkAlpha"],
        }
    )

    if bbox is None:
        record["anomalies"].append("no ink pixels detected")
    else:
        bw = bbox[2] - bbox[0]
        bh = bbox[3] - bbox[1]
        if bw <= 0 or bh <= 0:
            record["anomalies"].append("invalid ink bbox")
        if bw > frame.width or bh > frame.height:
            record["anomalies"].append("ink bbox larger than source canvas")

    if frame.width < 8 or frame.height < 8:
        record["anomalies"].append("unusually small source canvas")

    return record


def build_manifest(records: list[dict[str, object]]) -> dict[str, object]:
    valid = [r for r in records if r.get("inkBbox") is not None]
    max_extent = max(
        max(int(r["inkBbox"]["width"]), int(r["inkBbox"]["height"])) for r in valid
    )
    target_content = CANVAS_SIZE * (1.0 - 2.0 * CONTENT_PADDING_RATIO)
    global_scale = target_content / max_extent
    dominant_no = max(
        valid,
        key=lambda r: max(
            int(r["inkBbox"]["width"]),
            int(r["inkBbox"]["height"]),
        ),
    )

    return {
        "version": 1,
        "sourceDir": "official_symbols_source",
        "outputDir": "assets/symbols",
        "canvasSize": CANVAS_SIZE,
        "contentPaddingRatio": CONTENT_PADDING_RATIO,
        "targetContentSize": target_content,
        "globalScaleMethod": (
            "targetContentSize / max(max(inkWidth, inkHeight) across all 36 symbols); "
            "each cropped ink bbox is scaled uniformly by globalScale and centered "
            "on a 256x256 transparent canvas (no per-symbol bbox fill)."
        ),
        "globalScale": global_scale,
        "referenceMaxInkExtentPx": max_extent,
        "referenceSymbol": {
            "no": dominant_no["no"],
            "id": dominant_no["id"],
            "inkBbox": dominant_no["inkBbox"],
        },
        "alphaConversionMethod": (
            "Detect background color from corners/dominant color. "
            "For each pixel: ink = clamp((bgLum - pixelLum) / bgLum * 255) * (srcAlpha/255). "
            "Output RGB=(0,0,0) with computed alpha. "
            "White->alpha 0, black->alpha 255, gray anti-aliasing->intermediate alpha."
        ),
        "symbols": records,
    }


def render_output_png(converted: Image.Image, bbox: tuple[int, int, int, int], global_scale: float) -> Image.Image:
    cropped = converted.crop(bbox)
    bw = bbox[2] - bbox[0]
    bh = bbox[3] - bbox[1]
    dst_w = max(1, int(round(bw * global_scale)))
    dst_h = max(1, int(round(bh * global_scale)))
    resized = cropped.resize((dst_w, dst_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    x = (CANVAS_SIZE - dst_w) // 2
    y = (CANVAS_SIZE - dst_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def generate_assets(manifest: dict[str, object]) -> list[Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    global_scale = float(manifest["globalScale"])
    generated: list[Path] = []

    for record in manifest["symbols"]:
        if record.get("anomalies") and record.get("inkBbox") is None:
            continue
        source_path = ROOT / str(record["sourcePath"])
        frame = load_first_frame(source_path)
        converted = rgba_to_black_alpha(frame)
        bbox = ink_bbox(converted)
        if bbox is None:
            continue
        output = render_output_png(converted, bbox, global_scale)
        out_path = OUTPUT_DIR / str(record["outputFile"])
        output.save(out_path, format="PNG", optimize=True)
        generated.append(out_path)

    return generated


def build_contact_sheet(manifest: dict[str, object]) -> Path:
    cols = 6
    rows = 6
    cell = 180
    header = 28
    sheet_w = cols * cell
    sheet_h = rows * cell + header
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)

    try:
        label_font = ImageFont.truetype("arial.ttf", 16)
        title_font = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        label_font = ImageFont.load_default()
        title_font = label_font

    draw.text(
        (12, 6),
        "KnitMate official symbols PNG contact sheet (6x6)",
        fill=(0, 0, 0, 255),
        font=title_font,
    )

    for index, record in enumerate(manifest["symbols"]):
        row = index // cols
        col = index % cols
        x0 = col * cell
        y0 = row * cell + header

        draw.rectangle((x0, y0, x0 + cell - 1, y0 + cell - 1), outline=(220, 220, 220, 255), width=1)

        png_path = OUTPUT_DIR / str(record["outputFile"])
        if png_path.is_file():
            symbol = Image.open(png_path).convert("RGBA")
            preview_size = cell - 36
            symbol.thumbnail((preview_size, preview_size), Image.Resampling.LANCZOS)
            px = x0 + (cell - symbol.width) // 2
            py = y0 + 24 + (preview_size - symbol.height) // 2
            sheet.paste(symbol, (px, py), symbol)

        label = f"No.{record['no']}"
        draw.text((x0 + 8, y0 + 4), label, fill=(0, 0, 0, 255), font=label_font)

    CONTACT_SHEET_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_SHEET_PATH, format="PNG")
    return CONTACT_SHEET_PATH


def main() -> None:
    records = [audit_symbol(entry) for entry in SYMBOLS]
    manifest = build_manifest(records)
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    generated = generate_assets(manifest)
    contact_sheet = build_contact_sheet(manifest)

    anomalies = [
        f"No.{r['no']} ({r['id']}): {', '.join(r['anomalies'])}"
        for r in records
        if r.get("anomalies")
    ]

    print(f"manifest: {MANIFEST_PATH}")
    print(f"generated: {len(generated)} / {len(SYMBOLS)}")
    print(f"globalScale: {manifest['globalScale']:.6f}")
    print(f"referenceMaxInkExtentPx: {manifest['referenceMaxInkExtentPx']}")
    print(f"contactSheet: {contact_sheet}")
    if anomalies:
        print("anomalies:")
        for item in anomalies:
            print(f"  - {item}")


if __name__ == "__main__":
    main()
