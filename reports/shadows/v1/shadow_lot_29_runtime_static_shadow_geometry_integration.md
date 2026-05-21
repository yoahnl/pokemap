# Shadow-29 — Runtime Static Shadow Geometry Integration V0

## 1. Résumé du lot

Shadow-29 branche la géométrie statique commune de `map_core` dans le runtime Shadow statique.

Le runtime utilise maintenant :

- `StaticShadowVisualMetrics`
- `StaticShadowFootprintConfig`
- `resolveStaticShadowFootprint(...)`
- `resolveStaticShadowGeometry(...)`

Le pipeline final `resolveShadowRuntimeInstruction(...)` reste en place. Le runtime extrait uniquement de la géométrie core :

```text
geometry.anchorX
geometry.anchorY
geometry.baseWidth
geometry.baseHeight
```

Il ne construit pas directement `ShadowRuntimeRenderInstruction` depuis `geometry.centerX`, `geometry.left`, `geometry.width` ou équivalent.

## 2. Design retenu

Design appliqué : Option A.

Le resolver statique runtime continue à déléguer la construction finale de l’instruction à `resolveShadowRuntimeInstruction(...)`.

`resolveStaticShadowGeometry(...)` sert uniquement à produire l’ancre runtime compatible :

```text
ShadowRuntimeAnchor.worldX = geometry.anchorX
ShadowRuntimeAnchor.worldY = geometry.anchorY
ShadowRuntimeAnchor.baseWidth = geometry.baseWidth
ShadowRuntimeAnchor.baseHeight = geometry.baseHeight
```

Cela garde la responsabilité `offsetX/offsetY` et `scaleX/scaleY` dans le resolver runtime générique, et évite une double application.

## 3. Fichiers créés

```text
reports/shadows/shadow_lot_29_runtime_static_shadow_geometry_integration.md
```

## 4. Fichiers modifiés

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

## 5. Fichiers non modifiés explicitement

```text
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
```

Fichiers déjà présents/modifiés avant Shadow-29 : aucun au `git status` initial.

Fichiers non suivis préexistants hors lot : aucun au `git status` initial.

Dettes préexistantes hors lot : aucune découverte dans ce lot.

Problèmes introduits par Shadow-29 : aucun détecté par les tests, analyses et scans listés dans ce rapport.

## 6. Intégration de resolveStaticShadowGeometry

`staticPlacedElementShadowAnchorFromMetrics(...)` appelle maintenant `resolveStaticShadowGeometry(...)`.

Le mapping est :

```text
StaticPlacedElementShadowRuntimeMetrics.worldLeft -> StaticShadowVisualMetrics.left
StaticPlacedElementShadowRuntimeMetrics.worldTop -> StaticShadowVisualMetrics.top
StaticPlacedElementShadowRuntimeMetrics.visualWidth -> StaticShadowVisualMetrics.visualWidth
StaticPlacedElementShadowRuntimeMetrics.visualHeight -> StaticShadowVisualMetrics.visualHeight
```

Puis :

```text
geometry.anchorX -> ShadowRuntimeAnchor.worldX
geometry.anchorY -> ShadowRuntimeAnchor.worldY
geometry.baseWidth -> ShadowRuntimeAnchor.baseWidth
geometry.baseHeight -> ShadowRuntimeAnchor.baseHeight
```

## 7. Décision sur les anciens ratios runtime metrics

Les champs historiques sont conservés :

```text
anchorXRatio
anchorYRatio
baseWidthMultiplier
baseHeightMultiplier
```

Ils sont traduits en `StaticShadowFootprintConfig` legacy :

```text
anchorXRatio -> anchorXRatio
anchorYRatio -> anchorYRatio
baseWidthMultiplier -> footprintWidthRatio
baseHeightMultiplier -> footprintHeightRatio
```

Ce choix conserve le comportement existant des appels internes et des tests qui personnalisent les anciens ratios.

## 8. Transmission elementFootprint / overrideFootprint

`StaticPlacedElementShadowRuntimeInput` porte maintenant :

```dart
final StaticShadowFootprintConfig? elementFootprint;
final StaticShadowFootprintConfig? overrideFootprint;
```

