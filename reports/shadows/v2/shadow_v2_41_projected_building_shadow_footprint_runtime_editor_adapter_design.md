# ShadowV2-41 — Projected Building Shadow Footprint Runtime / Editor Adapter Design Gate

## 1. Résumé exécutif

ShadowV2-41 est un design gate / audit only. Aucun code runtime, editor, core, renderer, painter, screenshot, baseline ou fixture Selbrume n'a été modifié.

Conclusion principale : les chemins runtime et editor existants semblent déjà compatibles avec Footprint Geometry V0, car ils appellent déjà `resolveProjectedBuildingShadowGeometry(...)`, puis convertissent génériquement les `ProjectedBuildingShadowGeometry.points` en `projectedPolygon`.

Option recommandée : Option A — adapter production déjà compatible, tests only.

Le Lot 42 recommandé doit donc ajouter des tests runtime/editor in-memory prouvant que Footprint V0 traverse les adapters existants, sans modifier `ShadowRuntimeRenderer`, sans modifier `editor_static_shadow_preview_painter`, sans image, sans baseline, sans Selbrume.

Risque séparé : la persistance JSON de `geometryMode` / `footprint` n'est pas encore le point bloquant pour un POC in-memory, mais elle reste nécessaire avant une vraie utilisation `project.json` / Selbrume.

## 2. Objectif du lot

Objectif exact du Lot 41 :

```text
Déterminer comment brancher Footprint Geometry V0 dans le runtime et dans la preview editor,
en réutilisant si possible les adapters existants,
sans modifier le renderer,
sans modifier le painter,
sans créer d’image,
sans baseline,
sans Selbrume,
sans modifier le code dans ce lot.
```

Question centrale :

```text
Le nouveau mode footprint implémenté dans map_core est-il déjà automatiquement consommable par le runtime/editor,
ou faut-il modifier les adapters runtime/editor pour le supporter ?
```

## 3. Rappel ShadowV2-39 / ShadowV2-40

ShadowV2-39 a conçu Footprint Geometry V0 :

```text
geometryMode: footprint
points: 4
forme: skewed rectangle / footprint large et court
front edge attaché au pied du bâtiment
rear edge plus bas, légèrement plus large, légèrement décalé vers la droite
renderer/painter: réutilisation de projectedPolygon
Candidate C: benchmark/fallback du mode directional, pas cible principale
```

ShadowV2-40 a ensuite implémenté le core map_core :

```text
ProjectedBuildingShadowGeometryMode
ProjectedShadowFootprintTuning
ProjectBuildingShadowPreset.geometryMode
ProjectBuildingShadowPreset.footprint
resolveProjectedBuildingShadowGeometry(...) avec dispatch directional / footprint
```

Footprint V0 produit une `ProjectedBuildingShadowGeometry` classique :

```text
points.length == 4
opacity
colorHexRgb
```

Micro-fixture validée côté core :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

## 4. État initial du worktree

Commande exécutée avant toute création du rapport :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
 M examples/playable_runtime_host/.metadata
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
 M examples/playable_runtime_host/pubspec.yaml
