# AURORA — Architecture & Product Decisions
Version 1.7 — Suite de productivité et orchestration agentique
## 1. Vision produit
Aurora est un espace de travail personnel intelligent réunissant productivité, apprentissage, projets, recherche, pratique, suivi de progression et assistant agentique.
Principe directeur : les fonctionnalités sont les capacités d’Aurora ; l’intention et le contexte de l’utilisateur déterminent lesquelles l’agent active et orchestre.
## 2. Suite complète de productivité
Cycle global : Capturer → Organiser → Planifier → Exécuter → Suivre → Réviser → Améliorer.
### 2.1 Capture et organisation
Inbox universelle
Ajout rapide : tâche, note, événement, projet, objectif, document, idée ou ressource
Notes libres et structurées
Tags et relations entre éléments
Recherche universelle et Command Palette
Historique des modifications
Import/export et sauvegarde
### 2.2 Gestion des tâches
Tâches et sous-tâches
Statuts : à faire, en cours, bloqué, terminé, annulé
Projet, matière, objectif, contexte et ressources associés
Priorité, importance, urgence, échéance et estimation
Temps réellement passé
Dépendances
Récurrence
Pièces jointes/liens
Énergie et contexte de travail
Historique des reports
### 2.3 Priorisation
Matrice d’Eisenhower
Priorité manuelle
Priorisation assistée selon échéance, impact, effort, dépendances, importance, urgence et temps disponible
Détection des tâches critiques ou bloquantes
Réévaluation quand le contexte change
Explication par l’agent de ses recommandations
### 2.4 Calendrier et planification
Calendrier jour/semaine/mois
Agenda
Time blocking
Cours, examens, réunions, devoirs, révisions, projets et routines
Planification selon le temps réellement disponible
Échéances et rappels
Détection des conflits et de la surcharge
Replanification assistée par l’agent
Planification quotidienne, hebdomadaire et mensuelle
### 2.5 Projets
Objectif, échéance, jalons, tâches, ressources, documents, notes et historique
Vues Liste, Kanban, Timeline, Gantt et Calendrier
Progression
Dépendances et blocages
Modèles de projets réutilisables
### 2.6 Objectifs et progression
Objectifs court, moyen et long terme
Hiérarchie Objectif → Projet → Tâche
Jalons
Indicateurs de progression
Historique
Analyse plan/réalité
Suggestions d’ajustement par l’agent
### 2.7 Habitudes et routines
Habitudes quotidiennes/hebdomadaires
Routines matin/soir et routines d’étude
Suivi de régularité
Analyse de l’adhérence
Détection des habitudes perturbatrices
Adaptation des routines
### 2.8 Focus et anti-distraction
Focus Mode
Sessions de concentration
Minuteur/Pomodoro
Blocage ou limitation des applications distrayantes lorsque la plateforme le permet
Réduction des notifications pendant une session
Historique du temps de concentration
Bilan de session
Le blocage natif doit être validé techniquement par plateforme avant de promettre un blocage absolu.
### 2.9 Revues et pilotage personnel
Revue quotidienne
Revue hebdomadaire
Revue mensuelle
Bilan des tâches accomplies, reportées, abandonnées et bloquées
Analyse des causes de retard
Révision des priorités
Plan d’action suivant
Journal des décisions importantes
### 2.10 Analytics personnels
Temps de travail et de concentration
Temps par projet/matière/objectif
Charge planifiée vs charge réelle
Taux de réalisation
Tâches fréquemment reportées
Tendances de procrastination
Régularité des habitudes
Progression d’apprentissage
Détection de surcharge
### 2.11 Bibliothèque de ressources
Cours, PDF, documents, images, vidéos, liens, exercices, rapports et notes
Rattachement à matière, compétence, projet, objectif ou session
Recherche dans les ressources
Récupération de contexte par l’agent
Stockage des artefacts produits par Aurora ou des services externes
## 3. Suite d’apprentissage
Fiches de révision IA
Résumés de cours
QCM
Flashcards
Répétition espacée FSRS
Rappel actif
Exercices progressifs
Correction et analyse des erreurs
Mind maps lorsque réellement utiles
Mode Coach
Mirror Cognitive Mode : l’étudiante explique ce qu’elle a compris et Aurora détecte lacunes, contradictions et erreurs
Suivi des compétences et sujets maîtrisés/non maîtrisés
## 4. Intentions principales
Planifier
Organiser
Exécuter
Apprendre
Rechercher
Pratiquer
Progresser
Découvrir
Réviser
Piloter
L’utilisateur ne doit pas être obligé de choisir manuellement un module. Aurora déduit l’intention puis active les capacités nécessaires.
## 5. Orchestration agentique
Comprendre l’intention
Récupérer le contexte personnel pertinent
Identifier contraintes, échéances, dépendances et charge
Choisir les capacités nécessaires
Construire un plan
Demander confirmation pour les actions importantes ou irréversibles
Exécuter les actions autorisées
Vérifier le résultat
Enregistrer progression et état
Proposer une adaptation ou une prochaine action
## 6. Exemples
Planification : l’utilisateur donne ses cours, échéances et temps disponible ; Aurora analyse la charge et construit un planning réaliste avec priorités et time blocking.
Blocage : l’utilisateur indique qu’un rapport n’avance pas ; Aurora analyse tâches, dépendances, reports et temps disponible, puis propose une prochaine action concrète.
Apprentissage : l’utilisateur signale une notion incomprise ; Aurora récupère le cours, explique, questionne en rappel actif puis génère QCM ou flashcards si utile.
Progression : un objectif professionnel est transformé en compétences, ressources, exercices, projets, habitudes et points de contrôle.
Recherche : Aurora recherche sur le web, collecte les sources, synthétise et transforme les résultats en ressources ou artefacts exploitables.
## 7. Architecture technique consolidée
Frontend : Ionic React + TypeScript
Android : Capacitor
Desktop : Electron
Monorepo : pnpm
Local-first : PowerSync + SQLite/local storage
Backend : Supabase PostgreSQL + Auth + Edge Functions
Fichiers : Cloudflare R2, bucket privé + URLs présignées
Notifications mobiles : OneSignal + notifications locales Capacitor
Notifications desktop : notifications natives Electron
IA : Agent Kernel + AI Router + AI Gateway + multi-provider ; Agnes AI fournisseur primaire ; Cloudflare Workers AI/Worker comme fallback et second pool d’inférence
Recherche : ResearchProvider avec You.com, Tavily et Exa
Intégrations : Composio derrière IntegrationProvider
Knowledge Base : PostgreSQL + FTS + pgvector ; documents dans R2
Scientific Engine générique : calcul scientifique + unités ; pas de calculateur codé par matière
Artifact Hub : représentation unifiée des PDF/DOCX/PPTX/XLSX/images/audio/vidéo/etc.
Automatisations : Supabase Cron → dispatcher Aurora → jobs persistés → Edge Functions
Observabilité : Sentry + PostHog
CI/CD : GitHub Actions
## 8. Contrats internes
AIProvider
ResearchProvider
IntegrationProvider
ObjectStorage
ArtifactProvider
ScientificEngine
NotificationProvider
FocusController
KnowledgeBase
JobRunner
Les fonctionnalités métier ne doivent pas dépendre directement d’un fournisseur externe.
## 9. Fiabilité des fournisseurs
Les couches de fournisseurs doivent gérer santé, quotas, erreurs, cooldown, latence et fallback. La rotation de plusieurs comptes ou clés ne doit pas servir à contourner les quotas ou conditions d’utilisation d’un fournisseur.
## 10. Modèle de domaine initial
Task
Event
Project
Goal
Milestone
Habit
Routine
Note
Resource
Course
Subject
Skill
LearningSession
Review
FocusSession
Artifact
Automation
Decision
UserContext
## 11. Accueil
L’accueil ne doit pas devenir un tableau de bord rempli de widgets. Il doit répondre à : « Qu’est-ce qui compte maintenant ? »
Agenda du jour
Prochaine action importante
Priorité principale
Progression critique
Révisions à effectuer
Accès immédiat au Focus
Suggestions pertinentes d’Aurora Coach
## 12. Principe final
Aurora doit rester simple en surface et puissante en profondeur. Une utilisatrice peut commencer avec une simple tâche ou un calendrier puis exploiter projets, Gantt, apprentissage, recherche, automatisations et agent.
Décision produit : ne pas empiler des fonctionnalités visibles. Construire un système cohérent où les données, les capacités et l’agent se renforcent mutuellement. Cette suite de productivité est désormais intégrée à la vision d’architecture et doit être considérée comme une contrainte de conception pour les étapes suivantes.
## 13. Aurora Coach — accompagnement personnel adaptatif
Aurora Coach ne se limite pas à répondre aux demandes. Avec l’autorisation de l’utilisatrice, l’agent peut initier régulièrement de courtes interactions de coaching pour suivre la discipline personnelle, comprendre les écarts entre le plan et la réalité et adapter la journée en cours.
Check-ins contextuels : début de journée, avant un bloc important, après une session et fin de journée.
Détection des changements : retard, fatigue signalée, tâche terminée plus tôt, imprévu, rendez-vous ajouté, temps perdu ou priorité devenue urgente.
Replanification dynamique : recalcul du planning restant sans détruire l’historique du planning initial.
Adaptation de l’apprentissage : changement de durée, difficulté, ordre des matières, méthode ou contenu selon l’état réel de la journée.
Coaching de discipline : constance, respect des engagements, gestion des reports, démarrage des tâches, routines et retour à l’action.
Dialogue bref et orienté action : Aurora explique le constat, propose une action et suit le résultat au lieu de multiplier les notifications.
Mémoire longitudinale : tendances de plusieurs jours/semaines pour distinguer un incident ponctuel d’un schéma récurrent.
Paramètres de cadence, horaires de silence et niveau d’intervention contrôlés par l’utilisatrice.
Le coaching ne doit pas devenir intrusif : l’agent doit privilégier la pertinence contextuelle, respecter les périodes de silence et pouvoir être désactivé ou ajusté.
## 14. Arbre sémantique évolutif du savoir
Aurora intégrera un véritable arbre sémantique de connaissances. Il s’agit d’une hiérarchie lisible du savoir, et non d’un réseau de notes ou d’un graphe de type « second brain » difficile à interpréter.
Racines : principes fondamentaux, définitions structurantes et prérequis.
Branches : domaines, disciplines, matières, thèmes et sous-thèmes.
Nœuds : concepts, lois, méthodes, formules, théorèmes, procédures, exemples et applications.
Relations verticales privilégiées : « dépend de », « est un cas de », « approfondit », « applique », « conduit à ».
Ponts inter-domaines : les connexions entre domaines existent comme liens secondaires explicitement annotés, mais l’interface principale reste un arbre hiérarchique, jamais une toile de centaines de connexions.
Consolidation progressive : chaque nouveau document, cours ou recherche enrichit les nœuds existants, crée les branches manquantes et fusionne les doublons lorsque la preuve est suffisante.
Traçabilité : chaque notion importante peut pointer vers les documents, pages, passages, formules ou résultats de recherche qui la soutiennent.
Évolution temporelle : Aurora conserve l’évolution de l’arbre afin de visualiser comment le savoir s’est approfondi et où de nouvelles connexions inter-domaines sont apparues.
Vue par domaine : arbre de la matière ou du domaine professionnel de prédilection, tout en conservant sa position dans l’arbre global.
Vue de progression : branches fragiles, branches consolidées, notions isolées, prérequis manquants et zones encore peu couvertes.
Règle de lisibilité : Aurora ne doit pas transformer l’arbre en carte mentale gigantesque. L’interface privilégie l’exploration par niveaux, le repli/déploiement des branches, les chemins de prérequis et quelques ponts inter-domaines contextualisés.
## 15. Ingénierie mathématique, LaTeX et calcul
Le Scientific Engine devient une couche mathématique générale utilisable par l’agent, les exercices, les fiches, les documents et les projets techniques.
Rendu LaTeX pour formules, équations, symboles, matrices, dérivées, intégrales et notations techniques.
Édition et affichage de formules dans les notes, fiches, réponses de l’agent et artefacts.
Calcul numérique déterministe avec gestion des unités et conversions.
Calcul symbolique : simplification, factorisation, dérivation, intégration et résolution lorsque l’équation s’y prête.
Algèbre linéaire : vecteurs, matrices, systèmes et opérations associées.
Équations et systèmes : résolution, substitution et vérification des résultats.
Fonctions scientifiques et statistiques usuelles.
Vérification automatique : unités, dimensions, bornes élémentaires, cohérence des étapes et résultat final.
Traçabilité du calcul : expression initiale, étapes, hypothèses, unités et résultat.
Architecture par moteurs interchangeables derrière ScientificEngine afin de pouvoir utiliser plusieurs moteurs spécialisés sans coupler le domaine à une bibliothèque précise.
Les capacités de calcul spécialisées de génie civil ne sont pas codées comme une collection de calculateurs indépendants. L’agent mobilise le Scientific Engine générique avec les connaissances du corpus concerné.
## 16. Visualisation universelle des fichiers et artefacts
Tout fichier importé ou généré doit disposer d’un parcours de visualisation dans Aurora, avec prévisualisation adaptée au type de fichier et accès au fichier source.
PDF : lecture paginée, zoom, recherche et navigation.
DOCX : prévisualisation du document et extraction du contenu exploitable.
PPTX : aperçu des diapositives.
XLSX/CSV : aperçu tabulaire et, lorsque pertinent, visualisation graphique.
Images : visionneuse avec zoom.
Markdown/texte/code : rendu ou éditeur adapté.
Audio/vidéo : lecteur intégré lorsque le format et la plateforme le permettent.
LaTeX : rendu de la formule et du document lorsque le contenu est convertible.
Fichiers générés par Aurora : accès immédiat dans Artifact Hub, avec métadonnées sur la source, la tâche et le contexte de génération.
Formats non pris en charge : conservation du fichier, métadonnées et téléchargement/partage externe sans prétendre à une prévisualisation native.
## 17. Fiches de révision intelligentes et fidèles au corpus
La fiche de révision n’est pas une simple sortie de résumé. Aurora doit produire une fiche conçue pour mémoriser, retrouver et réutiliser les connaissances réellement apprises, tout en respectant strictement le corpus pédagogique fourni.
Extraction ciblée : définitions, lois, principes, formules, hypothèses, unités, méthodes, étapes, pièges, exemples et relations importantes.
Fidélité prioritaire au corpus enseignant : les définitions et formulations imposées peuvent être conservées textuellement ou quasi textuellement lorsque cela est nécessaire à la conformité académique.
Séparation explicite entre « formulation du corpus » et « explication d’Aurora » afin de ne jamais présenter une reformulation comme la définition officielle du cours.
Références aux sources : chaque bloc important peut indiquer le document, la page ou le passage d’origine.
Mémorisation des formules : formule, signification de chaque variable, unités, conditions d’utilisation, cas particuliers, transformations utiles et exemple d’application.
Fiches adaptées à la matière : une fiche de calcul ne suit pas exactement la même structure qu’une fiche de définitions, de procédés, de théorie ou de formules.
Génération orientée apprentissage : rappels actifs, questions, mini-QCM, flashcards et espaces à compléter peuvent être dérivés de la fiche sans altérer le contenu source.
Version courte et version complète selon la densité de contenu.
Détection des éléments à mémoriser à long terme et possibilité de les envoyer vers le système FSRS.
Contrôle de fidélité avant export : comparaison avec les passages sources et signalement des éléments reformulés, ajoutés ou incertains.
Formats d’export prioritaires : Markdown (.md), PDF, Word (.docx) et PNG. Aurora ne doit pas forcer une seule mise en page : le gabarit de sortie est adapté au format et au type de fiche.
Exemples de structures : fiche de définitions, fiche de formules, fiche méthode, fiche comparative, fiche procédure, fiche de synthèse théorique et fiche d’exercices. L’agent sélectionne la structure à partir du contenu et du but de révision.
Principe académique : lorsqu’un professeur exige les définitions de son propre corpus, la priorité est la fidélité au corpus. L’agent peut fournir une explication pédagogique séparée, mais ne doit pas remplacer silencieusement la formulation attendue.
## 18. Mise à jour des décisions de conception
Aurora Coach devient une capacité proactive et adaptative du noyau agentique, avec cadence et permissions contrôlables.
L’arbre sémantique devient une représentation centrale de l’évolution des connaissances, complémentaire à la base documentaire et distincte d’un second brain en réseau.
Le Scientific Engine doit supporter mathématiques, unités, calcul déterministe et extensions de moteurs, avec LaTeX comme format de représentation mathématique.
Artifact Hub doit fournir une expérience de visualisation cohérente pour les fichiers importés et générés.
Le générateur de fiches de révision devient une fonctionnalité spécialisée de haute fidélité au corpus, avec adaptation par type de matière et export multi-format.
Les connaissances issues des cours restent traçables ; les synthèses et explications de l’agent doivent être distinguées du contenu académique faisant autorité.
Version 0.9 : ces décisions complètent la vision produit définie précédemment. Elles doivent être considérées comme des contraintes fonctionnelles à respecter avant la phase d’implémentation détaillée.
## 13. Discovery Engine — découverte utile et orientée vers l’excellence
La Discovery d’Aurora ne doit pas être une veille passive qui accumule des liens, des articles ou des notifications. Elle doit fonctionner comme un système de découverte active : trouver ce qui est utile maintenant, expliquer pourquoi cela compte, relier la découverte au parcours de l’utilisatrice et provoquer progressivement un élargissement de ses capacités, de sa compréhension et de sa vision.
Principe : Aurora ne demande pas seulement « qu’est-ce qui est nouveau ? », mais « qu’est-ce que cette personne doit découvrir maintenant pour mieux comprendre son domaine, réduire ses lacunes, anticiper son évolution et augmenter son niveau professionnel ? »
### 13.1 Profil de découverte dynamique
Domaine de prédilection et sous-domaines.
Cours suivis et notions actuellement étudiées.
Compétences maîtrisées, fragiles et manquantes.
Objectifs académiques et professionnels.
Projets réalisés et projets en cours.
Niveau technique estimé et preuves utilisées pour l’estimer.
Technologies, méthodes, normes et outils déjà connus.
Centres d’intérêt émergents détectés dans les recherches et apprentissages.
Contraintes de temps et capacité réelle d’absorption.
### 13.2 Recherche multi-source
Pour une découverte importante, Aurora doit croiser plusieurs familles de sources plutôt que dépendre d’un seul type de contenu.
Sources académiques : universités, cours institutionnels, thèses, mémoires, publications et dépôts scientifiques.
Sources scientifiques : articles évalués, conférences, revues spécialisées, organismes de recherche et travaux expérimentaux.
Sources techniques : documentation officielle, spécifications, normes accessibles, manuels, guides techniques et dépôts de référence.
Sources professionnelles : bureaux d’études, cabinets, entreprises, instituts professionnels, rapports métiers, études de marché et retours d’expérience.
Sources technologiques : annonces de nouveaux outils, logiciels, méthodes, plateformes, automatisation, IA, cloud, robotique et autres transformations technologiques pertinentes.
Sources d’actualité sectorielle : changements récents, grands projets, innovations, incidents, tendances et événements qui modifient le métier.
Sources réglementaires et normatives lorsque le sujet l’exige.
Sources locales/régionales et internationales afin de comparer les réalités du Bénin, de l’Afrique, des pays développés et des pratiques internationales.
La diversité des sources est une exigence de conception : Aurora doit pouvoir distinguer ce qui relève d’une découverte scientifique, d’une pratique professionnelle, d’une innovation commerciale, d’une tendance médiatique ou d’une information encore incertaine.
### 13.3 Moteur de découverte guidé par les besoins
Relier chaque découverte aux objectifs, cours, compétences, projets et faiblesses actuels.
Éviter les sujets intéressants mais inutiles au regard des priorités actuelles.
Détecter les sujets adjacents susceptibles d’élargir la compréhension du domaine.
Découvrir volontairement des perspectives extérieures au domaine principal lorsque celles-ci peuvent créer un avantage professionnel.
Alterner approfondissement et ouverture : consolider les fondamentaux puis élargir vers les applications, technologies et domaines connexes.
Adapter la fréquence et la profondeur de découverte à la charge de travail réelle.
Mémoriser les découvertes déjà proposées afin de ne pas recycler inutilement les mêmes contenus.
### 13.4 Analyse des écarts
Une fonction centrale de Discovery est d’aider l’utilisatrice à comprendre où elle se situe par rapport aux exigences de son environnement réel. Aurora ne doit pas réduire cette analyse à une note unique ; elle doit produire une cartographie des écarts documentés.
Écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier.
Écart entre les connaissances académiques et les pratiques professionnelles locales.
Écart entre les pratiques locales/régionales et certaines pratiques internationales documentées.
Écart technologique : outils, logiciels, automatisation, IA, données et méthodes modernes.
Écart méthodologique : raisonnement, conception, vérification, documentation, communication et collaboration.
Écart de portefeuille : projets ou preuves concrètes nécessaires pour démontrer une compétence.
Écart de veille : sujets importants que l’utilisatrice ne connaît pas encore.
Écart de profondeur : notions connues superficiellement mais insuffisamment maîtrisées.
Chaque écart important doit être accompagné de preuves, de sources, de conséquences pratiques et, lorsque pertinent, d’un chemin de progression. Aurora doit clairement distinguer une exigence documentée, une pratique fréquente et une interprétation.
### 13.5 Vision de l’excellence internationale
Aurora peut utiliser un objectif de très haut niveau comme horizon de progression : devenir une ingénieure capable de comprendre son domaine en profondeur, de travailler avec les outils contemporains, de résoudre des problèmes complexes, d’apprendre continuellement et d’évoluer avec le métier.
Identifier les compétences fondamentales à consolider.
Identifier les compétences professionnelles avancées.
Identifier les compétences technologiques émergentes.
Identifier les compétences transversales nécessaires à l’exécution réelle de projets.
Identifier les domaines voisins utiles à la différenciation.
Construire progressivement des preuves de compétence : exercices, projets, études de cas, rapports, publications, portfolio ou réalisations.
Réévaluer régulièrement ce qui distingue une compétence scolaire d’une compétence réellement opérationnelle.
### 13.6 Historique vivant du domaine
Aurora doit pouvoir construire une représentation temporelle du domaine : d’où viennent les concepts, comment les méthodes ont évolué, quelles technologies les ont transformées et quelles tendances se poursuivent.
Chronologie des concepts, méthodes et technologies importantes.
Évolution des pratiques professionnelles.
Évolution des outils et logiciels.
Évolution des normes ou référentiels lorsque les sources sont disponibles.
Événements structurants et ruptures technologiques.
Relations entre anciennes méthodes et nouvelles pratiques.
Repérage des domaines en croissance, en transformation, en maturité ou en déclin documenté.
### 13.7 Présent + futurs possibles
La Discovery doit séparer strictement trois niveaux : faits établis sur la situation actuelle, tendances documentées et scénarios futurs. Pour l’horizon 2030–2050, Aurora doit présenter des trajectoires et non des certitudes.
État actuel du domaine.
Tendances observables et signaux émergents.
Facteurs susceptibles d’accélérer ou ralentir les transformations.
Scénarios plausibles à 2030, 2040 et 2050.
Compétences susceptibles de prendre de l’importance.
Compétences ou outils susceptibles de perdre de l’importance.
Incertitudes et hypothèses de chaque scénario.
Sources utilisées pour chaque projection.
### 13.8 Fiche de découverte
Chaque découverte importante doit pouvoir devenir un objet durable du système, avec une structure permettant de la réutiliser dans l’apprentissage et la planification.
Titre et question de départ.
Pourquoi Aurora recommande cette découverte maintenant.
Résumé factuel.
Sources classées par type.
Ce que cela confirme ou contredit dans les connaissances actuelles.
Lien avec les cours suivis.
Lien avec le domaine professionnel visé.
Compétences concernées.
Nouveaux concepts à apprendre.
Questions ouvertes.
Actions recommandées : lire, expérimenter, pratiquer, approfondir, suivre ou ignorer pour le moment.
Liens vers l’arbre sémantique et les objectifs concernés.
### 13.9 Boucle de découverte
Observer le profil et le contexte actuel.
Identifier un besoin, une lacune, une curiosité pertinente ou un changement du domaine.
Lancer une recherche multi-source.
Comparer et qualifier les résultats.
Sélectionner les découvertes à forte utilité.
Expliquer la découverte à l’utilisatrice.
Relier la découverte à son savoir existant.
Créer éventuellement une activité d’apprentissage ou un projet.
Mesurer ce qui a été compris, appliqué ou ignoré.
Utiliser le résultat pour améliorer les prochaines recommandations.
## 14. Self-Improvement de l’agent Aurora
Aurora doit disposer d’un mécanisme d’amélioration continue qui apprend de ses interactions avec l’utilisatrice. L’objectif n’est pas de prétendre que l’agent devient automatiquement plus intelligent dans tous les domaines, mais de lui permettre de conserver des apprentissages opérationnels vérifiés sur la manière de mieux assister cette utilisatrice et sur les procédures qui fonctionnent.
Principe : chaque erreur utile, réussite reproductible, correction explicite ou préférence stable peut devenir une connaissance opérationnelle réutilisable, avec niveau de confiance et possibilité de révision.
### 14.1 Ce que l’agent doit apprendre
Préférences de communication et de présentation.
Préférences d’apprentissage.
Préférences de planification.
Contraintes récurrentes.
Procédures qui donnent de bons résultats.
Erreurs déjà commises et leur cause identifiée.
Corrections explicitement données par l’utilisatrice.
Stratégies de coaching ayant amélioré l’exécution.
Stratégies ayant échoué ou provoqué une surcharge.
Conditions dans lesquelles une recommandation est pertinente ou non.
### 14.2 Expert Skills
Aurora doit pouvoir transformer des apprentissages récurrents et vérifiés en « Expert Skills » internes : de petites compétences procédurales spécialisées réutilisables par l’agent.
Déclencheur : dans quel contexte la skill doit être utilisée.
Objectif : quel résultat elle cherche à produire.
Procédure : étapes recommandées.
Contraintes : ce qu’il faut éviter.
Exemples de réussite.
Contre-exemples ou échecs connus.
Niveau de confiance.
Source : observation, correction de l’utilisatrice, document, test ou autre preuve.
Date et historique de validation.
Conditions de révision ou d’obsolescence.
Exemple : si plusieurs cycles montrent qu’une certaine structure de planning fonctionne mieux lorsqu’une journée est fortement chargée, Aurora peut créer une skill dédiée à ce contexte au lieu de redécouvrir la même stratégie à chaque conversation.
### 14.3 Apprentissage à partir des erreurs
Détecter une erreur ou un échec.
Identifier la cause probable au lieu de mémoriser seulement le symptôme.
Obtenir ou enregistrer la correction.
Tester la correction dans un contexte comparable.
Mesurer si l’erreur réapparaît.
Consolider la correction en skill si elle est suffisamment fiable.
Réduire ou archiver une ancienne stratégie devenue obsolète.
### 14.4 Apprentissage à partir des réussites
Identifier une action ou stratégie ayant produit un bon résultat.
Chercher ce qui a réellement contribué à la réussite.
Vérifier si le résultat est reproductible.
Extraire une procédure réutilisable.
Associer la procédure aux contextes où elle est pertinente.
Réutiliser la skill avec adaptation plutôt que copier mécaniquement la même stratégie.
### 14.5 Garde-fous du self-improvement
Ne pas transformer une hypothèse ponctuelle en vérité durable.
Conserver la provenance de chaque apprentissage important.
Attribuer un niveau de confiance.
Permettre à l’utilisatrice de corriger, désactiver ou supprimer une skill.
Détecter les contradictions entre skills.
Éviter qu’une mauvaise expérience répétée produise une règle générale injustifiée.
Réviser périodiquement les skills anciennes.
## 15. Interaction entre Discovery, Learning et Self-Improvement
Ces trois systèmes doivent former une boucle unique.
Discovery trouve une information ou une compétence utile.
Learning transforme cette découverte en compréhension et en maîtrise.
Practice vérifie la capacité à l’appliquer.
Progress mesure l’évolution.
Self-Improvement apprend ce qui a réellement fonctionné.
L’agent utilise cette nouvelle connaissance pour personnaliser les prochaines découvertes, séances d’apprentissage et plans d’action.
## 16. Nouvelle architecture conceptuelle de l’agent
Le noyau agentique doit donc travailler avec plusieurs formes de contexte : contexte instantané, contexte personnel, connaissances durables, état d’apprentissage, état de productivité, arbre sémantique et skills expertes.
Intent Context : ce que l’utilisatrice cherche à accomplir maintenant.
Personal Context : contraintes, préférences et historique personnel utile.
Productivity Context : tâches, projets, calendrier, objectifs, habitudes et charge.
Learning Context : cours, compétences, révisions, erreurs, maîtrise et FSRS.
Discovery Context : sujets suivis, sources, tendances, gaps et historique de veille.
Semantic Context : position des concepts dans l’arbre sémantique.
Expert Skills Context : procédures apprises par self-improvement.
Tool Context : outils actuellement disponibles.
Permission Context : actions autorisées, confirmées ou interdites.
## 17. Décision produit consolidée
Aurora n’est plus seulement un assistant qui exécute des commandes. Il devient un système d’accompagnement adaptatif : il aide à organiser le présent, construire les compétences, explorer le domaine, comprendre son évolution, détecter les écarts, apprendre de manière structurée et améliorer continuellement ses propres stratégies d’assistance.
La Discovery doit donc être considérée comme une capacité stratégique du produit, et le Self-Improvement comme une capacité fondamentale du noyau agentique. Ces deux éléments doivent être pris en compte dans toutes les futures décisions de données, d’interface, de stockage, d’outillage et d’architecture.

