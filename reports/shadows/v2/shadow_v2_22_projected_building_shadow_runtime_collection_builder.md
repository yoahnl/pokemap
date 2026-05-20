# ShadowV2-22 — Projected Building Shadow Runtime Collection Builder V0

## 1. Résumé exécutif

ShadowV2-22 ajoute le builder runtime interne qui transforme des données déjà authorées :

```text
ProjectManifest + MapData
-> ShadowRuntimeInstructionCollection
```

Le builder parcourt `mapData.placedElements` dans l'ordre source, lit `ProjectElementEntry.projectedBuildingShadow`, résout la géométrie pure V2 via `resolveProjectedBuildingShadowGeometry(...)`, puis convertit la géométrie en instruction runtime avec `createProjectedBuildingShadowRuntimeInstruction(...)`.

Aucune intégration rendu n'a été ajoutée. Aucun renderer, `MapLayersComponent`, fichier Flame, codec, diagnostic, modèle persistant, fixture Selbrume, screenshot ou baseline n'a été modifié.

## 2. Objectif du lot

Implémenter uniquement :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Le builder doit rester tolérant et local :

- skip des éléments absents ;
- skip des configs V2 absentes ou disabled ;
- skip des presets manquants ;
- skip des placements sur layer invisible / transparent ;
- skip des placements avec `opacity <= 0` ;
- aucun appel aux diagnostics ;
- aucun fallback ;
- aucune création automatique d'ombre.

## 3. Rappel ShadowV2-21

Décisions de design appliquées :

- builder location : `packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart` ;
- inputs : `ProjectManifest + MapData` ;
- output : `ShadowRuntimeInstructionCollection` ;
- traversal : `mapData.placedElements` dans l'ordre source ;
- missing preset : skip, pas de throw ;
- diagnostics : non appelés par le runtime builder ;
- render integration : hors scope V2-22.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
(aucune sortie)
```

## 5. Décision AGENTS / design gate satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- ShadowV2-21 a présenté et validé le design du collection builder.
- ShadowV2-22 implémente uniquement le builder validé.
- Le lot reste hors rendu, hors editor, hors Flame integration.

Vérification Flame MCP :

```text
mcp flame_docs search "Flame component render priority order" -> No results found for "Flame component render priority order"
mcp flame_docs search "component priority" -> No results found for "component priority"
```

Aucune API Flame n'a été utilisée dans ce lot.

## 6. Fichiers créés / modifiés

Créés par ce lot :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
reports/shadows/v2/shadow_v2_22_projected_building_shadow_runtime_collection_builder.md
```

Modifiés :

```text
Aucun
```

Supprimés :

```text
Aucun
```

Generated files créés :

```text
Aucun
```

Export public :

```text
Aucun export ajouté dans packages/map_runtime/lib/map_runtime.dart.
```

Fichiers Selbrume :

```text
Aucun fichier Selbrume modifié.
```

## 7. Builder créé

Fichier :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
```

API créée :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Le builder :

- construit un index d'éléments depuis `manifest.elements` ;
- construit un index de layers tile visibles ;
- parcourt `mapData.placedElements` ;
- lit uniquement les champs V2 utiles ;
- retourne `ShadowRuntimeInstructionCollection`.

## 8. Traversal implémenté

Ordre :

```text
mapData.placedElements dans l'ordre source
```

Règles :

```text
elementById = manifest.elements par id exact
visibleTileLayerById = mapData.layers.whereType<TileLayer>()
  avec layer.isVisible == true
  et layer.opacity > 0

pour chaque placed :
  skip si placed.opacity <= 0
  skip si placed.layerId.trim() absent des tile layers visibles
  lookup element via placed.elementId.trim()
  skip si element absent
  skip si element.frames vide
  lire element.projectedBuildingShadow
  skip si null
  skip si enabled == false
  lookup presetId via manifest.projectedBuildingShadowCatalog.presetById(...)
  skip si preset absent
  skip si source.width <= 0 ou source.height <= 0
  calculer StaticShadowVisualMetrics
  appeler resolveProjectedBuildingShadowGeometry(...)
  skip si geometry == null
  appeler createProjectedBuildingShadowRuntimeInstruction(...)
  ajouter l'instruction
