# Shadow-41 — Static Shadow Family Model / Style V0

## 1. Résumé du lot

Shadow-41 ajoute une sémantique persistante de famille d'ombre statique via `StaticShadowFamily` dans `map_core`.

Le lot ajoute :

- `StaticShadowFamily` ;
- `ProjectElementShadowConfig.family` ;
- `MapPlacedElementShadowOverride.family` ;
- un codec JSON dédié `encodeStaticShadowFamily` / `decodeStaticShadowFamily` ;
- l'encodage/décodage `family` dans les codecs Shadow existants ;
- un mapping de familles dans les suggestions automatiques Shadow-39 ;
- des tests modèle, JSON et suggestions/backfill.

Ce lot ne rend pas encore les ombres visuellement différentes. Il pose le signal sémantique que Shadow-42/43 devront consommer pour produire des familles de silhouettes plus proches de Pokémon.

## 2. Design retenu

`ProjectShadowProfile` reste un style partagé : mode, renderPass, couleur, opacité, softness et réglages numériques.

La nouvelle famille est portée par :

- `ProjectElementShadowConfig.family` pour le défaut de l'élément source ;
- `MapPlacedElementShadowOverride.family` pour une exception locale en mode `custom`.

Familles V0 :

```text
genericProjection
compactProp
tallProp
building
foliage
```

Le champ est nullable pour préserver les anciens projets. `null` signifie comportement existant jusqu'à ce que la géométrie familiale soit branchée.

## 3. Fichiers créés

- `packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart`
- `packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart`
- `reports/shadows/shadow_lot_41_static_shadow_family_model_style.md`

## 4. Fichiers modifiés

- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/shadow/project_element_shadow_config_test.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart`
- `packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart`
- `packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

## 5. Fichiers préexistants hors lot

Présents avant le codage Shadow-41 :

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? reports/analysis/psdk_fight_parity_audit_2026-05-16.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_41_static_shadow_family_model_style_plan.md
```

Un état transitoire PSDK/fight a été observé pendant la vérification, mais il n'est pas présent dans le `git status final` capturé plus bas. Aucun fichier PSDK/fight n'est attribué à Shadow-41.

## 6. StaticShadowFamily ajouté

Ajout dans `packages/map_core/lib/src/models/shadow.dart` :

```dart
enum StaticShadowFamily {
  genericProjection,
  compactProp,
  tallProp,
  building,
  foliage,
}
```

## 7. Intégration ProjectElementShadowConfig

`ProjectElementShadowConfig` porte maintenant :

```dart
final StaticShadowFamily? family;
```

La valeur est incluse dans `operator ==` et `hashCode`. `castsShadow: false` peut porter `family`, comme pour `footprint`, afin d'éviter une perte d'authoring lors d'un toggle.

## 8. Intégration MapPlacedElementShadowOverride

`MapPlacedElementShadowOverride` porte maintenant :

```dart
final StaticShadowFamily? family;
```

La valeur est incluse dans les champs custom. Donc `family` non-null est rejeté si `mode` vaut `inherit` ou `disabled`.

## 9. Format JSON family

Format :

```json
{
  "family": "building"
}
```

Règles :

- absent/null -> `null` ;
- string connue -> enum ;
- string inconnue -> `ValidationException` ;
- valeur non-string -> `ValidationException` ;
- encode `null` -> clé omise ;
- encode non-null -> `family.name`.

## 10. Compatibilité anciens JSON

Les tests confirment :

- old `ProjectElementShadowConfig` sans `family` décode `family == null` ;
- old `MapPlacedElementShadowOverride` sans `family` décode `family == null` ;
- champs inconnus existants restent ignorés ;
- le champ `footprint` garde son comportement existant.

## 11. Suggestions auto et mapping des familles

Mapping ajouté :

```text
tallThin -> tallProp
buildingLarge -> building
wideLow -> compactProp
smallSquare -> compactProp
defaultProp -> genericProjection
```

Le backfill Shadow-40 reçoit ce champ automatiquement car il applique déjà `suggestion.config`.

## 12. Pourquoi ce lot ne touche pas runtime/editor canvas

Shadow-41 ajoute uniquement le signal sémantique et sa persistance. Le runtime et la preview éditeur ne savent pas encore consommer `family` pour choisir une géométrie différente. Cela évite une modification visuelle partielle et garde la bascule de rendu pour Shadow-42/43.

## 13. Pourquoi ce lot ne crée pas de vraie lumière globale

`StaticShadowFamily` décrit une stratégie d'objet, pas une direction du soleil. Aucun `WorldLightState`, `timeOfDay`, `LightDirection`, `ShadowLightProfile` ou modèle de lumière globale n'est ajouté.

## 14. Tests ajoutés/modifiés

Ajouté :

- `static_shadow_family_json_codec_test.dart`

Modifiés :

- `project_element_shadow_config_test.dart`
- `map_placed_element_shadow_override_test.dart`
- `project_element_shadow_config_json_codec_test.dart`
- `map_placed_element_shadow_override_json_codec_test.dart`
- `element_auto_shadow_suggestion_test.dart`
- `element_auto_shadow_backfill_test.dart`

## 15. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/static_shadow_family_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_core && dart format lib/src/models/shadow.dart lib/src/operations/static_shadow_family_json_codec.dart lib/src/operations/project_element_shadow_config_json_codec.dart lib/src/operations/map_placed_element_shadow_override_json_codec.dart lib/map_core.dart test/shadow/static_shadow_family_json_codec_test.dart test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
cd packages/map_editor && dart format lib/src/application/shadow/element_auto_shadow_suggestion.dart test/application/shadow/element_auto_shadow_suggestion_test.dart test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_json_codec_test.dart
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_json_codec_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core packages/map_editor | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 16. Résultats complets utiles des tests ciblés

### RED map_core

```text
Command: cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/static_shadow_family_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
Result: exit 1 avant implémentation
Cause utile: StaticShadowFamily, family et encode/decodeStaticShadowFamily absents.
Exemples d'erreurs exactes:
Error: Undefined name 'StaticShadowFamily'.
Error: No named parameter with the name 'family'.
Error: Method not found: 'encodeStaticShadowFamily'.
Error: Method not found: 'decodeStaticShadowFamily'.
```

### GREEN map_core groupé

```text
Command: cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/map_placed_element_shadow_override_test.dart test/shadow/static_shadow_family_json_codec_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/map_placed_element_shadow_override_json_codec_test.dart
Final line: 00:00 +60: All tests passed!
```

### RED map_editor suggestions/backfill

```text
Command: cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart test/application/shadow/element_auto_shadow_backfill_test.dart
Result: exit 1 avant mapping family
Cause utile: suggestions et backfill avaient family == null.
Exemples d'échecs exacts:
Expected: StaticShadowFamily:<StaticShadowFamily.tallProp>
  Actual: <null>
Expected: StaticShadowFamily:<StaticShadowFamily.building>
  Actual: <null>
Expected: StaticShadowFamily:<StaticShadowFamily.compactProp>
  Actual: <null>
Expected: StaticShadowFamily:<StaticShadowFamily.genericProjection>
  Actual: <null>
```

### GREEN ciblés individuels

```text
cd packages/map_core && dart test test/shadow/static_shadow_family_json_codec_test.dart
00:00 +6: All tests passed!

cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart
00:00 +13: All tests passed!

cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_test.dart
00:00 +14: All tests passed!

cd packages/map_core && dart test test/shadow/project_element_shadow_config_json_codec_test.dart
00:00 +15: All tests passed!

cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_json_codec_test.dart
00:00 +12: All tests passed!

cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
00:00 +15: All tests passed!

cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
00:00 +9: All tests passed!
```

## 17. Lignes finales exactes des tests globaux ciblés

```text
cd packages/map_core && dart test test/shadow
00:01 +239: All tests passed!

cd packages/map_editor && flutter test test/application/shadow
00:01 +87: All tests passed!

cd packages/map_core && dart analyze lib test/shadow
No issues found!

cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
No issues found! (ran in 2.6s)
```

## 18. Résultats des scans anti-dérive

```text
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
Résultat: aucune sortie
```

Shadow-41 n'a modifié aucun fichier `map_runtime`, `map_gameplay` ou `map_battle`.

```text
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
12:packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Cette sortie vient des changements Shadow-38 déjà présents avant Shadow-41.

```text
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
Résultat: aucune sortie
```

```text
git diff -U0 -- packages/map_core packages/map_editor | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
619:-    canvas.drawOval(
637:+        canvas.drawOval(
651:+          canvas.drawPath(path, paint);
```

Ces lignes viennent du fichier painter Shadow-38 déjà modifié avant Shadow-41.

```text
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
Résultat: aucune sortie
```

```text
git diff --check
Résultat: aucune sortie
```

## 19. git status initial

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? reports/analysis/psdk_fight_parity_audit_2026-05-16.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_41_static_shadow_family_model_style_plan.md
```

## 20. git status final

```text
 M AGENTS.md
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/shadow.dart
 M packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
 M packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
 M packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
 M packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
 M packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
 M packages/map_core/test/shadow/project_element_shadow_config_test.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
?? packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_41_static_shadow_family_model_style.md
?? reports/shadows/shadow_lot_41_static_shadow_family_model_style_plan.md
```

## 21. git diff --stat

```text
AGENTS.md                                          | 1289 ++++++++++++--------
 packages/map_core/lib/map_core.dart                |    1 +
 packages/map_core/lib/src/models/shadow.dart       |   17 +
 ..._placed_element_shadow_override_json_codec.dart |    4 +
 .../project_element_shadow_config_json_codec.dart  |    4 +
 ...ed_element_shadow_override_json_codec_test.dart |   73 ++
 .../map_placed_element_shadow_override_test.dart   |   41 +
 ...ject_element_shadow_config_json_codec_test.dart |   50 +
 .../shadow/project_element_shadow_config_test.dart |   31 +
 .../shadow/editor_static_shadow_preview.dart       |  285 ++++-
 .../shadow/element_auto_shadow_suggestion.dart     |    5 +
 .../editor_static_shadow_preview_painter.dart      |   54 +-
 .../shadow/editor_static_shadow_preview_test.dart  |  390 +++++-
 .../shadow/element_auto_shadow_backfill_test.dart  |    8 +
 .../element_auto_shadow_suggestion_test.dart       |   11 +
 .../editor_static_shadow_preview_painter_test.dart |   69 +-
 16 files changed, 1679 insertions(+), 653 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis, donc les fichiers créés non suivis apparaissent dans `git status`.

## 22. Non-objectifs respectés

- Aucun `packages/map_runtime/**` modifié.
- Aucun `packages/map_gameplay/**` modifié.
- Aucun `packages/map_battle/**` modifié par Shadow-41.
- Aucun canvas/painter modifié par Shadow-41.
- Aucun generated file modifié.
- Aucun `build_runner` lancé.
- Aucun Shadow Studio.
- Aucune UI ajoutée.
- Aucune géométrie familiale consommée dans le rendu.
- Aucune lumière globale/time-of-day.
- Aucun commit effectué.

## 23. Risques / réserves

- Les ombres visibles ne changeront pas grâce à Shadow-41 seul. Le champ `family` devra être consommé par la géométrie familiale dans Shadow-42 puis branché runtime/editor dans Shadow-43.
- `foliage` est ajouté mais pas encore écrit par les suggestions automatiques. Il prépare le prochain lot de géométrie, sans heuristique de détection végétale prématurée.
- Le backfill préserve déjà les footprints et réglages manuels. Il ne traite pas encore `family` seul comme un marqueur manuel, parce que Shadow-41 suit le plan strict et ne modifie pas `element_auto_shadow_backfill.dart`. Si des données futures portent seulement `family` sans footprint/nombres, ce point devra être revu.

## 24. Auto-review finale

```text
- Ai-je ajouté StaticShadowFamily ? oui.
- Ai-je gardé ProjectShadowProfile comme style partagé ? oui.
- Ai-je ajouté family à ProjectElementShadowConfig ? oui.
- Ai-je ajouté family à MapPlacedElementShadowOverride ? oui.
- Ai-je interdit family sur override inherit/disabled ? oui.
- Ai-je gardé les anciens JSON compatibles ? oui.
- Ai-je encodé family seulement si non-null ? oui.
- Ai-je mis à jour les suggestions auto ? oui.
- Ai-je évité le runtime ? oui.
- Ai-je évité le canvas/painter éditeur ? oui.
- Ai-je évité build_runner/generated files ? oui.
- Ai-je évité une lumière globale/time-of-day ? oui.
- Ai-je documenté que le rendu visible viendra après ? oui.
```

## 25. Regard critique sur le prompt

Le plan Shadow-41 est cohérent avec la douleur produit : avant d'obtenir des ombres de bâtiments ou de lampadaires plus crédibles, il faut que les données sachent différencier les familles d'objets. Le point à surveiller est psychologique côté UX : ce lot ne donnera pas encore de capture plus belle. Il faut donc enchaîner rapidement avec Shadow-42/43 pour éviter de recréer la frustration des lots invisibles.

## 26. Contenu complet des fichiers créés/modifiés

### `packages/map_core/lib/src/models/shadow.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// How a project shadow profile describes its V0 shape.
enum ShadowCasterMode {
  /// Valid profile that intentionally emits no shadow.
  none,

  /// Small contact shadow for an actor or small object.
  contactBlob,

  /// Elliptical ground shadow for a simple static object.
  ellipse,
}

/// Constrained visual pass for V0 shadow rendering.
enum ShadowRenderPass {
  /// Ground-level shadow for static map elements.
  groundStatic,

  /// Contact shadow tied to a dynamic actor.
  actorContact,
}

/// V0 softness contract. Runtime blur is intentionally not represented.
enum ShadowSoftnessMode {
  /// Pixel-art friendly hard edge with no runtime blur.
  hardEdge,
}

/// Per-instance V0 override mode for a placed element shadow.
enum ShadowOverrideMode {
  /// Use the default shadow configuration from the project element.
  inherit,

  /// Disable the shadow for this placed element instance.
  disabled,

  /// Apply limited per-instance profile and numeric overrides later.
  custom,
}

enum StaticShadowFamily {
  genericProjection,
  compactProp,
  tallProp,
  building,
  foliage,
}

@immutable
final class StaticShadowFootprintConfig {
  StaticShadowFootprintConfig({
    this.anchorXRatio,
    this.anchorYRatio,
    this.footprintWidthRatio,
    this.footprintHeightRatio,
  }) {
    _validateStaticShadowOptionalAnchorRatio(anchorXRatio, 'anchorXRatio');
    _validateStaticShadowOptionalAnchorRatio(anchorYRatio, 'anchorYRatio');
    _validateStaticShadowOptionalFootprintRatio(
      footprintWidthRatio,
      'footprintWidthRatio',
    );
    _validateStaticShadowOptionalFootprintRatio(
      footprintHeightRatio,
      'footprintHeightRatio',
    );
  }

  final double? anchorXRatio;
  final double? anchorYRatio;
  final double? footprintWidthRatio;
  final double? footprintHeightRatio;

  bool get isEmpty =>
      anchorXRatio == null &&
      anchorYRatio == null &&
      footprintWidthRatio == null &&
      footprintHeightRatio == null;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticShadowFootprintConfig &&
          other.anchorXRatio == anchorXRatio &&
          other.anchorYRatio == anchorYRatio &&
          other.footprintWidthRatio == footprintWidthRatio &&
          other.footprintHeightRatio == footprintHeightRatio;

  @override
  int get hashCode => Object.hash(
        anchorXRatio,
        anchorYRatio,
        footprintWidthRatio,
        footprintHeightRatio,
      );
}

/// Pure authoring profile for a simple V0 shadow.
///
/// This model has no JSON API and no dependency on Flutter or Flame.
@immutable
final class ProjectShadowProfile {
  ProjectShadowProfile({
    required this.id,
    required this.name,
    required this.mode,
    required this.renderPass,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 0.35,
    String colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
  }) : colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(name, 'name');
    _validateFinite(offsetX, 'offsetX');
    _validateFinite(offsetY, 'offsetY');
    _validatePositiveFinite(scaleX, 'scaleX');
    _validatePositiveFinite(scaleY, 'scaleY');
    _validateOpacity(opacity);
  }

  final String id;
  final String name;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectShadowProfile &&
          other.id == id &&
          other.name == name &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mode,
        renderPass,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

/// Optional default shadow configuration carried by a project element.
///
/// This is an authoring contract only. It does not affect collision,
/// occlusion, cells, gameplay, Flutter, or Flame.
@immutable
final class ProjectElementShadowConfig {
  ProjectElementShadowConfig({
    this.castsShadow = false,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
    this.family,
    this.footprint,
  }) {
    final profileId = shadowProfileId;
    if (profileId != null) {
      _validateProjectElementShadowProfileId(profileId);
    }
    if (castsShadow && profileId == null) {
      throw const ValidationException(
        'ProjectElementShadowConfig.shadowProfileId is required when castsShadow is true',
      );
    }
    _validateProjectElementShadowOptionalFinite(offsetX, 'offsetX');
    _validateProjectElementShadowOptionalFinite(offsetY, 'offsetY');
    _validateProjectElementShadowOptionalPositive(scaleX, 'scaleX');
    _validateProjectElementShadowOptionalPositive(scaleY, 'scaleY');
    _validateProjectElementShadowOptionalOpacity(opacity);
  }

  /// Whether the element should cast its default shadow.
  final bool castsShadow;

  /// Reference to a future [ProjectShadowProfile].
  ///
  /// Shadow-4 intentionally does not resolve this id against a catalog.
  final String? shadowProfileId;

  /// Optional numeric overrides applied later by the Shadow resolver.
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;
  final StaticShadowFamily? family;
  final StaticShadowFootprintConfig? footprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementShadowConfig &&
          other.castsShadow == castsShadow &&
          other.shadowProfileId == shadowProfileId &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.family == family &&
          other.footprint == footprint;

  @override
  int get hashCode => Object.hash(
        castsShadow,
        shadowProfileId,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        family,
        footprint,
      );
}

/// Optional per-instance shadow override carried by a placed element.
///
/// This is only an authoring/data contract. Shadow-6 does not resolve profiles,
/// merge element defaults, affect collision, or render anything.
@immutable
final class MapPlacedElementShadowOverride {
  MapPlacedElementShadowOverride({
    this.mode = ShadowOverrideMode.inherit,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
    this.family,
    this.footprint,
  }) {
    final profileId = shadowProfileId;
    if (profileId != null) {
      _validateMapPlacedElementShadowProfileId(profileId);
    }
    _validateMapPlacedElementShadowOptionalFinite(offsetX, 'offsetX');
    _validateMapPlacedElementShadowOptionalFinite(offsetY, 'offsetY');
    _validateMapPlacedElementShadowOptionalPositive(scaleX, 'scaleX');
    _validateMapPlacedElementShadowOptionalPositive(scaleY, 'scaleY');
    _validateMapPlacedElementShadowOptionalOpacity(opacity);

    if (mode != ShadowOverrideMode.custom &&
        _hasMapPlacedElementShadowCustomFields) {
      throw ValidationException(
        'MapPlacedElementShadowOverride.${mode.name} cannot carry custom shadow fields',
      );
    }
  }

