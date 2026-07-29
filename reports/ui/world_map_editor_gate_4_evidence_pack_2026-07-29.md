# World Map Editor — Gate 4 Asset workflow

Date de clôture : 2026-07-29

Verdict : **DONE**

Lots couverts :

- `AST-01` — cache image lié à la session projet ;
- `AST-02` — contexte de palette par `(mapId, layerId)` et assignation normale ;
- `AST-03` — navigateur d’assets contextuel, recherchable et folder-aware.

Branche : `main`

Base Gate 4 :
`758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9`

HEAD code avant le présent Evidence Pack :
`9421c33c5ca72d30cfc19232a51bc755cf61d8db`

## 1. Résumé exécutif

Gate 4 remplace le workflow historique « une énorme liste globale de
tilesets » par un contrat d’assets lié au projet, à la carte et au calque.

Le résultat livré garantit notamment :

- un cache image détenu par la session projet, avec clés canoniques,
  fingerprint taille/mtime, variants de décodage, diagnostics typés et
  libération explicite ;
- des handles d’images indépendants pour chaque consommateur afin que le
  canvas et la palette ne puissent pas disposer les pixels de l’autre ;
- une mémoire de palette indexée par carte **et** calque, restaurée lors du
  parcours A → B → A ;
- des recherches, dossiers, collections, récents et favoris session-only qui
  ne modifient ni la map, ni l’historique, ni le disque ;
- une assignation de tileset explicite, refusée avant mutation lorsque le
  calque non vide est incompatible, enregistrée comme une mutation locale
  unique et undoable, puis persistée seulement au prochain Save ;
- un browser d’assets qui n’expose par défaut que les sources assignables,
  permet de révéler les autres en disabled avec une raison lisible et ne
  déduit jamais une catégorie depuis un nom de fichier ;
- une récupération visible lorsqu’une source assignée manque ou qu’une image
  ne peut pas être chargée ;
- la conservation du canvas interactif pendant les renouvellements
  asynchrones d’images, sans adoption d’un batch obsolète.

Statuts de clôture :

| Lot | Statut | Preuve principale |
|---|---|---|
| `AST-01` | **DONE** | cache/provider session-scopés, ownership corrigé, tests cache et lifecycle verts |
| `AST-02` | **DONE** | contexte map+layer, assignation locale/undoable, tests session/notifier/revision verts |
| `AST-03` | **DONE** | projector pur, browser DS, clavier/sémantique/compact/light-dark, tests verts |
| Gate 4 | **DONE** | `flutter test` complet `+4678 ~6`, analyse et build macOS verts, deux revues finales PASS |

## 2. Source de vérité, scope et non-objectifs

Le plan exécuté est :

`docs/superpowers/plans/2026-07-29-world-map-gate-4-assets.md`

Il est ignoré par la règle historique `/docs/*`, n’a pas été forcé dans Git et
figure intégralement en annexe.

Décisions produit verrouillées et respectées :

- la clé de contexte contient `mapId` et `layerId` ;
- parcourir ou sélectionner un asset ne change jamais `MapData`, dirty,
  historique ou disque ;
- la source assignée au calque reste la source durable et prioritaire ;
- aucune réassignation implicite n’est autorisée ;
- les calques non vides incompatibles sont rejetés avant mutation ;
- l’assignation est une mutation locale ordinaire ; seul Save écrit le disque ;
- la taxonomie v1 provient exclusivement des dossiers et scopes déclarés ;
- « Récents » et « Favoris » sont personnels, project-scoped et session-only ;
- les sources incompatibles sont masquées par défaut et révélables disabled ;
- les schémas persistés `map_core` et les formats projet/map restent inchangés.

Non-objectifs conservés :

- Gate 5 : recomposition canvas-first du shell, déplacement des docks/trays et
  isolation plus fine des rebuilds ;
- Gate 6 : certification Magic Mouse, trackpad physique, VoiceOver et parcours
  novice sur projet réaliste ;
- persistance durable des favoris entre deux ouvertures d’application ;
- inférence `character`, `terrain`, `path` ou autre depuis filenames/labels ;
- modification du runtime ou d’un modèle partagé.

## 3. Audit initial

### 3.1 Constat produit relu

L’audit ultra-complet de référence identifiait la cause racine suivante :

> « Pas de contexte d’asset par calque — une valeur globale remplace la relation
> naturelle calque ↔ source. »

La roadmap de cet audit prescrivait pour Gate 4 :

- `AST-01` : invalidation, dispose et diagnostics ;
- `AST-02` : A → B → A, assignabilité, undo/save normalisés ;
- `AST-03` : dossiers, recherche, récents, favoris et taxonomie explicite.

Source relue :

`reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md`

### 3.2 État technique observé avant code

L’inspection initiale a confirmé :

- deux caches statiques séparés (`_TilesetImageCache` et
  `_PaletteImageCache`) sans owner de session projet commun ;
- des échecs de chargement ramenés à `null`, donc non actionnables ;
- des images réutilisées sans contrat clair entre master et consommateurs ;
- une sélection de palette essentiellement globale, insuffisante pour deux
  cartes qui réutilisent le même ID de calque ;
- un fallback de source capable de masquer la source réellement assignée ;
- une assignation historique qui ne suivait pas complètement le lifecycle
  local dirty/undo/save attendu ;
- un sélecteur plat exposant tous les tilesets du projet ;
- aucune projection pure commune pour scopes assignables, folders,
  « Non classé », récents/favoris et raisons disabled.

### 3.3 Risques identifiés avant implémentation

- images disposées par un consommateur encore utilisées par un autre ;
- ancien résultat async adopté après changement de projet ;
- collision de contexte lorsque deux maps partagent le même `layerId` ;
- mutation implicite de map pendant une simple navigation dans la bibliothèque ;
- recherche « intelligente » mais mensongère basée sur les filenames ;
- source durable manquante rendant le browser lui-même inaccessible ;
- régression de l’ancien Tileset Studio non embedded ;
- UI locale hors design system ou couleurs hardcodées ;
- overflow compact, focus/clavier et sémantique insuffisants.

### 3.4 Cadrage Git

Le dépôt était déjà fortement sale. Le travail est resté sur `main` parce que
la politique locale interdit de créer un worktree sans autorisation explicite.
Chaque commit a donc stage uniquement ses chemins Gate 4.

## 4. État Git initial

Commandes :

```bash
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git rev-list --left-right --count origin/main...HEAD
git status --short --untracked-files=all
```

Résultat initial Gate 4 :

```text
branch=main
HEAD=758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9
origin/main=758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9
behind=0
ahead=0
status_count=62
status_breakdown=51 modified, 1 deleted, 10 untracked
```

Les 62 entrées suivantes préexistaient à Gate 4 et ont été tenues hors de tous
les commits :

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart
 M packages/map_editor/test/narrative_global_search_performance_test.dart
 M packages/map_editor/test/narrative_large_project_workspace_performance_test.dart
 M packages/map_editor/test/narrative_template_catalog_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/scene_action_builder_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
