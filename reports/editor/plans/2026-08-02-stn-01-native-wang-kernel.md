# STN-01 Native Wang Kernel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner à `map_core` un catalogue v2 et un noyau Smart Tile natifs qui résolvent les textures simples et les signatures Wang multi-matières réelles, détectent les ambiguïtés et distinguent une cellule non assignée d'un vide intentionnel.

**Architecture:** `ProjectVersion.v5` remplace les quatre listes concurrentes d'un Smart Tile v4 par un `SmartTileField` discriminé selon la topologie. `ProjectSmartTileCatalog` passe au format 2 avec matériau central contraignable, profil de couverture persisté et politique de transformation typée. Les `semanticCells` portent occupation/gameplay ; les lattices Wang portent les contraintes visuelles partagées. Un `SmartTileCellContext` neutre sépare ensuite le matériau central des huit slots observés ; le résolveur reste pur, indépendant de l'ordre des règles et produit des diagnostics structurés réutilisés par la couverture et la readiness.

**Tech Stack:** Dart 3, `meta`, Freezed/json_serializable pour les modèles persistés, `package:test`.

**ADR:** `reports/editor/stn_00_native_smart_tiles_architecture_decision_2026-08-02.md`

---

## 1. Frontière du lot

### Inclus

- `ProjectVersion.v5` ;
- `ProjectSmartTileCatalog.currentFormatVersion = 2`, rejet ciblé du format 1 non vide et normalisation de l'empty v1 ;
- union `SmartTileField.cell/corner/edge/mixed` ;
- suppression des quatre listes libres dans le nouveau `SmartTileLayer` ;
- `SmartTileTopology.uniform` ;
- `SmartTileTemplateHint.simple` ;
- `SmartTileRule.centerMatch` obligatoire ;
- `SmartTileCoverageProfile` et scénarios exacts persistés ;
- `SmartTileTransformPolicy` persistée ;
- `PathSurfaceKind?` sur les matériaux ;
- observation exacte centre/arêtes/sommets ;
- correspondance `same`, `different`, `empty` et `material(id)` ;
- support d'une intention Wang sans matériau central lorsque des slots exacts sont présents ;
- détection d'égalité entre règles de même spécificité ;
- fallback explicite et visible ;
- couverture Simple et templates binaires existants ;
- diagnostics distincts `unassigned` et `intentional empty` ;
- mise à jour de tous les appels au résolveur ;
- round-trip et exports publics ;
- refus temporaire et explicite des mutations régionales Wang qui ne passent pas encore par le compilateur STN-05.

### Exclus

- transformation/rotation/flip des frames ;
- nouvelle UX, nouveau layout Flutter ou comportement Flame ; seules les gardes/messages transitoires dans les widgets existants sont autorisés ;
- mutation persistée du catalogue via `map_authoring` ;
- pinceau et compilateur de stroke World Map ;
- `SurfaceKit` ;
- moteur de recettes ;
- import TSX ;
- suppression de Terrain/Path legacy ; l'ancien Smart Tile v4 et le catalogue format 1 non vide sont néanmoins cassés volontairement dès ce lot.

### Invariants

1. Une map ou un manifeste utilisant le nouveau schéma est v5.
2. Un variant de champ incompatible avec la topologie est structurellement invalide.
3. `semanticCells` et lattices ont des rôles différents ; aucune n'est un cache implicite de l'autre.
4. Une topologie Wang lit les grilles Wang, jamais les cellules diagonales par approximation.
5. `same/different` compare un groupe de connexion au centre ; si le centre est absent, ces deux contraintes ne correspondent pas.
6. `material(id)` compare l'identifiant exact, même si deux matériaux partagent un groupe.
7. `empty` correspond à une absence ou à un matériau `isEmpty`, pas à n'importe quel matériau différent.
8. Le résultat ne dépend pas de l'ordre de `preset.rules`.
9. Le fallback ne masque jamais son utilisation.
10. Le lot ne modifie aucun pixel et ne contient aucun algorithme porté de Tiled.
11. `centerMatch` accepte seulement `any`, `empty` et `material(id)` ; `same/different` sont invalides au centre.
12. La couverture promise est persistée dans le preset et bornée à 4 096 scénarios explicites.
13. Une map possède au plus un `SmartTileLayer(usage: terrain)`.
14. Une transition v5 en présence de Terrain/Path legacy échoue atomiquement et ne change aucune version.
15. Un `SmartTileVisualPart` de footprint supérieur à 1×1 reste possédé par sa cellule résolue ; son footprint n'étend jamais l'occupation sémantique.

## 2. Structure de fichiers cible

### Fichiers créés

- `packages/map_core/lib/src/models/smart_tile_field.dart` — union sérialisée et topology-specific.
- `packages/map_core/lib/src/models/smart_tile_field.freezed.dart` — généré.
- `packages/map_core/lib/src/models/smart_tile_field.g.dart` — généré.
- `packages/map_core/lib/src/operations/smart_tile_cell_context.dart` — valeurs observées et constructeurs pour grille cellulaire.
- `packages/map_core/lib/src/operations/smart_tile_layer_context.dart` — projection d'un `SmartTileLayer` vers un contexte exact.
- `packages/map_core/lib/src/operations/smart_tile_layer_creation.dart` — plan pur map + manifeste, sans écriture partielle.
- `packages/map_core/lib/src/operations/smart_tile_coverage.dart` — cas requis et rapport de couverture fondé sur le résolveur.
- `packages/map_core/lib/src/operations/smart_tile_layer_readiness.dart` — diagnostic unassigned/intentional-empty/unresolved.
- `packages/map_core/test/smart_tiles/smart_tile_cell_context_test.dart`.
- `packages/map_core/test/smart_tiles/smart_tile_native_resolver_test.dart`.
- `packages/map_core/test/smart_tiles/smart_tile_native_coverage_test.dart`.
- `packages/map_core/test/smart_tiles/smart_tile_layer_readiness_test.dart`.
- `packages/map_core/test/smart_tiles/smart_tile_field_v5_test.dart`.
- `packages/map_core/test/smart_tiles/smart_tile_layer_creation_test.dart`.

### Fichiers modifiés

- `packages/map_core/lib/src/models/smart_tile.dart` — valeurs `uniform`/`simple` et résultat persistant inchangé hors enums.
- `packages/map_core/lib/src/models/enums.dart` — `ProjectVersion.v5`.
- `packages/map_core/lib/src/models/map_layer.dart` — `SmartTileLayer.field` au lieu des quatre listes.
- `packages/map_core/lib/src/models/map_data.dart` — règles de version v5.
- `packages/map_core/lib/src/models/project_manifest.dart` — règles de version v5.
- `packages/map_core/lib/src/operations/project_json_migrations.dart` — diagnostic structuré pour ancien Smart Tile v4 non pris en charge.
- `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart` — accès topology-specific et upgrade v5.
- `packages/map_core/lib/src/operations/map_resize.dart` — resize du variant actif seulement.
- `packages/map_core/lib/src/operations/legacy_smart_tile_migration.dart` — désactivation explicite jusqu'à la conversion atomique STN-06 ; aucune sortie v5 partielle.
- `packages/map_core/lib/src/operations/smart_tile_resolver.dart` — nouvelle entrée et sélection sans ordre implicite.
- `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart` — construction du contexte exact.
- `packages/map_core/lib/src/operations/smart_tile_templates.dart` — contrat Simple et switches exhaustifs.
- `packages/map_core/lib/src/operations/smart_tile_test_bench.dart` — scénarios basés sur le contexte.
- `packages/map_core/lib/src/operations/smart_tile_catalog_validation.dart` — couverture et ambiguïtés canoniques.
- `packages/map_core/lib/src/validation/validators.dart` — séparation structure/readiness seulement dans les branches Smart Tile.
- `packages/map_core/lib/map_core.dart` — exports publics.
- `packages/map_core/test/smart_tiles/smart_tile_resolver_test.dart` — migration vers la nouvelle entrée.
- `packages/map_core/test/smart_tiles/smart_tile_layer_visual_resolver_test.dart` — preuves lattice exactes.
- `packages/map_core/test/smart_tiles/smart_tile_template_signatures_test.dart` — Simple.
- `packages/map_core/test/smart_tiles/smart_tile_test_bench_test.dart` — nouvelle entrée.
- `packages/map_core/test/smart_tiles/smart_tile_publication_diagnostics_test.dart` — nouveaux statuts de couverture.
- `packages/map_core/test/smart_tiles/project_smart_tile_catalog_test.dart` — round-trip des nouveaux enum values.
- `packages/map_authoring/lib/src/domains/maps/autotile_actions.dart` — appel au nouveau contexte sans dupliquer le matching.
- `packages/map_authoring/lib/src/domains/maps/layer_actions.dart`.
- `packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart`.
- `packages/map_authoring/lib/src/domains/maps/map_region_query.dart`.
- `packages/map_authoring/lib/src/domains/maps/region_operations.dart`.
- `packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart`.
- `packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart`.
- `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_cell_inspector.dart`.
- `packages/map_editor/lib/src/features/editor/application/map_context_target_resolver.dart`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`.
- `packages/map_editor/lib/src/ui/canvas/map_visual_stack_migration_renderer.dart`.
- `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart`.
- `packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart`.
- `packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart`.
- `tools/pokemap_mcp/test/mutation_server.test.ts` — payloads/assertions v5 et rejets transitoires.
- tous les tests `map_authoring`, `map_editor` et `map_runtime` listés par l'inventaire exhaustif de Task 0.
- `packages/map_editor/test/smart_tiles_studio/smart_tile_map_editing_test.dart` — helper de test et round-trip v5.

### Fichiers générés

Régénérer uniquement `packages/map_core` :

- `packages/map_core/lib/src/models/smart_tile.freezed.dart` ;
- `packages/map_core/lib/src/models/smart_tile.g.dart`.
- `packages/map_core/lib/src/models/map_layer.freezed.dart` ;
- `packages/map_core/lib/src/models/map_layer.g.dart` ;
- les generated files `map_data`/`project_manifest` produits par l'ajout de `ProjectVersion.v5`.

Les fichiers générés ne sont jamais modifiés manuellement.

## 3. Task 0 — Préflight et protection du travail concurrent

**Files:** lecture seule du worktree.

- [ ] **Step 1: Capturer la branche, le HEAD et le statut**

Run:

```bash
git branch --show-current
git rev-parse HEAD
git status --short --untracked-files=all
```

Expected: enregistrer la sortie exacte dans le rapport du lot ; aucune attente de worktree propre.

- [ ] **Step 2: Inspecter les diffs concurrents des fichiers chevauchants**

Run:

```bash
git diff -- \
  packages/map_core/lib/src/models/smart_tile.dart \
  packages/map_core/lib/src/models/map_layer.dart \
  packages/map_core/lib/src/operations/smart_tile_resolver.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_operations.dart \
  packages/map_core/lib/src/operations/map_resize.dart \
  packages/map_core/lib/src/operations/smart_tile_templates.dart \
  packages/map_core/lib/src/operations/smart_tile_catalog_validation.dart \
  packages/map_core/lib/src/validation/validators.dart \
  packages/map_authoring/lib/src/domains/maps/autotile_actions.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart \
  packages/map_core/test/smart_tiles/smart_tile_layer_operations_test.dart \
  packages/map_editor/test/smart_tiles_studio/smart_tile_map_editing_test.dart
