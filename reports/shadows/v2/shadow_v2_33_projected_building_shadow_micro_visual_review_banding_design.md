# ShadowV2-33 — Projected Building Shadow Micro Visual Review / Banding Decision Gate

## 1. Résumé exécutif

ShadowV2-33 est un lot design-only. Aucun fichier de production, aucun test, aucune donnée Selbrume, aucun screenshot et aucune baseline n'ont été modifiés ou créés.

Décision principale :

```text
Le banding actuel des projectedPolygon est réel, volontaire, partagé par le runtime et l'éditeur, et techniquement stable.
Il n'est pas encore validé artistiquement.
```

Option recommandée :

```text
Créer au Lot 34 un micro visual artifact contrôlé, lisible humainement, sans baseline CI et sans Selbrume.
```

Pourquoi :

- les tests actuels prouvent la géométrie, le pipeline, l'alpha intérieur/extérieur et le gradient near/far ;
- ils ne prouvent pas que l'ombre est belle ;
- une baseline CI figerait trop tôt un rendu potentiellement laid ;
- une revue renderer/painter sans image contrôlée serait prématurée ;
- Selbrume ne contient pas encore de ShadowV2 calibrée et ajoute trop de variables.

## 2. Objectif du lot

Objectif exact :

```text
Définir la meilleure stratégie de vérification visuelle de la calibration ShadowV2 V0,
en particulier décider si les bandes hard-edge actuelles du projectedPolygon sont acceptables,
avant de créer une baseline ou un screenshot de validation.
```

Ce lot répond à la question :

```text
Est-ce que la calibration V0 peut être validée visuellement avec le renderer/painter existant,
ou faut-il d'abord revoir le rendu des projectedPolygon à cause du banding ?
```

Réponse courte :

```text
La calibration V0 peut être visualisée avec le renderer/painter existant, mais elle ne doit pas encore être baselinée.
Le prochain lot doit produire un artifact visuel micro pour revue humaine avant toute baseline CI.
```

## 3. Rappel ShadowV2-30-bis à ShadowV2-32

ShadowV2-30-bis :

```text
V2 active + preset résoluble
=> aucune shadow V1 static placed same-element produite
=> runtime et editor preview alignés
```

ShadowV2-31 :

```text
preset id: pokemon-building-shadow-v0
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
opacity: 0.30
colorHexRgb: 606060
anchor: (0.5, 0.96)
localOffset: (0, 0)
```

ShadowV2-32 :

```text
map_core -> géométrie calibrée
map_runtime -> visual POC calibré avec pixel intérieur alpha > 0
map_editor -> preview editor calibrée
```

Ce que ShadowV2-32 ne prouve pas :

