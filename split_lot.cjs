// Split a lot file into two valid standalone INSERTs.
// Part A: INSERT header + first N tuples, each closed with );
// Part B: INSERT header + remaining tuples, closed with ON CONFLICT
const fs = require('fs');
const file = process.argv[2];
const s = fs.readFileSync(file, 'utf8');
const lines = s.split('\n');
const header = lines.slice(0, 3).join('\n'); // INSERT INTO ... VALUES
// Find tuple-start lines (lines beginning with "('marketplace:")
const starts = [];
for (let i = 0; i < lines.length; i++) if (lines[i].startsWith("('marketplace:")) starts.push(i);
// Split at midpoint
const halfIdx = Math.floor(starts.length / 2);
const cutLine = starts[halfIdx]; // first line of part B
const partA = lines.slice(0, cutLine).join('\n');
const partB = lines.slice(cutLine).join('\n');
// Part A: close each tuple with ; then ON CONFLICT
const aClosed = partA.replace(/\$body\$\),\s*$/, '$body$);\nON CONFLICT (skill_key) DO NOTHING;\n');
// Part B: prepend header, remove its ON CONFLICT tail, re-add
const bBody = partB.replace(/\nON CONFLICT \(skill_key\) DO NOTHING;\n?$/, '\n');
const bClosed = header + '\n' + bBody + 'ON CONFLICT (skill_key) DO NOTHING;\n';
fs.writeFileSync(process.argv[3], aClosed);
fs.writeFileSync(process.argv[4], bClosed);
console.log(JSON.stringify({
  aBytes: aClosed.length, bBytes: bClosed.length,
  aEnds: aClosed.slice(-60), bStarts: bClosed.slice(0, 80)
}));