```

Après l'inventaire Step 3, croiser chaque chemin cible avec `git status --short --untracked-files=all` et lancer `git diff -- <chemin>` pour toute cible trackée modifiée qui n'était pas dans la liste initiale. Pour une cible untracked, lire son contenu complet avant édition. Conserver cette matrice `path → clean/pre-existing/new → décision` dans le rapport du lot. Si une zone nécessaire contient une modification concurrente non comprise, arrêter l'implémentation et demander sa réconciliation ; ne jamais écraser le diff.

- [ ] **Step 3: Inventorier les anciens champs, constructeurs, appels et switches exhaustifs**

Run:

```bash
rg -n 'materialCells|horizontalEdges|verticalEdges|corners|ProjectSmartTilePreset\(|ProjectVersion\.v4|SmartTileNeighborhood|resolveSmartTile\(|SmartTileTopology\.|SmartTileTemplateHint\.' \
  packages/map_core packages/map_authoring packages/map_editor packages/map_runtime tools/pokemap_mcp \
  -g '*.dart' -g '*.ts'
```

Expected: conserver la liste complète comme checklist de compilation, classée par package et par Task. Le relevé initial du 2 août 2026 compte 40 fichiers Dart référençant au moins un ancien champ et 25 fichiers construisant un `ProjectSmartTilePreset` ; ces nombres sont des repères à recalculer, pas des critères figés. Chaque occurrence de production et chaque fixture suivie reçoit une décision explicite `migrate`, `reject` ou `remove` dans le rapport du lot.

- [ ] **Step 4: Verrouiller les points de mutation existants**

Inventorier séparément `addSmartTileLayer`, `layer.add`, `region.paint`, `region.fill`, `region.erase`, `autotile.apply` et les actions live Smart Tile :

```bash
rg -n 'addSmartTileLayer|setSmartTileCellMaterial|applyToManifest|onManifestChanged|layer\.add|region\.(paint|fill|erase)|autotile\.apply|smart_tile\.layer\.' \
  packages/map_core packages/map_authoring packages/map_editor tools/pokemap_mcp \
  -g '*.dart' -g '*.ts'
```

Expected: l'ancien `addSmartTileLayer(MapData, ...)` n'est plus une entrée de création native sûre, car il ne voit pas le manifeste. Le noyau expose un plan pur map + manifeste décrit en Task 1 ; jusqu'à son enveloppe transactionnelle STN-03, `layer.add`, `autotile.apply` et l'éditeur refusent toute création Smart Tile v5 avec `smart_tile_native_authoring_requires_stn03`. Le Studio peut conserver un brouillon en mémoire, mais `applyToManifest`/`onManifestChanged` ne persiste aucun catalogue v2 et affiche `smart_tile_native_catalog_authoring_requires_stn03`. Ils ne passent jamais une ressource seule en v5. Jusqu'à STN-05, les opérations de région et `editor_notifier` refusent les topologies `wangEdge4`, `wangCorner4` et `wang8` avec le même diagnostic stable au lieu de modifier seulement `semanticCells`. Le sous-outil est désactivé avec cette explication si l'UI ne peut pas transporter le diagnostic.

## 4. Task 1 — Introduire v5 et le champ topologique unique

**Files:**

- Create: `packages/map_core/lib/src/models/smart_tile_field.dart`
- Create: `packages/map_core/lib/src/operations/smart_tile_layer_creation.dart`
- Modify: `packages/map_core/lib/src/models/smart_tile.dart`
- Modify: `packages/map_core/lib/src/models/enums.dart`
- Modify: `packages/map_core/lib/src/models/map_layer.dart`
- Modify: `packages/map_core/lib/src/models/map_data.dart`
- Modify: `packages/map_core/lib/src/models/project_manifest.dart`
- Modify: `packages/map_core/lib/src/operations/project_json_migrations.dart`
- Modify: `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart`
- Modify: `packages/map_core/lib/src/operations/map_resize.dart`
- Modify: `packages/map_core/lib/src/operations/legacy_smart_tile_migration.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_field_v5_test.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_layer_creation_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_layer_roundtrip_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_project_version_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_v4_compatibility_test.dart`
- Modify: `packages/map_core/test/smart_tiles/project_smart_tile_catalog_test.dart`
- Modify: `packages/map_core/test/validation/project_validator_test.dart`

- [ ] **Step 1: Écrire les tests rouges du schéma v5**

Ajouter quatre round-trips asymétriques :

```dart
test('v5 corner field persists semantic cells and only its corner lattice', () {
  const field = SmartTileField.corner(
    semanticCells: <int>[1, 2],
    corners: <int>[1, 2, 3, 4, 5, 6],
  );
  final map = _mapV5(
    layer: const SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'grass-dirt',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass', 'dirt'],
      field: field,
    ),
  );

  final json = map.toJson();
  final decoded = MapData.fromJson(json);

  expect(decoded, map);
  expect(json['version'], 'v5');
  expect(
    ((json['layers'] as List).single as Map<String, Object?>)['field'],
    <String, Object?>{
      'kind': 'corner',
      'semanticCells': <int>[1, 2],
      'corners': <int>[1, 2, 3, 4, 5, 6],
    },
  );
  expect(json.toString(), isNot(contains('horizontalEdges')));
  expect(json.toString(), isNot(contains('verticalEdges')));
});
```

Ajouter les mêmes vérifications pour `cell`, `edge` et `mixed`, avec des valeurs distinctes dans chaque grille.

Ajouter aussi :

- un catalogue format 2 qui round-trip avec `centerMatch`, couverture, transform policy et `PathSurfaceKind` ;
- un catalogue format 1 ou sans `formatVersion`, non vide, qui échoue avec `smart_tile_catalog_v1_unsupported`, puis les variantes v1/absente strictement vides qui deviennent exactement `ProjectSmartTileCatalog.empty()` format 2 ;
- un catalogue format 3 qui échoue avec `smart_tile_catalog_version_unsupported` ;
- un manifeste avec catalogue natif format 2 qui exige v5 ;
- un manifeste v5 avec chacun de `terrainCategories`, `pathCategories`, `terrainPresets`, `pathPresets` et `pathPatternPresets` non vide qui échoue sans manifeste partiellement décodé ;
- une map v5 avec `TerrainLayer` ou `PathLayer` qui échoue sans map partiellement décodée ;
- une map v5 conserve `visualStack` et ses invariants actuels, tandis que v1/v2 restent refusés comme aujourd'hui ;
- une map v4 contenant `runtimeType: smart_tile` et les quatre anciennes listes qui échoue avec un code/message mentionnant `smart_tile_v4_unsupported` ;
- une map v4 sans variant supprimé qui reste lisible si les règles actuelles l'autorisent ;
- `uniform/cardinal4/blob8 + cell` valide ;
- chaque couple topologie/field incompatible invalide ;
- resize qui ne crée aucune grille inactive ;
- création de field depuis chaque topologie, sans fallback silencieux vers `cell` ;
- refus atomique d'ajouter un Smart Tile natif dans une map/manifeste contenant du legacy ;
- succès du plan pur qui projette map cible et manifeste ensemble en v5 sans modifier les entrées ;
- snapshot à deux maps dont la non-cible contient un Path/Terrain legacy : échec sans projection ;
- terrain Wang `complete` 2×2 initialise cellules et lattices intérieures/périmètre pour `empty` et `connected` ;
- rejet transitoire `smart_tile_native_authoring_requires_stn03` de `layer.add`/éditeur/MCP, avec zéro `AuthoringResourceChange` ;
- brouillon Studio autorisé en mémoire mais publication/persistance refusée avec `smart_tile_native_catalog_authoring_requires_stn03` et aucun callback manifeste ;
- refus d'un second fournisseur `SmartTileUsage.terrain` ;
- une visual part 2×3 round-trip sans créer six cellules d'occupation et reste résolue une seule fois depuis sa cellule owner ;
- `legacy_smart_tile_migration` avec preset/path pattern manquant qui rend un échec sans map, manifeste ni version projetée.

- [ ] **Step 2: Lancer le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_field_v5_test.dart \
  test/smart_tiles/smart_tile_layer_creation_test.dart \
  test/smart_tiles/smart_tile_layer_roundtrip_test.dart \
  test/smart_tiles/smart_tile_project_version_test.dart \
  test/smart_tiles/smart_tile_v4_compatibility_test.dart
```

