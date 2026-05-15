# Shadow Lot 20 — Runtime Static Placed Element Shadow Collection Builder V0

## 1. Résumé du lot

Shadow-20 ajoute une brique runtime pure qui construit une `ShadowRuntimeInstructionCollection` pour les ombres `groundStatic` d'éléments statiques placés, à partir de sources déjà préparées.

Le lot combine un `ProjectShadowCatalog`, une config élément optionnelle, un override placé optionnel et des métriques runtime statiques. Il délègue la résolution de config à `resolveShadowConfig(...)`, puis la géométrie au resolver statique Shadow-14.

Ce lot ne câble pas `PlayableMapGame`, `RuntimeMapGame` ou `MapLayersComponent`. Il ne traite aucun acteur, ne crée aucun renderer, ne crée aucun Flame Component, ne lit pas `MapData` ou `ProjectManifest`, et ne parcourt pas les éléments de carte.

## 2. Design retenu

Le design retenu est un builder pur dans :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
```

Il expose :

```dart
RuntimeStaticPlacedElementShadowSource
buildRuntimeStaticPlacedElementShadowCollection(...)
```

Le builder reçoit uniquement des sources déjà préparées. Le futur host runtime préparera ces sources depuis `ProjectElementEntry` / `MapPlacedElement`, mais ce lot ne fait pas ce câblage.

Flux implémenté :

```text
RuntimeStaticPlacedElementShadowSource[]
→ ignore isVisible=false
→ resolveShadowConfig(catalog, elementShadow, placedOverride)
→ ignore resolved == null
→ StaticPlacedElementShadowRuntimeInput
→ resolveStaticPlacedElementShadowRuntimeInstructions(...)
→ ShadowRuntimeInstructionCollection
```

## 3. Fichiers créés

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
```

## 4. Fichiers modifiés

Aucun fichier existant n'est modifié en état final.

Une réécriture transitoire de `examples/playable_runtime_host/ios/Runner.xcodeproj/project.pbxproj` a été détectée après les tests Flutter. Le statut initial du lot ne contenait pas ce fichier. Le diff a été inspecté, puis remis à zéro par patch ciblé sans commande Git d'écriture. Le diff final de ce fichier est vide.

## 5. Fichiers non modifiés explicitement

Ces fichiers et dossiers sont restés hors lot :

```text
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
```

Fichier hors lot préexistant, non modifié :

```text
reports/collision/collision_system_audit_v0.md
```

## 6. API runtime ajoutée

```dart
final class RuntimeStaticPlacedElementShadowSource

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollection({
  required ProjectShadowCatalog catalog,
  required Iterable<RuntimeStaticPlacedElementShadowSource> sources,
})
```

`RuntimeStaticPlacedElementShadowSource` contient :

```text
id
elementId
elementShadow
placedOverride
metrics
isVisible
```

L'API reste interne à `map_runtime/src/shadow`. Aucun export public n'a été ajouté dans `packages/map_runtime/lib/map_runtime.dart`.

## 7. Règles de résolution static placed element

Le builder parcourt les sources dans l'ordre d'entrée. Pour chaque source visible, il appelle :

```dart
resolveShadowConfig(
  catalog: catalog,
  elementShadow: source.elementShadow,
  placedOverride: source.placedOverride,
)
```

Si `resolution.resolved == null`, la source est ignorée. Sinon, la résolution est transformée en `StaticPlacedElementShadowRuntimeInput`, puis le builder délègue à :

```dart
resolveStaticPlacedElementShadowRuntimeInstructions(inputs)
```

Le builder ne réimplémente pas la géométrie de Shadow-14.

## 8. Gestion des overrides

Les tests couvrent :

```text
placedOverride == null
placedOverride inherit
placedOverride disabled
placedOverride custom avec offset/scale/opacity
placedOverride custom avec shadowProfileId
placedOverride custom sans shadowProfileId
```

Le comportement vient de `resolveShadowConfig(...)`. Shadow-20 ne duplique pas les règles de merge.

## 9. Gestion des profils manquants / mode none / castsShadow false

Comportements V0 :

```text
elementShadow == null -> aucune instruction
castsShadow == false -> aucune instruction
profil manquant -> aucune instruction
mode none -> aucune instruction
opacity 0 -> instruction conservée si produite
actorContact -> ValidationException du resolver statique, non masquée
```

Les diagnostics de `resolveShadowConfig(...)` sont ignorés par le builder quand `resolved == null`. Cette limite est volontaire pour V0 : aucun système de diagnostics runtime n'est créé dans ce lot.

