import { readFileSync } from 'fs';
import { createPrivateKey, createSign } from 'crypto';

const ISSUER_ID = '6c3b3640-c6bf-40a9-b6e5-57cda2c7776e';
const KEY_ID = '7ZLQ98Z2PK';
const PRIVATE_KEY_PATH = process.env.HOME + '/.appstoreconnect/private_keys/AuthKey_7ZLQ98Z2PK.p8';
const BUNDLE_ID = 'bontecou.Sync-md';
const APP_NAME = 'Sync.md';
const SKU = 'syncmd-ios-001';
const BASE = 'https://api.appstoreconnect.apple.com';

const pem = readFileSync(PRIVATE_KEY_PATH, 'utf8');

function generateToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })).toString('base64url');
  const input = `${header}.${payload}`;
  const key = createPrivateKey(pem);
  const sign = createSign('SHA256');
  sign.update(input);
  sign.end();
  const sig = sign.sign({ key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${input}.${sig}`;
}

async function apiFetch(path, options = {}) {
  const token = generateToken();
  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  const text = await res.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!res.ok) {
    console.error(`❌ ${res.status} ${res.statusText}`);
    console.error(typeof body === 'string' ? body : JSON.stringify(body, null, 2));
    return null;
  }
  return body;
}

// Step 1: List all apps to check if Sync.md exists
console.log('🔍 Checking existing apps...');
const appsResponse = await apiFetch('/v1/apps?fields[apps]=name,bundleId,sku,primaryLocale');
if (!appsResponse) process.exit(1);

console.log(`   Found ${appsResponse.data.length} app(s):`);
for (const app of appsResponse.data) {
  console.log(`   - "${app.attributes.name}" (${app.attributes.bundleId})`);
}

const existing = appsResponse.data.find(a => a.attributes.bundleId === BUNDLE_ID);
if (existing) {
  console.log(`\n✅ App "${existing.attributes.name}" already exists (${existing.id})`);
  console.log('🎉 Ready for upload!');
  process.exit(0);
}

// Step 2: Find the bundle ID resource
console.log('\n🔍 Looking up bundle ID...');
const bundleIdResponse = await apiFetch(`/v1/bundleIds?filter[identifier]=${BUNDLE_ID}`);
if (!bundleIdResponse) process.exit(1);

let bundleIdResourceId;
if (bundleIdResponse.data.length > 0) {
  bundleIdResourceId = bundleIdResponse.data[0].id;
  console.log(`✅ Bundle ID found: ${bundleIdResourceId}`);
} else {
  console.log('📝 Registering bundle ID...');
  const registerRes = await apiFetch('/v1/bundleIds', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'bundleIds',
        attributes: { identifier: BUNDLE_ID, name: APP_NAME, platform: 'IOS' },
      },
    }),
  });
  if (!registerRes) process.exit(1);
  bundleIdResourceId = registerRes.data.id;
  console.log(`✅ Bundle ID registered: ${bundleIdResourceId}`);
}

// Step 3: Create the app
console.log(`\n🚀 Creating app "${APP_NAME}" in App Store Connect...`);
const createRes = await apiFetch('/v1/apps', {
  method: 'POST',
  body: JSON.stringify({
    data: {
      type: 'apps',
      attributes: { name: APP_NAME, primaryLocale: 'en-US', sku: SKU, bundleId: BUNDLE_ID },
      relationships: {
        bundleId: { data: { type: 'bundleIds', id: bundleIdResourceId } },
      },
    },
  }),
});

if (!createRes) process.exit(1);
console.log(`✅ App created: "${createRes.data.attributes.name}" (${createRes.data.id})`);
console.log('🎉 Ready for upload!');
