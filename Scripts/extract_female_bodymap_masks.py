#!/usr/bin/env python3
"""
Extract per-muscle-group mask images, a lines-only overlay and a base image
from the generated FEMALE body map illustration.

Unlike the male extraction (grayscale thresholds), fill regions here are
separated from outlines by stroke thickness (distance transform), then each
region is assigned to a muscle group by nearest known centroid.
"""

import numpy as np
from PIL import Image
from scipy import ndimage
import json
import os

SOURCE = "/Users/tom/.cursor/projects/Users-tom-Documents-Projects-TrackMyProgress-Progress/assets/bodymap_female_source.png"
ASSETS = "/Users/tom/Documents/Projects/TrackMyProgress/Progress/Progress/Assets.xcassets"

# Crop (left, top, right, bottom) around the content bbox with padding
CROP = (88, 72, 904, 887)

NONWHITE_THRESHOLD = 230
MIN_FILL_PIXELS = 60
THIN_STROKE_MAX = 4.5  # max distance-transform value for outline strokes

GROUPS = ["chest", "back", "shoulders", "arms", "core", "quads", "posteriorChain"]

# Known fill-region centroids (source-image coordinates) -> muscle group.
# "heart" and "hand" are special: heart goes into the lines overlay,
# hands are grouped with arms.
KNOWN_REGIONS = [
    # Front figure (left) ------------------------------------------------
    (413, 113, "arms"),            # raised fist
    (444, 184, "arms"),            # raised forearm
    (402, 231, "arms"),            # raised bicep
    (350, 234, "shoulders"),       # right front delt
    (211, 269, "shoulders"),       # left front delt
    (262, 293, "chest"),           # left chest
    (327, 285, "chest"),           # right chest
    (196, 328, "arms"),            # left bicep
    (261, 369, "core"),            # left oblique
    (292, 337, "core"), (295, 366, "core"), (294, 394, "core"),   # abs left column
    (323, 334, "core"), (323, 365, "core"), (320, 393, "core"),   # abs right column
    (301, 435, "core"),            # lower abs
    (166, 404, "arms"),            # left forearm
    (138, 479, "arms"),            # left fist
    (221, 494, "quads"),           # left outer thigh strip
    (249, 515, "quads"),           # left quad
    (318, 519, "quads"),           # right inner quad
    (352, 528, "quads"),           # right quad
    (198, 699, "quads"),           # left front calf
    (356, 707, "quads"),           # right front calf
    (499, 341, "heart"),           # cardio heart
    # Back figure (right) ------------------------------------------------
    (763, 207, "back"), (787, 205, "back"),      # upper traps
    (699, 253, "shoulders"), (848, 250, "shoulders"),  # rear delts
    (755, 263, "back"), (797, 263, "back"),      # traps
    (721, 276, "back"), (831, 276, "back"),      # teres / rhomboids
    (738, 333, "back"), (814, 333, "back"),      # lats
    (775, 384, "back"),                          # lower back
    (678, 318, "arms"), (861, 318, "arms"),      # triceps
    (642, 402, "arms"), (857, 393, "arms"),      # rear forearms
    (614, 480, "arms"),                          # rear hand
    (738, 455, "posteriorChain"), (808, 455, "posteriorChain"),  # glutes
    (742, 558, "posteriorChain"), (812, 557, "posteriorChain"),  # hamstrings
    (711, 532, "posteriorChain"), (843, 535, "posteriorChain"),  # outer thigh strips
    (744, 700, "posteriorChain"), (802, 707, "posteriorChain"),  # rear calves
]

MAX_MATCH_DISTANCE = 40.0


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

    nonwhite = gray < NONWHITE_THRESHOLD
    labeled, num = ndimage.label(nonwhite)
    dist = ndimage.distance_transform_edt(nonwhite)
    print(f"Non-white components: {num}")

    group_masks = {g: np.zeros((H, W), dtype=bool) for g in GROUPS}
    lines_mask = np.zeros((H, W), dtype=bool)
    matched = 0

    for lid in range(1, num + 1):
        comp = labeled == lid
        size = comp.sum()
        ys, xs = np.where(comp)

        # Thin strokes and specks belong to the outline overlay
        if size < MIN_FILL_PIXELS or dist[comp].max() < THIN_STROKE_MAX:
            lines_mask |= comp
            continue

        cx, cy = xs.mean(), ys.mean()
        dists = [np.hypot(cx - kx, cy - ky) for kx, ky, _ in KNOWN_REGIONS]
        best = int(np.argmin(dists))
        if dists[best] > MAX_MATCH_DISTANCE:
            print(f"  WARNING: unmatched fill region at ({cx:.0f},{cy:.0f}) size={size} -> lines")
            lines_mask |= comp
            continue

        group = KNOWN_REGIONS[best][2]
        matched += 1
        if group == "heart":
            lines_mask |= comp  # heart renders as part of the base outline art
        else:
            group_masks[group] |= comp

    print(f"Matched {matched} fill regions")

    left, top, right, bottom = CROP

    def crop(arr):
        return arr[top:bottom, left:right]

    # Per-group white masks
    for group in GROUPS:
        m = crop(group_masks[group])
        out = np.zeros((*m.shape, 4), dtype=np.uint8)
        out[m] = [255, 255, 255, 255]
        save_imageset(out, f"bodymap_female_mask_{group}", ASSETS)
        print(f"  Saved bodymap_female_mask_{group} ({int(m.sum())} px)")

    # Lines overlay keeps original pixel colors
    lm = crop(lines_mask)
    cpx = crop(px)
    lines = np.zeros((*lm.shape, 4), dtype=np.uint8)
    lines[lm, :3] = cpx[lm, :3]
    lines[lm, 3] = 255
    save_imageset(lines, "bodymap_female_lines", ASSETS)
    print(f"  Saved bodymap_female_lines ({int(lm.sum())} px)")

    # Base image (full illustration, opaque)
    base = cpx.copy()
    base[:, :, 3] = 255
    save_imageset(base, "bodymap_female_base", ASSETS)
    h, w = base.shape[:2]
    print(f"  Saved bodymap_female_base ({w}x{h}, aspect {w / h:.4f})")

    # Heart position (normalized) for BodyMapView
    heart = next((k for k in KNOWN_REGIONS if k[2] == "heart"))
    hx = (heart[0] - left) / w
    hy = (heart[1] - top) / h
    print(f"  Heart normalized position: ({hx:.4f}, {hy:.4f})")

    print("\nDone!")


if __name__ == "__main__":
    main()
