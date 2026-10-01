import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Aurora mobile — Tailwind v3 for the shadcn/ui layer (@aurora/ui).
 *
 * The `@aurora/ui` shadcn components (Button, Card, Badge, Select, …) consume
 * these color tokens through Tailwind. Every token maps to a **runtime CSS
 * variable** (`var(--background)`, `var(--primary)`, …) that
 * `<AuroraThemeProvider>` writes on `<html>` (packages/ui `toShadcnVars`) —
 * so the shadcn layer responds to the active theme / preset / neutral style
 * (AD-17) and NEVER carries a hardcoded palette (docs/ui-libraries.md §4).
 *
 * The vars are FULL values (hex), so opacity modifiers (`bg-primary/90`)
 * degrade to the solid token (cosmetic); the SSoT static triplet form
 * (`aurora.css`, `hsl(var(--aurora-*-h))`) is used only inside packages/ui.
 *
 * `content` scans both the mobile screens and the @aurora/ui component source
 * (consumed via Vite `resolve.alias` → packages/ui/src).
 */
const here = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    path.resolve(here, 'index.html'),
    path.resolve(here, 'src/**/*.{ts,tsx}'),
    path.resolve(here, '../../packages/ui/src/**/*.{ts,tsx}'),
  ],
  theme: {
    extend: {
      colors: {
        border: 'var(--border)',
        input: 'var(--input)',
        ring: 'var(--ring)',
        background: 'var(--background)',
        foreground: 'var(--foreground)',
        primary: {
          DEFAULT: 'var(--primary)',
          foreground: 'var(--primary-foreground)',
        },
        secondary: {
          DEFAULT: 'var(--secondary)',
          foreground: 'var(--secondary-foreground)',
        },
        destructive: {
          DEFAULT: 'var(--destructive)',
          foreground: 'var(--destructive-foreground)',
        },
        muted: {
          DEFAULT: 'var(--muted)',
          foreground: 'var(--muted-foreground)',
        },
        accent: {
          DEFAULT: 'var(--accent)',
          foreground: 'var(--accent-foreground)',
        },
        popover: {
          DEFAULT: 'var(--popover)',
          foreground: 'var(--popover-foreground)',
        },
        card: {
          DEFAULT: 'var(--card)',
          foreground: 'var(--card-foreground)',
        },
        success: 'var(--success)',
        warning: 'var(--warning)',
        info: 'var(--info)',
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: '4px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'Roboto', 'sans-serif'],
        mono: ['JetBrains Mono', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
};