  /// Whether this instance inherits, disables, or customizes its shadow.
  final ShadowOverrideMode mode;

  /// Optional profile replacement for [ShadowOverrideMode.custom].
  ///
  /// Shadow-6 intentionally does not resolve this id against a catalog.
  final String? shadowProfileId;

  /// Optional numeric instance overrides applied later by the Shadow resolver.
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;
  final StaticShadowFamily? family;
  final StaticShadowFootprintConfig? footprint;

  bool get _hasMapPlacedElementShadowCustomFields =>
      shadowProfileId != null ||
      offsetX != null ||
      offsetY != null ||
      scaleX != null ||
      scaleY != null ||
      opacity != null ||
      family != null ||
      footprint != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPlacedElementShadowOverride &&
          other.mode == mode &&
          other.shadowProfileId == shadowProfileId &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.family == family &&
          other.footprint == footprint;

  @override
  int get hashCode => Object.hash(
        mode,
        shadowProfileId,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        family,
        footprint,
      );
}

void _validateStaticShadowOptionalAnchorRatio(double? value, String name) {
  if (value == null) {
    return;
  }
  if (!value.isFinite || value < 0 || value > 1) {
    throw ValidationException(
      'StaticShadowFootprintConfig.$name must be between 0 and 1',
    );
  }
}

void _validateStaticShadowOptionalFootprintRatio(double? value, String name) {
  if (value == null) {
    return;
  }
  if (!value.isFinite) {
    throw ValidationException(
      'StaticShadowFootprintConfig.$name must be finite',
    );
  }
  if (value <= 0) {
    throw ValidationException('StaticShadowFootprintConfig.$name must be > 0');
  }
}

void _validateMapPlacedElementShadowProfileId(String value) {
  if (value.trim().isEmpty) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.shadowProfileId must be non-empty',
    );
  }
}

void _validateMapPlacedElementShadowOptionalFinite(
  double? value,
  String name,
) {
  if (value == null) {
    return;
  }
  if (!value.isFinite) {
    throw ValidationException(
      'MapPlacedElementShadowOverride.$name must be finite',
    );
  }
}

void _validateMapPlacedElementShadowOptionalPositive(
  double? value,
  String name,
) {
  _validateMapPlacedElementShadowOptionalFinite(value, name);
  if (value != null && value <= 0) {
    throw ValidationException(
      'MapPlacedElementShadowOverride.$name must be > 0',
    );
  }
}

void _validateMapPlacedElementShadowOptionalOpacity(double? value) {
  _validateMapPlacedElementShadowOptionalFinite(value, 'opacity');
  if (value != null && (value < 0 || value > 1)) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.opacity must be between 0 and 1',
    );
  }
}

void _validateProjectElementShadowProfileId(String value) {
  if (value.trim().isEmpty) {
    throw const ValidationException(
      'ProjectElementShadowConfig.shadowProfileId must be non-empty',
    );
  }
}

void _validateProjectElementShadowOptionalFinite(
  double? value,
  String name,
) {
  if (value == null) {
    return;
  }
  if (!value.isFinite) {
    throw ValidationException(
      'ProjectElementShadowConfig.$name must be finite',
    );
  }
}

void _validateProjectElementShadowOptionalPositive(
  double? value,
  String name,
) {
  _validateProjectElementShadowOptionalFinite(value, name);
  if (value != null && value <= 0) {
    throw ValidationException(
      'ProjectElementShadowConfig.$name must be > 0',
    );
  }
}

void _validateProjectElementShadowOptionalOpacity(double? value) {
  _validateProjectElementShadowOptionalFinite(value, 'opacity');
  if (value != null && (value < 0 || value > 1)) {
    throw const ValidationException(
      'ProjectElementShadowConfig.opacity must be between 0 and 1',
    );
  }
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException('ProjectShadowProfile.$name must be non-empty');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('ProjectShadowProfile.$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('ProjectShadowProfile.$name must be > 0');
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'ProjectShadowProfile.opacity must be between 0 and 1',
    );
  }
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectShadowProfile.colorHexRgb must contain exactly 6 hexadecimal RGB characters without #',
    );
  }
  return value.toUpperCase();
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}
```
### `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';
import 'static_shadow_family_json_codec.dart';
import 'static_shadow_footprint_config_json_codec.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

bool _optionalBool(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  bool defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! bool) {
    throw ValidationException('$fieldKey must be a bool');
  }
  return value;
}

String? _optionalNullableString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

double? _optionalNullableDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

/// Encodes a [ProjectElementShadowConfig] using the external Shadow V0 JSON
/// shape.
Map<String, Object?> encodeProjectElementShadowConfig(
  ProjectElementShadowConfig config,
) {
  final footprintJson = encodeStaticShadowFootprintConfig(config.footprint);
  return <String, Object?>{
    'castsShadow': config.castsShadow,
    if (config.shadowProfileId != null)
      'shadowProfileId': config.shadowProfileId,
    if (config.offsetX != null) 'offsetX': config.offsetX,
    if (config.offsetY != null) 'offsetY': config.offsetY,
    if (config.scaleX != null) 'scaleX': config.scaleX,
    if (config.scaleY != null) 'scaleY': config.scaleY,
    if (config.opacity != null) 'opacity': config.opacity,
    if (config.family != null)
      'family': encodeStaticShadowFamily(config.family),
    if (footprintJson != null) 'footprint': footprintJson,
  };
}

/// Decodes an optional [ProjectElementShadowConfig] from its external Shadow V0
/// JSON shape.
///
/// `null` means no shadow config on the element. Unknown keys are ignored.
ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'ProjectElementShadowConfig JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  return ProjectElementShadowConfig(
    castsShadow: _optionalBool(
      map,
      'castsShadow',
      'ProjectElementShadowConfig.castsShadow',
      false,
    ),
    shadowProfileId: _optionalNullableString(
      map,
      'shadowProfileId',
      'ProjectElementShadowConfig.shadowProfileId',
    ),
    offsetX: _optionalNullableDouble(
      map,
      'offsetX',
      'ProjectElementShadowConfig.offsetX',
    ),
    offsetY: _optionalNullableDouble(
      map,
      'offsetY',
      'ProjectElementShadowConfig.offsetY',
    ),
    scaleX: _optionalNullableDouble(
      map,
      'scaleX',
      'ProjectElementShadowConfig.scaleX',
    ),
    scaleY: _optionalNullableDouble(
      map,
      'scaleY',
      'ProjectElementShadowConfig.scaleY',
    ),
    opacity: _optionalNullableDouble(
      map,
      'opacity',
      'ProjectElementShadowConfig.opacity',
    ),
    family: decodeStaticShadowFamily(map['family']),
    footprint: decodeStaticShadowFootprintConfig(map['footprint']),
  );
}

class ProjectElementShadowConfigJsonConverter
    implements JsonConverter<ProjectElementShadowConfig?, Object?> {
  const ProjectElementShadowConfigJsonConverter();

  @override
  ProjectElementShadowConfig? fromJson(Object? json) {
    return decodeProjectElementShadowConfig(json);
  }

  @override
  Object? toJson(ProjectElementShadowConfig? config) {
    return config == null ? null : encodeProjectElementShadowConfig(config);
  }
}
```
### `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';
import 'static_shadow_family_json_codec.dart';
import 'static_shadow_footprint_config_json_codec.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

String? _optionalNullableString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

double? _optionalNullableDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

ShadowOverrideMode _decodeShadowOverrideMode(Map<String, Object?> json) {
  if (!json.containsKey('mode')) {
    return ShadowOverrideMode.inherit;
  }

  final value = json['mode'];
  if (value is! String) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.mode must be a String',
    );
  }

  for (final mode in ShadowOverrideMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  throw ValidationException(
    'Unknown MapPlacedElementShadowOverride.mode "$value"',
  );
}

/// Encodes a [MapPlacedElementShadowOverride] using the external Shadow V0
/// JSON shape.
Map<String, Object?> encodeMapPlacedElementShadowOverride(
  MapPlacedElementShadowOverride override,
) {
  final footprintJson = encodeStaticShadowFootprintConfig(override.footprint);
  return <String, Object?>{
    'mode': override.mode.name,
    if (override.shadowProfileId != null)
      'shadowProfileId': override.shadowProfileId,
    if (override.offsetX != null) 'offsetX': override.offsetX,
    if (override.offsetY != null) 'offsetY': override.offsetY,
    if (override.scaleX != null) 'scaleX': override.scaleX,
    if (override.scaleY != null) 'scaleY': override.scaleY,
    if (override.opacity != null) 'opacity': override.opacity,
    if (override.family != null)
      'family': encodeStaticShadowFamily(override.family),
    if (footprintJson != null) 'footprint': footprintJson,
  };
}

/// Decodes an optional [MapPlacedElementShadowOverride] from its external
/// Shadow V0 JSON shape.
///
/// `null` means no per-instance override, which is equivalent to inherit.
/// Unknown keys are ignored.
MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
  Object? json,
) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'MapPlacedElementShadowOverride JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  return MapPlacedElementShadowOverride(
    mode: _decodeShadowOverrideMode(map),
    shadowProfileId: _optionalNullableString(
      map,
      'shadowProfileId',
      'MapPlacedElementShadowOverride.shadowProfileId',
    ),
    offsetX: _optionalNullableDouble(
      map,
      'offsetX',
      'MapPlacedElementShadowOverride.offsetX',
    ),
    offsetY: _optionalNullableDouble(
      map,
      'offsetY',
      'MapPlacedElementShadowOverride.offsetY',
    ),
    scaleX: _optionalNullableDouble(
      map,
      'scaleX',
      'MapPlacedElementShadowOverride.scaleX',
    ),
    scaleY: _optionalNullableDouble(
      map,
      'scaleY',
      'MapPlacedElementShadowOverride.scaleY',
    ),
    opacity: _optionalNullableDouble(
      map,
      'opacity',
      'MapPlacedElementShadowOverride.opacity',
    ),
    family: decodeStaticShadowFamily(map['family']),
    footprint: decodeStaticShadowFootprintConfig(map['footprint']),
  );
}

