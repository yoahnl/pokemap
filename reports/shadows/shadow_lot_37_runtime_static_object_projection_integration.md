# Shadow-37 - Runtime Static Object Projection Integration V0

## 1. Resume du lot

Shadow-37 branche les ombres statiques runtime d'elements places sur la projection polygonale core.

Avant ce lot, le runtime static placed calculait bien un footprint via `resolveStaticShadowGeometry(...)`, puis repassait par `resolveShadowRuntimeInstruction(...)`, ce qui produisait encore une instruction ovale (`ellipse` ou `contactBlob`).

Apres ce lot, `resolveStaticPlacedElementShadowRuntimeInstruction(...)` :

- garde les filtres existants (`none`, `groundStatic`, modes statiques autorises) ;
- calcule la geometrie statique via `resolveStaticShadowGeometry(...)` ;
- projette cette geometrie via `resolveProjectedStaticShadowGeometry(...)` ;
- mappe les points core vers `ShadowRuntimePoint` ;
- calcule les bounds depuis les points polygonaux ;
- retourne `ShadowRuntimeRenderInstruction(shape: ShadowRuntimeShapeKind.projectedPolygon, ...)`.

Ce lot ne change pas le renderer Shadow-36 : le renderer savait deja dessiner `projectedPolygon` avec `Canvas.drawPath(...)`.

## 2. Design retenu

Design applique : static placed runtime projection directe.

```text
StaticPlacedElementShadowRuntimeInput
-> resolveStaticShadowGeometry(...)
-> resolveProjectedStaticShadowGeometry(...)
-> ShadowRuntimeRenderInstruction.projectedPolygon
```

Decision importante : le resolver statique ne passe plus par `resolveShadowRuntimeInstruction(...)` pour produire l'instruction finale. Ce resolver generique reste utile ailleurs, mais il mappe les modes persistants `ellipse` / `contactBlob` vers des formes ovales. Shadow-37 doit produire une forme runtime derivee sans ajouter de mode persistant.

Les profils `ellipse` et `contactBlob` restent acceptes comme sources statiques `groundStatic`, mais la sortie runtime pour les objets statiques devient toujours `projectedPolygon`.

## 3. Fichiers crees

- `reports/shadows/shadow_lot_37_runtime_static_object_projection_integration.md`

## 4. Fichiers modifies par Shadow-37

- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`

## 5. Fichiers deja presents/modifies avant Shadow-37 implementation

- `AGENTS.md` etait deja modifie avant le debut de l'implementation Shadow-37. Je ne l'ai pas modifie.
- `reports/shadows/shadow_lot_37_runtime_static_object_projection_integration_plan.md` etait deja non suivi avant le debut de l'implementation Shadow-37. Je ne l'ai pas modifie pendant l'implementation.

## 6. Fichiers non suivis preexistants hors lot

- `reports/shadows/shadow_lot_37_runtime_static_object_projection_integration_plan.md`

## 7. Dettes preexistantes hors lot

- `AGENTS.md` modifie hors lot dans le worktree.
- Le plan Shadow-37 etait encore non suivi avant l'implementation.

## 8. Problemes introduits par Shadow-37

Aucun probleme connu introduit par Shadow-37 apres verification ciblee, runtime shadow, runtime complet, core shadow et scans anti-derive.

## 9. Integration de `resolveProjectedStaticShadowGeometry` cote runtime

`static_placed_element_shadow_runtime_resolver.dart` ajoute un flux prive :

```text
_resolveStaticPlacedElementBaseGeometry(...)
_runtimePointsFromProjection(...)
_boundsFromRuntimePoints(...)
```

La geometrie de base reste calculee par `resolveStaticShadowGeometry(...)`, puis la projection est calculee par `resolveProjectedStaticShadowGeometry(...)`.

## 10. Mapping `ProjectedStaticShadowPoint` vers `ShadowRuntimePoint`

Chaque point core est converti en point runtime :

```text
ProjectedStaticShadowPoint(x, y)
-> ShadowRuntimePoint(worldX: x, worldY: y)
```

Le mapping conserve l'ordre expose par `ProjectedStaticShadowGeometry.points`.

## 11. Calcul des bounds runtime polygonaux

Les champs obligatoires de `ShadowRuntimeRenderInstruction` restent remplis.

Pour `projectedPolygon`, ils representent le rectangle englobant du polygone :

```text
worldLeft = min(point.worldX)
worldTop = min(point.worldY)
width = max(point.worldX) - min(point.worldX)
height = max(point.worldY) - min(point.worldY)
```

Des tests verifient que tous les points du polygon sont contenus dans ces bounds.

## 12. Compatibilite mode none / groundStatic / actorContact

Conserve :

- `ShadowCasterMode.none` retourne toujours `null` avant les checks de render pass ;
- `renderPass != ShadowRenderPass.groundStatic` reste rejete dans le resolver statique ;
- un profil `actorContact` reste rejete par le resolver statique ;
- les actor contact shadows restent gerees par leurs resolvers existants.

## 13. Protection contre double offset/scale

Offset et scale ne sont appliques qu'une fois :

- `resolveStaticShadowGeometry(...)` applique deja `offsetX`, `offsetY`, `scaleX`, `scaleY` ;
- Shadow-37 projette la geometrie finale resultante ;
- le resolver statique ne repasse plus par `resolveShadowRuntimeInstruction(...)`, donc il ne reapplique pas offset/scale.

Le test `applies offset and scale once after core footprint geometry` compare l'instruction runtime avec une projection core attendue.

## 14. Transmission elementFootprint / overrideFootprint

Le builder collection transmettait deja :

```dart
elementFootprint: source.elementShadow?.footprint
overrideFootprint: source.placedOverride?.footprint
```

Shadow-37 conserve cette transmission et teste que :

- `elementShadow.footprint` modifie le polygon runtime ;
- `placedOverride.footprint` modifie le polygon runtime au-dessus du footprint element ;
- un override custom sans footprint conserve le footprint element.

Les tests comparent maintenant les coordonnees des points polygonaux, pas l'identite des listes Dart.

## 15. Pourquoi ce lot ne touche pas editor

L'editeur sera le lot suivant de preview polygonale. Shadow-37 est volontairement runtime-only pour rendre le changement visible dans le jeu sans coupler `map_editor` a `map_runtime`.

## 16. Pourquoi ce lot ne touche pas aux modeles/codecs

`projectedPolygon` est une forme runtime derivee. Aucun JSON authoring nouveau n'est necessaire : les champs existants `ProjectElementShadowConfig.footprint` et `MapPlacedElementShadowOverride.footprint` suffisent.

## 17. Pourquoi ce lot ne change pas les composants Flame

Shadow-36 a deja ajoute le rendu polygonal dans `ShadowRuntimeRenderer`. Shadow-37 ne change pas l'ordre de rendu, les `MapLayersComponent`, ni les jeux Flame. Le provider existant continue a fournir une collection d'instructions.

Doc Flame consultee :

```text
mcp__flame_docs__.search_documentation("Flame render Canvas drawPath component render order priority")
-> No results found.
```

Le plan s'appuie donc sur les patterns locaux deja verifies par les tests runtime.

## 18. Tests ajoutes/modifies

`static_placed_element_shadow_runtime_resolver_test.dart` :

- static ellipse groundStatic -> `projectedPolygon` ;
- static contactBlob groundStatic -> `projectedPolygon` ;
- points polygonaux attendus depuis la projection core ;
- bounds contenant tous les points ;
- offset/scale appliques une seule fois ;
- footprint element / override conserve ;
- batch conserve l'ordre et ignore `none`.

`runtime_static_placed_element_shadow_collection_test.dart` :

- collection produit `projectedPolygon` ;
- profile override reste pris en compte ;
- offset/scale/opacity custom modifient l'instruction ;
- footprint element et override atteignent la geometrie runtime ;
- filters existants conserves.

`runtime_static_placed_element_shadow_host_integration_test.dart` :

- override custom modifie des points polygonaux ;
- host integration reste verte sans modifier les composants Flame.

## 19. Commandes lancees

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && dart format lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart test/shadow/static_placed_element_shadow_runtime_resolver_test.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 20. Resultats complets des tests cibles

### RED initial resolver

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
00:00 +13 -1: resolveStaticPlacedElementShadowRuntimeInstruction resolves ellipse groundStatic into a projected polygon instruction [E]
  Expected: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.projectedPolygon>
    Actual: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.ellipse>
00:00 +13 -2: resolveStaticPlacedElementShadowRuntimeInstruction resolves contactBlob groundStatic into a projected polygon instruction [E]
  Expected: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.projectedPolygon>
    Actual: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.contactBlob>
00:00 +13 -3: resolveStaticPlacedElementShadowRuntimeInstruction applies static metrics and Shadow-12 offset/scale geometry [E]
  Expected: an object with length of <4>
    Actual: []
     Which: has length of <0>
00:00 +22 -8: Some tests failed.
```

