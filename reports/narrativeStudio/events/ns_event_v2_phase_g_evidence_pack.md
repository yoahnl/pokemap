# NS-EVENT-V2 Phase G — Map Editor Bridge — Evidence Pack

Date de validation : 2026-07-16

Révision auditée : `2f68328a38bf218c843e497940f8dd24a7a9c194`

Branche : `main`

Jalons : `NS-EVENT-V2-23`, `NS-EVENT-V2-24`, `NS-EVENT-V2-25`

Verdict : **IMPLEMENTATION FUNCTIONAL PASS / FORMAL CLOSURE BLOCKED**

## 1. Résumé des preuves

La Phase G possède désormais une implémentation fonctionnelle et des preuves
ciblées vertes :

- `NS-EVENT-V2-23` : création/ouverture d'un Event V2 depuis une source map
  existante, sans sélecteurs indépendants map/source ;
- `NS-EVENT-V2-24` : focus réel sur la source, navigation sûre et retour au
  même Event et au même groupe ;
- `NS-EVENT-V2-25` : création explicite d'une vraie source dans le Map Editor,
  persistance map puis registry, journal de récupération, retry et cleanup ;
- matrice Phase G finale : **410/410** ;
- analyse directe Phase G : **0 diagnostic** ;
- format : **32 fichiers, 0 changement** ;
- build macOS debug : **PASS**.

La clôture formelle reste bloquée pour trois raisons mesurées :

1. le Visual Gate produit n'a pas pu être capturé : Computer Use a atteint la
   copie isolée de l'app et le picker de la fixture temporaire, puis a échoué
   avec `-10005 timeoutReached` et `SCStreamErrorDomain Code=-3811` ;
2. la suite complète `map_editor` reste rouge : **`+2963 -98`** ;
3. l'analyse complète `map_editor` reste rouge : **451 diagnostics**, tous
   hors de la liste directe Phase G.

Ce document ne transforme donc pas un résultat ciblé vert en faux `CLOSED`.
Le statut proposé est `FUNCTIONAL PASS / FORMAL BLOCKED`. La roadmap n'a pas
été modifiée, conformément à la règle du repository qui exige une demande
explicite pour cette écriture.

Les deux rapports de clôture sont exclus des annexes de contenu complet afin
d'éviter une récursion documentaire. Les fichiers créés par la Phase G sont
annexés à la fin de ce document.

## 2. Scope exact et non-objectifs

### Inclus

- source atomique `NarrativeEventSourceRef` ;
- création/open depuis `MapEntity`, `MapTrigger` ou `mapEnter` ;
- garde des IDs map/entity/trigger liés ;
- navigation Event → Map, focus caméra one-shot, highlight et retour exact ;
- proposition physique dans le vrai Map Editor ;
- PNJ, panneau, objet, élément invisible et zone Event 1×1 ;
- ordre durable `journal prepared → mapCommitted → Event registry` ;
- retry, cleanup confirmé et interlocks ;
- blocages dirty/saving et prévention des échappatoires de navigation ;
- widgets PokeMap et tokens du design system.

### Exclus et préservés

- aucun picker indépendant map puis source dans l'Event Builder ;
- aucune création ou géométrie physique depuis l'Event Builder ;
- aucune `EventPosition` V2 ;
- aucun raw tile source ni `warpAttempt` V1 ;
- aucune prétention d'atomicité multi-fichiers ;
- aucun changement runtime ou contrat wire `map_core` ;
- aucune correction des 98 échecs globaux étrangers ;
- aucune correction des 451 diagnostics historiques étrangers ;
- aucune validation pixel-perfect de la référence globale fournie par
  l'utilisateur : cette preuve relève du workspace visuel et le Visual Gate G
  n'a pas pu être capturé.

## 3. Règles, plans et roadmaps consultés

- `AGENTS.md` ;
- `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- `docs/superpowers/plans/2026-07-15-event-builder-phase-g-map-bridge.md` ;
- skills locaux `subagent-driven-development`,
  `test-driven-development`, `requesting-code-review` et
  `verification-before-completion` ;
- workflow Product Design Audit et Computer Use pour le Visual Gate.

Lots gameplay consultés et volontairement laissés `TODO` : `FG-080`,
`FG-081`, `FG-082`, `FG-093`, `FG-183`, `FG-185`. La Phase G ne livre pas à
elle seule le command model, les builders complets, le runtime global ou le
release gate fangame.

## 4. Baseline Git et hygiène

### État initial de cette passe de clôture

```text
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Branche : main
Tracked modified : 42
Untracked : 81
Total : 123
packages/map_editor/test/failures : absent
selbrume/*.lock : absent
```

Le worktree contenait déjà les Phases F2, G, H, I, J, K et L non commitées.
Les fichiers Phase G étaient déjà modifiés ou non suivis avant les deux
correctifs de cette clôture. Aucun changement étranger n'a été restauré,
nettoyé ou réécrit.

### Artefacts de validation temporaires

Les suites complètes ont créé :

- 92 images sous `packages/map_editor/test/failures/` ;
- `selbrume/.pokemap-project-1f1a60297a27b0b0.lock`.

Ces artefacts étaient absents de la baseline, ont été inventoriés, puis ont été
supprimés après arrêt de l'instance `map_editor.app` lancée par la validation.
L'état est revenu exactement à 42 fichiers tracked modifiés et 81 non suivis
avant création des deux rapports.

## 5. Audit initial et verdicts contradictoires

| Passe | Verdict | Preuve / conséquence |
|---|---|---|
| Audit architecture V2-23 | `PASS` | 56 tests ciblés, 11 fichiers analysés sans diagnostic |
| Audit architecture V2-24 | `PASS fonctionnel` | 32 tests ciblés, 11 fichiers analysés sans diagnostic |
| Audit V2-25 initial | `CHANGES_REQUIRED` | drag résiduel et perte de l'identité recovery |
| Implémentation drag TDD | `PASS` | deux scénarios vus RED puis GREEN |
| Revue drag conformité | `PASS` | garde avant les quatre callbacks pan |
| Revue drag qualité | `PASS` | preuve RED écarte le faux positif ; chemins partagés |
| Implémentation recovery TDD | `PASS` | retry/cleanup × trois gates, copies exactes |
| Revue recovery conformité | `PASS` | journal/inspection exacts conservés |
| Revue recovery qualité | `PASS`, limite mineure | pas de widget matrix dirty/saving dédiée |
| Visual Gate réel | `BLOCKED` | service de capture en échec après picker natif |
| Tests/Build validation | `PASS` ciblé / `BLOCKED` global | 410 tests et build verts ; suite/analyse complètes rouges |
| Critique finale initiale | `CHANGES_REQUIRED` sur les preuves | code ciblé sans blocker confirmé ; quatre défauts de reproductibilité documentaire |
| Corrections post-critique | `PASS local` | hashes, commandes, traces, attestation et annexe corrigés |
| Contre-lecture corrective | `PASS` | quatre findings initiaux corrigés ; 26/26 hashes et annexes vérifiés ; aucun nouveau Important confirmé |

La passe V2-25 initiale a trouvé deux défauts fonctionnels qui n'étaient pas
des lacunes documentaires :

1. `MapCanvas` protégeait le tap guidé, mais un drag pouvait toujours appeler
   l'outil retained et modifier la map ;
2. un retry/cleanup bloqué par dirty/saving remplaçait la récupération durable
   par un résultat `blocked` sans journal, réactivant ensuite Annuler/Retour.

Les deux défauts ont été corrigés avant le verdict final ciblé.

## 6. TDD — correctif du drag guidé

### Test RED

```bash
cd packages/map_editor
flutter test test/map_canvas_narrative_event_focus_test.dart \
  --plain-name 'NS-EVENT-V2-25 guided map drag guard'
```

Résultat avant production : exit `1`, `+0 -2`.

- en mode `create`, le drag peignait la tuile `7` à l'index `215` ;
- en mode `choose`, le drag créait une `MapGameplayZone` en `(11, 7)`.

### Correctif minimal

Dans `map_canvas.dart`, le prédicat
`pendingReturn != null && navigationMode in {create, choose}` est calculé au
build, puis les callbacks `onPanStart`, `onPanUpdate`, `onPanEnd` et
`onPanCancel` retournent avant tout dispatch d'outil.

### Tests GREEN

```text
test ciblé par nom : +2, All tests passed
fichier complet : +7, All tests passed
analyse des deux fichiers : No issues found
git diff --check ciblé : exit 0
```

La revue a confirmé que `terrainPaint` et `eraser` passent derrière le même
garde que `tilePaint`; ils ne constituent pas des branches de sécurité
distinctes. Le clic guidé reste dans `onTapUp` et le pan normal reste inchangé
hors mode guidé.

## 7. TDD — conservation de la récupération durable

### Tests RED

```bash
cd packages/map_editor
flutter test test/narrative_event_source_creation_recovery_test.dart \
  --reporter expanded
```

Après correction d'une erreur de typage test-only préalable à la preuve
comportementale, la relance a produit deux échecs attendus : retry et cleanup
retournaient `blocked` au lieu de `recoveryRequired` pour `mapDirty`. Les 26
autres tests passaient.

```bash
flutter test test/ui/canvas/narrative_event_map_banner_test.dart \
  --plain-name 'source-less CTA exposes five types and map tap previews before legacy callback' \
  --reporter expanded
```

Résultat RED attendu : le libellé exact `Annuler` était absent.

### Correctif minimal

`_preserveTransientSourceRecovery` reconnaît désormais :

```text
mapDirty
projectDirty
saveInProgress
```

Lorsqu'un résultat entrant ne porte aucune identité durable, le contrôleur
conserve exactement le journal, l'inspection et l'état `recoveryRequired`
précédents. Les codes et messages entrants restent exposés pour expliquer le
gate. Annuler/Retour et la sélection d'un nouveau type restent bloqués tant que
la récupération durable existe.

Les copies produit sont désormais exactement :

```text
Annuler
Enregistrer et lier
```

### Tests GREEN

```text
narrative_event_source_creation_recovery_test.dart : +28, All tests passed
narrative_event_map_banner_test.dart : +16, All tests passed
analyse des quatre fichiers : No issues found (7.3s lors de l'implémentation)
```

La matrice couvre retry et cleanup pour les trois gates. Elle vérifie : statut,
identité `same(...)` du journal et de l'inspection, zéro commit/recovery/
cleanup/persist durable additionnel, token de retour inchangé, Annuler/Retour
refusés et choix d'un nouveau type refusé.

## 8. Traçabilité V2-23

| Critère | Preuve |
|---|---|
| Source entity | `NarrativeEventSourceRef.entityInteract(mapId, entityId)` |
| Source trigger | `NarrativeEventSourceRef.triggerEnter(mapId, triggerId)` |
| Source map | `NarrativeEventSourceRef.mapEnter(mapId)` |
| Aucun second picker map | intent atomique source + nom ; map dérivée |
| Existing links | draft/configured, enabled/disabled, ordre déterministe |
| Dirty/saving | rejet avant préparation et écriture |
| Snapshot stale | aucune duplication |
| Registry mémoire | remplacement uniquement après commit disque |
| Identités liées | rename/delete/kind incompatible bloqués |
| Legacy | section séparée et explicitement marquée |

Validation dédiée fraîche de l'auditeur : `+56: All tests passed!` et 11/11
fichiers ciblés sans diagnostic.

## 9. Traçabilité V2-24

| Critère | Preuve |
|---|---|
| Token exact | Event ID + group context + expected source |
| Même map dirty | aucune reload, historique préservé |
| Cross-map dirty | refus avant lecture |
| Cross-map clean | une lecture, owner revalidé, une activation |
| Focus entity/trigger/map | bounds exacts, aucun owner artificiel pour map |
| Caméra | requête consommée une fois, zoom préservé |
| Retour | même Event et même contexte ; aucun fallback premier Event |
| Source manquante | diagnostic honnête |
| Source non spatiale | aucun CTA carte |

Validation dédiée fraîche de l'auditeur : `+32: All tests passed!` et 11/11
fichiers ciblés sans diagnostic.

## 10. Traçabilité V2-25

| Critère | Preuve |
|---|---|
| Propositions | PNJ, panneau, objet, invisible, zone Event 1×1 |
| Proposition pure | `EditorState.activeMap`, dirty et historique intacts |
| Aucun MapEvent V1 | `afterMap.events` reste vide |
| Aucun `EventPosition` V2 | identité portée uniquement par source atomique |
| Journal | `prepared → mapCommitted → eventCommitted` |
| Map commit | temp même dossier, flush, CAS hash, rename, vérification |
| Registry commit | session fraîche post-map, write unique |
| Crash entre commits | journal `mapCommitted` conservé |
| Retry | même Event/source/journal, aucune nouvelle source |
| Cleanup | confirmation, owner exact, fingerprint inchangé |
| Owner modifié | cleanup refusé |
| Dirty/saving | identité recovery exacte conservée, aucune échappatoire |
| Drag guidé | aucun retained map tool ne peut muter la map |
| Copies | `Annuler`, `Enregistrer et lier` |

## 11. Matrice Phase G finale

Commande exécutée depuis `packages/map_editor` :

```bash
flutter test --no-pub --reporter=compact --concurrency=1 \
  test/narrative_event_map_creation_bridge_test.dart \
  test/narrative_event_source_dependency_guard_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/event_builder_draft_creation_notifier_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/map_focus_viewport_resolver_test.dart \
  test/event_builder_map_focus_return_flow_test.dart \
  test/map_canvas_narrative_event_focus_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/editor_workspace_controller_test.dart \
  test/editor_project_session_controller_test.dart \
  test/narrative_event_spatial_link_journal_repository_test.dart \
  test/narrative_event_explicit_source_creation_test.dart \
  test/narrative_event_source_creation_recovery_test.dart \
  test/narrative_event_spatial_source_link_use_case_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  test/map_canvas_entity_properties_smoke_test.dart \
  test/event_registry_recovery_test.dart \
  test/event_registry_recovery_gate_test.dart \
  test/event_registry_repository_test.dart
```

Résultat exact :

```text
exit 0
+410: All tests passed!
real 48.10s
```

## 12. Analyse ciblée et format

La validation directe a analysé les 20 fichiers production/intégration et les
12 tests Phase G ci-dessous. La même liste shell de **32 items** alimente
l'analyse et le contrôle de format, sans placeholder :

```zsh
cd packages/map_editor
phase_g_files=(
  lib/src/application/models/narrative_event_map_bridge_models.dart
  lib/src/application/models/narrative_event_spatial_link_journal_models.dart
  lib/src/application/models/narrative_event_spatial_source_creation_models.dart
  lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart
  lib/src/application/services/map_focus_viewport_resolver.dart
  lib/src/application/services/narrative_event_source_dependency_guard.dart
  lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart
  lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart
  lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart
  lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
  lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart
  lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
  lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
  lib/src/ui/panels/narrative_event_map_bridge_panel.dart
  lib/src/app/providers/core/repository_providers.dart
  lib/src/features/editor/state/editor_notifier.dart
  lib/src/ui/canvas/narrative_workspace_canvas.dart
  lib/src/ui/canvas/map_canvas.dart
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart
  lib/src/ui/panels/map_inspector_panel.dart
  test/narrative_event_map_creation_bridge_test.dart
  test/narrative_event_source_dependency_guard_test.dart
  test/ui/panels/narrative_event_map_bridge_panel_test.dart
  test/event_map_navigation_controller_test.dart
  test/map_focus_viewport_resolver_test.dart
  test/event_builder_map_focus_return_flow_test.dart
  test/map_canvas_narrative_event_focus_test.dart
  test/narrative_event_spatial_link_journal_repository_test.dart
  test/narrative_event_explicit_source_creation_test.dart
  test/narrative_event_source_creation_recovery_test.dart
  test/narrative_event_spatial_source_link_use_case_test.dart
  test/ui/canvas/narrative_event_map_banner_test.dart
)
flutter analyze --no-pub "${phase_g_files[@]}"
dart format --output=none --set-exit-if-changed "${phase_g_files[@]}"
```

Résultat frais de l'analyse :

```text
exit 0
items=32
Analyzing 32 items...
No issues found! (ran in 4.3s)
real 5.05s
```

Un superset de 44 items incluant des régressions adjacentes retourne dix
informations `prefer_const_constructors` uniquement dans
`test/editor_project_session_controller_test.dart`. Aucun diagnostic ne cible
un fichier Phase G.

```text
exit 0
items=32
Formatted 32 files (0 changed) in 0.23 seconds.
real 0.27s
```

Whitespaces :

```text
git diff --check : exit 0
26 fichiers Phase G non suivis, diff --no-index --check : 0 erreur
```

## 13. Build macOS

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

```text
exit 0
Built build/macos/Build/Products/Debug/map_editor.app
real 25.18s
```

## 14. Suite et analyse complètes

### Tests package complet

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact
```

```text
exit 1
+2963 -98: Some tests failed.
real 325.93s
98 lignes [E]
98 commandes de relance
```

Les premières racines observées concernent notamment :

- `scene_cinematic_picker_test.dart` — screenshot V1-39 ;
- `pokemap_topbar_migration_test.dart` — dark theme ;
- `pokemap_sidebar_item_test.dart` — selected styles ;
- `pokemap_right_inspector_resize_test.dart` ;
- `narrative_event_authoring_snapshot_performance_test.dart` ;
- `encounter_tables_panel_test.dart` ;
- des goldens Facts, World Rules, Storylines, Scenes et Shadows.

Aucun des 21 fichiers de la matrice Phase G n'échoue lorsqu'il est exécuté dans
la matrice isolée. Le package complet ne peut néanmoins pas être déclaré vert.

### Analyse package complet

```bash
cd packages/map_editor
flutter analyze --no-pub
```

```text
exit 1
451 issues found. (ran in 4.5s)
451 lignes diagnostics
0 ligne visant les fichiers Phase G directs
real 5.27s
```

Les diagnostics globaux ne sont pas absorbés dans G. Les corriger élargirait
le scope aux convertisseurs Pokémon SDK et à de nombreuses surfaces editor.

## 15. Visual Gate réel

Le contrôle a utilisé une copie temporaire de l'app avec bundle ID et nom
uniques, afin d'éviter le conflit avec un autre worktree. Le projet Selbrume
réel n'a pas été manipulé.

Parcours obtenu :

```text
copie unique lancée
→ fenêtre AX réelle
→ bouton « Ouvrir un projet »
→ picker macOS
→ sélection explicite /tmp/pokemap_phase_g_visual.HyeyA6
→ Open
→ -10005 timeoutReached
```

Seconde tentative propre :

```text
picker ouvert
→ Cancel pour fallback texte
→ com.apple.ScreenCaptureKit.SCStreamErrorDomain Code=-3811
  Failed to start stream due to audio/video capture failure
```

La copie a été quittée via Computer Use (`Cmd+Q`). Aucun screenshot Phase G
n'a été inventé ou accepté. La fixture temporaire est restée byte-identique :

| Fichier | SHA-256 inchangé |
|---|---|
| `README.md` | `dfd021263f3fe13920a6f7deef9c56119dc2aed9441061b532fa0fea069df61e` |
| `project.json` | `5261faa8d45514197113f87cd3e59be26b7a1d3026c889435ba8efaced137a77` |
| map | `830736cbc64eae658e331ce114a368cce67e3249db1bf079af1a411e1af0f912` |

`diff -rq` entre la fixture repo et la copie temporaire ne retourne aucune
différence. Ce blocage empêche la preuve visuelle des cinq flows exigés :

- source sélectionnée → create/open Event V2 ;
- Event → focus entity/trigger/map ;
- retour exact au draft ;
- création invisible et zone 1×1 ;
- erreur registry → retry/cleanup.

## 15.1 Empreintes transactionnelles map / manifest / journal

Trois tests existants émettent maintenant une trace JSON lisible par machine.
Ils ont été relancés seuls puis dans la matrice Phase G. La trace d'annulation
porte sur le JSON canonique de l'état map/manifest en mémoire et est couplée à
des compteurs de gateway à zéro ; les traces retry et cleanup portent sur les
octets réellement relus sur disque.

### Annulation avant écriture

Commande exacte depuis `packages/map_editor` :

```bash
flutter test --no-pub --reporter=expanded \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  --plain-name 'source-less CTA exposes five types and map tap previews before legacy callback'
```

```json
{"before":{"map":"sha256:6c126579ffc20248d1d8702d4e71a5eca864fe7202ec0463dd3a5d629a9854bf","manifest":"sha256:bd0a6d7c0f2a5e4fe956871360f9d353b4616a63e316529a02b335c4d7b4775c","journal":"absent"},"afterCancel":{"map":"sha256:6c126579ffc20248d1d8702d4e71a5eca864fe7202ec0463dd3a5d629a9854bf","manifest":"sha256:bd0a6d7c0f2a5e4fe956871360f9d353b4616a63e316529a02b335c4d7b4775c","journal":"absent"}}
```

Résultat : `exit 0`, `+1: All tests passed!`. Les représentations canoniques
map et manifest restent identiques, les gateways map et registry restent à
zéro appel, et aucun journal n'apparaît. Ce test ne prétend pas lire des
fichiers disque que ce preview n'a justement jamais écrits.

### Commit map puis reprise du commit Event

Commande exacte :

```bash
flutter test --no-pub --reporter=expanded \
  test/narrative_event_source_creation_recovery_test.dart \
  --plain-name 'registry failure after map commit is explicit and retry never rewrites the map'
```

```json
{"before":{"map":"sha256:625871bf887874b8f85534de40e1ce02ad6597700711af01aa610d40c1e7446e","manifest":"sha256:59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea","journal":"absent"},"afterMapCommit":{"map":"sha256:ba95794f0528827c54499b007c1c18cdf672b83e5b318156221eafbaad6ad247","manifest":"sha256:59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea","journal":"mapCommitted"},"afterRetry":{"map":"sha256:ba95794f0528827c54499b007c1c18cdf672b83e5b318156221eafbaad6ad247","manifest":"sha256:2a0774047abc1c99d0469c69d3f2b546483acf726a874a1eae5cd141feaffc03","journal":"eventCommitted"},"afterAcknowledge":{"journal":"clear"}}
```

Résultat : `exit 0`, `+1: All tests passed!`. Le commit map change uniquement
la map et place le journal à `mapCommitted`. La reprise conserve exactement
le hash de cette map, change le manifest, passe à `eventCommitted`, puis
l'acquittement efface le journal.

### Nettoyage confirmé après commit map interrompu

Commande exacte :

```bash
flutter test --no-pub --reporter=expanded \
  test/narrative_event_source_creation_recovery_test.dart \
  --plain-name 'cleanup requires a second confirmation and removes only pending owner'
```

```json
{"before":{"map":"sha256:625871bf887874b8f85534de40e1ce02ad6597700711af01aa610d40c1e7446e","manifest":"sha256:59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea","journal":"absent"},"afterMapCommit":{"map":"sha256:ba95794f0528827c54499b007c1c18cdf672b83e5b318156221eafbaad6ad247","manifest":"sha256:59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea","journal":"mapCommitted"},"afterCleanup":{"map":"sha256:4907d7d3e6e551e9cd62c454b1337df5e84da4e45aea17281dbceb4287e7213b","manifest":"sha256:59edd1f1f36814024ac5542e4f88b4d3b726bb00d294e29b65b29153f84bd2ea","journal":"clear","entities":0}}
```

Résultat : `exit 0`, `+1: All tests passed!`. Le manifest n'est jamais écrit.
Le cleanup restaure le `MapData` complet antérieur et retire l'unique owner,
mais le repository re-sérialise le JSON : le hash binaire final de la map
diffère donc honnêtement du hash initial. Le test compare aussi le modèle
rechargé à `proposal.beforeMap`, constate `entities: 0` et un journal clair.

## 16. Inventaire des fichiers Phase G

### Production créés

| Fichier | Rôle |
|---|---|
| `application/models/narrative_event_map_bridge_models.dart` | intents, tokens, focus, outcomes |
| `application/models/narrative_event_spatial_link_journal_models.dart` | journal durable strict |
| `application/models/narrative_event_spatial_source_creation_models.dart` | proposition physique pure |
| `application/ports/narrative_event_spatial_source_creation_gateway.dart` | frontière CAS/recovery/cleanup |
| `application/services/map_focus_viewport_resolver.dart` | calcul pur du centrage |
| `application/services/narrative_event_source_dependency_guard.dart` | garde des identités liées |
| `application/use_cases/create_narrative_event_from_map_source_use_case.dart` | create/open source-first |
| `application/use_cases/narrative_event_explicit_source_creation_use_case.dart` | deux commits et recovery |
| `application/use_cases/narrative_event_spatial_source_link_use_case.dart` | sélection/remplacement source |
| `features/narrative/state/narrative_event_map_bridge_state.dart` | état/navigation/recovery |
| `infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart` | persistance journal/map CAS |
| `ui/canvas/events/narrative_event_map_return_panel.dart` | contrôles Event → Map |
| `ui/canvas/map_canvas/narrative_event_map_banner.dart` | UX Map guidée/recovery |
| `ui/panels/narrative_event_map_bridge_panel.dart` | actions source-first inspector |

### Production intégrés

| Fichier | Zones / impact |
|---|---|
| `app/providers/core/repository_providers.dart` | gateways registry et source partagés |
| `features/editor/state/editor_notifier.dart` | registry sync, focus, proposition, lease, cleanup, dependency guard |
| `ui/canvas/narrative_workspace_canvas.dart` | return panel Event |
| `ui/canvas/map_canvas.dart` | tap guidé, pan guard, banner, focus caméra |
| `ui/canvas/map_canvas/map_grid_painter.dart` | highlight focus/proposal |
| `ui/panels/map_inspector_panel.dart` | bridge panel source-first |

### Tests créés

| Fichier | Couverture principale |
|---|---|
| `narrative_event_map_creation_bridge_test.dart` | V2-23 create/open/dirty/stale |
| `narrative_event_source_dependency_guard_test.dart` | IDs et kinds liés |
| `ui/panels/narrative_event_map_bridge_panel_test.dart` | actions no-code source-first |
| `event_map_navigation_controller_test.dart` | V2-24 tokens/navigation |
| `map_focus_viewport_resolver_test.dart` | centrage pur |
| `event_builder_map_focus_return_flow_test.dart` | focus/retour exact |
| `map_canvas_narrative_event_focus_test.dart` | highlight/caméra/drag guard |
| `narrative_event_spatial_link_journal_repository_test.dart` | journal/CAS/recovery |
| `narrative_event_explicit_source_creation_test.dart` | propositions physiques |
| `narrative_event_source_creation_recovery_test.dart` | deux commits/retry/cleanup/gates |
| `narrative_event_spatial_source_link_use_case_test.dart` | liaison source atomique |
| `ui/canvas/narrative_event_map_banner_test.dart` | UX guidée et recovery |

## 17. Zones précises corrigées par la passe actuelle

| Fichier | Zone | Changement |
|---|---|---|
| `map_canvas.dart` | prédicat vers 358 ; callbacks vers 541/581/620/635 | bloque tout drag primaire guidé avant mutation |
| `map_canvas_narrative_event_focus_test.dart` | groupe vers 287 | RED/GREEN create+tilePaint et choose+zone |
| `narrative_event_map_bridge_state.dart` | retry ~767 ; cleanup ~914 ; helper ~1528 | conserve recovery/journal/inspection pour trois gates |
| `narrative_event_map_banner.dart` | ~395 et ~414 | copies exactes produit |
| `narrative_event_source_creation_recovery_test.dart` | ~256–412, ~659–782, ~2048 et ~2175 | traces commit/retry/cleanup et matrices retry/cleanup × trois gates |
| `narrative_event_map_banner_test.dart` | ~41–174 | trace d'annulation, copies nouvelles présentes, anciennes absentes |

Les six fichiers étaient déjà respectivement modifiés ou non suivis avant la
correction ; leurs changements étrangers ont été préservés.

## 18. Hashes des fichiers Phase G créés

| Fichier | SHA-256 |
|---|---|
| `narrative_event_map_bridge_models.dart` | `02672bb2b0ea4311a07ef51041931f82121244efccb09d7ce853d6f3806ef642` |
| `narrative_event_spatial_link_journal_models.dart` | `7d99125a27e2d3547e094ffab3cef26d1c281d0a253273f6999bf93001d9fc7d` |
| `narrative_event_spatial_source_creation_models.dart` | `1f1270e23303e4202ba80f792315df6fec6aceeaf80d5581908bb5401f9d4d58` |
| `narrative_event_spatial_source_creation_gateway.dart` | `9ac738638801b077898f4b11bc9538a5c0554d41c5fcb0ee35b4305218d04758` |
| `map_focus_viewport_resolver.dart` | `a6e5994a0544da0b8c975887d1e7149157d38cde1c7f4205292c96d0a19a9afb` |
| `narrative_event_source_dependency_guard.dart` | `2ae7172825daae195e1f2471beb555550e67428218142b3f144983e43907192e` |
| `create_narrative_event_from_map_source_use_case.dart` | `8a66fcea25d5dc931741c0a5450e58c138d366e6b3fdc5f8e9081320ef2ba448` |
| `narrative_event_explicit_source_creation_use_case.dart` | `8bf60b1e55a3db437abc556e2e28fbdc04ef44d1b6861b51f0f821e0ffe09e70` |
| `narrative_event_spatial_source_link_use_case.dart` | `1457b25ce62bdb9b5e04355ee30f8da736aea17594c134ad971dbbf222672a4f` |
| `narrative_event_map_bridge_state.dart` | `4a5b986a2580e0c49d16f396520ba4cc94fc8afe8989bbe1148a976dd1db8613` |
| `narrative_event_spatial_link_journal_repository.dart` | `0eb4bdc96a2317aceb5d05879aa5164226372c82bcae878190f010319da77833` |
| `narrative_event_map_return_panel.dart` | `775d86cd0e21313ab2e2e2e3eb70352cd6d08177b94afc4d3c57b9eccb73ae5c` |
| `narrative_event_map_banner.dart` | `35e68b3874e5bf459603aaa86fa07fb0bca87dcf3febe2c4dad2233997a93568` |
| `narrative_event_map_bridge_panel.dart` | `0a3881bae1eb2d5bf76aaf8bdad63630b63c8b48b81eb53a7beab2810d5c3364` |

| Test créé | SHA-256 |
|---|---|
| `narrative_event_map_creation_bridge_test.dart` | `39a675bd02c54cc2de0def72d57786f89b8c988b101ae4f4d55ade64d6e84d09` |
| `narrative_event_source_dependency_guard_test.dart` | `e2d3d02e904067ff4c10fcec82a5a36f6cb19ad65f7a70d6da4b2f6bbd310568` |
| `narrative_event_map_bridge_panel_test.dart` | `d2390da0453bd9541487df54215289b194cae369eff718e67af0c457a4b3930c` |
| `event_map_navigation_controller_test.dart` | `ebcc1a453828072431999418b3b630f16ed59d6f72756ff51f2bdee709053a4b` |
| `map_focus_viewport_resolver_test.dart` | `88ee58d25572cc6863c0a59a0da0d5f06309048f68e221f198e67be40f33c073` |
| `event_builder_map_focus_return_flow_test.dart` | `2f58d7b7d2d9f1bdf69bbce07f15ecc3a67a577f50513690ad0e2713d7ae8608` |
| `map_canvas_narrative_event_focus_test.dart` | `515ac17b432770db6254f7c2f37ac87e082f70b11f3a94c5d4d4ef82b9d534a6` |
| `narrative_event_spatial_link_journal_repository_test.dart` | `c4114e8e802f358fc5cb289fc776ac1bd5c73aefde0bbdaa9aecb7df21d6e82e` |
| `narrative_event_explicit_source_creation_test.dart` | `036d933dcf85c086b64722a98fb4342c55cb6d2c2671d4bea7d5d509b1439052` |
| `narrative_event_source_creation_recovery_test.dart` | `cc537109551c0c5c9b7c2d75f1aaac0f9121441b33d5d1917eda34a0bdff7a13` |
| `narrative_event_spatial_source_link_use_case_test.dart` | `7e1bcbf97bdfb0a6fea64e5db6eb56ed495ec6f2a11211cb732c01647ad1b16f` |
| `narrative_event_map_banner_test.dart` | `6a0107dff37ceb870f28ab822ffd7f1328bcc5ea6dc1cf8c8c15367366c3e532` |

Le manifeste complet compte 26 fichiers et 20 848 lignes. Leur contenu complet
est reproduit en annexe.

Contrôle automatique relancé depuis la racine du repository : le script Ruby
lit les 26 sections `22.n`, compare leur texte aux fichiers, puis compare les
26 SHA-256 du tableau aux fichiers courants.

```ruby
require 'digest'
report = File.read(
  'reports/narrativeStudio/events/ns_event_v2_phase_g_evidence_pack.md',
  encoding: 'UTF-8',
)
annex = report.split(
  '## 22. Annexes — contenus complets des fichiers créés',
  2,
).fetch(1)
entries = annex.scan(
  /^### 22\.\d+ `([^`]+)`\n\n```dart\n(.*?)^```\n/m,
)
annex_failures = entries.reject do |path, embedded|
  embedded == File.read(path, encoding: 'UTF-8')
end
hash_rows = report.scan(
  /^\| `([^`]+\.dart)` \| `([0-9a-f]{64})` \|$/,
)
hash_failures = entries.reject do |path, _|
  reported = hash_rows.reverse.find { |row| row[0] == File.basename(path) }&.last
  reported == Digest::SHA256.file(path).hexdigest
end
puts "annex_entries=#{entries.length} annex_mismatches=#{annex_failures.length}"
puts "hash_entries_checked=#{entries.length} hash_mismatches=#{hash_failures.length}"
puts "source_lines=#{entries.sum { |path, _| File.foreach(path).count }}"
exit(entries.length == 26 && annex_failures.empty? && hash_failures.empty? ? 0 : 1)
```

```text
exit 0
annex_entries=26 annex_mismatches=0
hash_entries_checked=26 hash_mismatches=0
source_lines=20848
```

## 19. État Git final attendu

Après nettoyage des artefacts et création des deux rapports :

```text
Tracked modified : 42
Untracked : 83
Total : 125
Git write : aucune
Roadmap : non modifiée par cette passe
```

Attestation roadmap relue après les corrections documentaires :

```text
MVP Selbrume/road_map_event_builder_v2.md
SHA-256 contenu : a7e5ddb327a46b5e527dbe1816f326be6eb744df4b2a33dd097b926aab1d3349
SHA-256 diff Git actuel : 680a91c1d3026b8a0b33c20d5b9731096cbd1be140e9f48715a0514a9b73e9a7
mtime : 2026-07-15T20:21:02+0200
taille : 95856 octets
diff numstat : 126 ajouts / 39 suppressions
```

La contre-lecture indépendante avait relevé la même empreinte avant cette
dernière passe de correction. Aucun hash n'avait toutefois été capturé au tout
début du turn : cette double observation et le `mtime` antérieur constituent
l'attestation disponible, sans prétendre à une preuve initiale inexistante.
Le fichier reste une modification préexistante du worktree.

Les deux entrées non suivies supplémentaires sont :

```text
reports/narrativeStudio/events/ns_event_v2_phase_g_map_editor_bridge_closure_v0.md
reports/narrativeStudio/events/ns_event_v2_phase_g_evidence_pack.md
```

## 20. Auto-critique et risques restants

1. **Visual Gate non prouvé.** Les tests widget ne remplacent pas une capture
   du flow desktop réel. La référence globale ne peut pas être déclarée
   atteinte à partir de ce lot.
2. **Gates package rouges.** Le succès ciblé ne suffit pas à fermer une phase
   dont le plan exige `flutter test` et `flutter analyze` complets verts.
3. **Widget gate recovery.** La matrice dirty/saving est exhaustive au niveau
   contrôleur, mais pas rejouée via chaque bouton du banner. Le câblage est
   analysé et les tests widget recovery passent ; c'est un renforcement de
   preuve, pas un défaut observé.
4. **Worktree agrégé.** Plusieurs phases non commitées se superposent. La
   validation ciblée isole G, mais la suite complète reflète tout l'agrégat.
5. **Nettoyage et représentation binaire.** Le cleanup restaure le `MapData`
   complet, mais sa réécriture normalise le JSON ; l'égalité sémantique est
   forte, l'égalité byte-à-byte avec le fichier initial n'est pas revendiquée.

## 21. Statut proposé sans écriture roadmap

```text
NS-EVENT-V2-23 : PASS fonctionnel
NS-EVENT-V2-24 : PASS fonctionnel
NS-EVENT-V2-25 : PASS fonctionnel
Phase G : FUNCTIONAL PASS / FORMAL CLOSURE BLOCKED
```

Pour autoriser `CLOSED / ACCEPTED`, il reste à obtenir :

1. une session Computer Use fraîche et les cinq captures produit réelles ;
2. une décision explicite sur les 98 échecs et 451 diagnostics globaux :
   correction ou allowlist/baseline approuvée, jamais implicite ;
3. la relance des gates complets après stabilisation ;
4. seulement ensuite, une demande explicite de mise à jour roadmap.

## 22. Annexes — contenus complets des fichiers créés

Les deux rapports de clôture sont exclus pour éviter une récursion. Les fichiers ci-dessous sont reproduits byte-pour-byte en texte UTF-8.

### 22.1 `packages/map_editor/lib/src/application/models/narrative_event_map_bridge_models.dart`

```dart
import 'package:map_core/map_core.dart';

import 'narrative_event_registry_persistence_models.dart';

enum NarrativeEventGroupContextKind { map, global }

/// Exact Event Builder group restored after a Map Editor round trip.
///
/// A spatial group owns one map identity. Global Events deliberately carry no
/// map field so a non-spatial source cannot accidentally acquire a map picker.
final class NarrativeEventGroupContext {
  const NarrativeEventGroupContext.map(this.mapId)
      : kind = NarrativeEventGroupContextKind.map;

  const NarrativeEventGroupContext.global()
      : kind = NarrativeEventGroupContextKind.global,
        mapId = null;

  final NarrativeEventGroupContextKind kind;
  final String? mapId;

  @override
  bool operator ==(Object other) {
    return other is NarrativeEventGroupContext &&
        other.kind == kind &&
        other.mapId == mapId;
  }

  @override
  int get hashCode => Object.hash(kind, mapId);
}

enum NarrativeEventMapNavigationMode { view, choose, create }

final class NarrativeEventMapReturnToken {
  const NarrativeEventMapReturnToken({
    required this.requestId,
    required this.eventId,
    required this.groupContext,
    required this.expectedSource,
  });

  final String requestId;
  final String eventId;
  final NarrativeEventGroupContext groupContext;

  /// Exact source observed before leaving the Event Builder.
  ///
  /// The source is nullable for a future source-creation round trip, but an
  /// owner change on the same map is still a mismatch at return time.
  final NarrativeEventSourceRef? expectedSource;
}

final class NarrativeEventMapFocusRequest {
  const NarrativeEventMapFocusRequest({
    required this.requestId,
    required this.navigation,
    required this.returnToken,
    required this.source,
    required this.mode,
    this.cameraApplied = false,
  });

  final String requestId;
  final NarrativeEventNavigationIntent navigation;
  final NarrativeEventMapReturnToken returnToken;
  final NarrativeEventSourceRef source;
  final NarrativeEventMapNavigationMode mode;
  final bool cameraApplied;

  NarrativeEditorFocusTarget get focusTarget => navigation.focusTarget!;

  NarrativeEventMapFocusRequest markCameraApplied() {
    if (cameraApplied) return this;
    return NarrativeEventMapFocusRequest(
      requestId: requestId,
      navigation: navigation,
      returnToken: returnToken,
      source: source,
      mode: mode,
      cameraApplied: true,
    );
  }
}

enum NarrativeEventMapNavigationStatus {
  ready,
  blockedDirtyMap,
  unavailable,
  sourceMismatch,
  eventMissing,
  activationFailed,
  focusFailed,
}

final class NarrativeEventMapNavigationResult {
  const NarrativeEventMapNavigationResult({
    required this.status,
    required this.message,
    this.navigation,
  });

  final NarrativeEventMapNavigationStatus status;
  final String message;
  final NarrativeEventNavigationIntent? navigation;

  bool get succeeded => status == NarrativeEventMapNavigationStatus.ready;
}

/// Atomic request emitted by the Map Editor for an already existing source.
///
/// The source owns its map and owner identities. No parallel map, layer or
/// coordinate fields are intentionally exposed here.
final class NarrativeEventMapCreationIntent {
  NarrativeEventMapCreationIntent({
    required this.source,
    required String humanName,
  }) : humanName = _humanName(humanName) {
    if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
      throw ArgumentError.value(
        source,
        'source',
        'must be an entity, trigger, or map source',
      );
    }
  }

  final NarrativeEventSourceRef source;
  final String humanName;
}

enum NarrativeEventMapCreationStatus {
  blocked,
  existingLinks,
  committed,
  committedOutOfSync,
  authoringRejected,
  persistenceRejected,
  preflightRejected,
}

final class NarrativeEventMapLinkedEvent {
  const NarrativeEventMapLinkedEvent({
    required this.eventId,
    required this.name,
    required this.order,
    required this.enabled,
  });

  final String eventId;
  final String name;
  final int order;

  /// `null` identifies a draft; configured records carry their active state.
  final bool? enabled;
}

final class NarrativeEventMapCreationResult {
  NarrativeEventMapCreationResult._({
    required this.status,
    required this.code,
    required this.message,
    List<NarrativeEventMapLinkedEvent> linkedEvents = const [],
    this.eventId,
    this.nextRegistry,
    this.previousRegistry,
    this.authoringResult,
    this.persistenceResult,
  }) : linkedEvents = List.unmodifiable(linkedEvents);

  factory NarrativeEventMapCreationResult.blocked({
    required String code,
    required String message,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.blocked,
      code: code,
      message: message,
    );
  }

  factory NarrativeEventMapCreationResult.existingLinks(
    List<NarrativeEventMapLinkedEvent> linkedEvents,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.existingLinks,
      code: 'existingLinks',
      message: linkedEvents.length == 1
          ? 'Un Event utilise déjà cette source.'
          : '${linkedEvents.length} Events utilisent déjà cette source.',
      linkedEvents: linkedEvents,
    );
  }

  factory NarrativeEventMapCreationResult.committed({
    required String eventId,
    required NarrativeEventRegistry nextRegistry,
    required NarrativeEventRegistry? previousRegistry,
    required NarrativeEventAuthoringResult authoringResult,
    required NarrativeEventRegistryPersistenceResult persistenceResult,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.committed,
      code: persistenceResult.code,
      message: persistenceResult.message,
      eventId: eventId,
      nextRegistry: nextRegistry,
      previousRegistry: previousRegistry,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.committedOutOfSync(
    NarrativeEventMapCreationResult committed,
  ) {
    if (committed.status != NarrativeEventMapCreationStatus.committed) {
      throw ArgumentError.value(
        committed.status,
        'committed',
        'must be a committed result',
      );
    }
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.committedOutOfSync,
      code: 'committedOutOfSync',
      message: 'L’Event est enregistré sur disque, mais l’éditeur n’est plus '
          'synchronisé. Rechargez le projet avant de continuer.',
      eventId: committed.eventId,
      nextRegistry: committed.nextRegistry,
      previousRegistry: committed.previousRegistry,
      authoringResult: committed.authoringResult,
      persistenceResult: committed.persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.authoringRejected(
    NarrativeEventAuthoringResult result,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.authoringRejected,
      code: result.rejectionCode ?? result.status.name,
      message: result.humanReason ??
          'La création de l’Event a été refusée par le projet.',
      authoringResult: result,
    );
  }

  factory NarrativeEventMapCreationResult.persistenceRejected({
    required NarrativeEventAuthoringResult authoringResult,
    required NarrativeEventRegistryPersistenceResult persistenceResult,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.persistenceRejected,
      code: persistenceResult.code,
      message: persistenceResult.message,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.persistenceException(
    NarrativeEventAuthoringResult authoringResult,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.persistenceRejected,
      code: 'persistenceException',
      message: 'L’Event n’a pas pu être enregistré. Vérifiez le projet puis '
          'réessayez.',
      authoringResult: authoringResult,
    );
  }

  factory NarrativeEventMapCreationResult.preflightRejected(Object error) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.preflightRejected,
      code: 'preflightRejected',
      message: 'La session Event ne peut pas être préparée: $error',
    );
  }

  factory NarrativeEventMapCreationResult.unexpectedBridgeFailure() {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.preflightRejected,
      code: 'unexpectedBridgeFailure',
      message: 'L’opération Event a été interrompue. Vous pouvez réessayer '
          'sans modifier la map.',
    );
  }

  final NarrativeEventMapCreationStatus status;
  final String code;
  final String message;
  final List<NarrativeEventMapLinkedEvent> linkedEvents;
  final String? eventId;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

String _humanName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'humanName', 'must not be empty');
  }
  return normalized;
}
```

### 22.2 `packages/map_editor/lib/src/application/models/narrative_event_spatial_link_journal_models.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

enum NarrativeEventSpatialLinkJournalState {
  prepared,
  mapCommitted,
  eventCommitted,
}

enum NarrativeEventSpatialLinkCleanupMarker { none, requested }

enum NarrativeEventSpatialLinkCheckpoint {
  afterJournalPrepared,
  afterMapTempFlush,
  beforeMapRename,
  afterMapRename,
  afterMapVerified,
  afterCleanupJournalMarked,
  beforeCleanupRename,
  afterCleanupRename,
}

typedef NarrativeEventSpatialLinkFaultInjector = Future<void> Function(
  NarrativeEventSpatialLinkCheckpoint checkpoint,
);

enum NarrativeEventSpatialLinkOperationStatus {
  mapCommitted,
  eventCommitted,
  cleaned,
  recovered,
  noOp,
  conflict,
  blocked,
  ioFailure,
}

enum NarrativeEventSpatialLinkInspectionStatus {
  clear,
  preparedSourceAbsent,
  preparedSourcePresent,
  awaitingEventCommit,
  eventAlreadyLinked,
  cleanupPending,
  cleanupCompleted,
  blocked,
}

final class NarrativeEventSpatialLinkMapCommitRequest {
  NarrativeEventSpatialLinkMapCommitRequest({
    required String projectPath,
    required String projectRevision,
    required String operationId,
    required String eventId,
    required String eventRecordFingerprintBefore,
    required this.beforeMap,
    required this.afterMap,
    required this.source,
    required Map<String, Object?> sourceOwnerJson,
    required String sourceOwnerFingerprint,
  })  : projectPath = _identity(projectPath, 'projectPath'),
        projectRevision = _fingerprint(projectRevision, 'projectRevision'),
        operationId = _operationIdentity(operationId),
        eventId = _identity(eventId, 'eventId'),
        eventRecordFingerprintBefore = _fingerprint(
          eventRecordFingerprintBefore,
          'eventRecordFingerprintBefore',
        ),
        sourceOwnerJson = _canonicalObject(sourceOwnerJson),
        sourceOwnerFingerprint = _fingerprint(
          sourceOwnerFingerprint,
          'sourceOwnerFingerprint',
        ) {
    final sourceMapId = narrativeEventSpatialSourceMapId(source);
    if (sourceMapId == null) {
      throw ArgumentError.value(
        source,
        'source',
        'must be an entityInteract or triggerEnter source',
      );
    }
    if (beforeMap.id != sourceMapId || afterMap.id != sourceMapId) {
      throw ArgumentError.value(
        source,
        'source',
        'must own both map snapshots',
      );
    }
    final computed = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(this.sourceOwnerJson),
    );
    if (computed != this.sourceOwnerFingerprint) {
      throw ArgumentError.value(
        sourceOwnerFingerprint,
        'sourceOwnerFingerprint',
        'must match the canonical owner JSON',
      );
    }
  }

  final String projectPath;
  final String projectRevision;
  final String operationId;
  final String eventId;
  final String eventRecordFingerprintBefore;
  final MapData beforeMap;
  final MapData afterMap;
  final NarrativeEventSourceRef source;
  final Map<String, Object?> sourceOwnerJson;
  final String sourceOwnerFingerprint;
}

final class NarrativeEventSpatialLinkJournal {
  NarrativeEventSpatialLinkJournal({
    required this.schemaVersion,
    required String operationId,
    required String projectPath,
    required String projectRevision,
    required String journalPath,
    required String mapPath,
    required String mapTempPath,
    required String mapId,
    required String eventId,
    required String eventRecordFingerprintBefore,
    required this.source,
    required Map<String, Object?> sourceOwnerJson,
    required String sourceOwnerFingerprint,
    required String beforeMapHash,
    required String afterMapHash,
    required this.state,
    required this.preparedAt,
    this.mapCommittedAt,
    this.eventCommittedAt,
    required this.cleanupMarker,
    this.cleanupRequestedAt,
  })  : operationId = _operationIdentity(operationId),
        projectPath = _identity(projectPath, 'projectPath'),
        projectRevision = _fingerprint(projectRevision, 'projectRevision'),
        journalPath = _identity(journalPath, 'journalPath'),
        mapPath = _identity(mapPath, 'mapPath'),
        mapTempPath = _identity(mapTempPath, 'mapTempPath'),
        mapId = _identity(mapId, 'mapId'),
        eventId = _identity(eventId, 'eventId'),
        eventRecordFingerprintBefore = _fingerprint(
          eventRecordFingerprintBefore,
          'eventRecordFingerprintBefore',
        ),
        sourceOwnerJson = _canonicalObject(sourceOwnerJson),
        sourceOwnerFingerprint = _fingerprint(
          sourceOwnerFingerprint,
          'sourceOwnerFingerprint',
        ),
        beforeMapHash = _fingerprint(beforeMapHash, 'beforeMapHash'),
        afterMapHash = _fingerprint(afterMapHash, 'afterMapHash') {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    final sourceMapId = narrativeEventSpatialSourceMapId(source);
    if (sourceMapId == null || sourceMapId != this.mapId) {
      throw ArgumentError.value(source, 'source', 'must own mapId');
    }
    final computedOwnerFingerprint = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(this.sourceOwnerJson),
    );
    if (computedOwnerFingerprint != this.sourceOwnerFingerprint) {
      throw ArgumentError.value(
        sourceOwnerFingerprint,
        'sourceOwnerFingerprint',
        'must match sourceOwnerJson',
      );
    }
    _validateLifecycle(this);
  }

  factory NarrativeEventSpatialLinkJournal.fromJson(
    Map<String, Object?> json,
  ) {
    _expectExactFields(json, const {
      'schemaVersion',
      'operationId',
      'projectPath',
      'projectRevision',
      'journalPath',
      'mapPath',
      'mapTempPath',
      'mapId',
      'eventId',
      'eventRecordFingerprintBefore',
      'source',
      'sourceOwnerJson',
      'sourceOwnerFingerprint',
      'beforeMapHash',
      'afterMapHash',
      'state',
      'preparedAt',
      'mapCommittedAt',
      'eventCommittedAt',
      'cleanupMarker',
      'cleanupRequestedAt',
    });
    return NarrativeEventSpatialLinkJournal(
      schemaVersion: _integer(json, 'schemaVersion'),
      operationId: _string(json, 'operationId'),
      projectPath: _string(json, 'projectPath'),
      projectRevision: _string(json, 'projectRevision'),
      journalPath: _string(json, 'journalPath'),
      mapPath: _string(json, 'mapPath'),
      mapTempPath: _string(json, 'mapTempPath'),
      mapId: _string(json, 'mapId'),
      eventId: _string(json, 'eventId'),
      eventRecordFingerprintBefore:
          _string(json, 'eventRecordFingerprintBefore'),
      source: NarrativeEventSourceRef.fromJson(json['source']),
      sourceOwnerJson: _object(json['sourceOwnerJson'], 'sourceOwnerJson'),
      sourceOwnerFingerprint: _string(json, 'sourceOwnerFingerprint'),
      beforeMapHash: _string(json, 'beforeMapHash'),
      afterMapHash: _string(json, 'afterMapHash'),
      state: _enumByName(
        NarrativeEventSpatialLinkJournalState.values,
        _string(json, 'state'),
        'state',
      ),
      preparedAt: _dateTime(json, 'preparedAt')!,
      mapCommittedAt: _dateTime(json, 'mapCommittedAt'),
      eventCommittedAt: _dateTime(json, 'eventCommittedAt'),
      cleanupMarker: _enumByName(
        NarrativeEventSpatialLinkCleanupMarker.values,
        _string(json, 'cleanupMarker'),
        'cleanupMarker',
      ),
      cleanupRequestedAt: _dateTime(json, 'cleanupRequestedAt'),
    );
  }

  final int schemaVersion;
  final String operationId;
  final String projectPath;
  final String projectRevision;
  final String journalPath;
  final String mapPath;
  final String mapTempPath;
  final String mapId;
  final String eventId;
  final String eventRecordFingerprintBefore;
  final NarrativeEventSourceRef source;
  final Map<String, Object?> sourceOwnerJson;
  final String sourceOwnerFingerprint;
  final String beforeMapHash;
  final String afterMapHash;
  final NarrativeEventSpatialLinkJournalState state;
  final DateTime preparedAt;
  final DateTime? mapCommittedAt;
  final DateTime? eventCommittedAt;
  final NarrativeEventSpatialLinkCleanupMarker cleanupMarker;
  final DateTime? cleanupRequestedAt;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'operationId': operationId,
        'projectPath': projectPath,
        'projectRevision': projectRevision,
        'journalPath': journalPath,
        'mapPath': mapPath,
        'mapTempPath': mapTempPath,
        'mapId': mapId,
        'eventId': eventId,
        'eventRecordFingerprintBefore': eventRecordFingerprintBefore,
        'source': source.toJson(),
        'sourceOwnerJson': sourceOwnerJson,
        'sourceOwnerFingerprint': sourceOwnerFingerprint,
        'beforeMapHash': beforeMapHash,
        'afterMapHash': afterMapHash,
        'state': state.name,
        'preparedAt': preparedAt.toUtc().toIso8601String(),
        'mapCommittedAt': mapCommittedAt?.toUtc().toIso8601String(),
        'eventCommittedAt': eventCommittedAt?.toUtc().toIso8601String(),
        'cleanupMarker': cleanupMarker.name,
        'cleanupRequestedAt': cleanupRequestedAt?.toUtc().toIso8601String(),
      };

  NarrativeEventSpatialLinkJournal markMapCommitted(DateTime at) {
    return _copy(
      state: NarrativeEventSpatialLinkJournalState.mapCommitted,
      mapCommittedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal markEventCommitted(DateTime at) {
    return _copy(
      state: NarrativeEventSpatialLinkJournalState.eventCommitted,
      eventCommittedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal markCleanupRequested(DateTime at) {
    return _copy(
      cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.requested,
      cleanupRequestedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal _copy({
    NarrativeEventSpatialLinkJournalState? state,
    DateTime? mapCommittedAt,
    DateTime? eventCommittedAt,
    NarrativeEventSpatialLinkCleanupMarker? cleanupMarker,
    DateTime? cleanupRequestedAt,
  }) {
    return NarrativeEventSpatialLinkJournal(
      schemaVersion: schemaVersion,
      operationId: operationId,
      projectPath: projectPath,
      projectRevision: projectRevision,
      journalPath: journalPath,
      mapPath: mapPath,
      mapTempPath: mapTempPath,
      mapId: mapId,
      eventId: eventId,
      eventRecordFingerprintBefore: eventRecordFingerprintBefore,
      source: source,
      sourceOwnerJson: sourceOwnerJson,
      sourceOwnerFingerprint: sourceOwnerFingerprint,
      beforeMapHash: beforeMapHash,
      afterMapHash: afterMapHash,
      state: state ?? this.state,
      preparedAt: preparedAt,
      mapCommittedAt: mapCommittedAt ?? this.mapCommittedAt,
      eventCommittedAt: eventCommittedAt ?? this.eventCommittedAt,
      cleanupMarker: cleanupMarker ?? this.cleanupMarker,
      cleanupRequestedAt: cleanupRequestedAt ?? this.cleanupRequestedAt,
    );
  }
}

final class NarrativeEventSpatialLinkInspectionIssue {
  const NarrativeEventSpatialLinkInspectionIssue({
    required this.code,
    required this.message,
    this.path,
  });

  final String code;
  final String message;
  final String? path;
}

final class NarrativeEventSpatialLinkInspection {
  NarrativeEventSpatialLinkInspection({
    required this.status,
    this.journal,
    List<NarrativeEventSpatialLinkInspectionIssue> issues = const [],
  }) : issues = List.unmodifiable(issues);

  final NarrativeEventSpatialLinkInspectionStatus status;
  final NarrativeEventSpatialLinkJournal? journal;
  final List<NarrativeEventSpatialLinkInspectionIssue> issues;
}

final class NarrativeEventSpatialLinkOperationResult {
  const NarrativeEventSpatialLinkOperationResult({
    required this.status,
    required this.code,
    required this.message,
    this.journal,
    this.inspection,
  });

  final NarrativeEventSpatialLinkOperationStatus status;
  final String code;
  final String message;
  final NarrativeEventSpatialLinkJournal? journal;
  final NarrativeEventSpatialLinkInspection? inspection;

  bool get succeeded => switch (status) {
        NarrativeEventSpatialLinkOperationStatus.mapCommitted ||
        NarrativeEventSpatialLinkOperationStatus.eventCommitted ||
        NarrativeEventSpatialLinkOperationStatus.cleaned ||
        NarrativeEventSpatialLinkOperationStatus.recovered ||
        NarrativeEventSpatialLinkOperationStatus.noOp =>
          true,
        _ => false,
      };
}

String? narrativeEventSpatialSourceMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (_) => null,
    outcomeReceived: (_) => null,
  );
}

String narrativeEventRecordCanonicalFingerprint(NarrativeEventRecord record) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(
      _normalizeJsonValue(record.toJson()),
    ),
  );
}

String narrativeEventSpatialSourceOwnerId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (_, entityId) => entityId,
    triggerEnter: (_, triggerId) => triggerId,
    mapEnter: (_) => throw ArgumentError.value(source, 'source'),
    outcomeReceived: (_) => throw ArgumentError.value(source, 'source'),
  );
}

void _validateLifecycle(NarrativeEventSpatialLinkJournal journal) {
  final timestamps = [
    journal.preparedAt,
    journal.mapCommittedAt,
    journal.eventCommittedAt,
    journal.cleanupRequestedAt,
  ].whereType<DateTime>();
  if (timestamps.any((value) => !value.isUtc)) {
    throw ArgumentError('Journal timestamps must be UTC.');
  }
  if (journal.mapCommittedAt?.isBefore(journal.preparedAt) == true ||
      journal.eventCommittedAt?.isBefore(
            journal.mapCommittedAt ?? journal.preparedAt,
          ) ==
          true ||
      journal.cleanupRequestedAt?.isBefore(journal.preparedAt) == true) {
    throw ArgumentError('Journal timestamps must be monotonic.');
  }
  final lifecycleValid = switch (journal.state) {
    NarrativeEventSpatialLinkJournalState.prepared =>
      journal.mapCommittedAt == null && journal.eventCommittedAt == null,
    NarrativeEventSpatialLinkJournalState.mapCommitted =>
      journal.mapCommittedAt != null && journal.eventCommittedAt == null,
    NarrativeEventSpatialLinkJournalState.eventCommitted =>
      journal.mapCommittedAt != null && journal.eventCommittedAt != null,
  };
  if (!lifecycleValid) {
    throw ArgumentError('Journal state and timestamps are inconsistent.');
  }
  final cleanupValid = switch (journal.cleanupMarker) {
    NarrativeEventSpatialLinkCleanupMarker.none =>
      journal.cleanupRequestedAt == null,
    NarrativeEventSpatialLinkCleanupMarker.requested =>
      journal.cleanupRequestedAt != null &&
          journal.state == NarrativeEventSpatialLinkJournalState.mapCommitted,
  };
  if (!cleanupValid) {
    throw ArgumentError('Journal cleanup marker is inconsistent.');
  }
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _operationIdentity(String value) {
  final normalized = _identity(value, 'operationId');
  if (normalized.length > 96 ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'operationId', 'must be path-safe');
  }
  return normalized;
}

String _fingerprint(String value, String name) {
  final normalized = _identity(value, name);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a SHA-256 fingerprint');
  }
  return normalized;
}

Map<String, Object?> _canonicalObject(Map<String, Object?> value) {
  final decoded = _normalizeJsonValue(value);
  if (decoded is! Map) {
    throw const FormatException('Expected a canonical JSON object.');
  }
  return _deepFreeze(decoded) as Map<String, Object?>;
}

Object? _normalizeJsonValue(Object? value) {
  return decodeNarrativeEventJsonStrict(jsonEncode(value));
}

Object? _deepFreeze(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _deepFreeze(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_deepFreeze));
  }
  return value;
}

void _expectExactFields(Map<String, Object?> json, Set<String> expected) {
  final unknown = json.keys.where((key) => !expected.contains(key)).toList();
  final missing = expected.where((key) => !json.containsKey(key)).toList();
  if (unknown.isNotEmpty || missing.isNotEmpty) {
    throw FormatException(
      'Unexpected fields: ${unknown.join(', ')}; '
      'missing fields: ${missing.join(', ')}.',
    );
  }
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Map<String, Object?> _object(Object? value, String key) {
  if (value is! Map) throw FormatException('$key must be an object.');
  return {
    for (final entry in value.entries) entry.key as String: entry.value,
  };
}

DateTime? _dateTime(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a timestamp.');
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$key must be an explicit UTC timestamp.');
  }
  return parsed;
}

T _enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $field: $name.');
}
```

### 22.3 `packages/map_editor/lib/src/application/models/narrative_event_spatial_source_creation_models.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

/// Physical owners that the Map Editor can materialize for an Event V2.
enum NarrativeEventPhysicalSourceKind {
  npc,
  sign,
  item,
  invisible,
  zone1x1,
}

/// Pure before/after proposal for one real source owned by a map.
///
/// The proposal is deliberately detached from editor state and persistence.
/// Its immutable owner envelope is the exact payload used by the two-commit
/// workflow to detect changes to the physical source.
final class NarrativeEventCreatedSourceProposal {
  factory NarrativeEventCreatedSourceProposal({
    required NarrativeEventPhysicalSourceKind physicalKind,
    required NarrativeEventSourceRef source,
    required MapData beforeMap,
    required MapData afterMap,
    required MapRect bounds,
    required Map<String, Object?> ownerJson,
  }) {
    final normalizedOwnerJson = Map<String, Object?>.from(
      (jsonDecode(jsonEncode(ownerJson)) as Map).cast<String, Object?>(),
    );
    final frozenOwnerJson = _freezeJsonObject(normalizedOwnerJson);
    return NarrativeEventCreatedSourceProposal._(
      physicalKind: physicalKind,
      source: source,
      beforeMap: beforeMap,
      afterMap: afterMap,
      bounds: bounds,
      ownerJson: frozenOwnerJson,
      ownerFingerprint: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(frozenOwnerJson),
      ),
    );
  }

  const NarrativeEventCreatedSourceProposal._({
    required this.physicalKind,
    required this.source,
    required this.beforeMap,
    required this.afterMap,
    required this.bounds,
    required this.ownerJson,
    required this.ownerFingerprint,
  });

  final NarrativeEventPhysicalSourceKind physicalKind;
  final NarrativeEventSourceRef source;
  final MapData beforeMap;
  final MapData afterMap;
  final MapRect bounds;
  final Map<String, Object?> ownerJson;
  final String ownerFingerprint;
}

Map<String, Object?> _freezeJsonObject(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, nested) => MapEntry(key, _freezeJsonValue(nested)),
    ),
  );
}

Object? _freezeJsonValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      value.map(
        (key, nested) => MapEntry(key.toString(), _freezeJsonValue(nested)),
      ),
    );
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
  }
  return value;
}
```

### 22.4 `packages/map_editor/lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/narrative_event_spatial_link_journal_models.dart';

abstract interface class NarrativeEventSpatialSourceCreationGateway {
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  );

  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  );

  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  });

  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  });

  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  });

  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  });
}
```

### 22.5 `packages/map_editor/lib/src/application/services/map_focus_viewport_resolver.dart`

```dart
import 'dart:ui';

import 'package:map_core/map_core.dart';

Offset resolveMapFocusPanOffset({
  required MapRect bounds,
  required Size viewportSize,
  required double tileWidth,
  required double tileHeight,
  required double zoom,
}) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0) {
    throw ArgumentError.value(viewportSize, 'viewportSize');
  }
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    throw ArgumentError('Tile dimensions and zoom must be positive.');
  }
  final worldCenter = Offset(
    (bounds.pos.x + bounds.size.width / 2) * tileWidth,
    (bounds.pos.y + bounds.size.height / 2) * tileHeight,
  );
  return viewportSize.center(Offset.zero) - worldCenter * zoom;
}

MapRect resolveNarrativeEventMapFocusBounds({
  required NarrativeEditorFocusTarget focus,
  required MapData map,
}) {
  if (focus.mapId != map.id) {
    throw ArgumentError.value(
      focus.mapId,
      'focus',
      'must target the active map',
    );
  }
  final bounds = focus.bounds;
  if (bounds != null) return bounds;
  if (focus.kind != NarrativeEditorFocusTargetKind.map) {
    throw ArgumentError.value(
      focus,
      'focus',
      'an entity or trigger focus must carry bounds',
    );
  }
  return MapRect(
    pos: const GridPos(x: 0, y: 0),
    size: map.size,
  );
}
```

### 22.6 `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart`

```dart
import 'package:map_core/map_core.dart';

final class NarrativeEventSourceDependencyDecision {
  NarrativeEventSourceDependencyDecision._({
    required this.isAllowed,
    required List<String> linkedEventIds,
    required this.message,
  }) : linkedEventIds = List.unmodifiable(linkedEventIds);

  factory NarrativeEventSourceDependencyDecision.allowed() {
    return NarrativeEventSourceDependencyDecision._(
      isAllowed: true,
      linkedEventIds: const [],
      message: null,
    );
  }

  factory NarrativeEventSourceDependencyDecision.blocked({
    required List<String> linkedEventIds,
    required String operation,
  }) {
    return NarrativeEventSourceDependencyDecision._(
      isAllowed: false,
      linkedEventIds: linkedEventIds,
      message: 'Action bloquée ($operation) : source utilisée par '
          '${linkedEventIds.join(', ')}.',
    );
  }

  final bool isAllowed;
  final List<String> linkedEventIds;
  final String? message;
}

/// Protects physical identities referenced by every Event V2 record state.
///
/// This guard deliberately scans the registry records directly. The runtime
/// source index excludes drafts and disabled configured records and therefore
/// cannot be used for destructive editor decisions.
final class NarrativeEventSourceDependencyGuard {
  const NarrativeEventSourceDependencyGuard();

  NarrativeEventSourceDependencyDecision inspectMapRename({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String newMapId,
  }) {
    if (mapId == newMapId) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) => _mapId(source) == mapId,
      operation: 'renommage de la map $mapId',
    );
  }

  NarrativeEventSourceDependencyDecision inspectMapDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) => _mapId(source) == mapId,
      operation: 'suppression de la map $mapId',
    );
  }

  /// Blocks only degradations introduced by a history transition.
  ///
  /// A source which was already unresolved in [current] is deliberately
  /// ignored so an unrelated undo/redo, or a transition repairing that
  /// source, cannot become trapped by stale registry data.
  NarrativeEventSourceDependencyDecision inspectMapTransition({
    required NarrativeEventRegistry? registry,
    required MapData current,
    required MapData candidate,
    required String operation,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          _isResolvedByMap(source, current) &&
          !_isResolvedByMap(source, candidate),
      operation: operation,
    );
  }

  NarrativeEventSourceDependencyDecision inspectEntityUpdate({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required MapEntity current,
    required MapEntity next,
  }) {
    final breaksIdentity = current.id != next.id;
    final becomesSpawn =
        current.kind != MapEntityKind.spawn && next.kind == MapEntityKind.spawn;
    if (!breaksIdentity && !becomesSpawn) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.entityInteract(mapId, current.id),
      operation: breaksIdentity
          ? 'renommage de l’entité ${current.id}'
          : 'conversion de l’entité ${current.id} en spawn',
    );
  }

  NarrativeEventSourceDependencyDecision inspectEntityDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String entityId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.entityInteract(mapId, entityId),
      operation: 'suppression de l’entité $entityId',
    );
  }

  NarrativeEventSourceDependencyDecision inspectTriggerUpdate({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required MapTrigger current,
    required MapTrigger next,
  }) {
    final breaksIdentity = current.id != next.id;
    final leavesEventSourceKinds = _isEventSourceTrigger(current.type) &&
        !_isEventSourceTrigger(next.type);
    if (!breaksIdentity && !leavesEventSourceKinds) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.triggerEnter(mapId, current.id),
      operation: breaksIdentity
          ? 'renommage du déclencheur ${current.id}'
          : 'conversion système du déclencheur ${current.id}',
    );
  }

  NarrativeEventSourceDependencyDecision inspectTriggerDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String triggerId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
      operation: 'suppression du déclencheur $triggerId',
    );
  }
}

NarrativeEventSourceDependencyDecision _decision({
  required NarrativeEventRegistry? registry,
  required bool Function(NarrativeEventSourceRef source) matches,
  required String operation,
}) {
  final eventIds = <String>[
    for (final record in registry?.records ?? const <NarrativeEventRecord>[])
      if (record.when(
        draft: (draft) => draft.source != null && matches(draft.source!),
        configured: (definition, _) => matches(definition.source),
      ))
        record.id,
  ]..sort(compareNarrativeEventUtf16);
  if (eventIds.isEmpty) {
    return NarrativeEventSourceDependencyDecision.allowed();
  }
  return NarrativeEventSourceDependencyDecision.blocked(
    linkedEventIds: eventIds,
    operation: operation,
  );
}

String? _mapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => null,
  );
}

bool _isEventSourceTrigger(TriggerType type) {
  return type == TriggerType.event || type == TriggerType.custom;
}

bool _isResolvedByMap(NarrativeEventSourceRef source, MapData map) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapId == map.id &&
        map.entities.any(
          (entity) =>
              entity.id == entityId && entity.kind != MapEntityKind.spawn,
        ),
    triggerEnter: (mapId, triggerId) =>
        mapId == map.id &&
        map.triggers.any(
          (trigger) =>
              trigger.id == triggerId && _isEventSourceTrigger(trigger.type),
        ),
    mapEnter: (mapId) => mapId == map.id,
    outcomeReceived: (_) => false,
  );
}
```

### 22.7 `packages/map_editor/lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_map_bridge_models.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventMapBridgeSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);
typedef NarrativeEventIdGeneratorFactory = NarrativeEventIdGenerator Function();

final class CreateNarrativeEventFromMapSourceUseCase {
  CreateNarrativeEventFromMapSourceUseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventMapBridgeSession? prepareSession,
    NarrativeEventIdGeneratorFactory? eventIdGeneratorFactory,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _eventIdGeneratorFactory =
            eventIdGeneratorFactory ?? NarrativeEventIdGenerator.new,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventMapBridgeSession _prepareSession;
  final NarrativeEventIdGeneratorFactory _eventIdGeneratorFactory;
  final String Function() _operationIdFactory;

  Future<NarrativeEventMapCreationResult> call({
    required String projectPath,
    required NarrativeEventMapCreationIntent intent,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    bool allowAdditionalEvent = false,
  }) async {
    final blocked = _dirtyGuard(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventMapCreationResult.preflightRejected(error);
    }

    final existingLinks = _exactLinks(
      session.context.registryOrNull,
      intent.source,
    );
    if (existingLinks.isNotEmpty && !allowAdditionalEvent) {
      return NarrativeEventMapCreationResult.existingLinks(existingLinks);
    }

    final authoringResult = createNarrativeEventDraft(
      context: session.context,
      expectedRevision: session.projectRevision,
      name: intent.humanName,
      initialSource: intent.source,
      idGenerator: _eventIdGeneratorFactory(),
    );
    if (authoringResult.status != NarrativeEventAuthoringStatus.applied ||
        authoringResult.nextRegistry == null ||
        authoringResult.eventId == null) {
      return NarrativeEventMapCreationResult.authoringRejected(
        authoringResult,
      );
    }

    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: _operationIdFactory(),
      result: authoringResult,
    );
    late final NarrativeEventRegistryPersistenceResult persistenceResult;
    try {
      persistenceResult = await _persistenceGateway.persist(request);
    } on Object {
      return NarrativeEventMapCreationResult.persistenceException(
        authoringResult,
      );
    }
    if (!persistenceResult.succeeded) {
      return NarrativeEventMapCreationResult.persistenceRejected(
        authoringResult: authoringResult,
        persistenceResult: persistenceResult,
      );
    }
    return NarrativeEventMapCreationResult.committed(
      eventId: authoringResult.eventId!,
      nextRegistry: request.nextRegistry,
      previousRegistry: request.previousRegistry,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }
}

NarrativeEventMapCreationResult? _dirtyGuard({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde avant de créer un Event.',
    );
  }
  if (mapDirty) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'mapDirty',
      message: 'Enregistrez la map avant de créer un Event depuis sa source.',
    );
  }
  if (projectDirty) {
    return NarrativeEventMapCreationResult.blocked(
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de créer un Event.',
    );
  }
  return null;
}

List<NarrativeEventMapLinkedEvent> _exactLinks(
  NarrativeEventRegistry? registry,
  NarrativeEventSourceRef source,
) {
  final links = <NarrativeEventMapLinkedEvent>[];
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    final link = record.when<NarrativeEventMapLinkedEvent?>(
      draft: (draft) => draft.source == source
          ? NarrativeEventMapLinkedEvent(
              eventId: draft.id,
              name: draft.name,
              order: draft.order,
              enabled: null,
            )
          : null,
      configured: (definition, enabled) => definition.source == source
          ? NarrativeEventMapLinkedEvent(
              eventId: definition.id,
              name: definition.name,
              order: definition.order,
              enabled: enabled,
            )
          : null,
    );
    if (link != null) links.add(link);
  }
  links.sort((left, right) {
    final orderComparison = left.order.compareTo(right.order);
    if (orderComparison != 0) return orderComparison;
    return compareNarrativeEventUtf16(left.eventId, right.eventId);
  });
  return List.unmodifiable(links);
}

String _defaultOperationId() {
  return 'v2_23_${DateTime.now().microsecondsSinceEpoch}';
}
```

### 22.8 `packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../models/narrative_event_spatial_link_journal_models.dart';
import '../models/narrative_event_spatial_source_creation_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';
import '../ports/narrative_event_spatial_source_creation_gateway.dart';

typedef PrepareNarrativeEventExplicitSourceSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);

enum NarrativeEventExplicitSourceCreationStatus {
  blocked,
  committed,
  recoveryRequired,
  cleaned,
  clear,
  rejected,
}

final class NarrativeEventExplicitSourceCreationResult {
  const NarrativeEventExplicitSourceCreationResult({
    required this.status,
    required this.code,
    required this.message,
    this.journal,
    this.inspection,
    this.previousRegistry,
    this.nextRegistry,
    this.persistenceResult,
  });

  final NarrativeEventExplicitSourceCreationStatus status;
  final String code;
  final String message;
  final NarrativeEventSpatialLinkJournal? journal;
  final NarrativeEventSpatialLinkInspection? inspection;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

final class NarrativeEventExplicitSourceCreationUseCase {
  NarrativeEventExplicitSourceCreationUseCase({
    required NarrativeEventSpatialSourceCreationGateway sourceGateway,
    required NarrativeEventRegistryPersistenceGateway registryGateway,
    PrepareNarrativeEventExplicitSourceSession? prepareSession,
    String Function()? operationIdFactory,
  })  : _sourceGateway = sourceGateway,
        _registryGateway = registryGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventSpatialSourceCreationGateway _sourceGateway;
  final NarrativeEventRegistryPersistenceGateway _registryGateway;
  final PrepareNarrativeEventExplicitSourceSession _prepareSession;
  final String Function() _operationIdFactory;

  Future<NarrativeEventExplicitSourceCreationResult> inspect({
    required String projectPath,
    String? expectedEventId,
    String? expectedMapId,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    try {
      final inspection = await _sourceGateway.inspectProject(projectPath);
      final mismatch = _journalBindingMismatch(
        inspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (mismatch != null) return mismatch;
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return NarrativeEventExplicitSourceCreationResult(
          status: NarrativeEventExplicitSourceCreationStatus.clear,
          code: 'clear',
          message: 'Aucune création de source à récupérer.',
          inspection: inspection,
        );
      }
      return _recovery(
        code: inspection.issues.firstOrNull?.code ?? inspection.status.name,
        message: inspection.issues.firstOrNull?.message ??
            'Une création de source Event doit être récupérée.',
        journal: inspection.journal,
        inspection: inspection,
      );
    } on Object catch (error) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'inspectionException',
        message: 'La récupération ne peut pas être inspectée: $error',
      );
    }
  }

  Future<NarrativeEventExplicitSourceCreationResult> createAndLink({
    required String projectPath,
    required String eventId,
    required NarrativeEventCreatedSourceProposal proposal,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    final proposalIssue = _proposalIssue(proposal);
    if (proposalIssue != null) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'invalidProposal',
        message: proposalIssue,
      );
    }

    late final NarrativeEventAuthoringSession initialSession;
    try {
      initialSession = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
      );
    }
    final initialRecord = _uniqueEventRecord(
      initialSession.context.registryOrNull,
      eventId,
    );
    if (initialRecord?.draftOrNull == null ||
        initialRecord!.draftOrNull!.source != null) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'sourceLessDraftRequired',
        message: 'Seul un draft Event sans source peut créer une source.',
      );
    }

    final operationId = _operationIdFactory();
    late final NarrativeEventSpatialLinkOperationResult mapCommit;
    try {
      mapCommit = await _sourceGateway.commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: initialSession.projectPath,
          projectRevision: initialSession.projectRevision,
          operationId: operationId,
          eventId: eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(initialRecord),
          beforeMap: proposal.beforeMap,
          afterMap: proposal.afterMap,
          source: proposal.source,
          sourceOwnerJson: proposal.ownerJson,
          sourceOwnerFingerprint: proposal.ownerFingerprint,
        ),
      );
    } on Object catch (error) {
      return _afterMapCommitException(
        projectPath: initialSession.projectPath,
        error: error,
      );
    }
    final durableJournal = mapCommit.journal ?? mapCommit.inspection?.journal;
    if (mapCommit.status !=
            NarrativeEventSpatialLinkOperationStatus.mapCommitted ||
        durableJournal == null) {
      if (durableJournal != null) {
        return _recovery(
          code: mapCommit.code,
          message: mapCommit.message,
          journal: durableJournal,
          inspection: mapCommit.inspection,
        );
      }
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: mapCommit.code,
        message: mapCommit.message,
        inspection: mapCommit.inspection,
      );
    }

    return _commitEventFromJournal(
      projectPath: initialSession.projectPath,
      journal: durableJournal,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> retry({
    required String projectPath,
    String? expectedEventId,
    String? expectedMapId,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    late NarrativeEventSpatialLinkInspection sourceInspection;
    try {
      sourceInspection = await _sourceGateway.inspectProject(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'sourceInspectionException',
        message: 'La source durable ne peut pas être inspectée: $error',
      );
    }
    final initialMismatch = _journalBindingMismatch(
      sourceInspection,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
    );
    if (initialMismatch != null) return initialMismatch;
    if (sourceInspection.status ==
        NarrativeEventSpatialLinkInspectionStatus.clear) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.clear,
        code: 'noPendingCreation',
        message: 'Aucune création de source à réessayer.',
        inspection: sourceInspection,
      );
    }

    final registryRecovery = await _recoverRegistryBeforeRetry(projectPath);
    if (registryRecovery != null) {
      return NarrativeEventExplicitSourceCreationResult(
        status: registryRecovery.status,
        code: registryRecovery.code,
        message: registryRecovery.message,
        journal: registryRecovery.journal ?? sourceInspection.journal,
        inspection: registryRecovery.inspection ?? sourceInspection,
        previousRegistry: registryRecovery.previousRegistry,
        nextRegistry: registryRecovery.nextRegistry,
        persistenceResult: registryRecovery.persistenceResult,
      );
    }

    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.blocked &&
        sourceInspection.issues.firstOrNull?.code ==
            'eventRegistryRecoveryRequired') {
      try {
        sourceInspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceReinspectionException',
          message: 'La source récupérée ne peut pas être réinspectée: $error',
          journal: sourceInspection.journal,
          inspection: sourceInspection,
        );
      }
      final registryRecoveredMismatch = _journalBindingMismatch(
        sourceInspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (registryRecoveredMismatch != null) {
        return registryRecoveredMismatch;
      }
    }

    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent) {
      late final NarrativeEventSpatialLinkOperationResult recovered;
      final inspectedJournal = sourceInspection.journal!;
      try {
        recovered = await _sourceGateway.recoverProject(
          projectPath: projectPath,
          expectedOperationId: inspectedJournal.operationId,
          expectedEventId: inspectedJournal.eventId,
          expectedMapId: inspectedJournal.mapId,
          expectedSource: inspectedJournal.source,
        );
      } on Object catch (error) {
        return _recovery(
          code: 'sourceRecoveryException',
          message: 'La récupération du commit map a échoué: $error',
          journal: sourceInspection.journal,
          inspection: sourceInspection,
        );
      }
      if (!recovered.succeeded) {
        return _recovery(
          code: recovered.code,
          message: recovered.message,
          journal: recovered.journal ?? sourceInspection.journal,
          inspection: recovered.inspection ?? sourceInspection,
        );
      }
      try {
        sourceInspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceReinspectionException',
          message: 'La source récupérée ne peut pas être réinspectée: $error',
          journal: recovered.journal ?? sourceInspection.journal,
          inspection: recovered.inspection ?? sourceInspection,
        );
      }
      final recoveredMismatch = _journalBindingMismatch(
        sourceInspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (recoveredMismatch != null) return recoveredMismatch;
      if (sourceInspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return NarrativeEventExplicitSourceCreationResult(
          status: NarrativeEventExplicitSourceCreationStatus.clear,
          code: recovered.code,
          message: recovered.message,
          journal: recovered.journal,
          inspection: sourceInspection,
        );
      }
    }
    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.blocked ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.cleanupPending ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted) {
      return _recovery(
        code: sourceInspection.issues.firstOrNull?.code ??
            sourceInspection.status.name,
        message: sourceInspection.issues.firstOrNull?.message ??
            'La création ne peut pas être réessayée automatiquement.',
        journal: sourceInspection.journal,
        inspection: sourceInspection,
      );
    }

    final journal = sourceInspection.journal;
    if (journal == null) {
      return _recovery(
        code: 'journalMissing',
        message: 'Le journal de création est introuvable.',
        inspection: sourceInspection,
      );
    }

    return _commitEventFromJournal(
      projectPath: projectPath,
      journal: journal,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      _recoverRegistryBeforeRetry(String projectPath) async {
    late final NarrativeEventRegistryRecoveryInspection registryInspection;
    try {
      registryInspection = await _registryGateway.inspectRecovery(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'registryInspectionException',
        message: 'Le registre Event ne peut pas être inspecté: $error',
      );
    }
    if (registryInspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked) {
      return _recovery(
        code: registryInspection.issues.firstOrNull?.code ??
            'registryRecoveryBlocked',
        message: registryInspection.issues.firstOrNull?.message ??
            'La récupération du registre Event est bloquée.',
      );
    }
    if (registryInspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryRequired) {
      late final List<NarrativeEventRegistryPersistenceResult> recovered;
      try {
        recovered = await _registryGateway.recover(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'registryRecoveryException',
          message: 'La récupération du registre Event a échoué: $error',
        );
      }
      final failure =
          recovered.where((result) => !result.succeeded).firstOrNull;
      if (failure != null) {
        return _recovery(
          code: failure.code,
          message: failure.message,
          persistenceResult: failure,
        );
      }
    }
    return null;
  }

  Future<NarrativeEventExplicitSourceCreationResult> cleanup({
    required String projectPath,
    required String operationId,
    String? expectedEventId,
    String? expectedMapId,
    required bool confirmed,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;
    if (!confirmed) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.blocked,
        code: 'confirmationRequired',
        message: 'Confirmez une seconde fois la suppression de la source.',
      );
    }

    if (expectedEventId != null || expectedMapId != null) {
      late final NarrativeEventSpatialLinkInspection inspection;
      try {
        inspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceInspectionException',
          message: 'La source à nettoyer ne peut pas être inspectée: $error',
        );
      }
      final mismatch = _journalBindingMismatch(
        inspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
        expectedOperationId: operationId,
      );
      if (mismatch != null) return mismatch;
    }

    late final NarrativeEventSpatialLinkOperationResult result;
    try {
      result = await _sourceGateway.cleanupSource(
        projectPath: projectPath,
        operationId: operationId,
        confirmed: true,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'cleanupException',
        message: 'Le nettoyage de la source a échoué: $error',
      );
    }
    if (result.status == NarrativeEventSpatialLinkOperationStatus.cleaned) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.cleaned,
        code: result.code,
        message: result.message,
        journal: result.journal,
        inspection: result.inspection,
      );
    }
    return _recovery(
      code: result.code,
      message: result.message,
      journal: result.journal,
      inspection: result.inspection,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> acknowledge({
    required String projectPath,
    required String operationId,
    required String expectedEventId,
    required String expectedMapId,
  }) async {
    late final NarrativeEventSpatialLinkInspection inspection;
    try {
      inspection = await _sourceGateway.inspectProject(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'acknowledgementInspectionException',
        message: 'Le journal finalisé ne peut pas être inspecté: $error',
      );
    }
    if (inspection.status == NarrativeEventSpatialLinkInspectionStatus.clear) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.committed,
        code: 'eventCommitAlreadyAcknowledged',
        message: 'La liaison Event était déjà acquittée.',
      );
    }
    final mismatch = _journalBindingMismatch(
      inspection,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedOperationId: operationId,
    );
    if (mismatch != null) return mismatch;
    final journal = inspection.journal;
    if (journal == null ||
        journal.state != NarrativeEventSpatialLinkJournalState.eventCommitted ||
        inspection.status !=
            NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
      return _recovery(
        code: inspection.issues.firstOrNull?.code ??
            'eventCommitNotReadyForAcknowledgement',
        message: inspection.issues.firstOrNull?.message ??
            'La liaison durable n’est pas prête à être acquittée.',
        journal: journal,
        inspection: inspection,
      );
    }

    late final NarrativeEventSpatialLinkOperationResult acknowledged;
    try {
      acknowledged = await _sourceGateway.acknowledgeEventCommitted(
        projectPath: projectPath,
        operationId: operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'acknowledgementException',
        message: 'La liaison est durable, mais son acquittement a échoué: '
            '$error',
        journal: journal,
        inspection: inspection,
      );
    }
    if (acknowledged.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: acknowledged.code,
        message: acknowledged.message,
        journal: acknowledged.journal ?? journal,
        inspection: acknowledged.inspection ?? inspection,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: acknowledged.code,
      message: acknowledged.message,
      journal: acknowledged.journal ?? journal,
      inspection: acknowledged.inspection ?? inspection,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _commitEventFromJournal({
    required String projectPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) async {
    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'freshSessionRejected',
        message: 'La source est enregistrée, mais la session Event a échoué: '
            '$error',
        journal: journal,
      );
    }
    final record = _uniqueEventRecord(
      session.context.registryOrNull,
      journal.eventId,
    );
    if (record == null) {
      return _recovery(
        code: 'eventMissing',
        message: 'La source est enregistrée, mais l’Event est introuvable.',
        journal: journal,
      );
    }
    final currentSource =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    if (currentSource == journal.source) {
      return _finalizeAlreadyLinked(
        projectPath: projectPath,
        journal: journal,
        registry: session.context.registryOrNull,
      );
    }
    if (narrativeEventRecordCanonicalFingerprint(record) !=
            journal.eventRecordFingerprintBefore ||
        record.draftOrNull == null ||
        record.draftOrNull!.source != null) {
      return _recovery(
        code: 'eventModified',
        message: 'L’Event a changé après la création de la source. '
            'Aucune liaison automatique n’a été écrite.',
        journal: journal,
      );
    }

    final authoring = selectNarrativeEventSource(
      context: session.context,
      expectedRevision: session.projectRevision,
      eventId: journal.eventId,
      source: journal.source,
    );
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return _recovery(
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'La source est enregistrée, mais la liaison Event a été refusée.',
        journal: journal,
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry,
      );
    }
    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: '${journal.operationId}_event',
      result: authoring,
    );
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _registryGateway.persist(request);
    } on Object catch (error) {
      return _recovery(
        code: 'registryPersistenceException',
        message: 'La source est enregistrée, mais le registre Event n’a pas '
            'pu être écrit: $error',
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
      );
    }
    if (!persistence.succeeded) {
      return _recovery(
        code: persistence.code,
        message: persistence.message,
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }

    late final NarrativeEventSpatialLinkOperationResult finalized;
    try {
      finalized = await _sourceGateway.markEventCommitted(
        projectPath: projectPath,
        operationId: journal.operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'journalFinalizeException',
        message: 'L’Event est lié, mais le journal doit être récupéré: $error',
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }
    if (finalized.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: finalized.code,
        message: finalized.message,
        journal: finalized.journal ?? journal,
        inspection: finalized.inspection,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: finalized.code,
      message: finalized.message,
      journal: finalized.journal ?? journal,
      previousRegistry: request.previousRegistry,
      nextRegistry: request.nextRegistry,
      persistenceResult: persistence,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _finalizeAlreadyLinked({
    required String projectPath,
    required NarrativeEventSpatialLinkJournal journal,
    required NarrativeEventRegistry? registry,
  }) async {
    late final NarrativeEventSpatialLinkOperationResult finalized;
    try {
      finalized = await _sourceGateway.markEventCommitted(
        projectPath: projectPath,
        operationId: journal.operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'journalFinalizeException',
        message: 'L’Event est lié, mais le journal doit être récupéré: $error',
        journal: journal,
        previousRegistry: registry,
        nextRegistry: registry,
      );
    }
    if (finalized.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: finalized.code,
        message: finalized.message,
        journal: finalized.journal ?? journal,
        inspection: finalized.inspection,
        previousRegistry: registry,
        nextRegistry: registry,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: 'alreadyLinkedFinalized',
      message: 'La liaison déjà écrite a été finalisée.',
      journal: finalized.journal ?? journal,
      previousRegistry: registry,
      nextRegistry: registry,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _afterMapCommitException({
    required String projectPath,
    required Object error,
  }) async {
    try {
      final inspection = await _sourceGateway.inspectProject(projectPath);
      final durable = inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.clear &&
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent;
      if (durable) {
        return _recovery(
          code: 'mapCommitInterrupted',
          message: 'La création a été interrompue après une écriture possible '
              'de la source: $error',
          journal: inspection.journal,
          inspection: inspection,
        );
      }
    } on Object {
      // The original failure remains the useful pre-commit diagnostic.
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.rejected,
      code: 'mapCommitException',
      message: 'La source n’a pas pu être enregistrée: $error',
    );
  }

  NarrativeEventExplicitSourceCreationResult _recovery({
    required String code,
    required String message,
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
    NarrativeEventRegistry? previousRegistry,
    NarrativeEventRegistry? nextRegistry,
    NarrativeEventRegistryPersistenceResult? persistenceResult,
  }) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: code,
      message: message,
      journal: journal ?? inspection?.journal,
      inspection: inspection,
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
      persistenceResult: persistenceResult,
    );
  }
}

NarrativeEventExplicitSourceCreationResult? _dirtyGate({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (mapDirty) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de créer cette source.',
    );
  }
  if (projectDirty) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de créer cette source.',
    );
  }
  return null;
}

NarrativeEventExplicitSourceCreationResult? _journalBindingMismatch(
  NarrativeEventSpatialLinkInspection inspection, {
  required String? expectedEventId,
  required String? expectedMapId,
  String? expectedOperationId,
}) {
  final journal = inspection.journal;
  if (journal == null ||
      (expectedEventId == null &&
          expectedMapId == null &&
          expectedOperationId == null) ||
      (expectedEventId == null || journal.eventId == expectedEventId) &&
          (expectedMapId == null || journal.mapId == expectedMapId) &&
          (expectedOperationId == null ||
              journal.operationId == expectedOperationId)) {
    return null;
  }
  return NarrativeEventExplicitSourceCreationResult(
    status: NarrativeEventExplicitSourceCreationStatus.rejected,
    code: 'pendingJournalMismatch',
    message: 'La récupération durable appartient à un autre Event ou à une '
        'autre map. Ouvrez l’Event exact pour continuer.',
    inspection: inspection,
  );
}

NarrativeEventRecord? _uniqueEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String? _proposalIssue(NarrativeEventCreatedSourceProposal proposal) {
  if (proposal.beforeMap.id != proposal.afterMap.id) {
    return 'Les snapshots avant/après ne ciblent pas la même map.';
  }
  final sourceMapId = narrativeEventSpatialSourceMapId(proposal.source);
  if (sourceMapId == null || sourceMapId != proposal.beforeMap.id) {
    return 'La source créée ne cible pas la map des snapshots.';
  }
  final fingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(proposal.ownerJson),
  );
  if (fingerprint != proposal.ownerFingerprint) {
    return 'L’empreinte du propriétaire créé est invalide.';
  }

  return proposal.source.when(
    entityInteract: (_, entityId) {
      if (proposal.physicalKind == NarrativeEventPhysicalSourceKind.zone1x1) {
        return 'Une zone doit être matérialisée par un trigger.';
      }
      final beforeOwners = proposal.beforeMap.entities
          .where((candidate) => candidate.id == entityId)
          .toList();
      final afterOwners = proposal.afterMap.entities
          .where((candidate) => candidate.id == entityId)
          .toList();
      if (beforeOwners.isNotEmpty || afterOwners.length != 1) {
        return 'Le propriétaire entity doit être absent avant et unique après.';
      }
      final owner = afterOwners.single;
      final expectedKind = switch (proposal.physicalKind) {
        NarrativeEventPhysicalSourceKind.npc => MapEntityKind.npc,
        NarrativeEventPhysicalSourceKind.sign => MapEntityKind.sign,
        NarrativeEventPhysicalSourceKind.item => MapEntityKind.item,
        NarrativeEventPhysicalSourceKind.invisible => MapEntityKind.custom,
        NarrativeEventPhysicalSourceKind.zone1x1 => null,
      };
      if (owner.kind != expectedKind ||
          (proposal.physicalKind ==
                  NarrativeEventPhysicalSourceKind.invisible &&
              owner.blocksMovement)) {
        return 'Le type physique ne correspond pas au propriétaire entity.';
      }
      final exactBounds = MapRect(pos: owner.pos, size: owner.size);
      if (proposal.bounds != exactBounds) {
        return 'Les bounds ne correspondent pas au propriétaire entity.';
      }
      final expectedEnvelope = <String, Object?>{
        'schemaVersion': 1,
        'ownerKind': 'mapEntity',
        'mapId': proposal.afterMap.id,
        'sourceId': entityId,
        'owner': _jsonSafeObject(owner.toJson()),
      };
      if (!_sameCanonicalJson(proposal.ownerJson, expectedEnvelope)) {
        return 'L’enveloppe ne correspond pas au propriétaire entity exact.';
      }
      final withoutOwner = proposal.afterMap.copyWith(
        entities: proposal.afterMap.entities
            .where((candidate) => candidate.id != entityId)
            .toList(),
      );
      if (!_sameCanonicalJson(
        proposal.beforeMap.toJson(),
        withoutOwner.toJson(),
      )) {
        return 'La proposition modifie autre chose que le propriétaire entity.';
      }
      return null;
    },
    triggerEnter: (_, triggerId) {
      if (proposal.physicalKind != NarrativeEventPhysicalSourceKind.zone1x1) {
        return 'Seule une zone peut être matérialisée par un trigger.';
      }
      final beforeOwners = proposal.beforeMap.triggers
          .where((candidate) => candidate.id == triggerId)
          .toList();
      final afterOwners = proposal.afterMap.triggers
          .where((candidate) => candidate.id == triggerId)
          .toList();
      if (beforeOwners.isNotEmpty || afterOwners.length != 1) {
        return 'Le propriétaire trigger doit être absent avant et unique après.';
      }
      final owner = afterOwners.single;
      if (owner.type != TriggerType.event ||
          owner.area.size != const GridSize(width: 1, height: 1) ||
          proposal.bounds != owner.area) {
        return 'La zone créée doit être un trigger Event 1×1 exact.';
      }
      final expectedEnvelope = <String, Object?>{
        'schemaVersion': 1,
        'ownerKind': 'mapTrigger',
        'mapId': proposal.afterMap.id,
        'sourceId': triggerId,
        'owner': _jsonSafeObject(owner.toJson()),
      };
      if (!_sameCanonicalJson(proposal.ownerJson, expectedEnvelope)) {
        return 'L’enveloppe ne correspond pas au propriétaire trigger exact.';
      }
      final withoutOwner = proposal.afterMap.copyWith(
        triggers: proposal.afterMap.triggers
            .where((candidate) => candidate.id != triggerId)
            .toList(),
      );
      if (!_sameCanonicalJson(
        proposal.beforeMap.toJson(),
        withoutOwner.toJson(),
      )) {
        return 'La proposition modifie autre chose que le propriétaire trigger.';
      }
      return null;
    },
    mapEnter: (_) => 'Une création explicite ne peut pas créer une map.',
    outcomeReceived: (_) =>
        'Une création explicite ne peut pas créer un résultat narratif.',
  );
}

bool _sameCanonicalJson(Object? left, Object? right) {
  return narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(_jsonSafeValue(left)),
      ) ==
      narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(_jsonSafeValue(right)),
      );
}

Map<String, Object?> _jsonSafeObject(Map<String, dynamic> value) {
  return Map<String, Object?>.from(
    (_jsonSafeValue(value) as Map).cast<String, Object?>(),
  );
}

Object? _jsonSafeValue(Object? value) => jsonDecode(jsonEncode(value));

String _defaultOperationId() {
  return 'v2_25_${DateTime.now().microsecondsSinceEpoch}';
}
```

### 22.9 `packages/map_editor/lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

typedef PrepareNarrativeEventSpatialSourceSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);

enum NarrativeEventSpatialSourceLinkStatus {
  blocked,
  noOp,
  committed,
  committedOutOfSync,
  rejected,
  preflightRejected,
}

final class NarrativeEventSpatialSourceLinkResult {
  const NarrativeEventSpatialSourceLinkResult({
    required this.status,
    required this.code,
    required this.message,
    this.previousRegistry,
    this.nextRegistry,
    this.authoringResult,
    this.persistenceResult,
  });

  final NarrativeEventSpatialSourceLinkStatus status;
  final String code;
  final String message;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

final class NarrativeEventSpatialSourceLinkUseCase {
  NarrativeEventSpatialSourceLinkUseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventSpatialSourceSession? prepareSession,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventSpatialSourceSession _prepareSession;
  final String Function() _operationIdFactory;

  Future<NarrativeEventSpatialSourceLinkResult> call({
    required String projectPath,
    required String eventId,
    required NarrativeEventSourceRef source,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;
    if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
      return const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'nonSpatialSource',
        message: 'Choisissez une entité, une zone ou la map elle-même.',
      );
    }

    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.preflightRejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
      );
    }

    final record = _findEventRecord(
      session.context.registryOrNull,
      eventId,
    );
    final currentSource =
        record?.draftOrNull?.source ?? record?.definitionOrNull?.source;
    final authoring = currentSource == null
        ? selectNarrativeEventSource(
            context: session.context,
            expectedRevision: session.projectRevision,
            eventId: eventId,
            source: source,
          )
        : replaceNarrativeEventSource(
            context: session.context,
            expectedRevision: session.projectRevision,
            eventId: eventId,
            source: source,
          );

    if (authoring.status == NarrativeEventAuthoringStatus.noOp) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.noOp,
        code: 'noOp',
        message: 'Cette source est déjà liée à l’Event.',
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry ?? session.context.registryOrNull,
        authoringResult: authoring,
      );
    }
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'La source ne peut pas être liée à cet Event.',
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry,
        authoringResult: authoring,
      );
    }

    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: _operationIdFactory(),
      result: authoring,
    );
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _persistenceGateway.persist(request);
    } on Object {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'persistenceException',
        message: 'La liaison n’a pas pu être enregistrée.',
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        authoringResult: authoring,
      );
    }
    if (!persistence.succeeded) {
      return NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: persistence.code,
        message: persistence.message,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        authoringResult: authoring,
        persistenceResult: persistence,
      );
    }
    return NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.committed,
      code: persistence.code,
      message: persistence.message,
      previousRegistry: request.previousRegistry,
      nextRegistry: request.nextRegistry,
      authoringResult: authoring,
      persistenceResult: persistence,
    );
  }
}

NarrativeEventSpatialSourceLinkResult? _dirtyGate({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (mapDirty) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de changer la source.',
    );
  }
  if (projectDirty) {
    return const NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de changer la source.',
    );
  }
  return null;
}

String _defaultOperationId() {
  return 'v2_24_link_${DateTime.now().microsecondsSinceEpoch}';
}

NarrativeEventRecord? _findEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id == eventId) return record;
  }
  return null;
}
```

### 22.10 `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers/core/repository_providers.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../../application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import '../../../application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import '../../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_state.dart';

typedef ApplyPersistedNarrativeEventRegistry = bool Function({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
});
typedef LoadNarrativeEventMapSnapshot = Future<MapData?> Function(String mapId);
typedef ActivateNarrativeEventMapSnapshot = bool Function(MapData map);
typedef ApplyNarrativeEventMapFocus = bool Function(
  NarrativeEditorFocusTarget focus,
);
typedef OpenExactNarrativeEvent = void Function({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
});
typedef AdoptPersistedNarrativeEventSourceProposal = bool Function(
  NarrativeEventCreatedSourceProposal proposal,
);
typedef AdoptPersistedNarrativeEventSourceCleanup = Future<bool> Function({
  required String expectedProjectRootPath,
  required MapData expectedActiveMap,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef BeginNarrativeEventSourceCleanupInterlock = bool Function({
  required String expectedProjectRootPath,
  required MapData expectedActiveMap,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef ReleaseNarrativeEventSourceCleanupInterlock = void Function({
  required String expectedProjectRootPath,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef _SourceCreationInspectionIdentity = ({
  String projectRootPath,
  int projectSessionToken,
  int operationEpoch,
  String requestId,
  String eventId,
  String mapId,
});

enum _SourceCreationBusyKind { inspection, mutation }

@immutable
final class NarrativeEventMapBridgeRecovery {
  const NarrativeEventMapBridgeRecovery({
    required this.projectRootPath,
    required this.result,
  });

  final String projectRootPath;
  final NarrativeEventMapCreationResult result;
}

@immutable
final class NarrativeEventMapBridgeState {
  const NarrativeEventMapBridgeState({
    this.projectRootPath,
    this.projectSessionToken = 0,
    this.pendingIntent,
    this.isSubmitting = false,
    this.isLinkingSource = false,
    this.isSourceCreationBusy = false,
    this.linkedEvents = const [],
    this.linkedEventsIntent,
    this.isAdditionalEventRequest = false,
    this.selectedNarrativeEventV2Id,
    this.selectedGroupContext,
    this.pendingReturn,
    this.focusRequest,
    this.navigationMode,
    this.lastNavigationResult,
    this.lastSourceLinkResult,
    this.sourceCreationKind,
    this.sourceCreationProposal,
    this.lastSourceCreationResult,
    this.cleanupConfirmationRequested = false,
    this.lastResult,
    this.recovery,
  });

  final String? projectRootPath;
  final int projectSessionToken;
  final NarrativeEventMapCreationIntent? pendingIntent;
  final bool isSubmitting;
  final bool isLinkingSource;
  final bool isSourceCreationBusy;
  final List<NarrativeEventMapLinkedEvent> linkedEvents;
  final NarrativeEventMapCreationIntent? linkedEventsIntent;
  final bool isAdditionalEventRequest;

  /// Event V2 selection. It is deliberately unrelated to legacy MapEvent IDs.
  final String? selectedNarrativeEventV2Id;
  final NarrativeEventGroupContext? selectedGroupContext;
  final NarrativeEventMapReturnToken? pendingReturn;
  final NarrativeEventMapFocusRequest? focusRequest;
  final NarrativeEventMapNavigationMode? navigationMode;
  final NarrativeEventMapNavigationResult? lastNavigationResult;
  final NarrativeEventSpatialSourceLinkResult? lastSourceLinkResult;
  final NarrativeEventPhysicalSourceKind? sourceCreationKind;
  final NarrativeEventCreatedSourceProposal? sourceCreationProposal;
  final NarrativeEventExplicitSourceCreationResult? lastSourceCreationResult;
  final bool cleanupConfirmationRequested;
  final NarrativeEventMapCreationResult? lastResult;
  final NarrativeEventMapBridgeRecovery? recovery;

  NarrativeEventMapBridgeState copyWith({
    Object? projectRootPath = _unset,
    int? projectSessionToken,
    Object? pendingIntent = _unset,
    bool? isSubmitting,
    bool? isLinkingSource,
    bool? isSourceCreationBusy,
    List<NarrativeEventMapLinkedEvent>? linkedEvents,
    Object? linkedEventsIntent = _unset,
    bool? isAdditionalEventRequest,
    Object? selectedNarrativeEventV2Id = _unset,
    Object? selectedGroupContext = _unset,
    Object? pendingReturn = _unset,
    Object? focusRequest = _unset,
    Object? navigationMode = _unset,
    Object? lastNavigationResult = _unset,
    Object? lastSourceLinkResult = _unset,
    Object? sourceCreationKind = _unset,
    Object? sourceCreationProposal = _unset,
    Object? lastSourceCreationResult = _unset,
    bool? cleanupConfirmationRequested,
    Object? lastResult = _unset,
    Object? recovery = _unset,
  }) {
    return NarrativeEventMapBridgeState(
      projectRootPath: identical(projectRootPath, _unset)
          ? this.projectRootPath
          : projectRootPath as String?,
      projectSessionToken: projectSessionToken ?? this.projectSessionToken,
      pendingIntent: identical(pendingIntent, _unset)
          ? this.pendingIntent
          : pendingIntent as NarrativeEventMapCreationIntent?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLinkingSource: isLinkingSource ?? this.isLinkingSource,
      isSourceCreationBusy: isSourceCreationBusy ?? this.isSourceCreationBusy,
      linkedEvents: linkedEvents ?? this.linkedEvents,
      linkedEventsIntent: identical(linkedEventsIntent, _unset)
          ? this.linkedEventsIntent
          : linkedEventsIntent as NarrativeEventMapCreationIntent?,
      isAdditionalEventRequest:
          isAdditionalEventRequest ?? this.isAdditionalEventRequest,
      selectedNarrativeEventV2Id: identical(selectedNarrativeEventV2Id, _unset)
          ? this.selectedNarrativeEventV2Id
          : selectedNarrativeEventV2Id as String?,
      selectedGroupContext: identical(selectedGroupContext, _unset)
          ? this.selectedGroupContext
          : selectedGroupContext as NarrativeEventGroupContext?,
      pendingReturn: identical(pendingReturn, _unset)
          ? this.pendingReturn
          : pendingReturn as NarrativeEventMapReturnToken?,
      focusRequest: identical(focusRequest, _unset)
          ? this.focusRequest
          : focusRequest as NarrativeEventMapFocusRequest?,
      navigationMode: identical(navigationMode, _unset)
          ? this.navigationMode
          : navigationMode as NarrativeEventMapNavigationMode?,
      lastNavigationResult: identical(lastNavigationResult, _unset)
          ? this.lastNavigationResult
          : lastNavigationResult as NarrativeEventMapNavigationResult?,
      lastSourceLinkResult: identical(lastSourceLinkResult, _unset)
          ? this.lastSourceLinkResult
          : lastSourceLinkResult as NarrativeEventSpatialSourceLinkResult?,
      sourceCreationKind: identical(sourceCreationKind, _unset)
          ? this.sourceCreationKind
          : sourceCreationKind as NarrativeEventPhysicalSourceKind?,
      sourceCreationProposal: identical(sourceCreationProposal, _unset)
          ? this.sourceCreationProposal
          : sourceCreationProposal as NarrativeEventCreatedSourceProposal?,
      lastSourceCreationResult: identical(lastSourceCreationResult, _unset)
          ? this.lastSourceCreationResult
          : lastSourceCreationResult
              as NarrativeEventExplicitSourceCreationResult?,
      cleanupConfirmationRequested:
          cleanupConfirmationRequested ?? this.cleanupConfirmationRequested,
      lastResult: identical(lastResult, _unset)
          ? this.lastResult
          : lastResult as NarrativeEventMapCreationResult?,
      recovery: identical(recovery, _unset)
          ? this.recovery
          : recovery as NarrativeEventMapBridgeRecovery?,
    );
  }
}

const Object _unset = Object();

final class NarrativeEventMapBridgeController
    extends StateNotifier<NarrativeEventMapBridgeState> {
  NarrativeEventMapBridgeController({
    required CreateNarrativeEventFromMapSourceUseCase useCase,
    String? projectRootPath,
    String Function()? requestIdFactory,
    NarrativeEventSpatialSourceLinkUseCase? sourceLinkUseCase,
    NarrativeEventExplicitSourceCreationUseCase? explicitSourceCreationUseCase,
  })  : _useCase = useCase,
        _sourceLinkUseCase = sourceLinkUseCase,
        _explicitSourceCreationUseCase = explicitSourceCreationUseCase,
        _requestIdFactory = requestIdFactory ?? _defaultMapRequestId,
        super(
          NarrativeEventMapBridgeState(
            projectRootPath: _normalizedProjectRoot(projectRootPath),
          ),
        );

  final CreateNarrativeEventFromMapSourceUseCase _useCase;
  final NarrativeEventSpatialSourceLinkUseCase? _sourceLinkUseCase;
  final NarrativeEventExplicitSourceCreationUseCase?
      _explicitSourceCreationUseCase;
  final String Function() _requestIdFactory;
  int _operationEpoch = 0;
  int _sourceCreationBusyGeneration = 0;
  int? _sourceCreationBusyOwner;
  _SourceCreationBusyKind? _sourceCreationBusyKind;
  Object? _boundProjectIdentity;
  bool _hasProjectBinding = false;
  final _pendingSourceCreationInspections = <_SourceCreationInspectionIdentity,
      Future<NarrativeEventExplicitSourceCreationResult?>>{};

  void bindProjectRootPath(String? projectRootPath) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (normalized == state.projectRootPath) return;
    _boundProjectIdentity = null;
    _hasProjectBinding = true;
    _operationEpoch++;
    state = NarrativeEventMapBridgeState(
      projectRootPath: normalized,
      projectSessionToken: state.projectSessionToken + 1,
    );
  }

  /// Binds async bridge work to one concrete editor project session.
  ///
  /// Object identity is intentional: reloading an equal manifest at the same
  /// root must still invalidate a delayed map snapshot. Expected in-flight
  /// writes keep their token until they can report a durable outcome.
  void bindProjectSession({
    required String? projectRootPath,
    required ProjectManifest? project,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (_hasProjectBinding &&
        normalized == state.projectRootPath &&
        identical(project, _boundProjectIdentity)) {
      return;
    }
    final rootChanged = normalized != state.projectRootPath;
    _hasProjectBinding = true;
    _boundProjectIdentity = project;
    _operationEpoch++;
    final nextSessionToken = state.projectSessionToken + 1;
    if (rootChanged) {
      state = NarrativeEventMapBridgeState(
        projectRootPath: normalized,
        projectSessionToken: nextSessionToken,
      );
      return;
    }
    state = state.copyWith(
      projectRootPath: normalized,
      projectSessionToken: nextSessionToken,
    );
  }

  Future<NarrativeEventMapNavigationResult> openMapForEvent({
    required String eventId,
    required NarrativeEventGroupContext groupContext,
    required NarrativeEventMapNavigationMode mode,
    required ProjectManifest project,
    required MapData? activeMap,
    required bool mapDirty,
    required LoadNarrativeEventMapSnapshot loadMapSnapshot,
    required ActivateNarrativeEventMapSnapshot activateMapSnapshot,
    required ApplyNarrativeEventMapFocus applyFocus,
  }) async {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record == null) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.eventMissing,
        'L’Event sélectionné n’existe plus.',
      );
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    if (source == null ||
        source.kind == NarrativeEventSourceKind.outcomeReceived) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Cet Event n’a pas de source spatiale à afficher sur une map.',
      );
    }
    final sourceMapId = _spatialMapId(source);
    if (groupContext.kind != NarrativeEventGroupContextKind.map ||
        groupContext.mapId != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.sourceMismatch,
        'Le groupe Event et la source ne ciblent pas la même map.',
      );
    }

    final sameMap = activeMap?.id == sourceMapId;
    if (!sameMap && mapDirty) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.blockedDirtyMap,
        'Enregistrez la map active avant d’en ouvrir une autre.',
      );
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final targetMap = sameMap ? activeMap! : await loadMapSnapshot(sourceMapId);
    if (operationEpoch != _operationEpoch ||
        projectSessionToken != state.projectSessionToken) {
      return const NarrativeEventMapNavigationResult(
        status: NarrativeEventMapNavigationStatus.unavailable,
        message: 'Le projet a changé pendant la navigation.',
      );
    }
    if (targetMap == null || targetMap.id != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Les données de la map source sont indisponibles.',
      );
    }

    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [targetMap],
    ).mapNavigationForSource(source);
    final focus = navigation.focusTarget;
    if (!navigation.available || focus == null || focus.mapId != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        navigation.absenceReason ?? 'La source ne peut pas être localisée.',
        navigation: navigation,
      );
    }
    if (!sameMap && !activateMapSnapshot(targetMap)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.activationFailed,
        'La map source n’a pas pu être activée.',
      );
    }
    if (!applyFocus(focus)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.focusFailed,
        'La source a changé avant de pouvoir être sélectionnée.',
      );
    }

    final requestId = _requestIdFactory();
    final returnToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: eventId,
      groupContext: groupContext,
      expectedSource: source,
    );
    final result = NarrativeEventMapNavigationResult(
      status: NarrativeEventMapNavigationStatus.ready,
      message: mode == NarrativeEventMapNavigationMode.view
          ? 'Source affichée sur la map.'
          : 'Choisissez une source existante sur cette map.',
      navigation: navigation,
    );
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: groupContext,
      pendingReturn: returnToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: returnToken,
        source: source,
        mode: mode,
      ),
      navigationMode: mode,
      lastNavigationResult: result,
      lastSourceLinkResult: null,
    );
    return result;
  }

  Future<NarrativeEventMapNavigationResult> openMapForMissingSource({
    required String eventId,
    required NarrativeEventGroupContext groupContext,
    required ProjectManifest project,
    required MapData? activeMap,
    required bool mapDirty,
    required LoadNarrativeEventMapSnapshot loadMapSnapshot,
    required ActivateNarrativeEventMapSnapshot activateMapSnapshot,
  }) async {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record?.draftOrNull == null || record!.draftOrNull!.source != null) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Seul un draft Event sans source peut créer un élément sur la map.',
      );
    }
    final mapId = groupContext.mapId;
    if (groupContext.kind != NarrativeEventGroupContextKind.map ||
        mapId == null ||
        !_projectContainsMap(project, mapId)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.sourceMismatch,
        'Le groupe Event doit cibler une map réelle du projet.',
      );
    }
    final sameMap = activeMap?.id == mapId;
    if (!sameMap && mapDirty) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.blockedDirtyMap,
        'Enregistrez la map active avant d’en ouvrir une autre.',
      );
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final targetMap = sameMap ? activeMap! : await loadMapSnapshot(mapId);
    if (!_isCurrentNavigationOperation(
      operationEpoch: operationEpoch,
      projectSessionToken: projectSessionToken,
    )) {
      return const NarrativeEventMapNavigationResult(
        status: NarrativeEventMapNavigationStatus.unavailable,
        message: 'Le projet a changé pendant la navigation.',
      );
    }
    if (targetMap == null || targetMap.id != mapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Les données de la map du groupe sont indisponibles.',
      );
    }
    if (!sameMap && !activateMapSnapshot(targetMap)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.activationFailed,
        'La map du groupe n’a pas pu être activée.',
      );
    }

    final requestId = _requestIdFactory();
    final token = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: eventId,
      groupContext: groupContext,
      expectedSource: null,
    );
    const result = NarrativeEventMapNavigationResult(
      status: NarrativeEventMapNavigationStatus.ready,
      message: 'Choisissez le type puis placez la source sur cette map.',
    );
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: groupContext,
      pendingReturn: token,
      focusRequest: null,
      navigationMode: NarrativeEventMapNavigationMode.create,
      sourceCreationKind: null,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
      lastNavigationResult: result,
      lastSourceLinkResult: null,
    );
    return result;
  }

  bool selectPhysicalSourceKind(NarrativeEventPhysicalSourceKind kind) {
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        state.pendingReturn == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationKind: kind,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool previewSourceCreationProposal(
    NarrativeEventCreatedSourceProposal proposal,
  ) {
    final token = state.pendingReturn;
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create ||
        state.sourceCreationKind != proposal.physicalKind ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != proposal.beforeMap.id ||
        proposal.beforeMap.id != proposal.afterMap.id ||
        narrativeEventSpatialSourceMapId(proposal.source) !=
            proposal.beforeMap.id) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: proposal,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool cancelSourceCreationProposal() {
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        state.sourceCreationProposal == null) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> confirmSourceCreation({
    required String? projectRootPath,
    required ProjectManifest project,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final token = state.pendingReturn;
    final proposal = state.sourceCreationProposal;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (state.isSourceCreationBusy) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.blocked,
        code: 'sourceCreationInProgress',
        message: 'Une création de source est déjà en cours.',
      );
    }
    if (useCase == null ||
        token == null ||
        proposal == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(
      isSourceCreationBusy: true,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    late final NarrativeEventExplicitSourceCreationResult rawResult;
    try {
      rawResult = await useCase.createAndLink(
        projectPath: p.join(normalizedRoot, 'project.json'),
        eventId: token.eventId,
        proposal: proposal,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
      );
    } on Object catch (error) {
      rawResult = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'unexpectedSourceCreationFailure',
        message: 'La création de source a échoué: $error',
      );
    }
    final result = _bindSourceCreationResultToToken(rawResult, token);
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.committed
              ? _sourceCreationOutOfSync(result, 'projectChangedAfterCommit')
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
        );
      }
      return stale;
    }
    if (result.journal != null && state.sourceCreationProposal != null) {
      state = state.copyWith(sourceCreationProposal: null);
    }
    return _finishCommittedSourceCreation(
      result: result,
      proposal: proposal,
      durableMap: proposal.afterMap,
      source: proposal.source,
      token: token,
      project: project,
      adoptPersistedMap: adoptPersistedMap,
      applyPersistedRegistry: applyPersistedRegistry,
      busyOwner: busyOwner,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      inspectPendingSourceCreation({
    required String? projectRootPath,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) {
    final identity = _sourceCreationInspectionIdentity(projectRootPath);
    if (identity == null) {
      return Future<NarrativeEventExplicitSourceCreationResult?>.value();
    }
    final pending = _pendingSourceCreationInspections[identity];
    if (pending != null) return pending;
    late final Future<NarrativeEventExplicitSourceCreationResult?> tracked;
    tracked = _inspectPendingSourceCreation(
      identity: identity,
      token: state.pendingReturn!,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    ).whenComplete(() {
      if (identical(_pendingSourceCreationInspections[identity], tracked)) {
        _pendingSourceCreationInspections.remove(identity);
      }
    });
    _pendingSourceCreationInspections[identity] = tracked;
    return tracked;
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      _inspectPendingSourceCreation({
    required _SourceCreationInspectionIdentity identity,
    required NarrativeEventMapReturnToken token,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    if (useCase == null ||
        state.navigationMode == null ||
        (state.isSourceCreationBusy &&
            _sourceCreationBusyKind != _SourceCreationBusyKind.inspection)) {
      return null;
    }
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.inspection,
    );
    state = state.copyWith(isSourceCreationBusy: true);
    final previousRecovery = state.lastSourceCreationResult;
    final inspected = await useCase.inspect(
      projectPath: p.join(identity.projectRootPath, 'project.json'),
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _bindSourceCreationResultToToken(inspected, token);
    if (!_sourceCreationInspectionIsCurrent(identity)) {
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
      );
      return result;
    }
    final stateResult = _preserveTransientSourceRecovery(
      previousRecovery,
      result,
    );
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      sourceCreationProposal:
          stateResult.journal == null ? state.sourceCreationProposal : null,
      lastSourceCreationResult:
          stateResult.status == NarrativeEventExplicitSourceCreationStatus.clear
              ? null
              : stateResult,
    );
    return result;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> retrySourceCreation({
    required String? projectRootPath,
    required ProjectManifest project,
    required MapData activeMap,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final token = state.pendingReturn;
    final proposal = state.sourceCreationProposal;
    final journal = state.lastSourceCreationResult?.journal;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        token == null ||
        (proposal == null && journal == null) ||
        state.isSourceCreationBusy ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    if (journal != null && !_journalMatchesToken(journal, token)) {
      final mismatch = _pendingJournalMismatch(
        state.lastSourceCreationResult!,
      );
      state = state.copyWith(
        lastSourceCreationResult: mismatch,
        cleanupConfirmationRequested: false,
      );
      return mismatch;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final previousRecovery = state.lastSourceCreationResult;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(
      isSourceCreationBusy: true,
      sourceCreationProposal: journal == null ? proposal : null,
      cleanupConfirmationRequested: false,
    );
    final retried = await useCase.retry(
      projectPath: p.join(normalizedRoot, 'project.json'),
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _preserveTransientSourceRecovery(
      previousRecovery,
      _bindSourceCreationResultToToken(retried, token),
    );
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.committed
              ? _sourceCreationOutOfSync(result, 'projectChangedAfterRetry')
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
        );
      }
      return stale;
    }
    if (result.status != NarrativeEventExplicitSourceCreationStatus.committed) {
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        sourceCreationProposal:
            result.journal == null ? state.sourceCreationProposal : null,
        lastSourceCreationResult:
            result.status == NarrativeEventExplicitSourceCreationStatus.clear
                ? null
                : result,
      );
      return result;
    }
    final durableJournal = result.journal;
    final proposalForAdoption = durableJournal == null ? proposal : null;
    if (durableJournal != null && state.sourceCreationProposal != null) {
      state = state.copyWith(sourceCreationProposal: null);
    }
    return _finishCommittedSourceCreation(
      result: result,
      proposal: proposalForAdoption,
      durableMap: proposalForAdoption?.afterMap ?? activeMap,
      source: durableJournal?.source ?? proposal!.source,
      token: token,
      project: project,
      adoptPersistedMap: adoptPersistedMap,
      applyPersistedRegistry: applyPersistedRegistry,
      busyOwner: busyOwner,
    );
  }

  bool requestSourceCleanupConfirmation() {
    final result = state.lastSourceCreationResult;
    final token = state.pendingReturn;
    if (state.isSourceCreationBusy ||
        token == null ||
        result?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        result?.journal == null ||
        !_journalMatchesToken(result!.journal!, token)) {
      return false;
    }
    state = state.copyWith(cleanupConfirmationRequested: true);
    return true;
  }

  bool cancelSourceCleanupConfirmation() {
    if (state.isSourceCreationBusy || !state.cleanupConfirmationRequested) {
      return false;
    }
    state = state.copyWith(cleanupConfirmationRequested: false);
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> cleanupCreatedSource({
    required String? projectRootPath,
    required MapData activeMap,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required BeginNarrativeEventSourceCleanupInterlock beginCleanupInterlock,
    required ReleaseNarrativeEventSourceCleanupInterlock
        releaseCleanupInterlock,
    required AdoptPersistedNarrativeEventSourceCleanup adoptPersistedCleanup,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final pending = state.lastSourceCreationResult;
    final journal = pending?.journal;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        journal == null ||
        token == null ||
        !_journalMatchesToken(journal, token) ||
        activeMap.id != journal.mapId ||
        !state.cleanupConfirmationRequested ||
        state.isSourceCreationBusy ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    var cleanupInterlockArmed = false;
    try {
      cleanupInterlockArmed = beginCleanupInterlock(
        expectedProjectRootPath: normalizedRoot,
        expectedActiveMap: activeMap,
        journal: journal,
      );
    } on Object {
      cleanupInterlockArmed = false;
    }
    if (!cleanupInterlockArmed) {
      final blocked = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        code: 'cleanupInterlockUnavailable',
        message: 'La suppression n’a pas démarré car la map active ne peut '
            'pas être protégée contre une sauvegarde concurrente.',
        journal: journal,
        inspection: pending?.inspection,
        previousRegistry: pending?.previousRegistry,
        nextRegistry: pending?.nextRegistry,
        persistenceResult: pending?.persistenceResult,
      );
      state = state.copyWith(
        lastSourceCreationResult: blocked,
        cleanupConfirmationRequested: false,
      );
      return blocked;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(isSourceCreationBusy: true);
    final rawResult = await useCase.cleanup(
      projectPath: p.join(normalizedRoot, 'project.json'),
      operationId: journal.operationId,
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      confirmed: true,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _preserveTransientSourceRecovery(
      pending,
      _bindSourceCreationResultToToken(rawResult, token),
      preserveAnyRecoveryWithoutIdentity: true,
    );
    if (!_mustRetainCleanupInterlock(result)) {
      try {
        releaseCleanupInterlock(
          expectedProjectRootPath: normalizedRoot,
          journal: journal,
        );
      } on Object {
        // Keeping a stale-map barrier is safer than risking resurrection.
      }
    }
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.cleaned
              ? _sourceCleanupOutOfSync(result)
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
          cleanupConfirmationRequested: false,
        );
      }
      return stale;
    }
    var stateResult = result;
    if (result.status == NarrativeEventExplicitSourceCreationStatus.cleaned) {
      final cleanedJournal = result.journal;
      var adopted = false;
      if (cleanedJournal != null) {
        try {
          adopted = await adoptPersistedCleanup(
            expectedProjectRootPath: normalizedRoot,
            expectedActiveMap: activeMap,
            journal: cleanedJournal,
          );
        } on Object {
          adopted = false;
        }
      }
      if (!adopted ||
          !_isCurrentOperation(
            projectRootPath: normalizedRoot,
            projectSessionToken: projectSessionToken,
            operationEpoch: operationEpoch,
          )) {
        stateResult = _sourceCleanupOutOfSync(result);
      }
    }
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      sourceCreationProposal: stateResult.journal != null ||
              stateResult.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned
          ? null
          : state.sourceCreationProposal,
      lastSourceCreationResult: stateResult,
      cleanupConfirmationRequested: false,
    );
    return stateResult;
  }

  static bool _mustRetainCleanupInterlock(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    if (result.status == NarrativeEventExplicitSourceCreationStatus.cleaned ||
        result.code == 'cleanupException') {
      return true;
    }
    final journal = result.journal ?? result.inspection?.journal;
    return journal?.cleanupMarker ==
        NarrativeEventSpatialLinkCleanupMarker.requested;
  }

  bool completeSourceCleanupReload({
    required String? projectRootPath,
    required MapData activeMap,
  }) {
    final recovery = state.lastSourceCreationResult;
    final journal = recovery?.journal;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (state.isSourceCreationBusy ||
        recovery?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        recovery?.code != 'cleanedMapOutOfSync' ||
        journal == null ||
        token == null ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        !_journalMatchesToken(journal, token) ||
        activeMap.id != journal.mapId ||
        _mapOwnsSource(activeMap, journal.source)) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: null,
      lastSourceCreationResult: NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.cleaned,
        code: 'cleanupReloaded',
        message: 'La map nettoyée a été rechargée dans l’éditeur.',
        journal: journal,
        inspection: recovery!.inspection,
      ),
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool returnToEvent({
    required ProjectManifest project,
    required OpenExactNarrativeEvent openExactEvent,
  }) {
    if (state.isLinkingSource ||
        state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery) {
      return false;
    }
    final token = state.pendingReturn;
    if (token == null) return false;
    final record = _uniqueEventRecord(project.eventRegistry, token.eventId);
    if (record == null) {
      _operationEpoch++;
      state = state.copyWith(
        selectedNarrativeEventV2Id: null,
        selectedGroupContext: null,
        lastNavigationResult: const NarrativeEventMapNavigationResult(
          status: NarrativeEventMapNavigationStatus.eventMissing,
          message: 'L’Event a été supprimé pendant l’aller-retour carte.',
        ),
      );
      return false;
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final sourceMatchesReturnGroup = source == null
        ? token.expectedSource == null &&
            state.navigationMode == NarrativeEventMapNavigationMode.create &&
            token.groupContext.kind == NarrativeEventGroupContextKind.map &&
            token.groupContext.mapId != null &&
            _projectContainsMap(project, token.groupContext.mapId!)
        : _sourceMatchesGroup(source, token.groupContext);
    if (source != token.expectedSource || !sourceMatchesReturnGroup) {
      _operationEpoch++;
      state = state.copyWith(
        lastNavigationResult: const NarrativeEventMapNavigationResult(
          status: NarrativeEventMapNavigationStatus.sourceMismatch,
          message: 'La source de l’Event a changé pendant la navigation.',
        ),
      );
      return false;
    }
    openExactEvent(
      eventId: token.eventId,
      groupContext: token.groupContext,
    );
    _operationEpoch++;
    state = state.copyWith(
      selectedNarrativeEventV2Id: token.eventId,
      selectedGroupContext: token.groupContext,
      pendingReturn: null,
      focusRequest: null,
      navigationMode: null,
      lastNavigationResult: null,
    );
    return true;
  }

  Future<NarrativeEventSpatialSourceLinkResult?> linkChosenSource({
    required String? projectRootPath,
    required ProjectManifest project,
    required MapData activeMap,
    required NarrativeEventSourceRef source,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    if (state.isLinkingSource) {
      return const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.blocked,
        code: 'linkInProgress',
        message: 'Une liaison de source est déjà en cours.',
      );
    }
    final inspectionIdentity =
        _sourceCreationInspectionIdentity(projectRootPath);
    final pendingInspection = inspectionIdentity == null
        ? null
        : _pendingSourceCreationInspections[inspectionIdentity];
    if (pendingInspection != null) {
      state = state.copyWith(isLinkingSource: true);
      await pendingInspection;
      state = state.copyWith(isLinkingSource: false);
      if (_hasBlockingSourceCreationRecovery) {
        return const NarrativeEventSpatialSourceLinkResult(
          status: NarrativeEventSpatialSourceLinkStatus.blocked,
          code: 'sourceCreationRecoveryRequired',
          message: 'La récupération de la source durable doit être terminée '
              'avant de changer la liaison.',
        );
      }
    }
    final useCase = _sourceLinkUseCase;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.choose ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        source.kind == NarrativeEventSourceKind.outcomeReceived ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != activeMap.id ||
        _spatialMapId(source) != activeMap.id) {
      return null;
    }
    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [activeMap],
    ).mapNavigationForSource(source);
    if (!navigation.available ||
        navigation.focusTarget == null ||
        navigation.focusTarget?.mapId != activeMap.id) {
      final rejected = NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'candidateUnavailable',
        message: navigation.absenceReason ??
            'Cette source n’est plus disponible sur la map.',
      );
      state = state.copyWith(lastSourceLinkResult: rejected);
      return rejected;
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    state = state.copyWith(
      isLinkingSource: true,
      lastSourceLinkResult: null,
    );
    late final NarrativeEventSpatialSourceLinkResult result;
    try {
      result = await useCase(
        projectPath: p.join(normalizedRoot, 'project.json'),
        eventId: token.eventId,
        source: source,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
      );
    } on Object {
      result = const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'unexpectedLinkFailure',
        message: 'La liaison de source a échoué de façon inattendue.',
      );
    }
    if (operationEpoch != _operationEpoch ||
        projectSessionToken != state.projectSessionToken) {
      final staleResult =
          result.status == NarrativeEventSpatialSourceLinkStatus.committed
              ? _committedSourceLinkOutOfSync(result)
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isLinkingSource: false,
          lastSourceLinkResult: staleResult,
        );
      }
      return staleResult;
    }
    if (result.status == NarrativeEventSpatialSourceLinkStatus.committed) {
      var applied = false;
      try {
        applied = applyPersistedRegistry(
          expectedProjectRootPath: normalizedRoot,
          expectedPreviousRegistry: result.previousRegistry,
          nextRegistry: result.nextRegistry!,
        );
      } on Object {
        applied = false;
      }
      if (!applied) {
        final outOfSync = _committedSourceLinkOutOfSync(result);
        state = state.copyWith(
          isLinkingSource: false,
          lastSourceLinkResult: outOfSync,
        );
        return outOfSync;
      }
    }
    if (result.status == NarrativeEventSpatialSourceLinkStatus.committed ||
        result.status == NarrativeEventSpatialSourceLinkStatus.noOp) {
      final requestId = _requestIdFactory();
      final nextToken = NarrativeEventMapReturnToken(
        requestId: requestId,
        eventId: token.eventId,
        groupContext: token.groupContext,
        expectedSource: source,
      );
      state = state.copyWith(
        isLinkingSource: false,
        pendingReturn: nextToken,
        focusRequest: NarrativeEventMapFocusRequest(
          requestId: requestId,
          navigation: navigation,
          returnToken: nextToken,
          source: source,
          mode: NarrativeEventMapNavigationMode.choose,
        ),
        lastSourceLinkResult: result,
      );
      return result;
    }
    state = state.copyWith(
      isLinkingSource: false,
      lastSourceLinkResult: result,
    );
    return result;
  }

  bool previewChosenSource({
    required ProjectManifest project,
    required MapData map,
    required NarrativeEventSourceRef source,
  }) {
    final token = state.pendingReturn;
    if (state.isLinkingSource ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.choose ||
        source.kind == NarrativeEventSourceKind.outcomeReceived ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != map.id ||
        _spatialMapId(source) != map.id) {
      return false;
    }
    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [map],
    ).mapNavigationForSource(source);
    if (!navigation.available || navigation.focusTarget == null) return false;
    final requestId = _requestIdFactory();
    final nextToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: token.eventId,
      groupContext: token.groupContext,
      expectedSource: token.expectedSource,
    );
    _operationEpoch++;
    state = state.copyWith(
      pendingReturn: nextToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: nextToken,
        source: source,
        mode: NarrativeEventMapNavigationMode.choose,
      ),
      lastNavigationResult: null,
      lastSourceLinkResult: null,
    );
    return true;
  }

  void cancelMapNavigation() {
    if (state.isLinkingSource ||
        state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery) {
      return;
    }
    if (state.pendingReturn == null && state.focusRequest == null) return;
    _operationEpoch++;
    state = state.copyWith(
      pendingReturn: null,
      focusRequest: null,
      navigationMode: null,
      lastNavigationResult: null,
      lastSourceLinkResult: null,
      sourceCreationKind: null,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
  }

  bool markFocusCameraApplied(String requestId) {
    final focusRequest = state.focusRequest;
    if (focusRequest == null ||
        focusRequest.requestId != requestId ||
        focusRequest.cameraApplied) {
      return false;
    }
    state = state.copyWith(focusRequest: focusRequest.markCameraApplied());
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult>
      _finishCommittedSourceCreation({
    required NarrativeEventExplicitSourceCreationResult result,
    required NarrativeEventCreatedSourceProposal? proposal,
    required MapData durableMap,
    required NarrativeEventSourceRef source,
    required NarrativeEventMapReturnToken token,
    required ProjectManifest project,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
    required int busyOwner,
  }) async {
    if (result.status != NarrativeEventExplicitSourceCreationStatus.committed) {
      final stateResult = _preserveTransientSourceRecovery(
        state.lastSourceCreationResult,
        result,
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        sourceCreationProposal:
            stateResult.journal == null ? state.sourceCreationProposal : null,
        lastSourceCreationResult: stateResult,
      );
      return stateResult;
    }
    final nextRegistry = result.nextRegistry;
    if (nextRegistry == null) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedRegistryMissing',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    var mapApplied = proposal == null && _mapOwnsSource(durableMap, source);
    if (proposal != null) {
      try {
        mapApplied = adoptPersistedMap(proposal);
      } on Object {
        mapApplied = false;
      }
    }
    if (!mapApplied) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedMapOutOfSync',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    var registryApplied = false;
    try {
      registryApplied = applyPersistedRegistry(
        expectedProjectRootPath: state.projectRootPath!,
        expectedPreviousRegistry: result.previousRegistry,
        nextRegistry: nextRegistry,
      );
    } on Object {
      registryApplied = false;
    }
    if (!registryApplied) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedRegistryOutOfSync',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final navigation = buildNarrativeEventNavigationIndex(
      project: project.copyWith(eventRegistry: nextRegistry),
      maps: [durableMap],
    ).mapNavigationForSource(source);
    if (!navigation.available || navigation.focusTarget == null) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedSourceUnavailable',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final journal = result.journal;
    if (journal == null || !_journalMatchesToken(journal, token)) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedJournalMissing',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }
    final acknowledgementIdentity =
        _sourceCreationInspectionIdentity(state.projectRootPath);
    final acknowledgementBelongsToToken = acknowledgementIdentity != null &&
        acknowledgementIdentity.requestId == token.requestId &&
        acknowledgementIdentity.eventId == token.eventId &&
        acknowledgementIdentity.mapId == token.groupContext.mapId;
    final acknowledged = await _explicitSourceCreationUseCase!.acknowledge(
      projectPath: journal.projectPath,
      operationId: journal.operationId,
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId!,
    );
    if (!acknowledgementBelongsToToken ||
        !_sourceCreationInspectionIsCurrent(acknowledgementIdentity)) {
      final stale = _sourceCreationOutOfSync(
        result,
        'projectChangedAfterAcknowledgement',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
      );
      return stale;
    }
    if (acknowledged.status !=
        NarrativeEventExplicitSourceCreationStatus.committed) {
      final outOfSync = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        code: acknowledged.code,
        message: acknowledged.message,
        journal: acknowledged.journal ?? journal,
        inspection: acknowledged.inspection,
        previousRegistry: result.previousRegistry,
        nextRegistry: result.nextRegistry,
        persistenceResult: result.persistenceResult,
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final requestId = _requestIdFactory();
    final nextToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: token.eventId,
      groupContext: token.groupContext,
      expectedSource: source,
    );
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      pendingReturn: nextToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: nextToken,
        source: source,
        mode: state.navigationMode ?? NarrativeEventMapNavigationMode.create,
      ),
      sourceCreationProposal: null,
      lastSourceCreationResult: result,
      cleanupConfirmationRequested: false,
    );
    return result;
  }

  NarrativeEventExplicitSourceCreationResult _sourceCreationOutOfSync(
    NarrativeEventExplicitSourceCreationResult committed,
    String code,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: code,
      message: 'La source est durable, mais l’éditeur doit être resynchronisé '
          'avant de continuer.',
      journal: committed.journal,
      inspection: committed.inspection,
      previousRegistry: committed.previousRegistry,
      nextRegistry: committed.nextRegistry,
      persistenceResult: committed.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _sourceCleanupOutOfSync(
    NarrativeEventExplicitSourceCreationResult cleaned,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: 'cleanedMapOutOfSync',
      message: 'La source est supprimée sur disque, mais la map active doit '
          'être rechargée avant de continuer.',
      journal: cleaned.journal,
      inspection: cleaned.inspection,
      previousRegistry: cleaned.previousRegistry,
      nextRegistry: cleaned.nextRegistry,
      persistenceResult: cleaned.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _preserveTransientSourceRecovery(
    NarrativeEventExplicitSourceCreationResult? previous,
    NarrativeEventExplicitSourceCreationResult incoming, {
    bool preserveAnyRecoveryWithoutIdentity = false,
  }) {
    final resultWithoutIdentity = incoming.journal == null &&
        incoming.inspection?.journal == null &&
        (const {
              'inspectionException',
              'sourceInspectionException',
              'registryInspectionException',
              'registryRecoveryException',
              'cleanupException',
              'mapDirty',
              'projectDirty',
              'saveInProgress',
            }.contains(incoming.code) ||
            preserveAnyRecoveryWithoutIdentity &&
                incoming.status ==
                    NarrativeEventExplicitSourceCreationStatus
                        .recoveryRequired);
    if (!resultWithoutIdentity ||
        previous?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        previous?.journal == null) {
      return incoming;
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: incoming.code,
      message: incoming.message,
      journal: previous!.journal,
      inspection: previous.inspection,
      previousRegistry: incoming.previousRegistry ?? previous.previousRegistry,
      nextRegistry: incoming.nextRegistry ?? previous.nextRegistry,
      persistenceResult:
          incoming.persistenceResult ?? previous.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _bindSourceCreationResultToToken(
    NarrativeEventExplicitSourceCreationResult result,
    NarrativeEventMapReturnToken token,
  ) {
    final normalized = _normalizeSourceCreationResultJournal(result);
    final journal = normalized.journal;
    if (journal == null || _journalMatchesToken(journal, token)) {
      return normalized;
    }
    return _pendingJournalMismatch(normalized);
  }

  NarrativeEventExplicitSourceCreationResult
      _normalizeSourceCreationResultJournal(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    final journal = result.journal ?? result.inspection?.journal;
    if (journal == null || identical(journal, result.journal)) return result;
    return NarrativeEventExplicitSourceCreationResult(
      status: result.status,
      code: result.code,
      message: result.message,
      journal: journal,
      inspection: result.inspection,
      previousRegistry: result.previousRegistry,
      nextRegistry: result.nextRegistry,
      persistenceResult: result.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _pendingJournalMismatch(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.rejected,
      code: 'pendingJournalMismatch',
      message: 'La récupération durable appartient à un autre Event ou à une '
          'autre map. Ouvrez l’Event exact pour continuer.',
      inspection: result.inspection,
    );
  }

  int _claimSourceCreationBusy(_SourceCreationBusyKind kind) {
    final owner = ++_sourceCreationBusyGeneration;
    _sourceCreationBusyOwner = owner;
    _sourceCreationBusyKind = kind;
    return owner;
  }

  bool _busyAfterRelease(int owner) {
    if (_sourceCreationBusyOwner != owner) {
      return state.isSourceCreationBusy;
    }
    _sourceCreationBusyOwner = null;
    _sourceCreationBusyKind = null;
    return false;
  }

  bool _journalMatchesToken(
    NarrativeEventSpatialLinkJournal journal,
    NarrativeEventMapReturnToken token,
  ) {
    return token.eventId == journal.eventId &&
        token.groupContext.kind == NarrativeEventGroupContextKind.map &&
        token.groupContext.mapId == journal.mapId;
  }

  _SourceCreationInspectionIdentity? _sourceCreationInspectionIdentity(
    String? projectRootPath,
  ) {
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    final token = state.pendingReturn;
    final mapId = token?.groupContext.mapId;
    if (normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        token == null ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        mapId == null ||
        state.navigationMode == null) {
      return null;
    }
    return (
      projectRootPath: normalizedRoot,
      projectSessionToken: state.projectSessionToken,
      operationEpoch: _operationEpoch,
      requestId: token.requestId,
      eventId: token.eventId,
      mapId: mapId,
    );
  }

  bool _sourceCreationInspectionIsCurrent(
    _SourceCreationInspectionIdentity identity,
  ) {
    final token = state.pendingReturn;
    return identity.projectRootPath == state.projectRootPath &&
        identity.projectSessionToken == state.projectSessionToken &&
        identity.operationEpoch == _operationEpoch &&
        token?.requestId == identity.requestId &&
        token?.eventId == identity.eventId &&
        token?.groupContext.kind == NarrativeEventGroupContextKind.map &&
        token?.groupContext.mapId == identity.mapId;
  }

  bool get _hasBlockingSourceCreationRecovery =>
      state.lastSourceCreationResult?.status ==
      NarrativeEventExplicitSourceCreationStatus.recoveryRequired;

  bool _isCurrentNavigationOperation({
    required int operationEpoch,
    required int projectSessionToken,
  }) {
    return operationEpoch == _operationEpoch &&
        projectSessionToken == state.projectSessionToken;
  }

  NarrativeEventMapNavigationResult _navigationFailure(
    NarrativeEventMapNavigationStatus status,
    String message, {
    NarrativeEventNavigationIntent? navigation,
  }) {
    final result = NarrativeEventMapNavigationResult(
      status: status,
      message: message,
      navigation: navigation,
    );
    state = state.copyWith(lastNavigationResult: result);
    return result;
  }

  NarrativeEventSpatialSourceLinkResult _committedSourceLinkOutOfSync(
    NarrativeEventSpatialSourceLinkResult committed,
  ) {
    return NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
      code: 'committedOutOfSync',
      message: 'La source est enregistrée sur disque, mais le projet doit être '
          'rechargé avant de continuer.',
      previousRegistry: committed.previousRegistry,
      nextRegistry: committed.nextRegistry,
      authoringResult: committed.authoringResult,
      persistenceResult: committed.persistenceResult,
    );
  }

  bool request(
    NarrativeEventMapCreationIntent intent, {
    required String? projectRootPath,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: intent,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
      recovery: null,
    );
    return true;
  }

  void cancel() {
    if (state.isSubmitting) return;
    _operationEpoch++;
    if (state.isAdditionalEventRequest) {
      state = state.copyWith(
        pendingIntent: null,
        isAdditionalEventRequest: false,
      );
      return;
    }
    state = state.copyWith(
      pendingIntent: null,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
    );
  }

  void requestAdditionalEvent() {
    final intent = state.linkedEventsIntent;
    if (state.isSubmitting || state.linkedEvents.isEmpty || intent == null) {
      return;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: intent,
      isAdditionalEventRequest: true,
      lastResult: null,
    );
  }

  Future<NarrativeEventMapCreationResult?> confirm({
    required String? projectRootPath,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final normalizedProjectRoot = _normalizedProjectRoot(projectRootPath);
    final intent = state.pendingIntent;
    if (intent == null ||
        state.isSubmitting ||
        normalizedProjectRoot == null ||
        normalizedProjectRoot != state.projectRootPath) {
      return null;
    }
    final allowAdditionalEvent = state.isAdditionalEventRequest;
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await _useCase(
        projectPath: p.join(normalizedProjectRoot, 'project.json'),
        intent: intent,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
        allowAdditionalEvent: allowAdditionalEvent,
      );

      if (!_isCurrentOperation(
        projectRootPath: normalizedProjectRoot,
        projectSessionToken: projectSessionToken,
        operationEpoch: operationEpoch,
      )) {
        if (state.projectRootPath == normalizedProjectRoot) {
          if (result.status == NarrativeEventMapCreationStatus.committed) {
            final outOfSync =
                NarrativeEventMapCreationResult.committedOutOfSync(result);
            state = state.copyWith(
              pendingIntent: null,
              isSubmitting: false,
              linkedEvents: const [],
              linkedEventsIntent: null,
              isAdditionalEventRequest: false,
              selectedNarrativeEventV2Id: null,
              lastResult: outOfSync,
              recovery: NarrativeEventMapBridgeRecovery(
                projectRootPath: normalizedProjectRoot,
                result: outOfSync,
              ),
            );
            return outOfSync;
          }
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: const [],
            linkedEventsIntent: null,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: null,
            lastResult: result,
          );
        }
        return result;
      }

      switch (result.status) {
        case NarrativeEventMapCreationStatus.existingLinks:
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: result.linkedEvents,
            linkedEventsIntent: intent,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: result.linkedEvents.length == 1
                ? result.linkedEvents.single.eventId
                : null,
            lastResult: result,
          );
          return result;
        case NarrativeEventMapCreationStatus.committed:
          final registry = result.nextRegistry!;
          var applied = false;
          try {
            applied = applyPersistedRegistry(
              expectedProjectRootPath: normalizedProjectRoot,
              expectedPreviousRegistry: result.previousRegistry,
              nextRegistry: registry,
            );
          } on Object {
            applied = false;
          }
          if (!applied) {
            final outOfSync =
                NarrativeEventMapCreationResult.committedOutOfSync(result);
            state = state.copyWith(
              pendingIntent: null,
              isSubmitting: false,
              linkedEvents: const [],
              linkedEventsIntent: null,
              isAdditionalEventRequest: false,
              selectedNarrativeEventV2Id: null,
              lastResult: outOfSync,
              recovery: NarrativeEventMapBridgeRecovery(
                projectRootPath: normalizedProjectRoot,
                result: outOfSync,
              ),
            );
            return outOfSync;
          }
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: const [],
            linkedEventsIntent: null,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: result.eventId,
            lastResult: result,
            recovery: null,
          );
          return result;
        case NarrativeEventMapCreationStatus.committedOutOfSync:
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            selectedNarrativeEventV2Id: null,
            lastResult: result,
            recovery: NarrativeEventMapBridgeRecovery(
              projectRootPath: normalizedProjectRoot,
              result: result,
            ),
          );
          return result;
        case NarrativeEventMapCreationStatus.blocked:
        case NarrativeEventMapCreationStatus.authoringRejected:
        case NarrativeEventMapCreationStatus.persistenceRejected:
        case NarrativeEventMapCreationStatus.preflightRejected:
          state = state.copyWith(
            isSubmitting: false,
            lastResult: result,
          );
          return result;
      }
    } on Object {
      final failure = NarrativeEventMapCreationResult.unexpectedBridgeFailure();
      if (_isCurrentOperation(
        projectRootPath: normalizedProjectRoot,
        projectSessionToken: projectSessionToken,
        operationEpoch: operationEpoch,
      )) {
        state = state.copyWith(lastResult: failure);
      }
      return failure;
    } finally {
      if (_isCurrentOperation(
            projectRootPath: normalizedProjectRoot,
            projectSessionToken: projectSessionToken,
            operationEpoch: operationEpoch,
          ) &&
          state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  bool _isCurrentOperation({
    required String projectRootPath,
    required int projectSessionToken,
    required int operationEpoch,
  }) {
    return state.projectRootPath == projectRootPath &&
        state.projectSessionToken == projectSessionToken &&
        _operationEpoch == operationEpoch;
  }

  void selectLinkedEvent(String eventId) {
    if (!state.linkedEvents.any((event) => event.eventId == eventId)) return;
    state = state.copyWith(selectedNarrativeEventV2Id: eventId);
  }

  bool selectNarrativeEventV2(
    ProjectManifest project,
    String eventId, {
    NarrativeEventGroupContext? groupContext,
  }) {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record == null) return false;
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final resolvedGroup = switch (source?.kind) {
      null => groupContext,
      NarrativeEventSourceKind.outcomeReceived =>
        const NarrativeEventGroupContext.global(),
      _ => NarrativeEventGroupContext.map(_spatialMapId(source!)),
    };
    if (groupContext != null && resolvedGroup != groupContext) return false;
    if (resolvedGroup?.kind == NarrativeEventGroupContextKind.map &&
        !_projectContainsMap(project, resolvedGroup!.mapId!)) {
      return false;
    }
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: resolvedGroup,
      lastNavigationResult: null,
      lastSourceLinkResult: null,
    );
    return true;
  }

  void clearLinkedEvents() {
    if (state.isSubmitting) return;
    _operationEpoch++;
    state = state.copyWith(
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
    );
  }

  void dismissRecovery({required String? projectRootPath}) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath ||
        state.recovery?.projectRootPath != normalized) {
      return;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: null,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      selectedNarrativeEventV2Id: null,
      lastResult: null,
      recovery: null,
    );
  }

  bool finishRecoveryReload({
    required String? projectRootPath,
    required NarrativeEventRegistry? loadedRegistry,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    final recovery = state.recovery;
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath ||
        recovery?.projectRootPath != normalized ||
        recovery?.result.nextRegistry != loadedRegistry) {
      return false;
    }
    _operationEpoch++;
    state = NarrativeEventMapBridgeState(
      projectRootPath: normalized,
      projectSessionToken: state.projectSessionToken,
    );
    return true;
  }
}

bool _projectContainsMap(ProjectManifest project, String mapId) {
  return project.maps.any((entry) => entry.id == mapId);
}

final createNarrativeEventFromMapSourceUseCaseProvider =
    Provider<CreateNarrativeEventFromMapSourceUseCase>((ref) {
  return CreateNarrativeEventFromMapSourceUseCase(
    persistenceGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventSpatialSourceLinkUseCaseProvider =
    Provider<NarrativeEventSpatialSourceLinkUseCase>((ref) {
  return NarrativeEventSpatialSourceLinkUseCase(
    persistenceGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventExplicitSourceCreationUseCaseProvider =
    Provider<NarrativeEventExplicitSourceCreationUseCase>((ref) {
  return NarrativeEventExplicitSourceCreationUseCase(
    sourceGateway:
        ref.watch(narrativeEventSpatialSourceCreationGatewayProvider),
    registryGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventMapBridgeControllerProvider = StateNotifierProvider<
    NarrativeEventMapBridgeController, NarrativeEventMapBridgeState>((ref) {
  final controller = NarrativeEventMapBridgeController(
    useCase: ref.watch(createNarrativeEventFromMapSourceUseCaseProvider),
    sourceLinkUseCase:
        ref.watch(narrativeEventSpatialSourceLinkUseCaseProvider),
    explicitSourceCreationUseCase:
        ref.watch(narrativeEventExplicitSourceCreationUseCaseProvider),
  );
  ref.listen<EditorState>(
    editorNotifierProvider,
    (previous, next) {
      if (previous == null ||
          previous.projectRootPath != next.projectRootPath ||
          !identical(previous.project, next.project)) {
        controller.bindProjectSession(
          projectRootPath: next.projectRootPath,
          project: next.project,
        );
      }
    },
    fireImmediately: true,
  );
  return controller;
});

String? _normalizedProjectRoot(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return p.normalize(trimmed);
}

NarrativeEventRecord? _uniqueEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _spatialMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => throw StateError(
      'A non-spatial source does not own a map.',
    ),
  );
}

bool _sourceMatchesGroup(
  NarrativeEventSourceRef? source,
  NarrativeEventGroupContext group,
) {
  if (source == null) return false;
  if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
    return group.kind == NarrativeEventGroupContextKind.global;
  }
  return group.kind == NarrativeEventGroupContextKind.map &&
      group.mapId == _spatialMapId(source);
}

bool _mapOwnsSource(MapData map, NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapId == map.id &&
        map.entities.where((entity) => entity.id == entityId).length == 1,
    triggerEnter: (mapId, triggerId) =>
        mapId == map.id &&
        map.triggers.where((trigger) => trigger.id == triggerId).length == 1,
    mapEnter: (_) => false,
    outcomeReceived: (_) => false,
  );
}

String _defaultMapRequestId() {
  return 'v2_24_${DateTime.now().microsecondsSinceEpoch}';
}
```

### 22.11 `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

final class NarrativeEventSpatialLinkJournalRepository
    implements NarrativeEventSpatialSourceCreationGateway {
  NarrativeEventSpatialLinkJournalRepository({
    DateTime Function()? clock,
    this.faultInjector,
    NarrativeEventRegistryPersistence? eventRegistryPersistence,
  })  : _clock = clock ?? DateTime.now,
        _eventRegistryPersistence =
            eventRegistryPersistence ?? NarrativeEventRegistryPersistence();

  static const journalPrefix = '.pokemap-event-spatial-link-';
  static const journalSuffix = '.journal.json';
  static const mapTempSuffix = '.map.tmp';

  final DateTime Function() _clock;
  final NarrativeEventSpatialLinkFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence _eventRegistryPersistence;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    final project = await _qualifyProject(request.projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    return withProjectManifestWriteLock(project.path!, () async {
      final registryGate = await _eventRegistryPersistence
          .inspectProjectAlreadyLocked(project.path!);
      if (registryGate.status !=
          NarrativeEventRegistryRecoveryGateStatus.clear) {
        return _registryRecoveryBlocked(registryGate);
      }
      final existing = await _inspectLocked(project.path!);
      if (existing.status != NarrativeEventSpatialLinkInspectionStatus.clear) {
        return _blocked(
          'pendingSpatialLinkJournal',
          'Une autre liaison spatiale doit être récupérée avant de continuer.',
          inspection: existing,
        );
      }
      return _commitMapLocked(project.path!, request);
    });
  }

  Future<NarrativeEventSpatialLinkOperationResult> _commitMapLocked(
    String projectPath,
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    final projectFile = File(projectPath);
    final projectBytes = await projectFile.readAsBytes();
    final projectRevision = narrativeEventBytesFingerprint(projectBytes);
    if (projectRevision != request.projectRevision) {
      return _conflict(
        'staleProjectRevision',
        'Le projet a changé avant la préparation de la source.',
      );
    }
    late final ValidatedNarrativeEventAuthoringProject project;
    try {
      project = decodeValidatedNarrativeEventAuthoringProject(projectBytes);
    } on Object catch (error) {
      return _blocked(
        'invalidProject',
        'Le manifest du projet est invalide: $error',
      );
    }
    final eventRecord = _eventRecord(
      project.manifest.eventRegistry,
      request.eventId,
    );
    if (eventRecord == null) {
      return _blocked(
        'eventMissing',
        'L’Event ${request.eventId} est absent du registry.',
      );
    }
    if (narrativeEventRecordCanonicalFingerprint(eventRecord) !=
        request.eventRecordFingerprintBefore) {
      return _conflict(
        'eventRecordFingerprintMismatch',
        'L’Event cible a changé depuis la préparation de la création.',
      );
    }
    final mapResolution = await _resolveManifestMap(
      projectPath: projectPath,
      project: project.manifest,
      mapId: request.beforeMap.id,
    );
    if (mapResolution.issue case final issue?) return _blockedIssue(issue);
    final mapPath = mapResolution.path!;
    final beforeBytes = await File(mapPath).readAsBytes();
    final beforeHash = narrativeEventBytesFingerprint(beforeBytes);
    late final MapData diskBefore;
    try {
      diskBefore = decodeValidatedNarrativeEventAuthoringMap(
        beforeBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked('invalidMap', 'La map courante est invalide: $error');
    }
    if (!_sameJson(diskBefore.toJson(), request.beforeMap.toJson())) {
      return _conflict(
        'staleBeforeMap',
        'La map disque ne correspond pas à la proposition préparée.',
      );
    }
    final proposalIssue = _validateExactSourceAddition(request);
    if (proposalIssue != null) return _blockedIssue(proposalIssue);
    late final List<int> afterBytes;
    late final MapData verifiedAfter;
    try {
      afterBytes = _canonicalJsonUtf8(request.afterMap.toJson());
      verifiedAfter = decodeValidatedNarrativeEventAuthoringMap(
        afterBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked(
          'invalidAfterMap', 'La map proposée est invalide: $error');
    }
    final diskOwnerIssue = _exactOwnerIssue(
      map: verifiedAfter,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (diskOwnerIssue != null) return _blockedIssue(diskOwnerIssue);

    final paths = _pathsFor(
      projectPath: projectPath,
      mapPath: mapPath,
      operationId: request.operationId,
    );
    final pathIssue = await _writableArtifactPathIssue(paths);
    if (pathIssue != null) return _blockedIssue(pathIssue);
    final preparedAt = _clock().toUtc();
    var journal = NarrativeEventSpatialLinkJournal(
      schemaVersion: 1,
      operationId: request.operationId,
      projectPath: projectPath,
      projectRevision: projectRevision,
      journalPath: paths.journalPath,
      mapPath: mapPath,
      mapTempPath: paths.mapTempPath,
      mapId: request.beforeMap.id,
      eventId: request.eventId,
      eventRecordFingerprintBefore: request.eventRecordFingerprintBefore,
      source: request.source,
      sourceOwnerJson: request.sourceOwnerJson,
      sourceOwnerFingerprint: request.sourceOwnerFingerprint,
      beforeMapHash: beforeHash,
      afterMapHash: narrativeEventBytesFingerprint(afterBytes),
      state: NarrativeEventSpatialLinkJournalState.prepared,
      preparedAt: preparedAt,
      cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
    );
    await _writeJournal(journal);
    await _checkpoint(
      NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared,
    );
    await _writeBytesFlushed(paths.mapTempPath, afterBytes);
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapTempFlush);
    final tempHash = narrativeEventBytesFingerprint(
      await File(paths.mapTempPath).readAsBytes(),
    );
    if (tempHash != journal.afterMapHash) {
      return _blocked(
        'mapTempHashMismatch',
        'Le fichier temporaire de map ne correspond pas au hash attendu.',
        journal: journal,
      );
    }
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.beforeMapRename);
    final renamePathIssue = await _symbolicLinkIssue([
      projectPath,
      mapPath,
      paths.mapTempPath,
    ]);
    if (renamePathIssue != null) {
      await _deleteIfRegular(paths.mapTempPath);
      return _blockedIssue(renamePathIssue, journal: journal);
    }
    final liveProjectRevision = narrativeEventBytesFingerprint(
      await projectFile.readAsBytes(),
    );
    if (liveProjectRevision != projectRevision) {
      await _deleteIfRegular(paths.mapTempPath);
      return _conflict(
        'staleProjectRevisionBeforeMapRename',
        'Le projet a changé pendant la préparation de la map.',
        journal: journal,
      );
    }
    final liveMapHash = narrativeEventBytesFingerprint(
      await File(mapPath).readAsBytes(),
    );
    if (liveMapHash != beforeHash) {
      await _deleteIfRegular(paths.mapTempPath);
      return _conflict(
        'staleMapRevisionBeforeRename',
        'La map a changé pendant la préparation.',
        journal: journal,
      );
    }
    await File(paths.mapTempPath).rename(mapPath);
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapRename);
    final committedBytes = await File(mapPath).readAsBytes();
    final committedHash = narrativeEventBytesFingerprint(committedBytes);
    if (committedHash != journal.afterMapHash) {
      return _blocked(
        'committedMapHashMismatch',
        'La map écrite ne correspond pas au hash attendu.',
        journal: journal,
      );
    }
    late final MapData committedMap;
    try {
      committedMap = decodeValidatedNarrativeEventAuthoringMap(
        committedBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked(
        'committedMapInvalid',
        'La map écrite ne peut pas être relue: $error',
        journal: journal,
      );
    }
    final committedOwnerIssue = _exactOwnerIssue(
      map: committedMap,
      source: journal.source,
      expectedOwnerJson: journal.sourceOwnerJson,
      expectedFingerprint: journal.sourceOwnerFingerprint,
    );
    if (committedOwnerIssue != null) {
      return _blockedIssue(committedOwnerIssue, journal: journal);
    }
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapVerified);
    journal = journal.markMapCommitted(_clock().toUtc());
    await _writeJournal(journal);
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      code: 'mapCommitted',
      message: 'La source physique a été enregistrée sur la map.',
      journal: journal,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.blocked,
        issues: [issue],
      );
    }
    return withProjectManifestWriteLock(
      project.path!,
      () => _inspectLocked(project.path!),
    );
  }

  Future<NarrativeEventSpatialLinkInspection> _inspectLocked(
    String projectPath,
  ) async {
    final artifacts = await _journalArtifacts(projectPath);
    if (artifacts.rewriteTemps.isNotEmpty) {
      return _inspectionBlocked(
        'orphanJournalTemp',
        'Un temporaire de journal orphelin exige une inspection manuelle.',
        artifacts.rewriteTemps.first,
      );
    }
    if (artifacts.journals.length > 1) {
      return _inspectionBlocked(
        'multipleJournals',
        'Plusieurs journaux de liaison spatiale sont présents.',
        artifacts.journals.first,
      );
    }
    if (artifacts.journals.isEmpty) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    }
    final journalPath = artifacts.journals.single;
    if (await FileSystemEntity.type(journalPath, followLinks: false) ==
        FileSystemEntityType.link) {
      return _inspectionBlocked(
        'symbolicLinkRefused',
        'Le journal ne peut pas être un lien symbolique.',
        journalPath,
      );
    }
    late final NarrativeEventSpatialLinkJournal journal;
    try {
      final decoded = decodeNarrativeEventJsonStrict(
        await File(journalPath).readAsString(),
      );
      journal = NarrativeEventSpatialLinkJournal.fromJson(
        _jsonObject(decoded),
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'invalidJournal',
        'Le journal est invalide: $error',
        journalPath,
      );
    }
    final pathIssue = await _journalPathIssue(
      projectPath: projectPath,
      actualJournalPath: journalPath,
      journal: journal,
    );
    if (pathIssue != null) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.blocked,
        journal: journal,
        issues: [pathIssue],
      );
    }
    late final List<int> mapBytes;
    late final MapData map;
    try {
      mapBytes = await File(journal.mapPath).readAsBytes();
      map = decodeValidatedNarrativeEventAuthoringMap(
        mapBytes,
        journal.mapPath,
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'inspectionReadFailure',
        'Le projet ou la map ne peut pas être relu: $error',
        journalPath,
        journal: journal,
      );
    }
    final owner = _ownerState(
      map: map,
      source: journal.source,
      expectedOwnerJson: journal.sourceOwnerJson,
      expectedFingerprint: journal.sourceOwnerFingerprint,
    );
    if (journal.state == NarrativeEventSpatialLinkJournalState.prepared) {
      final mapHash = narrativeEventBytesFingerprint(mapBytes);
      if (owner.kind == _OwnerStateKind.absent &&
          mapHash == journal.beforeMapHash) {
        return NarrativeEventSpatialLinkInspection(
          status:
              NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
          journal: journal,
        );
      }
      if (owner.kind == _OwnerStateKind.exact &&
          mapHash == journal.afterMapHash) {
        return NarrativeEventSpatialLinkInspection(
          status:
              NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
          journal: journal,
        );
      }
      if (owner.kind == _OwnerStateKind.modified) {
        return _inspectionBlocked(
          'sourceFingerprintMismatch',
          'La source physique a été modifiée depuis sa création.',
          journal.mapPath,
          journal: journal,
        );
      }
      return _inspectionBlocked(
        'unknownPreparedMapRevision',
        'La map ne correspond ni à l’état avant ni à l’état committé.',
        journal.mapPath,
        journal: journal,
      );
    }
    final registryGate = await _eventRegistryPersistence
        .inspectProjectAlreadyLocked(projectPath);
    if (registryGate.status != NarrativeEventRegistryRecoveryGateStatus.clear) {
      final issue = registryGate.issues.firstOrNull;
      return _inspectionBlocked(
        registryGate.status ==
                NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
            ? 'eventRegistryRecoveryRequired'
            : 'eventRegistryRecoveryBlocked',
        issue?.message ??
            'Le registry Event doit être récupéré avant cette liaison.',
        issue?.path ?? projectPath,
        journal: journal,
      );
    }
    late final ValidatedNarrativeEventAuthoringProject project;
    try {
      project = decodeValidatedNarrativeEventAuthoringProject(
        await File(projectPath).readAsBytes(),
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'inspectionReadFailure',
        'Le projet ne peut pas être relu: $error',
        journalPath,
        journal: journal,
      );
    }
    if (owner.kind == _OwnerStateKind.modified) {
      return _inspectionBlocked(
        'sourceFingerprintMismatch',
        'La source physique a été modifiée depuis sa création.',
        journal.mapPath,
        journal: journal,
      );
    }
    final targetEventRecord =
        _eventRecord(project.manifest.eventRegistry, journal.eventId);
    if (targetEventRecord == null) {
      return _inspectionBlocked(
        'eventRecordMissing',
        'L’Event cible a été supprimé depuis le commit map.',
        projectPath,
        journal: journal,
      );
    }
    final eventSource = _recordSource(targetEventRecord);
    final exactEventLinked = eventSource == journal.source;
    final eventSourceMismatch = eventSource != null && !exactEventLinked;
    if (eventSourceMismatch) {
      return _inspectionBlocked(
        'eventSourceMismatch',
        'L’Event est désormais lié à une autre source.',
        projectPath,
        journal: journal,
      );
    }
    if (!exactEventLinked &&
        narrativeEventRecordCanonicalFingerprint(targetEventRecord) !=
            journal.eventRecordFingerprintBefore) {
      return _inspectionBlocked(
        'eventRecordChanged',
        'L’Event cible a été modifié depuis le commit map.',
        projectPath,
        journal: journal,
      );
    }
    if (journal.cleanupMarker ==
        NarrativeEventSpatialLinkCleanupMarker.requested) {
      return NarrativeEventSpatialLinkInspection(
        status: owner.kind == _OwnerStateKind.absent
            ? NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted
            : NarrativeEventSpatialLinkInspectionStatus.cleanupPending,
        journal: journal,
      );
    }
    switch (journal.state) {
      case NarrativeEventSpatialLinkJournalState.prepared:
        return _inspectionBlocked(
          'invalidPreparedInspectionState',
          'Le journal préparé n’a pas été classifié avant validation Event.',
          journalPath,
          journal: journal,
        );
      case NarrativeEventSpatialLinkJournalState.mapCommitted:
        if (owner.kind == _OwnerStateKind.absent) {
          return _inspectionBlocked(
            'sourceUnexpectedlyAbsent',
            'La source committée est absente sans marqueur de nettoyage.',
            journal.mapPath,
            journal: journal,
          );
        }
        return NarrativeEventSpatialLinkInspection(
          status: exactEventLinked
              ? NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked
              : NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
          journal: journal,
        );
      case NarrativeEventSpatialLinkJournalState.eventCommitted:
        if (owner.kind != _OwnerStateKind.exact || !exactEventLinked) {
          return _inspectionBlocked(
            'eventCommittedInvariantMismatch',
            'Le journal finalisé ne correspond plus au projet.',
            journalPath,
            journal: journal,
          );
        }
        return NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
          journal: journal,
        );
    }
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(expectedOperationId);
    if (safeOperationId == null ||
        expectedEventId.trim().isEmpty ||
        expectedMapId.trim().isEmpty ||
        narrativeEventSpatialSourceMapId(expectedSource) != expectedMapId) {
      return _blocked(
        'invalidRecoveryIdentity',
        'L’identité attendue pour la récupération est invalide.',
      );
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      final journal = inspection.journal;
      if (journal == null ||
          journal.operationId != safeOperationId ||
          journal.eventId != expectedEventId ||
          journal.mapId != expectedMapId ||
          journal.source != expectedSource) {
        return _conflict(
          'recoveryJournalMismatch',
          'Le journal durable a changé depuis son inspection. Aucune '
              'récupération n’a été appliquée.',
          journal: journal,
          inspection: inspection,
        );
      }
      switch (inspection.status) {
        case NarrativeEventSpatialLinkInspectionStatus.clear:
          return NarrativeEventSpatialLinkOperationResult(
            status: NarrativeEventSpatialLinkOperationStatus.noOp,
            code: 'noJournal',
            message: 'Aucun journal spatial à récupérer.',
            inspection: inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent:
          await _deleteCompletedArtifacts(journal);
          return _recovered(
            'preparedNoOpRemoved',
            'Le journal préparé sans écriture map a été retiré.',
            journal,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent:
          final promoted = journal.markMapCommitted(_clock().toUtc());
          await _writeJournal(promoted);
          final postPromotion = await _inspectLocked(project.path!);
          if (postPromotion.status ==
              NarrativeEventSpatialLinkInspectionStatus.blocked) {
            return _blocked(
              postPromotion.issues.firstOrNull?.code ??
                  'postPromotionValidationBlocked',
              postPromotion.issues.firstOrNull?.message ??
                  'La validation Event après promotion a échoué.',
              journal: promoted,
              inspection: postPromotion,
            );
          }
          return _recovered(
            'preparedPromotedToMapCommitted',
            'Le commit map interrompu a été reconnu.',
            promoted,
            postPromotion,
          );
        case NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked:
          final completed = journal.state ==
                  NarrativeEventSpatialLinkJournalState.eventCommitted
              ? journal
              : journal.markEventCommitted(_clock().toUtc());
          await _writeJournal(completed);
          return _recovered(
            'eventCommitRecovered',
            'La liaison Event déjà durable attend son acquittement éditeur.',
            completed,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted:
          await _deleteCompletedArtifacts(journal);
          return _recovered(
            'cleanupRecovered',
            'Le nettoyage déjà durable a été finalisé.',
            journal,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit:
        case NarrativeEventSpatialLinkInspectionStatus.cleanupPending:
        case NarrativeEventSpatialLinkInspectionStatus.blocked:
          return _blocked(
            inspection.issues.firstOrNull?.code ?? 'manualActionRequired',
            inspection.issues.firstOrNull?.message ??
                'Une action explicite est requise pour cette liaison.',
            journal: journal,
            inspection: inspection,
          );
      }
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      final journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      if (inspection.status !=
          NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
        return _blocked(
          inspection.status ==
                  NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit
              ? 'eventNotLinked'
              : inspection.issues.firstOrNull?.code ?? 'eventCommitBlocked',
          inspection.issues.firstOrNull?.message ??
              'L’Event n’est pas lié à la source exacte.',
          journal: journal,
          inspection: inspection,
        );
      }
      final completed =
          journal.state == NarrativeEventSpatialLinkJournalState.eventCommitted
              ? journal
              : journal.markEventCommitted(_clock().toUtc());
      await _writeJournal(completed);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
        code: 'eventCommitted',
        message: 'La liaison Event a été finalisée.',
        journal: completed,
        inspection: inspection,
      );
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return const NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitAlreadyAcknowledged',
          message: 'La liaison Event était déjà acquittée.',
        );
      }
      final journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      if (journal.state !=
              NarrativeEventSpatialLinkJournalState.eventCommitted ||
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
        return _blocked(
          inspection.issues.firstOrNull?.code ?? 'acknowledgementBlocked',
          inspection.issues.firstOrNull?.message ??
              'La liaison exacte doit être durable avant son acquittement.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _deleteCompletedArtifacts(journal);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
        code: 'eventCommitAcknowledged',
        message: 'La liaison Event durable a été acquittée par l’éditeur.',
        journal: journal,
        inspection: inspection,
      );
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      return _blocked(
        'confirmationRequired',
        'La suppression de la source exige une confirmation explicite.',
      );
    }
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      var inspection = await _inspectLocked(project.path!);
      var journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      final cleanupProjectBytes = await File(project.path!).readAsBytes();
      final cleanupProjectRevision =
          narrativeEventBytesFingerprint(cleanupProjectBytes);
      final cleanupProject = decodeValidatedNarrativeEventAuthoringProject(
        cleanupProjectBytes,
      ).manifest;
      final referenceIssue = _sourceReferenceIssue(
        cleanupProject.eventRegistry,
        journal,
      );
      if (referenceIssue != null) {
        return _blockedIssue(referenceIssue, journal: journal);
      }
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted) {
        await _deleteCompletedArtifacts(journal);
        return NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.cleaned,
          code: 'cleanupAlreadyCommitted',
          message: 'La source était déjà supprimée.',
          journal: journal,
          inspection: inspection,
        );
      }
      if (inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit &&
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.cleanupPending) {
        return _blocked(
          inspection.issues.firstOrNull?.code ?? 'cleanupBlocked',
          inspection.issues.firstOrNull?.message ??
              'La source ne peut pas être supprimée en sécurité.',
          journal: journal,
          inspection: inspection,
        );
      }
      final mapBytes = await File(journal.mapPath).readAsBytes();
      final currentMap = decodeValidatedNarrativeEventAuthoringMap(
        mapBytes,
        journal.mapPath,
      );
      final ownerIssue = _exactOwnerIssue(
        map: currentMap,
        source: journal.source,
        expectedOwnerJson: journal.sourceOwnerJson,
        expectedFingerprint: journal.sourceOwnerFingerprint,
      );
      if (ownerIssue != null) {
        return _blockedIssue(ownerIssue, journal: journal);
      }
      if (journal.cleanupMarker ==
          NarrativeEventSpatialLinkCleanupMarker.none) {
        journal = journal.markCleanupRequested(_clock().toUtc());
        await _writeJournal(journal);
        await _checkpoint(
          NarrativeEventSpatialLinkCheckpoint.afterCleanupJournalMarked,
        );
        inspection = NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.cleanupPending,
          journal: journal,
        );
      }
      final cleanedMap = _removeExactOwner(currentMap, journal.source);
      final cleanedBytes = _canonicalJsonUtf8(cleanedMap.toJson());
      decodeValidatedNarrativeEventAuthoringMap(
        cleanedBytes,
        journal.mapPath,
      );
      await _writeBytesFlushed(journal.mapTempPath, cleanedBytes);
      final tempHash = narrativeEventBytesFingerprint(
        await File(journal.mapTempPath).readAsBytes(),
      );
      final expectedCleanedHash = narrativeEventBytesFingerprint(cleanedBytes);
      if (tempHash != expectedCleanedHash) {
        return _blocked(
          'cleanupTempHashMismatch',
          'Le temporaire de nettoyage est invalide.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _checkpoint(
        NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename,
      );
      final cleanupPathIssue = await _symbolicLinkIssue([
        project.path!,
        journal.mapPath,
        journal.mapTempPath,
      ]);
      if (cleanupPathIssue != null) {
        await _deleteIfRegular(journal.mapTempPath);
        return _blockedIssue(cleanupPathIssue, journal: journal);
      }
      final liveProjectBytes = await File(project.path!).readAsBytes();
      final liveProjectHash = narrativeEventBytesFingerprint(liveProjectBytes);
      if (liveProjectHash != cleanupProjectRevision) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          'projectChangedDuringCleanup',
          'Le projet a changé pendant le nettoyage de la source.',
          journal: journal,
          inspection: inspection,
        );
      }
      final liveProject = decodeValidatedNarrativeEventAuthoringProject(
        liveProjectBytes,
      );
      final liveReferenceIssue = _sourceReferenceIssue(
        liveProject.manifest.eventRegistry,
        journal,
      );
      if (liveReferenceIssue != null) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          liveReferenceIssue.code,
          liveReferenceIssue.message,
          journal: journal,
          inspection: inspection,
        );
      }
      final liveMapHash = narrativeEventBytesFingerprint(
        await File(journal.mapPath).readAsBytes(),
      );
      if (liveMapHash != narrativeEventBytesFingerprint(mapBytes)) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          'staleMapRevisionBeforeCleanup',
          'La map a changé pendant le nettoyage.',
          journal: journal,
          inspection: inspection,
        );
      }
      await File(journal.mapTempPath).rename(journal.mapPath);
      await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterCleanupRename);
      final committedBytes = await File(journal.mapPath).readAsBytes();
      if (narrativeEventBytesFingerprint(committedBytes) !=
          expectedCleanedHash) {
        return _blocked(
          'cleanupMapHashMismatch',
          'La map nettoyée ne correspond pas au hash attendu.',
          journal: journal,
          inspection: inspection,
        );
      }
      final committedMap = decodeValidatedNarrativeEventAuthoringMap(
        committedBytes,
        journal.mapPath,
      );
      if (_ownerState(
            map: committedMap,
            source: journal.source,
            expectedOwnerJson: journal.sourceOwnerJson,
            expectedFingerprint: journal.sourceOwnerFingerprint,
          ).kind !=
          _OwnerStateKind.absent) {
        return _blocked(
          'cleanupOwnerStillPresent',
          'La source est encore présente après le nettoyage.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _deleteCompletedArtifacts(journal);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.cleaned,
        code: 'sourceCleaned',
        message: 'Seule la source physique inchangée a été supprimée.',
        journal: journal,
        inspection: inspection,
      );
    });
  }

  Future<_PathResolution> _qualifyProject(String projectPath) async {
    final input = File(p.normalize(File(projectPath).absolute.path));
    final type = await FileSystemEntity.type(input.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      return _PathResolution.issue(_issue(
        'symbolicLinkRefused',
        'Le manifest ne peut pas être un lien symbolique.',
        input.path,
      ));
    }
    if (type != FileSystemEntityType.file) {
      return _PathResolution.issue(_issue(
        'projectMissing',
        'Le manifest du projet est introuvable.',
        input.path,
      ));
    }
    return _PathResolution.path(
      p.normalize(await input.resolveSymbolicLinks()),
    );
  }

  Future<_PathResolution> _resolveManifestMap({
    required String projectPath,
    required ProjectManifest project,
    required String mapId,
  }) async {
    final matching = project.maps.where((entry) => entry.id == mapId).toList();
    if (matching.length != 1) {
      return _PathResolution.issue(_issue(
        'mapManifestIdentityMismatch',
        'La map $mapId doit apparaître exactement une fois dans le manifest.',
        projectPath,
      ));
    }
    final relativePath = matching.single.relativePath;
    if (p.isAbsolute(relativePath) ||
        p.split(relativePath).any((part) => part == '..')) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'Le chemin de map doit rester relatif au projet.',
        relativePath,
      ));
    }
    final projectRoot = p.dirname(projectPath);
    final candidate = p.normalize(p.join(projectRoot, relativePath));
    if (!p.isWithin(projectRoot, candidate)) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'Le chemin de map sort du projet.',
        candidate,
      ));
    }
    var cursor = projectRoot;
    for (final part in p.split(p.relative(candidate, from: projectRoot))) {
      cursor = p.join(cursor, part);
      final type = await FileSystemEntity.type(cursor, followLinks: false);
      if (type == FileSystemEntityType.link) {
        return _PathResolution.issue(_issue(
          'symbolicLinkRefused',
          'Les liens symboliques sont refusés pour la map.',
          cursor,
        ));
      }
    }
    if (await FileSystemEntity.type(candidate, followLinks: false) !=
        FileSystemEntityType.file) {
      return _PathResolution.issue(_issue(
        'mapMissing',
        'La map $mapId est introuvable.',
        candidate,
      ));
    }
    final canonical = p.normalize(await File(candidate).resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, canonical)) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'La map résolue sort du projet.',
        canonical,
      ));
    }
    return _PathResolution.path(canonical);
  }

  NarrativeEventSpatialLinkInspectionIssue? _validateExactSourceAddition(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    final beforeOwner = _ownerState(
      map: request.beforeMap,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (beforeOwner.kind != _OwnerStateKind.absent) {
      return _issue(
        'sourceAlreadyPresent',
        'La source existe déjà dans la map avant proposition.',
      );
    }
    final afterOwnerIssue = _exactOwnerIssue(
      map: request.afterMap,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (afterOwnerIssue != null) return afterOwnerIssue;
    final withoutSource = _removeExactOwner(request.afterMap, request.source);
    if (!_sameJson(withoutSource.toJson(), request.beforeMap.toJson())) {
      return _issue(
        'proposalMutatesUnrelatedMapContent',
        'La proposition doit ajouter uniquement sa source physique.',
      );
    }
    return null;
  }

  _OwnerState _ownerState({
    required MapData map,
    required NarrativeEventSourceRef source,
    required Map<String, Object?> expectedOwnerJson,
    required String expectedFingerprint,
  }) {
    final owner = _ownerEnvelope(map, source);
    if (owner == null) return const _OwnerState(_OwnerStateKind.absent);
    final fingerprint = narrativeEventBytesFingerprint(
      _canonicalJsonUtf8(owner),
    );
    if (fingerprint != expectedFingerprint ||
        !_sameJson(owner, expectedOwnerJson)) {
      return _OwnerState(_OwnerStateKind.modified, fingerprint: fingerprint);
    }
    return _OwnerState(_OwnerStateKind.exact, fingerprint: fingerprint);
  }

  NarrativeEventSpatialLinkInspectionIssue? _exactOwnerIssue({
    required MapData map,
    required NarrativeEventSourceRef source,
    required Map<String, Object?> expectedOwnerJson,
    required String expectedFingerprint,
  }) {
    final owner = _ownerState(
      map: map,
      source: source,
      expectedOwnerJson: expectedOwnerJson,
      expectedFingerprint: expectedFingerprint,
    );
    return switch (owner.kind) {
      _OwnerStateKind.exact => null,
      _OwnerStateKind.absent => _issue(
          'sourceUnexpectedlyAbsent',
          'La source physique attendue est absente.',
        ),
      _OwnerStateKind.modified => _issue(
          'sourceFingerprintMismatch',
          'La source physique ne correspond pas à son fingerprint.',
        ),
    };
  }

  Map<String, Object?>? _ownerEnvelope(
    MapData map,
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (mapId, entityId) {
        if (map.id != mapId) return null;
        final owners = map.entities.where((entity) => entity.id == entityId);
        if (owners.length != 1) return null;
        final owner = owners.single;
        return {
          'schemaVersion': 1,
          'ownerKind': 'mapEntity',
          'mapId': mapId,
          'sourceId': entityId,
          'owner': owner.toJson(),
        };
      },
      triggerEnter: (mapId, triggerId) {
        if (map.id != mapId) return null;
        final owners = map.triggers.where((trigger) => trigger.id == triggerId);
        if (owners.length != 1) return null;
        final owner = owners.single;
        return {
          'schemaVersion': 1,
          'ownerKind': 'mapTrigger',
          'mapId': mapId,
          'sourceId': triggerId,
          'owner': owner.toJson(),
        };
      },
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );
  }

  MapData _removeExactOwner(MapData map, NarrativeEventSourceRef source) {
    return source.when(
      entityInteract: (_, entityId) => map.copyWith(
        entities: [
          for (final entity in map.entities)
            if (entity.id != entityId) entity,
        ],
      ),
      triggerEnter: (_, triggerId) => map.copyWith(
        triggers: [
          for (final trigger in map.triggers)
            if (trigger.id != triggerId) trigger,
        ],
      ),
      mapEnter: (_) => throw ArgumentError.value(source, 'source'),
      outcomeReceived: (_) => throw ArgumentError.value(source, 'source'),
    );
  }

  NarrativeEventRecord? _eventRecord(
    NarrativeEventRegistry? registry,
    String eventId,
  ) {
    final records = registry?.records.where((record) => record.id == eventId) ??
        const <NarrativeEventRecord>[];
    if (records.length != 1) return null;
    return records.single;
  }

  NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
    return record.when(
      draft: (draft) => draft.source,
      configured: (definition, _) => definition.source,
    );
  }

  NarrativeEventSpatialLinkInspectionIssue? _sourceReferenceIssue(
    NarrativeEventRegistry? registry,
    NarrativeEventSpatialLinkJournal journal,
  ) {
    if (registry == null) return null;
    final recordIds = <String>[
      for (final record in registry.records)
        if (_recordSource(record) == journal.source) record.id,
    ];
    if (recordIds.any((id) => id != journal.eventId)) {
      return _issue(
        'sourceReferencedByAnotherEvent',
        'Un autre Event référence désormais cette source physique.',
      );
    }
    if (recordIds.isNotEmpty) {
      return _issue(
        'sourceReferencedByTargetEvent',
        'L’Event cible référence déjà cette source physique.',
      );
    }
    if (registry.legacyClaims.any((claim) => claim.source == journal.source)) {
      return _issue(
        'sourceReferencedByLegacyClaim',
        'Un claim legacy référence cette source physique.',
      );
    }
    return null;
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _journalPathIssue({
    required String projectPath,
    required String actualJournalPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) async {
    final expected = _pathsFor(
      projectPath: projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (journal.projectPath != projectPath ||
        p.normalize(actualJournalPath) != expected.journalPath ||
        journal.journalPath != expected.journalPath ||
        journal.mapTempPath != expected.mapTempPath ||
        !p.isWithin(p.dirname(projectPath), journal.mapPath)) {
      return _issue(
        'unsafeJournalPaths',
        'Les chemins du journal ne correspondent pas à son opération.',
        actualJournalPath,
      );
    }
    final projectBytes = await File(projectPath).readAsBytes();
    late final ProjectManifest project;
    try {
      project =
          decodeValidatedNarrativeEventAuthoringProject(projectBytes).manifest;
    } on Object catch (error) {
      return _issue(
        'invalidProject',
        'Le projet du journal est invalide: $error',
        projectPath,
      );
    }
    final resolved = await _resolveManifestMap(
      projectPath: projectPath,
      project: project,
      mapId: journal.mapId,
    );
    if (resolved.issue != null) return resolved.issue;
    if (resolved.path != journal.mapPath) {
      return _issue(
        'unsafeJournalPaths',
        'La map du journal ne correspond plus au manifest.',
        journal.mapPath,
      );
    }
    return null;
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _writableArtifactPathIssue(
    _SpatialLinkPaths paths,
  ) async {
    for (final path in [
      paths.journalPath,
      paths.journalRewriteTempPath,
      paths.mapTempPath,
    ]) {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.link) {
        return _issue(
          'symbolicLinkRefused',
          'Un artefact de persistance ne peut pas être un lien symbolique.',
          path,
        );
      }
    }
    return null;
  }

  Future<_JournalArtifacts> _journalArtifacts(String projectPath) async {
    final directory = Directory(p.dirname(projectPath));
    final prefix = _projectArtifactPrefix(projectPath);
    final journals = <String>[];
    final rewriteTemps = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (!name.startsWith(prefix)) continue;
      if (name.endsWith(journalSuffix)) {
        journals.add(p.normalize(entity.path));
      } else if (name.endsWith('$journalSuffix.rewrite.tmp')) {
        rewriteTemps.add(p.normalize(entity.path));
      }
    }
    journals.sort();
    rewriteTemps.sort();
    return _JournalArtifacts(journals, rewriteTemps);
  }

  _SpatialLinkPaths _pathsFor({
    required String projectPath,
    required String mapPath,
    required String operationId,
  }) {
    final safe = _safeOperationId(operationId);
    if (safe == null) {
      throw ArgumentError.value(
          operationId, 'operationId', 'must be path-safe');
    }
    final stem = '${_projectArtifactPrefix(projectPath)}$safe';
    final journalPath = p.normalize(
      p.join(p.dirname(projectPath), '$stem$journalSuffix'),
    );
    return _SpatialLinkPaths(
      journalPath: journalPath,
      journalRewriteTempPath: '$journalPath.rewrite.tmp',
      mapTempPath: p.normalize(
        p.join(p.dirname(mapPath), '$stem$mapTempSuffix'),
      ),
    );
  }

  String _projectArtifactPrefix(String projectPath) {
    final key = narrativeEventCanonicalSha256({
      'projectPath': projectPath,
    }).substring(0, 16);
    return '$journalPrefix$key-';
  }

  Future<void> _writeJournal(
    NarrativeEventSpatialLinkJournal journal,
  ) async {
    final paths = _pathsFor(
      projectPath: journal.projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (paths.journalPath != journal.journalPath ||
        paths.mapTempPath != journal.mapTempPath) {
      throw StateError('Unsafe spatial link journal paths.');
    }
    final pathIssue = await _symbolicLinkIssue([
      paths.journalPath,
      paths.journalRewriteTempPath,
    ]);
    if (pathIssue != null) {
      throw FileSystemException(pathIssue.message, pathIssue.path);
    }
    final bytes = _canonicalJsonUtf8(journal.toJson());
    await _writeBytesFlushed(paths.journalRewriteTempPath, bytes);
    final verify = await File(paths.journalRewriteTempPath).readAsBytes();
    if (narrativeEventBytesFingerprint(verify) !=
        narrativeEventBytesFingerprint(bytes)) {
      throw const FileSystemException('Journal temp hash mismatch.');
    }
    await File(paths.journalRewriteTempPath).rename(paths.journalPath);
  }

  Future<void> _writeBytesFlushed(String path, List<int> bytes) async {
    final file = File(path);
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException(
        'A symbolic link cannot be used as a persistence temporary.',
        path,
      );
    }
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  Future<void> _deleteCompletedArtifacts(
    NarrativeEventSpatialLinkJournal journal,
  ) async {
    final expected = _pathsFor(
      projectPath: journal.projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (expected.journalPath != journal.journalPath ||
        expected.mapTempPath != journal.mapTempPath) {
      return;
    }
    for (final path in [
      expected.mapTempPath,
      expected.journalRewriteTempPath,
      expected.journalPath,
    ]) {
      await _deleteIfRegular(path);
    }
  }

  Future<void> _deleteIfRegular(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.file) await File(path).delete();
  }

  Future<void> _checkpoint(
    NarrativeEventSpatialLinkCheckpoint checkpoint,
  ) async {
    await faultInjector?.call(checkpoint);
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _symbolicLinkIssue(
    Iterable<String> paths,
  ) async {
    for (final path in paths) {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.link) {
        return _issue(
          'symbolicLinkRefused',
          'Un chemin de persistance est devenu un lien symbolique.',
          path,
        );
      }
    }
    return null;
  }

  NarrativeEventSpatialLinkOperationResult _blocked(
    String code,
    String message, {
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
  }) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.blocked,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _blockedIssue(
    NarrativeEventSpatialLinkInspectionIssue issue, {
    NarrativeEventSpatialLinkJournal? journal,
  }) {
    return _blocked(issue.code, issue.message, journal: journal);
  }

  NarrativeEventSpatialLinkOperationResult _conflict(
    String code,
    String message, {
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
  }) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.conflict,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _recovered(
    String code,
    String message,
    NarrativeEventSpatialLinkJournal journal,
    NarrativeEventSpatialLinkInspection inspection,
  ) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.recovered,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _registryRecoveryBlocked(
    NarrativeEventRegistryRecoveryInspection inspection,
  ) {
    final issue = inspection.issues.firstOrNull;
    return _blocked(
      inspection.status ==
              NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
          ? 'eventRegistryRecoveryRequired'
          : 'eventRegistryRecoveryBlocked',
      issue?.message ??
          'Le registry Event doit être récupéré avant cette liaison.',
    );
  }

  NarrativeEventSpatialLinkInspection _inspectionBlocked(
    String code,
    String message,
    String path, {
    NarrativeEventSpatialLinkJournal? journal,
  }) {
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.blocked,
      journal: journal,
      issues: [_issue(code, message, path)],
    );
  }

  NarrativeEventSpatialLinkInspectionIssue _issue(
    String code,
    String message, [
    String? path,
  ]) {
    return NarrativeEventSpatialLinkInspectionIssue(
      code: code,
      message: message,
      path: path,
    );
  }

  String? _safeOperationId(String value) {
    if (value.length > 96 ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(value)) {
      return null;
    }
    return value;
  }
}

bool _sameJson(Object? left, Object? right) {
  return canonicalizeNarrativeEventJson(_normalizeJsonValue(left)) ==
      canonicalizeNarrativeEventJson(_normalizeJsonValue(right));
}

List<int> _canonicalJsonUtf8(Object? value) {
  return canonicalizeNarrativeEventJsonUtf8(_normalizeJsonValue(value));
}

Object? _normalizeJsonValue(Object? value) {
  return decodeNarrativeEventJsonStrict(jsonEncode(value));
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('JSON keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

enum _OwnerStateKind { absent, exact, modified }

final class _OwnerState {
  const _OwnerState(this.kind, {this.fingerprint});

  final _OwnerStateKind kind;
  final String? fingerprint;
}

final class _PathResolution {
  const _PathResolution._({this.path, this.issue});

  factory _PathResolution.path(String path) => _PathResolution._(path: path);

  factory _PathResolution.issue(
    NarrativeEventSpatialLinkInspectionIssue issue,
  ) =>
      _PathResolution._(issue: issue);

  final String? path;
  final NarrativeEventSpatialLinkInspectionIssue? issue;
}

final class _SpatialLinkPaths {
  const _SpatialLinkPaths({
    required this.journalPath,
    required this.journalRewriteTempPath,
    required this.mapTempPath,
  });

  final String journalPath;
  final String journalRewriteTempPath;
  final String mapTempPath;
}

final class _JournalArtifacts {
  const _JournalArtifacts(this.journals, this.rewriteTemps);

  final List<String> journals;
  final List<String> rewriteTemps;
}
```

### 22.12 `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../../theme/theme.dart';

/// Temporary V2 source summary embedded above the legacy Event Builder.
///
/// Phase H will replace the surrounding workspace. This panel deliberately
/// owns no map/source picker: it only navigates from the selected typed source.
class NarrativeEventMapReturnPanel extends ConsumerWidget {
  const NarrativeEventMapReturnPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final project = editor.project;
    final eventId = bridge.selectedNarrativeEventV2Id;
    final record = _recordById(project?.eventRegistry, eventId);
    if (project == null || eventId == null || record == null) {
      return const SizedBox.shrink();
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final sourceMissing = source == null;
    final spatial = source != null &&
        source.kind != NarrativeEventSourceKind.outcomeReceived;
    final selectedGroup = bridge.selectedGroupContext;
    final missingSourceMapContext = sourceMissing &&
        selectedGroup?.kind == NarrativeEventGroupContextKind.map;
    final colors = context.pokeMapColors;
    final name = record.draftOrNull?.name ?? record.definitionOrNull!.name;

    Future<void> open(NarrativeEventMapNavigationMode mode) async {
      if (!spatial) return;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final group = NarrativeEventGroupContext.map(_mapId(source));
      final notifier = ref.read(editorNotifierProvider.notifier);
      final result = await ref
          .read(narrativeEventMapBridgeControllerProvider.notifier)
          .openMapForEvent(
            eventId: eventId,
            groupContext: group,
            mode: mode,
            project: currentProject,
            activeMap: current.activeMap,
            mapDirty: current.isDirty,
            loadMapSnapshot: notifier.loadMapSnapshotById,
            activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
            applyFocus: notifier.focusNarrativeEventMapSource,
          );
      if (!result.succeeded) return;
      final afterNavigation = ref.read(editorNotifierProvider);
      await ref
          .read(narrativeEventMapBridgeControllerProvider.notifier)
          .inspectPendingSourceCreation(
            projectRootPath: afterNavigation.projectRootPath,
            mapDirty: afterNavigation.isDirty,
            projectDirty: afterNavigation.isProjectDirty,
            saving: afterNavigation.isSaving,
          );
      notifier.selectMapWorkspace();
    }

    Future<void> createSourceOnMap() async {
      if (!missingSourceMapContext || record.draftOrNull == null) return;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final notifier = ref.read(editorNotifierProvider.notifier);
      final controller =
          ref.read(narrativeEventMapBridgeControllerProvider.notifier);
      final result = await controller.openMapForMissingSource(
        eventId: eventId,
        groupContext: selectedGroup!,
        project: currentProject,
        activeMap: current.activeMap,
        mapDirty: current.isDirty,
        loadMapSnapshot: notifier.loadMapSnapshotById,
        activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
      );
      if (!result.succeeded) return;
      await controller.inspectPendingSourceCreation(
        projectRootPath: current.projectRootPath,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
      );
      notifier.selectMapWorkspace();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: PokeMapPanel(
        key: const ValueKey('narrative-event-map-return-panel'),
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.link, color: colors.narrative, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Event V2',
                variant: PokeMapBadgeVariant.narrative,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sourceMissing
                  ? missingSourceMapContext
                      ? 'Source manquante · ${_mapName(project, selectedGroup!.mapId!)}'
                      : 'Source manquante · choisissez cet Event depuis son groupe de map'
                  : spatial
                      ? _spatialSourceLabel(project, source)
                      : 'Event global · aucune position sur une map',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (spatial) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PokeMapButton(
                      key: const ValueKey('narrative-event-view-on-map'),
                      onPressed: () =>
                          open(NarrativeEventMapNavigationMode.view),
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.eye),
                      child: const Text('Voir sur la carte'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PokeMapButton(
                      key: const ValueKey('narrative-event-choose-on-map'),
                      onPressed: () =>
                          open(NarrativeEventMapNavigationMode.choose),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.scope),
                      child: const Text('Choisir / changer'),
                    ),
                  ),
                ],
              ),
            ],
            if (missingSourceMapContext && record.draftOrNull != null) ...[
              const SizedBox(height: 10),
              PokeMapButton(
                key: const ValueKey('narrative-event-create-source-on-map'),
                onPressed:
                    bridge.isSourceCreationBusy ? null : createSourceOnMap,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.add_circled),
                child: const Text('Créer une source sur la carte'),
              ),
            ],
            if (bridge.lastNavigationResult != null &&
                !bridge.lastNavigationResult!.succeeded) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastNavigationResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

NarrativeEventRecord? _recordById(
  NarrativeEventRegistry? registry,
  String? eventId,
) {
  if (eventId == null) return null;
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _mapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => throw StateError('A global source has no map.'),
  );
}

String _spatialSourceLabel(
  ProjectManifest project,
  NarrativeEventSourceRef source,
) {
  final mapId = _mapId(source);
  final mapName = _mapName(project, mapId);
  return source.when(
    entityInteract: (_, __) => 'Interaction avec une entité · $mapName',
    triggerEnter: (_, __) => 'Entrée dans une zone · $mapName',
    mapEnter: (_) => 'Entrée sur la map · $mapName',
    outcomeReceived: (_) => 'Event global',
  );
}

String _mapName(ProjectManifest project, String mapId) {
  for (final entry in project.maps) {
    if (entry.id == mapId) {
      return entry.name;
    }
  }
  return 'Map liée';
}
```

### 22.13 `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../design_system/design_system.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../../application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import '../../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../../theme/theme.dart';

class NarrativeEventMapBanner extends ConsumerWidget {
  const NarrativeEventMapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final token = bridge.pendingReturn;
    final map = editor.activeMap;
    final project = editor.project;
    if (token == null ||
        map == null ||
        project == null ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != map.id) {
      return const SizedBox.shrink();
    }
    final record = _recordById(project.eventRegistry, token.eventId);
    final eventName = record?.draftOrNull?.name ??
        record?.definitionOrNull?.name ??
        'Event supprimé';
    final isCreate =
        bridge.navigationMode == NarrativeEventMapNavigationMode.create;
    final hasBlockingSourceRecovery = bridge.lastSourceCreationResult?.status ==
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired;
    final cleanupRequiresReload = hasBlockingSourceRecovery &&
        bridge.lastSourceCreationResult?.code == 'cleanedMapOutOfSync';
    final recoveryRequiresReload = hasBlockingSourceRecovery &&
        (bridge.lastSourceCreationResult?.journal?.state ==
                NarrativeEventSpatialLinkJournalState.eventCommitted ||
            cleanupRequiresReload);
    final reloadIsBlocked = editor.isSaving ||
        bridge.isSourceCreationBusy ||
        (!cleanupRequiresReload && (editor.isDirty || editor.isProjectDirty));
    final candidate =
        bridge.navigationMode == NarrativeEventMapNavigationMode.choose
            ? _selectedCandidate(editor.activeMap!, editor.selectedEntityId,
                editor.selectedTriggerId)
            : null;
    final colors = context.pokeMapColors;
    final controller =
        ref.read(narrativeEventMapBridgeControllerProvider.notifier);
    final notifier = ref.read(editorNotifierProvider.notifier);

    void returnToExactEvent() {
      final currentProject = ref.read(editorNotifierProvider).project;
      if (currentProject == null) return;
      controller.returnToEvent(
        project: currentProject,
        openExactEvent: ({required eventId, required groupContext}) {
          notifier.selectEventsWorkspace();
        },
      );
    }

    Future<void> confirmCandidate() async {
      final source = candidate?.source;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (source == null || currentProject == null || currentMap == null) {
        return;
      }
      final result = await controller.linkChosenSource(
        projectRootPath: current.projectRootPath,
        project: currentProject,
        activeMap: currentMap,
        source: source,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
        applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
      );
      if (result?.status == NarrativeEventSpatialSourceLinkStatus.committed ||
          result?.status == NarrativeEventSpatialSourceLinkStatus.noOp) {
        returnToExactEvent();
      }
    }

    bool adoptPersistedMap(
      NarrativeEventCreatedSourceProposal proposal, {
      Object? mapWriteLeaseToken,
    }) {
      final current = ref.read(editorNotifierProvider);
      if (identical(current.activeMap, proposal.afterMap)) return true;
      return notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
        mapWriteLeaseToken: mapWriteLeaseToken,
      );
    }

    bool applyPersistedRegistry({
      required String expectedProjectRootPath,
      required NarrativeEventRegistry? expectedPreviousRegistry,
      required NarrativeEventRegistry nextRegistry,
    }) {
      final current = ref.read(editorNotifierProvider);
      if (current.project?.eventRegistry == nextRegistry) return true;
      return notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: expectedProjectRootPath,
        expectedPreviousRegistry: expectedPreviousRegistry,
        nextRegistry: nextRegistry,
      );
    }

    Future<void> confirmCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      NarrativeEventExplicitSourceCreationResult? result;
      try {
        result = await controller.confirmSourceCreation(
          projectRootPath: current.projectRootPath,
          project: currentProject,
          mapDirty: current.isDirty,
          projectDirty: current.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
      if (result?.status ==
          NarrativeEventExplicitSourceCreationStatus.committed) {
        returnToExactEvent();
      }
    }

    Future<void> retryCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (currentProject == null || currentMap == null) return;
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      NarrativeEventExplicitSourceCreationResult? result;
      try {
        result = await controller.retrySourceCreation(
          projectRootPath: current.projectRootPath,
          project: currentProject,
          activeMap: currentMap,
          mapDirty: current.isDirty,
          projectDirty: current.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
      if (result?.status ==
          NarrativeEventExplicitSourceCreationStatus.committed) {
        returnToExactEvent();
      }
    }

    Future<void> cleanupCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentMap = current.activeMap;
      if (currentMap == null) return;
      await controller.cleanupCreatedSource(
        projectRootPath: current.projectRootPath,
        activeMap: currentMap,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
        beginCleanupInterlock:
            notifier.beginNarrativeEventSourceCleanupInterlock,
        releaseCleanupInterlock:
            notifier.releaseNarrativeEventSourceCleanupInterlock,
        adoptPersistedCleanup:
            notifier.adoptPersistedNarrativeEventSourceCleanup,
      );
    }

    Future<void> reloadCommittedSource() async {
      final recovery = ref
          .read(narrativeEventMapBridgeControllerProvider)
          .lastSourceCreationResult;
      final journal = recovery?.journal;
      final current = ref.read(editorNotifierProvider);
      final root = current.projectRootPath;
      final cleanupReload = recovery?.code == 'cleanedMapOutOfSync';
      if (recovery?.status !=
              NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
          journal == null ||
          (!cleanupReload &&
              journal.state !=
                  NarrativeEventSpatialLinkJournalState.eventCommitted) ||
          root == null ||
          current.isSaving ||
          (!cleanupReload && (current.isDirty || current.isProjectDirty))) {
        return;
      }
      if (cleanupReload) {
        final currentProject = current.project;
        if (currentProject == null ||
            current.projectRootPath == null ||
            p.normalize(current.projectRootPath!) != p.normalize(root)) {
          return;
        }
        ProjectMapEntry? mapEntry;
        for (final entry in currentProject.maps) {
          if (entry.id == journal.mapId) {
            mapEntry = entry;
            break;
          }
        }
        if (mapEntry == null) return;
        await notifier.loadMap(mapEntry.relativePath);
        final reloaded = ref.read(editorNotifierProvider);
        final reloadedMap = reloaded.activeMap;
        if (reloadedMap == null || reloadedMap.id != journal.mapId) return;
        controller.completeSourceCleanupReload(
          projectRootPath: reloaded.projectRootPath,
          activeMap: reloadedMap,
        );
        return;
      }
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      try {
        await notifier.loadProject(
          p.join(root, 'project.json'),
          rememberAsRecent: false,
          mapWriteLeaseToken: writeLease,
        );
        var reloaded = ref.read(editorNotifierProvider);
        final reloadedProject = reloaded.project;
        if (reloadedProject == null ||
            reloaded.projectRootPath == null ||
            p.normalize(reloaded.projectRootPath!) != p.normalize(root)) {
          return;
        }
        ProjectMapEntry? mapEntry;
        for (final entry in reloadedProject.maps) {
          if (entry.id == journal.mapId) {
            mapEntry = entry;
            break;
          }
        }
        if (mapEntry == null) return;
        await notifier.loadMap(
          mapEntry.relativePath,
          mapWriteLeaseToken: writeLease,
        );
        reloaded = ref.read(editorNotifierProvider);
        final reloadedMap = reloaded.activeMap;
        final projectAfterMapLoad = reloaded.project;
        if (reloadedMap == null ||
            reloadedMap.id != journal.mapId ||
            projectAfterMapLoad == null) {
          return;
        }
        await controller.retrySourceCreation(
          projectRootPath: reloaded.projectRootPath,
          project: projectAfterMapLoad,
          activeMap: reloadedMap,
          mapDirty: reloaded.isDirty,
          projectDirty: reloaded.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
    }

    return SizedBox(
      width: 480,
      child: PokeMapPanel(
        key: const ValueKey('narrative-event-map-banner'),
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.scope, color: colors.narrative, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PokeMapBadge(
                label: switch (bridge.navigationMode) {
                  NarrativeEventMapNavigationMode.choose =>
                    'Choisir une source',
                  NarrativeEventMapNavigationMode.create => 'Créer une source',
                  _ => 'Voir la source',
                },
                variant: PokeMapBadgeVariant.narrative,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isCreate
                  ? bridge.sourceCreationKind == null
                      ? 'Choisissez un type physique. Le prochain clic sur la '
                          'map préparera uniquement un aperçu.'
                      : bridge.sourceCreationProposal == null
                          ? 'Cliquez sur la map pour prévisualiser la source. '
                              'Rien ne sera écrit avant confirmation.'
                          : 'Vérifiez l’aperçu puis confirmez la création et '
                              'la liaison à cet Event.'
                  : bridge.navigationMode ==
                          NarrativeEventMapNavigationMode.choose
                      ? 'Sélectionnez une entité ou une zone existante, ou utilisez '
                          'la map elle-même. Aucun élément physique n’est créé ici.'
                      : 'La source liée reste surlignée jusqu’au retour.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (isCreate) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final kind in NarrativeEventPhysicalSourceKind.values)
                    PokeMapButton(
                      key: ValueKey(
                        'narrative-event-create-kind-${kind.name}',
                      ),
                      onPressed: bridge.isSourceCreationBusy ||
                              hasBlockingSourceRecovery
                          ? null
                          : () => controller.selectPhysicalSourceKind(kind),
                      variant: bridge.sourceCreationKind == kind
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: Text(_physicalKindLabel(kind)),
                    ),
                ],
              ),
              if (bridge.sourceCreationProposal != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cancel-preview',
                        ),
                        onPressed: bridge.isSourceCreationBusy ||
                                hasBlockingSourceRecovery
                            ? null
                            : controller.cancelSourceCreationProposal,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-confirm',
                        ),
                        onPressed: editor.isSaving ||
                                bridge.isSourceCreationBusy ||
                                hasBlockingSourceRecovery ||
                                editor.isDirty ||
                                editor.isProjectDirty
                            ? null
                            : confirmCreatedSource,
                        isLoading: bridge.isSourceCreationBusy,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.check_mark),
                        child: const Text('Enregistrer et lier'),
                      ),
                    ),
                  ],
                ),
              ],
              if (bridge.lastSourceCreationResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  bridge.lastSourceCreationResult!.message,
                  style: TextStyle(
                    color: bridge.lastSourceCreationResult!.status ==
                            NarrativeEventExplicitSourceCreationStatus.cleaned
                        ? colors.textSecondary
                        : colors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (bridge.lastSourceCreationResult?.status ==
                      NarrativeEventExplicitSourceCreationStatus
                          .recoveryRequired &&
                  !recoveryRequiresReload) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-retry',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : retryCreatedSource,
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        child: const Text('Réessayer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-request',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : controller.requestSourceCleanupConfirmation,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Supprimer la source'),
                      ),
                    ),
                  ],
                ),
              ],
              if (recoveryRequiresReload) ...[
                const SizedBox(height: 8),
                PokeMapButton(
                  key: const ValueKey('narrative-event-create-reload'),
                  onPressed: reloadIsBlocked ? null : reloadCommittedSource,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.refresh),
                  child: Text(
                    cleanupRequiresReload
                        ? 'Recharger la map'
                        : 'Recharger le projet',
                  ),
                ),
              ],
              if (bridge.cleanupConfirmationRequested) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-cancel',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : controller.cancelSourceCleanupConfirmation,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-confirm',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : cleanupCreatedSource,
                        variant: PokeMapButtonVariant.danger,
                        size: PokeMapButtonSize.small,
                        child: const Text('Confirmer la suppression'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (!isCreate && bridge.lastSourceCreationResult != null) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastSourceCreationResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!isCreate && recoveryRequiresReload) ...[
              const SizedBox(height: 8),
              PokeMapButton(
                key: const ValueKey('narrative-event-create-reload'),
                onPressed: reloadIsBlocked ? null : reloadCommittedSource,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.refresh),
                child: Text(
                  cleanupRequiresReload
                      ? 'Recharger la map'
                      : 'Recharger le projet',
                ),
              ),
            ],
            if (candidate != null) ...[
              const SizedBox(height: 8),
              PokeMapButton(
                key: const ValueKey('narrative-event-map-confirm-candidate'),
                onPressed: editor.isSaving ||
                        bridge.isLinkingSource ||
                        hasBlockingSourceRecovery
                    ? null
                    : confirmCandidate,
                isLoading: bridge.isLinkingSource,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.link),
                child: Text('Utiliser ${candidate.label}'),
              ),
            ],
            if (bridge.lastNavigationResult != null &&
                !bridge.lastNavigationResult!.succeeded) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastNavigationResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (bridge.lastSourceLinkResult != null &&
                bridge.lastSourceLinkResult!.status !=
                    NarrativeEventSpatialSourceLinkStatus.committed &&
                bridge.lastSourceLinkResult!.status !=
                    NarrativeEventSpatialSourceLinkStatus.noOp) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastSourceLinkResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('narrative-event-map-cancel'),
                    onPressed: bridge.isLinkingSource ||
                            bridge.isSourceCreationBusy ||
                            hasBlockingSourceRecovery
                        ? null
                        : () {
                            controller.cancelMapNavigation();
                            notifier.selectEventsWorkspace();
                          },
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('narrative-event-map-return'),
                    onPressed: bridge.isLinkingSource ||
                            bridge.isSourceCreationBusy ||
                            hasBlockingSourceRecovery
                        ? null
                        : returnToExactEvent,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.chevron_left),
                    child: const Text('Retour à l’Event'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _Candidate {
  const _Candidate(this.source, this.label);

  final NarrativeEventSourceRef source;
  final String label;
}

_Candidate _selectedCandidate(
  MapData map,
  String? selectedEntityId,
  String? selectedTriggerId,
) {
  if (selectedEntityId != null) {
    for (final entity in map.entities) {
      if (entity.id == selectedEntityId && entity.kind != MapEntityKind.spawn) {
        return _Candidate(
          NarrativeEventSourceRef.entityInteract(map.id, entity.id),
          'l’entité sélectionnée',
        );
      }
    }
  }
  if (selectedTriggerId != null) {
    for (final trigger in map.triggers) {
      if (trigger.id == selectedTriggerId &&
          (trigger.type == TriggerType.event ||
              trigger.type == TriggerType.custom)) {
        return _Candidate(
          NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
          'la zone sélectionnée',
        );
      }
    }
  }
  return _Candidate(
    NarrativeEventSourceRef.mapEnter(map.id),
    'cette map',
  );
}

NarrativeEventRecord? _recordById(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _physicalKindLabel(NarrativeEventPhysicalSourceKind kind) {
  return switch (kind) {
    NarrativeEventPhysicalSourceKind.npc => 'PNJ',
    NarrativeEventPhysicalSourceKind.sign => 'Panneau',
    NarrativeEventPhysicalSourceKind.item => 'Objet',
    NarrativeEventPhysicalSourceKind.invisible => 'Invisible',
    NarrativeEventPhysicalSourceKind.zone1x1 => 'Zone 1×1',
  };
}
```

### 22.14 `packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_map_bridge_models.dart';
import '../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class NarrativeEventMapBridgePanel extends ConsumerWidget {
  const NarrativeEventMapBridgePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorNotifierProvider);
    final bridgeState = ref.watch(narrativeEventMapBridgeControllerProvider);
    final map = editorState.activeMap;
    if (map == null) return const SizedBox.shrink();

    final selectedEntity = _selectedEntity(
      map,
      editorState.selectedEntityId,
    );
    final selectedTrigger = _selectedTrigger(
      map,
      editorState.selectedTriggerId,
    );
    final controller =
        ref.read(narrativeEventMapBridgeControllerProvider.notifier);
    final colors = context.pokeMapColors;

    Future<void> chooseSource(NarrativeEventSourceRef source) async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (currentProject == null || currentMap == null) return;
      final notifier = ref.read(editorNotifierProvider.notifier);
      final result = await controller.linkChosenSource(
        projectRootPath: current.projectRootPath,
        project: currentProject,
        activeMap: currentMap,
        source: source,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
        applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
      );
      if (result?.status != NarrativeEventSpatialSourceLinkStatus.committed &&
          result?.status != NarrativeEventSpatialSourceLinkStatus.noOp) {
        return;
      }
      final updatedProject = ref.read(editorNotifierProvider).project;
      if (updatedProject == null) return;
      controller.returnToEvent(
        project: updatedProject,
        openExactEvent: ({required eventId, required groupContext}) {
          notifier.selectEventsWorkspace();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      child: PokeMapPanel(
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.link,
                color: colors.narrative,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Events V2 depuis la map',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Source existante',
                variant: PokeMapBadgeVariant.narrative,
              ),
            ],
          ),
        ),
        child: bridgeState.pendingReturn != null &&
                bridgeState.navigationMode ==
                    NarrativeEventMapNavigationMode.choose
            ? _ChooseSourceActions(
                map: map,
                selectedEntity: selectedEntity,
                selectedTrigger: selectedTrigger,
                result: bridgeState.lastSourceLinkResult,
                isBusy: bridgeState.isLinkingSource,
                onChoose: bridgeState.isLinkingSource ? null : chooseSource,
              )
            : bridgeState.recovery != null
                ? _OutOfSyncRecovery(
                    recovery: bridgeState.recovery!,
                    reloadBlocked: editorState.isDirty ||
                        editorState.isProjectDirty ||
                        editorState.isSaving,
                    onCancel: () => controller.dismissRecovery(
                      projectRootPath: editorState.projectRootPath,
                    ),
                    onReload: editorState.isDirty ||
                            editorState.isProjectDirty ||
                            editorState.isSaving
                        ? null
                        : () async {
                            final recovery = bridgeState.recovery!;
                            final current = ref.read(editorNotifierProvider);
                            final currentRoot = current.projectRootPath;
                            if (current.isDirty ||
                                current.isProjectDirty ||
                                current.isSaving ||
                                currentRoot == null ||
                                p.normalize(currentRoot) !=
                                    recovery.projectRootPath) {
                              return;
                            }
                            final notifier =
                                ref.read(editorNotifierProvider.notifier);
                            await notifier.loadProject(
                              p.join(recovery.projectRootPath, 'project.json'),
                              rememberAsRecent: false,
                            );
                            final reloaded = ref.read(editorNotifierProvider);
                            controller.finishRecoveryReload(
                              projectRootPath: reloaded.projectRootPath,
                              loadedRegistry: reloaded.project?.eventRegistry,
                            );
                          },
                  )
                : bridgeState.pendingIntent != null
                    ? _PendingIntent(
                        state: bridgeState,
                        onCancel: controller.cancel,
                        onConfirm: editorState.projectRootPath == null
                            ? null
                            : () async {
                                final result = await controller.confirm(
                                  projectRootPath: editorState.projectRootPath,
                                  mapDirty: editorState.isDirty,
                                  projectDirty: editorState.isProjectDirty,
                                  saving: editorState.isSaving,
                                  applyPersistedRegistry: ref
                                      .read(editorNotifierProvider.notifier)
                                      .applyPersistedNarrativeEventRegistry,
                                );
                                if (result?.status ==
                                    NarrativeEventMapCreationStatus.committed) {
                                  final current =
                                      ref.read(editorNotifierProvider);
                                  final project = current.project;
                                  final eventId = result?.eventId;
                                  if (project != null && eventId != null) {
                                    controller.selectNarrativeEventV2(
                                      project,
                                      eventId,
                                    );
                                    ref
                                        .read(editorNotifierProvider.notifier)
                                        .selectEventsWorkspace();
                                  }
                                }
                              },
                      )
                    : bridgeState.linkedEvents.isNotEmpty
                        ? _ExistingLinks(
                            state: bridgeState,
                            onSelect: (eventId) {
                              final project = editorState.project;
                              if (project == null ||
                                  !controller.selectNarrativeEventV2(
                                    project,
                                    eventId,
                                  )) {
                                return;
                              }
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .selectEventsWorkspace();
                            },
                            onCreateAdditional:
                                controller.requestAdditionalEvent,
                            onBack: controller.clearLinkedEvents,
                          )
                        : _SourceActions(
                            map: map,
                            selectedEntity: selectedEntity,
                            selectedTrigger: selectedTrigger,
                            result: bridgeState.lastResult,
                            onRequest: (intent) {
                              controller.request(
                                intent,
                                projectRootPath: editorState.projectRootPath,
                              );
                            },
                          ),
      ),
    );
  }
}

class _ChooseSourceActions extends StatelessWidget {
  const _ChooseSourceActions({
    required this.map,
    required this.selectedEntity,
    required this.selectedTrigger,
    required this.result,
    required this.isBusy,
    required this.onChoose,
  });

  final MapData map;
  final MapEntity? selectedEntity;
  final MapTrigger? selectedTrigger;
  final NarrativeEventSpatialSourceLinkResult? result;
  final bool isBusy;
  final ValueChanged<NarrativeEventSourceRef>? onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choisissez la source physique déjà présente. Sa map est reprise '
          'automatiquement.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedEntity != null) ...[
          PokeMapButton(
            key: ValueKey(
              'narrative-event-choose-source-entity-${selectedEntity!.id}',
            ),
            onPressed: onChoose == null
                ? null
                : () => onChoose!(
                      NarrativeEventSourceRef.entityInteract(
                        map.id,
                        selectedEntity!.id,
                      ),
                    ),
            isLoading: isBusy,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.person_crop_circle),
            child: const Text('Utiliser l’entité sélectionnée'),
          ),
          const SizedBox(height: 8),
        ],
        if (selectedTrigger != null) ...[
          PokeMapButton(
            key: ValueKey(
              'narrative-event-choose-source-trigger-${selectedTrigger!.id}',
            ),
            onPressed: onChoose == null
                ? null
                : () => onChoose!(
                      NarrativeEventSourceRef.triggerEnter(
                        map.id,
                        selectedTrigger!.id,
                      ),
                    ),
            isLoading: isBusy,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.square),
            child: const Text('Utiliser la zone sélectionnée'),
          ),
          const SizedBox(height: 8),
        ],
        PokeMapButton(
          key: ValueKey('narrative-event-choose-source-map-${map.id}'),
          onPressed: onChoose == null
              ? null
              : () => onChoose!(NarrativeEventSourceRef.mapEnter(map.id)),
          isLoading: isBusy,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.map),
          child: const Text('Utiliser cette map'),
        ),
        if (result != null &&
            result!.status != NarrativeEventSpatialSourceLinkStatus.committed &&
            result!.status != NarrativeEventSpatialSourceLinkStatus.noOp) ...[
          const SizedBox(height: 8),
          Text(
            result!.message,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _OutOfSyncRecovery extends StatelessWidget {
  const _OutOfSyncRecovery({
    required this.recovery,
    required this.reloadBlocked,
    required this.onReload,
    required this.onCancel,
  });

  final NarrativeEventMapBridgeRecovery recovery;
  final bool reloadBlocked;
  final Future<void> Function()? onReload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          recovery.result.message,
          style: TextStyle(
            color: colors.error,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        if (reloadBlocked) ...[
          const SizedBox(height: 8),
          Text(
            'Enregistrez les modifications en cours avant de recharger.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-recovery-reload'),
          onPressed: onReload,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.refresh),
          child: const Text('Recharger le projet'),
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-recovery-cancel'),
          onPressed: onCancel,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _SourceActions extends StatelessWidget {
  const _SourceActions({
    required this.map,
    required this.selectedEntity,
    required this.selectedTrigger,
    required this.result,
    required this.onRequest,
  });

  final MapData map;
  final MapEntity? selectedEntity;
  final MapTrigger? selectedTrigger;
  final NarrativeEventMapCreationResult? result;
  final ValueChanged<NarrativeEventMapCreationIntent> onRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final resultColor =
        result?.status == NarrativeEventMapCreationStatus.committed
            ? colors.success
            : colors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Créez un Event V2 ou ouvrez les Events déjà liés. La map et '
          'l’identité de la source sont reprises automatiquement.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        PokeMapButton(
          key: ValueKey('narrative-event-map-source-map-${map.id}'),
          onPressed: () => onRequest(
            NarrativeEventMapCreationIntent(
              source: NarrativeEventSourceRef.mapEnter(map.id),
              humanName: 'Entrée dans ${map.name}',
            ),
          ),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.map),
          child: Text('Entrée dans ${map.name}'),
        ),
        if (selectedEntity != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-source-entity-${selectedEntity!.id}',
            ),
            onPressed: () => onRequest(
              NarrativeEventMapCreationIntent(
                source: NarrativeEventSourceRef.entityInteract(
                  map.id,
                  selectedEntity!.id,
                ),
                humanName:
                    'Interaction avec ${selectedEntity!.inspectorHeadline}',
              ),
            ),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.person_crop_circle),
            child: Text(
              'Interaction avec ${selectedEntity!.inspectorHeadline}',
            ),
          ),
        ],
        if (selectedTrigger != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-source-trigger-${selectedTrigger!.id}',
            ),
            onPressed: () => onRequest(
              NarrativeEventMapCreationIntent(
                source: NarrativeEventSourceRef.triggerEnter(
                  map.id,
                  selectedTrigger!.id,
                ),
                humanName: 'Entrée dans ${_triggerLabel(selectedTrigger!)}',
              ),
            ),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.square),
            child: Text('Entrée dans ${_triggerLabel(selectedTrigger!)}'),
          ),
        ],
        if (result != null) ...[
          const SizedBox(height: 10),
          Text(
            result!.message,
            style: TextStyle(
              color: resultColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingIntent extends StatelessWidget {
  const _PendingIntent({
    required this.state,
    required this.onCancel,
    required this.onConfirm,
  });

  final NarrativeEventMapBridgeState state;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = state.pendingIntent!;
    final isAdditional = state.isAdditionalEventRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAdditional) ...[
          Text(
            'Confirmer l’Event supplémentaire',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          intent.humanName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAdditional
              ? 'Un nouvel Event sera lié à cette même source. Les Events '
                  'déjà liés resteront inchangés.'
              : 'La source existante sera liée atomiquement. Aucun placement '
                  'de map ne sera créé ou déplacé.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (state.lastResult != null) ...[
          const SizedBox(height: 8),
          Text(
            state.lastResult!.message,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('narrative-event-map-bridge-cancel'),
                onPressed: state.isSubmitting ? null : onCancel,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('narrative-event-map-bridge-confirm'),
                onPressed: state.isSubmitting ? null : onConfirm,
                isLoading: state.isSubmitting,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.link),
                child: Text(
                  isAdditional
                      ? 'Créer l’Event supplémentaire'
                      : 'Créer ou ouvrir',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExistingLinks extends StatelessWidget {
  const _ExistingLinks({
    required this.state,
    required this.onSelect,
    required this.onCreateAdditional,
    required this.onBack,
  });

  final NarrativeEventMapBridgeState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateAdditional;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.lastResult?.message ?? 'Events liés à cette source',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < state.linkedEvents.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-existing-'
              '${state.linkedEvents[index].eventId}',
            ),
            onPressed: () => onSelect(state.linkedEvents[index].eventId),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            isSelected: state.selectedNarrativeEventV2Id ==
                state.linkedEvents[index].eventId,
            leading: const Icon(CupertinoIcons.arrow_right_circle),
            child: Text(state.linkedEvents[index].name),
          ),
        ],
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey(
            'narrative-event-map-existing-create-additional',
          ),
          onPressed: onCreateAdditional,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.add_circled),
          child: const Text('Créer un Event supplémentaire'),
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-existing-back'),
          onPressed: onBack,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.chevron_left),
          child: const Text('Retour aux sources'),
        ),
      ],
    );
  }
}

MapEntity? _selectedEntity(MapData map, String? entityId) {
  if (entityId == null) return null;
  for (final entity in map.entities) {
    if (entity.id == entityId && entity.kind != MapEntityKind.spawn) {
      return entity;
    }
  }
  return null;
}

MapTrigger? _selectedTrigger(MapData map, String? triggerId) {
  if (triggerId == null) return null;
  for (final trigger in map.triggers) {
    if (trigger.id == triggerId &&
        (trigger.type == TriggerType.event ||
            trigger.type == TriggerType.custom)) {
      return trigger;
    }
  }
  return null;
}

String _triggerLabel(MapTrigger trigger) {
  final name = trigger.name.trim();
  return name.isEmpty ? trigger.id : name;
}
```

### 22.15 `packages/map_editor/test/narrative_event_map_creation_bridge_test.dart`

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000201';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000202';
const _eventC = 'evt_019abcde-0000-7000-8000-000000000203';
const _createdEvent = 'evt_019abcde-0000-7000-8000-000000000299';

void main() {
  group('NS-EVENT-V2-23 atomic map creation intent', () {
    test('carries one source ref and a human name only', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );

      final intent = NarrativeEventMapCreationIntent(
        source: source,
        humanName: 'Parler au rival',
      );

      expect(intent.source, source);
      expect(intent.humanName, 'Parler au rival');
      expect(intent.toString(), isNot(contains('layerId')));
      expect(intent.toString(), isNot(contains('coordinate')));
    });

    test('rejects a non-map outcome source', () {
      expect(
        () => NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_a',
              outcomeId: 'done',
            ),
          ),
          humanName: 'Résultat de scène',
        ),
        throwsArgumentError,
      );
    });
  });

  group('NS-EVENT-V2-23 create/open use case', () {
    for (final sourceCase in <(String, NarrativeEventSourceRef)>[
      (
        'entity',
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      ),
      (
        'trigger',
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      ),
      ('map', NarrativeEventSourceRef.mapEnter('map_a')),
    ]) {
      test('creates one source-prefilled draft from ${sourceCase.$1}',
          () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();
        final useCase = _useCase(gateway);

        final result = await useCase(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: sourceCase.$2,
            humanName: 'Event ${sourceCase.$1}',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(result.status, NarrativeEventMapCreationStatus.committed);
        expect(result.eventId, _createdEvent);
        expect(result.nextRegistry, gateway.requests.single.nextRegistry);
        expect(gateway.requests, hasLength(1));
        final created = result.nextRegistry!.records.single.draftOrNull!;
        expect(created.source, sourceCase.$2);
        expect(created.name, 'Event ${sourceCase.$1}');
      });
    }

    test('finds exact links in draft, enabled and disabled configured records',
        () async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final registry = persistenceRegistry(records: [
        _draft(_eventB, source: source, order: 20),
        _configured(_eventC, source: source, enabled: false, order: 30),
        _configured(_eventA, source: source, enabled: true, order: 10),
      ]);
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: _sourceMap(),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: source,
          humanName: 'Ne doit pas être créé',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventMapCreationStatus.existingLinks);
      expect(
        result.linkedEvents.map((event) => event.eventId),
        [_eventA, _eventB, _eventC],
      );
      expect(
        result.linkedEvents.map((event) => event.enabled),
        [true, null, false],
      );
      expect(gateway.requests, isEmpty);
    });

    test('multiple links are deterministic and never trigger a write',
        () async {
      final source = NarrativeEventSourceRef.triggerEnter(
        'map_a',
        'trigger_a',
      );
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(records: [
          _configured(_eventC, source: source, enabled: false, order: 2),
          _draft(_eventB, source: source, order: 1),
          _configured(_eventA, source: source, enabled: true, order: 1),
        ]),
        map: _sourceMap(),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: source,
          humanName: 'Zone du rival',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.linkedEvents.map((event) => event.eventId),
        [_eventA, _eventB, _eventC],
      );
      expect(gateway.persistCalls, 0);
    });

    test('explicit additional-event opt-in creates exactly one new link',
        () async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final registry = persistenceRegistry(records: [
        _draft(_eventA, source: source, order: 0),
        _configured(_eventB, source: source, enabled: false, order: 1),
      ]);
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: _sourceMap(),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: source,
          humanName: 'Rencontre alternative',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
        allowAdditionalEvent: true,
      );

      expect(result.status, NarrativeEventMapCreationStatus.committed);
      expect(result.eventId, _createdEvent);
      expect(gateway.persistCalls, 1);
      expect(gateway.requests, hasLength(1));
      expect(result.nextRegistry!.records, hasLength(3));
      final created = result.nextRegistry!.records
          .singleWhere((record) => record.id == _createdEvent)
          .draftOrNull!;
      expect(created.source, source);
      expect(created.name, 'Rencontre alternative');
    });

    test('additional-event opt-in still obeys dirty gates before preparation',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      var prepareCalls = 0;
      final gateway = _RecordingGateway();
      final useCase = CreateNarrativeEventFromMapSourceUseCase(
        persistenceGateway: gateway,
        prepareSession: (path) async {
          prepareCalls++;
          return fixture.session;
        },
      );

      final result = await useCase(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée supplémentaire',
        ),
        mapDirty: true,
        projectDirty: false,
        saving: false,
        allowAdditionalEvent: true,
      );

      expect(result.status, NarrativeEventMapCreationStatus.blocked);
      expect(prepareCalls, 0);
      expect(gateway.persistCalls, 0);
    });

    for (final dirtyCase in <(String, bool, bool, bool)>[
      ('map dirty', true, false, false),
      ('project dirty', false, true, false),
      ('saving', false, false, true),
    ]) {
      test('${dirtyCase.$1} blocks before session preparation and write',
          () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        var prepareCalls = 0;
        final gateway = _RecordingGateway();
        final useCase = CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (path) async {
            prepareCalls++;
            return fixture.session;
          },
          eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
            rawUuidFactory: () => _createdEvent.substring(4),
          ),
          operationIdFactory: () => 'v2_23_dirty_guard',
        );

        final result = await useCase(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée map',
          ),
          mapDirty: dirtyCase.$2,
          projectDirty: dirtyCase.$3,
          saving: dirtyCase.$4,
        );

        expect(result.status, NarrativeEventMapCreationStatus.blocked);
        expect(prepareCalls, 0);
        expect(gateway.persistCalls, 0);
      });
    }

    test('stale persistence result is propagated without duplicate creation',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        result: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Projet modifié.',
        ),
      );

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée map',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventMapCreationStatus.persistenceRejected,
      );
      expect(result.persistenceResult?.status,
          NarrativeEventRegistryPersistenceStatus.staleRevision);
      expect(gateway.persistCalls, 1);
      expect(gateway.requests, hasLength(1));
      expect(gateway.requests.single.nextRegistry.records, hasLength(1));
    });

    for (final rejectedStatus in [
      NarrativeEventRegistryPersistenceStatus.recoveryRequired,
      NarrativeEventRegistryPersistenceStatus.rejected,
    ]) {
      test('${rejectedStatus.name} is propagated without retry', () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway(
          result: NarrativeEventRegistryPersistenceResult(
            status: rejectedStatus,
            code: rejectedStatus.name,
            message: 'Writer rejected the request.',
          ),
        );

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée map',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventMapCreationStatus.persistenceRejected,
        );
        expect(result.persistenceResult?.status, rejectedStatus);
        expect(gateway.persistCalls, 1);
      });
    }

    test('recovered persistence outcome returns the committed registry',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        result: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recovered,
          code: 'recovered',
          message: 'Recovered committed write.',
        ),
      );

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée map',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventMapCreationStatus.committed);
      expect(result.persistenceResult?.status,
          NarrativeEventRegistryPersistenceStatus.recovered);
      expect(result.nextRegistry, gateway.requests.single.nextRegistry);
      expect(gateway.persistCalls, 1);
    });

    test('authoring rejection is returned without a persistence request',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'missing_entity',
          ),
          humanName: 'Source absente',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventMapCreationStatus.authoringRejected,
      );
      expect(result.code, 'sourceMissing');
      expect(gateway.persistCalls, 0);
    });

    test('gateway exception becomes a typed human persistence rejection',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _ThrowingGateway();

      final result = await _useCase(gateway)(
        projectPath: fixture.projectPath,
        intent: NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Erreur d’écriture',
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventMapCreationStatus.persistenceRejected,
      );
      expect(result.code, 'persistenceException');
      expect(result.message, contains('n’a pas pu être enregistré'));
      expect(result.message, isNot(contains('StateError')));
      expect(gateway.persistCalls, 1);
    });
  });

  group('NS-EVENT-V2-23 editor and feature state integration', () {
    test('project switch before confirm resets the bridge and writes nowhere',
        () async {
      final fixtureA = await createPersistenceFixture(map: _sourceMap());
      final fixtureB = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixtureA.dispose);
      addTearDown(fixtureB.dispose);
      final gateway = _RecordingGateway();
      final container = ProviderContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          _useCase(gateway),
        ),
      ]);
      addTearDown(container.dispose);
      final editor = container.read(editorNotifierProvider.notifier);
      editor.state = EditorState(
        projectRootPath: fixtureA.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      final sessionToken = controller.state.projectSessionToken;
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée A',
        ),
        projectRootPath: fixtureA.root.path,
      );

      editor.state = EditorState(
        projectRootPath: fixtureB.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );

      expect(controller.state.projectRootPath, fixtureB.root.path);
      expect(controller.state.projectSessionToken, greaterThan(sessionToken));
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.linkedEvents, isEmpty);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.recovery, isNull);

      final result = await controller.confirm(
        projectRootPath: fixtureB.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
      );

      expect(result, isNull);
      expect(gateway.persistCalls, 0);
    });

    test('late project A response never mutates project B bridge state',
        () async {
      final fixtureA = await createPersistenceFixture(map: _sourceMap());
      final fixtureB = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixtureA.dispose);
      addTearDown(fixtureB.dispose);
      final prepared = Completer<NarrativeEventAuthoringSession>();
      final gateway = _RecordingGateway();
      final useCase = CreateNarrativeEventFromMapSourceUseCase(
        persistenceGateway: gateway,
        prepareSession: (_) => prepared.future,
        eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
          rawUuidFactory: () => _createdEvent.substring(4),
        ),
        operationIdFactory: () => 'v2_23_late_project_a',
      );
      final container = ProviderContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          useCase,
        ),
      ]);
      addTearDown(container.dispose);
      final editor = container.read(editorNotifierProvider.notifier);
      editor.state = EditorState(
        projectRootPath: fixtureA.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          humanName: 'Réponse tardive A',
        ),
        projectRootPath: fixtureA.root.path,
      );

      final confirmation = controller.confirm(
        projectRootPath: fixtureA.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isSubmitting, isTrue);

      editor.state = EditorState(
        projectRootPath: fixtureB.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );
      prepared.complete(fixtureA.session);
      await confirmation;

      expect(gateway.persistCalls, 1);
      expect(gateway.requests.single.projectPath, fixtureA.projectPath);
      expect(controller.state.projectRootPath, fixtureB.root.path);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.lastResult, isNull);
      expect(controller.state.recovery, isNull);
      expect(editor.state.projectRootPath, fixtureB.root.path);
      expect(editor.state.project!.eventRegistry, isNull);
    });

    test(
        'same-root replacement after a durable V2-23 commit enters explicit recovery',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _BlockingGateway();
      final container = ProviderContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          _useCase(gateway),
        ),
      ]);
      addTearDown(container.dispose);
      final editor = container.read(editorNotifierProvider.notifier);
      final project = _project();
      editor.state = EditorState(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _sourceMap(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          humanName: 'Commit tardif même projet',
        ),
        projectRootPath: fixture.root.path,
      );

      final confirmation = controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
      );
      while (gateway.persistCalls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      editor.state = editor.state.copyWith(
        project: project.copyWith(name: 'Projet rechargé au même chemin'),
      );
      gateway.completeCommitted();
      final result = await confirmation;

      expect(
        result?.status,
        NarrativeEventMapCreationStatus.committedOutOfSync,
      );
      expect(gateway.persistCalls, 1);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.lastResult, same(result));
      expect(controller.state.recovery?.result, same(result));
      expect(
        controller.state.recovery?.projectRootPath,
        fixture.root.path,
      );
      expect(editor.state.project?.name, 'Projet rechargé au même chemin');
      expect(editor.state.project?.eventRegistry, isNull);
    });

    test('repository providers expose the exact same file repository instance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectRepository = container.read(projectRepositoryProvider);
      final registryGateway =
          container.read(narrativeEventRegistryPersistenceGatewayProvider);

      expect(identical(projectRepository, registryGateway), isTrue);
    });

    test('cancel clears pending intent without preparing or writing', () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      var prepareCalls = 0;
      final gateway = _RecordingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (path) async {
            prepareCalls++;
            return fixture.session;
          },
        ),
        projectRootPath: fixture.root.path,
      );
      addTearDown(controller.dispose);

      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée map',
        ),
        projectRootPath: fixture.root.path,
      );
      controller.cancel();

      expect(controller.state.pendingIntent, isNull);
      expect(prepareCalls, 0);
      expect(gateway.persistCalls, 0);
    });

    test('committed controller flow updates registry and V2 selection only',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project(),
        activeMap: _sourceMap(),
        selectedMapEventId: 'legacy_event',
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: _useCase(gateway),
        projectRootPath: fixture.root.path,
      );
      addTearDown(controller.dispose);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          humanName: 'Parler au rival',
        ),
        projectRootPath: fixture.root.path,
      );

      final result = await controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
      );

      expect(result?.status, NarrativeEventMapCreationStatus.committed);
      expect(notifier.state.project!.eventRegistry, result!.nextRegistry);
      expect(notifier.state.selectedMapEventId, 'legacy_event');
      expect(controller.state.selectedNarrativeEventV2Id, _createdEvent);
      expect(controller.state.pendingIntent, isNull);
      expect(gateway.persistCalls, 1);
    });

    test('persisted registry replacement preserves all map document state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeMap = _sourceMap();
      const undoSnapshot = MapHistorySnapshot(
          map: MapData(
        id: 'map_a',
        name: 'Before',
        size: GridSize(width: 8, height: 6),
      ));
      final nextRegistry = persistenceRegistry(records: [
        _draft(
          _eventA,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
        ),
      ]);
      notifier.state = EditorState(
        projectRootPath: '/tmp/project_a',
        project: _project(),
        activeMap: beforeMap,
        activeMapPath: '/tmp/maps/map_a.json',
        activeLayerId: 'objects',
        selectedEntityId: 'entity_a',
        selectedMapEventId: 'legacy_event',
        selectedTriggerId: 'trigger_a',
        mapUndoStack: const [undoSnapshot],
        mapRedoStack: const [undoSnapshot],
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: false,
      );

      final applied = notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: '/tmp/project_a',
        expectedPreviousRegistry: null,
        nextRegistry: nextRegistry,
      );
      final after = container.read(editorNotifierProvider);

      expect(applied, isTrue);
      expect(after.project!.eventRegistry, nextRegistry);
      expect(identical(after.activeMap, beforeMap), isTrue);
      expect(after.activeMapPath, '/tmp/maps/map_a.json');
      expect(after.activeLayerId, 'objects');
      expect(after.selectedEntityId, 'entity_a');
      expect(after.selectedMapEventId, 'legacy_event');
      expect(after.selectedTriggerId, 'trigger_a');
      expect(after.mapUndoStack, const [undoSnapshot]);
      expect(after.mapRedoStack, const [undoSnapshot]);
      expect(after.isDirty, isTrue);
      expect(after.isProjectDirty, isFalse);
    });

    test('same-project registry merge preserves unrelated dirty changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final previousRegistry = persistenceRegistry(records: [
        _draft(
          _eventA,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
        ),
      ]);
      final nextRegistry = persistenceRegistry(records: [
        _draft(
          _eventA,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
        ),
        _draft(
          _eventB,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 1,
        ),
      ]);
      final locallyEditedProject = _project().copyWith(
        name: 'Nom modifié localement',
        globalProperties: const {'unrelated': 'preserved'},
        eventRegistry: previousRegistry,
      );
      notifier.state = EditorState(
        projectRootPath: '/tmp/project_a',
        project: locallyEditedProject,
        activeMap: _sourceMap(),
        isProjectDirty: true,
      );

      final applied = notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: '/tmp/project_a',
        expectedPreviousRegistry: previousRegistry,
        nextRegistry: nextRegistry,
      );

      expect(applied, isTrue);
      expect(notifier.state.project!.eventRegistry, nextRegistry);
      expect(notifier.state.project!.name, 'Nom modifié localement');
      expect(
        notifier.state.project!.globalProperties,
        const {'unrelated': 'preserved'},
      );
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('registry merge rejects another project root or concurrent registry',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final previousRegistry = persistenceRegistry(records: []);
      final concurrentRegistry = persistenceRegistry(records: [
        _draft(
          _eventA,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
        ),
      ]);
      final nextRegistry = persistenceRegistry(records: [
        _draft(
          _eventB,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
        ),
      ]);
      final project = _project().copyWith(eventRegistry: concurrentRegistry);
      notifier.state = EditorState(
        projectRootPath: '/tmp/project_a',
        project: project,
        isProjectDirty: true,
      );

      expect(
        notifier.applyPersistedNarrativeEventRegistry(
          expectedProjectRootPath: '/tmp/project_b',
          expectedPreviousRegistry: concurrentRegistry,
          nextRegistry: nextRegistry,
        ),
        isFalse,
      );
      expect(notifier.state.project, project);
      expect(notifier.state.isProjectDirty, isTrue);

      expect(
        notifier.applyPersistedNarrativeEventRegistry(
          expectedProjectRootPath: '/tmp/project_a',
          expectedPreviousRegistry: previousRegistry,
          nextRegistry: nextRegistry,
        ),
        isFalse,
      );
      expect(notifier.state.project, project);
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('failed memory adoption becomes non-repeatable out-of-sync recovery',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: _useCase(gateway),
        projectRootPath: fixture.root.path,
      );
      addTearDown(controller.dispose);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Commit désynchronisé',
        ),
        projectRootPath: fixture.root.path,
      );

      final result = await controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: _rejectRegistryApply,
      );

      expect(
        result?.status,
        NarrativeEventMapCreationStatus.committedOutOfSync,
      );
      expect(controller.state.lastResult?.status,
          NarrativeEventMapCreationStatus.committedOutOfSync);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.recovery, isNotNull);
      expect(
        controller.state.recovery!.projectRootPath,
        fixture.root.path,
      );
      expect(gateway.persistCalls, 1);

      final repeated = await controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: _rejectRegistryApply,
      );
      expect(repeated, isNull);
      expect(gateway.persistCalls, 1);

      expect(
        controller.finishRecoveryReload(
          projectRootPath: fixture.root.path,
          loadedRegistry: persistenceRegistry(records: []),
        ),
        isFalse,
      );
      expect(controller.state.recovery, isNotNull);
      expect(
        controller.finishRecoveryReload(
          projectRootPath: fixture.root.path,
          loadedRegistry: result!.nextRegistry,
        ),
        isTrue,
      );
      expect(controller.state.recovery, isNull);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.lastResult, isNull);
    });

    test('memory adoption exception becomes out-of-sync and releases submit',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: _useCase(gateway),
        projectRootPath: fixture.root.path,
      );
      addTearDown(controller.dispose);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Adoption impossible',
        ),
        projectRootPath: fixture.root.path,
      );

      final result = await controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: _throwingRegistryApply,
      );

      expect(
          result?.status, NarrativeEventMapCreationStatus.committedOutOfSync);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.recovery, isNotNull);
      expect(gateway.persistCalls, 1);
    });

    test('project binding clears an out-of-sync recovery and stale selection',
        () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: _useCase(gateway),
        projectRootPath: fixture.root.path,
      );
      addTearDown(controller.dispose);
      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Recovery A',
        ),
        projectRootPath: fixture.root.path,
      );
      await controller.confirm(
        projectRootPath: fixture.root.path,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: _rejectRegistryApply,
      );
      expect(controller.state.recovery, isNotNull);

      controller.bindProjectRootPath('/tmp/project_b');

      expect(controller.state.projectRootPath, '/tmp/project_b');
      expect(controller.state.recovery, isNull);
      expect(controller.state.pendingIntent, isNull);
      expect(controller.state.linkedEvents, isEmpty);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.lastResult, isNull);
      expect(gateway.persistCalls, 1);
    });
  });
}

bool _rejectRegistryApply({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
}) {
  return false;
}

bool _throwingRegistryApply({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
}) {
  throw StateError('raw apply failure');
}

CreateNarrativeEventFromMapSourceUseCase _useCase(
  NarrativeEventRegistryPersistenceGateway gateway,
) {
  return CreateNarrativeEventFromMapSourceUseCase(
    persistenceGateway: gateway,
    eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
      rawUuidFactory: () => _createdEvent.substring(4),
    ),
    operationIdFactory: () => 'v2_23_create',
  );
}

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({NarrativeEventRegistryPersistenceResult? result})
      : result = result ??
            NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus.committed,
              code: 'committed',
              message: 'Committed.',
            );

  final NarrativeEventRegistryPersistenceResult result;
  final List<NarrativeEventRegistryWriteRequest> requests = [];
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    requests.add(request);
    return result;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    throw UnimplementedError();
  }
}

final class _ThrowingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('raw gateway failure');
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _BlockingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;
  final _completion = Completer<NarrativeEventRegistryPersistenceResult>();

  void completeCommitted() {
    _completion.complete(
      NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.committed,
        code: 'committed',
        message: 'Committed.',
      ),
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    return _completion.future;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

NarrativeEventRecord _draft(
  String id, {
  required NarrativeEventSourceRef source,
  required int order,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: 'Draft $id',
      source: source,
      conditions: const [],
      priority: 0,
      order: order,
    ),
  );
}

NarrativeEventRecord _configured(
  String id, {
  required NarrativeEventSourceRef source,
  required bool enabled,
  required int order,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: 'Configured $id',
      source: source,
      conditions: const [],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: order,
    ),
    enabled: enabled,
  );
}

MapData _sourceMap() => const MapData(
      id: 'map_a',
      name: 'Port Selbrume',
      size: GridSize(width: 8, height: 6),
      layers: [ObjectLayer(id: 'objects', name: 'Objets')],
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Rival',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'trigger_a',
          name: 'Zone du port',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 4, y: 3),
            size: GridSize(width: 2, height: 1),
          ),
        ),
      ],
    );

ProjectManifest _project() => ProjectManifest(
      name: 'Bridge project',
      maps: const [
        ProjectMapEntry(
          id: 'map_a',
          name: 'Port Selbrume',
          relativePath: 'maps/map_a.json',
        ),
      ],
      tilesets: const [],
      scenes: [persistenceScene()],
    );
```

### 22.16 `packages/map_editor/test/narrative_event_source_dependency_guard_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/services/narrative_event_source_dependency_guard.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

const _mapEvent = 'evt_019abcde-0000-7000-8000-000000000301';
const _entityEvent = 'evt_019abcde-0000-7000-8000-000000000302';
const _triggerEvent = 'evt_019abcde-0000-7000-8000-000000000303';

void main() {
  group('NS-EVENT-V2-23 source dependency guard', () {
    const guard = NarrativeEventSourceDependencyGuard();
    final registry = _registry();

    test('blocks linked map rename and delete across every record state', () {
      final rename = guard.inspectMapRename(
        registry: registry,
        mapId: 'map_a',
        newMapId: 'map_b',
      );
      final delete = guard.inspectMapDelete(
        registry: registry,
        mapId: 'map_a',
      );

      expect(rename.isAllowed, isFalse);
      expect(delete.isAllowed, isFalse);
      expect(
        rename.linkedEventIds,
        [_mapEvent, _entityEvent, _triggerEvent],
      );
      expect(delete.linkedEventIds, rename.linkedEventIds);
    });

    test('blocks linked entity identity breakage and transition to spawn', () {
      const current = MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      );

      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(id: 'entity_b'),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(kind: MapEntityKind.spawn),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'map_a',
              entityId: 'entity_a',
            )
            .isAllowed,
        isFalse,
      );
    });

    test('permits linked entity non-identity edits and interactable kinds', () {
      const current = MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      );
      final edited = current.copyWith(
        name: 'Rival du port',
        kind: MapEntityKind.sign,
        pos: const GridPos(x: 3, y: 2),
        size: const GridSize(width: 2, height: 1),
        properties: const {'mood': 'angry'},
      );

      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: edited,
            )
            .isAllowed,
        isTrue,
      );
    });

    test('blocks linked trigger identity/delete and event to system transition',
        () {
      const current = MapTrigger(
        id: 'trigger_a',
        name: 'Zone port',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(id: 'trigger_b'),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(type: TriggerType.camera),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'map_a',
              triggerId: 'trigger_a',
            )
            .isAllowed,
        isFalse,
      );
    });

    test('permits event/custom transitions and non-identity trigger edits', () {
      const current = MapTrigger(
        id: 'trigger_a',
        name: 'Zone port',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );
      final edited = current.copyWith(
        name: 'Zone rival',
        type: TriggerType.custom,
        area: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 2),
        ),
        properties: const {'front': 'north'},
      );

      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: edited,
            )
            .isAllowed,
        isTrue,
      );
    });

    test('unlinked sources keep the existing behavior', () {
      expect(
        guard
            .inspectMapDelete(registry: registry, mapId: 'map_unlinked')
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'map_a',
              entityId: 'entity_unlinked',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'map_a',
              triggerId: 'trigger_unlinked',
            )
            .isAllowed,
        isTrue,
      );
    });

    test('map transition blocks a resolved entity becoming absent or spawn',
        () {
      final current = _map();
      final absent = current.copyWith(entities: const []);
      final spawn = current.copyWith(
        entities: [
          current.entities.single.copyWith(kind: MapEntityKind.spawn),
        ],
      );

      for (final candidate in [absent, spawn]) {
        final decision = guard.inspectMapTransition(
          registry: registry,
          current: current,
          candidate: candidate,
          operation: 'restauration de l’historique',
        );

        expect(decision.isAllowed, isFalse);
        expect(decision.linkedEventIds, [_entityEvent]);
      }
    });

    test(
        'map transition blocks a resolved trigger becoming absent or incompatible',
        () {
      final current = _map();
      final absent = current.copyWith(triggers: const []);
      final system = current.copyWith(
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.camera),
        ],
      );

      for (final candidate in [absent, system]) {
        final decision = guard.inspectMapTransition(
          registry: registry,
          current: current,
          candidate: candidate,
          operation: 'restauration de l’historique',
        );

        expect(decision.isAllowed, isFalse);
        expect(decision.linkedEventIds, [_triggerEvent]);
      }
    });

    test('map transition permits non-identity edits and event/custom changes',
        () {
      final current = _map();
      final candidate = current.copyWith(
        name: 'Map A renommée visuellement',
        entities: [
          current.entities.single.copyWith(
            name: 'Rival du port',
            pos: const GridPos(x: 3, y: 2),
          ),
        ],
        triggers: [
          current.triggers.single.copyWith(
            name: 'Zone rival',
            type: TriggerType.custom,
          ),
        ],
      );

      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: current,
              candidate: candidate,
              operation: 'undo',
            )
            .isAllowed,
        isTrue,
      );
    });

    test('map transition permits an already broken reference and its repair',
        () {
      final broken = _map().copyWith(entities: const []);
      final stillBroken = broken.copyWith(name: 'Modification sans rapport');

      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: broken,
              candidate: stillBroken,
              operation: 'undo',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: broken,
              candidate: _map(),
              operation: 'redo',
            )
            .isAllowed,
        isTrue,
      );
    });
  });

  group('NS-EVENT-V2-23 notifier guard integration', () {
    test('blocks linked entity rename, spawn transition and delete', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: map,
        selectedEntityId: 'entity_a',
      );

      notifier.updateEntity(entityId: 'entity_a', id: 'entity_b');
      expect(notifier.state.activeMap, map);
      expect(notifier.state.errorMessage, contains(_entityEvent));

      notifier.updateEntity(
        entityId: 'entity_a',
        kind: MapEntityKind.spawn,
      );
      expect(notifier.state.activeMap, map);

      notifier.deleteEntity('entity_a');
      expect(notifier.state.activeMap, map);
    });

    test('blocks linked trigger identity/system transition and delete', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: map,
        selectedTriggerId: 'trigger_a',
      );

      notifier.updateTrigger(triggerId: 'trigger_a', id: 'trigger_b');
      expect(notifier.state.activeMap, map);
      expect(notifier.state.errorMessage, contains(_triggerEvent));

      notifier.updateTrigger(
        triggerId: 'trigger_a',
        type: TriggerType.camera,
      );
      expect(notifier.state.activeMap, map);

      notifier.deleteTrigger('trigger_a');
      expect(notifier.state.activeMap, map);
    });

    test('allows linked non-identity edits and event to custom transition', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: _map(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      notifier.updateEntity(
        entityId: 'entity_a',
        name: 'Rival du port',
        pos: const GridPos(x: 3, y: 2),
        properties: const {'mood': 'angry'},
      );
      notifier.updateTrigger(
        triggerId: 'trigger_a',
        name: 'Zone rival',
        type: TriggerType.custom,
      );

      expect(
        notifier.state.activeMap!.entities.single.name,
        'Rival du port',
      );
      expect(
          notifier.state.activeMap!.triggers.single.type, TriggerType.custom);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, isNull);
    });

    test('blocks linked map rename/delete before repository operations',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final project = _project(registry: _registry());
      notifier.state = EditorState(
        projectRootPath: '/tmp/v2_23_guard',
        project: project,
        activeMap: _map(),
      );

      await notifier.renameMap('map_a', 'map_b');
      expect(notifier.state.project, project);
      expect(notifier.state.errorMessage, contains(_mapEvent));

      await notifier.deleteMap('map_a');
      expect(notifier.state.project, project);
    });

    test('undo keeps map and history unchanged when an entity would disappear',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(entities: const []);
      final undoStack = [MapHistorySnapshot(map: candidate)];
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedEntityId: 'entity_a',
        mapUndoStack: undoStack,
        canUndoMap: true,
        statusMessage: 'Prêt',
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapUndoStack, undoStack);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.canUndoMap, isTrue);
      expect(notifier.state.statusMessage, 'Prêt');
      expect(notifier.state.errorMessage, contains(_entityEvent));
    });

    test('blocked undo leaves an active stroke and its history untouched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(entities: const []);
      final strokeStart = MapHistorySnapshot(map: candidate);
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedEntityId: 'entity_a',
        mapStrokeStart: strokeStart,
        canUndoMap: false,
        statusMessage: 'Trait en cours',
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapStrokeStart, strokeStart);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.canUndoMap, isFalse);
      expect(notifier.state.statusMessage, 'Trait en cours');
      expect(notifier.state.errorMessage, contains(_entityEvent));
    });

    test('redo keeps map and history unchanged when a trigger becomes system',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.camera),
        ],
      );
      final redoStack = [MapHistorySnapshot(map: candidate)];
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedTriggerId: 'trigger_a',
        mapRedoStack: redoStack,
        canRedoMap: true,
        statusMessage: 'Prêt',
      );

      notifier.redoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, redoStack);
      expect(notifier.state.canRedoMap, isTrue);
      expect(notifier.state.statusMessage, 'Prêt');
      expect(notifier.state.errorMessage, contains(_triggerEvent));
    });

    test('undo applies non-identity source edits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(
        entities: [
          current.entities.single.copyWith(name: 'Rival du port'),
        ],
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.custom),
        ],
      );
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        mapUndoStack: [MapHistorySnapshot(map: candidate)],
        canUndoMap: true,
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, candidate);
      expect(notifier.state.statusMessage, 'Undo');
      expect(notifier.state.errorMessage, isNull);
    });
  });
}

NarrativeEventRegistry _registry() => NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        _record(
          id: _mapEvent,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
          configured: false,
        ),
        _record(
          id: _entityEvent,
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          order: 1,
          configured: true,
          enabled: false,
        ),
        _record(
          id: _triggerEvent,
          source: NarrativeEventSourceRef.triggerEnter(
            'map_a',
            'trigger_a',
          ),
          order: 2,
          configured: true,
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    );

NarrativeEventRecord _record({
  required String id,
  required NarrativeEventSourceRef source,
  required int order,
  required bool configured,
  bool enabled = false,
}) {
  if (!configured) {
    return NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: id,
        source: source,
        conditions: const [],
        priority: 0,
        order: order,
      ),
    );
  }
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: order,
    ),
    enabled: enabled,
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 8, height: 6),
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Rival',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'trigger_a',
          name: 'Zone port',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );

ProjectManifest _project({NarrativeEventRegistry? registry}) => ProjectManifest(
      name: 'Guard project',
      maps: const [
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
      ],
      tilesets: const [],
      eventRegistry: registry,
    );
```

### 22.17 `packages/map_editor/test/ui/panels/narrative_event_map_bridge_panel_test.dart`

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_event_map_bridge_panel.dart';

import '../../support/event_registry_persistence_fixtures.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000401';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000402';
const _additionalEvent = 'evt_019abcde-0000-7000-8000-000000000499';

void main() {
  group('NS-EVENT-V2-23 Map Inspector bridge panel', () {
    testWidgets('offers map, selected eligible entity and trigger actions',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
        selectedMapEventId: 'legacy_event',
      );

      await _pumpPanel(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
        findsOneWidget,
      );
      expect(find.byType(PokeMapPanel), findsOneWidget);
      expect(find.byType(PokeMapButton), findsNWidgets(3));

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .pendingIntent
            ?.source,
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      expect(
        container.read(editorNotifierProvider).selectedMapEventId,
        'legacy_event',
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-cancel')),
      );
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).pendingIntent,
        isNull,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .pendingIntent
            ?.source,
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
    });

    testWidgets('hides spawn and system trigger actions', (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(
          entityKind: MapEntityKind.spawn,
          triggerType: TriggerType.camera,
        ),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      await _pumpPanel(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
        findsNothing,
      );
    });

    testWidgets('contains no map, layer, coordinate, or raw ID form input',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      await _pumpPanel(tester, container);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(CupertinoTextField), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
      expect(find.textContaining('Carte cible'), findsNothing);
      expect(find.textContaining('ID technique'), findsNothing);
    });

    testWidgets('lists every existing link without writing a duplicate',
        (tester) async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: _existingRegistry(source),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final beforeBytes = (await tester.runAsync(
        () => File(fixture.projectPath).readAsBytes(),
      ))!;
      final gateway = _NeverWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
          ),
        ),
      ]);
      final project = _project().copyWith(
        eventRegistry: _existingRegistry(source),
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedMapEventId: 'legacy_event',
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).isSubmitting,
        isFalse,
      );

      expect(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventA')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventB')),
        findsOneWidget,
      );
      expect(gateway.persistCalls, 0);
      expect(
        await tester.runAsync(
          () => File(fixture.projectPath).readAsBytes(),
        ),
        beforeBytes,
      );
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        isNull,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventB')),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        _eventB,
      );
      expect(
        container.read(editorNotifierProvider).selectedMapEventId,
        'legacy_event',
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-existing-back')),
      );
      await tester.pump();
      expect(gateway.persistCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'additional Event action requires explicit no-code confirmation and writes once',
        (tester) async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: _existingRegistry(source),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
            eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
              rawUuidFactory: () => _additionalEvent.substring(4),
            ),
            operationIdFactory: () => 'v2_23_additional',
          ),
        ),
      ]);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project().copyWith(eventRegistry: _existingRegistry(source)),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(gateway.persistCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
        findsOneWidget,
      );
      expect(find.text('Créer un Event supplémentaire'), findsOneWidget);
      expect(find.textContaining(_eventA), findsNothing);
      expect(find.textContaining(_eventB), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
      );
      await tester.pump();
      expect(find.text('Confirmer l’Event supplémentaire'), findsOneWidget);
      expect(find.text('Créer l’Event supplémentaire'), findsOneWidget);
      expect(gateway.persistCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-cancel')),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
        findsOneWidget,
      );
      expect(gateway.persistCalls, 0);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(gateway.persistCalls, 1);
      expect(gateway.requests, hasLength(1));
      final created = gateway.requests.single.nextRegistry.records
          .singleWhere((record) => record.id == _additionalEvent)
          .draftOrNull!;
      expect(created.source, source);
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        _additionalEvent,
      );
    });

    testWidgets('out-of-sync recovery blocks reload while dirty and can cancel',
        (tester) async {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: persistenceRegistry(
            records: [],
            mode: EventSystemMode.dualRead,
          ),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
            eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
              rawUuidFactory: () => _additionalEvent.substring(4),
            ),
            operationIdFactory: () => 'v2_23_out_of_sync_cancel',
          ),
        ),
      ]);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project().copyWith(
          eventRegistry: _existingRegistry(source),
        ),
        activeMap: _sourceMap(),
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        container.read(narrativeEventMapBridgeControllerProvider).recovery,
        isNotNull,
      );
      expect(find.text('Recharger le projet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-recovery-reload')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-recovery-cancel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
        findsNothing,
      );

      notifier.state = notifier.state.copyWith(isDirty: true);
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(
        isDirty: false,
        isProjectDirty: true,
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(
        isProjectDirty: false,
        isSaving: true,
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(isSaving: false);
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-recovery-cancel')),
      );
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).recovery,
        isNull,
      );
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).pendingIntent,
        isNull,
      );
      expect(gateway.persistCalls, 1);
    });

    testWidgets('gateway exception restores actions with a human message',
        (tester) async {
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(map: _sourceMap()),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _ThrowingPanelGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
          ),
        ),
      ]);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        container.read(narrativeEventMapBridgeControllerProvider).isSubmitting,
        isFalse,
      );
      expect(find.textContaining('n’a pas pu être enregistré'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-bridge-confirm'),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(gateway.persistCalls, 1);
    });

    testWidgets('MapEvent inspector remains separate and visibly legacy',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(includeLegacyEvent: true),
        selectedMapEventId: 'legacy_event',
      );

      await _pump(
        tester,
        container,
        const SizedBox(width: 420, height: 900, child: MapInspectorPanel()),
      );

      expect(find.textContaining('Legacy'), findsWidgets);
      expect(find.text('Événements de carte'), findsOneWidget);
      expect(find.byType(NarrativeEventMapBridgePanel), findsOneWidget);
    });
  });
}

ProviderContainer _testContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  final keepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(() {
    keepAlive.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) {
  return _pump(
    tester,
    container,
    const SizedBox(
      width: 400,
      child: NarrativeEventMapBridgePanel(),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, innerChild) => PokeMapMacosCompatibilityBridge(
          child: innerChild ?? const SizedBox.shrink(),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() => ProjectManifest(
      name: 'Bridge panel project',
      maps: const [
        ProjectMapEntry(
          id: 'map_a',
          name: 'Port Selbrume',
          relativePath: 'maps/map_a.json',
        ),
      ],
      tilesets: const [],
      scenes: [persistenceScene()],
    );

MapData _sourceMap({
  MapEntityKind entityKind = MapEntityKind.npc,
  TriggerType triggerType = TriggerType.event,
  bool includeLegacyEvent = false,
}) {
  return MapData(
    id: 'map_a',
    name: 'Port Selbrume',
    size: const GridSize(width: 8, height: 6),
    layers: const [ObjectLayer(id: 'objects', name: 'Objets')],
    entities: [
      MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: entityKind,
        pos: const GridPos(x: 2, y: 2),
      ),
    ],
    triggers: [
      MapTrigger(
        id: 'trigger_a',
        name: 'Zone du port',
        type: triggerType,
        area: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
    events: includeLegacyEvent
        ? const [
            MapEventDefinition(
              id: 'legacy_event',
              title: 'Ancien Event',
              position: EventPosition(layerId: 'objects', x: 1, y: 1),
              pages: [MapEventPage(pageNumber: 0)],
            ),
          ]
        : const [],
  );
}

NarrativeEventRegistry _existingRegistry(NarrativeEventSourceRef source) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: [
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: _eventB,
          name: 'Deuxième lien',
          source: source,
          conditions: const [],
          priority: 0,
          order: 1,
        ),
      ),
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _eventA,
          name: 'Premier lien',
          source: source,
          conditions: const [],
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: false,
      ),
    ],
    legacyClaims: const [],
  );
}

final class _NeverWriteGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    throw StateError('An existing link must not be persisted.');
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _RecordingWriteGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final List<NarrativeEventRegistryWriteRequest> requests = [];
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    requests.add(request);
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.committed,
      code: 'committed',
      message: 'Committed.',
    );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _ThrowingPanelGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('raw widget gateway failure');
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
```

### 22.18 `packages/map_editor/test/event_map_navigation_controller_test.dart`

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000301';

void main() {
  group('NS-EVENT-V2-24 map navigation controller', () {
    test('same-map dirty view never reloads and returns to the exact Event',
        () async {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final project = _project(source: source);
      final map = _mapA();
      final controller = _controller();
      var snapshotReads = 0;
      var activations = 0;
      NarrativeEditorFocusTarget? appliedFocus;

      final result = await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: project,
        activeMap: map,
        mapDirty: true,
        loadMapSnapshot: (_) async {
          snapshotReads++;
          return null;
        },
        activateMapSnapshot: (_) {
          activations++;
          return true;
        },
        applyFocus: (focus) {
          appliedFocus = focus;
          return true;
        },
      );

      expect(result.status, NarrativeEventMapNavigationStatus.ready);
      expect(snapshotReads, 0);
      expect(activations, 0);
      expect(appliedFocus?.kind, NarrativeEditorFocusTargetKind.entity);
      expect(appliedFocus?.ownerId, 'entity_a');
      expect(controller.state.pendingReturn?.eventId, _eventId);
      expect(
        controller.state.pendingReturn?.groupContext,
        const NarrativeEventGroupContext.map('map_a'),
      );
      expect(controller.state.focusRequest?.cameraApplied, isFalse);
      expect(controller.state.focusRequest?.source, source);
      expect(
        controller.state.focusRequest?.mode,
        NarrativeEventMapNavigationMode.view,
      );

      String? selectedEvent;
      NarrativeEventGroupContext? selectedGroup;
      final returned = controller.returnToEvent(
        project: project,
        openExactEvent: ({required eventId, required groupContext}) {
          selectedEvent = eventId;
          selectedGroup = groupContext;
        },
      );

      expect(returned, isTrue);
      expect(selectedEvent, _eventId);
      expect(selectedGroup, const NarrativeEventGroupContext.map('map_a'));
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    test('cross-map dirty refusal happens before any snapshot read', () async {
      final controller = _controller();
      var snapshotReads = 0;
      var activations = 0;

      final result = await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        ),
        activeMap: _mapA(),
        mapDirty: true,
        loadMapSnapshot: (_) async {
          snapshotReads++;
          return _mapB();
        },
        activateMapSnapshot: (_) {
          activations++;
          return true;
        },
        applyFocus: (_) => true,
      );

      expect(result.status, NarrativeEventMapNavigationStatus.blockedDirtyMap);
      expect(snapshotReads, 0);
      expect(activations, 0);
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    test('missing and nonspatial sources never create navigation state',
        () async {
      final cases = <NarrativeEventSourceRef>[
        NarrativeEventSourceRef.entityInteract('map_a', 'missing_entity'),
        NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_a',
            outcomeId: 'done',
          ),
        ),
      ];

      for (final source in cases) {
        final controller = _controller();
        var snapshotReads = 0;
        final result = await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: source.kind == NarrativeEventSourceKind.outcomeReceived
              ? const NarrativeEventGroupContext.global()
              : const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(source: source),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async {
            snapshotReads++;
            return null;
          },
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );

        expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
        expect(snapshotReads, 0);
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);
      }
    });

    test('clean cross-map navigation reads and activates one snapshot',
        () async {
      final controller = _controller();
      final snapshot = _mapB();
      var reads = 0;
      var activations = 0;
      MapData? activated;
      NarrativeEditorFocusTarget? focused;

      final result = await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        ),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async {
          reads++;
          return snapshot;
        },
        activateMapSnapshot: (map) {
          activations++;
          activated = map;
          return true;
        },
        applyFocus: (focus) {
          focused = focus;
          return true;
        },
      );

      expect(result.status, NarrativeEventMapNavigationStatus.ready);
      expect(reads, 1);
      expect(activations, 1);
      expect(activated, same(snapshot));
      expect(focused?.kind, NarrativeEditorFocusTargetKind.trigger);
      expect(focused?.ownerId, 'trigger_b');
    });

    test('mapEnter focus has no fake owner and camera request is one-shot',
        () async {
      final controller = _controller();
      final result = await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
        ),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      final request = controller.state.focusRequest!;

      expect(result.status, NarrativeEventMapNavigationStatus.ready);
      expect(request.focusTarget.kind, NarrativeEditorFocusTargetKind.map);
      expect(request.focusTarget.ownerId, isNull);
      expect(controller.markFocusCameraApplied(request.requestId), isTrue);
      expect(controller.markFocusCameraApplied(request.requestId), isFalse);
      expect(controller.state.focusRequest?.cameraApplied, isTrue);
    });

    test('group mismatch and ambiguous owner refuse without changing workspace',
        () async {
      final mismatchController = _controller();
      var mismatchReads = 0;
      final mismatch = await mismatchController.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
        ),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async {
          mismatchReads++;
          return null;
        },
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      expect(mismatch.status, NarrativeEventMapNavigationStatus.sourceMismatch);
      expect(mismatchReads, 0);

      final ambiguousController = _controller();
      final ambiguous = await ambiguousController.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
        ),
        activeMap: _mapA().copyWith(
          entities: [
            ..._mapA().entities,
            const MapEntity(
              id: 'entity_a',
              name: 'Duplicate',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 7, y: 6),
            ),
          ],
        ),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      expect(ambiguous.status, NarrativeEventMapNavigationStatus.unavailable);
      expect(ambiguousController.state.pendingReturn, isNull);
    });

    test('cancel clears token/highlight and deleted Event never falls back',
        () async {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final controller = _controller();
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: _project(source: source),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);

      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(source: source),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      var opened = false;
      final returned = controller.returnToEvent(
        project: const ProjectManifest(
          name: 'Deleted event project',
          maps: [],
          tilesets: [],
        ),
        openExactEvent: ({required eventId, required groupContext}) {
          opened = true;
        },
      );
      expect(returned, isFalse);
      expect(opened, isFalse);
      expect(
        controller.state.lastNavigationResult?.status,
        NarrativeEventMapNavigationStatus.eventMissing,
      );
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
    });

    test('choose preview accepts only an existing source and performs no write',
        () async {
      final controller = _controller();
      final map = _mapA().copyWith(
        triggers: [
          const MapTrigger(
            id: 'trigger_a',
            name: 'Trigger A',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 5, y: 4),
              size: GridSize(width: 1, height: 2),
            ),
          ),
        ],
      );
      final project = _project(
        source: NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        ),
      );
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );

      final previewed = controller.previewChosenSource(
        project: project,
        map: map,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
      final missing = controller.previewChosenSource(
        project: project,
        map: map,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'missing'),
      );

      expect(previewed, isTrue);
      expect(missing, isFalse);
      expect(
        controller.state.focusRequest?.source,
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
      expect(controller.state.pendingReturn?.eventId, _eventId);
    });

    test('return rejects a different exact source on the same map', () async {
      final originalSource =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final controller = _controller();
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(source: originalSource),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      var opened = false;

      final returned = controller.returnToEvent(
        project: _project(
          source: NarrativeEventSourceRef.triggerEnter(
            'map_a',
            'trigger_a',
          ),
        ),
        openExactEvent: ({required eventId, required groupContext}) {
          opened = true;
        },
      );

      expect(returned, isFalse);
      expect(opened, isFalse);
      expect(controller.state.pendingReturn?.expectedSource, originalSource);
      expect(controller.state.pendingReturn, isNotNull);
      expect(controller.state.focusRequest, isNotNull);
      expect(
        controller.state.lastNavigationResult?.status,
        NarrativeEventMapNavigationStatus.sourceMismatch,
      );
    });

    test('source-less draft keeps an explicit map group and is never global',
        () {
      final project = _project(source: null);
      final controller = _controller();

      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      expect(
        controller.state.selectedGroupContext,
        const NarrativeEventGroupContext.map('map_a'),
      );

      final withoutContext = _controller();
      expect(withoutContext.selectNarrativeEventV2(project, _eventId), isTrue);
      expect(withoutContext.state.selectedGroupContext, isNull);
    });

    test('source-less create flow returns to the exact draft before any write',
        () async {
      final project = _project(source: null);
      final controller = _controller();

      final openedMap = await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );

      expect(openedMap.status, NarrativeEventMapNavigationStatus.ready);
      expect(controller.state.pendingReturn?.expectedSource, isNull);

      String? selectedEvent;
      NarrativeEventGroupContext? selectedGroup;
      final returned = controller.returnToEvent(
        project: project,
        openExactEvent: ({required eventId, required groupContext}) {
          selectedEvent = eventId;
          selectedGroup = groupContext;
        },
      );

      expect(returned, isTrue);
      expect(selectedEvent, _eventId);
      expect(selectedGroup, const NarrativeEventGroupContext.map('map_a'));
      expect(controller.state.pendingReturn, isNull);
    });

    test(
        'double source submit writes once and cancel cannot clear in-flight token',
        () async {
      final project = _project(
        source: NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        ),
      );
      final fixture = await createPersistenceFixture(
        registry: project.eventRegistry,
        map: _mapA(),
      );
      addTearDown(fixture.dispose);
      final prepared = Completer<NarrativeEventAuthoringSession>();
      final gateway = _CountingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
        ),
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) => prepared.future,
        ),
      );
      controller.bindProjectRootPath(fixture.root.path);
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: project,
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );

      final first = controller.linkChosenSource(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _mapA(),
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) =>
            true,
      );
      await Future<void>.delayed(Duration.zero);
      final token = controller.state.pendingReturn;

      final second = await controller.linkChosenSource(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _mapA(),
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) =>
            true,
      );
      controller.cancelMapNavigation();

      expect(controller.state.isLinkingSource, isTrue);
      expect(controller.state.pendingReturn, same(token));
      expect(second?.code, 'linkInProgress');
      prepared.complete(fixture.session);
      final firstResult = await first;

      expect(
          firstResult?.status, NarrativeEventSpatialSourceLinkStatus.committed);
      expect(gateway.persistCalls, 1);
      expect(controller.state.isLinkingSource, isFalse);
    });

    test('same-root project replacement invalidates a delayed cross-map load',
        () async {
      final project = _project(
        source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
          ProjectMapEntry(
            id: 'map_b',
            name: 'Map B',
            relativePath: 'maps/map_b.json',
          ),
        ],
      );
      final controller = _controller();
      controller.bindProjectSession(
        projectRootPath: '/project',
        project: project,
      );
      final loaded = Completer<MapData?>();
      var activations = 0;
      final navigation = controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        mode: NarrativeEventMapNavigationMode.view,
        project: project,
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) => loaded.future,
        activateMapSnapshot: (_) {
          activations++;
          return true;
        },
        applyFocus: (_) => true,
      );
      await Future<void>.delayed(Duration.zero);

      controller.bindProjectSession(
        projectRootPath: '/project',
        project: project.copyWith(name: 'Reloaded project'),
      );
      loaded.complete(_mapB());
      final result = await navigation;

      expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
      expect(activations, 0);
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    test('committed stale link remains explicit and is never silently dropped',
        () async {
      final project = _project(
        source: NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        ),
      );
      final fixture = await createPersistenceFixture(
        registry: project.eventRegistry,
        map: _mapA(),
      );
      addTearDown(fixture.dispose);
      final gateway = _BlockingCountingGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
        ),
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async => fixture.session,
        ),
      );
      controller.bindProjectSession(
        projectRootPath: fixture.root.path,
        project: project,
      );
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: project,
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      final token = controller.state.pendingReturn;
      var adoptions = 0;

      final linking = controller.linkChosenSource(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _mapA(),
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          adoptions++;
          return true;
        },
      );
      while (gateway.persistCalls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      controller.bindProjectSession(
        projectRootPath: fixture.root.path,
        project: project.copyWith(name: 'Concurrent reload'),
      );
      gateway.completeCommitted();
      final result = await linking;

      expect(
        result?.status,
        NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
      );
      expect(adoptions, 0);
      expect(controller.state.pendingReturn, same(token));
      expect(controller.state.isLinkingSource, isFalse);
      expect(
        controller.state.lastSourceLinkResult?.status,
        NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
      );
    });
  });

  group('NS-EVENT-V2-24 EditorNotifier map focus', () {
    test('same-map activation preserves the dirty document and viewport', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final active = _mapA();
      notifier.state = EditorState(
        project: _project(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
        ),
        activeMap: active,
        activeMapPath: '/project/maps/map_a.json',
        isDirty: true,
        panOffset: const Offset(17, 23),
        zoom: 1.75,
      );

      final activated = notifier.activateNarrativeEventMapSnapshot(_mapA());

      expect(activated, isTrue);
      expect(notifier.state.activeMap, same(active));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.panOffset, const Offset(17, 23));
      expect(notifier.state.zoom, 1.75);
    });

    test('focus selects one exact owner atomically without dirtying the map',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapA().copyWith(
        triggers: [
          const MapTrigger(
            id: 'trigger_a',
            name: 'Trigger A',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 5, y: 4),
              size: GridSize(width: 2, height: 1),
            ),
          ),
        ],
      );
      notifier.state = EditorState(
        activeMap: map,
        selectedTriggerId: 'trigger_a',
        savedMapSnapshot: map,
      );

      final entityFocused = notifier.focusNarrativeEventMapSource(
        NarrativeEditorFocusTarget.entity(
          'map_a',
          'entity_a',
          const MapRect(
            pos: GridPos(x: 3, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      );

      expect(entityFocused, isTrue);
      expect(notifier.state.selectedEntityId, 'entity_a');
      expect(notifier.state.selectedTriggerId, isNull);
      expect(notifier.state.isDirty, isFalse);

      final triggerFocused = notifier.focusNarrativeEventMapSource(
        NarrativeEditorFocusTarget.trigger(
          'map_a',
          'trigger_a',
          const MapRect(
            pos: GridPos(x: 5, y: 4),
            size: GridSize(width: 2, height: 1),
          ),
        ),
      );
      expect(triggerFocused, isTrue);
      expect(notifier.state.selectedEntityId, isNull);
      expect(notifier.state.selectedTriggerId, 'trigger_a');
      expect(notifier.state.isDirty, isFalse);
    });

    test('one-shot pan setter changes only the viewport', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapA();
      notifier.state = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        zoom: 2,
      );

      notifier.setNarrativeEventMapPanOffset(const Offset(-120, 45));

      expect(notifier.state.panOffset, const Offset(-120, 45));
      expect(notifier.state.zoom, 2);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.isDirty, isFalse);
    });
  });
}

NarrativeEventMapBridgeController _controller() {
  return NarrativeEventMapBridgeController(
    useCase: CreateNarrativeEventFromMapSourceUseCase(
      persistenceGateway: _UnusedGateway(),
    ),
  );
}

ProjectManifest _project({
  required NarrativeEventSourceRef? source,
  List<ProjectMapEntry> maps = const [
    ProjectMapEntry(
      id: 'map_a',
      name: 'Map A',
      relativePath: 'maps/map_a.json',
    ),
  ],
}) {
  return ProjectManifest(
    name: 'Navigation project',
    maps: maps,
    tilesets: const [],
    scenes: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Rencontre au port',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _mapA() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 10, height: 8),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Rival',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
        ),
      ],
    );

MapData _mapB() => const MapData(
      id: 'map_b',
      name: 'Map B',
      size: GridSize(width: 12, height: 9),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      triggers: [
        MapTrigger(
          id: 'trigger_b',
          name: 'Entrée',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 4, y: 3),
            size: GridSize(width: 2, height: 2),
          ),
        ),
      ],
    );

final class _UnusedGateway implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _CountingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.committed,
      code: 'committed',
      message: 'Committed.',
    );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _BlockingCountingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;
  final _completion = Completer<NarrativeEventRegistryPersistenceResult>();

  void completeCommitted() {
    _completion.complete(
      NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.committed,
        code: 'committed',
        message: 'Committed.',
      ),
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    return _completion.future;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
```

### 22.19 `packages/map_editor/test/map_focus_viewport_resolver_test.dart`

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/map_focus_viewport_resolver.dart';

void main() {
  group('NS-EVENT-V2-24 focus viewport resolver', () {
    test('centers exact multi-cell bounds while preserving zoom', () {
      final pan = resolveMapFocusPanOffset(
        bounds: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 4),
        ),
        viewportSize: const Size(800, 600),
        tileWidth: 32,
        tileHeight: 24,
        zoom: 1.5,
      );

      expect(pan, const Offset(160, 120));
    });

    test('map focus resolves to full-map bounds without a fake owner', () {
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 20, height: 12),
        layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      );
      final focus = NarrativeEditorFocusTarget.map('map_a');

      final bounds = resolveNarrativeEventMapFocusBounds(
        focus: focus,
        map: map,
      );

      expect(
        bounds,
        const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 20, height: 12),
        ),
      );
      expect(focus.ownerId, isNull);
    });

    test('rejects a focus target from another map', () {
      expect(
        () => resolveNarrativeEventMapFocusBounds(
          focus: NarrativeEditorFocusTarget.map('map_b'),
          map: const MapData(
            id: 'map_a',
            name: 'Map A',
            size: GridSize(width: 3, height: 3),
            layers: [ObjectLayer(id: 'objects', name: 'Objects')],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
```

### 22.20 `packages/map_editor/test/event_builder_map_focus_return_flow_test.dart`

```dart
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import 'package:map_editor/src/ui/canvas/events/narrative_event_map_return_panel.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/narrative_event_map_banner.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/narrative_event_map_bridge_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000331';

void main() {
  group('NS-EVENT-V2-24 Event to Map return widget flow', () {
    testWidgets('same-map dirty flow returns to the exact V2 Event and group',
        (tester) async {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final project = _project(source);
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        activeMapPath: '/project/maps/map_a.json',
        savedMapSnapshot: _map(),
        isDirty: true,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);

      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
      );
      await tester.pumpAndSettle();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.activeMap?.id, 'map_a');
      expect(controller.state.pendingReturn?.eventId, _eventId);
      expect(
        controller.state.pendingReturn?.groupContext.mapId,
        'map_a',
      );
      expect(find.byKey(const ValueKey('narrative-event-map-banner')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await tester.pumpAndSettle();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.selectedGroupContext?.mapId, 'map_a');
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    testWidgets('nonspatial Event exposes no map CTA', (tester) async {
      final project = _project(
        NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_a',
            outcomeId: 'done',
          ),
        ),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);

      await _pumpFlow(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
        findsNothing,
      );
      expect(find.textContaining('global'), findsWidgets);
    });

    testWidgets(
        'source-less map draft shows a missing-source diagnostic without map navigation',
        (tester) async {
      final project = _project(null);
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );

      await _pumpFlow(tester, container);

      expect(find.textContaining('Source manquante'), findsOneWidget);
      expect(find.textContaining('Event global'), findsNothing);
      expect(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-create-source-on-map')),
        findsOneWidget,
      );
    });

    testWidgets('choose mode proposes selected source and map without picker',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('narrative-event-choose-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-choose-source-map-map_a'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
    });

    testWidgets('candidate confirmation persists once and returns exactly',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: _map(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingGateway();
      final container = _container(
        gateway: gateway,
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async => fixture.session,
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        activeMapPath: p.join(
          p.dirname(fixture.projectPath),
          'maps',
          'map_a.json',
        ),
        savedMapSnapshot: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-choose-source-map-map_a'),
        ),
      );
      await tester.pumpAndSettle();

      expect(gateway.requests, hasLength(1));
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.mapEnter('map_a'),
      );
    });

    testWidgets(
        'source link disables repeat and cancel actions while one write is in flight',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: _map(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _BlockingGateway();
      final container = _container(
        gateway: gateway,
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async => fixture.session,
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        savedMapSnapshot: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      final mapAction = find.byKey(
        const ValueKey('narrative-event-choose-source-map-map_a'),
      );
      await tester.tap(mapAction);
      await tester.pump();
      final token = controller.state.pendingReturn;

      expect(gateway.requests, hasLength(1));
      expect(controller.state.isLinkingSource, isTrue);
      expect(tester.widget<PokeMapButton>(mapAction).onPressed, isNull);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(mapAction);
      controller.cancelMapNavigation();
      await tester.pump();
      expect(gateway.requests, hasLength(1));
      expect(controller.state.pendingReturn, same(token));

      gateway.completeCommitted();
      await tester.pumpAndSettle();
      expect(controller.state.isLinkingSource, isFalse);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
    });

    testWidgets(
        'deleted Event while away shows diagnostic and never falls back',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
      );
      await tester.pumpAndSettle();

      notifier.state = notifier.state.copyWith(
        project: project.copyWith(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.dualRead,
            records: const [],
            legacyClaims: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await tester.pump();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.pendingReturn, isNotNull);
      expect(controller.state.focusRequest, isNotNull);
      expect(
        controller.state.lastNavigationResult?.status,
        NarrativeEventMapNavigationStatus.eventMissing,
      );
      expect(find.textContaining('supprimé'), findsWidgets);
    });
  });
}

ProviderContainer _container({
  NarrativeEventRegistryPersistenceGateway? gateway,
  NarrativeEventSpatialSourceLinkUseCase? sourceLinkUseCase,
}) {
  final container = ProviderContainer(
    overrides: [
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        _ClearSourceCreationGateway(),
      ),
      if (gateway != null)
        narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
          gateway,
        ),
      if (sourceLinkUseCase != null)
        narrativeEventSpatialSourceLinkUseCaseProvider.overrideWithValue(
          sourceLinkUseCase,
        ),
    ],
  );
  final editor = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridge = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    bridge.close();
    editor.close();
    container.dispose();
  });
  return container;
}

final class _ClearSourceCreationGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.clear,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) {
    throw UnimplementedError();
  }
}

Future<void> _pumpFlow(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NarrativeEventMapReturnPanel(),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: NarrativeEventMapBanner(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 330,
                    child: NarrativeEventMapBridgePanel(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project(NarrativeEventSourceRef? source) {
  return ProjectManifest(
    name: 'Flow project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    scenes: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Rencontre au port',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 10, height: 8),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Rival',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
        ),
      ],
    );

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final List<NarrativeEventRegistryWriteRequest> requests = [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    requests.add(request);
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.committed,
      code: 'committed',
      message: 'Committed.',
    );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _BlockingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final requests = <NarrativeEventRegistryWriteRequest>[];
  final _completion = Completer<NarrativeEventRegistryPersistenceResult>();

  void completeCommitted() {
    _completion.complete(
      NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.committed,
        code: 'committed',
        message: 'Committed.',
      ),
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    requests.add(request);
    return _completion.future;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
```

### 22.21 `packages/map_editor/test/map_canvas_narrative_event_focus_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('NS-EVENT-V2-24 independent map bridge highlight', () {
    test('entity highlight does not depend on normal editor selection', () {
      final focus = NarrativeEditorFocusTarget.entity(
        'map_a',
        'entity_a',
        const MapRect(
          pos: GridPos(x: 2, y: 3),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        isNarrativeEventBridgeEntityHighlighted(
          entityId: 'entity_a',
          focus: focus,
        ),
        isTrue,
      );
      expect(
        isNarrativeEventBridgeEntityHighlighted(
          entityId: 'another_selection',
          focus: focus,
        ),
        isFalse,
      );
    });

    test('trigger and map highlights remain typed', () {
      final trigger = NarrativeEditorFocusTarget.trigger(
        'map_a',
        'trigger_a',
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 3, height: 2),
        ),
      );
      final map = NarrativeEditorFocusTarget.map('map_a');

      expect(
        isNarrativeEventBridgeTriggerHighlighted(
          triggerId: 'trigger_a',
          focus: trigger,
        ),
        isTrue,
      );
      expect(
        isNarrativeEventBridgeTriggerHighlighted(
          triggerId: 'trigger_a',
          focus: map,
        ),
        isFalse,
      );
      expect(isNarrativeEventBridgeMapHighlighted(focus: map), isTrue);
      expect(isNarrativeEventBridgeMapHighlighted(focus: trigger), isFalse);
    });

    test('choose hit-test returns only one real authorable source', () {
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'entity_a',
            name: 'Entity A',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
          ),
          MapEntity(
            id: 'spawn_a',
            name: 'Spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 6, y: 6),
          ),
        ],
        triggers: [
          MapTrigger(
            id: 'trigger_a',
            name: 'Trigger A',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 4, y: 3),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      );

      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 2, y: 2),
        ),
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 5, y: 4),
        ),
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 0, y: 0),
        ),
        isNull,
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 6, y: 6),
        ),
        isNull,
      );

      final ambiguous = map.copyWith(
        triggers: [
          ...map.triggers,
          const MapTrigger(
            id: 'overlap',
            name: 'Overlap',
            type: TriggerType.custom,
            area: MapRect(
              pos: GridPos(x: 2, y: 2),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: ambiguous,
          pos: const GridPos(x: 2, y: 2),
        ),
        isNull,
      );
    });

    test('painter repaints when only the bridge focus changes', () {
      final before = _painter(
        focus: NarrativeEditorFocusTarget.map('map_a'),
      );
      final after = _painter(
        focus: NarrativeEditorFocusTarget.entity(
          'map_a',
          'entity_a',
          const MapRect(
            pos: GridPos(x: 2, y: 3),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      );

      expect(after.shouldRepaint(before), isTrue);
    });

    testWidgets('canvas applies each camera request once', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000321';
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final project = ProjectManifest(
        name: 'Canvas focus project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: eventId,
                name: 'Event focus',
                source: source,
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 10, height: 8),
        layers: [ObjectLayer(id: 'objects', name: 'Objects')],
        entities: [
          MapEntity(
            id: 'entity_a',
            name: 'Entity A',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 2),
          ),
        ],
      );
      final container = ProviderContainer();
      final editorSubscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final bridgeSubscription = container.listen<NarrativeEventMapBridgeState>(
        narrativeEventMapBridgeControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() {
        bridgeSubscription.close();
        editorSubscription.close();
        container.dispose();
      });
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      await controller.openMapForEvent(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: notifier.focusNarrativeEventMapSource,
      );

      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox.expand(child: MapCanvas()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final centeredPan = notifier.state.panOffset;
      expect(centeredPan, isNot(Offset.zero));
      expect(controller.state.focusRequest?.cameraApplied, isTrue);

      notifier.pan(const Offset(25, -10));
      await tester.pump();
      await tester.pump();
      expect(notifier.state.panOffset, centeredPan + const Offset(25, -10));
    });
  });

  group('NS-EVENT-V2-25 guided map drag guard', () {
    testWidgets('create mode ignores a tile-paint drag', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000322';
      final map = _guidedDragMap();
      final project = _guidedDragProject(eventId: eventId);
      final container = _createGuidedDragContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.tile(
          tileId: 7,
          tilesetId: 'primary',
        ),
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      final opened = await controller.openMapForMissingSource(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(opened.succeeded, isTrue);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      expect(controller.state.pendingReturn, isNotNull);

      await _pumpGuidedDragCanvas(tester, container);
      await _dragAcrossCanvas(tester);

      final activeLayer = notifier.state.activeMap!.layers.single as TileLayer;
      expect(
        activeLayer.tiles,
        everyElement(0),
        reason: 'Guided create mode must not leak into tile painting.',
      );
    });

    testWidgets('choose mode ignores a gameplay-zone drag', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000323';
      final map = _guidedDragMap();
      final project = _guidedDragProject(
        eventId: eventId,
        source: NarrativeEventSourceRef.mapEnter('map_a'),
      );
      final container = _createGuidedDragContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.gameplayZonePlacement,
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      final opened = await controller.openMapForEvent(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: notifier.focusNarrativeEventMapSource,
      );
      expect(opened.succeeded, isTrue);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.choose,
      );
      expect(controller.state.pendingReturn, isNotNull);

      await _pumpGuidedDragCanvas(tester, container);
      await _dragAcrossCanvas(tester);

      expect(
        notifier.state.activeMap!.gameplayZones,
        isEmpty,
        reason: 'Guided choose mode must not create gameplay zones.',
      );
      expect(notifier.state.gameplayZoneDraftArea, isNull);
    });
  });
}

ProviderContainer _createGuidedDragContainer() {
  final container = ProviderContainer();
  final editorSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridgeSubscription = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    bridgeSubscription.close();
    editorSubscription.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpGuidedDragCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _dragAcrossCanvas(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(MapCanvas)),
  );
  await gesture.moveBy(const Offset(48, 0));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

ProjectManifest _guidedDragProject({
  required String eventId,
  NarrativeEventSourceRef? source,
}) {
  return ProjectManifest(
    name: 'Guided drag project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: eventId,
            name: 'Guided drag Event',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _guidedDragMap() {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 20, height: 15),
    layers: [
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'primary',
        tiles: List<int>.filled(20 * 15, 0),
      ),
    ],
  );
}

MapGridPainter _painter({required NarrativeEditorFocusTarget focus}) {
  return MapGridPainter(
    map: const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 8, height: 6),
    ),
    zoom: 1,
    offset: Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const {},
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const {},
    warps: const [],
    gameplayZones: const [],
    connectionLabelsByDirection: const {},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const {},
    narrativeEventFocusTarget: focus,
    narrativeEventHighlightColor: const Color(0xFF815BFF),
  );
}
```

### 22.22 `packages/map_editor/test/narrative_event_spatial_link_journal_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2-25 spatial link journal repository', () {
    test('commits one source with a strict durable mapCommitted journal',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final request = _request(fixture);
      final result = await NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
      ).commitMap(request);

      expect(
        result.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final journal = result.journal!;
      expect(journal.state, NarrativeEventSpatialLinkJournalState.mapCommitted);
      expect(journal.operationId, 'phase_g_add_source');
      expect(journal.projectRevision, fixture.revision);
      expect(journal.mapId, 'map_a');
      expect(journal.eventId, persistenceEventA);
      expect(
        journal.eventRecordFingerprintBefore,
        _eventRecordFingerprintBefore,
      );
      expect(journal.source, _source);
      expect(journal.beforeMapHash, fixture.session.mapByteHashes['map_a']);
      expect(journal.afterMapHash, startsWith('sha256:'));
      expect(journal.sourceOwnerFingerprint, _ownerFingerprint);
      expect(
          journal.cleanupMarker, NarrativeEventSpatialLinkCleanupMarker.none);
      expect(journal.preparedAt, DateTime.utc(2026, 7, 15, 8));
      expect(journal.mapCommittedAt, DateTime.utc(2026, 7, 15, 8));
      expect(journal.eventCommittedAt, isNull);
      expect(await File(journal.journalPath).exists(), isTrue);
      expect(await File(journal.mapTempPath).exists(), isFalse);

      final raw =
          _object(jsonDecode(await File(journal.journalPath).readAsString()));
      expect(
        raw.keys.toSet(),
        {
          'schemaVersion',
          'operationId',
          'projectPath',
          'projectRevision',
          'journalPath',
          'mapPath',
          'mapTempPath',
          'mapId',
          'eventId',
          'eventRecordFingerprintBefore',
          'source',
          'sourceOwnerJson',
          'sourceOwnerFingerprint',
          'beforeMapHash',
          'afterMapHash',
          'state',
          'preparedAt',
          'mapCommittedAt',
          'eventCommittedAt',
          'cleanupMarker',
          'cleanupRequestedAt',
        },
      );
      final roundTrip = NarrativeEventSpatialLinkJournal.fromJson(raw);
      expect(
        roundTrip.eventRecordFingerprintBefore,
        _eventRecordFingerprintBefore,
      );
      final missingFingerprint = Map<String, Object?>.from(raw)
        ..remove('eventRecordFingerprintBefore');
      expect(
        () => NarrativeEventSpatialLinkJournal.fromJson(missingFingerprint),
        throwsA(isA<FormatException>()),
      );
      final unknownField = Map<String, Object?>.from(raw)
        ..['futureField'] = true;
      expect(
        () => NarrativeEventSpatialLinkJournal.fromJson(unknownField),
        throwsA(isA<FormatException>()),
      );
      final diskMap = await _readMap(fixture);
      expect(diskMap.entities.single.id, 'entity_event');
      expect(
        canonicalizeNarrativeEventJson(
          _ownerEnvelope(diskMap.entities.single),
        ),
        canonicalizeNarrativeEventJson(_ownerJson),
      );
    });

    test('commits and round-trips a real 1x1 trigger owner as strict JSON',
        () async {
      final fixture = await _triggerFixture();
      addTearDown(fixture.dispose);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_triggerRequest(fixture));

      expect(
        result.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final journal = result.journal!;
      expect(journal.source, _triggerSource);
      expect(journal.sourceOwnerJson, _triggerOwnerJsonSafe);
      expect(journal.sourceOwnerFingerprint, _triggerOwnerFingerprint);
      final strictJournalJson = _object(decodeNarrativeEventJsonStrict(
        await File(journal.journalPath).readAsString(),
      ));
      final roundTrip = NarrativeEventSpatialLinkJournal.fromJson(
        strictJournalJson,
      );
      expect(roundTrip.sourceOwnerJson, _triggerOwnerJsonSafe);
      final diskMap = await _readMap(fixture);
      expect(diskMap.triggers.map((trigger) => trigger.id), [
        'existing_trigger',
        'trigger_event',
      ]);
      expect(diskMap.triggers.last.area, _trigger.area);
      expect(
          diskMap.triggers.last.area.size, const GridSize(width: 1, height: 1));
    });

    test('cleanup removes only the exact 1x1 trigger from current disk map',
        () async {
      final fixture = await _triggerFixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_triggerRequest(fixture));

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_trigger',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      final diskMap = await _readMap(fixture);
      expect(diskMap.triggers.map((trigger) => trigger.id), [
        'existing_trigger',
      ]);
    });

    test('CAS checks project revision under the shared lock before map rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final beforeMapBytes = await File(_mapPath(fixture)).readAsBytes();
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
            final root = _object(jsonDecode(
              await File(fixture.projectPath).readAsString(),
            ));
            root['externalRevision'] = 2;
            await File(fixture.projectPath).writeAsString(
              jsonEncode(root),
              flush: true,
            );
          }
        },
      );

      final result = await repository.commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'staleProjectRevisionBeforeMapRename');
      expect(await File(_mapPath(fixture)).readAsBytes(), beforeMapBytes);
      expect(result.journal?.state,
          NarrativeEventSpatialLinkJournalState.prepared);
    });

    test('rejects a request whose canonical Event-before fingerprint is stale',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final staleRequest = NarrativeEventSpatialLinkMapCommitRequest(
        projectPath: fixture.projectPath,
        projectRevision: fixture.revision,
        operationId: 'phase_g_stale_event',
        eventId: persistenceEventA,
        eventRecordFingerprintBefore:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        beforeMap: _beforeMap,
        afterMap: _afterMap,
        source: _source,
        sourceOwnerJson: _ownerJson,
        sourceOwnerFingerprint: _ownerFingerprint,
      );

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(staleRequest);

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'eventRecordFingerprintMismatch');
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('blocks map commit while Event registry recovery is pending',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final previous = persistenceRegistry(records: [persistenceDraft()]);
      final interrupted = await NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'event_registry_pending',
          previousRegistry: previous,
          nextRegistry: persistenceRegistry(records: [
            persistenceDraft(name: 'Renamed draft'),
          ]),
          mutation: 'rename',
        ),
      );
      expect(interrupted.status,
          NarrativeEventRegistryPersistenceStatus.ioFailure);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'eventRegistryRecoveryRequired');
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('a crash after prepared is recovered as a no-op when source is absent',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(name: 'Changed while map remained untouched'),
        ]),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.recovered);
      expect(recovery.code, 'preparedNoOpRemoved');
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test(
        'recovery refuses journal B swapped after inspecting journal A without mutation',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final interrupted = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        interrupted.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspected = await restarted.inspectProject(fixture.projectPath);
      final journalA = inspected.journal!;
      expect(
        inspected.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final journalB = await _replaceJournalOperation(
        journalA,
        'phase_g_swapped_recovery_b',
      );
      final journalBBytes = await File(journalB.journalPath).readAsBytes();
      final projectBytes = await File(fixture.projectPath).readAsBytes();
      final mapBytes = await File(_mapPath(fixture)).readAsBytes();

      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        journalA,
      );

      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(recovery.code, 'recoveryJournalMismatch');
      expect(await File(journalB.journalPath).readAsBytes(), journalBBytes);
      expect(await File(fixture.projectPath).readAsBytes(), projectBytes);
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytes);
      expect(await File(journalA.journalPath).exists(), isFalse);
    });

    test(
        'prepared no-op recovery removes artifacts even when target Event was deleted',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: const []),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(recovery.code, 'preparedNoOpRemoved');
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test('a crash after rename promotes exact prepared source to mapCommitted',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterMapRename) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 9),
      );
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.recovered);
      expect(recovery.code, 'preparedPromotedToMapCommitted');
      expect(recovery.journal?.state,
          NarrativeEventSpatialLinkJournalState.mapCommitted);
      expect((await _readMap(fixture)).entities.single.id, 'entity_event');
    });

    test('unknown malformed and multiple journals block fail-closed', () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final committed = await repository.commitMap(_request(fixture));
      final journalFile = File(committed.journal!.journalPath);
      final raw = _object(jsonDecode(await journalFile.readAsString()));
      raw['schemaVersion'] = 99;
      await journalFile.writeAsString(jsonEncode(raw), flush: true);

      final unknown = await repository.inspectProject(fixture.projectPath);
      expect(unknown.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(unknown.issues.single.code, 'invalidJournal');
      expect(await _readMap(fixture), _afterMap);

      await File('${journalFile.path}.copy.journal.json').writeAsString(
        '{broken',
        flush: true,
      );
      final multiple = await repository.inspectProject(fixture.projectPath);
      expect(
          multiple.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(multiple.issues.map((issue) => issue.code),
          contains('multipleJournals'));
    });

    test(
        'eventCommitted is accepted only for the exact Event and waits for acknowledgement',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));

      final rejected = await repository.markEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );
      expect(rejected.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(rejected.code, 'eventNotLinked');

      await _writeRegistrySource(fixture, source: _source);
      final committed = await repository.markEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );
      expect(
        committed.status,
        NarrativeEventSpatialLinkOperationStatus.eventCommitted,
      );
      expect(committed.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(await File(committed.journal!.journalPath).exists(), isTrue);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
      );

      final acknowledged = await repository.acknowledgeEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );

      expect(
        acknowledged.status,
        NarrativeEventSpatialLinkOperationStatus.eventCommitted,
      );
      expect(acknowledged.code, 'eventCommitAcknowledged');
      expect(await File(committed.journal!.journalPath).exists(), isFalse);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test(
        'inspection blocks retry when the target Event changed after map commit',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(name: 'Changed after map commit'),
        ]),
      );

      final inspection = await repository.inspectProject(fixture.projectPath);

      expect(
          inspection.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(inspection.issues.single.code, 'eventRecordChanged');
    });

    test(
        'inspection blocks retry when the target Event was deleted after map commit',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: const []),
      );

      final inspection = await repository.inspectProject(fixture.projectPath);

      expect(
          inspection.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(inspection.issues.single.code, 'eventRecordMissing');
    });

    test('cleanup deletes only the unchanged owner from the current disk map',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      final current = await _readMap(fixture);
      const unrelated = MapEntity(
        id: 'unrelated',
        name: 'Keep me',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 6, y: 4),
      );
      await _writeMap(
          fixture,
          current.copyWith(entities: [
            ...current.entities,
            unrelated,
          ]));

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      final afterCleanup = await _readMap(fixture);
      expect(afterCleanup.entities, [unrelated]);
      expect(await File(cleanup.journal!.journalPath).exists(), isFalse);
    });

    test(
        'cleanup refuses no confirmation modified owner and incoherent absence',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));

      final notConfirmed = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: false,
      );
      expect(notConfirmed.code, 'confirmationRequired');
      expect((await _readMap(fixture)).entities, isNotEmpty);

      final changed = (await _readMap(fixture)).copyWith(entities: [
        _entity.copyWith(name: 'Changed after creation'),
      ]);
      await _writeMap(fixture, changed);
      final modified = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );
      expect(modified.code, 'sourceFingerprintMismatch');
      expect((await _readMap(fixture)).entities.single.name,
          'Changed after creation');

      await _writeMap(fixture, changed.copyWith(entities: const []));
      final absent = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );
      expect(absent.code, 'sourceUnexpectedlyAbsent');
    });

    test('cleanup refuses when any other Event record references the source',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(),
          persistenceDraft(id: persistenceEventB, source: _source),
        ]),
      );
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(cleanup.code, 'sourceReferencedByAnotherEvent');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
      expect((await _readMap(fixture)).entities.single.id, 'entity_event');
    });

    test('cleanup refuses a legacy claim that directly owns the atomic source',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(
          mode: EventSystemMode.dualRead,
          records: [persistenceDraft()],
          claims: [_legacyClaimFor(_source)],
        ),
      );
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(cleanup.code, 'sourceReferencedByLegacyClaim');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
    });

    test('cleanup preserves an unrelated manifest change made before it starts',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      final changedRoot = await _readProjectRoot(fixture)
        ..['unrelatedAfterMapCommit'] = {
          'preserve': true,
        };
      await File(fixture.projectPath).writeAsBytes(
        canonicalizeNarrativeEventJsonUtf8(changedRoot),
        flush: true,
      );

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      expect((await _readMap(fixture)).entities, isEmpty);
      expect(
        (await _readProjectRoot(fixture))['unrelatedAfterMapCommit'],
        {'preserve': true},
      );
    });

    test('cleanup CAS blocks a manifest mutation during cleanup without rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename) {
            final root = await _readProjectRoot(fixture)
              ..['changedDuringCleanup'] = true;
            await File(fixture.projectPath).writeAsBytes(
              canonicalizeNarrativeEventJsonUtf8(root),
              flush: true,
            );
          }
        },
      );

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(cleanup.code, 'projectChangedDuringCleanup');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
      expect((await _readProjectRoot(fixture))['changedDuringCleanup'], isTrue);
    });

    test('recovers cleanup after its exact-owner map rename became durable',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));
      final crashing = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterCleanupRename) {
            throw const FileSystemException('simulated cleanup crash');
          }
        },
      );

      await expectLater(
        crashing.cleanupSource(
          projectPath: fixture.projectPath,
          operationId: 'phase_g_add_source',
          confirmed: true,
        ),
        throwsA(isA<FileSystemException>()),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(recovery.code, 'cleanupRecovered');
      expect((await _readMap(fixture)).entities, isEmpty);
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test('refuses a map changed into a symbolic link immediately before rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final mapPath = _mapPath(fixture);
      final backupPath = '$mapPath.external';
      await File(backupPath).writeAsBytes(
        await File(mapPath).readAsBytes(),
        flush: true,
      );
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
            await File(mapPath).delete();
            await Link(mapPath).create(backupPath);
          }
        },
      );

      final result = await repository.commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'symbolicLinkRefused');
      expect(
        await FileSystemEntity.type(mapPath, followLinks: false),
        FileSystemEntityType.link,
      );
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('refuses a manifest map reached through a symbolic link', () async {
      final fixture = await createPersistenceFixture(
        map: _beforeMap,
        mapViaSymbolicLink: true,
        registry: persistenceRegistry(records: [persistenceDraft()]),
      );
      addTearDown(fixture.dispose);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'symbolicLinkRefused');
      expect((await _readMap(fixture)).entities, isEmpty);
    });
  });
}

final _source = NarrativeEventSourceRef.entityInteract('map_a', 'entity_event');
const _entity = MapEntity(
  id: 'entity_event',
  name: 'Invisible event source',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 3),
  blocksMovement: false,
);
const _beforeMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
);
const _afterMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  entities: [_entity],
);
const _existingTrigger = MapTrigger(
  id: 'existing_trigger',
  name: 'Existing trigger',
  type: TriggerType.custom,
  area: MapRect(
    pos: GridPos(x: 0, y: 0),
    size: GridSize(width: 2, height: 1),
  ),
);
const _trigger = MapTrigger(
  id: 'trigger_event',
  name: 'Event zone',
  type: TriggerType.event,
  area: MapRect(
    pos: GridPos(x: 3, y: 2),
    size: GridSize(width: 1, height: 1),
  ),
);
const _triggerBeforeMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  triggers: [_existingTrigger],
);
const _triggerAfterMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  triggers: [_existingTrigger, _trigger],
);

final _ownerJson = _ownerEnvelope(_entity);
final _ownerFingerprint = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(_ownerJson),
);
final _eventRecordFingerprintBefore = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(persistenceDraft().toJson()),
);
final _triggerSource =
    NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_event');
final _triggerOwnerJsonRaw = <String, Object?>{
  'schemaVersion': 1,
  'ownerKind': 'mapTrigger',
  'mapId': 'map_a',
  'sourceId': 'trigger_event',
  'owner': _trigger.toJson(),
};
final _triggerOwnerJsonSafe = _object(
  jsonDecode(jsonEncode(_triggerOwnerJsonRaw)),
);
final _triggerOwnerFingerprint = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(_triggerOwnerJsonSafe),
);

Future<EventRegistryPersistenceFixture> _fixture() {
  return createPersistenceFixture(
    map: _beforeMap,
    registry: persistenceRegistry(records: [persistenceDraft()]),
  );
}

Future<EventRegistryPersistenceFixture> _triggerFixture() {
  return createPersistenceFixture(
    map: _triggerBeforeMap,
    registry: persistenceRegistry(records: [persistenceDraft()]),
  );
}

NarrativeEventSpatialLinkMapCommitRequest _request(
  EventRegistryPersistenceFixture fixture,
) {
  return NarrativeEventSpatialLinkMapCommitRequest(
    projectPath: fixture.projectPath,
    projectRevision: fixture.revision,
    operationId: 'phase_g_add_source',
    eventId: persistenceEventA,
    eventRecordFingerprintBefore: _eventRecordFingerprintBefore,
    beforeMap: _beforeMap,
    afterMap: _afterMap,
    source: _source,
    sourceOwnerJson: _ownerJson,
    sourceOwnerFingerprint: _ownerFingerprint,
  );
}

NarrativeEventSpatialLinkMapCommitRequest _triggerRequest(
  EventRegistryPersistenceFixture fixture,
) {
  return NarrativeEventSpatialLinkMapCommitRequest(
    projectPath: fixture.projectPath,
    projectRevision: fixture.revision,
    operationId: 'phase_g_add_trigger',
    eventId: persistenceEventA,
    eventRecordFingerprintBefore: _eventRecordFingerprintBefore,
    beforeMap: _triggerBeforeMap,
    afterMap: _triggerAfterMap,
    source: _triggerSource,
    sourceOwnerJson: _triggerOwnerJsonRaw,
    sourceOwnerFingerprint: _triggerOwnerFingerprint,
  );
}

Map<String, Object?> _ownerEnvelope(MapEntity owner) => {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': owner.id,
      'owner': owner.toJson(),
    };

String _mapPath(EventRegistryPersistenceFixture fixture) =>
    fixture.session.mapPaths['map_a']!;

Future<MapData> _readMap(EventRegistryPersistenceFixture fixture) async {
  final bytes = await File(_mapPath(fixture)).readAsBytes();
  final value = _object(decodeNarrativeEventJsonStrict(utf8.decode(bytes)));
  return MapData.fromJson(value.cast<String, dynamic>());
}

Future<void> _writeMap(
  EventRegistryPersistenceFixture fixture,
  MapData map,
) {
  return File(_mapPath(fixture)).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(map.toJson()),
    flush: true,
  );
}

Future<void> _writeRegistrySource(
  EventRegistryPersistenceFixture fixture, {
  required NarrativeEventSourceRef source,
}) async {
  await _writeRegistry(
    fixture,
    persistenceRegistry(records: [
      persistenceDraft(source: source),
    ]),
  );
}

Future<void> _writeRegistry(
  EventRegistryPersistenceFixture fixture,
  NarrativeEventRegistry registry,
) async {
  final bytes = await File(fixture.projectPath).readAsBytes();
  final root = _object(decodeNarrativeEventJsonStrict(utf8.decode(bytes)));
  root['eventRegistry'] = registry.toJson();
  await File(fixture.projectPath).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(root),
    flush: true,
  );
}

Future<NarrativeEventSpatialLinkJournal> _replaceJournalOperation(
  NarrativeEventSpatialLinkJournal journal,
  String operationId,
) async {
  final raw = _object(jsonDecode(jsonEncode(journal.toJson())));
  raw['operationId'] = operationId;
  raw['journalPath'] =
      journal.journalPath.replaceFirst(journal.operationId, operationId);
  raw['mapTempPath'] =
      journal.mapTempPath.replaceFirst(journal.operationId, operationId);
  final replacement = NarrativeEventSpatialLinkJournal.fromJson(raw);
  await File(replacement.journalPath).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(replacement.toJson()),
    flush: true,
  );
  await File(journal.journalPath).delete();
  return replacement;
}

Future<NarrativeEventSpatialLinkOperationResult> _recoverExact(
  NarrativeEventSpatialLinkJournalRepository repository,
  String projectPath,
  NarrativeEventSpatialLinkJournal journal,
) {
  return repository.recoverProject(
    projectPath: projectPath,
    expectedOperationId: journal.operationId,
    expectedEventId: journal.eventId,
    expectedMapId: journal.mapId,
    expectedSource: journal.source,
  );
}

Future<Map<String, Object?>> _readProjectRoot(
  EventRegistryPersistenceFixture fixture,
) async {
  return _object(decodeNarrativeEventJsonStrict(
    await File(fixture.projectPath).readAsString(),
  ));
}

LegacySourceClaim _legacyClaimFor(NarrativeEventSourceRef source) {
  final member = LegacySourceClaimMember(
    provenance: LegacySourceRef.mapEvent('map_a', 'legacy_source'),
    sourceFingerprint:
        'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  );
  final cohortId = 'lsc_${narrativeEventCanonicalSha256({
        'source': source.toJson(),
        'provenances': [member.provenance.toJson()],
      })}';
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: 'sha256:${narrativeEventCanonicalSha256({
          'cohortId': cohortId,
          'members': [member.toJson()],
        })}',
    targetEventIds: const [persistenceEventA],
    migrationReceiptId: 'phase_g_legacy_claim',
  );
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw StateError('Expected a JSON object.');
  return value.map((key, value) => MapEntry(key as String, value));
}
```

### 22.23 `packages/map_editor/test/narrative_event_explicit_source_creation_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('NS-EVENT-V2-25 explicit physical source proposal', () {
    test('proposes authorable entity owners with their real dimensions', () {
      final cases = <(
        NarrativeEventPhysicalSourceKind,
        MapEntityKind,
        GridSize,
      )>[
        (
          NarrativeEventPhysicalSourceKind.npc,
          MapEntityKind.npc,
          const GridSize(width: 2, height: 2),
        ),
        (
          NarrativeEventPhysicalSourceKind.sign,
          MapEntityKind.sign,
          const GridSize(width: 1, height: 1),
        ),
        (
          NarrativeEventPhysicalSourceKind.item,
          MapEntityKind.item,
          const GridSize(width: 1, height: 1),
        ),
        (
          NarrativeEventPhysicalSourceKind.invisible,
          MapEntityKind.custom,
          const GridSize(width: 1, height: 1),
        ),
      ];

      for (final (physicalKind, entityKind, size) in cases) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _map();
        final beforeState = EditorState(
          activeMap: map,
          savedMapSnapshot: map,
          selectedEntityId: 'selected_before',
          selectedTriggerId: 'trigger_before',
          isDirty: false,
        );
        notifier.state = beforeState;

        final proposal = notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 3, y: 4),
          kind: physicalKind,
        );

        expect(proposal, isNotNull, reason: physicalKind.name);
        final created = proposal!.afterMap.entities.single;
        expect(created.kind, entityKind, reason: physicalKind.name);
        expect(created.pos, const GridPos(x: 3, y: 4));
        expect(created.size, size);
        expect(
          proposal.bounds,
          MapRect(pos: const GridPos(x: 3, y: 4), size: size),
        );
        expect(
          proposal.source,
          NarrativeEventSourceRef.entityInteract(map.id, created.id),
        );
        expect(
            created.npc, entityKind == MapEntityKind.npc ? isNotNull : isNull);
        expect(
          created.sign,
          entityKind == MapEntityKind.sign ? isNotNull : isNull,
        );
        expect(
          created.item,
          entityKind == MapEntityKind.item ? isNotNull : isNull,
        );
        if (physicalKind == NarrativeEventPhysicalSourceKind.invisible) {
          expect(created.blocksMovement, isFalse);
          expect(created.editorVisual, isNull);
        }
        expect(proposal.beforeMap, same(map));
        expect(proposal.afterMap.events, isEmpty);
        expect(proposal.afterMap.layers, map.layers);
        expect(notifier.state, same(beforeState));
      }
    });

    test('proposes an exact 1x1 event trigger without a legacy MapEvent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        selectedEntityId: 'entity_before',
      );
      notifier.state = beforeState;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 7, y: 2),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      );

      expect(proposal, isNotNull);
      final created = proposal!.afterMap.triggers.single;
      expect(created.type, TriggerType.event);
      expect(
        created.area,
        const MapRect(
          pos: GridPos(x: 7, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );
      expect(proposal.bounds, created.area);
      expect(
        proposal.source,
        NarrativeEventSourceRef.triggerEnter(map.id, created.id),
      );
      expect(proposal.afterMap.entities, isEmpty);
      expect(proposal.afterMap.events, isEmpty);
      expect(notifier.state, same(beforeState));
    });

    test('proposal leaves dirty state, history, selection and messages intact',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final undo = [MapHistorySnapshot(map: map, selectedEntityId: 'undo')];
      final redo = [MapHistorySnapshot(map: map, selectedTriggerId: 'redo')];
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: _map(name: 'persisted'),
        selectedEntityId: 'entity_before',
        selectedTriggerId: 'trigger_before',
        selectedMapEventId: 'legacy_event_before',
        mapUndoStack: undo,
        mapRedoStack: redo,
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: true,
        statusMessage: 'status before',
        errorMessage: 'error before',
      );
      notifier.state = beforeState;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 1, y: 1),
        kind: NarrativeEventPhysicalSourceKind.sign,
      );

      expect(proposal, isNotNull);
      expect(notifier.state, same(beforeState));
      expect(notifier.state.mapUndoStack, undo);
      expect(notifier.state.mapRedoStack, redo);
    });

    test('uses deterministic IDs unique against existing physical owners', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
          ),
          MapEntity(
            id: 'entity',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 5, y: 5),
          ),
        ],
        triggers: const [
          MapTrigger(
            id: 'trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 8, y: 8),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);

      final firstNpc = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.npc,
      )!;
      final secondNpc = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.npc,
      )!;
      final invisible = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 3, y: 3),
        kind: NarrativeEventPhysicalSourceKind.invisible,
      )!;
      final zone = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 4, y: 4),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;

      expect(firstNpc.source.toJson()['entityId'], 'npc_1');
      expect(secondNpc.source, firstNpc.source);
      expect(secondNpc.ownerFingerprint, firstNpc.ownerFingerprint);
      expect(invisible.source.toJson()['entityId'], 'entity_1');
      expect(zone.source.toJson()['triggerId'], 'trigger_1');
    });

    test('envelops owner JSON and computes a stable canonical fingerprint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);

      final entityProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 3),
        kind: NarrativeEventPhysicalSourceKind.item,
      )!;
      final triggerProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 6, y: 7),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;

      for (final (proposal, ownerKind) in [
        (entityProposal, 'mapEntity'),
        (triggerProposal, 'mapTrigger'),
      ]) {
        expect(proposal.ownerJson['schemaVersion'], 1);
        expect(proposal.ownerJson['ownerKind'], ownerKind);
        expect(proposal.ownerJson['mapId'], map.id);
        expect(
          proposal.ownerJson['sourceId'],
          proposal.source.when(
            entityInteract: (_, entityId) => entityId,
            triggerEnter: (_, triggerId) => triggerId,
            mapEnter: (_) => fail('A created source cannot be mapEnter.'),
            outcomeReceived: (_) =>
                fail('A created source cannot be outcomeReceived.'),
          ),
        );
        expect(proposal.ownerJson['owner'], isA<Map<String, Object?>>());
        expect(
          proposal.ownerFingerprint,
          'sha256:${narrativeEventCanonicalSha256(proposal.ownerJson)}',
        );
        expect(
          () => proposal.ownerJson['mapId'] = 'mutated',
          throwsUnsupportedError,
        );
        expect(
          () => (proposal.ownerJson['owner']! as Map<String, Object?>)['id'] =
              'mutated',
          throwsUnsupportedError,
        );
      }
    });

    test('refuses out-of-bounds placement without clamping or state writes',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(size: const GridSize(width: 5, height: 5));
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        statusMessage: 'unchanged',
      );
      notifier.state = beforeState;

      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 4, y: 4),
          kind: NarrativeEventPhysicalSourceKind.npc,
        ),
        isNull,
      );
      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: -1, y: 0),
          kind: NarrativeEventPhysicalSourceKind.sign,
        ),
        isNull,
      );
      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 5, y: 4),
          kind: NarrativeEventPhysicalSourceKind.zone1x1,
        ),
        isNull,
      );

      final edgeProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 4, y: 4),
        kind: NarrativeEventPhysicalSourceKind.item,
      );
      expect(edgeProposal, isNotNull);
      expect(edgeProposal!.bounds.pos, const GridPos(x: 4, y: 4));
      expect(notifier.state, same(beforeState));
    });

    test('returns null when no map is active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeState = notifier.state;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.sign,
      );

      expect(proposal, isNull);
      expect(notifier.state, same(beforeState));
    });

    test('adopts the persisted map only when the proposal baseline is current',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final undo = [MapHistorySnapshot(map: map)];
      notifier.state = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        mapUndoStack: undo,
        canUndoMap: true,
        selectedTriggerId: 'old_trigger',
      );
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.sign,
      )!;

      final adopted = notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
      );

      expect(adopted, isTrue);
      expect(notifier.state.activeMap, same(proposal.afterMap));
      expect(notifier.state.savedMapSnapshot, same(proposal.afterMap));
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, undo);
      expect(notifier.state.canUndoMap, isTrue);
      expect(
        notifier.state.selectedEntityId,
        proposal.source.toJson()['entityId'],
      );
      expect(notifier.state.selectedTriggerId, isNull);
    });

    test('persisted adoption never overwrites a map changed after proposal',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;
      final concurrentlyChanged = map.copyWith(name: 'Changed concurrently');
      final changedState = notifier.state.copyWith(
        activeMap: concurrentlyChanged,
        isDirty: true,
      );
      notifier.state = changedState;

      final adopted = notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
      );

      expect(adopted, isFalse);
      expect(notifier.state, same(changedState));
      expect(notifier.state.activeMap, same(concurrentlyChanged));
      expect(notifier.state.activeMap!.triggers, isEmpty);
    });
  });
}

MapData _map({
  String name = 'Map A',
  GridSize size = const GridSize(width: 12, height: 10),
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: 'map_a',
    name: name,
    size: size,
    entities: entities,
    triggers: triggers,
  );
}
```

### 22.24 `packages/map_editor/test/narrative_event_source_creation_recovery_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000351';
const _eventBId = 'evt_019abcde-0000-7000-8000-000000000352';

void main() {
  group('NS-EVENT-V2-25 explicit source orchestration', () {
    test('dirty and saving gates run before every durable gateway', () async {
      for (final gates in [
        (mapDirty: true, projectDirty: false, saving: false, code: 'mapDirty'),
        (
          mapDirty: false,
          projectDirty: true,
          saving: false,
          code: 'projectDirty',
        ),
        (
          mapDirty: false,
          projectDirty: false,
          saving: true,
          code: 'saveInProgress',
        ),
      ]) {
        final sourceGateway = _RecordingSourceGateway();
        final registryGateway = _NeverRegistryGateway();
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        );

        final result = await useCase.createAndLink(
          projectPath: '/project/project.json',
          eventId: _eventId,
          proposal: _proposal(),
          mapDirty: gates.mapDirty,
          projectDirty: gates.projectDirty,
          saving: gates.saving,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.blocked,
        );
        expect(result.code, gates.code);
        expect(sourceGateway.commitRequests, isEmpty);
        expect(registryGateway.calls, 0);
      }
    });

    test('rejects a forged proposal before any gateway or project read',
        () async {
      final valid = _proposal();
      final forged = NarrativeEventCreatedSourceProposal(
        physicalKind: valid.physicalKind,
        source: valid.source,
        beforeMap: valid.beforeMap,
        afterMap: valid.afterMap,
        bounds: valid.bounds,
        ownerJson: {
          ...valid.ownerJson,
          'sourceId': 'another_owner',
        },
      );
      final sourceGateway = _RecordingSourceGateway();
      final registryGateway = _NeverRegistryGateway();
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );

      final result = await useCase.createAndLink(
        projectPath: '/project/does-not-exist.json',
        eventId: _eventId,
        proposal: forged,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
          result.status, NarrativeEventExplicitSourceCreationStatus.rejected);
      expect(result.code, 'invalidProposal');
      expect(sourceGateway.commitRequests, isEmpty);
      expect(registryGateway.calls, 0);
    });

    test('accepts an exact proposal when the map has an existing trigger',
        () async {
      const existingTrigger = MapTrigger(
        id: 'existing_trigger',
        name: 'Existing trigger',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 2, height: 1),
        ),
      );
      final proposal = _proposal(
        beforeMap: const MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
          triggers: [existingTrigger],
        ),
      );
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        ),
        operationIdFactory: () => 'existing_trigger_source',
      );

      final result = await useCase.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      final diskMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await File(fixture.session.mapPaths['map_a']!).readAsString(),
          ) as Map,
        ),
      );
      expect(diskMap.triggers, [existingTrigger]);
      expect(diskMap.entities.single.id, 'sign');
    });

    test('commits map then one fresh Event write and finalizes the journal',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final steps = <String>[];
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        steps: steps,
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: steps,
      );
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        operationIdFactory: () => 'explicit_source_test',
      );

      final result = await useCase.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(steps, ['map', 'registry', 'finalize']);
      expect(sourceGateway.commitRequests, hasLength(1));
      expect(
        sourceGateway.commitRequests.single.eventRecordFingerprintBefore,
        narrativeEventRecordCanonicalFingerprint(
          persistenceDraft(id: _eventId),
        ),
      );
      expect(registryGateway.persistRequests, hasLength(1));
      expect(result.previousRegistry, isNotNull);
      expect(result.nextRegistry, isNotNull);
      expect(
        result.nextRegistry!.records.single.draftOrNull!.source,
        proposal.source,
      );
      final diskMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await File(fixture.session.mapPaths['map_a']!).readAsString(),
          ) as Map,
        ),
      );
      expect(diskMap.entities.single.id, 'sign');
      expect(
        (await sourceGateway.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
      );
      expect(await File(result.journal!.journalPath).exists(), isTrue);

      final acknowledged = await useCase.acknowledge(
        projectPath: fixture.projectPath,
        operationId: result.journal!.operationId,
        expectedEventId: _eventId,
        expectedMapId: 'map_a',
      );

      expect(
        acknowledged.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(acknowledged.code, 'eventCommitAcknowledged');
      expect(
        (await sourceGateway.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test(
        'registry failure after map commit is explicit and retry never rewrites the map',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final mapFile = File(fixture.session.mapPaths['map_a']!);
      final beforeMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final beforeManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      final firstSource = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final crashingRegistry = _RecordingRegistryGateway(
        delegate: FileProjectRepository(
          eventRegistryPersistence: NarrativeEventRegistryPersistence(
            faultInjector: (checkpoint) async {
              if (checkpoint ==
                  NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
                throw const FileSystemException('simulated registry crash');
              }
            },
          ),
        ),
        steps: <String>[],
      );
      final first = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: firstSource,
        registryGateway: crashingRegistry,
        operationIdFactory: () => 'explicit_source_retry',
      );

      final interrupted = await first.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(
        interrupted.journal?.state,
        NarrativeEventSpatialLinkJournalState.mapCommitted,
      );
      expect(firstSource.commitRequests, hasLength(1));
      expect(
        (await firstSource.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.blocked,
      );
      final sourceBytesAfterFirst = await mapFile.readAsBytes();
      final afterMapCommitHash =
          narrativeEventBytesFingerprint(sourceBytesAfterFirst);
      final afterMapCommitManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      expect(afterMapCommitHash, isNot(beforeMapHash));
      expect(afterMapCommitManifestHash, beforeManifestHash);

      final retrySource = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final retryRegistry = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final restarted = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: retrySource,
        registryGateway: retryRegistry,
      );
      final retried = await restarted.retry(
        projectPath: fixture.projectPath,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(
        retried.journal?.state,
        NarrativeEventSpatialLinkJournalState.eventCommitted,
      );
      expect(retrySource.commitRequests, isEmpty);
      expect(retryRegistry.recoverCalls, 1);
      expect(retryRegistry.persistRequests, hasLength(1));
      expect(
        await mapFile.readAsBytes(),
        sourceBytesAfterFirst,
      );
      final afterRetryMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final afterRetryManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      expect(afterRetryMapHash, afterMapCommitHash);
      expect(afterRetryManifestHash, isNot(beforeManifestHash));
      expect(
        retried.nextRegistry!.records.single.draftOrNull!.source,
        proposal.source,
      );
      expect(
        (await retrySource.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
      );
      final acknowledged = await restarted.acknowledge(
        projectPath: fixture.projectPath,
        operationId: retried.journal!.operationId,
        expectedEventId: _eventId,
        expectedMapId: 'map_a',
      );
      expect(
        acknowledged.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(
        (await retrySource.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
      // Machine-readable closure evidence for the V2-25 two-commit trace.
      // The hashes prove map-first persistence and a retry that never rewrites
      // the already committed physical source.
      // ignore: avoid_print
      print(
        'PHASE_G_RETRY_HASH_TRACE ${jsonEncode({
              'before': {
                'map': beforeMapHash,
                'manifest': beforeManifestHash,
                'journal': 'absent',
              },
              'afterMapCommit': {
                'map': afterMapCommitHash,
                'manifest': afterMapCommitManifestHash,
                'journal': interrupted.journal!.state.name,
              },
              'afterRetry': {
                'map': afterRetryMapHash,
                'manifest': afterRetryManifestHash,
                'journal': retried.journal!.state.name,
              },
              'afterAcknowledge': {'journal': 'clear'},
            })}',
      );
    });

    test('retry contains an exception while finalizing an already linked Event',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final firstSource = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        finalizeError: const FileSystemException('simulated finalize outage'),
      );
      final first = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: firstSource,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        ),
        operationIdFactory: () => 'already_linked_finalize_exception',
      );
      final interrupted = await first.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(interrupted.code, 'journalFinalizeException');

      final restarted = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
          finalizeError:
              const FileSystemException('simulated retry finalize outage'),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        ),
      );

      final retried = await restarted.retry(
        projectPath: fixture.projectPath,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(retried.code, 'journalFinalizeException');
      expect(retried.journal?.eventId, _eventId);
    });

    test('retry contains an exception during post-recovery reinspection',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final crashingSource = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                NarrativeEventSpatialLinkCheckpoint.afterMapRename) {
              throw const FileSystemException('simulated map commit crash');
            }
          },
        ),
      );
      final first = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: crashingSource,
        registryGateway: _NeverRegistryGateway(),
        operationIdFactory: () => 'post_recovery_reinspection',
      );
      final interrupted = await first.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        interrupted.inspection?.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
      );

      final restarted = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
          throwOnInspectCall: 2,
          inspectError:
              const FileSystemException('simulated reinspection outage'),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        ),
      );

      final retried = await restarted.retry(
        projectPath: fixture.projectPath,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(retried.code, 'sourceReinspectionException');
      expect(retried.journal?.eventId, _eventId);
    });

    test('refuses retry linkage when the Event changed after map commit',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        afterCommit: (_) async {
          final root = await fixture.readRoot();
          root['eventRegistry'] = persistenceRegistry(
            records: [
              persistenceDraft(id: _eventId, name: 'Changed elsewhere'),
            ],
          ).toJson();
          await File(fixture.projectPath).writeAsBytes(
            canonicalizeNarrativeEventJsonUtf8(root),
            flush: true,
          );
        },
      );
      final registryGateway = _NeverRegistryGateway();
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        operationIdFactory: () => 'explicit_source_event_changed',
      );

      final result = await useCase.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result.code, 'eventModified');
      expect(registryGateway.calls, 0);
      expect(
        (await sourceGateway.inspectProject(fixture.projectPath))
            .issues
            .single
            .code,
        'eventRecordChanged',
      );
    });

    test(
        'map mutation immediately before registry persist is attested and writes no Event link',
        () async {
      final proposal = _proposal();
      final registry = persistenceRegistry(
        records: [persistenceDraft(id: _eventId)],
      );
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final mapPath = fixture.session.mapPaths['map_a']!;
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
        beforePersist: (_) async {
          await File(mapPath).writeAsBytes(
            canonicalizeNarrativeEventJsonUtf8(proposal.beforeMap.toJson()),
            flush: true,
          );
        },
      );
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        operationIdFactory: () => 'explicit_source_stale_map_attestation',
      );

      final result = await useCase.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result.code, 'staleMapRevision');
      expect(
        result.persistenceResult?.status,
        NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
      );
      expect(result.persistenceResult?.code, 'staleMapRevision');
      expect(registryGateway.persistRequests, hasLength(1));
      expect(sourceGateway.steps, ['map']);
      final diskProject = decodeValidatedNarrativeEventAuthoringProject(
        await fixture.readBytes(),
      ).manifest;
      final diskRecord = diskProject.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == _eventId,
      );
      expect(diskRecord.draftOrNull?.source, isNull);
    });

    test(
        'cleanup requires a second confirmation and removes only pending owner',
        () async {
      final proposal = _proposal();
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        ),
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final mapFile = File(fixture.session.mapPaths['map_a']!);
      final beforeMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final beforeManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: _NeverRegistryGateway(),
        operationIdFactory: () => 'explicit_source_cleanup',
      );
      final interrupted = await useCase.createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(
        interrupted.journal?.state,
        NarrativeEventSpatialLinkJournalState.mapCommitted,
      );
      final afterMapCommitHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final afterMapCommitManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      expect(afterMapCommitHash, isNot(beforeMapHash));
      expect(afterMapCommitManifestHash, beforeManifestHash);
      expect(
        (await sourceGateway.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
      );

      final notConfirmed = await useCase.cleanup(
        projectPath: fixture.projectPath,
        operationId: 'explicit_source_cleanup',
        confirmed: false,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(notConfirmed.code, 'confirmationRequired');
      expect(sourceGateway.cleanupCalls, 0);

      final cleaned = await useCase.cleanup(
        projectPath: fixture.projectPath,
        operationId: 'explicit_source_cleanup',
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        cleaned.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(sourceGateway.cleanupCalls, 1);
      final afterCleanupMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final afterCleanupManifestHash = narrativeEventBytesFingerprint(
        await fixture.readBytes(),
      );
      expect(afterCleanupMapHash, isNot(afterMapCommitHash));
      expect(afterCleanupManifestHash, beforeManifestHash);
      final diskMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await mapFile.readAsString(),
          ) as Map,
        ),
      );
      expect(diskMap, proposal.beforeMap);
      expect(diskMap.entities, isEmpty);
      expect(
        (await sourceGateway.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
      // Machine-readable closure evidence for the confirmed cleanup rollback
      // of the exact physical owner. The map is reserialized by cleanup, so
      // semantic restoration is asserted above instead of byte identity.
      // ignore: avoid_print
      print(
        'PHASE_G_CLEANUP_HASH_TRACE ${jsonEncode({
              'before': {
                'map': beforeMapHash,
                'manifest': beforeManifestHash,
                'journal': 'absent',
              },
              'afterMapCommit': {
                'map': afterMapCommitHash,
                'manifest': afterMapCommitManifestHash,
                'journal': interrupted.journal!.state.name,
              },
              'afterCleanup': {
                'map': afterCleanupMapHash,
                'manifest': afterCleanupManifestHash,
                'journal': 'clear',
                'entities': diskMap.entities.length,
              },
            })}',
      );
    });

    test(
        'successful disk cleanup remains blocking when the cleaned map cannot be adopted in memory',
        () async {
      final proposal = _proposal();
      final registry = persistenceRegistry(
        records: [persistenceDraft(id: _eventId)],
      );
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final sourceGateway = _RecordingSourceGateway(delegate: repository);
      final interrupted = await NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: _NeverRegistryGateway(),
        operationIdFactory: () => 'cleanup_adoption_failure',
      ).createAndLink(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        proposal: proposal,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      final registryGateway = _CountingClearRegistryGateway();
      final project = ProjectManifest(
        name: 'Cleanup adoption failure project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registry,
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      final projectRoot = p.dirname(fixture.projectPath);
      controller.bindProjectRootPath(projectRoot);
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: proposal.afterMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      await controller.inspectPendingSourceCreation(
        projectRootPath: projectRoot,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(controller.requestSourceCleanupConfirmation(), isTrue);
      var adoptionAttempts = 0;

      final result = await controller.cleanupCreatedSource(
        projectRootPath: projectRoot,
        activeMap: proposal.afterMap,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        beginCleanupInterlock: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) =>
            true,
        releaseCleanupInterlock: ({
          required expectedProjectRootPath,
          required journal,
        }) {},
        adoptPersistedCleanup: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) async {
          adoptionAttempts++;
          return false;
        },
      );

      expect(
        result?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result?.code, 'cleanedMapOutOfSync');
      expect(result?.journal?.source, proposal.source);
      expect(controller.state.lastSourceCreationResult?.code,
          'cleanedMapOutOfSync');
      expect(adoptionAttempts, 1);
      expect(controller.state.isSourceCreationBusy, isFalse);
      final pendingReturn = controller.state.pendingReturn;
      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, same(pendingReturn));
      final diskMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await File(fixture.session.mapPaths['map_a']!).readAsString(),
          ) as Map,
        ),
      );
      expect(diskMap.entities, isEmpty);
      expect(
        controller.completeSourceCleanupReload(
          projectRootPath: projectRoot,
          activeMap: diskMap,
        ),
        isTrue,
      );
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, isNull);
    });

    test('bridge rejects a pending journal for another Event or map', () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      for (final journal in [
        _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
        _pendingJournal(eventId: _eventId, mapId: 'map_b'),
      ]) {
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = NarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
            sourceGateway: sourceGateway,
            registryGateway: registryGateway,
          ),
        );
        addTearDown(controller.dispose);
        controller.bindProjectRootPath('/project');
        expect(
          controller.selectNarrativeEventV2(
            project,
            _eventId,
            groupContext: const NarrativeEventGroupContext.map('map_a'),
          ),
          isTrue,
        );
        final opened = await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(opened.succeeded, isTrue);

        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          inspected?.status,
          NarrativeEventExplicitSourceCreationStatus.rejected,
        );
        expect(inspected?.code, 'pendingJournalMismatch');
        expect(controller.state.lastSourceCreationResult?.journal, isNull);
        expect(controller.requestSourceCleanupConfirmation(), isFalse);
        expect(
          await controller.retrySourceCreation(
            projectRootPath: '/project',
            project: project,
            activeMap: mapA,
            mapDirty: false,
            projectDirty: false,
            saving: false,
            adoptPersistedMap: (_) {
              fail('A mismatched journal must never adopt a map.');
            },
            applyPersistedRegistry: ({
              required expectedProjectRootPath,
              required expectedPreviousRegistry,
              required nextRegistry,
            }) {
              fail('A mismatched journal must never adopt a registry.');
            },
          ),
          isNull,
        );
        expect(
          await controller.cleanupCreatedSource(
            projectRootPath: '/project',
            activeMap: mapA,
            mapDirty: false,
            projectDirty: false,
            saving: false,
            beginCleanupInterlock: ({
              required expectedProjectRootPath,
              required expectedActiveMap,
              required journal,
            }) =>
                true,
            releaseCleanupInterlock: ({
              required expectedProjectRootPath,
              required journal,
            }) {},
            adoptPersistedCleanup: ({
              required expectedProjectRootPath,
              required expectedActiveMap,
              required journal,
            }) {
              fail('A mismatched journal must never adopt a cleanup.');
            },
          ),
          isNull,
        );
        expect(sourceGateway.inspectCalls, 1);
        expect(sourceGateway.recoverCalls, 0);
        expect(sourceGateway.cleanupCalls, 0);
        expect(registryGateway.inspectCalls, 0);
        expect(registryGateway.persistCalls, 0);
      }
    });

    test('bridge exposes recovery only for the exact Event and map token',
        () async {
      final project = _recoveryProject();
      const mapB = MapData(
        id: 'map_b',
        name: 'Map B',
        size: GridSize(width: 8, height: 6),
      );
      final journal = _pendingJournal(eventId: _eventBId, mapId: 'map_b');
      final sourceGateway = _PendingJournalSourceGateway(journal);
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath('/project');
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventBId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
        ),
        isTrue,
      );
      await controller.openMapForMissingSource(
        eventId: _eventBId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        project: project,
        activeMap: mapB,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );

      final inspected = await controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        inspected?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(inspected?.journal, same(journal));
      expect(controller.state.pendingReturn?.eventId, _eventBId);
      expect(
        controller.state.pendingReturn?.groupContext,
        const NarrativeEventGroupContext.map('map_b'),
      );
      expect(controller.requestSourceCleanupConfirmation(), isTrue);
      expect(controller.cancelSourceCleanupConfirmation(), isTrue);
    });

    test(
        'delayed inspection A never applies to navigation B and B starts its own inspection',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      const mapB = MapData(
        id: 'map_b',
        name: 'Map B',
        size: GridSize(width: 8, height: 6),
      );
      final sourceGateway = _DelayedInspectionSourceGateway();
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath('/project');
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final inspectionA = controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(sourceGateway.inspectCalls, 1);

      await controller.openMapForMissingSource(
        eventId: _eventBId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => mapB,
        activateMapSnapshot: (_) => true,
      );
      final inspectionB = controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(sourceGateway.inspectCalls, 2);
      sourceGateway.complete(
        0,
        _pendingJournal(eventId: _eventId, mapId: 'map_a'),
      );
      await inspectionA;
      expect(controller.state.pendingReturn?.eventId, _eventBId);
      expect(controller.state.pendingReturn?.groupContext.mapId, 'map_b');
      expect(controller.state.lastSourceCreationResult?.journal, isNull);
      expect(controller.state.isSourceCreationBusy, isTrue);

      final journalB = _pendingJournal(eventId: _eventBId, mapId: 'map_b');
      sourceGateway.complete(1, journalB);
      final resultB = await inspectionB;

      expect(resultB?.journal, same(journalB));
      expect(
          controller.state.lastSourceCreationResult?.journal, same(journalB));
      expect(controller.state.isSourceCreationBusy, isFalse);
    });

    test(
        'stale inspection after a same-root session rebind releases busy without applying its result',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      final sourceGateway = _DelayedInspectionSourceGateway();
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectSession(
        projectRootPath: '/project',
        project: project,
      );
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final staleInspection = controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(sourceGateway.inspectCalls, 1);
      expect(controller.state.isSourceCreationBusy, isTrue);

      controller.bindProjectSession(
        projectRootPath: '/project',
        project: _recoveryProject(),
      );
      final staleJournal = _pendingJournal(
        eventId: _eventId,
        mapId: 'map_a',
      );
      sourceGateway.complete(0, staleJournal);
      final staleResult = await staleInspection;

      expect(staleResult?.journal, same(staleJournal));
      expect(controller.state.lastSourceCreationResult, isNull);
      expect(controller.state.isSourceCreationBusy, isFalse);

      final freshInspection = controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(sourceGateway.inspectCalls, 2);
      sourceGateway.completeClear(1);
      expect(
        (await freshInspection)?.status,
        NarrativeEventExplicitSourceCreationStatus.clear,
      );
      expect(controller.state.isSourceCreationBusy, isFalse);

      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.navigationMode, isNull);
    });

    test(
        'stale inspection cannot release busy owned by a later source mutation',
        () async {
      final proposal = _proposal();
      final registry = persistenceRegistry(
        records: [persistenceDraft(id: _eventId)],
      );
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final delayedInspection =
          Completer<NarrativeEventSpatialLinkInspection>();
      final commitStarted = Completer<void>();
      final releaseCommit = Completer<void>();
      final sourceGateway = _RecordingSourceGateway(
        delegate: repository,
        inspectOverride: (projectPath, call) {
          if (call == 1) return delayedInspection.future;
          return repository.inspectProject(projectPath);
        },
        beforeCommit: (_) async {
          commitStarted.complete();
          await releaseCommit.future;
        },
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final project = ProjectManifest(
        name: 'Busy ownership project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registry,
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'busy_owner_mutation',
        ),
      );
      addTearDown(controller.dispose);
      final projectRoot = p.dirname(fixture.projectPath);
      controller.bindProjectSession(
        projectRootPath: projectRoot,
        project: project,
      );
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: proposal.beforeMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(
        controller.selectPhysicalSourceKind(proposal.physicalKind),
        isTrue,
      );
      expect(controller.previewSourceCreationProposal(proposal), isTrue);
      final staleInspection = controller.inspectPendingSourceCreation(
        projectRootPath: projectRoot,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(controller.state.isSourceCreationBusy, isTrue);

      controller.bindProjectSession(
        projectRootPath: projectRoot,
        project: ProjectManifest.fromJson(project.toJson()),
      );
      final freshInspection = controller.inspectPendingSourceCreation(
        projectRootPath: projectRoot,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        (await freshInspection)?.status,
        NarrativeEventExplicitSourceCreationStatus.clear,
      );
      expect(controller.state.isSourceCreationBusy, isFalse);

      final confirmation = controller.confirmSourceCreation(
        projectRootPath: projectRoot,
        project: project,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) => true,
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) =>
            true,
      );
      await commitStarted.future;
      expect(controller.state.isSourceCreationBusy, isTrue);

      delayedInspection.complete(
        NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.clear,
        ),
      );
      await staleInspection;
      expect(controller.state.lastSourceCreationResult, isNull);
      expect(controller.state.isSourceCreationBusy, isTrue);

      releaseCommit.complete();
      expect(
        (await confirmation)?.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(controller.state.isSourceCreationBusy, isFalse);
    });

    test(
        'delayed acknowledgement never injects Event A state after navigation switched to Event B',
        () async {
      final proposal = _proposal();
      final recordA = persistenceDraft(id: _eventId);
      final registryA = persistenceRegistry(records: [recordA]);
      final fixture = await createPersistenceFixture(
        registry: registryA,
        map: proposal.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final acknowledgementStarted = Completer<void>();
      final releaseAcknowledgement = Completer<void>();
      final sourceGateway = _RecordingSourceGateway(
        delegate: repository,
        beforeAcknowledge: () async {
          acknowledgementStarted.complete();
          await releaseAcknowledgement.future;
        },
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final projectA = ProjectManifest(
        name: 'Acknowledgement project A',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registryA,
      );
      final projectB = ProjectManifest(
        name: 'Acknowledgement project B',
        maps: projectA.maps,
        tilesets: const [],
        scenes: const [],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            recordA,
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _eventBId,
                name: 'Event B',
                conditions: const [],
                priority: 0,
                order: 1,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'delayed_ack_operation_a',
        ),
      );
      addTearDown(controller.dispose);
      final projectRoot = p.dirname(fixture.projectPath);
      controller.bindProjectSession(
        projectRootPath: projectRoot,
        project: projectA,
      );
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: projectA,
        activeMap: proposal.beforeMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(
        controller.selectPhysicalSourceKind(proposal.physicalKind),
        isTrue,
      );
      expect(controller.previewSourceCreationProposal(proposal), isTrue);

      final confirmation = controller.confirmSourceCreation(
        projectRootPath: projectRoot,
        project: projectA,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) => true,
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) =>
            true,
      );
      await acknowledgementStarted.future;
      expect(controller.state.isSourceCreationBusy, isTrue);

      controller.bindProjectSession(
        projectRootPath: projectRoot,
        project: projectB,
      );
      await controller.openMapForMissingSource(
        eventId: _eventBId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: projectB,
        activeMap: proposal.afterMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final tokenB = controller.state.pendingReturn;
      expect(tokenB?.eventId, _eventBId);

      releaseAcknowledgement.complete();
      final result = await confirmation;

      expect(
        result?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result?.code, 'projectChangedAfterAcknowledgement');
      expect(controller.state.pendingReturn, same(tokenB));
      expect(controller.state.pendingReturn?.eventId, _eventBId);
      expect(controller.state.focusRequest, isNull);
      expect(controller.state.lastSourceCreationResult, isNull);
      expect(controller.state.isSourceCreationBusy, isFalse);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test(
        'journal B appearing between preview A and confirm becomes the only recovery and retry identity',
        () async {
      final previewA = _proposal();
      final durableB = _alternateProposal();
      final record = persistenceDraft(id: _eventId);
      final registry = persistenceRegistry(records: [record]);
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: previewA.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final sourceGateway = _RecordingSourceGateway(
        delegate: repository,
        beforeCommit: (request) async {
          final injected = await repository.commitMap(
            NarrativeEventSpatialLinkMapCommitRequest(
              projectPath: request.projectPath,
              projectRevision: request.projectRevision,
              operationId: 'durable_operation_b_between_preview_and_confirm',
              eventId: request.eventId,
              eventRecordFingerprintBefore:
                  request.eventRecordFingerprintBefore,
              beforeMap: durableB.beforeMap,
              afterMap: durableB.afterMap,
              source: durableB.source,
              sourceOwnerJson: durableB.ownerJson,
              sourceOwnerFingerprint: durableB.ownerFingerprint,
            ),
          );
          expect(
            injected.status,
            NarrativeEventSpatialLinkOperationStatus.mapCommitted,
          );
        },
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final project = ProjectManifest(
        name: 'Concurrent source project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registry,
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'preview_operation_a',
        ),
      );
      addTearDown(controller.dispose);
      final projectRoot = p.dirname(fixture.projectPath);
      controller.bindProjectRootPath(projectRoot);
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: previewA.beforeMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(
        controller.selectPhysicalSourceKind(previewA.physicalKind),
        isTrue,
      );
      expect(controller.previewSourceCreationProposal(previewA), isTrue);
      var adoptedPreviewA = 0;
      var appliedRegistry = 0;

      final confirmation = await controller.confirmSourceCreation(
        projectRootPath: projectRoot,
        project: project,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          adoptedPreviewA++;
          return true;
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          appliedRegistry++;
          return true;
        },
      );

      expect(
        confirmation?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(confirmation?.code, 'pendingSpatialLinkJournal');
      expect(
        confirmation?.journal?.operationId,
        'durable_operation_b_between_preview_and_confirm',
      );
      expect(confirmation?.journal?.source, durableB.source);
      expect(confirmation?.inspection?.journal?.source, durableB.source);
      expect(controller.state.sourceCreationProposal, isNull);
      expect(
        controller.state.lastSourceCreationResult?.journal?.source,
        durableB.source,
      );
      expect(adoptedPreviewA, 0);
      expect(appliedRegistry, 0);
      expect(sourceGateway.acknowledgeCalls, 0);

      final mapPath = fixture.session.mapPaths['map_a']!;
      final durableMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await File(mapPath).readAsString(),
          ) as Map,
        ),
      );
      expect(durableMap, durableB.afterMap);

      final retried = await controller.retrySourceCreation(
        projectRootPath: projectRoot,
        project: project,
        activeMap: durableMap,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          adoptedPreviewA++;
          return true;
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          appliedRegistry++;
          final linked = nextRegistry.records.singleWhere(
            (candidate) => candidate.id == _eventId,
          );
          expect(linked.draftOrNull?.source, durableB.source);
          return true;
        },
      );

      expect(
        retried?.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(retried?.journal?.source, durableB.source);
      expect(controller.state.focusRequest?.source, durableB.source);
      expect(controller.state.pendingReturn?.expectedSource, durableB.source);
      expect(controller.state.sourceCreationProposal, isNull);
      expect(adoptedPreviewA, 0);
      expect(appliedRegistry, 1);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test(
        'retry derives map source and adoption from journal B discovered after preview A',
        () async {
      final previewA = _proposal();
      final durableB = _alternateProposal();
      final record = persistenceDraft(id: _eventId);
      final registry = persistenceRegistry(records: [record]);
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: previewA.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final committedB = await repository.commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: fixture.projectPath,
          projectRevision: fixture.revision,
          operationId: 'durable_operation_b_discovered_by_retry',
          eventId: _eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(record),
          beforeMap: durableB.beforeMap,
          afterMap: durableB.afterMap,
          source: durableB.source,
          sourceOwnerJson: durableB.ownerJson,
          sourceOwnerFingerprint: durableB.ownerFingerprint,
        ),
      );
      expect(
        committedB.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final sourceGateway = _RecordingSourceGateway(delegate: repository);
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final project = ProjectManifest(
        name: 'Retry race project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registry,
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      final projectRoot = p.dirname(fixture.projectPath);
      controller.bindProjectRootPath(projectRoot);
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: previewA.beforeMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(
        controller.selectPhysicalSourceKind(previewA.physicalKind),
        isTrue,
      );
      expect(controller.previewSourceCreationProposal(previewA), isTrue);
      final mapPath = fixture.session.mapPaths['map_a']!;
      final durableMap = MapData.fromJson(
        Map<String, dynamic>.from(
          decodeNarrativeEventJsonStrict(
            await File(mapPath).readAsString(),
          ) as Map,
        ),
      );
      var adoptedPreviewA = 0;
      var appliedRegistryB = 0;

      final retried = await controller.retrySourceCreation(
        projectRootPath: projectRoot,
        project: project,
        activeMap: durableMap,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          adoptedPreviewA++;
          return true;
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          appliedRegistryB++;
          final linked = nextRegistry.records.singleWhere(
            (candidate) => candidate.id == _eventId,
          );
          expect(linked.draftOrNull?.source, durableB.source);
          return true;
        },
      );

      expect(
        retried?.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(retried?.journal?.source, durableB.source);
      expect(controller.state.focusRequest?.source, durableB.source);
      expect(controller.state.sourceCreationProposal, isNull);
      expect(adoptedPreviewA, 0);
      expect(appliedRegistryB, 1);
      expect(sourceGateway.acknowledgeCalls, 1);
    });

    test(
        'durable journal B clears preview A and never adopts or acknowledges the mixed operation',
        () async {
      final previewA = _proposal();
      final durableB = _alternateProposal();
      final record = persistenceDraft(id: _eventId);
      final registry = persistenceRegistry(records: [record]);
      final fixture = await createPersistenceFixture(
        registry: registry,
        map: previewA.beforeMap,
      );
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final mapCommit = await repository.commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: fixture.projectPath,
          projectRevision: fixture.revision,
          operationId: 'durable_operation_b',
          eventId: _eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(record),
          beforeMap: durableB.beforeMap,
          afterMap: durableB.afterMap,
          source: durableB.source,
          sourceOwnerJson: durableB.ownerJson,
          sourceOwnerFingerprint: durableB.ownerFingerprint,
        ),
      );
      expect(
        mapCommit.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final sourceGateway = _RecordingSourceGateway(delegate: repository);
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: <String>[],
      );
      final project = ProjectManifest(
        name: 'Mixed operation project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        scenes: const [],
        eventRegistry: registry,
      );
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath(p.dirname(fixture.projectPath));
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: previewA.beforeMap,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(
        controller.selectPhysicalSourceKind(previewA.physicalKind),
        isTrue,
      );
      expect(controller.previewSourceCreationProposal(previewA), isTrue);

      final inspected = await controller.inspectPendingSourceCreation(
        projectRootPath: p.dirname(fixture.projectPath),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(inspected?.journal?.operationId, 'durable_operation_b');
      expect(controller.state.sourceCreationProposal, isNull);
      var adoptedPreviewA = 0;
      var appliedRegistryB = 0;
      final retried = await controller.retrySourceCreation(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: previewA.beforeMap,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          adoptedPreviewA++;
          return true;
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          appliedRegistryB++;
          return true;
        },
      );

      expect(
        retried?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(retried?.code, 'committedMapOutOfSync');
      expect(controller.state.sourceCreationProposal, isNull);
      expect(controller.state.lastSourceCreationResult?.journal?.source,
          durableB.source);
      expect(adoptedPreviewA, 0);
      expect(appliedRegistryB, 0);
      expect(sourceGateway.acknowledgeCalls, 0);
    });

    test(
        'transient inspection exception preserves the previous journal and retry action',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
      final sourceGateway = _RecordingSourceGateway(
        delegate: _PendingJournalSourceGateway(journal),
        throwOnInspectCall: 2,
        inspectError: const FileSystemException('transient inspection outage'),
      );
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath('/project');
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final recovered = await controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(recovered?.journal, same(journal));

      final transient = await controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(transient?.code, 'inspectionException');
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(controller.state.lastSourceCreationResult?.journal, same(journal));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);
      expect(controller.cancelSourceCleanupConfirmation(), isTrue);

      final retried = await controller.retrySourceCreation(
        projectRootPath: '/project',
        project: project,
        activeMap: mapA,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          fail('A transient inspection failure must not adopt a new preview.');
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          fail('A failed fresh session must not apply a registry.');
        },
      );

      expect(retried, isNotNull);
      expect(retried?.code, 'freshSessionRejected');
      expect(retried?.journal, same(journal));
      expect(sourceGateway.inspectCalls, 3);
    });

    test(
        'retry dirty gates preserve the exact durable recovery without IO or navigation escape',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      for (final gates in [
        (mapDirty: true, projectDirty: false, saving: false, code: 'mapDirty'),
        (
          mapDirty: false,
          projectDirty: true,
          saving: false,
          code: 'projectDirty',
        ),
        (
          mapDirty: false,
          projectDirty: false,
          saving: true,
          code: 'saveInProgress',
        ),
      ]) {
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = NarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
            sourceGateway: sourceGateway,
            registryGateway: registryGateway,
          ),
        );
        addTearDown(controller.dispose);
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final recovered = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        final exactInspection = recovered?.inspection;
        final recoveryToken = controller.state.pendingReturn;
        final sourceInspectionsBefore = sourceGateway.inspectCalls;
        final registryInspectionsBefore = registryGateway.inspectCalls;

        final retried = await controller.retrySourceCreation(
          projectRootPath: '/project',
          project: project,
          activeMap: mapA,
          mapDirty: gates.mapDirty,
          projectDirty: gates.projectDirty,
          saving: gates.saving,
          adoptPersistedMap: (_) {
            fail('A dirty-gated retry must not adopt a map.');
          },
          applyPersistedRegistry: ({
            required expectedProjectRootPath,
            required expectedPreviousRegistry,
            required nextRegistry,
          }) {
            fail('A dirty-gated retry must not apply a registry.');
          },
        );

        expect(retried?.code, gates.code, reason: gates.code);
        expect(
          retried?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
          reason: gates.code,
        );
        expect(retried?.journal, same(journal), reason: gates.code);
        expect(retried?.inspection, same(exactInspection), reason: gates.code);
        expect(
          controller.state.lastSourceCreationResult?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
          reason: gates.code,
        );
        expect(
          controller.state.lastSourceCreationResult?.journal,
          same(journal),
          reason: gates.code,
        );
        expect(sourceGateway.inspectCalls, sourceInspectionsBefore);
        expect(sourceGateway.recoverCalls, 0);
        expect(sourceGateway.cleanupCalls, 0);
        expect(registryGateway.inspectCalls, registryInspectionsBefore);
        expect(registryGateway.persistCalls, 0);

        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, same(recoveryToken));
        var openedDuringRecovery = false;
        expect(
          controller.returnToEvent(
            project: project,
            openExactEvent: ({required eventId, required groupContext}) {
              openedDuringRecovery = true;
            },
          ),
          isFalse,
          reason: gates.code,
        );
        expect(openedDuringRecovery, isFalse);
        expect(controller.state.pendingReturn, same(recoveryToken));
        expect(
          controller.selectPhysicalSourceKind(
            NarrativeEventPhysicalSourceKind.zone1x1,
          ),
          isFalse,
          reason: gates.code,
        );
      }
    });

    test(
        'cleanup dirty gates preserve the exact durable recovery without IO or navigation escape',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      for (final gates in [
        (mapDirty: true, projectDirty: false, saving: false, code: 'mapDirty'),
        (
          mapDirty: false,
          projectDirty: true,
          saving: false,
          code: 'projectDirty',
        ),
        (
          mapDirty: false,
          projectDirty: false,
          saving: true,
          code: 'saveInProgress',
        ),
      ]) {
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = NarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
            sourceGateway: sourceGateway,
            registryGateway: registryGateway,
          ),
        );
        addTearDown(controller.dispose);
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final recovered = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        final exactInspection = recovered?.inspection;
        final recoveryToken = controller.state.pendingReturn;
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
        final sourceInspectionsBefore = sourceGateway.inspectCalls;
        final registryInspectionsBefore = registryGateway.inspectCalls;
        var cleanupInterlockBegins = 0;
        var cleanupInterlockReleases = 0;
        var cleanupAdoptions = 0;

        final cleaned = await controller.cleanupCreatedSource(
          projectRootPath: '/project',
          activeMap: mapA,
          mapDirty: gates.mapDirty,
          projectDirty: gates.projectDirty,
          saving: gates.saving,
          beginCleanupInterlock: ({
            required expectedProjectRootPath,
            required expectedActiveMap,
            required journal,
          }) {
            cleanupInterlockBegins++;
            return true;
          },
          releaseCleanupInterlock: ({
            required expectedProjectRootPath,
            required journal,
          }) {
            cleanupInterlockReleases++;
          },
          adoptPersistedCleanup: ({
            required expectedProjectRootPath,
            required expectedActiveMap,
            required journal,
          }) async {
            cleanupAdoptions++;
            return true;
          },
        );

        expect(cleaned?.code, gates.code, reason: gates.code);
        expect(
          cleaned?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
          reason: gates.code,
        );
        expect(cleaned?.journal, same(journal), reason: gates.code);
        expect(cleaned?.inspection, same(exactInspection), reason: gates.code);
        expect(
          controller.state.lastSourceCreationResult?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
          reason: gates.code,
        );
        expect(
          controller.state.lastSourceCreationResult?.journal,
          same(journal),
          reason: gates.code,
        );
        expect(sourceGateway.inspectCalls, sourceInspectionsBefore);
        expect(sourceGateway.recoverCalls, 0);
        expect(sourceGateway.cleanupCalls, 0);
        expect(registryGateway.inspectCalls, registryInspectionsBefore);
        expect(registryGateway.persistCalls, 0);
        expect(cleanupInterlockBegins, 1);
        expect(cleanupInterlockReleases, 1);
        expect(cleanupAdoptions, 0);

        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, same(recoveryToken));
        var openedDuringRecovery = false;
        expect(
          controller.returnToEvent(
            project: project,
            openExactEvent: ({required eventId, required groupContext}) {
              openedDuringRecovery = true;
            },
          ),
          isFalse,
          reason: gates.code,
        );
        expect(openedDuringRecovery, isFalse);
        expect(controller.state.pendingReturn, same(recoveryToken));
        expect(
          controller.selectPhysicalSourceKind(
            NarrativeEventPhysicalSourceKind.zone1x1,
          ),
          isFalse,
          reason: gates.code,
        );
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
      }
    });

    test(
        'retry releasing a journal that became clear returns cleanly and releases busy',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
      final sourceGateway = _RecordingSourceGateway(
        inspectOverride: (_, call) async {
          if (call == 1) {
            return NarrativeEventSpatialLinkInspection(
              status:
                  NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
              journal: journal,
            );
          }
          return NarrativeEventSpatialLinkInspection(
            status: NarrativeEventSpatialLinkInspectionStatus.clear,
          );
        },
      );
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath('/project');
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final inspected = await controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(inspected?.journal, same(journal));

      final retried = await controller.retrySourceCreation(
        projectRootPath: '/project',
        project: project,
        activeMap: mapA,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        adoptPersistedMap: (_) {
          fail('A clear retry must never adopt a proposal.');
        },
        applyPersistedRegistry: ({
          required expectedProjectRootPath,
          required expectedPreviousRegistry,
          required nextRegistry,
        }) {
          fail('A clear retry must never adopt a registry.');
        },
      );

      expect(
        retried?.status,
        NarrativeEventExplicitSourceCreationStatus.clear,
      );
      expect(retried?.journal, isNull);
      expect(controller.state.isSourceCreationBusy, isFalse);
      expect(controller.state.sourceCreationProposal, isNull);
    });

    test(
        'transient cleanup exception preserves the exact recovery and allows another cleanup attempt',
        () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
      final sourceGateway = _PendingJournalSourceGateway(journal);
      final registryGateway = _CountingClearRegistryGateway();
      final controller = NarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: registryGateway,
        ),
        explicitSourceCreationUseCase:
            NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        ),
      );
      addTearDown(controller.dispose);
      controller.bindProjectRootPath('/project');
      await controller.openMapForMissingSource(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: mapA,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      final inspected = await controller.inspectPendingSourceCreation(
        projectRootPath: '/project',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      final exactInspection = inspected?.inspection;
      expect(inspected?.journal, same(journal));
      expect(exactInspection?.journal, same(journal));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final firstFailure = await controller.cleanupCreatedSource(
        projectRootPath: '/project',
        activeMap: mapA,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        beginCleanupInterlock: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) =>
            true,
        releaseCleanupInterlock: ({
          required expectedProjectRootPath,
          required journal,
        }) {},
        adoptPersistedCleanup: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) {
          fail('A failed cleanup must never adopt a map.');
        },
      );

      expect(firstFailure?.code, 'cleanupException');
      expect(firstFailure?.journal, same(journal));
      expect(firstFailure?.inspection, same(exactInspection));
      expect(
        controller.state.lastSourceCreationResult?.journal,
        same(journal),
      );
      expect(
        controller.state.lastSourceCreationResult?.inspection,
        same(exactInspection),
      );
      expect(sourceGateway.cleanupCalls, 1);
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final secondFailure = await controller.cleanupCreatedSource(
        projectRootPath: '/project',
        activeMap: mapA,
        mapDirty: false,
        projectDirty: false,
        saving: false,
        beginCleanupInterlock: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) =>
            true,
        releaseCleanupInterlock: ({
          required expectedProjectRootPath,
          required journal,
        }) {},
        adoptPersistedCleanup: ({
          required expectedProjectRootPath,
          required expectedActiveMap,
          required journal,
        }) {
          fail('A failed cleanup must never adopt a map.');
        },
      );

      expect(secondFailure?.code, 'cleanupException');
      expect(secondFailure?.journal, same(journal));
      expect(secondFailure?.inspection, same(exactInspection));
      expect(sourceGateway.cleanupCalls, 2);
      expect(controller.state.isSourceCreationBusy, isFalse);
      expect(controller.requestSourceCleanupConfirmation(), isTrue);
    });

    test('registry inspection exception keeps the exact source journal context',
        () async {
      final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: _PendingJournalSourceGateway(journal),
        registryGateway: _ThrowingRegistryInspectionGateway(),
      );

      final result = await useCase.retry(
        projectPath: '/project/project.json',
        expectedEventId: _eventId,
        expectedMapId: 'map_a',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result.code, 'registryInspectionException');
      expect(result.journal, same(journal));
      expect(result.inspection?.journal, same(journal));
    });

    test('retry rejects a swapped journal before registry recovery or writing',
        () async {
      final sourceGateway = _PendingJournalSourceGateway(
        _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
      );
      final registryGateway = _CountingClearRegistryGateway();
      var prepareCalls = 0;
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        prepareSession: (_) async {
          prepareCalls++;
          throw StateError('A mismatched journal must not prepare a session.');
        },
      );

      final result = await useCase.retry(
        projectPath: '/project/project.json',
        expectedEventId: _eventId,
        expectedMapId: 'map_a',
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.rejected,
      );
      expect(result.code, 'pendingJournalMismatch');
      expect(result.journal, isNull);
      expect(sourceGateway.inspectCalls, 1);
      expect(sourceGateway.recoverCalls, 0);
      expect(registryGateway.inspectCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(prepareCalls, 0);
    });

    test('cleanup rejects a swapped journal before deleting its owner',
        () async {
      final sourceGateway = _PendingJournalSourceGateway(
        _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
      );
      final useCase = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: sourceGateway,
        registryGateway: _CountingClearRegistryGateway(),
      );

      final result = await useCase.cleanup(
        projectPath: '/project/project.json',
        operationId: sourceGateway.journal.operationId,
        expectedEventId: _eventId,
        expectedMapId: 'map_a',
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventExplicitSourceCreationStatus.rejected,
      );
      expect(result.code, 'pendingJournalMismatch');
      expect(result.journal, isNull);
      expect(sourceGateway.inspectCalls, 1);
      expect(sourceGateway.cleanupCalls, 0);
    });
  });
}

NarrativeEventCreatedSourceProposal _proposal({MapData? beforeMap}) {
  final before = beforeMap ??
      const MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
  const owner = MapEntity(
    id: 'sign',
    name: 'Sign',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 2, y: 2),
    sign: MapEntitySignData(),
  );
  final after = before.copyWith(entities: const [owner]);
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract('map_a', 'sign'),
    beforeMap: before,
    afterMap: after,
    bounds: const MapRect(
      pos: GridPos(x: 2, y: 2),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': 'sign',
      'owner': owner.toJson(),
    },
  );
}

NarrativeEventCreatedSourceProposal _alternateProposal() {
  const before = MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
  );
  const owner = MapEntity(
    id: 'sign_b',
    name: 'Durable sign B',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 5, y: 3),
    sign: MapEntitySignData(),
  );
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract('map_a', owner.id),
    beforeMap: before,
    afterMap: before.copyWith(entities: const [owner]),
    bounds: const MapRect(
      pos: GridPos(x: 5, y: 3),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': owner.id,
      'owner': owner.toJson(),
    },
  );
}

ProjectManifest _recoveryProject() {
  return ProjectManifest(
    name: 'Recovery binding project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
      ProjectMapEntry(
        id: 'map_b',
        name: 'Map B',
        relativePath: 'maps/map_b.json',
      ),
    ],
    tilesets: const [],
    scenes: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event A',
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventBId,
            name: 'Event B',
            conditions: const [],
            priority: 0,
            order: 1,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

NarrativeEventSpatialLinkJournal _pendingJournal({
  required String eventId,
  required String mapId,
}) {
  const owner = MapEntity(
    id: 'pending_owner',
    name: 'Pending owner',
    kind: MapEntityKind.custom,
    pos: GridPos(x: 2, y: 2),
  );
  final ownerJson = Map<String, Object?>.from(
    (jsonDecode(jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': mapId,
      'sourceId': owner.id,
      'owner': owner.toJson(),
    })) as Map)
        .cast<String, Object?>(),
  );
  final ownerFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(ownerJson),
  );
  final projectFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'project': mapId}),
  );
  final eventFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'event': eventId}),
  );
  final mapFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'map': mapId}),
  );
  return NarrativeEventSpatialLinkJournal(
    schemaVersion: 1,
    operationId: 'pending_${eventId.hashCode.abs()}_${mapId.hashCode.abs()}',
    projectPath: '/project/project.json',
    projectRevision: projectFingerprint,
    journalPath: '/project/pending.journal.json',
    mapPath: '/project/maps/$mapId.json',
    mapTempPath: '/project/maps/$mapId.tmp',
    mapId: mapId,
    eventId: eventId,
    eventRecordFingerprintBefore: eventFingerprint,
    source: NarrativeEventSourceRef.entityInteract(mapId, owner.id),
    sourceOwnerJson: ownerJson,
    sourceOwnerFingerprint: ownerFingerprint,
    beforeMapHash: mapFingerprint,
    afterMapHash: mapFingerprint,
    state: NarrativeEventSpatialLinkJournalState.mapCommitted,
    preparedAt: DateTime.utc(2026, 7, 15, 12),
    mapCommittedAt: DateTime.utc(2026, 7, 15, 12, 0, 1),
    cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
  );
}

final class _DelayedInspectionSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  final _inspections = <Completer<NarrativeEventSpatialLinkInspection>>[];

  int get inspectCalls => _inspections.length;

  void complete(int index, NarrativeEventSpatialLinkJournal journal) {
    _inspections[index].complete(
      NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
        journal: journal,
      ),
    );
  }

  void completeClear(int index) {
    _inspections[index].complete(
      NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.clear,
      ),
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    final inspection = Completer<NarrativeEventSpatialLinkInspection>();
    _inspections.add(inspection);
    return inspection.future;
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A delayed inspection must never acknowledge an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) {
    throw StateError('A delayed inspection must never clean a source.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw StateError('A delayed inspection must never commit a map.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A delayed inspection must never finalize an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    throw StateError('A delayed inspection must never recover a source.');
  }
}

final class _PendingJournalSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _PendingJournalSourceGateway(this.journal);

  final NarrativeEventSpatialLinkJournal journal;
  int inspectCalls = 0;
  int recoverCalls = 0;
  int cleanupCalls = 0;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A recovery inspection must never acknowledge an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    throw StateError('A mismatched journal must never be cleaned.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw StateError('A recovery inspection must never commit a map.');
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    inspectCalls++;
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
      journal: journal,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A recovery inspection must never finalize an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    recoverCalls++;
    throw StateError('A mismatched journal must never be recovered.');
  }
}

final class _CountingClearRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int inspectCalls = 0;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    inspectCalls++;
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('A mismatched journal must never persist an Event.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('A mismatched journal must never recover a registry.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('A mismatched journal must never undo a registry.');
  }
}

final class _ThrowingRegistryInspectionGateway
    implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw const FileSystemException('transient registry inspection outage');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    throw StateError('A failed registry inspection must not persist.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('A failed registry inspection must not recover.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('A failed registry inspection must not undo.');
  }
}

final class _RecordingSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _RecordingSourceGateway({
    this.delegate,
    List<String>? steps,
    this.beforeAcknowledge,
    this.beforeCommit,
    this.afterCommit,
    this.finalizeError,
    this.throwOnInspectCall,
    this.inspectError,
    this.inspectOverride,
  }) : steps = steps ?? <String>[];

  final NarrativeEventSpatialSourceCreationGateway? delegate;
  final List<String> steps;
  final Future<void> Function()? beforeAcknowledge;
  final Future<void> Function(
      NarrativeEventSpatialLinkMapCommitRequest request)? beforeCommit;
  final Future<void> Function(NarrativeEventSpatialLinkOperationResult result)?
      afterCommit;
  final Object? finalizeError;
  final int? throwOnInspectCall;
  final Object? inspectError;
  final Future<NarrativeEventSpatialLinkInspection> Function(
    String projectPath,
    int call,
  )? inspectOverride;
  final commitRequests = <NarrativeEventSpatialLinkMapCommitRequest>[];
  int acknowledgeCalls = 0;
  int cleanupCalls = 0;
  int inspectCalls = 0;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    acknowledgeCalls++;
    await beforeAcknowledge?.call();
    final target = delegate;
    if (target == null) {
      throw StateError('acknowledgeEventCommitted must be gated in this test.');
    }
    return target.acknowledgeEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    commitRequests.add(request);
    steps.add('map');
    final target = delegate;
    if (target == null) {
      throw StateError('commitMap must be gated in this test.');
    }
    await beforeCommit?.call(request);
    final result = await target.commitMap(request);
    await afterCommit?.call(result);
    return result;
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    final target = delegate;
    if (target == null) {
      throw StateError('cleanupSource must be gated in this test.');
    }
    return target.cleanupSource(
      projectPath: projectPath,
      operationId: operationId,
      confirmed: confirmed,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    inspectCalls++;
    if (inspectCalls == throwOnInspectCall) {
      throw inspectError ?? StateError('Simulated inspection failure.');
    }
    final override = inspectOverride;
    if (override != null) return override(projectPath, inspectCalls);
    final target = delegate;
    if (target == null) {
      throw StateError('inspectProject must be gated in this test.');
    }
    return target.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    steps.add('finalize');
    if (finalizeError case final error?) throw error;
    final target = delegate;
    if (target == null) {
      throw StateError('markEventCommitted must be gated in this test.');
    }
    return target.markEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    final target = delegate;
    if (target == null) {
      throw StateError('recoverProject must be gated in this test.');
    }
    return target.recoverProject(
      projectPath: projectPath,
      expectedOperationId: expectedOperationId,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedSource: expectedSource,
    );
  }
}

final class _RecordingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingRegistryGateway({
    required this.delegate,
    required this.steps,
    this.beforePersist,
  });

  final NarrativeEventRegistryPersistenceGateway delegate;
  final List<String> steps;
  final Future<void> Function(NarrativeEventRegistryWriteRequest request)?
      beforePersist;
  final persistRequests = <NarrativeEventRegistryWriteRequest>[];
  int recoverCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    return delegate.inspectRecovery(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    steps.add('registry');
    persistRequests.add(request);
    await beforePersist?.call(request);
    return delegate.persist(request);
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    recoverCalls++;
    steps.add('registry-recover');
    return delegate.recover(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    return delegate.undo(undoPath);
  }
}

final class _NeverRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int calls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }
}
```

### 22.25 `packages/map_editor/test/narrative_event_spatial_source_link_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000311';

void main() {
  group('NS-EVENT-V2-24 spatial source link use case', () {
    test('replaces a disabled/draft source and persists exactly once',
        () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'v2_24_replace',
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventSpatialSourceLinkStatus.committed,
        reason: '${result.code}: ${result.message}',
      );
      expect(gateway.requests, hasLength(1));
      expect(
        result.nextRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
    });

    test('same source is a no-op with zero persistence write', () async {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(source: source),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: source,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.noOp);
      expect(gateway.requests, isEmpty);
    });

    test('selects a source for a source-less draft exactly once', () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(source: null),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.committed);
      expect(result.authoringResult?.mutation.name, 'selectSource');
      expect(gateway.requests, hasLength(1));
    });

    test('replaces a configured disabled source and keeps it disabled',
        () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          configured: true,
        ),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventSpatialSourceLinkStatus.committed,
        reason: '${result.code}: ${result.message}',
      );
      expect(result.nextRegistry!.records.single.enabledOrNull, isFalse);
      expect(gateway.requests, hasLength(1));
    });

    test('rejects a nonspatial outcome before preparation and writing',
        () async {
      var prepareCalls = 0;
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
        prepareSession: (_) async {
          prepareCalls++;
          throw StateError('must not prepare');
        },
      )(
        projectPath: '/unused/project.json',
        eventId: _eventId,
        source: NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_a',
            outcomeId: 'done',
          ),
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(result.code, 'nonSpatialSource');
      expect(prepareCalls, 0);
      expect(gateway.requests, isEmpty);
    });

    test('dirty and saving gates run before session preparation', () async {
      for (final flags in <(bool, bool, bool)>[
        (true, false, false),
        (false, true, false),
        (false, false, true),
      ]) {
        var prepareCalls = 0;
        final gateway = _RecordingGateway();
        final useCase = NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async {
            prepareCalls++;
            throw StateError('must not prepare');
          },
        );

        final result = await useCase(
          projectPath: '/unused/project.json',
          eventId: _eventId,
          source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
          mapDirty: flags.$1,
          projectDirty: flags.$2,
          saving: flags.$3,
        );

        expect(result.status, NarrativeEventSpatialSourceLinkStatus.blocked);
        expect(prepareCalls, 0);
        expect(gateway.requests, isEmpty);
      }
    });

    test('enabled Event rejection and stale persistence never double-write',
        () async {
      final enabledFixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          configuredEnabled: true,
        ),
      );
      addTearDown(enabledFixture.dispose);
      final enabledGateway = _RecordingGateway();
      final enabled = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: enabledGateway,
      )(
        projectPath: enabledFixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(enabled.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(enabled.code, 'mustDisableFirst');
      expect(enabledGateway.requests, isEmpty);

      final staleFixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
        ),
      );
      addTearDown(staleFixture.dispose);
      final staleGateway = _RecordingGateway(
        result: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Stale.',
        ),
      );
      final stale = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: staleGateway,
      )(
        projectPath: staleFixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(stale.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(stale.code, 'staleRevision');
      expect(staleGateway.requests, hasLength(1));
    });
  });
}

NarrativeEventRegistry _registry({
  required NarrativeEventSourceRef? source,
  bool configured = false,
  bool configuredEnabled = false,
}) {
  final record = configured || configuredEnabled
      ? NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Event',
            source: source!,
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: configuredEnabled,
        )
      : NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        );
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: [record],
    legacyClaims: const [],
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 10, height: 8),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Entity A',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'trigger_a',
          name: 'Trigger A',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 4, y: 3),
            size: GridSize(width: 2, height: 1),
          ),
        ),
      ],
    );

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({NarrativeEventRegistryPersistenceResult? result})
      : result = result ??
            NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus.committed,
              code: 'committed',
              message: 'Committed.',
            );

  final NarrativeEventRegistryPersistenceResult result;
  final List<NarrativeEventRegistryWriteRequest> requests = [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    requests.add(request);
    return result;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
```

### 22.26 `packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:map_editor/src/ui/canvas/events/narrative_event_map_return_panel.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:path/path.dart' as p;

import '../../support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000361';

void main() {
  group('NS-EVENT-V2-25 map source creation banner', () {
    testWidgets(
        'source-less CTA exposes five types and map tap previews before legacy callback',
        (tester) async {
      final sourceGateway = _RecordingSourceGateway();
      final registryGateway = _RecordingRegistryGateway();
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final project = _project();
      final beforeMapHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(map.toJson()),
      );
      final beforeManifestHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(project.toJson()),
      );
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        activeMap: map,
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      var legacyPositionCalls = 0;
      await _pump(
        tester,
        container,
        onLegacyPosition: (_) => legacyPositionCalls++,
      );

      await _openCreationFromEventPanel(tester, controller);

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      for (final kind in NarrativeEventPhysicalSourceKind.values) {
        expect(
          find.byKey(ValueKey('narrative-event-create-kind-${kind.name}')),
          findsOneWidget,
        );
      }
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
      expect(find.textContaining('Choisir une map'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-sign')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      final proposal = controller.state.sourceCreationProposal;
      expect(proposal, isNotNull);
      expect(proposal!.physicalKind, NarrativeEventPhysicalSourceKind.sign);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.isDirty, isFalse);
      expect(legacyPositionCalls, 0);
      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('narrative-event-create-cancel-preview'),
          ),
          matching: find.text('Annuler'),
        ),
        findsOneWidget,
      );
      expect(find.text('Annuler l’aperçu'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('narrative-event-create-confirm'),
          ),
          matching: find.text('Enregistrer et lier'),
        ),
        findsOneWidget,
      );
      expect(find.text('Créer et lier'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cancel-preview'),
        ),
      );
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNull);
      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(notifier.state.activeMap, same(map));
      final afterCancelMapHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(
          notifier.state.activeMap!.toJson(),
        ),
      );
      final afterCancelManifestHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(
          notifier.state.project!.toJson(),
        ),
      );
      expect(afterCancelMapHash, beforeMapHash);
      expect(afterCancelManifestHash, beforeManifestHash);
      // Machine-readable proof that cancelling a preview performs no map or
      // manifest write before the durable two-commit workflow starts.
      // ignore: avoid_print
      print(
        'PHASE_G_CANCEL_HASH_TRACE ${jsonEncode({
              'before': {
                'map': beforeMapHash,
                'manifest': beforeManifestHash,
                'journal': 'absent',
              },
              'afterCancel': {
                'map': afterCancelMapHash,
                'manifest': afterCancelManifestHash,
                'journal': 'absent',
              },
            })}',
      );
    });

    testWidgets(
        'confirm persists map then Event and returns to the exact draft',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final steps = <String>[];
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        steps: steps,
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: steps,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('narrative-event-create-kind-zone1x1'),
            ),
          )
          .onPressed!();
      await tester.pump();
      expect(
        controller.state.sourceCreationKind,
        NarrativeEventPhysicalSourceKind.zone1x1,
      );
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNotNull);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-confirm'),
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-confirm')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult != null) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source creation did not complete within two seconds.');
      });
      await tester.pump();

      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
        reason:
            '${controller.state.lastSourceCreationResult?.code}: ${controller.state.lastSourceCreationResult?.message}',
      );
      expect(steps, ['map', 'registry', 'finalize']);
      expect(sourceGateway.commitCalls, 1);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(registryGateway.persistCalls, 1);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(notifier.state.activeMap!.triggers, hasLength(1));
      expect(notifier.state.isDirty, isFalse);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.triggerEnter(
          'map_a',
          notifier.state.activeMap!.triggers.single.id,
        ),
      );
      final diskMap = (await tester.runAsync(() async {
        return MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(
              await File(fixture.session.mapPaths['map_a']!).readAsString(),
            ) as Map,
          ),
        );
      }))!;
      expect(diskMap.triggers, hasLength(1));
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets('busy state blocks double submit and cancel until commit ends',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      var allowPrepare = false;
      final sourceGateway = _RecordingSourceGateway(
        syntheticCommit: true,
      );
      final registryGateway = _RecordingRegistryGateway(
        syntheticCommit: true,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        explicitUseCase: NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          prepareSession: (_) async {
            while (!allowPrepare) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            return fixture.session;
          },
          operationIdFactory: () => 'banner_busy_source',
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-item')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNotNull);
      expect(controller.state.projectRootPath, notifier.state.projectRootPath);
      expect(controller.state.pendingReturn, isNotNull);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      expect(controller.state.isSourceCreationBusy, isFalse);

      await tester.runAsync(() async {
        final token = controller.state.pendingReturn;
        final pending = controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap:
              notifier.adoptPersistedNarrativeEventSourceProposal,
          applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.isSourceCreationBusy, isTrue);
        expect(sourceGateway.commitCalls, 0);
        final duplicate = await controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap:
              notifier.adoptPersistedNarrativeEventSourceProposal,
          applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
        );
        expect(duplicate?.code, 'sourceCreationInProgress');
        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, same(token));
        allowPrepare = true;
        await pending.timeout(const Duration(seconds: 2));
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 1);
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        reason:
            '${controller.state.lastSourceCreationResult?.code}: ${controller.state.lastSourceCreationResult?.message}',
      );
      expect(controller.state.lastSourceCreationResult?.code, 'sourceMissing');
      expect(registryGateway.persistCalls, 0);
    });

    testWidgets(
        'source map commit publishes the shared lease before rename and blocks a stale normal save',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final beforeMapRename = Completer<void>();
      final releaseMapRename = Completer<void>();
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(
          faultInjector: (checkpoint) async {
            if (checkpoint !=
                NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
              return;
            }
            if (!beforeMapRename.isCompleted) beforeMapRename.complete();
            await releaseMapRename.future;
          },
        ),
      );
      final mapRepository = _RejectingMapRepository();
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('narrative-event-create-kind-sign'),
            ),
          )
          .onPressed!();
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-confirm')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (beforeMapRename.isCompleted) return;
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult != null) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source commit did not reach map rename: '
            '${controller.state.lastSourceCreationResult?.code} / '
            '${controller.state.lastSourceCreationResult?.message}; '
            'commit calls=${sourceGateway.commitCalls}.');
      });

      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'The Event writer must publish the shared map lease.',
      );
      final sourceBaseline = notifier.state.activeMap;
      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(
        notifier.state.activeMap,
        same(sourceBaseline),
        reason: 'Map edits must not invalidate source adoption mid-commit.',
      );
      final competingProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 9, y: 9),
        kind: NarrativeEventPhysicalSourceKind.item,
      );
      expect(competingProposal, isNotNull);
      expect(
        notifier.adoptPersistedNarrativeEventSourceProposal(
          competingProposal!,
        ),
        isFalse,
        reason: 'Only the lease owner may adopt a persisted map proposal.',
      );
      expect(notifier.state.activeMap, same(sourceBaseline));
      await tester.runAsync(notifier.saveActiveMap);
      expect(
        mapRepository.operationCalls,
        0,
        reason: 'A stale normal save must not enter map IO during commit.',
      );

      await tester.runAsync(() async {
        releaseMapRename.complete();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source creation did not finish after releasing its map rename.');
      });
      await tester.pump();

      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(diskMap.entities, hasLength(1));
    });

    testWidgets(
        'normal project reload owns the lease before IO and Event reload reuses its owner token',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final projectRepository = _SuspendingProjectRepository(
        FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
      );

      late final Future<void> normalReload;
      await tester.runAsync(() async {
        normalReload = notifier.loadProject(
          fixture.projectPath,
          rememberAsRecent: false,
        );
        await projectRepository.loadStarted.future.timeout(
          const Duration(seconds: 2),
        );
      });
      expect(notifier.state.isSaving, isTrue);
      expect(
        notifier.beginNarrativeEventSourceMapWriteLease(),
        isNull,
        reason: 'An Event writer must not overtake a normal project reload.',
      );

      await tester.runAsync(() async {
        projectRepository.releaseLoad.complete();
        await normalReload.timeout(const Duration(seconds: 2));
      });
      expect(notifier.state.isSaving, isFalse);

      final ownerToken = notifier.beginNarrativeEventSourceMapWriteLease();
      expect(ownerToken, isNotNull);
      await tester.runAsync(
        () => notifier.loadProject(
          fixture.projectPath,
          rememberAsRecent: false,
          mapWriteLeaseToken: ownerToken,
        ),
      );
      expect(notifier.state.isSaving, isTrue);
      await tester.runAsync(
        () => notifier.loadMap(
          'maps/map_a.json',
          mapWriteLeaseToken: ownerToken,
        ),
      );
      expect(notifier.state.isSaving, isTrue);
      notifier.endNarrativeEventSourceMapWriteLease(ownerToken!);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap, map);
    });

    testWidgets(
        'failed memory adoption keeps the durable journal and gates false recovery exits',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final projectRepository =
          _SuspendingProjectRepository(FileProjectRepository());
      final mapRepository =
          _LoadDelegatingRejectingSaveMapRepository(FileMapRepository());
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        mapRepository: mapRepository,
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-sign')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      var registryAdoptions = 0;
      final result = await tester.runAsync(
        () => controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) => false,
          applyPersistedRegistry: ({
            required expectedProjectRootPath,
            required expectedPreviousRegistry,
            required nextRegistry,
          }) {
            registryAdoptions++;
            return true;
          },
        ),
      );
      await tester.pump();

      expect(
        result?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result?.code, 'committedMapOutOfSync');
      expect(result?.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(registryAdoptions, 0);
      expect(sourceGateway.acknowledgeCalls, 0);
      expect(
          await tester
              .runAsync(() => File(result!.journal!.journalPath).exists()),
          isTrue);
      expect(
        find.byKey(const ValueKey('narrative-event-create-reload')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-create-retry')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNull,
      );
      final recoveryToken = controller.state.pendingReturn;
      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, same(recoveryToken));
      var openedDuringRecovery = false;
      expect(
        controller.returnToEvent(
          project: project,
          openExactEvent: ({required eventId, required groupContext}) {
            openedDuringRecovery = true;
          },
        ),
        isFalse,
      );
      expect(openedDuringRecovery, isFalse);
      expect(controller.state.pendingReturn, same(recoveryToken));

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-reload')),
            )
            .onPressed!();
        await projectRepository.loadStarted.future.timeout(
          const Duration(seconds: 2),
        );
      });
      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'Reload recovery must own the lease before project IO.',
      );
      await tester.runAsync(notifier.saveActiveMap);
      expect(mapRepository.saveCalls, 0);

      await tester.runAsync(() async {
        projectRepository.releaseLoad.complete();
        for (var attempt = 0; attempt < 300; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed &&
              sourceGateway.acknowledgeCalls == 1) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Reload did not resynchronize and acknowledge the exact Event.');
      });
      await tester.pump();

      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
          await tester
              .runAsync(() => File(result!.journal!.journalPath).exists()),
          isFalse);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        result!.journal!.source,
      );
      expect(
        notifier.state.activeMap!.entities.single.id,
        narrativeEventSpatialSourceOwnerId(result.journal!.source),
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
        'new controller discovers eventCommitted from exact view then reloads and acknowledges',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: FileProjectRepository(),
          operationIdFactory: () => 'banner_restart_event_committed',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: _recoveryProposal(map),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(interrupted.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(
          await tester
              .runAsync(() => File(interrupted.journal!.journalPath).exists()),
          isTrue);
      final diskProject = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringProject(
          await File(fixture.projectPath).readAsBytes(),
        ).manifest;
      }))!;
      final diskMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: diskProject,
        activeMap: diskMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: diskMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          diskProject,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-view-on-map')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.journal?.state ==
                  NarrativeEventSpatialLinkJournalState.eventCommitted) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Exact Event view did not discover eventCommitted recovery.');
      });
      await tester.pump();

      expect(controller.state.navigationMode,
          NarrativeEventMapNavigationMode.view);
      expect(
        find.byKey(const ValueKey('narrative-event-create-reload')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNull,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-reload')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 300; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed &&
              sourceGateway.acknowledgeCalls == 1) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Restarted exact Event recovery did not acknowledge.');
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
          await tester
              .runAsync(() => File(interrupted.journal!.journalPath).exists()),
          isFalse);
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets(
        'new controller exposes recovery, cancels cleanup safely, then retries without rewriting map',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'banner_restart_recovery',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      final diskMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final mapBytesBeforeRetry = (await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
      ))!;
      expect(diskMap.entities, hasLength(1));

      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: diskMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: diskMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-source-on-map'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.recoveryRequired) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Restarted controller did not discover the durable journal.');
      });
      await tester.pump();

      expect(
        find.byKey(const ValueKey('narrative-event-create-retry')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-confirm'),
        ),
        findsOneWidget,
      );
      expect(find.text('Confirmer la suppression'), findsOneWidget);
      expect(sourceGateway.cleanupCalls, 0);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-cancel'),
        ),
      );
      await tester.pump();
      expect(controller.state.cleanupConfirmationRequested, isFalse);
      expect(sourceGateway.cleanupCalls, 0);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-retry')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Recovery retry did not complete.');
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 0);
      expect(sourceGateway.cleanupCalls, 0);
      expect(registryGateway.persistCalls, 1);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(
        notifier.state.project!.eventRegistry!.records,
        hasLength(1),
      );
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        proposal.source,
      );
      expect(
        await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ),
        mapBytesBeforeRetry,
      );
    });

    testWidgets(
        'confirmed cleanup button removes only the pending owner and clears the journal',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'banner_confirmed_cleanup',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      final journalPath = interrupted.journal!.journalPath;
      const independentOwner = MapEntity(
        id: 'independent_sign',
        name: 'Independent sign',
        kind: MapEntityKind.sign,
        pos: GridPos(x: 6, y: 4),
        sign: MapEntitySignData(plainText: 'Preserve me'),
      );
      final committedMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final mapWithIndependentChange = committedMap.copyWith(
        entities: [...committedMap.entities, independentOwner],
      );
      final projectBytesBeforeCleanup = (await tester.runAsync(
        () => File(fixture.projectPath).readAsBytes(),
      ))!;
      await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).writeAsBytes(
          canonicalizeNarrativeEventJsonUtf8(
            mapWithIndependentChange.toJson(),
          ),
          flush: true,
        ),
      );

      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: mapWithIndependentChange,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: mapWithIndependentChange,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      expect(sourceGateway.cleanupCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-confirm'),
        ),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Confirmed cleanup did not complete.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(registryGateway.persistCalls, 0);
      expect(controller.state.cleanupConfirmationRequested, isFalse);
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      final cleanedMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      expect(cleanedMap.entities, [independentOwner]);
      expect(notifier.state.activeMap, cleanedMap);
      expect(notifier.state.savedMapSnapshot, cleanedMap);
      expect(
        identical(
          notifier.state.activeMap,
          notifier.state.savedMapSnapshot,
        ),
        isTrue,
      );
      expect(notifier.state.selectedEntityId, isNull);
      expect(notifier.state.isDirty, isFalse);
      await tester.runAsync(notifier.saveActiveMap);
      final mapAfterSave = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      expect(mapAfterSave.entities, [independentOwner]);
      expect(
        await tester.runAsync(
          () => File(fixture.projectPath).readAsBytes(),
        ),
        projectBytesBeforeCleanup,
      );
      expect(
        decodeValidatedNarrativeEventAuthoringProject(
          projectBytesBeforeCleanup,
        ).manifest.eventRegistry!.records.single.draftOrNull!.source,
        isNull,
      );
      expect(await tester.runAsync(() => File(journalPath).exists()), isFalse);
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets(
        'cleanup CAS mismatch interlocks stale map writes until a map-only reload acknowledges cleanup',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_stale_map_interlock',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      late EditorNotifier notifier;
      late MapData staleConcurrentMap;
      var saveAttemptedDuringCleanup = false;
      var saveBlockedDuringCleanup = false;
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        duringCleanup: () async {
          saveAttemptedDuringCleanup = true;
          await notifier.saveActiveMap();
          saveBlockedDuringCleanup =
              notifier.state.errorMessage?.toLowerCase().contains('recharg') ==
                  true;
        },
        afterCleanup: () async {
          final current = notifier.state;
          final activeMap = current.activeMap!;
          final changedOwner = activeMap.entities.single.copyWith(
            name: 'Owner edited concurrently after cleanup',
          );
          staleConcurrentMap = activeMap.copyWith(entities: [changedOwner]);
          notifier.state = current.copyWith(
            activeMap: staleConcurrentMap,
            isDirty: true,
            isProjectDirty: true,
          );
        },
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanedMapOutOfSync') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose the stale map recovery interlock.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(saveAttemptedDuringCleanup, isTrue);
      expect(
        saveBlockedDuringCleanup,
        isTrue,
        reason: 'The stale-map barrier must be armed before cleanup I/O.',
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.isProjectDirty, isTrue);
      final cleanDiskBytes = (await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
      ))!;
      expect(
        decodeValidatedNarrativeEventAuthoringMap(
          cleanDiskBytes,
          fixture.session.mapPaths['map_a']!,
        ).entities,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final diskMapAfterBlockedSave = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        diskMapAfterBlockedSave.entities,
        isEmpty,
        reason: 'Saving the stale snapshot must not resurrect its owner.',
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));

      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));
      await tester.pump();

      final reloadButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('narrative-event-create-reload')),
      );
      expect(
        reloadButton.onPressed,
        isNotNull,
        reason: 'Cleanup recovery must not deadlock behind dirty state.',
      );
      await tester.runAsync(() async {
        reloadButton.onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned &&
              notifier.state.activeMap?.entities.isEmpty == true) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Map-only reload did not acknowledge the durable cleanup.');
      });
      await tester.pump();

      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(notifier.state.savedMapSnapshot, notifier.state.activeMap);
      expect(notifier.state.isDirty, isFalse);
      expect(
        notifier.state.isProjectDirty,
        isTrue,
        reason: 'Cleanup reload must not discard unrelated manifest edits.',
      );
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(
        controller.state.lastSourceCreationResult?.code,
        'cleanupReloaded',
      );

      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
    });

    testWidgets(
        'post-rename cleanup verification failure keeps stale map saves interlocked',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_post_rename_verification',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final cleanupRepository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint !=
              NarrativeEventSpatialLinkCheckpoint.afterCleanupRename) {
            return;
          }
          final mapPath = fixture.session.mapPaths['map_a']!;
          final cleaned = decodeValidatedNarrativeEventAuthoringMap(
            await File(mapPath).readAsBytes(),
            mapPath,
          );
          await FileMapRepository().saveMap(
            cleaned.copyWith(
              mapMetadata: cleaned.mapMetadata.copyWith(
                displayName: 'Post-rename concurrent bytes',
              ),
            ),
            mapPath,
          );
        },
      );
      final sourceGateway = _RecordingSourceGateway(
        delegate: cleanupRepository,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupMapHashMismatch') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose its post-rename verification failure.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(
        decodeValidatedNarrativeEventAuthoringMap(
          (await tester.runAsync(
            () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          ))!,
          fixture.session.mapPaths['map_a']!,
        ).entities,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final afterBlockedSave = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        afterBlockedSave.entities,
        isEmpty,
        reason: 'An uncertain durable cleanup must retain its write barrier.',
      );
      expect(
        afterBlockedSave.mapMetadata.displayName,
        'Post-rename concurrent bytes',
      );
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));
    });

    testWidgets(
        'owner-present reload rebinds an uncertain cleanup lock for an in-process retry',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_owner_reload_retry',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      var failOnce = true;
      final cleanupRepository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (failOnce &&
              checkpoint ==
                  NarrativeEventSpatialLinkCheckpoint
                      .afterCleanupJournalMarked) {
            failOnce = false;
            throw const FileSystemException('one-shot cleanup interruption');
          }
        },
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(delegate: cleanupRepository),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupException') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose the one-shot interruption.');
      });
      await tester.pump();

      final originalIdentity = notifier.state.activeMap;
      await tester.runAsync(() => notifier.loadMap('maps/map_a.json'));
      final reloadedOwnerMap = notifier.state.activeMap!;
      expect(reloadedOwnerMap, isNot(same(originalIdentity)));
      expect(reloadedOwnerMap.entities, hasLength(1));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final retried = (await tester.runAsync(
        () => controller.cleanupCreatedSource(
          projectRootPath: notifier.state.projectRootPath,
          activeMap: reloadedOwnerMap,
          mapDirty: notifier.state.isDirty,
          projectDirty: notifier.state.isProjectDirty,
          saving: notifier.state.isSaving,
          beginCleanupInterlock:
              notifier.beginNarrativeEventSourceCleanupInterlock,
          releaseCleanupInterlock:
              notifier.releaseNarrativeEventSourceCleanupInterlock,
          adoptPersistedCleanup:
              notifier.adoptPersistedNarrativeEventSourceCleanup,
        ),
      ))!;

      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    testWidgets(
        'a direct map writer started before cleanup is serialized and cleanup performs no IO',
        (tester) async {
      final map = _tileMap();
      final project = _projectWithTilesets();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_in_flight_map_writer',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final mapRepository = _SuspendingMapRepository(FileMapRepository());
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        activeLayerId: 'ground',
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      late final Future<void> writer;
      await tester.runAsync(() async {
        writer = notifier.assignTilesetToActiveLayer('secondary');
        await mapRepository.saveStarted.future.timeout(
          const Duration(seconds: 2),
        );
      });
      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'The direct writer must publish its lease before map IO.',
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupInterlockUnavailable') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not refuse the in-flight map writer.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 0);
      expect(mapRepository.saveCalls, 1);

      final concurrentMap = notifier.state.activeMap!.copyWith(
        mapMetadata: notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Concurrent editor snapshot',
        ),
      );
      notifier.state = notifier.state.copyWith(
        activeMap: concurrentMap,
        isDirty: true,
      );

      await tester.runAsync(() async {
        mapRepository.releaseSave.complete();
        await writer;
      });
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap, same(concurrentMap));
      expect(notifier.state.activeMap!.mapMetadata.displayName,
          'Concurrent editor snapshot');
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).tilesetId,
        'primary',
        reason: 'A stale writer result must not replace the newer snapshot.',
      );
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(diskMap.entities, hasLength(1));
      expect((diskMap.layers.single as TileLayer).tilesetId, 'secondary');
    });

    testWidgets(
        'a map reload started before cleanup owns the lease and cannot resurrect the cleaned owner',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_in_flight_map_reload',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final mapRepository = _SnapshotSuspendingMapRepository(
        FileMapRepository(),
        staleSnapshot: proposal.afterMap,
      );
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      expect(notifier.state.isSaving, isFalse);
      mapRepository.suspendNextLoad();
      late final Future<void> staleReload;
      await tester.runAsync(() async {
        staleReload = notifier.loadMap('maps/map_a.json');
        await mapRepository.targetLoadStarted.future.timeout(
          const Duration(seconds: 2),
        );
        await mapRepository.snapshotRead.future.timeout(
          const Duration(seconds: 10),
        );
      });
      expect(notifier.state.isSaving, isTrue);
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final blocked = (await tester.runAsync(
        () => controller.cleanupCreatedSource(
          projectRootPath: notifier.state.projectRootPath,
          activeMap: notifier.state.activeMap!,
          mapDirty: notifier.state.isDirty,
          projectDirty: notifier.state.isProjectDirty,
          saving: notifier.state.isSaving,
          beginCleanupInterlock:
              notifier.beginNarrativeEventSourceCleanupInterlock,
          releaseCleanupInterlock:
              notifier.releaseNarrativeEventSourceCleanupInterlock,
          adoptPersistedCleanup:
              notifier.adoptPersistedNarrativeEventSourceCleanup,
        ),
      ))!;
      expect(blocked.code, 'cleanupInterlockUnavailable');
      expect(sourceGateway.cleanupCalls, 0);

      await tester.runAsync(() async {
        mapRepository.releaseLoad.complete();
        await staleReload.timeout(const Duration(seconds: 2));
      });
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final cleaned = (await tester.runAsync(
        () => controller
            .cleanupCreatedSource(
              projectRootPath: notifier.state.projectRootPath,
              activeMap: notifier.state.activeMap!,
              mapDirty: notifier.state.isDirty,
              projectDirty: notifier.state.isProjectDirty,
              saving: notifier.state.isSaving,
              beginCleanupInterlock:
                  notifier.beginNarrativeEventSourceCleanupInterlock,
              releaseCleanupInterlock:
                  notifier.releaseNarrativeEventSourceCleanupInterlock,
              adoptPersistedCleanup:
                  notifier.adoptPersistedNarrativeEventSourceCleanup,
            )
            .timeout(const Duration(seconds: 10)),
      ))!;
      expect(
        cleaned.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(sourceGateway.cleanupCalls, 1);
      expect(notifier.state.activeMap!.entities, isEmpty);

      await tester.runAsync(notifier.saveActiveMap);
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        diskMap.entities,
        isEmpty,
        reason: 'The pre-cleanup reload must never resurrect its snapshot.',
      );
    });

    testWidgets(
        'cleanup interlock blocks map lifecycle IO and duplicate create is rejected before IO',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_lifecycle_interlock',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      final journal = interrupted.journal!;
      final mapRepository = _RejectingMapRepository();
      final projectRepository = _RejectingProjectRepository();
      final container = _container(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
      );
      expect(
        notifier.beginNarrativeEventSourceCleanupInterlock(
          expectedProjectRootPath: p.dirname(fixture.projectPath),
          expectedActiveMap: proposal.afterMap,
          journal: journal,
        ),
        isTrue,
      );

      await notifier.renameMap('map_a', 'map_b');
      await notifier.deleteMap('map_a');
      await notifier.createMap('map_new', 4, 4);

      final switchedMap = map.copyWith(id: 'map_switched');
      notifier.state = notifier.state.copyWith(
        activeMap: switchedMap,
        activeMapPath: p.join(
          p.dirname(fixture.session.mapPaths['map_a']!),
          'map_switched.json',
        ),
        savedMapSnapshot: switchedMap,
      );
      await notifier.createMap('map_new_after_switch', 4, 4);

      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);

      notifier.releaseNarrativeEventSourceCleanupInterlock(
        expectedProjectRootPath: p.dirname(fixture.projectPath),
        journal: journal,
      );
      await notifier.createMap('map_a', 4, 4);

      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);
      expect(notifier.state.errorMessage, contains('existe déjà'));

      await expectLater(
        CreateMapUseCase(mapRepository, projectRepository).execute(
          ProjectFileSystem(p.dirname(fixture.projectPath)),
          project,
          'map_a',
          4,
          4,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);
      await tester.pump();
    });

    testWidgets(
        'cleanup rebases the exact owner deletion over unrelated concurrent map edits',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: repository,
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_concurrent_rebase',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      final journal = interrupted.journal!;
      final cleaned = (await tester.runAsync(
        () => repository.cleanupSource(
          projectPath: fixture.projectPath,
          operationId: journal.operationId,
          confirmed: true,
        ),
      ))!;
      expect(
        cleaned.status,
        NarrativeEventSpatialLinkOperationStatus.cleaned,
      );

      final concurrentMap = proposal.afterMap.copyWith(
        mapMetadata: proposal.afterMap.mapMetadata.copyWith(
          displayName: 'Concurrent map label',
        ),
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(delegate: repository),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: concurrentMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        isDirty: true,
      );

      final adopted = (await tester.runAsync(
        () => notifier.adoptPersistedNarrativeEventSourceCleanup(
          expectedProjectRootPath: p.dirname(fixture.projectPath),
          expectedActiveMap: proposal.afterMap,
          journal: journal,
        ),
      ))!;

      expect(adopted, isTrue);
      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(
        notifier.state.activeMap!.mapMetadata.displayName,
        'Concurrent map label',
      );
      expect(notifier.state.selectedEntityId, isNull);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.savedMapSnapshot!.entities, isEmpty);
      expect(
        notifier.state.savedMapSnapshot!.mapMetadata.displayName,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final savedMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(savedMap.entities, isEmpty);
      expect(savedMap.mapMetadata.displayName, 'Concurrent map label');
    });
  });
}

ProviderContainer _container({
  required NarrativeEventSpatialSourceCreationGateway sourceGateway,
  required NarrativeEventRegistryPersistenceGateway registryGateway,
  NarrativeEventExplicitSourceCreationUseCase? explicitUseCase,
  MapRepository? mapRepository,
  ProjectRepository? projectRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        sourceGateway,
      ),
      narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
        registryGateway,
      ),
      if (explicitUseCase != null)
        narrativeEventExplicitSourceCreationUseCaseProvider.overrideWithValue(
          explicitUseCase,
        ),
      if (mapRepository != null)
        mapRepositoryProvider.overrideWithValue(mapRepository),
      if (projectRepository != null)
        projectRepositoryProvider.overrideWithValue(projectRepository),
    ],
  );
  final editor = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridge = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final workspaceFactory = container.listen(
    projectWorkspaceFactoryProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    workspaceFactory.close();
    bridge.close();
    editor.close();
    container.dispose();
  });
  return container;
}

Future<void> _openCreationFromEventPanel(
  WidgetTester tester,
  NarrativeEventMapBridgeController controller,
) async {
  await tester.runAsync(() async {
    tester
        .widget<PokeMapButton>(
          find.byKey(
            const ValueKey('narrative-event-create-source-on-map'),
          ),
        )
        .onPressed!();
    // The callback opens create mode first, then performs the recovery
    // inspection. Do not mistake the short gap between those awaits for idle.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (var attempt = 0; attempt < 200; attempt++) {
      if (!controller.state.isSourceCreationBusy &&
          controller.state.navigationMode ==
              NarrativeEventMapNavigationMode.create) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('The Event panel did not open source creation mode.');
  });
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container, {
  ValueChanged<GridPos>? onLegacyPosition,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          home: CupertinoPageScaffold(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapCanvas(
                    onEventBuilderPositionChosen: onLegacyPosition,
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: NarrativeEventMapReturnPanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'V2-25 banner project',
    maps: [
      const ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: [],
    scenes: [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event sans source',
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 20, height: 15),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
    );

ProjectManifest _projectWithTilesets() => _project().copyWith(
      tilesets: const [
        ProjectTilesetEntry(
          id: 'primary',
          name: 'Primary',
          relativePath: 'tilesets/primary.png',
        ),
        ProjectTilesetEntry(
          id: 'secondary',
          name: 'Secondary',
          relativePath: 'tilesets/secondary.png',
        ),
      ],
    );

MapData _tileMap() => MapData(
      id: 'map_a',
      name: 'Map A',
      size: const GridSize(width: 20, height: 15),
      layers: [
        TileLayer(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'primary',
          tiles: List<int>.filled(20 * 15, 0),
        ),
      ],
    );

NarrativeEventCreatedSourceProposal _recoveryProposal(MapData beforeMap) {
  const owner = MapEntity(
    id: 'recovery_sign',
    name: 'Recovery sign',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 2, y: 2),
    sign: MapEntitySignData(),
  );
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract(
      beforeMap.id,
      owner.id,
    ),
    beforeMap: beforeMap,
    afterMap: beforeMap.copyWith(entities: const [owner]),
    bounds: const MapRect(
      pos: GridPos(x: 2, y: 2),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': beforeMap.id,
      'sourceId': owner.id,
      'owner': owner.toJson(),
    },
  );
}

final class _RecordingSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _RecordingSourceGateway({
    this.delegate,
    List<String>? steps,
    this.syntheticCommit = false,
    this.duringCleanup,
    this.afterCleanup,
  }) : steps = steps ?? <String>[];

  final NarrativeEventSpatialSourceCreationGateway? delegate;
  final List<String> steps;
  final bool syntheticCommit;
  final Future<void> Function()? duringCleanup;
  final Future<void> Function()? afterCleanup;
  int commitCalls = 0;
  int cleanupCalls = 0;
  int acknowledgeCalls = 0;
  NarrativeEventSpatialLinkJournal? _lastJournal;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    acknowledgeCalls++;
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitAcknowledged',
          message: 'Synthetic acknowledgement.',
          journal: _lastJournal,
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected acknowledgement.');
    return target.acknowledgeEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    commitCalls++;
    steps.add('map');
    final target = delegate;
    if (syntheticCommit) {
      final preparedAt = DateTime.utc(2026, 7, 15, 12);
      final journal = NarrativeEventSpatialLinkJournal(
        schemaVersion: 1,
        operationId: request.operationId,
        projectPath: request.projectPath,
        projectRevision: request.projectRevision,
        journalPath: '${request.projectPath}.spatial.journal',
        mapPath: '${request.projectPath}.map',
        mapTempPath: '${request.projectPath}.map.tmp',
        mapId: request.afterMap.id,
        eventId: request.eventId,
        eventRecordFingerprintBefore: request.eventRecordFingerprintBefore,
        source: request.source,
        sourceOwnerJson: request.sourceOwnerJson,
        sourceOwnerFingerprint: request.sourceOwnerFingerprint,
        beforeMapHash: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(request.beforeMap.toJson()),
        ),
        afterMapHash: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(request.afterMap.toJson()),
        ),
        state: NarrativeEventSpatialLinkJournalState.mapCommitted,
        preparedAt: preparedAt,
        mapCommittedAt: preparedAt.add(const Duration(seconds: 1)),
        cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
      );
      _lastJournal = journal;
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.mapCommitted,
        code: 'mapCommitted',
        message: 'Synthetic map commit.',
        journal: journal,
      );
    }
    if (target == null) throw StateError('Unexpected map write.');
    return target.commitMap(request);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    final target = delegate;
    if (target == null) throw StateError('Unexpected cleanup.');
    await duringCleanup?.call();
    final result = await target.cleanupSource(
      projectPath: projectPath,
      operationId: operationId,
      confirmed: confirmed,
    );
    await afterCleanup?.call();
    return result;
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected inspection.');
    return target.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    steps.add('finalize');
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitted',
          message: 'Synthetic finalization.',
          journal: _lastJournal,
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected finalization.');
    return target.markEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected recovery.');
    return target.recoverProject(
      projectPath: projectPath,
      expectedOperationId: expectedOperationId,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedSource: expectedSource,
    );
  }
}

final class _SuspendingMapRepository implements MapRepository {
  _SuspendingMapRepository(this._delegate);

  final MapRepository _delegate;
  final Completer<void> saveStarted = Completer<void>();
  final Completer<void> releaseSave = Completer<void>();
  int saveCalls = 0;

  @override
  Future<void> deleteMap(String path) => _delegate.deleteMap(path);

  @override
  Future<MapData> loadMap(String path) => _delegate.loadMap(path);

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      _delegate.renameMap(oldPath, newPath);

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls++;
    if (!saveStarted.isCompleted) saveStarted.complete();
    await releaseSave.future;
    await _delegate.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
  }
}

final class _SuspendingProjectRepository implements ProjectRepository {
  _SuspendingProjectRepository(this._delegate);

  final ProjectRepository _delegate;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<void> releaseLoad = Completer<void>();

  @override
  Future<ProjectManifest> loadProject(String path) async {
    if (!loadStarted.isCompleted) loadStarted.complete();
    await releaseLoad.future;
    return _delegate.loadProject(path);
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) =>
      _delegate.saveProject(project, path);
}

final class _SnapshotSuspendingMapRepository implements MapRepository {
  _SnapshotSuspendingMapRepository(
    this._delegate, {
    required this.staleSnapshot,
  });

  final MapRepository _delegate;
  final MapData staleSnapshot;
  Completer<void>? _targetLoadStarted;
  Completer<void>? _snapshotRead;
  Completer<void>? _releaseLoad;
  var _suspendNextLoad = false;

  Completer<void> get targetLoadStarted => _targetLoadStarted!;
  Completer<void> get snapshotRead => _snapshotRead!;
  Completer<void> get releaseLoad => _releaseLoad!;

  void suspendNextLoad() {
    if (_suspendNextLoad) {
      throw StateError('A target map load is already armed.');
    }
    _suspendNextLoad = true;
    _targetLoadStarted = Completer<void>();
    _snapshotRead = Completer<void>();
    _releaseLoad = Completer<void>();
  }

  @override
  Future<void> deleteMap(String path) => _delegate.deleteMap(path);

  @override
  Future<MapData> loadMap(String path) async {
    if (!_suspendNextLoad) return _delegate.loadMap(path);
    _suspendNextLoad = false;
    targetLoadStarted.complete();
    if (!snapshotRead.isCompleted) snapshotRead.complete();
    await releaseLoad.future;
    return staleSnapshot;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      _delegate.renameMap(oldPath, newPath);

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) {
    return _delegate.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
  }
}

final class _LoadDelegatingRejectingSaveMapRepository implements MapRepository {
  _LoadDelegatingRejectingSaveMapRepository(this._delegate);

  final MapRepository _delegate;
  int saveCalls = 0;

  @override
  Future<void> deleteMap(String path) => _delegate.deleteMap(path);

  @override
  Future<MapData> loadMap(String path) => _delegate.loadMap(path);

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      _delegate.renameMap(oldPath, newPath);

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls++;
    throw StateError('A stale normal save reached map IO.');
  }
}

final class _RejectingMapRepository implements MapRepository {
  int operationCalls = 0;

  Never _unexpected(String operation) {
    operationCalls++;
    throw StateError('Unexpected map repository $operation.');
  }

  @override
  Future<void> deleteMap(String path) async => _unexpected('delete');

  @override
  Future<MapData> loadMap(String path) async => _unexpected('load');

  @override
  Future<void> renameMap(String oldPath, String newPath) async =>
      _unexpected('rename');

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async =>
      _unexpected('save');
}

final class _RejectingProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw StateError('Unexpected project repository load.');

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls++;
    throw StateError('Unexpected project repository save.');
  }
}

final class _RecordingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingRegistryGateway({
    this.delegate,
    List<String>? steps,
    this.syntheticCommit = false,
  }) : steps = steps ?? <String>[];

  final NarrativeEventRegistryPersistenceGateway? delegate;
  final List<String> steps;
  final bool syntheticCommit;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry inspection.');
    return target.inspectRecovery(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    steps.add('registry');
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.committed,
          code: 'committed',
          message: 'Synthetic registry commit.',
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry write.');
    return target.persist(request);
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry recovery.');
    return target.recover(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry undo.');
    return target.undo(undoPath);
  }
}

final class _FailingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw StateError('Unexpected registry recovery inspection.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.ioFailure,
      code: 'simulatedRegistryFailure',
      message: 'Simulated post-map registry failure.',
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('Unexpected registry recovery.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('Unexpected registry undo.');
  }
}
```

## Addendum append-only — 2026-07-16 — Gate technique Phase 1

Cet addendum conserve le verdict historique ci-dessus et ajoute les preuves
obtenues lors du montage de la vraie route produit H1. Il ne réécrit pas la
clôture initiale et ne transforme pas G0 en `DONE` tant que S0 n'est pas fermé.

### Preuve technique supersédant le blocker « route produit encore V1 »

- `legacyOnly` monte exclusivement V1 ;
- `dualRead` et `v2Only` montent exclusivement la route V2 ;
- une erreur de snapshot reste fail-closed et propose un retry explicite,
  sans fallback silencieux vers V1 ;
- le round-trip d'un Event spatial ouvre le vrai `MapCanvas`, focalise la
  source exacte, puis restaure le même Event ;
- le round-trip d'un draft sans source ouvre le vrai `MapCanvas`, crée et
  persiste la source physique, revient au même draft et recharge ensuite la
  source depuis le disque ;
- le contexte map d'un draft sans source est désormais isolé par racine de
  projet et ne peut pas fuir vers un autre projet.

Le gate groupé final G + V0 + H1 + H2 a produit :

```text
01:50 +446: All tests passed!
```

La revue indépendante H1 conclut : `TECHNIQUEMENT VALIDÉE`, aucun défaut
P0/P1 restant. La capture Phase 1 est toutefois une preuve du workspace métier
réel, pas de la fenêtre applicative complète. Les captures G demandées pour
chaque variante MapEntity, MapTrigger et `mapEnter`, ainsi que l'approbation V0
par l'utilisateur, restent des preuves formelles manquantes.

### Verdict de l'addendum

`FUNCTIONAL PASS CONFIRMED / FORMAL CLOSURE STILL BLOCKED` : le code et la
matrice ciblée sont verts, mais la dépendance S0, le checkpoint récupérable et
les captures produit exhaustives ne sont pas satisfaits. Le tableau maître et
le dashboard restent donc inchangés.
