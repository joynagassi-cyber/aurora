# AURORA

## Référence produit, fonctionnelle et feuille de route

**Version :** 1.1 — référence produit, fonctionnelle et stack candidate intégrée  
**Date :** 24 octobre 2026  
**Statut :** baseline produit + stack de référence choisie ; intégrations à valider par prototypes et audit du dépôt  
**Périmètre :** modules Aurora existants + Design Space Pro dans la première version Web responsive ; Desktop ensuite ; Mobile après Desktop ; autres studios spécialisés selon la roadmap.

> **Objet du document** — Décrire Aurora comme un produit cohérent, préciser l’expérience des cinq personas prioritaires, conserver l’ensemble des modules fonctionnels existants, définir Design Space Pro, séquencer les livraisons et rendre explicites les décisions, dépendances, limites et critères de validation.
>
> Ce document ne certifie pas l'état actuel du code. Il enregistre désormais la stack de référence sélectionnée par le propriétaire du produit et les briques complémentaires issues de la recherche TanStack. La sélection d'un outil ne vaut pas validation de compatibilité en production : versions exactes, intégration PowerSync, architecture Ionic/Next.js, sécurité Electron, éditeurs et travaux en arrière-plan doivent passer les portes de validation décrites dans la roadmap.

---

# Sommaire général