Expected: FAIL à la compilation pour `ProjectVersion.v5`, `SmartTileField` et `field`.

- [ ] **Step 3: Définir l'union sérialisée**

Créer :

```dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'smart_tile_field.freezed.dart';
part 'smart_tile_field.g.dart';

@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class SmartTileField with _$SmartTileField {
  const factory SmartTileField.cell({
    @Default(<int>[]) List<int> semanticCells,
  }) = SmartTileCellField;

  const factory SmartTileField.corner({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> corners,
  }) = SmartTileCornerField;

  const factory SmartTileField.edge({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> horizontalEdges,
    @Default(<int>[]) List<int> verticalEdges,
  }) = SmartTileEdgeField;

  const factory SmartTileField.mixed({
    @Default(<int>[]) List<int> semanticCells,
    @Default(<int>[]) List<int> horizontalEdges,
    @Default(<int>[]) List<int> verticalEdges,
    @Default(<int>[]) List<int> corners,
  }) = SmartTileMixedField;

  factory SmartTileField.fromJson(Map<String, dynamic> json) =>
      _$SmartTileFieldFromJson(json);
}
```

Ajouter `ProjectVersion.v5` sans changer les valeurs JSON antérieures.

Ajouter également dans `smart_tile.dart` :

```dart
enum SmartTileCoveragePolicy {
  @JsonValue('complete')
  complete,
  @JsonValue('sparse')
  sparse,
}
```

Ajouter les contrats persistés suivants dans le même fichier :

```dart
enum SmartTileCoverageMode {
  @JsonValue('template')
  template,
  @JsonValue('explicit')
  explicit,
  @JsonValue('template_and_explicit')
  templateAndExplicit,
}

@freezed
class SmartTileExactSignature with _$SmartTileExactSignature {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileExactSignature({
    String? northEdge,
    String? northEastCorner,
    String? eastEdge,
    String? southEastCorner,
    String? southEdge,
    String? southWestCorner,
    String? westEdge,
    String? northWestCorner,
  }) = _SmartTileExactSignature;

  factory SmartTileExactSignature.fromJson(Map<String, dynamic> json) =>
      _$SmartTileExactSignatureFromJson(json);
}

@freezed
class SmartTileCoverageScenario with _$SmartTileCoverageScenario {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCoverageScenario({
    required String id,
    String? centerMaterialId,
    @Default(SmartTileExactSignature()) SmartTileExactSignature signature,
  }) = _SmartTileCoverageScenario;

  factory SmartTileCoverageScenario.fromJson(Map<String, dynamic> json) =>
      _$SmartTileCoverageScenarioFromJson(json);
}

@freezed
class SmartTileCoverageProfile with _$SmartTileCoverageProfile {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCoverageProfile({
    required SmartTileCoverageMode mode,
    @Default(<SmartTileCoverageScenario>[])
    List<SmartTileCoverageScenario> requiredScenarios,
    @Default(false) bool allowFallback,
  }) = _SmartTileCoverageProfile;

  factory SmartTileCoverageProfile.fromJson(Map<String, dynamic> json) =>
      _$SmartTileCoverageProfileFromJson(json);
}

@freezed
class SmartTileTransformPolicy with _$SmartTileTransformPolicy {
  const factory SmartTileTransformPolicy({
    @Default(false) bool allowHFlip,
    @Default(false) bool allowVFlip,
    @Default(false) bool allowQuarterTurns,
    @Default(true) bool preferUntransformed,
  }) = _SmartTileTransformPolicy;

  factory SmartTileTransformPolicy.fromJson(Map<String, dynamic> json) =>
      _$SmartTileTransformPolicyFromJson(json);
}
```

Dans un scénario exact, `null` signifie absence exacte et jamais wildcard. Le validateur impose un ID non vide/unique, au plus 4 096 scénarios et uniquement les slots actifs de la topologie.

Faire évoluer les contrats existants :

```dart
const factory SmartTileRule({
  required String id,
  required SmartTileSlotMatch centerMatch,
  @Default(SmartTileSignature()) SmartTileSignature signature,
  @Default(<SmartTileCandidate>[]) List<SmartTileCandidate> candidates,
}) = _SmartTileRule;

const factory ProjectSmartTileMaterial({
  // champs existants inchangés
  TerrainType? terrainType,
  PathSurfaceKind? pathSurfaceKind,
  // champs existants inchangés
}) = _ProjectSmartTileMaterial;
```

`ProjectSmartTilePreset` rend `coveragePolicy`, `coverageProfile` et `transformPolicy` obligatoires. Tous les constructeurs natifs du lot fournissent ces valeurs. Le validateur refuse `centerMatch.same/different` et les références de matériaux inconnues. Un footprint visuel supérieur à 1×1 est autorisé mais ne modifie jamais `semanticCells`. Fixer `ProjectSmartTileCatalog.currentFormatVersion = 2`.

- [ ] **Step 4: Remplacer les quatre listes du layer**

Le nouveau factory devient :

```dart
@FreezedUnionValue('smart_tile')
@JsonSerializable(explicitToJson: true)
const factory MapLayer.smartTile({
  required String id,
  required String name,
  @Default(true) bool isVisible,
  @Default(1.0) double opacity,
  required String presetId,
  required SmartTileUsage usage,
  @Default(<String>['']) List<String> materialPalette,
  required SmartTileField field,
  @Default(0) int layerSeed,
  @Default(<String, String>{}) Map<String, String> properties,
}) = SmartTileLayer;
```

Ne pas ajouter de getters qui recréent quatre listes vides et permettraient aux consommateurs d'ignorer le variant.

- [ ] **Step 5: Verrouiller la version et le rejet v4 ciblé**

Règles :

```text
new native catalog/layer write → v5
catalog format 1 non-empty → smart_tile_catalog_v1_unsupported
catalog format 1 empty → canonical empty format 2
v5 + TerrainLayer/PathLayer or legacy manifest categories/presets → invalid
v5 SmartTileLayer → field required
v5 + visualStack → same structural rules as v4
v4 + old smart_tile four-list payload → structured unsupported error
v4 without removed payload → existing domain rules continue to apply
```

Les diagnostics incluent le chemin JSON, la version, le variant et un code stable. Ils ne construisent jamais une couche partielle. Les opérations de création/publication vérifient le projet projeté avant de changer map, manifeste ou version ; le rejet legacy restitue exactement l'état initial.

- [ ] **Step 6: Mettre à jour opérations, resize et migration interne**

Créer des helpers exhaustifs dans `smart_tile_layer_operations.dart` :

```dart
List<int> smartTileSemanticCells(SmartTileLayer layer);
List<int> smartTileHorizontalEdges(SmartTileLayer layer);
List<int> smartTileVerticalEdges(SmartTileLayer layer);
List<int> smartTileCorners(SmartTileLayer layer);
```

Les helpers de lattice retournent une liste vide seulement lorsque la topologie/field ne possède pas ce domaine. Toute mutation utilise `field.map(...)` et reconstruit le même variant ; elle ne convertit jamais implicitement `corner` en `mixed`.

Le resize applique :

```text
semanticCells      → width × height
corner.corners     → (width + 1) × (height + 1)
edge.horizontal    → width × (height + 1)
edge.vertical      → (width + 1) × height
mixed              → les trois lattices
```

Créer une opération pure `planNativeSmartTileLayerCreation` qui reçoit le snapshot de toutes les maps, `ProjectManifest` et le `ProjectSmartTilePreset` canonique, vérifie legacy/usage/topologie, puis retourne soit un échec sans mutation, soit une projection contenant map cible et manifeste v5 :

