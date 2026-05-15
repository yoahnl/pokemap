# Shadow Lot 14 — Runtime Static Placed Element Shadow Resolver V0

## 1. Résumé

Shadow-14 ajoute un resolver runtime pur pour transformer `ResolvedShadowConfig + StaticPlacedElementShadowRuntimeMetrics` en `ShadowRuntimeRenderInstruction`.
Il ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement`.
Il ne modifie aucun composant Flame et ne dessine rien.

Le lot ajoute une couche spécialisée pour les éléments statiques placés, symétrique au resolver acteur Shadow-13, et délègue la géométrie finale au resolver générique Shadow-12.

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `reports/shadows/shadow_lot_14_static_placed_element_shadow_resolver.md`

## 3. Fichiers modifiés

Aucun fichier existant modifié.

## 4. API runtime ajoutée

```dart
StaticPlacedElementShadowRuntimeMetrics
StaticPlacedElementShadowRuntimeInput
staticPlacedElementShadowAnchorFromMetrics(...)
resolveStaticPlacedElementShadowRuntimeInstruction(...)
resolveStaticPlacedElementShadowRuntimeInstructions(...)
```

L'API reste interne à `map_runtime`; elle n'est pas exportée depuis `packages/map_runtime/lib/map_runtime.dart`.

## 5. Modèles runtime ajoutés

`StaticPlacedElementShadowRuntimeMetrics` contient :

- `worldLeft`
- `worldTop`
- `visualWidth`
- `visualHeight`
- `anchorXRatio`
- `anchorYRatio`
- `baseWidthMultiplier`
- `baseHeightMultiplier`

`StaticPlacedElementShadowRuntimeInput` contient :

- `ResolvedShadowConfig resolvedConfig`
- `StaticPlacedElementShadowRuntimeMetrics metrics`

Les deux modèles ont une égalité de valeur et un `hashCode` cohérent.

## 6. Règles de résolution statique V0

- `ShadowCasterMode.none` -> `null`
- `ShadowCasterMode.ellipse + ShadowRenderPass.groundStatic` -> instruction
- `ShadowCasterMode.contactBlob + ShadowRenderPass.groundStatic` -> instruction
- `ShadowRenderPass.actorContact` -> `ValidationException`
- Délégation vers `resolveShadowRuntimeInstruction(...)` de Shadow-12.

La règle `none -> null` est appliquée avant la validation de `renderPass`, donc `none + actorContact` retourne aussi `null` si ce cas est représentable.

## 7. Géométrie et calculs

Le resolver calcule d'abord une `ShadowRuntimeAnchor` depuis les métriques statiques :

```text
anchor.worldX = worldLeft + visualWidth * anchorXRatio
anchor.worldY = worldTop + visualHeight * anchorYRatio
baseWidth = visualWidth * baseWidthMultiplier
baseHeight = visualHeight * baseHeightMultiplier
```

Puis Shadow-12 applique les offsets et scales résolus :

```text
resolvedWidth = baseWidth * scaleX
resolvedHeight = baseHeight * scaleY
centerX = anchor.worldX + offsetX
centerY = anchor.worldY + offsetY
worldLeft = centerX - resolvedWidth / 2
worldTop = centerY - resolvedHeight / 2
```

Les valeurs par défaut :

- `anchorXRatio = 0.5`
- `anchorYRatio = 1.0`
- `baseWidthMultiplier = 0.75`
- `baseHeightMultiplier = 0.25`

sont des heuristiques V0 temporaires, ajustables après observation du rendu réel.

## 8. Gestion des cas none / opacity 0 / configs non static-ground

- `ShadowCasterMode.none` retourne `null`.
- `opacity == 0` produit une instruction valide.
- `ShadowRenderPass.actorContact` est rejeté.
- Aucun clamp silencieux n'est effectué.
- Une dimension calculée invalide, par exemple via `scaleX < 0`, est rejetée par `ShadowRuntimeRenderInstruction`.

## 9. Décisions d’implémentation

- Les métriques élément statique sont fournies par l'appelant, car Shadow-14 ne décide pas comment lire les bounds réels d'un sprite.
- Le resolver ne lit pas `MapData`.
- Le resolver ne lit pas `ProjectManifest`.
- Le resolver ne lit pas `ProjectElementEntry`.
- Le resolver ne lit pas `MapPlacedElement`.
- Le resolver accepte `contactBlob + groundStatic`, car certains petits props statiques peuvent utiliser une ombre de contact.
- Le batch préserve l'ordre d'entrée.
- Le batch ne trie pas par `renderPass`.
- Le batch ne fait pas de culling.
- Le batch ne déduplique pas.
- Le resolver ne dessine rien.
- L'API n'est pas exportée depuis `map_runtime.dart`, pour rester cohérente avec les briques Shadow runtime V0 précédentes.

## 10. Tests ajoutés

Fichier ajouté :

- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

Couverture :

- validations de `StaticPlacedElementShadowRuntimeMetrics`;
- ratios et multipliers par défaut;
- ratios et multipliers custom;
- égalité de valeur des metrics;
- égalité de valeur de l'input;
- conversion metrics -> `ShadowRuntimeAnchor`;
- résolution `ellipse + groundStatic`;
- résolution `contactBlob + groundStatic`;
- calculs offset/scale via Shadow-12;
- passage de `opacity`, `colorHexRgb`, `softnessMode`, `renderPass`;
- normalisation de couleur lowercase via `ShadowRuntimeRenderInstruction`;
- `opacity == 0` conservée;
- `none -> null` avant validation de passe;
- `actorContact` rejeté;
- absence de clamp silencieux;
- batch vide;
- batch ordre préservé;
- batch ignore les entrées `none`;
- batch sans culling;
- batch sans déduplication;
- sortie batch non modifiable.

### Code complet des fichiers créés/modifiés

#### `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`

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
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
      );
}

ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return ShadowRuntimeAnchor(
    worldX: metrics.worldLeft + metrics.visualWidth * metrics.anchorXRatio,
    worldY: metrics.worldTop + metrics.visualHeight * metrics.anchorYRatio,
    baseWidth: metrics.visualWidth * metrics.baseWidthMultiplier,
    baseHeight: metrics.visualHeight * metrics.baseHeightMultiplier,
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

  return resolveShadowRuntimeInstruction(
    ShadowRuntimeResolutionInput(
      resolvedConfig: resolved,
      anchor: staticPlacedElementShadowAnchorFromMetrics(input.metrics),
    ),
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
```

