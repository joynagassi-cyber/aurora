import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:5173',
    supportFile: false,
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx,js,jsx}',
    video: false,
    // Le bundle Vite du monorepo est lourd au premier chargement
    // (la machine tourne lentement) : on étire les timeouts par défaut.
    defaultCommandTimeout: 20000,
    pageLoadTimeout: 120000,
  },
});
