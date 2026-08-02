# Evidence Pack — PERF-RM-07A Révisions sémantiques éditeur

**Lot :** `PERF-RM-07A`
**Finding :** `PERF-ED-02`
**Verdict proposé :** `DONE — CONFIRMED AND FIXED`
**HEAD de départ :** `main@818db8a14c001bd932116dfe16a5df276223ce9c`

## Résumé exécutif

Le hotspot a été confirmé : `EditorShellPage` observait la `MapData` complète même dans le workspace World Map, puis construisait l'index de recherche narratif dès que l'identité de la map changeait. Un changement d'une seule tuile salissait donc le shell global et pouvait relancer une projection narrative sans consommateur visible.

Le correctif conserve `EditorState` comme source de vérité unique. Il ajoute une projection Riverpod narrative ciblée, active cet abonnement seulement lorsqu'un workspace Narrative Studio consomme réellement ces données, et rend la construction de l'index narrative paresseuse. Le test RED observait `Element.dirty == true` après une édition de tuile ; le même test observe désormais `false`, tandis qu'un renommage de map rafraîchit toujours le titre du shell.

La mesure profile macOS open→paint→undo→save passe : 20 frames, frame p95 `2 589 µs`, aucune frame >33,3 ms, post-undo paint `24 998 µs`. La phase `collision-paint-100` dure `275 027 µs`, soit environ `2,75 ms` par échantillon en moyenne avec un pump toutes les dix mutations. Le lot respecte donc le gate d'action principale ≤50 ms et ferme l'invalidation narrative parasite.

## Confirmation du scope et non-objectifs

Scope livré :

- isoler les invalidations document, viewport et narrative ;
- empêcher une mutation tile-only de salir le shell global ;
- préserver les invalidations de métadonnées et de map switch ;
- rendre le profil macOS reproductible à une surface produit valide ;
- couvrir le comportement par tests RED→GREEN et mesure profile.

Non-objectifs conservés :

- aucun second système d'état ;
- aucune migration de schéma ou persistance ;
- aucune refonte globale de `EditorNotifier` ;
- aucune modification visuelle ou fonctionnelle du produit ;
- aucune nouvelle action auteur, JSONL ou MCP ;
- aucun fichier World Map hors lot stagé ou modifié par ce lot.

## Audit initial

### Contrats et fichiers inspectés

- `editor_shell_page.dart` : abonnement direct à `activeMap`, cache `_globalSearchIndexFor`, composition des workspaces.
- `editor_selectors.dart` : projections existantes shell/document/viewport/interaction déjà value-equal.
- `editor_state.dart` : source de vérité unique à préserver.
- `world_map_rebuild_isolation_test.dart` : compteurs de rebuild/repaint déjà focalisés.
- `editor_shell_page_smoke_test.dart` et son harness : preuve du shell réel.
- `editor_project_journey_test.dart` : mesure profile réelle open→paint→undo→save.
- roadmap et audit performance : gate `NOT CONFIRMED — NO CODE` ou implémentation ciblée si hotspot reproduit.

### Cause racine

`editorShellSnapshotProvider` produisait déjà un record inchangé lors d'une mutation de cellule. Cette isolation était neutralisée par :

```dart
final activeMap =
    ref.watch(editorNotifierProvider.select((s) => s.activeMap));
```

Le même `build` appelait ensuite `_globalSearchIndexFor` pour tout projet, même hors Narrative Studio. L'identité de `activeMap` faisait partie de la clé du cache. Le chemin exact était donc :

```text
tile edit -> new MapData -> EditorShellPage dirty
          -> _globalSearchIndexFor(activeMap identity changed)
          -> dependency index + global narrative search index
```

### État Git initial

Le démarrage de phase contenait six éléments hors phase, laissés intacts :

```text
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Pendant le lot, d'autres changements auteur/Smart Tile sont apparus dans le worktree. Ils sont considérés comme travail concurrent de l'utilisateur et sont explicitement exclus du staging.

## Implémentation et zones précises modifiées

### `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`

Ajout d'un read model d'invalidation, pas d'un état parallèle :

```dart
typedef EditorNarrativeProjectionSnapshot = ({
  String? projectRootPath,
  MapData? activeMap,
  bool projectIsDirty,
});