```text
- beauté visuelle ;
- acceptabilité humaine du banding ;
- lisibilité sur artifact inspectable ;
- stabilité d'une baseline image ;
- rendu Selbrume réel.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
 M packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
?? reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

Fichiers préexistants non liés au Lot 33 :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

Ces fichiers correspondent au travail Lot 32 déjà présent dans le worktree. Ils n'ont pas été modifiés par le Lot 33.

Fichiers créés par le Lot 33 :

```text
reports/shadows/v2/shadow_v2_33_projected_building_shadow_micro_visual_review_banding_design.md
```

Fichiers modifiés par le Lot 33 :

```text
Aucun
```

Fichiers supprimés par le Lot 33 :

```text
Aucun
```

Fichier non suivi apparu pendant la vérification finale, non créé par le Lot 33 :

```text
packages/map_battle/tmp_mirror.dart
```

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Résultats utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
AGENTS.md:1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

```text
Le Lot 33 est un design gate / audit-only.
Aucune implémentation n'a été faite.
Aucun test n'a été lancé, conformément au prompt, puisqu'aucun fichier de code ou test n'a été modifié.
```

## 6. Fichiers audités

Runtime :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

map_core :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Editor :

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Tooling / reports :

```text
packages/map_runtime/**
packages/map_editor/**
reports/shadows/**
```

Selbrume, lecture seule :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/**/*.json
```

## 7. Audit renderer runtime projectedPolygon

Commande :

```bash
rg -n "ShadowRuntimeRenderer|projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|ProjectedStaticShadowOpacityBand|opacityBands|defaultProjectedStaticShadowFillBandCount|defaultProjectedStaticShadowNearOpacityScale|defaultProjectedStaticShadowFarOpacityScale|isAntiAlias|hardEdge|shadowRuntimePaintForInstruction" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib
```

Constantes map_core auditées dans `static_shadow_projection_geometry.dart` :

```text
defaultProjectedStaticShadowFillBandCount = 7
defaultProjectedStaticShadowNearOpacityScale = 1.0
defaultProjectedStaticShadowFarOpacityScale = 0.52
```

Le helper `createProjectedStaticShadowOpacityBands(...)` produit 7 bandes, avec une interpolation linéaire near -> far. Pour l'opacité V0 `0.30`, les opacités effectives sont approximativement :

```text
Bande 1: 0.30 * 0.9657 ≈ 0.290
Bande 2: 0.30 * 0.8971 ≈ 0.269
Bande 3: 0.30 * 0.8286 ≈ 0.249
Bande 4: 0.30 * 0.7600 ≈ 0.228
Bande 5: 0.30 * 0.6914 ≈ 0.207
Bande 6: 0.30 * 0.6229 ≈ 0.187
Bande 7: 0.30 * 0.5543 ≈ 0.166
```

Rendu runtime audité dans `shadow_runtime_renderer.dart` :

```text
- ShadowRuntimeRenderer.renderInstruction(...) route projectedPolygon vers _renderProjectedPolygon(...).
- Si polygonPoints.length != 4, le renderer dessine un seul Path rempli.
- Si polygonPoints.length == 4, le renderer dessine 7 sous-polygones via createProjectedStaticShadowOpacityBands(...).
- shadowRuntimePaintForInstruction(...) utilise PaintingStyle.fill.
- shadowRuntimePaintForInstruction(...) force isAntiAlias = false.
- _validateHardEdge(...) rejette tout softnessMode différent de hardEdge.
- La couleur vient directement de colorHexRgb.
- L'alpha vient de opacity, puis est multiplié par opacityScale pour chaque bande.
```

Conclusion runtime :

```text
Le projectedPolygon n'est pas un fill plat quand il a 4 points.
Il est rendu en 7 bandes hard-edge, sans antialiasing.
Le banding est donc attendu, visible par construction, et stable techniquement.
```

Comportement si `polygonPoints.length != 4` :

```text
Fallback fill plat d'un Path unique.
Ce fallback n'est pas la forme normale des ShadowV2 bâtiment, qui produisent 4 points.
```

Stabilité pixel :

```text
Les tests runtime existants utilisent PictureRecorder/toImage et lisent les pixels en mémoire.
Ils sont adaptés à vérifier alpha intérieur/extérieur et near/far.
Ils ne remplacent pas une revue visuelle humaine.
```

Implication artistique :

```text
7 bandes hard-edge peuvent aider à éviter une grosse plaque uniforme.
Mais sans antialiasing ni blur, ces bandes peuvent aussi produire un effet de strates visible.
La qualité dépend fortement de la taille du bâtiment, de l'opacité et de la surface derrière.
```

## 8. Audit painter editor projectedPolygon

Commande :

```bash
rg -n "paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewShapeKind.projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|opacityBands|isAntiAlias|colorHexRgb|opacity" packages/map_editor/lib packages/map_editor/test
```

Painter audité dans `editor_static_shadow_preview_painter.dart` :

```text
- paintEditorStaticShadowPreviewInstructions(...) ignore les instructions invalides ou opacity <= 0.
- EditorStaticShadowPreviewShapeKind.projectedPolygon utilise la même logique 4 points que le runtime.
- Si polygonPoints.length != 4, le painter dessine un Path unique.
- Si polygonPoints.length == 4, le painter dessine les bandes de createProjectedStaticShadowOpacityBands(...).
- Chaque bande applique opacity * band.opacityScale.
- Le painter force isAntiAlias = false.
- La couleur vient de colorHexRgb.
```

Tests editor audités dans `editor_static_shadow_preview_painter_test.dart` :

```text
- projected polygon preview visible interior / transparent outside ;
- opacity zero transparent ;
- stronger near alpha than far alpha ;
- fallback non-four-point polygons.
```

Conclusion editor :

```text
Le painter editor est aligné avec le renderer runtime pour projectedPolygon.
Il utilise le même helper map_core, les mêmes 7 bandes et isAntiAlias=false.
La preview editor est donc fiable pour vérifier la même famille de rendu que le runtime.
Elle ne suffit pas seule à juger la beauté de l'ombre.
```

Divergence connue runtime/editor :

```text
Aucune divergence de banding identifiée pour projectedPolygon.
Les deux chemins dessinent les mêmes bandes, avec le même modèle d'opacité.
```

## 9. Audit tests visuels actuels

Commande :

```bash
rg -n "runtime_projected_building_shadow_visual_poc|editor_projected_building_shadow_preview|pixel|alpha|PictureRecorder|rawRgba|606060|0.30|pokemon-building-shadow-v0|projectedPolygon|nearAlpha|farAlpha|visible interior|transparent outside|band" packages/map_runtime/test packages/map_editor/test packages/map_core/test reports/shadows
```

Tests qui prouvent la géométrie calibrée :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Preuves :

```text
- preset pokemon-building-shadow-v0 ;
- colorHexRgb 606060 ;
- opacity 0.30 ;
- points calibrés attendus.
```

Tests qui prouvent le pipeline runtime et les pixels :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

Preuves :

```text
- visual POC utilise pokemon-building-shadow-v0 ;
- pixel intérieur recommandé alpha > 0 ;
- pixel extérieur alpha == 0 ;
- projectedPolygon rend un near alpha plus fort que far alpha ;
- renderer applique hardEdge.
```

Tests qui prouvent la preview editor :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Preuves :

```text
- instruction editor projectedPolygon calibrée ;
- points/bounds/opacité/couleur attendus ;
- painter editor visible interior / transparent outside ;
- painter editor near alpha > far alpha.
```

Ce que les tests ne prouvent pas :

```text
- perception humaine du banding ;
- propreté visuelle sur fond type carte ;
- effet "grosse plaque grise" ;
- comparaison avec référence Pokémon-like ;
- cohérence artistique sur plusieurs tailles de bâtiment ;
- stabilité ou pertinence d'une image baseline.
```

## 10. Audit screenshot / baseline tooling existant

Commande :

```bash
rg -n "screenshot|baseline|golden|matchesGoldenFile|toImage|PictureRecorder|ImageByteFormat|png|SHADOW_SCREENSHOT|reports/shadows/baselines|tool/shadow" packages/map_runtime packages/map_editor reports/shadows
```

Résultats utiles :

```text
- Des rapports historiques mentionnent reports/shadows/screenshots et reports/shadows/baselines.
- Plusieurs chemins utilisent PictureRecorder/toImage/ImageByteFormat dans des tests ou harness visuels.
- Des usages golden/matchesGoldenFile existent dans le repo mais ne doivent pas être utilisés pour ce lot.
- Les anciens screenshots/baselines shadow sont surtout liés à des validations historiques ou Selbrume.
```

Évaluation :

```text
Il existe des patterns techniques pour rendre une image en mémoire et, historiquement, exporter des images.
Mais les baselines existantes ne sont pas le bon outil immédiat pour ShadowV2 V0.
```

Pourquoi ne pas réutiliser directement une baseline existante :

```text
- risque de figer un rendu artistiquement non validé ;
- risque de dépendre de pixels exacts trop tôt ;
- risque d'entraîner une baseline massive ou Selbrume-specific ;
- le besoin actuel est d'abord une revue humaine micro, pas une assertion golden.
```

CI-friendliness :

```text
Les tests in-memory actuels sont CI-friendly.
Une baseline image disque pourrait être CI-friendly plus tard, mais seulement après validation visuelle humaine du rendu.
```

## 11. Audit micro-fixture possible

Commande :

```bash
rg -n "Runtime Projected Building Shadow Visual POC|Projected Building Shadow Visual POC|projected-building-shadow-visual-poc|pokemon-building-shadow-v0|606060|MapGridPainter|solidColorImage|_renderGroundStaticShadows|_alphaAt" packages/map_runtime/test packages/map_editor/test
```

Micro-fixture runtime existante :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Caractéristiques :

```text
- utilise le preset pokemon-building-shadow-v0 ;
- rend en mémoire via PictureRecorder ;
- passe par ShadowRuntimeRenderer.renderCollectionPass(...) ;
- vérifie un pixel intérieur et un pixel extérieur ;
- peut servir de base technique à un artifact visuel micro.
```

Micro-fixture editor existante :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Caractéristiques :

```text
- vérifie l'instruction preview calibrée ;
- vérifie le painter projectedPolygon ;
- peut servir à comparer runtime/editor si un artifact côté editor est jugé utile.
```

Décision micro-fixture :

```text
Une image mémoire runtime de petite taille est techniquement suffisante pour produire un artifact visuel stable.
Une comparaison in-memory seule ne suffit pas à répondre à "est-ce joli ?".
Une image disque ponctuelle, non-baseline, est le meilleur prochain support de décision.
```

Taille / zone utile :

```text
La micro-fixture runtime actuelle utilise une image suffisamment petite pour inspecter le polygone calibré.
Le pixel intérieur (80, 150) et le pixel extérieur (10, 10) sont utiles pour les tests, mais l'artifact doit montrer toute l'ombre pour juger le banding.
```

## 12. Audit données Selbrume lecture seule

Commandes :

```bash
test -f /Users/karim/Desktop/selbrume/project.json && rg -n '"projectedBuildingShadow"|"projectedBuildingShadowCatalog"|"pokemon-building-shadow-v0"|"606060"|"shadowCatalog"|"shadow"' /Users/karim/Desktop/selbrume/project.json || true
test -d /Users/karim/Desktop/selbrume/maps && rg -n '"projectedBuildingShadow"|"shadowOverride"|"elementId"' /Users/karim/Desktop/selbrume/maps || true
```

Résumé structuré de l'audit lecture seule :

```text
SELBRUME_PROJECT exists
elements=63
elements_with_shadow=20
elements_with_projectedBuildingShadow=0
projectedBuildingShadowCatalog_presets=0
shadowCatalog_profiles=3
contains_pokemon_building_shadow_v0=false
contains_606060=false
SELBRUME_MAPS files=2
maps_with_projectedBuildingShadow_text=0
maps_with_shadowOverride_text=1
placed_elements=2114
placed_shadowOverride_non_null=0
```

Conclusion Selbrume :

```text
Selbrume ne contient pas la calibration V0.
Selbrume ne contient pas de configs projectedBuildingShadow.
Selbrume contient encore des shadows V1 sur des éléments, mais aucun shadowOverride placement non-null.
```

Décision pour Lot 34 :

```text
Lot 34 ne doit pas modifier Selbrume.
Lot 34 ne doit pas dépendre d'une screenshot Selbrume.
Lot 34 doit rester micro-fixture contrôlée.
```

## 13. Options étudiées

### Option A — Micro baseline image disque

Principe :

```text
Créer une petite image PNG de micro-fixture ShadowV2 calibrée,
puis la comparer ou l'archiver comme baseline ciblée.
```

Avantages :

```text
- preuve visuelle claire ;
- facile à revoir humainement ;
- peut devenir un verrou de régression une fois le rendu accepté.
```

Risques :

```text
- fige trop tôt le banding actuel ;
- peut transformer une décision artistique non tranchée en contrainte CI ;
- dépendance pixel exact ;
- maintenance potentiellement bruyante si le renderer évolue.
```

Décision :

```text
Rejetée pour le prochain lot.
Une baseline CI est prématurée avant une revue visuelle humaine.
```

### Option B — Micro visual test in-memory seulement

Principe :

```text
Étendre les tests pixel actuels sans écrire d'image disque.
```

Avantages :

```text
- stable ;
- CI-friendly ;
- pas de screenshot ;
- pas de baseline.
```

Risques :

```text
- ne répond pas à "est-ce joli ?" ;
- valide des pixels, pas une perception ;
- les tests near/far existent déjà.
```

Décision :

```text
Rejetée comme prochaine étape principale.
Utile en complément, insuffisante pour la décision artistique.
```

### Option C — Manual review artifact sans test golden

Principe :

```text
Créer une image contrôlée de micro-fixture ShadowV2 calibrée,
destinée à la revue humaine,
sans baseline CI et sans matchesGoldenFile.
```

Avantages :

```text
- répond directement à "est-ce joli ?" ;
- évite de baseliner un rendu potentiellement mauvais ;
- garde le scope petit ;
- peut utiliser la micro-fixture runtime déjà calibrée ;
- ne dépend pas de Selbrume.
```

Risques :

```text
- demande un artifact image au prochain lot ;
- ne crée pas encore de verrou CI ;
- nécessite de documenter l'interprétation humaine.
```

Décision :

```text
Option recommandée.
```

### Option D — Banding review avant baseline

Principe :

```text
Ne pas créer d'artifact visuel.
Auditer et éventuellement ajuster les bandes hard-edge avant de figer une image.
```

Avantages :

```text
- évite une baseline sur un rendu potentiellement laid ;
- reconnaît explicitement le risque du banding.
```

Risques :

```text
- reste théorique sans image contrôlée ;
- peut mener à modifier renderer/painter avant d'avoir vu le rendu calibré ;
- risque de sur-concevoir le rendu.
```

Décision :

```text
Rejetée comme prochain lot immédiat.
Le banding doit d'abord être vu dans une micro-fixture calibrée.
```

### Option E — Selbrume mini screenshot

Principe :

```text
Créer une capture réelle sur Selbrume ou une vraie map.
```

Avantages :

```text
- contexte réel ;
- meilleure intuition produit finale.
```

Risques :

```text
- Selbrume ne contient pas de ShadowV2 ;
- trop de variables ;
- assets avec possibles ombres peintes ;
- anciennes V1 encore présentes dans les données ;
- baseline fragile ;
- scope trop large.
```

Décision :

```text
Rejetée.
```

## 14. Décision recommandée

Option recommandée :

```text
Option C — Manual review artifact sans test golden.
```

Décision banding :

```text
Le banding actuel est accepté provisoirement pour produire un micro visual artifact.
Il n'est pas accepté comme baseline CI.
Il ne doit pas être rejeté ou ajusté sans image contrôlée montrant son effet réel.
```

Pourquoi :

```text
- runtime et editor sont alignés ;
- le banding est volontaire et stable ;
- les tests prouvent déjà les propriétés techniques ;
- la question restante est esthétique ;
- un artifact visuel micro répond mieux à cette question qu'un test pixel supplémentaire ;
- une baseline figerait trop tôt le rendu ;
- Selbrume n'est pas prêt pour cette validation.
```

Pourquoi les autres options sont rejetées :

```text
Option A: baseline trop précoce.
Option B: tests in-memory insuffisants pour l'esthétique.
Option D: revue renderer/painter trop théorique sans image micro.
Option E: Selbrume trop variable et sans V2 actuelle.
```

Lot 34 doit faire :

```text
- générer une image micro-fixture ShadowV2 calibrée ;
- rester hors Selbrume ;
- ne pas utiliser matchesGoldenFile ;
- ne pas créer de baseline CI ;
- documenter si les bandes sont visuellement acceptables.
```

Lot 34 ne doit pas faire :

```text
- modifier renderer/painter ;
- modifier les modèles ;
- modifier Selbrume ;
- créer une baseline massive ;
- lancer une calibration artistique large ;
- traiter cycle jour/nuit ou followsSun.
```

## 15. Plan précis du Lot 34

Direction choisie :

```text
ShadowV2-34 — Projected Building Shadow Micro Visual Artifact V0
```

Objectif :

```text
Produire un artifact PNG micro-fixture ShadowV2 calibré, inspectable humainement,
pour décider si le banding hard-edge actuel est acceptable,
sans baseline CI, sans Selbrume et sans modification production.
```

Fichiers à créer :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_micro_visual_artifact_test.dart
reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Fichiers à modifier :

```text
Aucun fichier de production.
Éventuellement aucun fichier existant si le test/artifact est entièrement nouveau.
```

Fichiers interdits :

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
```

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "pokemon-building-shadow-v0|606060|0.30|_renderGroundStaticShadows|PictureRecorder|toImage|ImageByteFormat" packages/map_runtime/test packages/map_editor/test
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_micro_visual_artifact_test.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