## 10. Pourquoi ce lot ne câble pas encore le runtime host

Shadow-20 doit seulement forger la brique pure. Brancher les éléments statiques dans `PlayableMapGame`, `RuntimeMapGame` ou `MapLayersComponent` impliquerait de parcourir les éléments de carte, préparer les sources et décider du cycle de rafraîchissement. Ce sera le rôle d'un futur Shadow-21.

## 11. Pourquoi ce lot ne traite pas les acteurs

Les ombres acteur sont déjà couvertes par Shadow-19 via `runtime_actor_contact_shadow_collection.dart`. Shadow-20 reste strictement sur les ombres statiques `groundStatic` et n'appelle aucun resolver acteur.

## 12. Tests ajoutés

Fichier ajouté :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Couverture :

```text
source visible + ellipse groundStatic
source visible + contactBlob groundStatic
source invisible
elementShadow null
castsShadow false
override disabled
override inherit
override custom offset/scale/opacity
override custom avec shadowProfileId
override custom sans shadowProfileId
mode none
profil manquant
opacity 0 conservée
ordre préservé
pas de déduplication
actorContact rejeté
id vide rejeté
elementId vide rejeté
listes immuables
égalité de valeur de source
```

## 13. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && dart format lib/src/shadow/runtime_static_placed_element_shadow_collection.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow
cd packages/map_runtime && rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
cd packages/map_runtime && rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
cd packages/map_runtime && rg -n "resolveActorContactShadow|ActorContactShadow|PlayerComponent|OverworldActorComponent" lib/src/presentation/flame lib/src/shadow
cd packages/map_runtime && rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow|resolveActorContactShadow|ActorContactShadow"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
git diff --no-index -- /dev/null packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart | rg -n "resolveShadowConfig|resolveStaticPlacedElementShadow|ProjectShadowCatalog|ProjectElementShadowConfig|MapPlacedElementShadowOverride"
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
git diff --no-index --stat -- /dev/null packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
git diff --no-index --stat -- /dev/null packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
git diff -- examples/playable_runtime_host/ios/Runner.xcodeproj/project.pbxproj
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
git diff --no-index --check -- /dev/null packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
git diff --no-index --check -- /dev/null packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
git diff --no-index --check -- /dev/null reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
```

## 14. Résultats complets des tests ciblés

Premier run RED avant création du fichier :

```text
Error when reading 'lib/src/shadow/runtime_static_placed_element_shadow_collection.dart': No such file or directory
Type 'RuntimeStaticPlacedElementShadowSource' not found.
Method not found: 'buildRuntimeStaticPlacedElementShadowCollection'.
Some tests failed.
```

Run après implémentation finale :

```text
00:00 +0: RuntimeStaticPlacedElementShadowSource uses value equality and matching hashCode
00:00 +1: RuntimeStaticPlacedElementShadowSource rejects blank ids
00:00 +2: RuntimeStaticPlacedElementShadowSource rejects blank element ids
00:00 +3: buildRuntimeStaticPlacedElementShadowCollection visible active element shadow with ellipse groundStatic creates one instruction
00:00 +4: buildRuntimeStaticPlacedElementShadowCollection contactBlob groundStatic profile creates a groundStatic instruction
00:00 +5: buildRuntimeStaticPlacedElementShadowCollection invisible source creates no instruction
00:00 +6: buildRuntimeStaticPlacedElementShadowCollection null element shadow creates no instruction
00:00 +7: buildRuntimeStaticPlacedElementShadowCollection castsShadow false creates no instruction
00:00 +8: buildRuntimeStaticPlacedElementShadowCollection disabled placed override creates no instruction
00:00 +9: buildRuntimeStaticPlacedElementShadowCollection inherit placed override keeps the element profile
00:00 +10: buildRuntimeStaticPlacedElementShadowCollection custom placed override applies offset scale and opacity
00:00 +11: buildRuntimeStaticPlacedElementShadowCollection custom placed override with shadowProfileId uses the override profile
00:00 +12: buildRuntimeStaticPlacedElementShadowCollection custom placed override without shadowProfileId keeps the element profile
00:00 +13: buildRuntimeStaticPlacedElementShadowCollection none profile creates no instruction
00:00 +14: buildRuntimeStaticPlacedElementShadowCollection missing profile creates no instruction in V0
00:00 +15: buildRuntimeStaticPlacedElementShadowCollection opacity zero instruction is retained
00:00 +16: buildRuntimeStaticPlacedElementShadowCollection multiple sources preserve order
00:00 +17: buildRuntimeStaticPlacedElementShadowCollection identical sources are not deduplicated
00:00 +18: buildRuntimeStaticPlacedElementShadowCollection actorContact profile is rejected by the static resolver
00:00 +19: buildRuntimeStaticPlacedElementShadowCollection returned collection exposes immutable lists
00:00 +20: All tests passed!
```

## 15. Ligne finale exacte des tests globaux

```text
cd packages/map_runtime && flutter test test/shadow
00:04 +184: All tests passed!
```

```text
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
No issues found! (ran in 2.1s)
```

```text
cd packages/map_runtime && flutter test
00:15 +1105: All tests passed!
```

```text
cd packages/map_core && dart test test/shadow
00:00 +152: All tests passed!
```

## 16. Résultats des scans anti-dérive

Commande :

```bash
cd packages/map_runtime && rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
```

Sortie : occurrences préexistantes de composants Flame dans `lib/src/presentation/flame`, aucune occurrence dans le nouveau builder Shadow-20, aucun `ShadowLayerComponent`.

Commande :

```bash
cd packages/map_runtime && rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
```

Sortie utile :

```text
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:10:    required this.elementShadow,
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:21:  final ProjectElementShadowConfig? elementShadow;
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:22:  final MapPlacedElementShadowOverride? placedOverride;
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:32:          other.elementShadow == elementShadow &&
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:41:        elementShadow,
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:50:  required ProjectShadowCatalog catalog,
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:58:    final resolution = resolveShadowConfig(
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:60:      elementShadow: source.elementShadow,
lib/src/shadow/shadow_runtime_instruction_collection.dart:110:ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
```

Les autres occurrences de cette commande sont préexistantes dans `lib/src/presentation/flame` ou Shadow-15. Les occurrences Shadow-20 sont limitées au nouveau builder.

Commande :

```bash
cd packages/map_runtime && rg -n "resolveActorContactShadow|ActorContactShadow|PlayerComponent|OverworldActorComponent" lib/src/presentation/flame lib/src/shadow
```

Sortie : occurrences préexistantes de Shadow-13 / Shadow-19 et de composants runtime. Aucune occurrence dans `runtime_static_placed_element_shadow_collection.dart`.

Commande :

```bash
cd packages/map_runtime && rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
```

Sortie : occurrences préexistantes de `drawImageRect` dans les composants de rendu Flame. Aucune occurrence dans le nouveau builder Shadow-20.

Diff-only zones interdites :

```text
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions"
aucune sortie

git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow|resolveActorContactShadow|ActorContactShadow"
aucune sortie

git diff -U0 -- packages/map_runtime/lib/src/presentation/flame | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
aucune sortie
```

Diff-only équivalent du nouveau builder :

```text
27:+  final ProjectElementShadowConfig? elementShadow;
28:+  final MapPlacedElementShadowOverride? placedOverride;
56:+  required ProjectShadowCatalog catalog,
64:+    final resolution = resolveShadowConfig(
81:+    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
```

Scans JSON / renderer sur les nouveaux fichiers :

```text
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
aucune sortie

rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
aucune sortie
```

## 17. git status initial

Statut initial du lot :

```text
?? reports/collision/collision_system_audit_v0.md
```

Le fichier `reports/collision/collision_system_audit_v0.md` était préexistant, hors périmètre Shadow-20, et n'a pas été modifié.

## 18. git status final

Statut final :

```text
?? packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
?? reports/collision/collision_system_audit_v0.md
?? reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
```

## 19. git diff --stat

`git diff --stat` ne liste aucun fichier, car les fichiers Shadow-20 restent non suivis et aucune commande Git d'écriture n'a été utilisée.

Sorties finales :

```text
git diff --check
aucune sortie

git diff --stat
aucune sortie

git diff --name-status
aucune sortie
```

Checks `/dev/null` des fichiers non suivis créés :

```text
git diff --no-index --check -- /dev/null packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
aucune sortie

git diff --no-index --check -- /dev/null packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
aucune sortie

git diff --no-index --check -- /dev/null reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
aucune sortie
```

Stats équivalentes `/dev/null` pour les fichiers créés :

```text
...me_static_placed_element_shadow_collection.dart | 85 ++++++++++++++++++++++
1 file changed, 85 insertions(+)
```

```text
...atic_placed_element_shadow_collection_test.dart | 421 +++++++++++++++++++++
1 file changed, 421 insertions(+)
```

## 20. Non-objectifs respectés

```text
aucun câblage PlayableMapGame
aucun câblage RuntimeMapGame
aucun changement MapLayersComponent
aucun traitement acteur
aucun resolver acteur appelé
aucun ShadowLayerComponent
aucun nouveau Flame Component
aucun renderer
aucun drawImageRect / drawAtlas / saveLayer / blur ajouté
aucun zOrder / zIndex ajouté
aucun culling ajouté
aucun tri ajouté
aucune déduplication ajoutée
aucun JSON / toJson / fromJson ajouté
aucun build_runner lancé
aucun changement map_core
aucun changement map_editor
aucun changement map_gameplay
aucun changement map_battle
```

## 21. Risques / réserves

Le builder ignore les diagnostics de `resolveShadowConfig(...)` quand `resolved == null`. Cela garde Shadow-20 léger, mais un futur câblage host devra peut-être exposer des diagnostics runtime ou debug pour expliquer pourquoi une ombre statique n'apparaît pas.

Le modèle source accepte directement `ProjectElementShadowConfig?` et `MapPlacedElementShadowOverride?`. C'est volontaire pour ce lot : le futur adapter host préparera ces objets sans que le builder lise `MapData` ou `ProjectManifest`.

Le builder ne fait pas de culling. Le culling reste la responsabilité de Shadow-15.

## 22. Auto-review finale

```text
Ai-je créé uniquement un builder statique pur ? oui.
Ai-je câblé PlayableMapGame / RuntimeMapGame ? non.
Ai-je modifié MapLayersComponent ? non.
Ai-je touché aux acteurs ? non.
Ai-je appelé resolveShadowConfig uniquement dans le builder statique ? oui.
Ai-je appelé le resolver statique uniquement dans le builder statique ? oui.
Ai-je appelé un resolver acteur ? non.
Ai-je créé un nouveau Flame Component ? non.
Ai-je ajouté du culling / tri / déduplication ? non.
Ai-je laissé les éléments statiques non câblés au runtime host ? oui.
Le lot est-il prêt pour un futur Shadow-21 de host integration ? oui.
```

## 23. Regard critique sur le prompt

Le prompt est strict mais cohérent avec la progression Shadow. Le point le plus délicat est que `git diff --stat` ne montre pas les fichiers créés tant qu'ils restent non suivis, alors que le prompt interdit `git add`. Le rapport compense avec les stats et diffs `/dev/null` des fichiers créés.

La demande de contenu complet des fichiers créés est raisonnable ici, car les deux fichiers Shadow-20 restent lisibles.

## 24. Contenu complet des fichiers créés/modifiés

### packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart

```dart
import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'static_placed_element_shadow_runtime_resolver.dart';

final class RuntimeStaticPlacedElementShadowSource {
  RuntimeStaticPlacedElementShadowSource({
    required this.id,
    required this.elementId,
    required this.elementShadow,
    this.placedOverride,
    required this.metrics,
    this.isVisible = true,
  }) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(elementId, 'elementId');
  }

  final String id;
  final String elementId;
  final ProjectElementShadowConfig? elementShadow;
  final MapPlacedElementShadowOverride? placedOverride;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final bool isVisible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeStaticPlacedElementShadowSource &&
          other.id == id &&
          other.elementId == elementId &&
          other.elementShadow == elementShadow &&
          other.placedOverride == placedOverride &&
          other.metrics == metrics &&
          other.isVisible == isVisible;

  @override
  int get hashCode => Object.hash(
        id,
        elementId,
        elementShadow,
        placedOverride,
        metrics,
        isVisible,
      );
}

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollection({
  required ProjectShadowCatalog catalog,
  required Iterable<RuntimeStaticPlacedElementShadowSource> sources,
}) {
  final inputs = <StaticPlacedElementShadowRuntimeInput>[];
  for (final source in sources) {
    if (!source.isVisible) {
      continue;
    }
    final resolution = resolveShadowConfig(
      catalog: catalog,
      elementShadow: source.elementShadow,
      placedOverride: source.placedOverride,
    );
    final resolved = resolution.resolved;
    if (resolved == null) {
      continue;
    }
    inputs.add(
      StaticPlacedElementShadowRuntimeInput(
        resolvedConfig: resolved,
        metrics: source.metrics,
      ),
    );
  }
  return ShadowRuntimeInstructionCollection(
    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
  );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException(
      'RuntimeStaticPlacedElementShadowSource.$name must not be blank',
    );
  }
}
```

### packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('RuntimeStaticPlacedElementShadowSource', () {
    test('uses value equality and matching hashCode', () {
      final a = _source();
      final b = _source();
      final c = _source(id: 'other');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('rejects blank ids', () {
      expect(
        () => _source(id: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _source(id: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects blank element ids', () {
      expect(
        () => _source(elementId: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _source(elementId: '   '),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('buildRuntimeStaticPlacedElementShadowCollection', () {
    test(
        'visible active element shadow with ellipse groundStatic creates one instruction',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      );

      expect(collection.length, 1);
      expect(collection.actorContact, isEmpty);
      expect(collection.groundStatic, hasLength(1));
      final instruction = collection.groundStatic.single;
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
      expect(instruction.width, closeTo(36, 0.0001));
      expect(instruction.height, closeTo(7.5, 0.0001));
      expect(instruction.worldLeft, closeTo(88, 0.0001));
      expect(instruction.worldTop, closeTo(186.25, 0.0001));
    });

    test('contactBlob groundStatic profile creates a groundStatic instruction',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'blob_ground')),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(collection.groundStatic.single.renderPass,
          ShadowRenderPass.groundStatic);
      expect(collection.groundStatic.single.shape,
          ShadowRuntimeShapeKind.contactBlob);
    });

    test('invisible source creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(isVisible: false),
        ],
      );

      expect(collection, ShadowRuntimeInstructionCollection());
    });

    test('null element shadow creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: null),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('castsShadow false creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: ProjectElementShadowConfig(castsShadow: false),
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('disabled placed override creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('inherit placed override keeps the element profile', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            placedOverride: MapPlacedElementShadowOverride(),
          ),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(
          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
      expect(collection.groundStatic.single.width, closeTo(36, 0.0001));
    });

    test('custom placed override applies offset scale and opacity', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              offsetX: 5,
              offsetY: 7,
              scaleX: 2,
              scaleY: 3,
              opacity: 0.2,
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      expect(instruction.width, closeTo(60, 0.0001));
      expect(instruction.height, closeTo(45, 0.0001));
      expect(instruction.worldLeft, closeTo(75, 0.0001));
      expect(instruction.worldTop, closeTo(164.5, 0.0001));
      expect(instruction.opacity, 0.2);
    });

    test(
        'custom placed override with shadowProfileId uses the override profile',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              shadowProfileId: 'blob_ground',
            ),
          ),
        ],
      );

      expect(collection.groundStatic.single.shape,
          ShadowRuntimeShapeKind.contactBlob);
      expect(collection.groundStatic.single.width, closeTo(30, 0.0001));
    });

    test(
        'custom placed override without shadowProfileId keeps the element profile',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              offsetX: 4,
            ),
          ),
        ],
      );

      expect(
          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
      expect(collection.groundStatic.single.worldLeft, closeTo(89, 0.0001));
    });

    test('none profile creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'none_profile')),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('missing profile creates no instruction in V0', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'missing_profile')),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('opacity zero instruction is retained', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'zero_opacity')),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(collection.groundStatic.single.opacity, 0);
    });

    test('multiple sources preserve order', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(id: 'first', metrics: _metrics(worldLeft: 80)),
          _source(id: 'second', metrics: _metrics(worldLeft: 200)),
        ],
      );

      expect(collection.groundStatic, hasLength(2));
      expect(
        collection.groundStatic[0].worldLeft,
        lessThan(collection.groundStatic[1].worldLeft),
      );
    });

    test('identical sources are not deduplicated', () {
      final source = _source();

      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          source,
          source,
        ],
      );

      expect(collection.groundStatic, hasLength(2));
      expect(collection.groundStatic[0], collection.groundStatic[1]);
    });

    test('actorContact profile is rejected by the static resolver', () {
      expect(
        () => buildRuntimeStaticPlacedElementShadowCollection(
          catalog: _catalog(),
          sources: [
            _source(elementShadow: _elementShadow(profileId: 'actor_contact')),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('returned collection exposes immutable lists', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      );

      expect(
        () => collection.instructions.add(collection.instructions.single),
        throwsUnsupportedError,
      );
    });
  });
}

RuntimeStaticPlacedElementShadowSource _source({
  String id = 'tree-instance',
  String elementId = 'tree',
  Object? elementShadow = _defaultElementShadow,
  MapPlacedElementShadowOverride? placedOverride,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  bool isVisible = true,
}) {
  final resolvedElementShadow = identical(
    elementShadow,
    _defaultElementShadow,
  )
      ? _elementShadow()
      : elementShadow as ProjectElementShadowConfig?;
  return RuntimeStaticPlacedElementShadowSource(
    id: id,
    elementId: elementId,
    elementShadow: resolvedElementShadow,
    placedOverride: placedOverride,
    metrics: metrics ?? _metrics(),
    isVisible: isVisible,
  );
}

const Object _defaultElementShadow = Object();

ProjectElementShadowConfig _elementShadow({
  String profileId = 'ellipse_ground',
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: profileId,
  );
}

StaticPlacedElementShadowRuntimeMetrics _metrics({
  double worldLeft = 80,
  double worldTop = 120,
  double visualWidth = 40,
  double visualHeight = 60,
}) {
  return StaticPlacedElementShadowRuntimeMetrics(
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
}

ProjectShadowCatalog _catalog() {
  return ProjectShadowCatalog(
    profiles: [
      _profile(
        id: 'ellipse_ground',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 6,
        offsetY: 10,
        scaleX: 1.2,
        scaleY: 0.5,
      ),
      _profile(
        id: 'plain_ellipse',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
      _profile(
        id: 'blob_ground',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.groundStatic,
      ),
      _profile(
        id: 'none_profile',
        mode: ShadowCasterMode.none,
        renderPass: ShadowRenderPass.groundStatic,
      ),
      _profile(
        id: 'zero_opacity',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0,
      ),
      _profile(
        id: 'actor_contact',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      ),
    ],
  );
}

ProjectShadowProfile _profile({
  required String id,
  required ShadowCasterMode mode,
  required ShadowRenderPass renderPass,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
}) {
  return ProjectShadowProfile(
    id: id,
    name: id,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
  );
}
```

