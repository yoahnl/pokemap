# ShadowV2-27 — Projected Building Shadow Editor Preview Design Gate

## 1. Résumé exécutif

ShadowV2-27 est un lot design-only. Aucun fichier de production, aucun test, aucune fixture, aucun screenshot et aucune baseline ne doivent être créés ou modifiés.

Décision principale : le Lot 28 doit intégrer la preview ShadowV2 dans le canvas editor existant, côté `map_editor`, en réutilisant les modèles et resolvers purs de `map_core`, sans importer `map_runtime`.

Option recommandée : Option B — créer un builder/adapter editor local qui transforme `ProjectManifest + MapData` en primitives de preview editor déjà peintes par le système existant.

Le code audité montre déjà :

- un canvas central : `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` et son part `map_canvas/map_grid_painter.dart` ;
- une primitive editor locale : `EditorStaticShadowPreviewInstruction` ;
- un shape editor local : `EditorStaticShadowPreviewShapeKind.projectedPolygon` ;
- un painter editor local capable de dessiner un polygone projeté ;
- un slot de rendu existant pour les ombres statiques entre les tiles/surfaces et les éléments placés.

Le Lot 28 doit donc rester petit : construire des instructions editor locales ShadowV2, les peindre dans le slot d’ombres statiques existant, et tester que la preview existe, respecte les skips, reste sous les sprites et ne dépend pas de `map_runtime`.

## 2. Objectif du lot

Concevoir la preview editor minimale des ombres projetées ShadowV2 déjà authorées.

Le lot répond à ces questions :

- où raccorder la preview dans le canvas editor ;
- quelles briques réutiliser ;
- quelles dépendances éviter ;
- comment gérer les configs invalides ;
- quels fichiers et tests cadrer pour ShadowV2-28 ;
- comment empêcher toute réintroduction de `genericProjection` ou d’auto-shadow V1 dans la preview V2.

Ce lot ne code pas cette preview.

## 3. Rappel ShadowV2-22 à ShadowV2-26

ShadowV2-22 a créé le builder runtime :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Ce builder produit des instructions `ShadowRuntimeShapeKind.projectedPolygon` sur `ShadowRenderPass.groundStatic`.

ShadowV2-24 a branché ces instructions au runtime via `PlayableMapGame`, sans modifier `MapLayersComponent` ni `ShadowRuntimeRenderer`.

ShadowV2-26 a prouvé visuellement en mémoire que la collection fournie par `PlayableMapGame` est rendue par `ShadowRuntimeRenderer` et produit des pixels non transparents pour une ombre V2 authorée.

Le prochain axe est editor-only : afficher une preview dans le canvas d’authoring, sans runtime Flame, sans renderer runtime, sans capture disque et sans Selbrume.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Interprétation : le worktree était propre au début du Lot 27.

Fichiers préexistants non liés au lot : Aucun.

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties pertinentes :

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

Décision : ce lot est bien un design gate. La consigne locale impose de présenter et valider un design avant toute action créative, structurelle, architecturale ou product-facing. ShadowV2-27 respecte cette règle : aucune implémentation n’est prévue.

Compétences/processus utilisés :

- `superpowers:using-superpowers` pour appliquer la discipline de workflow ;
- `superpowers:brainstorming` pour cadrer le design avant implémentation ;
- `karpathy-guidelines` pour garder le lot minimal, borné et non spéculatif ;
- `superpowers:verification-before-completion` pour vérifier le résultat avant clôture.

## 6. Fichiers audités

Canvas / painter editor :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`

Preview shadow editor existante :

- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/lib/src/application/shadow/editor_shadow_light_preview.dart`
- `packages/map_editor/lib/src/application/shadow/editor_shadow_render_order_contract.dart`

Tests editor existants :

- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart`
- `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

Briques ShadowV2 / runtime :

- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart`

Package boundary :

- `packages/map_editor/pubspec.yaml`

## 7. Audit du canvas / map editor

Commande obligatoire exécutée :

```bash
rg -n "class .*Canvas|CustomPainter|paint\\(|Canvas|MapEditor|MapCanvas|MapViewport|PlacedElement|placedElements|MapPlacedElement|selection|overlay|preview|ghost" packages/map_editor/lib packages/map_editor/test
```

Résultat : 2389 lignes trouvées. Les résultats utiles convergent vers `MapCanvas` et `MapGridPainter`.

Extraits pertinents :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:...:part 'map_canvas/map_grid_painter.dart';
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:...:import '../../application/shadow/editor_static_shadow_preview.dart';
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:...:import 'shadow/editor_static_shadow_preview_painter.dart';
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:...:class MapGridPainter extends CustomPainter
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:...:void paint(Canvas canvas, Size size)
```

Le canvas principal est `MapCanvas`, avec un painter central `MapGridPainter` dans un part file. Le shell widget gère l’état, les interactions, les ressources images et les options d’aperçu. Le painter central reçoit déjà :

- `map` ;
- `project` ;
- `tileWidth` / `tileHeight` ;
- les images de tileset ;
- les informations d’édition et overlays ;
- `shadowLightPreviewPreset`.

Le rendu existant dans `MapGridPainter.paint` suit cet ordre synthétique :

```text
terrain layers
path layers
tile background
surface layer preview
static shadow preview
placed elements background
collision/grid/hover
entity background
tile foreground + placed elements foreground
entity foreground
selection / tool previews / environment overlays / events / triggers / warps / connections
```

Le point important est déjà présent :

```dart
paintEditorStaticShadowPreviewInstructions(
  canvas,
  staticShadowPreviewInstructions,
);
```

Ce call est positionné après les tiles/surfaces et avant les sprites/éléments placés. C’est le bon slot pour les grandes ombres projetées ShadowV2.

## 8. Audit des éléments placés editor

Commande obligatoire exécutée :

```bash
rg -n "MapPlacedElement|placedElements|ProjectElementEntry|TilesetVisualFrame|TilesetSourceRect|elementId|layerId|opacity|shadow|shadowOverride|projectedBuildingShadow" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
```

Résultat : 5606 lignes trouvées. Les résultats utiles se concentrent dans `MapGridPainter`, `editor_static_shadow_preview.dart`, les tests shadow editor et les modèles `map_core`.

Le painter editor résout déjà les éléments placés avec un index `ProjectElementEntry` :

```dart
final elementById = <String, ProjectElementEntry>{
  for (final entry in projectContext.elements) entry.id: entry,
};
```

Puis il parcourt les placements par layer :

```dart
for (final instance in map.placedElements) {
  if (instance.layerId.trim() != layerId) {
    continue;
  }
  _paintPlacedElement(...);
}
```

Le calcul visuel pour un élément placé existe déjà :

- `placed.pos.x * tileWidth`
- `placed.pos.y * tileHeight`
- `frame.source.width * tileWidth`
- `frame.source.height * tileHeight`

L’opacité de placement existe et est appliquée au sprite placé :

```dart
final resolvedOpacity = (opacity * instance.opacity).clamp(0.0, 1.0).toDouble();
```

Le builder preview V1 existant filtre déjà les layers TileLayer invisibles ou transparents :

```dart
final visibleTileLayerById = <String, TileLayer>{
  for (final layer in map.layers.whereType<TileLayer>())
    if (layer.isVisible && layer.opacity > 0) layer.id: layer,
};
```

Pour ShadowV2 editor preview, le Lot 28 doit reprendre ces conventions :

- layer absent/invisible/transparent : skip ;
- placement `opacity <= 0` : skip ;
- élément absent : skip ;
- frame absente ou source invalide : skip ;
- config ShadowV2 absente/disabled : skip ;
- preset absent : skip.

## 9. Audit des previews / overlays existants

Commande obligatoire exécutée :

```bash
rg -n "preview|Preview|ghost|Ghost|overlay|Overlay|selection|Selection|highlight|debug|paint.*Overlay|brush|indicator" packages/map_editor/lib packages/map_editor/test
```

Résultat : 3133 lignes trouvées.

Le code editor possède déjà plusieurs familles d’overlays et previews :

