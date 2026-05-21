# Shadow Lot 15 — Runtime Shadow Instruction Collection / Culling V0

## 1. Résumé

Shadow-15 ajoute une collection runtime pure pour organiser et culler des `ShadowRuntimeRenderInstruction`.
Elle ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement`.
Elle ne modifie aucun composant Flame et ne dessine rien.

Le lot ajoute uniquement une brique de rangement runtime :

```text
instructions + optional culling bounds
-> collection organisée par renderPass
```

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart`
- `reports/shadows/shadow_lot_15_runtime_instruction_collection_culling.md`

## 3. Fichiers modifiés

Aucun fichier existant modifié.

## 4. API runtime ajoutée

```dart
ShadowRuntimeCullingBounds
ShadowRuntimeInstructionCollection
shadowRuntimeInstructionIntersectsBounds(...)
collectShadowRuntimeInstructions(...)
```

L'API reste interne à `map_runtime`; elle n'est pas exportée depuis `packages/map_runtime/lib/map_runtime.dart`.

## 5. Modèles runtime ajoutés

`ShadowRuntimeCullingBounds` :

- `worldLeft`
- `worldTop`
- `width`
- `height`
- `worldRight`
- `worldBottom`

`ShadowRuntimeInstructionCollection` :

- `instructions`
- `groundStatic`
- `actorContact`
- `isEmpty`
- `isNotEmpty`
- `length`

Les listes exposées sont défensivement copiées et immuables.

## 6. Règles de collection V0

- Ordre global préservé.
- Groupes par `renderPass`.
- Ordre intra-groupe préservé.
- Aucun tri.
- Aucune déduplication.
- `opacity == 0` conservée.
- Aucune instruction modifiée.
- `cullingPadding` validé même lorsque `cullingBounds == null`.

## 7. Règles de culling V0

Le culling utilise une intersection AABB en coordonnées monde.

Rectangle instruction :

```text
left = instruction.worldLeft
top = instruction.worldTop
right = instruction.worldLeft + instruction.width
bottom = instruction.worldTop + instruction.height
```

Bounds avec padding :

```text
left = bounds.worldLeft - padding
top = bounds.worldTop - padding
right = bounds.worldRight + padding
bottom = bounds.worldBottom + padding
```

Règles :

- instruction entièrement hors bounds -> filtrée;
- instruction entièrement dans bounds -> conservée;
- instruction partiellement dans bounds -> conservée;
- instruction qui touche exactement le bord -> conservée;
- bords inclusifs;
- culling géométrique uniquement;
- pas de culling par `opacity`;
- pas de culling par `renderPass`;
- pas de culling par `shape`.

## 8. Grouping par renderPass

```text
ShadowRenderPass.groundStatic
-> collection.groundStatic

ShadowRenderPass.actorContact
-> collection.actorContact
```

La collection principale `instructions` garde l'ordre global après culling. Les deux groupes gardent l'ordre relatif d'entrée dans leur passe.

## 9. Décisions d’implémentation

- La collection reçoit déjà des instructions, parce que les resolvers Shadow-12, Shadow-13 et Shadow-14 produisent les rectangles monde.
- Elle ne lit pas `MapData`.
- Elle ne lit pas `ProjectManifest`.
- Elle ne lit pas `ProjectElementEntry`.
- Elle ne lit pas `MapPlacedElement`.
- Elle ne trie pas, pour ne pas anticiper le futur renderer.
- Elle ne crée pas de `zOrder` ou `zIndex`.
- Elle ne dessine pas.
- Elle implémente une égalité de valeur simple via comparaison privée de listes, sans dépendance externe.
- Elle n'est pas exportée depuis `map_runtime.dart`, pour rester cohérente avec les briques Shadow runtime V0 précédentes.

## 10. Tests ajoutés

Fichier ajouté :

- `packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart`

Couverture :