```text
- un seul artifact PNG micro créé ;
- aucune baseline créée ;
- aucun matchesGoldenFile ;
- aucun Selbrume ;
- aucune modification production ;
- artifact rendu avec pokemon-building-shadow-v0 ;
- rapport indique si le banding est visuellement acceptable ;
- si le banding est jugé moche, le Lot 35 devient un design gate renderer/painter ;
- si le banding est jugé acceptable, le Lot 35 peut devenir une micro-baseline ciblée.
```

## 16. Fichiers explicitement interdits au Lot 34

```text
packages/map_core/lib/**
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/models/**
packages/map_editor/lib/src/data/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
```

Également interdit au Lot 34 recommandé :

```text
matchesGoldenFile
baseline CI
shader
blur
auto-shadow
genericProjection
followsSun réel
cycle jour/nuit
UI authoring
migration de données
```

## 17. Risques / réserves

```text
1. Le banding peut paraître acceptable sur micro-fixture mais moins bon sur fond réel.
2. Un artifact manuel ne protège pas encore contre les régressions CI.
3. Le rendu hard-edge sans antialiasing peut être trop abrupt selon l'échelle affichée.
4. Les données Selbrume ne permettent pas encore une validation réelle ShadowV2.
5. Le worktree contient des modifications Lot 32 préexistantes, donc le git status final ne peut pas montrer seulement le rapport Lot 33.
6. Le fichier non suivi packages/map_battle/tmp_mirror.dart est apparu pendant la vérification finale. Il n'a pas été créé, lu, modifié ou supprimé par le Lot 33.
```

