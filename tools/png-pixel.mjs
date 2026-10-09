// Minimal PNG decoder (no deps): read pixel color at (x, y) in a region.
// Returns { r, g, b, a } at center of the clip or -1 if unsupported.
const fs = require('fs');

function decodePngPixel(filePath, px, py) {
  const buf = fs.readFileSync(filePath);
  // PNG signature check
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error('not a PNG');
  let off = 8;
  const idat = [];
  while (off < buf.length) {
    const len = buf.readUInt32BE(off);
    const type = buf.toString('ascii', off + 4, off + 8);
    const data = buf.subarray(off + 8, off + 8 + len);
    if (type === 'IHDR') {
      const w = data.readUInt32BE(0);
      const h = data.readUInt32BE(4);
      const bitDepth = data[8];
      const colorType = data[9];
      // We only handle 8-bit RGBA (colorType=6) or RGB (colorType=2)
      const channels = colorType === 6 ? 4 : colorType === 2 ? 3 : colorType === 0 ? 1 : 0;
      if (bitDepth !== 8 || channels === 0) throw new Error('unsupported PNG: bitDepth=' + bitDepth + ' colorType=' + colorType);
      idat.push({ w, h, channels, len });
    } else if (type === 'IDAT') {
      idat.push(data);
    }
    off += 12 + len;
  }
  // Find IHDR
  const ihdr = idat[0];
  const { w, h, channels } = ihdr;
  // Collect all IDAT data and inflate
  const zlib = require('zlib');
  const rawChunks = [];
  for (let i = 1; i < idat.length; i++) {
    if (idat[i] instanceof ArrayBuffer || Buffer.isBuffer(idat[i])) rawChunks.push(Buffer.from(idat[i]));
  }
  const raw = zlib.inflateSync(Buffer.concat(rawChunks));
  // Unfilter (PNG row filters)
  const stride = w * channels;
  const imgData = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const filter = raw[y * (stride + 1)];
    const row = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    const out = imgData.subarray(y * stride, (y + 1) * stride);
    if (filter === 0) {
      row.copy(out);
    } else if (filter === 1) {
      // Sub: a(x) = b(x)
      for (let x = 0; x < w; x++) {
        for (let c = 0; c < channels; c++) {
          const left = x > 0 ? out[(x * channels + c - channels)] : 0;
          out[x * channels + c] = (row[x * channels + c] + left) & 0xff;
        }
      }
    } else if (filter === 2) {
      // Up
      const prevRow = y > 0 ? imgData.subarray((y - 1) * stride, y * stride) : null;
      for (let x = 0; x < w; x++) {
        for (let c = 0; c < channels; c++) {
          const up = prevRow ? prevRow[x * channels + c] : 0;
          out[x * channels + c] = (row[x * channels + c] + up) & 0xff;
        }
      }
    } else {
      throw new Error('unsupported PNG filter: ' + filter);
    }
  }
  // Sample center
  const cx = Math.min(px, w - 1);
  const cy = Math.min(py, h - 1);
  const idx = cy * stride + cx * channels;
  return {
    r: imgData[idx],
    g: channels > 1 ? imgData[idx + 1] : imgData[idx],
    b: channels > 2 ? imgData[idx + 2] : imgData[idx],
    a: channels > 3 ? imgData[idx + 3] : 255,
  };
}

module.exports = { decodePngPixel };
