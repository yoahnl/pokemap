# Shadow Lot 11 — Runtime Shadow Render Instruction V0

## 1. Résumé

Shadow-11 ajoute `ShadowRuntimeRenderInstruction` dans `map_runtime`.
L'instruction est runtime-only, non persistee, sans renderer, sans Flame
Component et sans dessin.

Le lot ajoute aussi `ShadowRuntimeShapeKind` et des helpers purs pour :

- convertir un `ShadowCasterMode` dessinable en shape runtime ;
- mapper `ShadowRenderPass.groundStatic` vers le slot Shadow-10
  `futureStaticPlacedElementShadows` ;
- mapper `ShadowRenderPass.actorContact` vers le slot Shadow-10
  `futureDynamicActorContactShadows`.

Aucun `map_core`, `map_editor`, `map_gameplay`, renderer, resolver map/project,
JSON, Canvas ou Paint n'est ajoute.

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart`
- `reports/shadows/shadow_lot_11_runtime_render_instruction.md`

## 3. Fichiers modifiés

Aucun fichier existant n'a ete modifie.

`packages/map_runtime/lib/map_runtime.dart` n'a pas ete modifie : l'instruction
reste interne au runtime en V0, comme `SurfaceRuntimeRenderInstruction`, qui
n'est pas exportee depuis le barrel public.

## 4. Modèles runtime ajoutés

`ShadowRuntimeShapeKind` :

- `contactBlob`
- `ellipse`

`ShadowRuntimeRenderInstruction` :

- `shape: ShadowRuntimeShapeKind`
- `renderPass: ShadowRenderPass`
- `worldLeft: double`
- `worldTop: double`
- `width: double`
- `height: double`
- `opacity: double`
- `colorHexRgb: String`
- `softnessMode: ShadowSoftnessMode`

## 5. API ajoutée

```dart
enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
}

final class ShadowRuntimeRenderInstruction { ... }

ShadowRuntimeShapeKind shadowRuntimeShapeFromCasterMode(
  ShadowCasterMode mode,
);

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForPass(
  ShadowRenderPass pass,
);

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForInstruction(
  ShadowRuntimeRenderInstruction instruction,
);
```

## 6. Validations implémentées

`ShadowRuntimeRenderInstruction` valide :

- `worldLeft` fini ;
- `worldTop` fini ;
- `width` fini et strictement positif ;
- `height` fini et strictement positif ;
- `opacity` fini et entre `0` et `1` inclus ;
- `colorHexRgb` exactement 6 caracteres hexadecimaux RGB, sans `#` ;
- `colorHexRgb` normalise en uppercase ;
- `softnessMode == ShadowSoftnessMode.hardEdge`.

`shadowRuntimeShapeFromCasterMode` rejette `ShadowCasterMode.none`, car une
instruction runtime dessinable ne represente pas "rien".

Les validations utilisent `ValidationException` uniquement via
`package:map_core/map_core.dart`, qui exporte publiquement cette exception.
Aucun import `package:map_core/src/...` n'est ajoute.

## 7. Mapping vers le contrat de rendu Shadow-10

Le mapping vit dans le nouveau fichier Shadow-11, pas dans le contrat Shadow-10.

```text
ShadowRenderPass.groundStatic
-> RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows

ShadowRenderPass.actorContact
-> RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows
```

Les tests verifient ensuite que ces slots respectent le contrat Shadow-10 :

- static shadows apres terrain/paths/surfaces ;
- static shadows avant placed sprites/actors/occlusion/debug/HUD ;
- dynamic actor contact shadows avant actors/occlusion/debug/HUD.

## 8. Décisions d’implémentation

- L'instruction porte un rectangle monde final (`worldLeft`, `worldTop`,
  `width`, `height`) parce que le futur resolver runtime calculera cette
  geometrie depuis les positions monde, bounding boxes, footY et
  `ResolvedShadowConfig`. Shadow-11 ne calcule rien.
- L'instruction ne depend pas de Canvas/Paint/Flame pour rester une brique pure
  et testable avant tout renderer.
- La couleur reste `colorHexRgb + opacity`, pas un `Color` Flutter, pour eviter
  `dart:ui` et garder la convention Shadow V0.
- Aucun JSON n'est ajoute : cette instruction est runtime-only et non persistee.
- Aucun resolver n'est ajoute : pas de `MapData`, pas de `ProjectManifest`, pas
  de `ProjectElementEntry`, pas de `MapPlacedElement`.
