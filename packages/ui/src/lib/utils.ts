/**
 * @aurora/ui — class merging (shadcn/ui convention).
 * clsx + tailwind-merge, per docs/ui-libraries.md §2 (shadcn prerequisite).
 */
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
