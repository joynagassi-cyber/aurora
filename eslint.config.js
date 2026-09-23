/**
 * Aurora ESLint 9 flat config — boundary rules.
 *
 * Layer 1 — TypeScript parser + recommended rules.
 * Layer 2 — boundary invariants via:
 *   - `no-restricted-imports`  (package-level bans)
 *   - `import/no-restricted-paths` (directory-level bans)
 *
 * Rules enforced:
 *   packages/domain       imports NOTHING (AD-1, AD-15 hexagon center)
 *   packages/ui           never imports @aurora/data or @aurora/platform
 *   packages/{domain,ui,agent} + apps/mobile:
 *                          vendor SDKs & AD-10 engines are FORBIDDEN
 *                          (AD-1 vendor isolation, AD-10 frozen engines)
 */

import js from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import tseslint from 'typescript-eslint';

/**
 * Vendor SDK patterns that MUST stay inside:
 *   packages/{data,platform,integrations,scientific-engine} and apps/server
 * They are FORBIDDEN in all other packages.
 */
const VENDOR_PATTERNS = [
  '@supabase/*',
  'supabase',
  'supabase-*',
  '@cloudflare/*',
  'cloudflare-*',
  '@google/*',
  'ai',
  'openai',
  'anthropic',
  '@anthropic-ai/*',
  '@composio/*',
  'composio*',
  'onesignal*',
  'powersync*',
  '@powersync/*',
  '@ionic/*',
  'react-native*',
  'electron',
];

/**
 * The AD-10 frozen viz engines. Restricted to packages/ui.
 */
const AD10_ENGINES = [
  '@xyflow/react',
  '@dagrejs/dagre',
  '@antv/infographic',
  '@antv/g2',
  'katex',
  'motion',
];

export default tseslint.config(
  // 1. Base: recommended JS rules.
  js.configs.recommended,

  // 2. TypeScript: parser + recommended (non type-checked, no project setup needed).
  ...tseslint.configs.recommended,

  // Skeleton: allow unused vars during wave 0 (tsconfig noUnusedLocals covers it
  // at typecheck time). We don't want a flood of style noise on stub packages.
  {
    rules: {
      '@typescript-eslint/no-unused-vars': 'off',
      'no-unused-vars': 'off',
      // Allow unused function args (port stubs have signatures, no bodies yet).
      '@typescript-eslint/no-unused-args': 'off',
    },
  },

  // 3. Import plugin (provides `import/no-restricted-paths`).
  {
    plugins: {
      import: importPlugin,
    },
    languageOptions: {
      sourceType: 'module',
    },
  },

  // ============================================================
  // packages/domain — imports NOTHING (AD-1 / AD-15 SSoT)
  // ============================================================
  {
    files: ['packages/domain/**/*.ts'],
    rules: {
      // no-restricted-imports: ban any BARE (package) import — the group
      // '*' matches only non-relative specifiers, so './x' and '../x' are
      // untouched. Combined with the relative-import whitelist below, this
      // fully seals the hexagon center (zero dependencies).
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['*'],
              message:
                'AD-1/AD-15: packages/domain must not import any external package (hexagon center, zero dependencies).',
            },
          ],
        },
      ],
      // import/no-restricted-paths: ban relative imports that escape the
      // domain package (allow only './…' and '../…' within domain/src).
      'import/no-restricted-paths': [
        'error',
        {
          whitelist: ['\\.\\/.+$', '\\.\\./\\.\\/.+$'],
          zones: [
            {
              from: 'packages/domain/src',
              target: ['../../../../..', '../../../../../..'],
              message:
                'AD-1: packages/domain must not import anything outside its own src directory.',
            },
          ],
        },
      ],
      'import/no-unresolved': 'off', // external libs are banned, not resolved
    },
  },

  // ============================================================
  // packages/ui — AD-10 engines ALLOWED; no data/platform
  // ============================================================
  {
    files: ['packages/ui/**/*.ts'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@aurora/data', '@aurora/platform'],
              message:
                'AD-6: packages/ui must not import @aurora/data or @aurora/platform. It is the pure design system.',
            },
          ],
        },
      ],
      'import/no-restricted-paths': [
        'error',
        {
          // ui can never reach into data / platform dirs
          zones: [
            {
              from: 'packages/ui',
              target: ['packages/data', 'packages/platform'],
              message:
                'AD-6: packages/ui must not import from packages/data or packages/platform.',
            },
          ],
        },
      ],
    },
  },

  // ============================================================
  // packages/{domain,ui,agent} + apps/mobile —
  //   ban vendor SDKs + AD-10 engines (AD-1, AD-10)
  // ============================================================
  {
    files: [
      'packages/{domain,ui,agent}/**/*.ts',
      'apps/mobile/**/*.ts',
    ],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: VENDOR_PATTERNS,
              message:
                'AD-1: vendor SDKs must stay in packages/{data,platform,integrations,scientific-engine} or apps/server.',
            },
            // AD-10 engines are banned in domain / agent / apps/mobile.
            // (In ui they are allowed — the ui block above doesn't ban them.)
            {
              group: AD10_ENGINES,
              message:
                'AD-10: the 5 frozen viz engines are restricted to packages/ui only.',
            },
          ],
        },
      ],
      'import/no-restricted-paths': [
        'error',
        {
          // mobile feature-slices don't import sibling mobile feature dirs
          zones: [
            {
              from: 'apps/mobile/src/features/([^/]+)',
              target: [
                // any sibling feature dir (not self)
                '../../..**',
              ],
              message:
                'Mobile feature-slice isolation: a feature must not import from a sibling feature. Share code via packages/.',
            },
          ],
        },
      ],
    },
  },
);