`buildRuntimeStaticPlacedElementShadowCollection(...)` transmet :

```dart
elementFootprint: source.elementShadow?.footprint,
overrideFootprint: source.placedOverride?.footprint,
```

Le fichier `runtime_static_placed_element_shadow_sources.dart` reste inchangé : il prépare déjà `elementShadow` et `placedOverride`.

## 9. Compatibilité sans footprint

Sans footprint authoring, les anciens ratios metrics sont convertis en footprint legacy complet.

Avec les defaults historiques :

```text
anchorXRatio = 0.5
anchorYRatio = 1.0
baseWidthMultiplier = 0.75
baseHeightMultiplier = 0.25
```

La géométrie runtime reste identique :

```text
width = 36
height = 7.5
worldLeft = 88
worldTop = 186.25
```

Cette valeur est couverte par le test existant maintenu :

```text
resolveStaticPlacedElementShadowRuntimeInstruction applies static metrics and Shadow-12 offset/scale geometry
```

## 10. Protection contre double offset/scale

Le test ajouté :

```text
resolveStaticPlacedElementShadowRuntimeInstruction applies offset and scale once after core footprint geometry
```

vérifie explicitement :

```text
width = 24
height = 7.5
worldLeft = 84
worldTop = 156.25
```

Ces valeurs correspondent à une seule application de `offsetX/offsetY` et `scaleX/scaleY` par `resolveShadowRuntimeInstruction(...)`.

## 11. Pourquoi ce lot ne touche pas editor

Shadow-29 est uniquement l’intégration runtime de la géométrie commune. L’éditeur conserve sa preview Shadow-24 actuelle. L’intégration editor de la géométrie core appartient au lot suivant prévu.

## 12. Pourquoi ce lot ne touche pas aux modèles/codecs

Shadow-27 a déjà rendu `StaticShadowFootprintConfig` persistable dans `map_core`. Shadow-29 ne change aucun contrat JSON ou modèle persistant ; il consomme seulement les champs déjà disponibles.

## 13. Tests ajoutés/modifiés

Fichier :