## 18. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Aucun fichier de production, test, fixture, screenshot, baseline ou donnée Selbrume n'a été modifié.
```

La décision sur le banding est-elle explicite ?

```text
Oui. Le banding est accepté provisoirement pour produire un artifact micro, mais pas accepté comme baseline CI.
```

La recommandation évite-t-elle de baseliner un rendu potentiellement mauvais ?

```text
Oui. La baseline CI est explicitement repoussée après revue humaine.
```

Le plan Lot 34 est-il strictement borné ?

```text
Oui. Il crée un artifact micro contrôlé et un rapport, sans production ni Selbrume.
```

Le plan Lot 34 évite-t-il Selbrume ?

```text
Oui. Selbrume est explicitement interdit.
```

Le plan Lot 34 évite-t-il une baseline massive ?

```text
Oui. Aucun fichier sous reports/shadows/baselines n'est autorisé.
```

Le plan Lot 34 répond-il vraiment à "est-ce que c'est joli ?" ?

```text
Oui, mieux qu'un test pixel : il produit une image micro inspectable humainement.
```

Le rapport contient-il toutes les preuves ?

```text
Oui pour le niveau design-only : commandes, synthèses d'audit, Selbrume, options, décision, plan Lot 34, git final.
```

## 19. Regard critique sur le prompt

Le prompt est bien borné : il évite de transformer une question esthétique en modification prématurée du renderer ou en baseline fragile.

Point de vigilance :

```text
La section "prochain lot potentiel" oppose baseline et banding review,
mais les options incluent un artifact manuel sans golden.
Cette troisième voie est la plus adaptée : elle permet de regarder le rendu avant de décider entre baseline et ajustement renderer.
```

Autre point :

```text
Le critère "git status final ne montre que le rapport Lot 33" n'est pas atteignable dans le worktree actuel,
car des fichiers Lot 32 étaient déjà modifiés/non suivis avant le Lot 33.
Le Lot 33 respecte néanmoins son propre scope : il ne crée que son rapport.
```

## 20. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "ShadowRuntimeRenderer|projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|ProjectedStaticShadowOpacityBand|opacityBands|defaultProjectedStaticShadowFillBandCount|defaultProjectedStaticShadowNearOpacityScale|defaultProjectedStaticShadowFarOpacityScale|isAntiAlias|hardEdge|shadowRuntimePaintForInstruction" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib
rg -n "paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewShapeKind.projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|opacityBands|isAntiAlias|colorHexRgb|opacity" packages/map_editor/lib packages/map_editor/test
rg -n "runtime_projected_building_shadow_visual_poc|editor_projected_building_shadow_preview|pixel|alpha|PictureRecorder|rawRgba|606060|0.30|pokemon-building-shadow-v0|projectedPolygon|nearAlpha|farAlpha|visible interior|transparent outside|band" packages/map_runtime/test packages/map_editor/test packages/map_core/test reports/shadows
rg -n "screenshot|baseline|golden|matchesGoldenFile|toImage|PictureRecorder|ImageByteFormat|png|SHADOW_SCREENSHOT|reports/shadows/baselines|tool/shadow" packages/map_runtime packages/map_editor reports/shadows
rg -n "Runtime Projected Building Shadow Visual POC|Projected Building Shadow Visual POC|projected-building-shadow-visual-poc|pokemon-building-shadow-v0|606060|MapGridPainter|solidColorImage|_renderGroundStaticShadows|_alphaAt" packages/map_runtime/test packages/map_editor/test
test -f /Users/karim/Desktop/selbrume/project.json && rg -n '"projectedBuildingShadow"|"projectedBuildingShadowCatalog"|"pokemon-building-shadow-v0"|"606060"|"shadowCatalog"|"shadow"' /Users/karim/Desktop/selbrume/project.json || true
test -d /Users/karim/Desktop/selbrume/maps && rg -n '"projectedBuildingShadow"|"shadowOverride"|"elementId"' /Users/karim/Desktop/selbrume/maps || true
node - <<'NODE'
// Lecture seule Selbrume : comptage project.json et maps.
NODE
sed -n '1,220p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés :

```text
Aucun. Le lot est design-only et aucun fichier de code/test n'a été modifié.
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../projected_building_shadow_geometry_test.dart   | 69 +++++++++++++++++++++-
 ...tor_projected_building_shadow_preview_test.dart | 44 +++++++-------
 ..._projected_building_shadow_visual_poc_test.dart | 40 ++++++-------
 3 files changed, 109 insertions(+), 44 deletions(-)