final editorNarrativeProjectionSnapshotProvider =
    Provider<EditorNarrativeProjectionSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select(
      (state) => (
        projectRootPath: state.projectRootPath,
        activeMap: state.activeMap,
        projectIsDirty: state.isDirty || state.isProjectDirty,
      ),
    ),
  );
});
```

Impact : les entrées narratives ont une frontière explicite et découvrable dans le même fichier que les projections document/viewport/interaction.

### `packages/map_editor/lib/src/ui/editor_shell_page.dart`

Zones changées : début de `_EditorShellPageState.build` et construction de `narrativeSearchIndex`.

```dart
final narrativeProjection = usesNarrativeStudioProductShell
    ? ref.watch(editorNarrativeProjectionSnapshotProvider)
    : null;
final editorState = ref.read(editorNotifierProvider);
final projectRootPath =
    narrativeProjection?.projectRootPath ?? editorState.projectRootPath;
final projectIsDirty = narrativeProjection?.projectIsDirty ?? false;
final activeMap = narrativeProjection?.activeMap ?? editorState.activeMap;
```

```dart
final narrativeSearchIndex =
    !usesNarrativeStudioProductShell || project == null
        ? null
        : _globalSearchIndexFor(...);
```

Impact : World Map laisse ses enfants ciblés observer la map, le shell ne suit plus chaque cellule, et l'index narrative n'est construit que pour son consommateur.

### `packages/map_editor/test/editor_shell_page_smoke_test.dart`

Zones changées :

- test RED→GREEN tile-only via `Element.dirty` ;
- garde positive de rafraîchissement du titre après renommage ;
- remplacement de trois `pumpAndSettle` par un pump borné pour un test d'expansion ;
- initialisation bornée de Tileset Studio, qui possède une preview continue.

Les deux ajustements de pump corrigent une faiblesse de test confirmée avant patch : attendre la quiescence globale est invalide lorsque le produit possède volontairement un ticker de preview.

### `packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart`

Ajout d'une caractérisation des domaines : pan/zoom notifie seulement la projection viewport ; une tuile notifie seulement le document map. Les six tests de repaint/rebuild existants restent verts.

### `packages/map_editor/integration_test/editor_project_journey_test.dart`

Ajout d'une surface fixe `1280×800` avant le montage de `MapEditorApp`, avec reset en teardown. Le premier essai profile avait reproduit trois exceptions `PokeMap desktop layouts require at least 800.0 × 600.0`; la mesure ne doit pas dépendre de la taille transitoire de la fenêtre hôte.

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-07a-editor-semantic-revisions.md`

Plan test-first dédié exigé par la roadmap, créé avant le premier patch production. Son contenu complet figure en annexe.

## Tests créés ou modifiés

- Positif : renommage de map rafraîchit le titre du shell.
- Négatif : une édition tile-only ne salit pas `EditorShellPage`.
- Garde-fou : viewport et document ne se notifient pas mutuellement.
- Non-régression : isolation animation/canvas/inspector, navigation, sauvegarde clavier, expansion Explorer et modes de workspace.
- Profil réel : open, map open, 100 peintures collision, undo, peinture post-undo et save.

## Commandes et résultats exacts

### Baseline et RED

```text
flutter test test/ui/world_map/world_map_rebuild_isolation_test.dart
=> exit 0 ; +6 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart test/ui/world_map/world_map_rebuild_isolation_test.dart
=> baseline interrompue après un pumpAndSettle timeout dans
   "preserves Project Explorer expansion across map tileset round trips"

flutter test test/editor_shell_page_smoke_test.dart --plain-name
  'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
=> exit 1 ; Expected false, Actual true
```

### GREEN et non-régression

```text
flutter test test/editor_shell_page_smoke_test.dart --plain-name
  'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
=> exit 0 ; +1 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --plain-name
  'EditorShellPage smoke map metadata changes still refresh the editor shell'
=> exit 0 ; +1 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --plain-name
  'EditorShellPage smoke preserves Project Explorer expansion across map tileset round trips'
=> exit 0 ; +1 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --plain-name
  'EditorShellPage smoke updates the workspace header for tileset mode'
=> exit 0 ; +1 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart
=> exit 0 ; +17 ; All tests passed!

flutter test test/ui/world_map/world_map_rebuild_isolation_test.dart
=> exit 0 ; +7 ; All tests passed!

flutter test test/editor_shell_page_smoke_test.dart \
  test/ui/world_map/world_map_rebuild_isolation_test.dart
=> exit 0 ; +24 ; All tests passed!

flutter analyze
=> exit 0 ; No issues found! (ran in 6.1s)
```