?? examples/playable_runtime_host/android/.gitignore
?? examples/playable_runtime_host/android/app/build.gradle.kts
?? examples/playable_runtime_host/android/app/src/debug/AndroidManifest.xml
?? examples/playable_runtime_host/android/app/src/main/AndroidManifest.xml
?? examples/playable_runtime_host/android/app/src/main/kotlin/com/example/pokemap_loader/MainActivity.kt
?? examples/playable_runtime_host/android/app/src/main/res/drawable-v21/launch_background.xml
?? examples/playable_runtime_host/android/app/src/main/res/drawable/launch_background.xml
?? examples/playable_runtime_host/android/app/src/main/res/values-night/styles.xml
?? examples/playable_runtime_host/android/app/src/main/res/values/styles.xml
?? examples/playable_runtime_host/android/app/src/profile/AndroidManifest.xml
?? examples/playable_runtime_host/android/build.gradle.kts
?? examples/playable_runtime_host/android/gradle.properties
?? examples/playable_runtime_host/android/gradle/wrapper/gradle-wrapper.properties
?? examples/playable_runtime_host/android/settings.gradle.kts
?? examples/playable_runtime_host/test/widget_test.dart
```

Fichiers préexistants avant ShadowV2-41 :

```text
examples/playable_runtime_host/.metadata
examples/playable_runtime_host/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
examples/playable_runtime_host/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
examples/playable_runtime_host/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
examples/playable_runtime_host/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
examples/playable_runtime_host/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
examples/playable_runtime_host/pubspec.yaml
examples/playable_runtime_host/android/.gitignore
examples/playable_runtime_host/android/app/build.gradle.kts
examples/playable_runtime_host/android/app/src/debug/AndroidManifest.xml
examples/playable_runtime_host/android/app/src/main/AndroidManifest.xml
examples/playable_runtime_host/android/app/src/main/kotlin/com/example/pokemap_loader/MainActivity.kt
examples/playable_runtime_host/android/app/src/main/res/drawable-v21/launch_background.xml
examples/playable_runtime_host/android/app/src/main/res/drawable/launch_background.xml
examples/playable_runtime_host/android/app/src/main/res/values-night/styles.xml
examples/playable_runtime_host/android/app/src/main/res/values/styles.xml
examples/playable_runtime_host/android/app/src/profile/AndroidManifest.xml
examples/playable_runtime_host/android/build.gradle.kts
examples/playable_runtime_host/android/gradle.properties
examples/playable_runtime_host/android/gradle/wrapper/gradle-wrapper.properties
examples/playable_runtime_host/android/settings.gradle.kts
examples/playable_runtime_host/test/widget_test.dart
```

Ces fichiers sont hors scope ShadowV2-41 et n'ont pas été touchés.

Fichier créé par ShadowV2-41 :

```text
reports/shadows/v2/shadow_v2_41_projected_building_shadow_footprint_runtime_editor_adapter_design.md
```

Fichiers modifiés par ShadowV2-41 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-41 :

```text
Aucun
```

## 5. Décision AGENTS / design gate

Commandes exécutées :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties utiles :

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

Décision : le prompt définit un design gate audit-only, donc aucune implémentation n'a été lancée. Les règles AGENTS confirment qu'il faut rester dans l'audit et préparer le lot suivant.

## 6. Fichiers audités

Core map_core :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_core/test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

Runtime :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Editor :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

JSON / persistence :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

V1 suppression / same-element :

```text
packages/map_runtime/lib
packages/map_runtime/test/shadow
packages/map_editor/lib
packages/map_editor/test
reports/shadows/v2
```

## 7. Audit core Footprint V0

Commande exécutée :

```bash
rg -n "ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|geometryMode|footprint|resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint" packages/map_core/lib packages/map_core/test/shadow_v2 reports/shadows/v2
```

Constats :

- `ProjectedBuildingShadowGeometryMode` existe dans `packages/map_core/lib/src/models/projected_building_shadow.dart`.
- `ProjectedShadowFootprintTuning` existe avec les champs V0 attendus.
- `ProjectBuildingShadowPreset` expose `geometryMode` et `footprint`.
- Le mode `directional` reste le défaut historique.
- Le resolver `resolveProjectedBuildingShadowGeometry(...)` dispatche entre directional et footprint.
- La sortie footprint reste un `ProjectedBuildingShadowGeometry` avec 4 points, une opacité et une couleur.

Formule footprint auditée :

```text
centerX = metrics.left + metrics.visualWidth * 0.5 + config.localOffset.x
frontY = metrics.top + metrics.visualHeight * footprint.attachYRatio + config.localOffset.y

frontWidth = metrics.visualWidth * footprint.frontWidthRatio
rearWidth = metrics.visualWidth * footprint.rearWidthRatio
depth = metrics.visualHeight * footprint.depthRatio

rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio
rearY = frontY + depth

frontLeft.x = centerX - frontWidth / 2
frontLeft.y = frontY

frontRight.x = centerX + frontWidth / 2
frontRight.y = frontY

rearRight.x = rearCenterX + rearWidth / 2
rearRight.y = rearY

