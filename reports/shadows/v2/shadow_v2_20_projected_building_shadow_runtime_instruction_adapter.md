# ShadowV2-20 — Projected Building Shadow Runtime Instruction Adapter V0

## 1. Résumé exécutif

ShadowV2-20 a créé un adapter runtime borné :

```text
ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction
```

L’adapter utilise l’instruction runtime existante, sans modifier le renderer, sans collection builder, sans traversal de manifest/map, sans Selbrume, sans screenshot, sans build runner et sans fichier generated.

Décision appliquée depuis ShadowV2-19 :

```text
shape: ShadowRuntimeShapeKind.projectedPolygon
renderPass: ShadowRenderPass.groundStatic
points: ordre préservé
opacity: préservée
colorHexRgb: préservé
```

## 2. Objectif du lot

Implémenter uniquement le pont mécanique entre une géométrie V2 déjà résolue et une instruction runtime existante.

Ce lot ne crée pas d’ombre automatiquement. Il ne résout pas de preset, ne parcourt aucun projet, ne déclenche aucun rendu et ne modifie aucun comportement runtime existant.

## 3. Rappel ShadowV2-19

ShadowV2-19 a validé :

```text
ProjectedBuildingShadowGeometry
-> ShadowRuntimeRenderInstruction
-> ShadowRuntimeShapeKind.projectedPolygon
-> ShadowRenderPass.groundStatic
```

ShadowV2-20 devait rester limité à l’adapter `geometry -> instruction`, avec tests unitaires seulement.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
 M reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

Note : cette modification du rapport ShadowV2-19 était déjà présente avant ShadowV2-20. Elle n’a pas été modifiée dans ce lot.

## 5. Décision AGENTS / design gate satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

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

```text
ShadowV2-19 a validé le design runtime instruction.
ShadowV2-20 est un lot d’implémentation borné.
Aucun nouveau design gate bloquant n’a été détecté.
```

Flame docs :

```text
Recherche effectuée : "Flame Component render Canvas priority render order"
Résultat : No results found.
Impact : aucun, car l’adapter créé n’importe pas Flame, Flutter, dart:ui, Canvas, Path ou Paint.
```

## 6. Fichiers créés / modifiés

Créés :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Modifiés par ce lot :

```text
Aucun fichier existant modifié.
```

Préexistants déjà modifiés avant ce lot :

```text
reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

Supprimés :

```text
Aucun.
```

Generated :

```text
Aucun.
```

Selbrume :

```text
Aucun fichier Selbrume modifié.
```

## 7. Adapter créé

Fichier :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
```

API créée :

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

Le nom exact recommandé par le prompt a été conservé.

## 8. Mapping geometry -> instruction

Mapping implémenté :

```text
geometry.points[n].x -> ShadowRuntimePoint.worldX
geometry.points[n].y -> ShadowRuntimePoint.worldY
geometry.opacity -> instruction.opacity
geometry.colorHexRgb -> instruction.colorHexRgb
shape -> ShadowRuntimeShapeKind.projectedPolygon
renderPass -> ShadowRenderPass.groundStatic
```

Bounds :

```text
worldLeft = min(points.worldX)
worldTop = min(points.worldY)
width = max(points.worldX) - min(points.worldX)
height = max(points.worldY) - min(points.worldY)
```

Les validations de runtime existantes restent actives via `ShadowRuntimeRenderInstruction`.

## 9. Tests ajoutés

Fichier :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Tests ajoutés :

```text
- converts geometry to a ground projected polygon instruction
- preserves point order exactly
- preserves appearance values
- keeps runtime validation for degenerate polygons
- adapter source stays independent from render and traversal layers
```

## 10. Résultats des tests

### RED ciblé initial

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Sortie RED attendue :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
test/shadow/projected_building_shadow_runtime_adapter_test.dart:5:8: Error: Error when reading 'lib/src/shadow/projected_building_shadow_runtime_adapter.dart': No such file or directory
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
       ^