```

`MapPlacedElement` expose `opacity`, mais pas de champ `visible`. Le test couvre donc `placed.opacity == 0`, `TileLayer.isVisible == false` et `TileLayer.opacity == 0`.

## 9. Metrics strategy

Le calcul reprend la stratégie V1 sans modifier les fichiers V1 :

```text
cellWidth = manifest.settings.tileWidth * manifest.settings.displayScale
cellHeight = manifest.settings.tileHeight * manifest.settings.displayScale

left = placed.pos.x * cellWidth
top = placed.pos.y * cellHeight
visualWidth = source.width * cellWidth
visualHeight = source.height * cellHeight
```

Audit V1 pertinent :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:15:  final visibleTileLayerById = <String, TileLayer>{
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:29:    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:53:        metrics: StaticPlacedElementShadowRuntimeMetrics(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:54:          worldLeft: placed.pos.x * cellWidth,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:55:          worldTop: placed.pos.y * cellHeight,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:56:          visualWidth: source.width * cellWidth,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:57:          visualHeight: source.height * cellHeight,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:295:StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:299:    left: metrics.worldLeft,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:300:    top: metrics.worldTop,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:301:    visualWidth: metrics.visualWidth,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:302:    visualHeight: metrics.visualHeight,
```

## 10. Missing preset behavior

Si `presetId` est absent du catalogue :

```text
skip
pas de throw
pas de fallback
pas de genericProjection
```

Test couvert :

```text
skips missing preset without throwing
```

## 11. Diagnostics usage

Le builder n'appelle pas :

```dart
diagnoseProjectedBuildingShadows(...)
```

Les diagnostics restent authoring-only. Le runtime builder est silencieux, local et tolérant.

## 12. Relation V1/V2

Le builder ne lit pas `element.shadow`, `MapPlacedElementShadowOverride`, `StaticShadowFamily` ni la policy auto-shadow V1.

La coexistence V1 + V2 est autorisée au niveau runtime collection builder. Elle reste signalée par les diagnostics ShadowV2-16.

Test couvert :

```text
does not block V2 when the element also has a V1 shadow
```

## 13. Tests ajoutés

Fichier :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Cas couverts :

- no projected shadows -> collection vide ;
- valid config -> 1 instruction `projectedPolygon` / `groundStatic` ;
- points attendus calculés précisément ;
- disabled config -> skip ;
- missing preset -> skip sans throw ;
- missing element -> skip sans throw ;
- layer invisible / layer opacity 0 / placed opacity 0 -> skip ;
- placement opacity non multipliée ;
- ordre source des placements conservé ;
- V1 shadow + V2 config -> instruction V2 produite ;
- audit source anti-dérive.

TDD RED initial :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
test/shadow/runtime_projected_building_shadow_collection_test.dart:5:8: Error: Error when reading 'lib/src/shadow/runtime_projected_building_shadow_collection.dart': No such file or directory
import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';
       ^