### Build et profil

Premier essai :

```text
flutter drive --profile -d macos ...
=> build macOS réussi, test exit 1 : viewport hôte inférieur à 800×600
```

Après correction du harness :

```text
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_project_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/phase3/rm07a_editor_project_journey.json
=> exit 0 ; Built Profile/PokeMap.app 66.4MB ; All tests passed
```

Mesures :

| Signal | Résultat |
|---|---:|
| project-open | 33 348 µs |
| map-open | 33 149 µs |
| collision-paint-100 | 275 027 µs |
| undo | 25 105 µs |
| post-undo-paint | 24 998 µs |
| save | 149 907 µs |
| frame p50 / p95 / p99 | 1 389 / 2 589 / 30 926 µs |
| frames >16,67 ms | 1/20 |
| frames >33,3 ms | 0/20 |

Le warning `Failed to foreground app; open returned 1` n'a pas empêché la connexion VM Service ni le succès du test. Les warnings Swift proviennent des plugins `audioplayers_darwin`/`video_player_avfoundation`, hors scope.

## Parité PokeMap MCP

Verdict `N/A` justifié. Ce lot modifie uniquement les abonnements et le coût de projection internes de l'éditeur. Il ne change ni donnée projet, ni sémantique auteur, ni commande, ni validation, ni import/export, ni rendu final. L'API canonical `map_authoring`, JSONL/CLI et le catalogue MCP restent inchangés ; les exécuter ne prouverait rien de plus sur cette isolation de rebuild.

## Passes séparées exigées par `codex_rule.md`

- **Passe Audit / Architecture — PASS :** cause racine tracée jusqu'aux deux abonnements globaux ; solution limitée aux read models Riverpod existants.
- **Passe Implémentation — PASS :** un provider de projection et un abonnement conditionnel ; aucune révision persistée ni second store.
- **Passe Tests — PASS :** RED observé, GREEN observé, 24 tests ciblés verts, garde positive et négative.
- **Passe Build / Validation — PASS WITH NOTE :** build/profile macOS vert après correction de la surface du harness ; warnings de plugins externes conservés.
- **Passe Critique finale — PASS :** aucun changement visuel, aucune donnée stale reproduite, aucun fichier concurrent stagé ; le cache narratif continue d'invalider sur projet/map/diagnostics lorsqu'il est visible.

La règle repo demandait des sub-agents ; la politique développeur active interdit d'en lancer sans demande explicite de l'utilisateur. Ces cinq passes ont donc été menées séparément par l'agent principal, comme le fallback prévu par `codex_rule.md`.

## État Git final avant commit

Fichiers du lot uniquement :

```text
 M packages/map_editor/integration_test/editor_project_journey_test.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-07a-editor-semantic-revisions.md
?? reports/performance/perf_rm_07a_editor_semantic_revisions.md
```

Les fichiers auteur/Smart Tile et les six éléments World Map/`__pycache__` concurrents restent hors staging. `git diff --check` ne produit aucune erreur.

## Limites, risques et auto-critique

- La mesure profile est une observation unique de 20 frames ; le gate CI reste observation-only et demandera davantage d'historique dans `PERF-RM-11`.
- Flutter profile n'expose pas le nombre de rebuilds ; la preuve de rebuild repose donc sur le test debug réel `Element.dirty`, tandis que la mesure profile prouve les frames.
- Le save à 149,907 ms n'est pas optimisé ici : c'est un coût I/O hors objectif de l'action principale `RM-07A` et déjà adressé par la Phase 2.
- L'optimisation ne remplace pas l'identité de cache narrative par un fingerprint complexe : l'abonnement n'existe simplement pas hors Narrative Studio, ce qui est plus petit et évite un nouveau calcul.
- Risque restant faible : un futur consommateur narratif rendu dans le shell World Map devra explicitement s'abonner à la projection narrative et ajouter un test de fraîcheur.

Prochaine étape recommandée, non implémentée dans ce lot : `PERF-RM-07B`, transmission des bornes visibles aux Smart Tiles et filtrage exact des projections d'ombres.