## 18. Progress — système de mesure de la transformation réelle
Progress n’est pas un simple tableau de statistiques ni un compteur de tâches terminées. C’est le système qui mesure la transformation réelle de l’utilisatrice dans le temps : état actuel, évolution, causes, écarts, preuves de progression et prochaine trajectoire d’action.
### 18.1 Questions fondamentales
Où en suis-je réellement ?
Qu’est-ce qui s’est réellement amélioré ?
Qu’est-ce qui stagne, régresse ou a été oublié ?
Pourquoi cette évolution a-t-elle eu lieu ?
Quelle prochaine action produira le plus de progrès utile ?
### 18.2 Dimensions de progression
Progression académique
Suivre les chapitres, concepts, définitions, formules et méthodes selon leur état : découvert, compris, rappelable, fragile, maîtrisé, oublié.
Mesurer les exercices réalisés, taux de réussite, erreurs récurrentes, autonomie de résolution et progression dans le programme.
Progression des compétences
Distinguer connaissance vue et compétence réellement utilisable.
Utiliser une échelle de transformation : découverte → compréhension → rappel → application guidée → application autonome → problème nouveau → maîtrise → expertise.
Associer chaque compétence à des preuves, un niveau, une fraîcheur et un degré de confiance.
Progression réelle contre illusion de progrès
Comparer QCM, rappel actif, exercices ouverts, problèmes nouveaux, explication à autrui, projets et applications professionnelles.
Détecter les cas où un bon score de reconnaissance masque une faible capacité de rappel ou de transfert.
Progression temporelle
Permettre des lectures à 7 jours, 30 jours, semestre, année et multi-années.
Privilégier la trajectoire et les tendances plutôt qu'un pourcentage isolé.
Progression vers les objectifs
Relier Goal → Skills → Projects → Tasks → Evidence.
Mesurer les jalons réellement atteints et les preuves disponibles.
Progression professionnelle
Comparer les compétences actuelles aux exigences du métier visé, aux pratiques professionnelles avancées et aux évolutions du domaine.
Présenter des écarts documentés et leurs voies de remédiation sans réduire la personne à un score global artificiel.
Oubli et consolidation
Distinguer une compétence acquise d'une compétence encore disponible.
Utiliser les données de répétition espacée/FSRS et les performances récentes pour détecter les connaissances qui se dégradent.
Progression de discipline et d'exécution
Suivre ponctualité, régularité, sessions réalisées, reports, durée planifiée contre durée réelle, interruptions, travail profond et récupération après un échec.
Analyser les causes des écarts plutôt que simplement compter les tâches terminées ou non.
### 18.3 Modèle de preuve
Une progression significative doit être liée à une ou plusieurs preuves observables. Le modèle de preuve peut inclure : QCM, rappel actif, exercice standard, exercice nouveau, explication personnelle, correction d'erreur, projet, application professionnelle et répétition réussie.
La donnée de progression doit conserver au minimum : compétence ou objectif concerné, niveau observé, preuve, date, fraîcheur, contexte et confiance.
### 18.4 Analyse causale de la progression
Progress doit chercher les facteurs expliquant l'évolution : stratégie d'apprentissage, temps réellement disponible, régularité, difficulté, charge, interruptions, qualité des ressources, erreurs récurrentes, compréhension préalable et changements de plan. L'agent ne doit pas confondre corrélation et causalité.
### 18.5 Trajectoires conditionnelles
Aurora peut construire des trajectoires conditionnelles à partir de l'état observé : maintien du rythme actuel, augmentation du temps disponible, changement de stratégie, réduction de charge ou correction d'un blocage. Ces trajectoires sont des scénarios d'aide à la planification et non des prédictions certaines.
### 18.6 Dashboard Progress
Aujourd'hui : progrès important, blocage principal, prochaine action.
Semaine : objectifs, compétences travaillées, temps réellement investi, écarts et difficultés persistantes.
Mois : compétences acquises ou consolidées, projets, habitudes, erreurs persistantes et changements observés.
Trajectoire : objectifs de long terme, gaps actuels, tendances, conditions de progression et prochaines étapes.
### 18.7 Progress comme moteur agentique
Progress ne doit pas être un écran passif. Ses résultats alimentent directement l'orchestration agentique.
Discovery → Learning → Practice → Progress → analyse → Self-Improvement → Adaptive Planning → Action.
Un gap détecté peut déclencher une révision, un exercice, une recherche, une nouvelle tâche ou une adaptation du planning.
Une stagnation peut déclencher une analyse de cause avant toute nouvelle recommandation.
Une réussite reproductible peut devenir une Expert Skill après validation.
### 18.8 Modèle de données conceptuel
ProgressSnapshot : état observé à un instant donné.
ProgressEvidence : preuve associée à une compétence ou un objectif.
SkillState : niveau actuel, fraîcheur, confiance, preuves et historique.
ProgressEvent : événement significatif d'apprentissage, d'exécution, d'erreur, de réussite ou de changement.
ProgressTrend : évolution agrégée sur une période.
Gap : écart identifié entre état actuel et état cible.
TrajectoryScenario : scénario conditionnel reliant état, hypothèses et actions possibles.
## 19. Boucle globale Aurora
Avec Progress intégré, Aurora forme une boucle opérationnelle complète :
Capture : recueillir tâches, idées, cours, documents, événements et informations.
Organize : structurer les objets, relations, ressources et priorités.
Plan : transformer les objectifs et contraintes en plan réaliste.
Execute : accompagner l'action et le travail profond.
Learn : transformer les ressources en compréhension, rappel, application et maîtrise.
Discover : détecter besoins, évolutions, gaps et opportunités d'approfondissement.
Practice : produire des preuves réelles de compétence.
Progress : mesurer l'évolution, les stagnations, les régressions et leurs causes.
Self-Improve : apprendre des erreurs et réussites validées.
Adapt : replanifier, personnaliser et améliorer les stratégies futures.
Review : réévaluer périodiquement les objectifs, trajectoires, habitudes et connaissances.
Le principe directeur devient : Aurora ne mesure pas seulement ce que l'utilisatrice a fait ; il cherche à comprendre ce qu'elle est désormais capable de faire, pourquoi elle a progressé ou stagné, et quelle action suivante peut transformer cette situation.
## 20. Décision produit consolidée — mise à jour v1.1
Aurora est un système d'accompagnement adaptatif qui relie productivité, apprentissage, découverte, progression et amélioration continue. Progress devient une capacité fondamentale du noyau agentique, au même niveau conceptuel que Learning, Discovery et Self-Improvement.
Toute décision importante de planification ou d'apprentissage doit pouvoir exploiter l'état de Progress.
Toute progression significative doit être reliée à des preuves et à un contexte.
Les recommandations doivent pouvoir être révisées lorsque les données montrent une stagnation, une régression ou une nouvelle contrainte.
Les données de Progress doivent rester exploitables par l'agent, les dashboards et les futures fonctions de coaching.

