# ShadowV2-28 — Projected Building Shadow Editor Preview POC V0

## 1. Résumé exécutif

ShadowV2-28 implémente une preview editor minimale des ombres projetées de bâtiments déjà authorées.

Résultat :

- builder editor V2 créé dans `map_editor`, basé uniquement sur `map_core` ;
- aucune dépendance `map_runtime` ajoutée ;
- `MapGridPainter` construit les instructions de preview V2 ;
- la preview V2 est peinte dans le slot d’ombres statiques existant ;
- la preview V2 est peinte avant la preview V1 dans ce slot ;
- la preview V2 est peinte sous les éléments placés ;
- aucune UI authoring, aucun screenshot, aucune baseline, aucun Selbrume.

Le POC respecte le design ShadowV2-27 : `map_editor` consomme la géométrie pure ShadowV2 via `resolveProjectedBuildingShadowGeometry(...)` et convertit le résultat vers la primitive editor existante `EditorStaticShadowPreviewInstruction`.

## 2. Objectif du lot

Objectif exact :

```text
Afficher dans le canvas editor une preview minimale des ombres projetées ShadowV2 déjà authorées,
dans le slot d’ombres statiques existant,
sans importer map_runtime,
sans modifier le runtime,
sans modifier map_core,
sans créer d’UI authoring,
sans screenshot,
sans baseline,
sans Selbrume.
```

Chaîne implémentée :

```text
ProjectManifest + MapData + tileWidth/tileHeight
-> buildEditorProjectedBuildingShadowPreviewInstructions(...)
-> List<EditorStaticShadowPreviewInstruction>
-> MapGridPainter
-> paintEditorStaticShadowPreviewInstructions(...)
-> Canvas editor
```

## 3. Rappel ShadowV2-27

ShadowV2-27 a validé :

- Option B : `map_editor` utilise `map_core`, pas `map_runtime` ;
- `MapGridPainter` est le point d’intégration ;
- `EditorStaticShadowPreviewInstruction` peut être réutilisé ;
- le painter editor sait déjà dessiner `projectedPolygon` ;
- la preview V2 doit être peinte dans le slot d’ombres statiques existant ;
- V2 doit être peinte avant V1 dans ce slot.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Fichiers préexistants non liés au lot : Aucun.

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation : ShadowV2-27 a fourni le design gate. ShadowV2-28 est l’implémentation bornée de ce design, sans élargissement de périmètre.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
reports/shadows/v2/shadow_v2_28_projected_building_shadow_editor_preview_poc.md
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Fichiers supprimés : Aucun.

Generated modifiés : Aucun.

Fichiers `map_core` modifiés : Aucun.

Fichiers `map_runtime` modifiés : Aucun.

Screenshots/baselines : Aucun.

Selbrume : Aucun.

## 7. Audit initial du canvas / preview shadow editor

Commandes d’audit initial :

```bash
rg -n "paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewShapeKind|EditorStaticShadowPreviewPoint|futureStaticElementShadows|projectedPolygon" packages/map_editor/lib packages/map_editor/test
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadow|StaticShadowVisualMetrics|ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "map_runtime|ShadowRuntime|buildRuntimeProjectedBuildingShadowCollection|ShadowRuntimeRenderer|ShadowRuntimeInstructionCollection|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec" packages/map_editor/lib packages/map_editor/test
```

Résultats utiles :

- `EditorStaticShadowPreviewInstruction`, `EditorStaticShadowPreviewPoint` et `EditorStaticShadowPreviewShapeKind.projectedPolygon` existent déjà dans `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`.
- `paintEditorStaticShadowPreviewInstructions(...)` existe déjà dans `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`.
- `MapGridPainter.paint(...)` appelle déjà `paintEditorStaticShadowPreviewInstructions(...)` dans le slot d’ombres statiques.
- `editor_shadow_render_order_contract.dart` contient le slot `futureStaticElementShadows`.
- `map_core` exporte déjà les modèles ShadowV2 et `resolveProjectedBuildingShadowGeometry(...)`.
- Les hits `genericProjection`, `resolveProjectedStaticShadowGeometry` et `resolveStaticShadowFamilyProjectionSpec` existants sont dans la preview V1 ou les tests V1, pas dans le nouveau builder V2.
- `map_editor` contient des commentaires qui mentionnent `map_runtime`, mais ne dépend pas de `map_runtime`.