## Annexe — contenu complet du fichier créé

Le présent Evidence Pack s'exclut lui-même afin d'éviter une récursion infinie. Le seul autre fichier créé est reproduit intégralement ci-dessous.

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-07a-editor-semantic-revisions.md`

````markdown
# PERF-RM-07A Editor Semantic Revisions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent tile, viewport, and unrelated editor mutations from rebuilding the editor shell or its narrative projections while keeping map switches and narrative changes fresh.

**Architecture:** Keep `EditorState` as the single state system and use Riverpod semantic projections as the invalidation boundary. The shell will subscribe to the full active map only while a Narrative Studio product shell is visible; the World Map workspace keeps its existing focused providers. Narrative search construction becomes lazy, so a tile-only mutation cannot execute it.

**Tech Stack:** Dart 3, Flutter, Riverpod, `flutter_test`, existing PokeMap editor selectors and performance harnesses.

---

## Audit and constraints

- Baseline HEAD: `818db8a14c001bd932116dfe16a5df276223ce9c` on `main`, with unrelated pre-existing editor-tool files left unstaged.
- `EditorShellPage.build` currently watches `state.activeMap` unconditionally and calls `_globalSearchIndexFor` whenever the map identity changes.
- `editorShellSnapshotProvider` already emits a value-equal record for tile-only mutations; the unconditional full-map watch bypasses that isolation.
- `world_map_rebuild_isolation_test.dart` is green before the patch. The combined shell smoke baseline has an existing `pumpAndSettle` timeout and must be reported honestly rather than hidden.
- No new state-management system, persisted revision field, project schema, editor command, or MCP action is introduced.
- The local worktree is used because the user explicitly requested commits on the current phase and did not authorize branch/worktree creation; this is the narrow adaptation to the worktree recommendation in the planning skill.

### Task 1: Characterize shell invalidation

**Files:**

- Modify: `packages/map_editor/test/editor_shell_page_smoke_test.dart`

- [ ] **Step 1: Add the failing tile-isolation test**

Use the mounted `EditorShellPage` element's public `dirty` flag so the test observes real Riverpod invalidation without adding a test-only production callback:

```dart
testWidgets('tile-only map edits do not dirty the editor shell', (tester) async {
  final map = buildShellChromeMap(
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'tiles',
        tiles: List<int>.filled(20 * 15, 0, growable: false),
      ),
    ],
  );
  final container = await pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: '/tmp/perf_rm_07a',
      project: buildShellChromeProject(),
      activeMap: map,
      activeLayerId: 'ground',
    ),
    settleInitialFrame: false,
  );
  final shellElement = tester.element(find.byType(EditorShellPage));

  container.read(editorNotifierProvider.notifier).state =
      container.read(editorNotifierProvider).copyWith(
            activeMap: paintTileOnLayer(
              map,
              layerId: 'ground',
              pos: const GridPos(x: 1, y: 1),
              tileId: 1,
            ),
          );

  expect(shellElement.dirty, isFalse);
}
```

- [ ] **Step 2: Run RED and record the expected failure**

Run:

```bash
cd packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
```

Expected: `FAIL`, because the unconditional `activeMap` subscription marks `EditorShellPage` dirty.

- [ ] **Step 3: Add positive invalidation coverage**

Extend the test group with a map metadata/map-switch case that pumps once and verifies the refreshed title. Riverpod schedules derived-provider delivery, so rendered output is the stable positive assertion while `Element.dirty` remains the precise synchronous negative assertion for the unwanted direct subscription.

### Task 2: Split the narrative projection subscription

**Files:**

- Modify: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- Modify: `packages/map_editor/lib/src/ui/editor_shell_page.dart`

- [ ] **Step 1: Add one semantic narrative projection provider**

Add a record and provider beside the existing document/viewport/interaction projections:

```dart
typedef EditorNarrativeProjectionSnapshot = ({
  String? projectRootPath,
  MapData? activeMap,
  bool projectIsDirty,
});