## 21. Stratégie de parallélisation — contrats, branches et Pull Requests
La parallélisation du développement d’Aurora repose sur un principe central : les agents sont séparés par responsabilités et par contrats techniques explicites. Chaque agent travaille dans une branche isolée et soumet une Pull Request vérifiable avant intégration.
### 21.1 Contrats techniques
Avant le codage parallèle, chaque domaine possède un Contract Pack définissant :
Responsabilité exacte du domaine.
Packages et fichiers autorisés à modifier.
Interfaces TypeScript publiques.
Types et modèles de données.
Événements entrants et sortants.
API/fonctions exposées.
Dépendances autorisées et interdites.
États loading, empty, success, error et offline.
Permissions et règles de sécurité.
Critères d’acceptation et Definition of Done.
Tests obligatoires.
### 21.2 Ownership des fichiers
Chaque agent possède un périmètre principal. Deux agents ne modifient pas simultanément les mêmes fichiers centraux. Les fichiers partagés sont gérés par l’agent Foundation/Owner ou par une PR dédiée.
Foundation → configuration racine, workspace, conventions et tooling.
Design System → packages/ui et tokens.
Data → packages/data, migrations et repositories.
Agent → packages/agent.
Scientific → packages/scientific-engine.
Integrations → packages/integrations.
Feature agents → leurs modules et tests.
### 21.3 Git et branches
Aucun agent ne travaille directement sur main. Chaque mission possède une branche courte et spécialisée.
feat/foundation-setup
feat/design-system
feat/productivity
feat/learning
feat/agent-kernel
feat/discovery
feat/progress
feat/knowledge
feat/artifacts-scientific
### 21.4 Pull Request comme unité d’intégration
La PR est le contrat d’intégration entre agents. Elle documente le changement, les contrats consommés ou modifiés, les tests et les risques.
Résumé de la fonctionnalité.
Contract Pack concerné.
Interfaces consommées et exposées.
Changements importants.
Tests et résultats.
Impact base de données/migrations.
Impact UI/UX.
Risques et breaking changes.
Capture ou vidéo pour les changements UI importants.
Checklist Definition of Done.
### 21.5 Pipeline obligatoire d’une PR
Code dans la branche de l’agent.
Tests unitaires et tests de domaine.
Type-check.
Lint/format.
Build du package concerné.
Vérification des contrats.
Review Codex.
Correction des findings.
CI GitHub.
Merge après validation.
### 21.6 Rôle de Codex
Codex agit comme reviewer indépendant et recherche notamment :
Violations d’architecture et de boundaries.
Incompatibilités de contrats et types.
Problèmes de sécurité, RLS, secrets, permissions et IPC.
Duplication, complexité et dette technique.
Régressions et cas limites.
États UX incomplets.
Problèmes d’orchestration agentique, permissions, tool calls et idempotence.
### 21.7 Évolution des contrats
Additive change : changement compatible, intégration normale.
Compatible change : modification interne sans impact du contrat, revue standard.
Breaking change : renommage, suppression ou changement de comportement ; PR dédiée et revue Codex obligatoire.
Une breaking change doit migrer ses consommateurs dans la même séquence d’intégration ou utiliser temporairement une version du contrat.
### 21.8 Stratégie de merge
main reste toujours buildable.
Les features sont intégrées par petites PRs.
Les PRs dépendantes déclarent explicitement leur dépendance.
Une PR dépendant d’un contrat non fusionné peut être préparée mais n’est pas considérée comme intégrée.
Ordre recommandé : Foundation → Contracts → Data/Core → Features → Agent → UI refinement → QA.
Après chaque vague : build + tests d’intégration.
### 21.9 Matrice de dépendances
Claude Code doit produire avant le codage une matrice indiquant pour chaque agent : inputs, outputs, contrats consommés, contrats produits, dépendances bloquantes et fichiers possédés. Cette matrice sert de carte officielle du parallélisme.
### 21.10 Interdictions pour les agents
Modifier le périmètre d’un autre agent sans accord.
Changer un contrat partagé sans le signaler.
Créer une abstraction concurrente lorsqu’un contrat existe déjà.
Modifier la configuration globale pour résoudre un problème local sans revue.
Contourner les interfaces ou types.
Fusionner directement dans main.
Ajouter une dépendance externe sans justification et revue.
### 21.11 Definition of Done
Fonctionnalité conforme au Contract Pack.
Type-check, lint et format validés.
Tests validés.
États UX pertinents traités.
Sécurité vérifiée.
Documentation mise à jour.
PR créée.
Review Codex terminée.
Findings critiques corrigés.
CI verte.
### 21.12 Vagues de parallélisation
Vague 0 — Architecture : contrats, tokens, types, schéma, conventions et CI de base.
Vague 1 — Fondations : UI, Data, Auth, stockage local et infrastructure.
Vague 2 — Features : Productivity, Learning, Knowledge, Discovery, Progress, Scientific/Artifacts.
Vague 3 — Agent Kernel : orchestration et connexion des capacités.
Vague 4 — Intégration : flows transversaux et scénarios utilisateur.
Vague 5 — Dyad : refinement UI/UX et validation.
Vague 6 — Codex : deep review globale, sécurité et dette technique.
Vague 7 — Release candidate : E2E, Android/Desktop, CI/CD et tests finaux.
### 21.13 Règle finale
La vitesse ne vient pas de plusieurs agents écrivant dans les mêmes fichiers. Elle vient de frontières explicites permettant à plusieurs agents de travailler simultanément sans se bloquer. Les contrats rendent le parallélisme possible ; les Pull Requests le contrôlent ; Codex en vérifie la qualité.
## 22. Mise à jour de la stratégie One-Day Build
Claude Code ×4 : architecture documentaire, Contract Packs, design system, flows, specs et découpage des agents.
Claude Code ×10 agents : implémentations parallèles dans des branches isolées.
Codex ×2 : reviews continues des PRs et deepening après chaque agent.
GitHub : PR obligatoire, CI obligatoire, main toujours buildable.
Dyad : refinement UI/UX et validation des flows après intégration.
QA final : E2E, build mobile/desktop et scénarios réels.
Post-build : collecte des gaps puis enhancement.