test/shadow/runtime_projected_building_shadow_collection_test.dart:13:26: Error: Method not found: 'buildRuntimeProjectedBuildingShadowCollection'.
      final collection = buildRuntimeProjectedBuildingShadowCollection(
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: test/shadow/runtime_projected_building_shadow_collection_test.dart:5:8: Error: Error when reading 'lib/src/shadow/runtime_projected_building_shadow_collection.dart': No such file or directory
  import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';
         ^
00:00 +0 -1: Some tests failed.
```

## 14. Résultats des tests

### Test ciblé

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
00:00 +0: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +1: buildRuntimeProjectedBuildingShadowCollection builds one ground projected polygon for a valid projected shadow
00:00 +2: buildRuntimeProjectedBuildingShadowCollection skips disabled projected shadow config
00:00 +3: buildRuntimeProjectedBuildingShadowCollection skips missing preset without throwing
00:00 +4: buildRuntimeProjectedBuildingShadowCollection skips missing element without throwing
00:00 +5: buildRuntimeProjectedBuildingShadowCollection skips hidden or transparent placement layers and zero opacity placement
00:00 +6: buildRuntimeProjectedBuildingShadowCollection does not multiply preset opacity by placement opacity
00:00 +7: buildRuntimeProjectedBuildingShadowCollection preserves source placement order
00:00 +8: buildRuntimeProjectedBuildingShadowCollection does not block V2 when the element also has a V1 shadow
00:00 +9: buildRuntimeProjectedBuildingShadowCollection builder source stays independent from renderer and diagnostics layers
00:00 +10: All tests passed!
```

### Régression runtime shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:03 +248: All tests passed!
```

### Régression ShadowV2 core

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +150: All tests passed!
```

## 15. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow/runtime_projected_building_shadow_collection.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 1.7s)
```

## 16. Audit anti-dérive

Commande demandée :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|Canvas|Path|Paint|dart:ui|package:flutter|package:flame" packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Sortie :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart:3:import 'package:flutter_test/flutter_test.dart';
```

Interprétation :

- le hit vient du harness de test Flutter (`flutter_test`) ;
- le fichier production builder ne contient aucun hit.

Vérification production-only :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|Canvas|Path|Paint|dart:ui|package:flutter|package:flame" packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
```

Sortie :

```text
(aucune sortie)
```

## 17. Export public

Export ajouté :

```text
Non
```

Raison :

```text
Le builder est interne au pipeline runtime. Le lot V2-22 ne branche pas encore la collection au rendu et ne rend pas cette API publique.
```

Diff de `packages/map_runtime/lib/map_runtime.dart` :

```text
Sans objet : fichier non modifié.
```

## 18. Ce qui n'a volontairement pas été créé

Non créés / non modifiés :

- renderer ;
- `ShadowRuntimeRenderer` ;
- `MapLayersComponent` ;
- pipeline Flame ;
- runtime visual integration ;
- collection provider wiring ;
- screenshots ;
- baselines ;
- Selbrume ;
- diagnostics call ;
- fallback automatique ;
- `genericProjection` ;
- codecs ;
- modèles persistants ;
- generated files ;
- export public.

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
(aucune sortie)
```

Note : les fichiers de ce lot sont nouveaux et non stagés.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
(aucune sortie)
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
(aucune sortie)
```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale vérifiée :

```text
?? packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
?? reports/shadows/v2/shadow_v2_22_projected_building_shadow_runtime_collection_builder.md
```

## 23. Risques / réserves

- Le builder réplique volontairement la formule métrique V1 au lieu d'extraire un helper partagé, parce que la modification des fichiers V1 était interdite dans ce lot.
- La frame utilisée est `element.frames.first`, comme dans le pipeline V1 audité.
- `MapPlacedElement` ne possède pas de booléen `visible`; le skip visibility porte donc sur `TileLayer.isVisible`.
- La collection n'est pas encore branchée au rendu. Le lot prouve la construction des instructions, pas leur apparition à l'écran.

## 24. Auto-critique

Le lot reste borné et testable, mais l'existence de deux calculs métriques séparés V1/V2 mérite un futur audit si les règles d'échelle évoluent. Pour V2-22, ne pas toucher les helpers V1 réduit le risque d'une régression runtime existante.

## 25. Regard critique sur le prompt

Le prompt est très clair sur les frontières runtime/rendering. Les commandes d'audit larges capturent beaucoup de fichiers non liés quand les motifs sont génériques (`opacity`, `visible`, `frame`). Pour les prochains lots, ajouter une commande focalisée sur les fichiers réellement audités faciliterait un evidence pack plus lisible.

## 26. Prochain lot recommandé

```text
ShadowV2-23 — Projected Building Shadow Runtime Render Integration Design Gate
```

Objectif recommandé :

- décider comment raccorder la collection V2 au provider / merge / render path ;
- conserver un design gate avant toute modification de `MapLayersComponent` ou du renderer ;
- définir à quel moment déclencher le visual gate et les screenshots V2.

## Code complet des fichiers créés/modifiés

### packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart

```dart
import 'package:map_core/map_core.dart';

import 'projected_building_shadow_runtime_adapter.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in mapData.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty ||
      visibleTileLayerById.isEmpty ||
      mapData.placedElements.isEmpty) {
    return ShadowRuntimeInstructionCollection();
  }

  final cellWidth =
      manifest.settings.tileWidth * manifest.settings.displayScale;
  final cellHeight =
      manifest.settings.tileHeight * manifest.settings.displayScale;
  final instructions = <ShadowRuntimeRenderInstruction>[];

  for (final placed in mapData.placedElements) {
    if (placed.opacity <= 0 ||
        !visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }

    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }

    final config = element.projectedBuildingShadow;
    if (config == null || !config.enabled) {
      continue;
    }

    final preset = manifest.projectedBuildingShadowCatalog.presetById(
      config.presetId,
    );
    if (preset == null) {
      continue;
    }

    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: placed.pos.x * cellWidth,
        top: placed.pos.y * cellHeight,
        visualWidth: source.width * cellWidth,
        visualHeight: source.height * cellHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    instructions.add(
      createProjectedBuildingShadowRuntimeInstruction(geometry),
    );
  }

  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