```dart
sealed class SmartTileLayerCreationResult {
  const SmartTileLayerCreationResult();
}

final class SmartTileLayerCreationSuccess
    extends SmartTileLayerCreationResult {
  const SmartTileLayerCreationSuccess({
    required this.map,
    required this.manifest,
    required this.layerId,
  });

  final MapData map;
  final ProjectManifest manifest;
  final String layerId;
}

final class SmartTileLayerCreationFailure
    extends SmartTileLayerCreationResult {
  const SmartTileLayerCreationFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

SmartTileLayerCreationResult planNativeSmartTileLayerCreation({
  required Iterable<MapData> projectMaps,
  required String targetMapId,
  required ProjectManifest manifest,
  required ProjectSmartTilePreset preset,
  required String layerId,
  required String layerName,
});
```

Le plan copie les entrées, ne les mute jamais et valide le manifeste ainsi que toutes les maps du snapshot avant de sélectionner `targetMapId`. Une map non cible contenant Terrain/Path fait échouer la transition entière. Il construit une palette `['', ...allowedMaterialIds]` dédupliquée dans l'ordre du preset et initialise les usages `sparse` à `0`.

Pour un terrain `complete`, toutes les `semanticCells` prennent l'index de `defaultMaterialId`. Les lattices Wang sont initialisées atomiquement : chaque arête/sommet intérieur prend le même index ; un slot du périmètre prend cet index avec `boundaryPolicy.connected` et `0` avec `boundaryPolicy.empty`. Les tests couvrent edge, corner et mixed sur une map 2×2 avec les deux boundary policies, puis exigent une readiness résolue ; aucune couche Wang complète ne naît avec des lattices incohérentes.

```text
uniform/cardinal4/blob8 → SmartTileField.cell
wangEdge4              → SmartTileField.edge
wangCorner4            → SmartTileField.corner
wang8                  → SmartTileField.mixed
```

La création refuse un second `usage: terrain`. Aucune action authoring ne persiste encore cette projection dans STN-01 : les chemins existants répondent `smart_tile_native_authoring_requires_stn03`. STN-03 enveloppe la projection dans un unique `AuthoringChangeSet` map + manifeste. `legacy_smart_tile_migration.dart` ne produit plus rien dans STN-01 : il retourne un diagnostic `legacy_smart_tile_conversion_deferred` jusqu'à la conversion all-or-nothing de STN-06.

`region.paint/fill/erase` peut continuer pour les fields `cell` en reconstruisant le variant actif. Pour `edge`, `corner` et `mixed`, l'action retourne `smart_tile_wang_paint_compiler_required` jusqu'à STN-05. `normalize` et `merge` sont migrés maintenant pour opérer exhaustivement sur le field actif ; ils ne recréent jamais les anciennes listes.

- [ ] **Step 7: Régénérer puis faire passer les tests**

Run:

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/smart_tiles/smart_tile_field_v5_test.dart \
  test/smart_tiles/smart_tile_layer_creation_test.dart \
  test/smart_tiles/smart_tile_layer_roundtrip_test.dart \
  test/smart_tiles/smart_tile_project_version_test.dart \
  test/smart_tiles/smart_tile_v4_compatibility_test.dart \
  test/smart_tiles/smart_tile_layer_operations_test.dart
```

Expected: PASS.

## 5. Task 2 — Ajouter le contrat Simple

**Files:**

- Modify: `packages/map_core/lib/src/models/smart_tile.dart`
- Modify: `packages/map_core/lib/src/operations/smart_tile_templates.dart`
- Test: `packages/map_core/test/smart_tiles/smart_tile_template_signatures_test.dart`
- Test: `packages/map_core/test/smart_tiles/project_smart_tile_catalog_test.dart`

- [ ] **Step 1: Écrire les tests rouges Simple**

Ajouter les assertions suivantes :

```dart
test('Simple has one canonical case and uses uniform topology', () {
  expect(
    smartTileCanonicalMasks(SmartTileTemplateHint.simple),
    const <int>[0],
  );
  expect(
    smartTileTopologyForTemplate(SmartTileTemplateHint.simple),
    SmartTileTopology.uniform,
  );
  expect(
    smartTileSignatureForMask(0, topology: SmartTileTopology.uniform),
    const SmartTileSignature(),
  );
});

test('Simple topology and template round-trip with stable JSON values', () {
  final preset = _preset(
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
  );

  final decoded = ProjectSmartTilePreset.fromJson(preset.toJson());

  expect(decoded, preset);
  expect(preset.toJson()['topology'], 'uniform');
  expect(preset.toJson()['templateHint'], 'simple');
});
```

Ajouter un preset Simple avec `allowedMaterialIds: ['grass', 'dirt']` : le template doit générer deux règles, chacune avec `centerMatch.material(...)`, et les deux matériaux doivent résoudre vers leurs propres candidats. Ajouter aussi le round-trip de `SmartTileTransformPolicy` et d'une visual part 2×3 possédée par une seule cellule.

- [ ] **Step 2: Lancer le test et constater le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_template_signatures_test.dart \
  test/smart_tiles/project_smart_tile_catalog_test.dart
```

Expected: FAIL à la compilation parce que `simple` et `uniform` n'existent pas.

- [ ] **Step 3: Ajouter les valeurs sérialisées**

Ajouter exactement :

```dart
enum SmartTileTopology {
  @JsonValue('uniform')
  uniform,
  @JsonValue('cardinal_4')
  cardinal4,
  @JsonValue('blob_8')
  blob8,
  @JsonValue('wang_edge_4')
  wangEdge4,
  @JsonValue('wang_corner_4')
  wangCorner4,
  @JsonValue('wang_8')
  wang8,
}

enum SmartTileTemplateHint {
  @JsonValue('simple')
  simple,
  @JsonValue('legacy_20')
  legacy20,
  @JsonValue('edge_16')
  edge16,
  @JsonValue('corner_16')
  corner16,
  @JsonValue('corner_12')
  corner12,
  @JsonValue('blob_47')
  blob47,
  @JsonValue('mixed_256')
  mixed256,
  @JsonValue('free')
  free,
}
```

Mettre à jour tous les switches de `smart_tile_templates.dart` :

```dart
SmartTileTemplateHint.simple => const <int>[0],
```

```dart
SmartTileTemplateHint.simple => SmartTileTopology.uniform,
```

```dart
SmartTileTopology.uniform => const SmartTileSignature(),
```

`smartTileMaskForSignature` retourne `0` pour `uniform` seulement si tous les slots sont `any` ; sinon il retourne `null`.

La génération Simple itère les `allowedMaterialIds` non vides, triés par identifiant stable, et produit une règle explicite par matériau central. Elle ne produit pas une règle universelle implicite. Un matériau marqué `isEmpty` n'entre que dans un scénario/règle explicitement demandé.

- [ ] **Step 4: Régénérer le package**

Run:

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
```

Expected: exit 0 ; seuls les generated files dépendant du modèle changent.

- [ ] **Step 5: Rejouer les tests ciblés**

Run:

```bash
dart test test/smart_tiles/smart_tile_template_signatures_test.dart \
  test/smart_tiles/project_smart_tile_catalog_test.dart
