# Shadow Lot 12 - Runtime Shadow Resolver V0

## 1. Résumé

Shadow-12 ajoute un resolver runtime pur qui transforme `ResolvedShadowConfig` + `ShadowRuntimeAnchor` en `ShadowRuntimeRenderInstruction`.

Le lot ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement`. Il ne dessine rien, ne crée aucun renderer, ne crée aucun Flame Component, et ne modifie pas `map_core`, `map_editor`, `map_gameplay` ou `map_battle`.

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart`
- `reports/shadows/shadow_lot_12_runtime_shadow_resolver.md`

## 3. Fichiers modifiés

- Aucun fichier existant modifié.

## 4. API runtime ajoutée

API ajoutée dans `packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart` :

```dart
final class ShadowRuntimeAnchor {
  ShadowRuntimeAnchor({
    required this.worldX,
    required this.worldY,
    required this.baseWidth,
    required this.baseHeight,
  });

  final double worldX;
  final double worldY;
  final double baseWidth;
  final double baseHeight;
}
```

```dart
final class ShadowRuntimeResolutionInput {
  const ShadowRuntimeResolutionInput({
    required this.resolvedConfig,
    required this.anchor,
  });

  final ResolvedShadowConfig resolvedConfig;
  final ShadowRuntimeAnchor anchor;
}
```

```dart
ShadowRuntimeRenderInstruction? resolveShadowRuntimeInstruction(
  ShadowRuntimeResolutionInput input,
);
```

```dart
List<ShadowRuntimeRenderInstruction> resolveShadowRuntimeInstructions(
  Iterable<ShadowRuntimeResolutionInput> inputs,
);
```

Code de production ajouté :

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

/// Runtime-provided geometry used to place a resolved V0 shadow.
///
/// The caller owns the conversion from sprites, actors, or placed elements to
/// this anchor. This resolver only applies resolved shadow offsets and scales.
final class ShadowRuntimeAnchor {
  ShadowRuntimeAnchor({
    required this.worldX,
    required this.worldY,
    required this.baseWidth,
    required this.baseHeight,
  }) {
    _validateFinite(worldX, 'worldX');
    _validateFinite(worldY, 'worldY');
    _validatePositiveFinite(baseWidth, 'baseWidth');
    _validatePositiveFinite(baseHeight, 'baseHeight');
  }

  final double worldX;
  final double worldY;
  final double baseWidth;
  final double baseHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeAnchor &&
          other.worldX == worldX &&
          other.worldY == worldY &&
          other.baseWidth == baseWidth &&
          other.baseHeight == baseHeight;

  @override
  int get hashCode => Object.hash(
        worldX,
        worldY,
        baseWidth,
        baseHeight,
      );
}

/// Single runtime shadow resolution request.
final class ShadowRuntimeResolutionInput {
  const ShadowRuntimeResolutionInput({
    required this.resolvedConfig,
    required this.anchor,
  });

  final ResolvedShadowConfig resolvedConfig;
  final ShadowRuntimeAnchor anchor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeResolutionInput &&
          other.resolvedConfig == resolvedConfig &&
          other.anchor == anchor;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        anchor,
      );
}

ShadowRuntimeRenderInstruction? resolveShadowRuntimeInstruction(
  ShadowRuntimeResolutionInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }

  final anchor = input.anchor;
  final resolvedWidth = anchor.baseWidth * resolved.scaleX;
  final resolvedHeight = anchor.baseHeight * resolved.scaleY;
  final centerX = anchor.worldX + resolved.offsetX;
  final centerY = anchor.worldY + resolved.offsetY;

  return ShadowRuntimeRenderInstruction(
    shape: shadowRuntimeShapeFromCasterMode(resolved.mode),
    renderPass: resolved.renderPass,
    worldLeft: centerX - resolvedWidth / 2,
    worldTop: centerY - resolvedHeight / 2,
    width: resolvedWidth,
    height: resolvedHeight,
    opacity: resolved.opacity,
    colorHexRgb: resolved.colorHexRgb,
    softnessMode: resolved.softnessMode,
  );
}