#### `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

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
  });

  group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
    test('resolves ellipse groundStatic into an instruction', () {
      final instruction =
          resolveStaticPlacedElementShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.ellipse);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('resolves contactBlob groundStatic into an instruction', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('applies static metrics and Shadow-12 offset/scale geometry', () {
      final instruction =
          resolveStaticPlacedElementShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(36, 0.000001));
      expect(instruction.height, closeTo(7.5, 0.000001));
      expect(instruction.worldLeft, closeTo(88, 0.000001));
      expect(instruction.worldTop, closeTo(186.25, 0.000001));
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
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
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
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
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
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
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
```

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && dart format lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
rg -n "ShadowLayerComponent|ShadowRenderer|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig|RuntimeTilesetImage|TileImageLoader" packages/map_runtime/lib/src/shadow
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
```

La première exécution du test ciblé était le RED TDD attendu : compilation en échec car `static_placed_element_shadow_runtime_resolver.dart` n'existait pas encore.

## 12. Résultats des tests ciblés

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat final :

```text
00:00 +24: All tests passed!
```

## 13. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final :

```text
00:00 +89: All tests passed!
```

## 14. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat final :

```text
No issues found! (ran in 1.8s)
```

## 15. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat final :

```text
00:18 +1010: All tests passed!
```

Commande complémentaire côté `map_core` :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final :

```text
00:00 +152: All tests passed!
```

## 16. Vérifications anti-dérive

Résultats des scans `rg` : aucune occurrence.

Confirmations :

- aucun `ShadowLayerComponent`;
- aucun `ShadowRenderer`;
- aucun Flame Component;
- aucun `Canvas`;
- aucun `Paint`;
- aucun `drawOval` / `drawPath` / `drawImageRect`;
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
- aucun `RuntimeTilesetImage` lu;
- aucun `TileImageLoader` lu;
- aucun `map_core` modifié;
- aucun `map_editor` modifié;
- aucun `map_gameplay` modifié;
- aucune collision modifiée;
- aucune occlusion modifiée;
- aucun `visualMask` / `collisionMask` / `occlusionMask` / `cells` modifié;
- aucun `runtimeBlur`;
- aucun `blurRadius`;
- aucun `zOrder` / `zIndex`;
- aucun time-of-day;
- aucun custom shadow sprite;
- aucun JSON / `toJson` / `fromJson`;
- aucun build_runner lancé.

## 17. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
```

Le workspace était propre au début du lot.

## 18. Git status final

Résultat final attendu après création du rapport :

```text
?? packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
?? packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_14_static_placed_element_shadow_resolver.md
```

## 19. Git diff stat final

`git diff --stat` ne liste pas les fichiers non suivis. Résultat attendu :

```text
```

## 20. Non-objectifs respectés

- Aucun renderer ajouté.
- Aucun Flame Component ajouté.
- Aucun branchement dans `MapLayersComponent`.
- Aucun branchement dans `RuntimeMapGame`.
- Aucun branchement dans `PlayableMapGame`.
- Aucun branchement dans `PlayerComponent`.
- Aucun branchement dans `OverworldActorComponent`.
- Aucun branchement dans `PlacedElementOcclusionPatchComponent`.
- Aucun parcours de `MapData`.
- Aucune lecture de `ProjectManifest`.
- Aucune lecture de `ProjectElementEntry`.
- Aucune lecture de `MapPlacedElement`.
- Aucune modification de `map_core`.
- Aucune modification de `map_editor`.
- Aucune modification de `map_gameplay`.
- Aucune modification de collision.
- Aucune modification d'occlusion.
- Aucun `Canvas`, `Paint` ou `draw*`.
- Aucun JSON ajouté.
- Aucun build runner.

## 21. Risques / réserves

- Les ratios et multipliers par défaut sont des heuristiques V0. Ils devront être réévalués quand les ombres seront réellement rendues.
- Le resolver reçoit déjà les bounds visuels de l'élément; un futur lot devra définir comment les extraire proprement depuis les vrais éléments placés runtime.
- Le lot ne trie pas les instructions par passe et ne fait pas de culling; ces responsabilités restent hors périmètre Shadow-14.

## 22. Prochain lot recommandé

Shadow-15 — Runtime Shadow Instruction Collection / Culling V0