rearLeft.x = rearCenterX - rearWidth / 2
rearLeft.y = rearY
```

Micro-fixture core attendue :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

Contrat de sortie consommable :

```text
ProjectedBuildingShadowGeometry(
  points: List<ProjectedBuildingShadowPoint>,
  opacity: double,
  colorHexRgb: String,
)
```

Cette sortie est identique au contrat déjà consommé par les adapters runtime/editor pour le mode directionnel.

Risque identifié : les codecs JSON ne sont pas encore considérés comme prêts pour persister `geometryMode` / `footprint`, donc Footprint V0 est consommable in-memory mais pas encore prêt pour une vraie donnée persistée `project.json`.

## 8. Audit runtime adapter

Commande exécutée :

```bash
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ShadowRuntimeRenderInstruction|ShadowRuntimePoint|projectedPolygon|polygonPoints|ProjectBuildingShadowPreset|projectedBuildingShadow" packages/map_runtime/lib packages/map_runtime/test/shadow
```

Fichiers clés lus :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

Réponse aux questions obligatoires :

1. Le runtime adapter appelle-t-il déjà `resolveProjectedBuildingShadowGeometry(...)` ?

Oui, le chemin collection runtime appelle le resolver map_core dans `runtime_projected_building_shadow_collection.dart`.

2. Convertit-il les points génériquement ?

Oui. `createProjectedBuildingShadowRuntimeInstruction(ProjectedBuildingShadowGeometry geometry)` transforme `geometry.points` en `ShadowRuntimePoint` sans inspecter `direction`, `shape`, `anchor`, `geometryMode` ou `footprint`.

3. Dépend-il de direction / shape / anchor explicitement ?

Non dans l'adapter runtime. Ces détails sont délégués au resolver map_core.

4. Sait-il déjà transporter n'importe quelle geometry à 4 points ?

Oui. Il exige seulement que la géométrie fournisse des points valides, puis calcule les bounds depuis ces points.

5. Faut-il modifier le runtime adapter pour footprint ?

Diagnostic : non, pas pour Footprint V0 in-memory. La production runtime adapter paraît déjà compatible.

6. Faut-il seulement ajouter des tests footprint ?

Oui. Le Lot 42 doit prouver cette compatibilité avec des tests runtime ciblés.

7. Le renderer a-t-il besoin d'être modifié ?

Non. Footprint V0 sort un `projectedPolygon` à 4 points, compatible avec le renderer existant.

8. Les instructions runtime actuelles acceptent-elles les points footprint ?

Oui. `ShadowRuntimeRenderInstruction` accepte `ShadowRuntimeShapeKind.projectedPolygon` avec `polygonPoints`. Footprint V0 ne demande pas de nouveau shape kind.

Constat sur le renderer :

```text
ShadowRuntimeRenderer rend déjà projectedPolygon.
Avec 4 points, il applique les bandes hard-edge existantes.
Avec plus de 4 points, il basculerait vers un remplissage plat.
Footprint V0 est à 4 points, donc il conserve le comportement actuel.
```

Conclusion runtime : adapter production déjà compatible pour un preset footprint construit en mémoire.

## 9. Audit editor preview adapter

Commande exécutée :

```bash
rg -n "buildEditorProjectedBuildingShadowPreviewInstructions|resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewPoint|projectedPolygon|polygonPoints|ProjectBuildingShadowPreset|projectedBuildingShadow" packages/map_editor/lib packages/map_editor/test
```

Fichiers clés lus :

```text
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Réponse aux questions obligatoires :

1. Le builder editor appelle-t-il déjà `resolveProjectedBuildingShadowGeometry(...)` ?

Oui. `buildEditorProjectedBuildingShadowPreviewInstructions(...)` résout la géométrie via map_core.

2. Convertit-il les points génériquement ?

Oui. Il mappe les `geometry.points` en `EditorStaticShadowPreviewPoint` sans branche spécifique au mode directionnel.

3. Dépend-il explicitement de direction / shape / anchor ?

Non dans l'adapter preview. Ces paramètres restent encapsulés dans le resolver map_core.

4. Sait-il déjà produire une `EditorStaticShadowPreviewInstruction` avec les points footprint ?

Oui, car il émet une instruction `projectedPolygon` à partir de la géométrie résolue.

5. Faut-il modifier le builder editor pour footprint ?

Diagnostic : non, pas pour Footprint V0 in-memory.

6. Faut-il seulement ajouter des tests footprint ?

