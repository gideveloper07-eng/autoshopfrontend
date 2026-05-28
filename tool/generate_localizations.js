const fs = require('fs');
const path = require('path');

const l10nDir = path.join(__dirname, '..', 'lib', 'l10n');
const baseFile = path.join(l10nDir, 'app_localizations_en.dart');

const targets = {
  ar: 'Arabic',
  bn: 'Bengali',
  de: 'German',
  es: 'Spanish',
  fr: 'French',
  gu: 'Gujarati',
  hi: 'Hindi',
  id: 'Indonesian',
  it: 'Italian',
  ja: 'Japanese',
  kn: 'Kannada',
  ml: 'Malayalam',
  mr: 'Marathi',
  nl: 'Dutch',
  or: 'Odia',
  pa: 'Punjabi',
  pl: 'Polish',
  pt: 'Portuguese',
  ru: 'Russian',
  ta: 'Tamil',
  te: 'Telugu',
  th: 'Thai',
  tr: 'Turkish',
  ur: 'Urdu',
  vi: 'Vietnamese',
  zh: 'Chinese',
};

const preserveValues = new Set(['appTitle']);

const encodeToken = (i) => `__PH_${i}__`;

function shieldPlaceholders(input) {
  const placeholders = [];
  const protectedText = input.replace(/\$\w+/g, (m) => {
    placeholders.push(m);
    return encodeToken(placeholders.length - 1);
  });
  return { protectedText, placeholders };
}

function unshieldPlaceholders(input, placeholders) {
  let out = input;
  placeholders.forEach((value, i) => {
    out = out.replaceAll(encodeToken(i), value);
  });
  return out;
}

function escapeDartSingleQuoted(input) {
  return input.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

async function translateText(text, langCode) {
  const { protectedText, placeholders } = shieldPlaceholders(text);
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${langCode}&dt=t&q=${encodeURIComponent(protectedText)}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Translate API failed: ${res.status} for ${langCode}`);
  }

  const data = await res.json();
  const translated = data?.[0]?.map((item) => item?.[0] ?? '').join('') ?? text;
  const restored = unshieldPlaceholders(translated, placeholders);
  return escapeDartSingleQuoted(restored);
}

function toClassSuffix(langCode) {
  return langCode[0].toUpperCase() + langCode.slice(1);
}

async function generate() {
  const template = fs.readFileSync(baseFile, 'utf8');

  for (const langCode of Object.keys(targets)) {
    const classSuffix = toClassSuffix(langCode);
    const className = `AppLocalizations${classSuffix}`;
    let content = template;

    content = content
      .replace("/// The translations for English (`en`).", `/// The translations for ${targets[langCode]} (\`${langCode}\`).`)
      .replace('class AppLocalizationsEn extends AppLocalizations {', `class ${className} extends AppLocalizations {`)
      .replace("AppLocalizationsEn([String locale = 'en']) : super(locale);", `${className}([String locale = '${langCode}']) : super(locale);`);

    const getterRegex = /String get (\w+) => '((?:\\'|[^'])*)';/g;
    const updates = [];
    let m;

    while ((m = getterRegex.exec(content)) !== null) {
      const key = m[1];
      const raw = m[2].replace(/\\'/g, "'").replace(/\\\\/g, '\\');
      if (preserveValues.has(key)) {
        updates.push({ start: m.index, end: m.index + m[0].length, key, value: escapeDartSingleQuoted(raw) });
      } else {
        updates.push({ start: m.index, end: m.index + m[0].length, key, value: await translateText(raw, langCode) });
      }
    }

    for (let i = updates.length - 1; i >= 0; i -= 1) {
      const u = updates[i];
      const replacement = `String get ${u.key} => '${u.value}';`;
      content = content.slice(0, u.start) + replacement + content.slice(u.end);
    }

    const recordsRegex = /String records\(int count, String plural\) \{\s+return '((?:\\'|[^'])*)';\s+\}/m;
    const recordsMatch = content.match(recordsRegex);
    if (recordsMatch) {
      const raw = recordsMatch[1].replace(/\\'/g, "'").replace(/\\\\/g, '\\');
      const translated = await translateText(raw, langCode);
      content = content.replace(recordsRegex, `String records(int count, String plural) {\n    return '${translated}';\n  }`);
    }

    const outFile = path.join(l10nDir, `app_localizations_${langCode}.dart`);
    fs.writeFileSync(outFile, content, 'utf8');
    console.log(`Generated ${path.basename(outFile)}`);
  }
}

generate().catch((err) => {
  console.error(err);
  process.exit(1);
});
