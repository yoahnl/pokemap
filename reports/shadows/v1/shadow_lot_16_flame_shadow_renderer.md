# Shadow Lot 16 — Flame Shadow Renderer V0

## 1. Résumé

Shadow-16 ajoute un renderer runtime isolé capable de dessiner des `ShadowRuntimeRenderInstruction` sur un `Canvas`.
Il ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement`.
Il ne modifie aucun composant Flame existant.

Le lot ajoute uniquement la brique :

```text
ShadowRuntimeRenderInstruction / ShadowRuntimeInstructionCollection
-> Canvas.drawOval(...)
```

## 2. Fichiers créés

- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`
- `reports/shadows/shadow_lot_16_flame_shadow_renderer.md`

Inventaire complet :

```text
Créés:
- packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
- packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
- reports/shadows/shadow_lot_16_flame_shadow_renderer.md

Modifiés:
- Aucun

Supprimés:
- Aucun

Générés:
- Aucun

Encore non suivis touchés par le lot:
- packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
- packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
- reports/shadows/shadow_lot_16_flame_shadow_renderer.md
```

## 3. Fichiers modifiés

Aucun fichier existant modifié.

## 4. API runtime ajoutée

```dart
ShadowRuntimeRenderer
ShadowRuntimeRenderer.renderInstruction(...)
ShadowRuntimeRenderer.renderInstructions(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
shadowRuntimeColorForInstruction(...)
shadowRuntimePaintForInstruction(...)
```

L'API reste interne à `map_runtime`; elle n'est pas exportée depuis `packages/map_runtime/lib/map_runtime.dart`.

## 5. Règles de rendu V0

- `ShadowRuntimeShapeKind.ellipse` -> `Canvas.drawOval`.
- `ShadowRuntimeShapeKind.contactBlob` -> `Canvas.drawOval`.
- Le rectangle de dessin vient de `Rect.fromLTWH(worldLeft, worldTop, width, height)`.
- Le rendu utilise `PaintingStyle.fill`.
- Le rendu utilise `isAntiAlias = false`.
- Le rendu est `hardEdge` only.
- Aucun blur.
- Aucun `saveLayer`.
- Aucune image.
- Aucun atlas.
- Aucun tri.
- Aucun culling.
- Aucun `zOrder` / `zIndex`.

## 6. Conversion couleur / paint

`colorHexRgb` est lu comme RGB `RRGGBB`.
`opacity` est convertie en alpha entier stable avec :

```text
alpha = (opacity * 255).round().clamp(0, 255)
```

Exemples testés :

- `336699 + opacity 1` -> `0xFF336699`
- `336699 + opacity 0` -> `0x00336699`
- `000000 + opacity 0.35` -> `0x59000000`

Le choix `Color((alpha << 24) | rgb)` évite une dépendance à un arrondi implicite de `withValues`.
Le test du `Paint.color` compare `toARGB32()` car `Paint` peut restituer une couleur équivalente dont l'égalité objet est plus stricte que la comparaison ARGB.

## 7. Rendu par collection/pass

`renderCollectionPass(...)` sélectionne uniquement le groupe demandé :

```text
ShadowRenderPass.groundStatic -> collection.groundStatic
ShadowRenderPass.actorContact -> collection.actorContact
```

Le renderer :

- ne trie pas;
- ne cull pas;
- ne déduplique pas;
- ne crée aucun ordre libre;
- laisse l'appelant futur choisir le moment d'appel dans la pile de rendu.

## 8. Décisions d’implémentation

- Le renderer reçoit déjà des instructions monde, donc il ne lit pas `MapData`.
- Le renderer ne lit pas `ProjectManifest`.
- Le renderer ne lit pas `ProjectElementEntry`.
- Le renderer ne lit pas `MapPlacedElement`.
- Le renderer ne résout pas de profil Shadow.
- Le renderer ne trie pas, car Shadow-10 et Shadow-15 séparent déjà les responsabilités d'ordre et de grouping.
- Le renderer ne cull pas, car Shadow-15 porte déjà cette responsabilité.
- Le renderer ne crée pas de `Flame Component`, pour rester testable isolément.
- Le renderer n'est pas branché à `MapLayersComponent`; ce branchement appartient au lot suivant.
- Le renderer n'est pas exporté depuis `map_runtime.dart`, comme les briques Shadow runtime V0 précédentes.

## 9. Tests ajoutés

Fichier ajouté :

- `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`

Couverture :