test/shadow/projected_building_shadow_runtime_adapter_test.dart:11:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/projected_building_shadow_runtime_adapter_test.dart:44:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/projected_building_shadow_runtime_adapter_test.dart:67:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/projected_building_shadow_runtime_adapter_test.dart:86:15: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
        () => createProjectedBuildingShadowRuntimeInstruction(
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart: test/shadow/projected_building_shadow_runtime_adapter_test.dart:5:8: Error: Error when reading 'lib/src/shadow/projected_building_shadow_runtime_adapter.dart': No such file or directory
  import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
         ^
  test/shadow/projected_building_shadow_runtime_adapter_test.dart:11:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
        final instruction = createProjectedBuildingShadowRuntimeInstruction(
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/shadow/projected_building_shadow_runtime_adapter_test.dart:44:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
        final instruction = createProjectedBuildingShadowRuntimeInstruction(
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/shadow/projected_building_shadow_runtime_adapter_test.dart:67:27: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
        final instruction = createProjectedBuildingShadowRuntimeInstruction(
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/shadow/projected_building_shadow_runtime_adapter_test.dart:86:15: Error: Method not found: 'createProjectedBuildingShadowRuntimeInstruction'.
          () => createProjectedBuildingShadowRuntimeInstruction(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.
```

### Test ciblé final

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
00:00 +0: createProjectedBuildingShadowRuntimeInstruction converts geometry to a ground projected polygon instruction
00:00 +1: createProjectedBuildingShadowRuntimeInstruction preserves point order exactly
00:00 +2: createProjectedBuildingShadowRuntimeInstruction preserves appearance values
00:00 +3: createProjectedBuildingShadowRuntimeInstruction keeps runtime validation for degenerate polygons
00:00 +4: createProjectedBuildingShadowRuntimeInstruction adapter source stays independent from render and traversal layers
00:00 +5: All tests passed!
```

### Régression runtime shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:07 +238: All tests passed!
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

## 11. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow/projected_building_shadow_runtime_adapter.dart test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Sortie :

```text
Waiting for another flutter command to release the startup lock...
Analyzing 2 items...
No issues found! (ran in 2.0s)
```

## 12. Audit anti-dérive

Commande demandée :

```bash
rg -n "genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|ProjectManifest|ProjectElementEntry|MapData|MapPlacedElement|Canvas|Path|Paint|dart:ui|package:flutter|package:flame" packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Sortie :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart:3:import 'package:flutter_test/flutter_test.dart';
```

Interprétation :

```text
Le seul hit est l’import normal du harness de test Flutter.
Le fichier adapter de production n’a aucun hit interdit.
```

Vérification adapter seul :

```bash
rg -n "genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|ProjectManifest|ProjectElementEntry|MapData|MapPlacedElement|Canvas|Path|Paint|dart:ui|package:flutter|package:flame" packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
```

Sortie :

```text
Aucune ligne.
```

## 13. Export public

Export ajouté :

```text
Non.
```

Raison :

```text
Le prompt demandait d’éviter l’export public par défaut.
L’adapter est un détail runtime interne pour le prochain builder/POC.
```

`packages/map_runtime/lib/map_runtime.dart` n’a pas été modifié.

## 14. Ce qui n’a volontairement pas été créé

Non créés :

```text
- renderer
- drawPath
- Canvas / Paint / dart:ui usage
- collection builder
- ProjectManifest traversal
- MapData traversal
- preset lookup
- appel à resolveProjectedBuildingShadowGeometry
- diagnostics
- editor preview
- screenshots
- fixtures Selbrume
- baselines
- generated files
```

Non modifiés :

```text
- ShadowRuntimeRenderer
- ShadowRuntimeRenderInstruction
- MapLayersComponent
- ProjectManifest
- ProjectElementEntry
- map_core
- map_editor
- Selbrume
```

## 15. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 ...d_building_shadow_runtime_instruction_design.md | 1052 ++++++++++----------
 1 file changed, 504 insertions(+), 548 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis créés par ce lot. La ligne affichée correspond au rapport ShadowV2-19 préexistant.

## 16. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

Note : modification préexistante, non touchée par ShadowV2-20.

## 17. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Aucune ligne.
```

## 18. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale attendue après création de ce rapport :

```text
 M reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
?? packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
?? packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
?? reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

## 19. Risques / réserves

Le principal risque est que l’adapter calcule les bounds localement parce que `ShadowRuntimeRenderInstruction` les exige. C’est une conversion mécanique, pas une résolution géométrique : les points restent ceux de `ProjectedBuildingShadowGeometry`.

Le test d’audit anti-dérive du fichier de test utilise `flutter_test`, donc la commande globale demandée signale `package:flutter_test`. Le fichier de production est propre.

## 20. Auto-critique

Le lot respecte le cadrage : l’adapter ne connaît ni le manifest, ni les placements, ni le renderer. Le test de source pourrait être considéré comme un peu défensif, mais il protège précisément le risque de dérive demandé par le prompt.

Une alternative aurait été de créer un helper de bounds partagé avec V1, mais cela aurait touché du code existant et élargi inutilement le diff.

## 21. Regard critique sur le prompt

Le prompt est très cadrant et adapté à ce lot. Une petite friction : l’audit anti-dérive inclut le fichier de test et cherche `package:flutter`, ce qui matche naturellement `package:flutter_test`. Pour un prochain lot, séparer l’audit production et l’audit test éviterait ce faux positif attendu.

## 22. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-21 — Projected Building Shadow Runtime Collection Builder Design Gate
```

Objectif :

```text
Concevoir, sans coder, le builder futur qui parcourra les placements authorés,
fera le lookup du preset V2, appellera la géométrie core puis cet adapter runtime.
```

## Code complet des fichiers créés/modifiés par ce lot

### packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
) {
  final points = geometry.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList(growable: false);
  final bounds = _boundsFromRuntimePoints(points);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: geometry.opacity,
    colorHexRgb: geometry.colorHexRgb,
    polygonPoints: points,
  );
}

_ProjectedBuildingShadowRuntimeBounds _boundsFromRuntimePoints(
  List<ShadowRuntimePoint> points,
) {
  var minX = points.first.worldX;
  var maxX = points.first.worldX;
  var minY = points.first.worldY;
  var maxY = points.first.worldY;
  for (final point in points.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
    if (point.worldY < minY) {
      minY = point.worldY;
    }
    if (point.worldY > maxY) {
      maxY = point.worldY;
    }
  }

  return _ProjectedBuildingShadowRuntimeBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _ProjectedBuildingShadowRuntimeBounds {
  const _ProjectedBuildingShadowRuntimeBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}
```

### packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('createProjectedBuildingShadowRuntimeInstruction', () {
    test('converts geometry to a ground projected polygon instruction', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 5),
            ProjectedBuildingShadowPoint(x: 0, y: 5),
          ],
          opacity: 0.18,
          colorHexRgb: '000000',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '000000');
      expect(instruction.worldLeft, 0);
      expect(instruction.worldTop, 0);
      expect(instruction.width, 10);
      expect(instruction.height, 5);
      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 0, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 5),
          ShadowRuntimePoint(worldX: 0, worldY: 5),
        ],
      );
    });

    test('preserves point order exactly', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 1, y: 2),
            ProjectedBuildingShadowPoint(x: 3, y: 5),
            ProjectedBuildingShadowPoint(x: 8, y: 13),
            ProjectedBuildingShadowPoint(x: 21, y: 34),
          ],
        ),
      );

      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 1, worldY: 2),
          ShadowRuntimePoint(worldX: 3, worldY: 5),
          ShadowRuntimePoint(worldX: 8, worldY: 13),
          ShadowRuntimePoint(worldX: 21, worldY: 34),
        ],
      );
    });

    test('preserves appearance values', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: -5, y: 2),
            ProjectedBuildingShadowPoint(x: 6, y: 3),
            ProjectedBuildingShadowPoint(x: 8, y: 14),
            ProjectedBuildingShadowPoint(x: -3, y: 12),
          ],
          opacity: 0.42,
          colorHexRgb: '123ABC',
        ),
      );

      expect(instruction.opacity, 0.42);
      expect(instruction.colorHexRgb, '123ABC');
    });

    test('keeps runtime validation for degenerate polygons', () {
      expect(
        () => createProjectedBuildingShadowRuntimeInstruction(
          _geometry(
            [
              ProjectedBuildingShadowPoint(x: 0, y: 0),
              ProjectedBuildingShadowPoint(x: 1, y: 1),
              ProjectedBuildingShadowPoint(x: 2, y: 2),
              ProjectedBuildingShadowPoint(x: 3, y: 3),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('adapter source stays independent from render and traversal layers',
        () {
      final source = File(
        'lib/src/shadow/projected_building_shadow_runtime_adapter.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Project' 'Manifest',
        'ProjectElement' 'Entry',
        'Map' 'Data',
        'MapPlaced' 'Element',
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

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points, {
  double opacity = 0.18,
  String colorHexRgb = '000000',
}) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}
```