final editorNarrativeProjectionSnapshotProvider =
    Provider<EditorNarrativeProjectionSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select(
      (state) => (
        projectRootPath: state.projectRootPath,
        activeMap: state.activeMap,
        projectIsDirty: state.isDirty || state.isProjectDirty,
      ),
    ),
  );
});
```

This provider is intentionally not a second source of truth; it is a read-only invalidation domain over `EditorState`.

- [ ] **Step 2: Make the shell subscribe only when narrative UI consumes the projection**

In `EditorShellPage.build`, determine `usesNarrativeStudioProductShell` from the already focused workspace/project inputs, then conditionally watch the narrative projection:

```dart
final narrativeProjection = usesNarrativeStudioProductShell
    ? ref.watch(editorNarrativeProjectionSnapshotProvider)
    : null;
final editorState = ref.read(editorNotifierProvider);
final projectRootPath =
    narrativeProjection?.projectRootPath ?? editorState.projectRootPath;
final activeMap = narrativeProjection?.activeMap ?? editorState.activeMap;
final projectIsDirty = narrativeProjection?.projectIsDirty ?? false;
```

Remove the unconditional `activeMap` and dirty-state watches. Keep the existing focused shell, project, error, status, and workspace listeners.

- [ ] **Step 3: Make narrative index construction lazy**

Replace the unconditional project-based construction with:

```dart
final narrativeSearchIndex = !usesNarrativeStudioProductShell || project == null
    ? null
    : _globalSearchIndexFor(
        project: project,
        activeMap: activeMap,
        diagnostics: narrativeDiagnostics,
      );
```

- [ ] **Step 4: Run GREEN**

Run the two focused tests by plain name. Expected: both tile isolation and metadata invalidation pass.

### Task 3: Prove behavior, profile, and report

**Files:**

- Modify: `packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart`
- Modify: `packages/map_editor/integration_test/editor_project_journey_test.dart`
- Create: `reports/performance/perf_rm_07a_editor_semantic_revisions.md`

- [ ] **Step 1: Add deterministic domain-isolation coverage**

Add provider listeners that prove viewport changes notify only the viewport projection, tile changes notify the map document projection, and neither notifies the narrative projection while the narrative projection has no listener in the World Map shell.

- [ ] **Step 2: Run focused and package checks**

Pin the integration fixture to `1280x800` before mounting `MapEditorApp`; the
production layout rejects smaller transient host-window sizes, and a profile
must measure the editor rather than an error frame.

```bash
cd packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke map metadata changes still refresh the editor shell'
flutter test test/ui/world_map/world_map_rebuild_isolation_test.dart
flutter analyze
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_project_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/phase3/rm07a_editor_project_journey.json
```

Run the broader smoke file separately and preserve any pre-existing timeout as an explicit limit.

- [ ] **Step 3: Assess PokeMap MCP parity**

Record `N/A`: this lot changes only editor subscription/performance behavior. It adds no authoring semantic, project data, validation, import/export, rendering result, or editor command; direct API/JSONL/MCP contracts remain unchanged.

- [ ] **Step 4: Write the Evidence Pack**

Follow `codex_rule.md`: include initial/final Git state, exact diff zones, every command/result, named Audit/Architecture, Implementation, Tests, Build/Validation, and Final Critique verdicts, plus the full content of this created plan. Exclude the Evidence Pack's own recursively self-referential content and state that exception explicitly.

- [ ] **Step 5: Commit only this lot**

```bash
git add \
  packages/map_editor/lib/src/features/editor/state/editor_selectors.dart \
  packages/map_editor/lib/src/ui/editor_shell_page.dart \
  packages/map_editor/test/editor_shell_page_smoke_test.dart \
  packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart \
  packages/map_editor/integration_test/editor_project_journey_test.dart \
  reports/performance/plans/2026-08-01-pokemap-perf-rm-07a-editor-semantic-revisions.md \
  reports/performance/perf_rm_07a_editor_semantic_revisions.md
git diff --cached --check
git commit -m 'perf(editor): isolate semantic shell revisions'
```

Do not stage unrelated World Map tool-activation changes and do not push yet.

## Self-review

- Spec coverage: profile decision, tile/narrative invalidation, map switch freshness, focused tests, evidence, and commit boundary are all mapped above.
- Placeholder scan: no `TBD`, deferred implementation, or unspecified test step remains.
- Type consistency: the single new record/provider name and its three fields are consistent across production and tests.
- Non-goals: no global Riverpod refactor, integer revision counters, persistence/schema change, UI redesign, or authoring API change.
````