### `flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

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
00:00 +13: resolveStaticPlacedElementShadowRuntimeInstruction resolves ellipse groundStatic into a projected polygon instruction
00:00 +14: resolveStaticPlacedElementShadowRuntimeInstruction resolves contactBlob groundStatic into a projected polygon instruction
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

### `flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
00:00 +0: RuntimeStaticPlacedElementShadowSource uses value equality and matching hashCode
00:00 +1: RuntimeStaticPlacedElementShadowSource rejects blank ids
00:00 +2: RuntimeStaticPlacedElementShadowSource rejects blank element ids
00:00 +3: buildRuntimeStaticPlacedElementShadowCollection visible active element shadow with ellipse groundStatic creates one projected instruction
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

### `flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`

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

### `flutter test test/shadow/shadow_runtime_renderer_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
00:00 +0: shadowRuntimeColorForInstruction converts RGB hex and opacity to runtime color
00:00 +1: shadowRuntimeColorForInstruction converts opacity zero to transparent color
00:00 +2: shadowRuntimeColorForInstruction uses stable rounded alpha for fractional opacity
00:00 +3: shadowRuntimePaintForInstruction creates a hard-edge fill paint
00:00 +4: shadowRuntimePaintForInstruction accepts hardEdge softness
00:00 +5: ShadowRuntimeRenderer.renderInstruction draws an ellipse with visible center and transparent outside pixels
00:00 +6: ShadowRuntimeRenderer.renderInstruction draws contactBlob through the same V0 oval path
00:00 +7: ShadowRuntimeRenderer.renderInstruction keeps opacity zero transparent at the center
00:00 +8: ShadowRuntimeRenderer.renderInstruction draws projectedPolygon with visible interior and transparent outside
00:00 +9: ShadowRuntimeRenderer.renderInstruction keeps projectedPolygon opacity zero transparent inside
00:00 +10: ShadowRuntimeRenderer.renderInstructions draws multiple instructions in input order
00:00 +11: ShadowRuntimeRenderer.renderInstructions draws projectedPolygon and ellipse in input order
00:00 +12: ShadowRuntimeRenderer.renderCollectionPass draws only groundStatic instructions for the groundStatic pass
00:00 +13: ShadowRuntimeRenderer.renderCollectionPass draws only actorContact instructions for the actorContact pass
00:00 +14: ShadowRuntimeRenderer.renderCollectionPass filters projectedPolygon instructions by render pass
00:00 +15: All tests passed!
```

## 21. Ligne finale exacte des tests globaux

```text
cd packages/map_runtime && flutter test test/shadow
Resultat final exact : succes
Ligne finale exacte : 00:02 +220: All tests passed!
```

```text
cd packages/map_runtime && flutter test
Resultat final exact : succes
Ligne finale exacte : 00:19 +1141: All tests passed!
```

```text
cd packages/map_core && dart test test/shadow
Resultat final exact : succes
Ligne finale exacte : 00:00 +225: All tests passed!
```

```text
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
Resultat final exact : succes
Sortie exacte : No issues found! (ran in 1.7s)
```

```text
cd packages/map_core && dart analyze lib test/shadow
Resultat final exact : succes
Sortie exacte : No issues found!
```

## 22. Resultats des scans anti-derive

```text
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
Sortie : aucune sortie
```

```text
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
Sortie : aucune sortie
```

```text
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
Sortie : aucune sortie
```

```text
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
Sortie : aucune sortie
```

```text
git diff --check
Sortie : aucune sortie
```

```text
find .. -name AGENTS.md -print
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

