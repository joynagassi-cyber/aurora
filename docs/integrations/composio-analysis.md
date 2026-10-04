# Analyse Composio — catalogue & plan de migration

_Généré le 2026-10-04. Source : docs.canonical (toolkits + changelog 2026-02-11 + skill Platform)._

## 1. Ce que le catalogue Composio contient (1500+ toolkits)

Catégories standardisées (changelog 2026-02-11) :
`AI & Automation`, `Business & Commerce`, `Communication`, `Content & Files`,
`Human Resources`, `IT & Development`, `Lifestyle`, `Marketing`,
`Productivity`, `Sales & Support`, `Web & Apps`.

Les 14 toolkits les plus utiles à un **agent étudiant** (métadonnées extraites
des pages `docs.composio.dev/toolkits/<slug>.md`, cat/auth/managed) :

| Toolkit (slug) | Cat | Auth | Managed OAuth ? | Tools | Valeur pour Aurora |
|---|---|---|---|---|---|
| `SPOTIFY` | news & lifestyle | OAUTH2 | **NON** — app OAuth maison requise (Spotify Developer Dashboard) | 88 | focus mode : visualisation session + playlist/album/morceau perso |
| `GOOGLECALENDAR` | scheduling & booking | OAUTH2 | OUI | 50 | planifier/replanifier focus & tâches ; verrouiller créneaux |
| `GMAIL` | email | OAUTH2 | OUI | 62 | envoyer/résumer/cacher docs & travaux (ADR S6 canonical example) |
| `GOOGLEDOCS` | documents | OAUTH2 | OUI | 43 | rédiger/réviser rapports (outil agent S4) |
| `GOOGLEDRIVE` | file mgmt | OAUTH2 | OUI | 105 | stockage d'artefacts r2Key (artifacts module) |
| `GOOGLESHEETS` | spreadsheets | OAUTH2 | OUI | 58 | notes/progression/suivi de résultats |
| `OUTLOOK` | email | OAUTH2 + S2S | OUI | 306 | équivalent GSuite pour les étudiants Windows |
| `NOTION` | notes | OAUTH2 + API_KEY | OUI | 57 | base de connaissances / cours |
| `TODOIST` | task mgmt | OAUTH2 | OUI | 84 | sync des tâches avec le module Productivity (03) |
| `CLICKUP` | productivity | OAUTH2 + API_KEY | OUI | 164 | PM étudiant (groupes/projets) |
| `TRELLO` | project mgmt | OAUTH1 | OUI | 330 | kanban de révisions |
| `SLACK` | team chat | OAUTH2 | OUI | 168 | notifications aux coéquipiers (travaux de groupe) |
| `GITHUB` | dev tools | OAUTH2 | OUI | 896 | pour les profils code/CS |
| `YOUTUBE` | video & audio | OAUTH2 | OUI | 51 | résumé de cours / recherche vidéo |

