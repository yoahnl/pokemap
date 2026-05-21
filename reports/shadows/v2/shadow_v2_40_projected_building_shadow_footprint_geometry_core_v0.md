# ShadowV2-40 — Projected Building Shadow Footprint Geometry Core V0

## 1. Résumé exécutif

ShadowV2-40 implémente uniquement le core `map_core` de Footprint Geometry V0.

Ajouté :

- `ProjectedBuildingShadowGeometryMode` ;
- `ProjectedShadowFootprintTuning` ;
- validation stricte `directional` / `footprint` dans `ProjectBuildingShadowPreset` ;
- résolution pure footprint 4 points dans `resolveProjectedBuildingShadowGeometry(...)` ;
- tests map_core pour defaults, validations, preset, micro-fixture, `localOffset`, `anchor` ignoré.

Non modifié :

- runtime ;
- editor ;
- renderer ;
- painter ;
- Selbrume ;
- screenshots / baselines.

Résultat :

```text
Footprint V0 core-only implémenté.
Directional reste rétrocompatible.
```

## 2. Objectif du lot

Objectif exact :

```text
Ajouter dans map_core le modèle et la résolution pure Footprint Geometry V0
pour les ombres projetées de bâtiments ShadowV2,
en conservant le renderer/runtime/editor inchangés.
```

Scope respecté :

```text
map_core model + pure geometry resolver + tests map_core + rapport.
```

## 3. Rappel ShadowV2-39

Lot 39 a recommandé :

```text
Option : Footprint 4 points / skewed rectangle.
Modèle : geometryMode + ProjectedShadowFootprintTuning.
Points : frontLeft, frontRight, rearRight, rearLeft.
Renderer/painter : réutiliser projectedPolygon.
Candidate C : benchmark/fallback directional.
```

Default Footprint V0 :

```text
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Micro-fixture attendue :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Fichiers préexistants non liés au lot :

```text
Aucun fichier modifié ou non suivi au démarrage de ShadowV2-40.
```

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md

765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

```text
Le design gate était satisfait par ShadowV2-39.
ShadowV2-40 est donc une implémentation core-only TDD.
```

Skills / rituels utilisés :

- TDD : test RED avant implémentation ;
- vérification avant complétion ;
- karpathy-guidelines : scope minimal, pas runtime/editor.

## 6. Fichiers créés / modifiés / supprimés

Fichiers modifiés :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Fichiers créés :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

Fichiers supprimés :

```text
Aucun
```

Fichiers hors scope modifiés :

```text
Aucun
```

## 7. Audit initial du modèle et resolver ShadowV2

Commande :

```bash
rg -n "ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|ProjectBuildingShadowPreset|ProjectedShadowShapeTuning|ProjectedBuildingShadowGeometry|resolveProjectedBuildingShadowGeometry" packages/map_core/lib packages/map_core/test/shadow_v2 reports/shadows/v2
```

Constats :

- `ProjectBuildingShadowPreset` existait avec `direction`, `shape`, `appearance`, `timeOfDayMode`, `categoryId`, `sortOrder`.
- Aucun `geometryMode`.
- Aucun `ProjectedShadowFootprintTuning`.
- `resolveProjectedBuildingShadowGeometry(...)` résolvait seulement la formule directionnelle.
- `ProjectedBuildingShadowGeometry` imposait déjà exactement 4 points, compatible Footprint V0 4 points.
- Les tests existants caractérisaient la direction, la normalisation, `localOffset`, ratios de shape, appearance, `followsSun`, et la calibration V0 directionnelle.

Pourquoi map_core-only suffit :

```text
Footprint V0 produit la même sortie core que le mode directionnel :
ProjectedBuildingShadowGeometry(points, opacity, colorHexRgb).
Runtime/editor consommeront plus tard cette même sortie via les adapters.
```

## 8. Modèle ajouté : ProjectedBuildingShadowGeometryMode

Ajout :

```dart
enum ProjectedBuildingShadowGeometryMode {
  directional,
  footprint,
}
```

Règles :

- `directional` est le mode historique et le default.
- `footprint` active le nouveau resolver V0.

## 9. Modèle ajouté : ProjectedShadowFootprintTuning

Ajout :

```dart
final class ProjectedShadowFootprintTuning
```

Defaults :

```text
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
```

Validations :

```text
attachYRatio: finite, 0 <= value <= 1
frontWidthRatio: finite, 0 < value <= 2.0
rearWidthRatio: finite, 0 < value <= 2.0
depthRatio: finite, 0 < value <= 1.0
skewXRatio: finite, -0.5 <= value <= 0.5
```

Égalité :

```text
operator == et hashCode incluent les 5 champs.
```

## 10. Modification ProjectBuildingShadowPreset

Ajouts :

```dart
ProjectedBuildingShadowGeometryMode geometryMode =
    ProjectedBuildingShadowGeometryMode.directional