class MapPlacedElementShadowOverrideJsonConverter
    implements JsonConverter<MapPlacedElementShadowOverride?, Object?> {
  const MapPlacedElementShadowOverrideJsonConverter();

  @override
  MapPlacedElementShadowOverride? fromJson(Object? json) {
    return decodeMapPlacedElementShadowOverride(json);
  }

  @override
  Object? toJson(MapPlacedElementShadowOverride? override) {
    return override == null
        ? null
        : encodeMapPlacedElementShadowOverride(override);
  }
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
export 'src/operations/static_shadow_projection_geometry.dart';
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
### `packages/map_core/test/shadow/project_element_shadow_config_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementShadowConfig', () {
    test('defaults to not casting a shadow', () {
      final config = ProjectElementShadowConfig();

      expect(config.castsShadow, isFalse);
      expect(config.shadowProfileId, isNull);
      expect(config.offsetX, isNull);
      expect(config.offsetY, isNull);
      expect(config.scaleX, isNull);
      expect(config.scaleY, isNull);
      expect(config.opacity, isNull);
    });

    test('keeps a profile id when castsShadow is false', () {
      final config = ProjectElementShadowConfig(
        shadowProfileId: 'tree_large',
      );

      expect(config.castsShadow, isFalse);
      expect(config.shadowProfileId, 'tree_large');
    });

    test('accepts castsShadow true with a profile id', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      );

      expect(config.castsShadow, isTrue);
      expect(config.shadowProfileId, 'tree_large');
    });

    test('accepts valid numeric overrides', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );

      expect(config.offsetX, 4);
      expect(config.offsetY, 12);
      expect(config.scaleX, 1.2);
      expect(config.scaleY, 0.45);
      expect(config.opacity, 0.35);
    });

    test('castsShadow false can carry family', () {
      final config = ProjectElementShadowConfig(
        family: StaticShadowFamily.compactProp,
      );

      expect(config.castsShadow, isFalse);
      expect(config.family, StaticShadowFamily.compactProp);
    });

    test('accepts opacity bounds', () {
      expect(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'hidden',
          opacity: 0,
        ).opacity,
        0,
      );
      expect(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'opaque',
          opacity: 1,
        ).opacity,
        1,
      );
    });

    test('rejects blank profile ids when provided', () {
      expect(
        () => ProjectElementShadowConfig(shadowProfileId: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(shadowProfileId: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects castsShadow true without a profile id', () {
      expect(
        () => ProjectElementShadowConfig(castsShadow: true),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite offsets', () {
      expect(
        () => ProjectElementShadowConfig(offsetX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid scale overrides', () {
      for (final value in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => ProjectElementShadowConfig(scaleX: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ProjectElementShadowConfig(scaleY: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid opacity overrides', () {
      for (final value in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => ProjectElementShadowConfig(opacity: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('uses value equality', () {
      final a = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );
      final b = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );
      final c = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'rock_small',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('value equality includes family', () {
      final base = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.building,
      );
      final same = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.building,
      );
      final different = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.tallProp,
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });
  });
}
```
### `packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElementShadowOverride', () {
    test('defaults to inherit', () {
      final override = MapPlacedElementShadowOverride();

      expect(override.mode, ShadowOverrideMode.inherit);
      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, isNull);
      expect(override.offsetY, isNull);
      expect(override.scaleX, isNull);
      expect(override.scaleY, isNull);
      expect(override.opacity, isNull);
    });

    test('accepts disabled override', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      expect(override.mode, ShadowOverrideMode.disabled);
    });

    test('accepts custom override with profile id', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, 'tree_short');
    });

    test('accepts custom numeric overrides without profile id', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );

      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, 2);
      expect(override.offsetY, 8);
      expect(override.scaleX, 0.8);
      expect(override.scaleY, 0.35);
      expect(override.opacity, 0.25);
    });

    test('accepts custom override with family', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.tallProp,
      );

      expect(override.family, StaticShadowFamily.tallProp);
    });

    test('accepts opacity bounds on custom override', () {
      expect(
        MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 0,
        ).opacity,
        0,
      );
      expect(
        MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 1,
        ).opacity,
        1,
      );
    });

    test('rejects blank profile ids when provided', () {
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects inherit with any override fields', () {
      expect(
        () => MapPlacedElementShadowOverride(shadowProfileId: 'tree_short'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(offsetX: 2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(opacity: 0.25),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects disabled with any override fields', () {
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          shadowProfileId: 'tree_short',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          offsetX: 2,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          opacity: 0.25,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite offsets', () {
      for (final value in <double>[double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: value,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetY: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid scale overrides', () {
      for (final value in <double>[0, -1, double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            scaleX: value,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            scaleY: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid opacity overrides', () {
      for (final value in <double>[-0.1, 1.1, double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            opacity: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('uses value equality', () {
      final a = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );
      final b = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );
      final c = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('value equality includes family', () {
      final base = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.building,
      );
      final same = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.building,
      );
      final different = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.compactProp,
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });
  });
}
```
### `packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementShadowConfig JSON codec', () {
    test('encodes a complete config to canonical JSON', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
        family: StaticShadowFamily.building,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
      );

      expect(encodeProjectElementShadowConfig(config), <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4.0,
        'offsetY': 12.0,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'family': 'building',
        'footprint': <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1.0,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      });
    });

    test('decodes a complete config', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4,
        'offsetY': 12,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'family': 'building',
        'footprint': <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      });

      expect(
        config,
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
          offsetY: 12,
          scaleX: 1.2,
          scaleY: 0.45,
          opacity: 0.35,
          family: StaticShadowFamily.building,
          footprint: StaticShadowFootprintConfig(
            anchorXRatio: 0.5,
            anchorYRatio: 1,
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.25,
          ),
        ),
      );
    });

    test('old JSON without footprint decodes footprint null', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
      });

      expect(config!.footprint, isNull);
    });

    test('old JSON without family decodes family null', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
      });

      expect(config!.family, isNull);
    });

    test('encodes and decodes family when present', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.tallProp,
      );

      expect(encodeProjectElementShadowConfig(config), <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'family': 'tallProp',
      });
      expect(
        decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'family': 'tallProp',
        })!
            .family,
        StaticShadowFamily.tallProp,
      );
    });

    test('encodes null and empty footprint by omitting footprint key', () {
      expect(
        encodeProjectElementShadowConfig(
          ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
          ),
        ),
        <String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
        },
      );
      expect(
        encodeProjectElementShadowConfig(
          ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
            footprint: StaticShadowFootprintConfig(),
          ),
        ),
        <String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
        },
      );
    });

    test('equality includes footprint', () {
      final base = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final same = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final different = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.4),
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });

    test('castsShadow false can carry footprint', () {
      final config = ProjectElementShadowConfig(
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.7),
      );

      expect(config.castsShadow, isFalse);
      expect(config.footprint!.footprintWidthRatio, 0.7);
    });

    test('roundtrips encode to decode', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );

      expect(
        decodeProjectElementShadowConfig(
          encodeProjectElementShadowConfig(config),
        ),
        config,
      );
    });

    test('roundtrips decode to canonical encode', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4,
        'offsetY': 12,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'unknown': 'ignored',
      });

      expect(encodeProjectElementShadowConfig(config!), <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4.0,
        'offsetY': 12.0,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
      });
    });

    test('decodes null as null', () {
      expect(decodeProjectElementShadowConfig(null), isNull);
    });

    test('decodes empty and minimal objects with defaults', () {
      expect(
        decodeProjectElementShadowConfig(<String, Object?>{}),
        ProjectElementShadowConfig(),
      );
      expect(
        decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': false,
        }),
        ProjectElementShadowConfig(),
      );

      final absentCastsShadow = decodeProjectElementShadowConfig(
        <String, Object?>{'shadowProfileId': 'tree_large'},
      );

      expect(absentCastsShadow!.castsShadow, isFalse);
      expect(absentCastsShadow.shadowProfileId, 'tree_large');
      expect(absentCastsShadow.offsetX, isNull);
      expect(absentCastsShadow.offsetY, isNull);
      expect(absentCastsShadow.scaleX, isNull);
      expect(absentCastsShadow.scaleY, isNull);
      expect(absentCastsShadow.opacity, isNull);
    });

    test('ignores unknown fields and does not encode them', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': false,
        'runtimeBlur': true,
        'zOrder': 99,
      });

      expect(config, ProjectElementShadowConfig());
      expect(
        encodeProjectElementShadowConfig(config!),
        <String, Object?>{'castsShadow': false},
      );
    });

    test('rejects invalid root and field types', () {
      expect(
        () => decodeProjectElementShadowConfig('shadow'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': 'true',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'shadowProfileId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'offsetX': '4',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'offsetY': '12',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'scaleX': '1.2',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'scaleY': '0.45',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'opacity': '0.35',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'footprint': 'wide',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'family': 42,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid decoded values', () {
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': '',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'scaleX': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'scaleY': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'opacity': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'footprint': <String, Object?>{
            'footprintWidthRatio': 0,
          },
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'family': 'zeppelin',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```
### `packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElementShadowOverride JSON codec', () {
    test('encodes inherit, disabled, and custom canonically', () {
      expect(
        encodeMapPlacedElementShadowOverride(MapPlacedElementShadowOverride()),
        <String, Object?>{'mode': 'inherit'},
      );
      expect(
        encodeMapPlacedElementShadowOverride(
          MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
        ),
        <String, Object?>{'mode': 'disabled'},
      );
      expect(
        encodeMapPlacedElementShadowOverride(_customOverride()),
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2.0,
          'offsetY': 8.0,
          'scaleX': 0.8,
          'scaleY': 0.35,
          'opacity': 0.25,
          'family': 'building',
          'footprint': <String, Object?>{
            'anchorXRatio': 0.5,
            'anchorYRatio': 1.0,
            'footprintWidthRatio': 0.75,
            'footprintHeightRatio': 0.25,
          },
        },
      );
    });

    test('decodes inherit, disabled, and custom', () {
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
        }),
        MapPlacedElementShadowOverride(),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
        }),
        MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2,
          'offsetY': 8,
          'scaleX': 0.8,
          'scaleY': 0.35,
          'opacity': 0.25,
          'family': 'building',
          'footprint': <String, Object?>{
            'anchorXRatio': 0.5,
            'anchorYRatio': 1,
            'footprintWidthRatio': 0.75,
            'footprintHeightRatio': 0.25,
          },
        }),
        _customOverride(),
      );
    });

    test('old JSON without footprint decodes footprint null', () {
      final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
        'mode': 'custom',
        'offsetX': 2,
      });

      expect(override!.footprint, isNull);
    });

    test('old JSON without family decodes family null', () {
      final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
        'mode': 'custom',
        'offsetX': 2,
      });

      expect(override!.family, isNull);
    });

    test('encodes and decodes custom family when present', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.compactProp,
      );

      expect(encodeMapPlacedElementShadowOverride(override), <String, Object?>{
        'mode': 'custom',
        'family': 'compactProp',
      });
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'family': 'building',
        })!
            .family,
        StaticShadowFamily.building,
      );
    });

    test('encodes null and empty footprint by omitting footprint key', () {
      expect(
        encodeMapPlacedElementShadowOverride(
          MapPlacedElementShadowOverride(mode: ShadowOverrideMode.custom),
        ),
        <String, Object?>{'mode': 'custom'},
      );
      expect(
        encodeMapPlacedElementShadowOverride(
          MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            footprint: StaticShadowFootprintConfig(),
          ),
        ),
        <String, Object?>{'mode': 'custom'},
      );
    });

    test('equality includes footprint', () {
      final base = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final same = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final different = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.4),
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });

    test('rejects inherit and disabled overrides with footprint', () {
      expect(
        () => MapPlacedElementShadowOverride(
          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('roundtrips encode/decode and canonicalizes unknown fields', () {
      final custom = _customOverride();
      expect(
        decodeMapPlacedElementShadowOverride(
          encodeMapPlacedElementShadowOverride(custom),
        ),
        custom,
      );

      final decoded = decodeMapPlacedElementShadowOverride(
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2,
          'unknown': true,
        },
      );

      expect(
        encodeMapPlacedElementShadowOverride(decoded!),
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2.0,
        },
      );
    });

    test('decodes null and empty objects as inherit/null contract', () {
      expect(decodeMapPlacedElementShadowOverride(null), isNull);
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{}),
        MapPlacedElementShadowOverride(),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'shadowProfileId': null,
        }),
        MapPlacedElementShadowOverride(),
      );
    });

    test('rejects invalid root, mode, and field types', () {
      expect(
        () => decodeMapPlacedElementShadowOverride('override'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'deleteTheSun',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'family': 42,
        }),
        throwsA(isA<ValidationException>()),
      );
      for (final key in <String>[
        'offsetX',
        'offsetY',
        'scaleX',
        'scaleY',
        'opacity',
      ]) {
        expect(
          () => decodeMapPlacedElementShadowOverride(<String, Object?>{
            'mode': 'custom',
            key: '1',
          }),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid decoded values', () {
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
          'offsetX': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
          'shadowProfileId': 'tree_short',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': '',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'scaleX': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'scaleY': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'opacity': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
          'footprint': <String, Object?>{
            'anchorXRatio': 0.5,
          },
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
          'footprint': <String, Object?>{
            'anchorXRatio': 0.5,
          },
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
          'family': 'building',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
          'family': 'building',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'family': 'zeppelin',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'footprint': <String, Object?>{
            'footprintHeightRatio': 0,
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapPlacedElementShadowOverride _customOverride() {
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: 'tree_short',
    offsetX: 2,
    offsetY: 8,
    scaleX: 0.8,
    scaleY: 0.35,
    opacity: 0.25,
    family: StaticShadowFamily.building,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      footprintWidthRatio: 0.75,
      footprintHeightRatio: 0.25,
    ),
  );
}
```
### `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`

```dart
import 'package:map_core/map_core.dart';

enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
}) {
  if (element.frames.isEmpty) {
    return null;
  }
  final source = element.frames.first.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }
  final kind = _classifyElement(
    width: source.width.toDouble(),
    height: source.height.toDouble(),
  );
  final profile = _profileForKind(shadowCatalog, kind);
  if (profile == null) {
    return null;
  }
  return ElementAutoShadowSuggestion(
    kind: kind,
    config: _configForKind(kind, profile.id),
    summary: _summaryForKind(kind),
  );
}

ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  if (aspect >= 2.2 && width <= 2) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 4 || area >= 12) {
    return ElementAutoShadowSuggestionKind.buildingLarge;
  }
  if (width >= 3 && height <= 3) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}

