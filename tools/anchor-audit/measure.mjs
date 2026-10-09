/**
 * B3 — anchorColor audit (run: node tools/anchor-audit/measure.mjs)
 *
 * Measures the dominant color of each `<slug>_paysage.png` in
 * `apps/mobile/public/themes/` using the SAME algorithm as the dev-only
 * HTML tool (tools/anchor-audit/index.html): downsampled to a 96×54
 * grayscale-free grid, dominant = mean of the most-saturated quartile
 * (S ≥ 8%, 8% ≤ L ≤ 95%), compared to `anchorColor` from
 * `packages/ui/src/themes/image-themes.ts`.
 *
 * ΔE ad hoc = ΔHue + 0.5·ΔSat + 0.5·ΔLight (all in ° / %).
 * Verdict: < 12 = "fidèle", < 30 = "à vérifier visuellement", ≥ 30 = "à corriger".
 *
 * The HTML tool uses a PNG decoder in the browser; this Node script uses
 * the same logic with a small pure-JS PNG decoder (via the built-in
 * `zlib` module + manual chunk parsing — no npm deps).
 */

import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, "../..");

const THEMES = [
  ["new_york", "New York", "#2563EB"],
  ["tokyo", "Tokyo", "#E23B45"],
  ["paris", "Paris", "#3D6FD8"],
  ["londres", "Londres", "#12A878"],
  ["dubai", "Dubaï", "#19A7A8"],
  ["sydney", "Sydney", "#00A9C7"],
  ["printemps", "Printemps", "#68C27B"],
  ["ete", "Été", "#19B8D8"],
  ["automne", "Automne", "#C95B43"],
  ["hiver", "Hiver", "#74A9E8"],
  ["noel", "Noël", "#C92F50"],
  ["paques", "Pâques", "#D987B5"],
  ["nouvel_an", "Nouvel An", "#704CFF"],
  ["fete", "Fête", "#F23DAA"],
  ["paix", "Paix", "#78B29A"],
  ["impressionnisme", "Impressionnisme", "#62B59F"],
  ["jazz", "Jazz", "#7657D9"],
  ["street_art", "Street Art", "#E83D7C"],
  ["ballet", "Ballet", "#B69ADF"],
  ["sculpture", "Sculpture", "#4E8BCE"],
  ["volcans", "Volcans", "#D9473F"],
  ["glacier", "Glacier", "#2CB9D4"],
  ["dunes", "Dunes", "#C9A76B"],
  ["jungle", "Jungle", "#22B36F"],
  ["ponts", "Ponts", "#D8444B"],
  ["afrique", "Afrique", "#C96F4A"],
];

// ---- PNG decode (pure JS: zlib inflate + unfilter) ----
import { inflateSync } from "node:zlib";

function decodePng(buf) {
  // Check signature
  if (buf.length < 24 || buf[0] !== 0x89 || buf[1] !== 0x50)
    throw new Error("not a PNG");
  // Walk chunks: width/height in IHDR, pixel data in IDAT
  let off = 8;
  let width = 0, height = 0, bitDepth = 0, colorType = 0;
  const idat = [];
  while (off < buf.length) {
    const len = buf.readUInt32BE(off); off += 4;
    const type = buf.toString("ascii", off, off + 4); off += 4;
    const data = buf.subarray(off, off + len); off += len;
    off += 4; // CRC
    if (type === "IHDR") {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
    } else if (type === "IDAT") {
      idat.push(data);
    } else if (type === "IEND") break;
  }
  if (colorType !== 6 && colorType !== 2)
    throw new Error("unsupported colorType " + colorType);
  const ch = colorType === 6 ? 4 : 3; // RGBA / RGB
  const stride = width * ch + 1;
  const raw = inflateSync(Buffer.concat(idat));
  const pixels = Buffer.alloc(width * height * ch);
  let pos = 0;
  for (let y = 0; y < height; y++) {
    const filter = raw[pos++];
    const lineStart = y * width * ch;
    const prevStart = y > 0 ? lineStart - width * ch : 0;
    for (let x = 0; x < width * ch; x++) {
      const cur = raw[pos++];
      const left = x >= ch ? pixels[lineStart + x - ch] : 0;
      const up = y > 0 ? pixels[prevStart + x] : 0;
      const upLeft = y > 0 && x >= ch ? pixels[prevStart + x - ch] : 0;
      let v;
      switch (filter) {
        case 0: v = cur; break;
        case 1: v = (cur + left) & 0xff; break;
        case 2: v = (cur + up) & 0xff; break;
        case 3: v = (cur + ((left + up) >> 1)) & 0xff; break;
        case 4: {
          const p = left + up - upLeft;
          const pa = Math.abs(p - left), pb = Math.abs(p - up), pc = Math.abs(p - upLeft);
          v = (pa <= pb && pa <= pc) ? left : (pb <= pc ? up : upLeft);
          v = (cur + v) & 0xff;
          break;
        }
        default: v = cur;
      }
      pixels[lineStart + x] = v;
    }
  }
  return { width, height, ch, pixels };
}

