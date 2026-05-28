const fs = require('fs');
const path = require('path');

const targetFile = path.join(
  __dirname,
  '..',
  'lib',
  'screens',
  'challan',
  'challan_edit_details_screen.dart',
);

const base = {
  customerLabel: 'Customer',
  exShowroomLabel: 'Ex-Showroom',
  corporateLabel: 'Corporate',
  subtotalLabel: 'Subtotal',
  rtoAmountLabel: 'RTO Amount',
  insuranceAmtLabel: 'Insurance Amt',
  netAmountLabel: 'Net Amount',
  mobileLabel: 'Mobile',
  challanDetails: 'Challan Details',
  challanNoLabel: 'Challan No',
  loadingChallanDetails: 'Loading challan details...',
  failedToLoadDetails: 'Failed to load details',
  showSelectionCheckboxes: 'Show Selection Checkboxes',
  enableCheckboxesHelp: 'Enable checkboxes to select fields for rejection remarks',
  rejectRemarkTitle: 'Reject remark',
  reject: 'Reject',
  approve: 'Approve',
  pleaseSelectFieldOrReason: 'Please check at least one field or enter a rejection reason',
  basicInformation: 'Basic Information',
  pricingDetails: 'Pricing Details',
  discountsAndOffers: 'Discounts & Offers',
  discountTitle: 'Discount',
  rtoDetails: 'RTO Details',
  taxDetails: 'Tax Details',
  insuranceDetails: 'Insurance Details',
  financialDetails: 'Financial Details',
  customerInformation: 'Customer Information',
  rejectChallan: 'Reject Challan',
  checkedFieldInfo: 'Checked fields are added below. You can edit before rejecting:',
  rejectRemarkHint: 'Reject remark (auto-filled from checked fields)...',
};

const codes = [
  'en', 'ar', 'as', 'bn', 'de', 'es', 'fr', 'gu', 'hi', 'id', 'it', 'ja', 'kn',
  'ml', 'mr', 'nl', 'or', 'pa', 'pl', 'pt', 'ru', 'ta', 'te', 'th', 'tr', 'ur', 'vi', 'zh',
];

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

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

async function translate(text, lang) {
  if (lang === 'en') return text;
  const { protectedText, placeholders } = shieldPlaceholders(text);
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${lang}&dt=t&q=${encodeURIComponent(protectedText)}`;
  const res = await fetch(url);
  if (!res.ok) return text;
  const data = await res.json();
  const translated = data?.[0]?.map((item) => item?.[0] ?? '').join('') ?? text;
  return unshieldPlaceholders(translated, placeholders);
}

async function buildMap() {
  const out = {};
  for (const code of codes) {
    out[code] = {};
    for (const key of Object.keys(base)) {
      // Keep app/business terms stable where translation can be awkward.
      if (key === 'challanDetails' || key === 'challanNoLabel' || key === 'rejectChallan') {
        const translated = await translate(base[key], code);
        out[code][key] = translated;
      } else {
        out[code][key] = await translate(base[key], code);
      }
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
  console.log('Updated challan UI text map.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
