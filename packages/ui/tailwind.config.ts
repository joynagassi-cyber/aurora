/**
 * @aurora/ui — Aurora design system tokens → Tailwind (shadcn/ui).
 *
 * All shadcn/ui components consume these CSS variables; the values are
 * resolved by <AuroraThemeProvider> from the theme JSON (packages/ui/
 * src/themes/, AD-17) — changing the theme changes the JSON, never
 * this file (docs/ui-libraries.md §4).
 *
 * Aurora radii: sm 4 / md 8 / lg 12 / xl 16 / full 9999 (05 §2.4).
 */

import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
  	extend: {
  		colors: {
  			border: 'hsl(var(--aurora-border-h) / 1)',
  			input: 'hsl(var(--aurora-border-strong-h) / 1)',
  			ring: 'hsl(var(--aurora-focus-ring-h) / 1)',
  			background: 'hsl(var(--aurora-bg-h) / 1)',
  			foreground: 'hsl(var(--aurora-text-primary-h) / 1)',
  			primary: {
  				DEFAULT: 'hsl(var(--aurora-accent-primary-h))',
  				foreground: 'hsl(var(--aurora-accent-on-primary-h))'
  			},
  			secondary: {
  				DEFAULT: 'hsl(var(--aurora-surface-alt-h))',
  				foreground: 'hsl(var(--aurora-text-primary-h))'
  			},
  			destructive: {
  				DEFAULT: 'hsl(var(--aurora-danger-h))',
  				foreground: 'hsl(var(--aurora-surface-h))'
  			},
  			muted: {
  				DEFAULT: 'hsl(var(--aurora-bg-subtle-h))',
  				foreground: 'hsl(var(--aurora-text-muted-h))'
  			},
  			accent: {
  				DEFAULT: 'hsl(var(--aurora-accent-selected-surface-h))',
  				foreground: 'hsl(var(--aurora-text-primary-h))'
  			},
  			popover: {
  				DEFAULT: 'hsl(var(--aurora-surface-h))',
  				foreground: 'hsl(var(--aurora-text-primary-h))'
  			},
  			card: {
  				DEFAULT: 'hsl(var(--aurora-surface-h))',
  				foreground: 'hsl(var(--aurora-text-primary-h))'
  			},
  			success: 'hsl(var(--aurora-success-h))',
  			warning: 'hsl(var(--aurora-warning-h))',
  			info: 'hsl(var(--aurora-info-h))',
  			sidebar: {
  				DEFAULT: 'hsl(var(--sidebar-background))',
  				foreground: 'hsl(var(--sidebar-foreground))',
  				primary: 'hsl(var(--sidebar-primary))',
  				'primary-foreground': 'hsl(var(--sidebar-primary-foreground))',
  				accent: 'hsl(var(--sidebar-accent))',
  				'accent-foreground': 'hsl(var(--sidebar-accent-foreground))',
  				border: 'hsl(var(--sidebar-border))',
  				ring: 'hsl(var(--sidebar-ring))'
  			}
  		},
  		borderRadius: {
  			lg: 'var(--radius)',
  			md: 'calc(var(--radius) - 2px)',
  			sm: '4px'
  		},
  		keyframes: {
  			'accordion-down': {
  				from: {
  					height: '0'
  				},
  				to: {
  					height: 'var(--radix-accordion-content-height)'
  				}
  			},
  			'accordion-up': {
  				from: {
  					height: 'var(--radix-accordion-content-height)'
  				},
  				to: {
  					height: '0'
  				}
  			},
  			shimmer: {
  				'0%': {
  					opacity: '0.6'
  				},
  				'50%': {
  					opacity: '1'
  				},
  				'100%': {
  					opacity: '0.6'
  				}
  			},
  			'accordion-down': {
  				from: {
  					height: '0'
  				},
  				to: {
  					height: 'var(--radix-accordion-content-height)'
  				}
  			},
  			'accordion-up': {
  				from: {
  					height: 'var(--radix-accordion-content-height)'
  				},
  				to: {
  					height: '0'
  				}
  			}
  		},
  		animation: {
  			'accordion-down': 'accordion-down 0.2s ease-out',
  			'accordion-up': 'accordion-up 0.2s ease-out',
  			'pulse-skeleton': 'shimmer 1.2s ease-in-out infinite',
  			'aurora-fast': 'aurora 150ms ease-out',
  			'aurora-normal': 'aurora 250ms ease-out',
  			'accordion-down': 'accordion-down 0.2s ease-out',
  			'accordion-up': 'accordion-up 0.2s ease-out'
  		},
  		fontFamily: {
  			sans: [
  				'Inter',
  				'system-ui',
  				'Roboto',
  				'sans-serif'
  			],
  			mono: [
  				'JetBrains Mono',
  				'ui-monospace',
  				'monospace'
  			]
  		}
  	}
  },
  plugins: [],
};

export default config;
