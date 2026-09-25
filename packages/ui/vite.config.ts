import path from "node:path";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";

// @ts-expect-error — Vite's plugin-init signature differs from tailwind's;
// cast only, runtime is standard (shadcn/Vite template, docs/ui-libraries.md §2).
function tailwind(): import("vite").Plugin {
  return tailwindcss() as unknown as import("vite").Plugin;
}

export default defineConfig({
  plugins: [react(), tailwind(), autoprefixer()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