- `editor_static_shadow_preview.dart` pour les shadows editor V1 ;
- `editor_static_shadow_preview_painter.dart` pour peindre ces instructions ;
- previews Surface / Environment dans le canvas ;
- overlays de sélection, hover, zones, warps, triggers, environment brush ;
- tests pixel-level de painter dans `map_grid_painter_test.dart`.

La preview shadow V1 est le pattern le plus proche. Elle n’est pas un widget séparé : elle est construite en application layer editor, puis peinte dans `MapGridPainter`.

Tests existants utiles :

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

`map_grid_painter_test.dart` contient déjà un test nommé :

```text
paints static shadow preview below placed elements
```

Ce test prouve que le harness canvas/pixel est déjà disponible côté editor. Le Lot 28 peut l’étendre ou créer un test voisin pour la preview V2 sans introduire screenshot disque ni baseline.

## 10. Audit des briques ShadowV2 réutilisables

Commande obligatoire exécutée :

```bash
rg -n "ProjectedBuildingShadow|ProjectedShadow|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics|ShadowRuntimeRenderInstruction|ShadowRuntimeRenderer|buildRuntimeProjectedBuildingShadowCollection" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test
```

Résultat : 820 lignes trouvées.

Briques pures réutilisables dans `map_core` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_geometry.dart
packages/map_core/lib/map_core.dart
```

`map_core/lib/map_core.dart` exporte déjà :

```text
31:export 'src/models/projected_building_shadow.dart';
77:export 'src/operations/projected_building_shadow_geometry.dart';
```

La géométrie pure V2 est directement adaptée au besoin editor :

```dart
ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
})
```

Elle ne dépend pas de Flutter, Flame ou du runtime. Elle produit exactement les quatre points authorés/résolus que l’éditeur doit prévisualiser.

Briques runtime à ne pas importer côté editor :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

`packages/map_editor/pubspec.yaml` dépend de `map_core`, mais ne dépend pas de `map_runtime` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  ...
  map_core:
    path: ../map_core
```

Décision : ne pas ajouter une dépendance `map_editor -> map_runtime` pour une preview editor. Cela mélangerait authoring UI et runtime Flame.

## 11. Audit anti-dérive genericProjection / diagnostics