Autres candidats à envisager (non tirés de l'index) : `Miro`, `Notion
API`, `Canva`, `ChatGPT`, `Perplexity`, `DeepSeek`, `Anthropic`, `OpenAI`
(côté AI & Automation) — à filtrer selon le besoin.

## 2. Spotify = le cas particulier qui doit être réglé en premier

`SPOTIFY` est le **seul toolkit sans OAuth géré par Composio** :

- L'utilisateur DOIT créer son propre app OAuth sur
  `developer.spotify.com/dashboard` (client_id + secret, redirect URI, scopes).
- Les scopes Spotify sont **granulaires** et obligatoires pour chaque tool :
  - lecture : `user-read-playback-state`, `user-read-currently-playing`,
    `user-library-read`
  - playlist : `playlist-read-private`, `playlist-modify-public`,
    `playlist-modify-private`
  - queue / pause / skip : `user-modify-playback-state`
- Les 88 tools couvrent : playlists (`SPOTIFY_GET_CURRENT_USER_S_PLAYLISTS`,
  `SPOTIFY_GET_USER_S_SAVED_TRACKS`, `SPOTIFY_CREATE_PLAYLIST`,
  `SPOTIFY_UPDATE_PLAYLIST_ITEMS`), lecture
  (`SPOTIFY_GET_CURRENTLY_PLAYING_TRACK`, `SPOTIFY_GET_PLAYBACK_STATE`,
  `SPOTIFY_ADD_ITEM_TO_PLAYBACK_QUEUE`, `SPOTIFY_PAUSE_PLAYBACK`),
  recherche (`SPOTIFY_SEARCH_FOR_ITEM`, `SPOTIFY_GET_CATEGORY_S_PLAYLISTS`),
  recommandation (`SPOTIFY_GET_RECENTLY_PLAYED_TRACKS`,
  `SPOTIFY_GET_USER_S_TOP_TRACKS`), etc.

Pour l'implémenter proprement dans Aurora, il faut :
1. Créer l'app Spotify (une fois, côté client), obtenir `client_id` + `secret`.
2. Stocker `client_id` en secret Supabase + `secret` dans le secret store
   server-side (AD-3) — jamais sur device.
3. Enregistrer l'OAuth app dans Composio (`AuthConfig` custom,
   `composio.sessionConfigs` ou `auth config` API, pas l'interface admin
   générique).
4. Le toolkit `SPOTIFY` devient utilisable dans les sessions avec
   les scopes demandés par l'app maison.

## 3. Ce qui est RÉELLEMENT FAIT (état au commit 9691c98)

| Composant | État |
|---|---|
| `packages/integrations/src/composio.ts` | Adapter REST v1 (legacy : `/tools`, `/accounts`, `/tools/execute` sur `api.composio.dev/api/v1`). **NON** conforme au modèle v3.1 (sessions + meta-tools). Runtime-agnostic (process.env ou injection explicite). 5 tests verts. |
| `supabase/functions/fn-integrations/index.ts` | 4 verbs : `discover_tools`, `list_accounts`, `execute_tool`, `connect`. Auth JWT user + clé via `Deno.env.get("COMPOSIO_API_KEY")`. Le verb `connect` est un STUB (retourne `connectLink: null` + note) — le vrai flow OAuth n'est pas branché. |
| `packages/integrations/test/composio.test.ts` | 5 tests OK (Node, `process.env`). |
| `supabase/.env` (secret store) | 10 clés poussées (dont `COMPOSIO_API_KEY`) — OQ-03 résolu. |
| `packages/focus/src/controller.ts` + `dist` | `FocusSessionOptions.spotifySource` (contrat) — **mais aucune implémentation** (ni côté controller, ni côté kernel, ni côté UI appelant l'EF). |
| `packages/agent/src/tools.ts` | `focus_sound_catalog` (read-only, 25 sons device + thèmes) — tool kernel opérationnel, **mais le kernel ne merge PAS les tools Composio dans son Tool Registry** (pas de `discoverTools` appelé par le kernel). |
| `apps/mobile/src/pages/integrations/index.tsx` | Page **statique mock** : liste des connectors (Google, Spotify, Notion, Slack, GitHub) avec toggle local, **aucun appel à `fn-integrations`** (zéro `fetch` ou `invoke` dans la page). |
| `apps/mobile/src/pages/focus/index.tsx` | Spotify picker (`playlist:liked` / `album:study` / `track:custom`) — **slugs inventés**, non validés contre le catalogue Composio (violation du skill « ne jamais inventer de toolkit/tool slugs »). |
| `docs/integrations/composio.md` | Spéc v1 (mission S33-35) — décrit l'architecture mais **ne mentionne ni v3.1, ni sessions, ni meta-tools, ni le cas particulier Spotify-managed-OAuth** (section 4 « Auth Config / OAuth flow » est générique). |
| `docs/agent/capability-catalog.md` | **Aucune ligne Composio** (grep vide). Le catalogue d'agent n'a pas encore intégré les tools externes. |

## 4. Ce qui est À FAIRE (backlog détaillé)

### 4.1. Migration de l'adapter vers le modèle v3.1 (sessions + meta-tools)

L'adapter courant cible le REST v1 ; il faut le basculer sur :

```
POST /api/v3.1/sessions (ou composio.create(user_id))
  → session.tools()  (meta-tools : COMPOSIO_SEARCH_TOOLS,
                      COMPOSIO_MULTI_EXECUTE_TOOL,
                      COMPOSIO_MANAGE_CONNECTIONS,
                      COMPOSIO_WAIT_FOR_CONNECTIONS)
  → session.execute(tool_slug, args) pour exécuter un tool
```

Actions concrètes :
- Remplacer `discoverTools` / `listConnectedAccounts` / `executeTool`
  dans `composio.ts` par des appels `session.tools()` / `session.execute()`.
  La session est créées côté user (per-user session, pas une session
  globale), donc adapter le `userId` signature (déjà dans la signaure).
- Mettre à jour les 5 tests Node pour le nouveau contrat
  (`/sessions`, `/tools` de session, pas `/tools` legacy).
- Changer la `baseUrl` par défaut de `https://api.composio.dev/api/v1`
  à `https://backend.composio.dev/api/v3.1`.
- Mettre à jour `fn-integrations/index.ts` pour exposer les nouveaux
  verbs (ou en garder les 4, mais leur implémentation interne
  utilise les sessions).

### 4.2. Brancher le vrai flow OAuth de Spotify (le verrou principal)

Spotify n'a pas d'OAuth géré par Composio ; c'est le **seul toolkit**
dans la liste qui pose ce problème. Plan :
1. Créer l'app OAuth Spotify (client, une fois) : `client_id` + `secret`,
   redirect URI = l'URI de callback Composio de l'app (doc Composio
   custom OAuth / white-labeling-authentication).
2. Enregistrer l'app dans Composio comme `AuthConfig` custom
   (API ou SDK `sessionConfigs`/`auth config`), pas via l'interface admin.
3. Pusher `client_id` (public) + `secret` (secret store server-side,
   AD-3) dans Supabase ; le redirect URI est configuré dans l'app
   Spotify côté dashboard Composio.
4. À la connection de l'utilisateur, le verb `connect` (aujourd'hui
   stub) doit appeler `COMPOSIO_MANAGE_CONNECTIONS` via la session
   de l'utilisateur pour obtenir le **Connect Link** Composio ;
   l'utilisateur l'ouvre, complète l'OAuth, le token reste chez
   Composio.