## 23. git status initial

Avant implementation Shadow-37 :

```text
 M AGENTS.md
?? reports/shadows/shadow_lot_37_runtime_static_object_projection_integration_plan.md
```

## 24. git status final

```text
 M AGENTS.md
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_37_runtime_static_object_projection_integration.md
?? reports/shadows/shadow_lot_37_runtime_static_object_projection_integration_plan.md
```

## 25. git diff --stat

Stat global incluant la modification preexistante `AGENTS.md` :

```text
AGENTS.md                                          | 1289 ++++++++++++--------
 ...tic_placed_element_shadow_runtime_resolver.dart |  118 +-
 ...atic_placed_element_shadow_collection_test.dart |  124 +-
 ...laced_element_shadow_host_integration_test.dart |   40 +-
 ...laced_element_shadow_runtime_resolver_test.dart |  214 +++-
 5 files changed, 1172 insertions(+), 613 deletions(-)
```

Stat limite aux fichiers Shadow-37 :

```text
...tic_placed_element_shadow_runtime_resolver.dart | 118 ++++++++++--
 ...atic_placed_element_shadow_collection_test.dart | 124 +++++++++---
 ...laced_element_shadow_host_integration_test.dart |  40 +++-
 ...laced_element_shadow_runtime_resolver_test.dart | 214 +++++++++++++++++----
 4 files changed, 418 insertions(+), 78 deletions(-)
```

## 26. git diff --name-status

Name-status global incluant `AGENTS.md` preexistant :

```text
M	AGENTS.md
M	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
M	packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Name-status limite aux fichiers Shadow-37 :

```text
M	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
M	packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

## 27. Non-objectifs respectes

- Aucun `packages/map_editor/**` modifie.
- Aucun `packages/map_gameplay/**` modifie.
- Aucun `packages/map_battle/**` modifie.
- Aucun modele persistant core modifie.
- Aucun codec JSON core modifie.
- Aucun generated file modifie.
- Aucun `build_runner` lance.
- Aucun composant Flame modifie.
- Aucun `MapLayersComponent`, `PlayableMapGame`, `RuntimeMapGame` modifie.
- Aucune direction globale de lumiere ajoutee.
- Aucun `time-of-day`, `WorldLightState`, `ShadowLightProfile`, `LightDirection` ajoute.
- Aucun `blur`, `saveLayer`, `ImageFilter`, atlas ou sprite shadow ajoute.
- Aucun commit effectue.

## 28. Risques / reserves

- L'editeur affiche encore l'ancienne preview ovale tant que Shadow-38 n'est pas implemente. C'est attendu.
- Les profils statiques `contactBlob` sortent maintenant en `projectedPolygon` dans le resolver statique. Les actor contact shadows restent inchangees.
- Le rendu est une projection V0. Il devrait etre nettement moins absurde que les galettes, mais la direction/longueur automatique fine reste a calibrer dans les lots suivants.
- La modification preexistante `AGENTS.md` reste dans le worktree et n'appartient pas a Shadow-37.

## 29. Auto-review finale

```text
- Ai-je fait produire projectedPolygon aux static placed shadows runtime ? oui.
- Ai-je utilise resolveProjectedStaticShadowGeometry(...) ? oui.
- Ai-je mappe les points core vers ShadowRuntimePoint ? oui.
- Ai-je calcule les bounds depuis les points polygonaux ? oui.
- Ai-je evite resolveShadowRuntimeInstruction(...) pour la sortie statique finale ? oui.
- Ai-je evite double offset/scale ? oui.
- Ai-je conserve mode none -> null ? oui.
- Ai-je conserve le rejet actorContact dans le resolver statique ? oui.
- Ai-je laisse les actor contact shadows intactes ? oui.
- Ai-je evite editor ? oui.
- Ai-je evite les modeles/codecs core ? oui.
- Ai-je evite les composants Flame et l'ordre de rendu ? oui.
- Ai-je evite toute lumiere globale ? oui.
```

## 30. Regard critique sur le prompt

Le prompt/plan est bon pour obtenir un premier changement visible cote runtime. Le point discutable est l'utilisation de `contactBlob` comme profil statique : ce mode portait historiquement une forme ovale, mais le besoin produit actuel est de supprimer les galettes pour les objets statiques. Le compromis retenu est sain : en `groundStatic`, `ellipse` et `contactBlob` restent des modes sources acceptes, mais la forme runtime derivee devient `projectedPolygon`.

Le point a surveiller pour la suite : Shadow-38 doit aligner l'editeur. Sans Shadow-38, l'utilisateur verra une difference runtime mais pas encore dans la preview canvas.

## 31. Contenu complet des fichiers crees/modifies

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
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final StaticShadowFootprintConfig? elementFootprint;
  final StaticShadowFootprintConfig? overrideFootprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics &&
          other.elementFootprint == elementFootprint &&
          other.overrideFootprint == overrideFootprint;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
        elementFootprint,
        overrideFootprint,
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
  final projectedGeometry = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
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
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
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
### `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`

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
        'visible active element shadow with ellipse groundStatic creates one projected instruction',
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
      _expectProjectedPolygon(instruction);
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
          ShadowRuntimeShapeKind.projectedPolygon);
      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
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
        collection.groundStatic.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
    });

    test('custom placed override applies offset scale and opacity', () {
      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
        ],
      ).groundStatic.single;
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
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, baseline);
      expect(instruction.opacity, 0.2);
    });

    test(
        'custom placed override with shadowProfileId uses the override profile',
        () {
      final elementProfile = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
        ],
      ).groundStatic.single;
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
          ShadowRuntimeShapeKind.projectedPolygon);
      _expectDifferentPolygon(collection.groundStatic.single, elementProfile);
    });

    test(
        'custom placed override without shadowProfileId keeps the element profile',
        () {
      final inheritedProfile = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
            ),
          ),
        ],
      ).groundStatic.single;
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
        collection.groundStatic.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
      _expectDifferentPolygon(collection.groundStatic.single, inheritedProfile);
    });

    test('element shadow footprint is transmitted to runtime geometry', () {
      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, baseline);
    });

    test('placed override footprint is transmitted to runtime geometry', () {
      final elementOnly = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
          ),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              footprint: StaticShadowFootprintConfig(
                anchorYRatio: 0.5,
                footprintHeightRatio: 0.125,
              ),
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, elementOnly);
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
  StaticShadowFootprintConfig? footprint,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: profileId,
    footprint: footprint,
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
        scaleX: 0.5,
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

