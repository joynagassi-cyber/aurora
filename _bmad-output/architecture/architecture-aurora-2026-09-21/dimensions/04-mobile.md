---
name: "Aurora — Dimension Mobile (Ionic React + Capacitor, Android Phase 1, pack de contrat, vague 0)"
type: dimension-pack
altitude: initiative
companion-of: ARCHITECTURE-SPINE.md (autorité, read-only)
sources:
  - ARCHITECTURE-SPINE.md (AD-1…AD-16 + F-01…F-10, statut final, 2026-09-21)
  - adr-extract.md (ADR v1.7 gelé, sections 23–24 Phase 1 Mobile Only)
  - reviews/review-adversary.md
status: wave-0-draft
created: 2026-09-21
owner: équipe App Shell (feature agents consument ce pack)
binds: "apps/mobile, packages/platform (couche platform, AD-7/doc 23.3)"
consumes: ["02-frontend.md (state, use-cases, routing)", "03-sync.md (repositories, offline)", "01-backend.md (jobs, AppError, OneSignal serveur)", "05-design-system.md (composants + contrats AD-10)"]
adRefs: [AD-1, AD-3, AD-7, AD-8, AD-9, AD-13, AD-15, AD-16, F-03, F-09, doc §23, doc §24]
---

# 04 — Dimension MOBILE (Ionic React + Capacitor)

> Pack de dimension « Contract Pack » (wave 0) — cible **Android uniquement, Phase 1** (ADR §23,
> spine § Stack : Electron est Phase 2, **absent du V1**). Ce pack est **prescriptif** pour les
> agents de développement : il référence le spine (AD-x) sans le répéter, et approfondit la couche
> **plateforme** (doc §23.2/§23.3) là où le spine reste volontairement silencieux. Les AD-x citées
> sont contraignantes et read-only. Le contenu est en français ; les identifiants de code
> (noms de packages, interfaces, Capacitor plugins, événements) sont en anglais.
>
> Ce pack **consomme** `02-frontend.md` (il ne ré-invente ni le state ni le routing : § 2 ci-dessous
> se réfère) et **approfondit** `01-backend.md` (jobs, OneSignal serveur, `AppError`) et
> `03-sync.md` (PowerSync/SQLite, offline). Le Design System (composants, tokens, contrats AD-10)
> vit dans `05-design-system.md` — ce pack ne le définit pas (AD-13, une seule équipe écrit
> `packages/ui`).

---

## 1. Périmètre et objectifs

**Périmètre du pack** : tout ce qui est **spécifique à la plateforme mobile** dans la Phase 1,
c'est-à-dire la couche `Platform` (doc §23.3 : « couche spécifique Android/mobile ou desktop,
isolée derrière des interfaces ») plus les capacités natives qu'elle expose à l'app :

- **`packages/platform`** : la **couche d'adapters** Capacitor. L'app (`apps/mobile`, pack 02)
  n'importe **que l'interface** ; **jamais** `@capacitor/*` directement (§ 23.2 du doc : « les
  hooks, services, use-cases, repositories, types et modèles doivent rester indépendants de
  Capacitor »).
- **Plugins Capacitor & adapters natifs** (section 3) : notifications (OneSignal + locales
  Capacitor), stockage fichiers (upload via R2 présigné, pack 01 § 5.4), caméra/scan
  (`DocumentScanner`/`OCRProvider` — v1.5), audio (`AudioArtifactProvider`,
  `TranscriptionProvider` optionnel — v1.5), détection réseau (`@capacitor/network`, pack 02 § 7).
- **Focus Controller** (section 4, doc §2.8) : blocage/restriction des apps distrayantes
  **lorsque la plateforme le permet** — **le blocage natif doit être validé techniquement par
  plateforme AVANT d'être promis** (règle expresse du doc §2.8, à valider ici car Android,
  section 4.1) ; réduction des notifications pendant une session Focus.
- **Contraintes perf/batterie mobile** (section 6) : le cap `first-interactive` du pack 02
  s'appliquant, ici on y ajoute les **lignes rouges mobiles** : cycle de vie (foreground/background),
  batterie, données, mémoire.
- **Tests E2E mobile** (section 7, doc §23.1 : « QA, tests E2E et critères de release de la
  Phase 1 sont centrés sur l'expérience mobile ») : smoke **Capacitor Android** (device réel,
  vague 7 QA, doc §21.12). *(Typo corrigée : « Tèste » → « Tests ».)*
- **Règle Phase 2 Electron** (section 8.2) : le cœur reste **platform-agnostic**
  (doc §23.2/§23.3) ; **aucun adapter desktop n'est écrit en V1** (spine § Deferred).

**Objectifs opérationnels du pack** :

1. Trancher **qui détient `packages/platform`** et la **liste blanche de Capacitor plugins
   autorisés** (section 2–3) : l'app Shell team ne peut ajouter un plugin qu'en PR (spine §
   Consistency Conventions).
2. Figer **les contrats TS des adapters** (notifications, fichiers, scan, audio, focus, réseau)
   que l'app **consomme** — l'app ne voit que ces interfaces, jamais le plugin (AD-1, § 23.3).
3. Trancher la **stratégie de validation du blocage natif** (Focus, doc §2.8) : Android
   **ne bloque pas** nativement les apps tierces (pas de permission app-level lock) — donc le
   produit promet une **limitation/restriction** (rappel + DND + Focus in-app), **jamais** un
   « blocage absolu » (section 4, décision normative).
4. Figer les **états de cycle de vie** (foreground/background/kill) et leur impact sur
   PowerSync/sync (pack 03) et les jobs (pack 01) : **retour foreground = re-sync
   automatique**, jamais un écran crashé.
5. Figer la **stratégie de batterie/perf mobile** (section 6) : throttling sync en
   background, pas de polling réseau en app background, `IonList` natif pour longues listes.

**Hors périmètre de ce pack** :