## 23. Stratégie de plateformes — Phase 1 Mobile Only, Phase 2 Desktop
Aurora est développée et mise en production selon une stratégie en deux phases. La Phase 1 est strictement mobile-only afin de concentrer les efforts sur une expérience mobile complète, stable et production-ready. Le desktop n'est pas une cible de livraison de la Phase 1.
### 23.1 Phase 1 — Mobile Only
Cible principale : application mobile Android via Ionic React + Capacitor.
Toutes les fonctionnalités prioritaires sont conçues, développées, intégrées et validées d'abord sur mobile.
Le One-Day Build et la première mise en production ne doivent pas inclure Electron.
La QA, les tests E2E et les critères de release de la Phase 1 sont centrés sur l'expérience mobile.
Aucun agent ne doit consacrer du temps à une implémentation desktop pendant cette phase.
### 23.2 Composants réutilisables et architecture portable
Même si l'interface cible est exclusivement mobile en Phase 1, les composants et responsabilités doivent être conçus pour permettre une migration vers desktop sans réécriture massive.
Les composants UI réutilisables doivent être isolés dans packages/ui lorsque cela est pertinent.
La logique métier ne doit pas être enfouie dans les composants visuels.
Les hooks, services, use-cases, repositories, types et modèles doivent rester indépendants de Capacitor autant que possible.
Les packages domain, data, agent, scientific-engine et integrations ne doivent pas dépendre directement d'Electron.
Les APIs natives doivent passer par des abstractions ou adapters explicites.
Les responsabilités frontend doivent être clairement séparées : présentation, état UI, orchestration de vue et logique métier.
Les composants qui nécessitent une adaptation desktop doivent avoir un contrat de comportement commun plutôt qu'une duplication complète.
### 23.3 Responsabilités compatibles desktop
La compatibilité future ne signifie pas développer deux interfaces simultanément. Elle signifie que les responsabilités sont placées au bon niveau architectural.
UI : composants et primitives réutilisables.
Application : use-cases, orchestration de fonctionnalités et gestion d'état.
Domain : règles métier et modèles indépendants de la plateforme.
Data : accès aux données et synchronisation via interfaces.
Integrations : adapters pour services externes.
Platform : couche spécifique Android/mobile ou desktop, isolée derrière des interfaces.
### 23.4 Préparation de la Phase 2
Après finalisation, mise en production et stabilisation de la version mobile, Aurora entre en Phase 2 : extension desktop avec Electron.
Réutiliser au maximum les packages et composants existants.
Ajouter les adapters Electron nécessaires aux capacités propres au desktop.
Créer les layouts desktop sans modifier inutilement la logique métier.
Réutiliser les contrats Agent, Data, Scientific Engine, Knowledge, Artifact et Integrations.
Ajouter une couche de tests desktop spécifique aux comportements propres à la plateforme.
Ne pas transformer la Phase 1 en développement cross-platform prématuré.
### 23.5 Règle architecturale
Principe : « Mobile Only pour la livraison, Platform-Agnostic pour le cœur. » La Phase 1 optimise l'exécution et la qualité mobile ; l'architecture conserve des frontières suffisamment propres pour permettre une extension desktop rapide et maîtrisée en Phase 2.
## 24. Mise à jour du One-Day Build
La cible de fin de journée est désormais explicitement la version mobile. Le desktop est retiré du périmètre de construction, de QA et de release de cette journée.
Claude Code : spécifications et implémentation orientées mobile.
Agents parallèles : aucun agent Electron/Desktop.
Codex : review de la qualité mobile et vérification de la portabilité architecturale.
Dyad : optimisation et validation de l'expérience mobile.
CI/CD : pipeline de build et tests de la cible mobile.
Release : version mobile production-ready.
Phase 2 ultérieure : Electron/Desktop après stabilisation de la production mobile.