- Aucun renderer n'est ajoute : pas de `drawOval`, pas de `drawPath`, pas de
  `drawImageRect`, pas de `ShadowLayerComponent`.
- L'API n'est pas exportee depuis `map_runtime.dart`, car les instructions
  runtime Surface comparables restent internes.

## 9. Tests ajoutés

`shadow_runtime_render_instruction_test.dart` couvre :

- creation valide `contactBlob` ;
- creation valide `ellipse` ;
- defaults `colorHexRgb = 000000` et `softnessMode = hardEdge` ;
- opacite `0` et `1` acceptees ;
- couleur lowercase normalisee en uppercase ;
- couleurs invalides rejetees ;
- coordonnees monde non finies rejetees ;
- `width` et `height` invalides rejetees ;
- opacite invalide rejetee ;
- V0 hardEdge seulement ;
- egalite de valeur et `hashCode` ;
- mapping `ShadowCasterMode.contactBlob` et `ellipse` ;
- rejet de `ShadowCasterMode.none`.

`shadow_runtime_render_order_mapping_test.dart` couvre :

- `groundStatic -> futureStaticPlacedElementShadows` ;
- `actorContact -> futureDynamicActorContactShadows` ;
- mapping d'une instruction via son `renderPass` ;
- ordre static shadows apres sol/surfaces et avant sprites/actors/occlusion ;
- ordre dynamic shadows avant actors/occlusion/debug/HUD.

### Code généré — instruction runtime

```dart
import 'package:map_core/map_core.dart';

import '../presentation/flame/shadow_runtime_render_order_contract.dart';

enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

/// Pure runtime draw instruction for one resolved V0 shadow.
///
/// The rectangle is already expressed in world coordinates. This model does
/// not resolve map data, load images, or draw anything.
final class ShadowRuntimeRenderInstruction {
  ShadowRuntimeRenderInstruction({
    required this.shape,
    required this.renderPass,
    required this.worldLeft,
    required this.worldTop,
    required this.width,
    required this.height,
    required this.opacity,
    String colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
  }) : colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
    _validateOpacity(opacity);
    _validateSoftnessMode(softnessMode);
  }

  final ShadowRuntimeShapeKind shape;
  final ShadowRenderPass renderPass;
  final double worldLeft;
  final double worldTop;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeRenderInstruction &&
          other.shape == shape &&
          other.renderPass == renderPass &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        shape,
        renderPass,
        worldLeft,
        worldTop,
        width,
        height,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

ShadowRuntimeShapeKind shadowRuntimeShapeFromCasterMode(
  ShadowCasterMode mode,
) {
  return switch (mode) {
    ShadowCasterMode.contactBlob => ShadowRuntimeShapeKind.contactBlob,
    ShadowCasterMode.ellipse => ShadowRuntimeShapeKind.ellipse,
    ShadowCasterMode.none => throw const ValidationException(
        'ShadowCasterMode.none cannot produce a drawable runtime shadow shape',
      ),
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForPass(
  ShadowRenderPass pass,
) {
  return switch (pass) {
    ShadowRenderPass.groundStatic =>
      RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
    ShadowRenderPass.actorContact =>
      RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) =>
    runtimeShadowRenderSlotForPass(instruction.renderPass);

String _normalizeColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
  return value.toUpperCase();
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be greater than 0',
    );
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateSoftnessMode(ShadowSoftnessMode value) {
  if (value != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.softnessMode only supports hardEdge in V0',
    );
  }
}
```