```text
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Tests ajoutés :

- input equality includes element and override footprints ;
- legacy metrics custom ratios remain preserved ;
- element footprint overrides legacy metrics field by field ;
- override footprint wins over element footprint field by field ;
- offset/scale applies once after core footprint geometry ;
- custom override without footprint keeps element footprint.

Fichier :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Tests ajoutés :

- element shadow footprint is transmitted to runtime geometry ;
- placed override footprint is transmitted to runtime geometry.

## 14. Commandes lancées

Depuis `/Users/karim/Project/pokemonProject` :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Depuis `/Users/karim/Project/pokemonProject/packages/map_runtime` :

```bash
flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
dart format lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart lib/src/shadow/runtime_static_placed_element_shadow_collection.dart test/shadow/static_placed_element_shadow_runtime_resolver_test.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart
flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
flutter test test/shadow
flutter analyze lib/src/shadow test/shadow
flutter test
```

Depuis `/Users/karim/Project/pokemonProject/packages/map_core` :

```bash
dart test test/shadow/static_shadow_geometry_test.dart
dart test test/shadow
dart analyze lib test/shadow
```

Depuis `/Users/karim/Project/pokemonProject` :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "Canvas|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Résultats complets des tests ciblés

### RED resolver

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat utile :

```text
test/shadow/static_placed_element_shadow_runtime_resolver_test.dart:216:9: Error: No named parameter with the name 'elementFootprint'.
        elementFootprint: StaticShadowFootprintConfig(
        ^^^^^^^^^^^^^^^^
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:91:21: Context: Found this candidate, but the arguments don't match.
ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_placed_element_shadow_runtime_resolver_test.dart:231:9: Error: No named parameter with the name 'elementFootprint'.
        elementFootprint: StaticShadowFootprintConfig(
        ^^^^^^^^^^^^^^^^
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:91:21: Context: Found this candidate, but the arguments don't match.
ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_placed_element_shadow_runtime_resolver_test.dart:494:5: Error: No named parameter with the name 'elementFootprint'.
    elementFootprint: elementFootprint,
    ^^^^^^^^^^^^^^^^
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:69:9: Context: Found this candidate, but the arguments don't match.
  const StaticPlacedElementShadowRuntimeInput({
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### RED collection

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat utile :

```text
00:00 +13 -1: buildRuntimeStaticPlacedElementShadowCollection element shadow footprint is transmitted to runtime geometry [E]
  Expected: a numeric value within <0.0001> of <24>
    Actual: <36.0>
     Which:  differs by <12.0>

00:00 +13 -2: buildRuntimeStaticPlacedElementShadowCollection placed override footprint is transmitted to runtime geometry [E]
  Expected: a numeric value within <0.0001> of <24>
    Actual: <36.0>
     Which:  differs by <12.0>

00:00 +20 -2: Some tests failed.
```

### Format

Commande :

```bash
cd packages/map_runtime && dart format lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart lib/src/shadow/runtime_static_placed_element_shadow_collection.dart test/shadow/static_placed_element_shadow_runtime_resolver_test.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat :

```text
Formatted 4 files (0 changed) in 0.01 seconds.
```

### GREEN resolver

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
00:00 +0: StaticPlacedElementShadowRuntimeMetrics creates valid metrics with default ratios and multipliers
00:00 +1: StaticPlacedElementShadowRuntimeMetrics accepts custom valid ratios and multipliers
00:00 +2: StaticPlacedElementShadowRuntimeMetrics rejects non-finite world coordinates
00:00 +3: StaticPlacedElementShadowRuntimeMetrics rejects invalid visual dimensions
00:00 +4: StaticPlacedElementShadowRuntimeMetrics rejects invalid anchor ratios
00:00 +5: StaticPlacedElementShadowRuntimeMetrics rejects invalid base multipliers
00:00 +6: StaticPlacedElementShadowRuntimeMetrics uses value equality and matching hashCode
00:00 +7: StaticPlacedElementShadowRuntimeInput uses value equality and matching hashCode
00:00 +8: StaticPlacedElementShadowRuntimeInput equality includes element and override footprints
00:00 +9: staticPlacedElementShadowAnchorFromMetrics converts static metrics into a runtime anchor
00:00 +10: staticPlacedElementShadowAnchorFromMetrics preserves custom legacy metrics ratios and multipliers
00:00 +11: staticPlacedElementShadowAnchorFromMetrics element footprint overrides legacy metrics field by field
00:00 +12: staticPlacedElementShadowAnchorFromMetrics override footprint wins over element footprint field by field
00:00 +13: resolveStaticPlacedElementShadowRuntimeInstruction resolves ellipse groundStatic into an instruction
00:00 +14: resolveStaticPlacedElementShadowRuntimeInstruction resolves contactBlob groundStatic into an instruction
00:00 +15: resolveStaticPlacedElementShadowRuntimeInstruction applies static metrics and Shadow-12 offset/scale geometry
00:00 +16: resolveStaticPlacedElementShadowRuntimeInstruction applies offset and scale once after core footprint geometry
00:00 +17: resolveStaticPlacedElementShadowRuntimeInstruction custom override without footprint keeps element footprint
00:00 +18: resolveStaticPlacedElementShadowRuntimeInstruction passes opacity color softness and renderPass through
00:00 +19: resolveStaticPlacedElementShadowRuntimeInstruction keeps opacity zero as a valid instruction
00:00 +20: resolveStaticPlacedElementShadowRuntimeInstruction returns null for ShadowCasterMode.none before render pass checks
00:00 +21: resolveStaticPlacedElementShadowRuntimeInstruction rejects actorContact render pass
00:00 +22: resolveStaticPlacedElementShadowRuntimeInstruction does not silently clamp invalid computed dimensions
00:00 +23: resolveStaticPlacedElementShadowRuntimeInstructions returns an empty list for no inputs
00:00 +24: resolveStaticPlacedElementShadowRuntimeInstructions resolves one input into one instruction
00:00 +25: resolveStaticPlacedElementShadowRuntimeInstructions preserves input order without sorting
00:00 +26: resolveStaticPlacedElementShadowRuntimeInstructions ignores mode none inputs
00:00 +27: resolveStaticPlacedElementShadowRuntimeInstructions does not cull opacity zero instructions
00:00 +28: resolveStaticPlacedElementShadowRuntimeInstructions does not deduplicate equal inputs
00:00 +29: resolveStaticPlacedElementShadowRuntimeInstructions does not modify inputs and exposes an unmodifiable list
00:00 +30: All tests passed!
```

### GREEN collection

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
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
00:00 +13: buildRuntimeStaticPlacedElementShadowCollection element shadow footprint is transmitted to runtime geometry
00:00 +14: buildRuntimeStaticPlacedElementShadowCollection placed override footprint is transmitted to runtime geometry
00:00 +15: buildRuntimeStaticPlacedElementShadowCollection none profile creates no instruction
00:00 +16: buildRuntimeStaticPlacedElementShadowCollection missing profile creates no instruction in V0
00:00 +17: buildRuntimeStaticPlacedElementShadowCollection opacity zero instruction is retained
00:00 +18: buildRuntimeStaticPlacedElementShadowCollection multiple sources preserve order
00:00 +19: buildRuntimeStaticPlacedElementShadowCollection identical sources are not deduplicated
00:00 +20: buildRuntimeStaticPlacedElementShadowCollection actorContact profile is rejected by the static resolver
00:00 +21: buildRuntimeStaticPlacedElementShadowCollection returned collection exposes immutable lists
00:00 +22: All tests passed!
```

### Host integration ciblé

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
00:00 +0: runtime static placed element shadow host integration PlayableMapGame builds static shadows for configured placed elements
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +1: runtime static placed element shadow host integration static shadow is visible in the background render when configured
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +2: runtime static placed element shadow host integration empty catalog or missing profile creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +3: runtime static placed element shadow host integration element without shadow config creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +4: runtime static placed element shadow host integration disabled placed override creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +5: runtime static placed element shadow host integration custom placed override modifies the static shadow instruction
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +6: runtime static placed element shadow host integration internal static and actor shadows are merged for the active map
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +7: runtime static placed element shadow host integration static and actor flags affect only their internal collections
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +8: runtime static placed element shadow host integration external provider remains priority even when internal flags are off
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +9: runtime static placed element shadow host integration connected map background receives static shadows but no actor shadows
[runtime] Map loaded: active-static-map, spawn at (0, 0)
[connection] loaded map=connected-static-map origin=(4, 0)
00:00 +10: runtime static placed element shadow host integration RuntimeMapGame remains passive for static placed element shadows
00:00 +11: All tests passed!
```

### Core geometry ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
```

Résultat :

```text
00:00 +0: loading test/shadow/static_shadow_geometry_test.dart
00:00 +0: StaticShadowVisualMetrics accepts valid metrics
00:00 +1: StaticShadowVisualMetrics rejects non-finite left and top
00:00 +2: StaticShadowVisualMetrics rejects invalid visual sizes
00:00 +3: StaticShadowVisualMetrics equality and hashCode include all fields
00:00 +4: ResolvedStaticShadowFootprint defaults match current V0 ratios
00:00 +5: ResolvedStaticShadowFootprint element footprint overrides defaults field by field
00:00 +6: ResolvedStaticShadowFootprint override footprint wins over element footprint field by field
00:00 +7: ResolvedStaticShadowFootprint rejects invalid direct resolved ratios
00:00 +8: ResolvedStaticShadowFootprint equality and hashCode include all fields
00:00 +9: resolveStaticShadowGeometry without footprint reproduces current V0 formula
00:00 +10: resolveStaticShadowGeometry element footprint changes anchor and footprint size
00:00 +11: resolveStaticShadowGeometry override footprint wins while partial override keeps element fields
00:00 +12: resolveStaticShadowGeometry offset and scale apply after footprint
00:00 +13: resolveStaticShadowGeometry mode renderPass opacity color and softness do not affect geometry
00:00 +14: resolveStaticShadowGeometry rejects invalid direct geometry values
00:00 +15: resolveStaticShadowGeometry equality and hashCode include all fields
00:00 +16: static shadow geometry integration with existing configs ProjectElementShadowConfig footprint can be passed directly
00:00 +17: static shadow geometry integration with existing configs MapPlacedElementShadowOverride footprint can be passed directly
00:00 +18: static shadow geometry integration with existing configs custom override with null footprint uses element or default footprint
00:00 +19: All tests passed!
```

## 16. Ligne finale exacte des tests globaux

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final exact :

```text
00:03 +207: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat exact :

```text
Analyzing 2 items...
No issues found! (ran in 4.5s)
```

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat final exact :

```text
00:22 +1128: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final exact :

```text
00:01 +204: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat exact :

```text
Analyzing lib, shadow...
No issues found!
```

## 17. Résultats des scans anti-dérive

Commande :

```bash
find .. -name AGENTS.md -print
```

Résultat :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "Canvas|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune sortie
```

## 18. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

## 19. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final après création du rapport :

```text
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_29_runtime_static_shadow_geometry_integration.md
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat avant création du rapport :

```text
 ...me_static_placed_element_shadow_collection.dart |   2 +
 ...tic_placed_element_shadow_runtime_resolver.dart |  88 ++++++++++++++--
 ...atic_placed_element_shadow_collection_test.dart |  53 ++++++++++
 ...laced_element_shadow_runtime_resolver_test.dart | 112 +++++++++++++++++++++
 4 files changed, 247 insertions(+), 8 deletions(-)
```

Commande :

```bash
git diff --name-status
```

Résultat :

```text
M	packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
M	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
M	packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

## 21. Non-objectifs respectés

- Aucun `map_editor`.
- Aucun `map_gameplay`.
- Aucun `map_battle`.
- Aucun changement de modèles persistants.
- Aucun changement de codecs JSON.
- Aucun fichier généré.
- Aucun `build_runner`.
- Aucun `PlayableMapGame`.
- Aucun `RuntimeMapGame`.
- Aucun `MapLayersComponent`.
- Aucun nouveau Flame Component.
- Aucun Shadow Studio.
- Aucune UI footprint.
- Aucune direction globale de lumière.
- Aucun blur, atlas, `zOrder` ou `zIndex`.

## 22. Risques / réserves

- `StaticPlacedElementShadowRuntimeMetrics` conserve ses anciens ratios pour compatibilité. Ils peuvent devenir redondants après migration complète vers footprints authorés.
- L’éditeur n’utilise pas encore la géométrie core dans ce lot. Le rendu runtime et la preview editor seront totalement alignés seulement après le lot d’intégration editor.
- Le helper `_identityShadowConfig` sert uniquement au calcul d’ancre quand `staticPlacedElementShadowAnchorFromMetrics(...)` est appelé sans config explicite. Les instructions runtime réelles passent le `ResolvedShadowConfig` effectif.

## 23. Auto-review finale

- Ai-je remplacé la formule runtime statique par la géométrie core ? oui.
- Ai-je évité d’appliquer offset/scale deux fois ? oui.
- Ai-je conservé le comportement sans footprint ? oui.
- Ai-je transmis elementFootprint et overrideFootprint ? oui.
- Ai-je évité de toucher à l’éditeur ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité build_runner ? oui.
- Ai-je évité une lumière globale ? oui.
- Ai-je gardé le filtrage mode/renderPass hors de map_core geometry ? oui.

## 24. Regard critique sur le prompt

Le prompt cible le bon point de risque : éviter une double application de `offsetX/offsetY` et `scaleX/scaleY`. La contrainte de garder `resolveShadowRuntimeInstruction(...)` est pertinente, car elle évite de dupliquer le mapping shape/color/opacity/softness. Le seul point délicat est la coexistence temporaire des anciens ratios runtime metrics avec les nouveaux footprints ; la traduction en footprint legacy garde la compatibilité sans élargir le modèle.

## 25. Contenu complet des fichiers créés/modifiés

Le rapport Shadow-29 est le seul fichier créé.

Pour les quatre fichiers de code/tests modifiés, la section 26 fournit les diffs complets des changements avec le contexte utile. Les sections modifiées et leurs contextes couvrent chaque ligne modifiée par Shadow-29.

## 26. Diffs complets ou équivalents /dev/null pour fichiers créés

### packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart

```diff
diff --git a/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart b/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
index 23d2c3dc..b66e565b 100644
--- a/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
+++ b/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
@@ -69,33 +69,60 @@ final class StaticPlacedElementShadowRuntimeInput {
   const StaticPlacedElementShadowRuntimeInput({
     required this.resolvedConfig,
     required this.metrics,
+    this.elementFootprint,
+    this.overrideFootprint,
   });
 
   final ResolvedShadowConfig resolvedConfig;
   final StaticPlacedElementShadowRuntimeMetrics metrics;
+  final StaticShadowFootprintConfig? elementFootprint;
+  final StaticShadowFootprintConfig? overrideFootprint;
 
   @override
   bool operator ==(Object other) =>
       identical(this, other) ||
       other is StaticPlacedElementShadowRuntimeInput &&
           other.resolvedConfig == resolvedConfig &&
-          other.metrics == metrics;
+          other.metrics == metrics &&
+          other.elementFootprint == elementFootprint &&
+          other.overrideFootprint == overrideFootprint;
 
   @override
   int get hashCode => Object.hash(
         resolvedConfig,
         metrics,
+        elementFootprint,
+        overrideFootprint,
       );
 }
 
 ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
-  StaticPlacedElementShadowRuntimeMetrics metrics,
-) {
+  StaticPlacedElementShadowRuntimeMetrics metrics, {
+  ResolvedShadowConfig? shadowConfig,
+  StaticShadowFootprintConfig? elementFootprint,
+  StaticShadowFootprintConfig? overrideFootprint,
+}) {
+  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
+    metrics: metrics,
+    elementFootprint: elementFootprint,
+  );
+  final geometry = resolveStaticShadowGeometry(
+    metrics: StaticShadowVisualMetrics(
+      left: metrics.worldLeft,
+      top: metrics.worldTop,
+      visualWidth: metrics.visualWidth,
+      visualHeight: metrics.visualHeight,
+    ),
+    shadowConfig: shadowConfig ?? _identityShadowConfig,
+    elementFootprint: legacyAndElementFootprint,
+    overrideFootprint: overrideFootprint,
+  );
+
   return ShadowRuntimeAnchor(
-    worldX: metrics.worldLeft + metrics.visualWidth * metrics.anchorXRatio,
-    worldY: metrics.worldTop + metrics.visualHeight * metrics.anchorYRatio,
-    baseWidth: metrics.visualWidth * metrics.baseWidthMultiplier,
-    baseHeight: metrics.visualHeight * metrics.baseHeightMultiplier,
+    worldX: geometry.anchorX,
+    worldY: geometry.anchorY,
+    baseWidth: geometry.baseWidth,
+    baseHeight: geometry.baseHeight,
   );
 }
 
@@ -122,7 +149,12 @@ ShadowRuntimeRenderInstruction?
   return resolveShadowRuntimeInstruction(
     ShadowRuntimeResolutionInput(
       resolvedConfig: resolved,
-      anchor: staticPlacedElementShadowAnchorFromMetrics(input.metrics),
+      anchor: staticPlacedElementShadowAnchorFromMetrics(
+        input.metrics,
+        shadowConfig: resolved,
+        elementFootprint: input.elementFootprint,
+        overrideFootprint: input.overrideFootprint,
+      ),
     ),
   );
 }
@@ -167,3 +199,43 @@ void _validateRatio(double value, String name) {
     );
   }
 }