Oui. Le Lot 42 doit ajouter un test editor preview footprint ciblé.

7. Le painter editor a-t-il besoin d'être modifié ?

Non. Le painter sait déjà dessiner `EditorStaticShadowPreviewShapeKind.projectedPolygon`.

8. `MapGridPainter` a-t-il besoin d'être modifié ?

Diagnostic : non. Un test de non-régression peut être utile si le pipeline de preview l'exige, mais aucune modification painter / grid n'est recommandée.

Conclusion editor : le builder preview paraît déjà compatible avec Footprint V0, à condition que le preset footprint soit disponible en mémoire dans le manifest.

## 10. Audit JSON / persistence risk

Commande exécutée :

```bash
rg -n "ProjectBuildingShadowPreset|ProjectBuildingShadowPresetCatalog|projectedBuildingShadowCatalog|projectedBuildingShadow|encode|decode|fromJson|toJson|geometryMode|footprint" packages/map_core/lib packages/map_core/test reports/shadows/v2
```

Réponses :

1. Existe-t-il un codec JSON manuel pour `ProjectBuildingShadowPreset` ou le catalog ?

Oui. Les fichiers audités indiquent un codec manuel pour les presets et le catalog :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
```

2. Les nouveaux champs `geometryMode` / `footprint` sont-ils persistés aujourd'hui ?

Audit : non confirmé comme supporté. Les tests JSON existants caractérisent le preset directionnel historique avec `direction`, `shape`, `appearance`, `timeOfDayMode`, `categoryId`, `sortOrder`. Aucun support persistant complet de `geometryMode` / `footprint` n'a été retenu comme déjà validé par ce lot.

3. Si non, est-ce bloquant pour un test runtime/editor in-memory ?

Non. Le Lot 42 peut créer un preset footprint en mémoire et vérifier les adapters sans passer par JSON.

4. Est-ce bloquant pour une vraie utilisation Selbrume / `project.json` ?

Oui. Avant d'utiliser Footprint V0 dans des données réelles, il faudra un lot JSON / persistence pour encoder et décoder `geometryMode` / `footprint`.

5. Faut-il faire un lot JSON avant ou après l'intégration runtime/editor ?

Recommandation : après les tests adapter in-memory. Le chemin adapter doit d'abord être prouvé sans mélanger la persistance. Ensuite seulement, un lot JSON pourra rendre Footprint V0 utilisable dans `project.json`.

Décision JSON :

```text
Pas bloquant pour ShadowV2-42 si Lot 42 reste in-memory.
Bloquant pour application réelle à Selbrume ou toute donnée persistée.
```

## 11. Audit V1 suppression same-element

Commande exécutée :

```bash
rg -n "_hasResolvableProjectedBuildingShadow|projectedBuildingShadowCatalog|projectedBuildingShadow|enableStaticPlacedElementShadows|same-element|legacy static shadow|shadowOverride" packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test reports/shadows/v2
```

Constats :

- La règle de suppression V2 / V1 same-element repose sur la présence d'une ombre projetée V2 résolvable pour le même élément.
- Cette règle est liée au config `projectedBuildingShadow` et au preset disponible dans le catalog, pas à une dépendance directe au modèle directionnel.
- Footprint V0 reste un preset V2 et produit une géométrie V2 valide.
- Il ne devrait donc pas réactiver les anciennes ombres V1 same-element.

Risque :

```text
Même si le raisonnement est favorable, il faut ajouter un test footprint spécifique.
```

Recommandation Lot 42 :

```text
Ajouter un test V1 suppression same-element avec preset footprint in-memory,
pour garantir qu'une ombre V2 footprint valide continue de masquer la V1 du même élément.
```

## 12. Options étudiées

### Option A — Adapter production déjà compatible, tests only

Principe :

```text
Runtime/editor appellent déjà le resolver map_core.
Footprint est automatiquement supporté.
Le prochain lot ajoute seulement des tests runtime/editor.
```

Analyse :

- Meilleur cas confirmé par audit.
- Pas de modification production runtime/editor.
- Pas de modification renderer/painter.
- Permet de prouver le pipeline in-memory.
- Nécessite des tests runtime/editor ciblés.
- Nécessite un test V1 suppression + footprint.

### Option B — Adapter runtime/editor minimal

Principe :

```text
Modifier minimalement les adapters runtime/editor pour consommer Footprint V0.
```

Analyse :

- Non recommandé maintenant.
- Les adapters sont déjà génériques.
- Modifier production sans preuve de besoin créerait du bruit et du risque.

### Option C — Runtime d'abord, editor ensuite

Analyse :

- Réduit le scope apparent.
- Mais crée un risque de divergence entre rendu et preview.
- Non nécessaire puisque les deux chemins semblent déjà compatibles.

### Option D — Editor d'abord, runtime ensuite

Analyse :

- Utile si l'authoring était prioritaire.
- Mais crée aussi une divergence preview/runtime.
- Non nécessaire puisque les deux chemins peuvent être testés ensemble.

### Option E — JSON / persistence d'abord

Analyse :

- Nécessaire pour vraie utilisation project.json.
- Mais ce n'est pas nécessaire pour prouver les adapters in-memory.
- Mélanger JSON et runtime/editor rendrait le Lot 42 moins lisible.

### Option F — Renderer / painter changes

Analyse :

- Rejeté.
- Footprint V0 est volontairement un `projectedPolygon` 4 points.
- Les bandes hard-edge et les choix painter/renderer sont un sujet séparé.
- Modifier renderer/painter maintenant serait prématuré.

## 13. Option recommandée

Option recommandée : Option A — Adapter production déjà compatible, tests only.

Diagnostic :

```text
runtime adapter : déjà compatible
editor preview : déjà compatible
JSON : non bloquant maintenant, nécessaire plus tard
V1 suppression : conceptuellement OK, besoin de test footprint
```

Pourquoi :

- `map_core` produit déjà une `ProjectedBuildingShadowGeometry` standard.
- Le runtime collection appelle déjà `resolveProjectedBuildingShadowGeometry(...)`.
- Le runtime adapter convertit les points génériquement vers `ShadowRuntimePoint`.
- Le renderer accepte déjà `ShadowRuntimeShapeKind.projectedPolygon`.
- Le builder editor appelle déjà le même resolver map_core.
- Le builder editor convertit les points génériquement vers `EditorStaticShadowPreviewPoint`.
- Le painter editor accepte déjà `EditorStaticShadowPreviewShapeKind.projectedPolygon`.
- Footprint V0 ne demande ni nouveau renderer, ni nouveau painter, ni nouveau shape kind.

Pourquoi les autres options sont rejetées :

- Option B ajoute du code production sans besoin identifié.
- Option C et D fragmentent runtime/editor alors que l'objectif est la cohérence.
- Option E est utile pour plus tard, mais retarderait inutilement la preuve adapter in-memory.
- Option F contredit le design Footprint V0, qui réutilise `projectedPolygon`.

Lot 42 doit faire :

- Ajouter des tests runtime/editor in-memory pour Footprint V0.
- Vérifier le transport exact des 4 points footprint.
- Vérifier les bounds, l'opacité et la couleur.
- Vérifier que la suppression V1 same-element reste active avec footprint.
- Produire un rapport complet.

Lot 42 ne doit pas faire :

- Modifier le renderer.
- Modifier le painter editor.
- Modifier `MapGridPainter`, sauf test strictement nécessaire.
- Modifier JSON / codecs.
- Modifier Selbrume.
- Créer baseline.
- Créer screenshot.
- Créer UI authoring.

## 14. Plan précis du Lot 42

Nom recommandé :

```text
ShadowV2-42 — Projected Building Shadow Footprint Runtime / Editor Adapter Tests V0
```

Objectif :

```text
Ajouter des tests runtime/editor prouvant que le Footprint V0 map_core traverse déjà les adapters existants,
sans modifier la production runtime/editor,
sans modifier le renderer,
sans modifier le painter,
sans JSON,
sans image,
sans baseline,
sans Selbrume.
```

Fichiers probables à modifier :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers possibles si une couverture visuelle in-memory déjà existante est pertinente :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Fichier rapport à créer :

```text
reports/shadows/v2/shadow_v2_42_projected_building_shadow_footprint_runtime_editor_adapter_tests_v0.md
```

Fichiers à ne pas modifier :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_core/lib/**
```