### Code généré — tests instruction

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeRenderInstruction', () {
    test('creates a valid contact blob instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.contactBlob,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.worldLeft, 12);
      expect(instruction.worldTop, 24);
      expect(instruction.width, 32);
      expect(instruction.height, 16);
      expect(instruction.opacity, 0.4);
    });

    test('creates a valid ellipse instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.ellipse,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('applies default color and softness', () {
      final instruction = _instruction();

      expect(instruction.colorHexRgb, '000000');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('accepts opacity bounds', () {
      expect(_instruction(opacity: 0).opacity, 0);
      expect(_instruction(opacity: 1).opacity, 1);
    });

    test('normalizes lowercase color to uppercase', () {
      final instruction = _instruction(colorHexRgb: '0a0b0c');

      expect(instruction.colorHexRgb, '0A0B0C');
    });

    test('rejects invalid colors', () {
      for (final color in <String>[
        '',
        '#000000',
        '00000',
        '0000000',
        'GGGGGG',
      ]) {
        expect(
          () => _instruction(colorHexRgb: color),
          throwsA(isA<ValidationException>()),
          reason: 'color $color should be rejected',
        );
      }
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _instruction(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid width', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(width: width),
          throwsA(isA<ValidationException>()),
          reason: 'width $width should be rejected',
        );
      }
    });

    test('rejects invalid height', () {
      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(height: height),
          throwsA(isA<ValidationException>()),
          reason: 'height $height should be rejected',
        );
      }
    });

    test('rejects invalid opacity', () {
      for (final opacity in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(opacity: opacity),
          throwsA(isA<ValidationException>()),
          reason: 'opacity $opacity should be rejected',
        );
      }
    });

    test('rejects non hard-edge softness in V0 if one appears later', () {
      for (final softnessMode in ShadowSoftnessMode.values) {
        if (softnessMode == ShadowSoftnessMode.hardEdge) {
          expect(_instruction(softnessMode: softnessMode).softnessMode,
              ShadowSoftnessMode.hardEdge);
        } else {
          expect(
            () => _instruction(softnessMode: softnessMode),
            throwsA(isA<ValidationException>()),
          );
        }
      }
    });

    test('has value equality and stable hashCode', () {
      final a = _instruction(colorHexRgb: '0a0b0c');
      final b = _instruction(colorHexRgb: '0A0B0C');
      final c = _instruction(opacity: 0.5);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('shadowRuntimeShapeFromCasterMode', () {
    test('maps contactBlob and ellipse', () {
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.contactBlob),
        ShadowRuntimeShapeKind.contactBlob,
      );
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.ellipse),
        ShadowRuntimeShapeKind.ellipse,
      );
    });

    test('rejects none because render instructions must be drawable', () {
      expect(
        () => shadowRuntimeShapeFromCasterMode(ShadowCasterMode.none),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### Code généré — tests mapping

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/shadow_runtime_render_order_contract.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('runtime shadow render order mapping', () {
    test('maps groundStatic to the static placed element shadow slot', () {
      expect(
        runtimeShadowRenderSlotForPass(ShadowRenderPass.groundStatic),
        RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
      );
    });

    test('maps actorContact to the dynamic actor contact shadow slot', () {
      expect(
        runtimeShadowRenderSlotForPass(ShadowRenderPass.actorContact),
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      );
    });

    test('maps an instruction through its render pass', () {
      final instruction = ShadowRuntimeRenderInstruction(
        shape: ShadowRuntimeShapeKind.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 0,
        worldTop: 0,
        width: 16,
        height: 8,
        opacity: 0.35,
      );

      expect(
        runtimeShadowRenderSlotForInstruction(instruction),
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      );
    });

    test(
        'keeps static shadows after ground and before sprites actors occlusion',
        () {
      const staticSlot =
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows;

      for (final lowerSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.baseTerrain,
        RuntimeShadowRenderOrderSlot.groundPaths,
        RuntimeShadowRenderOrderSlot.surfaceLayers,
      ]) {
        expect(runtimeShadowSlotIsBefore(lowerSlot, staticSlot), isTrue);
      }

      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.placedElementSprites,
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(runtimeShadowSlotIsBefore(staticSlot, upperSlot), isTrue);
      }
    });

    test('keeps dynamic actor shadows below actors occlusion debug and HUD',
        () {
      const dynamicSlot =
          RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows;

      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(runtimeShadowSlotIsBefore(dynamicSlot, upperSlot), isTrue);
      }
    });
  });
}
```

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
rg --files -g AGENTS.md
flutter test test/shadow/shadow_runtime_render_instruction_test.dart test/shadow/shadow_runtime_render_order_mapping_test.dart
dart format packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart test/shadow/shadow_runtime_render_order_mapping_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame/shadow_runtime_render_order_contract.dart test/shadow
cd packages/map_core && dart test test/shadow
cd packages/map_runtime && flutter test
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
rg -n "ShadowRuntimeResolver|ShadowLayerComponent|ShadowRenderer|resolveShadow|MapData|ProjectManifest|MapPlacedElement|ProjectElementEntry" packages/map_runtime/lib/src/shadow
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

Commande RED initiale :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart test/shadow/shadow_runtime_render_order_mapping_test.dart
```

