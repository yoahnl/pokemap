# Shadow Lot 13 - Runtime Actor Contact Shadow Resolver V0

## 1. Résumé

Shadow-13 ajoute un resolver runtime pur pour transformer `ResolvedShadowConfig` + `ActorContactShadowRuntimeMetrics` en `ShadowRuntimeRenderInstruction`.

Le lot ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement`. Il ne modifie aucun composant Flame et ne dessine rien. Les multiplicateurs par défaut `0.6` / `0.18` sont documentés comme heuristiques V0 temporaires, ajustables quand le rendu réel existera.

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart`
- `reports/shadows/shadow_lot_13_actor_contact_shadow_resolver.md`

Ces fichiers sont les trois fichiers non suivis listés par :

```bash
git ls-files --others --exclude-standard
```

## 3. Fichiers modifiés

Fichiers existants modifiés dans le workspace au moment de cette correction de rapport :

- `AGENTS.md`

Note : `AGENTS.md` a été modifié après Shadow-13 à la demande explicite de l'utilisateur pour renforcer la règle d'inventaire complet dans les rapports. Ce changement n'appartient pas à l'implémentation runtime Shadow-13.

Fichiers existants modifiés par l'implémentation runtime Shadow-13 :

- Aucun.

Fichiers supprimés :

- Aucun.

Fichiers générés :

- Aucun.

Inventaire complet recoupé avec `git status --short --untracked-files=all`, `git diff --name-only` et `git ls-files --others --exclude-standard` :

```text
Modifiés suivis:
M  AGENTS.md

Créés non suivis:
?? packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart
?? packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_13_actor_contact_shadow_resolver.md

Supprimés:
Aucun

Générés:
Aucun
```

## 4. API runtime ajoutée

API ajoutée dans `packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart` :

```dart
ActorContactShadowRuntimeMetrics
ActorContactShadowRuntimeInput
actorContactShadowAnchorFromMetrics(...)
resolveActorContactShadowRuntimeInstruction(...)
resolveActorContactShadowRuntimeInstructions(...)
```

L'API n'est pas exportée depuis `packages/map_runtime/lib/map_runtime.dart` en V0, comme les briques Shadow-11 et Shadow-12.

## 5. Modèles runtime ajoutés

`ActorContactShadowRuntimeMetrics`

- `footWorldX`
- `footWorldY`
- `visualWidth`
- `visualHeight`
- `baseWidthMultiplier`
- `baseHeightMultiplier`

`ActorContactShadowRuntimeInput`

- `resolvedConfig`
- `metrics`

Les deux modèles ont une égalité de valeur et un `hashCode`.

## 6. Règles de résolution acteur V0

Le resolver applique les règles suivantes :

- `ShadowCasterMode.none` retourne `null` immédiatement.
- `ShadowCasterMode.contactBlob` + `ShadowRenderPass.actorContact` produit une instruction.
- `ShadowCasterMode.ellipse` est rejeté avec `ValidationException`.
- `ShadowRenderPass.groundStatic` est rejeté avec `ValidationException`.
- La géométrie finale est déléguée à `resolveShadowRuntimeInstruction(...)` de Shadow-12.

L'ordre de validation est volontaire :

```text
none -> null
mode != contactBlob -> ValidationException
renderPass != actorContact -> ValidationException
metrics -> ShadowRuntimeAnchor
delegate -> resolveShadowRuntimeInstruction(...)
```

## 7. Géométrie et calculs

Le resolver acteur transforme les métriques en ancre runtime :

```text
baseWidth = visualWidth * baseWidthMultiplier
baseHeight = visualHeight * baseHeightMultiplier
anchor.worldX = footWorldX
anchor.worldY = footWorldY
```

Ensuite Shadow-12 applique `offsetX`, `offsetY`, `scaleX` et `scaleY`.

Exemple testé :

```text
metrics:
footWorldX = 100
footWorldY = 200
visualWidth = 32
visualHeight = 48
baseWidthMultiplier = 0.5
baseHeightMultiplier = 0.125

anchor:
baseWidth = 16
baseHeight = 6

resolved:
mode = contactBlob
renderPass = actorContact
offsetX = 4
offsetY = 3
scaleX = 1.5
scaleY = 0.5
opacity = 0.35

instruction:
width = 24
height = 3
centerX = 104
centerY = 203
worldLeft = 92
worldTop = 201.5
```

## 8. Gestion des cas none / opacity 0 / configs non actor-contact