Confirmations :

- `map_editor` dépend déjà de `map_core`.
- `map_editor` ne dépend pas de `map_runtime`.
- `EditorStaticShadowPreviewInstruction` supporte déjà `projectedPolygon`.
- `MapGridPainter` possède déjà un slot de preview shadow.
- `paintEditorStaticShadowPreviewInstructions(...)` est réutilisable.
- aucun fichier production runtime/core n’était nécessaire.

## 8. Builder editor V2 créé

Fichier créé :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
```

API :

```dart
List<EditorStaticShadowPreviewInstruction>
    buildEditorProjectedBuildingShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
})
```

Comportement :

- indexe `manifest.elements` par id ;
- indexe les `TileLayer` visibles avec `opacity > 0` ;
- parcourt `map.placedElements` dans l’ordre source ;
- skippe les placements opacity `<= 0` ;
- skippe les layers absents/invisibles/transparents ;
- lit `ProjectElementEntry.projectedBuildingShadow` ;
- skippe config absente ou disabled ;
- lookup le preset dans `manifest.projectedBuildingShadowCatalog` ;
- skippe preset absent sans throw ;
- calcule `StaticShadowVisualMetrics` depuis `tileWidth` / `tileHeight` effectifs du canvas editor ;
- appelle `resolveProjectedBuildingShadowGeometry(...)` ;
- convertit les points V2 en `EditorStaticShadowPreviewPoint` ;
- retourne une liste unmodifiable d’`EditorStaticShadowPreviewInstruction`.

## 9. Intégration MapGridPainter

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

`map_canvas.dart` ajoute l’import du builder editor V2, parce que `map_grid_painter.dart` est un part file.

`MapGridPainter.paint(...)` construit les instructions V2 au même niveau que les instructions V1 :

```dart
final projectedBuildingShadowPreviewInstructions = projectContext == null
    ? const <EditorStaticShadowPreviewInstruction>[]
    : buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: projectContext,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );
```

Puis il peint V2 avant V1 :

```dart
paintEditorStaticShadowPreviewInstructions(
  canvas,
  projectedBuildingShadowPreviewInstructions,
);