- conversion `colorHexRgb + opacity`;
- alpha stable pour `opacity 0.35`;
- `PaintingStyle.fill`;
- `isAntiAlias = false`;
- `hardEdge` accepté;
- ellipse dessinée avec centre visible;
- pixel hors rectangle transparent;
- `contactBlob` dessiné par le même chemin V0;
- `opacity 0` transparente au centre;
- `renderInstructions` conserve l'ordre d'entrée;
- `renderCollectionPass(groundStatic)` ne dessine que `groundStatic`;
- `renderCollectionPass(actorContact)` ne dessine que `actorContact`.

Le RED TDD a été observé avant implémentation : le test échouait à la compilation parce que `shadow_runtime_renderer.dart` n'existait pas encore.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && dart format lib/src/shadow/shadow_runtime_renderer.dart test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow
rg -n "ShadowLayerComponent|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig|RuntimeTilesetImage|TileImageLoader" packages/map_runtime/lib/src/shadow
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" packages/map_runtime/lib/src/shadow
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
rg -n "Canvas|Paint|drawOval|Rect|Color" packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

Commande RED :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
```

Résultat RED attendu :

```text
Error when reading 'lib/src/shadow/shadow_runtime_renderer.dart': No such file or directory
Method not found: 'shadowRuntimeColorForInstruction'
Method not found: 'shadowRuntimePaintForInstruction'
Couldn't find constructor 'ShadowRuntimeRenderer'
Some tests failed.
```

Commande finale :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
```

Résultat final :

```text
00:00 +11: All tests passed!
```

## 12. Résultat de flutter test test/shadow

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final :

```text
00:00 +123: All tests passed!
```

## 13. Résultat de flutter analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat final :

```text
No issues found! (ran in 1.6s)
```

## 14. Résultat du test complet map_runtime

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat final :

```text
00:17 +1044: All tests passed!
```

Commande optionnelle :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final :

```text
00:00 +152: All tests passed!
```

## 15. Vérifications anti-dérive

Commandes sans sortie :

```bash
rg -n "ShadowLayerComponent|MapLayersComponent|PlayableMapGame|RuntimeMapGame|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "MapData|ProjectManifest|ProjectElementEntry|MapPlacedElement|resolveShadowConfig|RuntimeTilesetImage|TileImageLoader" packages/map_runtime/lib/src/shadow
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" packages/map_runtime/lib/src/shadow
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow
```

Occurrences autorisées et limitées au renderer Shadow-16 et à son test :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

Confirmation :

- aucun `ShadowLayerComponent`;
- aucun `Flame Component`;
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
- aucun `RuntimeTilesetImage`;
- aucun `TileImageLoader`;
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
- aucun `build_runner`.

## 16. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
Aucune sortie.
```

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat attendu après création de ce rapport :

```text
?? packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
?? packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
?? reports/shadows/shadow_lot_16_flame_shadow_renderer.md
```

## 18. Git diff stat final

Commande :

```bash
git diff --stat
```

Résultat :

```text
Aucune sortie, car les fichiers Shadow-16 sont encore non suivis.
```

## 19. Non-objectifs respectés

- Pas de branchement dans `MapLayersComponent`.
- Pas de branchement dans `PlayableMapGame`.
- Pas de branchement dans `RuntimeMapGame`.
- Pas de modification de `PlayerComponent`.
- Pas de modification de `OverworldActorComponent`.
- Pas de modification de `PlacedElementOcclusionPatchComponent`.
- Pas de lecture `MapData`.
- Pas de lecture `ProjectManifest`.
- Pas de lecture `ProjectElementEntry`.
- Pas de lecture `MapPlacedElement`.
- Pas de resolver.
- Pas de culling dans le renderer.
- Pas de tri.
- Pas de `zOrder`.
- Pas de blur.
- Pas de sprite / image / atlas.
- Pas de JSON.
- Pas d'UI.

## 20. Risques / réserves

- Les tests pixel restent volontairement légers pour éviter des snapshots fragiles.
- `ellipse` et `contactBlob` partagent le même `drawOval` en V0; leur différence visuelle vient des métriques produites en amont.
- L'alpha utilise un arrondi ARGB stable; si un futur renderer adopte un pipeline color-space plus avancé, ces tests devront rester centrés sur le contrat V0.
- Le renderer n'étant pas encore intégré, aucune ombre n'est visible dans la carte runtime à ce lot.

## 21. Contenu complet des fichiers créés/modifiés

### `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`

```dart
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

