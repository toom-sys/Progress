#!/usr/bin/env python3
"""
Extract per-muscle-group mask images and a lines-only overlay
from the body map reference illustration.
"""

import numpy as np
from PIL import Image
from scipy import ndimage
import json
import os

SOURCE = "/Users/tom/.cursor/projects/Users-tom-Documents-Projects-TrackMyProgress-Progress/assets/IMG_3503-53804219-5619-484c-ac60-a0b1b2dc887a.png"
ASSETS = "/Users/tom/Documents/Projects/TrackMyProgress/Progress/Progress/Assets.xcassets"

FILL_LO = 75
FILL_HI = 215
OUTLINE_THRESHOLD = 75
MIN_REGION_PIXELS = 80

GROUPS = ["chest", "back", "shoulders", "arms", "core", "quads", "posteriorChain"]


def classify(cx, cy):
    """Assign a muscle group to a connected region based on its centroid."""
    if cx < 350:
        if cy < 200 and cx < 200:
            return "arms"
        if cy < 200 and cx >= 200:
            return "arms"
        if 140 < cy < 270 and cx < 105:
            return "shoulders"
        if 140 < cy < 270 and 250 < cx < 340:
            return "shoulders"
        if cx > 280 and cy > 200:
            return "arms"
        if 170 < cy < 310 and 80 < cx < 270:
            return "chest"
        if 280 < cy < 455 and 85 < cx < 265:
            return "core"
        if cy >= 400:
            return "quads"
        return "core"
    else:
        if 120 < cy < 260 and cx < 455:
            return "shoulders"
        if 120 < cy < 260 and cx > 610:
            return "shoulders"
        if cx < 445 and cy > 200:
            return "arms"
        if cx > 625 and cy > 200:
            return "arms"
        if cy < 410 and 440 < cx < 625:
            return "back"
        if cy >= 360:
            return "posteriorChain"
        return "back"


def save_imageset(img_array, name, assets_dir):
    """Save an RGBA numpy array as an Xcode imageset."""
    dir_path = os.path.join(assets_dir, f"{name}.imageset")
    os.makedirs(dir_path, exist_ok=True)

    png_name = f"{name}.png"
    Image.fromarray(img_array, "RGBA").save(os.path.join(dir_path, png_name))

    contents = {
        "images": [
            {"filename": png_name, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "preserves-vector-representation": False,
            "template-rendering-intent": "original",
        },
    }
    with open(os.path.join(dir_path, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)


def main():
    img = Image.open(SOURCE).convert("RGBA")
    px = np.array(img)
    gray = np.mean(px[:, :, :3], axis=2)
    H, W = gray.shape
    print(f"Image: {W}x{H}")

    is_fill = (gray >= FILL_LO) & (gray <= FILL_HI)

    labeled, num_features = ndimage.label(is_fill)
    print(f"Connected components found: {num_features}")

    regions = []
    for label_id in range(1, num_features + 1):
        ys, xs = np.where(labeled == label_id)
        size = len(ys)
        if size < MIN_REGION_PIXELS:
            continue

        cx = xs.mean()
        cy = ys.mean()
        group = classify(cx, cy)

        regions.append(
            {
                "label_id": label_id,
                "cx": cx,
                "cy": cy,
                "size": size,
                "bbox": (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())),
                "group": group,
            }
        )

    print(f"\nClassified {len(regions)} regions (>={MIN_REGION_PIXELS}px):")
    for r in sorted(regions, key=lambda r: r["group"]):
        print(
            f"  {r['group']:>16s}  centroid=({r['cx']:5.0f},{r['cy']:5.0f})  "
            f"size={r['size']:6d}  bbox={r['bbox']}"
        )

    group_counts = {}
    for r in regions:
        group_counts[r["group"]] = group_counts.get(r["group"], 0) + 1
    print("\nRegions per group:")
    for g in GROUPS:
        print(f"  {g}: {group_counts.get(g, 0)} regions")

    for group in GROUPS:
        mask = np.zeros((H, W, 4), dtype=np.uint8)
        group_labels = [r["label_id"] for r in regions if r["group"] == group]
        for lid in group_labels:
            mask[labeled == lid] = [255, 255, 255, 255]
        save_imageset(mask, f"bodymap_mask_{group}", ASSETS)
        total_px = sum(r["size"] for r in regions if r["group"] == group)
        print(f"  Saved bodymap_mask_{group} ({total_px} pixels, {len(group_labels)} regions)")

    lines = np.zeros((H, W, 4), dtype=np.uint8)
    outline_mask = gray < OUTLINE_THRESHOLD
    lines[outline_mask, 0] = px[outline_mask, 0]
    lines[outline_mask, 1] = px[outline_mask, 1]
    lines[outline_mask, 2] = px[outline_mask, 2]
    lines[outline_mask, 3] = 255
    save_imageset(lines, "bodymap_lines", ASSETS)
    print(f"  Saved bodymap_lines ({outline_mask.sum()} outline pixels)")

    print("\nDone!")


if __name__ == "__main__":
    main()
