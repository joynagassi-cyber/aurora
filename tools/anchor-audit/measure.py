"""B3 — anchorColor audit (Python, run: python tools/anchor-audit/measure.py).

The goal: verify that each `anchorColor` in `image-themes.ts` (SSoT =
`.stitch/prompts_v4.md`) is a color that is VISUALLY PRESENT in the
corresponding image. We do NOT measure "which color dominates the whole
image" (that picks up sky, sand, rock, etc.) — we measure whether the
ANCHOR is a distinct cluster in the image's color space.

Algorithm:
  1. Downsample to 96×54, RGB.
  2. Run a lightweight k-means (k=8, Lloyd iteration, 20 rounds) over the
     full downsampled pixel set to find the 8 dominant color clusters.
  3. For each theme, compute the minimum ΔE ad hoc between its
     `anchorColor` and all 8 cluster centroids.
  4. Verdict:
       min ΔE <  12  → "fidèle" (the anchor is clearly one of the image's
                        dominant colors)
       min ΔE <  30  → "à vérifier visuellement" (the anchor is close to a
                        cluster but not exact — may still be fine)
       min ΔE ≥  30  → "à corriger" (the anchor does not match ANY
                        dominant cluster — it was likely derived from the
                        SSoT table, not from the image; update it)
"""
import sys, io
from pathlib import Path
from PIL import Image
import colorsys, random

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

REPO = Path(__file__).resolve().parent.parent.parent

THEMES = [
    ("new_york", "New York", "#2563EB"),
    ("tokyo", "Tokyo", "#E23B45"),
    ("paris", "Paris", "#3D6FD8"),
    ("londres", "Londres", "#12A878"),
    ("dubai", "Dubaï", "#19A7A8"),
    ("sydney", "Sydney", "#00A9C7"),
    ("printemps", "Printemps", "#68C27B"),
    ("ete", "Été", "#19B8D8"),
    ("automne", "Automne", "#C95B43"),
    ("hiver", "Hiver", "#74A9E8"),
    ("noel", "Noël", "#C92F50"),
    ("paques", "Pâques", "#D987B5"),
    ("nouvel_an", "Nouvel An", "#704CFF"),
    ("fete", "Fête", "#F23DAA"),
    ("paix", "Paix", "#78B29A"),
    ("impressionnisme", "Impressionnisme", "#62B59F"),
    ("jazz", "Jazz", "#7657D9"),
    ("street_art", "Street Art", "#E83D7C"),
    ("ballet", "Ballet", "#B69ADF"),
    ("sculpture", "Sculpture", "#4E8BCE"),
    ("volcans", "Volcans", "#D9473F"),
    ("glacier", "Glacier", "#2CB9D4"),
    ("dunes", "Dunes", "#C9A76B"),
    ("jungle", "Jungle", "#22B36F"),
    ("ponts", "Ponts", "#D8444B"),
    ("afrique", "Afrique", "#C96F4A"),
]

DW, DH = 96, 54
K = 8       # k-means clusters
ROUNDS = 20 # Lloyd iterations


def hex_to_rgb(h):
    n = int(h.lstrip("#"), 16)
    return ((n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF)


def rgb_to_hex(rgb):
    r, g, b = (max(0, min(255, int(round(v)))) for v in rgb)
    return "#%02X%02X%02X" % (r, g, b)


def rgb_to_hsl(rgb):
    r, g, b = (v / 255 for v in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return (h * 360, s * 100, l * 100)


def hue_dist(a, b):
    d = abs(a - b) % 360
    return d if d <= 180 else 360 - d


def delta_e_ad_hoc(rgb_a, rgb_b):
    """Ad hoc ΔE: ΔHue + 0.5·ΔSat + 0.5·ΔLight (° / % units)."""
    ha = rgb_to_hsl(rgb_a)
    hb = rgb_to_hsl(rgb_b)
    return hue_dist(ha[0], hb[0]) + 0.5 * abs(ha[1] - hb[1]) + 0.5 * abs(ha[2] - hb[2])


def kmeans(pixels, k=K, rounds=ROUNDS, seed=42):
    """Lightweight Lloyd k-means over a list of RGB tuples.

    Returns a list of k centroid RGB tuples.
    pixels: list of (r, g, b) ints.
    """
    rng = random.Random(seed)
    # Init: pick k random pixels (deterministic with seed)
    centroids = [pixels[rng.randint(0, len(pixels) - 1)] for _ in range(k)]

    for _ in range(rounds):
        # Assign
        clusters = [[] for _ in range(k)]
        for px in pixels:
            best = 0
            best_d = 10**9
            for i, c in enumerate(centroids):
                d = (px[0] - c[0]) ** 2 + (px[1] - c[1]) ** 2 + (px[2] - c[2]) ** 2
                if d < best_d:
                    best_d = d
                    best = i
            clusters[best].append(px)
        # Update
        for i in range(k):
            if clusters[i]:
                n = len(clusters[i])
                centroids[i] = (
                    sum(p[0] for p in clusters[i]) // n,
                    sum(p[1] for p in clusters[i]) // n,
                    sum(p[2] for p in clusters[i]) // n,
                )
            # If empty cluster, reseed from a random pixel
            else:
                centroids[i] = pixels[rng.randint(0, len(pixels) - 1)]
    return centroids


def analyze_image(f):
    with Image.open(f) as im:
        small = im.convert("RGB").resize((DW, DH), Image.LANCZOS)
        pixels = list(small.getdata())
    centroids = kmeans(pixels)
    return centroids


def main():
    print("Aurora B3 — anchorColor audit (k-means, 8 clusters)\n")
    results = []
    ok = warn = bad = fail = 0

    for slug, label, anchor in THEMES:
        f = REPO / "apps" / "mobile" / "public" / "themes" / f"{slug}_paysage.png"
        try:
            centroids = analyze_image(f)
            anchor_rgb = hex_to_rgb(anchor)
            min_de = min(delta_e_ad_hoc(anchor_rgb, c) for c in centroids)
            best_centroid = min(centroids, key=lambda c: delta_e_ad_hoc(anchor_rgb, c))

            if min_de < 12:
                cls, txt = "OK  ", "fidèle"
                ok += 1
            elif min_de < 30:
                cls, txt = "WARN", "à vérifier visuellement"
                warn += 1
            else:
                cls, txt = "BAD ", "à corriger — l'ancre n'appeart à aucun cluster"
                bad += 1

            results.append((slug, label, anchor, rgb_to_hex(best_centroid), min_de, cls, txt))
            print(
                f"{cls}  {slug:<16}  anchor {anchor}  "
                f"vs  {rgb_to_hex(best_centroid)} (plus proche cluster)  "
                f"ΔE_min={min_de:5.1f}  {txt}"
            )
        except Exception as e:
            fail += 1
            print(f"FAIL  {slug:<16}  {e}")

    print(f"\nRésumé : {ok} fidèle · {warn} à vérifier · {bad} à corriger · {fail} erreur(s)")
    if bad:
        print("\nSuggestions de correction pour packages/ui/src/themes/image-themes.ts :")
        for slug, label, anchor, closest, de, cls, _ in results:
            if cls == "BAD ":
                print(f"  {slug:<16}  {anchor}  →  {closest}  (ΔE={de:.1f})")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