paintEditorStaticShadowPreviewInstructions(
  canvas,
  staticShadowPreviewInstructions,
);
```

## 10. Ordre de rendu V2 / V1 / éléments placés

Ordre effectif dans le slot shadow :

```text
1. Preview ShadowV2 projected building
2. Preview Shadow V1 static existante
3. Placed elements background
```

Le test canvas vérifie :

- un pixel de shadow V2 non recouvert reçoit de l’alpha ;
- un pixel situé à la fois sous l’ombre et sous le sprite final reste rouge opaque, ce qui prouve que le sprite est au-dessus de la preview ;
- l’ordre source de `MapGridPainter` place le paint V2 avant le paint V1.

## 11. Tests builder ajoutés

Fichier créé :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Tests ajoutés :

- `builds a projected polygon preview`
- `returns empty when element has no projectedBuildingShadow config`
- `returns empty when projectedBuildingShadow is disabled`
- `skips missing projected building shadow preset without throwing`
- `skips hidden or transparent tile layers`
- `skips zero opacity placements`
- `skips invalid visual source dimensions`
- `preserves placed element source order`
- `does not depend on runtime or auto projection`

Le test valide les points attendus :

```text
(64,128)
(64,192)
(112,176)
(112,144)
```

Et les bounds :

```text
left = 64
top = 128
width = 48
height = 64
```

## 12. Tests canvas ajoutés

Fichier modifié :

```text
packages/map_editor/test/map_grid_painter_test.dart
```

Tests ajoutés :

- `paints projected building shadow preview below placed elements`
- `paints projected building shadow preview before static shadow preview`

Le test pixel-level utilise une image mémoire, pas de screenshot disque et pas de golden.

## 13. Test anti-dérive runtime/genericProjection

Le test source-level lit :

```text
lib/src/application/shadow/editor_projected_building_shadow_preview.dart
```

Et vérifie l’absence de :

```text
map_runtime
ShadowRuntime
buildRuntimeProjectedBuildingShadowCollection
ShadowRuntimeRenderer
genericProjection
applyElementAutoShadowPolicyToProject
diagnoseProjectedBuildingShadows
resolveProjectedStaticShadowGeometry
resolveStaticShadowFamilyProjectionSpec
static_shadow_family_projection
element_auto_shadow_policy
```

Les chaînes interdites sont concaténées dans le test pour que l’audit final ne se détecte pas lui-même.

## 14. TDD RED initial

Après création du test builder, avant création du builder, commande lancée :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie RED initiale :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
test/application/shadow/editor_projected_building_shadow_preview_test.dart:5:8: Error: Error when reading 'lib/src/application/shadow/editor_projected_building_shadow_preview.dart': No such file or directory
import 'package:map_editor/src/application/shadow/editor_projected_building_shadow_preview.dart';
       ^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:12:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:44:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:59:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:77:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:98:9: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
        buildEditorProjectedBuildingShadowPreviewInstructions(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:110:9: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
        buildEditorProjectedBuildingShadowPreviewInstructions(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:125:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:140:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/editor_projected_building_shadow_preview_test.dart:160:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart: test/application/shadow/editor_projected_building_shadow_preview_test.dart:5:8: Error: Error when reading 'lib/src/application/shadow/editor_projected_building_shadow_preview.dart': No such file or directory
  import 'package:map_editor/src/application/shadow/editor_projected_building_shadow_preview.dart';
         ^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:12:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:44:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:59:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:77:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:98:9: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:110:9: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
          buildEditorProjectedBuildingShadowPreviewInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:125:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:140:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/application/shadow/editor_projected_building_shadow_preview_test.dart:160:11: Error: Method not found: 'buildEditorProjectedBuildingShadowPreviewInstructions'.
            buildEditorProjectedBuildingShadowPreviewInstructions(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.
```

Note : un run intermédiaire lancé en parallèle avec une autre commande Flutter a échoué sur le lock de démarrage Flutter. La cause était la commande parallèle, pas le code ; toutes les vérifications finales ont été relancées séquentiellement.

## 15. Résultats des tests

### Test ciblé builder

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
00:00 +0: buildEditorProjectedBuildingShadowPreviewInstructions builds a projected polygon preview
00:00 +1: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when element has no projectedBuildingShadow config
00:00 +2: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when projectedBuildingShadow is disabled
00:00 +3: buildEditorProjectedBuildingShadowPreviewInstructions skips missing projected building shadow preset without throwing
00:00 +4: buildEditorProjectedBuildingShadowPreviewInstructions skips hidden or transparent tile layers
00:00 +5: buildEditorProjectedBuildingShadowPreviewInstructions skips zero opacity placements
00:00 +6: buildEditorProjectedBuildingShadowPreviewInstructions skips invalid visual source dimensions
00:00 +7: buildEditorProjectedBuildingShadowPreviewInstructions preserves placed element source order
00:00 +8: buildEditorProjectedBuildingShadowPreviewInstructions does not depend on runtime or auto projection
00:00 +9: All tests passed!
```

### Test canvas ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +0: MapGridPainter foreground split helpers marks only non-collision cells of multi-tile placed elements as foreground
00:00 +1: MapGridPainter foreground split helpers routes split cells to the correct render pass deterministically
00:00 +2: MapGridPainter foreground split helpers routes project-element entities to the requested render pass
00:00 +3: MapGridPainter foreground split helpers paints SurfaceLayer static preview without atlas tile images
00:00 +4: MapGridPainter foreground split helpers paints SurfaceLayer with resolved atlas tile image when available
00:00 +5: MapGridPainter foreground split helpers paints placed elements even when their TileLayer has no tiles
00:00 +6: MapGridPainter foreground split helpers paints static shadow preview below placed elements
00:00 +7: MapGridPainter foreground split helpers paints projected building shadow preview below placed elements
00:00 +8: MapGridPainter foreground split helpers paints projected building shadow preview before static shadow preview
00:00 +9: MapGridPainter foreground split helpers does not double-paint matching baked tiles under translucent elements
00:00 +10: MapGridPainter foreground split helpers keeps non-matching base tiles visible under translucent elements
00:00 +11: MapGridPainter foreground split helpers delete preview highlights sprite without footprint rectangle
00:00 +12: MapGridPainter foreground split helpers paints SurfaceLayer atlas tile from current editor elapsed time
00:00 +13: MapGridPainter foreground split helpers paints path layer with center-only 2x2 PathPattern in canvas
00:00 +14: All tests passed!
```

