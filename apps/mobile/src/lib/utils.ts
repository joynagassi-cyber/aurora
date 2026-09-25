import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * `cn` — shadcn/ui class combiner (ui-libraries.md S2 step 2: clsx +
 * tailwind-merge prerequisites). Merges conflicting Tailwind utilities
 * (last wins) so Aurora design tokens (AD-17) can override component
 * defaults without CSS specificity fights.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