List<ShadowRuntimeRenderInstruction> resolveShadowRuntimeInstructions(
  Iterable<ShadowRuntimeResolutionInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction = resolveShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeAnchor.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeAnchor.$name must be greater than 0',
    );
  }
}
```

## 5. Modèles runtime ajoutés

`ShadowRuntimeAnchor`

- `worldX`
- `worldY`
- `baseWidth`
- `baseHeight`

`ShadowRuntimeResolutionInput`

- `resolvedConfig`
- `anchor`

Les deux modèles sont immuables côté API, ont une égalité de valeur, et n'ont aucune API JSON.

## 6. Règles de résolution V0

Le resolver applique uniquement la géométrie V0 depuis une config déjà résolue.

```text
resolvedWidth = baseWidth * scaleX
resolvedHeight = baseHeight * scaleY
centerX = worldX + offsetX
centerY = worldY + offsetY
worldLeft = centerX - resolvedWidth / 2
worldTop = centerY - resolvedHeight / 2
```

Puis il construit `ShadowRuntimeRenderInstruction` avec :

- `shape` depuis `shadowRuntimeShapeFromCasterMode(resolved.mode)`
- `renderPass` depuis `resolved.renderPass`
- `opacity` depuis `resolved.opacity`
- `colorHexRgb` depuis `resolved.colorHexRgb`
- `softnessMode` depuis `resolved.softnessMode`

## 7. Géométrie et calculs

Exemple testé :

```text
anchor.worldX = 100
anchor.worldY = 200
anchor.baseWidth = 20
anchor.baseHeight = 10

resolved.offsetX = 4
resolved.offsetY = 12
resolved.scaleX = 1.2
resolved.scaleY = 0.5

resolvedWidth = 24
resolvedHeight = 5
centerX = 104
centerY = 212
worldLeft = 92
worldTop = 209.5
```

Le resolver ne calcule pas l'ancre depuis un sprite, un acteur, un élément placé ou une map. Cette conversion reste hors scope.

## 8. Gestion des cas none / opacity 0

- `ShadowCasterMode.none` retourne `null`.
- Le test vérifie que `none` est traité avant l'appel à `shadowRuntimeShapeFromCasterMode(...)`, car le helper Shadow-11 rejette `none`.
- `opacity == 0` produit une instruction valide.
- Aucun clamp silencieux n'est fait.
- Le batch ignore les entrées qui résolvent `null`.
- Le batch preserve l'ordre d'entrée, ne trie pas par `renderPass`, et ne fait pas de culling.

## 9. Décisions d'implémentation

- L'ancre est fournie par l'appelant, parce que Shadow-12 ne doit pas décider comment convertir un sprite, un acteur, ou un élément placé en coordonnées monde.
- Le resolver ne lit pas `MapData`, car le parcours de map appartient à un futur lot.
- Le resolver ne lit pas `ProjectManifest`, car la résolution catalogue/élément/instance existe déjà côté `map_core`.
- Le resolver ne lit pas `ProjectElementEntry` ni `MapPlacedElement`, car il reçoit déjà une `ResolvedShadowConfig`.
- Le batch ne trie pas les instructions pour garder un contrat simple et prévisible; le tri par passe de rendu appartient à un futur lot.
- Le batch ne fait pas de culling; `opacity == 0` reste une instruction valide.
- Aucun renderer n'est ajouté; le lot produit seulement des instructions.
- L'API n'est pas exportée depuis `packages/map_runtime/lib/map_runtime.dart`, en cohérence avec Shadow-11 qui garde ces briques internes en V0.

## 10. Tests ajoutés

Tests créés dans `packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart`.

Couverture ajoutée :

- création de `ShadowRuntimeAnchor`;
- rejet de `worldX/worldY` non finis;
- rejet de `baseWidth/baseHeight` non finis ou `<= 0`;
- égalité de valeur et `hashCode` pour `ShadowRuntimeAnchor`;
- égalité de valeur et `hashCode` pour `ShadowRuntimeResolutionInput`;
- résolution `ellipse` + `groundStatic`;
- résolution `contactBlob` + `actorContact`;
- calcul `offset` + `scale` vers rectangle monde;
- transmission `opacity`, `colorHexRgb`, `softnessMode`, `renderPass`;
- normalisation de couleur par `ShadowRuntimeRenderInstruction`;
- `opacity == 0` gardée comme instruction valide;
- `ShadowCasterMode.none -> null`;
- batch vide;
- batch à une entrée;
- batch à plusieurs entrées avec ordre préservé;
- batch sans tri par `renderPass`;
- batch ignorant les entrées `null`;
- batch sans culling;
- liste batch immuable.

Extrait du test géométrique :

```dart
test('applies offset and scale to compute the world rectangle', () {
  final instruction = resolveShadowRuntimeInstruction(_input());

  expect(instruction, isNotNull);
  expect(instruction!.width, closeTo(24, 0.000001));
  expect(instruction.height, closeTo(5, 0.000001));
  expect(instruction.worldLeft, closeTo(92, 0.000001));
  expect(instruction.worldTop, closeTo(209.5, 0.000001));
});
```

Extrait du test `none` :

```dart
test('returns null for ShadowCasterMode.none before shape conversion', () {
  final instruction = resolveShadowRuntimeInstruction(
    _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
  );

  expect(instruction, isNull);
});
```

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
```

