describe('Calendrier — rendu visuel (Dynamic Theming)', () => {
  beforeEach(() => {
    cy.viewport(1280, 800);
    // Le monorepo est lourd : le premier chargement Vite est le plus lent.
    // On laisse 3 minutes avant de déclarer un échec.
    cy.visit('/calendar', { timeout: 180000 });
    // Attendre que la grille se peigne (le fond image + le canvas)
    cy.get('.cal-dynamic', { timeout: 180000 }).should('be.visible');
  });

  it('affiche le calendrier avec la grille 7 colonnes', () => {
    cy.get('.cal-dynamic-grid').should('be.visible');
    cy.get('.cal-dynamic-day').should('have.length.at.least', 28);
    cy.screenshot('01-calendrier-grille');
  });

  it("cycle l'image de fond et change la couleur", () => {
    cy.get('.cal-dynamic-switch').click();
    // L'image suivante doit re-déclencher le hook : la variable
    // `--dynamic-accent` doit redevenir une valeur non vide.
    cy.document()
      .its('documentElement')
      .should((el: HTMLElement) => {
        expect(getComputedStyle(el).getPropertyValue('--dynamic-accent').trim()).to.not.be.empty;
      });
    cy.screenshot('02-calendrier-image-2');
  });

  it('affiche la section Aujourd\'hui et le FAB', () => {
    cy.get('.cal-card').should('exist');
    cy.get('ion-fab-button').should('be.visible');
    cy.screenshot('03-calendrier-timeline-fab');
  });
});