+
+StaticShadowFootprintConfig _legacyFootprintFromMetrics(
+  StaticPlacedElementShadowRuntimeMetrics metrics,
+) {
+  return StaticShadowFootprintConfig(
+    anchorXRatio: metrics.anchorXRatio,
+    anchorYRatio: metrics.anchorYRatio,
+    footprintWidthRatio: metrics.baseWidthMultiplier,
+    footprintHeightRatio: metrics.baseHeightMultiplier,
+  );
+}
+
+StaticShadowFootprintConfig _mergeLegacyAndElementFootprint({
+  required StaticPlacedElementShadowRuntimeMetrics metrics,
+  required StaticShadowFootprintConfig? elementFootprint,
+}) {
+  final resolved = resolveStaticShadowFootprint(
+    elementFootprint: _legacyFootprintFromMetrics(metrics),
+    overrideFootprint: elementFootprint,
+  );
+  return StaticShadowFootprintConfig(
+    anchorXRatio: resolved.anchorXRatio,
+    anchorYRatio: resolved.anchorYRatio,
+    footprintWidthRatio: resolved.footprintWidthRatio,
+    footprintHeightRatio: resolved.footprintHeightRatio,
+  );
+}
+
+const _identityShadowConfig = ResolvedShadowConfig(
+  shadowProfileId: 'runtime-static-shadow-anchor',
+  mode: ShadowCasterMode.ellipse,
+  renderPass: ShadowRenderPass.groundStatic,
+  offsetX: 0,
+  offsetY: 0,
+  scaleX: 1,
+  scaleY: 1,
+  opacity: 1,
+  colorHexRgb: '000000',
+  softnessMode: ShadowSoftnessMode.hardEdge,
+);
```

### packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart

```diff
diff --git a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
index 1f7eb206..ad1d98f5 100644
--- a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
+++ b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
@@ -68,6 +68,8 @@ ShadowRuntimeInstructionCollection
       StaticPlacedElementShadowRuntimeInput(
         resolvedConfig: resolved,
         metrics: source.metrics,
+        elementFootprint: source.elementShadow?.footprint,
+        overrideFootprint: source.placedOverride?.footprint,
       ),
     );
   }