5. Les tools Spotify dans le session de l'utilisateur utilisent alors
   le compte connecté (scopes : playback, playlists, library, search).

### 4.3. Brancher la page IntegrationsDevice sur `fn-integrations`

La page courante est un **mock** (pas de fetch). Plan :
- Remplacer le toggle local par un appel à `fn-integrations` :
  `POST { verb: 'connect', app: 'spotify' }` → renvoie le Connect Link
  (après 4.2) ; le device ouvre ce lien (WebView ou browser),
  l'utilisateur autorise, le callback retombe côté Composio,
  `integrations_state` est mis à jour côté server (AD-7 single-writer).
- `list_accounts` pour les comptes connectés ; `discover_tools` pour
  afficher les tools disponibles dans la section Spotify.
- Ne PAS faire de deep-link OAuth maison : Composio fournit le Connect
  Link (règle du skill, jamais de provider OAuth flow maison).

### 4.4. Brancher le kernel Tool Registry sur les tools Composio

Aujourd'hui le kernel ne merge que les tools internes +
`focus_sound_catalog` (device-side mock). Plan :
- `fn-agent-bootstrap.ts` (le seam serveur) doit appeler
  `p.discoverTools(user, { limit: N })` (via l'adapter migré en 4.1)
  et ajouter les tools Composio disponibles (connecté) au Tool
  Registry de l'agent (kernel S12 merge a+b per composio.md §3).
- Le Tool Router (composio.md §3) : pour chaque step du plan qui a
  besoin d'un tool externe, matcher `app` + `action` dans le
  catalogue ; si non connecté → `unavailable` + kernel dégrade
  (AD-1), si connecté → tool exécutable.
- `integrations.automation.toggle` (feature-agentability-matrix)
  doit appeler `composio` (via session) pour toggle un automation ;
  aujourd'hui le tool kernel existe mais n'appelle pas l'adapter
  (il est probablement un stub interne).

### 4.5. Nettoyer les slugs inventés du focus page

`spotifySource` envoie `playlist:liked` / `album:study` / `track:custom` —
**aucun de ces slugs n'existe** dans le catalogue Spotify Composio
(les vrais : `SPOTIFY_GET_USER_S_PLAYLISTS`,
`SPOTIFY_CREATE_PLAYLIST`, `SPOTIFY_UPDATE_PLAYLIST_ITEMS`,
`SPOTIFY_SEARCH_FOR_ITEM`, `SPOTIFY_START_RESUME_PLAYBACK`,
`SPOTIFY_SET_REPEAT_MODE`, etc.).

- Remplacer les 4 options par des **références aux vrais tool slugs**
  (ex : `spotify_source: { type: 'playlist', idOrQuery: '...' }`)
  qui sont résolues au runtime via `COMPOSIO_SEARCH_TOOLS` +
  `COMPOSIO_MULTI_EXECUTE_TOOL` (pas de slug durci, skill §4).
- Les 5 thèmes `focus-sounds.ts` (sons local device) restent en
  fallback (AD-1, pas besoin de Composio pour ça) ; le Spotify est
  la **source premium** quand connecté.

### 4.6. Documenter le cas Spotify-managed-OAuth dans la spéc

`docs/integrations/composio.md` (section 4 « Connected accounts & auth »)
est trop générique. Ajouter un sous-section :
- « Spotify & non-managed OAuth toolkits » : l'admin doit créer
  l'app OAuth Spotify maison, enregistrer l'AuthConfig custom dans
  Composio (via SDK/API, pas admin UI), le client_id est public
  (Supabase public env ou device-acceptable), le secret reste
  server-side (AD-3).
- Un tableau des toolkits avec `managed_oauth: false` (Spotify
  au moins) pour que l'équipe sache lesquels nécessitent ce setup.

### 4.7. Étendre le capability-catalog (agent side)

`docs/agent/capability-catalog.md` n'a **aucune ligne Composio** (grep
vide). À ajouter : les tools Composio (par toolkit : gmail.send,
googlecalendar.create_event, notion.create_page, spotify.start_playback,
etc.) en tant que capabilities `external`, avec les mêmes colonnes
que le catalogue (capability_id, description, input schema,
confirmation policy, audit event).