```

Expected: PASS.

## 6. Task 3 — Créer le contexte observé

**Files:**

- Create: `packages/map_core/lib/src/operations/smart_tile_cell_context.dart`
- Create: `packages/map_core/lib/src/operations/smart_tile_layer_context.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_cell_context_test.dart`
- Test: `packages/map_core/test/smart_tiles/smart_tile_layer_visual_resolver_test.dart`

- [ ] **Step 1: Écrire les tests rouges de structure et d'ordre**

Le test utilise des valeurs toutes distinctes afin qu'une permutation ne puisse pas passer :

```dart
test('mixed signature exposes Tiled-compatible ordered slots', () {
  const signature = SmartTileObservedSignature(
    northEdge: SmartTileObservedSlot.inside(materialId: 'n'),
    northEastCorner: SmartTileObservedSlot.inside(materialId: 'ne'),
    eastEdge: SmartTileObservedSlot.inside(materialId: 'e'),
    southEastCorner: SmartTileObservedSlot.inside(materialId: 'se'),
    southEdge: SmartTileObservedSlot.inside(materialId: 's'),
    southWestCorner: SmartTileObservedSlot.inside(materialId: 'sw'),
    westEdge: SmartTileObservedSlot.inside(materialId: 'w'),
    northWestCorner: SmartTileObservedSlot.inside(materialId: 'nw'),
  );

  expect(
    signature
        .activeSlots(SmartTileTopology.wang8)
        .map((slot) => slot.materialId),
    <String?>['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
  );
});
```

Ajouter un test lattice sur une map 1×1 avec huit valeurs distinctes et vérifier chaque champ nommé du contexte produit.

- [ ] **Step 2: Lancer le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_cell_context_test.dart \
  test/smart_tiles/smart_tile_layer_visual_resolver_test.dart
```

Expected: FAIL à la compilation, nouveaux types absents.

- [ ] **Step 3: Implémenter les valeurs immuables**

Le fichier `smart_tile_cell_context.dart` expose :

```dart
@immutable
final class SmartTileObservedSlot {
  const SmartTileObservedSlot.inside({this.materialId}) : isInsideMap = true;
  const SmartTileObservedSlot.outside()
      : isInsideMap = false,
        materialId = null;

  final bool isInsideMap;
  final String? materialId;
}

@immutable
final class SmartTileObservedSignature {
  const SmartTileObservedSignature({
    this.northEdge = const SmartTileObservedSlot.outside(),
    this.northEastCorner = const SmartTileObservedSlot.outside(),
    this.eastEdge = const SmartTileObservedSlot.outside(),
    this.southEastCorner = const SmartTileObservedSlot.outside(),
    this.southEdge = const SmartTileObservedSlot.outside(),
    this.southWestCorner = const SmartTileObservedSlot.outside(),
    this.westEdge = const SmartTileObservedSlot.outside(),
    this.northWestCorner = const SmartTileObservedSlot.outside(),
  });

  final SmartTileObservedSlot northEdge;
  final SmartTileObservedSlot northEastCorner;
  final SmartTileObservedSlot eastEdge;
  final SmartTileObservedSlot southEastCorner;
  final SmartTileObservedSlot southEdge;
  final SmartTileObservedSlot southWestCorner;
  final SmartTileObservedSlot westEdge;
  final SmartTileObservedSlot northWestCorner;

  List<SmartTileObservedSlot> activeSlots(SmartTileTopology topology) {
    return switch (topology) {
      SmartTileTopology.uniform => const <SmartTileObservedSlot>[],
      SmartTileTopology.cardinal4 || SmartTileTopology.wangEdge4 =>
        <SmartTileObservedSlot>[
          northEdge,
          eastEdge,
          southEdge,
          westEdge,
        ],
      SmartTileTopology.blob8 || SmartTileTopology.wang8 =>
        <SmartTileObservedSlot>[
          northEdge,
          northEastCorner,
          eastEdge,
          southEastCorner,
          southEdge,
          southWestCorner,
          westEdge,
          northWestCorner,
        ],
      SmartTileTopology.wangCorner4 => <SmartTileObservedSlot>[
          northEastCorner,
          southEastCorner,
          southWestCorner,
          northWestCorner,
        ],
    };
  }
}

@immutable
final class SmartTileCellContext {
  const SmartTileCellContext({
    this.centerMaterialId,
    this.observed = const SmartTileObservedSignature(),
  });

  factory SmartTileCellContext.fromCellGrid({
    required int width,
    required int height,
    required int x,
    required int y,
    required String? Function(int x, int y) materialAt,
  });

  final String? centerMaterialId;
  final SmartTileObservedSignature observed;
}
```

`activeSlots` utilise :

```text
uniform      → []
cardinal4    → [N, E, S, W]
wangEdge4    → [N, E, S, W]
wangCorner4  → [NE, SE, SW, NW]
blob8/wang8  → [N, NE, E, SE, S, SW, W, NW]
```

`fromCellGrid` conserve `outside()` pour une coordonnée hors map et `inside(materialId: null)` pour une cellule vide située dans la map.

- [ ] **Step 4: Implémenter la projection de couche**

Le fichier `smart_tile_layer_context.dart` expose :

```dart
SmartTileCellContext smartTileCellContextForLayerCell({
  required SmartTileLayer layer,
  required MapData map,
  required ProjectSmartTilePreset preset,
  required int x,
  required int y,
});
```

Règles de projection :

- `uniform`, `cardinal4`, `blob8` : exiger `SmartTileCellField`, lire `semanticCells` et utiliser `fromCellGrid` ;
- `wangEdge4` : exiger `SmartTileEdgeField`, centre dans `semanticCells`, côtés dans ses deux lattices ;
- `wangCorner4` : exiger `SmartTileCornerField`, centre dans `semanticCells`, sommets dans sa lattice ;
- `wang8` : exiger `SmartTileMixedField`, centre, quatre côtés et quatre sommets dans ses grilles ;
- une entrée lattice située sur la frontière est `inside`, même si sa matière est absente ;
- une coordonnée de cellule hors map lance `RangeError`.

- [ ] **Step 5: Exporter et faire passer les tests**

Run:

```bash
cd packages/map_core
dart format lib/src/operations/smart_tile_cell_context.dart \
  lib/src/operations/smart_tile_layer_context.dart \
  test/smart_tiles/smart_tile_cell_context_test.dart \
  test/smart_tiles/smart_tile_layer_visual_resolver_test.dart
dart test test/smart_tiles/smart_tile_cell_context_test.dart \
  test/smart_tiles/smart_tile_layer_visual_resolver_test.dart
```

Expected: PASS.

## 7. Task 4 — Remplacer le matching du résolveur

**Files:**

- Modify: `packages/map_core/lib/src/operations/smart_tile_resolver.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_native_resolver_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_resolver_test.dart`

- [ ] **Step 1: Écrire les tests rouges de comportement**

Ajouter les tests de comportement suivants :

```dart
test('uniform resolves variants without reading neighbors', () {
  final result = resolveSmartTile(
    preset: _uniformPreset(),
    materials: _materials,
    context: const SmartTileCellContext(centerMaterialId: 'grass'),
    x: 2,
    y: 3,
  );

  expect(result.status, SmartTileResolutionStatus.resolved);
  expect(result.ruleId, 'uniform');
  expect(result.candidate, isNotNull);
});

test('uniform rules distinguish the center material', () {
  final grass = resolveSmartTile(
    preset: _uniformMultiMaterialPreset(),
    materials: _materials,
    context: const SmartTileCellContext(centerMaterialId: 'grass'),
    x: 0,
    y: 0,
  );
  final dirt = resolveSmartTile(
    preset: _uniformMultiMaterialPreset(),
    materials: _materials,
    context: const SmartTileCellContext(centerMaterialId: 'dirt'),
    x: 0,
    y: 0,
  );

  expect(grass.ruleId, 'uniform_grass');
  expect(dirt.ruleId, 'uniform_dirt');
});

test('exact material distinguishes ids sharing one connection group', () {
  final result = resolveSmartTile(
    preset: _exactNorthPreset(),
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass_a',
        name: 'Grass A',
        connectionGroupId: 'grass',
      ),
      ProjectSmartTileMaterial(
        id: 'grass_b',
        name: 'Grass B',
        connectionGroupId: 'grass',
      ),
    ],
    context: const SmartTileCellContext(
      centerMaterialId: 'grass_a',
      observed: SmartTileObservedSignature(
        northEdge: SmartTileObservedSlot.inside(materialId: 'grass_b'),
      ),
    ),
    x: 0,
    y: 0,
  );

  expect(result.ruleId, 'north_grass_b');
});

test('equal maximum specificity is ambiguous regardless of rule order', () {
  final first = resolveSmartTile(
    preset: _ambiguousPreset(ruleOrder: const <String>['a', 'b']),
    materials: _materials,
    context: _northConnected,
    x: 0,
    y: 0,
  );
  final second = resolveSmartTile(
    preset: _ambiguousPreset(ruleOrder: const <String>['b', 'a']),
    materials: _materials,
    context: _northConnected,
    x: 0,
    y: 0,
  );

  expect(first.status, SmartTileResolutionStatus.ambiguousRule);
  expect(second.status, SmartTileResolutionStatus.ambiguousRule);
  expect(first.matchingRuleIds, <String>['a', 'b']);
  expect(second.matchingRuleIds, <String>['a', 'b']);
});
```

Ajouter aussi :

- `centerMatch.material` exact, `centerMatch.empty` et `centerMatch.any` ;
- validation rejetant `centerMatch.same` et `centerMatch.different` ;
- validation rejetant une contrainte non-`any` sur un slot inactif de la topologie ;
- Wang exact sans centre mais avec quatre slots non vides ;
- règle relative sans centre qui ne matche pas ;
- `empty` face à `null`, `''`, matériau `isEmpty` et matériau non vide ;
- fallback absent, fallback présent et fallback sans candidat positif ;
- candidat poids zéro jamais choisi ;
- candidat de poids négatif rejeté ; poids zéro autorisé/dormant ; règle publiée ou fallback sans aucun poids positif rejeté ;
- stabilité du hash/candidat après réordonnancement des candidats.

- [ ] **Step 2: Lancer le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_native_resolver_test.dart \
  test/smart_tiles/smart_tile_resolver_test.dart
```

Expected: FAIL à la compilation pour l'argument `context`, le statut et les nouveaux champs.

- [ ] **Step 3: Étendre le résultat structuré**

Utiliser le contrat suivant :

```dart
enum SmartTileResolutionStatus {
  resolved,
  noIntent,
  noMatchingRule,
  ambiguousRule,
  noCandidate,
  invalidRule,
}

@immutable
final class SmartTileResolution {
  const SmartTileResolution({
    required this.status,
    this.ruleId,
    this.candidate,
    this.deterministicHash,
    this.matchingRuleIds = const <String>[],
    this.usedFallback = false,
    this.message = '',
  });

  final SmartTileResolutionStatus status;
  final String? ruleId;
  final SmartTileCandidate? candidate;
  final int? deterministicHash;
  final List<String> matchingRuleIds;
  final bool usedFallback;
  final String message;
  List<SmartTileVisualPart> get parts =>
      candidate?.parts ?? const <SmartTileVisualPart>[];
}
```

`matchingRuleIds` est trié par octets UTF-8 et rendu non modifiable dans les branches non constantes.

- [ ] **Step 4: Implémenter l'intention et le matching**

Changer l'entrée publique :

```dart
SmartTileResolution resolveSmartTile({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required SmartTileCellContext context,
  required int x,
  required int y,
  String mapId = '',
  String layerId = '',
  int projectSeed = 0,
  int layerSeed = 0,
});
```

Définir l'intention :

- centre non vide et non `isEmpty` → intention ;
- sinon, topologie Wang avec au moins un slot actif non vide et non `isEmpty` → intention ;
- sinon `noIntent`.

Définir les contraintes :

```text
any        → true
same       → centre non vide ET même connectionGroup
different  → centre non vide ET groupe différent/absence
empty      → slot absent, '' ou matériau isEmpty
material   → égalité exacte d'id
```

Matcher d'abord `rule.centerMatch` contre `context.centerMaterialId`, puis uniquement les slots actifs de la topologie. Pour le centre, `any`, `empty` et `material` suivent les mêmes définitions ; `same/different` ne doivent jamais parvenir au résolveur après validation et produisent `invalidRule` dans l'API défensive si un objet non validé est fourni.

Appliquer `boundaryPolicy` seulement aux slots `outside`. Un slot `inside(null)` reste vide quelle que soit la policy.

- [ ] **Step 5: Implémenter la sélection sans ordre implicite**

Algorithme contractuel :

```text
primaryRules = toutes les règles sauf preset.fallbackRuleId
matches = toutes les primaryRules compatibles avec leur spécificité
si matches vide : essayer fallback explicite
spécificité = nombre de contraintes non-any (centre + slots actifs)
max = spécificité maximale
best = toutes les règles de spécificité max
si best.length > 1 : ambiguousRule + ids triés
sinon : sélectionner un candidat positif de la règle unique
```

Le fallback est exclu du matching primaire même si sa signature est catch-all. Il est ensuite cherché par ID, sans tester sa signature, uniquement après absence de match. Le résultat résolu porte `usedFallback: true`. Un fallback absent reste un diagnostic de catalogue ; un fallback sans candidat valide donne `noCandidate`. Ajouter un test où un fallback `any` coexiste avec une règle primaire : il ne devient ni résultat exact ni source d'ambiguïté.

- [ ] **Step 6: Faire passer les tests**

Run:

```bash
cd packages/map_core
dart format lib/src/operations/smart_tile_resolver.dart \
  test/smart_tiles/smart_tile_native_resolver_test.dart \
  test/smart_tiles/smart_tile_resolver_test.dart
dart test test/smart_tiles/smart_tile_native_resolver_test.dart \
  test/smart_tiles/smart_tile_resolver_test.dart
```

Expected: PASS.

## 8. Task 5 — Migrer tous les consommateurs vers le contexte exact

**Files:**

- Modify: `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart`
- Modify: `packages/map_core/lib/src/operations/smart_tile_test_bench.dart`
- Modify: `packages/map_authoring/lib/src/domains/maps/autotile_actions.dart`
- Modify: chaque test/callsite capturé dans la checklist obligatoire de Task 0 Step 3 ; le rapport doit reproduire la liste exacte avant la première édition.

- [ ] **Step 1: Remplacer la construction dans le visual resolver**

Remplacer `smartTileNeighborhoodForLayerCell` par `smartTileCellContextForLayerCell`. Ne conserver aucun second code de lecture des lattices dans le renderer.

- [ ] **Step 2: Remplacer les scénarios du banc d'essai**

`SmartTileTestBenchCase` porte :

```dart
final class SmartTileTestBenchCase {
  const SmartTileTestBenchCase({
    required this.id,
    required this.context,
  });

  final String id;
  final SmartTileCellContext context;
}
```

Les masques standard sont convertis en contextes par un helper pur réutilisé par la couverture ; ne pas maintenir deux tables de bits.

- [ ] **Step 3: Migrer `autotile.apply`**

L'action `map_authoring` construit le même contexte public ou appelle la projection de couche exportée. Elle ne réimplémente pas la correspondance des règles.

- [ ] **Step 4: Supprimer l'ancien type après le dernier appel**

Run:

```bash
rg -n 'SmartTileNeighborhood|SmartTileCellSample|smartTileNeighborhoodForLayerCell' \
  packages/map_core packages/map_authoring packages/map_editor packages/map_runtime \
  -g '*.dart'
```

Expected: aucune occurrence. Si un appel externe public inconnu existe, conserver temporairement un adaptateur annoté `@Deprecated` et ouvrir un sous-lot explicite ; ne pas laisser deux résolveurs canoniques.

- [ ] **Step 5: Tester les consommateurs**

Run:

```bash
(cd packages/map_core && dart test \
  test/smart_tiles/smart_tile_layer_visual_resolver_test.dart \
  test/smart_tiles/smart_tile_test_bench_test.dart)

(cd packages/map_authoring && dart test \
  test/domains/maps/autotile_determinism_test.dart \
  test/domains/maps/smart_tile_layer_actions_test.dart)
```

Expected: PASS.

## 9. Task 6 — Unifier couverture et ambiguïtés

**Files:**

- Create: `packages/map_core/lib/src/operations/smart_tile_coverage.dart`
- Modify: `packages/map_core/lib/src/operations/smart_tile_catalog_validation.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_native_coverage_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_publication_diagnostics_test.dart`

- [ ] **Step 1: Écrire les tests rouges**

Cas minimum :

```dart
test('Simple requires exactly one resolvable canonical case', () {
  final report = analyzeSmartTileCoverage(
    preset: _simplePreset(),
    materials: _materials,
    atlases: _atlases,
    animations: _animations,
  );

  expect(report.cases, hasLength(1));
  expect(report.exactCount, 1);
  expect(report.missingCount, 0);
  expect(report.ambiguousCount, 0);
});

test('coverage exposes fallback instead of counting it as exact', () {
  final report = analyzeSmartTileCoverage(
    preset: _presetWithOnlyFallback(),
    materials: _materials,
    atlases: _atlases,
    animations: _animations,
  );

  expect(report.fallbackCount, greaterThan(0));
  expect(report.isExact, isFalse);
});
```

Ajouter : Edge16 exact, Corner16 exact depuis slots Wang, Blob47, Mixed256, règle dupliquée ambiguë, candidat sans partie, atlas/animation absent, frame hors grille d'atlas, draft incomplet warning et published incomplet error.

Ajouter aussi :

- Simple avec deux matériaux autorisés produit deux cas de centre distincts ;
- `explicit` relit uniquement les scénarios persistés après round-trip JSON ;
- `templateAndExplicit` déduplique par ID et diagnostique une collision de contenu ;
- `free` sans scénario explicite produit `smart_tiles.coverage.explicit_scenarios_required` ;
- un Wang exact dont les slots référencent au moins deux matériaux refuse `template` seul et exige un scénario croisé explicite ;
- scénario avec slot `null` exige une absence exacte et ne matche pas `any` par conversion ;
- 4 097 scénarios et deux IDs identiques sont rejetés ;
- une expansion template × matériaux ou une union dépassant 4 096 cas est rejetée avant le premier appel au résolveur ;
- fallback autorisé/interdit suit `coverageProfile.allowFallback`.

- [ ] **Step 2: Lancer le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_native_coverage_test.dart \
  test/smart_tiles/smart_tile_publication_diagnostics_test.dart
```

Expected: FAIL à la compilation, analyseur de couverture absent.

- [ ] **Step 3: Implémenter les contrats**

```dart
enum SmartTileCoverageStatus {
  exact,
  fallback,
  missing,
  ambiguous,
  noCandidate,
  missingVisualSource,
  outOfAtlasGrid,
}

@immutable
final class SmartTileCoverageDiagnostic {
  const SmartTileCoverageDiagnostic({
    required this.code,
    required this.message,
    this.scenarioId,
  });

  final String code;
  final String message;
  final String? scenarioId;
}

@immutable
final class SmartTileCoverageCase {
  const SmartTileCoverageCase({
    required this.id,
    required this.context,
    required this.status,
    this.ruleIds = const <String>[],
  });

  final String id;
  final SmartTileCellContext context;
  final SmartTileCoverageStatus status;
  final List<String> ruleIds;
}

@immutable
final class SmartTileCoverageReport {
  const SmartTileCoverageReport({
    required this.cases,
    this.diagnostics = const <SmartTileCoverageDiagnostic>[],
  });

  final List<SmartTileCoverageCase> cases;
  final List<SmartTileCoverageDiagnostic> diagnostics;

  int get exactCount =>
      cases.where((item) => item.status == SmartTileCoverageStatus.exact).length;
  int get fallbackCount =>
      cases.where((item) => item.status == SmartTileCoverageStatus.fallback).length;
  int get missingCount =>
      cases.where((item) => item.status == SmartTileCoverageStatus.missing).length;
  int get ambiguousCount =>
      cases.where((item) => item.status == SmartTileCoverageStatus.ambiguous).length;
  int get noCandidateCount =>
      cases.where((item) => item.status == SmartTileCoverageStatus.noCandidate).length;
  int get missingVisualSourceCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.missingVisualSource)
      .length;
  int get outOfAtlasGridCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.outOfAtlasGrid)
      .length;
  bool get isExact =>
      diagnostics.isEmpty && cases.isNotEmpty && exactCount == cases.length;
}

SmartTileCoverageReport analyzeSmartTileCoverage({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required Iterable<ProjectSmartTileAtlas> atlases,
  required Iterable<ProjectSmartTileAnimation> animations,
});
```

`SmartTileCoverageDiagnostic` est défini exactement ci-dessus. L'analyse construit ses cas uniquement depuis `preset.coverageProfile` :

- `template` génère les cas canoniques de Simple, Edge16, Corner16/12, Blob47 ou Mixed256 pour chaque matériau central autorisé non vide ;
- `explicit` convertit les `requiredScenarios` persistés en contextes exacts ;
- `templateAndExplicit` prend l'union par ID et diagnostique toute collision non identique ;
- l'ensemble final template/explicite/union est borné à 4 096 avant résolution et produit `smart_tiles.coverage.too_many_scenarios` au-delà ;
- `free` exige `explicit` ou `templateAndExplicit` avec au moins un scénario, sans inventer C^8 ;
- un preset Wang multi-matières exact ne peut pas se déclarer couvert par les seuls masques binaires du template : il exige `explicit` ou `templateAndExplicit` et au moins un scénario croisant les matériaux de slots déclarés ;
- `legacy20` est rejeté pour un catalogue v2 et supprimé définitivement dans STN-06.

Chaque cas appelle `resolveSmartTile`. Pour le candidat résolu, l'analyse vérifie ensuite chaque `SmartTileVisualPart` : atlas/animation référencé existant, animation non vide, et chaque `SmartTileFrameRef` contenu dans la grille déclarée de l'atlas. Elle retourne `missingVisualSource` ou `outOfAtlasGrid` sans second matcher. STN-01 ne prétend pas connaître les pixels du PNG : `outOfImage` est vérifié par l'action asset canonique STN-03. Le statut `transformed` et la validation D4 arrivent en STN-02.

- [ ] **Step 4: Brancher la validation catalogue**

Remplacer les détections limitées aux masques dupliqués par le rapport lorsque le template possède des cas canoniques. Conserver des codes stables ou introduire :

```text
smart_tiles.coverage.incomplete
smart_tiles.coverage.fallback_only
smart_tiles.rules.ambiguous
smart_tiles.visual.no_candidate
smart_tiles.candidate.negative_weight
smart_tiles.rule.no_positive_candidate
smart_tiles.visual.source_missing
smart_tiles.visual.out_of_atlas_grid
smart_tiles.coverage.explicit_scenarios_required
smart_tiles.coverage.too_many_scenarios
smart_tiles.coverage.duplicate_scenario_id
smart_tiles.coverage.scenario_id_collision
```

Draft incomplet → warning. Published incomplet/ambigu → error.

Remplacer la garde historique `weight <= 0` par `weight < 0`. Un poids nul reste sérialisable/dormant, mais la publication et la couverture exigent au moins un candidat strictement positif pour chaque règle requise et pour le fallback.

- [ ] **Step 5: Faire passer les tests**

Run:

```bash
cd packages/map_core
dart format lib/src/operations/smart_tile_coverage.dart \
  lib/src/operations/smart_tile_catalog_validation.dart \
  test/smart_tiles/smart_tile_native_coverage_test.dart \
  test/smart_tiles/smart_tile_publication_diagnostics_test.dart
dart test test/smart_tiles/smart_tile_native_coverage_test.dart \
  test/smart_tiles/smart_tile_publication_diagnostics_test.dart \
  test/smart_tiles/smart_tile_catalog_validation_test.dart
```

Expected: PASS.

## 10. Task 7 — Séparer structure et readiness de couche

**Files:**

- Create: `packages/map_core/lib/src/operations/smart_tile_layer_readiness.dart`
- Modify: `packages/map_core/lib/src/validation/validators.dart`
- Create: `packages/map_core/test/smart_tiles/smart_tile_layer_readiness_test.dart`
- Modify: `packages/map_core/test/smart_tiles/smart_tile_layer_roundtrip_test.dart`

- [ ] **Step 1: Écrire les tests rouges**

Scénarios obligatoires :

1. terrain `complete` avec palette index `0` → sérialisation structurelle possible, readiness error `unassigned` ;
2. terrain `complete` avec matériau `isEmpty` explicite → pas `unassigned`, compteur intentional empty ;
3. terrain `sparse` avec `0` → readiness autorisée ;
4. path sparse vide → valide ;
5. index palette hors borne → erreur structurelle ;
6. tailles incorrectes des lattices → erreur structurelle ;
7. cellule avec intention mais résolution absente → readiness error contextualisée ;
8. deux layers `usage: terrain` → erreur structurelle avec les deux IDs ;
9. terrain Simple/uniform multi-matières → structure valide ;
10. terrain Wang multi-matières → structure valide quand field/topologie correspondent.

Test représentatif :

```dart
test('unassigned and intentional empty remain distinct', () {
  const layer = SmartTileLayer(
    id: 'terrain',
    name: 'Terrain',
    presetId: 'terrain',
    usage: SmartTileUsage.terrain,
    materialPalette: <String>['', 'grass', 'void'],
    field: SmartTileField.cell(semanticCells: <int>[0, 2]),
  );
  final report = analyzeSmartTileLayerReadiness(
    map: _mapWith(layer),
    layer: layer,
    preset: _terrainPreset(),
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
      ProjectSmartTileMaterial(
        id: 'void',
        name: 'Void',
        connectionGroupId: 'void',
        isEmpty: true,
      ),
    ],
  );

  expect(report.unassignedCellCount, 1);
  expect(report.intentionalEmptyCellCount, 1);
});
```

- [ ] **Step 2: Lancer le rouge**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_layer_readiness_test.dart \
  test/smart_tiles/smart_tile_layer_roundtrip_test.dart
```

Expected: FAIL, analyseur absent.

- [ ] **Step 3: Implémenter le rapport de readiness**

Le rapport contient exactement ce noyau public pour STN-01 :

```dart
@immutable
final class SmartTileLayerReadinessReport {
  const SmartTileLayerReadinessReport({
    required this.unassignedCellCount,
    required this.intentionalEmptyCellCount,
    required this.unresolvedCellCount,
    required this.diagnostics,
  });

  final int unassignedCellCount;
  final int intentionalEmptyCellCount;
  final int unresolvedCellCount;
  final List<SmartTileDiagnostic> diagnostics;
  bool get hasErrors => diagnostics.any((item) => item.isError);
}
```

La politique `complete/sparse` est un champ typé obligatoire du preset, jamais une chaîne libre dans `properties` :

```dart
enum SmartTileCoveragePolicy {
  @JsonValue('complete')
  complete,
  @JsonValue('sparse')
  sparse,
}
```

et dans `ProjectSmartTilePreset` :

```dart
required SmartTileCoveragePolicy coveragePolicy,
```

Les helpers de création du Studio et de `map_authoring` utiliseront terrain → `complete`, path/forest → `sparse`. Le schéma v5 exige une valeur explicite ; il ne déduit rien silencieusement au décodage.

- [ ] **Step 4: Limiter le validateur aux erreurs structurelles**

Restent structurellement invalides : tailles de grilles, index hors palette, matériau/preset absent, usage incompatible, identifiants invalides et plus d'un fournisseur `usage: terrain`.

Supprimer explicitement les contraintes historiques qui imposent `usage: terrain → cardinal4` et exactement un matériau visuel par preset. Les remplacer par la compatibilité topologie/field, les références `allowedMaterialIds`, `centerMatch` et le profil de couverture. Les tests prouvent `uniform`, Wang et plusieurs matériaux publiables.

Passent dans la readiness : cellules non assignées d'un terrain complete, signatures non résolues et fallback-only selon le profil.

Si la transaction actuelle exige la readiness pour appliquer/publier, `map_authoring` doit l'appeler explicitement dans STN-03. `MapData.fromJson` ne doit pas détruire un brouillon sérialisable.

- [ ] **Step 5: Régénérer et faire passer les tests**

Run:

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart format lib/src/operations/smart_tile_layer_readiness.dart \
  lib/src/validation/validators.dart \
  test/smart_tiles/smart_tile_layer_readiness_test.dart \
  test/smart_tiles/smart_tile_layer_roundtrip_test.dart
dart test test/smart_tiles/smart_tile_layer_readiness_test.dart \
  test/smart_tiles/smart_tile_layer_roundtrip_test.dart \
  test/smart_tiles/smart_tile_project_version_test.dart
```

Expected: PASS.

## 11. Task 8 — Exports, compatibilité interne et contrôle de frontière

**Files:**

- Modify: `packages/map_core/lib/map_core.dart`
- Modify: tous les callsites trouvés Task 0
- Test: package boundary et suites ciblées.

- [ ] **Step 1: Exporter le modèle et les cinq nouveaux modules**

Ajouter des exports publics directs depuis `map_core.dart` :

```dart
export 'src/models/smart_tile_field.dart';
export 'src/operations/smart_tile_cell_context.dart';
export 'src/operations/smart_tile_layer_context.dart';
export 'src/operations/smart_tile_layer_creation.dart';
export 'src/operations/smart_tile_coverage.dart';
export 'src/operations/smart_tile_layer_readiness.dart';
```

- [ ] **Step 2: Vérifier l'absence de dépendance interdite**

Run:

```bash
cd packages/map_core
rg -n "package:(flutter|flame)|map_editor|map_runtime|map_authoring|tiled" \
  lib/src/models/smart_tile.dart \
  lib/src/operations/smart_tile_*.dart
```

Expected: aucune importation interdite. Une mention documentaire de Tiled dans un commentaire de contrat doit rester neutre et ne pas reprendre de source.

- [ ] **Step 3: Vérifier les vieux symboles et switches**

Run:

```bash
rg -n 'SmartTileNeighborhood|SmartTileCellSample|smartTileNeighborhoodForLayerCell' \
  packages -g '*.dart'
```

Expected: aucune occurrence, sauf adaptateur `@Deprecated` explicitement justifié par un appel externe réel.

Run:

```bash
rg -n 'switch \(.*SmartTileTopology|switch \(.*SmartTileTemplateHint' \
  packages -g '*.dart'
```

Expected: relire chaque résultat pour confirmer les branches `uniform/simple`.

- [ ] **Step 4: Lancer les tests de frontière**

Run:

```bash
cd packages/map_core
dart test test/smart_tiles
```

Expected: toute la suite Smart Tile est verte. Le préflight du 2 août 2026 n'a trouvé aucun `test/package_boundary_test.dart` dans `map_core` : ce contrôle précis est donc `N/A`, consigné comme tel, et aucune commande masquant les erreurs avec `|| true` n'est utilisée. Les imports interdits de Step 2 constituent la garde de frontière disponible dans ce lot.

## 12. Task 9 — Vérification finale du lot

**Files:** tous les fichiers du lot, lecture et validation.

- [ ] **Step 1: Formatter sans toucher aux fichiers hors lot**

Run depuis la racine, puis ajouter à cette liste toute occurrence supplémentaire classée `migrate` à Task 0 ; ne jamais dériver la liste depuis tout le worktree sale :

```bash
dart format \
  packages/map_core/lib/src/models/smart_tile.dart \
  packages/map_core/lib/src/models/smart_tile_field.dart \
  packages/map_core/lib/src/models/enums.dart \
  packages/map_core/lib/src/models/map_layer.dart \
  packages/map_core/lib/src/models/map_data.dart \
  packages/map_core/lib/src/models/project_manifest.dart \
  packages/map_core/lib/src/operations/project_json_migrations.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_operations.dart \
  packages/map_core/lib/src/operations/map_resize.dart \
  packages/map_core/lib/src/operations/legacy_smart_tile_migration.dart \
  packages/map_core/lib/src/operations/smart_tile_resolver.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart \
  packages/map_core/lib/src/operations/smart_tile_templates.dart \
  packages/map_core/lib/src/operations/smart_tile_test_bench.dart \
  packages/map_core/lib/src/operations/smart_tile_catalog_validation.dart \
  packages/map_core/lib/src/operations/smart_tile_cell_context.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_context.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_creation.dart \
  packages/map_core/lib/src/operations/smart_tile_coverage.dart \
  packages/map_core/lib/src/operations/smart_tile_layer_readiness.dart \
  packages/map_core/lib/src/validation/validators.dart
```

Formatter ensuite, package par package, les callsites authoring/editor/runtime explicitement modifiés d'après l'inventaire. Ne pas lancer `dart format packages`.

- [ ] **Step 2: Exécuter la suite complète `map_core`**

Run:

```bash
(cd packages/map_core && dart test && dart analyze)
```

Expected: exit 0 pour les deux commandes. Reporter les totaux exacts affichés, sans les inventer dans ce plan.

- [ ] **Step 3: Exécuter les consommateurs directement affectés**

Run:

```bash
(cd packages/map_authoring && dart test \
  test/domains/maps/autotile_determinism_test.dart \
  test/domains/maps/smart_tile_layer_actions_test.dart \
  test/tooling/jsonl_mutation_worker_test.dart \
  test/parity/full_authoring_parity_test.dart && dart analyze)

(cd packages/map_editor && flutter test \
  test/smart_tiles_studio/smart_tile_map_editing_test.dart \
  test/smart_tiles_studio/smart_tile_authoring_controller_test.dart \
  test/smart_tiles_studio/smart_tiles_studio_panel_test.dart \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/authoring_api/editor_write_boundary_test.dart \
  test/authoring_api/no_bypass_guardrail_test.dart && flutter analyze)

(cd packages/map_runtime && flutter test \
  test/smart_tile_runtime_render_test.dart && flutter analyze)

(cd packages/map_authoring && dart run tool/pmcp085_conformance.dart)
(cd tools/pokemap_mcp && npm run check && npm test && npm run build)
```

Recharger ensuite le serveur MCP et exécuter avec les vrais outils :

1. `pokemap_describe` sur les ressources/actions existantes ;
2. open d'une fixture synthétique v5 sous une racine étroite, query manifeste + map, puis validate ;
3. tentative `layer.add` Smart Tile et persistance catalogue, toutes deux rejetées par les codes transitoires STN-01 avec révisions inchangées ;
4. close, puis open d'une fixture Smart Tile v4 allowlistée qui retourne `smart_tile_v4_unsupported` sans ressource partielle ;
5. open d'une fixture sans Smart Tile mais avec empty catalogue v1, query prouvant sa normalisation exacte vers empty v2.

Expected: catalogue live conforme, diagnostics et révisions identiques aux API directe/JSONL. Une suite ou preuve de transport affectée qui échoue maintient le lot `PARTIAL`, même si `map_core` est vert.

- [ ] **Step 4: Vérifier les generated files et le diff**

Run:

```bash
git diff --check
git diff --name-only
git status --short --untracked-files=all
```

Expected: aucun whitespace error ; seuls les fichiers du lot et les modifications concurrentes préexistantes sont présents. Le rapport distingue les deux groupes.

- [ ] **Step 5: Réaliser les cinq passes obligatoires**

Documenter les verdicts :

1. Audit / Architecture ;
2. Implémentation ;
3. Tests ;
4. Build / Validation ;
5. Critique finale.

La critique cherche activement : matcher dupliqué, ordre implicite, fallback silencieux, confusion centre/sommet, generated churn, bypass `map_authoring` et écrasement d'un diff concurrent.

## 13. Critères de clôture STN-01

Le lot peut être proposé `DONE` uniquement si :

- [ ] le nouveau schéma écrit `ProjectVersion.v5` ;
- [ ] le catalogue écrit format 2, rejette format 1 non vide avec `smart_tile_catalog_v1_unsupported` et normalise seulement l'empty v1 ;
- [ ] `SmartTileLayer` porte un seul `SmartTileField` compatible avec sa topologie ;
- [ ] aucune grille inactive n'est sérialisée ;
- [ ] `semanticCells` et lattices conservent leurs responsabilités distinctes ;
- [ ] `uniform/simple` round-trip et se résout ;
- [ ] le contexte exact possède l'ordre huit slots verrouillé par un test asymétrique ;
- [ ] la couche Wang lit ses lattices partagées ;
- [ ] `material(id)` est exact ;
- [ ] `centerMatch` distingue les matériaux Simple et refuse same/different ;
- [ ] same/different exigent un centre ;
- [ ] l'ambiguïté est indépendante de l'ordre ;
- [ ] le fallback est explicitement marqué ;
- [ ] la couverture appelle le même résolveur ;
- [ ] le profil de couverture round-trip, borne les scénarios et pilote l'analyse sans entrée éphémère ;
- [ ] la transform policy et `PathSurfaceKind` round-trip dans le catalogue v2 ;
- [ ] unassigned et intentional empty sont distincts ;
- [ ] une map possède au plus un terrain provider ;
- [ ] la transition v5 en présence de legacy échoue atomiquement ;
- [ ] les mutations régionales Wang refusent proprement d'agir avant STN-05 ;
- [ ] l'éditeur transitoire ne contourne pas cette garde via `setSmartTileCellMaterial` ;
- [ ] le Studio transitoire ne persiste pas son brouillon via `applyToManifest`/`onManifestChanged` avant STN-03 ;
- [ ] tous les appels de production utilisent le nouveau contexte ;
- [ ] `map_core` complet passe ;
- [ ] les consommateurs touchés passent ;
- [ ] les transports existants API/JSONL/éditeur/MCP ont été reconstruits et vérifiés sans introduire de nouvelle action produit avant STN-03 ;
- [ ] aucun comportement Flutter, import TSX ou retrait Terrain/Path n'a été glissé dans le lot.

## 14. Suites explicitement différées

- STN-02 applique les transformations au plan visuel et aux renderers.
- STN-03 rend les catalogues et sets mutables par l'API canonique et les transports.
- STN-04 construit l'expérience de marquage visuel dans le Studio.
- STN-05 compile les gestes de peinture vers cellules/lattices.
- Les lots suivants ajoutent kits, recettes, retrait legacy et import TSX.