void _expectProjectedPolygon(ShadowRuntimeRenderInstruction instruction) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.polygonPoints, hasLength(4));
  expect(instruction.width, greaterThan(0));
  expect(instruction.height, greaterThan(0));
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

void _expectDifferentPolygon(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction baseline,
) {
  expect(actual.polygonPoints, hasLength(baseline.polygonPoints.length));
  var hasDifferentPoint = false;
  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
    final actualPoint = actual.polygonPoints[i];
    final baselinePoint = baseline.polygonPoints[i];
    if (actualPoint.worldX != baselinePoint.worldX ||
        actualPoint.worldY != baselinePoint.worldY) {
      hasDifferentPoint = true;
    }
  }
  expect(hasDifferentPoint, isTrue);
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
### `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime static placed element shadow host integration', () {
    test('PlayableMapGame builds static shadows for configured placed elements',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);
      expect(collection.groundStatic.single.renderPass,
          ShadowRenderPass.groundStatic);
    });

    test('static shadow is visible in the background render when configured',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final instruction =
          background.shadowCollectionProvider!()!.groundStatic.single;
      final image = await _render(background, width: 160, height: 160);
      final centerX = (instruction.worldLeft + instruction.width / 2).round();
      final centerY = (instruction.worldTop + instruction.height / 2).round();

      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
    });

    test('empty catalog or missing profile creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(shadowCatalog: const ProjectShadowCatalog.empty()),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('element without shadow config creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(elementShadow: null),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('disabled placed override creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('custom placed override modifies the static shadow instruction',
        () async {
      final baselineGame = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );
      baselineGame.onGameResize(Vector2(160, 160));
      await baselineGame.onLoad();
      baselineGame.update(0);
      final baselineInstruction = _backgroundLayer(baselineGame)
          .shadowCollectionProvider!()!
          .groundStatic
          .single;

      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 8,
            scaleX: 2,
            opacity: 0.2,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final instruction = _backgroundLayer(game)
          .shadowCollectionProvider!()!
          .groundStatic
          .single;

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(
        _hasDifferentPolygonPoints(instruction, baselineInstruction),
        isTrue,
      );
      expect(instruction.opacity, 0.2);
    });

    test('internal static and actor shadows are merged for the active map',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!()!;

      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, hasLength(1));
      expect(collection.instructions.first.renderPass,
          ShadowRenderPass.groundStatic);
      expect(collection.instructions.last.renderPass,
          ShadowRenderPass.actorContact);
    });

    test('static and actor flags affect only their internal collections',
        () async {
      final staticOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );
      staticOnly.onGameResize(Vector2(160, 160));
      await staticOnly.onLoad();
      staticOnly.update(0);

      final actorOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableStaticPlacedElementShadows: false,
      );
      actorOnly.onGameResize(Vector2(160, 160));
      await actorOnly.onLoad();
      actorOnly.update(0);

      final disabled = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );
      disabled.onGameResize(Vector2(160, 160));
      await disabled.onLoad();
      disabled.update(0);

      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.groundStatic,
        hasLength(1),
      );
      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.actorContact,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.groundStatic,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.actorContact,
        hasLength(1),
      );
      expect(_backgroundLayer(disabled).shadowCollectionProvider, isNull);
    });

    test('external provider remains priority even when internal flags are off',
        () async {
      ShadowRuntimeInstructionCollection? provider() {
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(64, 64));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(
          background.shadowCollectionProvider!()!.groundStatic, hasLength(1));
    });

    test(
        'connected map background receives static shadows but no actor shadows',
        () async {
      final connected = _bundle(mapId: 'connected-static-map');
      final game = PlayableMapGame(
        bundle: _bundle(
          mapId: 'active-static-map',
          connectionTargetMapId: 'connected-static-map',
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
          expect(mapId, 'connected-static-map');
          return Future.value(connected);
        },
      );

      game.onGameResize(Vector2(320, 160));
      await game.onLoad();
      await _pumpUntil(
          game, () => game.debugIsMapLoaded('connected-static-map'));
      game.update(0);
      final activeProvider =
          game.debugShadowCollectionProviderForMap('active-static-map')!;
      final connectedProvider =
          game.debugShadowCollectionProviderForMap('connected-static-map')!;

      expect(activeProvider()!.groundStatic, hasLength(1));
      expect(activeProvider()!.actorContact, hasLength(1));
      expect(connectedProvider()!.groundStatic, hasLength(1));
      expect(connectedProvider()!.actorContact, isEmpty);
    });

    test('RuntimeMapGame remains passive for static placed element shadows',
        () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });
  });
}

RuntimeMapBundle _bundle({
  String mapId = 'static-shadow-test',
  ProjectShadowCatalog? shadowCatalog,
  Object? elementShadow = _defaultElementShadow,
  MapPlacedElementShadowOverride? placedOverride,
  String? connectionTargetMapId,
}) {
  final tileLayer = List<int>.filled(16, 0);
  final connections = <MapConnection>[
    if (connectionTargetMapId != null)
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: connectionTargetMapId,
      ),
  ];
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Static Shadow Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      elements: [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'props',
          categoryId: 'nature',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: identical(elementShadow, _defaultElementShadow)
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'soft-tree',
                )
              : elementShadow as ProjectElementShadowConfig?,
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
      shadowCatalog: shadowCatalog ?? _shadowCatalog(),
    ),
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'base',
          tiles: tileLayer,
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'tree-1',
          layerId: 'decor',
          elementId: 'tree',
          pos: const GridPos(x: 1, y: 1),
          shadowOverride: placedOverride,
        ),
      ],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      connections: connections,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-static-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const Object _defaultElementShadow = Object();