```

## 5. Passes indépendantes et verdicts

### 5.1 AST-01 — conformité puis qualité

Les deux passes initiales ont conclu **PASS** sur le contrat fonctionnel du
cache, ses diagnostics et son provider. La passe qualité a cependant conduit à
un durcissement supplémentaire, commité séparément :

`86825ae8790645e7ae71159c1c0aceac58f64c53`
`fix(map-editor): isolate asset image ownership`

Décision issue de cette revue :

- le cache conserve un master ;
- chaque appel consommateur reçoit un clone indépendant ;
- `release` et `dispose` restent idempotents ;
- palette, canvas et cache ne partagent pas le même handle disposable.

### 5.2 AST-02 — conformité puis qualité

Verdict initial : **PASS**, sans blocage après corrections.

Points vérifiés :

- clé `(mapId, layerId)` ;
- restauration de tous les champs A → B → A ;
- sanitation des IDs obsolètes ;
- récents LRU et favoris bornés ;
- reset au remplacement de session projet ;
- assignation explicite locale, une entrée undo, aucune écriture directe ;
- Save seul détecte et arbitre une révision disque concurrente ;
- suppression/undo/redo/réactivation restaurent le bon contexte.

### 5.3 AST-03 — conformité

Verdict : **PASS**, aucun finding Critical ou Important.

La passe avait signalé un libellé mineur `Favorites · session`; il a été
corrigé en `Favoris · session`.

Preuves indépendantes :

- projector + browser : 19/19 ;
- recherche, dossiers, incompatible reveal, disabled reason, assignation,
  clavier et sémantique ;
- aucun `filename`/`relativePath` utilisé comme taxonomie ;
- aucun overflow sur les tailles couvertes.

### 5.4 AST-03 — qualité

Verdict final : **PASS**, aucun blocage.

Vérifications indépendantes :

- projector + browser : 19/19 ;
- suite session/notifier/selectors/projector/browser : 41 tests verts ;
- analyse ciblée des 13 fichiers : aucune issue ;
- format : 0 changement ;
- `git diff --check` : propre.

Findings corrigés pendant la passe :

- raison disabled tronquée ;
- source assignée manquante affichée comme absence de sélection ;
- lacunes clavier/sémantique ;
- collision possible avec un folder ID légal `root` ;
- double mise à jour au clear de recherche ;
- wiring dossier non prouvé ;
- message de récupération différent pour calque vide/non vide ;
- launcher perdu sur échec d’image.

### 5.5 Revue du correctif de clôture

Verdict : **PASS**, aucun finding bloquant ou important.

La revue a confirmé :

- chaque batch remplacé est libéré après la frame ;
- le batch courant est libéré au `dispose` ;
- les résultats consumer sont idempotents ;
- la génération capturée neutralise les anciennes données conservées
  temporairement par `FutureBuilder` ;
- retirer la clé évite le remount de tout le canvas ;
- la fixture pointer assignée à `world` correspond au nouveau contrat ;
- aucun double-dispose ni fuite sur les chemins normaux.

Preuves indépendantes :

- pointer navigation : 18/18 ;
- cache + pointer : 33/33 ;
- analyse ciblée, format et `git diff --check` verts.

### 5.6 Critique finale Gate 4

Verdict : **PASS** après le commit correctif
`9421c33c5ca72d30cfc19232a51bc755cf61d8db`.

Cette passe a volontairement comparé plusieurs archives :

- base `758015c1e` : pointer et Border passent ;
- AST-01 : pointer passe, mais le test Border révèle le remount Semantics ;
- AST-02 : la fixture pointer sans source assignée échoue avant le pinch ;
- HEAD `a8e40ad5c` : les deux échecs sont présents ;
- correction finale : Border + pointer 29/29.

Deux findings importants ont ainsi été détectés puis corrigés :

1. la `ValueKey` du `FutureBuilder` remontait le sous-arbre interactif et
   provoquait une assertion Flutter Semantics ;
2. la fixture « incidental pinch » dépendait de l’ancien rebind implicite et
   devait déclarer explicitement la source de son calque.

Aucun autre finding critique ou important n’est resté ouvert.

## 6. Décisions d’architecture

### 6.1 Ownership image : un master, des handles consommateurs

`EditorImageCache` est le propriétaire de session. Les consommateurs reçoivent
des clones et libèrent uniquement leur handle. Un renouvellement ou la
fermeture du projet ne laisse ainsi ni handle partagé ni owner global.

### 6.2 Cache indexé par identité physique et variant

La clé combine chemin canonique, taille, date de modification et variant de
décodage. Un remplacement au même chemin invalide donc correctement les
pixels. Les couleurs transparentes de tileset restent des variants séparés.

### 6.3 Une session transitoire, une seule vérité durable

`EditorPaletteSession` contient la navigation et les préférences éphémères.
`MapData` conserve seulement l’assignation durable. Le browser ne crée aucune
seconde vérité persistée.

### 6.4 Assignation dans le lifecycle normal de map

`AssignTilesetToMapUseCase` prépare un candidat pur. `EditorNotifier` le publie
via la mutation map ordinaire : dirty local, une entrée undo, pas de lease IO,
pas de mise à jour de `savedMapSnapshot`. Save reste l’unique écriture.

### 6.5 Projection pure du browser

`MapPaletteAssetBrowserProjector` réutilise
`ResolveAssignableTilesetsForMapUseCase`, construit les breadcrumbs depuis
`ProjectTilesetFolder`, projette « Non classé » honnêtement et fournit à l’UI
des états explicites assigned/selected/favorite/recent/assignable/disabled.

### 6.6 Résultats async filtrés sans remonter le canvas

Chaque batch image transporte sa génération. Lors d’un changement de future,
les données d’une génération antérieure sont ignorées, puis libérées après la
frame. Le `FutureBuilder` reste monté : les interactions, le focus et l’arbre
Semantics ne sont pas détruits pour une simple requête image.

## 7. Inventaire complet des fichiers Gate 4

Diff de série code, de la base au commit correctif :

```text
31 fichiers
6914 insertions
258 suppressions
```

### 7.1 Fichiers créés

| Fichier | Zone | Raison et impact |
|---|---|---|
| `docs/superpowers/plans/2026-07-29-world-map-gate-4-assets.md` | plan complet | Cadrage local ignoré par `/docs/*`, inclus intégralement en annexe |
| `reports/ui/world_map_editor_gate_4_evidence_pack_2026-07-29.md` | présent rapport | Audit, preuves, inventaire, critique et clôture ; auto-inclusion récursive impossible |
| `lib/src/app/providers/editor/editor_asset_cache_providers.dart` | provider Riverpod | Owner autoDispose par racine projet |
| `lib/src/application/models/map_palette_asset_browser.dart` | modèles de présentation | Collections, folders, items et raisons disabled |
| `lib/src/application/services/editor_palette_session_service.dart` | service pur | Remember/activate/sanitize/recents/favoris |
| `lib/src/application/services/map_palette_asset_browser_projector.dart` | projector pur | Assignabilité, taxonomie déclarée et tri stable |
| `lib/src/features/editor/state/models/editor_palette_session.dart` | modèles Freezed | Clé map+layer, contexte et session transitoire |
| `lib/src/features/editor/state/models/editor_palette_session.freezed.dart` | généré | Immutabilité/copyWith/égalité des modèles de session |
| `lib/src/ui/assets/editor_image_cache.dart` | cache de session | Fingerprints, diagnostics, variants, clones et dispose |
| `lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart` | UI browser | Recherche, dossiers, collections, actions, diagnostic, clavier et sémantique |
| `test/editor_image_cache_test.dart` | tests AST-01 | Cache, replacement, diagnostics, ownership et provider |
| `test/editor_notifier_palette_context_test.dart` | tests AST-02 | A→B→A, session map+layer et non-mutation |
| `test/editor_palette_session_service_test.dart` | tests purs AST-02 | Sanitation, LRU, favoris, reset et collisions |
| `test/map_palette_asset_browser_projector_test.dart` | tests purs AST-03 | Scope, folders, recherche, collections et disabled |
| `test/map_palette_asset_browser_test.dart` | tests widget AST-03 | Workflow, assignation, recovery, clavier, sémantique et image failure |

Le SHA-256 et le contenu intégral du plan et des treize fichiers Dart créés
figurent en annexe. Le présent rapport est exclu de cette règle récursive.

### 7.2 Fichiers modifiés

| Fichier | Raison et impact |
|---|---|
| `lib/src/application/use_cases/project_tileset_use_cases.dart` | Préparer une assignation pure et réutiliser le resolver de scope |
| `lib/src/features/editor/application/map_editing_controller.dart` | Ne plus contourner le lifecycle local normal de l’assignation |
| `lib/src/features/editor/application/project_session_controller.dart` | Réinitialiser la session palette lors du remplacement projet |
| `lib/src/features/editor/state/editor_notifier.dart` | Synchroniser contextes, recents/favoris, browser et assignation undoable |
| `lib/src/features/editor/state/editor_selectors.dart` | Rendre explicites source assignée, contexte actif et validité de peinture |
| `lib/src/features/editor/state/editor_state.dart` | Stocker la session palette transitoire |
| `lib/src/features/editor/state/editor_state.freezed.dart` | Régénération locale de l’état |
| `lib/src/ui/canvas/map_canvas.dart` | Consommer le cache projet, diagnostics, ownership et batch génération |
| `lib/src/ui/canvas/map_canvas/map_canvas_assets.dart` | Supprimer l’ancien cache statique canvas |
| `lib/src/ui/design_system/pokemap_sidebar_item.dart` | Variante DS à deux lignes pour raison disabled lisible |
| `lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart` | Supprimer l’ancien cache statique palette |
| `lib/src/ui/panels/tileset_palette_panel.dart` | Intégrer le browser embedded tout en gardant le Studio legacy |
| `test/editor_project_session_controller_test.dart` | Prouver le reset de session au changement de projet |
| `test/editor_selectors_test.dart` | Prouver la priorité de la source assignée et les contextes |
| `test/features/editor/state/editor_notifier_map_revision_test.dart` | Prouver assignation locale, undo et conflit seulement au Save |
| `test/map_canvas_pointer_navigation_test.dart` | Fixture de peinture explicitement assignée sous le nouveau contrat |
| `test/map_editing_controller_test.dart` | Prouver l’absence de direct-write lors de l’assignation |
| `test/project_tileset_use_cases_test.dart` | Prouver préparation, assignabilité et refus non vide |

### 7.3 Hunks exacts des fichiers modifiés

Commande de preuve :

```bash
git diff --unified=0 \
  758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9..9421c33c5ca72d30cfc19232a51bc755cf61d8db \
  -- packages/map_editor
```

Hunks exacts, sans regroupement ni omission :

```text
packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart
  @@ -407 +407 @@ class AssignTilesetToMapUseCase {
  @@ -425 +425 @@ class AssignTilesetToMapUseCase {
  @@ -449 +449,4 @@ class AssignTilesetToMapUseCase {
packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart
  @@ -92 +91,0 @@ class MapEditingController {
  @@ -141 +139,0 @@ class MapEditingController {
  @@ -190 +187,0 @@ class MapEditingController {
  @@ -276 +272,0 @@ class MapEditingController {
packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
  @@ -19,0 +20 @@ class ProjectSessionController {
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
  @@ -43,0 +44 @@ import '../../../application/services/editor_map_mutation_coordinator.dart';
  @@ -1987,0 +1989,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -1989 +1992,4 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -1994,4 +2000,8 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -2000,0 +2011 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -2211,0 +2223 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -2221,3 +2233,3 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -2225 +2237 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -2233,0 +2246 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3947,0 +3961 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3962,2 +3975,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3965 +3977,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3976,2 +3989,20 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3981 +4012 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3984 +4014,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -3987,8 +4016,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4000,3 +4022,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4007 +4027,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4009,0 +4030 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4010,0 +4032 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4013,7 +4035,3 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4334,0 +4353,26 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4346,2 +4390,3 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4349 +4394 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4357,0 +4403,14 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4360 +4419,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4370,0 +4431,6 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4379,0 +4446,8 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4413,0 +4488,264 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4443,0 +4782 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4980,0 +5320 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4987,0 +5328 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4992,0 +5334 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -4993,0 +5336 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5002,0 +5346 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5007,0 +5352 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5008,0 +5354 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5013,0 +5360 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5016 +5362,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5018,0 +5365 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5019,0 +5367 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -5134 +5481,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7624,5 +7971,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7745,0 +8090,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7766,2 +8112,3 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7768,0 +8116 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7780,0 +8129,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7801,2 +8151,3 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -7803,0 +8155 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -8522,16 +8873,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -8540 +8875,0 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -8544,5 +8879,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -8551,22 +8883,7 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -8574,13 +8891 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -12359 +12664,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -12360,0 +12667 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -12365 +12672 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -12376,0 +12684 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -13369,0 +13678,2 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -13385,2 +13695,8 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -13387,0 +13704,4 @@ class EditorNotifier extends _$EditorNotifier {
  @@ -13993,6 +14312,0 @@ class _PaintPattern {
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
  @@ -84,0 +85,10 @@ typedef EditorTilesetPaletteSnapshot = ({
  @@ -321,0 +332,45 @@ final editorTilesetPaletteSnapshotProvider =
  @@ -342,2 +397,3 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  @@ -345 +401 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  @@ -350,0 +407,18 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  @@ -353 +427,6 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  @@ -362,0 +442,6 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  @@ -371,0 +457,8 @@ ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
packages/map_editor/lib/src/features/editor/state/editor_state.dart
  @@ -7,0 +8 @@ import 'models/editor_ui_modes.dart';
  @@ -13,0 +15 @@ export 'models/editor_ui_modes.dart';
  @@ -115,0 +118 @@ class EditorState with _$EditorState {
packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
  @@ -1275,0 +1276 @@ mixin _$EditorState {
  @@ -1354,0 +1356 @@ abstract class $EditorStateCopyWith<$Res> {
  @@ -1380,0 +1383 @@ abstract class $EditorStateCopyWith<$Res> {
  @@ -1429,0 +1433 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
  @@ -1570,0 +1575,4 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
  @@ -1727,0 +1736,10 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
  @@ -1795,0 +1814 @@ abstract class _$$EditorStateImplCopyWith<$Res>
  @@ -1828,0 +1848,2 @@ abstract class _$$EditorStateImplCopyWith<$Res>
  @@ -1876,0 +1898 @@ class __$$EditorStateImplCopyWithImpl<$Res>
  @@ -2017,0 +2040,4 @@ class __$$EditorStateImplCopyWithImpl<$Res>
  @@ -2132,0 +2159 @@ class _$EditorStateImpl implements _EditorState {
  @@ -2249,0 +2277,3 @@ class _$EditorStateImpl implements _EditorState {
  @@ -2323 +2353 @@ class _$EditorStateImpl implements _EditorState {
  @@ -2393,2 +2423,3 @@ class _$EditorStateImpl implements _EditorState {
  @@ -2447,0 +2479 @@ class _$EditorStateImpl implements _EditorState {
  @@ -2509,0 +2542 @@ abstract class _EditorState implements EditorState {
  @@ -2603,0 +2637,2 @@ abstract class _EditorState implements EditorState {
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
  @@ -3 +2,0 @@ import 'dart:math' as math;
  @@ -26,0 +26 @@ import 'package:path/path.dart' as p;
  @@ -63,0 +64 @@ import 'entity_editor_element_visual.dart';
  @@ -68,0 +70 @@ import '../design_system/pokemap_badge.dart';
  @@ -96,0 +99,30 @@ bool _isEnvironmentMaskEditing(EditorState state, MapData map) {
  @@ -291,0 +324,5 @@ class MapCanvas extends ConsumerStatefulWidget {
  @@ -379 +416,3 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -455,0 +495,2 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -463,0 +505,20 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -464,0 +526 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -468,0 +531 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -475,0 +539,4 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -481 +548 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -483 +550,26 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -484,0 +577 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -490,0 +584,5 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -524,0 +623 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -554 +653 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -557 +656,13 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
  @@ -1602,0 +1714,26 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart
  @@ -14,62 +13,0 @@ class _ResolvedTerrainFrame {
packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
  @@ -18,0 +19 @@ class PokeMapSidebarItem extends StatefulWidget {
  @@ -23 +24 @@ class PokeMapSidebarItem extends StatefulWidget {
  @@ -53,0 +55,6 @@ class PokeMapSidebarItem extends StatefulWidget {
  @@ -200 +207 @@ class _PokeMapSidebarItemState extends State<PokeMapSidebarItem> {
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart
  @@ -246,21 +245,0 @@ class _TilesetSelectionPainter extends CustomPainter {
packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
  @@ -25,0 +26 @@ import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';
  @@ -31,0 +33,2 @@ import '../../features/editor/tools/editor_tool.dart';
  @@ -32,0 +36 @@ import 'element_collision_editor_sheet.dart';
  @@ -45,0 +50,22 @@ const ElementCollisionAuthoringService _elementCollisionAuthoringService =
  @@ -82,0 +109,3 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -85,0 +115,2 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -90,0 +122,53 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -319,0 +404,14 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -343,5 +441,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -351,0 +452,4 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -367,2 +471,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -370 +479,2 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -371,0 +482 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -382,4 +493,6 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -386,0 +500,4 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -389 +506 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -391,2 +507,0 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -396,0 +512,2 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -443,17 +560,34 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -490,0 +625 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -1302 +1436,0 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -1313,0 +1448 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  @@ -2320 +2455 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
packages/map_editor/test/editor_project_session_controller_test.dart
  @@ -30,0 +31,7 @@ void main() {
  @@ -70,0 +78 @@ void main() {
packages/map_editor/test/editor_selectors_test.dart
  @@ -88,0 +89,142 @@ void main() {
packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
  @@ -134 +134,3 @@ void main() {
  @@ -145 +147,3 @@ void main() {
  @@ -146,0 +151,7 @@ void main() {
  @@ -150,0 +162,12 @@ void main() {
  @@ -153,0 +177,87 @@ void main() {
packages/map_editor/test/map_canvas_pointer_navigation_test.dart
  @@ -1063,0 +1064 @@ const _activeMap = MapData(
packages/map_editor/test/map_editing_controller_test.dart
  @@ -135,0 +136,48 @@ void main() {
packages/map_editor/test/project_tileset_use_cases_test.dart
  @@ -149,0 +150,70 @@ void main() {
  @@ -151,0 +222,32 @@ void main() {
  @@ -176,0 +279,24 @@ class _FakeProjectRepository implements ProjectRepository {
```


## 8. Tests créés ou étendus

### 8.1 AST-01

- missing file non mis en cache ;
- aliases de chemin canonique ;
- hit/miss et diagnostics ;
- remplacement au même path par fingerprint ;
- variants de décodage ;
- decode failure puis récupération ;
- bulk loading et failures typées ;
- handles consommateurs indépendants ;
- dispose idempotent, y compris decode en cours ;
- isolation et invalidation des providers projet.

### 8.2 AST-02

- restauration complète A → B → A ;
- deux maps avec le même layer ID sans collision ;
- sanitation source/groupe/brush/folder/preferences ;
- récents LRU et favoris bornés ;
- reset session au changement de projet ;
- activation, deletion, undo/redo et map revision ;
- source assignée prioritaire ;
- assignation locale, une mutation undoable, aucun IO ;
- refus d’un calque non vide incompatible.

### 8.3 AST-03

- global et ancestor-group assignables ;
- foreign scope caché puis révélé disabled ;
- folder nesting, breadcrumbs et « Non classé » ;
- folder légal nommé `root` sans collision avec l’agrégat ;
- recherche sur métadonnées visibles, jamais filename/path ;
- all/recent/favorite et ordres stables ;
- source manquante, calque vide/non vide et non-tile ;
- recherche/folder/favorite/recent sans dirty ni historique ;
- assignation explicite locale et undoable ;
- launcher conservé sans sélection et après image failure ;
- clavier, focus, Escape et labels sémantiques ;
- light/dark, 420 px compact et 800×600.

### 8.4 Régressions de clôture

- `border_layer_inspector_test.dart` protège le canvas contre le remount
  Semantics pendant une mutation externe au browser ;
- `map_canvas_pointer_navigation_test.dart` protège le stroke owner/pinch avec
  une source désormais explicitement assignée ;
- la suite complète couvre les interactions de ces changements avec les autres
  studios de l’éditeur.

## 9. TDD et corrections issues des revues

### 9.1 AST-01

Les tests cache ont d’abord caractérisé les absences de diagnostics,
d’invalidation et d’owner session. Le premier GREEN a ensuite été durci par la
revue ownership : le cache ne retourne plus directement son master à plusieurs
consommateurs.

### 9.2 AST-02

Les tests purs ont verrouillé la clé map+layer, la sanitation et les
préférences. Les tests notifier/révision ont ensuite imposé l’abandon de
l’écriture directe : l’assignation devient dirty/undoable et le conflit disque
n’apparaît qu’au Save.

### 9.3 AST-03

Le projector a été spécifié avant le widget. Les revues ont ajouté les preuves
de récupération, sémantique, folder UI, incompatibilité lisible, keys non
collisionnelles et image failure.

### 9.4 Full-suite RED puis GREEN

Premier passage complet après AST-03 :

```text
+4676 ~6 -2
Some tests failed.

border_layer_inspector_test.dart
  Border inspector exposes published CRUD and confirms compatible blueprint changes

map_canvas_pointer_navigation_test.dart
  an incidental pinch cannot rollback an owned paint stroke
```

Les deux erreurs ont été reproduites isolément, puis comparées à des archives
du commit de base et des lots intermédiaires.

Diagnostic :

- la clé du `FutureBuilder` remountait le canvas et déclenchait une assertion
  Flutter Semantics ;
- la peinture du test pointer était rejetée avant le pinch parce que sa couche
  n’avait plus le droit d’utiliser implicitement un tileset non assigné.

Correction :

- conserver le `FutureBuilder` monté ;
- capturer une génération avec chaque batch et ignorer un batch obsolète ;
- disposer l’ancien batch après la frame ;
- assigner explicitement `world` à la fixture de peinture.

GREEN final :

```text
+4678 ~6
All tests passed!
```

## 10. Commandes et résultats exacts

Toutes les commandes Flutter ci-dessous ont été lancées depuis
`packages/map_editor`.

### 10.1 Lots

AST-01 :

```bash
flutter test test/editor_image_cache_test.dart
flutter test test/ui_panels_smoke_test.dart
flutter analyze
```

Résultat de lot : tests ciblés verts ; matrice cache/consommateurs portée à
25 tests lors de la passe intégrée ; analyse sans issue.

AST-02 :

```bash
flutter test test/editor_palette_session_service_test.dart
flutter test test/project_tileset_use_cases_test.dart
flutter test test/editor_selectors_test.dart
flutter test test/features/editor/state/editor_notifier_map_revision_test.dart
flutter test test/features/editor/state/editor_notifier_map_activation_test.dart
flutter analyze
```

Résultat de lot : 92 tests focalisés verts ; analyse sans issue.

AST-03 :

```bash
flutter test test/map_palette_asset_browser_projector_test.dart
flutter test test/map_palette_asset_browser_test.dart
flutter test test/tileset_palette_recommended_layer_test.dart
flutter test test/tileset_palette_placed_instance_opacity_test.dart
flutter test test/ui_panels_smoke_test.dart
flutter test test/design_system_guardrail_test.dart
flutter analyze
```

Résultats indépendants : projector + browser 19/19 ; intégration
session/notifier/selectors/projector/browser 41 tests ; analyse sans issue.

### 10.2 Matrice ciblée finale

Commande :

```bash
flutter test \
  test/editor_image_cache_test.dart \
  test/ui_panels_smoke_test.dart \
  test/editor_palette_session_service_test.dart \
  test/editor_project_session_controller_test.dart \
  test/project_tileset_use_cases_test.dart \
  test/editor_selectors_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/editor_notifier_palette_context_test.dart \
  test/map_editing_controller_test.dart \
  test/map_palette_asset_browser_projector_test.dart \
  test/map_palette_asset_browser_test.dart \
  test/tileset_palette_recommended_layer_test.dart \
  test/tileset_palette_placed_instance_opacity_test.dart \
  test/design_system_guardrail_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/border_layer_inspector_test.dart
```

Résultat exact :

```text
+164
All tests passed!
```

### 10.3 Suite complète finale

Commande :

```bash
flutter test
```

Résultat exact :

```text
06:36 +4678 ~6: All tests passed!
```

Les six tests marqués skipped appartiennent à leurs lanes dédiées ; aucun test
exécuté n’échoue.

### 10.4 Analyse finale

Commande :

```bash
flutter analyze
```

Résultat exact :

```text
Analyzing map_editor...
No issues found! (ran in 6.0s)
```

### 10.5 Build final

Commande :

```bash
flutter build macos --debug
```

Résultat exact :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

### 10.6 Garde-fous design system

Commandes :

```bash
rg -n 'Color\(0x|Colors\.|PokeMapPalette' \
  lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart

rg -n '\b(Card|ElevatedButton|OutlinedButton|TextButton|IconButton|FilledButton|Material|Scaffold)\(' \
  lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart
```

Résultat :

```text
PASS: no hardcoded or package-palette colors in new Gate 4 UI
PASS: no ad-hoc Material UI primitives in new Gate 4 UI
```

`test/design_system_guardrail_test.dart` est également inclus dans la matrice
finale verte.

### 10.7 Format et diff

Commandes :

```bash
dart format <fichiers Gate 4>
git diff --check
git diff --check 758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9..HEAD
```

Résultat final : aucun changement de format restant et aucune erreur de
whitespace ; les deux commandes `git diff --check` ne produisent aucune sortie.

## 11. Commits par lot

```text
aa7950bd46584d11f8a6783df51863f06b4f9c72 feat(map-editor): scope asset images to project sessions
f317701294c8b08c0a9655f47dded6c3ac8ee2ab feat(map-editor): scope palette context by map layer
86825ae8790645e7ae71159c1c0aceac58f64c53 fix(map-editor): isolate asset image ownership
a8e40ad5cd3e28cbcb480ca975e5456c2ed268be feat(map-editor): add contextual asset browser
9421c33c5ca72d30cfc19232a51bc755cf61d8db fix(map-editor): preserve canvas lifecycle across asset loads
```

Le premier et le quatrième commit livrent respectivement AST-01 et AST-03. Le
deuxième livre AST-02. Les troisième et cinquième commits sont des corrections
transversales imposées par les revues. Le présent Evidence Pack reçoit un
commit de clôture séparé.

## 12. État Git avant le commit du rapport

Après le commit correctif et avant la création du présent fichier :

```text
branch=main
HEAD=9421c33c5ca72d30cfc19232a51bc755cf61d8db
origin/main=758015c1eec5ae90f3dcbc0b8b724ebdefaf12e9
behind=0
ahead=5
status_count=63
status_count_preexistant=62
status_count_concurrent_hors_gate_4=1
status_count_gate_4_non_commite=0
```

Une modification hors Gate 4 est apparue pendant l’exécution :

```text
 M packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart
```

Elle n’était pas dans les 62 entrées initiales, n’a pas été modifiée ni staged
par Gate 4 et reste entièrement préservée comme travail concurrent.

Après création du rapport, l’unique entrée Gate 4 non commitée est :

```text
?? reports/ui/world_map_editor_gate_4_evidence_pack_2026-07-29.md
```

Les vérifications post-commit, post-fetch et post-push sont consignées dans le
retour de clôture ; elles ne peuvent pas être inscrites récursivement dans le
commit qu’elles vérifient.

## 13. Auto-critique, limites et risques restants

### 13.1 Auto-critique

- Les premières passes de lot n’avaient pas lancé la suite complète après
  chaque commit. La clôture a heureusement révélé deux régressions
  transversales. La leçon est nette : les tests Border et pointer doivent faire
  partie de la matrice AST-01/AST-02 dès qu’un changement touche le canvas ou
  le contrat d’assignation.
- `EditorNotifier`, `MapCanvas` et `TilesetPalettePanel` restent volumineux.
  Gate 4 ajoute des services et projectors purs, mais Gate 5 devra encore
  recomposer les responsabilités visuelles et réduire les rebuilds.
- Le volume de ce rapport est élevé parce que `codex_rule.md` exige le contenu
  intégral des fichiers créés, y compris le Freezed généré.
- Les favoris sont volontairement session-only. Cela résout le besoin de
  contexte sans inventer un schéma de préférences durable, mais un utilisateur
  ne les retrouve pas après fermeture complète de l’application.

### 13.2 Risques non bloquants

- Le filtre de génération async est couvert par inspection, suites canvas et
  test Semantics, mais aucun test widget dédié ne résout encore deux futures
  contrôlées dans l’ordre inverse.
- Les cartes d’éléments sous le browser peuvent encore sembler visuellement
  activables lorsqu’une source parcourue n’est pas assignée ; le notifier
  bloque correctement la sélection et affiche une erreur. Gate 5 pourra rendre
  cet état proactivement disabled.
- Une taxonomie manifeste volontairement cyclique ou structurellement invalide
  reste hors des cas Gate 4.
- La certification Magic Mouse, trackpad physique et VoiceOver réel appartient
  à Gate 6.
- La disposition générale reste celle de l’ancien shell ; Gate 4 améliore le
  workflow d’assets sans prétendre livrer la recomposition UI de Gate 5.

### 13.3 Prochaine étape proposée

Passer à **Gate 5 — Recomposition UI** :

- `UI-01` : shell canvas-first, dock cartes/calques, tray assets, inspecteur
  contextuel et canvas dominant ;
- `UI-02` : design system/accessibilité à l’échelle du nouveau shell ;
- `UI-03` : isolation des rebuilds et repaint du canvas.

Gate 6 restera ensuite la certification produit physique et assistive.

## 14. Contenu intégral des fichiers créés

Les treize contenus Dart ci-dessous correspondent exactement au commit code
`9421c33c5ca72d30cfc19232a51bc755cf61d8db`. Le plan local ignoré correspond
au fichier de travail utilisé pour cette Gate. Chaque annexe indique son
SHA-256 et son nombre de lignes.

### 14.1 `docs/superpowers/plans/2026-07-29-world-map-gate-4-assets.md`

SHA-256 : `f2b8fe82a45196492c29be9cc076059b05a19f225c215eb16f0eb64695e73f7d`
Lignes : `270`

``````markdown
# World Map Editor Gate 4 — Asset Workflow Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to execute this plan task-by-task, with `test-driven-development` for every behavior change and `verification-before-completion` before any completion claim.

**Goal:** Make the world-map asset workflow predictable: image caches follow the open project lifecycle, every map layer remembers its own palette context, tileset assignment participates in normal undo/dirty/save behavior, and the palette becomes a searchable, folder-aware asset browser.

**Architecture:** Keep persisted project and map schemas unchanged. Put image ownership in a project-scoped Riverpod cache service; put transient palette browsing state in editor session state keyed by `(mapId, layerId)`; keep the assigned tileset in `MapData` as the only durable layer source. Project folders and declared scope are the v1 taxonomy. Recents and favorites are personal, project-scoped, session-only preferences and must be labelled as such in the UI.

**Tech Stack:** Dart 3, Flutter desktop, Riverpod, Freezed, `map_core`, PokeMap design system, `flutter_test`.

## Locked product decisions

- A palette context key includes both map ID and layer ID. A bare layer ID is not unique across maps.
- Selecting or browsing an asset never changes `MapData`, dirty state, history, or disk.
- A layer’s assigned tileset remains the primary source. Browsing another source does not silently reassign it.
- Reassignment is explicit. It is allowed for an empty tile layer, rejected before mutation for a non-empty incompatible layer, and recorded as one ordinary undoable map mutation.
- Save remains the only disk write. Assignment must not update `savedMapSnapshot` or acquire a direct-write lease.
- The v1 taxonomy uses only declared tileset folders, group/global scope, and an honest “Non classé” bucket. It never infers `character`, `terrain`, `path`, or similar semantics from filenames or labels.
- Recents and favorites contain project tileset IDs only, are cleaned against the current manifest, have deterministic limits/order, do not dirty the project, and are reset when the project session changes.
- Incompatible sources are hidden by default. An explicit control can reveal them disabled with a user-facing reason.
- Gate 5 layout recomposition and Gate 6 physical-device/accessibility certification remain out of scope.
- Work stays on the current branch because repository Git policy forbids creating a worktree without explicit permission. Every commit stages only the exact Gate 4 paths.

## Lot AST-01 — Project-scoped image cache

**Files**

- Create: `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart`
- Create: `packages/map_editor/lib/src/app/providers/editor/editor_asset_cache_providers.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Modify: `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- Modify: `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart`
- Create: `packages/map_editor/test/editor_image_cache_test.dart`
- Create or modify focused provider/widget tests as required.

### Task 1: Specify the lifecycle in failing tests

- Add tests for canonical-path reuse, cache hit/miss diagnostics, missing-file diagnostics, decode failure diagnostics, and idempotent disposal.
- Add a same-path replacement test using file size/mtime fingerprinting so stale pixels cannot survive an asset replacement.
- Add a provider/session test proving two project roots do not share ownership and disposal happens when the project-scoped provider is released.
- Run:

```bash
cd packages/map_editor
flutter test test/editor_image_cache_test.dart
```

- Confirm RED for missing cache behavior, not for fixture/setup errors.

### Task 2: Implement one shared cache owner

- Implement a cache entry key from canonical path, byte length, modified time, and decode parameters.
- Return a typed result containing either `ui.Image` or an actionable diagnostic; do not collapse every failure into `null`.
- Count entries, hits, misses, invalidations, missing files, decode failures, and disposal.
- Retire superseded images safely and dispose all loaded or pending images when the project cache is disposed.
- Dispose codecs after frame extraction.
- Expose a Riverpod `autoDispose.family` provider keyed by project root and register `ref.onDispose`.

### Task 3: Replace both static caches

- Route map-canvas bulk loading and palette preview loading through the shared project cache.
- Remove `_TilesetImageCache` and `_PaletteImageCache`.
- Surface palette failures through a PokeMap diagnostic/empty-state primitive with asset context and retry/invalidate action.
- Preserve canvas rendering behavior and prevent stale async results from a previous project session from being adopted.

### Task 4: Verify and commit AST-01

```bash
cd packages/map_editor
dart format lib/src/ui/assets/editor_image_cache.dart \
  lib/src/app/providers/editor/editor_asset_cache_providers.dart \
  lib/src/ui/canvas/map_canvas/map_canvas_assets.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/panels/tileset_palette_panel.dart \
  lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart \
  test/editor_image_cache_test.dart
flutter test test/editor_image_cache_test.dart
flutter test test/ui_panels_smoke_test.dart
flutter analyze
```

- Run a spec-compliance review, then a code-quality review; fix findings and rerun focused checks.
- Stage exact AST-01 files only.
- Commit: `feat(map-editor): scope asset images to project sessions`

## Lot AST-02 — Palette context per map layer

**Files**

- Create: `packages/map_editor/lib/src/features/editor/state/models/editor_palette_session.dart`
- Create: `packages/map_editor/lib/src/application/services/editor_palette_session_service.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- Regenerate: `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`
- Modify: `packages/map_editor/lib/src/application/services/editor_map_session_coordinator.dart` only if its legacy global-source fallback must be removed.
- Modify: `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`
- Create: `packages/map_editor/test/editor_palette_session_service_test.dart`
- Modify/Create focused notifier, selector, assignment, and revision tests.

### Task 1: Specify pure context behavior in failing tests

- Test A→B→A restoration for selected source, element group, category filter, brush, browser query/folder/collection, and incompatible visibility.
- Test equal layer IDs on different maps do not collide.
- Test project-session replacement resets contexts, recents, and favorites.
- Test missing layer/tileset IDs are sanitized without dirtying the map.
- Confirm RED.

### Task 2: Implement immutable transient session state

- Add immutable `EditorPaletteContextKey`, `EditorLayerPaletteContext`, and `EditorPaletteSession`.
- Add a pure service for remember/activate/restore/sanitize/recent/favorite operations.
- Store one session object in `EditorState`; synchronize legacy current fields only at notifier boundaries needed by existing consumers.
- Update selectors so the active layer context and its assigned tileset are explicit. Do not let a stale global source outrank the active layer.
- Regenerate Freezed only in `packages/map_editor`.

### Task 3: Normalize assignment with failing tests first

- Add use-case tests proving assignability is resolved through the existing global/group resolver.
- Add notifier tests proving:
  - browsing does not dirty, write, or alter history;
  - empty-layer assignment changes local `MapData`, sets dirty, and adds exactly one undo entry;
  - undo restores the previous layer source;
  - no repository write occurs before Save;
  - Save persists through the normal revision-aware lifecycle;
  - non-empty incompatible assignment is rejected before mutation with a readable reason.
- Adapt the legacy revision test: assignment stays local; the subsequent Save detects an external revision conflict.
- Confirm RED.

### Task 4: Implement explicit normal mutation

- Expose a pure `prepare`/candidate method on `AssignTilesetToMapUseCase`; preserve legacy APIs only where still used.
- Make `assignTilesetToActiveLayer` use the pure candidate plus `_applyMapMutation` without a disk lease and without `updateSavedSnapshot: true`.
- Remember the outgoing context and restore the incoming one in `setActiveLayer` and map activation.
- Ensure a selected incompatible source cannot create a paint brush or mutate the map before explicit assignment.

### Task 5: Verify and commit AST-02

```bash
cd packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs
dart format lib/src/features/editor/state/models/editor_palette_session.dart \
  lib/src/application/services/editor_palette_session_service.dart \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/features/editor/state/editor_selectors.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/editor/application/project_session_controller.dart \
  lib/src/application/services/editor_map_session_coordinator.dart \
  lib/src/application/use_cases/project_tileset_use_cases.dart \
  test/editor_palette_session_service_test.dart
flutter test test/editor_palette_session_service_test.dart
flutter test test/project_tileset_use_cases_test.dart
flutter test test/editor_selectors_test.dart
flutter test test/features/editor/state/editor_notifier_map_revision_test.dart
flutter test test/features/editor/state/editor_notifier_map_activation_test.dart
flutter analyze
```

- Run spec-compliance and code-quality reviews; fix findings and rerun focused checks.
- Stage exact AST-02 files only.
- Commit: `feat(map-editor): remember palette context per layer`

## Lot AST-03 — Searchable asset browser

**Files**

- Create: `packages/map_editor/lib/src/application/models/map_palette_asset_browser.dart`
- Create: `packages/map_editor/lib/src/application/services/map_palette_asset_browser_projector.dart`
- Create: `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart`
- Modify: `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- Create: `packages/map_editor/test/map_palette_asset_browser_projector_test.dart`
- Create: `packages/map_editor/test/map_palette_asset_browser_test.dart`
- Modify focused palette smoke/recommended-layer tests as required.

### Task 1: Specify the projection in failing pure tests

- Test assignable global and ancestor-group tilesets are shown by default.
- Test unrelated group tilesets are hidden by default and revealed disabled with a reason.
- Test nested folder path/breadcrumb projection, deterministic “Non classé”, folder filtering, and text search over user-visible labels.
- Test all/recent/favorite collections, LRU cleanup, stale-ID cleanup, and stable ordering.
- Test active non-tile and non-empty incompatible layers produce explanatory disabled states.
- Confirm RED.

### Task 2: Implement a pure browser projector

- Reuse `ResolveAssignableTilesetsForMapUseCase`; do not duplicate scope rules in widgets.
- Build folder breadcrumbs only from `ProjectTilesetFolder`.
- Produce presentation items with explicit `assigned`, `selected`, `favorite`, `recent`, `assignable`, and disabled-reason fields.
- Never infer asset family from IDs, filenames, or labels.

### Task 3: Specify the widget in failing tests

- Cover search, folder filtering, all/recent/favorite switches, favorite toggle, explicit assignment, incompatible reveal, and disabled reason.
- Cover keyboard focus/activation and semantic labels for selected, assigned, favorite, and disabled states.
- Pump at 800×600 and assert no overflow or Flutter error.
- Cover light and dark themes.
- Confirm RED.

### Task 4: Replace the flat selector with design-system UI

- Put the asset browser before the preview so the user can recover from a missing or incompatible source.
- Use only PokeMap design-system surfaces, cards, search, controls, badges, buttons, empty states, diagnostics, and semantic theme tokens.
- Remove the flat “all project tilesets” dropdown from the normal palette flow.
- Label favorites and recents as session preferences.
- Keep preview/element editing below the browser; disable placement with a visible reason until an incompatible source is explicitly and validly assigned.
- Do not perform Gate 5 panel relocation or shell recomposition.

### Task 5: Verify and commit AST-03

```bash
cd packages/map_editor
dart format lib/src/application/models/map_palette_asset_browser.dart \
  lib/src/application/services/map_palette_asset_browser_projector.dart \
  lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart \
  lib/src/ui/panels/tileset_palette_panel.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/editor/state/editor_selectors.dart \
  test/map_palette_asset_browser_projector_test.dart \
  test/map_palette_asset_browser_test.dart
flutter test test/map_palette_asset_browser_projector_test.dart
flutter test test/map_palette_asset_browser_test.dart
flutter test test/tileset_palette_recommended_layer_test.dart
flutter test test/tileset_palette_placed_instance_opacity_test.dart
flutter test test/ui_panels_smoke_test.dart
flutter test test/design_system_guardrail_test.dart
flutter analyze
```

- Run spec-compliance and code-quality reviews; fix findings and rerun focused checks.
- Stage exact AST-03 files only.
- Commit: `feat(map-editor): add contextual asset browser`

## Gate 4 closure

**Files**

- Create: `reports/ui/world_map_editor_gate_4_evidence_pack_2026-07-29.md`

### Task 1: Integrated verification

- Run every focused Gate 4 test.
- Run the complete `packages/map_editor` test suite and analyzer.
- Run source guardrails for hardcoded colors and ad-hoc primitives in every new Gate 4 UI file.
- Inspect final diff and verify no unrelated pre-existing file was staged or changed by Gate 4.

```bash
cd packages/map_editor
flutter test
flutter analyze
```

### Task 2: Evidence Pack and independent verdict

- Read `codex_rule.md` before writing.
- Include initial audit, every sub-agent/review verdict, decisions/non-goals, full created-file contents, exact modified zones/diffs, exact commands/results, initial/final Git states, risks, and self-critique.
- Obtain an independent final Gate 4 review against the audit contract.
- Mark `AST-01`, `AST-02`, `AST-03`, and Gate 4 `DONE` only if fresh evidence satisfies every locked criterion; otherwise report the exact remaining status honestly.

### Task 3: Commit, push, and remote verification

- Stage only the Evidence Pack and any reviewed closure-only correction.
- Commit: `docs(map-editor): close Gate 4 asset workflow`
- Fetch and verify local `main` is not behind `origin/main`.
- Push `main` once after all lots.
- Verify local HEAD equals `origin/main`.
- Report the unchanged pre-existing dirty set separately from all Gate 4 commits.
``````

### 14.2 `packages/map_editor/lib/src/app/providers/editor/editor_asset_cache_providers.dart`

SHA-256 : `ed04d812427250c0582dc896c9ab537db3b2fa3e2811139a115981de821e17e1`
Lignes : `10`

``````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/assets/editor_image_cache.dart';

final editorImageCacheProvider =
    Provider.autoDispose.family<EditorImageCache, String>((ref, projectRoot) {
  final cache = EditorImageCache(sessionKey: projectRoot);
  ref.onDispose(cache.dispose);
  return cache;
});
``````

### 14.3 `packages/map_editor/lib/src/application/models/map_palette_asset_browser.dart`

SHA-256 : `493a7891b7d8fe7377579b9b1dac190f2ffc3d04db7608ab050bd0bafe736636`
Lignes : `109`

``````dart
import 'package:map_core/map_core.dart';

enum MapPaletteAssetBrowserStatus {
  ready,
  noProject,
  noMap,
  noActiveLayer,
  activeLayerMissing,
  unsupportedLayer,
  invalidMapScope,
  assignedSourceMissing,
}

enum MapPaletteAssetAssignmentState {
  alreadyAssigned,
  canAssign,
  noMap,
  noLayer,
  layerMissing,
  layerNotTile,
  outsideMapScope,
  layerNotEmpty,
}

class MapPaletteAssetFolderRow {
  const MapPaletteAssetFolderRow({
    required this.id,
    required this.name,
    required this.path,
    required this.depth,
  });

  final String id;
  final String name;
  final String path;
  final int depth;
}

class MapPaletteAssetCategoryRow {
  const MapPaletteAssetCategoryRow({
    required this.id,
    required this.name,
    required this.path,
    required this.depth,
  });

  final String id;
  final String name;
  final String path;
  final int depth;
}

class MapPaletteAssetBrowserItem {
  const MapPaletteAssetBrowserItem({
    required this.tileset,
    required this.folderPath,
    required this.scopeLabel,
    required this.explicitCategoryLabels,
    required this.isAssigned,
    required this.isSelected,
    required this.isFavorite,
    required this.isRecent,
    required this.isScopeAssignable,
    required this.isCompatible,
    required this.canAssign,
    required this.assignmentState,
    required this.disabledReason,
  });

  final ProjectTilesetEntry tileset;
  final String folderPath;
  final String scopeLabel;
  final List<String> explicitCategoryLabels;
  final bool isAssigned;
  final bool isSelected;
  final bool isFavorite;
  final bool isRecent;
  final bool isScopeAssignable;
  final bool isCompatible;
  final bool canAssign;
  final MapPaletteAssetAssignmentState assignmentState;
  final String? disabledReason;
}

class MapPaletteAssetBrowserProjection {
  const MapPaletteAssetBrowserProjection({
    required this.status,
    required this.activeLayerName,
    required this.assignedTilesetId,
    required this.selectedTilesetId,
    required this.folders,
    required this.categories,
    required this.items,
    required this.hiddenIncompatibleCount,
    required this.hasUnclassifiedSources,
    required this.diagnostic,
  });

  final MapPaletteAssetBrowserStatus status;
  final String? activeLayerName;
  final String? assignedTilesetId;
  final String? selectedTilesetId;
  final List<MapPaletteAssetFolderRow> folders;
  final List<MapPaletteAssetCategoryRow> categories;
  final List<MapPaletteAssetBrowserItem> items;
  final int hiddenIncompatibleCount;
  final bool hasUnclassifiedSources;
  final String? diagnostic;
}
``````

### 14.4 `packages/map_editor/lib/src/application/services/editor_palette_session_service.dart`

SHA-256 : `dd0763f6a4288d38d641bbe022bfc7d6a7c3901947637e1ea07fe64e8c828fa0`
Lignes : `246`

``````dart
import 'package:map_core/map_core.dart';

import '../../features/editor/state/models/editor_palette_session.dart';

typedef EditorPaletteActivation = ({
  EditorPaletteSession session,
  EditorLayerPaletteContext context,
});

class EditorPaletteSessionService {
  const EditorPaletteSessionService({
    this.maxRecentTilesets = 8,
    this.maxFavoriteTilesets = 32,
  })  : assert(maxRecentTilesets > 0),
        assert(maxFavoriteTilesets > 0);

  final int maxRecentTilesets;
  final int maxFavoriteTilesets;

  EditorPaletteSession remember(
    EditorPaletteSession session, {
    required EditorPaletteContextKey key,
    required EditorLayerPaletteContext context,
  }) {
    return session.copyWith(
      activeKey: key,
      contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
        ...session.contexts,
        key: context,
      },
    );
  }

  EditorPaletteActivation activate(
    EditorPaletteSession session, {
    required EditorPaletteContextKey key,
    required ProjectManifest project,
    required String? assignedTilesetId,
    MapData? activeMap,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final sanitizedSession = sanitize(
      session,
      project: project,
      activeMap: activeMap,
    );
    final existing = sanitizedSession.contexts[key];
    final context = _sanitizeContext(
      existing ??
          EditorLayerPaletteContext(
            selectedTilesetId: _validId(assignedTilesetId, validTilesetIds),
          ),
      project: project,
      assignedTilesetId: assignedTilesetId,
    );
    return (
      session: remember(
        sanitizedSession,
        key: key,
        context: context,
      ),
      context: context,
    );
  }

  EditorPaletteSession sanitize(
    EditorPaletteSession session, {
    required ProjectManifest project,
    MapData? activeMap,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final validMapIds = project.maps.map((entry) => entry.id).toSet();
    if (activeMap != null) {
      validMapIds.add(activeMap.id);
    }
    final activeLayerIds =
        activeMap?.layers.map((layer) => layer.id).toSet() ?? const <String>{};
    final contexts = <EditorPaletteContextKey, EditorLayerPaletteContext>{
      for (final entry in session.contexts.entries)
        if (validMapIds.contains(entry.key.mapId) &&
            (activeMap == null ||
                entry.key.mapId != activeMap.id ||
                activeLayerIds.contains(entry.key.layerId)))
          entry.key: entry.value,
    };
    final activeKey = session.activeKey;
    return _sanitizePreferences(
      session.copyWith(
        activeKey: activeKey != null && contexts.containsKey(activeKey)
            ? activeKey
            : null,
        contexts: contexts,
      ),
      validTilesetIds: validTilesetIds,
    );
  }

  EditorPaletteSession recordRecent(
    EditorPaletteSession session, {
    required String tilesetId,
    required Set<String> validTilesetIds,
  }) {
    final current = session.recentTilesetIds
        .where(validTilesetIds.contains)
        .where((id) => id != tilesetId)
        .toList(growable: true);
    if (validTilesetIds.contains(tilesetId)) {
      current.insert(0, tilesetId);
    }
    return session.copyWith(
      recentTilesetIds: current.take(maxRecentTilesets).toList(growable: false),
      favoriteTilesetIds: session.favoriteTilesetIds
          .where(validTilesetIds.contains)
          .toList(growable: false),
    );
  }

  EditorPaletteSession toggleFavorite(
    EditorPaletteSession session, {
    required String tilesetId,
    required Set<String> validTilesetIds,
  }) {
    final favorites = session.favoriteTilesetIds
        .where(validTilesetIds.contains)
        .toList(growable: true);
    if (favorites.remove(tilesetId)) {
      return session.copyWith(favoriteTilesetIds: favorites);
    }
    if (!validTilesetIds.contains(tilesetId)) {
      return session.copyWith(favoriteTilesetIds: favorites);
    }
    favorites.add(tilesetId);
    if (favorites.length > maxFavoriteTilesets) {
      favorites.removeRange(0, favorites.length - maxFavoriteTilesets);
    }
    return session.copyWith(favoriteTilesetIds: favorites);
  }

  EditorPaletteSession reset(EditorPaletteSession _) {
    return const EditorPaletteSession();
  }

  EditorPaletteSession _sanitizePreferences(
    EditorPaletteSession session, {
    required Set<String> validTilesetIds,
  }) {
    return session.copyWith(
      recentTilesetIds: session.recentTilesetIds
          .where(validTilesetIds.contains)
          .take(maxRecentTilesets)
          .toList(growable: false),
      favoriteTilesetIds: session.favoriteTilesetIds
          .where(validTilesetIds.contains)
          .take(maxFavoriteTilesets)
          .toList(growable: false),
    );
  }

  EditorLayerPaletteContext _sanitizeContext(
    EditorLayerPaletteContext context, {
    required ProjectManifest project,
    required String? assignedTilesetId,
  }) {
    final validTilesetIds =
        project.tilesets.map((tileset) => tileset.id).toSet();
    final validAssignedId = _validId(assignedTilesetId, validTilesetIds);
    final selectedTilesetId =
        _validId(context.selectedTilesetId, validTilesetIds) ?? validAssignedId;
    ProjectTilesetEntry? selectedTileset;
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedTilesetId) {
        selectedTileset = tileset;
        break;
      }
    }
    final selectedGroupId = selectedTileset?.elementGroups
                .any((group) => group.id == context.selectedElementGroupId) ==
            true
        ? context.selectedElementGroupId
        : null;
    final validFolderIds = project.tilesetFolders
        .map((folder) => folder.id)
        .toSet()
      ..add(kEditorPaletteUnclassifiedFolderId);
    final validElementCategoryIds =
        project.elementCategories.map((category) => category.id).toSet();

    return context.copyWith(
      selectedTilesetId: selectedTilesetId,
      selectedElementGroupId: selectedGroupId,
      activeBrush: _sanitizeBrush(
        context.activeBrush,
        project: project,
        assignedTilesetId: validAssignedId,
      ),
      browserFolderId: _validId(context.browserFolderId, validFolderIds),
      projectElementCategoryId: _validId(
        context.projectElementCategoryId,
        validElementCategoryIds,
      ),
    );
  }

  EditorPaletteBrushMemory _sanitizeBrush(
    EditorPaletteBrushMemory brush, {
    required ProjectManifest project,
    required String? assignedTilesetId,
  }) {
    return brush.map(
      none: (_) => brush,
      tile: (tile) => tile.tilesetId == assignedTilesetId
          ? brush
          : const EditorPaletteBrushMemory.none(),
      paletteEntry: (entry) {
        if (entry.tilesetId != assignedTilesetId) {
          return const EditorPaletteBrushMemory.none();
        }
        for (final tileset in project.tilesets) {
          if (tileset.id == entry.tilesetId &&
              tileset.paletteEntries
                  .any((candidate) => candidate.id == entry.entryId)) {
            return brush;
          }
        }
        return const EditorPaletteBrushMemory.none();
      },
      projectElement: (element) {
        for (final candidate in project.elements) {
          if (candidate.id == element.elementId &&
              candidate.tilesetId == assignedTilesetId) {
            return brush;
          }
        }
        return const EditorPaletteBrushMemory.none();
      },
    );
  }

  String? _validId(String? id, Set<String> validIds) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return validIds.contains(normalized) ? normalized : null;
  }
}
``````

### 14.5 `packages/map_editor/lib/src/application/services/map_palette_asset_browser_projector.dart`

SHA-256 : `f74f1de309eabada6570fb8814102dff3ed1fe9f9c050e192377ab2ac55cdf3c`
Lignes : `478`

``````dart
import 'package:map_core/map_core.dart';

import '../../features/editor/state/models/editor_palette_session.dart';
import '../models/map_palette_asset_browser.dart';
import '../use_cases/project_element_use_cases.dart';
import '../use_cases/project_tileset_use_cases.dart';

class MapPaletteAssetBrowserProjector {
  MapPaletteAssetBrowserProjector(
    this._assignableTilesetsResolver, [
    ResolveVisibleProjectElementsUseCase? visibleElementsResolver,
  ]) : _visibleElementsResolver =
            visibleElementsResolver ?? ResolveVisibleProjectElementsUseCase();

  final ResolveAssignableTilesetsForMapUseCase _assignableTilesetsResolver;
  final ResolveVisibleProjectElementsUseCase _visibleElementsResolver;

  MapPaletteAssetBrowserProjection project({
    required ProjectManifest? project,
    required MapData? map,
    required String? activeLayerId,
    String? selectedTilesetId,
    String query = '',
    String? folderId,
    String? elementCategoryId,
    EditorPaletteAssetCollection collection = EditorPaletteAssetCollection.all,
    bool showIncompatible = false,
    List<String> recentTilesetIds = const <String>[],
    List<String> favoriteTilesetIds = const <String>[],
  }) {
    if (project == null) {
      return const MapPaletteAssetBrowserProjection(
        status: MapPaletteAssetBrowserStatus.noProject,
        activeLayerName: null,
        assignedTilesetId: null,
        selectedTilesetId: null,
        folders: <MapPaletteAssetFolderRow>[],
        categories: <MapPaletteAssetCategoryRow>[],
        items: <MapPaletteAssetBrowserItem>[],
        hiddenIncompatibleCount: 0,
        hasUnclassifiedSources: false,
        diagnostic: 'Ouvrez un projet avant de parcourir ses sources.',
      );
    }
    final folders = _folderRows(project);
    final categories = _categoryRows(project);
    if (map == null) {
      return MapPaletteAssetBrowserProjection(
        status: MapPaletteAssetBrowserStatus.noMap,
        activeLayerName: null,
        assignedTilesetId: null,
        selectedTilesetId: selectedTilesetId,
        folders: List<MapPaletteAssetFolderRow>.unmodifiable(folders),
        categories: List<MapPaletteAssetCategoryRow>.unmodifiable(categories),
        items: const <MapPaletteAssetBrowserItem>[],
        hiddenIncompatibleCount: 0,
        hasUnclassifiedSources: _hasUnclassifiedSources(project),
        diagnostic: 'Ouvrez une carte avant de choisir une source.',
      );
    }
    final folderPathById = <String, String>{
      for (final folder in folders) folder.id: folder.path,
    };
    final categoryPathById = <String, String>{
      for (final category in categories) category.id: category.path,
    };

    MapLayer? activeLayer;
    if (activeLayerId != null) {
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          activeLayer = layer;
          break;
        }
      }
    }

    var status = MapPaletteAssetBrowserStatus.ready;
    String? diagnostic;
    if (activeLayerId == null) {
      status = MapPaletteAssetBrowserStatus.noActiveLayer;
      diagnostic = 'Sélectionnez un calque avant de choisir une source.';
    } else if (activeLayer == null) {
      status = MapPaletteAssetBrowserStatus.activeLayerMissing;
      diagnostic = 'Le calque actif n’existe plus dans cette carte.';
    } else if (activeLayer is! TileLayer) {
      status = MapPaletteAssetBrowserStatus.unsupportedLayer;
      diagnostic = 'Sélectionnez un calque de tuiles pour assigner une source.';
    }

    List<ProjectTilesetEntry> assignableInResolverOrder;
    Set<String> assignableIds;
    try {
      assignableInResolverOrder =
          _assignableTilesetsResolver.execute(project, map.id);
      assignableIds =
          assignableInResolverOrder.map((tileset) => tileset.id).toSet();
    } on Object catch (error) {
      assignableInResolverOrder = const <ProjectTilesetEntry>[];
      assignableIds = const <String>{};
      status = MapPaletteAssetBrowserStatus.invalidMapScope;
      diagnostic = 'La portée de sources de cette carte est invalide : $error';
    }

    List<ProjectElementEntry> visibleElements;
    try {
      visibleElements = _visibleElementsResolver.execute(
        project,
        mapId: map.id,
      );
    } on Object {
      visibleElements = const <ProjectElementEntry>[];
    }
    final elementsByTilesetId = <String, List<ProjectElementEntry>>{};
    for (final element in visibleElements) {
      elementsByTilesetId
          .putIfAbsent(element.tilesetId, () => <ProjectElementEntry>[])
          .add(element);
    }

    final assignedTilesetId =
        activeLayer is TileLayer ? _assignedTilesetId(map, activeLayer) : null;
    final layerIsEmpty = activeLayer is TileLayer &&
        activeLayer.tiles.every((tile) => tile == 0);
    final assignedSourceMissing = assignedTilesetId != null &&
        !project.tilesets.any((tileset) => tileset.id == assignedTilesetId);
    if (status == MapPaletteAssetBrowserStatus.ready && assignedSourceMissing) {
      status = MapPaletteAssetBrowserStatus.assignedSourceMissing;
      diagnostic = layerIsEmpty
          ? 'La source assignée « $assignedTilesetId » n’existe plus dans le '
              'projet. Choisissez puis assignez une source disponible pour '
              'réparer ce calque vide.'
          : 'La source assignée « $assignedTilesetId » n’existe plus dans le '
              'projet. Ce calque contient encore des tuiles : videz-le avant '
              'de changer de source afin de ne pas réinterpréter leurs IDs.';
    }
    final recentIndexById = <String, int>{
      for (var index = 0; index < recentTilesetIds.length; index++)
        recentTilesetIds[index]: index,
    };
    final favoriteIds = favoriteTilesetIds.toSet();
    final selectedCategoryIds = elementCategoryId == null
        ? const <String>{}
        : _categorySubtreeIds(project, elementCategoryId);
    final folderIds =
        folderId == null || folderId == kEditorPaletteUnclassifiedFolderId
            ? const <String>{}
            : tilesetFolderSubtreeIds(project, folderId);
    final queryTokens = _tokens(query);

    final orderedTilesets = <ProjectTilesetEntry>[
      ...assignableInResolverOrder,
      ...project.tilesets.where(
        (tileset) => !assignableIds.contains(tileset.id),
      ),
    ];

    final projected = <MapPaletteAssetBrowserItem>[];
    var hiddenIncompatibleCount = 0;
    for (final tileset in orderedTilesets) {
      final isAssigned = tileset.id == assignedTilesetId;
      final isScopeAssignable = assignableIds.contains(tileset.id);
      final assignment = _assignmentFor(
        activeLayerId: activeLayerId,
        activeLayer: activeLayer,
        isAssigned: isAssigned,
        isScopeAssignable: isScopeAssignable,
        layerIsEmpty: layerIsEmpty,
      );
      final isCompatible =
          assignment == MapPaletteAssetAssignmentState.alreadyAssigned ||
              assignment == MapPaletteAssetAssignmentState.canAssign;
      final disabledReason = _disabledReason(assignment);
      if (!showIncompatible && !isCompatible) {
        hiddenIncompatibleCount += 1;
        continue;
      }

      final isRecent = recentIndexById.containsKey(tileset.id);
      final isFavorite = favoriteIds.contains(tileset.id);
      if (collection == EditorPaletteAssetCollection.recent && !isRecent) {
        continue;
      }
      if (collection == EditorPaletteAssetCollection.favorites && !isFavorite) {
        continue;
      }

      final normalizedFolderId = tileset.folderId?.trim();
      final isUnclassified = normalizedFolderId == null ||
          normalizedFolderId.isEmpty ||
          !folderPathById.containsKey(normalizedFolderId);
      if (folderId == kEditorPaletteUnclassifiedFolderId) {
        if (!isUnclassified) continue;
      } else if (folderId != null &&
          (isUnclassified || !folderIds.contains(normalizedFolderId))) {
        continue;
      }

      final elements =
          elementsByTilesetId[tileset.id] ?? const <ProjectElementEntry>[];
      if (elementCategoryId != null &&
          !elements.any(
            (element) => selectedCategoryIds.contains(element.categoryId),
          )) {
        continue;
      }

      final folderPath =
          isUnclassified ? 'Non classé' : folderPathById[normalizedFolderId]!;
      final categoryLabels = <String>{
        for (final element in elements)
          if (categoryPathById[element.categoryId] case final path?) path,
      }.toList(growable: false)
        ..sort(_compareFolded);
      final scopeLabel = _scopeLabel(project, tileset);
      final searchableLabels = <String>[
        tileset.name,
        folderPath,
        scopeLabel,
        ...tileset.elementGroups.map((group) => group.name),
        ...tileset.paletteEntries.map((entry) => entry.name),
        ...elements.expand(
          (element) => <String>[
            element.name,
            ...element.tags,
            if (categoryPathById[element.categoryId] case final path?) path,
          ],
        ),
      ];
      if (!_matchesTokens(searchableLabels, queryTokens)) {
        continue;
      }

      projected.add(
        MapPaletteAssetBrowserItem(
          tileset: tileset,
          folderPath: folderPath,
          scopeLabel: scopeLabel,
          explicitCategoryLabels: List<String>.unmodifiable(categoryLabels),
          isAssigned: isAssigned,
          isSelected: tileset.id == selectedTilesetId,
          isFavorite: isFavorite,
          isRecent: isRecent,
          isScopeAssignable: isScopeAssignable,
          isCompatible: isCompatible,
          canAssign: assignment == MapPaletteAssetAssignmentState.canAssign,
          assignmentState: assignment,
          disabledReason: disabledReason,
        ),
      );
    }

    if (collection == EditorPaletteAssetCollection.recent) {
      projected.sort((a, b) {
        final aIndex = recentIndexById[a.tileset.id] ?? 1 << 30;
        final bIndex = recentIndexById[b.tileset.id] ?? 1 << 30;
        return aIndex.compareTo(bIndex);
      });
    }

    return MapPaletteAssetBrowserProjection(
      status: status,
      activeLayerName: activeLayer?.name,
      assignedTilesetId: assignedTilesetId,
      selectedTilesetId: selectedTilesetId,
      folders: List<MapPaletteAssetFolderRow>.unmodifiable(folders),
      categories: List<MapPaletteAssetCategoryRow>.unmodifiable(categories),
      items: List<MapPaletteAssetBrowserItem>.unmodifiable(projected),
      hiddenIncompatibleCount: hiddenIncompatibleCount,
      hasUnclassifiedSources: _hasUnclassifiedSources(project),
      diagnostic: diagnostic,
    );
  }

  bool _hasUnclassifiedSources(ProjectManifest project) {
    final declaredFolderIds =
        project.tilesetFolders.map((folder) => folder.id).toSet();
    return project.tilesets.any((tileset) {
      final id = tileset.folderId?.trim();
      return id == null || id.isEmpty || !declaredFolderIds.contains(id);
    });
  }

  MapPaletteAssetAssignmentState _assignmentFor({
    required String? activeLayerId,
    required MapLayer? activeLayer,
    required bool isAssigned,
    required bool isScopeAssignable,
    required bool layerIsEmpty,
  }) {
    if (activeLayerId == null) {
      return MapPaletteAssetAssignmentState.noLayer;
    }
    if (activeLayer == null) {
      return MapPaletteAssetAssignmentState.layerMissing;
    }
    if (activeLayer is! TileLayer) {
      return MapPaletteAssetAssignmentState.layerNotTile;
    }
    if (isAssigned) {
      return MapPaletteAssetAssignmentState.alreadyAssigned;
    }
    if (!isScopeAssignable) {
      return MapPaletteAssetAssignmentState.outsideMapScope;
    }
    if (!layerIsEmpty) {
      return MapPaletteAssetAssignmentState.layerNotEmpty;
    }
    return MapPaletteAssetAssignmentState.canAssign;
  }

  String? _disabledReason(MapPaletteAssetAssignmentState state) {
    return switch (state) {
      MapPaletteAssetAssignmentState.alreadyAssigned ||
      MapPaletteAssetAssignmentState.canAssign =>
        null,
      MapPaletteAssetAssignmentState.noMap =>
        'Aucune carte active ne peut recevoir cette source.',
      MapPaletteAssetAssignmentState.noLayer =>
        'Sélectionnez un calque avant de choisir cette source.',
      MapPaletteAssetAssignmentState.layerMissing =>
        'Le calque actif n’existe plus.',
      MapPaletteAssetAssignmentState.layerNotTile =>
        'Cette source nécessite un calque de tuiles.',
      MapPaletteAssetAssignmentState.outsideMapScope =>
        'Cette source appartient à un autre groupe de cartes.',
      MapPaletteAssetAssignmentState.layerNotEmpty =>
        'Ce calque contient déjà des tuiles d’une autre source.',
    };
  }

  String? _assignedTilesetId(MapData map, TileLayer layer) {
    final layerId = layer.tilesetId?.trim();
    if (layerId != null && layerId.isNotEmpty) return layerId;
    final mapId = map.tilesetId.trim();
    return mapId.isEmpty ? null : mapId;
  }

  List<MapPaletteAssetFolderRow> _folderRows(ProjectManifest project) {
    final rows = flattenTilesetFoldersForPicker(project);
    final nameById = <String, String>{
      for (final folder in project.tilesetFolders) folder.id: folder.name,
    };
    return rows
        .map(
          (row) => MapPaletteAssetFolderRow(
            id: row.id,
            name: nameById[row.id] ?? row.label,
            path: row.label,
            depth: ' / '.allMatches(row.label).length,
          ),
        )
        .toList(growable: false);
  }

  List<MapPaletteAssetCategoryRow> _categoryRows(ProjectManifest project) {
    final categories = project.elementCategories.toList(growable: false);
    final output = <MapPaletteAssetCategoryRow>[];

    void walk(String? parentId, String prefix, int depth) {
      final children = categories
          .where((category) => category.parentCategoryId == parentId)
          .toList(growable: false)
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) return order;
          final name = _compareFolded(a.name, b.name);
          if (name != 0) return name;
          return a.id.compareTo(b.id);
        });
      for (final category in children) {
        final path =
            prefix.isEmpty ? category.name : '$prefix / ${category.name}';
        output.add(
          MapPaletteAssetCategoryRow(
            id: category.id,
            name: category.name,
            path: path,
            depth: depth,
          ),
        );
        walk(category.id, path, depth + 1);
      }
    }

    walk(null, '', 0);
    return output;
  }

  Set<String> _categorySubtreeIds(
    ProjectManifest project,
    String rootId,
  ) {
    final byParent = <String?, List<ProjectElementCategory>>{};
    for (final category in project.elementCategories) {
      byParent
          .putIfAbsent(
            category.parentCategoryId,
            () => <ProjectElementCategory>[],
          )
          .add(category);
    }
    final ids = <String>{};
    void walk(String id) {
      if (!ids.add(id)) return;
      for (final child in byParent[id] ?? const <ProjectElementCategory>[]) {
        walk(child.id);
      }
    }

    walk(rootId);
    return ids;
  }

  String _scopeLabel(ProjectManifest project, ProjectTilesetEntry tileset) {
    if (tileset.scope == TilesetScope.global) return 'Toutes les cartes';
    final groupId = tileset.groupId;
    if (groupId == null) return 'Groupe non défini';
    for (final group in project.groups) {
      if (group.id == groupId) return 'Groupe : ${group.name}';
    }
    return 'Groupe inconnu';
  }

  List<String> _tokens(String query) {
    return _fold(query)
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  bool _matchesTokens(List<String> labels, List<String> tokens) {
    if (tokens.isEmpty) return true;
    final haystack = _fold(labels.join(' '));
    return tokens.every(haystack.contains);
  }

  int _compareFolded(String a, String b) => _fold(a).compareTo(_fold(b));

  String _fold(String value) {
    var folded = value.trim().toLowerCase();
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    for (final entry in replacements.entries) {
      folded = folded.replaceAll(entry.key, entry.value);
    }
    return folded;
  }
}
``````

### 14.6 `packages/map_editor/lib/src/features/editor/state/models/editor_palette_session.dart`

SHA-256 : `b08649bf3ff54ad37157e53350f9aeaa8350258299edc759d48efcab0595c4c4`
Lignes : `72`

``````dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import 'editor_ui_modes.dart';

part 'editor_palette_session.freezed.dart';

/// Session-only sentinel used by the asset browser for tilesets that have no
/// declared library folder. It is UI taxonomy, never a persisted folder ID.
const kEditorPaletteUnclassifiedFolderId = '__unclassified__';

enum EditorPaletteAssetCollection {
  all,
  recent,
  favorites,
}

@freezed
class EditorPaletteContextKey with _$EditorPaletteContextKey {
  const factory EditorPaletteContextKey({
    required String mapId,
    required String layerId,
  }) = _EditorPaletteContextKey;
}

@freezed
sealed class EditorPaletteBrushMemory with _$EditorPaletteBrushMemory {
  const factory EditorPaletteBrushMemory.none() = NoEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.tile({
    required int tileId,
    required String tilesetId,
  }) = TileEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.paletteEntry({
    required String entryId,
    required String tilesetId,
  }) = PaletteEntryEditorPaletteBrushMemory;

  const factory EditorPaletteBrushMemory.projectElement({
    required String elementId,
  }) = ProjectElementEditorPaletteBrushMemory;
}

@freezed
class EditorLayerPaletteContext with _$EditorLayerPaletteContext {
  const factory EditorLayerPaletteContext({
    String? selectedTilesetId,
    String? selectedElementGroupId,
    PaletteCategory? paletteCategoryFilter,
    @Default(EditorPaletteBrushMemory.none())
    EditorPaletteBrushMemory activeBrush,
    @Default(TilesElementsPanelMode.palette) TilesElementsPanelMode panelMode,
    @Default('') String browserQuery,
    String? browserFolderId,
    String? projectElementCategoryId,
    @Default(EditorPaletteAssetCollection.all)
    EditorPaletteAssetCollection browserCollection,
    @Default(false) bool showIncompatible,
  }) = _EditorLayerPaletteContext;
}

@freezed
class EditorPaletteSession with _$EditorPaletteSession {
  const factory EditorPaletteSession({
    EditorPaletteContextKey? activeKey,
    @Default(<EditorPaletteContextKey, EditorLayerPaletteContext>{})
    Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
    @Default(<String>[]) List<String> recentTilesetIds,
    @Default(<String>[]) List<String> favoriteTilesetIds,
  }) = _EditorPaletteSession;
}
``````

### 14.7 `packages/map_editor/lib/src/features/editor/state/models/editor_palette_session.freezed.dart`

SHA-256 : `443e51457f690aae798db61d0a20ce3f26a9fc4030ba9eeefcaff4d4af671b1e`
Lignes : `1505`

``````dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_palette_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EditorPaletteContextKey {
  String get mapId => throw _privateConstructorUsedError;
  String get layerId => throw _privateConstructorUsedError;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorPaletteContextKeyCopyWith<EditorPaletteContextKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteContextKeyCopyWith<$Res> {
  factory $EditorPaletteContextKeyCopyWith(EditorPaletteContextKey value,
          $Res Function(EditorPaletteContextKey) then) =
      _$EditorPaletteContextKeyCopyWithImpl<$Res, EditorPaletteContextKey>;
  @useResult
  $Res call({String mapId, String layerId});
}

/// @nodoc
class _$EditorPaletteContextKeyCopyWithImpl<$Res,
        $Val extends EditorPaletteContextKey>
    implements $EditorPaletteContextKeyCopyWith<$Res> {
  _$EditorPaletteContextKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = null,
    Object? layerId = null,
  }) {
    return _then(_value.copyWith(
      mapId: null == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EditorPaletteContextKeyImplCopyWith<$Res>
    implements $EditorPaletteContextKeyCopyWith<$Res> {
  factory _$$EditorPaletteContextKeyImplCopyWith(
          _$EditorPaletteContextKeyImpl value,
          $Res Function(_$EditorPaletteContextKeyImpl) then) =
      __$$EditorPaletteContextKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mapId, String layerId});
}

/// @nodoc
class __$$EditorPaletteContextKeyImplCopyWithImpl<$Res>
    extends _$EditorPaletteContextKeyCopyWithImpl<$Res,
        _$EditorPaletteContextKeyImpl>
    implements _$$EditorPaletteContextKeyImplCopyWith<$Res> {
  __$$EditorPaletteContextKeyImplCopyWithImpl(
      _$EditorPaletteContextKeyImpl _value,
      $Res Function(_$EditorPaletteContextKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = null,
    Object? layerId = null,
  }) {
    return _then(_$EditorPaletteContextKeyImpl(
      mapId: null == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EditorPaletteContextKeyImpl implements _EditorPaletteContextKey {
  const _$EditorPaletteContextKeyImpl(
      {required this.mapId, required this.layerId});

  @override
  final String mapId;
  @override
  final String layerId;

  @override
  String toString() {
    return 'EditorPaletteContextKey(mapId: $mapId, layerId: $layerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorPaletteContextKeyImpl &&
            (identical(other.mapId, mapId) || other.mapId == mapId) &&
            (identical(other.layerId, layerId) || other.layerId == layerId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mapId, layerId);

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorPaletteContextKeyImplCopyWith<_$EditorPaletteContextKeyImpl>
      get copyWith => __$$EditorPaletteContextKeyImplCopyWithImpl<
          _$EditorPaletteContextKeyImpl>(this, _$identity);
}

abstract class _EditorPaletteContextKey implements EditorPaletteContextKey {
  const factory _EditorPaletteContextKey(
      {required final String mapId,
      required final String layerId}) = _$EditorPaletteContextKeyImpl;

  @override
  String get mapId;
  @override
  String get layerId;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorPaletteContextKeyImplCopyWith<_$EditorPaletteContextKeyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorPaletteBrushMemory {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteBrushMemoryCopyWith<$Res> {
  factory $EditorPaletteBrushMemoryCopyWith(EditorPaletteBrushMemory value,
          $Res Function(EditorPaletteBrushMemory) then) =
      _$EditorPaletteBrushMemoryCopyWithImpl<$Res, EditorPaletteBrushMemory>;
}

/// @nodoc
class _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        $Val extends EditorPaletteBrushMemory>
    implements $EditorPaletteBrushMemoryCopyWith<$Res> {
  _$EditorPaletteBrushMemoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NoEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$NoEditorPaletteBrushMemoryImplCopyWith(
          _$NoEditorPaletteBrushMemoryImpl value,
          $Res Function(_$NoEditorPaletteBrushMemoryImpl) then) =
      __$$NoEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$NoEditorPaletteBrushMemoryImpl>
    implements _$$NoEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$NoEditorPaletteBrushMemoryImplCopyWithImpl(
      _$NoEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$NoEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NoEditorPaletteBrushMemoryImpl implements NoEditorPaletteBrushMemory {
  const _$NoEditorPaletteBrushMemoryImpl();

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.none()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoEditorPaletteBrushMemoryImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }
}

abstract class NoEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const factory NoEditorPaletteBrushMemory() = _$NoEditorPaletteBrushMemoryImpl;
}

/// @nodoc
abstract class _$$TileEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$TileEditorPaletteBrushMemoryImplCopyWith(
          _$TileEditorPaletteBrushMemoryImpl value,
          $Res Function(_$TileEditorPaletteBrushMemoryImpl) then) =
      __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int tileId, String tilesetId});
}

/// @nodoc
class __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$TileEditorPaletteBrushMemoryImpl>
    implements _$$TileEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$TileEditorPaletteBrushMemoryImplCopyWithImpl(
      _$TileEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$TileEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? tilesetId = null,
  }) {
    return _then(_$TileEditorPaletteBrushMemoryImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TileEditorPaletteBrushMemoryImpl
    implements TileEditorPaletteBrushMemory {
  const _$TileEditorPaletteBrushMemoryImpl(
      {required this.tileId, required this.tilesetId});

  @override
  final int tileId;
  @override
  final String tilesetId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.tile(tileId: $tileId, tilesetId: $tilesetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TileEditorPaletteBrushMemoryImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tileId, tilesetId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TileEditorPaletteBrushMemoryImplCopyWith<
          _$TileEditorPaletteBrushMemoryImpl>
      get copyWith => __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<
          _$TileEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return tile(tileId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return tile?.call(tileId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(tileId, tilesetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return tile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return tile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(this);
    }
    return orElse();
  }
}

abstract class TileEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory TileEditorPaletteBrushMemory(
      {required final int tileId,
      required final String tilesetId}) = _$TileEditorPaletteBrushMemoryImpl;

  int get tileId;
  String get tilesetId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TileEditorPaletteBrushMemoryImplCopyWith<
          _$TileEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith(
          _$PaletteEntryEditorPaletteBrushMemoryImpl value,
          $Res Function(_$PaletteEntryEditorPaletteBrushMemoryImpl) then) =
      __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String entryId, String tilesetId});
}

/// @nodoc
class __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$PaletteEntryEditorPaletteBrushMemoryImpl>
    implements _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl(
      _$PaletteEntryEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$PaletteEntryEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entryId = null,
    Object? tilesetId = null,
  }) {
    return _then(_$PaletteEntryEditorPaletteBrushMemoryImpl(
      entryId: null == entryId
          ? _value.entryId
          : entryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PaletteEntryEditorPaletteBrushMemoryImpl
    implements PaletteEntryEditorPaletteBrushMemory {
  const _$PaletteEntryEditorPaletteBrushMemoryImpl(
      {required this.entryId, required this.tilesetId});

  @override
  final String entryId;
  @override
  final String tilesetId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.paletteEntry(entryId: $entryId, tilesetId: $tilesetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaletteEntryEditorPaletteBrushMemoryImpl &&
            (identical(other.entryId, entryId) || other.entryId == entryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryId, tilesetId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>
      get copyWith => __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return paletteEntry(entryId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return paletteEntry?.call(entryId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (paletteEntry != null) {
      return paletteEntry(entryId, tilesetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return paletteEntry(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return paletteEntry?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (paletteEntry != null) {
      return paletteEntry(this);
    }
    return orElse();
  }
}

abstract class PaletteEntryEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory PaletteEntryEditorPaletteBrushMemory(
          {required final String entryId, required final String tilesetId}) =
      _$PaletteEntryEditorPaletteBrushMemoryImpl;

  String get entryId;
  String get tilesetId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith(
          _$ProjectElementEditorPaletteBrushMemoryImpl value,
          $Res Function(_$ProjectElementEditorPaletteBrushMemoryImpl) then) =
      __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String elementId});
}

/// @nodoc
class __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$ProjectElementEditorPaletteBrushMemoryImpl>
    implements _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl(
      _$ProjectElementEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$ProjectElementEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? elementId = null,
  }) {
    return _then(_$ProjectElementEditorPaletteBrushMemoryImpl(
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ProjectElementEditorPaletteBrushMemoryImpl
    implements ProjectElementEditorPaletteBrushMemory {
  const _$ProjectElementEditorPaletteBrushMemoryImpl({required this.elementId});

  @override
  final String elementId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.projectElement(elementId: $elementId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementEditorPaletteBrushMemoryImpl &&
            (identical(other.elementId, elementId) ||
                other.elementId == elementId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, elementId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<
          _$ProjectElementEditorPaletteBrushMemoryImpl>
      get copyWith =>
          __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<
              _$ProjectElementEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return projectElement(elementId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return projectElement?.call(elementId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (projectElement != null) {
      return projectElement(elementId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return projectElement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return projectElement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (projectElement != null) {
      return projectElement(this);
    }
    return orElse();
  }
}

abstract class ProjectElementEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory ProjectElementEditorPaletteBrushMemory(
          {required final String elementId}) =
      _$ProjectElementEditorPaletteBrushMemoryImpl;

  String get elementId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<
          _$ProjectElementEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorLayerPaletteContext {
  String? get selectedTilesetId => throw _privateConstructorUsedError;
  String? get selectedElementGroupId => throw _privateConstructorUsedError;
  PaletteCategory? get paletteCategoryFilter =>
      throw _privateConstructorUsedError;
  EditorPaletteBrushMemory get activeBrush =>
      throw _privateConstructorUsedError;
  TilesElementsPanelMode get panelMode => throw _privateConstructorUsedError;
  String get browserQuery => throw _privateConstructorUsedError;
  String? get browserFolderId => throw _privateConstructorUsedError;
  String? get projectElementCategoryId => throw _privateConstructorUsedError;
  EditorPaletteAssetCollection get browserCollection =>
      throw _privateConstructorUsedError;
  bool get showIncompatible => throw _privateConstructorUsedError;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorLayerPaletteContextCopyWith<EditorLayerPaletteContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorLayerPaletteContextCopyWith<$Res> {
  factory $EditorLayerPaletteContextCopyWith(EditorLayerPaletteContext value,
          $Res Function(EditorLayerPaletteContext) then) =
      _$EditorLayerPaletteContextCopyWithImpl<$Res, EditorLayerPaletteContext>;
  @useResult
  $Res call(
      {String? selectedTilesetId,
      String? selectedElementGroupId,
      PaletteCategory? paletteCategoryFilter,
      EditorPaletteBrushMemory activeBrush,
      TilesElementsPanelMode panelMode,
      String browserQuery,
      String? browserFolderId,
      String? projectElementCategoryId,
      EditorPaletteAssetCollection browserCollection,
      bool showIncompatible});

  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;
}

/// @nodoc
class _$EditorLayerPaletteContextCopyWithImpl<$Res,
        $Val extends EditorLayerPaletteContext>
    implements $EditorLayerPaletteContextCopyWith<$Res> {
  _$EditorLayerPaletteContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedTilesetId = freezed,
    Object? selectedElementGroupId = freezed,
    Object? paletteCategoryFilter = freezed,
    Object? activeBrush = null,
    Object? panelMode = null,
    Object? browserQuery = null,
    Object? browserFolderId = freezed,
    Object? projectElementCategoryId = freezed,
    Object? browserCollection = null,
    Object? showIncompatible = null,
  }) {
    return _then(_value.copyWith(
      selectedTilesetId: freezed == selectedTilesetId
          ? _value.selectedTilesetId
          : selectedTilesetId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedElementGroupId: freezed == selectedElementGroupId
          ? _value.selectedElementGroupId
          : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      paletteCategoryFilter: freezed == paletteCategoryFilter
          ? _value.paletteCategoryFilter
          : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
              as PaletteCategory?,
      activeBrush: null == activeBrush
          ? _value.activeBrush
          : activeBrush // ignore: cast_nullable_to_non_nullable
              as EditorPaletteBrushMemory,
      panelMode: null == panelMode
          ? _value.panelMode
          : panelMode // ignore: cast_nullable_to_non_nullable
              as TilesElementsPanelMode,
      browserQuery: null == browserQuery
          ? _value.browserQuery
          : browserQuery // ignore: cast_nullable_to_non_nullable
              as String,
      browserFolderId: freezed == browserFolderId
          ? _value.browserFolderId
          : browserFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectElementCategoryId: freezed == projectElementCategoryId
          ? _value.projectElementCategoryId
          : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      browserCollection: null == browserCollection
          ? _value.browserCollection
          : browserCollection // ignore: cast_nullable_to_non_nullable
              as EditorPaletteAssetCollection,
      showIncompatible: null == showIncompatible
          ? _value.showIncompatible
          : showIncompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush {
    return $EditorPaletteBrushMemoryCopyWith<$Res>(_value.activeBrush, (value) {
      return _then(_value.copyWith(activeBrush: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorLayerPaletteContextImplCopyWith<$Res>
    implements $EditorLayerPaletteContextCopyWith<$Res> {
  factory _$$EditorLayerPaletteContextImplCopyWith(
          _$EditorLayerPaletteContextImpl value,
          $Res Function(_$EditorLayerPaletteContextImpl) then) =
      __$$EditorLayerPaletteContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? selectedTilesetId,
      String? selectedElementGroupId,
      PaletteCategory? paletteCategoryFilter,
      EditorPaletteBrushMemory activeBrush,
      TilesElementsPanelMode panelMode,
      String browserQuery,
      String? browserFolderId,
      String? projectElementCategoryId,
      EditorPaletteAssetCollection browserCollection,
      bool showIncompatible});

  @override
  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;
}

/// @nodoc
class __$$EditorLayerPaletteContextImplCopyWithImpl<$Res>
    extends _$EditorLayerPaletteContextCopyWithImpl<$Res,
        _$EditorLayerPaletteContextImpl>
    implements _$$EditorLayerPaletteContextImplCopyWith<$Res> {
  __$$EditorLayerPaletteContextImplCopyWithImpl(
      _$EditorLayerPaletteContextImpl _value,
      $Res Function(_$EditorLayerPaletteContextImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedTilesetId = freezed,
    Object? selectedElementGroupId = freezed,
    Object? paletteCategoryFilter = freezed,
    Object? activeBrush = null,
    Object? panelMode = null,
    Object? browserQuery = null,
    Object? browserFolderId = freezed,
    Object? projectElementCategoryId = freezed,
    Object? browserCollection = null,
    Object? showIncompatible = null,
  }) {
    return _then(_$EditorLayerPaletteContextImpl(
      selectedTilesetId: freezed == selectedTilesetId
          ? _value.selectedTilesetId
          : selectedTilesetId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedElementGroupId: freezed == selectedElementGroupId
          ? _value.selectedElementGroupId
          : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      paletteCategoryFilter: freezed == paletteCategoryFilter
          ? _value.paletteCategoryFilter
          : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
              as PaletteCategory?,
      activeBrush: null == activeBrush
          ? _value.activeBrush
          : activeBrush // ignore: cast_nullable_to_non_nullable
              as EditorPaletteBrushMemory,
      panelMode: null == panelMode
          ? _value.panelMode
          : panelMode // ignore: cast_nullable_to_non_nullable
              as TilesElementsPanelMode,
      browserQuery: null == browserQuery
          ? _value.browserQuery
          : browserQuery // ignore: cast_nullable_to_non_nullable
              as String,
      browserFolderId: freezed == browserFolderId
          ? _value.browserFolderId
          : browserFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectElementCategoryId: freezed == projectElementCategoryId
          ? _value.projectElementCategoryId
          : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      browserCollection: null == browserCollection
          ? _value.browserCollection
          : browserCollection // ignore: cast_nullable_to_non_nullable
              as EditorPaletteAssetCollection,
      showIncompatible: null == showIncompatible
          ? _value.showIncompatible
          : showIncompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$EditorLayerPaletteContextImpl implements _EditorLayerPaletteContext {
  const _$EditorLayerPaletteContextImpl(
      {this.selectedTilesetId,
      this.selectedElementGroupId,
      this.paletteCategoryFilter,
      this.activeBrush = const EditorPaletteBrushMemory.none(),
      this.panelMode = TilesElementsPanelMode.palette,
      this.browserQuery = '',
      this.browserFolderId,
      this.projectElementCategoryId,
      this.browserCollection = EditorPaletteAssetCollection.all,
      this.showIncompatible = false});

  @override
  final String? selectedTilesetId;
  @override
  final String? selectedElementGroupId;
  @override
  final PaletteCategory? paletteCategoryFilter;
  @override
  @JsonKey()
  final EditorPaletteBrushMemory activeBrush;
  @override
  @JsonKey()
  final TilesElementsPanelMode panelMode;
  @override
  @JsonKey()
  final String browserQuery;
  @override
  final String? browserFolderId;
  @override
  final String? projectElementCategoryId;
  @override
  @JsonKey()
  final EditorPaletteAssetCollection browserCollection;
  @override
  @JsonKey()
  final bool showIncompatible;

  @override
  String toString() {
    return 'EditorLayerPaletteContext(selectedTilesetId: $selectedTilesetId, selectedElementGroupId: $selectedElementGroupId, paletteCategoryFilter: $paletteCategoryFilter, activeBrush: $activeBrush, panelMode: $panelMode, browserQuery: $browserQuery, browserFolderId: $browserFolderId, projectElementCategoryId: $projectElementCategoryId, browserCollection: $browserCollection, showIncompatible: $showIncompatible)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorLayerPaletteContextImpl &&
            (identical(other.selectedTilesetId, selectedTilesetId) ||
                other.selectedTilesetId == selectedTilesetId) &&
            (identical(other.selectedElementGroupId, selectedElementGroupId) ||
                other.selectedElementGroupId == selectedElementGroupId) &&
            (identical(other.paletteCategoryFilter, paletteCategoryFilter) ||
                other.paletteCategoryFilter == paletteCategoryFilter) &&
            (identical(other.activeBrush, activeBrush) ||
                other.activeBrush == activeBrush) &&
            (identical(other.panelMode, panelMode) ||
                other.panelMode == panelMode) &&
            (identical(other.browserQuery, browserQuery) ||
                other.browserQuery == browserQuery) &&
            (identical(other.browserFolderId, browserFolderId) ||
                other.browserFolderId == browserFolderId) &&
            (identical(
                    other.projectElementCategoryId, projectElementCategoryId) ||
                other.projectElementCategoryId == projectElementCategoryId) &&
            (identical(other.browserCollection, browserCollection) ||
                other.browserCollection == browserCollection) &&
            (identical(other.showIncompatible, showIncompatible) ||
                other.showIncompatible == showIncompatible));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedTilesetId,
      selectedElementGroupId,
      paletteCategoryFilter,
      activeBrush,
      panelMode,
      browserQuery,
      browserFolderId,
      projectElementCategoryId,
      browserCollection,
      showIncompatible);

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorLayerPaletteContextImplCopyWith<_$EditorLayerPaletteContextImpl>
      get copyWith => __$$EditorLayerPaletteContextImplCopyWithImpl<
          _$EditorLayerPaletteContextImpl>(this, _$identity);
}

abstract class _EditorLayerPaletteContext implements EditorLayerPaletteContext {
  const factory _EditorLayerPaletteContext(
      {final String? selectedTilesetId,
      final String? selectedElementGroupId,
      final PaletteCategory? paletteCategoryFilter,
      final EditorPaletteBrushMemory activeBrush,
      final TilesElementsPanelMode panelMode,
      final String browserQuery,
      final String? browserFolderId,
      final String? projectElementCategoryId,
      final EditorPaletteAssetCollection browserCollection,
      final bool showIncompatible}) = _$EditorLayerPaletteContextImpl;

  @override
  String? get selectedTilesetId;
  @override
  String? get selectedElementGroupId;
  @override
  PaletteCategory? get paletteCategoryFilter;
  @override
  EditorPaletteBrushMemory get activeBrush;
  @override
  TilesElementsPanelMode get panelMode;
  @override
  String get browserQuery;
  @override
  String? get browserFolderId;
  @override
  String? get projectElementCategoryId;
  @override
  EditorPaletteAssetCollection get browserCollection;
  @override
  bool get showIncompatible;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorLayerPaletteContextImplCopyWith<_$EditorLayerPaletteContextImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorPaletteSession {
  EditorPaletteContextKey? get activeKey => throw _privateConstructorUsedError;
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts =>
      throw _privateConstructorUsedError;
  List<String> get recentTilesetIds => throw _privateConstructorUsedError;
  List<String> get favoriteTilesetIds => throw _privateConstructorUsedError;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorPaletteSessionCopyWith<EditorPaletteSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteSessionCopyWith<$Res> {
  factory $EditorPaletteSessionCopyWith(EditorPaletteSession value,
          $Res Function(EditorPaletteSession) then) =
      _$EditorPaletteSessionCopyWithImpl<$Res, EditorPaletteSession>;
  @useResult
  $Res call(
      {EditorPaletteContextKey? activeKey,
      Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      List<String> recentTilesetIds,
      List<String> favoriteTilesetIds});

  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey;
}

/// @nodoc
class _$EditorPaletteSessionCopyWithImpl<$Res,
        $Val extends EditorPaletteSession>
    implements $EditorPaletteSessionCopyWith<$Res> {
  _$EditorPaletteSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeKey = freezed,
    Object? contexts = null,
    Object? recentTilesetIds = null,
    Object? favoriteTilesetIds = null,
  }) {
    return _then(_value.copyWith(
      activeKey: freezed == activeKey
          ? _value.activeKey
          : activeKey // ignore: cast_nullable_to_non_nullable
              as EditorPaletteContextKey?,
      contexts: null == contexts
          ? _value.contexts
          : contexts // ignore: cast_nullable_to_non_nullable
              as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,
      recentTilesetIds: null == recentTilesetIds
          ? _value.recentTilesetIds
          : recentTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      favoriteTilesetIds: null == favoriteTilesetIds
          ? _value.favoriteTilesetIds
          : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey {
    if (_value.activeKey == null) {
      return null;
    }

    return $EditorPaletteContextKeyCopyWith<$Res>(_value.activeKey!, (value) {
      return _then(_value.copyWith(activeKey: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorPaletteSessionImplCopyWith<$Res>
    implements $EditorPaletteSessionCopyWith<$Res> {
  factory _$$EditorPaletteSessionImplCopyWith(_$EditorPaletteSessionImpl value,
          $Res Function(_$EditorPaletteSessionImpl) then) =
      __$$EditorPaletteSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EditorPaletteContextKey? activeKey,
      Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      List<String> recentTilesetIds,
      List<String> favoriteTilesetIds});

  @override
  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey;
}

/// @nodoc
class __$$EditorPaletteSessionImplCopyWithImpl<$Res>
    extends _$EditorPaletteSessionCopyWithImpl<$Res, _$EditorPaletteSessionImpl>
    implements _$$EditorPaletteSessionImplCopyWith<$Res> {
  __$$EditorPaletteSessionImplCopyWithImpl(_$EditorPaletteSessionImpl _value,
      $Res Function(_$EditorPaletteSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeKey = freezed,
    Object? contexts = null,
    Object? recentTilesetIds = null,
    Object? favoriteTilesetIds = null,
  }) {
    return _then(_$EditorPaletteSessionImpl(
      activeKey: freezed == activeKey
          ? _value.activeKey
          : activeKey // ignore: cast_nullable_to_non_nullable
              as EditorPaletteContextKey?,
      contexts: null == contexts
          ? _value._contexts
          : contexts // ignore: cast_nullable_to_non_nullable
              as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,
      recentTilesetIds: null == recentTilesetIds
          ? _value._recentTilesetIds
          : recentTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      favoriteTilesetIds: null == favoriteTilesetIds
          ? _value._favoriteTilesetIds
          : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$EditorPaletteSessionImpl implements _EditorPaletteSession {
  const _$EditorPaletteSessionImpl(
      {this.activeKey,
      final Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts =
          const <EditorPaletteContextKey, EditorLayerPaletteContext>{},
      final List<String> recentTilesetIds = const <String>[],
      final List<String> favoriteTilesetIds = const <String>[]})
      : _contexts = contexts,
        _recentTilesetIds = recentTilesetIds,
        _favoriteTilesetIds = favoriteTilesetIds;

  @override
  final EditorPaletteContextKey? activeKey;
  final Map<EditorPaletteContextKey, EditorLayerPaletteContext> _contexts;
  @override
  @JsonKey()
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts {
    if (_contexts is EqualUnmodifiableMapView) return _contexts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_contexts);
  }

  final List<String> _recentTilesetIds;
  @override
  @JsonKey()
  List<String> get recentTilesetIds {
    if (_recentTilesetIds is EqualUnmodifiableListView)
      return _recentTilesetIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTilesetIds);
  }

  final List<String> _favoriteTilesetIds;
  @override
  @JsonKey()
  List<String> get favoriteTilesetIds {
    if (_favoriteTilesetIds is EqualUnmodifiableListView)
      return _favoriteTilesetIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoriteTilesetIds);
  }

  @override
  String toString() {
    return 'EditorPaletteSession(activeKey: $activeKey, contexts: $contexts, recentTilesetIds: $recentTilesetIds, favoriteTilesetIds: $favoriteTilesetIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorPaletteSessionImpl &&
            (identical(other.activeKey, activeKey) ||
                other.activeKey == activeKey) &&
            const DeepCollectionEquality().equals(other._contexts, _contexts) &&
            const DeepCollectionEquality()
                .equals(other._recentTilesetIds, _recentTilesetIds) &&
            const DeepCollectionEquality()
                .equals(other._favoriteTilesetIds, _favoriteTilesetIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      activeKey,
      const DeepCollectionEquality().hash(_contexts),
      const DeepCollectionEquality().hash(_recentTilesetIds),
      const DeepCollectionEquality().hash(_favoriteTilesetIds));

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorPaletteSessionImplCopyWith<_$EditorPaletteSessionImpl>
      get copyWith =>
          __$$EditorPaletteSessionImplCopyWithImpl<_$EditorPaletteSessionImpl>(
              this, _$identity);
}

abstract class _EditorPaletteSession implements EditorPaletteSession {
  const factory _EditorPaletteSession(
      {final EditorPaletteContextKey? activeKey,
      final Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      final List<String> recentTilesetIds,
      final List<String> favoriteTilesetIds}) = _$EditorPaletteSessionImpl;

  @override
  EditorPaletteContextKey? get activeKey;
  @override
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts;
  @override
  List<String> get recentTilesetIds;
  @override
  List<String> get favoriteTilesetIds;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorPaletteSessionImplCopyWith<_$EditorPaletteSessionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
``````

### 14.8 `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart`

SHA-256 : `b690f513cde10d3cf2b0291283b70181c2cc0fad53c37fb1cc2c2f101d5d749f`
Lignes : `543`

``````dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;

enum EditorImageFailureKind {
  invalidPath,
  missingFile,
  emptyFile,
  readFailed,
  decodeFailed,
  cacheDisposed,
}

class EditorImageFailure {
  const EditorImageFailure({
    required this.kind,
    required this.path,
    required this.message,
    this.cause,
  });

  final EditorImageFailureKind kind;
  final String path;
  final String message;
  final Object? cause;
}

/// A successful result owns one disposable consumer handle.
///
/// Call [dispose] when the consumer no longer paints or inspects [image].
class EditorImageLoadResult {
  EditorImageLoadResult.success(ui.Image decodedImage)
      : image = decodedImage,
        failure = null,
        _lease = _EditorImageConsumerLease();

  const EditorImageLoadResult.failure(EditorImageFailure loadFailure)
      : image = null,
        failure = loadFailure,
        _lease = null;

  final ui.Image? image;
  final EditorImageFailure? failure;
  final _EditorImageConsumerLease? _lease;

  bool get isSuccess => image != null;

  /// Releases this consumer's image handle without affecting cache masters or
  /// handles owned by other consumers.
  void release() {
    final decodedImage = image;
    if (decodedImage != null) {
      _lease?.release(decodedImage);
    }
  }

  /// Alias for [release], suitable for widget and owner lifecycle methods.
  void dispose() => release();
}

class _EditorImageConsumerLease {
  var _released = false;

  void release(ui.Image image) {
    if (_released) return;
    _released = true;
    image.dispose();
  }
}

class EditorImageCacheDiagnostics {
  const EditorImageCacheDiagnostics({
    required this.sessionKey,
    required this.entries,
    required this.hits,
    required this.misses,
    required this.invalidations,
    required this.missingFiles,
    required this.readFailures,
    required this.decodeFailures,
    required this.disposedImages,
    required this.isDisposed,
  });

  final String sessionKey;
  final int entries;
  final int hits;
  final int misses;
  final int invalidations;
  final int missingFiles;
  final int readFailures;
  final int decodeFailures;
  final int disposedImages;
  final bool isDisposed;
}

typedef EditorImageBytesTransform = FutureOr<Uint8List> Function(
  Uint8List bytes,
);

typedef EditorImageRetirementScheduler = void Function(
  void Function() disposeImage,
);

class EditorImageCache {
  EditorImageCache({
    required this.sessionKey,
    EditorImageRetirementScheduler? retirementScheduler,
  }) : _scheduleRetirement = retirementScheduler ?? _scheduleAfterConsumerFrame;

  final String sessionKey;
  final EditorImageRetirementScheduler _scheduleRetirement;

  final Map<_EditorImageSlot, _EditorImageCacheEntry> _entries =
      <_EditorImageSlot, _EditorImageCacheEntry>{};
  final Expando<bool> _disposedImageIdentities =
      Expando<bool>('disposed editor image');

  var _hits = 0;
  var _misses = 0;
  var _invalidations = 0;
  var _missingFiles = 0;
  var _readFailures = 0;
  var _decodeFailures = 0;
  var _disposedImages = 0;
  var _disposed = false;

  EditorImageCacheDiagnostics get diagnostics => EditorImageCacheDiagnostics(
        sessionKey: sessionKey,
        entries: _entries.length,
        hits: _hits,
        misses: _misses,
        invalidations: _invalidations,
        missingFiles: _missingFiles,
        readFailures: _readFailures,
        decodeFailures: _decodeFailures,
        disposedImages: _disposedImages,
        isDisposed: _disposed,
      );

  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) async {
    final rawPath = path?.trim() ?? '';
    if (_disposed) {
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.cacheDisposed,
          path: rawPath,
          message: 'The image cache for this project session is closed.',
        ),
      );
    }
    if (rawPath.isEmpty) {
      _misses += 1;
      return const EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.invalidPath,
          path: '',
          message: 'No image path was provided.',
        ),
      );
    }

    final unresolvedFile = File(rawPath).absolute;
    if (!await unresolvedFile.exists()) {
      _misses += 1;
      _missingFiles += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: p.normalize(unresolvedFile.path),
          message: 'The image file does not exist.',
        ),
      );
    }

    late final String canonicalPath;
    late final FileStat stat;
    try {
      canonicalPath = p.normalize(
        await unresolvedFile.resolveSymbolicLinks(),
      );
      stat = await File(canonicalPath).stat();
    } on Object catch (error) {
      _misses += 1;
      _readFailures += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.readFailed,
          path: p.normalize(unresolvedFile.path),
          message: 'The image file metadata could not be read.',
          cause: error,
        ),
      );
    }

    final slot = _EditorImageSlot(
      canonicalPath: canonicalPath,
      variantKey: variantKey,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
    );
    final fingerprint = _EditorImageFingerprint(
      byteLength: stat.size,
      modifiedMicros: stat.modified.microsecondsSinceEpoch,
    );
    final current = _entries[slot];
    if (current != null && current.fingerprint == fingerprint) {
      _hits += 1;
      return _acquireConsumer(
        current.future,
        canonicalPath: canonicalPath,
      );
    }

    _misses += 1;
    if (current != null) {
      _invalidations += 1;
      _retire(current.future);
    }

    late final Future<_EditorImageMasterResult> future;
    future = _decode(
      canonicalPath,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
      transformBytes: transformBytes,
    );
    _entries[slot] = _EditorImageCacheEntry(
      fingerprint: fingerprint,
      future: future,
    );
    unawaited(
      future.then((result) {
        if (result.failure != null &&
            identical(_entries[slot]?.future, future)) {
          _entries.remove(slot);
        }
        if (_disposed && result.image != null) {
          _scheduleImageDisposal(result.image!);
        }
      }),
    );
    return _acquireConsumer(
      future,
      canonicalPath: canonicalPath,
    );
  }

  Future<Map<String, EditorImageLoadResult>> loadMany(
    Map<String, String> paths, {
    String Function(String id)? variantKeyForId,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? Function(String id)? transformForId,
  }) async {
    final entries = await Future.wait(
      paths.entries.map((entry) async {
        final result = await load(
          entry.value,
          variantKey: variantKeyForId?.call(entry.key) ?? 'original',
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          allowUpscaling: allowUpscaling,
          transformBytes: transformForId?.call(entry.key),
        );
        return MapEntry<String, EditorImageLoadResult>(entry.key, result);
      }),
    );
    return Map<String, EditorImageLoadResult>.fromEntries(entries);
  }

  Future<void> invalidate(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty || _disposed) return;
    final file = File(trimmed).absolute;
    String canonicalPath;
    try {
      canonicalPath = p.normalize(await file.resolveSymbolicLinks());
    } on Object {
      canonicalPath = p.normalize(file.path);
    }
    final matchingSlots = _entries.keys
        .where((slot) => slot.canonicalPath == canonicalPath)
        .toList(growable: false);
    for (final slot in matchingSlots) {
      final entry = _entries.remove(slot);
      if (entry != null) {
        _invalidations += 1;
        _retire(entry.future);
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final ownedFutures = <Future<_EditorImageMasterResult>>{
      ..._entries.values.map((entry) => entry.future),
    };
    _entries.clear();
    for (final future in ownedFutures) {
      unawaited(
        future.then((result) {
          final image = result.image;
          if (image != null) {
            _scheduleImageDisposal(image);
          }
        }),
      );
    }
  }

  Future<_EditorImageMasterResult> _decode(
    String canonicalPath, {
    required int? targetWidth,
    required int? targetHeight,
    required bool allowUpscaling,
    required EditorImageBytesTransform? transformBytes,
  }) async {
    Uint8List bytes;
    try {
      bytes = await File(canonicalPath).readAsBytes();
      if (bytes.isEmpty) {
        _readFailures += 1;
        return _EditorImageMasterResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.emptyFile,
            path: canonicalPath,
            message: 'The image file is empty.',
          ),
        );
      }
      if (transformBytes != null) {
        bytes = await transformBytes(bytes);
      }
    } on Object catch (error) {
      _readFailures += 1;
      return _EditorImageMasterResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.readFailed,
          path: canonicalPath,
          message: 'The image bytes could not be read.',
          cause: error,
        ),
      );
    }

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
      final frame = await codec.getNextFrame();
      if (_disposed) {
        _disposeImage(frame.image);
        return _EditorImageMasterResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project session closed while the image was loading.',
          ),
        );
      }
      return _EditorImageMasterResult.success(frame.image);
    } on Object catch (error) {
      _decodeFailures += 1;
      return _EditorImageMasterResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.decodeFailed,
          path: canonicalPath,
          message: 'The image file could not be decoded.',
          cause: error,
        ),
      );
    } finally {
      codec?.dispose();
    }
  }

  void _disposeImage(ui.Image image) {
    if (_disposedImageIdentities[image] == true) return;
    _disposedImageIdentities[image] = true;
    image.dispose();
    _disposedImages += 1;
  }

  Future<EditorImageLoadResult> _acquireConsumer(
    Future<_EditorImageMasterResult> future, {
    required String canonicalPath,
  }) async {
    final result = await future;
    final failure = result.failure;
    if (failure != null) {
      return EditorImageLoadResult.failure(failure);
    }
    if (_disposed) {
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.cacheDisposed,
          path: canonicalPath,
          message: 'The project session closed while the image was loading.',
        ),
      );
    }
    final image = result.image;
    if (image == null) {
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.decodeFailed,
          path: canonicalPath,
          message: 'The decoded image is unavailable.',
        ),
      );
    }
    try {
      return EditorImageLoadResult.success(image.clone());
    } on Object catch (error) {
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.cacheDisposed,
          path: canonicalPath,
          message: 'The project image became unavailable before acquisition.',
          cause: error,
        ),
      );
    }
  }

  void _retire(Future<_EditorImageMasterResult> future) {
    unawaited(
      future.then((result) {
        final image = result.image;
        if (image == null) return;
        _scheduleImageDisposal(image);
      }),
    );
  }

  void _scheduleImageDisposal(ui.Image image) {
    _scheduleRetirement(() => _disposeImage(image));
  }

  static void _scheduleAfterConsumerFrame(void Function() disposeImage) {
    final scheduler = SchedulerBinding.instance;
    scheduler.addPostFrameCallback((_) => disposeImage());
    scheduler.ensureVisualUpdate();
  }
}

class _EditorImageSlot {
  const _EditorImageSlot({
    required this.canonicalPath,
    required this.variantKey,
    required this.targetWidth,
    required this.targetHeight,
    required this.allowUpscaling,
  });

  final String canonicalPath;
  final String variantKey;
  final int? targetWidth;
  final int? targetHeight;
  final bool allowUpscaling;

  @override
  bool operator ==(Object other) {
    return other is _EditorImageSlot &&
        other.canonicalPath == canonicalPath &&
        other.variantKey == variantKey &&
        other.targetWidth == targetWidth &&
        other.targetHeight == targetHeight &&
        other.allowUpscaling == allowUpscaling;
  }

  @override
  int get hashCode => Object.hash(
        canonicalPath,
        variantKey,
        targetWidth,
        targetHeight,
        allowUpscaling,
      );
}

class _EditorImageFingerprint {
  const _EditorImageFingerprint({
    required this.byteLength,
    required this.modifiedMicros,
  });

  final int byteLength;
  final int modifiedMicros;

  @override
  bool operator ==(Object other) {
    return other is _EditorImageFingerprint &&
        other.byteLength == byteLength &&
        other.modifiedMicros == modifiedMicros;
  }

  @override
  int get hashCode => Object.hash(byteLength, modifiedMicros);
}

class _EditorImageCacheEntry {
  const _EditorImageCacheEntry({
    required this.fingerprint,
    required this.future,
  });

  final _EditorImageFingerprint fingerprint;
  final Future<_EditorImageMasterResult> future;
}

class _EditorImageMasterResult {
  const _EditorImageMasterResult.success(ui.Image decodedImage)
      : image = decodedImage,
        failure = null;

  const _EditorImageMasterResult.failure(EditorImageFailure loadFailure)
      : image = null,
        failure = loadFailure;

  final ui.Image? image;
  final EditorImageFailure? failure;
}
``````

### 14.9 `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart`

SHA-256 : `0cf44f56b2861e6d33244adbc5b6724b23f043367904fcde46c83b8d6b45d225`
Lignes : `630`

``````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../../app/providers/use_case_providers.dart';
import '../../../../../application/models/map_palette_asset_browser.dart';
import '../../../../../application/services/map_palette_asset_browser_projector.dart';
import '../../../../../features/editor/state/editor_notifier.dart';
import '../../../../../features/editor/state/editor_selectors.dart';
import '../../../../../features/editor/state/editor_state.dart';
import '../../../../design_system/design_system.dart';
import '../../../../../theme/theme.dart';

abstract final class MapPaletteAssetBrowserKeys {
  static const openButton = ValueKey<String>('world-map-asset-browser-open');
  static const sheet = ValueKey<String>('world-map-asset-browser-sheet');
  static const search = ValueKey<String>('world-map-asset-browser-search');
  static const collectionAll =
      ValueKey<String>('world-map-asset-browser-collection-all');
  static const collectionRecent =
      ValueKey<String>('world-map-asset-browser-collection-recent');
  static const collectionFavorites =
      ValueKey<String>('world-map-asset-browser-collection-favorites');
  static const folderRail = ValueKey<String>('world-map-asset-browser-folders');
  static const folderPicker =
      ValueKey<String>('world-map-asset-browser-folder-picker');
  static const categoryFilter =
      ValueKey<String>('world-map-asset-browser-category-filter');
  static const showIncompatible =
      ValueKey<String>('world-map-asset-browser-show-incompatible');
  static const resultCount =
      ValueKey<String>('world-map-asset-browser-result-count');
  static const results = ValueKey<String>('world-map-asset-browser-results');
  static const empty = ValueKey<String>('world-map-asset-browser-empty');
  static const folderAll =
      ValueKey<String>('world-map-asset-browser-folder-all');
  static const folderUnclassified =
      ValueKey<String>('world-map-asset-browser-folder-unclassified');

  static ValueKey<String> folder(String id) =>
      ValueKey<String>('world-map-asset-browser-folder-$id');

  static ValueKey<String> tilesetRow(String id) =>
      ValueKey<String>('world-map-asset-browser-tileset-$id');

  static ValueKey<String> tilesetSemantics(String id) =>
      ValueKey<String>('world-map-asset-browser-tileset-semantics-$id');

  static ValueKey<String> favoriteButton(String id) =>
      ValueKey<String>('world-map-asset-browser-favorite-$id');

  static ValueKey<String> assignButton(String id) =>
      ValueKey<String>('world-map-asset-browser-assign-$id');
}

class MapPaletteAssetBrowserLauncher extends ConsumerStatefulWidget {
  const MapPaletteAssetBrowserLauncher({super.key});

  @override
  ConsumerState<MapPaletteAssetBrowserLauncher> createState() =>
      _MapPaletteAssetBrowserLauncherState();
}

class _MapPaletteAssetBrowserLauncherState
    extends ConsumerState<MapPaletteAssetBrowserLauncher> {
  final FocusNode _launcherFocusNode = FocusNode(
    debugLabel: 'world map asset browser launcher',
  );

  @override
  void dispose() {
    _launcherFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openBrowser() async {
    final searchFocusNode = FocusNode(
      debugLabel: 'world map asset browser search',
    );
    final container = ProviderScope.containerOf(context);
    try {
      await showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Sources de tuiles & éléments',
        semanticLabel: 'Bibliothèque de sources pour le calque actif',
        width: 560,
        initialFocusNode: searchFocusNode,
        builder: (_) => UncontrolledProviderScope(
          container: container,
          child: _MapPaletteAssetBrowserSheet(
            searchFocusNode: searchFocusNode,
          ),
        ),
      );
    } finally {
      searchFocusNode.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorMapPaletteAssetBrowserSnapshotProvider);
    final selectedId = snapshot.context.selectedTilesetId;
    String? selectedName;
    var assignedSourceMissing = snapshot.assignedTilesetId != null;
    for (final tileset
        in snapshot.project?.tilesets ?? const <ProjectTilesetEntry>[]) {
      if (tileset.id == selectedId) {
        selectedName = tileset.name;
      }
      if (tileset.id == snapshot.assignedTilesetId) {
        assignedSourceMissing = false;
      }
    }
    return PokeMapButton(
      key: MapPaletteAssetBrowserKeys.openButton,
      focusNode: _launcherFocusNode,
      onPressed: snapshot.project == null ? null : _openBrowser,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: const Icon(Icons.grid_view_rounded),
      trailing: const Icon(Icons.chevron_right_rounded),
      child: Text(
        assignedSourceMissing
            ? 'Source introuvable : ${snapshot.assignedTilesetId}'
            : selectedName == null
                ? 'Choisir une source'
                : 'Source : $selectedName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MapPaletteAssetBrowserSheet extends ConsumerStatefulWidget {
  const _MapPaletteAssetBrowserSheet({
    required this.searchFocusNode,
  });

  final FocusNode searchFocusNode;

  @override
  ConsumerState<_MapPaletteAssetBrowserSheet> createState() =>
      _MapPaletteAssetBrowserSheetState();
}

class _MapPaletteAssetBrowserSheetState
    extends ConsumerState<_MapPaletteAssetBrowserSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final query = ref
        .read(editorMapPaletteAssetBrowserSnapshotProvider)
        .context
        .browserQuery;
    _searchController = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final snapshot = ref.watch(editorMapPaletteAssetBrowserSnapshotProvider);
    final browserContext = snapshot.context;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final projector = MapPaletteAssetBrowserProjector(
      ref.watch(resolveAssignableTilesetsForMapUseCaseProvider),
      ref.watch(resolveVisibleProjectElementsUseCaseProvider),
    );
    final projection = projector.project(
      project: snapshot.project,
      map: snapshot.activeMap,
      activeLayerId: snapshot.activeLayerId,
      selectedTilesetId: browserContext.selectedTilesetId,
      query: browserContext.browserQuery,
      folderId: browserContext.browserFolderId,
      elementCategoryId: browserContext.projectElementCategoryId,
      collection: browserContext.browserCollection,
      showIncompatible: browserContext.showIncompatible,
      recentTilesetIds: snapshot.recentTilesetIds,
      favoriteTilesetIds: snapshot.favoriteTilesetIds,
    );
    final assignedName = _tilesetName(
      snapshot.project,
      projection.assignedTilesetId,
    );
    final assignedSourceMissing =
        projection.assignedTilesetId != null && assignedName == null;

    return KeyedSubtree(
      key: MapPaletteAssetBrowserKeys.sheet,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PokeMapBadge(
                  label: 'Calque : ${projection.activeLayerName ?? 'aucun'}',
                  variant: PokeMapBadgeVariant.mapAccent,
                ),
                PokeMapBadge(
                  label: assignedSourceMissing
                      ? 'Assignée introuvable : ${projection.assignedTilesetId}'
                      : assignedName == null
                          ? 'Aucune source assignée'
                          : 'Assigné : $assignedName',
                  variant: assignedName == null
                      ? PokeMapBadgeVariant.warning
                      : PokeMapBadgeVariant.success,
                ),
              ],
            ),
            if (projection.diagnostic case final diagnostic?) ...[
              const SizedBox(height: 10),
              PokeMapDiagnosticCallout(
                severity: switch (projection.status) {
                  MapPaletteAssetBrowserStatus.invalidMapScope =>
                    PokeMapDiagnosticSeverity.error,
                  MapPaletteAssetBrowserStatus.assignedSourceMissing =>
                    PokeMapDiagnosticSeverity.warning,
                  _ => PokeMapDiagnosticSeverity.info,
                },
                message: diagnostic,
              ),
            ],
            const SizedBox(height: 12),
            KeyedSubtree(
              key: MapPaletteAssetBrowserKeys.search,
              child: PokeMapSearchField(
                controller: _searchController,
                focusNode: widget.searchFocusNode,
                semanticLabel: 'Rechercher une source déclarée',
                hintText: 'Nom, dossier, élément ou catégorie…',
                onChanged: notifier.setPaletteBrowserQuery,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionAll,
                  label: 'Toutes',
                  value: EditorPaletteAssetCollection.all,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionRecent,
                  label: 'Récentes · session',
                  value: EditorPaletteAssetCollection.recent,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionFavorites,
                  label: 'Favoris · session',
                  value: EditorPaletteAssetCollection.favorites,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PokeMapDropdownField<String>(
              key: MapPaletteAssetBrowserKeys.categoryFilter,
              label: 'Contient des éléments de…',
              value: browserContext.projectElementCategoryId ?? '',
              compact: true,
              items: <PokeMapDropdownItem<String>>[
                const PokeMapDropdownItem<String>(
                  value: '',
                  label: 'Toutes les catégories déclarées',
                ),
                for (final category in projection.categories)
                  PokeMapDropdownItem<String>(
                    value: category.id,
                    label: category.path,
                  ),
              ],
              onChanged: (value) => notifier.setPaletteBrowserElementCategory(
                value.isEmpty ? null : value,
              ),
            ),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: MapPaletteAssetBrowserKeys.showIncompatible,
              child: PokeMapToggleTile(
                label: 'Voir les sources non disponibles',
                description: projection.hiddenIncompatibleCount == 0
                    ? 'Aucune source masquée par le contexte actif.'
                    : '${projection.hiddenIncompatibleCount} source(s) '
                        'masquée(s) avec leur raison.',
                value: browserContext.showIncompatible,
                onChanged: notifier.setPaletteBrowserShowIncompatible,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              label: '${projection.items.length} source(s) affichée(s)',
              child: Text(
                '${projection.items.length} source(s)',
                key: MapPaletteAssetBrowserKeys.resultCount,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final results = _AssetBrowserResults(
                    projection: projection,
                    onSelect: notifier.selectTilesetEditorContext,
                    onToggleFavorite: notifier.togglePaletteTilesetFavorite,
                  );
                  if (constraints.maxWidth < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FolderPicker(
                          projection: projection,
                          selectedFolderId: browserContext.browserFolderId,
                          onSelected: notifier.setPaletteBrowserFolder,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: results),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 176,
                        child: _FolderRail(
                          projection: projection,
                          selectedFolderId: browserContext.browserFolderId,
                          onSelected: notifier.setPaletteBrowserFolder,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: results),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _AssignmentFooter(
              projection: projection,
              onAssign: (tilesetId) => unawaited(
                notifier.assignTilesetToActiveLayer(tilesetId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionButton({
    required Key key,
    required String label,
    required EditorPaletteAssetCollection value,
    required EditorPaletteAssetCollection selected,
    required ValueChanged<EditorPaletteAssetCollection> onSelected,
  }) {
    return PokeMapButton(
      key: key,
      onPressed: () => onSelected(value),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: value == selected,
      child: Text(label),
    );
  }
}

class _FolderRail extends StatelessWidget {
  const _FolderRail({
    required this.projection,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final MapPaletteAssetBrowserProjection projection;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: MapPaletteAssetBrowserKeys.folderRail,
      children: [
        PokeMapSidebarItem(
          key: MapPaletteAssetBrowserKeys.folderAll,
          label: 'Tous les dossiers',
          compact: true,
          selected: selectedFolderId == null,
          onTap: () => onSelected(null),
        ),
        for (final folder in projection.folders)
          PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.folder(folder.id),
            label: folder.path,
            compact: true,
            selected: selectedFolderId == folder.id,
            onTap: () => onSelected(folder.id),
          ),
        if (projection.hasUnclassifiedSources)
          PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.folderUnclassified,
            label: 'Non classé',
            compact: true,
            selected: selectedFolderId == kEditorPaletteUnclassifiedFolderId,
            onTap: () => onSelected(kEditorPaletteUnclassifiedFolderId),
          ),
      ],
    );
  }
}

class _FolderPicker extends StatelessWidget {
  const _FolderPicker({
    required this.projection,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final MapPaletteAssetBrowserProjection projection;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PokeMapDropdownField<String>(
      key: MapPaletteAssetBrowserKeys.folderPicker,
      label: 'Dossier',
      value: selectedFolderId ?? '',
      compact: true,
      items: <PokeMapDropdownItem<String>>[
        const PokeMapDropdownItem<String>(
          value: '',
          label: 'Tous les dossiers',
        ),
        for (final folder in projection.folders)
          PokeMapDropdownItem<String>(
            value: folder.id,
            label: folder.path,
          ),
        if (projection.hasUnclassifiedSources)
          const PokeMapDropdownItem<String>(
            value: kEditorPaletteUnclassifiedFolderId,
            label: 'Non classé',
          ),
      ],
      onChanged: (value) => onSelected(value.isEmpty ? null : value),
    );
  }
}

class _AssetBrowserResults extends StatelessWidget {
  const _AssetBrowserResults({
    required this.projection,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  final MapPaletteAssetBrowserProjection projection;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (projection.items.isEmpty) {
      return const PokeMapEmptyState(
        key: MapPaletteAssetBrowserKeys.empty,
        icon: Icon(Icons.search_off_rounded),
        title: 'Aucune source trouvée',
        description:
            'Modifiez la recherche, le dossier ou la collection de session.',
      );
    }
    return ListView.separated(
      key: MapPaletteAssetBrowserKeys.results,
      itemCount: projection.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = projection.items[index];
        final stateLabel = item.isAssigned
            ? 'Assigné'
            : item.isCompatible
                ? 'Disponible'
                : 'Non disponible';
        final subtitle = <String>[
          if (item.disabledReason case final reason?) reason,
          item.folderPath,
          item.scopeLabel,
          stateLabel,
        ].join(' · ');
        final semanticLabel = <String>[
          item.tileset.name,
          if (item.isSelected) 'Sélectionnée dans le navigateur',
          if (item.isAssigned) 'Assignée au calque actif',
          if (item.isFavorite) 'Favori de cette session',
          if (!item.isCompatible) 'Désactivée',
          if (item.disabledReason case final reason?) reason,
          item.folderPath,
          item.scopeLabel,
        ].join('. ');
        return Semantics(
          key: MapPaletteAssetBrowserKeys.tilesetSemantics(item.tileset.id),
          container: true,
          label: semanticLabel,
          selected: item.isSelected,
          enabled: item.isCompatible,
          child: PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.tilesetRow(item.tileset.id),
            label: item.tileset.name,
            subtitle: subtitle,
            compact: true,
            growForTextScale: true,
            subtitleMaxLines: item.disabledReason == null ? 1 : 2,
            selected: item.isSelected,
            disabled: !item.isCompatible,
            icon: const Icon(Icons.grid_view_rounded),
            onTap: item.isCompatible ? () => onSelect(item.tileset.id) : null,
            trailing: PokeMapIconButton(
              key: MapPaletteAssetBrowserKeys.favoriteButton(item.tileset.id),
              onPressed: () => onToggleFavorite(item.tileset.id),
              icon: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
              tooltip: item.isFavorite
                  ? 'Retirer des favoris de cette session'
                  : 'Ajouter aux favoris de cette session',
              isSelected: item.isFavorite,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentFooter extends StatelessWidget {
  const _AssignmentFooter({
    required this.projection,
    required this.onAssign,
  });

  final MapPaletteAssetBrowserProjection projection;
  final ValueChanged<String> onAssign;

  @override
  Widget build(BuildContext context) {
    MapPaletteAssetBrowserItem? selected;
    for (final item in projection.items) {
      if (item.isSelected) {
        selected = item;
        break;
      }
    }
    final selectedItem = selected;
    if (selectedItem == null) {
      return const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Parcourir sans modifier',
        message: 'Sélectionnez une source disponible. La carte ne changera que '
            'lorsque vous utiliserez explicitement le bouton Assigner.',
      );
    }
    if (selectedItem.isAssigned) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Source assignée',
        message:
            '« ${selectedItem.tileset.name} » est déjà la source de ce calque.',
      );
    }
    if (!selectedItem.canAssign) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.warning,
        title: 'Assignation indisponible',
        message: selectedItem.disabledReason ??
            'Cette source ne peut pas être assignée au calque actif.',
      );
    }
    return PokeMapButton(
      key: MapPaletteAssetBrowserKeys.assignButton(selectedItem.tileset.id),
      onPressed: () => onAssign(selectedItem.tileset.id),
      variant: PokeMapButtonVariant.primary,
      leading: const Icon(Icons.link_rounded),
      child: Text(
        'Assigner à « ${projection.activeLayerName ?? 'ce calque'} »',
      ),
    );
  }
}

String? _tilesetName(ProjectManifest? project, String? tilesetId) {
  if (project == null || tilesetId == null) return null;
  for (final tileset in project.tilesets) {
    if (tileset.id == tilesetId) return tileset.name;
  }
  return null;
}
``````

### 14.10 `packages/map_editor/test/editor_image_cache_test.dart`

SHA-256 : `bb4168384d7dee1e055b16fc9edd90860960bc6fc3fe447ff69a61a27d16d725`
Lignes : `377`

``````dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pokemap-image-cache-');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('reports missing files without pinning a null cache entry', () async {
    final cache = _immediateCache(tempDir);
    final missingPath = '${tempDir.path}/missing.png';

    final first = await cache.load(missingPath);
    final second = await cache.load(missingPath);

    expect(first.failure?.kind, EditorImageFailureKind.missingFile);
    expect(second.failure?.kind, EditorImageFailureKind.missingFile);
    expect(cache.diagnostics.entries, 0);
    expect(cache.diagnostics.missingFiles, 2);
    expect(cache.diagnostics.misses, 2);

    cache.dispose();
  });

  test('reuses decoded pixels through distinct consumer image handles',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final first = await cache.load(file.path);
    final second = await cache.load(file.path);

    expect(first.image, isNotNull);
    expect(identical(second.image, first.image), isFalse);
    expect(second.image!.isCloneOf(first.image!), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.misses, 1);
    expect(cache.diagnostics.hits, 1);

    first.dispose();
    expect(second.image!.debugDisposed, isFalse);
    final secondConsumerClone = second.image!.clone();
    secondConsumerClone.dispose();
    second.dispose();
    cache.dispose();
  });

  test('canonical path aliases share one decoded image', () async {
    final file = File('${tempDir.path}/tiles.png');
    final alias = Link('${tempDir.path}/tiles-alias.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    await alias.create(file.path);
    final cache = _immediateCache(tempDir);

    final first = await cache.load(file.path);
    final second = await cache.load(alias.path);

    expect(identical(second.image, first.image), isFalse);
    expect(second.image!.isCloneOf(first.image!), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.hits, 1);

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  test('invalidates a same-path image when the file fingerprint changes',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final first = await cache.load(file.path);
    expect(first.image?.width, 1);

    await file.writeAsBytes(_png(width: 2, height: 1), flush: true);
    await file.setLastModified(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    final second = await cache.load(file.path);
    await Future<void>.delayed(Duration.zero);

    expect(second.image?.width, 2);
    expect(identical(second.image, first.image), isFalse);
    expect(cache.diagnostics.invalidations, 1);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.disposedImages, 1);
    expect(first.image!.debugDisposed, isFalse);
    final retainedConsumerClone = first.image!.clone();
    retainedConsumerClone.dispose();

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  testWidgets(
      'default retirement keeps superseded images through the handoff frame',
      (tester) async {
    final file = File('${tempDir.path}/tiles.png');
    final cache = EditorImageCache(sessionKey: tempDir.path);
    late EditorImageLoadResult first;
    late EditorImageLoadResult second;
    await tester.runAsync(() async {
      await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
      first = await cache.load(file.path);
      await file.writeAsBytes(_png(width: 2, height: 1), flush: true);
      await file.setLastModified(
        DateTime.now().add(const Duration(seconds: 2)),
      );
      second = await cache.load(file.path);
    });

    expect(first.image?.width, 1);
    expect(second.image?.width, 2);
    expect(cache.diagnostics.disposedImages, 0);

    await tester.pump();
    expect(cache.diagnostics.disposedImages, 1);
    expect(first.image!.debugDisposed, isFalse);

    cache.dispose();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(cache.diagnostics.disposedImages, 2);
    expect(first.image!.debugDisposed, isFalse);
    expect(second.image!.debugDisposed, isFalse);

    first.dispose();
    second.dispose();
  });

  test('consumer release is idempotent and independent from cache disposal',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final result = await cache.load(file.path);

    cache.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(cache.diagnostics.disposedImages, 1);
    expect(result.image!.debugDisposed, isFalse);
    expect(result.image!.debugGetOpenHandleStackTraces(), hasLength(1));

    result.release();
    result.dispose();

    expect(result.image!.debugDisposed, isTrue);
    expect(result.image!.debugGetOpenHandleStackTraces(), isEmpty);
  });

  test('keeps decode variants isolated in the cache key', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final original = await cache.load(file.path);
    final transformed = await cache.load(
      file.path,
      variantKey: 'transparent:ff00ff',
      transformBytes: (_) => _png(width: 2, height: 1),
    );
    final transformedAgain = await cache.load(
      file.path,
      variantKey: 'transparent:ff00ff',
      transformBytes: (_) => _png(width: 3, height: 1),
    );

    expect(original.image?.width, 1);
    expect(transformed.image?.width, 2);
    expect(identical(transformedAgain.image, transformed.image), isFalse);
    expect(
      transformedAgain.image!.isCloneOf(transformed.image!),
      isTrue,
    );
    expect(cache.diagnostics.entries, 2);
    expect(cache.diagnostics.hits, 1);

    original.dispose();
    transformed.dispose();
    transformedAgain.dispose();
    cache.dispose();
  });

  test('returns a typed decode diagnostic and recovers after replacement',
      () async {
    final file = File('${tempDir.path}/broken.png');
    await file.writeAsBytes(<int>[1, 2, 3], flush: true);
    final cache = _immediateCache(tempDir);

    final broken = await cache.load(file.path);
    expect(broken.failure?.kind, EditorImageFailureKind.decodeFailed);
    expect(broken.failure?.path, endsWith('broken.png'));
    expect(cache.diagnostics.decodeFailures, 1);
    expect(cache.diagnostics.entries, 0);

    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    await file.setLastModified(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    final recovered = await cache.load(file.path);

    expect(recovered.image, isNotNull);
    expect(recovered.failure, isNull);

    recovered.dispose();
    cache.dispose();
  });

  test('bulk loading preserves typed failures for the canvas', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final results = await cache.loadMany({
      'ground': file.path,
      'missing': '${tempDir.path}/missing.png',
    });

    expect(results['ground']?.image, isNotNull);
    expect(
      results['missing']?.failure?.kind,
      EditorImageFailureKind.missingFile,
    );

    for (final result in results.values) {
      result.dispose();
    }
    cache.dispose();
  });

  test('bulk loading gives each consumer id its own image handle', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final results = await cache.loadMany({
      'ground': file.path,
      'details': file.path,
    });
    final ground = results['ground']!;
    final details = results['details']!;

    expect(identical(ground.image, details.image), isFalse);
    expect(ground.image!.isCloneOf(details.image!), isTrue);

    ground.dispose();
    details.dispose();
    cache.dispose();
  });

  test('dispose is idempotent and owns decoded images', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final consumer = await cache.load(file.path);

    cache.dispose();
    cache.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(cache.diagnostics.isDisposed, isTrue);
    expect(cache.diagnostics.disposedImages, 1);
    expect(consumer.image!.debugDisposed, isFalse);
    final afterDispose = await cache.load(file.path);
    expect(afterDispose.failure?.kind, EditorImageFailureKind.cacheDisposed);

    consumer.dispose();
  });

  test('dispose owns an image that is still decoding', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final transformGate = Completer<Uint8List>();
    final cache = _immediateCache(tempDir);
    final pending = cache.load(
      file.path,
      variantKey: 'pending',
      transformBytes: (_) => transformGate.future,
    );
    await Future<void>.delayed(Duration.zero);

    cache.dispose();
    transformGate.complete(_png(width: 1, height: 1));
    final result = await pending;
    await Future<void>.delayed(Duration.zero);

    expect(result.failure?.kind, EditorImageFailureKind.cacheDisposed);
    expect(cache.diagnostics.disposedImages, 1);
  });

  test('provider isolates and disposes project sessions', () async {
    final container = ProviderContainer();
    final first = container.read(editorImageCacheProvider('/project/a'));
    final second = container.read(editorImageCacheProvider('/project/b'));

    expect(identical(first, second), isFalse);

    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(first.diagnostics.isDisposed, isTrue);
    expect(second.diagnostics.isDisposed, isTrue);
  });

  test('autoDispose releases a cache when its provider listener closes',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      editorImageCacheProvider('/project/a'),
      (_, __) {},
    );
    final cache = container.read(editorImageCacheProvider('/project/a'));

    subscription.close();
    await container.pump();

    expect(cache.diagnostics.isDisposed, isTrue);
  });

  test('invalidating a provider replaces and disposes its project owner',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      editorImageCacheProvider('/project/a'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final first = container.read(editorImageCacheProvider('/project/a'));

    container.invalidate(editorImageCacheProvider('/project/a'));
    final second = container.read(editorImageCacheProvider('/project/a'));
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, second), isFalse);
    expect(first.diagnostics.isDisposed, isTrue);
    expect(second.diagnostics.isDisposed, isFalse);
  });
}

Uint8List _png({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}

EditorImageCache _immediateCache(Directory directory) {
  return EditorImageCache(
    sessionKey: directory.path,
    retirementScheduler: (disposeImage) => disposeImage(),
  );
}
``````

### 14.11 `packages/map_editor/test/editor_notifier_palette_context_test.dart`

SHA-256 : `5d589265a7dd05f09d76f8b0260404801871f08fc9d4a3b9d47a8ebf63a8faed`
Lignes : `234`

``````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('setActiveLayer restores an independent palette context A to B to A',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
        selectedTilesetEditorId: 'details',
        selectedTilesetElementGroupId: 'nature',
        paletteCategoryFilter: PaletteCategory.trees,
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
      );

    notifier.setPaletteBrowserQuery('arbres');
    notifier.setPaletteBrowserFolder('outdoor');
    notifier.setPaletteBrowserElementCategory('nature');
    notifier.setPaletteBrowserCollection(
      EditorPaletteAssetCollection.favorites,
    );
    notifier.setPaletteBrowserShowIncompatible(true);
    notifier.togglePaletteTilesetFavorite('world');
    notifier.setActiveLayer('details');

    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    expect(notifier.state.activeBrush, const EditorBrush.none());
    expect(notifier.state.selectedTilesetElementGroupId, isNull);
    expect(notifier.state.paletteCategoryFilter, isNull);
    expect(
      notifier.state.tilesElementsPanelMode,
      TilesElementsPanelMode.palette,
    );
    expect(_activeContext(notifier).browserQuery, isEmpty);
    expect(_activeContext(notifier).browserFolderId, isNull);
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.all,
    );
    expect(_activeContext(notifier).showIncompatible, isFalse);

    notifier.selectTilesetEditorContext('details');
    notifier.selectTilesetElementGroupFilter('decor');
    notifier.setPaletteCategoryFilter(PaletteCategory.decorations);
    notifier.selectPaletteTile(3);
    notifier.setTilesElementsPanelMode(TilesElementsPanelMode.palette);
    notifier.setPaletteBrowserQuery('lampes');
    notifier.setPaletteBrowserCollection(EditorPaletteAssetCollection.recent);

    notifier.setActiveLayer('ground');

    expect(notifier.getSelectedTilesetEntry()?.id, 'world');
    expect(
      notifier.state.activeBrush,
      const EditorBrush.tile(tileId: 7, tilesetId: 'world'),
    );
    expect(notifier.state.selectedTilesetElementGroupId, 'nature');
    expect(notifier.state.paletteCategoryFilter, PaletteCategory.trees);
    expect(
      notifier.state.tilesElementsPanelMode,
      TilesElementsPanelMode.placedInstances,
    );
    expect(_activeContext(notifier).browserQuery, 'arbres');
    expect(_activeContext(notifier).browserFolderId, 'outdoor');
    expect(_activeContext(notifier).projectElementCategoryId, 'nature');
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.favorites,
    );
    expect(_activeContext(notifier).showIncompatible, isTrue);
    expect(notifier.state.paletteSession.favoriteTilesetIds, <String>['world']);

    notifier.setActiveLayer('details');

    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    expect(
      notifier.state.activeBrush,
      const EditorBrush.tile(tileId: 3, tilesetId: 'details'),
    );
    expect(notifier.state.selectedTilesetElementGroupId, 'decor');
    expect(
      notifier.state.paletteCategoryFilter,
      PaletteCategory.decorations,
    );
    expect(_activeContext(notifier).browserQuery, 'lampes');
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.recent,
    );
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('browsing another tileset never arms an incompatible paint brush', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
      );

    notifier.selectTilesetEditorContext('details');
    expect(notifier.getSelectedTilesetEntry()?.id, 'details');

    notifier.selectPaletteTile(3);

    expect(notifier.state.activeBrush, const EditorBrush.none());
    expect(notifier.state.errorMessage, contains('Assignez'));
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('painting never assigns a mismatched brush tileset implicitly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
        activeBrush: EditorBrush.tile(tileId: 3, tilesetId: 'details'),
      );

    notifier.paintSelectedBrushAt(
      const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );

    expect(notifier.state.activeMap, _map);
    expect(
      (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
      'world',
    );
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.errorMessage, contains('Assignez-lui'));
  });

  test('invalid browser filters are rejected without map mutations', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
      );

    notifier.setPaletteBrowserFolder('missing-folder');

    expect(notifier.state.errorMessage, contains('n’existe plus'));
    expect(notifier.state.activeMap, _map);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });
}

EditorLayerPaletteContext _activeContext(EditorNotifier notifier) {
  final map = notifier.state.activeMap!;
  final key = EditorPaletteContextKey(
    mapId: map.id,
    layerId: notifier.state.activeLayerId!,
  );
  return notifier.state.paletteSession.contexts[key]!;
}

const _project = ProjectManifest(
  name: 'Palette context',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Town',
      relativePath: 'maps/town.json',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'nature', name: 'Nature'),
      ],
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'decor', name: 'Décor'),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: [],
    ),
    TileLayer(
      id: 'details',
      name: 'Details',
      tilesetId: 'details',
      tiles: [],
    ),
  ],
);
``````

### 14.12 `packages/map_editor/test/editor_palette_session_service_test.dart`

SHA-256 : `69246d64f6309f24a381145ee94d97a12f1e1e633048ba1db20d9bded8111213`
Lignes : `248`

``````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_palette_session_service.dart';
import 'package:map_editor/src/features/editor/state/models/editor_palette_session.dart';

void main() {
  const service = EditorPaletteSessionService(
    maxRecentTilesets: 3,
    maxFavoriteTilesets: 3,
  );

  group('EditorPaletteSessionService', () {
    test('restores every palette field across A to B to A navigation', () {
      const keyA = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const keyB = EditorPaletteContextKey(mapId: 'town', layerId: 'details');
      const contextA = EditorLayerPaletteContext(
        selectedTilesetId: 'world',
        selectedElementGroupId: 'nature',
        paletteCategoryFilter: PaletteCategory.trees,
        activeBrush:
            EditorPaletteBrushMemory.tile(tileId: 7, tilesetId: 'world'),
        browserQuery: 'arbres',
        browserFolderId: 'outdoor',
        browserCollection: EditorPaletteAssetCollection.favorites,
        showIncompatible: true,
      );
      const contextB = EditorLayerPaletteContext(
        selectedTilesetId: 'details',
        browserQuery: 'lampes',
      );

      var session = service.remember(
        const EditorPaletteSession(),
        key: keyA,
        context: contextA,
      );
      session = service
          .activate(
            session,
            key: keyB,
            project: project,
            assignedTilesetId: 'details',
          )
          .session;
      session = service.remember(
        session,
        key: keyB,
        context: contextB,
      );

      final restored = service.activate(
        session,
        key: keyA,
        project: project,
        assignedTilesetId: 'world',
      );

      expect(restored.context, contextA);
      expect(restored.session.activeKey, keyA);
    });

    test('does not collide when two maps reuse the same layer id', () {
      const town = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const route = EditorPaletteContextKey(mapId: 'route', layerId: 'ground');
      var session = service.remember(
        const EditorPaletteSession(),
        key: town,
        context: const EditorLayerPaletteContext(
          selectedTilesetId: 'world',
          browserQuery: 'town',
        ),
      );
      session = service.remember(
        session,
        key: route,
        context: const EditorLayerPaletteContext(
          selectedTilesetId: 'details',
          browserQuery: 'route',
        ),
      );

      expect(session.contexts[town]?.browserQuery, 'town');
      expect(session.contexts[route]?.browserQuery, 'route');
    });

    test('sanitizes stale source, group, brush, folder and preferences', () {
      const key = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const missingLayerKey =
          EditorPaletteContextKey(mapId: 'town', layerId: 'removed');
      const missingMapKey =
          EditorPaletteContextKey(mapId: 'removed', layerId: 'ground');
      final stale = EditorPaletteSession(
        activeKey: key,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          key: const EditorLayerPaletteContext(
            selectedTilesetId: 'missing',
            selectedElementGroupId: 'missing-group',
            activeBrush: EditorPaletteBrushMemory.paletteEntry(
              entryId: 'missing-entry',
              tilesetId: 'missing',
            ),
            browserFolderId: 'missing-folder',
            projectElementCategoryId: 'missing-category',
          ),
          missingLayerKey:
              const EditorLayerPaletteContext(selectedTilesetId: 'world'),
          missingMapKey:
              const EditorLayerPaletteContext(selectedTilesetId: 'world'),
        },
        recentTilesetIds: <String>['missing', 'world'],
        favoriteTilesetIds: <String>['details', 'missing'],
      );

      final result = service.activate(
        stale,
        key: key,
        project: project,
        assignedTilesetId: 'world',
        activeMap: townMap,
      );

      expect(result.context.selectedTilesetId, 'world');
      expect(result.context.selectedElementGroupId, isNull);
      expect(
        result.context.activeBrush,
        const EditorPaletteBrushMemory.none(),
      );
      expect(result.context.browserFolderId, isNull);
      expect(result.context.projectElementCategoryId, isNull);
      expect(result.session.contexts.keys, <EditorPaletteContextKey>{key});
      expect(result.session.recentTilesetIds, <String>['world']);
      expect(result.session.favoriteTilesetIds, <String>['details']);
    });

    test('recents are LRU and favorites are bounded session preferences', () {
      var session = const EditorPaletteSession();
      for (final id in <String>['world', 'details', 'indoor', 'world']) {
        session = service.recordRecent(
          session,
          tilesetId: id,
          validTilesetIds: const <String>{
            'world',
            'details',
            'indoor',
            'other',
          },
        );
      }
      expect(
        session.recentTilesetIds,
        <String>['world', 'indoor', 'details'],
      );

      for (final id in <String>['world', 'details', 'indoor', 'other']) {
        session = service.toggleFavorite(
          session,
          tilesetId: id,
          validTilesetIds: const <String>{
            'world',
            'details',
            'indoor',
            'other',
          },
        );
      }
      expect(
        session.favoriteTilesetIds,
        <String>['details', 'indoor', 'other'],
      );
    });

    test('reset drops contexts, recents and favorites', () {
      const key = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      final populated = EditorPaletteSession(
        activeKey: key,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          key: const EditorLayerPaletteContext(selectedTilesetId: 'world'),
        },
        recentTilesetIds: <String>['world'],
        favoriteTilesetIds: <String>['world'],
      );

      expect(service.reset(populated), const EditorPaletteSession());
    });
  });
}

const project = ProjectManifest(
  name: 'Palette session',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Town',
      relativePath: 'maps/town.json',
    ),
    ProjectMapEntry(
      id: 'route',
      name: 'Route',
      relativePath: 'maps/route.json',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Outdoor'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'nature', name: 'Nature'),
      ],
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
    ),
    ProjectTilesetEntry(
      id: 'indoor',
      name: 'Indoor',
      relativePath: 'tilesets/indoor.png',
    ),
    ProjectTilesetEntry(
      id: 'other',
      name: 'Other',
      relativePath: 'tilesets/other.png',
    ),
  ],
);

const townMap = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[0],
    ),
  ],
);
``````

### 14.13 `packages/map_editor/test/map_palette_asset_browser_projector_test.dart`

SHA-256 : `94711f050d29697025f3bee2b0f140f1c0ff14a35e7662fb5495f5be3e83dbec`
Lignes : `477`

``````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_palette_asset_browser.dart';
import 'package:map_editor/src/application/services/map_palette_asset_browser_projector.dart';
import 'package:map_editor/src/application/use_cases/project_tileset_use_cases.dart';
import 'package:map_editor/src/features/editor/state/models/editor_palette_session.dart';

void main() {
  late MapPaletteAssetBrowserProjector projector;

  setUp(() {
    projector = MapPaletteAssetBrowserProjector(
      ResolveAssignableTilesetsForMapUseCase(),
    );
  });

  group('MapPaletteAssetBrowserProjector', () {
    test('shows global and ancestor-group sources but hides foreign scopes',
        () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
      );

      expect(
        result.items.map((item) => item.tileset.id),
        <String>[
          'world',
          'unclassified',
          'regional_details',
          'town_details',
        ],
      );
      expect(result.items.first.isAssigned, isTrue);
      expect(result.items.every((item) => item.isCompatible), isTrue);
      expect(
        result.items.map((item) => item.tileset.id),
        isNot(contains('foreign_characters')),
      );
    });

    test('reveals incompatible sources disabled with an explicit reason', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      final foreign = result.items.singleWhere(
        (item) => item.tileset.id == 'foreign_characters',
      );
      expect(foreign.isCompatible, isFalse);
      expect(foreign.disabledReason, contains('autre groupe'));
    });

    test('builds declared breadcrumbs and filters a folder subtree', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        folderId: 'outdoor',
        showIncompatible: true,
      );

      expect(
        result.folders.map((folder) => folder.path),
        <String>['Extérieur', 'Extérieur / Nature', 'Personnages'],
      );
      expect(
        result.items.map((item) => item.tileset.id),
        <String>['world', 'regional_details', 'town_details'],
      );
      expect(
        result.items
            .singleWhere((item) => item.tileset.id == 'regional_details')
            .folderPath,
        'Extérieur / Nature',
      );
    });

    test('offers a deterministic unclassified bucket', () {
      final projectWithOrphan = project.copyWith(
        tilesets: <ProjectTilesetEntry>[
          ...project.tilesets,
          const ProjectTilesetEntry(
            id: 'orphan',
            name: 'Dossier supprimé',
            relativePath: 'tilesets/orphan.png',
            folderId: 'missing_folder',
          ),
        ],
      );
      final result = projector.project(
        project: projectWithOrphan,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        folderId: kEditorPaletteUnclassifiedFolderId,
      );

      expect(result.hasUnclassifiedSources, isTrue);
      expect(
        result.items.map((item) => item.tileset.id),
        containsAll(<String>['unclassified', 'orphan']),
      );
      expect(result.items.every((item) => item.folderPath == 'Non classé'),
          isTrue);
    });

    test('searches declared labels and never infers from filenames', () {
      final elementMatch = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'lampadaire',
      );
      final folderMatch = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'nature',
      );
      final filenameOnly = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'secret_filename',
        showIncompatible: true,
      );

      expect(
        elementMatch.items.map((item) => item.tileset.id),
        <String>['regional_details'],
      );
      expect(
        folderMatch.items.map((item) => item.tileset.id),
        <String>['world', 'regional_details', 'town_details'],
      );
      expect(filenameOnly.items, isEmpty);
    });

    test('filters explicit element categories without filename heuristics', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        elementCategoryId: 'nature',
      );

      expect(
        result.items.map((item) => item.tileset.id),
        <String>['world'],
      );
    });

    test('returns typed empty states instead of throwing on missing context',
        () {
      final noProject = projector.project(
        project: null,
        map: null,
        activeLayerId: null,
      );
      final noMap = projector.project(
        project: project,
        map: null,
        activeLayerId: null,
      );
      final missingLayer = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'removed',
        showIncompatible: true,
      );

      expect(noProject.status, MapPaletteAssetBrowserStatus.noProject);
      expect(noProject.items, isEmpty);
      expect(noMap.status, MapPaletteAssetBrowserStatus.noMap);
      expect(noMap.items, isEmpty);
      expect(
        missingLayer.status,
        MapPaletteAssetBrowserStatus.activeLayerMissing,
      );
      expect(
        missingLayer.items.every(
          (item) =>
              item.assignmentState ==
              MapPaletteAssetAssignmentState.layerMissing,
        ),
        isTrue,
      );
    });

    test('surfaces a durable assigned source missing from the manifest', () {
      final missingSourceMap = mapWithLayer().copyWith(
        layers: const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            tilesetId: 'deleted_source',
            tiles: <int>[0],
          ),
        ],
      );

      final result = projector.project(
        project: project,
        map: missingSourceMap,
        activeLayerId: 'ground',
      );

      expect(
        result.status,
        MapPaletteAssetBrowserStatus.assignedSourceMissing,
      );
      expect(result.assignedTilesetId, 'deleted_source');
      expect(result.diagnostic, contains('deleted_source'));
      expect(result.items, isNotEmpty);
      expect(result.items.every((item) => item.canAssign), isTrue);

      final occupied = projector.project(
        project: project,
        map: missingSourceMap.copyWith(
          layers: const <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Sol',
              tilesetId: 'deleted_source',
              tiles: <int>[1],
            ),
          ],
        ),
        activeLayerId: 'ground',
        showIncompatible: true,
      );
      expect(occupied.diagnostic, contains('videz-le avant'));
      expect(occupied.items.every((item) => !item.canAssign), isTrue);
    });

    test('surfaces an invalid map scope as a diagnostic projection', () {
      final invalidProject = project.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'town',
            name: 'Ville',
            relativePath: 'maps/town.json',
            groupId: 'missing-group',
          ),
        ],
      );

      final result = projector.project(
        project: invalidProject,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      expect(result.status, MapPaletteAssetBrowserStatus.invalidMapScope);
      expect(result.diagnostic, contains('invalide'));
      expect(result.items, isNotEmpty);
    });

    test('projects recent order and favorites from session-only ids', () {
      final recent = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        collection: EditorPaletteAssetCollection.recent,
        recentTilesetIds: const <String>[
          'regional_details',
          'missing',
          'world',
        ],
      );
      final favorites = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        collection: EditorPaletteAssetCollection.favorites,
        favoriteTilesetIds: const <String>[
          'town_details',
          'missing',
          'world',
        ],
      );

      expect(
        recent.items.map((item) => item.tileset.id),
        <String>['regional_details', 'world'],
      );
      expect(
        favorites.items.map((item) => item.tileset.id),
        <String>['world', 'town_details'],
      );
      expect(favorites.items.every((item) => item.isFavorite), isTrue);
    });

    test('keeps the assigned source on a non-empty layer and disables others',
        () {
      final hidden = projector.project(
        project: project,
        map: mapWithLayer(occupied: true),
        activeLayerId: 'ground',
      );
      final revealed = projector.project(
        project: project,
        map: mapWithLayer(occupied: true),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      expect(
        hidden.items.map((item) => item.tileset.id),
        <String>['world'],
      );
      final other = revealed.items.singleWhere(
        (item) => item.tileset.id == 'regional_details',
      );
      expect(other.isCompatible, isFalse);
      expect(other.disabledReason, contains('contient déjà'));
      expect(
        revealed.items
            .singleWhere((item) => item.tileset.id == 'world')
            .canAssign,
        isFalse,
      );
    });

    test('explains that a non-tile layer cannot receive a tileset', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'collision',
        showIncompatible: true,
      );

      expect(result.items, isNotEmpty);
      expect(result.items.every((item) => !item.isCompatible), isTrue);
      expect(result.items.first.disabledReason, contains('calque de tuiles'));
      expect(result.activeLayerName, 'Collision');
    });
  });
}

const project = ProjectManifest(
  name: 'Browser',
  groups: <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'region',
      name: 'Région',
      type: MapGroupType.special,
    ),
    ProjectMapGroup(
      id: 'town_group',
      name: 'Villes',
      type: MapGroupType.city,
      parentGroupId: 'region',
    ),
    ProjectMapGroup(
      id: 'foreign',
      name: 'Étranger',
      type: MapGroupType.special,
    ),
  ],
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
      groupId: 'town_group',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
    ProjectTilesetFolder(
      id: 'nature_folder',
      name: 'Nature',
      parentFolderId: 'outdoor',
    ),
    ProjectTilesetFolder(id: 'characters', name: 'Personnages'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
    ProjectElementCategory(
      id: 'trees',
      name: 'Arbres',
      parentCategoryId: 'nature',
    ),
    ProjectElementCategory(id: 'decor', name: 'Décor'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
      sortOrder: 0,
    ),
    ProjectTilesetEntry(
      id: 'unclassified',
      name: 'Divers',
      relativePath: 'tilesets/misc.png',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'regional_details',
      name: 'Détails régionaux',
      relativePath: 'tilesets/secret_filename.png',
      scope: TilesetScope.group,
      groupId: 'region',
      folderId: 'nature_folder',
      sortOrder: 0,
    ),
    ProjectTilesetEntry(
      id: 'town_details',
      name: 'Détails urbains',
      relativePath: 'tilesets/town.png',
      scope: TilesetScope.group,
      groupId: 'town_group',
      folderId: 'nature_folder',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'foreign_characters',
      name: 'Personnages étrangers',
      relativePath: 'tilesets/characters.png',
      scope: TilesetScope.group,
      groupId: 'foreign',
      folderId: 'characters',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Grand arbre',
      tilesetId: 'world',
      categoryId: 'trees',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
        ),
      ],
      tags: <String>['forêt'],
    ),
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lampadaire',
      tilesetId: 'regional_details',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
        ),
      ],
    ),
  ],
);

MapData mapWithLayer({bool occupied = false}) => MapData(
      id: 'town',
      name: 'Ville',
      size: const GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Sol',
          tilesetId: 'world',
          tiles: <int>[occupied ? 1 : 0],
        ),
        const CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false],
        ),
      ],
    );
``````

### 14.14 `packages/map_editor/test/map_palette_asset_browser_test.dart`

SHA-256 : `c1ff9c55be29ed294431627ba504775f1d29fd1c831e6695b4b2695e171bc5de`
Lignes : `651`

``````dart
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'browser filters declared sources without dirtying the map',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'ground',
        );

      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: const Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  child: MapPaletteAssetBrowserLauncher(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(MapPaletteAssetBrowserKeys.openButton),
        findsOneWidget,
      );
      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
      await tester.pumpAndSettle();

      expect(find.byKey(MapPaletteAssetBrowserKeys.sheet), findsOneWidget);
      expect(find.byKey(MapPaletteAssetBrowserKeys.search), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'world map asset browser search',
      );
      expect(find.text('Monde'), findsWidgets);
      expect(find.text('Détails'), findsOneWidget);
      expect(find.text('Personnages privés'), findsNothing);
      expect(find.byKey(MapPaletteAssetBrowserKeys.folderRail), findsOneWidget);
      expect(find.byKey(MapPaletteAssetBrowserKeys.folderAll), findsOneWidget);
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.folder('root')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(MapPaletteAssetBrowserKeys.search),
        'Détails',
      );
      await tester.pump();

      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
        findsOneWidget,
      );
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('world')),
        findsNothing,
      );
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.favoriteButton('details')),
      );
      await tester.pump();
      expect(
        notifier.state.paletteSession.favoriteTilesetIds,
        <String>['details'],
      );

      await tester.enterText(
        find.byKey(MapPaletteAssetBrowserKeys.search),
        '',
      );
      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.collectionFavorites),
      );
      await tester.pump();
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
        findsOneWidget,
      );
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('world')),
        findsNothing,
      );

      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.collectionAll));
      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.showIncompatible),
      );
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('autre groupe'), findsOneWidget);
      final disabledReason = tester.widget<Text>(
        find.textContaining('Cette source appartient à un autre groupe'),
      );
      expect(disabledReason.maxLines, 2);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.folder('outdoor')),
      );
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsNothing,
      );
      expect(
        _activeBrowserContext(notifier).browserFolderId,
        'outdoor',
      );
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);

      await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.folderAll));
      await tester.pump();
      expect(
        find.byKey(
          MapPaletteAssetBrowserKeys.tilesetRow('private_characters'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
      );
      await tester.pump();
      expect(notifier.getSelectedTilesetEntry()?.id, 'details');
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(
        find.byKey(MapPaletteAssetBrowserKeys.assignButton('details')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(MapPaletteAssetBrowserKeys.sheet), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'world map asset browser launcher',
      );
    },
  );

  testWidgets('compact browser replaces the folder rail with a picker',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
    );

    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.folderPicker),
      findsOneWidget,
    );
    expect(find.byKey(MapPaletteAssetBrowserKeys.folderRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing assigned source stays visible as a recovery warning',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map.copyWith(
        layers: const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            tilesetId: 'deleted_source',
            tiles: <int>[0],
          ),
        ],
      ),
      activeLayerId: 'ground',
    );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );

    expect(find.text('Source introuvable : deleted_source'), findsOneWidget);
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Assignée introuvable : deleted_source'),
      findsOneWidget,
    );
    expect(find.textContaining('deleted_source'), findsWidgets);
    expect(find.textContaining('n’existe plus dans le projet'), findsOneWidget);
  });

  testWidgets('keyboard and semantics expose browser item states',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const contextKey = EditorPaletteContextKey(
      mapId: 'town',
      layerId: 'ground',
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
      paletteSession: EditorPaletteSession(
        activeKey: contextKey,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          contextKey: const EditorLayerPaletteContext(
            selectedTilesetId: 'details',
            showIncompatible: true,
          ),
        },
        recentTilesetIds: <String>['details'],
        favoriteTilesetIds: <String>['details'],
      ),
    );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();

    final assigned = tester.getSemantics(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetSemantics('world')),
    );
    expect(assigned.label, contains('Assignée au calque actif'));

    final selectedFavorite = tester.getSemantics(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetSemantics('details')),
    );
    expect(selectedFavorite.flagsCollection.isSelected, Tristate.isTrue);
    expect(selectedFavorite.label, contains('Favori de cette session'));

    final disabled = tester.getSemantics(
      find.byKey(
        MapPaletteAssetBrowserKeys.tilesetSemantics('private_characters'),
      ),
    );
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabled.label, contains('Désactivée'));
    expect(disabled.label, contains('autre groupe'));

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'world map asset browser search',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      container
          .read(editorNotifierProvider)
          .paletteSession
          .contexts[contextKey]
          ?.browserCollection,
      EditorPaletteAssetCollection.recent,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('embedded palette keeps the launcher without a selected image',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: MapData(
        id: 'town',
        name: 'Ville',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            tiles: <int>[0],
          ),
        ],
      ),
      activeLayerId: 'ground',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: TilesetPalettePanel(embedded: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.openButton),
      findsOneWidget,
    );
    expect(find.text('Aucun tileset sélectionné'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    keepAlive.close();
    await container.pump();
    await tester.pump();
  });

  testWidgets('embedded palette keeps the launcher after an image failure',
      (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        editorImageCacheProvider.overrideWith(
          (ref, projectRoot) {
            final cache = _FailingEditorImageCache(projectRoot);
            ref.onDispose(cache.dispose);
            return cache;
          },
        ),
      ],
    );
    container.listen(editorNotifierProvider, (_, __) {});
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: p.join(
        Directory.systemTemp.path,
        'pokemap_asset_browser_missing_project',
      ),
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'ground',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: TilesetPalettePanel(embedded: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(MapPaletteAssetBrowserKeys.openButton),
      findsOneWidget,
    );
    expect(find.text('Tileset image unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('explicit browser assignment is one local undoable mutation',
      (tester) async {
    final root = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_asset_browser_assignment_',
      );
      await FileProjectRepository().saveProject(
        project,
        p.join(directory.path, 'project.json'),
      );
      await FileMapRepository().saveMap(
        map,
        p.join(directory.path, 'maps', 'town.json'),
        projectDialogueContext: project,
      );
      return directory;
    });
    final projectRoot = root!;
    addTearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });
    final mapPath = p.join(projectRoot.path, 'maps', 'town.json');

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeMapPath: mapPath,
        activeLayerId: 'ground',
        savedMapSnapshot: map,
      );

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: MapPaletteAssetBrowserLauncher(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(MapPaletteAssetBrowserKeys.openButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(MapPaletteAssetBrowserKeys.tilesetRow('details')),
    );
    await tester.pump();
    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    await tester.tap(
      find.byKey(MapPaletteAssetBrowserKeys.assignButton('details')),
    );
    await tester.pump();

    expect(notifier.state.isDirty, isTrue);
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(
      (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
      'details',
    );
    expect(
      (await tester.runAsync(
        () => FileMapRepository().loadMap(mapPath),
      ))!
          .layers
          .first,
      isA<TileLayer>().having(
        (layer) => layer.tilesetId,
        'tilesetId',
        'world',
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    keepAlive.close();
    await container.pump();
    await tester.pump();
  });
}

const project = ProjectManifest(
  name: 'Browser widget',
  groups: <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'towns',
      name: 'Villes',
      type: MapGroupType.city,
    ),
    ProjectMapGroup(
      id: 'private',
      name: 'Privé',
      type: MapGroupType.special,
    ),
  ],
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
      groupId: 'towns',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
    ProjectTilesetFolder(id: 'root', name: 'Racine'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Détails',
      relativePath: 'tilesets/details.png',
      folderId: 'outdoor',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'private_characters',
      name: 'Personnages privés',
      relativePath: 'tilesets/private.png',
      scope: TilesetScope.group,
      groupId: 'private',
    ),
  ],
);

const map = MapData(
  id: 'town',
  name: 'Ville',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tilesetId: 'world',
      tiles: <int>[0],
    ),
  ],
);

class _FailingEditorImageCache extends EditorImageCache {
  _FailingEditorImageCache(String sessionKey) : super(sessionKey: sessionKey);

  @override
  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) {
    return Future<EditorImageLoadResult>.value(
      EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: path ?? '',
          message: 'Synthetic missing image.',
        ),
      ),
    );
  }
}

EditorLayerPaletteContext _activeBrowserContext(EditorNotifier notifier) {
  final activeMap = notifier.state.activeMap!;
  final key = EditorPaletteContextKey(
    mapId: activeMap.id,
    layerId: notifier.state.activeLayerId!,
  );
  return notifier.state.paletteSession.contexts[key]!;
}
``````