```

### packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('buildRuntimeProjectedBuildingShadowCollection', () {
    test('returns an empty collection when no element has a projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(elements: [_element()]),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection, ShadowRuntimeInstructionCollection());
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, isEmpty);
    });

    test('builds one ground projected polygon for a valid projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '123ABC');
      expect(instruction.worldLeft, closeTo(64, 0.000001));
      expect(instruction.worldTop, closeTo(128, 0.000001));
      expect(instruction.width, closeTo(48, 0.000001));
      expect(instruction.height, closeTo(64, 0.000001));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
    });

    test('skips disabled projected shadow config', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.isEmpty, isTrue);
    });

    test('skips missing preset without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([]),
              elements: [
                _element(projectedBuildingShadow: _config(presetId: 'missing')),
              ],
            ),
            mapData: _map(placedElements: [_placed()]),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test('skips missing element without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([_preset()]),
              elements: const [],
            ),
            mapData: _map(
              placedElements: [_placed(elementId: 'missing-element')],
            ),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test(
        'skips hidden or transparent placement layers and zero opacity placement',
        () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(placedElements: [_placed(opacity: 0)]),
        ).isEmpty,
        isTrue,
      );
    });

    test('does not multiply preset opacity by placement opacity', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(placedElements: [_placed(opacity: 0.5)]),
      );

      expect(collection.groundStatic.single.opacity, 0.18);
    });

    test('preserves source placement order', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(
          placedElements: [
            _placed(id: 'late-left', pos: const GridPos(x: 5, y: 2)),
            _placed(id: 'early-left', pos: const GridPos(x: 1, y: 2)),
          ],
        ),
      );

      expect(collection.groundStatic, hasLength(2));
      expect(collection.groundStatic[0].worldLeft, greaterThan(100));
      expect(collection.groundStatic[1].worldLeft, lessThan(100));
    });

    test('does not block V2 when the element also has a V1 shadow', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'legacy-shadow',
              ),
              projectedBuildingShadow: _config(),
            ),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.groundStatic, hasLength(1));
    });

    test(
        'builder source stays independent from renderer and diagnostics layers',
        () {
      final source = File(
        'lib/src/shadow/runtime_projected_building_shadow_collection.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'generic' 'Projection',
        'applyElementAutoShadow' 'PolicyToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'Project' 'Validator',
        'Map' 'Validator',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
        'static_shadow_family' '_projection',
        'static_shadow_projection' '_geometry',
        'static_shadow_contact_ledge' '_geometry',
        'element_auto_shadow' '_policy',
        'projected_building_shadow' '_diagnostics',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 10, height: 10),
    layers: layers ?? [_layer()],
    placedElements: placedElements,
  );
}

MapLayer _layer({
  String id = 'objects',
  bool isVisible = true,
  double opacity = 1,
}) {
  return MapLayer.tile(
    id: id,
    name: 'Objects',
    tilesetId: 'tileset',
    isVisible: isVisible,
    opacity: opacity,
  );
}

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementShadowConfig? shadow,
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  int sourceWidth = 2,
  int sourceHeight = 3,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'Building',
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(
          x: 0,
          y: 0,
          width: sourceWidth,
          height: sourceHeight,
        ),
      ),
    ],
    shadow: shadow,
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

MapPlacedElement _placed({
  String id = 'building-placed',
  String layerId = 'objects',
  String elementId = 'building',
  GridPos pos = const GridPos(x: 1, y: 2),
  double opacity = 1,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    opacity: opacity,
  );
}

ProjectBuildingShadowPresetCatalog _catalog(
  List<ProjectBuildingShadowPreset> presets,
) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  String id = 'shadow-a',
  double opacity = 0.18,
  String colorHexRgb = '123ABC',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'shadow-a',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}
```