```

Interprétation :

```text
Ces diffs sont préexistants au Lot 33 et correspondent au Lot 32.
Le rapport Lot 33 est un fichier non suivi, donc il n'apparaît pas dans git diff --stat.
```

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
M	packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Interprétation :

```text
Ces fichiers étaient déjà modifiés avant le Lot 33.
Le Lot 33 ne les a pas touchés.
```

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Aucune sortie.
```

Interprétation :

```text
git diff --check est propre pour les diffs suivis existants.
```

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale attendue après création du rapport Lot 33 :

```text
 M packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
?? packages/map_battle/tmp_mirror.dart
?? reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
?? reports/shadows/v2/shadow_v2_33_projected_building_shadow_micro_visual_review_banding_design.md
```

Interprétation :

```text
Le seul fichier créé par le Lot 33 est :
reports/shadows/v2/shadow_v2_33_projected_building_shadow_micro_visual_review_banding_design.md

Les trois fichiers de test modifiés et le rapport Lot 32 étaient déjà présents avant le Lot 33.
packages/map_battle/tmp_mirror.dart est un fichier non suivi apparu pendant la vérification finale et non touché par le Lot 33.
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
- [x] Renderer runtime projectedPolygon audité
- [x] Painter editor projectedPolygon audité
- [x] Tests visuels actuels audités
- [x] Tooling screenshot/baseline audité
- [x] Micro-fixture possible auditée
- [x] Données Selbrume lues en lecture seule ou inaccessibilité documentée
- [x] Banding accepté/rejeté explicitement
- [x] Options comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-34 précis
- [x] Fichiers interdits au Lot 34 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope Lot 33, avec modifications Lot 32 préexistantes et tmp_mirror non suivi documentés
