// Debug: screenshot of / with image theme active, using Playwright.
// Run: node tools/debug-image-theme-bg.mjs
import { chromium } from 'playwright';

const URL = process.env.AURORA_URL ?? 'http://localhost:5173';
const SLUG = process.env.AURORA_IMAGE_SLUG ?? 'jazz'; // a real image-theme slug

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 420, height: 840 } });

// Capture every console message + page errors, to spot a JS failure that
// would leave the theme layer unmounted (→ no data-aurora-image-theme set).
const consoleMsgs = [];
page.on('console', (msg) => consoleMsgs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', (err) => consoleMsgs.push(`[pageerror] ${err.message}`));

await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
// The data provider may keep polling (PowerSync relay) — don't block on
// networkidle. Give the theme layer a moment to hydrate instead.
await page.waitForTimeout(3000);

// The store key is whatever useUiStateStore persists to — inspect at
// runtime rather than assuming the exact name.
const applied = await page.evaluate(() => {
  // Trigger an image theme by simulating what <ImageThemeLayer> does:
  // the store is the source of truth, so we set it directly on the
  // persisted localStorage key the zustand store uses, then reload.
  const before = Object.keys(localStorage).filter((k) => /ui|state|aurora/i.test(k));
  return before;
});
console.log('localStorage keys matching ui/state/aurora:', applied);

// The store key is 'aurora.ui-state' (ui-state.ts, persist name: 'aurora.ui-state').
// Pre-seed it inside the browser context so the reload picks it up.
const found = { key: 'aurora.ui-state', val: null };

if (found) {
  // Set the theme to the chosen image slug and reload, so the layer
  // re-runs its effect on mount and paints the background.
  await page.evaluate(({ key, slug }) => {
    const raw = localStorage.getItem(key);
    const parsed = raw ? JSON.parse(raw) : { state: {}, version: 0 };
    const patch = (o) => {
      if (o.state && typeof o.state === 'object') {
        o.state.auroraImageTheme = slug;
      } else {
        o.auroraImageTheme = slug;
      }
      return o;
    };
    localStorage.setItem(key, JSON.stringify(patch(parsed)));
  }, { key: found.key, slug: SLUG });

  await page.reload({ waitUntil: 'domcontentloaded', timeout: 60000 });

  // Give the theme provider + image layer a moment to run their effects.
  await page.waitForTimeout(1500);

  // The user's actual complaint is the CALENDAR view (and all shadcn Card
  // surfaces), not just Home. Navigate to /calendar so the screenshot shows
  // the central card that was staying opaque.
  await page.evaluate(() => {
    const root = window.history;
    root.pushState({}, '', '/calendar');
    window.dispatchEvent(new PopStateEvent('popstate'));
  });
  await page.waitForTimeout(1500);

  // Read the actual computed state of interest:
  const diagnostics = await page.evaluate(() => {
    const doc = document.documentElement;
    const card = document.querySelector('.shadcn-card, [class*=card]');
    const before = getComputedStyle(doc, '::before');
    const afterApp = getComputedStyle(document.querySelector('ion-app'), '::after');
    const body = getComputedStyle(document.body);
    const vars = (sel) => {
      const s = getComputedStyle(sel);
      return {
        '--card': s.getPropertyValue('--card'),
        '--aurora-surface-bg': s.getPropertyValue('--aurora-surface-bg'),
        '--aurora-bg': s.getPropertyValue('--aurora-bg'),
        '--aurora-surface': s.getPropertyValue('--aurora-surface'),
        '--background': s.getPropertyValue('--background'),
      };
    };
    return {
      dataAttr: doc.dataset.auroraImageTheme ?? null,
      dataStyle: doc.dataset.auroraStyle ?? null,
      bgImageVar: doc.style.getPropertyValue('--aurora-bg-image') || 'unset (not set inline)',
      htmlVars: vars(doc),
      cardComputed: card ? {
        cls: card.className.slice(0, 120),
        bg: getComputedStyle(card).backgroundColor,
        bgImg: getComputedStyle(card).backgroundImage.slice(0, 80),
      } : null,
      beforeContent: before.content,
      beforePosition: before.position,
      beforeBackground: before.background.slice(0, 200),
      beforeFilter: before.filter,
      beforeScale: before.scale ?? '(n/a)',
      afterAppContent: afterApp.content,
      afterAppFilter: afterApp.filter,
      afterAppBackdropFilter: afterApp.backdropFilter ?? afterApp.webkitBackdropFilter ?? '(n/a)',
      afterAppPosition: afterApp.position,
      afterAppZIndex: afterApp.zIndex,
      bodyBackground: body.background.slice(0, 200),
      bodyBackgroundImage: body.backgroundImage.slice(0, 200),
    };
  });
  console.log('\n=== DIAGNOSTICS ===');
  console.log(JSON.stringify(diagnostics, null, 2));
  console.log('\n=== CONSOLE ===');
  for (const line of consoleMsgs.slice(-40)) console.log(line);

  await page.screenshot({ path: 'debug-image-theme-bg.png', fullPage: false });
  console.log('\nScreenshot saved: debug-image-theme-bg.png');
} else {
  console.log('No image-theme store key found in localStorage — taking a plain screenshot to at least see the default state.');
  await page.screenshot({ path: 'debug-image-theme-bg.png' });
  console.log('Screenshot saved: debug-image-theme-bg.png');
}

await browser.close();