ProjectShadowCatalog _shadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'soft-tree',
        name: 'Soft Tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
      ),
    ],
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

MapLayersComponent _backgroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
}

MapLayersComponent _foregroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
}

Future<ui.Image> _render(
  MapLayersComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() condition,
) async {
  for (var i = 0; i < 20; i += 1) {
    if (condition()) {
      return;
    }
    game.update(0);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met');
}

ShadowRuntimeRenderInstruction _shadow({
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}

bool _hasDifferentPolygonPoints(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction baseline,
) {
  if (actual.polygonPoints.length != baseline.polygonPoints.length) {
    return true;
  }
  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
    final actualPoint = actual.polygonPoints[i];
    final baselinePoint = baseline.polygonPoints[i];
    if (actualPoint.worldX != baselinePoint.worldX ||
        actualPoint.worldY != baselinePoint.worldY) {
      return true;
    }
  }
  return false;
}

```

## 32. Diffs complets des fichiers Shadow-37 modifies

```diff
diff --git a/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart b/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
index b66e565b..e1062e93 100644
--- a/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
+++ b/packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
@@ -107,12 +107,7 @@ ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
     elementFootprint: elementFootprint,
   );
   final geometry = resolveStaticShadowGeometry(
-    metrics: StaticShadowVisualMetrics(
-      left: metrics.worldLeft,
-      top: metrics.worldTop,
-      visualWidth: metrics.visualWidth,
-      visualHeight: metrics.visualHeight,
-    ),
+    metrics: _visualMetricsFromRuntimeMetrics(metrics),
     shadowConfig: shadowConfig ?? _identityShadowConfig,
     elementFootprint: legacyAndElementFootprint,
     overrideFootprint: overrideFootprint,
@@ -146,16 +141,25 @@ ShadowRuntimeRenderInstruction?
     );
   }
 
-  return resolveShadowRuntimeInstruction(
-    ShadowRuntimeResolutionInput(
-      resolvedConfig: resolved,
-      anchor: staticPlacedElementShadowAnchorFromMetrics(
-        input.metrics,
-        shadowConfig: resolved,
-        elementFootprint: input.elementFootprint,
-        overrideFootprint: input.overrideFootprint,
-      ),
-    ),
+  final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
+  final projectedGeometry = resolveProjectedStaticShadowGeometry(
+    baseGeometry: baseGeometry,
+    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
+  );
+  final points = _runtimePointsFromProjection(projectedGeometry);
+  final bounds = _boundsFromRuntimePoints(points);
+
+  return ShadowRuntimeRenderInstruction(
+    shape: ShadowRuntimeShapeKind.projectedPolygon,
+    renderPass: resolved.renderPass,
+    worldLeft: bounds.left,
+    worldTop: bounds.top,
+    width: bounds.width,
+    height: bounds.height,
+    opacity: resolved.opacity,
+    colorHexRgb: resolved.colorHexRgb,
+    softnessMode: resolved.softnessMode,
+    polygonPoints: points,
   );
 }
 
@@ -227,6 +231,88 @@ StaticShadowFootprintConfig _mergeLegacyAndElementFootprint({
   );
 }
 