Commande obligatoire exécutée :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_editor/lib packages/map_runtime/lib packages/map_core/lib
```

Résultat : 139 lignes trouvées.

Hits pertinents attendus :

- `ProjectValidator` et `MapValidator` existent dans `map_core` et dans le chargement runtime ;
- `diagnoseProjectedBuildingShadows` existe dans `map_core` comme opération diagnostics authoring ;
- `genericProjection` existe dans les modèles/operations V1 ;
- `resolveProjectedStaticShadowGeometry` et `resolveStaticShadowFamilyProjectionSpec` existent dans la preview/editor V1 et le runtime V1 ;
- `element_auto_shadow_policy` existe comme opération V1/maintenance.

Interprétation : ces hits sont des surfaces existantes V1, diagnostics ou validation. Ils ne doivent pas être utilisés pour la preview ShadowV2 du Lot 28.

Règle Lot 28 :

- ne pas appeler `genericProjection` ;
- ne pas appeler `applyElementAutoShadowPolicyToProject` ;
- ne pas appeler `resolveProjectedStaticShadowGeometry` pour V2 ;
- ne pas appeler `resolveStaticShadowFamilyProjectionSpec` pour V2 ;
- ne pas appeler `diagnoseProjectedBuildingShadows` comme condition de preview ;
- ne pas créer de fallback artistique.

## 12. Options étudiées

### Option A — Réutiliser le builder runtime V2 dans map_editor

Principe :

```text
map_editor importe buildRuntimeProjectedBuildingShadowCollection(...)
puis dessine les ShadowRuntimeRenderInstruction
```

Avantages :

- semble éviter une duplication de traversal ;
- réutilise le travail runtime validé jusqu’au rendu.

Risques :

- ajoute une dépendance `map_editor -> map_runtime` absente aujourd’hui ;
- introduit des types runtime dans l’éditeur ;
- rapproche l’authoring UI du pipeline Flame ;
- rend la preview editor dépendante de décisions runtime ;
- complexifie les tests et les frontières de package.

Décision : rejetée pour V0.

### Option B — Réutiliser uniquement map_core et créer un adapter editor

Principe :

```text
map_editor lit ProjectManifest + MapData
-> traverse les placements visibles
-> utilise resolveProjectedBuildingShadowGeometry(...)
-> convertit en primitives editor locales
-> peint via le painter editor existant
```

Avantages :

- respecte la frontière actuelle `map_editor -> map_core` ;
- réutilise la géométrie pure ShadowV2 ;
- évite Flame et le runtime ;
- s’aligne avec la preview V1 editor existante ;
- peut réutiliser `EditorStaticShadowPreviewInstruction` et le painter `projectedPolygon` existant ;
- facile à tester par builder pur et test pixel-level du painter/canvas.

Risques :

- duplication partielle du traversal runtime V2 ;
- besoin de garder les règles de skip alignées avec le runtime ;
- le nom `EditorStaticShadowPreviewInstruction` est historiquement V1/static, même s’il supporte déjà les projected polygons.

Décision : recommandée.

### Option C — Créer un helper commun dans map_core pour construire les géométries V2 par map

Principe :

```text
map_core expose ProjectManifest + MapData -> List<ProjectedBuildingShadowGeometry>
runtime et editor peuvent l’utiliser
```

Avantages :

- réduit la duplication runtime/editor ;
- garde le traversal pur ;
- pourrait devenir la bonne abstraction si plusieurs clients consomment la même liste de géométries.

Risques :

- modifie `map_core` dans un lot censé seulement prouver une preview editor ;
- élargit le contrat partagé avant d’avoir validé les besoins editor ;
- pourrait forcer une API prématurée autour des metadata editor/runtime.

Décision : différée. À envisager après le POC editor si la duplication devient réelle et douloureuse.

### Option D — Ne prévisualiser que dans un panneau inspector

Principe :

```text
pas de preview canvas ;
afficher seulement les données du preset/config dans un inspector
```

Avantages :

- très peu risqué visuellement ;
- utile plus tard pour l’authoring des presets/configs.

Risques :

- ne répond pas au besoin artistique principal ;
- ne prouve pas la projection sur la map ;
- ne montre pas l’ordre sous sprites / au-dessus des tiles.

Décision : rejetée pour le POC preview. Un inspector pourra venir dans un lot authoring séparé.

### Option E — Preview screenshot/runtime embarqué dans editor

Principe :

```text
l’éditeur embarque une preview runtime Flame pour voir les ombres
```

Avantages :

- fidélité runtime potentielle.

Risques :

- trop lourd pour V0 ;
- introduit `map_runtime`/Flame dans le chemin editor ;
- complique le lifecycle, les assets et les tests ;
- mélange preview authoring et runtime ;
- contredit le choix déjà prouvé par ShadowV2-26 : le renderer runtime est validé séparément.

Décision : rejetée.

## 13. Option recommandée

Option recommandée : Option B — builder/adapter editor local basé sur `map_core`.

Lot 28 doit créer un builder editor local :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
```

Nom recommandé :

```dart
List<EditorStaticShadowPreviewInstruction>
    buildEditorProjectedBuildingShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
})
```

Responsabilité :

```text
ProjectManifest + MapData + dimensions editor
-> géométries V2 via map_core
-> EditorStaticShadowPreviewInstruction projetées
```

Pourquoi :

- `map_core` contient déjà les modèles et le resolver pur V2 ;
- `map_editor` dépend déjà de `map_core` ;
- `map_editor` ne dépend pas de `map_runtime` ;
- le painter editor sait déjà peindre un `projectedPolygon` ;
- `MapGridPainter` possède déjà le slot visuel correct ;
- la preview doit rester authoring-facing, pas runtime-facing.

Lot 28 doit faire :