Le présent rapport est le fichier :

```text
reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
```

## 25. Diffs complets ou équivalents /dev/null pour fichiers créés

### /dev/null -> packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart

```diff
diff --git a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
new file mode 100644
--- /dev/null
+++ b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
@@
+import 'package:map_core/map_core.dart';
+
+import 'shadow_runtime_instruction_collection.dart';
+import 'static_placed_element_shadow_runtime_resolver.dart';
+
+final class RuntimeStaticPlacedElementShadowSource {
+  RuntimeStaticPlacedElementShadowSource({
+    required this.id,
+    required this.elementId,
+    required this.elementShadow,
+    this.placedOverride,
+    required this.metrics,
+    this.isVisible = true,
+  }) {
+    _validateNonBlank(id, 'id');
+    _validateNonBlank(elementId, 'elementId');
+  }
+
+  final String id;
+  final String elementId;
+  final ProjectElementShadowConfig? elementShadow;
+  final MapPlacedElementShadowOverride? placedOverride;
+  final StaticPlacedElementShadowRuntimeMetrics metrics;
+  final bool isVisible;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is RuntimeStaticPlacedElementShadowSource &&
+          other.id == id &&
+          other.elementId == elementId &&
+          other.elementShadow == elementShadow &&
+          other.placedOverride == placedOverride &&
+          other.metrics == metrics &&
+          other.isVisible == isVisible;
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        elementId,
+        elementShadow,
+        placedOverride,
+        metrics,
+        isVisible,
+      );
+}
+
+ShadowRuntimeInstructionCollection
+    buildRuntimeStaticPlacedElementShadowCollection({
+  required ProjectShadowCatalog catalog,
+  required Iterable<RuntimeStaticPlacedElementShadowSource> sources,
+}) {
+  final inputs = <StaticPlacedElementShadowRuntimeInput>[];
+  for (final source in sources) {
+    if (!source.isVisible) {
+      continue;
+    }
+    final resolution = resolveShadowConfig(
+      catalog: catalog,
+      elementShadow: source.elementShadow,
+      placedOverride: source.placedOverride,
+    );
+    final resolved = resolution.resolved;
+    if (resolved == null) {
+      continue;
+    }
+    inputs.add(
+      StaticPlacedElementShadowRuntimeInput(
+        resolvedConfig: resolved,
+        metrics: source.metrics,
+      ),
+    );
+  }
+  return ShadowRuntimeInstructionCollection(
+    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
+  );
+}
+
+void _validateNonBlank(String value, String name) {
+  if (value.trim().isEmpty) {
+    throw ValidationException(
+      'RuntimeStaticPlacedElementShadowSource.$name must not be blank',
+    );
+  }
+}
```

### /dev/null -> packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart

Le diff complet de ce fichier créé est équivalent au contenu complet reproduit en section 24, avec chaque ligne précédée de `+`.