Resultat RED attendu :

```text
Error when reading 'lib/src/shadow/shadow_runtime_render_instruction.dart': No such file or directory
Undefined name 'ShadowRuntimeShapeKind'
Method not found: 'runtimeShadowRenderSlotForPass'
Some tests failed.
```

Commande apres implementation :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart test/shadow/shadow_runtime_render_order_mapping_test.dart
```

Resultat :

```text
00:00 +19: All tests passed!
```

## 12. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Resultat :

```text
00:00 +24: All tests passed!
```

Commande optionnelle core :

```bash
cd packages/map_core && dart test test/shadow
```

Resultat :

```text
00:00 +152: All tests passed!
```

## 13. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame/shadow_runtime_render_order_contract.dart test/shadow
```

Resultat :

```text
Analyzing 3 items...
No issues found! (ran in 1.8s)
```

## 14. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Resultat :

```text
00:16 +945: All tests passed!
```

## 15. Vérifications anti-dérive

Commande :

```bash
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
```

Resultat :

```text
aucune sortie
```

Commande :

```bash
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
```

Resultat :

```text
aucune sortie
```

Commande :

```bash
rg -n "ShadowRuntimeResolver|ShadowLayerComponent|ShadowRenderer|resolveShadow|MapData|ProjectManifest|MapPlacedElement|ProjectElementEntry" packages/map_runtime/lib/src/shadow
```

Resultat :

```text
aucune sortie
```

Commande :

```bash
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
```

Resultat :

```text
aucune sortie
```

Confirmations :

- aucun `ShadowRuntimeResolver` ;
- aucun `ShadowLayerComponent` ;
- aucun `ShadowRenderer` ;
- aucun `Canvas` ;
- aucun `Paint` ;
- aucun `drawOval` / `drawPath` / `drawImageRect` ;
- aucun Flame Component ;
- aucun resolver `MapData` / `ProjectManifest` ;
- aucun `map_core` modifie ;
- aucun `map_editor` modifie ;
- aucun `map_gameplay` modifie ;
- aucune collision modifiee ;
- aucune occlusion modifiee ;
- aucun `visualMask` / `collisionMask` / `occlusionMask` / `cells` modifie ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder` / `zIndex` ;
- aucun time-of-day ;
- aucun custom shadow sprite ;
- aucun JSON / `toJson` / `fromJson`.

## 16. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Resultat initial :

```text
aucune sortie
```

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Resultat final :

```text
?? packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
?? packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
?? packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart
?? reports/shadows/shadow_lot_11_runtime_render_instruction.md
```

## 18. Git diff stat final

Commande :

```bash
git diff --stat
```

Resultat final :

```text
aucune sortie
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Le status final
liste donc les fichiers crees.

## 19. Non-objectifs respectés

- pas de renderer Shadow ;
- pas de Flame Component ;
- pas de `ShadowRuntimeResolver` ;
- pas de resolution `MapData` / `ProjectManifest` ;
- pas de lecture `ProjectElementEntry` / `MapPlacedElement` ;
- pas de dessin ;
- pas d'import Flutter ;
- pas d'import Flame ;
- pas d'import `dart:ui` ;
- pas de JSON ;
- pas d'export public V0 ;
- pas de modification de `map_core` ;
- pas de modification de `map_editor` ;
- pas de modification de `map_gameplay` ;
- pas de collision / occlusion / gameplay change.

## 20. Risques / réserves

- L'instruction porte un rectangle monde final, mais Shadow-11 ne calcule pas ce
  rectangle. Le futur resolver runtime devra definir les regles exactes de
  placement depuis `ResolvedShadowConfig` et les positions monde.
- Le mapping vers Shadow-10 est volontairement petit. Si de nouveaux
  `ShadowRenderPass` apparaissent, le `switch` exhaustif forcera une decision.
- L'instruction reste interne au package runtime. Un futur lot pourra l'exporter
  si une API publique devient necessaire.

## 21. Prochain lot recommandé

Shadow-12 — Runtime Shadow Resolver V0

Objectif futur : resoudre `ResolvedShadowConfig` + positions monde en
`ShadowRuntimeRenderInstruction[]`, sans encore elargir vers blur, z-order
libre, time-of-day ou custom shadow sprite.