- créer le builder editor V2 ;
- convertir `ProjectedBuildingShadowGeometry.points` en `EditorStaticShadowPreviewPoint` ;
- calculer les bounds pour remplir `left/top/width/height` de la primitive editor ;
- intégrer le builder dans `MapGridPainter` ;
- peindre les previews V2 dans le slot d’ombres statiques existant ;
- peindre V2 avant la preview V1 dans ce slot, pour rester aligné avec le runtime V2 -> V1 ;
- tester builder, skips, ordre et absence de dépendance runtime.

Lot 28 ne doit pas faire :

- importer `map_runtime` dans `map_editor` ;
- modifier `map_core` ;
- modifier le runtime ;
- modifier les modèles/JSON/codecs/diagnostics ;
- créer une UI de réglage ;
- créer screenshot, baseline ou fixture Selbrume ;
- traiter `followsSun` réel ou cycle jour/nuit.

## 14. Ordre de rendu editor recommandé

Ordre recommandé pour le canvas editor :

```text
terrain layers
path layers
tile background
surface layer preview
ShadowV2 projected building preview
Shadow V1 static preview existante
placed elements background
collision/grid/hover
entity background
tile foreground + placed elements foreground
entity foreground
selection / tool previews / environment overlays / events / triggers / warps / connections
Flutter UI
```

Le slot à utiliser existe déjà : `EditorShadowRenderOrderSlot.futureStaticElementShadows`.

`editor_shadow_render_order_contract.dart` confirme :

```text
baseTerrain
groundPaths
surfacePreview
futureStaticElementShadows
futureDynamicActorShadows
placedElementsBackground
actorsOrEntitiesBackground
placedElementsForeground
actorsOrEntitiesForeground
foregroundOcclusion
debugAndSelectionOverlays
flutterUi
```

Lot 28 ne doit pas créer un nouveau système d’ordre. Il doit insérer V2 dans le slot existant, avant les éléments placés et sous les overlays de sélection/debug.

Ordre relatif recommandé dans le slot :

```text
1. ShadowV2 projected building preview
2. Shadow V1 static preview existante
```

Raison : cet ordre reproduit la décision runtime validée au Lot 24, où V2 est mergée avant V1.

## 15. Comportement config invalide recommandé

Le builder editor V2 du Lot 28 doit être tolérant et silencieux.

Règles recommandées :

```text
project null -> aucune preview
tileWidth/tileHeight invalides -> aucune preview
map.placedElements vide -> aucune preview
layer absent -> skip
layer non TileLayer -> skip
layer invisible -> skip
layer opacity <= 0 -> skip
placed opacity <= 0 -> skip
elementId absent du manifest -> skip
element.frames vide -> skip
frame source width/height <= 0 -> skip
element.projectedBuildingShadow null -> skip
element.projectedBuildingShadow.enabled == false -> skip
presetId absent du projectedBuildingShadowCatalog -> skip
resolveProjectedBuildingShadowGeometry(...) retourne null -> skip
```

Le builder editor V2 ne doit jamais :

- throw pour un preset manquant ;
- appeler les diagnostics comme garde runtime/editor ;
- fallback vers V1 ;
- appliquer `genericProjection` ;
- inférer une ombre depuis les dimensions d’asset ;
- muter le manifest ou la map.

Opacité recommandée :

- `instruction.opacity = geometry.opacity`, donc valeur preset V2 ;
- `placed.opacity` sert uniquement de skip si `<= 0`, comme au runtime V0 ;
- ne pas multiplier l’opacité V2 par l’opacité du placement en V0.

## 16. Plan précis du Lot 28

### ShadowV2-28 — Projected Building Shadow Editor Preview POC V0

Objectif :

```text
Afficher dans le canvas editor une preview minimale des ombres projetées V2 déjà authorées,
dans le slot d’ombres statiques existant,
sans dépendance map_runtime,
sans UI authoring,
sans screenshot,
sans Selbrume.
```

Fichiers à créer :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers à modifier :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Modification attendue dans `map_canvas.dart` :

```text
ajouter l’import du builder editor V2, car map_grid_painter.dart est un part file.
```

Modification attendue dans `map_grid_painter.dart` :