- Design system / écrans → `05-design-system.md` + dimension design (l'inventaire des écrans
  est une partie **complète à part entière** de l'architecture, portée par le pack design).
- Schéma SQL / PowerSync / supabase / jobs serveur / OneSignal serveur → `01-backend.md`,
  `03-sync.md` (ce pack consomme, ne définit pas).
- Le cœur applicatif (state, routing, use-cases, contrats AD-10 consommés) → `02-frontend.md`.

---

## 2. Modules / packages concernés (AD-13, AD-15, AD-16 ; matrice doc §21.2)

Écriture unique (one-writer-per-file, AD-13) :

| Package / app | Équipe owner | Rôle dans cette dimension |
|---|---|---|
| `apps/mobile` | **App Shell team** | La seule app déployable Phase 1 (spine § Structural Seed). Importe **uniquement** les interfaces de `packages/platform` (§ 23.3) — **jamais** `@capacitor/*` en dur. |
| `packages/platform` | **Foundation** | Couche adapters Capacitor (doc §23.3 « Platform »). Possède : (a) le `capacitor.config.ts` de l'app, (b) le **whitelist de plugins** (§ 3), (c) les **interfaces d'adapter** que l'app consomme (§ 3.2). L'app Shell team **n'y écrit que par PR** (AD-13, §21.10). |
| `packages/integrations` (mobile) | **Integrations team** | Le **serveur** possède OneSignal (pack 01 § 5.1, `fn-notifications`) ; ce que **mobile** possède ici : le plugin Capacitor OneSignal + le listener local qui route les notifications vers l'app (section 3.3). L'équipe mobile **ne s'authentifie JAMAIS** sur l'API OneSignal (AD-3, pas de clé sur l'appareil) — elle reçoit les URLs présignées / le token **par l'app**. |
| `packages/data` (consommation) | **Data team** | Le store local (PowerSync/SQLite) et ses repositories ; la couche de `packages/platform` **ne touche JAMAIS** le store (AD-7, F-03 : single-writer par entité locale, `03-sync` § 4) — un adapter **écrit** uniquement via le use-case du module owner. |
| `packages/domain` (consommation) | owner par entité (AD-15) | Types de domaine SSoT ; les adapters **reçoivent/retournent** ces types (ex. un scan produit une `Document` → `OCRProvider` la qualifie) ; l'adapter ne redéclare jamais une shape (F-01). |

**Règle de dépendance (AD-1 / §23.2)** : `packages/platform` peut importer `@capacitor/*`
**et seulement** la whitelist de § 3.1 (les plugins sont des implémentations derrière des
contrats, comme les moteurs AD-10 — AD-1). Tout autre import fournisseur/SDK dans
`packages/platform` = **blocking finding** en review. `apps/mobile` n'importe **que**
`packages/platform` (les interfaces), **jamais** `@capacitor/*` (lint boundary CI, § 7).

**Ownership des fichiers (AD-13, §21.2)** :
- `apps/mobile` (toutes les pages, layouts, `capacitor.config.ts` **hors** le plugins section)
  → App Shell team.
- `packages/platform` (l'adapter) → Foundation (doc §21.2 : Foundation possède
  configuration racine, workspace, conventions et tooling — le `capacitor.config.ts` et le
  manifest Android vivent ici).
- `android/` (code natif Android généré par `npx cap add android`) → Foundation **exclusif**
  (le code natif **est** `packages/platform` déployé ; l'app Shell team n'y touche pas).

---

## 3. Contrats (interfaces TS publiques des adapters — AD-9 prod/consom, AD-1)

### 3.1 Capacitor plugins — whitelist normative (vague 0, à ratifier par Foundation)

Le pack **gèle** la liste des plugins Capacitor autorisés dans le V1. Tout plugin non listé ici
exige une PR d'ajout (spine § Consistency Conventions : « adding external deps without
justification + review » = interdit) :

| Plugin Capacitor (v) | Rôle | Adaptateur (interface) |
|---|---|---|
| `@capacitor/app` | Cycle de vie (`appStateChange`), back button, identité app | `AppLifecycleAdapter` (§ 3.2.1) |
| `@capacitor/status-bar` / `@capacitor/keyboard` | Immersion clavier/status bar | via `AppLifecycleAdapter` |
| `@capacitor/filesystem` | Accès local (cache d'images/thumbnails R2) | `LocalFileStorageAdapter` (§ 3.2.2) |
| `@capacitor/filesystem` + `@capacitor/http` (ou R2 direct) | Upload → presigned URL (pack 01 § 5.4) | `LocalFileStorageAdapter.upload()` |
| `@capacitor/camera` | Scan doc (DocumentScanner) | `DocumentScanner` (§ 3.2.3) |
| `@capacitor/media` / `@capacitor/audio` (ou `@awesome-cordova-plugins`) | Enregistrement audio (cours, voice note) | `AudioArtifactProvider` (§ 3.2.4) |
| `@onesignal/cordova` (via Capacitor / `@onesignal/react`) | Notifications push (serveur, pack 01) | `RemoteNotificationAdapter` (§ 3.2.5) |
| `@capacitor/push-notifications` | Notifications **locales** (rappels Focus, tâches) | `LocalNotificationAdapter` (§ 3.2.5) |
| `@capacitor/network` | Détection online/offline (pack 02 § 7) | `NetworkStatusAdapter` (§ 3.2.6) |
| `@capacitor/splash-screen` + `@capacitor/status-bar` | Boot sequence | via `AppLifecycleAdapter` |
| `@capacitor/app` (background activity) | Maintien sync dans le background (section 6) | `AppLifecycleAdapter` |

**Règle (AD-1 / AD-3)** : un plugin = une implémentation derrière une interface. **Aucun**
code de feature (use-case, écran) n'importe un plugin directement ; il consomme **l'adapter**
(§ 3.2). Le whitelist est **additif** (n'ajouter un plugin = PR approuvée par Foundation) —
**jamais** un `npm install @capacitor/xxx` fait en feature sans PR (spine §21.10).

### 3.2 Interfaces TS des adapters (la seule surface publique que l'app consomme)

```ts
// packages/platform — contrats consommés par apps/mobile (AD-1, §23.3 ; l'app ne voit que ceci)

// 3.2.1 Cycle de vie (§23.2 : l'app reste indépendante de Capacitor)
export interface AppLifecycleAdapter {
  readonly platform: 'android';                       // V1 = android ; la Phase 2 ajoutera 'desktop'
  onAppStateChange(cb: (state: AppState) => void): Unsubscribe;
  canGoBack(): boolean;                                 // back natif (section 6.1, pack 02 § 6.3)
  goBack(): void;
  getPermission(name: 'BACKGROUND_ACTIVITY' | 'FOREGROUND_SERVICE' | 'POST_NOTIFICATIONS'):
    'granted' | 'denied' | 'undetermined';              // surface unique des permissions natives
  requestPermission(name: 'FOREGROUND_SERVICE'): Promise<boolean>;
  // `FOREGROUND_SERVICE` (API 34+) : requis uniquement si le sync doit continuer en background
  // prolongé (O4, §6.1) — la décision d'activer/désactiver ce mode appartient au pack 03
  // (PowerSync sync engine, §5.7 owner `packages/data`) ; ce pack **impose** la contrainte
  // (throttling ≥ 5 min, pas de polling), le pack 03 **définit** le paramètre `minSyncIntervalMs`
  // et décide si `FOREGROUND_SERVICE` est nécessaire. La permission est demandée par le pack 03
  // (au premier passage en background > 30 s, si O4 = sync continue), JAMAIS au boot (§3.4).
  // `POST_NOTIFICATIONS` : demandée au premier usage (rappels locaux, §3.4), pas au boot.
}
export type AppState = 'foreground' | 'background';     // pas 'killed' — pas fiable ; voir § 6.1

// 3.2.2 Stockage fichiers local (cache de previews, scan temp)
export interface LocalFileStorageAdapter {
  saveBlob(mime: string, bytes: Uint8Array): Promise<string>; // → fileId local
  getFile(fileId: string): Promise<Uint8Array>;
  deleteFile(fileId: string): Promise<void>;
  // UPLOAD → R2 (le client poste SUR R2 via URL presignée ; la clé R2 n'est JAMAIS ici, AD-3)
  upload(fileId: string, presigned: { url: string; method: 'PUT'; headers: Record<string,string>; expiresAt: number },
         onProgress?: (pct: number) => void): Promise<{ r2Key: string; sha256: string }>;
  // PACK 01 § 5.4 : presignGet/presignUpload sont EMIS par l'Edge Function, JAMAIS par le client
}

// 3.2.3 DocumentScanner + OCRProvider (ADR v1.5, § « Capture documentaire — Scanner + OCR »)
// Le FLUX cible (doc v1.5) : caméra → scan pages → OCR → structuration → KB → extraction → Learning.
// « Aucun moteur OCR précis n'est imposé au cœur applicatif : l'implémentation reste interchangeable. »
export interface DocumentScanner {                       // contract v1.5
  capturePage(opts: { source: 'camera' | 'gallery'; allowMulti?: boolean }): Promise<ScannedPage[]>;
  // ScannedPage = { fileId: string; mime: 'image/*'; bytesSize: number; capturedAt: Date }
  // L'OCR se passe CÔTE SERVEUR (job AD-8, pack 01 § 5.1 fn-import-course) ; l'app ne fait QUE
  // capturer + uploader (LocalFileStorageAdapter.upload) + déclencher le job.
}
export interface OCRProvider {                            // contract v1.5 (le SERVEUR l'implémente,
  // l'app ne la voit QUE via AppError (pack 02 § 10) ; la présence du provider est optionnelle
  isAvailable(): Promise<boolean>;   // si false → l'UI dégrade : saisie manuelle (AD-1 last par)
}
// RÈGLE (AD-1) : le capteur (camera) est mobile ; le moteur OCR est serveur (job, AD-8).
// L'app ne contient JAMAIS un moteur OCR embarqué.

// 3.2.4 Audio — AudioArtifactProvider (v1.5) + TranscriptionProvider (OPTIONNEL, v1.5)
export interface AudioArtifactProvider {
  record(opts: { maxSec?: number }): Promise<AudioArtifact>;  // AudioArtifact = { fileId, mime:'audio/*', durationSec, sampleRate }
  stopRecording(): Promise<void>;
  stream(fileId: string): Promise<ReadableStream>;           // lecture locale
  // « La transcription est indépendante de la lecture audio. » (doc v1.5)
  export(fileId: string): Promise<AudioArtifact>;            // → ArtifactProvider (AD-10) si c'est un cours
}
export interface TranscriptionProvider {                    // OPTIONAL (doc v1.5)
  isAvailable(): Promise<boolean>;  // AD-1 : « une capacité absente doit dégrader proprement »
  transcribe(fileId: string): Promise<{ jobId: string }>;   // → job serveur (AD-8), PAS du STT local V1
  // « Le système doit accepter l'absence de provider, fonctionner sans transcription et
  //    permettre l'ajout d'un provider cloud ou local sans modification du domaine. »
}

// 3.2.5 Notifications (ADR §7 : « Notifications mobiles : OneSignal + Capacitor local »)
export interface RemoteNotificationAdapter {                  // OneSignal = SERVEUR (pack 01 fn-notifications)
  // L'APP ne tient JAMAIS la clé OneSignal **serveur-side** (AD-3). Distinction normative
  // (fix, clarifie R4 + test 7.2(e)) :
  //  - L'`appKey` OneSignal (app-specific) est **gérée par Foundation dans
  //    `capacitor.config.ts`** (owner Foundation, AD-16c, §2 du pack) — le plugin
  //    `@onesignal/react` reçoit sa config via le `capacitor.config.ts` (pas un import TS
  //    dans le code de feature).
  //  - La **clé OneSignal serveur-side** (celle qui envoie les pushes via l'API OneSignal)
  //    est **JAMAIS** dans le bundle : elle vit côté serveur (pack 01 § 5.1, `fn-notifications`),
  //    et le test 7.2(e) vérifie que `capacitor.config.ts` (owner Foundation) ne contient
  //    **pas** de clé OneSignal serveur-side (la clé `appKey` ≠ la clé serveur OneSignal).
  //  - Le `token` OneSignal (token de push par utilisateur) est **émis par le serveur**
  //    (Edge Function, pack 01) — l'app reçoit le token, ne gère pas la clé.
  init(appKey: string /* via capacitor.config.ts, owner Foundation */): Promise<void>;
  onForegroundNotification(cb: (n: OneSignalNotification) => void): Unsubscribe; // click → route (pack 02 § 6)
  getSubscribed(): Promise<boolean>;
  setSubscribed(on: boolean): Promise<void>;  // respecte les « périodes de silence » du coaching (ADR §13)
}
export interface LocalNotificationAdapter {                   // rappels Focus / tâches dues (doc §2.4)
  scheduleLocal(id: string, at: Date, payload: { title: string; body: string; route?: string }): Promise<void>;
  cancelLocal(id: string): Promise<void>;
  // Pendant une session Focus : l'app **réduit** les notifications (doc §2.8) :
  reduceForFocus(on: boolean): void;   // = silences toutes les notifications non-critiques
}
export interface OneSignalNotification { id: string; title: string; body: string; data?: Record<string,string>; route?: string; }

// 3.2.6 Réseau (pack 02 § 7, détection offline)
export interface NetworkStatusAdapter {
  readonly online: boolean;
  onNetworkChange(cb: (online: boolean) => void): Unsubscribe;
}
```

### 3.3 Événements AD-9 produits/consumés côté mobile

Le mobile **ne produit aucun événement du vocabulaire AD-9** (AD-9/F-09 : les événements
agentiques sont produits côté serveur). Ce que le mobile **consomme** (déclaré ici, AD-13) :

- **`JobCompleted`** (F-08 : `jobId`+`jobKind` obligatoires) → état `success` UI (pack 02 § 7) ;
  le mobile filtre par `jobKind` (ex. `ocr`, `transcription`, `artifact_gen`) pour surfacer le
  succès **uniquement** des jobs qu'il a déclenchés.
- **`ArtifactGenerated`** (F-06 : post-upload R2) → l'app télécharge via `LocalFileStorageAdapter`
  l'artefact (presigned `presignGet`, pack 01 § 5.4) et l'ouvre dans l'Artifact Hub (AD-10).
- **`TaskCompleted` / `GoalUpdated` / …** : le mobile **lit** ces états via PowerSync (pack 03),
  **ne les consomme JAMAIS** comme événements directs (AD-7 : la UI lit le store local, F-03).

**Règle (AD-13, F-04)** : un consommateur d'événement = **déclaré** dans ce pack ; tout
consommateur non listé ici = violation blocking.

### 3.4 Notifications (OneSignal + Capacitor local) — contrats et flux

- **OneSignal** = les notifications **push** (serveur, pack 01 § 5.1 `fn-notifications`) :
  coaching check-ins (ADR §13), jobs terminés (pack 01), rappels. L'app (mobile) reçoit via
  `RemoteNotificationAdapter` (§ 3.2.5) ; le **serveur** est le seul à appeler l'API OneSignal.
- **Capacitor local** = les notifications **locales** (sans réseau) : rappels de tâches/
  événements dus **aujourd'hui** (doc §2.4), minuterie Focus/Pomodoro (doc §2.8). Elles sont
  programmées **par l'app** via `LocalNotificationAdapter.scheduleLocal()` quand elle détecte
  une deadline locale ; **pas de serveur requis**.
- **Séparation normative** : une notification **due à un état serveur** (un job, un coaching
  check-in) = OneSignal (serveur). Une notification **due à une deadline locale connue**
  (tâche due 9h, focus session de 25 min) = Capacitor local. **Jamais les deux pour le même
  objet** (anti-double-push, test § 7).
- **Permissions** : `POST_NOTIFICATIONS` (Android 13+) demandée **au premier usage** (pas au
  boot) ; l'utilisateur qui refuse → l'app continue (les tâches restent dues dans l'app,
  seule la notification est désactivée). `FOREGROUND_SERVICE` (si sync en background,
  section 6.2) demandée au premier passage en background de plus de 30 s.

---

## 4. Focus Controller (doc §2.8) — le blocage natif doit être validé techniquement

> **Règle du doc §2.8 (expresse) : « Le blocage natif doit être validé techniquement par
> plateforme avant de promettre un blocage absolu. »** — cette section **est** cette
> validation pour Android (Phase 1). Elle tranche ce qu'on **peut** promettre.

### 4.1 Validation technique — Android, Phase 1

| Capacité « Focus » (doc §2.8) | Android supporte-t-il nativement ? | Verdict Phase 1 |
|---|---|---|
| **Timer/Pomodoro** (doc §2.8) | ✅ `LocalNotificationAdapter` + in-app timer | **Promise** (in-app) |
| **Réduction des notifications** pendant une session (doc §2.8) | ✅ `reduceForFocus()` (DND via `NotificationManager` / OneSignal `setSubscribed(false)` + mute locale) | **Promise** |
| **Blocage des apps distrayantes** (doc §2.8) | ❌ Android **n'expose JAMAIS** une API pour une app tierce de bloquer/empêcher une autre app (pas de « app lock » public ; c'est le rôle de **Screen Pinning** / **Do Not Disturb** / **App Timers** du **système**, pas d'une app ; et Aurora **n'est pas** le système). **Digital Wellbeing** (Android 12+) le fait mais n'est **pas** une API tierce accessible. | **Ne PAS promettre le blocage absolu** — on promet **restriction** (cf. 4.2) |
| **Session Focus (temps, bilan)** (doc §2.8) | ✅ `FocusSession` (AD-15) + historique (doc §2.8) | **Promise** |

**Décision normative (Focus Controller, Phase 1 Android)** : le produit **ne promet JAMAIS**
un « blocage des apps distrayantes » (impossible techniquement sur Android sans être
l'appareil lui-même). Il promet :

1. **In-app Focus Mode** : l'app entre en Focus (un switch UI), met `reduceForFocus(true)` →
   silences toutes les notifications non-critiques (OneSignal mute + local mute), active le
   timer/Pomodoro.
2. **Option DND système (recommandée, non imposée)** : l'app **guide** l'utilisatrice vers
   l'interrupteur Android **Do Not Disturb** (API `@capacitor` n'existe pas nativement pour ça ;
   on pointe vers les réglages du système) pour un blocage plus fort. C'est une **recommandation
   utilisateur**, pas une promesse produit.
3. **Option Screen Pinning (optionnel, à demander)** : l'app peut demander à l'utilisateur
   « Activer le Screen Pinning pour cette session ? » (API `@capacitor` via un plugin natif ou
   `startLockTask` Android) — l'utilisateur autorise explicitement ; l'app **ne le fait jamais**
   silencieusement.
4. **Historique** : chaque `FocusSession` (AD-15 : durée, tâches associées, interruptions,
   score de concentration) est persistée (Productivity module, pack 01 § 4.1) ; bilan de
   session (doc §2.8) = lecture locale + rendu G2 (**`DataVisualizationRenderer`**, pack 02
   §5.3 / pack 05 : le graphique de bilan Focus est un spec `ChartSpec` consommé par
   `apps/mobile` via `packages/ui` — l'écran de bilan Focus **doit** être dans l'inventaire
   d'écrans du pack 05 avec le G2 contractuel ; si le pack 02 ne définit pas cette vue G2,
   les équipes Productivity + Design produisent des UIs de bilan incompatibles — le pack
   05 porte le contrat, pas le pack 02).

**Le port `FocusController` (contrat interne, ADR §8)** : son implémentation mobile V1 =
`packages/platform` (§ 3.2, `reduceForFocus()` + timer + DND recommendation). La
**validation du blocage natif** est ce que cette section **documente** : Android ne permet pas
le blocage d'apps tierces → **on ne le promet pas** (doc §2.8 règle = respectée).

> **TODO vague 0 (Foundation + Productivity)** : valider **avec précision** la disponibilité
> de `startLockTask()` (Screen Pinning) sur les versions cibles Android (API 21+) et décider
> si on l'expose comme option **utilisateur** (recommandation) ou non. Ce n'est **pas** un
> blocant pour la Phase 1 (le Focus Mode in-app suffit) mais c'est une ouverture (O3, § 8.3).

### 4.2 Contrat `FocusController` (le port interne, ADR §8)

```ts
// packages/domain (SSoT, AD-15) — le port interne FocusController, ADR §8
export interface FocusController {
  startSession(opts: { durationMin?: number; taskIds?: string[]; context: string }): Promise<FocusSession>;
  endSession(): Promise<FocusSessionBilan>;          // bilan (doc §2.8) : durée réelle, interruptions, score
  reduceNotifications(on: boolean): Promise<void>;    // via adapters § 3.2.5
  // Phase 1 Android : « reduceNotifications » est la capacité PROMISE ; le blocage natif
  // d'apps tierces n'est PAS une capacité (section 4.1). La doc §2.8 est respectée.
  isBlockingAvailable(): Promise<boolean>;            // V1 = false sur Android ; ne PAS cacher, on ne le promet pas
}
```

**Règle** : si `isBlockingAvailable()` = `false`, l'UI **n'affiche jamais** un CTA « bloquer
les apps » (ça serait promettre un blocage non validé, violation doc §2.8). L'UI affiche la
capacité **réelle** : réduction + timer + (optionnel) Screen Pinning recommandé.

---

## 5. Stockage fichiers, caméra/scan, audio (récap des contrats consommés)

> Détail normatif en § 3.2 (les interfaces). Cette section donne la **règle d'usage** que les
> agents doivent suivre : **qui** fait quoi, côté mobile vs côté serveur.

| Capacité | Côté mobile (ce que l'app FAIT) | Côté serveur (ce que l'app ne fait PAS, packs 01/03) |
|---|---|---|
| **Scan document** (doc v1.5) | `DocumentScanner.capturePage()` (camera) + `LocalFileStorageAdapter.upload()` → R2 | OCR + structuration + ingestion KB = **job** (AD-8, pack 01 § 5.1 `fn-import-course`), jamais dans l'app (AD-1 : pas de moteur embarqué) |
| **Audio** (doc v1.5) | `AudioArtifactProvider.record()` (enregistrement) + lecture locale (`stream()`) | Transcription (si provider) = **job serveur optionnel** (AD-8) ; pipeline audio (ADR v1.5) : Audio Artifact → TranscriptionProvider (optionnel) → Transcript → … Les traitements lourds sont asynchrones et persistés comme Jobs. **Note (AD-10)** : le **rendu** de la waveform + timestamps du cours audio (`AudioWaveformRenderer`, contrat AD-10, owner Design System, pack 05) est un **composant React pur dans `packages/ui`** (pas un adapter Capacitor) — `packages/platform` ne l'expose **pas** ; `apps/mobile` le consomme directement via `packages/ui` (comme les 5 contrats AD-10, pack 02 §5). Le lecteur audio local (`stream()`) est le seul point d'intersection avec `packages/platform`. |
| **Fichiers R2** | `LocalFileStorageAdapter.upload(fileId, presigned)` (le client poste **sur** R2 via URL presignée) ; `presignGet` pour preview | Les **URLS présignées sont émises par l'Edge Function** (service role) — le client **n'a JAMAIS** une clé R2 (AD-3, pack 01 § 5.4) |
| **Fichiers générés (artefacts)** | L'app **télécharge** (presigned GET) quand `ArtifactGenerated` arrive (§ 3.3) et ouvre dans Artifact Hub (AD-10) | L'artefact est généré + uploadé **serveur** (job, pack 01 § 5.1 `fn-generate-artifact` → `ArtifactGenerated` post-upload, F-06) |
| **Cache local (images/thumbs)** | `LocalFileStorageAdapter.saveBlob/getFile` (cache des previews R2 pour l'offline, AD-7) | Les fichiers « source » sont **toujours** dans R2 (serveur) ; le cache local est **déductible/reconstruisible** (pas une source de vérité, AD-7 : le store local est la vérité UI, pas le cache de fichiers lourds) |

**Règles fortes (normatives)** :

1. **Pas de clé fournisseur sur l'appareil** (AD-3) : R2 presigned uniquement (pas de
   `aws-sdk`), OneSignal token émis par l'app (pas de clé serveur dans l'app), OCR/STT =
   jamais embarqué (AD-1). Tout provider = URL presignée ou endpoint serveur (pack 01).
2. **Toute capacité coûteuse/optionnelle se dégrade proprement** (AD-1 last paragraph, doc v1.5
   principe complémentaire) : OCR absent → saisie manuelle ; TranscriptionProvider absent →
   lecture audio fonctionne, le transcript est optionnel ; R2 indisponible → l'app continue
   (le cache local des previews), l'upload est différé (job à re-pousser au retour réseau).
3. **Le domaine ne dépend jamais d'un fournisseur** (AD-1) : les adapters (§ 3.2) sont des
   interfaces ; le code de feature consomme l'interface, jamais le plugin Capacitor.

---

## 6. Contraintes perf / batterie / cycle de vie mobile

> Le pack 02 (§ 9) fixe le budget **web** (first-interactive ≤ 300 Ko JS gz, TTI ≤ 1.5 s sur
> Android mid-range). Cette section ajoute les **lignes rouges mobiles** (battery, network,
> memory, lifecycle) qui ne sont pas dans le pack web.

### 6.1 Cycle de vie (normatif)

- **Foreground** : l'app lit le store local (PowerSync/SQLite, pack 03), synchronize en
  arrière-plan ; **aucun** polling réseau dans le UI (AD-7 : la sync ne bloque jamais un frame).
- **Passage en background** (délai > 30 s) : (a) la sync PowerSync continue **throttlée**
  (pas de boucle serrée) ; (b) les **jobs long** (OCR, transcription) sont **serveur** (AD-8,
  pack 01) — l'app n'a **pas** à les maintenir ; (c) `FOREGROUND_SERVICE` **seulement si**
  la sync doit continuer au-delà d'une limite (à valider, O4).
- **Retour au foreground** : **re-sync automatique** (PowerSync re-pousse/pull) ; l'app **re-
  valide** son état local (si un job serveur a produit un `ArtifactGenerated`/`JobCompleted`
  pendant l'absence, l'app le consomme au retour, § 3.3). L'écran **ne doit jamais** crasher
  au retour foreground (test § 7).
- **Pas d'état « killed »** : Android n'expose pas un signal fiable de kill (l'app peut être
  tuée par le système à tout moment). Donc **tout** l'état important vit dans le store local
  (AD-7) — **pas** dans `localStorage`/Zustand. C'est la règle qui rend le « kill » inoffensif :
  au reboot, l'app relit le store local et reprend là où elle était.

### 6.2 Batterie & données (lignes rouges, mesurables)

- **Pas de polling réseau en app background** : si sync doit continuer, c'est via un
  **background sync throttlé** (intervalle ≥ 5 min, ou déclenché par retour réseau) — jamais
  une boucle de 5 s.
- **Throttling sync** : la fréquence de sync PowerSync **baisse** automatiquement quand
  l'app est en background (pack 03 gère la mécanique ; ce pack **impose** la contrainte).
- **Métrique batterie** : **pas de SLO** strict (variable par appareil), mais Sentry perf
  (pack 02 § 9.4) mesure la **consommation anormale** (app qui reste chargée sans raison).
- **Données** : une session Focus **n'entraîne JAMAIS** d'upload réseau (pas de sync
  forcé pendant une session — le respect du Focus, doc §2.8).

### 6.3 Mémoire (mobile-first)

- Les **lignes rouges** du pack 02 (§ 9) s'appliquent ; en plus, sur mobile on **interdit** :
  (a) charger un artefact lourd dans le DOM (PDF 50 pages = lazy paginé, pack 02 § 9.3) ;
  (b) tenir en mémoire le tree de 1 000+ nœuds (pack 02 § 9.2, 150 nœuds DOM max).
- **Test de fuite mémoire** (test § 7) : naviguer 50 écrans = la RAM ne doit pas croître
  au-delà de +50 Mo (sur appareil de référence, G5 pack 02).

---

## 7. Tests obligatoires (AD-13 DoD — à chaque PR de ce pack)

### 7.1 Smoke Capacitor Android (device réel, vague 7 QA — doc §23.1 : « QA centrée mobile »)

- **Lancement** de l'app sur un device Android **réel** (vague 7, doc §21.12) :
  build debug (`npx cap run android`) + un **build AAB** (`npx cap build android --prod`).
- **Test E2E mobile** (doc §23.1) : les **scénarios signature** du pack 02 (créer → terminer
  une tâche, Home AD-14, offline) **sont rejoués sur device** (pas seulement web/Playwright).
  Outil de ce pack = **Playwright + Capacitor (device driver)** ou un framework d'automatisation
  Android (choix retenu : Playwright + driver Capacitor, O2 — Appium = fallback si Playwright ne supporte pas le device Android 14) — le **contrat** est : chaque scénario signature tourne sur device.
- **Test de cycle de vie** (section 6.1) : (a) passage background → foreground = **re-sync**
  automatique, pas de crash ; (b) retour foreground après un `ArtifactGenerated` = l'artefact
  **apparaît** ; (c) kill de l'app (swipe) + relance = l'état local **est intact** (AD-7).

### 7.2 Tests par adapter (packages/platform)

- **Chaque adapter** (§ 3.2) a un **test d'interface** (un stub Capacitor mocké) :
  (a) `AppLifecycleAdapter.onAppStateChange` émet bien `foreground`/`background` ;
  (b) `LocalFileStorageAdapter.upload` ne contient **JAMAIS** de clé R2 (test d'anti-leak,
  AD-3) ; (c) `DocumentScanner` renvoie des `ScannedPage` conformes (mime, taille) ;
  (d) `AudioArtifactProvider.record` est annulable (stopRecording) ;
  (e) **`capacitor.config.ts`** (owner Foundation, §2) ne contient **PAS** de clé OneSignal
  serveur-side (AD-3 — la clé `appKey` app-specific est autorisée dans `capacitor.config.ts`,
  la **clé serveur** qui envoie les pushes via l'API OneSignal est **JAMAIS** dans le bundle :
  elle vit côté serveur, pack 01 § 5.1 `fn-notifications`). Le test vérifie le contenu de
  `capacitor.config.ts` (owner Foundation), **pas** un import de module de feature.
- **Test anti-couplage (CI, lint boundary)** : `apps/mobile` n'importe **JAMAIS**
  `@capacitor/*` (pack 02 § 5.6 règle = étendue) — la seule porte vers le natif est
  `packages/platform`. Toute violation = CI rouge (AD-1, § 23.3).
- **Test de whitelist** : tout plugin importé par `packages/platform` **est** dans la
  whitelist § 3.1 (un test CI qui liste les imports `@capacitor/*` et les compare à la liste ;
  un plugin non listé = CI rouge).

### 7.3 Tests Focus Controller (section 4)

- `FocusController.reduceNotifications(true)` **silence** réellement les notifications
  non-critiques (test : après `reduceForFocus(true)`, aucune notification locale planifiée
  non-critique ne sonne).
- **Anti-promesse** (doc §2.8) : `isBlockingAvailable()` = `false` sur Android → **l'UI ne
  rend JAMAIS** un CTA de blocage (test de non-affichage, section 4.2).
- **Pomodoro** (doc §2.8) : le timer se met en pause au passage background (6.1) et se
  **reprend** au retour (l'heure restant correcte, pas perdue).

### 7.4 Tests de dégradation propre (AD-1 last paragraph, doc v1.5)

- **OCR absent** (`OCRProvider.isAvailable()` = false) : le pipeline documentaire **continue**
  (saisie manuelle proposée, pas de crash).
- **TranscriptionProvider absent** : la lecture audio **fonctionne**, le transcript est marquée
  indisponible (pas un erreur, un état).
- **Réseau coupé** : l'app **reste utilisable** (lecture locale AD-7), upload différé, jobs
  non-bloquants (pack 03 offline test, pack 02 § 11) — ce pack **ajoute** : le passage
  foreground **ne réessaye pas** un upload en boucle (backoff, pas de hammering du réseau).

### 7.5 CI du pack (obligatoire, doc §21.5 pipeline)

Type-check (TS) + lint/format + **lint boundary** (import Capacitor interdit en app, whitelist
de plugins CI) + build `apps/mobile` (web HMR + **`npx cap build android`** debug) + tests
unitaires (vitest, adapters mockés) + **test E2E mobile (device, vague 7)** + review Codex
(AD-13, blocking sur tout contrat public de `packages/platform`).

---

## 8. Risques et dépendances

### 8.1 Risques (avec mitigations)

| # | Risque | Impact | Mitigation (normative) |
|---|---|---|---|
| R1 | **Couplage app → `@capacitor/*`** (un dev importe le plugin directement « pour aller plus vite »). | Violation AD-1 / §23.2 (cœur platform-agnostic) ; la migration Electron Phase 2 devient une **réécriture** (plus une addition d'adapter, §23.4). | Lint boundary CI (section 7.2) : `apps/mobile` ne peut importer **que** `packages/platform` ; un import `@capacitor/*` direct = **CI rouge** (blocking). Le pack **verrouille** la séparation §23.3. |
| R2 | **Plugin non whitelisted ajouté** dans une feature (ex. ajouter `@capacitor/geolocation` pour « la localisation »). | Violation §21.10 (dépendance externe sans justification + review) ; la whitelist §3.1 saignée ; bloat bundle. | La whitelist §3.1 est **additive** (ajout = PR approuvée par Foundation) ; test CI de whitelist (§ 7.2) ; toute dépendance nouvelle = **blocking review** (spine § Consistency Conventions, Forbidden). |
| R3 | **Le blocage natif Focus est promis** par l'UI (un CTA « bloquer les apps ») alors qu'Android ne le permet pas (section 4.1). | Violation doc §2.8 (« le blocage natif doit être validé techniquement par plateforme AVANT de promettre ») ; promesse produit fausse ; déception utilisateur. | `FocusController.isBlockingAvailable()` = **false** sur Android (§ 4.2) ; l'UI **n'affiche JAMAIS** un CTA de blocage (test anti-promesse, § 7.3) ; on promet **restriction** (réduction + DND recommandé + option Screen Pinning utilisateur). Le **TODO vague 0** (Foundation) tranche si on expose Screen Pinning. |
| R4 | **Une clé R2 / OneSignal / AI finit sur l'appareil** (AD-3). | Violation AD-3 (provider keys sur le client, rate-limiting by-passable) ; compromission totale. | Les adapters (§ 3.2) **n'ont JAMAIS** de clé fournisseur (test d'anti-leak, § 7.2b/e) : R2 = presigned URL (émise par l'Edge Function, pack 01 §5.4), OneSignal = token **app** (pas la clé serveur), OCR/STT/AI = **jamais** embarqué (AD-1, jobs serveur AD-8). Un test CI vérifie qu'aucune clé ne part dans le bundle. |
| R5 | **Batterie/ données tuées par la sync** (polling serré en background). | Réputation mobile dégradée (l'app « mange la batterie ») ; non conforme §6.2. | Throttling sync en background (section 6.2, pack 03) ; **pas de polling réseau en background** (test § 7.4c) ; la **session Focus n'entraîne JAMAIS** d'upload réseau (§6.2) ; Sentry perf = SLO de consommation anormale (§6.2). |
| R6 | **Retour foreground = crash / état perdu** (tout l'état UI dans Zustand/localStorage, pas dans le store local). | Violation AD-7 (l'état important = store local) ; perte de travail utilisateur ; la Phase 1 mobile-only doit être **stable**. | Règle de cycle de vie (§6.1) : tout l'état **important** vit dans le store local (PowerSync/SQLite, pack 03) — **pas** Zustand/localStorage ; au retour foreground, re-sync + re-validation (test §7.1) ; le kill de l'app ne **perd** rien (test §7.1c). |
| R7 | **Double-notification** (OneSignal + locale pour la même deadline). | Spams l'utilisatrice ; violation ADR §13 (« dialogue bref et orienté action », pas de multiplication de notifications). | Séparation normative (§3.4) : une notification **due à un état serveur** = OneSignal **seul** ; une **deadline locale connue** = Capacitor local **seul** ; **jamais les deux** pour le même objet (test §7.4 / anti-double-push). |
| R8 | **Électron Phase 2 sauté** (un dev « commence le desktop adapter » en V1). | Violation §23.1 (« le One-Day Build et la première mise en production ne doivent pas inclure Electron ») ; dilution de la Phase 1 mobile-only ; le cœur se dégrade pour le desktop (trop tôt). | **Règle Phase 2 = platform-agnostic core** (doc §23.2/§23.3, §23.5 : « Mobile Only pour la livraison, Platform-Agnostic pour le cœur ») : ce pack ne définit **aucun** adapter desktop ; `AppLifecycleAdapter.platform` = `'android'` **seul** en V1 (§ 3.2.1) ; toute PR qui ajoute un adapter **desktop** en V1 = **rejet** (blocking, violation §23.1). La Phase 2 = **ajouter** un adapter (doc §23.4), **pas** réécrire le cœur — c'est ce que la séparation §23.3 **garantit**. |
| R9 | **Moteur OCR/STT embarqué** « pour l'offline » (un dev ajoute whisper.cpp / tesseract). | Violation AD-1 (le domaine ne dépend jamais d'un fournisseur/moteur) ; le pack §5.2 (spine § Deferred) fixe que le STT local (whisper.cpp) est une **capacité connue via `TranscriptionProvider` (optionnel)** mais **le moteur local concret est évalué plus tard sur de vrais appareils** — il n'est **pas** dans le V1. | `TranscriptionProvider.isAvailable()` = false en V1 (§ 3.2.4) ; la transcription = **job serveur** (AD-8, pipeline doc v1.5) ; **aucun** moteur STT embarqué (spine § Deferred : « Local STT (e.g., whisper.cpp on Android) — capability known to the core via TranscriptionProvider (optional) ; concrete engine evaluated later on real devices »). Un moteur local embarqué = violation AD-1 (blocking). |

### 8.2 Règle Phase 2 Electron (doc §23.2/§23.3/§23.4/§23.5) — rappel contraignant

> « **Mobile Only pour la livraison, Platform-Agnostic pour le cœur** » (règle architecturale,
> doc §23.5). Phase 1 = **strictement** mobile-only (doc §23.1 : « Toutes les fonctionnalités
> prioritaires sont conçues, développées, intégrées et validées **d'abord** sur mobile. Le
> One-Day Build et la première mise en production **ne doivent pas inclure Electron**. La QA,
> les tests E2E et les critères de release de la Phase 1 sont **centrés sur l'expérience
> mobile**. Aucun agent ne doit consacrer du temps à une implémentation desktop pendant cette
> phase. »).

Ce pack **garantit** la portabilité **sans** écrire le desktop :

1. **Le cœur est platform-agnostic** (doc §23.2) : la logique métier (`packages/domain`), le
   state (`apps/mobile` use-cases), les repositories (`packages/data`), les adapters
   **interfaces** (`packages/platform`) ne **dépendent JAMAIS** d'Electron (spine § Deferred :
   « no desktop adapter is in V1 »). Seule **l'implémentation** Android des adapters
   (`packages/platform` + `android/`) est spécifique plateforme (§ 2, ownership).
2. **Phase 2 = ajouter un adapter** (doc §23.4) : « Réutiliser au maximum les packages et
   composants existants. Ajouter les adapters Electron nécessaires aux capacités propres au
   desktop. Créer les layouts desktop **sans modifier inutilement** la logique métier. Réutiliser
   les contrats Agent, Data, Scientific Engine, Knowledge, Artifact et Integrations. Ajouter une
   couche de tests desktop **spécifique aux comportements propres à la plateforme**. Ne pas
   transformer la Phase 1 en développement cross-platform prématuré. » → la **preuve** que la
   Phase 1 est portable = les adapters sont **descriptifs par interface** (§ 3.2) ; un adapter
   desktop **implémenterait la même interface** (ex. `AppLifecycleAdapter.platform: 'desktop'`).
3. **En V1, aucun adapter desktop n'est écrit** (règle expresse) : `packages/platform` contient
   **uniquement** l'implémentation Android. Toute PR qui ajoute du code desktop en V1 =
   violation §23.1 (blocking, R8).

### 8.3 Dépendances (wave gating, doc §21.12 / spine merge order)

- **`02-frontend.md`** (state, routing, contrats AD-10 consommés, perf web) → ce pack s'appuie
  dessus (section 6 perf = **extension** du pack 02 §9).
- **`03-sync.md`** (PowerSync/SQLite repositories, offline, single-writer F-03) → ce pack
  consomme (section 6.1 cycle de vie re-sync, section 5 cache local reconstruisible).
- **`01-backend.md`** (jobs AD-8, OneSignal serveur, R2 presigned, `AppError`) → ce pack
  consomme (sections 3.4, 5 : OCR/STT = jobs serveur, upload R2 = presigned).
- **`05-design-system.md`** (composants + contrats AD-10) → ce pack **consomme** les
  composants ; les adapters ne **rendent JAMAIS** un composant DS (ils exposent des
  interfaces, la **présentation** reste dans `apps/mobile` via `packages/ui`).
- **Vague 0 (ce pack)** : trancher la whitelist de plugins Capacitor (§ 3.1, ratifier par
  Foundation) + le choix du framework d'automatisation Android pour le test E2E device (O2 : Playwright + driver Capacitor retenu, Appium = fallback) +
  le **TODO Focus natif** (Screen Pinning, section 4.1) + le device de référence Android (G5
  pack 02). **Vague 1 (Fondations)** : implémenter `packages/platform` (les adapters § 3.2) +
  le `capacitor.config.ts` + le manifest Android. **Vague 7 (QA)** : le test E2E mobile
  device réel (section 7.1, doc §23.1/§21.12).

### 8.4 Ouvertures (à trancher avant la vague 1)

- **O1 (gating, section 4.1)** : **trancher** si on expose **Screen Pinning** (`startLockTask()`)
  comme option utilisateur (recommandation) pour le Focus Controller — à valider par Foundation
  sur les versions Android cibles (API 21+). **Ce n'est PAS un blocant de la Phase 1** (le
  Focus Mode in-app = réduction + timer suffit, doc §2.8).
- **O2 (vague 7, section 7.1)** : framework d'automatisation Android pour le test E2E **device** —
  **décision figée (normative, plus d'ouverture)** : **Playwright + driver Capacitor (device réel)
  = choix retenu** ; Appium = fallback si Playwright ne supporte pas le device Android 14 (ADR
  éventuel). **Contrat d'intégration (normatif, le contrat = le test, l'outil = implémentation
  interne QA)** : chaque scénario signature du pack 02 (créer → terminer une tâche, Home AD-14,
  offline, re-sync au retour foreground) **tourne sur device** — le contrat est le **résultat**
  (pass/fail du scénario), l'outil (Playwright vs Appium) est une décision d'implémentation QA
  (vague 7, doc §21.12) qui ne change **pas** le contrat. Les deux packs (Data + QA) sont
  cohérents : le test E2E device est un **gate de la vague 7** (pas la vague 1), le contrat est
  ici, l'outil est interne QA.
- **O3 (gating, section 3.1)** : **ratifier la whitelist** de plugins Capacitor par Foundation
  (vague 0) ; c'est **additive** (tout ajout = PR), pas une rétro-gradation.
- **O3b (gating, AD-17 v2 — thème par défaut Android, session nocturne)** : trancher la valeur
  du thème au boot Android. À valider par Foundation (vague 0) : le thème par défaut **persisté**
  (le `theme: AuroraTheme` de `UserContext`, pack 01 §4 / AD-15, migré vers l'enum v2)
  **prévaut** sur le `prefers-color-scheme` du système Android pour la Phase 1 — un utilisateur
  qui a choisi `Aurora` + `themeStyle: light` au boot voit Light même si Android est en Dark
  (le Dark n'est pas une surprise au retour foreground, §3.4 : le kill de l'app ne change pas le
  thème). Alternative (à rejeter en V1) : le thème suit `prefers-color-scheme` Android ; c'est
  **interdit** en V1 car il violerait la règle de non-surprise du store UI (pack 02 §3.2 : le thème
  est persisté, il ne change jamais silencieusement au retour foreground).
- **O4 (section 6.1)** : **trancher** si la sync doit continuer **au-delà** d'un passage
  background (nécessité de `FOREGROUND_SERVICE`) — la mécanique de sync est owner `packages/data`
  (pack 03, §5.7 : le paramètre `minSyncIntervalMs` est défini par le pack 03 ; ce pack impose la
  contrainte). La permission `FOREGROUND_SERVICE` est demandée **par le pack 03** (au premier
  passage en background > 30 s, si O4 = sync continue), via la surface unique
  `AppLifecycleAdapter.requestPermission` (§3.2.1) ; **pas** au boot. À valider avec le pack 03
  avant la vague 1 (pour ne pas demander une permission inutile au boot).
- **O5 (vague 7, R9)** : **évaluer** le moteur STT local (whisper.cpp) **sur de vrais
  appareils** Android (spine § Deferred) — **après** la Phase 1 (capacité connue via
  `TranscriptionProvider`, jamais bloquante V1).

---

**Références** : spine (AD-1…AD-16 + F-01…F-10, statut final 2026-09-21) ; ADR v1.7 (gelé,
sections 23–24 Phase 1 Mobile Only + v1.5 nouveaux contrats Scanner/OCR/Audio/Transcription +
§8 contrats internes) ; revue adversariale (F-03/F-09). Ce pack **référence et approfondit**
le spine (pas de redondance) ; les **décisions contraignantes** restent dans le spine
(read-only) ; **ce pack est prescriptif** (il dit **comment** implémenter la couche plate
forme mobile). *Pack 04 ; prochain en série : 05-design-system.md (composants + tokens +
contrats AD-10 + inventaire des écrans) et 06-agent.md (kernel serveur, surface UI, AD-12/F-09).*