ProjectShadowProfile? _profileForKind(
  ProjectShadowCatalog catalog,
  ElementAutoShadowSuggestionKind kind,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.smallSquare:
      return _preferredCompactProfile(catalog);
    case ElementAutoShadowSuggestionKind.buildingLarge:
    case ElementAutoShadowSuggestionKind.wideLow:
      return _preferredWideProfile(catalog);
    case ElementAutoShadowSuggestionKind.defaultProp:
      return _preferredSoftProfile(catalog);
  }
}

ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-contact-blob') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.contactBlob) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-wide-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-soft-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _compatibleProfileById(
  ProjectShadowCatalog catalog,
  String id,
) {
  final profile = catalog.profileById(id);
  if (profile == null || !isGroundStaticElementShadowProfile(profile)) {
    return null;
  }
  return profile;
}

ProjectShadowProfile? _firstCompatibleProfileWithMode(
  ProjectShadowCatalog catalog,
  ShadowCasterMode mode,
) {
  for (final profile in catalog.profiles) {
    if (profile.mode == mode && isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog) {
  for (final profile in catalog.profiles) {
    if (isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectElementShadowConfig _configForKind(
  ElementAutoShadowSuggestionKind kind,
  String profileId,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 0.28,
        family: StaticShadowFamily.tallProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1.0,
          footprintWidthRatio: 0.18,
          footprintHeightRatio: 0.07,
        ),
      );
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 0.85,
        opacity: 0.30,
        family: StaticShadowFamily.building,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.82,
          footprintHeightRatio: 0.12,
        ),
      );
    case ElementAutoShadowSuggestionKind.wideLow:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.92,
        scaleY: 0.75,
        opacity: 0.27,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.72,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.smallSquare:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.78,
        scaleY: 0.70,
        opacity: 0.26,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.96,
          footprintWidthRatio: 0.46,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.defaultProp:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.90,
        scaleY: 0.80,
        opacity: 0.28,
        family: StaticShadowFamily.genericProjection,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.62,
          footprintHeightRatio: 0.12,
        ),
      );
  }
}