## 25. Stack de visualisation, Semantic Tree et explications visuelles
La couche visuelle d’Aurora adopte plusieurs moteurs spécialisés plutôt qu’une seule bibliothèque universelle. Le choix est basé sur l’usage réel, la compatibilité React/TypeScript/mobile et la maintenabilité.
### 25.1 Décisions retenues
Semantic Tree — @xyflow/react + @dagrejs/dagre
React Flow fournit les nœuds React personnalisables, le pan/zoom/touch et les interactions. Dagre fournit un layout arborescent simple et adapté au Semantic Tree.
Infographies explicatives — @antv/infographic
Moteur déclaratif d’infographies rendu en SVG, intégrable dans React, avec thèmes, palettes, ressources personnalisables et export SVG/PNG. Très adapté aux explications générées par l’agent.
Graphiques et données — @antv/g2
Grammaire de visualisation data-driven pour courbes, distributions, comparaisons, statistiques, progression et résultats scientifiques. Supporte Canvas, SVG et WebGL.
Formules scientifiques — KaTeX
Rendu LaTeX performant dans le navigateur, adapté aux fiches, cours, exercices, cartes mémoire et contenus scientifiques.
Animation et micro-interactions — motion
Animation React/HTML/SVG, gestes, transitions, springs et animations de tracés SVG.
### 25.2 Pourquoi React Flow pour le Semantic Tree
Le Semantic Tree reste hiérarchique et lisible ; les relations transversales sont des ponts secondaires et ne doivent pas transformer l’interface principale en réseau illisible.
Nœuds entièrement personnalisables comme composants React.
Pan, zoom et zoom par pincement adaptés aux écrans tactiles.
Possibilité de masquer les descendants et de n’afficher que les branches ouvertes.
Support naturel des arbres hiérarchiques via Dagre.
Intégration directe avec Zustand et notre Design System.
Licence MIT pour le cœur React Flow.
Règle de performance : Aurora ne rend pas obligatoirement tout l’arbre. Les branches profondes sont chargées/affichées progressivement et peuvent être repliées. Les composants de nœuds doivent être mémorisés pour éviter les re-renders inutiles.
### 25.3 Architecture du Semantic Tree
SemanticNode : concept, domaine, sujet, principe, définition, formule, méthode, exemple, application, compétence.
SemanticEdge : relation hiérarchique principale.
SemanticBridge : relation transversale entre domaines, affichée à la demande.
NodeState : collapsed, expanded, selected, focused, mastered, fragile, forgotten.
SourceRef : provenance vers cours, document, passage ou découverte.
EvidenceRef : preuve de compréhension/application provenant de Progress.
Le moteur graphique ne doit pas devenir la source de vérité. La vérité du Semantic Tree est stockée dans la Knowledge Base ; React Flow ne fait que la visualiser et gérer l’interaction.
### 25.4 Pourquoi AntV Infographic pour les explications
AntV Infographic est particulièrement intéressant pour Aurora car il fonctionne avec une syntaxe déclarative, possède un renderer SVG, propose des thèmes/palettes personnalisés, des resource loaders et des exports SVG/PNG. Il fournit également une API getTypes() conçue pour générer les types nécessaires à des modèles génératifs.
AI → InfographicSpec → validation → @antv/infographic → SVG → affichage/export.
Le contenu reste séparé du moteur de rendu.
Les templates servent de structures de présentation ; l’agent choisit la structure selon le contenu.
Les palettes Aurora sont enregistrées comme thèmes/palettes réutilisables.
Les ressources visuelles passent par un loader contrôlé et peuvent être servies depuis nos propres assets.
Les infographies peuvent être exportées en SVG ou PNG.
### 25.5 Règle de fidélité pédagogique
AntV Infographic ne doit pas devenir un moteur de réécriture pédagogique incontrôlée. Pour les définitions, formules et éléments issus du corpus d’un professeur, Aurora conserve le texte source comme autorité. L’agent peut sélectionner, hiérarchiser et mettre en page ces éléments sans les paraphraser lorsqu’un mode de fidélité stricte est activé.
### 25.6 Pourquoi G2 reste séparé d’Infographic
G2 et AntV Infographic ne remplissent pas le même rôle. G2 est conçu comme une grammaire de visualisation pilotée par les données ; Infographic est orienté composition d’infographies et storytelling visuel.
G2 → progression, statistiques, séries temporelles, comparaisons, distributions, résultats expérimentaux.
Infographic → explication d’une notion, synthèse visuelle, processus, étapes, comparaison structurée, fiche visuelle.
### 25.7 Pourquoi KaTeX
Rendu natif de contenu LaTeX dans le navigateur.
Très adapté aux formules techniques affichées en grand nombre.
Compatible avec l’écosystème React via des wrappers existants ou un renderer interne.
Les formules restent textuelles et peuvent être intégrées dans les fiches, exercices et infographies.
### 25.8 Pourquoi Motion
Motion ne remplace aucun moteur de visualisation. Il donne au Design System la capacité de rendre les explications plus vivantes : révélation progressive d’une formule, tracé d’une flèche, transition entre étapes, apparition d’un résultat, gestes et micro-interactions.
### 25.9 Technologies évaluées mais non retenues comme moteur principal
G6 : puissant pour les graphes et adapté aux arbres/graphes de grande taille, mais plus bas niveau et moins directement intégré à React que React Flow. À conserver comme option future pour un Knowledge Graph à très grande échelle.
ECharts : moteur généraliste mature, mais son intérêt diminue puisque G2 couvre notre besoin data-driven avec une grammaire plus adaptée à Aurora.
Mermaid : excellent pour générer rapidement des schémas textuels, mais moins adapté au niveau de personnalisation visuelle recherché.
tldraw : excellent canvas/whiteboard, mais hors périmètre du Semantic Tree et inutile dans le cœur V1.
### 25.10 Abstraction interne obligatoire
Pour éviter de coupler Aurora aux bibliothèques choisies, la couche de visualisation expose ses propres contrats.
SemanticTreeRenderer
InfographicRenderer
DataVisualizationRenderer
MathRenderer
AnimationController
Les bibliothèques externes sont des implémentations. Les features métier, l’Agent Kernel et la Knowledge Base ne doivent pas importer directement les détails des moteurs lorsque cela peut être évité.
### 25.11 Flux agentique de génération visuelle
Intent : identifier ce que l’utilisatrice cherche à comprendre.
Context : récupérer cours, sources, niveau, connaissances déjà maîtrisées et Progress.
Structure : choisir arbre, infographie, graphique, formule ou combinaison.
Content validation : vérifier les sources, définitions et formules.
Render : produire la représentation via le moteur adapté.
Explain : accompagner la représentation d’une explication progressive.
Interact : permettre zoom, sélection, révélation, comparaison ou exercice.
Evidence : enregistrer ce qui a été compris/appliqué et alimenter Progress.
### 25.12 Décision finale de la stack visuelle V1
@xyflow/react + @dagrejs/dagre → Semantic Tree interactif.
@antv/infographic → explications et infographies générées.
@antv/g2 → graphiques de données, progression et résultats scientifiques.
KaTeX → LaTeX et mathématiques.
motion → animations et micro-interactions.
Cette combinaison évite une dépendance excessive à un seul moteur, tout en gardant une séparation claire : structure cognitive, explication visuelle, données, mathématiques et animation.
## 26. Sources techniques vérifiées — 21 septembre 2026
React Flow / xyflow — https://reactflow.dev/ ; https://github.com/xyflow/xyflow
React Flow layouting — https://reactflow.dev/learn/layouting/layouting
AntV Infographic — https://infographic.antv.vision/ ; https://github.com/antvis/Infographic
AntV Infographic API — https://infographic.antv.vision/reference/infographic-api
AntV G2 — https://g2.antv.antgroup.com/ ; https://github.com/antvis/G2
AntV G6 — https://g6.antv.antgroup.com/
Motion — https://motion.dev/ ; https://github.com/motiondivision/motion
KaTeX — https://katex.org/docs/
Nouveaux composants intégrés — v1.5
Knowledge Editor — Tiptap
Tiptap est retenu comme couche d’édition riche pour les notes, fiches de révision, annotations, explications IA, formules, tableaux, images et blocs structurés. Il reste découplé du cœur métier afin de pouvoir changer d’éditeur si nécessaire. La collaboration Yjs est architecturée comme extension future, mais n’est pas activée dans le One-Day Build.
Capture documentaire — Scanner + OCR
Aurora ajoute un contrat DocumentScanner et un contrat OCRProvider. Le flux cible est : caméra → scan de pages → OCR → structuration → Knowledge Base → extraction des définitions/formules → apprentissage. Aucun moteur OCR précis n’est imposé au cœur applicatif : l’implémentation reste interchangeable.
Audio et visualisation temporelle
Aurora ajoute un Audio Artifact Viewer et une abstraction AudioWaveformRenderer. Les cours audio peuvent être lus, parcourus et associés à des timestamps. La transcription est indépendante de la lecture audio.
Transcription vocale — capacité optionnelle
Un contrat TranscriptionProvider est ajouté, mais aucun modèle STT n’est embarqué dans le One-Day Build. Le cœur Aurora connaît la capacité de transcription, pas son fournisseur. Une implémentation locale telle que whisper.cpp pourra être évaluée ultérieurement sur de vrais appareils Android. Le système doit accepter l’absence de provider, fonctionner sans transcription et permettre l’ajout d’un provider cloud ou local sans modification du domaine.
Pipeline audio futur
Audio Artifact → TranscriptionProvider (optionnel) → Transcript → Segmentation → Concepts → Knowledge Base → Semantic Tree → Learning/Progress. Les traitements lourds sont asynchrones et persistés comme Jobs ; ils ne bloquent pas l’interface.
Explain Engine — extension conceptuelle
Le système d’explication peut sélectionner dynamiquement une représentation : Tiptap pour une explication structurée, KaTeX pour une formule, Semantic Tree pour une structure de connaissances, AntV Infographic pour une explication visuelle/processus, G2 pour les données et Motion pour l’animation. L’objectif est que l’agent choisisse la représentation adaptée plutôt que d’exposer tous les moteurs comme des modules indépendants.
Contrats ajoutés / confirmés
DocumentScanner
OCRProvider
AudioArtifactProvider
AudioWaveformRenderer
TranscriptionProvider (optional)
ExplainRenderer / ExplainEngine
Principe architectural complémentaire
Les capacités coûteuses ou optionnelles (OCR, transcription, génération d’artefacts, recherche, etc.) sont traitées comme des providers remplaçables et/ou des Jobs asynchrones. Le domaine Aurora ne dépend jamais directement d’un fournisseur ou d’un modèle. Une capacité absente doit dégrader proprement l’expérience au lieu de casser le produit.
Architecture cible figée — v1.6
STATUT : DÉCISION ARCHITECTURALE DE RÉFÉRENCE — GELÉE POUR LE DÉVELOPPEMENT
Cette section fige l’architecture cible d’Aurora après comparaison des architectures envisagées. Elle devient la référence pour Claude Code, Codex, les agents de développement, les PR et les futures évolutions. Toute modification importante doit faire l’objet d’une décision architecturale documentée.
## 1. Décision générale
Aurora adopte une architecture composite : Modular Monolith + Vertical Slices + Clean/Hexagonal Architecture (Ports & Adapters) + Local-First + Serverless ciblé + Jobs asynchrones + Event-Driven ciblé + données hybrides (relationnel + vectoriel + arbre sémantique + historique d’événements) + Agent Kernel central à capacités spécialisées.
## 2. Architecture retenue par dimension
Dimension
Choix figé
Règle
Architecture globale
Modular Monolith
Une seule unité principale déployable, organisée en modules métier fortement séparés.
Organisation du code
Vertical Slices
Chaque capacité fonctionnelle possède son périmètre de code, tests et contrats.
Dépendances
Clean Architecture
Le domaine et l’application restent indépendants des frameworks et fournisseurs.
Découplage
Hexagonal / Ports & Adapters
Les fournisseurs IA, recherche, OCR, transcription, stockage, notifications, etc. passent par des contrats.
Frontend
Ionic React + TypeScript
Frontend mobile-first et réutilisable.
Mobile
Capacitor
Accès aux capacités natives Android en phase 1.
Desktop
Electron — Phase 2
Introduit après stabilisation et production de la version mobile.
Offline
Local-First
L’application privilégie l’état local puis synchronise avec le cloud.
Synchronisation
PowerSync + SQLite + Supabase PostgreSQL
Synchronisation persistante entre état local et backend.
Backend
Supabase
Supabase reste le backend transactionnel ; Cloudflare n’est pas un second backend métier.
Serverless
Supabase Edge Functions + Cloudflare Workers ciblés
Edge Functions pour backend/jobs adaptés ; Workers pour la couche IA edge/fallback et les besoins à faible latence.
Traitements longs
Jobs persistés + Workers
Traitements lourds asynchrones, idempotents et observables.
Communication
Request/Response + Events ciblés
Les opérations transactionnelles restent directes ; les événements servent au découplage.
CQRS
Hybride et ciblé
Uniquement lorsque lecture et écriture ont des besoins réellement différents.
Event Sourcing
Non en V1
Historique d’événements utile sans en faire l’unique source de vérité.
Microservices
Non en V1
Architecture prête à extraire certains modules plus tard, mais aucun découpage distribué initial.
IA
Agent Kernel + AI Router + AI Gateway multi-provider
Agnes comme primaire ; Cloudflare Workers AI/Worker comme pool de secours ; autres fournisseurs derrière des Ports/Providers ; aucune clé dans le mobile.
Données
Hybrides
PostgreSQL + pgvector + Semantic Tree + Event History.
## 3. Architecture logique de référence
AURORA
├── Mobile Client — Ionic React + TypeScript + Capacitor
│   └── Local-First — SQLite / PowerSync
├── Application / Domain
│   ├── Identity
│   ├── Productivity
│   ├── Learning
│   ├── Knowledge
│   ├── Discovery
│   ├── Progress
│   ├── Agent
│   ├── Scientific
│   ├── Artifact
│   └── Integrations
├── Ports / Contracts
│   ├── AIProvider
│   ├── ResearchProvider
│   ├── OCRProvider
│   ├── TranscriptionProvider
│   ├── ObjectStorage
│   ├── ArtifactProvider
│   ├── NotificationProvider
│   ├── ScientificEngine
│   ├── KnowledgeBase
│   └── FocusController
├── Infrastructure Adapters
│   ├── Supabase
│   ├── R2
│   ├── Agnes AI
│   ├── You.com / Tavily / Exa
│   └── Composio
├── Async Job System
│   ├── Dispatcher
│   ├── Persisted Jobs
│   ├── Workers / Edge Functions
│   ├── Retry / Backoff
│   ├── Idempotency
│   └── Job Logs
└── Data Layer
    ├── PostgreSQL
    ├── pgvector
    ├── Semantic Tree
    └── Event History