Tests recommandés :

```text
runtime adapter converts footprint geometry points into projected polygon instruction
runtime collection resolves footprint preset in-memory and emits projected polygon
runtime same-element V1 shadow is suppressed when footprint V2 is resolvable
editor preview resolves footprint preset in-memory and emits projected polygon preview instruction
editor same-element V1 preview is suppressed when footprint V2 is resolvable
```

Assertions recommandées :

```text
shape == projectedPolygon
points.length == 4
point[0] == (28.80, 146.56)
point[1] == (99.20, 146.56)
point[2] == (108.80, 173.44)
point[3] == (32.00, 173.44)
bounds.left == 28.80
bounds.top == 146.56
bounds.width == 80.00
bounds.height == 26.88
opacity == 0.28
colorHexRgb == 606060
```

Commandes à lancer dans Lot 42 :

```bash
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
cd packages/map_runtime && flutter analyze test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Critères de validation Lot 42 :

```text
tests runtime footprint passent
tests editor footprint passent
aucun fichier production runtime modifié
aucun fichier production editor modifié
aucun renderer/painter modifié
aucun map_core modifié
aucun JSON modifié
aucun screenshot/baseline créé
```

## 15. Fichiers explicitement interdits au Lot 42

Sauf justification forte et nouveau prompt explicite, le Lot 42 ne doit pas modifier :

```text
packages/map_core/**
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_grid_painter.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
```

Le Lot 42 ne doit pas créer :

```text
screenshot
baseline
fixture Selbrume
UI authoring
shader
blur
renderer
painter
codec JSON
migration
```

## 16. Risques / réserves

- Le diagnostic "adapters déjà compatibles" repose sur l'audit du code et doit être transformé en tests au Lot 42.
- Le support JSON n'est pas considéré comme prêt ; cela bloque l'utilisation réelle dans `project.json`.
- Les bandes hard-edge restent présentes, car Footprint V0 produit 4 points et réutilise les bandes actuelles.
- Le renderer et le painter ne doivent pas être modifiés tant que le pipeline footprint n'a pas été prouvé par tests.
- Les changements préexistants dans `examples/playable_runtime_host/**` restent hors scope et peuvent rendre le `git status final` non vide.

## 17. Auto-critique

- Le lot est-il bien design-only ?
  Oui. Seul ce rapport Markdown est créé.

- Le rapport prouve-t-il vraiment si les adapters sont déjà compatibles ?
  Il le prouve au niveau audit statique : les adapters consomment la géométrie résolue de façon générique. Le Lot 42 doit transformer cette preuve en tests exécutables.

- Le rapport évite-t-il de modifier runtime/editor trop tôt ?
  Oui. La recommandation est tests only.

- Le risque JSON/persistence est-il clairement séparé du POC in-memory ?
  Oui. JSON est non bloquant pour Lot 42, mais bloquant pour usage réel.

- Le plan Lot 42 est-il strictement borné ?
  Oui. Il cible tests runtime/editor sans production.

- Le plan évite-t-il Selbrume / baseline / renderer / painter ?
  Oui.

- Le rapport contient-il toutes les preuves ?
  Oui pour l'audit design. Les sorties git finales sont documentées dans les sections dédiées.

## 18. Regard critique sur le prompt

Le prompt est utilement strict : il empêche de coder prématurément dans runtime/editor alors que l'audit montre que les adapters sont probablement déjà compatibles.

Point de vigilance : le prompt demande d'auditer JSON mais interdit toute modification. Cette séparation est saine, car elle évite de mélanger trois sujets différents :

```text
1. compatibilité adapter in-memory ;
2. persistance project.json ;
3. rendu visuel / artifact.
```

La bonne trajectoire est donc :

```text
Lot 42 : tests adapter in-memory
Lot suivant éventuel : JSON / persistence
Lot ultérieur : artifact visuel footprint ou application projet réelle
```

## 19. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

```bash
find .. -name AGENTS.md -print
```

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

```bash
rg -n "ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|geometryMode|footprint|resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint" packages/map_core/lib packages/map_core/test/shadow_v2 reports/shadows/v2
```

```bash
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ShadowRuntimeRenderInstruction|ShadowRuntimePoint|projectedPolygon|polygonPoints|ProjectBuildingShadowPreset|projectedBuildingShadow" packages/map_runtime/lib packages/map_runtime/test/shadow
```

```bash
rg -n "buildEditorProjectedBuildingShadowPreviewInstructions|resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewPoint|projectedPolygon|polygonPoints|ProjectBuildingShadowPreset|projectedBuildingShadow" packages/map_editor/lib packages/map_editor/test
```

```bash
rg -n "ProjectBuildingShadowPreset|ProjectBuildingShadowPresetCatalog|projectedBuildingShadowCatalog|projectedBuildingShadow|encode|decode|fromJson|toJson|geometryMode|footprint" packages/map_core/lib packages/map_core/test reports/shadows/v2
```

```bash
rg -n "_hasResolvableProjectedBuildingShadow|projectedBuildingShadowCatalog|projectedBuildingShadow|enableStaticPlacedElementShadows|same-element|legacy static shadow|shadowOverride" packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test reports/shadows/v2
```

```bash
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés :

```text
Aucun. Le lot est design-only et le prompt demande de ne pas lancer de tests.
```

## 20. git diff --stat

Commande exécutée :

```bash
git diff --stat
```

Sortie :

```text
 examples/playable_runtime_host/.metadata    | 12 ++++++------
 examples/playable_runtime_host/pubspec.yaml |  2 +-
 2 files changed, 7 insertions(+), 7 deletions(-)
```

Note : le rapport ShadowV2-41 est un fichier non suivi, donc il n'apparaît pas dans `git diff --stat`.

## 21. git diff --name-status

Commande exécutée :

```bash
git diff --name-status
```

Sortie :

```text
M	examples/playable_runtime_host/.metadata
M	examples/playable_runtime_host/pubspec.yaml
```

Ces deux fichiers étaient déjà modifiés avant ShadowV2-41 et sont hors scope.

## 22. git diff --check

Commande exécutée :

```bash
git diff --check
```

Sortie :

```text
```

Résultat : propre, exit code 0.

## 23. git status final

Commande exécutée :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M examples/playable_runtime_host/.metadata
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
A  examples/playable_runtime_host/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
 M examples/playable_runtime_host/pubspec.yaml
?? examples/playable_runtime_host/android/.gitignore
?? examples/playable_runtime_host/android/app/build.gradle.kts
?? examples/playable_runtime_host/android/app/src/debug/AndroidManifest.xml
?? examples/playable_runtime_host/android/app/src/main/AndroidManifest.xml
?? examples/playable_runtime_host/android/app/src/main/kotlin/com/example/pokemap_loader/MainActivity.kt
?? examples/playable_runtime_host/android/app/src/main/res/drawable-v21/launch_background.xml
?? examples/playable_runtime_host/android/app/src/main/res/drawable/launch_background.xml
?? examples/playable_runtime_host/android/app/src/main/res/values-night/styles.xml
?? examples/playable_runtime_host/android/app/src/main/res/values/styles.xml
?? examples/playable_runtime_host/android/app/src/profile/AndroidManifest.xml
?? examples/playable_runtime_host/android/build.gradle.kts
?? examples/playable_runtime_host/android/gradle.properties
?? examples/playable_runtime_host/android/gradle/wrapper/gradle-wrapper.properties
?? examples/playable_runtime_host/android/settings.gradle.kts
?? examples/playable_runtime_host/test/widget_test.dart
?? reports/shadows/v2/shadow_v2_41_projected_building_shadow_footprint_runtime_editor_adapter_design.md
```

Conformité scope :

```text
Fichier créé par ShadowV2-41 :
reports/shadows/v2/shadow_v2_41_projected_building_shadow_footprint_runtime_editor_adapter_design.md

Fichiers préexistants hors scope encore visibles :
examples/playable_runtime_host/**

Fichiers production/test/runtime/editor/core modifiés par ShadowV2-41 :
Aucun
```

Checklist finale :

- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Core Footprint V0 audité
- [x] Runtime adapter audité
- [x] Editor preview adapter audité
- [x] JSON / persistence risk audité
- [x] V1 suppression same-element auditée
- [x] Options comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-42 précis
- [x] Fichiers interdits au Lot 42 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