// ---- Color math (same as the HTML tool) ----
function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function rgbToHex(r, g, b) {
  return "#" + [r, g, b]
    .map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}
function rgbToHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s = 0;
  const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      default: h = (r - g) / d + 4;
    }
    h *= 60;
  }
  return [h, s * 100, l * 100];
}
function hueDist(a, b) {
  const d = Math.abs(a - b) % 360;
  return d > 180 ? 360 - d : d;
}
function deltaEAdHoc(rgbA, rgbB) {
  const ha = rgbToHsl(...rgbA), hb = rgbToHsl(...rgbB);
  return hueDist(ha[0], hb[0]) + Math.abs(ha[1] - hb[1]) * 0.5 + Math.abs(ha[2] - hb[2]) * 0.5;
}

function dominantColor({ width, height, ch, pixels }) {
  // Downsample to 96×54 (matches the HTML tool)
  const DW = 96, DH = 54;
  const px = [];
  for (let dy = 0; dy < DH; dy++) {
    for (let dx = 0; dx < DW; dx++) {
      const sx = Math.floor((dx * width) / DW);
      const sy = Math.floor((dy * height) / DH);
      const idx = (sy * width + sx) * ch;
      const r = pixels[idx], g = pixels[idx + 1], b = pixels[idx + 2];
      const [H, S, L] = rgbToHsl(r, g, b);
      if (S < 8 || L < 8 || L > 95) continue;
      px.push({ r, g, b, s: S });
    }
  }
  if (px.length === 0) return null;
  px.sort((a, b) => a.s - b.s);
  const top = px.slice(Math.floor(px.length * 0.75));
  const n = top.length;
  const r = top.reduce((s, p) => s + p.r, 0) / n;
  const g = top.reduce((s, p) => s + p.g, 0) / n;
  const b = top.reduce((s, p) => s + p.b, 0) / n;
  return [Math.round(r), Math.round(g), Math.round(b)];
}

// ---- Run ----
console.log("Aurora B3 — anchorColor audit\n");
const results = [];
let ok = 0, warn = 0, bad = 0, fail = 0;

for (const [slug, label, anchor] of THEMES) {
  const file = resolve(REPO, "apps/mobile/public/themes", `${slug}_paysage.png`);
  try {
    const buf = readFileSync(file);
    const img = decodePng(buf);
    const dom = dominantColor(img);
    if (!dom) throw new Error("no chromatic pixel detected");
    const domHex = rgbToHex(...dom);
    const [ar, ag, ab] = hexToRgb(anchor);
    const de = deltaEAdHoc([ar, ag, ab], dom);
    let cls, txt;
    if (de < 12) { cls = "OK  "; txt = "fidèle"; ok++; }
    else if (de < 30) { cls = "WARN"; txt = "à vérifier visuellement"; warn++; }
    else { cls = "BAD "; txt = "à corriger — ancre diffère de la couleur dominante"; bad++; }
    results.push({ slug, label, anchor, domHex, de, cls, txt });
    console.log(
      `${cls}  ${slug.padEnd(16)} ${anchor}  vs  ${domHex}  (ΔE=${de.toFixed(1)})  ${txt}`
    );
  } catch (e) {
    fail++;
    console.log(`FAIL  ${slug.padEnd(16)} ${e.message}`);
  }
}

console.log(`\nRésumé : ${ok} fidèle · ${warn} à vérifier · ${bad} à corriger · ${fail} erreur(s)`);

if (bad > 0) {
  console.log("\nCorrections à appliquer dans packages/ui/src/themes/image-themes.ts :");
  for (const r of results.filter(x => x.cls === "BAD ")) {
    console.log(`  ${r.slug}: anchorColor ${r.anchor} → ${r.domHex}  (ΔE=${r.de.toFixed(1)})`);
  }
}