## 5. Ordre de passage recommandé (dépendances)

1. **MIGRATION v3.1** (socle, ~1 jour) : adapter → sessions/meta-tools,
   tests, `baseUrl` → `backend.composio.dev/api/v3.1`, EF à jour.
   *À faire avant tout le reste.*
2. **Page IntegrationsDevice → EF** (4.3) : remplacer le mock par des appels
   réels à `fn-integrations` (`connect` / `list_accounts` /
   `discover_tools`).
3. **Slugs Spotify (focus)** (4.5) : remplacer les slugs inventés par les
   vrais `SPOTIFY_*`.
4. **Kernel Tool Registry → Composio** (4.4) : merge des tools Composio
   (connectés) dans le Tool Registry de l'agent (le kernel dégrade par
   toolkit non connecté, AD-1).
5. **Spotify OAuth app** (4.2) : dernier verrou. Spotify n'a pas d'OAuth
   géré par Composio → app maison (`client_id`/`secret` sur
   `developer.spotify.com`), `AuthConfig` custom dans Composio
   (SDK/API), `secret` en secret store server-side (AD-3), `client_id`
   device-acceptable. **Les toolkits 4.1–4.4 (gmail, googlecalendar,
   notion, …) marchent en managed OAuth sans ça.**
6. **Documentation** (4.6) : section « Spotify & non-managed OAuth » dans
   `composio.md` + tableau des toolkits `managed_oauth: false`.
7. **capability-catalog** (4.7) : ajouter les lignes Composio
   (optionnelle mais propre).

Le verrou **critique** est le 4.2 (Spotify OAuth app) : tout ce qui
tourne autour peut se faire sans ça, mais Spotify ne sera jamais
fonctionnel sans l'app maison.

## 6. Risques & vérifications

- **Composio-managed OAuth = No pour Spotify** : si on n'a pas
  d'app OAuth maison, Spotify ne sera jamais utilisable ; les
  13 autres toolkits sont OK (managed = Yes).
- **429 / retry-after** : l'adapter courant gère déjà le 429 (null
  + note) ; à conserver post-migration v3.1.
- **AD-3 (zero provider keys on device)** : le `COMPOSIO_API_KEY`
  est dans le secret store Supabase (déjà pushé), l'app Spotify
  `client_id` peut être device-acceptable, `secret` reste
  server-side uniquement.
- **Test de non-régression** : les 5 tests composio Node
  doivent être migrés vers le nouveau contrat (sessions) avant
  de passer à vert.

## 7. Intégration dans le plan global 4 semaines (deep-analysis)

Le deep-analysis a livré un plan 4 semaines. Le chantier Composio
se positionne ainsi (les 3 étapes 1–2–3 de ce fichier = la ligne
`integrations: useIntegrations + Composio OAuth deep-link` de la
**semaine 3** ; la migration v3.1 = le prérequis de la **semaine 1–2**) :

- **Sem. 1–2** : migration v3.1 (étape 1) + branchement page→EF
  (étape 2) + slugs Spotify (étape 3) → prêtes.
- **Sem. 3** : `integrations` passe de « UI-only / hardcoded CONNECTORS »
  à `useIntegrations` (données PowerSync) + OAuth deep-link Composio
  (close ce bloc). Spotify OAuth app (étape 5) peut se faire ici ou en
  Sem. 4 selon la priorité.
- **Sem. 4** : polish + UI purity + Spotify final si non fait + gate final.

Les autres lignes du plan 4 semaines (data wiring, mocks→prod, UI
purity, OQ-03/OQ-17) sont orthogonales et restent le reste de la
semaine 1-4.

## 8. Confirmation croisée avec le deep-analysis

Le deep-analysis a confirmé que `integrations` est aujourd'hui
« UI-ONLY, hardcoded CONNECTORS, no Composio OAuth flow yet » — ce
qui est **exactly** l'analyse faite dans ce fichier (section 3,
point « la page est un mock statique »). Les deux documents sont
cohérents ; ce fichier est le détail Composio, le plan 4 semaines
du deep-analysis est le plan global.