final class ShadowRuntimeRenderer {
  const ShadowRuntimeRenderer();

  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    final rect = ui.Rect.fromLTWH(
      instruction.worldLeft,
      instruction.worldTop,
      instruction.width,
      instruction.height,
    );
    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
  }

  void renderInstructions(
    ui.Canvas canvas,
    Iterable<ShadowRuntimeRenderInstruction> instructions,
  ) {
    for (final instruction in instructions) {
      renderInstruction(canvas, instruction);
    }
  }

  void renderCollectionPass(
    ui.Canvas canvas,
    ShadowRuntimeInstructionCollection collection,
    ShadowRenderPass pass,
  ) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    renderInstructions(canvas, instructions);
  }
}

ui.Color shadowRuntimeColorForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  final rgb = int.parse(instruction.colorHexRgb, radix: 16);
  final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
  return ui.Color((alpha << 24) | rgb);
}

ui.Paint shadowRuntimePaintForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  _validateHardEdge(instruction);
  return ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = false
    ..color = shadowRuntimeColorForInstruction(instruction);
}

void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
  if (instruction.softnessMode != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderer only supports hardEdge shadows in V0',
    );
  }
}
```

### `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shadowRuntimeColorForInstruction', () {
    test('converts RGB hex and opacity to runtime color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 1),
      );

      expect(color, const ui.Color(0xFF336699));
    });

    test('converts opacity zero to transparent color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 0),
      );

      expect(color, const ui.Color(0x00336699));
    });

    test('uses stable rounded alpha for fractional opacity', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '000000', opacity: 0.35),
      );

      expect(color, const ui.Color(0x59000000));
    });
  });

  group('shadowRuntimePaintForInstruction', () {
    test('creates a hard-edge fill paint', () {
      final paint = shadowRuntimePaintForInstruction(_instruction());

      expect(paint.style, ui.PaintingStyle.fill);
      expect(paint.isAntiAlias, isFalse);
      expect(paint.color.toARGB32(), 0x59000000);
    });

    test('accepts hardEdge softness', () {
      expect(
        () => shadowRuntimePaintForInstruction(
          _instruction(softnessMode: ShadowSoftnessMode.hardEdge),
        ),
        returnsNormally,
      );
    });
  });

  group('ShadowRuntimeRenderer.renderInstruction', () {
    test('draws an ellipse with visible center and transparent outside pixels',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.ellipse,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('draws contactBlob through the same V0 oval path', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.contactBlob,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps opacity zero transparent at the center', () async {
      final image = await _renderInstruction(
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 0,
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });
  });

  group('ShadowRuntimeRenderer.renderInstructions', () {
    test('draws multiple instructions in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
        ),
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 6, 6), _rgba(0, 0, 255, 255));
    });
  });

  group('ShadowRuntimeRenderer.renderCollectionPass', () {
    test('draws only groundStatic instructions for the groundStatic pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.groundStatic,
      );

      expect(await _alphaAt(image, 6, 6), greaterThan(0));
      expect(await _alphaAt(image, 18, 6), 0);
    });

    test('draws only actorContact instructions for the actorContact pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 6, 6), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double worldTop = 0,
  double width = 8,
  double height = 4,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

Future<ui.Image> _renderInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  return _renderInstructions([instruction]);
}

Future<ui.Image> _renderInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderInstructions(canvas, instructions);
  return recorder.endRecording().toImage(24, 16);
}

Future<ui.Image> _renderCollectionPass(
  ShadowRuntimeInstructionCollection collection,
  ShadowRenderPass pass,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
  return recorder.endRecording().toImage(24, 16);
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  return (await _rgbaAt(image, x, y))[3];
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
```

Le rapport lui-même n'est pas ré-inclus ici pour éviter une copie récursive.

## 22. Autocritique

- Le renderer V0 est volontairement strict : seulement `drawOval`, seulement `hardEdge`, pas de blur.
- Les tests pixel ne vérifient pas une image complète, seulement des pixels témoins; c'est moins exhaustif mais plus robuste.
- `ellipse` et `contactBlob` partagent le même dessin; si une direction artistique demande une forme différente, un futur lot devra l'ajouter explicitement.
- Le renderer ne sait pas encore où s'insérer dans la pile Flame; Shadow-17 devra respecter le contrat Shadow-10.
- Le choix d'alpha ARGB arrondi est stable mais devra rester documenté si Flutter change ses APIs couleur.

## 23. Prochain lot recommandé

```text
Shadow-17 — Runtime Shadow Renderer Integration V0
```

Ne pas l'implémenter dans Shadow-16.