String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return 'lampadaire fin';
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return 'grand bâtiment';
    case ElementAutoShadowSuggestionKind.wideLow:
      return 'élément large et bas';
    case ElementAutoShadowSuggestionKind.smallSquare:
      return 'petit élément compact';
    case ElementAutoShadowSuggestionKind.defaultProp:
      return 'élément standard';
  }
}
```
### `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('returns null without compatible ground static profile', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(suggestion, isNull);
    });

    test('returns null for missing frames', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _elementWithFrames(const []),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('returns null for invalid first frame source', () {
      final invalidWidth = buildElementAutoShadowSuggestion(
        element: _element(width: 0, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final invalidHeight = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 0),
        shadowCatalog: _defaultCatalog(),
      );

      expect(invalidWidth, isNull);
      expect(invalidHeight, isNull);
    });

    test('classifies tall thin elements as tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.family, StaticShadowFamily.tallProp);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
      expect(suggestion.config.opacity, 0.28);
    });

    test('classifies large buildings as buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.building);
      expect(suggestion.config.footprint!.anchorYRatio, 0.92);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleY, 0.85);
      expect(suggestion.config.opacity, 0.30);
    });

    test('classifies wide low elements as wideLow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 3, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.compactProp);
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.92);
      expect(suggestion.config.scaleY, 0.75);
      expect(suggestion.config.opacity, 0.27);
    });

    test('classifies small square elements as smallSquare', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.smallSquare);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.family, StaticShadowFamily.compactProp);
      expect(suggestion.config.footprint!.anchorYRatio, 0.96);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.46);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.78);
      expect(suggestion.config.scaleY, 0.70);
      expect(suggestion.config.opacity, 0.26);
    });

    test('classifies remaining valid elements as defaultProp', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.defaultProp);
      expect(suggestion.config.shadowProfileId, 'default-ground-soft-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.genericProjection);
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.62);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleX, 0.90);
      expect(suggestion.config.scaleY, 0.80);
      expect(suggestion.config.opacity, 0.28);
    });

    test('prefers default compact profile for tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-soft'),
            _profile('default-ground-contact-blob',
                mode: ShadowCasterMode.contactBlob),
          ],
        ),
      )!;

      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
    });

    test('falls back to custom compatible profile ids', () {
      final tallThin = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-contact', mode: ShadowCasterMode.contactBlob)
          ],
        ),
      )!;
      final building = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-ellipse')],
        ),
      )!;
      final defaultProp = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-soft')],
        ),
      )!;

      expect(tallThin.config.shadowProfileId, 'custom-contact');
      expect(building.config.shadowProfileId, 'custom-ellipse');
      expect(defaultProp.config.shadowProfileId, 'custom-soft');
    });

    test('all suggestions have castsShadow true', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.castsShadow, isTrue);
      }
    });

    test('all suggestion footprints are non-null and valid', () {
      for (final suggestion in _allSuggestionKinds()) {
        final footprint = suggestion.config.footprint;
        expect(footprint, isNotNull);
        expect(footprint!.anchorXRatio, inInclusiveRange(0, 1));
        expect(footprint.anchorYRatio, inInclusiveRange(0, 1));
        expect(footprint.footprintWidthRatio, greaterThan(0));
        expect(footprint.footprintHeightRatio, greaterThan(0));
      }
    });

    test('all suggestions carry a static shadow family', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.family, isNotNull);
      }
    });

    test('all suggestion opacities are within 0..1', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.opacity, inInclusiveRange(0, 1));
      }
    });

    test('all suggestion scaleX and scaleY are greater than zero', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.scaleX, greaterThan(0));
        expect(suggestion.config.scaleY, greaterThan(0));
      }
    });
  });
}

Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
  for (final dimensions in const [
    (width: 1, height: 4),
    (width: 4, height: 3),
    (width: 3, height: 2),
    (width: 2, height: 2),
    (width: 2, height: 3),
  ]) {
    yield buildElementAutoShadowSuggestion(
      element: _element(width: dimensions.width, height: dimensions.height),
      shadowCatalog: _defaultCatalog(),
    )!;
  }
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required int width,
  required int height,
}) {
  return _elementWithFrames([
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
    ),
  ]);
}