+ResolvedStaticShadowGeometry _resolveStaticPlacedElementBaseGeometry(
+  StaticPlacedElementShadowRuntimeInput input,
+) {
+  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
+    metrics: input.metrics,
+    elementFootprint: input.elementFootprint,
+  );
+  return resolveStaticShadowGeometry(
+    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
+    shadowConfig: input.resolvedConfig,
+    elementFootprint: legacyAndElementFootprint,
+    overrideFootprint: input.overrideFootprint,
+  );
+}
+
+StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
+  StaticPlacedElementShadowRuntimeMetrics metrics,
+) {
+  return StaticShadowVisualMetrics(
+    left: metrics.worldLeft,
+    top: metrics.worldTop,
+    visualWidth: metrics.visualWidth,
+    visualHeight: metrics.visualHeight,
+  );
+}
+
+List<ShadowRuntimePoint> _runtimePointsFromProjection(
+  ProjectedStaticShadowGeometry geometry,
+) {
+  return List<ShadowRuntimePoint>.unmodifiable(
+    geometry.points.map(
+      (point) => ShadowRuntimePoint(
+        worldX: point.x,
+        worldY: point.y,
+      ),
+    ),
+  );
+}
+
+_ProjectedRuntimeShadowBounds _boundsFromRuntimePoints(
+  List<ShadowRuntimePoint> points,
+) {
+  var minX = points.first.worldX;
+  var maxX = points.first.worldX;
+  var minY = points.first.worldY;
+  var maxY = points.first.worldY;
+  for (final point in points.skip(1)) {
+    if (point.worldX < minX) {
+      minX = point.worldX;
+    }
+    if (point.worldX > maxX) {
+      maxX = point.worldX;
+    }
+    if (point.worldY < minY) {
+      minY = point.worldY;
+    }
+    if (point.worldY > maxY) {
+      maxY = point.worldY;
+    }
+  }
+  return _ProjectedRuntimeShadowBounds(
+    left: minX,
+    top: minY,
+    width: maxX - minX,
+    height: maxY - minY,
+  );
+}
+
+final class _ProjectedRuntimeShadowBounds {
+  const _ProjectedRuntimeShadowBounds({
+    required this.left,
+    required this.top,
+    required this.width,
+    required this.height,
+  });
+
+  final double left;
+  final double top;
+  final double width;
+  final double height;
+}
+
 const _identityShadowConfig = ResolvedShadowConfig(
   shadowProfileId: 'runtime-static-shadow-anchor',
   mode: ShadowCasterMode.ellipse,
diff --git a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
index f1a0e492..2117a44f 100644
--- a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
@@ -42,7 +42,7 @@ void main() {
 
   group('buildRuntimeStaticPlacedElementShadowCollection', () {
     test(
-        'visible active element shadow with ellipse groundStatic creates one instruction',
+        'visible active element shadow with ellipse groundStatic creates one projected instruction',
         () {
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
@@ -56,11 +56,7 @@ void main() {
       expect(collection.groundStatic, hasLength(1));
       final instruction = collection.groundStatic.single;
       expect(instruction.renderPass, ShadowRenderPass.groundStatic);
-      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
-      expect(instruction.width, closeTo(36, 0.0001));
-      expect(instruction.height, closeTo(7.5, 0.0001));
-      expect(instruction.worldLeft, closeTo(88, 0.0001));
-      expect(instruction.worldTop, closeTo(186.25, 0.0001));
+      _expectProjectedPolygon(instruction);
     });
 
     test('contactBlob groundStatic profile creates a groundStatic instruction',
@@ -76,7 +72,8 @@ void main() {
       expect(collection.groundStatic.single.renderPass,
           ShadowRenderPass.groundStatic);
       expect(collection.groundStatic.single.shape,
-          ShadowRuntimeShapeKind.contactBlob);
+          ShadowRuntimeShapeKind.projectedPolygon);
+      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
     });
 
     test('invisible source creates no instruction', () {
@@ -141,11 +138,19 @@ void main() {
 
       expect(collection.groundStatic, hasLength(1));
       expect(
-          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
-      expect(collection.groundStatic.single.width, closeTo(36, 0.0001));
+        collection.groundStatic.single.shape,
+        ShadowRuntimeShapeKind.projectedPolygon,
+      );
+      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
     });
 
     test('custom placed override applies offset scale and opacity', () {
+      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
+        ],
+      ).groundStatic.single;
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
         sources: [
@@ -164,16 +169,20 @@ void main() {
       );
 
       final instruction = collection.groundStatic.single;
-      expect(instruction.width, closeTo(60, 0.0001));
-      expect(instruction.height, closeTo(45, 0.0001));
-      expect(instruction.worldLeft, closeTo(75, 0.0001));
-      expect(instruction.worldTop, closeTo(164.5, 0.0001));
+      _expectProjectedPolygon(instruction);
+      _expectDifferentPolygon(instruction, baseline);
       expect(instruction.opacity, 0.2);
     });
 
     test(
         'custom placed override with shadowProfileId uses the override profile',
         () {
+      final elementProfile = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
+        ],
+      ).groundStatic.single;
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
         sources: [
@@ -188,13 +197,24 @@ void main() {
       );
 
       expect(collection.groundStatic.single.shape,
-          ShadowRuntimeShapeKind.contactBlob);
-      expect(collection.groundStatic.single.width, closeTo(30, 0.0001));
+          ShadowRuntimeShapeKind.projectedPolygon);
+      _expectDifferentPolygon(collection.groundStatic.single, elementProfile);
     });
 
     test(
         'custom placed override without shadowProfileId keeps the element profile',
         () {
+      final inheritedProfile = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(
+            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
+            placedOverride: MapPlacedElementShadowOverride(
+              mode: ShadowOverrideMode.custom,
+            ),
+          ),
+        ],
+      ).groundStatic.single;
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
         sources: [
@@ -209,11 +229,19 @@ void main() {
       );
 
       expect(
-          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
-      expect(collection.groundStatic.single.worldLeft, closeTo(89, 0.0001));
+        collection.groundStatic.single.shape,
+        ShadowRuntimeShapeKind.projectedPolygon,
+      );
+      _expectDifferentPolygon(collection.groundStatic.single, inheritedProfile);
     });
 
     test('element shadow footprint is transmitted to runtime geometry', () {
+      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
+        catalog: _catalog(),
+        sources: [
+          _source(),
+        ],
+      ).groundStatic.single;
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
         sources: [
@@ -229,13 +257,24 @@ void main() {
       );
 
       final instruction = collection.groundStatic.single;
-      expect(instruction.width, closeTo(24, 0.0001));
-      expect(instruction.height, closeTo(7.5, 0.0001));
-      expect(instruction.worldLeft, closeTo(84, 0.0001));
-      expect(instruction.worldTop, closeTo(186.25, 0.0001));
+      _expectProjectedPolygon(instruction);
+      _expectDifferentPolygon(instruction, baseline);
     });
 
     test('placed override footprint is transmitted to runtime geometry', () {
+      final elementOnly = buildRuntimeStaticPlacedElementShadowCollection(
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
+      ).groundStatic.single;
       final collection = buildRuntimeStaticPlacedElementShadowCollection(
         catalog: _catalog(),
         sources: [
@@ -258,10 +297,8 @@ void main() {
       );
 
       final instruction = collection.groundStatic.single;
-      expect(instruction.width, closeTo(24, 0.0001));
-      expect(instruction.height, closeTo(3.75, 0.0001));
-      expect(instruction.worldLeft, closeTo(84, 0.0001));
-      expect(instruction.worldTop, closeTo(158.125, 0.0001));
+      _expectProjectedPolygon(instruction);
+      _expectDifferentPolygon(instruction, elementOnly);
     });
 
     test('none profile creates no instruction', () {
@@ -429,6 +466,7 @@ ProjectShadowCatalog _catalog() {
         id: 'blob_ground',
         mode: ShadowCasterMode.contactBlob,
         renderPass: ShadowRenderPass.groundStatic,
+        scaleX: 0.5,
       ),
       _profile(
         id: 'none_profile',
@@ -450,6 +488,42 @@ ProjectShadowCatalog _catalog() {
   );
 }
 
+void _expectProjectedPolygon(ShadowRuntimeRenderInstruction instruction) {
+  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+  expect(instruction.polygonPoints, hasLength(4));
+  expect(instruction.width, greaterThan(0));
+  expect(instruction.height, greaterThan(0));
+  for (final point in instruction.polygonPoints) {
+    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
+    expect(
+      point.worldX,
+      lessThanOrEqualTo(instruction.worldLeft + instruction.width),
+    );
+    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
+    expect(
+      point.worldY,
+      lessThanOrEqualTo(instruction.worldTop + instruction.height),
+    );
+  }
+}
+
+void _expectDifferentPolygon(
+  ShadowRuntimeRenderInstruction actual,
+  ShadowRuntimeRenderInstruction baseline,
+) {
+  expect(actual.polygonPoints, hasLength(baseline.polygonPoints.length));
+  var hasDifferentPoint = false;
+  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
+    final actualPoint = actual.polygonPoints[i];
+    final baselinePoint = baseline.polygonPoints[i];
+    if (actualPoint.worldX != baselinePoint.worldX ||
+        actualPoint.worldY != baselinePoint.worldY) {
+      hasDifferentPoint = true;
+    }
+  }
+  expect(hasDifferentPoint, isTrue);
+}
+
 ProjectShadowProfile _profile({
   required String id,
   required ShadowCasterMode mode,
diff --git a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
index c5ee8eba..167c8205 100644
--- a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
@@ -117,6 +117,20 @@ void main() {
 
     test('custom placed override modifies the static shadow instruction',
         () async {
+      final baselineGame = PlayableMapGame(
+        bundle: _bundle(),
+        projectFilePath: '/tmp/project.json',
+        runtimeTilesetImageLoader: _emptyImageLoader,
+        enableActorContactShadows: false,
+      );
+      baselineGame.onGameResize(Vector2(160, 160));
+      await baselineGame.onLoad();
+      baselineGame.update(0);
+      final baselineInstruction = _backgroundLayer(baselineGame)
+          .shadowCollectionProvider!()!
+          .groundStatic
+          .single;
+
       final game = PlayableMapGame(
         bundle: _bundle(
           placedOverride: MapPlacedElementShadowOverride(
@@ -139,8 +153,12 @@ void main() {
           .groundStatic
           .single;
 
-      expect(instruction.width, closeTo(96, 0.0001));
-      expect(instruction.worldLeft, closeTo(24, 0.0001));
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.polygonPoints, hasLength(4));
+      expect(
+        _hasDifferentPolygonPoints(instruction, baselineInstruction),
+        isTrue,
+      );
       expect(instruction.opacity, 0.2);
     });
 
@@ -469,3 +487,21 @@ ShadowRuntimeRenderInstruction _shadow({
     colorHexRgb: colorHexRgb,
   );
 }
+
+bool _hasDifferentPolygonPoints(
+  ShadowRuntimeRenderInstruction actual,
+  ShadowRuntimeRenderInstruction baseline,
+) {
+  if (actual.polygonPoints.length != baseline.polygonPoints.length) {
+    return true;
+  }
+  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
+    final actualPoint = actual.polygonPoints[i];
+    final baselinePoint = baseline.polygonPoints[i];
+    if (actualPoint.worldX != baselinePoint.worldX ||
+        actualPoint.worldY != baselinePoint.worldY) {
+      return true;
+    }
+  }
+  return false;
+}
diff --git a/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart b/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
index 9f864996..30144028 100644
--- a/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
+++ b/packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
@@ -248,68 +248,76 @@ void main() {
   });
 
   group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
-    test('resolves ellipse groundStatic into an instruction', () {
-      final instruction =
-          resolveStaticPlacedElementShadowRuntimeInstruction(_input());
+    test('resolves ellipse groundStatic into a projected polygon instruction',
+        () {
+      final input = _input();
+      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
+        input,
+      );
 
       expect(instruction, isNotNull);
-      expect(instruction!.shape, ShadowRuntimeShapeKind.ellipse);
+      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.polygonPoints, hasLength(4));
       expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      _expectInstructionMatchesProjectedGeometry(instruction, input);
     });
 
-    test('resolves contactBlob groundStatic into an instruction', () {
+    test(
+        'resolves contactBlob groundStatic into a projected polygon instruction',
+        () {
+      final input = _input(
+        resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
+      );
       final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
-        _input(
-          resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
-        ),
+        input,
       );
 
       expect(instruction, isNotNull);
-      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
+      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.polygonPoints, hasLength(4));
       expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      _expectInstructionMatchesProjectedGeometry(instruction, input);
     });
 
     test('applies static metrics and Shadow-12 offset/scale geometry', () {
-      final instruction =
-          resolveStaticPlacedElementShadowRuntimeInstruction(_input());
+      final input = _input();
+      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
+        input,
+      );
 
       expect(instruction, isNotNull);
-      expect(instruction!.width, closeTo(36, 0.000001));
-      expect(instruction.height, closeTo(7.5, 0.000001));
-      expect(instruction.worldLeft, closeTo(88, 0.000001));
-      expect(instruction.worldTop, closeTo(186.25, 0.000001));
+      _expectInstructionMatchesProjectedGeometry(instruction!, input);
+      _expectAllPointsInsideBounds(instruction);
     });
 
     test('applies offset and scale once after core footprint geometry', () {
-      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
-        _input(
-          elementFootprint: StaticShadowFootprintConfig(
-            anchorXRatio: 0.25,
-            anchorYRatio: 0.5,
-            footprintWidthRatio: 0.5,
-            footprintHeightRatio: 0.25,
-          ),
+      final input = _input(
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.5,
+          footprintWidthRatio: 0.5,
+          footprintHeightRatio: 0.25,
         ),
       );
+      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
+        input,
+      );
 
       expect(instruction, isNotNull);
-      expect(instruction!.width, closeTo(24, 0.000001));
-      expect(instruction.height, closeTo(7.5, 0.000001));
-      expect(instruction.worldLeft, closeTo(84, 0.000001));
-      expect(instruction.worldTop, closeTo(156.25, 0.000001));
+      _expectInstructionMatchesProjectedGeometry(instruction!, input);
     });
 
     test('custom override without footprint keeps element footprint', () {
+      final input = _input(
+        resolvedConfig: _resolvedConfig(offsetX: 4),
+        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+      );
       final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
-        _input(
-          resolvedConfig: _resolvedConfig(offsetX: 4),
-          elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
-        ),
+        input,
       );
 
       expect(instruction, isNotNull);
-      expect(instruction!.worldLeft, closeTo(76, 0.000001));
-      expect(instruction.worldTop, closeTo(186.25, 0.000001));
+      _expectInstructionMatchesProjectedGeometry(instruction!, input);
     });
 
     test('passes opacity color softness and renderPass through', () {
@@ -328,6 +336,7 @@ void main() {
       expect(instruction.colorHexRgb, '0A0B0C');
       expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
       expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
     });
 
     test('keeps opacity zero as a valid instruction', () {
@@ -388,7 +397,10 @@ void main() {
       ]);
 
       expect(instructions, hasLength(1));
-      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
+      expect(
+        instructions.single.shape,
+        ShadowRuntimeShapeKind.projectedPolygon,
+      );
     });
 
     test('preserves input order without sorting', () {
@@ -417,7 +429,10 @@ void main() {
       ]);
 
       expect(instructions, hasLength(1));
-      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
+      expect(
+        instructions.single.shape,
+        ShadowRuntimeShapeKind.projectedPolygon,
+      );
     });
 
     test('does not cull opacity zero instructions', () {
@@ -521,3 +536,132 @@ ResolvedShadowConfig _resolvedConfig({
     softnessMode: softnessMode,
   );
 }
+
+void _expectInstructionMatchesProjectedGeometry(
+  ShadowRuntimeRenderInstruction instruction,
+  StaticPlacedElementShadowRuntimeInput input,
+) {
+  final expected = _expectedProjectedGeometry(input);
+  final expectedPoints = expected.points
+      .map(
+        (point) => ShadowRuntimePoint(
+          worldX: point.x,
+          worldY: point.y,
+        ),
+      )
+      .toList();
+
+  expect(instruction.polygonPoints, hasLength(expectedPoints.length));
+  for (var i = 0; i < expectedPoints.length; i += 1) {
+    expect(
+      instruction.polygonPoints[i].worldX,
+      closeTo(expectedPoints[i].worldX, 0.000001),
+    );
+    expect(
+      instruction.polygonPoints[i].worldY,
+      closeTo(expectedPoints[i].worldY, 0.000001),
+    );
+  }
+
+  final expectedBounds = _boundsFromPoints(expectedPoints);
+  expect(instruction.worldLeft, closeTo(expectedBounds.left, 0.000001));
+  expect(instruction.worldTop, closeTo(expectedBounds.top, 0.000001));
+  expect(instruction.width, closeTo(expectedBounds.width, 0.000001));
+  expect(instruction.height, closeTo(expectedBounds.height, 0.000001));
+}
+
+void _expectAllPointsInsideBounds(ShadowRuntimeRenderInstruction instruction) {
+  for (final point in instruction.polygonPoints) {
+    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
+    expect(
+      point.worldX,
+      lessThanOrEqualTo(instruction.worldLeft + instruction.width),
+    );
+    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
+    expect(
+      point.worldY,
+      lessThanOrEqualTo(instruction.worldTop + instruction.height),
+    );
+  }
+}
+
+ProjectedStaticShadowGeometry _expectedProjectedGeometry(
+  StaticPlacedElementShadowRuntimeInput input,
+) {
+  final metrics = input.metrics;
+  final legacyAndElementFootprint = resolveStaticShadowFootprint(
+    elementFootprint: StaticShadowFootprintConfig(
+      anchorXRatio: metrics.anchorXRatio,
+      anchorYRatio: metrics.anchorYRatio,
+      footprintWidthRatio: metrics.baseWidthMultiplier,
+      footprintHeightRatio: metrics.baseHeightMultiplier,
+    ),
+    overrideFootprint: input.elementFootprint,
+  );
+  final baseGeometry = resolveStaticShadowGeometry(
+    metrics: StaticShadowVisualMetrics(
+      left: metrics.worldLeft,
+      top: metrics.worldTop,
+      visualWidth: metrics.visualWidth,
+      visualHeight: metrics.visualHeight,
+    ),
+    shadowConfig: input.resolvedConfig,
+    elementFootprint: StaticShadowFootprintConfig(
+      anchorXRatio: legacyAndElementFootprint.anchorXRatio,
+      anchorYRatio: legacyAndElementFootprint.anchorYRatio,
+      footprintWidthRatio: legacyAndElementFootprint.footprintWidthRatio,
+      footprintHeightRatio: legacyAndElementFootprint.footprintHeightRatio,
+    ),
+    overrideFootprint: input.overrideFootprint,
+  );
+  return resolveProjectedStaticShadowGeometry(
+    baseGeometry: baseGeometry,
+    metrics: StaticShadowVisualMetrics(
+      left: metrics.worldLeft,
+      top: metrics.worldTop,
+      visualWidth: metrics.visualWidth,
+      visualHeight: metrics.visualHeight,
+    ),
+  );
+}
+
+_RuntimeTestBounds _boundsFromPoints(List<ShadowRuntimePoint> points) {
+  var minX = points.first.worldX;
+  var maxX = points.first.worldX;
+  var minY = points.first.worldY;
+  var maxY = points.first.worldY;
+  for (final point in points.skip(1)) {
+    if (point.worldX < minX) {
+      minX = point.worldX;
+    }
+    if (point.worldX > maxX) {
+      maxX = point.worldX;
+    }
+    if (point.worldY < minY) {
+      minY = point.worldY;
+    }
+    if (point.worldY > maxY) {
+      maxY = point.worldY;
+    }
+  }
+  return _RuntimeTestBounds(
+    left: minX,
+    top: minY,
+    width: maxX - minX,
+    height: maxY - minY,
+  );
+}
+
+final class _RuntimeTestBounds {
+  const _RuntimeTestBounds({
+    required this.left,
+    required this.top,
+    required this.width,
+    required this.height,
+  });
+
+  final double left;
+  final double top;
+  final double width;
+  final double height;
+}

```