### Régression shadow editor ciblée

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart test/application/shadow/editor_shadow_render_order_contract_test.dart
```

Ligne finale exacte :

```text
00:00 +31: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_projected_building_shadow_preview.dart lib/src/ui/canvas/map_canvas.dart test/application/shadow/editor_projected_building_shadow_preview_test.dart test/map_grid_painter_test.dart
```

Sortie complète :

```text
Analyzing 4 items...                                            

No issues found! (ran in 1.8s)
```

## 17. Audit anti-dérive

Commande :

```bash
rg -n "map_runtime|ShadowRuntime|buildRuntimeProjectedBuildingShadowCollection|ShadowRuntimeRenderer|ShadowRuntimeInstructionCollection|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy|matchesGoldenFile|SHADOW_SCREENSHOT|selbrume|reports/shadows/baselines" packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart packages/map_editor/test/map_grid_painter_test.dart
```

Sortie :

```text

```

Interprétation : aucun hit. Le code du lot n’importe pas `map_runtime`, ne mentionne pas `genericProjection`, ne lance pas de diagnostics et ne crée pas de chemin screenshot/baseline/Selbrume.

## 18. Ce qui n’a volontairement pas été modifié

Non modifié :

- `packages/map_runtime/**`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/**`
- `packages/map_editor/pubspec.yaml`
- modèles persistants editor/core ;
- codecs ;
- diagnostics ;
- generated files ;
- fixtures.

## 19. Ce qui n’a volontairement pas été créé

Non créés :

- UI authoring ;
- widget de réglage ;
- provider public ;
- renderer runtime ;
- screenshot ;
- baseline ;
- fixture Selbrume ;
- preset par défaut ;
- diagnostic ;
- generated file.

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   1 +
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  13 ++
 .../map_editor/test/map_grid_painter_test.dart     | 202 +++++++++++++++++++++
 3 files changed, 216 insertions(+)
```

Note : les fichiers nouveaux non suivis ne figurent pas dans `git diff --stat`.

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_editor/lib/src/ui/canvas/map_canvas.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M	packages/map_editor/test/map_grid_painter_test.dart
```

Note : les fichiers nouveaux non suivis ne figurent pas dans `git diff --name-status`.

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Interprétation : aucune erreur whitespace détectée.

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie avant création du rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
?? packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Le status final après création du présent rapport est renseigné à la fin de ce fichier après vérification finale.

## 24. Risques / réserves

Le builder editor V2 duplique une partie du traversal runtime V2. C’est volontaire en V0 pour éviter de coupler `map_editor` à `map_runtime`. Si la duplication devient une dette après la preview editor, un lot design séparé pourra étudier un helper pur dans `map_core`.

La primitive réutilisée s’appelle `EditorStaticShadowPreviewInstruction`, nom hérité de la preview V1. Elle supporte déjà `projectedPolygon`, et la réutiliser évite un nouveau painter. Un renommage plus générique serait un refactor séparé.

Le test d’ordre V2 avant V1 est source-level plutôt que pixel-level, parce qu’un test de blending exact serait plus fragile que le contrat réel à vérifier : l’appel paint V2 précède l’appel paint V1.

## 25. Auto-critique

Le lot respecte-t-il strictement ShadowV2-27 ?

Oui. L’implémentation suit l’Option B : `map_editor` utilise `map_core` et un builder editor local.

`map_editor` dépend-il toujours uniquement de `map_core` pour ShadowV2 ?

Oui. Aucun import `map_runtime` n’a été ajouté. L’audit anti-dérive final est silencieux.

Le builder editor duplique-t-il seulement le strict nécessaire ?

Oui. Il duplique uniquement le traversal nécessaire à la preview : index éléments/layers, skips locaux, metrics, resolver V2, conversion vers primitive editor.

Les règles de skip sont-elles alignées avec le runtime ?

Oui pour V0 : layer invisible/transparent, placement opacity zéro, élément absent, config absente/disabled, preset absent, source invalide, geometry null.

Le test canvas prouve-t-il réellement la preview editor ?

Oui. Il passe par `MapGridPainter`, rend une image mémoire, vérifie un pixel de shadow V2 non recouvert, puis vérifie qu’un pixel recouvert par sprite reste le sprite opaque.

Le test confond-il preview V2 et V1 ?

Non. Le fixture du test pixel n’active aucune shadow V1 ; l’ombre visible vient de `projectedBuildingShadow`.

L’ordre V2 avant V1 est-il vérifié ?

Oui par un test source-level ciblé dans `map_grid_painter_test.dart`.

Le lot a-t-il évité UI authoring / screenshot / Selbrume ?

Oui. Aucun de ces fichiers ou chemins n’a été créé ou modifié.

Le rapport contient-il toutes les preuves ?

Oui : RED initial, tests, analyze, audit anti-dérive, diff stat/name/check, status, contenus des fichiers créés et diffs complets des fichiers modifiés.

## 26. Regard critique sur le prompt

Le prompt est bien verrouillé. Il force le point d’intégration, interdit `map_runtime`, impose le RED TDD, et limite clairement les fichiers.

Le seul ajustement utile pour un futur lot similaire serait de préciser si les tests source-level sont acceptés pour l’ordre de paint quand un test pixel de blending serait plus fragile. Ici, le choix source-level reste ciblé et justifié.

## 27. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-29 — Projected Building Shadow Existing V1 Ugly Shadow Source Audit / Suppression Design Gate
```

Objectif probable :

```text
identifier précisément pourquoi les anciennes ombres V1 restent visibles,
puis décider comment les désactiver/nettoyer sans casser les contact shadows utiles.
```

## 28. Code complet des fichiers créés/modifiés

### Fichier créé — `packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart`

```dart
import 'package:map_core/map_core.dart';

import 'editor_static_shadow_preview.dart';

List<EditorStaticShadowPreviewInstruction>
    buildEditorProjectedBuildingShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
}) {
  if (!tileWidth.isFinite ||
      !tileHeight.isFinite ||
      tileWidth <= 0 ||
      tileHeight <= 0 ||
      map.placedElements.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty || visibleTileLayerById.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final instructions = <EditorStaticShadowPreviewInstruction>[];
  for (final placed in map.placedElements) {
    if (placed.opacity <= 0 ||
        !visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }

    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }

    final config = element.projectedBuildingShadow;
    if (config == null || !config.enabled) {
      continue;
    }

    final preset = manifest.projectedBuildingShadowCatalog.presetById(
      config.presetId,
    );
    if (preset == null) {
      continue;
    }

    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: placed.pos.x * tileWidth,
        top: placed.pos.y * tileHeight,
        visualWidth: source.width * tileWidth,
        visualHeight: source.height * tileHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    final points = geometry.points
        .map((point) => EditorStaticShadowPreviewPoint(
              x: point.x,
              y: point.y,
            ))
        .toList(growable: false);
    final bounds = _boundsFromEditorPreviewPoints(points);

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
        opacity: geometry.opacity,
        colorHexRgb: geometry.colorHexRgb,
        polygonPoints: points,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}

_EditorProjectedShadowPreviewBounds _boundsFromEditorPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _EditorProjectedShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _EditorProjectedShadowPreviewBounds {
  const _EditorProjectedShadowPreviewBounds({
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

### Fichier créé — `packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_projected_building_shadow_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorProjectedBuildingShadowPreviewInstructions', () {
    test('builds a projected polygon preview', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '123ABC');
      expect(instruction.left, 64);
      expect(instruction.top, 128);
      expect(instruction.width, 48);
      expect(instruction.height, 64);
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
    });

    test('returns empty when element has no projectedBuildingShadow config',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element()],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('returns empty when projectedBuildingShadow is disabled', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips missing projected building shadow preset without throwing', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          elements: [
            _element(projectedBuildingShadow: _config(presetId: 'missing')),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips hidden or transparent tile layers', () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
    });

    test('skips zero opacity placements', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed(opacity: 0)]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips invalid visual source dimensions', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(),
              sourceWidth: 0,
            ),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('preserves placed element source order', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(
          placedElements: [
            _placed(id: 'first', pos: const GridPos(x: 1, y: 2)),
            _placed(id: 'second', pos: const GridPos(x: 3, y: 2)),
          ],
        ),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(
        instructions.map((instruction) => instruction.instanceId),
        ['first', 'second'],
      );
    });

    test('does not depend on runtime or auto projection', () {
      final source = File(
        'lib/src/application/shadow/editor_projected_building_shadow_preview.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'map_' 'runtime',
        'Shadow' 'Runtime',
        'buildRuntimeProjected' 'BuildingShadowCollection',
        'Shadow' 'Runtime' 'Renderer',
        'generic' 'Projection',
        'applyElementAutoShadowPolicy' 'ToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'resolveProjectedStatic' 'ShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'static_shadow_family' '_projection',
        'element_auto_shadow' '_policy',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 10, height: 10),
    layers: layers ?? [_layer()],
    placedElements: placedElements,
  );
}

MapLayer _layer({
  String id = 'objects',
  bool isVisible = true,
  double opacity = 1,
}) {
  return MapLayer.tile(
    id: id,
    name: 'Objects',
    tilesetId: 'tileset',
    isVisible: isVisible,
    opacity: opacity,
  );
}

MapPlacedElement _placed({
  String id = 'building-placed',
  String layerId = 'objects',
  String elementId = 'building',
  GridPos pos = const GridPos(x: 1, y: 2),
  double opacity = 1,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    opacity: opacity,
  );
}

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  int sourceWidth = 2,
  int sourceHeight = 3,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'Building',
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(
          x: 0,
          y: 0,
          width: sourceWidth,
          height: sourceHeight,
        ),
      ),
    ],
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

ProjectBuildingShadowPresetCatalog _catalog(
  List<ProjectBuildingShadowPreset> presets,
) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  String id = 'shadow-a',
  double opacity = 0.18,
  String colorHexRgb = '123ABC',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'shadow-a',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  EditorStaticShadowPreviewPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.000001));
  expect(point.y, closeTo(y, 0.000001));
}
```

### Diff complet — `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index c38ca4dc..354651b0 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -12,6 +12,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../application/models/map_tool_preview.dart';
 import '../../application/models/path_autotile_set.dart';
+import '../../application/shadow/editor_projected_building_shadow_preview.dart';
 import '../../application/shadow/editor_shadow_light_preview.dart';
 import '../../application/shadow/editor_static_shadow_preview.dart';
 import '../../application/services/environment_generated_placement_hover_resolver.dart';
```

### Diff complet — `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index a202295d..f81fcc3b 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -270,6 +270,14 @@ class MapGridPainter extends CustomPainter {
       project: project,
     );
     final projectContext = project;
+    final projectedBuildingShadowPreviewInstructions = projectContext == null
+        ? const <EditorStaticShadowPreviewInstruction>[]
+        : buildEditorProjectedBuildingShadowPreviewInstructions(
+            manifest: projectContext,
+            map: map,
+            tileWidth: tileWidth,
+            tileHeight: tileHeight,
+          );
     final staticShadowPreviewInstructions = projectContext == null
         ? const <EditorStaticShadowPreviewInstruction>[]
         : buildEditorStaticShadowPreviewInstructions(
@@ -324,6 +332,11 @@ class MapGridPainter extends CustomPainter {
       }
     }
 
+    paintEditorStaticShadowPreviewInstructions(
+      canvas,
+      projectedBuildingShadowPreviewInstructions,
+    );
+
     paintEditorStaticShadowPreviewInstructions(
       canvas,
       staticShadowPreviewInstructions,
```

### Diff complet — `packages/map_editor/test/map_grid_painter_test.dart`

```diff
diff --git a/packages/map_editor/test/map_grid_painter_test.dart b/packages/map_editor/test/map_grid_painter_test.dart
index 3e80ce38..c910716e 100644
--- a/packages/map_editor/test/map_grid_painter_test.dart
+++ b/packages/map_editor/test/map_grid_painter_test.dart
@@ -1,3 +1,4 @@
+import 'dart:io';
 import 'dart:ui' as ui;
 
 import 'package:flutter_test/flutter_test.dart';
@@ -457,6 +458,159 @@ void main() {
       image.dispose();
     });
 
+    test('paints projected building shadow preview below placed elements',
+        () async {
+      const map = MapData(
+        id: 'market',
+        name: 'Market',
+        size: GridSize(width: 5, height: 7),
+        layers: <MapLayer>[
+          TileLayer(
+            id: 'environment',
+            name: 'Environment',
+            tilesetId: 'element-tileset',
+            tiles: <int>[
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+              0,
+            ],
+          ),
+        ],
+        placedElements: <MapPlacedElement>[
+          MapPlacedElement(
+            id: 'building_1',
+            layerId: 'environment',
+            elementId: 'building',
+            pos: GridPos(x: 1, y: 2),
+          ),
+        ],
+      );
+      final project = ProjectManifest(
+        name: 'editor',
+        maps: const <ProjectMapEntry>[],
+        tilesets: const <ProjectTilesetEntry>[
+          ProjectTilesetEntry(
+            id: 'element-tileset',
+            name: 'Element Tileset',
+            relativePath: 'tilesets/elements.png',
+          ),
+        ],
+        surfaceCatalog: ProjectSurfaceCatalog(),
+        projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
+          presets: [_projectedBuildingShadowPreset()],
+        ),
+        elements: [
+          ProjectElementEntry(
+            id: 'building',
+            name: 'Building',
+            tilesetId: 'element-tileset',
+            categoryId: 'market',
+            frames: const <TilesetVisualFrame>[
+              TilesetVisualFrame(
+                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
+              ),
+            ],
+            projectedBuildingShadow: _projectedBuildingShadowConfig(),
+          ),
+        ],
+      );
+      final tilesetImage = await _solidColorImage(
+        width: 64,
+        height: 96,
+        color: const ui.Color(0xFFFF0000),
+      );
+      final recorder = ui.PictureRecorder();
+      final canvas = ui.Canvas(recorder);
+
+      MapGridPainter(
+        map: map,
+        zoom: 1,
+        offset: ui.Offset.zero,
+        tileWidth: 32,
+        tileHeight: 32,
+        tilesetImagesById: {'element-tileset': tilesetImage},
+        sourceTileWidth: 32,
+        sourceTileHeight: 32,
+        tilesPerRowById: const <String, int>{'element-tileset': 2},
+        warps: const <MapWarp>[],
+        gameplayZones: const <MapGameplayZone>[],
+        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
+        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
+        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
+        project: project,
+      ).paint(canvas, const ui.Size(160, 224));
+
+      final picture = recorder.endRecording();
+      final image = await picture.toImage(160, 224);
+      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
+      final shadowOnlyOffset = _rgbaOffset(image, x: 104, y: 150);
+      expect(pixels!.getUint8(shadowOnlyOffset + 3), greaterThan(0));
+      final spriteOverShadowOffset = _rgbaOffset(image, x: 80, y: 150);
+      expect(pixels.getUint8(spriteOverShadowOffset), greaterThan(220));
+      expect(pixels.getUint8(spriteOverShadowOffset + 1), lessThan(40));
+      expect(pixels.getUint8(spriteOverShadowOffset + 2), lessThan(40));
+      expect(pixels.getUint8(spriteOverShadowOffset + 3), greaterThan(240));
+      picture.dispose();
+      image.dispose();
+      tilesetImage.dispose();
+    });
+
+    test(
+        'paints projected building shadow preview before static shadow preview',
+        () {
+      final source = File(
+        'lib/src/ui/canvas/map_canvas/map_grid_painter.dart',
+      ).readAsStringSync();
+      final projectedPaintIndex = source.indexOf(
+        'paintEditorStaticShadowPreviewInstructions(\n'
+        '      canvas,\n'
+        '      projectedBuildingShadowPreviewInstructions,\n'
+        '    );',
+      );
+      final staticPaintIndex = source.indexOf(
+        'paintEditorStaticShadowPreviewInstructions(\n'
+        '      canvas,\n'
+        '      staticShadowPreviewInstructions,\n'
+        '    );',
+      );
+
+      expect(projectedPaintIndex, isNonNegative);
+      expect(staticPaintIndex, isNonNegative);
+      expect(projectedPaintIndex, lessThan(staticPaintIndex));
+    });
+
     test(
         'does not double-paint matching baked tiles under translucent elements',
         () async {
@@ -1019,6 +1173,23 @@ Future<ui.Image> _testTilesetImage() async {
   return image;
 }
 
+Future<ui.Image> _solidColorImage({
+  required int width,
+  required int height,
+  required ui.Color color,
+}) async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  canvas.drawRect(
+    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
+    ui.Paint()..color = color,
+  );
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(width, height);
+  picture.dispose();
+  return image;
+}
+
 Future<ui.Image> _testPathPatternTilesetImage() async {
   final recorder = ui.PictureRecorder();
   final canvas = ui.Canvas(recorder);
@@ -1047,3 +1218,34 @@ Future<ui.Image> _testPathPatternTilesetImage() async {
   picture.dispose();
   return image;
 }
+
+ProjectBuildingShadowPreset _projectedBuildingShadowPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'shadow-a',
+    name: 'Shadow A',
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.18,
+      colorHexRgb: '123ABC',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
+ProjectElementProjectedBuildingShadowConfig _projectedBuildingShadowConfig() {
+  return ProjectElementProjectedBuildingShadowConfig(
+    enabled: true,
+    presetId: 'shadow-a',
+    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+    localOffset: ProjectedShadowOffset(x: 0, y: 0),
+  );
+}
+
+int _rgbaOffset(ui.Image image, {required int x, required int y}) {
+  return ((y * image.width) + x) * 4;
+}
```

### Rapport courant

Le présent fichier est :

```text
reports/shadows/v2/shadow_v2_28_projected_building_shadow_editor_preview_poc.md
```

Il est le rapport créé par ce lot.

## 29. Vérification finale post-rapport

Commandes :

```bash
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

`git diff --stat` :

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   1 +
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  13 ++
 .../map_editor/test/map_grid_painter_test.dart     | 202 +++++++++++++++++++++
 3 files changed, 216 insertions(+)
```

`git diff --name-status` :

```text
M	packages/map_editor/lib/src/ui/canvas/map_canvas.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M	packages/map_editor/test/map_grid_painter_test.dart
```

`git diff --check` :

```text

```

`git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
?? packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
?? reports/shadows/v2/shadow_v2_28_projected_building_shadow_editor_preview_poc.md
```

Interprétation : le status final est conforme au périmètre autorisé.

Checklist finale :

- [x] Builder editor V2 créé
- [x] Preview V2 intégrée dans MapGridPainter
- [x] V2 peinte avant V1
- [x] V2 peinte sous les éléments placés
- [x] Aucun import map_runtime dans map_editor
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun modèle persistant modifié
- [x] Aucun codec modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Selbrume non modifié
- [x] Config absente testée
- [x] Config disabled testée
- [x] Preset manquant testé
- [x] Layer invisible / transparent testé
- [x] Placement opacity <= 0 testé
- [x] Source invalide testée
- [x] Ordre source testé
- [x] Anti-dérive runtime/genericProjection vérifié
- [x] Tests ciblés passés
- [x] Régressions ciblées passées
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