- `ShadowCasterMode.none` retourne `null`.
- `opacity == 0` produit une instruction valide.
- `ShadowCasterMode.ellipse` est rejeté.
- `ShadowRenderPass.groundStatic` est rejeté.
- Aucun clamp silencieux n'est fait.
- Le batch ignore les entrées qui résolvent `null`.
- Le batch preserve l'ordre d'entrée.
- Le batch ne trie pas par `renderPass`.
- Le batch ne fait pas de culling.
- Le batch ne déduplique pas.

## 9. Décisions d'implémentation

- Les métriques acteur sont fournies par l'appelant, car Shadow-13 ne doit pas décider comment les composants runtime calculent les pieds ou les dimensions visuelles.
- Le resolver ne lit pas `PlayerComponent`.
- Le resolver ne lit pas `OverworldActorComponent`.
- Le resolver ne lit pas `MapData`.
- Le resolver ne lit pas `ProjectManifest`.
- Le resolver ne lit pas `ProjectElementEntry`.
- Le resolver ne lit pas `MapPlacedElement`.
- Le resolver ne trie pas les instructions; l'ordre d'entrée est conservé.
- Le resolver ne fait pas de culling; `opacity == 0` reste valide.
- Le resolver ne dessine rien.
- Les multiplicateurs `0.6` et `0.18` sont des heuristiques V0 temporaires.
- L'API reste interne et n'est pas exportée depuis `map_runtime.dart`.

## 10. Tests ajoutés

Tests créés dans `packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart`.

Couverture ajoutée :

- création de métriques valides;
- defaults `0.6` / `0.18`;
- multipliers custom valides;
- rejet des coordonnées de pieds non finies;
- rejet des dimensions visuelles invalides;
- rejet des multipliers invalides;
- égalité et `hashCode` de `ActorContactShadowRuntimeMetrics`;
- égalité et `hashCode` de `ActorContactShadowRuntimeInput`;
- conversion metrics -> `ShadowRuntimeAnchor`;
- résolution `contactBlob` + `actorContact`;
- calcul metrics + offset + scale via Shadow-12;
- transmission `opacity`, `colorHexRgb`, `softnessMode`, `renderPass`;
- normalisation de couleur lowercase via l'instruction Shadow-11;
- `opacity == 0` conservée;
- `ShadowCasterMode.none -> null`;
- rejet `ellipse`;
- rejet `groundStatic`;
- absence de clamp silencieux;
- batch vide;
- batch à une entrée;
- batch avec ordre préservé;
- batch ignorant `none`;
- batch sans culling;
- batch sans déduplication;
- liste batch immuable;
- inputs non modifiés.

### Code complet des fichiers créés/modifiés

#### `packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart`

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';
import 'shadow_runtime_resolver.dart';

/// Runtime actor metrics used to derive a contact shadow anchor.
///
/// The default multipliers are V0 heuristics for a compact contact blob. They
/// are intentionally adjustable once real rendered shadows can be evaluated.
final class ActorContactShadowRuntimeMetrics {
  ActorContactShadowRuntimeMetrics({
    required this.footWorldX,
    required this.footWorldY,
    required this.visualWidth,
    required this.visualHeight,
    this.baseWidthMultiplier = 0.6,
    this.baseHeightMultiplier = 0.18,
  }) {
    _validateFinite(footWorldX, 'footWorldX');
    _validateFinite(footWorldY, 'footWorldY');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
    _validatePositiveFinite(baseWidthMultiplier, 'baseWidthMultiplier');
    _validatePositiveFinite(baseHeightMultiplier, 'baseHeightMultiplier');
  }

  final double footWorldX;
  final double footWorldY;
  final double visualWidth;
  final double visualHeight;
  final double baseWidthMultiplier;
  final double baseHeightMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActorContactShadowRuntimeMetrics &&
          other.footWorldX == footWorldX &&
          other.footWorldY == footWorldY &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.baseWidthMultiplier == baseWidthMultiplier &&
          other.baseHeightMultiplier == baseHeightMultiplier;

  @override
  int get hashCode => Object.hash(
        footWorldX,
        footWorldY,
        visualWidth,
        visualHeight,
        baseWidthMultiplier,
        baseHeightMultiplier,
      );
}

/// Single actor contact shadow resolution request.
final class ActorContactShadowRuntimeInput {
  const ActorContactShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
  });

  final ResolvedShadowConfig resolvedConfig;
  final ActorContactShadowRuntimeMetrics metrics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActorContactShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
      );
}

ShadowRuntimeAnchor actorContactShadowAnchorFromMetrics(
  ActorContactShadowRuntimeMetrics metrics,
) {
  return ShadowRuntimeAnchor(
    worldX: metrics.footWorldX,
    worldY: metrics.footWorldY,
    baseWidth: metrics.visualWidth * metrics.baseWidthMultiplier,
    baseHeight: metrics.visualHeight * metrics.baseHeightMultiplier,
  );
}

