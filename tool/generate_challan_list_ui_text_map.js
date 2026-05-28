const fs = require('fs');
const path = require('path');

const targetFile = path.join(
  __dirname,
  '..',
  'lib',
  'screens',
  'challan',
  'challan_screen.dart',
);

const base = {
  searchHint: 'Search customer, challan no...',
  invalidChallanId: 'Invalid challan ID. Available fields:',
};

const codes = [
  'en', 'ar', 'as', 'bn', 'de', 'es', 'fr', 'gu', 'hi', 'id', 'it', 'ja', 'kn',
  'ml', 'mr', 'nl', 'or', 'pa', 'pl', 'pt', 'ru', 'ta', 'te', 'th', 'tr', 'ur', 'vi', 'zh',
];

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

async function translate(text, lang) {
  if (lang === 'en') return text;
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${lang}&dt=t&q=${encodeURIComponent(text)}`;
  const res = await fetch(url);
  if (!res.ok) return text;
  const data = await res.json();
  return data?.[0]?.map((item) => item?.[0] ?? '').join('') ?? text;
}

async function buildMap() {
  const out = {};
  for (const code of codes) {
    out[code] = {};
    for (const key of Object.keys(base)) {
      out[code][key] = await translate(base[key], code);
    }
    console.log(`Translated ${code}`);
  }
  return out;
}

function toDartMap(obj) {
  const lines = [];
  lines.push('  static const Map<String, Map<String, String>> _uiText = {');
  for (const [code, inner] of Object.entries(obj)) {
    lines.push(`    '${code}': {`);
    for (const [k, v] of Object.entries(inner)) {
      lines.push(`      '${k}': '${esc(v)}',`);
    }
    lines.push('    },');
  }
  lines.push('  };');
  return lines.join('\n');
}

async function main() {
  const content = fs.readFileSync(targetFile, 'utf8');
  const generated = toDartMap(await buildMap());
  const updated = content.replace(
    /  static const Map<String, Map<String, String>> _uiText = \{[\s\S]*?\n  \};/,
    generated,
  );
  fs.writeFileSync(targetFile, updated, 'utf8');
  console.log('Updated challan list UI text map.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