1. [Résumé exécutif](#1-résumé-exécutif)
2. [Vision, positionnement et principes](#2-vision-positionnement-et-principes)
3. [Personas et adaptation de l’expérience](#3-personas-et-adaptation-de-lexpérience)
4. [Architecture de navigation et surfaces produit](#4-architecture-de-navigation-et-surfaces-produit)
5. [Modules fonctionnels existants — catalogue complet](#5-modules-fonctionnels-existants--catalogue-complet)
6. [Design Space Pro — spécification fonctionnelle](#6-design-space-pro--spécification-fonctionnelle)
7. [Modèle universel de projet](#7-modèle-universel-de-projet)
8. [Architecture fonctionnelle et stack de référence](#8-architecture-fonctionnelle-et-stack-de-référence)
   - [Stack choisie et topologie des applications](#87-stack-de-référence-retenue-par-le-propriétaire-du-produit)
   - [PowerSync, SQLite et état applicatif](#88-données-powersync-sqlite-postgresql-et-état-applicatif)
   - [Écosystème TanStack](#89-audit-de-lécosystème-tanstack)
   - [Briques complémentaires](#810-autres-briques-utiles-pour-éviter-de-réimplémenter-des-mécanismes-complexes)
   - [Agent Aurora et multi-agents](#811-architecture-de-lagent-aurora-et-des-chaînes-multi-agents)
9. [Qualité, sécurité et exigences non fonctionnelles](#9-qualité-sécurité-limites-et-exigences-non-fonctionnelles)
10. [Roadmap produit et priorités](#10-roadmap-produit-et-priorités-de-réalisation)
11. [Parcours de bout en bout](#11-parcours-de-bout-en-bout-servant-de-preuve-dintégration)
12. [Critères d’acceptation et revue de qualité](#12-critères-dacceptation-et-revue-de-qualité)
13. [Registre des décisions et risques](#13-registre-des-décisions-et-risques)
14. [Références utilisées](#14-références-utilisées-et-statut-des-connaissances)
15. [Glossaire](#15-glossaire)

---

# Comment lire cette référence

Les marqueurs ci-dessous permettent de distinguer les faits de cadrage, les héritages et les recommandations :

- **DÉCIDÉ** — choix confirmé explicitement par le propriétaire du produit dans le cadrage courant.
- **HÉRITÉ** — capacité ou règle déjà décrite dans les documents Aurora antérieurs ; à préserver, sauf décision ultérieure explicite.
- **PROPOSÉ** — organisation ou recommandation ajoutée pour rendre la vision exploitable ; à valider avant gel technique.
- **À ARBITRER** — question qui nécessite une décision ; le document ne la tranche pas par défaut.
- **À VÉRIFIER** — l'information existe dans une source, mais son état réel dans le produit doit être vérifié dans le code, les tests ou le journal de livraison.
- **ROADMAP** — capacité visée, mais qui ne fait pas partie du premier périmètre fonctionnel à livrer.

## Décisions de cadrage confirmées

1. Aurora se positionne autour de cinq verbes : **Créer, Apprendre, Découvrir, S'organiser et Innover**.
2. Tous les modules et capacités fonctionnels antérieurs restent dans la vision et le périmètre cible d'Aurora ; ils ne sont pas supprimés au profit du nouveau Design Space.
3. La première version cible comprend le socle fonctionnel existant et **Design Space Pro**, centré sur les identités visuelles, les logos, les chartes graphiques, les affiches et les documents professionnels.
4. Les autres studios spécialisés (notamment 3D, musique, vidéo et création avancée de sites Web) seront ordonnés dans la roadmap. Les capacités des modules antérieurs sont conservées même si certains studios avancés arrivent plus tard.
5. Ordre des plateformes : **Web responsive → Desktop → Mobile**.
6. L'interface doit s'adapter à cinq personas principaux : étudiant, entrepreneur, autodidacte curieux, entreprise et particulier.
7. Les personas adaptent l'accueil, les raccourcis, les modèles et les parcours ; ils ne créent pas cinq applications ou cinq bases fonctionnelles indépendantes.
8. La stack de référence inclut TypeScript, Ionic React, Capacitor, Electron, Next.js, PowerSync, SQLite, Supabase/PostgreSQL, Zod et l'Agent Aurora ; les bibliothèques de l'écosystème TanStack sont sélectionnées selon leur utilité, leurs recouvrements et leur maturité.

## Points explicitement non gelés

- Les versions exactes des paquets et l'activation définitive de quelques briques en pré-version (notamment TanStack DB/PowerSync Collection, TanStack AI, Pacer et Hotkeys), qui doivent être testées avant d'entrer dans le chemin critique.
- L'architecture précise de coexistence entre Next.js et Ionic React : la proposition de référence sépare le site public Next.js de l'application métier Ionic React ; cette topologie doit être confirmée au spike d'intégration.
- La technologie du moteur d'édition de Design Space Pro et ses formats de fichiers définitifs, même si Fabric.js, SVG structuré et Tiptap sont les candidats préférentiels issus des recherches.
- Les choix précis d'intégration entre PowerSync et TanStack DB, et la frontière exacte entre les données synchronisées, les caches de requêtes et l'état d'édition local.
- Les formats source/export garantis et le découpage détaillé en packages pour Brand DNA, LOGO, AFFICHE et documents multipages.
- Le degré de collaboration multi-utilisateur dans l'offre entreprise et les fonctions d'administration d'organisation.
- L'ordre des studios postérieurs à Design Space Pro.
- L'état exact d'implémentation de chaque capacité existante : les sources disponibles sont incohérentes sur certains points et ne remplacent pas un audit actuel du dépôt.

---

## Parcours logique de rédaction et de revue du document

La référence est construite de manière séquentielle pour empêcher les décisions techniques de précéder les décisions produit, et pour rendre chaque partie vérifiable indépendamment.

### 1. Consolider les sources
**Travail :** lire la vision récente, le catalogue de fonctionnalités, le modèle universel de projet et les rapports LOGO, AFFICHE et VIDEO.  
**Résultat attendu :** inventaire des décisions, capacités, contraintes, propositions et contradictions.  
**Porte de revue :** aucun choix ancien n’est remplacé silencieusement.

### 2. Fixer le produit
**Travail :** définir la promesse, le périmètre de la première version, les studios inclus et les studios de roadmap.  
**Résultat attendu :** vision produit commune.  
**Porte de revue :** les limites de la première version sont compréhensibles.

### 3. Décrire les personas
**Travail :** définir objectifs, besoins, accueil, navigation, raccourcis et fonctions exposées par persona.  
**Résultat attendu :** contrats UX par persona.  
**Porte de revue :** les personas réutilisent le même socle et leurs préférences restent modifiables.

### 4. Cartographier les modules
**Travail :** reprendre tous les modules et toutes les capacités documentées sans en omettre, avec propriétaires et relations.  
**Résultat attendu :** catalogue fonctionnel maître.  
**Porte de revue :** chaque capacité a un rôle clair et n’est pas dupliquée sous un autre nom.

### 5. Spécifier Design Space Pro
**Travail :** décrire Brand DNA, génération éditable, éditeurs, validation, documents multipages, versions et exports.  
**Résultat attendu :** spécification du premier studio de création.  
**Porte de revue :** les sources de travail et les rendus ne sont pas confondus.

### 6. Décrire les parcours de bout en bout
**Travail :** relier recherche, connaissances, projet, création, vérification, planification et export.  
**Résultat attendu :** scénarios utilisateur qui testent l’intégration réelle.  
**Porte de revue :** les transferts conservent le contexte et les propriétaires des données.

### 7. Définir les responsabilités système
**Travail :** séparer interface, contexte de projet, Agent Kernel, modules, moteurs, données, tâches longues et export.  
**Résultat attendu :** architecture fonctionnelle indépendante de la stack.  
**Porte de revue :** aucun module n’écrit directement dans les données d’un autre module sans contrat.

### 8. Construire la roadmap
**Travail :** classer les fondations, le premier lancement Web, Desktop, les studios suivants et Mobile.  
**Résultat attendu :** phases, dépendances, critères d’entrée et de sortie.  
**Porte de revue :** le plan ancien est réconcilié avec le nouveau Web-first.

### 9. Définir les validations
**Travail :** établir les critères d’acceptation, la qualité, les états d’erreur, la sécurité et les tests.  
**Résultat attendu :** définition de fin de travail transversale et par studio.  
**Porte de revue :** une fonctionnalité ne passe pas « terminée » sur la seule base d’une maquette ou d’une génération réussie une fois.

### 10. Effectuer la revue de cohérence
**Travail :** vérifier terminologie, périmètre, dépendances, statuts, responsabilités et risques.  
**Résultat attendu :** baseline prête à servir à la mise en œuvre de la stack de référence et au découpage technique.  
**Porte de revue :** les points non tranchés sont consignés dans un registre ouvert.

**Règle de revue :** tout changement ultérieur doit préciser s'il modifie la vision produit, le périmètre, un contrat fonctionnel, une décision technique ou uniquement la présentation UX. Une modification de vision ou de contrat ne doit pas être introduite par simple changement de code.

---

# 1. Résumé exécutif

Aurora est un espace de travail intelligent destiné à aider une personne à **créer, apprendre, découvrir, s'organiser et innover**. Il transforme des intentions en actions, des recherches en connaissances, des connaissances en décisions et des décisions en productions ou en résultats vérifiables.

La proposition de valeur ne repose pas sur l'addition de modules. Elle repose sur la continuité entre eux. Un utilisateur peut formuler un objectif, explorer le sujet, définir un projet, apprendre les compétences manquantes, produire un livrable, vérifier ce qui peut l'être, organiser les prochaines actions et faire évoluer son travail sans devoir reconstruire le contexte à chaque étape.

Aurora comporte deux niveaux de lecture :

- **Le produit visible** : expériences adaptées aux personas, espaces de travail, projets, raccourcis, éditeurs, tableaux de bord et productions.
- **Le socle de capacités** : modules spécialisés, Agent Kernel, recherche, calcul, stockage, synchronisation, exports, sécurité et intégrations.

La première version cible doit associer le socle fonctionnel existant à **Design Space Pro**. Ce studio rend la valeur créative immédiatement visible au travers de créations de marque, logos, chartes, affiches et documents professionnels multipages, tout en préservant les autres capacités Aurora. Les studios 3D, musique, vidéo et développement Web avancé étendent ensuite le potentiel créatif selon la roadmap.

Le déploiement se fait dans l'ordre suivant : **Web responsive en premier**, puis **Desktop**, puis **Mobile**. Le Web est la première surface qui devra rendre accessibles le socle et les fonctions de Design Space Pro. Desktop approfondira le travail sur des projets exigeants ; Mobile privilégiera les actions adaptées au téléphone, la consultation, la capture, l'organisation, l'apprentissage et les modifications rapides. Il ne s'agit pas de supposer que chaque fonction avancée doit être reproduite à l'identique sur les trois plateformes.

La règle d'ingénierie centrale est de préserver l'éditabilité et la traçabilité : les sorties ne doivent pas se limiter à des pixels lorsque des représentations structurées sont adaptées. Un logo peut être constitué de paths et de calques SVG ; une affiche peut être décrite par une charte et une structure de calques ; une vidéo future pourra s'appuyer sur une timeline et des scènes structurées ; un modèle 3D pourra être conceptuel ou paramétrique selon le moteur. L'IA interprète, propose et orchestre ; des moteurs déterministes rendent, calculent et valident ce qui peut l'être.

---

# 2. Vision, positionnement et principes

## 2.1 Promesse produit

**Aurora est l'espace dans lequel on développe ses capacités, ses projets et ses créations.** Il aide l'utilisateur à démarrer même lorsque son idée est imprécise, à progresser sans devoir choisir lui-même tous les outils et à conserver les éléments utiles pour continuer son travail.

Les cinq dimensions de la promesse sont des orientations d'expérience et de communication, pas nécessairement cinq modules techniques :

1. **Créer** — produire des résultats éditables, visuels, documentaires, numériques ou autres selon les moteurs disponibles.
2. **Apprendre** — acquérir des connaissances et compétences directement utiles à un objectif ou à une curiosité.
3. **Découvrir** — rechercher, explorer, comparer, trouver les lacunes et formuler des hypothèses.
4. **S'organiser** — transformer objectifs et décisions en tâches, calendriers, projets et habitudes.
5. **Innover** — combiner découvertes, compétences et prototypes afin d'explorer de nouvelles solutions.

## 2.2 Ce qu'Aurora n'est pas

- Pas une simple collection de générateurs indépendants.
- Pas uniquement une application de productivité ou d'apprentissage.
- Pas un clone de Canva ou un éditeur uniquement graphique.
- Pas un agent qui agit sans contrôle ni explication.
- Pas un moteur universel qui garantirait toutes les sorties créées par l'IA.
- Pas une suite dans laquelle chaque artefact est un fichier final opaque et difficile à modifier.
- Pas une promesse que tout module ou studio de la vision cible soit déjà implémenté.

## 2.3 Principes de conception

### Continuité de contexte
Les projets, briefs, décisions, sources, tâches, apprentissages, artefacts et versions doivent rester liés lorsque c'est utile. Le contexte aide les modules à coopérer sans fusionner leurs responsabilités.

### Intention d'abord
L'utilisateur doit pouvoir exprimer ce qu'il souhaite faire en langage naturel ou à partir d'une entrée explicite. Aurora sélectionne les capacités pertinentes ; il ne doit pas obliger chaque utilisateur à connaître le nom des modules.

### Représentations modifiables
Quand c'est approprié, une production conserve sa structure : SVG éditable, JSON de calques, protocole de rendu textuel, timeline, spécifications, données et ressources sources. Une image ou une vidéo aplatie peut être fournie comme aperçu ou export, mais ne remplace pas systématiquement la source éditable.

### IA encadrée par des moteurs et des règles
L'IA est adaptée à la compréhension, au raisonnement, à l'analyse et à la proposition. Les opérations calculables, les rendus, les contrôles de structure et les validations déterministes doivent être confiés à des fonctions dédiées lorsqu'elles existent.

### Contrôle utilisateur
L'utilisateur peut modifier manuellement, verrouiller des éléments, comparer des variantes, accepter ou refuser une modification, revenir à une version antérieure et décider du passage à l'étape suivante.

### Qualité explicite
Une création générée, une création rendue, une création vérifiée et une production validée pour un usage donné sont des états distincts. Aurora doit expliquer ce qui a été contrôlé, ce qui a échoué et ce qui reste incertain.

### Progressivité
L'utilisateur n'a pas à configurer tout Aurora au premier lancement. L'expérience commence par ses objectifs et centres d'intérêt, puis expose progressivement les capacités avancées.

### Extensibilité sans refonte systématique
Les nouveaux moteurs spécialisés doivent pouvoir s'intégrer au contexte de projet, à la sécurité, à la gestion des versions, à l'export et à l'orchestration commune sans forcer une refonte de tous les modules.

---

# 3. Personas et adaptation de l'expérience

## 3.1 Principes communs aux personas

Les personas sont des modes de personnalisation. Un compte peut avoir plusieurs rôles et l'utilisateur peut changer son mode principal, ses centres d'intérêt et ses raccourcis. L'interface ne doit pas déduire automatiquement des informations sensibles ou enfermer l'utilisateur dans une identité définitive.

Chaque persona adapte :

- le contenu principal de l'accueil ;
- l'ordre et la visibilité des sections de navigation ;
- les modèles de projet proposés ;
- les raccourcis et actions suggérées ;
- les conseils de l'assistant, en tenant compte du contexte explicite ;
- les informations de progression et les rappels ;
- l'entrée dans Design Space Pro lorsque celui-ci est pertinent.

Les autres fonctions restent retrouvables via la navigation générale, la recherche et le lanceur de commandes.

## 3.2 Persona A — Étudiant

**Objectif principal :** mieux apprendre, réussir les cours et examens, organiser les échéances et constater les progrès.

**Questions typiques :** « Que dois-je réviser aujourd'hui ? », « Transforme ce cours en fiches », « Sur quels concepts est-ce que je bloque ? », « Aide-moi à planifier mes examens ».

**Accueil recommandé :**
- échéances et calendrier d'études ;
- tâches urgentes et prochaines séances ;
- matières et cours actifs ;
- révisions planifiées et cartes à revoir ;
- progression observée et concepts fragiles ;
- accès rapide à l'import de cours et à la bibliothèque.

**Capacités privilégiées :** Learning, Knowledge, Progress, Productivity, Discovery et Agent.

**Parcours types :** importer un cours → extraire/organiser les éléments → générer fiches ou exercices → planifier les révisions → collecter les preuves de maîtrise → adapter la suite.

**Design Space Pro :** affiches académiques, supports de présentation, infographies ou documents structurés liés à un projet d'étude. Le studio doit rester disponible sans encombrer l'accueil d'étude.

**Réduction des frictions :** convertir les actions répétitives en commandes guidées ; conserver les liens avec la source d'origine ; distinguer fidèlement le contenu fourni de l'explication générée par l'IA ; annoncer clairement ce qui n'a pas pu être vérifié.

## 3.3 Persona B — Entrepreneur

**Objectif principal :** passer de l'idée à une activité, un produit, une proposition commerciale ou un livrable tangible.

**Questions typiques :** « Aide-moi à valider ce marché », « Structure mon projet », « Quels sont les livrables qui manquent ? », « Crée l'identité de ma marque et son affiche de lancement ».

**Accueil recommandé :**
- initiatives et projets actifs ;
- prochaines actions, jalons, blocages et décisions à prendre ;
- recherche et hypothèses ouvertes ;
- ressources liées à l'entreprise ou au produit ;
- livrables en cours et éléments à faire approuver ;
- lancement rapide d'un projet ou de Design Space Pro.

**Capacités privilégiées :** Discovery, Knowledge, Productivity, Agent, Artifact, Integrations et Design Space Pro.

**Parcours types :** formuler un problème → rechercher et comparer → préciser l'offre → créer les supports → organiser le lancement → examiner les résultats et itérer.

**Design Space Pro :** Brand DNA, logo, charte, affiches, dossiers commerciaux, guides et documents de référence pour l'activité.

**Réduction des frictions :** modèles guidés pour les initiatives fréquentes ; un seul brief partagé entre recherche et création ; production progressive de livrables ; conversion des décisions en tâches ; affichage clair des éléments incomplets.

## 3.4 Persona C — Autodidacte curieux

**Objectif principal :** explorer des sujets, satisfaire sa curiosité, développer des compétences et transformer certaines découvertes en projets.

**Questions typiques :** « Explique-moi cette idée », « Recherche les différentes approches », « Qu'est-ce que je ne comprends pas encore ? », « Organise les connaissances que j'ai trouvées ».

**Accueil recommandé :**
- explorations récentes et sujets suivis ;
- découvertes enregistrées ;
- ressources et notes reliées ;
- pistes de recherche et questions ouvertes ;
- activités d'apprentissage suggérées ;
- objectifs personnels facultatifs.

**Capacités privilégiées :** Discovery, Knowledge, Learning et Progress, avec Productivity activé quand l'utilisateur veut planifier.

**Parcours types :** poser une question → explorer les sources → distinguer les faits, analyses et incertitudes → structurer les connaissances → apprendre au besoin → créer éventuellement un projet.

**Design Space Pro :** schémas, affiches explicatives, documents de synthèse et supports qui permettent de communiquer les découvertes.

**Réduction des frictions :** transformer une conversation utile en ressource réutilisable ; conserver les sources ; proposer des étapes de profondeur croissante sans imposer des plans d'apprentissage complets à chaque exploration.

## 3.5 Persona D — Entreprise

**Objectif principal :** créer et maintenir des livrables professionnels cohérents, organiser les projets et réutiliser les ressources de référence.

**Questions typiques :** « Prépare notre charte », « Produis les affiches de cette campagne », « Mets ce dossier au format de notre marque », « Quelles productions utilisent encore l'ancienne identité ? ».

**Accueil recommandé :**
- projets et livrables d'équipe ou d'activité, selon les permissions disponibles ;
- documents de référence ;
- Brand DNA ou charte de la marque ;
- tâches, échéances et versions en attente de validation ;
- productions récentes et historique des modifications ;
- accès aux intégrations disponibles.

**Capacités privilégiées :** Design Space Pro, Productivity, Knowledge, Discovery, Artifact et Integrations.

**Parcours types :** fournir un brief et les ressources autorisées → établir la charte → produire les supports → vérifier la cohérence et la lisibilité → réviser → exporter → conserver les versions.

**Design Space Pro :** chartes professionnelles, logo, affiches, documents multipages, guides de marque, modèles et déclinaisons alignées sur les références choisies.

**Réduction des frictions :** réutilisation des règles de marque ; modèles ; paramètres verrouillables ; versions comparables ; traçabilité des modifications ; contrôles avant export.

**À arbitrer :** le périmètre du travail collaboratif, des commentaires, des rôles d'organisation, des approbations formelles, du SSO et de l'administration centralisée. Ces capacités ne doivent pas être promises avant vérification de leur support effectif.

## 3.6 Persona E — Particulier

**Objectif principal :** gérer sa vie personnelle, capturer ses idées, organiser ses projets et créer des documents ou supports utiles.

**Questions typiques :** « Aide-moi à organiser ma semaine », « Je veux garder cette idée », « Prépare une invitation », « Aide-moi à apprendre quelque chose de nouveau ».

**Accueil recommandé :**
- tâches et événements à venir ;
- capture rapide d'idées, notes et ressources ;
- objectifs, habitudes et routines ;
- projets personnels actifs ;
- accès facile à l'apprentissage et à la création ponctuelle.

**Capacités privilégiées :** Productivity, Learning, Knowledge, Discovery et Agent selon le besoin.

**Design Space Pro :** invitations, affiches, documents personnels, supports pour des activités et petits projets créatifs.

**Réduction des frictions :** démarrage simple ; pas de paramétrage professionnel obligatoire ; modèles personnalisables ; rappels contrôlables ; fonctionnement dégradé explicite lorsque le réseau ou un fournisseur n'est pas disponible.

## 3.7 Matrice indicative personas × capacités

- **Productivité et projets :** priorité très élevée pour les étudiants, entrepreneurs, entreprises et particuliers ; mise en avant selon les objectifs pour les autodidactes.
- **Learning :** priorité très élevée pour les étudiants et autodidactes ; capacité mobilisée selon le besoin chez les autres personas.
- **Knowledge :** priorité élevée pour les étudiants, entrepreneurs et entreprises, très élevée pour les autodidactes ; personnalisation selon les ressources et projets.
- **Discovery :** priorité très élevée pour les entrepreneurs et autodidactes, élevée pour les entreprises, moyenne à élevée pour les étudiants ; activation selon le besoin pour les particuliers.
- **Progress :** priorité très élevée pour les étudiants ; adaptation aux objectifs, processus et sujets pour les autres personas.
- **Agent IA :** capacité transversale dans tous les personas, limitée par les permissions et capacités effectivement disponibles.
- **Calcul scientifique :** mis en avant selon le cursus, le produit, le sujet ou l'activité professionnelle ; usage occasionnel chez les particuliers.
- **Design Space Pro :** supports académiques pour l'étudiant ; marque et supports commerciaux pour l'entrepreneur ; synthèses visuelles pour l'autodidacte ; charte et production pour l'entreprise ; créations personnelles pour le particulier.
- **Intégrations et automatisations :** visibilité selon les outils utilisés, le workflow, les règles d'entreprise et les besoins personnels.

Cette matrice est un réglage initial, pas une restriction d'accès. Les fonctions sensibles ou payantes éventuelles dépendront de permissions, contrats et décisions commerciales distinctes.

---

# 4. Architecture de navigation et surfaces produit

## 4.1 Principes d'interface

- L'utilisateur voit d'abord les projets, tâches, questions et productions utiles, pas l'organigramme technique des packages.
- La navigation est prévisible et cohérente entre les modules.
- Le contexte du projet reste visible ou retrouvable lorsqu'on passe d'une capacité à une autre.
- Chaque écran possède les états requis : chargement, vide, succès, erreur, absence de réseau ou indisponibilité d'un fournisseur lorsque cela s'applique.
- Une action d'IA doit indiquer son intention, son état d'exécution et son résultat ; elle ne doit jamais simuler une réussite.
- Les fonctions avancées sont accessibles sans rendre l'accueil incompréhensible aux nouveaux utilisateurs.

## 4.2 Structure de navigation proposée

**A. Accueil personnalisé** — prochaines actions, projets, recommandations de la semaine et raccourcis selon persona.

**B. Projets / Workspaces** — liste et recherche des initiatives, briefs, artefacts et versions.

**C. Créer** — entrée vers Design Space Pro et, ultérieurement, vers les studios spécialisés disponibles.

**D. Apprendre** — ressources, cours importés, fiches, flashcards, exercices et progression.

**E. Découvrir** — recherche, dossiers d'exploration, lacunes et scénarios.

**F. S'organiser** — inbox, tâches, calendrier, objectifs, habitudes, focus, projets de productivité et bilans.

**G. Connaissances** — arborescence sémantique, ressources, sources et recherche.

**H. Bibliothèque / Artefacts** — livrables, exports et aperçus pris en charge.

**I. Paramètres** — profil, personnalisation, confidentialité, notifications, intégrations et préférences.

Cette hiérarchie est proposée pour l'expérience Web. Le nom final, la barre latérale, le regroupement éventuel de certaines sections et la navigation compacte doivent être testés sur des tâches réelles. La navigation doit permettre de revenir au contexte précédent sans perdre les filtres, les sélections ou le projet actif.

## 4.3 Web responsive — Phase 1

Le Web responsive est la surface complète de première livraison. Il doit prendre en charge les principaux parcours de modules et l'édition professionnelle de Design Space Pro. Les grandes surfaces de travail peuvent adapter leurs panneaux et leurs contrôles à la largeur disponible, mais aucune fonction essentielle du périmètre Web ne doit être invisible sur des formats d'écran courants sans explication.

Contrats de responsive design :

- navigation compacte quand la largeur diminue ;
- panneaux de contexte et d'inspection repliables ;
- contrôles d'édition qui restent utilisables au clavier et au pointeur ;
- tableaux transformés en vues adaptées lorsque nécessaire, sans supprimer les actions ;
- sauvegarde d'état et reprise après rafraîchissement selon les règles du produit ;
- confirmation visible des sauvegardes et des exports ;
- traitement des travaux longs hors du cycle bloquant de l'interface.

## 4.4 Desktop — Phase 2

Desktop reprend les parcours Web tout en privilégiant les tâches qui bénéficient d'une grande surface de travail : documents longs, comparaison de variantes, bibliothèques d'actifs, projets volumineux et édition approfondie. Les raccourcis clavier, le traitement des fichiers locaux et les fonctions natives éventuelles devront être décidés lors de l'arbitrage technique. Desktop ne signifie pas automatiquement Electron ou une technologie particulière.

## 4.5 Mobile — Phase 4

Mobile propose une expérience adaptée, notamment : capture rapide, inbox, tâches, calendrier, habitudes, sessions de focus, consultation des sources et livrables, apprentissage, progression, notifications et petites corrections. La création de documents ou la révision d'une affiche peut être limitée à des actions compatibles avec l'écran. Les projets complexes doivent pouvoir être repris plus tard sur Web ou Desktop au même état logique.

## 4.6 Recherche globale et lanceur de commandes

Une recherche globale doit permettre de retrouver projets, tâches, notes, ressources, connaissances, productions et commandes accessibles. Les résultats respectent les permissions de l'utilisateur. Un lanceur de commandes peut proposer des actions fréquentes telles que créer un projet, capturer une idée, chercher une source ou ouvrir Design Space Pro. Les commandes destructrices ou ayant des effets externes exigent les confirmations prévues.

---

# 5. Modules fonctionnels existants — catalogue complet

Les modules ci-dessous sont conservés dans le périmètre produit. Leur inclusion dans ce document signifie « capacité requise dans la vision cible » ; elle ne prouve pas qu'elle est déjà intégrée, testée ou disponible dans une version publiée.

## 5.1 Productivity — Organiser son travail et sa vie

**Responsabilité :** transformer intentions, objectifs et décisions en actions organisées.

### Inbox universelle (`productivity.inbox`)
Capturer des tâches, notes, événements, idées, ressources et documents. Permettre le tri ultérieur, la conversion vers les bons objets et l'accès rapide depuis l'interface globale.

### Tâches et sous-tâches (`productivity.tasks`)
Gérer statut, échéance, priorité, estimation, temps réellement passé, récurrence, dépendances, pièces jointes, reports et historique. Les sous-tâches et les états doivent être explicites ; les tâches bloquées ne sont pas traitées comme terminées.

### Priorisation Eisenhower (`productivity.eisenhower`)
Présenter une matrice importance/urgence et fournir des suggestions explicables basées sur les contraintes et le contexte disponibles. La décision finale appartient à l'utilisateur. Le statut de l'écran dédié doit être confirmé dans le catalogue de l'interface.

### Calendrier et time blocking (`productivity.calendar`)
Planifier des événements et plages de travail, détecter les conflits et surcharges, suggérer des créneaux et demander confirmation pour les changements qui engagent l'agenda ou déclenchent une notification.

### Projets de productivité (`productivity.projects`)
Organiser tâches, jalons, dépendances et ressources avec des vues Liste, Kanban, Timeline et Gantt. Les modèles doivent pouvoir accélérer les projets courants et rester personnalisables.

### Objectifs (`productivity.goals`)
Relier objectifs à court, moyen et long terme aux projets et tâches. Les objectifs doivent être suivis à partir de résultats et de preuves disponibles, pas uniquement d'une déclaration subjective.

### Habitudes et routines (`productivity.habits`)
Suivre des habitudes quotidiennes ou hebdomadaires, des routines et des tendances de régularité. Les rappels et l'analyse ne doivent pas devenir intrusifs ; les paramètres de cadence et de silence sont respectés.

### Focus et Pomodoro (`productivity.focus`)
Gérer les sessions de concentration, les minuteurs, Pomodoro et bilans. Le blocage d'applications au niveau système est dépendant de la plateforme et des autorisations. Il ne doit pas être promis sur le Web si le navigateur ne le permet pas.

### Revues et journal des décisions (`productivity.reviews`)
Produire des bilans quotidiens, hebdomadaires ou mensuels, conserver des décisions et comparer prévu/réalisé. L'agent peut préparer une revue, mais doit laisser l'utilisateur vérifier les interprétations.

### Analytics personnels (`productivity.analytics`)
Analyser écarts entre plan et réalité, reports, surcharge et tendances. Les analyses associatives ne doivent pas être formulées comme des causes certaines sans preuve appropriée.

### Bibliothèque de ressources (`productivity.library`)
Centraliser cours, PDF, images, liens, exercices, notes et autres ressources, avec métadonnées, rattachement à des matières, compétences ou projets et recherche.

## 5.2 Learning — Apprendre efficacement

**Responsabilité :** transformer les ressources et objectifs en activités d'apprentissage, de pratique et de révision.

### Import de cours et de ressources (`learning.import`)
Importer des cours à partir de fichiers, images ou captures lorsque le support existe. Le traitement peut inclure extraction, OCR et ingestion dans les connaissances. Si l'automatisation d'import échoue, une saisie manuelle doit rester possible. L'origine et les limites d'extraction doivent être indiquées.

### Fiches de révision (`learning.sheet`)
Créer plusieurs structures de fiches à partir du corpus fourni. Préserver la fidélité aux sources ; séparer clairement les explications supplémentaires produites par l'IA ; contrôler le contenu avant export.

### Flashcards et répétition espacée (`learning.flashcards`)
Créer et réviser des cartes selon un algorithme de répétition espacée. La révision devrait rester accessible dans des conditions réseau réduites si les données requises sont disponibles localement ; la génération et les calculs nécessitant le serveur suivent leur contrat de disponibilité.

### QCM, exercices progressifs et analyse des erreurs (`learning.qcm`)
Générer des questions, exercices et feedback. Suivre les erreurs récurrentes et proposer une pratique ciblée. Éviter d'inventer une réponse attribuée au cours lorsque le corpus ne la justifie pas.

### Coach d'apprentissage (`learning.coach`)
Proposer des check-ins et de l'accompagnement selon une cadence contrôlée par l'utilisateur. Les notifications doivent respecter les périodes de silence et la préférence d'intervention.

### Mirror Cognitive Mode (`learning.mirror`)
Analyser, lorsque le mécanisme est effectivement disponible, des motifs d'apprentissage et des difficultés à partir de preuves structurées. Les détections doivent garder leur provenance et ne pas être présentées comme des diagnostics certains.

### Compétences (`learning.skills`)
Consulter les états de compétences détenus par Progress : maîtrisée, fragile ou manquante. Learning propose des activités, mais ne devient pas propriétaire d'un état de progression appartenant à un autre module.

## 5.3 Knowledge — Construire et retrouver le savoir

### Arbre sémantique (`knowledge.tree`)
Organiser les connaissances en racines, branches, nœuds et relations. Les liens secondaires doivent enrichir la lecture sans rendre l'arbre principal illisible. Les modifications et versions de l'arbre sont traçables.

### Recherche et récupération (`knowledge.retrieval`)
Retrouver des passages pertinents à partir du texte, de la recherche sémantique et de documents indexés. Les résultats doivent contenir une référence de source lorsque disponible et respecter les accès. L'agent distingue les extraits de source de ses propres explications.

### OCR et numérisation (`knowledge.ocr`)
Extraire du texte à partir de documents ou d'images pris en charge. Si la reconnaissance est incertaine ou indisponible, signaler le problème et autoriser la correction manuelle.

## 5.4 Discovery — Découvrir et explorer

### Recherche multi-source (`discovery.research`)
Explorer plusieurs sources, comparer les approches et produire un dossier de recherche. Séparer les faits rapportés, tendances, analyses, scénarios et incertitudes. Les données sans source ou sans confirmation doivent être identifiées comme telles.

### Analyse des lacunes (`discovery.gaps`)
Comparer les compétences ou prérequis disponibles à ceux nécessaires à un cursus, une fonction professionnelle ou un projet. Les définitions de lacunes doivent être structurées et reliées à Progress lorsque requis.

### Horizons et scénarios (`discovery.horizons`)
Explorer l'évolution historique et des scénarios d'horizons 2030, 2040 et 2050 lorsque pertinent. Les scénarios sont des trajectoires conditionnelles, pas des prédictions certaines ; leurs projections doivent conserver sources et hypothèses.

### Fiches de découverte (`discovery.sheet`)
Enregistrer durablement une découverte avec son contexte et permettre de la convertir en activité d'apprentissage ou de la relier à un projet.

## 5.5 Progress — Mesurer la progression réelle

### Tableaux de progression (`progress.dashboards`)
Afficher des vues journalières, hebdomadaires, mensuelles et des trajectoires plus longues, adaptées aux données disponibles.

### Preuves (`progress.evidence`)
Conserver les éléments qui étayent les états de compétence ou les résultats. Les preuves ont un propriétaire, une provenance et une règle de production explicites ; aucune synthèse ne doit inventer une preuve absente.

### Analyse causale (`progress.cause`)
Explorer les facteurs susceptibles d'être associés à un résultat. Distinguer corrélation et causalité ; signaler les données insuffisantes et les limites de l'analyse.

### Trajectoires conditionnelles (`progress.trajectories`)
Examiner des scénarios sous certaines hypothèses, détecter l'oubli ou la fragilité des acquis lorsque les signaux nécessaires existent, et proposer des actions. Les trajectoires sont des aides à la décision, pas des garanties de résultat.

## 5.6 Agent Kernel — Coordination de l'IA

**Responsabilité :** comprendre la demande, assembler le contexte autorisé, planifier, choisir des capacités enregistrées, exécuter les actions permises, vérifier le résultat et le rattacher à l'initiative concernée.

La boucle fonctionnelle de référence est :

1. Comprendre l'intention et le résultat recherché.
2. Récupérer le contexte utile avec les règles d'accès applicables.
3. Identifier contraintes, inconnues et besoins de clarification.
4. Choisir les capacités nécessaires et planifier les étapes.
5. Présenter une proposition ou exécuter les actions autorisées.
6. Demander confirmation quand une action l'exige.
7. Vérifier ce qui a réellement été produit ou modifié.
8. Enregistrer résultat, échecs et informations utiles pour la suite.
9. Relier artefacts, décisions et prochaines étapes au projet.

Les rôles Planner, Coach, Tutor, Researcher et Executor sont des capacités ou modes du noyau, pas nécessairement des services autonomes distincts. Les modules restent propriétaires de leurs données et actions métier. L'Agent Kernel ne doit pas écrire directement dans toutes les entités.

Exigences transversales : appels d'outils typés, autorisations explicites, limites de coût et de temps, traçabilité, reprise d'erreur, gestion des tâches longues, vérification des actions critiques et absence de fausse confirmation de succès.

## 5.7 Scientific Engine — Calculer et vérifier

Capacités fonctionnelles prévues :

- représentation et affichage de formules et équations ;
- calcul numérique et conversions ;
- unités et vérifications dimensionnelles ;
- opérations symboliques prises en charge (simplification, factorisation, dérivation, intégration et résolution) ;
- algèbre linéaire et fonctions mathématiques/scientifiques ;
- validation ou vérification d'expressions, selon les moteurs et contrats disponibles.

Les calculs déterministes doivent être produits par un moteur approprié, pas uniquement par le texte d'un LLM. Les unités, domaines de validité, hypothèses et limites doivent être exposés. Le choix final des moteurs interchangeables demeure un arbitrage technique pour l'étape de stack.

## 5.8 Artifact — Consulter et exporter les productions

### Aperçu
Afficher uniquement les formats réellement pris en charge. Si un format ne peut pas être prévisualisé, il reste téléchargeable ou exportable selon le cas, mais l'interface ne doit pas simuler un aperçu fonctionnel.

### Export
Produire les formats disponibles pour les documents, fiches, graphiques et autres artefacts. Un export doit avoir un statut, une provenance, des métadonnées raisonnables et un résultat vérifié. Les opérations longues sont traitées comme des jobs et ne doivent pas bloquer l'interface.

### Gestion des artefacts
Conserver le lien entre une production, son projet, ses sources, son format de travail, ses rendus et ses versions. Un PDF exporté n'est pas la même chose que la source éditable ayant servi à le créer.

## 5.9 Integrations — Services externes et automatisations

### Automatisations
Planifier et exécuter des tâches différées via un système de jobs persistés, reprenables, idempotents et observables. Une automatisation doit avoir un déclencheur, une action, un état, des permissions et un moyen de désactivation compréhensible.

### Intégrations
Connecter les services externes au travers d'adaptateurs définis. La disponibilité d'un fournisseur ne doit pas être supposée ; les erreurs, limites, coûts et permissions doivent être présentés.

### Notifications
Combiner notifications locales et serveur selon des règles évitant le doublon, en respectant les permissions système et les préférences de l'utilisateur.

## 5.10 Identity — Identité, contexte et sécurité

Capacités prévues : authentification, profil et contexte utilisateur, préférences, thèmes, horaires de silence, préférences d'intervention, contrôle d'accès et isolation des données.

L'expérience entreprise peut nécessiter plus tard organisations, rôles, accès par projet, SSO et administration centralisée. Ces capacités doivent être classées distinctement si elles ne sont pas intégrées dans la première version.

## 5.11 Design System, données et services partagés

Ces éléments sont des fondations techniques et UX plutôt que de nouveaux modules de produit :

- langage visuel commun, composants, thèmes, tokens et états de contrôle ;
- contrats métier et validation de données ;
- services d'accès aux données et de synchronisation ;
- gestion des fichiers et actifs ;
- tâches longues, files de traitement et reprise ;
- observabilité, diagnostics et gestion des erreurs ;
- gestion de modèles IA, routage, budgets et politiques ;
- permissions, confidentialité, configuration et intégrations de plateforme.

Le présent document ne ratifie pas la technologie de chacune de ces fondations. Les choix déjà mentionnés dans les anciens documents doivent être distingués des nouveaux choix qui dépendront du Web-first.

---

# 6. Design Space Pro — spécification fonctionnelle

## 6.1 Mission

Design Space Pro permet de produire des créations et documents professionnels cohérents, éditables, révisables et exportables à partir d'un brief, de ressources de référence et éventuellement d'une identité de marque existante.

Le premier périmètre couvre :

1. identité et système de marque ;
2. logos et déclinaisons vectorielles ;
3. chartes graphiques et guides de marque ;
4. affiches et supports promotionnels ;
5. documents professionnels multipages ;
6. cohérence, validation, versions et export.

Les studios vidéo, 3D, musique et création avancée de sites Web ne sont pas réputés inclus simplement parce qu'ils apparaissent dans la vision cible. Ils seront détaillés dans les phases correspondantes de la roadmap.

## 6.2 Projet de marque et Brand DNA

Le Brand DNA est une représentation structurée et versionnée de l'identité d'une marque. Ce n'est ni uniquement un logo, ni un PDF de charte, ni un simple répertoire de couleurs. C'est la source de référence qui alimente les rendus et les documents dérivés.

### Contenu fonctionnel du Brand DNA

**Stratégie :** nom, description, mission, positionnement, audience, contexte de marché, différenciation et promesse lorsque les informations sont disponibles.

**Personnalité et expression :** valeurs, personnalité, ton, vocabulaire, messages clés, slogan ou règles de rédaction.

**Identité visuelle :** logos et variantes, palettes, typographies, iconographie, styles d'image, grilles, marges et principes de composition.

**Règles d'usage :** variantes sur fonds clairs ou foncés, proportions, tailles minimales, espaces de protection, usages à éviter, contraste et lisibilité.

**Identité numérique :** lorsqu'elle est utile, design tokens, composants de base, états, styles d'interface et règles de réutilisation.

**Provenance et version :** source de chaque décision importante, auteur/modificateur, date, différence avec la version précédente et productions concernées.

Tous les champs ne sont pas obligatoires pour toutes les marques. Aurora doit distinguer information fournie, proposition générée, décision acceptée et information inconnue. Les assertions stratégiques ne doivent pas être présentées comme des faits de marché sans sources.

## 6.3 Parcours de création de marque

1. **Comprendre le brief** — obtenir le nom, le secteur, l'offre, l'audience, le contexte, les contraintes, les références et les livrables attendus.
2. **Identifier les inconnues** — demander uniquement les précisions qui influencent réellement les choix suivants et étiqueter les hypothèses.
3. **Explorer** — lorsque demandé, rechercher le marché ou les références, conserver les sources et distinguer les observations des recommandations.
4. **Formaliser le Brand DNA** — proposer une stratégie et une direction de marque structurées.
5. **Présenter des directions** — fournir plusieurs options différenciées et leurs compromis, sans présenter un résultat généré comme déjà accepté.
6. **Créer les actifs initiaux** — logo, palette, typographies, grille et règles de base.
7. **Vérifier et modifier** — laisser l'utilisateur corriger et verrouiller des éléments ; conserver les versions.
8. **Produire la charte et les supports** — générer les documents à partir de la version du Brand DNA retenue.
9. **Contrôler et exporter** — vérifier la cohérence, la lisibilité, les formats et les ressources ; signaler les limites restantes.
10. **Faire évoluer la marque** — proposer les productions potentiellement affectées par une modification, sans les réécrire sans accord.

## 6.4 LOGO Studio — chaîne technique fonctionnelle

### Objectif
Produire des logos vectoriels structurés et modifiables, plutôt que des images pixelisées difficiles à reprendre.

### Pipeline fonctionnel

1. Recevoir l'intention, le brief ou une image de référence.
2. Construire une représentation sémantique de la composition : formes, hiérarchie, objets, contraintes, thème et relations entre calques.
3. Générer ou compiler une structure vectorielle et des paramètres géométriques.
4. Rendre la sortie intermédiaire pour inspection.
5. Utiliser le retour visuel pour corriger le résultat et rejeter les éléments dégénérés, répétitifs ou sans effet utile.
6. Normaliser, canonicaliser et optimiser le SVG.
7. Comparer le rendu avant/après optimisation afin de détecter les régressions visuelles.
8. Présenter le logo à l'utilisateur, permettre l'édition et conserver le format source.
9. Exporter les formats confirmés comme pris en charge ; les déclinaisons multi-ratios et multi-palettes demeurent des capacités à implémenter/évaluer selon le rapport LOGO.

### Règles de représentation

- Séparer structure et paramètres numériques ; ne pas dégrader inutilement la précision des valeurs géométriques.
- Organiser le logo en calques et formes sémantiques identifiables.
- Maintenir l'ordre de rendu explicite lorsque les couches se recouvrent.
- Garder les objets utiles individuellement éditables.
- Valider la syntaxe, les coordonnées et le rendu visuel.
- Ne pas garantir qu'un logo soit juridiquement disponible ou distinct de toutes les marques existantes sans une recherche adaptée.

### Périmètre initial documenté dans la recherche

Wordmarks, monogrammes et icônes simples constituent le périmètre initial proposé par le rapport LOGO. La prise en charge de compositions beaucoup plus complexes, la correction optique automatisée et certaines déclinaisons avancées doivent faire l'objet de tests supplémentaires.

## 6.5 AFFICHE Studio — affiches, chartes et documents visuels

### Objectif
Créer affiches et documents visuels en conservant une structure éditable : contenu, géométrie, style, ordre des calques et identité de marque.

### Pipeline recommandé

1. Analyser le brief, le public, le canal, le format et l'objectif.
2. Identifier la catégorie de style ou laisser l'utilisateur la sélectionner.
3. Construire ou réutiliser la charte de marque.
4. Planifier la composition avant de générer les calques.
5. Définir fond, contenu, texte, actifs graphiques, sous-couches de lisibilité et ordre de rendu.
6. Produire une représentation structurée du layout, avec coordonnées normalisées lorsque cela convient au format.
7. Appliquer un validateur déterministe aux contraintes objectives.
8. Présenter un rendu dans un éditeur où l'utilisateur peut modifier les calques manuellement ou via une instruction.
9. Permettre de verrouiller des attributs choisis afin que les tours d'amélioration ne les modifient pas.
10. Raffiner avec une boucle plafonnée et un critère d'arrêt explicite ; ne pas itérer indéfiniment sans gain.
11. Exporter la structure éditable et les formats de sortie pris en charge.

### Validation déterministe

Le validateur peut vérifier, selon les formats et règles retenus :

- dimensions, positionnement et éléments hors-canevas ;
- chevauchement d'éléments qui ne doivent pas se superposer ;
- ordre des calques et sous-couches ;
- alignements et utilisation de l'espace ;
- cohérence de la charte et du style ;
- contraste et lisibilité du texte par rapport à son fond local ;
- densité ou complexité du layout ;
- présence des éléments obligatoires ;
- non-régression du rendu après transformation ou optimisation.

Les contrôles qui restent subjectifs — attrait esthétique, adéquation stratégique ou préférence de marque — doivent être présentés comme des évaluations assistées, pas des vérités déterministes.

### Brand kit multiproductions

Les documents liés à une marque héritent du thème racine, mais peuvent avoir des spécialisations contrôlées selon leur usage. Une affiche de campagne et un guide interne partagent l'identité sans devoir reprendre exactement le même layout. Le modèle doit enregistrer les règles héritées et les surcharges propres au document.

## 6.6 Document Studio — publications professionnelles multipages

### Types de livrables visés

- chartes graphiques détaillées et guides de marque ;
- dossiers de présentation et documents commerciaux ;
- rapports professionnels ;
- guides de procédures ou d'utilisation ;
- documents de référence structurés ;
- autres publications multipages compatibles avec les formats effectivement supportés.

La longueur peut aller d'un document court à une publication de plusieurs dizaines de pages, y compris la cible évoquée de 20 à 100 pages pour une charte complète lorsque la quantité d'information le justifie. Le nombre de pages ne doit pas être utilisé comme indicateur artificiel de qualité.

### Pipeline documentaire

1. Construire le plan et la hiérarchie des sections.
2. Recueillir ou générer le contenu en indiquant les sources, hypothèses et champs restant à compléter.
3. Définir le style éditorial à partir du Brand DNA ou d'un thème de document.
4. Créer le système de mise en page : grille, marges, styles de titres, corps, listes, tableaux, encadrés, images, figures et numérotation.
5. Produire le contenu page par page avec continuité éditoriale et sans répétitions inutiles.
6. Contrôler la structure, les références internes, les titres, les renvois, la cohérence du vocabulaire et les éléments requis.
7. Vérifier la pagination, les coupures de paragraphes, les tableaux, les images, les contrastes et l'équilibre des pages.
8. Permettre la modification du contenu, des styles et des calques éditoriaux.
9. Effectuer une revue finale et produire un rapport des points non résolus.
10. Exporter les formats confirmés et conserver la source éditable.

### Exigences de contenu

- Ne pas inventer les données de l'entreprise, chiffres, politiques ou décisions qui n'ont pas été fournis ou vérifiés.
- Distinguer les contenus proposés, les contenus validés par l'utilisateur et les contenus étayés par une source.
- Maintenir la cohérence des informations répétées entre sections.
- Vérifier qu'une modification du Brand DNA n'entraîne pas une mise à jour silencieuse de documents déjà approuvés.
- Pour les documents scientifiques ou techniques, préserver les références et les limites du résultat ; une belle mise en page ne valide pas la science.

## 6.7 Édition et interaction utilisateur

Le studio doit permettre, selon le format :

- sélection et édition d'un calque ou d'un bloc ;
- déplacement, redimensionnement, rotation, alignement et réorganisation ;
- modification du texte, des styles et des actifs ;
- verrouillage d'un contenu, d'une position, d'une taille, d'une couleur ou d'un autre attribut disponible ;
- sélection d'une partie du document comme contexte d'une instruction IA ;
- comparaison des variantes et retour à une version antérieure ;
- aperçu du rendu à différents formats lorsque cela est pris en charge ;
- affichage des problèmes du validateur et application ou refus des corrections proposées.

L'IA ne doit pas écraser un document complet lorsque seule une partie a été sélectionnée pour modification. Elle doit proposer un delta contrôlable ou une nouvelle version et préserver les modifications manuelles qui sont verrouillées.

## 6.8 Gestion des versions et cohérence de marque

Chaque version publiée ou exportée doit référencer la version de Brand DNA utilisée, les sources et actifs dépendants lorsque pertinent, les modifications et les résultats de validation.

Une modification de logo, de palette ou de typographie doit déclencher une analyse des conséquences possibles. Aurora peut identifier les productions affectées et proposer leur révision ; il ne doit pas réécrire silencieusement les fichiers approuvés.

## 6.9 Exports — règles fonctionnelles

Les formats définitifs sont à arbitrer avec la stack et les moteurs retenus. Les exigences de principe sont :

- conserver le format éditable natif ou structuré quand il existe ;
- fournir un rendu final dans les formats pris en charge ;
- distinguer fichier source et fichier de distribution ;
- vérifier l'ouverture, les dimensions et les ressources essentielles de l'export ;
- ne jamais afficher un format comme disponible avant le test réel de sa chaîne d'export ;
- informer l'utilisateur des éléments non transférés ou convertis ;
- conserver la relation entre export et version source.

---

# 7. Modèle universel de projet

## 7.1 Principe

**Un contexte de projet durable ; plusieurs capacités spécialisées ; plusieurs chemins possibles vers un résultat.** Le projet est le fil de continuité du travail utilisateur, mais ne remplace pas tous les modules métier ni leurs sources de vérité.

## 7.2 Distinctions de vocabulaire

- **Initiative :** l'effort global pour atteindre un résultat, par exemple lancer une marque ou concevoir un produit.
- **Workspace / espace de travail :** l'expérience de travail sur cette initiative ; ce nom ne signifie pas nécessairement une entité de données distincte.
- **Projet de productivité :** l'objet de tâches, jalons, ressources et échéances, lié à une initiative quand nécessaire.
- **Objectif :** un état souhaité, éventuellement relié à plusieurs projets et activités.
- **Artefact/livrable :** une production identifiable et versionnable : brief, recherche, logo, affiche, document, prototype ou export.
- **Prototype :** un livrable d'exploration ou d'essai dont le niveau de maturité est indiqué.
- **Parcours d'apprentissage :** les activités nécessaires au développement de compétences ; Aurora gère le besoin contextualisé et Cyforge peut fournir un parcours approfondi lorsque l'intégration est disponible et autorisée.

**À ne pas faire avant audit :** créer immédiatement une nouvelle entité racine ou un nouveau package sans examiner les concepts existants, notamment projets, objectifs et entités `GoalProject`, `SubGoal`, `FeaturePlacement` et `GoalProgress` mentionnées dans les documents antérieurs.

## 7.3 Cycle de vie adaptable

### A. Formuler
Clarifier le problème, l'intention, les personnes concernées, le résultat recherché et les contraintes. Résultat : brief initial versionné.

### B. Explorer
Rechercher des sources, comparer des approches, identifier hypothèses, risques, inconnues et questions ouvertes. Résultat : dossier d'exploration traçable.

### C. Apprendre au besoin
Identifier les compétences utiles à la prochaine étape, proposer une explication ou une activité concise et, le cas échéant, relier à Cyforge. Résultat : besoins d'apprentissage contextualisés.

### D. Définir
Formaliser périmètre, exigences, contraintes, critères de réussite, architecture de conception ou plan de test. Résultat : spécification suffisante pour commencer un prototype.

### E. Concevoir et prototyper
Choisir le moteur adapté et créer un ou plusieurs résultats manipulables, examinables et versionnés. Résultat : prototype avec limites et sources identifiables.

### F. Vérifier
Comparer les résultats aux exigences, exécuter les contrôles disponibles et collecter les retours. Résultat : état de validation, problèmes, décisions et incertitudes restantes.

### G. Organiser et réaliser
Convertir le travail en objectifs, tâches, jalons et dépendances ; préparer un paquet de transfert si le travail continue ailleurs. Résultat : plan d'exécution exploitable.

### H. Évaluer et faire évoluer
Prendre en compte les retours, mettre à jour les hypothèses, décider d'une nouvelle version ou clôturer l'initiative. Résultat : décision de suite fondée sur ce qui a été appris.

Ce cycle n'est pas un tunnel obligatoire. Un utilisateur peut commencer directement par une affiche, sauter la recherche, revenir à la définition ou itérer entre conception et vérification.

## 7.4 Objets conceptuels à couvrir

Sans présumer de tables ou types définitifs, le modèle fonctionnel doit permettre de représenter :

1. profil et identité de l'initiative ;
2. briefs et versions ;
3. questions, hypothèses, contraintes, exigences et critères d'acceptation ;
4. recherches, extraits, sources et références ;
5. décisions et raisons ;
6. artefacts et prototypes versionnés ;
7. tests, validations, retours et résultats ;
8. plan de réalisation et tâches reliées ;
9. compétences et besoins d'apprentissage ;
10. exécutions d'agent, statut et traces utiles ;
11. paquet de transfert ;
12. associations à une marque, un Brand DNA ou une bibliothèque d'actifs si le domaine l'exige.

## 7.5 Propriété des données

Le Workspace relie les objets, mais chaque module reste propriétaire des données relevant de sa compétence. Les tâches appartiennent à Productivity ; les états de compétences à Progress ; les connaissances structurées à Knowledge ; les recherches à Discovery ; les productions à leurs domaines de création et au gestionnaire d'artefacts selon le contrat retenu. L'Agent Kernel orchestre par des capacités définies plutôt que par des écritures directes transversales.

## 7.6 Paquet de transfert

Un transfert vers un outil, un développeur ou une autre équipe doit conserver ce qui est nécessaire pour poursuivre le travail : brief et versions utiles, exigences, décisions, sources, versions des artefacts, ressources, actifs, format source, contraintes connues, tests, état de validation et prochaines étapes. Le paquet doit préciser ce qu'il inclut, ce qui manque et ce qui doit être reconstruit dans l'outil cible.

Le futur transfert vers des outils de développement, tels que Claude Code ou Codex, relève de la vision d'Aurora. Il ne fait pas partie du premier studio Design Space Pro au même niveau qu'un logo ou une affiche, sauf si une capacité d'export correspondante existe déjà et passe les tests de bout en bout.

## 7.7 Cyforge

Cyforge reste un produit distinct d'apprentissage augmenté. Aurora peut identifier un besoin d'apprentissage et, avec consentement et permissions explicites, relier l'utilisateur à une ressource ou un parcours Cyforge. Il ne doit pas dupliquer intégralement le système de parcours de Cyforge. Toute synchronisation de compétences, objectifs ou progression doit être spécifiée, autorisée et réversible selon les règles de confidentialité applicables.

---

# 8. Architecture fonctionnelle et stack de référence

Les sections 8.1 à 8.6 décrivent les responsabilités fonctionnelles indépendamment des outils. Les sections 8.7 à 8.11 consignent la stack de référence choisie, la topologie applicative proposée et les bibliothèques retenues ou à tester. Les décisions « sélectionnées » doivent néanmoins être confrontées au dépôt, aux versions réellement publiées et aux tests de compatibilité.

## 8.1 Couches fonctionnelles

1. **Surfaces utilisateur** — interface Web responsive d'abord, Desktop ensuite, Mobile ensuite.
2. **Navigation et contexte actif** — persona, projet courant, recherche, commande, état d'édition et filtres.
3. **Workspace / relation de projet** — brief, décisions, artefacts, versions et références vers les modules propriétaires.
4. **Agent Kernel / orchestration** — intention, contexte, plan, capacités, exécution, vérification et résultat.
5. **Modules métier** — productivité, apprentissage, connaissances, découverte, progression, science, artefacts, intégrations et identité.
6. **Moteurs spécialisés** — logo vectoriel, mise en page, document multipages et futurs moteurs 3D, vidéo, musique ou Web.
7. **Services partagés** — fichiers, tâches longues, notifications, synchronisation, modèles IA, logs, politiques et permissions.
8. **Stockage et intégrations** — persistance, recherche, fichiers et services externes derrière des contrats d'accès.
9. **Validation et qualité** — tests métier, validation déterministe, vérification du rendu et revue humaine là où elle est nécessaire.

## 8.2 Contrat d'un moteur spécialisé

Chaque studio ou moteur doit déclarer au minimum :

- domaine et cas d'utilisation ;
- types de demande acceptés ;
- données d'entrée et ressources nécessaires ;
- résultat structuré et format source ;
- formats de sortie ;
- capacités d'édition manuelle ;
- stratégie de versionnement ;
- validations automatiques disponibles ;
- limites et risques ;
- coût/temps estimé lorsque mesurable ;
- permissions et données manipulées ;
- états de succès, d'échec, d'annulation et de reprise ;
- tests prouvant la chaîne de bout en bout.

## 8.3 Orchestration IA et outils

Le modèle IA ne doit pas être choisi uniquement à partir de mots-clés. Les profils de tâches doivent distinguer par exemple la recherche, le raisonnement, l'analyse visuelle, la génération de structure, la révision de contenu et la validation. Les secrets d'accès aux fournisseurs ne doivent jamais être exposés au client. Les coûts et les limites de traitement sont suivis selon le budget de la plateforme.

L'Agent Kernel peut proposer un plan, mais doit exécuter uniquement les capacités exposées par les modules, avec leurs permissions et confirmations. Les opérations longues sont gérées hors du cycle bloquant de l'interface. Les échecs sont persistés et visibles ; l'agent ne prétend pas qu'une action est réussie avant la confirmation du moteur concerné.

## 8.4 Architecture d'édition structurée

La création professionnelle devrait séparer :

- l'intention et le brief ;
- la représentation sémantique ;
- la structure éditable (calques, objets, paramètres, styles) ;
- le rendu ;
- les résultats de validation ;
- les exports ;
- l'historique des modifications.

Cette séparation est particulièrement importante pour LOGO et AFFICHE. Pour les futurs domaines, le format sera adapté : les propriétés d'une timeline vidéo diffèrent des paramètres d'un modèle 3D ou d'une interface Web. Il ne faut pas imposer un format universel unique à toutes les formes de création.

## 8.5 Données, événements et tâches longues

PowerSync est choisi pour éviter de reconstruire intégralement le moteur complexe de synchronisation. Ce choix ne supprime pas le travail d'intégration : Aurora doit encore définir le schéma local, les sync rules, le connecteur d'upload, l'acquisition et le renouvellement des credentials, les autorisations, les politiques RLS, les migrations, le comportement des conflits métier et les scénarios de récupération. Ces responsabilités doivent être prouvées par des tests sur chaque surface cible.

Les opérations lourdes doivent rester persistées, observables et reprenables sans bloquer l'interface. Les événements doivent être réservés aux flux où ils apportent une valeur claire ; ils ne remplacent pas automatiquement les commandes transactionnelles simples.

## 8.6 Règles de séparation des modules

- Un module possède ses propres objets et règles métier.
- Les autres modules lisent ou agissent par des contrats explicites.
- Les moteurs spécialisés ne réimplémentent pas les fonctions générales d'identité, de permissions, de projets ou de stockage.
- Le gestionnaire d'artefacts ne se substitue pas au moteur qui édite l'artefact.
- Le Workspace ne devient pas une base de données parallèle qui duplique toutes les sources de vérité.
- Toute nouvelle entité, tout événement partagé ou toute dépendance structurelle doit faire l'objet d'une décision documentée.


## 8.7 Stack de référence retenue par le propriétaire du produit

### 8.7.1 Principes

La stack retenue vise à réutiliser les briques existantes, éviter de réécrire des mécanismes d'infrastructure difficiles et conserver une architecture TypeScript commune lorsque c'est pertinent. Elle ne signifie pas que chaque bibliothèque doit être importée partout : chaque brique doit avoir un propriétaire et une responsabilité unique.

- **TypeScript** est le langage principal des applications, des contrats métier et des outils d'orchestration lorsque le domaine ne nécessite pas un moteur spécialisé différent.
- **Ionic React** fournit les composants et l'expérience de l'application métier Web responsive ; il ne remplace pas le modèle métier d'Aurora.
- **Capacitor** est réservé à la future enveloppe Mobile et aux fonctions natives nécessaires à cette plateforme.
- **Electron** est retenu pour la phase Desktop, sous réserve de tests du rendu des éditeurs et d'une conception sécurité stricte.
- **Next.js** est conservé dans la stack. Pour éviter deux routeurs dans une même application, la topologie de référence proposée l'affecte au site public (présentation, pages SEO et documentation publique) tandis que l'application métier connectée reste une application Ionic React avec sa navigation React Router. Si le propriétaire préfère que Next.js porte également l'application métier, il faudra choisir explicitement l'usage des composants Ionic sans `IonReactRouter`, puis prouver le build destiné à Capacitor et Electron.
- **Supabase/PostgreSQL** constitue la base de données principale côté serveur, avec les fonctions Supabase retenues pour l'authentification, les politiques d'accès, le stockage ou l'exécution côté serveur lorsque cela convient.
- **PowerSync + SQLite** constitue le mécanisme choisi pour les données métier synchronisées et utilisables hors ligne. SQLite n'est pas une seconde source de vérité serveur : il s'agit de la base locale synchronisée par PowerSync.
- **Zod** constitue le socle de validation runtime des entrées/sorties TypeScript, des formulaires, des outils d'agent, des réponses d'intégration et des données structurées générées par les modèles.
- **Agent Aurora** est l'orchestrateur central visible dans l'application. Les sous-agents sont déclenchés conditionnellement lorsque le workflow le justifie ; les modules métier restent propriétaires de leurs données et exposent des capacités typées.

### 8.7.2 Topologie recommandée du monorepo

La structure suivante est une proposition de responsabilités, pas une obligation de noms de répertoires si le dépôt courant impose déjà une organisation équivalente.

```text
apps/
  marketing/        # Next.js : site public, SEO, présentation, pages publiques
  web-app/          # Ionic React : application connectée et responsive
  desktop/          # Electron : conteneur Desktop et accès système contrôlé
  mobile/           # Capacitor : à construire après Web et Desktop
  server/           # fonctions serveur/API/Agent Kernel/jobs si le dépôt les sépare ainsi
packages/
  domain/           # types et invariants métier canoniques
  contracts/        # schémas Zod, DTO et contrats des capacités
  data/             # repositories, PowerSync, clients de données et migrations
  ui/               # composants communs compatibles avec leurs hôtes
  design-system/    # tokens, thèmes, primitives et règles de marque
  agent/            # contrats et client UI ; secrets et exécution privilégiée côté serveur
  modules/          # capacités métier, réparties en packages si l'existant le prévoit
  design-engines/   # contrats des moteurs LOGO, AFFICHE et documentaires
```

**Règle de coexistence Next.js/Ionic React.** Ionic React utilise habituellement `IonReactRouter`, bâti sur React Router ; Next.js possède son propre routeur App Router. La topologie de référence les sépare donc en deux applications frontales partageant des contrats et des tokens, sans tenter de placer les deux systèmes de navigation dans le même arbre d'application. Le coût de cette séparation (deux builds/deux déploiements) doit être accepté explicitement. Si le dépôt ou les besoins commerciaux favorisent une unique application Next.js avec composants Ionic, ce choix devient un ADR à instruire avant l'implémentation du shell.

**Règle de réutilisation.** Les contrats métier, schémas, clients de service, règles de validation et tokens peuvent être partagés ; le code qui dépend d'une API native, d'un environnement serveur Next.js ou du cycle de vie Ionic doit rester dans une couche adaptée à sa plateforme.

### 8.7.3 Responsabilités et décisions associées

| Brique | Responsabilité ciblée | Décision de référence | Porte de validation |
|---|---|---|---|
| TypeScript | Langage, types, contrats partagés | Retenu | Configuration stricte et tests de compilation dans tous les packages. |
| Ionic React | Application métier responsive | Retenu | Navigation, accessibilité, grands écrans, petits écrans et éditeurs testés. |
| Capacitor | Mobile ultérieur et plugins natifs | Retenu pour la phase Mobile | Vérifier les plugins réellement nécessaires et le build des assets locaux. |
| Electron | Conteneur Desktop | Retenu pour la phase Desktop | Vérifier impression, fichiers, presse-papiers, rendu et sécurité IPC. |
| Next.js | Site public ; éventuellement alternative à arbitrer pour le shell métier | Retenu, périmètre proposé | Décider la séparation `marketing`/`web-app` avant les implémentations du shell. |
| Supabase/PostgreSQL | Persistance serveur, auth, RLS et fonctions | Retenu | Audit des schémas existants, migrations, sauvegarde et règles RLS. |
| PowerSync/SQLite | Synchronisation et stockage local des tables choisies | Retenu | Prototype réel Web, puis tests Desktop/Mobile avant de promettre une compatibilité uniforme. |
| Zod | Validation runtime partagée | Retenu | Schémas alignés sur les contrats serveur et versions TypeScript. |
| Agent Aurora | Orchestration principale des capacités | Retenu | Permissions, trace d'exécution, confirmation, annulation, coûts et vérification. |
| Chaînes multi-agents | Décomposition des tâches complexes | Retenues comme stratégie sélective | Un gain mesurable doit justifier les agents supplémentaires ; pas un agent par module par défaut. |

### 8.7.4 Sécurité Electron et limites des clients

Electron ne doit pas être utilisé comme un simple navigateur avec des privilèges Node ouverts. Les fenêtres de rendu doivent activer l'isolation de contexte et le sandboxing, désactiver l'intégration Node pour le contenu non fiable, limiter navigation et fenêtres secondaires, appliquer une Content Security Policy et valider l'émetteur de chaque message IPC. Les secrets Supabase privilégiés, les clés fournisseurs IA et les fonctions d'administration ne doivent pas être intégrés dans le bundle client.

Les APIs des modules doivent vérifier l'identité et les droits côté serveur ; une validation Zod côté client améliore l'expérience mais ne remplace pas la validation serveur, les politiques RLS ou les autorisations d'outils.

## 8.8 Données : PowerSync, SQLite, PostgreSQL et état applicatif

### 8.8.1 Ce que PowerSync prend en charge et ce qu'Aurora doit encore coder

PowerSync est choisi précisément pour ne pas avoir à réimplémenter toute la mécanique de synchronisation offline-first. Il fournit la couche de synchronisation et le stockage SQLite client pour les tables configurées. Il ne décide cependant pas à la place d'Aurora quelles données l'utilisateur a le droit de recevoir, comment une modification métier est autorisée, quelle stratégie de conflit convient à chaque entité ni comment une action serveur doit être validée.

Le travail d'intégration Aurora comprend au minimum :

1. définir le schéma des tables synchronisées et les migrations ;
2. définir les sync rules/streams et la minimisation des données par utilisateur/projet ;
3. implémenter le connecteur PowerSync qui récupère des credentials et transmet les batches locaux au backend ;
4. valider les écritures côté serveur et appliquer RLS/permissions ;
5. documenter les conflits métier, les suppressions, les changements d'accès et les migrations ;
6. tester perte réseau, reprise, doublons, mises à jour concurrentes, changement de compte et révocation d'accès ;
7. observer retards, échecs de sync et erreurs de désérialisation sans exposer de données privées dans les logs.

La règle de source de vérité est la suivante : **PostgreSQL est la source serveur ; SQLite via PowerSync est la base locale synchronisée ; la mémoire de l'interface ne constitue pas une source de vérité supplémentaire.** Les fichiers lourds peuvent être conservés dans le stockage objet et référencés par des métadonnées synchronisées.

### 8.8.2 Séparer trois types d'état

- **Données métier synchronisées** (projets, tâches, ressources choisies, préférences/entités prévues offline) : lecture et mises à jour selon les contrats PowerSync/SQLite.
- **Ressources distantes non synchronisées** (recherches à la demande, résultats de fournisseurs externes, informations d'état d'un job, coûts ou métadonnées de services) : TanStack Query peut assurer cache, retries, invalidation et rafraîchissement lorsque ces responsabilités ne sont pas déjà couvertes par un autre client.
- **État éphémère d'interface/éditeur** (sélection active, panneau ouvert, outil de dessin, zoom, aperçu temporaire) : état local du composant ou du moteur d'édition ; ne pas écrire chaque mouvement de souris dans la base métier. Les points de sauvegarde et autosaves restent explicites.

Ne pas faire de TanStack Query un deuxième cache autoritaire pour les mêmes entités synchronisées par PowerSync. Les règles de mutation doivent avoir un seul propriétaire clair.

### 8.8.3 TanStack DB relié à PowerSync : opportunité à tester

L'écosystème TanStack fournit une intégration nommée `@tanstack/powersync-db-collection`/PowerSync Collection. Elle peut exposer les données SQLite dans des collections réactives, fournir des live queries, des jointures, des mises à jour optimistes et une annulation automatique en cas d'erreur. Cela pourrait réduire le code d'affichage et de requête dans les tableaux et listes des modules Aurora.

**Statut : POC obligatoire, pas dépendance critique au démarrage.** La documentation TanStack classe TanStack DB en bêta et la documentation PowerSync indique l'intégration TanStack DB comme alpha. L'intégration introduit aussi une représentation réactive en mémoire au-dessus des données SQLite. La décision doit comparer la simplicité gagnée, le comportement de cache, les transactions, la gestion des erreurs, les gros volumes et la compatibilité multiplateforme. Commencer par une collection limitée (par exemple tâches/projets), puis généraliser uniquement si les tests démontrent un bénéfice net.

## 8.9 Audit de l'écosystème TanStack

L'écosystème TanStack fournit des briques spécialisées ; ce n'est pas une suite qu'il faut installer en totalité. Le catalogue officiel consulté le 24 octobre 2026 comprend notamment Start, Router, Query, DB, AI, Store, Table, Charts, Form, Markdown, Highlight, Virtual, Pacer, Hotkeys, Intent, Devtools et Config. La sélection ci-dessous est spécifique à Aurora.

### 8.9.1 Bibliothèques à adopter ou à préparer pour un usage réel

| Outil | Problème difficile qu'il évite | Usage Aurora | Statut et limites |
|---|---|---|---|
| **TanStack Form** | État de formulaire complexe, validation par champ/formulaire, erreurs sync/asynchrones, formes dynamiques | Briefs de marque, paramètres de projet, onboarding des personas, préférences et formulaires multi-étapes | **À adopter après intégration POC.** Sa validation accepte les bibliothèques Standard Schema, dont Zod. Vérifier accessibilité et intégration avec les composants Ionic. |
| **TanStack Query** | Cache des appels asynchrones, déduplication, retries, états de mutation, invalidation et rafraîchissement | APIs non synchronisées, recherches distantes, suivi de jobs et appels externes | **À utiliser de façon ciblée.** Pas de double cache autoritaire des lignes que PowerSync synchronise. |
| **TanStack Table** | Tri, filtrage, pagination, colonnes et état de grille sans imposer un design préfabriqué | Tables des tâches, ressources, artefacts, résultats de recherche, éléments de marque et registres de versions | **Candidat fort.** Headless : Aurora garde la responsabilité du markup, de l'accessibilité et du style. Valider la version publiée et l'intégration Ionic/Design System. |
| **TanStack Virtual** | Rendu coûteux de longues listes/grilles et de flux inversés | Historique de conversations, listes de fichiers/assets, ressources, tâches et logs d'exécution | **À adopter lorsqu'un écran atteint des volumes importants.** Il fournit le virtualizer, pas le composant visuel ; mesurer l'accessibilité et les hauteurs variables. |
| **TanStack Charts** | Définition typée et rendu responsif de graphiques SVG/Canvas | Tableaux de bord Progress, analytics personnels, métriques de jobs et graphiques de rapports | **À évaluer par un petit projet pilote.** La compatibilité stable débute à la version 1.0 selon la documentation ; les exports intégrés à un document nécessitent un pipeline de rendu propre. |
| **TanStack Markdown** | Parsing/rendu déterministe et contrôlé du Markdown, y compris des réponses IA en streaming | Messages de l'Agent Aurora, aperçus Markdown, contenu technique et documentation | **Candidat conditionnel.** Sa syntaxe supportée est un profil explicite, pas toute la spécification CommonMark/GFM. Vérifier la compatibilité avec les documents existants avant de remplacer le renderer en place. |
| **TanStack Highlight** | Coloration syntaxique légère de blocs de code | Réponses techniques de l'agent, documentation et extraits de code | **Option complémentaire** au rendu Markdown. Ce n'est pas un éditeur de code complet. |
| **TanStack Intent** | Charger des guides de bibliothèques versionnés dans le contexte des agents qui écrivent le code | Outiller Claude Code, Codex ou autres agents de développement pour qu'ils utilisent les APIs installées correctement | **Intérêt élevé côté développement, pas runtime.** Outil marqué alpha : l'utiliser avec liste d'autorisation, revue des instructions et validation des sources. |

### 8.9.2 Bibliothèques utiles à tester, sans les mettre d'office dans le chemin critique

| Outil | Utilité envisagée | Décision de prudence |
|---|---|---|
| **TanStack DB + PowerSync Collection** | Collections réactives, live queries, mises à jour optimistes et requêtes/jointures côté interface au-dessus de SQLite | **POC isolé.** DB est bêta et le connecteur PowerSync est signalé alpha dans la documentation PowerSync ; pas de généralisation avant tests. |
| **TanStack AI** | API TypeScript pour streaming de chat, outils typés, sorties structurées, adaptateurs de fournisseurs et médias | **POC pour la couche chat/tools/provider.** Il peut réduire du code de transport et d'appel d'outils, mais ne remplace pas le Kernel Aurora, les permissions, le workflow persistant, la mémoire métier, l'audit ou le budget des agents. Garder le Kernel indépendant du SDK. |
| **TanStack Pacer** | Debounce/throttle, limite de fréquence, file côté client et batch d'événements | **À piloter pour autosave, recherche instantanée et actions UI répétées.** Le package est bêta ; ne pas l'utiliser comme file durable côté serveur ni comme remplacement des jobs Supabase. |
| **TanStack Hotkeys** | Raccourcis typés avec scopes, libellés par OS, enregistrement et réglages utilisateur | **POC pour les éditeurs et Desktop.** Le package est bêta : tester AZERTY/QWERTY, raccourcis système, champs de saisie, dialogues, annulation/rétablissement et conflits. |
| **TanStack Store** | État réactif local partagé à granularité fine | **Reporter.** Le package est alpha et un store supplémentaire pourrait chevaucher l'état React, l'état du moteur d'édition ou la donnée PowerSync. Introduire seulement si un besoin mesuré l'impose. |
| **TanStack Ranger** | Primitives de curseurs/ranges personnalisés | **Reporter/optionnel.** Les composants Ionic peuvent suffire ; tester uniquement si Design Space a besoin de commandes fines impossibles à satisfaire avec le Design System. |
| **TanStack Devtools** | Panneau extensible pour déboguer les bibliothèques et outils internes | **Développement seulement, facultatif.** Le package est alpha ; utile pour un POC d'intégration, jamais une dépendance indispensable du runtime. |
| **TanStack Router** | Routage React typé, paramètres d'URL validés, loaders et préchargement | **Ne pas ajouter dans le shell Ionic de référence** : Ionic React utilise React Router. Il ferait aussi double emploi avec le routeur intégré à Next.js si on tentait de combiner les shells. Réévaluer seulement si la topologie de routage change. |
| **TanStack Start** | Framework React full-stack avec SSR, streaming, server functions et Router | **Ne pas ajouter avec Next.js par défaut.** Il résout une partie du même problème de framework ; il faudrait remplacer Next.js par Start, pas entretenir deux frameworks full-stack principaux. |
| **TanStack Config** | Outils de configuration utilisés par les projets TanStack (notamment ESLint, publication et Vite) | **Pas une dépendance métier.** Continuer avec la configuration du monorepo existant, sauf raison concrète de publier et maintenir des packages comme le fait l'écosystème TanStack. |
| **TanStack CLI** | Génération de projets/compléments TanStack Start/Router | **Ne pas l'utiliser pour scaffold la stack Aurora** puisque l'architecture choisie n'est pas fondée sur Start/Router. Vérifier sa maturité alpha avant tout essai. |

**Règle d'adoption TanStack :** faire une petite preuve par problème, comparer le gain au coût d'intégration, verrouiller les versions, consulter les notes de migration et n'ajouter le package au socle commun qu'après une revue. « On prend ce qui est utile » ne signifie pas installer tous les packages : les doublons de responsabilités fragilisent les données et augmentent la maintenance.

## 8.10 Autres briques utiles pour éviter de réimplémenter des mécanismes complexes

| Besoin complexe | Brique candidate | Application Aurora | Limites / revue obligatoire |
|---|---|---|---|
| Édition 2D et interactions sur canvas | **Fabric.js** | Toile d'affiches, composition de calques, positionnement, sélection, transformations et sérialisation | Favori pour AFFICHE d'après le rapport AFFICHE. Le modèle canonique doit rester indépendant de la version de la bibliothèque ; tester le round-trip JSON/SVG et la réouverture des anciens fichiers. |
| Logos vectoriels | **SVG structuré + SVGO** | Formes sémantiques, calques, déclinaisons, optimisation SVG | SVG est un format source, SVGO un optimiseur : conserver une version source éditable et comparer le rendu avant/après optimisation. Ne pas faire de la sortie pixelisée le seul artefact. |
| Édition de texte riche | **Tiptap/ProseMirror** | Édition des contenus des documents, titres, listes, tableaux, images et nœuds personnalisés | Le texte riche n'est pas à lui seul un système de publication multipages : pagination, mise en page, sauts de page, tables, notes, en-têtes et exports exigent une couche de rendu/test complémentaire. Certaines extensions avancées Tiptap sont payantes/Cloud ; distinguer le cœur open-source des services/extensions commerciaux. |
| Génération PDF à partir d'une composition Web | **Chromium/Playwright**, après prototype | Produire des PDFs de documents et de chartes à partir d'une version HTML/CSS déterministe | Valider polices embarquées, pagination, coupures de tableaux, images, liens, sommaires et cohérence entre aperçu et fichier exporté. Playwright est également retenu comme candidat de tests E2E. |
| Tests unitaires et de composants | **Vitest** et outils de test React adaptés | Tests rapides des contrats, validators, calculs, reducers et composants | Choisir un seul runner unitaire principal et définir ce qui relève du test composant vs test navigateur. |
| Tests E2E multi-navigateurs et parcours complets | **Playwright Test** | Connexion, parcours personas, création de marque, autosave, export, tests Chromium/WebKit/Firefox lorsque pertinents | La matrice réelle doit intégrer les WebViews Electron et les plateformes mobiles plus tard ; un test de navigateur classique ne suffit pas à valider toute la couche native. |
| Files d'attente et traitements asynchrones | **Supabase Queues/PGMQ + Cron**, à comparer au système de jobs existant | Dispatcher générations, exports, notifications ou travaux différés | Supabase Queues est signalé *Public Alpha*. Ne pas remplacer automatiquement le job model déjà documenté : il faut préserver statut, progression, idempotence, retry, résultats, audit et annulation lorsque requis. Faire un POC et garder un seul propriétaire de chaque responsabilité. |
| Erreurs et traces | **Sentry et/ou OpenTelemetry** | Repérer erreurs UI/serveur, suivre un appel Agent → outil → job → export et mesurer les temps | Ne pas envoyer de prompts privés, documents ou secrets en télémétrie sans politique de filtrage. La partie navigateur d'OpenTelemetry JS demande une revue de maturité spécifique ; Sentry peut servir de voie pragmatique pour les erreurs applicatives. |
| Parsing de documents importés | **Docling**, derrière un service d'import isolé | Extraire structure et texte de PDF/DOCX et alimenter le Workspace ou une fonction d'import de charte | Le parsing doit conserver la provenance, les pages et les erreurs ; vérifier les formats, la performance, la sécurité des fichiers et les licences de toute dépendance. |
| Travaux programmés | **Supabase Cron** ou mécanisme déjà propriétaire des jobs | Rappels, exécutions récurrentes et tâches planifiées | Ne pas créer deux planificateurs concurrents. Garder un identifiant de job, l'idempotence, un état terminal et l'observabilité. |

Les composants sont des candidats fondés sur les responsabilités qu'ils exposent dans leurs documents officiels ou dans les rapports Aurora. La présence dans ce tableau ne valide pas leur compatibilité exacte ni leur licence pour le produit final ; cela doit être confirmé lors du prototype, du contrôle des licences et de la revue de sécurité.

## 8.11 Architecture de l'Agent Aurora et des chaînes multi-agents

### 8.11.1 Un seul orchestrateur produit, plusieurs stratégies d'exécution

L'Agent Aurora est le point d'entrée de l'assistance dans l'application. Il comprend l'intention, récupère le contexte autorisé du Workspace, identifie les contraintes, choisit les capacités nécessaires, construit un plan, demande une confirmation si l'action l'exige, exécute, vérifie et rattache les résultats au projet.

Les modules ne doivent pas tous devenir des agents autonomes. Ils restent des propriétaires de capacités et de règles métier. Quand un workflow bénéficie d'une chaîne multi-agent, l'Agent Aurora appelle des sous-agents spécialisés au travers de contrats typés, avec une responsabilité explicite et un résultat vérifiable.

### 8.11.2 Cas adaptés à une chaîne multi-agent

- **Recherche complexe :** agent de planification des questions, agents de recherche ou d'analyse par source, agent de synthèse, puis contrôle des citations/provenances.
- **Brand DNA :** collecte/lecture du brief, analyse de marché si autorisée, synthèse de positionnement, proposition verbale et visuelle, contrôle de cohérence entre les règles et les livrables.
- **Affiche ou charte :** analyse de la demande, génération du plan/layout structuré, génération des calques, moteur déterministe de validation, rendu, éventuel contrôle visuel multimodal, correction et export.
- **Document multipages :** plan de document, rédaction section par section, contrôle de cohérence et références, rendu paginé, contrôle des sauts de page et révision finale.
- **Projet logiciel :** analyse du besoin, spécification, décomposition en étapes, génération de prototypes, tests, paquet de transfert et plan de mise en œuvre.

### 8.11.3 Contrat minimal de chaque agent spécialisé

Chaque agent ou étape spécialisée doit définir : input schema Zod ; permissions et outils accessibles ; objectifs et critères de sortie ; budget maximum de temps/tokens/coût ; politique de retry et d'annulation ; format de sortie typé ; traces de provenance ; mécanisme de validation ; comportement en cas d'incertitude/échec ; et les effets de bord autorisés.

Par défaut, les agents de génération ne disposent pas de droits directs illimités en base. Ils émettent des propositions structurées. Les modules et le moteur déterministe valident ensuite ces propositions ; les changements sensibles peuvent nécessiter une confirmation humaine. Le résultat d'une étape doit être persisté dans le workflow lorsqu'il est utile à la reprise.

### 8.11.4 Où TanStack AI peut intervenir

TanStack AI est une piste pour éviter de recréer certains éléments de transport de chat, streaming, tool calls typés, adaptateurs de fournisseurs et flux de média. Une preuve de concept devra le comparer à la solution IA déjà présente dans le dépôt, notamment sa compatibilité avec les agents, les outils existants, la persistance des conversations, les approvals, les jobs et les règles de sécurité.

Même si TanStack AI est retenu, **Agent Aurora demeure le contrat métier d'orchestration**. Le SDK est une implémentation possible de certains mécanismes, pas la source de vérité du produit. La logique de planification, la permission d'utiliser un outil, le contrôle de coût, l'historique d'exécution et la vérification des résultats restent définis et testés par Aurora.


---

# 9. Qualité, sécurité, limites et exigences non fonctionnelles

## 9.1 Fiabilité fonctionnelle

Toute fonction doit gérer au minimum, selon sa nature : état initial, chargement, état vide, succès, échec, accès refusé, fournisseur indisponible, annulation, reprise et résultat partiel. L'absence d'une capacité externe ne doit pas rendre le reste de l'application inutilisable si un mode dégradé est possible.

## 9.2 Qualité du contenu

- Les données issues de sources doivent conserver leur provenance.
- Les faits, tendances, analyses, hypothèses, scénarios et incertitudes sont différenciés dans les espaces de recherche.
- Le contenu importé d'un cours ou d'un document est distingué des explications ajoutées par l'IA.
- Les références d'un document professionnel doivent être vérifiables lorsque celui-ci prétend s'appuyer sur des sources.
- Les nombres, résultats de calcul ou paramètres dimensionnels utilisent des moteurs adaptés lorsqu'ils sont disponibles.

## 9.3 Qualité visuelle et documentaire

- Pas de calque manquant, de texte superposé par erreur ou d'actif introuvable.
- Vérification des contrastes et de la lisibilité du texte.
- Contrôle de la pagination, des marges, de la numérotation et de la cohérence des styles.
- Tests de non-régression du rendu après optimisation ou transformation.
- Respect du Brand DNA lorsqu'il est activé.
- Identification explicite des problèmes non résolus avant export.

## 9.4 Éditabilité et versionnement

- Les modifications conservent une source structurée lorsqu'elle existe.
- Les données verrouillées par l'utilisateur ne sont pas changées par une itération automatisée.
- Chaque nouvelle génération importante produit une version ou une proposition de changement claire.
- Les exports référencent leur version source.
- Le retour arrière et la comparaison de versions doivent être possibles selon le type de production.

## 9.5 Sécurité et confidentialité

- Accès selon l'identité et les permissions réelles ; pas d'exposition d'un projet via la recherche globale à un utilisateur non autorisé.
- Clés et secrets conservés côté serveur ou dans les magasins adaptés, jamais exposés sans raison au client.
- Permissions demandées au moment approprié et expliquées.
- Données sensibles minimisées dans les prompts, logs et intégrations.
- Confirmation nécessaire pour les actions ayant des effets externes, destructifs ou engageants selon leur classification.
- Règles claires de suppression, conservation, export et partage des données à définir pour la version commerciale.

## 9.6 Accessibilité et ergonomie

- Navigation clavier pour les fonctions clés.
- Focus visible, labels compréhensibles et messages d'erreur accessibles.
- Contraste adéquat, tailles de texte et zones d'interaction utilisables.
- Interfaces d'édition adaptées aux pointeurs et au clavier ; alternative à la manipulation uniquement à la souris si le format le permet.
- Réduction de la surcharge : afficher l'essentiel puis dévoiler les contrôles avancés.

## 9.7 Performance et tâches longues

Les opérations de génération, import, OCR, recherche ou export qui dépassent l'interaction immédiate doivent avoir un statut visible, une annulation ou une reprise lorsque c'est possible et un résultat persisté. La performance doit être évaluée sur des briefs, documents, actifs et tailles de projet représentatifs ; le temps et le coût doivent être mesurés, pas promis sans tests.

## 9.8 Limites propres aux domaines

- Un logo généré n'est pas automatiquement libre de droits ni distinct juridiquement de toutes les marques existantes.
- Un document convaincant n'est pas nécessairement exact, complet ou conforme à une réglementation.
- Une charte graphique n'établit pas à elle seule une stratégie de marque validée par le marché.
- Un futur modèle 3D visuel n'est pas automatiquement un modèle prêt à fabriquer, tolérancé ou sûr.
- Une future vidéo générée n'est pas automatiquement exempte d'artefacts ou parfaitement synchronisée.
- Un export de code n'est pas une garantie que le produit soit compilable, sécurisé ou prêt à déployer sans tests dans l'environnement cible.

---

# 10. Roadmap produit et priorités de réalisation

## 10.1 Règle de lecture

Le premier périmètre fonctionnel comprend l'ensemble des modules antérieurs et Design Space Pro. La roadmap détermine **l'ordre concret de livraison**, et non l'élimination de fonctions de la vision cible. Les capacités déjà codées doivent être réutilisées lorsqu'elles satisfont les contrats ; celles qui ne sont que documentées doivent être planifiées et construites.

## 10.2 Phase 0 — Rebaselining produit et technique (priorité préalable)

**Objectif :** aligner la vision, les contrats, la roadmap et l'état réel du code avant de réordonner les travaux.

Travaux :

1. établir un état de référence du dépôt et du changelog ;
2. inventorier chaque capacité, ses tests, sa disponibilité par plateforme et ses contrats ;
3. établir la liste des capacités implémentées, partielles, uniquement conçues ou à décider ;
4. remplacer la priorité mobile-only par la stratégie Web responsive → Desktop → Mobile dans les documents normatifs appropriés ;
5. préserver les règles métier déjà valides et identifier les décisions liées uniquement à la plateforme mobile ;
6. proposer la topologie `Next.js site public` + `Ionic React application métier`, ou déposer un ADR motivant une topologie différente ;
7. vérifier versions/licences/compatibilité de Supabase, PowerSync, SQLite, Capacitor, Electron, Zod et des paquets TanStack sélectionnés ;
8. exécuter un POC PowerSync de bout en bout sur la Web : auth → règles de sync → SQLite local → modification offline → upload → reprise réseau → RLS et changement de compte ;
9. exécuter un POC des outils de formulaire, de liste/virtualisation et de rendu Design Space Pro ;
10. cartographier les modules existants sur la nouvelle navigation et les cinq personas ;
11. définir les exigences minimales d'intégration de Design Space Pro ;
12. définir la stratégie de migration des projets, artefacts et données existants selon les conséquences réelles de la plateforme.

**Porte de sortie :** registre de statut fiable, contradictions documentaires résolues par décision explicite, topologie des applications confirmée, POC de synchronisation validé, backlog trié et dépendances connues.

## 10.3 Phase 1 — Aurora Web responsive : socle et modules

**Objectif :** disposer d'un Web utilisable sur téléphone, tablette et ordinateur, avec les modules essentiels intégrés dans les parcours des personas.

### Priorité P0 — Fondations nécessaires

- navigation et shell Web ;
- authentification, contexte utilisateur et permissions ;
- navigation par projet et contexte préservé ;
- gestion des données et fichiers, sauvegarde et récupération ;
- états d'interface cohérents (chargement, vide, erreur, résultat partiel) ;
- recherche globale et commande de création rapide ;
- intégration de l'Agent Kernel au travers de contrats contrôlés ;
- tâches longues et statut de génération/export ;
- observabilité, tests de base, sécurité et CI/CD adaptés à la surface Web ;
- design system responsive et accessibilité des flux critiques ;
- contrats Zod partagés par les services et capacités, ainsi que TanStack Form pour les formulaires complexes après validation ;
- politique de séparation des données PowerSync, du cache TanStack Query et de l'état éphémère des éditeurs ;
- TanStack Table/Virtual pour les écrans qui en ont besoin, avec test de performance avant généralisation ;
- Pacer/Hotkeys en pilotes limités seulement, en tenant compte de leur statut beta.

### Priorité P1 — Couverture du socle métier

S'assurer que toutes les fonctions incluses dans la baseline et déjà disponibles dans le code soient accessibles depuis le Web selon leurs contrats ; planifier les fonctions manquantes du catalogue :

- Productivity : inbox, tâches, priorités, calendrier, projets, objectifs, habitudes, focus lorsque supporté, revues, analytics et bibliothèque ;
- Learning : import, fiches, flashcards, QCM, coach, Mirror et compétences ;
- Knowledge : arbre sémantique, récupération et OCR ;
- Discovery : recherche, analyse des lacunes, horizons/scénarios et fiches de découverte ;
- Progress : tableaux, preuves, analyses et trajectoires ;
- Agent : capacités, vérification, confirmation et gestion des erreurs ;
- Scientific Engine : opérations prises en charge et vérifications ;
- Artifact : aperçu réel des formats supportés, gestion des sources et export ;
- Integrations : connecteurs, notifications et automatisations disponibles ;
- Identity : contexte, préférences, accès et isolation.

Les fonctions dépendantes d'une plateforme mobile, dont le blocage système d'applications, doivent avoir un comportement Web explicite — indisponible, adapté ou dégradé — sans être présentées comme identiques.

**Porte de sortie :** scénarios clés exécutables sur Web, qualité et limitations vérifiables, modules propriétaires respectés et données cohérentes.

## 10.4 Phase 1B — Design Space Pro initial

**Objectif :** livrer le premier espace de création professionnelle capable de produire des actifs de marque et des documents visuels multipages éditables.

Ordre recommandé :

1. projet Design Space, brief et source de référence ;
2. modèle Brand DNA versionné ;
3. création et révision des logos vectoriels simples ;
4. génération de la charte et héritage des tokens de marque ;
5. création d'affiches avec structure de calques éditable ;
6. éditeur visuel et édition manuelle des calques ;
7. validateur déterministe : contraintes de layout, ordre, lisibilité et style ;
8. génération de documents professionnels multipages à partir de modèles ;
9. export et vérification des formats confirmés ;
10. comparaison de versions, verrouillage d'attributs et propagation contrôlée des modifications de marque.

**Porte de sortie :** un utilisateur peut partir d'un brief, créer une identité cohérente, modifier logo/affiche/charte/document, vérifier le résultat, revenir en arrière et exporter une production dont les sources sont conservées.

## 10.5 Phase 1C — Intégration et qualité de la version Web

- parcours complets par persona ;
- vérification des permissions entre projets et ressources ;
- mesure de latence, de taux d'échec et de coût des générations ;
- tests de régression visuelle et documentaire ;
- validation de l'éditabilité et du cycle sauvegarde/chargement/export ;
- documentation utilisateur et état des limites ;
- tests responsive et d'accessibilité ;
- revue de la cohérence entre les documents normatifs et le code.

**Critère de sortie :** aucune fonction présentée comme disponible sans mécanisme, permission, comportement, limite et test démontrables.

## 10.6 Phase 2 — Aurora Desktop

**Objectif :** reprendre les capacités Web et optimiser l'expérience pour le travail professionnel prolongé.

Priorités :
- continuité des comptes, projets, versions et fichiers ;
- affichage multi-panneaux et comparaison avancée ;
- opérations sur documents et actifs volumineux ;
- flux fichier/export et raccourcis si justifiés ;
- robustesse des travaux longs ;
- tests des environnements et intégrations retenus.

Electron est retenu comme candidat de référence pour l'emballage Desktop. Le POC doit vérifier l'accès aux fichiers, l'installation et les mises à jour, les raccourcis, le presse-papiers, l'impression, les exports, la stabilité des éditeurs et la consommation de ressources. La configuration de sécurité doit suivre les recommandations Electron (isolation de contexte, sandbox, CSP restrictive, validation des messages IPC et absence de privilèges Node dans le contenu non fiable). Desktop est une phase d'expérience et de qualité, pas seulement un changement d'icône d'application.

## 10.7 Phase 3 — Studios spécialisés

Les studios suivants sont dans la vision cible, mais restent à prioriser après le premier parcours professionnel et Desktop :

- **3D & Spatial Design** — architecture, jardin, intérieur, scènes, objets et gadgets ; partir d'images/références ; édition manuelle ; différencier modèle visuel, modèle paramétrique et modèle destiné à une utilisation technique.
- **Video Studio** — storyboard, scènes, calques, timeline, keyframes, textes éditables, audio, voix, effets, mixage, ducking, rendu, édition manuelle et export. HyperFrames/Chromium/FFmpeg sont des candidats de la recherche VIDEO, pas une décision de stack de ce document.
- **Music Studio** — idée sonore, rythme, composition, arrangement et amélioration ; préserver le rôle de directeur artistique de l'utilisateur et les éléments éditables lorsque le moteur le permet.
- **Web & Digital Product Studio avancé** — produire ou prolonger une interface, des composants, des règles de design et des fichiers destinés au développement ; transfert à des outils tels que Claude Code ou Codex lorsque l'export est testé.
- **Data Visualization avancée** — graphiques et visualisations liés à des données, rapports et tableaux de bord.

L'ordre interne de ces studios reste **À ARBITRER** sur la base de la valeur, de la faisabilité, de la dépendance entre moteurs, du coût et de la demande utilisateur.

## 10.8 Phase 4 — Aurora Mobile

**Objectif :** fournir une expérience mobile cohérente et limitée aux interactions adaptées à la plateforme.

Priorités potentielles :
- capture/inbox ;
- tâches, agenda, objectifs, habitudes et focus selon autorisations ;
- notifications et bilans ;
- consultation et recherche dans les projets ;
- apprentissage, flashcards, fiches et progression ;
- consultation des documents et commentaires simples lorsque supportés ;
- modifications rapides et reprise de projets ;
- création légère et lancements de génération dont les résultats se consultent ensuite sur Web/Desktop.

Le mobile doit réutiliser les contrats et données communs sans tenter de reproduire tous les éditeurs riches. Les limites de plateforme et d'accès aux fichiers doivent être explicites.

## 10.9 Correspondance avec l'ancienne roadmap technique

Les documents précédents contiennent des vagues de travail technique (wave 0 à 7) centrées sur les contrats/types, les fondations, les modules, l'Agent Kernel, l'intégration, le raffinement UX, la revue et la release candidate. Ces travaux doivent être **mappés** vers la nouvelle roadmap, non copiés aveuglément.

- Les contrats, données, identité, design system, intégrations et jobs restent potentiellement réutilisables.
- Les fonctions métier existantes sont conservées si leurs comportements et contrats restent corrects.
- Les écrans, routes et dépendances mobile-only doivent être réévalués pour le Web-first.
- Design Space Pro nécessite ses propres capacités, ses contrats d'artefacts, son édition, sa validation et ses tests.
- Les éléments de la roadmap existante marqués comme livrés doivent être confirmés par le code, le changelog et les tests actuels.

### Contradiction de sources à résoudre

Le document `00-overview.md` indique dans son en-tête que les vagues 0 à 7 auraient été livrées et que le projet serait au stade d'une release candidate v0.1.0. À l'inverse, le rapport `implementation-readiness-report-2026-09-22.md` et certaines versions de `project-context.md` parlent de prérequis de lancement, de wave 1 en cours et de wave 2 partiellement livrée. Ces états ne peuvent pas être considérés simultanément comme une vérité unique sans examen du dépôt et du journal de livraison.

**Décision de cette référence :** ne pas déclarer l'une de ces versions comme exacte. La phase 0 doit établir l'état réel à partir des commits, des packages, du changelog, des workflows CI et des tests exécutables. Cette référence n'est pas un audit du dépôt.

---

# 11. Parcours de bout en bout servant de preuve d'intégration

## 11.1 Parcours prioritaire — Une entreprise crée sa marque et ses supports

1. L'utilisateur sélectionne « Entreprise » ou « Entrepreneur » et crée un projet de marque.
2. Aurora recueille le brief et indique les informations inconnues.
3. Discovery recherche les références de marché demandées et conserve les sources.
4. L'utilisateur valide une direction stratégique ; le Brand DNA est structuré et versionné.
5. LOGO produit un logo éditable et présente les contrôles pertinents.
6. L'utilisateur modifie les éléments puis verrouille les choix approuvés.
7. AFFICHE utilise la même identité pour composer une affiche éditable.
8. Document Studio produit la charte complète avec sections, règles d'usage et exemples.
9. Le validateur vérifie les règles objectives ; l'utilisateur revoit les choix subjectifs.
10. Aurora produit les exports supportés et conserve les sources ainsi que la version du Brand DNA.
11. Productivity transforme les tâches restantes en plan de lancement.
12. La modification ultérieure de la marque déclenche un aperçu des livrables potentiellement concernés, mais pas de réécriture silencieuse.

**Ce que ce scénario teste :** intégration Discovery/Knowledge/Productivity/Agent/Artifact/Design Space Pro, héritage de marque, versionnement, validation, exports, sécurité et qualité du rendu.

## 11.2 Parcours — Étudiant transforme un cours en révision structurée

1. Importer un cours ou un document.
2. Extraire le contenu et signaler les passages incertains.
3. Enregistrer les références dans Knowledge.
4. Générer fiches et cartes de révision en séparant le corpus des explications ajoutées.
5. Créer des QCM et exercices.
6. Planifier les révisions dans Productivity.
7. Collecter les preuves d'apprentissage et mettre à jour les vues Progress selon les règles du module.
8. Proposer des révisions supplémentaires ciblées.

**Ce que ce scénario teste :** l'import, la fidélité aux sources, les relations entre Learning/Knowledge/Productivity/Progress et la gestion d'erreurs.

## 11.3 Parcours — Autodidacte explore un sujet

1. Formuler une question.
2. Recherche multi-source avec provenance.
3. Distinguer faits, tendances, analyse, scénarios et incertitudes.
4. Enregistrer une fiche de découverte.
5. Relier les éléments à l'arbre de connaissances.
6. Identifier une compétence utile et proposer une activité d'apprentissage.
7. Créer éventuellement un projet ou un document de synthèse.

**Ce que ce scénario teste :** Discovery et Knowledge restent distincts mais interopérables, sources traçables, et le parcours ne devient pas obligatoirement une formation structurée.

## 11.4 Parcours — Entrepreneur transforme une idée en activité

1. Capturer et préciser l'idée.
2. Rechercher le problème, le public, les solutions et les contraintes.
3. Formaliser les hypothèses, risques et critères de réussite.
4. Découper l'activité en objectifs, projets, tâches et jalons.
5. Créer les livrables initiaux avec Design Space Pro.
6. Vérifier le résultat puis organiser le lancement.
7. Faire des bilans à partir des résultats disponibles et adapter le plan.

## 11.5 Parcours futur — Gadget 3D conceptuel

1. Décrire la fonction, les utilisateurs, les contraintes et les dimensions connues.
2. Explorer les principes techniques et conserver les sources.
3. Définir exigences, inconnues et tests.
4. Générer un concept 3D puis, si le moteur le permet, une représentation paramétrique.
5. Modifier les paramètres et comparer plusieurs versions.
6. Exécuter les contrôles effectivement supportés et indiquer les aspects non vérifiés.
7. Exporter un paquet exploitable par un outil spécialisé et conserver le contexte du projet.

Ce scénario valide la future universalité du modèle, mais ne signifie pas que le studio 3D appartient au premier lancement.

---

# 12. Critères d'acceptation et revue de qualité

## 12.1 Critères communs à toute fonctionnalité

Une fonctionnalité n'est considérée comme livrée que si :

1. son objectif, son propriétaire fonctionnel et son entrée utilisateur sont documentés ;
2. les cas d'utilisation et les critères d'acceptation sont explicites ;
3. les contrats de données et les permissions sont définis ;
4. les états chargement, vide, succès, erreur et indisponibilité appropriés existent ;
5. le parcours utilisateur est accessible depuis la navigation du produit ;
6. les erreurs et résultats partiels sont visibles ;
7. la sortie est liée au bon projet ou contexte lorsque pertinent ;
8. les opérations longues et les reprises sont gérées ;
9. les tests automatisés et manuels nécessaires passent ;
10. l'observabilité et les logs respectent les règles de confidentialité ;
11. la documentation reflète le comportement réel ;
12. la disponibilité par plateforme est vérifiée.

## 12.2 Critères spécifiques Design Space Pro

- Le brief est modifiable et versionné.
- Le Brand DNA distingue propositions, informations fournies, choix acceptés et informations non vérifiées.
- Les logos supportés ont une source structurée et des calques éditables.
- Les affiches exposent leur structure de layout et leur ordre de rendu.
- Les documents multipages conservent une hiérarchie éditoriale cohérente.
- Le moteur de validation renvoie des violations typées et compréhensibles.
- Les attributs verrouillés ne sont pas modifiés par les cycles de raffinement.
- Les exports sont réellement ouverts ou rendus pour vérification.
- Une nouvelle version n'écrase pas une version approuvée sans possibilité de retour.
- Le résultat final indique les contrôles passés et les limites restantes.

## 12.3 Tests de plateforme

**Web responsive :** tailles d'écran représentatives, navigation clavier, édition, sauvegarde, erreurs réseau, chargement long, transfert de contexte et export.

**Desktop :** continuité de projet, éditions prolongées, gestion des fichiers si prévue, reprise des jobs, fenêtres et raccourcis si disponibles.

**Mobile :** fonctions réellement supportées, permissions natives, notifications, reprise hors ligne lorsque prévue, navigation tactile et transfert de projets complexes vers Web/Desktop.

## 12.4 Revue de non-régression

Toute modification d'un moteur, d'une représentation ou d'une règle de validation doit comporter des exemples représentatifs et une comparaison avant/après. Pour les sorties visuelles, la revue inclut le rendu ; pour les données, elle inclut schémas et migrations ; pour l'IA, elle inclut des cas d'échec et de refus, pas seulement des exemples réussis.

## 12.5 Métriques proposées

À confirmer selon instrumentation et contraintes de vie privée :

- taux de complétion des parcours de bout en bout ;
- taux d'échec et de reprise des générations/imports/exports ;
- durée d'attente et coût approximatif par type de tâche ;
- taux de modification manuelle après génération ;
- fréquence de retour arrière ou de rejet des suggestions ;
- taux de validité des sorties ;
- problèmes de contraste, mise en page ou export détectés après génération ;
- progression dans les tâches/projets sans confondre activité et valeur réelle ;
- satisfaction utilisateur par persona et tâche.

Les métriques servent à améliorer le produit, pas à affirmer que l'IA a raison sans validation.

---

# 13. Registre des décisions et risques

## 13.1 Décisions confirmées

- **D-01 — Promesse :** Aurora repose sur Créer, Apprendre, Découvrir, S’organiser et Innover. Conséquence : le positionnement relie les modules à ces résultats utilisateur.
- **D-02 — Modules :** les modules antérieurs sont conservés dans la vision cible. Conséquence : Design Space Pro ne remplace pas Productivity, Learning, Knowledge ou les autres modules.
- **D-03 — Création professionnelle :** Design Space Pro est la première extension créative professionnelle. Priorité sur Brand DNA, logo, charte, affiche et document multipages.
- **D-04 — Plateformes :** Web responsive → Desktop → Mobile. La roadmap technique existante doit être rebaselinée.
- **D-05 — Personas :** cinq personas à prendre en charge. Le shell et les modèles doivent permettre personnalisation et accès transversal.
- **D-06 — Stack de référence :** TypeScript, Ionic React, Capacitor, Electron, Next.js, PowerSync, SQLite, Supabase/PostgreSQL, Zod et Agent Aurora. La topologie proposée sépare le site public Next.js de l'application métier Ionic React pour éviter deux routeurs dans un même shell.
- **D-07 — Synchronisation :** PowerSync est choisi pour décharger Aurora d'une grande partie du moteur de synchronisation ; le connecteur, les sync rules, la sécurité, les migrations et les tests de conflits restent à implémenter et valider.
- **D-08 — TanStack :** adopter les bibliothèques utiles par responsabilité (Form, Query ciblé, Table, Virtual, Charts/Markdown selon POC) et isoler les packages alpha/beta (DB+PowerSync Collection, AI, Pacer, Hotkeys, Store, Devtools, Intent) selon les règles de la section 8.9.

## 13.2 Décisions à arbitrer

- **A-01 — Topologie Next.js / Ionic React :** confirmer la séparation proposée entre site public Next.js et application métier Ionic React, ou choisir explicitement une autre topologie sans cumuler deux routeurs dans le même shell. **Quand :** spike Web initial. **Risque :** routage concurrent, complexité de build et réutilisation insuffisante entre Web, Electron et Capacitor.
- **A-02 — Éditeurs et formats :** valider Fabric.js, SVG structuré, Tiptap/ProseMirror et le pipeline PDF/DOCX à partir de prototypes. **Quand :** POC Design Space Pro. **Risque :** promettre l'éditabilité ou la pagination sans preuve.
- **A-03 — État réel du dépôt :** quel est l'état réel des modules et de chaque capacité ? **Quand :** phase 0 immédiate. **Risque :** réécrire du code existant ou annoncer comme acquis un travail non terminé.
- **A-04 — Collaboration entreprise :** quel périmètre de travail multi-utilisateur ? **Quand :** avant de promettre l’offre équipe. **Risque :** confondre usage professionnel et administration multi-utilisateurs.
- **A-05 — Brand DNA :** entité dédiée ou représentation d’un artefact/projet existant ? **Quand :** audit des contrats et données. **Risque :** duplication des sources de vérité.
- **A-06 — Studios futurs :** lesquels développer après Desktop, et dans quel ordre ? **Quand :** roadmap post-lancement. **Risque :** éparpillement.
- **A-07 — Mobile :** quelles fonctionnalités exactes proposer sur cette surface ? **Quand :** conception de la phase Mobile. **Risque :** répliquer des interfaces inadaptées au petit écran.
- **A-08 — Plans commerciaux :** quelles fonctions sont disponibles par formule ? **Quand :** positionnement et tarification. **Risque :** laisser le produit technique définir seul les limites commerciales.
- **A-09 — Cyforge :** comment lier les deux produits et quelles données partager ? **Quand :** conception d’intégration dédiée. **Risque :** duplication ou partage non consenti.
- **A-10 — Workflow entreprise :** quels modèles, commentaires et mécanismes d’approbation ? **Quand :** revue UX/produit entreprise. **Risque :** workflow de validation incomplet.
- **A-11 — TanStack DB/PowerSync Collection :** faut-il introduire les collections réactives par-dessus SQLite ? **Quand :** après POC comparant requêtes directes PowerSync et TanStack DB. **Risque :** ajouter un deuxième état/cache et dépendre d'un adaptateur alpha.
- **A-12 — TanStack AI :** quel périmètre du streaming/tool-calling peut être délégué à ce SDK sans coupler le Kernel Aurora à son modèle ? **Quand :** POC IA serveur. **Risque :** recouvrement avec les capacités déjà codées ou dépendance prématurée.
- **A-13 — Files d'attente :** utiliser Supabase Queues/PGMQ ou poursuivre le système de jobs persistant déjà documenté ? **Quand :** audit du job system et POC. **Risque :** maintenir deux files et perdre idempotence, progression ou audit.

## 13.3 Risques à surveiller

- **Périmètre trop large :** réduire le risque par étapes de livraison et preuves de valeur, sans supprimer la vision globale.
- **Écart entre vision et état réel :** tenir le registre de statut à jour et exiger un test par capacité.
- **Dépendance à des services IA externes :** gérer coûts, limites, alternatives et dégradation.
- **Qualité des rendus :** rendre les sorties vérifiables et éditables, utiliser des boucles de rendu contrôlées et des validations déterministes.
- **Données de marque incohérentes :** centraliser le Brand DNA et suivre les versions qui en héritent.
- **Suradaptation aux personas :** permettre les fonctions transversales et les changements de profil.
- **Anciennes décisions mobile-only :** mettre à jour le référentiel normatif avant d'engager des nouveaux flux Web/Desktop.
- **Trop d'outils qui se chevauchent :** imposer un propriétaire unique à l'état synchronisé, au cache de requêtes, à l'état local et à la file de jobs.
- **Dépendances en alpha/bêta :** isoler les POC, verrouiller les versions et prévoir les conditions de retrait ou de remplacement.
- **Ambiguïté sur la conformité :** ne jamais confondre qualité visuelle, justesse technique et conformité réglementaire.

---

# 14. Références utilisées et statut des connaissances

Cette référence synthétise les documents Aurora fournis, les rapports LOGO/AFFICHE/VIDEO et une recherche externe ciblée des documentations officielles de stack consultées le 24 octobre 2026. Les liens externes ci-dessous fondent l'analyse des responsabilités et de la maturité affichée des bibliothèques ; ils ne dispensent pas d'une vérification des versions exactes, licences et matrices de compatibilité au moment d'implémenter.

## 14.1 Sources de vision et d'architecture Aurora

- `Aurora-Universal-Project-Model-v0.1.md` — contexte durable, cycle de vie de projet, objets conceptuels, Agent Kernel, scénarios SaaS et gadget, intégration Cyforge et ordre de validation.
- `00-overview.md` — architecture antérieure, modules, responsabilités, données, orchestration IA, modèle de jobs et ancienne roadmap technique.
- `master-feature-catalog.md` — catalogue de capacités des modules et chaînes d'intégration.
- `project-context.md` et `project-context-changelog.md` — contraintes d'implémentation et règles à l'intention des agents.
- `implementation-readiness-report-2026-09-22.md` — analyse de couverture, lacunes et recommandations de readiness ; date et état doivent être replacés par rapport au dépôt actuel.
- Les échanges de cadrage précédents sur les cinq dimensions Aurora, Design Space, le Brand DNA, les transferts vers les environnements de développement et les cinq personas.

## 14.2 LOGO — principes repris

`LOGO.md` synthétise notamment les travaux associés à :

- DeepSVG, arXiv `2007.11301` — représentation hiérarchique des formes vectorielles ;
- LayerPeeler, arXiv `2505.23740` — décomposition raster/vectorielle en couches ;
- Render-in-the-Loop, arXiv `2604.20730` — génération SVG avec retour de rendu visuel et vérification ;
- NeuralSVG, arXiv `2501.03992` — représentation vectorielle et contrôle de complexité ;
- From Tokens to Numbers, arXiv `2602.02820` — séparation structure/valeurs numériques ;
- autres méthodes de layout et références citées dans le rapport.

Principe retenu pour la baseline : produire et conserver des représentations SVG structurées et éditables, accompagner la génération d'une boucle de rendu/vérification et effectuer un post-traitement contrôlé. Les modèles ou techniques cités dans la recherche ne sont pas automatiquement des dépendances de production.

## 14.3 AFFICHE — principes repris

`AFFICHE.md` synthétise notamment :

- CreatiPoster, arXiv `2506.10890` ;
- PosterLLaVa, arXiv `2406.02884` ;
- PosterLlama, arXiv `2404.00995` ;
- GLDesigner, arXiv `2411.11435` ;
- SciFig, arXiv `2601.04390` ;
- Ad Banner, arXiv `2512.12596` ;
- d'autres méthodes de layout, lisibilité, style et contrôle des calques citées dans le rapport.

Principe retenu : construire une mise en page structurée avec des calques éditables, partager une charte racine, valider les contraintes objectives et limiter les boucles de raffinement. Fabric.js est retenu comme candidat principal de toile ; son modèle source, le round-trip JSON/SVG, les exports et les validations doivent être éprouvés avant gel.

## 14.4 VIDEO — conservé pour la roadmap

`VIDEO.md` propose un éditeur vidéo par calques et mentionne HyperFrames, Chromium, FFmpeg et une timeline structurée, avec script → storyboard → audio → composition → rendu → édition → export. Il reprend des références de recherche telles que LayerT2V (`2508.04228`), Vid-LLM Survey (`2312.17432`), SVGDreamer (`2312.16476`) et CreatiParser (`2604.19632`).

Ces éléments sont conservés comme piste de roadmap ; le studio vidéo ne fait pas partie du périmètre initial de Design Space Pro décidé ici, et les outils mentionnés restent des options à réévaluer au moment de la stack.

## 14.5 Recherche 3D et approche générale

Les notes de recherche précédentes ont favorisé l'approche LLM-to-CAD : transformer le langage naturel en représentations structurées, paramètres et commandes, puis déléguer la géométrie à un moteur approprié et afficher le résultat dans un visualiseur. Les familles de solutions mentionnées incluent des outils CAD-as-code tels que CadQuery/build123d, des moteurs géométriques basés sur OpenCascade et des visualiseurs Web tels que Three.js. Elles restent candidates, pas décisions finales.

Le document maintient une distinction importante entre concept visuel, maillage, modèle paramétrique et modèle techniquement validé. Les contraintes d'ingénierie, de tolérance, de sécurité, de fabrication et de réglementation nécessitent des vérifications adaptées.

## 14.6 Recherche externe — stack, TanStack et briques d'ingénierie

### Écosystème TanStack consulté

- [Catalogue officiel des bibliothèques TanStack](https://tanstack.com/libraries) — inventaire des bibliothèques publiques et indications de maturité affichées.
- [TanStack Query](https://tanstack.com/query/latest/docs/framework/react/overview) — cache et cycle de vie de données distantes/asynchrones.
- [TanStack Form](https://tanstack.com/form/latest/docs/overview) et [validation par schéma](https://tanstack.com/form/latest/docs/framework/react/guides/validation) — formulaires complexes, validation au champ ou au niveau du formulaire, support Standard Schema dont Zod.
- [TanStack Table](https://tanstack.com/table/latest/docs/overview) — moteur headless pour grilles et tableaux.
- [TanStack Virtual](https://tanstack.com/virtual/latest/docs/introduction) — virtualisation des listes/grilles longues.
- [TanStack Charts](https://tanstack.com/charts/latest/docs/overview) et [contrat de compatibilité stable](https://tanstack.com/charts/latest/docs/compatibility) — définition et rendu SVG/Canvas de graphiques.
- [TanStack Markdown](https://tanstack.com/markdown/latest/docs/overview) — parseur/rendeur Markdown déterministe ; profil de syntaxe à comparer aux contenus existants.
- [TanStack Highlight](https://tanstack.com/highlight/latest/docs/overview) — coloration syntaxique légère des blocs de code.
- [TanStack Pacer](https://tanstack.com/pacer/latest/docs/overview) — debounce, throttling, rate-limiting, file et batching client ; le site officiel indique un statut bêta.
- [TanStack Hotkeys](https://tanstack.com/hotkeys/latest/docs/overview) — raccourcis typés, scopes et personnalisation ; le site officiel indique un statut bêta.
- [TanStack DB](https://tanstack.com/db/latest/docs/overview) et [PowerSync Collection](https://tanstack.com/db/latest/docs/collections/powersync-collection) — collections réactives et optimistes au-dessus d'une source de données ; DB est bêta et la doc PowerSync signale l'adaptateur comme alpha.
- [TanStack AI](https://tanstack.com/ai/latest/docs/getting-started/overview) — API TypeScript pour chat en streaming, tool calls, sorties structurées et adaptateurs de fournisseurs ; à comparer au Kernel existant.
- [TanStack Store](https://tanstack.com/store/latest/docs/overview) — store réactif local ; le site officiel le marque alpha.
- [TanStack Router](https://tanstack.com/router/latest/docs/overview) et [TanStack Start](https://tanstack.com/start/latest/docs/framework/react/overview) — routeur typé et framework full-stack ; pas sélectionnés par défaut car Ionic React et Next.js ont déjà leur propre système de navigation/framework.
- [TanStack Ranger](https://tanstack.com/ranger/latest/docs/overview) — primitives de ranges/cursors ; optionnel pour contrôles avancés d'éditeur.
- [TanStack Devtools](https://tanstack.com/devtools/latest/docs/overview) — instrumentation de développement, marquée alpha.
- [TanStack Intent](https://tanstack.com/intent/latest/docs/overview) — CLI pour distribuer et charger des Agent Skills versionnés ; option dev-only pour guider les agents de code.
- [TanStack Config](https://tanstack.com/config/latest/docs/overview) et [TanStack CLI](https://tanstack.com/cli/latest/docs/overview) — outillage d'écosystème/scaffolding ; non retenus comme couche runtime d'Aurora, et le CLI est alpha.

### Briques complémentaires retenues ou candidates

- [Ionic React](https://ionicframework.com/docs/react/overview) et [navigation Ionic React](https://ionicframework.com/docs/react/navigation) — l'application Ionic utilise normalement React Router via `IonReactRouter`.
- [Next.js App Router](https://nextjs.org/docs/app) — le site public peut utiliser son propre routeur ; ne pas mélanger deux routeurs dans le même shell.
- [Capacitor](https://capacitorjs.com/docs) et [flux de build des assets](https://capacitorjs.com/docs/getting-started) — conteneur natif pour construire ensuite Mobile à partir d'un bundle Web ; les exigences de build doivent être compatibles.
- [Electron — sécurité](https://www.electronjs.org/docs/latest/tutorial/security) — contexte isolé, sandbox, CSP, contrôles IPC, navigation limitée et absence de privilèges Node pour le contenu non fiable.
- [PowerSync](https://docs.powersync.com/) — moteur sync SQLite/offline-first ; intégration et connecteur Aurora à coder selon le schéma et les règles de permission.
- [Supabase Queues](https://supabase.com/docs/guides/queues) et [Supabase Cron](https://supabase.com/docs/guides/cron) — candidats pour les messages durables et jobs récurrents. Supabase Queues est présenté comme Public Alpha ; comparer avec le job system existant avant de remplacer quoi que ce soit.
- [Tiptap/ProseMirror](https://tiptap.dev/docs/editor/getting-started/overview) — éditeur de contenu structuré ; la composition multipage et les exports nécessitent un pipeline supplémentaire.
- [Fabric.js](https://fabricjs.com/docs/) — canevas éditable candidat pour AFFICHE.
- [SVGO](https://svgo.dev/) — optimisation SVG ; le fichier source et le rendu doivent rester validables après optimisation.
- [Playwright Test](https://playwright.dev/docs/intro) — tests E2E multi-navigateurs et validation des parcours d'intégration.
- [OpenTelemetry JS](https://opentelemetry.io/docs/languages/js/) — traces/metrics côté serveur et stratégie d'observabilité ; l'instrumentation navigateur a un statut à vérifier.
- [TanStack AI : agents skills](https://tanstack.com/ai/latest/docs/getting-started/agent-skills) — guidelines versionnées utiles aux agents de développement, distinctes de l'orchestration runtime.

## 14.7 Sources contradictoires ou insuffisantes

Les rapports d'ingénierie ne prouvent pas à eux seuls l'état actuel du produit. Les statuts listés dans les catalogues sont des états de conception ou des annotations historiques ; la disponibilité effective exige une vérification dans le code, les contrats, les tests et la version livrée.

---

# 15. Glossaire

- **Agent Kernel :** orchestrateur central qui sélectionne et exécute les capacités autorisées.
- **Artefact :** livrable ou ressource identifiable, versionnable et relié à un contexte.
- **Brand DNA :** représentation de référence et versionnée de l’identité d’une marque.
- **Brand kit :** ensemble de règles, d’actifs et de documents cohérents dérivés d’une identité de marque.
- **Calque :** élément de composition indépendant, ordonné et modifiable lorsque le format le permet.
- **Capacité :** fonction qu’un module expose à l’interface ou à l’agent au travers d’un contrat.
- **Design Space Pro :** premier environnement créatif professionnel du périmètre initial.
- **Initiative :** fil de continuité d’un résultat global que l’utilisateur cherche à atteindre.
- **Moteur spécialisé :** composant qui réalise un domaine de création, de calcul, de rendu ou de validation.
- **Persona :** profil d’usage qui adapte la présentation et les parcours sans limiter les capacités disponibles.
- **Source de vérité :** propriétaire d’une donnée métier et de ses règles de modification.
- **Workspace :** vue de travail qui relie l’utilisateur et le contexte d’une initiative.

---

# Conclusion

Aurora doit évoluer d'une suite de modules vers un produit intégré qui aide l'utilisateur à développer ses projets, ses connaissances et ses créations. Les modules existants restent en place ; Design Space Pro ajoute une première capacité professionnelle visible, structurée autour du Brand DNA, des logos, des chartes, des affiches et des documents professionnels multipages.

Le Web responsive devient la première surface complète, Desktop approfondit les tâches professionnelles, puis Mobile fournit une expérience adaptée plutôt qu'une réplique de chaque éditeur. Les studios 3D, vidéo, musique et Web avancé sont conservés dans la vision et organisés dans la roadmap.

La stack de référence est désormais consignée dans cette version : TypeScript, Ionic React, Capacitor, Electron, Next.js, PowerSync/SQLite, Supabase/PostgreSQL, Zod et Agent Aurora, avec une sélection contrôlée des briques TanStack et d'éditeurs spécialisés. La prochaine étape est d'auditer le dépôt, vérifier les versions et licences, puis exécuter les POC prioritaires de routage, synchronisation, état des données, génération structurée et exports. Les sources divergent encore sur l'état réel de l'implémentation et certaines supposent un lancement mobile-first : ces contradictions doivent être résolues avant de lancer les lots de développement Web-first.