ShadowRuntimeRenderInstruction? resolveActorContactShadowRuntimeInstruction(
  ActorContactShadowRuntimeInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }
  if (resolved.mode != ShadowCasterMode.contactBlob) {
    throw const ValidationException(
      'Actor contact shadow resolver requires contactBlob mode',
    );
  }
  if (resolved.renderPass != ShadowRenderPass.actorContact) {
    throw const ValidationException(
      'Actor contact shadow resolver requires actorContact render pass',
    );
  }

  return resolveShadowRuntimeInstruction(
    ShadowRuntimeResolutionInput(
      resolvedConfig: resolved,
      anchor: actorContactShadowAnchorFromMetrics(input.metrics),
    ),
  );
}

List<ShadowRuntimeRenderInstruction>
    resolveActorContactShadowRuntimeInstructions(
  Iterable<ActorContactShadowRuntimeInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction = resolveActorContactShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ActorContactShadowRuntimeMetrics.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ActorContactShadowRuntimeMetrics.$name must be greater than 0',
    );
  }
}
```

#### `packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/actor_contact_shadow_runtime_resolver.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';

void main() {
  group('ActorContactShadowRuntimeMetrics', () {
    test('creates valid metrics with default multipliers', () {
      final metrics = _metrics();

      expect(metrics.footWorldX, 100);
      expect(metrics.footWorldY, 200);
      expect(metrics.visualWidth, 32);
      expect(metrics.visualHeight, 48);
      expect(metrics.baseWidthMultiplier, 0.6);
      expect(metrics.baseHeightMultiplier, 0.18);
    });

    test('accepts custom valid multipliers', () {
      final metrics = _metrics(
        baseWidthMultiplier: 0.5,
        baseHeightMultiplier: 0.125,
      );

      expect(metrics.baseWidthMultiplier, 0.5);
      expect(metrics.baseHeightMultiplier, 0.125);
    });

    test('rejects non-finite foot coordinates', () {
      expect(
        () => _metrics(footWorldX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldY: double.infinity),
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
      final c = _metrics(footWorldX: 101);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ActorContactShadowRuntimeInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(metrics: _metrics(footWorldX: 101));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('actorContactShadowAnchorFromMetrics', () {
    test('converts actor metrics into a runtime anchor', () {
      final anchor = actorContactShadowAnchorFromMetrics(
        _metrics(
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
      );

      expect(anchor, isA<ShadowRuntimeAnchor>());
      expect(anchor.worldX, 100);
      expect(anchor.worldY, 200);
      expect(anchor.baseWidth, closeTo(16, 0.000001));
      expect(anchor.baseHeight, closeTo(6, 0.000001));
    });
  });

  group('resolveActorContactShadowRuntimeInstruction', () {
    test('resolves contactBlob actorContact into an instruction', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
    });

    test('applies actor metrics and Shadow-12 offset/scale geometry', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(24, 0.000001));
      expect(instruction.height, closeTo(3, 0.000001));
      expect(instruction.worldLeft, closeTo(92, 0.000001));
      expect(instruction.worldTop, closeTo(201.5, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
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
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
      );

      expect(instruction, isNull);
    });

    test('rejects non contactBlob modes', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(
              resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.ellipse)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non actorContact render passes', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(
            resolvedConfig: _resolvedConfig(
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(resolvedConfig: _resolvedConfig(scaleX: -1)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveActorContactShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveActorContactShadowRuntimeInstructions(const []), isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.contactBlob);
    });

    test('preserves input order without sorting', () {
      final first = _input(
        metrics: _metrics(footWorldX: 100),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );
      final second = _input(
        metrics: _metrics(footWorldX: 200),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );

      final instructions = resolveActorContactShadowRuntimeInstructions([
        first,
        second,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].worldLeft, lessThan(instructions[1].worldLeft));
    });

    test('ignores mode none inputs', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.contactBlob);
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('does not deduplicate equal inputs', () {
      final input = _input();

      final instructions = resolveActorContactShadowRuntimeInstructions([
        input,
        input,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0], instructions[1]);
    });

    test('does not modify inputs and exposes an unmodifiable list', () {
      final input = _input();
      final before = _input();

      final instructions = resolveActorContactShadowRuntimeInstructions([
        input,
      ]);

      expect(input, before);
      expect(
        () => instructions.add(
          resolveActorContactShadowRuntimeInstruction(_input())!,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

ActorContactShadowRuntimeMetrics _metrics({
  double footWorldX = 100,
  double footWorldY = 200,
  double visualWidth = 32,
  double visualHeight = 48,
  double baseWidthMultiplier = 0.6,
  double baseHeightMultiplier = 0.18,
}) {
  return ActorContactShadowRuntimeMetrics(
    footWorldX: footWorldX,
    footWorldY: footWorldY,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    baseWidthMultiplier: baseWidthMultiplier,
    baseHeightMultiplier: baseHeightMultiplier,
  );
}

ActorContactShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  ActorContactShadowRuntimeMetrics? metrics,
}) {
  return ActorContactShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ??
        _metrics(
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'actor_contact',
  ShadowCasterMode mode = ShadowCasterMode.contactBlob,
  ShadowRenderPass renderPass = ShadowRenderPass.actorContact,
  double offsetX = 4,
  double offsetY = 3,
  double scaleX = 1.5,
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
```

```bash
cd packages/map_runtime && dart format packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart && flutter test test/shadow/actor_contact_shadow_runtime_resolver_test.dart
```

La commande ci-dessus a volontairement servi au RED test, mais le préfixe de chemin du `dart format` était incorrect depuis `packages/map_runtime`. Le test a ensuite échoué comme attendu car le fichier de production n'existait pas encore.

```bash
cd packages/map_runtime && dart format lib/src/shadow/actor_contact_shadow_runtime_resolver.dart test/shadow/actor_contact_shadow_runtime_resolver_test.dart && flutter test test/shadow/actor_contact_shadow_runtime_resolver_test.dart
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
git diff --name-only
```

```bash
git ls-files --others --exclude-standard
```

```bash
git status --short --untracked-files=all
```

## 12. Résultats des tests ciblés

RED test :

```bash
cd packages/map_runtime && flutter test test/shadow/actor_contact_shadow_runtime_resolver_test.dart
```

Résultat attendu avant implémentation :

```text
Error when reading 'lib/src/shadow/actor_contact_shadow_runtime_resolver.dart': No such file or directory
Some tests failed.
```

GREEN test :

```bash
cd packages/map_runtime && flutter test test/shadow/actor_contact_shadow_runtime_resolver_test.dart
```

Résultat :

```text
00:00 +23: All tests passed!
```

## 13. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat :

```text
00:00 +65: All tests passed!
```

## 14. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat :

```text
No issues found! (ran in 2.2s)
```

## 15. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat :

```text
00:17 +986: All tests passed!
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
?? packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart
?? packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_12_runtime_shadow_resolver.md
```

Les fichiers Shadow-12 non suivis étaient attendus et n'ont pas été supprimés.

## 18. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M AGENTS.md
?? packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart
?? packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_13_actor_contact_shadow_resolver.md
```

Note : `AGENTS.md` est une modification post-lot demandée pour rendre obligatoire l'inventaire exhaustif des fichiers. Les trois fichiers Shadow-13 restent non suivis.

## 19. Git diff stat final

Commande :

```bash
git diff --stat
```

Résultat final :

```text
 AGENTS.md | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)
```

Note : les fichiers Shadow-13 sont non suivis, donc `git diff --stat` ne les affiche pas tant qu'ils ne sont pas ajoutés à l'index.

Commande :

```bash
git diff --name-only
```

Résultat :

```text
AGENTS.md
```

Commande :

```bash
git ls-files --others --exclude-standard
```

Résultat :

```text
packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart
packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart
reports/shadows/shadow_lot_13_actor_contact_shadow_resolver.md
```

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
- Aucun `PlayerComponent` modifié.
- Aucun `OverworldActorComponent` modifié.
- Aucun `MapLayersComponent` modifié.
- Aucun `PlayableMapGame` modifié.
- Aucun `RuntimeMapGame` modifié.
- Aucun `PlacedElementOcclusionPatchComponent` modifié.
- Aucun resolver complet de map ajouté.
- Aucun `MapData` / `ProjectManifest` lu.
- Aucun `ProjectElementEntry` / `MapPlacedElement` lu.
- Aucun merge de config élément + instance ajouté.
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

- Les métriques de pieds et de dimensions visuelles devront être fournies par un futur lot d'intégration runtime.
- Les multipliers `0.6` / `0.18` sont des heuristiques V0; ils devront probablement être ajustés lorsque les ombres seront visibles.
- Le batch ne trie pas par passe de rendu; le tri appartient à un futur lot d'intégration.
- `opacity == 0` reste une instruction valide; le culling éventuel appartient à un futur lot d'optimisation.
- L'API reste interne à `map_runtime` en V0.

## 22. Prochain lot recommandé

Shadow-14 - Runtime Static Placed Element Shadow Resolver V0

Ne pas l'implémenter dans Shadow-13.