```bash
dart format packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart
```

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_resolver_test.dart
```

```bash
cd packages/map_runtime && flutter test test/shadow
```

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

```bash
cd packages/map_runtime && flutter test
```

```bash
cd packages/map_core && dart test test/shadow
```

```bash
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
```

```bash
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "ShadowLayerComponent|ShadowRenderer|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
```

```bash
git diff --check
```

```bash
git diff --stat
```

```bash
git status --short --untracked-files=all
```

## 12. Résultats des tests ciblés

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_resolver_test.dart
```

Résultat :

```text
00:00 +18: All tests passed!
```

La phase RED avait été vérifiée avant implémentation : le test ciblé échouait car `shadow_runtime_resolver.dart` et les symboles Shadow-12 n'existaient pas encore.

## 13. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat :

```text
00:00 +42: All tests passed!
```

## 14. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat :

```text
No issues found! (ran in 1.9s)
```

## 15. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat :

```text
00:17 +963: All tests passed!
```

Commande complémentaire côté `map_core` :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat :

```text
00:00 +152: All tests passed!
```

## 16. Vérifications anti-dérive

Les scans anti-dérive suivants ont tous retourné aucune sortie :

```bash
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
```

```bash
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "ShadowLayerComponent|ShadowRenderer|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig" packages/map_runtime/lib/src/shadow
```

```bash
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
```

Confirmations :

- aucun `ShadowLayerComponent`;
- aucun `ShadowRenderer`;
- aucun Flame Component;
- aucun `Canvas`;
- aucun `Paint`;
- aucun `drawOval`, `drawPath`, `drawImageRect`;
- aucun `MapLayersComponent` modifié;
- aucun `PlayableMapGame` modifié;
- aucun `RuntimeMapGame` modifié;
- aucun `PlayerComponent` modifié;
- aucun `OverworldActorComponent` modifié;
- aucun `PlacedElementOcclusionPatchComponent` modifié;
- aucun `MapData` lu;
- aucun `ProjectManifest` lu;
- aucun `ProjectElementEntry` lu;
- aucun `MapPlacedElement` lu;
- aucun `map_core` modifié;
- aucun `map_editor` modifié;
- aucun `map_gameplay` modifié;
- aucune collision modifiée;
- aucune occlusion modifiée;
- aucun `visualMask`, `collisionMask`, `occlusionMask`, `cells` modifié;
- aucun `runtimeBlur`;
- aucun `blurRadius`;
- aucun `zOrder` / `zIndex`;
- aucun time-of-day;
- aucun custom shadow sprite;
- aucun JSON / `toJson` / `fromJson`.

## 17. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

## 18. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
?? packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart
?? packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_12_runtime_shadow_resolver.md
```

## 19. Git diff stat final

Commande :

```bash
git diff --stat
```

Résultat final :

```text
aucune sortie
```

Note : les fichiers Shadow-12 sont non suivis, donc `git diff --stat` ne les affiche pas tant qu'ils ne sont pas ajoutés à l'index.

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune sortie
```

## 20. Non-objectifs respectés

- Aucun renderer Shadow ajouté.
- Aucun Flame Component ajouté.
- Aucun `Canvas`, `Paint` ou `draw*` ajouté.
- Aucun resolver `MapData` / `ProjectManifest` ajouté.
- Aucun parcours de layers, elements, entities ou acteurs ajouté.
- Aucun merge élément + instance ajouté.
- Aucun JSON ajouté.
- Aucun build_runner lancé.
- Aucun generated file créé.
- Aucun `map_core` modifié.
- Aucun `map_editor` modifié.
- Aucun `map_gameplay` modifié.
- Aucun `map_battle` modifié.
- Aucune collision modifiée.
- Aucune occlusion modifiée.

## 21. Risques / réserves

- Le calcul d'ancre monde depuis les sprites, les acteurs, les éléments placés ou les bounding boxes reste volontairement hors scope.
- Le batch preserve l'ordre d'entrée et ne trie pas par passe de rendu; le tri appartiendra à un futur lot d'intégration runtime.
- `opacity == 0` reste une instruction valide; le culling éventuel appartient à un futur lot d'optimisation.
- L'API reste interne à `map_runtime` en V0.

## 22. Prochain lot recommandé

Shadow-13 - Runtime Actor Contact Shadow Resolver V0

Ne pas l'implémenter dans Shadow-12.