- création de bounds valides;
- `worldRight` et `worldBottom`;
- rejet des coordonnées non finies;
- rejet des dimensions invalides;
- égalité de valeur des bounds;
- culling AABB entièrement visible;
- culling AABB partiellement visible sur chaque côté;
- bords inclusifs;
- rejet entièrement hors bounds sur chaque côté;
- padding positif;
- padding invalide;
- collection vide;
- collection d'une instruction;
- ordre global préservé;
- copie défensive;
- listes immuables;
- grouping `groundStatic`;
- grouping `actorContact`;
- ordre intra-groupe préservé;
- absence de déduplication;
- `opacity == 0` conservée;
- validation de `cullingPadding` même sans bounds;
- égalité de valeur de la collection;
- culling + grouping combinés.

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_instruction_collection_test.dart
cd packages/map_runtime && dart format lib/src/shadow/shadow_runtime_instruction_collection.dart test/shadow/shadow_runtime_instruction_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_instruction_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow
rg -n "Canvas|Paint|drawOval|drawPath|drawImageRect|drawAtlas|saveLayer|ImageFilter|Flame|Component" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
rg -n "ShadowLayerComponent|ShadowRenderer|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig|RuntimeTilesetImage|TileImageLoader" packages/map_runtime/lib/src/shadow
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile" packages/map_runtime/lib/src/shadow
git diff --check
git diff --stat
git status --short --untracked-files=all
```

La première exécution du test ciblé était le RED TDD attendu : compilation en échec car `shadow_runtime_instruction_collection.dart` n'existait pas encore.

## 12. Résultats des tests ciblés

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_instruction_collection_test.dart
```

Résultat final :

```text
00:00 +23: All tests passed!
```

## 13. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final :

```text
00:00 +112: All tests passed!
```

## 14. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat final :

```text
No issues found! (ran in 1.6s)
```

## 15. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat final :

```text
00:18 +1033: All tests passed!
```

Commande complémentaire :

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
?? packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
?? packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
?? reports/shadows/shadow_lot_15_runtime_instruction_collection_culling.md
```

## 19. Git diff stat final

`git diff --stat` ne liste pas les fichiers non suivis. Résultat :

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

- Le culling est volontairement strictement géométrique. Un futur renderer pourra ajouter des optimisations par opacité ou taille écran si nécessaire.
- La collection ne trie pas les instructions; le futur renderer devra respecter le contrat Shadow-10 au moment de consommer `groundStatic` et `actorContact`.
- Le padding est exprimé en unités monde; un futur lot devra décider comment dériver ce padding depuis la caméra ou le viewport réel.

## 22. Contenu complet des fichiers créés/modifiés

Le contenu complet des deux fichiers code/test Shadow-15 est inclus ci-dessous. Le rapport lui-même n'est pas inclus récursivement pour éviter une boucle infinie de contenu.

### `packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart`

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

/// World-space rectangle used to cull runtime shadow instructions.
final class ShadowRuntimeCullingBounds {
  ShadowRuntimeCullingBounds({
    required this.worldLeft,
    required this.worldTop,
    required this.width,
    required this.height,
  }) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
  }

  final double worldLeft;
  final double worldTop;
  final double width;
  final double height;

  double get worldRight => worldLeft + width;

  double get worldBottom => worldTop + height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeCullingBounds &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(
        worldLeft,
        worldTop,
        width,
        height,
      );
}

/// Immutable runtime shadow instruction grouping after optional culling.
final class ShadowRuntimeInstructionCollection {
  ShadowRuntimeInstructionCollection({
    Iterable<ShadowRuntimeRenderInstruction> instructions = const [],
  }) : this._fromList(List<ShadowRuntimeRenderInstruction>.of(instructions));

  ShadowRuntimeInstructionCollection._fromList(
    List<ShadowRuntimeRenderInstruction> source,
  )   : instructions = List<ShadowRuntimeRenderInstruction>.unmodifiable(
          source,
        ),
        groundStatic = List<ShadowRuntimeRenderInstruction>.unmodifiable(
          source.where(
            (instruction) =>
                instruction.renderPass == ShadowRenderPass.groundStatic,
          ),
        ),
        actorContact = List<ShadowRuntimeRenderInstruction>.unmodifiable(
          source.where(
            (instruction) =>
                instruction.renderPass == ShadowRenderPass.actorContact,
          ),
        );

  final List<ShadowRuntimeRenderInstruction> instructions;
  final List<ShadowRuntimeRenderInstruction> groundStatic;
  final List<ShadowRuntimeRenderInstruction> actorContact;

  bool get isEmpty => instructions.isEmpty;

  bool get isNotEmpty => instructions.isNotEmpty;

  int get length => instructions.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeInstructionCollection &&
          _listEquals(other.instructions, instructions);

  @override
  int get hashCode => Object.hashAll(instructions);
}

bool shadowRuntimeInstructionIntersectsBounds(
  ShadowRuntimeRenderInstruction instruction,
  ShadowRuntimeCullingBounds bounds, {
  double padding = 0,
}) {
  _validatePadding(padding);

  final instructionRight = instruction.worldLeft + instruction.width;
  final instructionBottom = instruction.worldTop + instruction.height;
  final paddedLeft = bounds.worldLeft - padding;
  final paddedTop = bounds.worldTop - padding;
  final paddedRight = bounds.worldRight + padding;
  final paddedBottom = bounds.worldBottom + padding;

  return instructionRight >= paddedLeft &&
      instruction.worldLeft <= paddedRight &&
      instructionBottom >= paddedTop &&
      instruction.worldTop <= paddedBottom;
}

ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions, {
  ShadowRuntimeCullingBounds? cullingBounds,
  double cullingPadding = 0,
}) {
  _validatePadding(cullingPadding);

  final retained = <ShadowRuntimeRenderInstruction>[];
  for (final instruction in instructions) {
    if (cullingBounds == null ||
        shadowRuntimeInstructionIntersectsBounds(
          instruction,
          cullingBounds,
          padding: cullingPadding,
        )) {
      retained.add(instruction);
    }
  }
  return ShadowRuntimeInstructionCollection(instructions: retained);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeCullingBounds.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeCullingBounds.$name must be greater than 0',
    );
  }
}

void _validatePadding(double value) {
  if (!value.isFinite || value < 0) {
    throw const ValidationException(
      'Shadow runtime culling padding must be finite and greater than or equal to 0',
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
```