```

### packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart b/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
index df7c7515..9f864996 100644
--- a/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
+++ b/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
@@ -157,6 +157,25 @@ void main() {
       expect(a.hashCode, b.hashCode);
       expect(a, isNot(c));
     });
+
+    test('equality includes element and override footprints', () {
+      final a = _input(
+        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
+      );
+      final b = _input(
+        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
+      );
+      final c = _input(
+        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
+        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
   });
 
   group('staticPlacedElementShadowAnchorFromMetrics', () {
@@ -169,6 +188,63 @@ void main() {
       expect(anchor.baseWidth, closeTo(30, 0.000001));
       expect(anchor.baseHeight, closeTo(15, 0.000001));
     });
+
+    test('preserves custom legacy metrics ratios and multipliers', () {
+      final anchor = staticPlacedElementShadowAnchorFromMetrics(
+        _metrics(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.75,
+          baseWidthMultiplier: 0.5,
+          baseHeightMultiplier: 0.125,
+        ),
+      );
+
+      expect(anchor.worldX, closeTo(90, 0.000001));
+      expect(anchor.worldY, closeTo(165, 0.000001));
+      expect(anchor.baseWidth, closeTo(20, 0.000001));
+      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
+    });
+
+    test('element footprint overrides legacy metrics field by field', () {
+      final anchor = staticPlacedElementShadowAnchorFromMetrics(
+        _metrics(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.75,
+          baseWidthMultiplier: 0.5,
+          baseHeightMultiplier: 0.125,
+        ),
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorYRatio: 0.5,
+          footprintWidthRatio: 0.25,
+        ),
+      );
+
+      expect(anchor.worldX, closeTo(90, 0.000001));
+      expect(anchor.worldY, closeTo(150, 0.000001));
+      expect(anchor.baseWidth, closeTo(10, 0.000001));
+      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
+    });
+
+    test('override footprint wins over element footprint field by field', () {
+      final anchor = staticPlacedElementShadowAnchorFromMetrics(
+        _metrics(),
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.75,
+          footprintWidthRatio: 0.5,
+          footprintHeightRatio: 0.125,
+        ),
+        overrideFootprint: StaticShadowFootprintConfig(
+          anchorYRatio: 0.5,
+          footprintWidthRatio: 0.25,
+        ),
+      );
+
+      expect(anchor.worldX, closeTo(90, 0.000001));
+      expect(anchor.worldY, closeTo(150, 0.000001));
+      expect(anchor.baseWidth, closeTo(10, 0.000001));
+      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
+    });
   });
 
   group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
@@ -204,6 +280,38 @@ void main() {
       expect(instruction.worldTop, closeTo(186.25, 0.000001));
     });
 
+    test('applies offset and scale once after core footprint geometry', () {
+      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
+        _input(
+          elementFootprint: StaticShadowFootprintConfig(
+            anchorXRatio: 0.25,
+            anchorYRatio: 0.5,
+            footprintWidthRatio: 0.5,
+            footprintHeightRatio: 0.25,
+          ),
+        ),
+      );
+
+      expect(instruction, isNotNull);
+      expect(instruction!.width, closeTo(24, 0.000001));
+      expect(instruction.height, closeTo(7.5, 0.000001));
+      expect(instruction.worldLeft, closeTo(84, 0.000001));
+      expect(instruction.worldTop, closeTo(156.25, 0.000001));
+    });
+
+    test('custom override without footprint keeps element footprint', () {
+      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
+        _input(
+          resolvedConfig: _resolvedConfig(offsetX: 4),
+          elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+        ),
+      );
+
+      expect(instruction, isNotNull);
+      expect(instruction!.worldLeft, closeTo(76, 0.000001));
+      expect(instruction.worldTop, closeTo(186.25, 0.000001));
+    });
+
     test('passes opacity color softness and renderPass through', () {
       final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
         _input(
@@ -377,10 +485,14 @@ StaticPlacedElementShadowRuntimeMetrics _metrics({
 StaticPlacedElementShadowRuntimeInput _input({
   ResolvedShadowConfig? resolvedConfig,
   StaticPlacedElementShadowRuntimeMetrics? metrics,
+  StaticShadowFootprintConfig? elementFootprint,
+  StaticShadowFootprintConfig? overrideFootprint,
 }) {
   return StaticPlacedElementShadowRuntimeInput(
     resolvedConfig: resolvedConfig ?? _resolvedConfig(),
     metrics: metrics ?? _metrics(),
+    elementFootprint: elementFootprint,
+    overrideFootprint: overrideFootprint,
   );
 }
```

### packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
index 08f1af91..f1a0e492 100644
--- a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
@@ -213,6 +213,57 @@ void main() {
       expect(collection.groundStatic.single.worldLeft, closeTo(89, 0.0001));
     });
 
+    test('element shadow footprint is transmitted to runtime geometry', () {
+      final collection = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(
+            elementShadow: _elementShadow(
+              footprint: StaticShadowFootprintConfig(
+                anchorXRatio: 0.25,
+                footprintWidthRatio: 0.5,
+              ),
+            ),
+          ),
+        ],
+      );
+
+      final instruction = collection.groundStatic.single;
+      expect(instruction.width, closeTo(24, 0.0001));
+      expect(instruction.height, closeTo(7.5, 0.0001));
+      expect(instruction.worldLeft, closeTo(84, 0.0001));
+      expect(instruction.worldTop, closeTo(186.25, 0.0001));
+    });
+
+    test('placed override footprint is transmitted to runtime geometry', () {
+      final collection = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(
+            elementShadow: _elementShadow(
+              footprint: StaticShadowFootprintConfig(
+                anchorXRatio: 0.25,
+                footprintWidthRatio: 0.5,
+              ),
+            ),
+            placedOverride: MapPlacedElementShadowOverride(
+              mode: ShadowOverrideMode.custom,
+              footprint: StaticShadowFootprintConfig(
+                anchorYRatio: 0.5,
+                footprintHeightRatio: 0.125,
+              ),
+            ),
+          ),
+        ],
+      );
+
+      final instruction = collection.groundStatic.single;
+      expect(instruction.width, closeTo(24, 0.0001));
+      expect(instruction.height, closeTo(3.75, 0.0001));
+      expect(instruction.worldLeft, closeTo(84, 0.0001));
+      expect(instruction.worldTop, closeTo(158.125, 0.0001));
+    });
+
     test('none profile creates no instruction', () {
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
@@ -334,10 +385,12 @@ const Object _defaultElementShadow = Object();
 
 ProjectElementShadowConfig _elementShadow({
   String profileId = 'ellipse_ground',
+  StaticShadowFootprintConfig? footprint,
 }) {
   return ProjectElementShadowConfig(
     castsShadow: true,
     shadowProfileId: profileId,
+    footprint: footprint,
   );
 }
```