ProjectElementEntry _elementWithFrames(List<TilesetVisualFrame> frames) {
  return ProjectElementEntry(
    id: 'element',
    name: 'Element',
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: frames,
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}
```
### `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('applyElementAutoShadowSuggestionsToProject', () {
    test('applies suggestions to elements without shadow configs', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(id: 'house', name: 'House', width: 4, height: 3),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 2);
      expect(result.skippedCount, 0);
      expect(result.hasChanges, isTrue);
      expect(result.addedDefaultProfiles, isFalse);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.appliedMissing,
        ElementAutoShadowBackfillStatus.appliedMissing,
      ]);
      expect(result.entries.map((entry) => entry.suggestionKind), [
        ElementAutoShadowSuggestionKind.tallThin,
        ElementAutoShadowSuggestionKind.buildingLarge,
      ]);
      expect(
        result.project.elements[0].shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
      expect(
        result.project.elements[0].shadow!.family,
        StaticShadowFamily.tallProp,
      );
      expect(
        result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
        0.18,
      );
      expect(
        result.project.elements[1].shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
      expect(
        result.project.elements[1].shadow!.family,
        StaticShadowFamily.building,
      );
      expect(
        result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
        0.82,
      );
    });

    test('replaces generic pre-footprint active shadows', () {
      final project = _project(
        elements: [
          _element(
            id: 'stand',
            name: 'Stand',
            width: 3,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-soft-ellipse',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(result.project.elements.single.shadow!.footprint, isNotNull);
      expect(
        result.project.elements.single.shadow!.footprint!.footprintWidthRatio,
        0.72,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
    });

    test('preserves disabled shadows', () {
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final project = _project(
        elements: [
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 1,
            height: 4,
            shadow: disabled,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      );
      expect(result.project.elements.single.shadow, disabled);
    });

    test('preserves manual footprints and numeric overrides', () {
      final manualFootprint = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-contact-blob',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.31),
      );
      final manualNumbers = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-wide-ellipse',
        offsetX: 4,
        scaleY: 0.6,
        opacity: 0.18,
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-footprint',
            name: 'Manual footprint',
            width: 1,
            height: 4,
            shadow: manualFootprint,
          ),
          _element(
            id: 'manual-numbers',
            name: 'Manual numbers',
            width: 4,
            height: 3,
            shadow: manualNumbers,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 2);
      expect(
        result.entries.map((entry) => entry.status),
        everyElement(ElementAutoShadowBackfillStatus.skippedManual),
      );
      expect(result.project.elements[0].shadow, manualFootprint);
      expect(result.project.elements[1].shadow, manualNumbers);
    });

    test('preserves non-default existing profile ids present in catalog', () {
      final customShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final project = _project(
        elements: [
          _element(
            id: 'custom-profile',
            name: 'Custom profile',
            width: 4,
            height: 3,
            shadow: customShadow,
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, customShadow);
    });

    test('replaces generic shadows with missing profile ids', () {
      final project = _project(
        elements: [
          _element(
            id: 'missing-profile',
            name: 'Missing profile',
            width: 2,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing-profile-id',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('adds default profiles when the catalog has no compatible profile',
        () {
      final project = _project(
        elements: [
          _element(id: 'prop', name: 'Prop', width: 2, height: 3),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
          result.project.shadowCatalog.profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-soft-ellipse',
      );
    });

    test('records skippedNoSuggestion for invalid element frames', () {
      final project = _project(
        elements: [
          _elementWithFrames(
            id: 'invalid',
            name: 'Invalid',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0, height: 2),
              ),
            ],
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves element order and non-shadow fields', () {
      final project = _project(
        elements: [
          _element(
            id: 'first',
            name: 'First',
            width: 1,
            height: 4,
            presetKind: ElementPresetKind.tree,
            tags: const ['nature', 'tall'],
            sortOrder: 7,
          ),
          _element(
            id: 'second',
            name: 'Second',
            width: 4,
            height: 3,
            recommendedLayerId: 'decor_layer',
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.project.elements.map((element) => element.id), [
        'first',
        'second',
      ]);
      expect(result.project.elements[0].presetKind, ElementPresetKind.tree);
      expect(result.project.elements[0].tags, ['nature', 'tall']);
      expect(result.project.elements[0].sortOrder, 7);
      expect(result.project.elements[1].recommendedLayerId, 'decor_layer');
      expect(result.project.elements[0].shadow, isNotNull);
      expect(result.project.elements[1].shadow, isNotNull);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Backfill test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return _elementWithFrames(
    id: id,
    name: name,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
    presetKind: presetKind,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

ProjectElementEntry _elementWithFrames({
  required String id,
  required String name,
  required List<TilesetVisualFrame> frames,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: frames,
    presetKind: presetKind,
    shadow: shadow,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}
```
### `packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';

String? encodeStaticShadowFamily(StaticShadowFamily? family) {
  return family?.name;
}

StaticShadowFamily? decodeStaticShadowFamily(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! String) {
    throw ValidationException(
      'StaticShadowFamily JSON must be a String or null, got ${json.runtimeType}',
    );
  }
  for (final family in StaticShadowFamily.values) {
    if (family.name == json) {
      return family;
    }
  }
  throw ValidationException('Unknown StaticShadowFamily "$json"');
}
```
### `packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticShadowFamily JSON codec', () {
    test('encodes null as null', () {
      expect(encodeStaticShadowFamily(null), isNull);
    });

    test('encodes family by stable enum name', () {
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.building),
        'building',
      );
      expect(
        encodeStaticShadowFamily(StaticShadowFamily.tallProp),
        'tallProp',
      );
    });

    test('decodes null as null', () {
      expect(decodeStaticShadowFamily(null), isNull);
    });

    test('decodes valid family names', () {
      expect(
        decodeStaticShadowFamily('genericProjection'),
        StaticShadowFamily.genericProjection,
      );
      expect(
        decodeStaticShadowFamily('compactProp'),
        StaticShadowFamily.compactProp,
      );
      expect(
        decodeStaticShadowFamily('tallProp'),
        StaticShadowFamily.tallProp,
      );
      expect(
        decodeStaticShadowFamily('building'),
        StaticShadowFamily.building,
      );
      expect(
        decodeStaticShadowFamily('foliage'),
        StaticShadowFamily.foliage,
      );
    });

    test('rejects non-string values', () {
      expect(
        () => decodeStaticShadowFamily(42),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown family values', () {
      expect(
        () => decodeStaticShadowFamily('houseButMaybeLater'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

## 27. Diffs complets ou équivalents /dev/null pour fichiers créés

### Diff complet des fichiers modifiés Shadow-41

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index c87c78ca..d468dcca 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -46,6 +46,7 @@ export 'src/operations/project_manifest_shadow_catalog_operations.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
 export 'src/operations/project_shadow_profile_json_codec.dart';
+export 'src/operations/static_shadow_family_json_codec.dart';
 export 'src/operations/static_shadow_footprint_config_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
 export 'src/operations/default_shadow_profiles.dart';
diff --git a/packages/map_core/lib/src/models/shadow.dart b/packages/map_core/lib/src/models/shadow.dart
index 79d0409c..4a1b45b5 100644
--- a/packages/map_core/lib/src/models/shadow.dart
+++ b/packages/map_core/lib/src/models/shadow.dart
@@ -41,6 +41,14 @@ enum ShadowOverrideMode {
   custom,
 }

+enum StaticShadowFamily {
+  genericProjection,
+  compactProp,
+  tallProp,
+  building,
+  foliage,
+}
+
 @immutable
 final class StaticShadowFootprintConfig {
   StaticShadowFootprintConfig({
@@ -177,6 +185,7 @@ final class ProjectElementShadowConfig {
     this.scaleX,
     this.scaleY,
     this.opacity,
+    this.family,
     this.footprint,
   }) {
     final profileId = shadowProfileId;
@@ -209,6 +218,7 @@ final class ProjectElementShadowConfig {
   final double? scaleX;
   final double? scaleY;
   final double? opacity;
+  final StaticShadowFamily? family;
   final StaticShadowFootprintConfig? footprint;

   @override
@@ -222,6 +232,7 @@ final class ProjectElementShadowConfig {
           other.scaleX == scaleX &&
           other.scaleY == scaleY &&
           other.opacity == opacity &&
+          other.family == family &&
           other.footprint == footprint;

   @override
@@ -233,6 +244,7 @@ final class ProjectElementShadowConfig {
         scaleX,
         scaleY,
         opacity,
+        family,
         footprint,
       );
 }
@@ -251,6 +263,7 @@ final class MapPlacedElementShadowOverride {
     this.scaleX,
     this.scaleY,
     this.opacity,
+    this.family,
     this.footprint,
   }) {
     final profileId = shadowProfileId;
@@ -285,6 +298,7 @@ final class MapPlacedElementShadowOverride {
   final double? scaleX;
   final double? scaleY;
   final double? opacity;
+  final StaticShadowFamily? family;
   final StaticShadowFootprintConfig? footprint;

   bool get _hasMapPlacedElementShadowCustomFields =>
@@ -294,6 +308,7 @@ final class MapPlacedElementShadowOverride {
       scaleX != null ||
       scaleY != null ||
       opacity != null ||
+      family != null ||
       footprint != null;

   @override
@@ -307,6 +322,7 @@ final class MapPlacedElementShadowOverride {
           other.scaleX == scaleX &&
           other.scaleY == scaleY &&
           other.opacity == opacity &&
+          other.family == family &&
           other.footprint == footprint;

   @override
@@ -318,6 +334,7 @@ final class MapPlacedElementShadowOverride {
         scaleX,
         scaleY,
         opacity,
+        family,
         footprint,
       );
 }
diff --git a/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart b/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
index 4b2a3776..4627654a 100644
--- a/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
+++ b/packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
@@ -2,6 +2,7 @@ import 'package:json_annotation/json_annotation.dart';

 import '../exceptions/map_exceptions.dart';
 import '../models/shadow.dart';
+import 'static_shadow_family_json_codec.dart';
 import 'static_shadow_footprint_config_json_codec.dart';

 Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
@@ -87,6 +88,8 @@ Map<String, Object?> encodeMapPlacedElementShadowOverride(
     if (override.scaleX != null) 'scaleX': override.scaleX,
     if (override.scaleY != null) 'scaleY': override.scaleY,
     if (override.opacity != null) 'opacity': override.opacity,
+    if (override.family != null)
+      'family': encodeStaticShadowFamily(override.family),
     if (footprintJson != null) 'footprint': footprintJson,
   };
 }
@@ -141,6 +144,7 @@ MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
       'opacity',
       'MapPlacedElementShadowOverride.opacity',
     ),
+    family: decodeStaticShadowFamily(map['family']),
     footprint: decodeStaticShadowFootprintConfig(map['footprint']),
   );
 }
diff --git a/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart b/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
index 9160e4e5..3a67bb8f 100644
--- a/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
+++ b/packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
@@ -2,6 +2,7 @@ import 'package:json_annotation/json_annotation.dart';

 import '../exceptions/map_exceptions.dart';
 import '../models/shadow.dart';
+import 'static_shadow_family_json_codec.dart';
 import 'static_shadow_footprint_config_json_codec.dart';

 Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
@@ -77,6 +78,8 @@ Map<String, Object?> encodeProjectElementShadowConfig(
     if (config.scaleX != null) 'scaleX': config.scaleX,
     if (config.scaleY != null) 'scaleY': config.scaleY,
     if (config.opacity != null) 'opacity': config.opacity,
+    if (config.family != null)
+      'family': encodeStaticShadowFamily(config.family),
     if (footprintJson != null) 'footprint': footprintJson,
   };
 }
@@ -133,6 +136,7 @@ ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json) {
       'opacity',
       'ProjectElementShadowConfig.opacity',
     ),
+    family: decodeStaticShadowFamily(map['family']),
     footprint: decodeStaticShadowFootprintConfig(map['footprint']),
   );
 }
diff --git a/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart b/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
index 6a17d432..7f262cc8 100644
--- a/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
+++ b/packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
@@ -24,6 +24,7 @@ void main() {
           'scaleX': 0.8,
           'scaleY': 0.35,
           'opacity': 0.25,
+          'family': 'building',
           'footprint': <String, Object?>{
             'anchorXRatio': 0.5,
             'anchorYRatio': 1.0,
@@ -56,6 +57,7 @@ void main() {
           'scaleX': 0.8,
           'scaleY': 0.35,
           'opacity': 0.25,
+          'family': 'building',
           'footprint': <String, Object?>{
             'anchorXRatio': 0.5,
             'anchorYRatio': 1,
@@ -76,6 +78,35 @@ void main() {
       expect(override!.footprint, isNull);
     });

+    test('old JSON without family decodes family null', () {
+      final override = decodeMapPlacedElementShadowOverride(<String, Object?>{
+        'mode': 'custom',
+        'offsetX': 2,
+      });
+
+      expect(override!.family, isNull);
+    });
+
+    test('encodes and decodes custom family when present', () {
+      final override = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        family: StaticShadowFamily.compactProp,
+      );
+
+      expect(encodeMapPlacedElementShadowOverride(override), <String, Object?>{
+        'mode': 'custom',
+        'family': 'compactProp',
+      });
+      expect(
+        decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'custom',
+          'family': 'building',
+        })!
+            .family,
+        StaticShadowFamily.building,
+      );
+    });
+
     test('encodes null and empty footprint by omitting footprint key', () {
       expect(
         encodeMapPlacedElementShadowOverride(
@@ -127,6 +158,19 @@ void main() {
         ),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => MapPlacedElementShadowOverride(
+          family: StaticShadowFamily.building,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.disabled,
+          family: StaticShadowFamily.building,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
     });

     test('roundtrips encode/decode and canonicalizes unknown fields', () {
@@ -195,6 +239,13 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'custom',
+          'family': 42,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
       for (final key in <String>[
         'offsetX',
         'offsetY',
@@ -273,6 +324,27 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'inherit',
+          'family': 'building',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'disabled',
+          'family': 'building',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
+          'mode': 'custom',
+          'family': 'zeppelin',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
       expect(
         () => decodeMapPlacedElementShadowOverride(<String, Object?>{
           'mode': 'custom',
@@ -295,6 +367,7 @@ MapPlacedElementShadowOverride _customOverride() {
     scaleX: 0.8,
     scaleY: 0.35,
     opacity: 0.25,
+    family: StaticShadowFamily.building,
     footprint: StaticShadowFootprintConfig(
       anchorXRatio: 0.5,
       anchorYRatio: 1,
diff --git a/packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart b/packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
index 10f41282..c98bdf76 100644
--- a/packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
+++ b/packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
@@ -51,6 +51,15 @@ void main() {
       expect(override.opacity, 0.25);
     });

+    test('accepts custom override with family', () {
+      final override = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        family: StaticShadowFamily.tallProp,
+      );
+
+      expect(override.family, StaticShadowFamily.tallProp);
+    });
+
     test('accepts opacity bounds on custom override', () {
       expect(
         MapPlacedElementShadowOverride(
@@ -98,6 +107,12 @@ void main() {
         () => MapPlacedElementShadowOverride(opacity: 0.25),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => MapPlacedElementShadowOverride(
+          family: StaticShadowFamily.building,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
     });

     test('rejects disabled with any override fields', () {
@@ -122,6 +137,13 @@ void main() {
         ),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.disabled,
+          family: StaticShadowFamily.building,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
     });

     test('rejects non-finite offsets', () {
@@ -201,5 +223,24 @@ void main() {
       expect(a.hashCode, b.hashCode);
       expect(a, isNot(c));
     });
+
+    test('value equality includes family', () {
+      final base = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        family: StaticShadowFamily.building,
+      );
+      final same = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        family: StaticShadowFamily.building,
+      );
+      final different = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        family: StaticShadowFamily.compactProp,
+      );
+
+      expect(base, same);
+      expect(base.hashCode, same.hashCode);
+      expect(base, isNot(different));
+    });
   });
 }
diff --git a/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart b/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
index 8ded62ad..9d11d7f1 100644
--- a/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
+++ b/packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
@@ -12,6 +12,7 @@ void main() {
         scaleX: 1.2,
         scaleY: 0.45,
         opacity: 0.35,
+        family: StaticShadowFamily.building,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 1,
@@ -28,6 +29,7 @@ void main() {
         'scaleX': 1.2,
         'scaleY': 0.45,
         'opacity': 0.35,
+        'family': 'building',
         'footprint': <String, Object?>{
           'anchorXRatio': 0.5,
           'anchorYRatio': 1.0,
@@ -46,6 +48,7 @@ void main() {
         'scaleX': 1.2,
         'scaleY': 0.45,
         'opacity': 0.35,
+        'family': 'building',
         'footprint': <String, Object?>{
           'anchorXRatio': 0.5,
           'anchorYRatio': 1,
@@ -64,6 +67,7 @@ void main() {
           scaleX: 1.2,
           scaleY: 0.45,
           opacity: 0.35,
+          family: StaticShadowFamily.building,
           footprint: StaticShadowFootprintConfig(
             anchorXRatio: 0.5,
             anchorYRatio: 1,
@@ -83,6 +87,38 @@ void main() {
       expect(config!.footprint, isNull);
     });

+    test('old JSON without family decodes family null', () {
+      final config = decodeProjectElementShadowConfig(<String, Object?>{
+        'castsShadow': true,
+        'shadowProfileId': 'tree_large',
+      });
+
+      expect(config!.family, isNull);
+    });
+
+    test('encodes and decodes family when present', () {
+      final config = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        family: StaticShadowFamily.tallProp,
+      );
+
+      expect(encodeProjectElementShadowConfig(config), <String, Object?>{
+        'castsShadow': true,
+        'shadowProfileId': 'tree_large',
+        'family': 'tallProp',
+      });
+      expect(
+        decodeProjectElementShadowConfig(<String, Object?>{
+          'castsShadow': true,
+          'shadowProfileId': 'tree_large',
+          'family': 'tallProp',
+        })!
+            .family,
+        StaticShadowFamily.tallProp,
+      );
+    });
+
     test('encodes null and empty footprint by omitting footprint key', () {
       expect(
         encodeProjectElementShadowConfig(
@@ -280,6 +316,12 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeProjectElementShadowConfig(<String, Object?>{
+          'family': 42,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
     });

     test('rejects invalid decoded values', () {
@@ -330,6 +372,14 @@ void main() {
         }),
         throwsA(isA<ValidationException>()),
       );
+      expect(
+        () => decodeProjectElementShadowConfig(<String, Object?>{
+          'castsShadow': true,
+          'shadowProfileId': 'tree_large',
+          'family': 'zeppelin',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
     });
   });
 }
diff --git a/packages/map_core/test/shadow/project_element_shadow_config_test.dart b/packages/map_core/test/shadow/project_element_shadow_config_test.dart
index e9ad57f1..f7482a18 100644
--- a/packages/map_core/test/shadow/project_element_shadow_config_test.dart
+++ b/packages/map_core/test/shadow/project_element_shadow_config_test.dart
@@ -52,6 +52,15 @@ void main() {
       expect(config.opacity, 0.35);
     });

+    test('castsShadow false can carry family', () {
+      final config = ProjectElementShadowConfig(
+        family: StaticShadowFamily.compactProp,
+      );
+
+      expect(config.castsShadow, isFalse);
+      expect(config.family, StaticShadowFamily.compactProp);
+    });
+
     test('accepts opacity bounds', () {
       expect(
         ProjectElementShadowConfig(
@@ -175,5 +184,27 @@ void main() {
       expect(a.hashCode, b.hashCode);
       expect(a, isNot(c));
     });
+
+    test('value equality includes family', () {
+      final base = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        family: StaticShadowFamily.building,
+      );
+      final same = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        family: StaticShadowFamily.building,
+      );
+      final different = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        family: StaticShadowFamily.tallProp,
+      );
+
+      expect(base, same);
+      expect(base.hashCode, same.hashCode);
+      expect(base, isNot(different));
+    });
   });
 }
diff --git a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
index bdbe3b49..8b2978ff 100644
--- a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
+++ b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
@@ -147,6 +147,7 @@ ProjectElementShadowConfig _configForKind(
         scaleX: 1,
         scaleY: 1,
         opacity: 0.28,
+        family: StaticShadowFamily.tallProp,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 1.0,
@@ -163,6 +164,7 @@ ProjectElementShadowConfig _configForKind(
         scaleX: 1,
         scaleY: 0.85,
         opacity: 0.30,
+        family: StaticShadowFamily.building,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 0.92,
@@ -179,6 +181,7 @@ ProjectElementShadowConfig _configForKind(
         scaleX: 0.92,
         scaleY: 0.75,
         opacity: 0.27,
+        family: StaticShadowFamily.compactProp,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 0.95,
@@ -195,6 +198,7 @@ ProjectElementShadowConfig _configForKind(
         scaleX: 0.78,
         scaleY: 0.70,
         opacity: 0.26,
+        family: StaticShadowFamily.compactProp,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 0.96,
@@ -211,6 +215,7 @@ ProjectElementShadowConfig _configForKind(
         scaleX: 0.90,
         scaleY: 0.80,
         opacity: 0.28,
+        family: StaticShadowFamily.genericProjection,
         footprint: StaticShadowFootprintConfig(
           anchorXRatio: 0.5,
           anchorYRatio: 0.95,
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
index 6a5af0d8..06982b7f 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
@@ -32,6 +32,10 @@ void main() {
         result.project.elements[0].shadow!.shadowProfileId,
         'default-ground-contact-blob',
       );
+      expect(
+        result.project.elements[0].shadow!.family,
+        StaticShadowFamily.tallProp,
+      );
       expect(
         result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
         0.18,
@@ -40,6 +44,10 @@ void main() {
         result.project.elements[1].shadow!.shadowProfileId,
         'default-ground-wide-ellipse',
       );
+      expect(
+        result.project.elements[1].shadow!.family,
+        StaticShadowFamily.building,
+      );
       expect(
         result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
         0.82,
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
index 687153e6..ac5468ac 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
@@ -53,6 +53,7 @@ void main() {

       expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
       expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
+      expect(suggestion.config.family, StaticShadowFamily.tallProp);
       expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
       expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
       expect(suggestion.config.opacity, 0.28);
@@ -66,6 +67,7 @@ void main() {

       expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
       expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
+      expect(suggestion.config.family, StaticShadowFamily.building);
       expect(suggestion.config.footprint!.anchorYRatio, 0.92);
       expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
       expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
@@ -81,6 +83,7 @@ void main() {

       expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
       expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
+      expect(suggestion.config.family, StaticShadowFamily.compactProp);
       expect(suggestion.config.footprint!.anchorYRatio, 0.95);
       expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
       expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
@@ -97,6 +100,7 @@ void main() {

       expect(suggestion.kind, ElementAutoShadowSuggestionKind.smallSquare);
       expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
+      expect(suggestion.config.family, StaticShadowFamily.compactProp);
       expect(suggestion.config.footprint!.anchorYRatio, 0.96);
       expect(suggestion.config.footprint!.footprintWidthRatio, 0.46);
       expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
@@ -113,6 +117,7 @@ void main() {

       expect(suggestion.kind, ElementAutoShadowSuggestionKind.defaultProp);
       expect(suggestion.config.shadowProfileId, 'default-ground-soft-ellipse');
+      expect(suggestion.config.family, StaticShadowFamily.genericProjection);
       expect(suggestion.config.footprint!.anchorYRatio, 0.95);
       expect(suggestion.config.footprint!.footprintWidthRatio, 0.62);
       expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
@@ -180,6 +185,12 @@ void main() {
       }
     });

+    test('all suggestions carry a static shadow family', () {
+      for (final suggestion in _allSuggestionKinds()) {
+        expect(suggestion.config.family, isNotNull);
+      }
+    });
+
     test('all suggestion opacities are within 0..1', () {
       for (final suggestion in _allSuggestionKinds()) {
         expect(suggestion.config.opacity, inInclusiveRange(0, 1));
```

### `/dev/null -> packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart`

```diff
--- /dev/null
+++ b/packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
+import '../exceptions/map_exceptions.dart';
+import '../models/shadow.dart';
+
+String? encodeStaticShadowFamily(StaticShadowFamily? family) {
+  return family?.name;
+}
+
+StaticShadowFamily? decodeStaticShadowFamily(Object? json) {
+  if (json == null) {
+    return null;
+  }
+  if (json is! String) {
+    throw ValidationException(
+      'StaticShadowFamily JSON must be a String or null, got ${json.runtimeType}',
+    );
+  }
+  for (final family in StaticShadowFamily.values) {
+    if (family.name == json) {
+      return family;
+    }
+  }
+  throw ValidationException('Unknown StaticShadowFamily "$json"');
+}
```
### `/dev/null -> packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart`

```diff
--- /dev/null
+++ b/packages/map_core/test/shadow/static_shadow_family_json_codec_test.dart
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('StaticShadowFamily JSON codec', () {
+    test('encodes null as null', () {
+      expect(encodeStaticShadowFamily(null), isNull);
+    });
+
+    test('encodes family by stable enum name', () {
+      expect(
+        encodeStaticShadowFamily(StaticShadowFamily.building),
+        'building',
+      );
+      expect(
+        encodeStaticShadowFamily(StaticShadowFamily.tallProp),
+        'tallProp',
+      );
+    });
+
+    test('decodes null as null', () {
+      expect(decodeStaticShadowFamily(null), isNull);
+    });
+
+    test('decodes valid family names', () {
+      expect(
+        decodeStaticShadowFamily('genericProjection'),
+        StaticShadowFamily.genericProjection,
+      );
+      expect(
+        decodeStaticShadowFamily('compactProp'),
+        StaticShadowFamily.compactProp,
+      );
+      expect(
+        decodeStaticShadowFamily('tallProp'),
+        StaticShadowFamily.tallProp,
+      );
+      expect(
+        decodeStaticShadowFamily('building'),
+        StaticShadowFamily.building,
+      );
+      expect(
+        decodeStaticShadowFamily('foliage'),
+        StaticShadowFamily.foliage,
+      );
+    });
+
+    test('rejects non-string values', () {
+      expect(
+        () => decodeStaticShadowFamily(42),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects unknown family values', () {
+      expect(
+        () => decodeStaticShadowFamily('houseButMaybeLater'),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+  });
+}
```