### `packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeCullingBounds', () {
    test('creates valid bounds and derives right and bottom edges', () {
      final bounds = _bounds();

      expect(bounds.worldLeft, 0);
      expect(bounds.worldTop, 0);
      expect(bounds.width, 100);
      expect(bounds.height, 80);
      expect(bounds.worldRight, 100);
      expect(bounds.worldBottom, 80);
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _bounds(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _bounds(width: width),
          throwsA(isA<ValidationException>()),
          reason: 'width $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _bounds(height: height),
          throwsA(isA<ValidationException>()),
          reason: 'height $height should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _bounds();
      final b = _bounds();
      final c = _bounds(worldLeft: 1);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('shadowRuntimeInstructionIntersectsBounds', () {
    test('keeps instructions fully inside bounds', () {
      expect(
        shadowRuntimeInstructionIntersectsBounds(_instruction(), _bounds()),
        isTrue,
      );
    });

    test('keeps partially visible instructions on every side', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -5, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 95, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -5, height: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 75, height: 10),
          bounds,
        ),
        isTrue,
      );
    });

    test('keeps instructions touching each edge exactly', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -10, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 100, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -10, height: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 80, height: 10),
          bounds,
        ),
        isTrue,
      );
    });

    test('filters instructions fully outside each side', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -11, width: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 101, width: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -11, height: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 81, height: 10),
          bounds,
        ),
        isFalse,
      );
    });

    test('uses padding to keep instructions just outside bounds', () {
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 105, width: 10),
          _bounds(),
          padding: 5,
        ),
        isTrue,
      );
    });

    test('rejects invalid padding', () {
      for (final padding in <double>[
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => shadowRuntimeInstructionIntersectsBounds(
            _instruction(),
            _bounds(),
            padding: padding,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'padding $padding should be rejected',
        );
      }
    });
  });

  group('ShadowRuntimeInstructionCollection without culling', () {
    test('creates an empty collection', () {
      final collection = collectShadowRuntimeInstructions(const []);

      expect(collection.isEmpty, isTrue);
      expect(collection.isNotEmpty, isFalse);
      expect(collection.length, 0);
      expect(collection.instructions, isEmpty);
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, isEmpty);
    });

    test('collects one instruction', () {
      final instruction = _instruction();

      final collection = collectShadowRuntimeInstructions([instruction]);

      expect(collection.isEmpty, isFalse);
      expect(collection.isNotEmpty, isTrue);
      expect(collection.length, 1);
      expect(collection.instructions, [instruction]);
    });

    test('preserves global input order without sorting by renderPass', () {
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 30,
      );
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );

      final collection = collectShadowRuntimeInstructions([actor, ground]);

      expect(collection.instructions, [actor, ground]);
    });

    test('copies instructions defensively and exposes immutable lists', () {
      final first = _instruction(worldLeft: 10);
      final second = _instruction(worldLeft: 20);
      final source = [first];

      final collection = collectShadowRuntimeInstructions(source);
      source.add(second);

      expect(collection.instructions, [first]);
      expect(() => collection.instructions.add(second), throwsUnsupportedError);
      expect(() => collection.groundStatic.add(second), throwsUnsupportedError);
      expect(() => collection.actorContact.add(second), throwsUnsupportedError);
    });

    test('groups instructions by renderPass while preserving group order', () {
      final groundA = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );
      final actorA = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 20,
      );
      final groundB = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );
      final actorB = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 40,
      );

      final collection = collectShadowRuntimeInstructions([
        groundA,
        actorA,
        groundB,
        actorB,
      ]);

      expect(collection.groundStatic, [groundA, groundB]);
      expect(collection.actorContact, [actorA, actorB]);
    });

    test('does not deduplicate equal instructions', () {
      final instruction = _instruction();

      final collection = collectShadowRuntimeInstructions([
        instruction,
        instruction,
      ]);

      expect(collection.instructions, [instruction, instruction]);
      expect(collection.length, 2);
    });

    test('keeps opacity zero instructions', () {
      final instruction = _instruction(opacity: 0);

      final collection = collectShadowRuntimeInstructions([instruction]);

      expect(collection.instructions, [instruction]);
      expect(collection.instructions.single.opacity, 0);
    });

    test('rejects invalid cullingPadding even without bounds', () {
      for (final padding in <double>[
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => collectShadowRuntimeInstructions(
            [_instruction()],
            cullingPadding: padding,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'cullingPadding $padding should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = collectShadowRuntimeInstructions([_instruction()]);
      final b = collectShadowRuntimeInstructions([_instruction()]);
      final c = collectShadowRuntimeInstructions([
        _instruction(worldLeft: 11),
      ]);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('collectShadowRuntimeInstructions with culling', () {
    test('filters outside instructions and keeps visible instructions', () {
      final inside = _instruction(worldLeft: 10, worldTop: 10);
      final outside = _instruction(worldLeft: 200, worldTop: 10);

      final collection = collectShadowRuntimeInstructions(
        [inside, outside],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [inside]);
    });

    test('keeps partially visible and edge-touching instructions', () {
      final partial = _instruction(worldLeft: -5, width: 10);
      final touching = _instruction(worldLeft: 100, width: 10);

      final collection = collectShadowRuntimeInstructions(
        [partial, touching],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [partial, touching]);
    });

    test('preserves visible order and groups after culling', () {
      final actorOutside = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 200,
      );
      final groundA = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );
      final actorA = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 20,
      );
      final groundB = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );

      final collection = collectShadowRuntimeInstructions(
        [
          actorOutside,
          groundA,
          actorA,
          groundB,
        ],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [groundA, actorA, groundB]);
      expect(collection.groundStatic, [groundA, groundB]);
      expect(collection.actorContact, [actorA]);
    });

    test('uses cullingPadding and does not deduplicate', () {
      final paddedVisible = _instruction(worldLeft: 105, width: 10);

      final collection = collectShadowRuntimeInstructions(
        [
          paddedVisible,
          paddedVisible,
        ],
        cullingBounds: _bounds(),
        cullingPadding: 5,
      );

      expect(collection.instructions, [paddedVisible, paddedVisible]);
    });
  });
}

ShadowRuntimeCullingBounds _bounds({
  double worldLeft = 0,
  double worldTop = 0,
  double width = 100,
  double height = 80,
}) {
  return ShadowRuntimeCullingBounds(
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
  );
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 10,
  double worldTop = 10,
  double width = 10,
  double height = 10,
  double opacity = 0.35,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: renderPass == ShadowRenderPass.actorContact
        ? ShadowRuntimeShapeKind.contactBlob
        : ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
  );
}
```

## 23. Autocritique

- Potentiellement trop strict : `cullingPadding` invalide est rejeté même sans `cullingBounds`; c'est volontaire pour éviter des appels incohérents silencieux.
- Potentiellement trop permissif : `opacity == 0` reste conservée; c'est cohérent avec les lots précédents, mais le renderer ou un futur collector optimisé pourra faire du culling d'opacité.
- À revoir lors du vrai renderer : le padding devrait peut-être dépendre de la caméra et de la taille des sprites/ombres, pas d'une constante fournie à la main.
- Choix discutable : l'égalité de collection compare seulement `instructions`, car `groundStatic` et `actorContact` sont dérivés. C'est simple et évite une triple comparaison redondante.

## 24. Prochain lot recommandé

Shadow-16 — Flame Shadow Renderer V0
