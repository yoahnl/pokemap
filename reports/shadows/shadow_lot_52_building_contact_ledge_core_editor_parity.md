# Shadow-52 — Building Contact Ledge Core / Editor Preview Parity V0

## 1. Résumé du lot

Shadow-52 extrait la géométrie `building contact ledge` introduite côté runtime en Shadow-51 vers une opération pure `map_core`, puis fait consommer cette même opération par le runtime et la preview canvas éditeur.

Le résultat attendu est une parité runtime/editor pour les bâtiments : les ombres de bâtiments ne repassent plus par la projection longue générique dans l'éditeur, et la formule n'est plus dupliquée entre packages.

## 2. Design retenu

- `map_core` expose `resolveBuildingStaticShadowContactLedgeGeometry(...)`.
- L'opération retourne `ProjectedStaticShadowGeometry`, déjà utilisé par runtime/editor pour transporter un polygone 4 points.
- Les constantes Shadow-51 sont déplacées en constantes publiques `map_core` pour stabiliser le tuning.
- `map_runtime` continue de produire un `ShadowRuntimeRenderInstruction.projectedPolygon`, mais ses points viennent du helper core.
- `map_editor` continue de produire un `EditorStaticShadowPreviewInstruction.projectedPolygon`, mais les bâtiments utilisent le helper core.
- Les familles non-building continuent à utiliser `resolveProjectedStaticShadowGeometry(...)` et la preview horaire existante.
- Les bâtiments ignorent la direction/longueur de la preview horaire pour ne pas recréer de longues dalles diagonales, mais conservent le multiplicateur d'opacité de la preview.

## 3. Fichiers créés par Shadow-52

- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md`

## 4. Fichiers modifiés par Shadow-52

- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

## 5. Fichiers non modifiés explicitement

- Aucun modèle persistant `map_core/lib/src/models/**`.
- Aucun codec JSON Shadow.
- Aucun generated file `.g.dart` ou `.freezed.dart`.
- Aucun fichier `packages/map_gameplay/**`.
- Aucun fichier `packages/map_battle/**`.
- Aucun renderer runtime.
- Aucun painter editor.
- Aucun fichier `packages/map_editor/lib/src/ui/canvas/**`.
- Aucun panel UI.

## 6. Fichiers non suivis préexistants hors lot

Au début de l'implémentation, le worktree contenait déjà :

```text
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md
```

Ce fichier de plan n'a pas été modifié par l'implémentation Shadow-52.

## 7. Opération core ajoutée

Nouvelle API :

```dart
ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
});
```

Constantes exposées :

```dart
buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.55
buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.48
buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.30
buildingStaticShadowContactLedgeDepthRatio = 0.035
buildingStaticShadowContactLedgeMinDepth = 4.0
buildingStaticShadowContactLedgeMaxDepth = 14.0
buildingStaticShadowContactLedgeSkewRatio = 0.025
buildingStaticShadowContactLedgeMinSkew = 0.0
buildingStaticShadowContactLedgeMaxSkew = 8.0
```

## 8. Runtime extraction

`static_placed_element_shadow_runtime_resolver.dart` ne porte plus les constantes et helpers privés de contact ledge. Pour `StaticShadowFamily.building`, il appelle maintenant :

```dart
resolveBuildingStaticShadowContactLedgeGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
)
```

Le pipeline runtime reste inchangé : l'instruction finale reste un `projectedPolygon`, le renderer reste inchangé, et offset/scale sont toujours appliqués une seule fois via `baseGeometry`.

## 9. Editor preview parity

`editor_static_shadow_preview.dart` résout maintenant la famille une seule fois. Si la famille effective est `StaticShadowFamily.building`, il utilise `resolveBuildingStaticShadowContactLedgeGeometry(...)`. Sinon, il conserve la projection existante avec `resolveStaticShadowFamilyProjectionSpec(...)` et `_projectionSpecForEditorLightPreview(...)`.

Décision : la famille `building` ignore direction/longueur de la preview horaire, mais conserve l'opacité preview. Cela évite de recréer les longues ombres de bâtiments dans le canvas tout en gardant la comparaison de lisibilité.

## 10. Flame docs

`flame_docs` a été consulté pour le sujet `Flame component priority render order`, mais le serveur n'a renvoyé aucun résultat exploitable. Shadow-52 ne modifie aucune API Flame, aucun composant Flame, aucun ordre de rendu, et aucun renderer. L'implémentation respecte donc l'architecture PokeMap existante : calculs purs dans `map_core`, adaptation runtime dans `map_runtime`, preview editor dans `map_editor`.

## 11. Tests ajoutés/modifiés

Ajout :

- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`

Modifications :

- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
  - les attentes building utilisent maintenant le helper core.
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
  - building family vérifie le contact ledge core ;
  - override building family vérifie la même géométrie ;
  - preview morning conserve les points building mais applique l'opacité.

## 12. Commandes lancées et résultats

### Git / AGENTS

Commande :

```bash
find .. -name AGENTS.md -print
```

Résultat utile :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md
```

### RED core

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Résultat attendu avant implémentation :

```text
Failed to load "test/shadow/static_shadow_contact_ledge_geometry_test.dart":
Error: Undefined name 'buildingStaticShadowContactLedgeNearHalfWidthMultiplier'.
Error: Method not found: 'resolveBuildingStaticShadowContactLedgeGeometry'.
00:00 +0 -1: Some tests failed.
```

### GREEN core ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading test/shadow/static_shadow_contact_ledge_geometry_test.dart
00:00 +0: building static shadow contact ledge constants defaults match Shadow-51 runtime tuning
00:00 +1: building static shadow contact ledge constants defaults match Shadow-51 runtime tuning
00:00 +1: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge
00:00 +2: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge
00:00 +2: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-51 runtime formula exactly
00:00 +3: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-51 runtime formula exactly
00:00 +3: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width
00:00 +4: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width
00:00 +4: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry
00:00 +5: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry
00:00 +5: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth
00:00 +6: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth
00:00 +6: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew
00:00 +7: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew
00:00 +7: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite
00:00 +8: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite
00:00 +8: All tests passed!
```

### Runtime resolver ciblé

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat final exact :

```text
00:00 +37: All tests passed!
```

### Runtime collection ciblé

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat final exact :

```text
00:00 +26: All tests passed!
```

### Runtime shadow suite

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final exact :

```text
00:04 +233: All tests passed!
```

### Editor preview RED

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Résultat utile avant implémentation editor :

```text
buildEditorStaticShadowPreviewInstructions building family emits a contact ledge preview matching core [E]
Expected: a numeric value within <0.001> of <27.6>
  Actual: <31.275131833966412>

buildEditorStaticShadowPreviewInstructions override building family wins over element family in preview [E]
Expected: a numeric value within <0.001> of <27.6>
  Actual: <31.275131833966412>

buildEditorStaticShadowPreviewInstructions building contact ledge ignores light direction but keeps opacity preview [E]
Expected: [...neutral points...]
  Actual: [...morning projected points...]
00:00 +12 -3: Some tests failed.
```

### Editor preview ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Résultat final exact :

```text
00:00 +19: All tests passed!
```

### Editor painter ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Résultat final exact :

```text
00:00 +7: All tests passed!
```

### Editor application/shadow large

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat : échec hors Shadow-52 dans les tests d'auto-suggestion non modifiés par ce lot.

Échec complet utile :

```text
00:00 +11 -1: element_auto_shadow_backfill_test.dart: applyElementAutoShadowSuggestionsToProject applies suggestions to elements without shadow configs [E]
Expected: <0.18>
  Actual: <0.28>
test/application/shadow/element_auto_shadow_backfill_test.dart 39:7

00:00 +11 -2: element_auto_shadow_backfill_test.dart: applyElementAutoShadowSuggestionsToProject replaces generic pre-footprint active shadows [E]
Expected: <0.72>
  Actual: <0.58>
test/application/shadow/element_auto_shadow_backfill_test.dart 82:7

00:00 +62 -3: element_auto_shadow_suggestion_test.dart: buildElementAutoShadowSuggestion classifies tall thin elements as tallThin [E]
Expected: <0.18>
  Actual: <0.28>
test/application/shadow/element_auto_shadow_suggestion_test.dart 76:7

00:00 +62 -4: element_auto_shadow_suggestion_test.dart: buildElementAutoShadowSuggestion classifies large buildings as buildingLarge [E]
Expected: <0.92>
  Actual: <0.98>
test/application/shadow/element_auto_shadow_suggestion_test.dart 90:7

00:00 +62 -5: element_auto_shadow_suggestion_test.dart: buildElementAutoShadowSuggestion wide low needs enough surface to receive an automatic shadow [E]
Expected: <0.95>
  Actual: <0.98>
test/application/shadow/element_auto_shadow_suggestion_test.dart 111:7

00:00 +90 -5: Some tests failed.
```

Classification : dette préexistante / hors lot. Shadow-52 ne modifie aucun fichier `element_auto_shadow_*`. `git diff --name-only` ne liste que les fichiers Shadow-52.

### Core shadow suite

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final exact :

```text
00:00 +281: All tests passed!
```

### Analyse core

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat complet :

```text
Analyzing lib, shadow...
No issues found!
```

### Analyse runtime

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat complet :

```text
Analyzing 2 items...
No issues found! (ran in 2.3s)
```

### Analyse editor ciblée

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Résultat complet :

```text
Analyzing 3 items...
No issues found! (ran in 1.2s)
```

## 13. Scans anti-dérive

Commande :

```bash
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
```

Résultat : aucune sortie.

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
```

Résultat : aucune sortie.

Commande :

```bash
git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Résultat : aucune sortie.

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Résultat : aucune sortie.

Commande :

```bash
git diff --check
```

Résultat : aucune sortie.

## 14. git diff --stat

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../shadow/editor_static_shadow_preview.dart       | 30 ++++---
 .../shadow/editor_static_shadow_preview_test.dart  | 93 ++++++++++++++++++++--
 ...tic_placed_element_shadow_runtime_resolver.dart | 81 +------------------
 ...laced_element_shadow_runtime_resolver_test.dart | 66 ++++-----------
 5 files changed, 128 insertions(+), 143 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les nouveaux fichiers Shadow-52 sont inventoriés dans les sections 3 et 19.

## 15. git diff --name-status

```text
M	packages/map_core/lib/map_core.dart
M	packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
M	packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
M	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
M	packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

## 16. git status final

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
?? packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md
```

## 17. Non-objectifs respectés

- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun generated file.
- Aucun `build_runner`.
- Aucun changement Flame renderer/component.
- Aucun painter editor modifié.
- Aucun panel UI modifié.
- Aucune direction globale de lumière.
- Aucun `WorldLightState`, `ShadowLightProfile`, `LightDirection`, `timeOfDay`.
- Aucun `saveLayer`, `ImageFilter`, `drawAtlas`, `zOrder`, `zIndex`.
- Aucun import `map_runtime` dans `map_editor`.

## 18. Risques / réserves

- Shadow-52 améliore la parité runtime/editor pour les bâtiments, mais ne garantit pas encore le rendu final "Pokémon-like" sur tous les assets. Il réduit surtout une divergence technique et enlève les longues dalles de bâtiments côté editor.
- La suite large `map_editor test/application/shadow` échoue encore sur la politique d'auto-suggestion d'ombres. Les fichiers fautifs ne sont pas modifiés par Shadow-52 ; cette dette doit être traitée dans un lot dédié.
- Les ombres de familles non-building restent sur la projection polygonale existante.

## 19. Auto-review finale

- Ai-je extrait la formule building contact ledge vers `map_core` ? oui.
- Ai-je évité de dupliquer la formule dans `map_editor` ? oui.
- Ai-je fait consommer cette opération par le runtime ? oui.
- Ai-je fait consommer cette opération par la preview editor ? oui.
- Ai-je laissé les familles non-building utiliser la projection existante ? oui.
- Ai-je évité de changer le renderer runtime ? oui.
- Ai-je évité de changer le painter editor ? oui.
- Ai-je évité de modifier les modèles/codecs ? oui.
- Ai-je évité les generated files et `build_runner` ? oui.
- Ai-je documenté la dette de tests hors lot ? oui.

## 20. Regard critique sur le plan

Le plan était techniquement juste : le problème n'était pas d'ajouter un nouveau rendu, mais de centraliser la petite géométrie contact ledge. Le point délicat est que la suite large editor révèle une dette préexistante autour de l'auto-suggestion d'ombres ; corriger cette dette dans Shadow-52 aurait mélangé deux sujets différents.

## 21. Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`

```dart
import 'static_shadow_geometry.dart';
import 'static_shadow_projection_geometry.dart';

const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.55;
const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.48;
const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.30;
const buildingStaticShadowContactLedgeDepthRatio = 0.035;
const buildingStaticShadowContactLedgeMinDepth = 4.0;
const buildingStaticShadowContactLedgeMaxDepth = 14.0;
const buildingStaticShadowContactLedgeSkewRatio = 0.025;
const buildingStaticShadowContactLedgeMinSkew = 0.0;
const buildingStaticShadowContactLedgeMaxSkew = 8.0;

ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
}) {
  final centerX = baseGeometry.centerX;
  final nearY = baseGeometry.centerY -
      baseGeometry.height *
          buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
  final farY =
      baseGeometry.centerY + _buildingStaticShadowContactLedgeDepth(metrics);
  final nearHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
  final farHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
  final skewX = _buildingStaticShadowContactLedgeSkew(metrics);

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: centerX - nearHalfWidth,
      y: nearY,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: centerX + nearHalfWidth,
      y: nearY,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: centerX + skewX + farHalfWidth,
      y: farY,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: centerX + skewX - farHalfWidth,
      y: farY,
    ),
  );
}

double _buildingStaticShadowContactLedgeDepth(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    buildingStaticShadowContactLedgeMinDepth,
    buildingStaticShadowContactLedgeMaxDepth,
  );
}

double _buildingStaticShadowContactLedgeSkew(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    buildingStaticShadowContactLedgeMinSkew,
    buildingStaticShadowContactLedgeMaxSkew,
  );
}

double _clampDouble(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

```
### `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('building static shadow contact ledge constants', () {
    test('defaults match Shadow-51 runtime tuning', () {
      expect(buildingStaticShadowContactLedgeNearHalfWidthMultiplier, 0.55);
      expect(buildingStaticShadowContactLedgeFarHalfWidthMultiplier, 0.48);
      expect(buildingStaticShadowContactLedgeNearHeightOffsetMultiplier, 0.30);
      expect(buildingStaticShadowContactLedgeDepthRatio, 0.035);
      expect(buildingStaticShadowContactLedgeMinDepth, 4);
      expect(buildingStaticShadowContactLedgeMaxDepth, 14);
      expect(buildingStaticShadowContactLedgeSkewRatio, 0.025);
      expect(buildingStaticShadowContactLedgeMinSkew, 0);
      expect(buildingStaticShadowContactLedgeMaxSkew, 8);
    });
  });

  group('resolveBuildingStaticShadowContactLedgeGeometry', () {
    test('creates a shallow four point contact ledge', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      expect(geometry.points, hasLength(4));
      expect(geometry.nearLeft.y, closeTo(geometry.nearRight.y, 0.000001));
      expect(geometry.farLeft.y, closeTo(geometry.farRight.y, 0.000001));
      expect(geometry.farLeft.y, greaterThan(geometry.nearLeft.y));
      expect(geometry.farRight.y, greaterThan(geometry.nearRight.y));
      expect(_bounds(geometry).height, lessThan(18));
      expect(_bounds(geometry).width, lessThan(100));
    });

    test('matches the Shadow-51 runtime formula exactly', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final depth = _clamp(metrics.visualHeight * 0.035, 4, 14);
      final skew = _clamp(metrics.visualWidth * 0.025, 0, 8);
      expect(geometry.nearLeft.x,
          closeTo(base.centerX - base.width * 0.55, 0.000001));
      expect(geometry.nearLeft.y,
          closeTo(base.centerY - base.height * 0.30, 0.000001));
      expect(geometry.nearRight.x,
          closeTo(base.centerX + base.width * 0.55, 0.000001));
      expect(geometry.nearRight.y,
          closeTo(base.centerY - base.height * 0.30, 0.000001));
      expect(geometry.farRight.x,
          closeTo(base.centerX + skew + base.width * 0.48, 0.000001));
      expect(geometry.farRight.y, closeTo(base.centerY + depth, 0.000001));
      expect(geometry.farLeft.x,
          closeTo(base.centerX + skew - base.width * 0.48, 0.000001));
      expect(geometry.farLeft.y, closeTo(base.centerY + depth, 0.000001));
    });

    test('uses base footprint width', () {
      final metrics = _metrics();
      final narrow = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.25),
        metrics: metrics,
      );
      final wide = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.75),
        metrics: metrics,
      );

      expect(_bounds(narrow).width, lessThan(_bounds(wide).width));
    });

    test('applies offset and scale only through base geometry', () {
      final metrics = _metrics();
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final nearCenterX = (geometry.nearLeft.x + geometry.nearRight.x) / 2;
      expect(nearCenterX, closeTo(base.centerX, 0.000001));
      expect(_bounds(geometry).width, greaterThan(base.width));
      expect(_bounds(geometry).height, lessThan(18));
    });

    test('clamps minimum and maximum depth', () {
      final small = _metrics(visualHeight: 24);
      final large = _metrics(visualHeight: 800);

      final smallGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(small),
        metrics: small,
      );
      final largeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(large),
        metrics: large,
      );

      expect(
        smallGeometry.farLeft.y - _base(small).centerY,
        closeTo(4, 0.000001),
      );
      expect(
        largeGeometry.farLeft.y - _base(large).centerY,
        closeTo(14, 0.000001),
      );
    });

    test('clamps maximum skew', () {
      final metrics = _metrics(visualWidth: 640);
      final base = _base(metrics);

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final farCenterX = (geometry.farLeft.x + geometry.farRight.x) / 2;
      expect(farCenterX - base.centerX, closeTo(8, 0.000001));
    });

    test('geometry is immutable and all points are finite', () {
      final metrics = _metrics();
      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics),
        metrics: metrics,
      );

      for (final point in geometry.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
      expect(() => geometry.points.add(ProjectedStaticShadowPoint(x: 0, y: 0)),
          throwsUnsupportedError);
    });
  });
}

StaticShadowVisualMetrics _metrics({
  double left = 80,
  double top = 120,
  double visualWidth = 40,
  double visualHeight = 60,
}) {
  return StaticShadowVisualMetrics(
    left: left,
    top: top,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
}

ResolvedStaticShadowGeometry _base(
  StaticShadowVisualMetrics metrics, {
  double footprintWidthRatio = 0.5,
}) {
  return resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: _shadowConfig(),
    elementFootprint: StaticShadowFootprintConfig(
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: 0.2,
    ),
  );
}

ResolvedShadowConfig _shadowConfig({
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'test-shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: 1,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

_TestBounds _bounds(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _TestBounds(width: maxX - minX, height: maxY - minY);
}

double _clamp(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

final class _TestBounds {
  const _TestBounds({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

```
### `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
export 'src/operations/element_auto_shadow_policy.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';

```
### `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';
import 'shadow_runtime_resolver.dart';

/// Runtime static element metrics used to derive a ground shadow anchor.
///
/// The default ratios and multipliers are V0 heuristics for common static
/// props. They are intentionally adjustable once real rendered shadows can be
/// evaluated.
final class StaticPlacedElementShadowRuntimeMetrics {
  StaticPlacedElementShadowRuntimeMetrics({
    required this.worldLeft,
    required this.worldTop,
    required this.visualWidth,
    required this.visualHeight,
    this.anchorXRatio = 0.5,
    this.anchorYRatio = 1.0,
    this.baseWidthMultiplier = 0.75,
    this.baseHeightMultiplier = 0.25,
  }) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
    _validateRatio(anchorXRatio, 'anchorXRatio');
    _validateRatio(anchorYRatio, 'anchorYRatio');
    _validatePositiveFinite(baseWidthMultiplier, 'baseWidthMultiplier');
    _validatePositiveFinite(baseHeightMultiplier, 'baseHeightMultiplier');
  }

  final double worldLeft;
  final double worldTop;
  final double visualWidth;
  final double visualHeight;
  final double anchorXRatio;
  final double anchorYRatio;
  final double baseWidthMultiplier;
  final double baseHeightMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeMetrics &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.anchorXRatio == anchorXRatio &&
          other.anchorYRatio == anchorYRatio &&
          other.baseWidthMultiplier == baseWidthMultiplier &&
          other.baseHeightMultiplier == baseHeightMultiplier;

  @override
  int get hashCode => Object.hash(
        worldLeft,
        worldTop,
        visualWidth,
        visualHeight,
        anchorXRatio,
        anchorYRatio,
        baseWidthMultiplier,
        baseHeightMultiplier,
      );
}

/// Single static placed element shadow resolution request.
final class StaticPlacedElementShadowRuntimeInput {
  const StaticPlacedElementShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
    this.elementFootprint,
    this.overrideFootprint,
    this.elementFamily,
    this.overrideFamily,
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final StaticShadowFootprintConfig? elementFootprint;
  final StaticShadowFootprintConfig? overrideFootprint;
  final StaticShadowFamily? elementFamily;
  final StaticShadowFamily? overrideFamily;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics &&
          other.elementFootprint == elementFootprint &&
          other.overrideFootprint == overrideFootprint &&
          other.elementFamily == elementFamily &&
          other.overrideFamily == overrideFamily;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
        elementFootprint,
        overrideFootprint,
        elementFamily,
        overrideFamily,
      );
}

ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics, {
  ResolvedShadowConfig? shadowConfig,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: metrics,
    elementFootprint: elementFootprint,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: _visualMetricsFromRuntimeMetrics(metrics),
    shadowConfig: shadowConfig ?? _identityShadowConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: overrideFootprint,
  );

  return ShadowRuntimeAnchor(
    worldX: geometry.anchorX,
    worldY: geometry.anchorY,
    baseWidth: geometry.baseWidth,
    baseHeight: geometry.baseHeight,
  );
}

ShadowRuntimeRenderInstruction?
    resolveStaticPlacedElementShadowRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }
  if (resolved.renderPass != ShadowRenderPass.groundStatic) {
    throw const ValidationException(
      'Static placed element shadow resolver requires groundStatic render pass',
    );
  }
  if (resolved.mode != ShadowCasterMode.ellipse &&
      resolved.mode != ShadowCasterMode.contactBlob) {
    throw const ValidationException(
      'Static placed element shadow resolver requires ellipse or contactBlob mode',
    );
  }

  final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
  final family = resolveStaticShadowFamily(
    elementFamily: input.elementFamily,
    overrideFamily: input.overrideFamily,
  );
  if (family == StaticShadowFamily.building) {
    return _resolveBuildingContactLedgeRuntimeInstruction(
      input,
      baseGeometry,
    );
  }

  final projectedGeometry = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: family,
    ),
  );
  final points = _runtimePointsFromProjection(projectedGeometry);
  final bounds = _boundsFromRuntimePoints(points);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: resolved.renderPass,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: resolved.opacity,
    colorHexRgb: resolved.colorHexRgb,
    softnessMode: resolved.softnessMode,
    polygonPoints: points,
  );
}

List<ShadowRuntimeRenderInstruction>
    resolveStaticPlacedElementShadowRuntimeInstructions(
  Iterable<StaticPlacedElementShadowRuntimeInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction =
        resolveStaticPlacedElementShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

ShadowRuntimeRenderInstruction _resolveBuildingContactLedgeRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
  ResolvedStaticShadowGeometry baseGeometry,
) {
  final ledgeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
    baseGeometry: baseGeometry,
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
  );
  final points = _runtimePointsFromProjection(ledgeGeometry);
  final bounds = _boundsFromRuntimePoints(points);
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: input.resolvedConfig.renderPass,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: input.resolvedConfig.opacity,
    colorHexRgb: input.resolvedConfig.colorHexRgb,
    softnessMode: input.resolvedConfig.softnessMode,
    polygonPoints: points,
  );
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be greater than 0',
    );
  }
}

void _validateRatio(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be between 0 and 1',
    );
  }
}

StaticShadowFootprintConfig _legacyFootprintFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowFootprintConfig(
    anchorXRatio: metrics.anchorXRatio,
    anchorYRatio: metrics.anchorYRatio,
    footprintWidthRatio: metrics.baseWidthMultiplier,
    footprintHeightRatio: metrics.baseHeightMultiplier,
  );
}

StaticShadowFootprintConfig _mergeLegacyAndElementFootprint({
  required StaticPlacedElementShadowRuntimeMetrics metrics,
  required StaticShadowFootprintConfig? elementFootprint,
}) {
  final resolved = resolveStaticShadowFootprint(
    elementFootprint: _legacyFootprintFromMetrics(metrics),
    overrideFootprint: elementFootprint,
  );
  return StaticShadowFootprintConfig(
    anchorXRatio: resolved.anchorXRatio,
    anchorYRatio: resolved.anchorYRatio,
    footprintWidthRatio: resolved.footprintWidthRatio,
    footprintHeightRatio: resolved.footprintHeightRatio,
  );
}

ResolvedStaticShadowGeometry _resolveStaticPlacedElementBaseGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: input.metrics,
    elementFootprint: input.elementFootprint,
  );
  return resolveStaticShadowGeometry(
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
    shadowConfig: input.resolvedConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: input.overrideFootprint,
  );
}

StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowVisualMetrics(
    left: metrics.worldLeft,
    top: metrics.worldTop,
    visualWidth: metrics.visualWidth,
    visualHeight: metrics.visualHeight,
  );
}

List<ShadowRuntimePoint> _runtimePointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<ShadowRuntimePoint>.unmodifiable(
    geometry.points.map(
      (point) => ShadowRuntimePoint(
        worldX: point.x,
        worldY: point.y,
      ),
    ),
  );
}

_ProjectedRuntimeShadowBounds _boundsFromRuntimePoints(
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
  return _ProjectedRuntimeShadowBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _ProjectedRuntimeShadowBounds {
  const _ProjectedRuntimeShadowBounds({
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

const _identityShadowConfig = ResolvedShadowConfig(
  shadowProfileId: 'runtime-static-shadow-anchor',
  mode: ShadowCasterMode.ellipse,
  renderPass: ShadowRenderPass.groundStatic,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 1,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
);

```
### `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('StaticPlacedElementShadowRuntimeMetrics', () {
    test('creates valid metrics with default ratios and multipliers', () {
      final metrics = _metrics();

      expect(metrics.worldLeft, 80);
      expect(metrics.worldTop, 120);
      expect(metrics.visualWidth, 40);
      expect(metrics.visualHeight, 60);
      expect(metrics.anchorXRatio, 0.5);
      expect(metrics.anchorYRatio, 1.0);
      expect(metrics.baseWidthMultiplier, 0.75);
      expect(metrics.baseHeightMultiplier, 0.25);
    });

    test('accepts custom valid ratios and multipliers', () {
      final metrics = _metrics(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        baseWidthMultiplier: 0.5,
        baseHeightMultiplier: 0.125,
      );

      expect(metrics.anchorXRatio, 0.25);
      expect(metrics.anchorYRatio, 0.75);
      expect(metrics.baseWidthMultiplier, 0.5);
      expect(metrics.baseHeightMultiplier, 0.125);
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _metrics(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid visual dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualWidth: width),
          throwsA(isA<ValidationException>()),
          reason: 'visualWidth $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualHeight: height),
          throwsA(isA<ValidationException>()),
          reason: 'visualHeight $height should be rejected',
        );
      }
    });

    test('rejects invalid anchor ratios', () {
      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorXRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorXRatio $ratio should be rejected',
        );
      }

      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorYRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorYRatio $ratio should be rejected',
        );
      }
    });

    test('rejects invalid base multipliers', () {
      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseWidthMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseWidthMultiplier $multiplier should be rejected',
        );
      }

      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseHeightMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseHeightMultiplier $multiplier should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _metrics();
      final b = _metrics();
      final c = _metrics(worldLeft: 81);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('StaticPlacedElementShadowRuntimeInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(metrics: _metrics(worldLeft: 81));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality includes element and override footprints', () {
      final a = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final b = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final c = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality includes element and override families', () {
      final a = _input(
        elementFamily: StaticShadowFamily.tallProp,
        overrideFamily: StaticShadowFamily.building,
      );
      final b = _input(
        elementFamily: StaticShadowFamily.tallProp,
        overrideFamily: StaticShadowFamily.building,
      );
      final c = _input(
        elementFamily: StaticShadowFamily.compactProp,
        overrideFamily: StaticShadowFamily.building,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('staticPlacedElementShadowAnchorFromMetrics', () {
    test('converts static metrics into a runtime anchor', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(_metrics());

      expect(anchor, isA<ShadowRuntimeAnchor>());
      expect(anchor.worldX, closeTo(100, 0.000001));
      expect(anchor.worldY, closeTo(180, 0.000001));
      expect(anchor.baseWidth, closeTo(30, 0.000001));
      expect(anchor.baseHeight, closeTo(15, 0.000001));
    });

    test('preserves custom legacy metrics ratios and multipliers', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(165, 0.000001));
      expect(anchor.baseWidth, closeTo(20, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('element footprint overrides legacy metrics field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('override footprint wins over element footprint field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
        overrideFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
    test('resolves ellipse groundStatic into a projected polygon instruction',
        () {
      final input = _input();
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      _expectInstructionMatchesProjectedGeometry(instruction, input);
    });

    test(
        'resolves contactBlob groundStatic into a projected polygon instruction',
        () {
      final input = _input(
        resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      _expectInstructionMatchesProjectedGeometry(instruction, input);
    });

    test('applies static metrics and Shadow-12 offset/scale geometry', () {
      final input = _input();
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
      _expectAllPointsInsideBounds(instruction);
    });

    test('applies offset and scale once after core footprint geometry', () {
      final input = _input(
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.25,
        ),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('custom override without footprint keeps element footprint', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(offsetX: 4),
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('building family emits a short contact ledge polygon', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(
          offsetX: 0,
          offsetY: 0,
          scaleX: 0.72,
          scaleY: 0.44,
        ),
        metrics: _metrics(
          worldLeft: 160,
          worldTop: 96,
          visualWidth: 192,
          visualHeight: 224,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
        elementFamily: StaticShadowFamily.building,
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesBuildingContactLedge(instruction!, input);
      expect(instruction.height, lessThan(18));
      expect(instruction.width, lessThan(100));
    });

    test('building contact ledge uses resolved footprint width', () {
      final narrow = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final wide = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      _expectBuildingContactLedgeShape(narrow);
      _expectBuildingContactLedgeShape(wide);
      expect(narrow.width, lessThan(wide.width));
    });

    test('building contact ledge applies offset and scale once', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFamily: StaticShadowFamily.building,
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesBuildingContactLedge(instruction!, input);
    });

    test('non-building family keeps projected shadow geometry', () {
      final input = _input(
        elementFamily: StaticShadowFamily.tallProp,
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.25,
          footprintHeightRatio: 0.08,
        ),
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('element family changes the projected shadow silhouette', () {
      final tallProp = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.tallProp,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final building = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      expect(tallProp.width, lessThan(building.width));
      expect(tallProp.polygonPoints, isNot(building.polygonPoints));
    });

    test('override family wins over element family', () {
      final overrideBuilding =
          resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.tallProp,
          overrideFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final building = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      expect(overrideBuilding.width, closeTo(building.width, 0.000001));
      expect(overrideBuilding.height, closeTo(building.height, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            opacity: 0.7,
            colorHexRgb: '0a0b0c',
            softnessMode: ShadowSoftnessMode.hardEdge,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0.7);
      expect(instruction.colorHexRgb, '0A0B0C');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none before render pass checks',
        () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            mode: ShadowCasterMode.none,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
      );

      expect(instruction, isNull);
    });

    test('rejects actorContact render pass', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(
            resolvedConfig: _resolvedConfig(
              renderPass: ShadowRenderPass.actorContact,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(resolvedConfig: _resolvedConfig(scaleX: -1)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveStaticPlacedElementShadowRuntimeInstructions(const []),
          isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(
        instructions.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
    });

    test('preserves input order without sorting', () {
      final first = _input(
        metrics: _metrics(worldLeft: 80),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );
      final second = _input(
        metrics: _metrics(worldLeft: 200),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        first,
        second,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].worldLeft, lessThan(instructions[1].worldLeft));
    });

    test('ignores mode none inputs', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(
        instructions.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('does not deduplicate equal inputs', () {
      final input = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
        input,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0], instructions[1]);
    });

    test('does not modify inputs and exposes an unmodifiable list', () {
      final input = _input();
      final before = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
      ]);

      expect(input, before);
      expect(
        () => instructions.add(
          resolveStaticPlacedElementShadowRuntimeInstruction(_input())!,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

StaticPlacedElementShadowRuntimeMetrics _metrics({
  double worldLeft = 80,
  double worldTop = 120,
  double visualWidth = 40,
  double visualHeight = 60,
  double anchorXRatio = 0.5,
  double anchorYRatio = 1.0,
  double baseWidthMultiplier = 0.75,
  double baseHeightMultiplier = 0.25,
}) {
  return StaticPlacedElementShadowRuntimeMetrics(
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    anchorXRatio: anchorXRatio,
    anchorYRatio: anchorYRatio,
    baseWidthMultiplier: baseWidthMultiplier,
    baseHeightMultiplier: baseHeightMultiplier,
  );
}

StaticPlacedElementShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
    elementFamily: elementFamily,
    overrideFamily: overrideFamily,
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'tree_large',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 6,
  double offsetY = 10,
  double scaleX = 1.2,
  double scaleY = 0.5,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: shadowProfileId,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

void _expectInstructionMatchesProjectedGeometry(
  ShadowRuntimeRenderInstruction instruction,
  StaticPlacedElementShadowRuntimeInput input,
) {
  final expected = _expectedProjectedGeometry(input);
  final expectedPoints = expected.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList();

  expect(instruction.polygonPoints, hasLength(expectedPoints.length));
  for (var i = 0; i < expectedPoints.length; i += 1) {
    expect(
      instruction.polygonPoints[i].worldX,
      closeTo(expectedPoints[i].worldX, 0.000001),
    );
    expect(
      instruction.polygonPoints[i].worldY,
      closeTo(expectedPoints[i].worldY, 0.000001),
    );
  }

  final expectedBounds = _boundsFromPoints(expectedPoints);
  expect(instruction.worldLeft, closeTo(expectedBounds.left, 0.000001));
  expect(instruction.worldTop, closeTo(expectedBounds.top, 0.000001));
  expect(instruction.width, closeTo(expectedBounds.width, 0.000001));
  expect(instruction.height, closeTo(expectedBounds.height, 0.000001));
}

void _expectAllPointsInsideBounds(ShadowRuntimeRenderInstruction instruction) {
  for (final point in instruction.polygonPoints) {
    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
    expect(
      point.worldX,
      lessThanOrEqualTo(instruction.worldLeft + instruction.width),
    );
    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
    expect(
      point.worldY,
      lessThanOrEqualTo(instruction.worldTop + instruction.height),
    );
  }
}

ProjectedStaticShadowGeometry _expectedProjectedGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final legacyAndElementFootprint = resolveStaticShadowFootprint(
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: metrics.anchorXRatio,
      anchorYRatio: metrics.anchorYRatio,
      footprintWidthRatio: metrics.baseWidthMultiplier,
      footprintHeightRatio: metrics.baseHeightMultiplier,
    ),
    overrideFootprint: input.elementFootprint,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    shadowConfig: input.resolvedConfig,
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: legacyAndElementFootprint.anchorXRatio,
      anchorYRatio: legacyAndElementFootprint.anchorYRatio,
      footprintWidthRatio: legacyAndElementFootprint.footprintWidthRatio,
      footprintHeightRatio: legacyAndElementFootprint.footprintHeightRatio,
    ),
    overrideFootprint: input.overrideFootprint,
  );
  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: resolveStaticShadowFamily(
        elementFamily: input.elementFamily,
        overrideFamily: input.overrideFamily,
      ),
    ),
  );
}

void _expectInstructionMatchesBuildingContactLedge(
  ShadowRuntimeRenderInstruction instruction,
  StaticPlacedElementShadowRuntimeInput input,
) {
  _expectBuildingContactLedgeShape(instruction);
  final expectedPoints = _expectedBuildingContactLedgePoints(input);

  expect(instruction.polygonPoints, hasLength(expectedPoints.length));
  for (var i = 0; i < expectedPoints.length; i += 1) {
    expect(
      instruction.polygonPoints[i].worldX,
      closeTo(expectedPoints[i].worldX, 0.000001),
    );
    expect(
      instruction.polygonPoints[i].worldY,
      closeTo(expectedPoints[i].worldY, 0.000001),
    );
  }

  final expectedBounds = _boundsFromPoints(expectedPoints);
  expect(instruction.worldLeft, closeTo(expectedBounds.left, 0.000001));
  expect(instruction.worldTop, closeTo(expectedBounds.top, 0.000001));
  expect(instruction.width, closeTo(expectedBounds.width, 0.000001));
  expect(instruction.height, closeTo(expectedBounds.height, 0.000001));
}

void _expectBuildingContactLedgeShape(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.polygonPoints, hasLength(4));
  final points = instruction.polygonPoints;
  expect(points[0].worldY, closeTo(points[1].worldY, 0.000001));
  expect(points[2].worldY, closeTo(points[3].worldY, 0.000001));
  expect(points[2].worldY, greaterThan(points[0].worldY));
  expect(points[3].worldY, greaterThan(points[1].worldY));
  _expectAllPointsInsideBounds(instruction);
}

List<ShadowRuntimePoint> _expectedBuildingContactLedgePoints(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
    baseGeometry: _expectedBaseGeometry(input),
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
  );
  return geometry.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList();
}

ResolvedStaticShadowGeometry _expectedBaseGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final legacyAndElementFootprint = resolveStaticShadowFootprint(
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: metrics.anchorXRatio,
      anchorYRatio: metrics.anchorYRatio,
      footprintWidthRatio: metrics.baseWidthMultiplier,
      footprintHeightRatio: metrics.baseHeightMultiplier,
    ),
    overrideFootprint: input.elementFootprint,
  );
  return resolveStaticShadowGeometry(
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    shadowConfig: input.resolvedConfig,
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: legacyAndElementFootprint.anchorXRatio,
      anchorYRatio: legacyAndElementFootprint.anchorYRatio,
      footprintWidthRatio: legacyAndElementFootprint.footprintWidthRatio,
      footprintHeightRatio: legacyAndElementFootprint.footprintHeightRatio,
    ),
    overrideFootprint: input.overrideFootprint,
  );
}

_RuntimeTestBounds _boundsFromPoints(List<ShadowRuntimePoint> points) {
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
  return _RuntimeTestBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _RuntimeTestBounds {
  const _RuntimeTestBounds({
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
### `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`

```dart
import 'package:map_core/map_core.dart';

import 'editor_shadow_light_preview.dart';

enum EditorStaticShadowPreviewShapeKind {
  oval,
  projectedPolygon,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class EditorStaticShadowPreviewPoint {
  EditorStaticShadowPreviewPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'EditorStaticShadowPreviewPoint.x');
    _validateFinite(y, 'EditorStaticShadowPreviewPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class EditorStaticShadowPreviewInstruction {
  EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
    Iterable<EditorStaticShadowPreviewPoint> polygonPoints = const [],
  }) : polygonPoints =
            List<EditorStaticShadowPreviewPoint>.unmodifiable(polygonPoints) {
    _validateNonBlank(
      instanceId,
      'EditorStaticShadowPreviewInstruction.instanceId',
    );
    _validateNonBlank(
      elementId,
      'EditorStaticShadowPreviewInstruction.elementId',
    );
    _validateFinite(left, 'EditorStaticShadowPreviewInstruction.left');
    _validateFinite(top, 'EditorStaticShadowPreviewInstruction.top');
    _validatePositiveFinite(
      width,
      'EditorStaticShadowPreviewInstruction.width',
    );
    _validatePositiveFinite(
      height,
      'EditorStaticShadowPreviewInstruction.height',
    );
    _validateOpacity(opacity);
    _validateColorHexRgb(colorHexRgb);
    _validatePreviewPolygon(shape, this.polygonPoints);
  }

  final String instanceId;
  final String elementId;
  final EditorStaticShadowPreviewShapeKind shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final List<EditorStaticShadowPreviewPoint> polygonPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewInstruction &&
          other.instanceId == instanceId &&
          other.elementId == elementId &&
          other.shape == shape &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          _previewPointsEqual(other.polygonPoints, polygonPoints);

  @override
  int get hashCode => Object.hash(
        instanceId,
        elementId,
        shape,
        left,
        top,
        width,
        height,
        opacity,
        colorHexRgb,
        Object.hashAll(polygonPoints),
      );
}

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
  EditorShadowLightPreviewPreset? lightPreviewPreset,
}) {
  if (!tileWidth.isFinite ||
      !tileHeight.isFinite ||
      tileWidth <= 0 ||
      tileHeight <= 0 ||
      map.placedElements.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty || visibleTileLayerById.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final instructions = <EditorStaticShadowPreviewInstruction>[];
  final resolvedLightPreviewPreset =
      lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
  for (final placed in map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final resolution = resolveShadowConfig(
      catalog: manifest.shadowCatalog,
      elementShadow: element.shadow,
      placedOverride: placed.shadowOverride,
    );
    final resolved = resolution.resolved;
    if (resolved == null ||
        resolved.renderPass != ShadowRenderPass.groundStatic ||
        resolved.mode == ShadowCasterMode.none) {
      continue;
    }

    final visualWidth = source.width * tileWidth;
    final visualHeight = source.height * tileHeight;
    final baseLeft = placed.pos.x * tileWidth;
    final baseTop = placed.pos.y * tileHeight;
    final metrics = StaticShadowVisualMetrics(
      left: baseLeft,
      top: baseTop,
      visualWidth: visualWidth,
      visualHeight: visualHeight,
    );
    final geometry = resolveStaticShadowGeometry(
      metrics: metrics,
      shadowConfig: resolved,
      elementFootprint: element.shadow?.footprint,
      overrideFootprint: placed.shadowOverride?.footprint,
    );
    final family = resolveStaticShadowFamily(
      elementFamily: element.shadow?.family,
      overrideFamily: placed.shadowOverride?.family,
    );
    final projectedGeometry = family == StaticShadowFamily.building
        ? resolveBuildingStaticShadowContactLedgeGeometry(
            baseGeometry: geometry,
            metrics: metrics,
          )
        : resolveProjectedStaticShadowGeometry(
            baseGeometry: geometry,
            metrics: metrics,
            projectionSpec: resolveStaticShadowFamilyProjectionSpec(
              family: family,
              baseProjectionSpec: _projectionSpecForEditorLightPreview(
                resolvedLightPreviewPreset,
              ),
            ),
          );
    final points = _editorPreviewPointsFromProjection(projectedGeometry);
    final bounds = _boundsFromEditorPreviewPoints(points);

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
        opacity: _opacityForEditorLightPreview(
          resolved.opacity,
          resolvedLightPreviewPreset,
        ),
        colorHexRgb: resolved.colorHexRgb,
        polygonPoints: points,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}

StaticShadowProjectionSpec _projectionSpecForEditorLightPreview(
  EditorShadowLightPreviewPreset preset,
) {
  final hasDirection = preset.directionX != 0 || preset.directionY != 0;
  final lengthRatio = preset.lengthMultiplier > 0
      ? preset.lengthMultiplier
      : defaultStaticShadowProjectionLengthRatio * preset.scaleYMultiplier;

  return StaticShadowProjectionSpec(
    directionX: hasDirection
        ? preset.directionX
        : defaultStaticShadowProjectionDirectionX,
    directionY: hasDirection
        ? preset.directionY
        : defaultStaticShadowProjectionDirectionY,
    lengthRatio: lengthRatio,
    nearWidthMultiplier: defaultStaticShadowProjectionNearWidthMultiplier *
        preset.scaleXMultiplier,
    farWidthMultiplier: defaultStaticShadowProjectionFarWidthMultiplier *
        preset.scaleXMultiplier,
  );
}

double _opacityForEditorLightPreview(
  double opacity,
  EditorShadowLightPreviewPreset preset,
) {
  final nextOpacity = opacity * preset.opacityMultiplier;
  if (nextOpacity < 0) {
    return 0;
  }
  if (nextOpacity > 1) {
    return 1;
  }
  return nextOpacity;
}

List<EditorStaticShadowPreviewPoint> _editorPreviewPointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<EditorStaticShadowPreviewPoint>.unmodifiable(
    geometry.points.map(
      (point) => EditorStaticShadowPreviewPoint(x: point.x, y: point.y),
    ),
  );
}

_EditorStaticShadowPreviewBounds _boundsFromEditorPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _EditorStaticShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _EditorStaticShadowPreviewBounds {
  const _EditorStaticShadowPreviewBounds({
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

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException('$name must not be blank');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be greater than 0');
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'EditorStaticShadowPreviewInstruction.opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
}

void _validatePreviewPolygon(
  EditorStaticShadowPreviewShapeKind shape,
  List<EditorStaticShadowPreviewPoint> points,
) {
  switch (shape) {
    case EditorStaticShadowPreviewShapeKind.oval:
      if (points.isNotEmpty) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction polygonPoints are only allowed for projectedPolygon',
        );
      }
    case EditorStaticShadowPreviewShapeKind.projectedPolygon:
      if (points.length < 3) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon requires at least 3 points',
        );
      }
      if (_previewPolygonArea(points) <= 0) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon must be non-degenerate',
        );
      }
  }
}

double _previewPolygonArea(List<EditorStaticShadowPreviewPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

bool _previewPointsEqual(
  List<EditorStaticShadowPreviewPoint> a,
  List<EditorStaticShadowPreviewPoint> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

```
### `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_light_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorStaticShadowPreviewInstructions', () {
    test('builds a projected groundStatic instruction', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.instanceId, 'layer::1::2');
      expect(instruction.elementId, 'stand');
      expect(instruction.colorHexRgb, '000000');
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('neutral light preview matches the runtime default projection', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('noon light preview shortens the projected polygon once', () {
      final neutral = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      ).single;
      final noon = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('noon'),
      ).single;

      expect(_projectionLength(noon), lessThan(_projectionLength(neutral)));
      expect(noon.opacity, lessThan(neutral.opacity));
    });

    test('morning and evening light previews shift in opposite directions', () {
      final morning = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
      ).single;
      final evening = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('evening'),
      ).single;

      expect(_farCenterX(morning), greaterThan(_nearCenterX(morning)));
      expect(_farCenterX(evening), lessThan(_nearCenterX(evening)));
      expect(_farCenterY(morning), greaterThan(_nearCenterY(morning)));
      expect(_farCenterY(evening), greaterThan(_nearCenterY(evening)));
    });

    test('contactBlob groundStatic produces a projected preview instruction',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          profile: _profile(
            'base_shadow',
            mode: ShadowCasterMode.contactBlob,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(
        instructions.single.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
    });

    test('ignores empty catalog and missing profiles', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(catalog: const ProjectShadowCatalog.empty()),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            elementShadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing',
            ),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
    });

    test('ignores missing disabled incompatible and invalid sources', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(omitElementShadow: true),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            elementShadow: ProjectElementShadowConfig(castsShadow: false),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            profile: _profile(
              'base_shadow',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            profile: _profile('base_shadow', mode: ShadowCasterMode.none),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(frames: const []),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0),
              ),
            ],
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
    });

    test('ignores invisible tile layers', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(layerVisible: false),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, isEmpty);
    });

    test('applies disabled and custom overrides', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(),
          map: _map(
            shadowOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );

      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 4,
            offsetY: -2,
            scaleX: 2,
            scaleY: 0.5,
            opacity: 0.2,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(
          offsetX: 4,
          offsetY: -2,
          scaleX: 2,
          scaleY: 0.5,
          opacity: 0.2,
        ),
        metrics: _defaultMetrics(),
        opacity: 0.2,
      );
    });

    test('uses element footprint for preview anchor and size', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.25,
              anchorYRatio: 0.75,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.125,
            ),
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
      );
    });

    test('uses override footprint over element footprint field by field', () {
      final elementFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.125,
      );
      final overrideFootprint = StaticShadowFootprintConfig(
        anchorYRatio: 0.5,
        footprintWidthRatio: 0.25,
      );
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: elementFootprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            footprint: overrideFootprint,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: elementFootprint,
        overrideFootprint: overrideFootprint,
      );
    });

    test('custom override without footprint keeps element footprint', () {
      final elementFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.5,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.5,
      );
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: elementFootprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 4,
            offsetY: -2,
            scaleX: 2,
            scaleY: 0.5,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(
          offsetX: 4,
          offsetY: -2,
          scaleX: 2,
          scaleY: 0.5,
        ),
        metrics: _defaultMetrics(),
        elementFootprint: elementFootprint,
      );
    });

    test('building family emits a contact ledge preview matching core', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final tallProp = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.tallProp,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;
      final building = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.building,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      _expectBuildingInstructionMatchesCoreContactLedge(
        instruction: building,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: footprint,
      );
      expect(tallProp.polygonPoints, isNot(building.polygonPoints));
    });

    test('override building family wins over element family in preview', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final overrideBuilding = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.tallProp,
            footprint: footprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            family: StaticShadowFamily.building,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;
      final building = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.building,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      _expectBuildingInstructionMatchesCoreContactLedge(
        instruction: overrideBuilding,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: footprint,
      );
      expect(overrideBuilding.polygonPoints, building.polygonPoints);
    });

    test(
        'building contact ledge ignores light direction but keeps opacity preview',
        () {
      final manifest = _manifest(
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'base_shadow',
          family: StaticShadowFamily.building,
          footprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      );
      final neutral = buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      ).single;
      final morning = buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
      ).single;

      expect(morning.polygonPoints, neutral.polygonPoints);
      expect(morning.left, closeTo(neutral.left, 0.001));
      expect(morning.top, closeTo(neutral.top, 0.001));
      expect(morning.width, closeTo(neutral.width, 0.001));
      expect(morning.height, closeTo(neutral.height, 0.001));
      expect(morning.opacity, closeTo(0.315, 0.001));
    });

    test('custom profile overrides source profile and null profile inherits it',
        () {
      final overrideProfile = _profile(
        'wide_shadow',
        scaleX: 1.5,
        opacity: 0.1,
        colorHexRgb: '112233',
      );
      final overridden = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          catalog: ProjectShadowCatalog(
            profiles: [_profile('base_shadow'), overrideProfile],
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'wide_shadow',
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      expect(overridden.opacity, 0.1);
      expect(overridden.colorHexRgb, '112233');
      _expectProjectedInstructionMatchesCore(
        instruction: overridden,
        shadowConfig: _resolvedConfig(
          shadowProfileId: 'wide_shadow',
          scaleX: 1.5,
          opacity: 0.1,
          colorHexRgb: '112233',
        ),
        metrics: _defaultMetrics(),
        opacity: 0.1,
      );

      final inherited = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      expect(inherited.colorHexRgb, '000000');
      _expectProjectedInstructionMatchesCore(
        instruction: inherited,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('preserves source order and opacity zero instructions', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          profile: _profile('base_shadow', opacity: 0),
        ),
        map: _map(
          placedElements: const [
            MapPlacedElement(
              id: 'first',
              layerId: 'layer',
              elementId: 'stand',
              pos: GridPos(x: 0, y: 0),
            ),
            MapPlacedElement(
              id: 'second',
              layerId: 'layer',
              elementId: 'stand',
              pos: GridPos(x: 1, y: 0),
            ),
          ],
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions.map((instruction) => instruction.instanceId), [
        'first',
        'second',
      ]);
      expect(instructions.first.opacity, 0);
    });

    test('instruction equality and hashCode include polygon points', () {
      final first = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
        ],
      );
      final same = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
        ],
      );
      final different = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 8, y: 10),
        ],
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('projected instruction rejects degenerate polygon points', () {
      expect(
        () => EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          opacity: 0.5,
          colorHexRgb: '000000',
          polygonPoints: [
            EditorStaticShadowPreviewPoint(x: 0, y: 0),
            EditorStaticShadowPreviewPoint(x: 5, y: 0),
            EditorStaticShadowPreviewPoint(x: 10, y: 0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

void _expectProjectedInstructionMatchesCore({
  required EditorStaticShadowPreviewInstruction instruction,
  required ResolvedShadowConfig shadowConfig,
  required StaticShadowVisualMetrics metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowProjectionSpec projectionSpec = defaultStaticShadowProjectionSpec,
  double opacity = 0.35,
}) {
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: shadowConfig,
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: projectionSpec,
  );
  final bounds = _testBounds(projected.points);

  expect(
      instruction.shape, EditorStaticShadowPreviewShapeKind.projectedPolygon);
  expect(instruction.opacity, closeTo(opacity, 0.001));
  expect(instruction.left, closeTo(bounds.left, 0.001));
  expect(instruction.top, closeTo(bounds.top, 0.001));
  expect(instruction.width, closeTo(bounds.width, 0.001));
  expect(instruction.height, closeTo(bounds.height, 0.001));
  expect(instruction.polygonPoints, hasLength(projected.points.length));
  for (var i = 0; i < projected.points.length; i += 1) {
    expect(
        instruction.polygonPoints[i].x, closeTo(projected.points[i].x, 0.001));
    expect(
        instruction.polygonPoints[i].y, closeTo(projected.points[i].y, 0.001));
  }
}

void _expectBuildingInstructionMatchesCoreContactLedge({
  required EditorStaticShadowPreviewInstruction instruction,
  required ResolvedShadowConfig shadowConfig,
  required StaticShadowVisualMetrics metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  double opacity = 0.35,
}) {
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: shadowConfig,
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final ledge = resolveBuildingStaticShadowContactLedgeGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
  );
  final bounds = _testBounds(ledge.points);

  expect(
    instruction.shape,
    EditorStaticShadowPreviewShapeKind.projectedPolygon,
  );
  expect(instruction.opacity, closeTo(opacity, 0.001));
  expect(instruction.left, closeTo(bounds.left, 0.001));
  expect(instruction.top, closeTo(bounds.top, 0.001));
  expect(instruction.width, closeTo(bounds.width, 0.001));
  expect(instruction.height, closeTo(bounds.height, 0.001));
  expect(instruction.polygonPoints, hasLength(ledge.points.length));
  for (var i = 0; i < ledge.points.length; i += 1) {
    expect(instruction.polygonPoints[i].x, closeTo(ledge.points[i].x, 0.001));
    expect(instruction.polygonPoints[i].y, closeTo(ledge.points[i].y, 0.001));
  }
}

StaticShadowVisualMetrics _defaultMetrics() {
  return StaticShadowVisualMetrics(
    left: 16,
    top: 32,
    visualWidth: 32,
    visualHeight: 64,
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'base_shadow',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: shadowProfileId,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

double _projectionLength(EditorStaticShadowPreviewInstruction instruction) {
  return _distance(
    _nearCenterX(instruction),
    _nearCenterY(instruction),
    _farCenterX(instruction),
    _farCenterY(instruction),
  );
}

double _nearCenterX(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[0].x + instruction.polygonPoints[1].x) / 2;
}

double _nearCenterY(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[0].y + instruction.polygonPoints[1].y) / 2;
}

double _farCenterX(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[2].x + instruction.polygonPoints[3].x) / 2;
}

double _farCenterY(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[2].y + instruction.polygonPoints[3].y) / 2;
}

double _distance(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return dx.abs() + dy.abs();
}

_TestBounds _testBounds(List<ProjectedStaticShadowPoint> points) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _TestBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _TestBounds {
  const _TestBounds({
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

ProjectManifest _manifest({
  ProjectShadowCatalog? catalog,
  ProjectShadowProfile? profile,
  ProjectElementShadowConfig? elementShadow,
  bool omitElementShadow = false,
  List<TilesetVisualFrame>? frames,
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [profile ?? _profile('base_shadow')],
        ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    elements: [
      ProjectElementEntry(
        id: 'stand',
        name: 'Stand',
        tilesetId: 'tiles',
        categoryId: 'props',
        frames: frames ??
            const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 4),
              ),
            ],
        shadow: omitElementShadow
            ? null
            : elementShadow ??
                ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'base_shadow',
                ),
      ),
    ],
  );
}

MapData _map({
  bool layerVisible = true,
  MapPlacedElementShadowOverride? shadowOverride,
  List<MapPlacedElement>? placedElements,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      TileLayer(
        id: 'layer',
        name: 'Layer',
        isVisible: layerVisible,
        tilesetId: 'tiles',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    placedElements: placedElements ??
        [
          MapPlacedElement(
            id: 'layer::1::2',
            layerId: 'layer',
            elementId: 'stand',
            pos: const GridPos(x: 1, y: 2),
            shadowOverride: shadowOverride,
          ),
        ],
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double scaleX = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
}) {
  return ProjectShadowProfile(
    id: id,
    name: id,
    mode: mode,
    renderPass: renderPass,
    scaleX: scaleX,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}

```