## 4. Règles architecturales obligatoires
Le domaine ne dépend jamais directement d’un fournisseur externe ou d’un framework.
Aucun module métier ne doit accéder directement aux tables internes d’un autre module sans contrat explicite.
Les fournisseurs externes sont encapsulés derrière des Ports/Providers.
Les fonctionnalités optionnelles doivent pouvoir être absentes sans rendre Aurora inutilisable.
Les traitements lourds ou longs ne doivent pas bloquer l’interface utilisateur.
Tout Job doit être persisté, identifiable, idempotent, réessayable et observable.
Les événements servent au découplage ; ils ne remplacent pas toutes les interactions synchrones.
CQRS est appliqué uniquement lorsqu’un besoin concret le justifie.
Event Sourcing complet est exclu de la V1.
Aucun microservice ne doit être créé simplement pour suivre une tendance technologique.
Toute future extraction en microservice doit être justifiée par un besoin mesurable : scalabilité indépendante, isolation opérationnelle, cadence de déploiement, équipe autonome ou contrainte technologique.
Le cœur applicatif doit rester portable afin de permettre l’arrivée future d’Electron sans réécriture du domaine.
Les décisions d’architecture sont versionnées et toute modification importante doit faire l’objet d’une ADR.
## 5. Pourquoi les microservices sont reportés
Aurora n’adopte pas les microservices en V1 malgré la richesse fonctionnelle du produit. La distribution introduirait des appels réseau, des défaillances distantes, des problèmes de cohérence et une charge opérationnelle supplémentaires. Les frontières modulaires sont donc imposées au niveau du code et des contrats, sans payer immédiatement le coût d’un système distribué.
La stratégie d’évolution est : Modular Monolith First → mesurer en production → identifier un besoin réel → extraire uniquement le module concerné.
## 6. Architecture événementielle ciblée
Les événements sont réservés aux cas où plusieurs composants doivent réagir indépendamment à une évolution de l’état ou lorsqu’un traitement asynchrone est souhaitable.
TaskCompleted
CourseImported
FlashcardReviewed
ProgressEvidenceCreated
SkillStateChanged
GoalUpdated
ArtifactGenerated
JobCompleted
DiscoveryItemCreated
Une opération transactionnelle simple reste une commande directe. Modifier le titre d’une tâche, par exemple, n’a pas besoin de devenir un événement distribué.
## 7. Architecture de données figée
PostgreSQL est la source transactionnelle principale. pgvector complète PostgreSQL pour la recherche sémantique et le retrieval. Le Semantic Tree représente la hiérarchie de connaissances. L’Event History conserve les événements utiles à l’analyse de progression, à l’audit et à l’apprentissage du système, sans imposer Event Sourcing comme modèle général.
## 8. Architecture agentique figée
Aurora utilise un Agent Kernel central. Planner, Coach, Tutor, Researcher, Executor et les autres capacités ne constituent pas nécessairement des agents indépendants déployés séparément. Le Kernel coordonne : Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory.
## 9. Stratégie d’évolution
Phase 1 — One-Day Build
Mobile uniquement. Modular Monolith, Local-First, contrats, jobs, Agent Kernel et fonctionnalités principales. Aucun Electron et aucun microservice.
Phase 1.1 — Stabilisation
Tests réels, sécurité, observabilité, performance, synchronisation, corrections UX et validation des scénarios complets.
Phase 1.2 — Production
Déploiement mobile stable, mesure des usages et identification des véritables goulots d’étranglement.
Phase 2 — Desktop
Electron après finalisation et stabilisation du mobile. Réutilisation du cœur platform-agnostic.
Phase 3 — Extraction éventuelle
Un module peut devenir un service indépendant uniquement si des mesures et contraintes réelles le justifient.
## 10. Fondement de la décision
La décision tient compte des coûts documentés de la distribution : appels distants faillibles, cohérence éventuelle et complexité opérationnelle. Les architectures événementielles sont conservées de manière ciblée pour le découplage asynchrone. Supabase Edge Functions restent utilisées comme infrastructure serverless adaptée aux API, webhooks et traitements appropriés.
Références consultées : Martin Fowler — Microservice Trade-Offs, Microservice Prerequisites et Microservices Guide ; Microsoft Azure Architecture Center — Architecture Styles ; Supabase Documentation — Edge Functions Architecture.
## 11. Statut de gel
ARCHITECTURE v1.6 — SUPERSEDÉE PAR v1.7 : la présente section historique reste conservée pour la traçabilité. La décision de référence actuelle est la section v1.7 ajoutée ci-dessous.