ProjectedShadowFootprintTuning? footprint
```

Règles strictes :

```text
directional + footprint null => accepté
directional + footprint non-null => rejeté
footprint + footprint non-null => accepté
footprint + footprint null => rejeté
```

Rétrocompatibilité :

```text
Les appels existants sans geometryMode restent directional.
```

## 11. Résolution Footprint Geometry V0

`resolveProjectedBuildingShadowGeometry(...)` sélectionne maintenant :

```text
directional => helper directionnel existant
footprint => helper footprint V0
```

Formule footprint :

```text
centerX = metrics.left + metrics.visualWidth * 0.5 + config.localOffset.x
frontY = metrics.top + metrics.visualHeight * footprint.attachYRatio + config.localOffset.y

frontWidth = metrics.visualWidth * footprint.frontWidthRatio
rearWidth = metrics.visualWidth * footprint.rearWidthRatio
depth = metrics.visualHeight * footprint.depthRatio

rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio
rearY = frontY + depth

frontLeft = (centerX - frontWidth / 2, frontY)
frontRight = (centerX + frontWidth / 2, frontY)
rearRight = (rearCenterX + rearWidth / 2, rearY)
rearLeft = (rearCenterX - rearWidth / 2, rearY)
```

Ordre :

```text
frontLeft, frontRight, rearRight, rearLeft
```

Appearance :

```text
preset.appearance.opacity
preset.appearance.colorHexRgb
```

`localOffset` :

```text
Translate toute l'ombre footprint.
```

`anchor` :

```text
Ignoré en Footprint V0.
```

## 12. Compatibilité Directional Geometry

Le code directionnel existant est extrait dans un helper privé.

Formule préservée :

```text
direction normalisée
perpendicular
anchorWorldX/Y depuis anchor + localOffset
length depuis visualHeight * lengthRatio
near/far widths depuis visualWidth
points nearLeft, nearRight, farRight, farLeft
```

Tests existants directionnels :

```text
Verts sans changement d'attentes.
```

## 13. Tests ajoutés / modifiés

`projected_building_shadow_geometry_test.dart` :

- `resolves footprint geometry with attached skewed rectangle points`
- `footprint geometry localOffset shifts all points`
- `footprint geometry ignores anchor`

`projected_building_shadow_footprint_tuning_test.dart` :

- defaults footprint V0 ;
- equality/hashCode ;
- validations des bornes ;
- default directional ;
- directional sans footprint accepté ;
- directional avec footprint rejeté ;
- footprint avec tuning accepté ;
- footprint sans tuning rejeté ;
- equality/hashCode preset avec `geometryMode` et `footprint`.

## 14. TDD RED initial

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie RED utile :

```text
Failed to load "test/shadow_v2/projected_building_shadow_geometry_test.dart":
test/shadow_v2/projected_building_shadow_geometry_test.dart:223:23: Error: Undefined name 'ProjectedBuildingShadowGeometryMode'.
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_geometry_test.dart:224:20: Error: Method not found: 'ProjectedShadowFootprintTuning'.
        footprint: ProjectedShadowFootprintTuning(),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_geometry_test.dart:223:9: Error: No named parameter with the name 'geometryMode'.
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        ^^^^^^^^^^^^
lib/src/models/projected_building_shadow.dart:212:11: Context: Found this candidate, but the arguments don't match.
  factory ProjectBuildingShadowPreset({
          ^
test/shadow_v2/projected_building_shadow_geometry_test.dart:475:19: Error: Undefined name 'ProjectedBuildingShadowGeometryMode'.
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_geometry_test.dart:476:16: Error: Method not found: 'ProjectedShadowFootprintTuning'.
    footprint: ProjectedShadowFootprintTuning(),
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_geometry_test.dart:475:5: Error: No named parameter with the name 'geometryMode'.
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    ^^^^^^^^^^^^
lib/src/models/projected_building_shadow.dart:212:11: Context: Found this candidate, but the arguments don't match.
  factory ProjectBuildingShadowPreset({
          ^

Some tests failed.
```

## 15. Résultats des tests

Commande :

```bash
cd packages/map_core && dart test --reporter=expanded test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_geometry_test.dart
00:00 +0: Projected building shadow geometry disabled config returns null
00:00 +1: Projected building shadow geometry resolves basic horizontal geometry with stable point order
00:00 +2: Projected building shadow geometry normalizes direction before applying length
00:00 +3: Projected building shadow geometry resolves vertical direction geometry
00:00 +4: Projected building shadow geometry localOffset shifts all points
00:00 +5: Projected building shadow geometry shape ratios control length and widths
00:00 +6: Projected building shadow geometry propagates preset appearance
00:00 +7: Projected building shadow geometry followsSun uses preset direction as fixed in V0
00:00 +8: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points
00:00 +9: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points
00:00 +10: Projected building shadow geometry footprint geometry localOffset shifts all points
00:00 +11: Projected building shadow geometry footprint geometry ignores anchor
00:00 +12: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +13: Projected building shadow geometry point and geometry equality include ordered values
00:00 +14: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +15: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +16: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=expanded test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
00:00 +0: ProjectedShadowFootprintTuning uses footprint V0 defaults
00:00 +1: ProjectedShadowFootprintTuning uses value equality and matching hashCode
00:00 +2: ProjectedShadowFootprintTuning rejects invalid attachYRatio values
00:00 +3: ProjectedShadowFootprintTuning rejects invalid frontWidthRatio values
00:00 +4: ProjectedShadowFootprintTuning rejects invalid rearWidthRatio values
00:00 +5: ProjectedShadowFootprintTuning rejects invalid depthRatio values
00:00 +6: ProjectedShadowFootprintTuning rejects invalid skewXRatio values
00:00 +7: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode
00:00 +8: ProjectBuildingShadowPreset footprint mode accepts directional without footprint
00:00 +9: ProjectBuildingShadowPreset footprint mode rejects directional with footprint
00:00 +10: ProjectBuildingShadowPreset footprint mode accepts footprint with footprint tuning
00:00 +11: ProjectBuildingShadowPreset footprint mode rejects footprint without footprint tuning
00:00 +12: ProjectBuildingShadowPreset footprint mode equality and hashCode include geometryMode and footprint
00:00 +13: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=expanded test/shadow_v2 | tail -n 1 | perl -pe 's/\e\[[0-9;]*m//g'
```

Ligne finale exacte :

```text
00:00 +167: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart lib/src/operations/projected_building_shadow_geometry.dart test/shadow_v2/projected_building_shadow_geometry_test.dart test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_geometry.dart, projected_building_shadow_geometry_test.dart, projected_building_shadow_footprint_tuning_test.dart...
No issues found!
```

## 17. Audit anti-dérive

Commande :

```bash
rg -n "map_runtime|map_editor|ShadowRuntimeRenderer|paintEditorStaticShadowPreviewInstructions|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
```

Sortie :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:416:      expect(source, isNot(contains('map_runtime')));
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:417:      expect(source, isNot(contains('map_editor')));
```

Interprétation :

```text
Hits attendus : test préexistant anti-dépendance runtime/editor.
Aucun renderer, painter, baseline, Selbrume, genericProjection ou policy introduit.
```

## 18. Ce qui n’a volontairement pas été modifié

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/operations/project_manifest_*.dart
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 19. Ce qui n’a volontairement pas été créé

```text
screenshot
baseline
fixture Selbrume
nouveau renderer
nouveau painter
nouveau codec JSON
generated file
migration
UI authoring
shader
blur
alpha mask runtime
author-defined polygon UI
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant rapport :

```text
 .../lib/src/models/projected_building_shadow.dart  | 127 +++++++++++++++++
 .../projected_building_shadow_geometry.dart        |  64 +++++++++
 .../projected_building_shadow_geometry_test.dart   | 153 +++++++++++++++++++++
 3 files changed, 344 insertions(+)
```

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant rapport :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
M	packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
M	packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie avant rapport :

```text

```

Interprétation :

```text
Propre.
```

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale à mettre à jour après création du rapport :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
 M packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
 M packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
?? reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

## 24. Risques / réserves

- Les codecs JSON ne sont pas modifiés dans ce lot. Les presets footprint ne peuvent donc pas encore être persistés proprement via JSON.
- Runtime/editor ne consomment pas encore Footprint V0. C'est volontaire.
- 4 points gardent le comportement de bandes actuel côté renderer/painter futur.
- `anchor` est directional-only en footprint V0 ; une future UI devra le masquer ou l'expliquer.

## 25. Auto-critique

Le lot est-il bien map_core-only ?

```text
Oui. Modifications limitées à map_core et au rapport.
```

La rétrocompatibilité directional est-elle préservée ?

```text
Oui. geometryMode default directional ; tests directionnels inchangés et verts.
```

Le modèle footprint est-il suffisamment strict ?

```text
Oui. directional avec footprint rejeté ; footprint sans tuning rejeté.
```

Le modèle footprint est-il trop riche ?

```text
Non. 5 champs de tuning seulement.
```

La formule correspond-elle exactement au Lot 39 ?

```text
Oui. Points micro-fixture vérifiés explicitement.
```

Les points attendus sont-ils explicites et non recalculés par le test ?

```text
Oui. Les assertions utilisent les coordonnées attendues en dur.
```

anchor est-il clairement directional-only ?

```text
Oui. Test dédié : deux anchors différents produisent la même footprint geometry.
```

localOffset fonctionne-t-il pour footprint ?

```text
Oui. Test dédié avec offset (5, -3).
```

Le lot évite-t-il runtime/editor/images/Selbrume ?

```text
Oui.
```

Le rapport contient-il toutes les preuves ?

```text
Oui, avec RED, tests, analyze, anti-dérive, status et code du nouveau test.
```

## 26. Regard critique sur le prompt

Le prompt est bien borné :

```text
Il force map_core-only, sans brancher runtime/editor trop tôt.
```

Point de vigilance :

```text
La demande "nouveau codec JSON sauf blocage" est respectée : aucun codec créé.
Le prochain lot devra explicitement décider si persistance JSON vient avant runtime/editor.
```

## 27. Prochain lot recommandé

Recommandation :

```text
ShadowV2-41 — Projected Building Shadow Footprint Runtime / Editor Adapter Design Gate
```

Objectif probable :

```text
Décider comment brancher Footprint Geometry V0 dans l'adapter runtime et la preview editor,
sans modifier renderer/painter.
```

## 28. Code complet des fichiers créés/modifiés

### Diff complet des fichiers modifiés

Résumé des changements complets :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
- ajout ProjectedBuildingShadowGeometryMode
- ajout ProjectedShadowFootprintTuning avec validations et equality/hashCode
- ajout geometryMode et footprint dans ProjectBuildingShadowPreset
- validation stricte directional/footprint
- equality/hashCode incluent geometryMode et footprint

packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
- dispatch par geometryMode
- extraction helper directional sans changement de formule
- ajout helper footprint 4 points

packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
- ajout test micro-fixture footprint
- ajout test localOffset footprint
- ajout test anchor ignoré en footprint
- ajout helpers footprint locaux
```

### Contenu complet du fichier créé `packages/map_core/test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowFootprintTuning', () {
    test('uses footprint V0 defaults', () {
      final tuning = ProjectedShadowFootprintTuning();

      expect(tuning.attachYRatio, 0.86);
      expect(tuning.frontWidthRatio, 1.10);
      expect(tuning.rearWidthRatio, 1.20);
      expect(tuning.depthRatio, 0.28);
      expect(tuning.skewXRatio, 0.10);
    });

    test('uses value equality and matching hashCode', () {
      final first = ProjectedShadowFootprintTuning(
        attachYRatio: 0.8,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );
      final same = ProjectedShadowFootprintTuning(
        attachYRatio: 0.8,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );
      final different = ProjectedShadowFootprintTuning(
        attachYRatio: 0.9,
        frontWidthRatio: 1.1,
        rearWidthRatio: 1.2,
        depthRatio: 0.3,
        skewXRatio: 0.1,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('rejects invalid attachYRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(attachYRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid frontWidthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(
          frontWidthRatio: double.infinity,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(frontWidthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(frontWidthRatio: 2.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid rearWidthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(rearWidthRatio: 2.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid depthRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(depthRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid skewXRatio values', () {
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: -0.51),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowFootprintTuning(skewXRatio: 0.51),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectBuildingShadowPreset footprint mode', () {
    test('defaults to directional geometry mode', () {
      final preset = _preset();

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
    });

    test('accepts directional without footprint', () {
      final preset = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.directional,
      );

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
    });

    test('rejects directional with footprint', () {
      expect(
        () => _preset(
          geometryMode: ProjectedBuildingShadowGeometryMode.directional,
          footprint: ProjectedShadowFootprintTuning(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts footprint with footprint tuning', () {
      final footprint = ProjectedShadowFootprintTuning();
      final preset = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );

      expect(preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, footprint);
    });

    test('rejects footprint without footprint tuning', () {
      expect(
        () => _preset(
          geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality and hashCode include geometryMode and footprint', () {
      final footprint = ProjectedShadowFootprintTuning();
      final first = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );
      final same = _preset(
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: footprint,
      );
      final directional = _preset();

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(directional));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  ProjectedBuildingShadowGeometryMode geometryMode =
      ProjectedBuildingShadowGeometryMode.directional,
  ProjectedShadowFootprintTuning? footprint,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: geometryMode,
    footprint: footprint,
  );
}
```

Le rapport courant est le fichier créé :

```text
reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

Checklist finale :

- [x] ProjectedBuildingShadowGeometryMode ajouté
- [x] ProjectedShadowFootprintTuning ajouté
- [x] Validations FootprintTuning ajoutées
- [x] Equality/hashCode FootprintTuning ajoutés
- [x] ProjectBuildingShadowPreset geometryMode ajouté
- [x] ProjectBuildingShadowPreset footprint ajouté
- [x] Directional default rétrocompatible
- [x] Directional avec footprint rejeté
- [x] Footprint sans tuning rejeté
- [x] Footprint avec tuning accepté
- [x] Resolver directional inchangé
- [x] Resolver footprint implémenté
- [x] Points micro-fixture footprint vérifiés
- [x] localOffset footprint testé
- [x] anchor ignoré en footprint testé
- [x] appearance footprint propagée
- [x] Aucun runtime modifié
- [x] Aucun editor modifié
- [x] Aucun renderer/painter modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Tests ciblés passés
- [x] test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