```text
construire projectedBuildingShadowPreviewInstructions à côté de staticShadowPreviewInstructions ;
peindre V2 avant V1 dans le slot existant.
```

Pseudo-code attendu :

```dart
final projectedBuildingShadowPreviewInstructions = projectContext == null
    ? const <EditorStaticShadowPreviewInstruction>[]
    : buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: projectContext,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );

paintEditorStaticShadowPreviewInstructions(
  canvas,
  projectedBuildingShadowPreviewInstructions,
);
paintEditorStaticShadowPreviewInstructions(
  canvas,
  staticShadowPreviewInstructions,
);
```

Fichiers interdits :

```text
packages/map_runtime/**
packages/map_core/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/models/**
packages/map_editor/lib/src/operations/** si cela crée un contrat partagé prématuré
packages/map_editor/test/fixtures/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Tests à ajouter/modifier :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Assertions obligatoires :

```text
builder produit 1 preview V2 pour config authorée valide
shape == EditorStaticShadowPreviewShapeKind.projectedPolygon
points V2 attendus préservés dans l’ordre
opacity == preset.appearance.opacity
colorHexRgb == preset.appearance.colorHexRgb normalisé
aucune preview si config absente
aucune preview si config disabled
aucune preview si preset manquant
aucune preview si layer invisible ou opacity <= 0
aucune preview si placed opacity <= 0
aucune preview si source frame invalide
MapGridPainter peint la preview V2 sous les éléments placés
ordre V2 avant V1 dans le slot statique si les deux existent
aucune dépendance map_runtime dans le nouveau builder
aucun genericProjection / auto-policy / diagnostics runtime dans le nouveau builder
```

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "map_runtime|ShadowRuntime|buildRuntimeProjectedBuildingShadowCollection|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec" packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart packages/map_editor/test/map_grid_painter_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart test/map_grid_painter_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_projected_building_shadow_preview.dart lib/src/ui/canvas/map_canvas.dart test/application/shadow/editor_projected_building_shadow_preview_test.dart test/map_grid_painter_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

```text
preview editor V2 visible via MapGridPainter
aucune dépendance map_runtime ajoutée à map_editor
aucun fichier map_core modifié
aucun fichier runtime modifié
aucune UI authoring créée
aucun screenshot/baseline/Selbrume
tests ciblés passent
analyze ciblé passe
git diff --check propre
```

## 17. Tests recommandés pour le Lot 28

### 17.1 Builder produit une preview V2 valide

Nom recommandé :

```text
buildEditorProjectedBuildingShadowPreviewInstructions builds a projected polygon preview
```

Entrée :

```text
ProjectManifest avec preset V2
ProjectElementEntry avec projectedBuildingShadow enabled
MapData avec TileLayer visible et placement
tileWidth/tileHeight connus
```

Assertions :

```text
1 instruction
shape projectedPolygon
points attendus via resolveProjectedBuildingShadowGeometry
opacity du preset V2
colorHexRgb du preset V2
```

### 17.2 Config absente / disabled / preset manquant

Tests recommandés :

```text
ignores elements without projected building shadow config
ignores disabled projected building shadow config
skips missing projected building shadow preset without throwing
```

### 17.3 Visibility / opacity / source invalides

Tests recommandés :

```text
ignores invisible or transparent tile layers
ignores placements with zero opacity
ignores invalid visual sources
```

### 17.4 Ordre et peinture canvas

Test recommandé dans `map_grid_painter_test.dart` :

```text
paints projected building shadow preview below placed elements
```

Ce test peut reprendre le pattern pixel-level existant du test V1 static shadow preview. Il doit vérifier qu’un pixel d’ombre est visible dans une zone non recouverte, et qu’un pixel recouvert par sprite garde le sprite au-dessus si le fixture le permet.

Test recommandé pour ordre V2/V1 :

```text
paints projected building shadow preview before static shadow preview
```

Si le résultat pixel est fragile à cause du blending, tester l’ordre via une petite abstraction de construction d’instructions ou par couleurs/alpha clairement séparés.

### 17.5 Anti-dépendance runtime et anti-dérive

Test ou audit obligatoire :

```text
editor projected building preview does not depend on map_runtime or auto projection
```

Termes interdits :

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

## 18. Fichiers explicitement interdits au Lot 28

Le Lot 28 ne doit pas modifier :

```text
packages/map_runtime/**
packages/map_core/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/features/**
packages/map_editor/lib/src/application/validation/**
packages/map_editor/lib/src/data/**
packages/map_editor/test/fixtures/**
```

Le Lot 28 ne doit pas créer :

```text
nouveau modèle persistant
nouveau codec
nouveau generated file
nouveau renderer
nouveau provider public
nouveau widget réglage/preset
nouveau screenshot
nouvelle baseline
fixture Selbrume
```

Le Lot 28 ne doit pas toucher :

```text
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 19. Risques / réserves

Risque principal : duplication partielle du traversal runtime V2. Pour le POC editor, cette duplication est acceptable car elle reste locale, testée et évite une dépendance runtime. Si un troisième consommateur apparaît ou si les règles divergent, un lot ultérieur pourra concevoir un helper pur commun dans `map_core`.

Deuxième réserve : `EditorStaticShadowPreviewInstruction` est nommé "StaticShadow" et vient du système V1, mais il représente déjà une primitive editor locale capable de porter un `projectedPolygon`. Le réutiliser en V0 évite un nouveau painter. Un renommage ou une primitive plus générale serait un refactor séparé, pas nécessaire pour le Lot 28.

Troisième réserve : la preview editor V2 n’intègre pas encore d’UI d’authoring, de warnings inline, ni de cycle jour/nuit réel. Ce sont des lots séparés.

## 20. Auto-critique

Le lot est-il bien design-only ?

Oui. Le présent lot ne crée que ce rapport. Aucune implémentation n’est ajoutée.

Le rapport recommande-t-il un vrai point d’intégration editor ?

Oui. Point d’intégration recommandé : `MapGridPainter`, dans le slot existant où `paintEditorStaticShadowPreviewInstructions(...)` est déjà appelé.

Le plan Lot 28 évite-t-il map_runtime si ce n’est pas nécessaire ?

Oui. La recommandation refuse `map_editor -> map_runtime` et utilise `map_core`.

Le plan Lot 28 évite-t-il genericProjection et auto-policy ?

Oui. La preview V2 doit appeler `resolveProjectedBuildingShadowGeometry(...)`, pas les projections V1 ni l’auto-policy.

Le plan Lot 28 reste-t-il une preview minimale, pas un workflow authoring ?

Oui. Aucun inspector, UI de preset, migration, diagnostic UI ou screenshot n’est inclus.

Les fichiers interdits sont-ils suffisamment explicites ?

Oui. Les packages runtime/core/gameplay/battle/examples, Selbrume, baselines/screenshots et surfaces de persistance sont listés comme interdits.

Le rapport contient-il toutes les preuves ?

Oui pour un design gate : commandes d’audit, synthèses précises, extraits utiles, décisions, plan Lot 28, risques, diff/status final.

## 21. Regard critique sur le prompt

Le prompt est bien borné : il empêche l’implémentation, interdit les modifications de packages, exige l’audit du canvas editor et demande une recommandation unique.

Le point le plus utile du prompt est l’interdiction explicite d’importer implicitement le runtime par facilité. L’audit confirme que cette tentation serait mauvaise pour ce dépôt : `map_editor` est actuellement aligné sur `map_core`, pas sur `map_runtime`.

Le seul point à préciser dans le futur prompt Lot 28 : autoriser explicitement la réutilisation de `EditorStaticShadowPreviewInstruction` malgré son nom historique, ou imposer un nom de primitive V2 si l’équipe préfère une séparation sémantique plus stricte. La recommandation de ce rapport est de réutiliser la primitive existante pour garder le POC petit.

## 22. Commandes lancées

Commandes obligatoires exécutées :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "class .*Canvas|CustomPainter|paint\\(|Canvas|MapEditor|MapCanvas|MapViewport|PlacedElement|placedElements|MapPlacedElement|selection|overlay|preview|ghost" packages/map_editor/lib packages/map_editor/test
rg -n "MapPlacedElement|placedElements|ProjectElementEntry|TilesetVisualFrame|TilesetSourceRect|elementId|layerId|opacity|shadow|shadowOverride|projectedBuildingShadow" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
rg -n "preview|Preview|ghost|Ghost|overlay|Overlay|selection|Selection|highlight|debug|paint.*Overlay|brush|indicator" packages/map_editor/lib packages/map_editor/test
rg -n "ProjectedBuildingShadow|ProjectedShadow|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics|ShadowRuntimeRenderInstruction|ShadowRuntimeRenderer|buildRuntimeProjectedBuildingShadowCollection" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_editor/lib packages/map_runtime/lib packages/map_core/lib
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes ciblées complémentaires exécutées pour confirmer les points d’intégration :

```bash
sed -n '1,180p' packages/map_editor/lib/src/ui/canvas/map_canvas.dart
sed -n '240,380p' packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
sed -n '1,260p' packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
sed -n '1,180p' packages/map_editor/lib/src/application/shadow/editor_shadow_render_order_contract.dart
rg -n "paintEditorStaticShadowPreviewInstructions|editorShadowRenderOrder|futureStaticElementShadows|below placed|placed elements|shadow preview|projectedPolygon" packages/map_editor/test packages/map_editor/lib/src/ui/canvas packages/map_editor/lib/src/application/shadow
rg -n "map_runtime|runtime_projected|ShadowRuntime|buildRuntimeProjectedBuildingShadowCollection" packages/map_editor/pubspec.yaml packages/map_editor/lib packages/map_editor/test
sed -n '1,260p' packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
sed -n '1,220p' packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart
sed -n '320,540p' packages/map_editor/test/map_grid_painter_test.dart
sed -n '1,220p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
rg -n "projected_building_shadow_geometry|projected_building_shadow|StaticShadowVisualMetrics" packages/map_core/lib/map_core.dart packages/map_core/lib/src/operations/static_shadow_geometry.dart packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
sed -n '1,160p' packages/map_editor/pubspec.yaml
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Interprétation : aucune modification suivie par Git. Le rapport Lot 27 est un fichier nouveau non suivi, donc absent de `git diff --stat`.

## 24. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text

```

Interprétation : aucun fichier suivi modifié, ajouté ou supprimé.

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Interprétation : aucune erreur whitespace détectée dans les fichiers suivis. Le fichier nouveau est non suivi, donc hors diff Git standard tant qu’il n’est pas indexé.

## 26. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/shadows/v2/shadow_v2_27_projected_building_shadow_editor_preview_design.md
```

Fichiers créés par le Lot 27 :

```text
reports/shadows/v2/shadow_v2_27_projected_building_shadow_editor_preview_design.md
```

Fichiers modifiés par le Lot 27 : Aucun.

Fichiers supprimés par le Lot 27 : Aucun.

Fichiers generated créés/modifiés : Aucun.

Screenshots/baselines créés/modifiés : Aucun.

Fichiers Selbrume modifiés : Aucun.

Confirmation : un seul rapport Markdown a été créé.

Checklist finale :

- [ ] Design-only respecté
- [ ] Aucun fichier de production modifié
- [ ] Aucun test créé/modifié
- [ ] Aucun fichier map_core modifié
- [ ] Aucun fichier map_runtime modifié
- [ ] Aucun fichier map_editor modifié
- [ ] Aucun generated modifié
- [ ] Aucun screenshot créé
- [ ] Aucune baseline créée
- [ ] Selbrume non modifié
- [ ] Canvas / map editor audité
- [ ] Éléments placés editor audités
- [ ] Previews / overlays existants audités
- [ ] Briques ShadowV2 réutilisables auditées
- [ ] Anti-dérive genericProjection / diagnostics vérifié
- [ ] Options comparées
- [ ] Option recommandée unique
- [ ] Plan ShadowV2-28 précis
- [ ] Fichiers interdits au Lot 28 listés
- [ ] Evidence Pack complet
- [ ] git diff --check propre
- [ ] git status final conforme