Architecture cible figée — v1.7
STATUT : DÉCISION ARCHITECTURALE DE RÉFÉRENCE — GELÉE POUR LE DÉVELOPPEMENT
## 1. Objet de l’évolution
La v1.7 conserve la décision globale v1.6 et ajoute une architecture IA multi-provider réellement opérationnelle. Aurora ne dépend plus d’un seul fournisseur de modèles. Le domaine, l’Agent Kernel et les fonctionnalités métier ne connaissent jamais un nom de modèle concret.
## 2. Décision IA globale
Aurora adopte : Agent Kernel → AI Router → AI Policy/Budget → Cloudflare AI Gateway → fournisseurs IA. Agnes reste le fournisseur primaire pour le raisonnement et l’agenticité ; Cloudflare Workers AI constitue un second pool d’inférence gratuit pour les modèles éligibles ; Groq, Cerebras, OpenRouter, Mistral, Cohere et Google sont des providers optionnels selon disponibilité, qualité, confidentialité et limites du moment.
## 3. Rôle de Cloudflare AI Gateway
AI Gateway est la couche de contrôle et d’observabilité de la sortie IA. Ses fonctions cœur sont gratuites sur tous les plans. Il fournit notamment analytics, caching, rate limiting, retries, fallback et Dynamic Routing. Il peut aussi intégrer un fournisseur non natif via Custom Providers, ce qui permet de proxifier Agnes sans coupler le cœur Aurora à Agnes.
## 4. Rôle du Cloudflare Worker de fallback
Un Cloudflare Worker dédié, séparé du domaine Aurora, constitue le chemin de dernier recours. Il peut appeler directement Workers AI lorsque le chemin principal ou le routage Gateway devient indisponible. Le Worker ne porte aucune logique métier durable ; il normalise les requêtes/réponses, applique les timeouts et expose un point edge minimal. Il ne doit pas être utilisé pour contourner des quotas.
## 5. Architecture logique IA
AURORA → Agent Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → AI Gateway → Provider Adapter → modèle. En cas d’échec, le Router sélectionne un provider compatible selon la tâche. En dernier recours, Aurora peut appeler le Cloudflare Worker de secours, qui utilise Workers AI directement. Les tâches critiques peuvent ensuite passer par une vérification KB/source et/ou Scientific Engine.
## 6. Sélection dynamique des modèles
Le routeur choisit selon : complexité, raisonnement requis, tool calling, vision, longueur de contexte, latence, criticité, coût/quota disponible, politique de confidentialité et santé du provider. Aucun branchement ne doit dépendre d’un mot-clé naïf dans le prompt. La décision repose sur un profil de tâche typé.
## 7. Niveaux de routage
ROUTINE : modèle rapide et économique. AGENT : modèle à raisonnement/tool calling. MULTIMODAL : modèle vision/audio si requis. CRITIQUE : modèle fort + vérification externe ou déterministe. FALLBACK : autre provider compatible. Aurora doit préférer une réponse légèrement moins puissante mais fiable et vérifiable à une panne totale.
## 8. Registre actuel des free tiers — vérifié le 21 septembre 2026
Cette matrice décrit des accès actuellement observés dans les documentations officielles. Un free tier est traité comme une capacité variable, non comme une SLA. Les quotas, modèles et conditions peuvent changer ; le Model Registry doit donc rester versionné et réévaluable.
Provider
Accès gratuit actuel
Modèles / capacités utiles
Limites clés
Rôle Aurora
Décision
Agnes
Oui — API gratuite
Agnes 3.0 Flash ; 2.5 Flash ; multimodal Agnes selon catalogue
Quotas Agnes propres, à suivre par compte/type de clé
Primaire : Agent / Coach / Planner / Tutor / Researcher
Cœur V1
Cloudflare Workers AI
Oui — 10 000 Neurons/jour
GLM-4.7 Flash ; Gemma 4 26B A4B ; Nemotron 3 Super 120B ; autres modèles éligibles
10 000 Neurons/jour ; certains gros modèles exigent Workers Paid
Second pool gratuit + multimodal + fallback
Cœur V1
Groq
Oui — Free Plan
GPT-OSS 120B ; GPT-OSS 20B ; outils/raisonnement selon modèle
Ex. 30 RPM ; GPT-OSS 120B/20B : 1 000 RPD, 8K TPM, 200K TPD au Free Plan
Fallback haute vitesse / batch léger / voice selon modèles
Provider V1 optionnel
Cerebras
Oui — Free Trial/Tier
GPT-OSS 120B ; GLM-4.7 (et modèles gratuits selon compte)
5 RPM, 30K TPM, 1M tokens/jour sur les modèles concernés ; limites temporaires possibles
Fallback reasoning très rapide / comparaison
Provider V1 optionnel
OpenRouter
Oui — pool de modèles gratuits
Nemotron 3 Ultra/Super, Gemma 4, GPT-OSS 20B, autres free modèles variables
50 requêtes/jour et 20 RPM pour compte gratuit ; pool dynamique
Fallback expérimental / benchmarking / diversification
Staging + fallback
Cohere
Oui — Trial Key
Command A Reasoning 111B, Command A+, Command A Vision, North Mini Code
1 000 appels/mois ; généralement 20 req/min sur Chat ; trial pour évaluation/POC
RAG/raisonnement/vision spécialisé, pas moteur public V1
Staging
Mistral
Oui — Free mode, sans carte
Mistral Small 4 ; Medium 3.5 et autres modèles disponibles selon compte
Limites free faibles et visibles dans l’Admin ; pas de chiffres publics stables
Alternative de test ; désactiver l’usage des données pour entraînement selon politique
Staging / optionnel
Google Gemini API
Oui — Free tier toujours actif
Gemini 3.5 Flash, Flash-Lite et autres modèles avec prix free selon le catalogue courant
Limites par projet/modèle, dynamiques et à vérifier dans AI Studio
Vision/long contexte en expérimentation ; pas de dépendance au free tier
Optionnel
Hugging Face Inference Providers
Oui — micro-crédit
Centaines de modèles via plusieurs providers
0,10 USD/mois pour comptes Free ; insuffisant pour le trafic Aurora
Benchmarks et tests ponctuels
Non-core
GitHub Models
Non
Service retiré le 30 juillet 2026
Playground/catalog/API retirés
Aucun
Exclu
SambaNova Cloud
Pas retenu comme free tier autonome
Modèles production disponibles avec crédits
Page officielle actuelle : le plan Free demande un moyen de paiement et l’achat de crédits
Pas une vraie réserve gratuite fiable pour Aurora
Exclu de la matrice free
## 9. Contrats IA obligatoires
AIProvider : interface uniforme d’inférence, streaming et erreurs normalisées.
AIModelRegistry : catalogue de modèles, capacités, contexte, modalités, statut, quotas et conditions.
AIModelRouter : sélection dynamique du modèle/provider selon le TaskProfile et l’état courant.
AIModelPolicy : règles de sécurité, confidentialité, criticité, coût et compatibilité.
AIFallbackStrategy : chaîne de repli déterministe par type de tâche.
AIHealthRegistry : latence, taux d’erreur, 429/5xx, cooldown et disponibilité par provider/modèle.
AIUsageTracker : tokens/neurons/requêtes/latence/coûts et consommation des free tiers.
AIBudgetManager : budget par provider, modèle, environnement et utilisateur ; arrêt avant dépassement.
AIRequestGuard : validation, taille de contexte, timeouts, idempotence des jobs et filtrage des données sensibles lorsque requis.
## 10. Règles de fallback
Un fallback doit conserver la compatibilité fonctionnelle minimale de la tâche : vision si vision requise, tool calling si outils requis, sortie structurée si JSON exigé.
Un 429 est interprété avec le type de limite concerné. Changer de clé ne sert jamais à contourner une limite.
Les retries sont bornés et séparés des fallbacks : retry sur panne transitoire ; fallback sur indisponibilité, incompatibilité ou limite atteinte.
Une réponse de fallback doit rester traçable : provider, modèle, tentative, motif et qualité attendue sont enregistrés.
Les modèles free ne sont pas considérés comme une garantie de capacité permanente. Le routeur doit pouvoir les retirer automatiquement du pool s’ils deviennent indisponibles ou payants.
## 11. Confidentialité et données
Les documents, cours, notes et informations personnelles d’Aurora ne doivent pas être envoyés automatiquement vers un free tier dont la politique de données est incompatible avec les besoins d’Aurora. Les providers doivent déclarer une DataPolicy dans le Model Registry. Les offres gratuites de Mistral et certains modèles gratuits d’OpenRouter peuvent avoir des conditions d’utilisation des données différentes ; la route de production doit donc pouvoir les exclure. Groq, de son côté, indique ne pas retenir les données d’inférence par défaut et propose un contrôle Zero Data Retention. Les politiques restent à vérifier au moment de l’intégration et à versionner.
## 12. Google : statut corrigé
Contrairement aux anciennes informations diffusées en ligne, Google dispose encore d’un free tier API en septembre 2026. Cependant, Google ne publie pas une table universelle et stable de quotas pour tous les comptes : les limites exactes dépendent du projet, du modèle et du niveau d’utilisation et doivent être vérifiées dans AI Studio. Le mode gratuit indique également que certaines données peuvent être utilisées pour améliorer les produits. Aurora conserve donc Google comme provider optionnel plutôt que comme pilier de production gratuit.
## 13. Providers explicitement non retenus comme piliers gratuits
GitHub Models est retiré depuis le 30 juillet 2026 et ne peut plus être utilisé. SambaNova n’est pas retenu comme réserve free fiable car sa page officielle actuelle associe le plan Free à l’ajout d’un moyen de paiement et à l’achat de crédits. Hugging Face reste utile pour les tests, mais le crédit gratuit actuel de 0,10 USD/mois est trop faible pour compter comme capacité d’inférence Aurora.
## 14. Stratégie de routage de référence
ROUTINE : Agnes 2.5 / GLM-4.7 Flash / Groq GPT-OSS 20B selon disponibilité. AGENT : Agnes 3.0 en priorité, puis Nemotron 3 Super, GPT-OSS 120B ou Cerebras selon santé et quotas. VISION/DOCUMENT : Gemma 4 ou un provider vision compatible. CRITIQUE : modèle fort + vérification KB/source et/ou Scientific Engine ; un second modèle peut être utilisé comme juge uniquement lorsque la valeur de la vérification justifie la consommation de quota. Aucun modèle unique ne doit être supposé indispensable.
## 15. Schéma de référence
Aurora Mobile → Backend Aurora → Agent Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget → Cloudflare AI Gateway → {Agnes Custom Provider | Workers AI | Groq | Cerebras | Mistral | OpenRouter | Cohere | Google} → réponse normalisée → Verify → Action/Result → Memory/Progress. En cas d’indisponibilité du chemin Gateway, le Cloudflare AI Edge Worker peut utiliser directement Workers AI comme voie de dernier recours.
## 16. Impact sur le One-Day Build
Le One-Day Build doit implémenter les abstractions et au moins deux providers fonctionnels : Agnes et Cloudflare Workers AI. Groq et Cerebras doivent être branchés derrière le même contrat dès que les clés et accès sont disponibles. OpenRouter, Cohere, Mistral et Google peuvent être enregistrés comme adaptateurs optionnels sans devenir des dépendances bloquantes. Le Model Registry doit permettre d’activer/désactiver un provider sans modifier le domaine.
## 17. Changelog v1.7
Ajout d’un AI Router et d’un Model Registry.
Ajout de Cloudflare AI Gateway comme couche de contrôle multi-provider.
Ajout d’un Cloudflare Worker de dernier recours utilisant Workers AI directement.
Ajout de Groq et Cerebras comme providers gratuits de secours à forte vitesse.
Ajout d’OpenRouter comme pool de modèles gratuits expérimental et de benchmarking.
Ajout de Cohere, Mistral et Google comme providers optionnels avec restrictions de production selon quotas/politiques de données.
Retrait de GitHub Models du registre en raison de sa fermeture au 30 juillet 2026.
SambaNova exclu du free pool de référence en raison de son plan Free actuel nécessitant un moyen de paiement et l’achat de crédits.
Hugging Face reclassé en provider de test à cause du faible crédit mensuel gratuit.
Décision de ne jamais utiliser plusieurs clés pour contourner les quotas.
## 18. Sources de vérification utilisées le 21 septembre 2026
Cloudflare AI Gateway — Pricing / Dynamic Routing / Custom Providers / REST API / Changelog : https://developers.cloudflare.com/ai-gateway/
Cloudflare Workers AI — Pricing et Changelog : https://developers.cloudflare.com/workers-ai/platform/pricing/ ; https://developers.cloudflare.com/changelog/product/workers-ai/
Groq — Rate Limits / Models / Your Data : https://console.groq.com/docs/rate-limits ; https://console.groq.com/docs/models ; https://console.groq.com/docs/your-data
Cerebras Inference — Rate Limits / Models : https://inference-docs.cerebras.ai/support/rate-limits ; https://inference-docs.cerebras.ai/models/overview
OpenRouter — Pricing / Free Models : https://openrouter.ai/pricing ; https://openrouter.ai/collections/free-models
Cohere — Rate Limits / Command A Reasoning / North Mini Code : https://docs.cohere.com/v1/docs/rate-limits ; https://docs.cohere.com/docs/command-a-reasoning ; https://docs.cohere.com/docs/north-mini-code-1.0
Mistral — Free mode, limits et data controls : https://docs.mistral.ai/admin/billing-usage/usage-limits ; https://help.mistral.ai/en/articles/698531-why-am-i-hitting-api-rate-limits-and-how-do-i-increase-them ; https://help.mistral.ai/en/articles/347617-do-you-use-my-user-data-to-train-your-artificial-intelligence-models
Google Gemini API — Pricing / Rate Limits : https://ai.google.dev/gemini-api/docs/pricing ; https://ai.google.dev/gemini-api/docs/rate-limits
Hugging Face Inference Providers — Pricing : https://huggingface.co/docs/inference-providers/pricing
GitHub Models — Retirement notice : https://docs.github.com/en/github-models
SambaNova Cloud — Plans : https://cloud.sambanova.ai/plans
Agnes AI — modèle 3.0 Flash / accès API : https://agnes-ai.com/en/docs/agnes-30-flash
## 19. Statut final
ARCHITECTURE GELÉE v1.7 POUR LE DÉVELOPPEMENT : Aurora est multi-provider dès la V1. Agnes est le provider primaire ; Cloudflare AI Gateway et Workers AI constituent la couche de résilience ; Cloudflare Worker est le dernier recours edge ; Groq et Cerebras renforcent le pool gratuit ; les autres providers sont ajoutables via contrats sans toucher au domaine. Les free tiers sont des capacités opportunistes et non des garanties de service.
