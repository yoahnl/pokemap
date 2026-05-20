# ShadowV2-31 — Projected Building Shadow Visual Calibration Design Gate

## 1. Résumé exécutif

Lot 31 réalisé en design-only.

Conclusion principale : la calibration ShadowV2 V0 peut passer par les données existantes, sans modifier le renderer runtime, le painter editor, les modèles, les codecs, Selbrume, ni les assets.

Option recommandée : calibration par preset uniquement.

Preset V0 recommandé :

- id : `pokemon-building-shadow-v0`
- name : `Pokemon-like building shadow V0`
- direction : `ProjectedShadowDirection(x: 0.8, y: 0.35)`
- shape.lengthRatio : `0.32`
- shape.nearWidthRatio : `0.90`
- shape.farWidthRatio : `0.72`
- appearance.opacity : `0.30`
- appearance.colorHexRgb : `606060`
- timeOfDayMode : `ProjectedShadowTimeOfDayMode.fixed`
- anchor recommandé côté element config : `ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96)`
- localOffset recommandé côté element config : `ProjectedShadowOffset(x: 0, y: 0)`

Le rendu actuel `projectedPolygon` n'est pas un blur, pas un shader et pas une simulation physique. Runtime et editor utilisent un remplissage dur avec `isAntiAlias=false`, modulé par 7 bandes d'opacité hard-edge. Ces bandes sont acceptables en V0 : elles donnent un léger affaiblissement vers l'extrémité sans introduire de soft shadow. Si ce rendu apparaît trop bandé artistiquement, cela devra faire l'objet d'un lot séparé renderer/painter, pas du Lot 32.

## 2. Objectif du lot

Définir une calibration artistique ShadowV2 simple, propre et Pokemon-like pour les ombres projetées de bâtiments.

Le lot devait répondre aux points suivants :

- paramètres ShadowV2 de forme, couleur et opacité ;
- comportement du renderer runtime pour `projectedPolygon` ;
- comportement du painter editor pour `projectedPolygon` ;
- présence ou non de bandes d'opacité ;
- recommandation V0 pour direction, longueur, largeurs, couleur, opacité, anchor et offset ;
- nombre de presets V0 ;
- stratégie runtime/editor ;
- micro-fixture recommandée pour le Lot 32 ;
- fichiers autorisés et interdits au Lot 32.

## 3. Rappel ShadowV2-24 à ShadowV2-30-bis

ShadowV2-24 a branché le runtime :

```text
ProjectManifest + MapData
-> buildRuntimeProjectedBuildingShadowCollection(...)
-> stockage privé par map
-> merge V2 + V1 + actorContact
-> provider interne du background MapLayersComponent
-> ShadowRuntimeRenderer existant
```

ShadowV2-26 a prouvé la chaîne visuelle runtime :

```text
donnée ShadowV2 authorée
-> provider runtime
-> ShadowRuntimeRenderer
-> pixels visibles
```

ShadowV2-28 a branché la preview editor :

```text
ProjectManifest + MapData + tileWidth/tileHeight
-> buildEditorProjectedBuildingShadowPreviewInstructions(...)
-> EditorStaticShadowPreviewInstruction
-> MapGridPainter
-> Canvas editor
```

ShadowV2-30-bis a neutralisé la V1 same-element :

```text
V2 active + preset résoluble
=> aucune shadow V1 static placed same-element produite
=> runtime et editor preview alignés
```

L'état produit est donc bon pour calibrer ShadowV2 : le pipeline existe, la preview editor existe, et la V1 same-element ne salit plus une V2 valide.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
(aucune ligne)
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Décision AGENTS / design gate

AGENTS.md trouvé :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Instruction pertinente dans `/Users/karim/Project/pokemonProject/AGENTS.md` :

```text
Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

- ce lot est explicitement un design gate ;
- aucune implémentation n'a été produite ;
- les compétences process ont été utilisées pour cadrer le travail, mais les instructions directes du lot interdisent tout fichier autre que le rapport ;
- aucun test n'a été lancé, car le lot est design-only et aucun fichier de production/test n'a été modifié.

## 6. Fichiers audités

Fichiers lus ou audités directement :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
/Users/karim/Desktop/selbrume/maps/route 1.json
```

Commandes `rg` obligatoires également exécutées sur :

```text
packages/map_core/lib
packages/map_core/test
packages/map_runtime/lib
packages/map_runtime/test/shadow
packages/map_editor/lib
packages/map_editor/test
reports/shadows
```

## 7. Audit modèles et presets ShadowV2

Champs disponibles pour calibrer ShadowV2 :

- `ProjectBuildingShadowPreset.direction`
- `ProjectBuildingShadowPreset.shape.lengthRatio`
- `ProjectBuildingShadowPreset.shape.nearWidthRatio`
- `ProjectBuildingShadowPreset.shape.farWidthRatio`
- `ProjectBuildingShadowPreset.appearance.opacity`
- `ProjectBuildingShadowPreset.appearance.colorHexRgb`
- `ProjectBuildingShadowPreset.timeOfDayMode`
- `ProjectElementProjectedBuildingShadowConfig.anchor`
- `ProjectElementProjectedBuildingShadowConfig.localOffset`
- `ProjectElementProjectedBuildingShadowConfig.enabled`
- `ProjectElementProjectedBuildingShadowConfig.presetId`

Constats :

- `ProjectedShadowDirection` refuse les vecteurs non finis ou nuls et expose une direction normalisée.
- `ProjectedShadowShapeTuning.lengthRatio` doit être fini et non négatif.
- `nearWidthRatio` et `farWidthRatio` doivent être finis et strictement positifs.
- `ProjectedShadowAppearance` normalise `colorHexRgb` en uppercase et valide une couleur RGB hex.
- `ProjectedShadowAppearance` a un défaut `opacity: 0.18` et `colorHexRgb: '000000'`, mais ce défaut n'est pas une calibration artistique suffisante.
- `ProjectBuildingShadowPresetCatalog.presetById(...)` est exact et sensible à la casse.
- `ProjectedShadowTimeOfDayMode.followsSun` existe comme mode de données, mais il est traité comme `fixed` dans la résolution V0.

Extraits utiles :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:13: followsSun
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:72: final direction = switch (preset.timeOfDayMode) {
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:74: ProjectedShadowTimeOfDayMode.followsSun => preset.direction.normalized,
```

Valeurs déjà utilisées dans les tests :

- `123ABC` : couleur sentinelle de test, pas une couleur visuelle crédible.
- `0.18` : valeur technique historique utilisée dans les micro-fixtures, pas une recommandation artistique solide.
- `ProjectedShadowDirection(x: 1, y: 0)` : direction horizontale stable pour assertions géométriques.
- `lengthRatio: 0.5`, `nearWidthRatio: 1`, `farWidthRatio: 0.5` : géométrie volontairement simple pour obtenir les points attendus `(64,128)`, `(64,192)`, `(112,176)`, `(112,144)`.
- un test de catalogue utilise aussi `direction: (-0.55, 0.35)`, `lengthRatio: 0.28`, `nearWidthRatio: 0.85`, `farWidthRatio: 0.75`, ce qui est plus proche d'un preset court, mais pas encore une décision visuelle V0.

Conclusion :

```text
La calibration peut être faite uniquement par preset/config ShadowV2 existants.
Aucun nouveau modèle, codec, renderer ou painter n'est nécessaire pour un V0.
```

## 8. Audit géométrie ShadowV2

Fichier principal :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
```

Fonction :

```dart
ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
})
```

Comportement :

- si `config.enabled == false`, la géométrie retourne `null` ;
- la direction du preset est normalisée ;
- `followsSun` utilise actuellement la même direction normalisée que `fixed` ;
- l'ancre monde vaut `metrics.left + metrics.visualWidth * anchor.xRatio + localOffset.x` et `metrics.top + metrics.visualHeight * anchor.yRatio + localOffset.y` ;
- la longueur vaut `metrics.visualHeight * lengthRatio` ;
- la demi-largeur proche vaut `metrics.visualWidth * nearWidthRatio / 2` ;
- la demi-largeur lointaine vaut `metrics.visualWidth * farWidthRatio / 2` ;
- le centre lointain vaut `anchor + direction * length` ;
- l'ordre des points est `nearLeft`, `nearRight`, `farRight`, `farLeft`.

Extraits utiles :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:81: final anchorWorldX = metrics.left +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:84: final anchorWorldY = metrics.top +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:88: final length = metrics.visualHeight * preset.shape.lengthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:89: final nearHalfWidth = metrics.visualWidth * preset.shape.nearWidthRatio / 2;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:90: final farHalfWidth = metrics.visualWidth * preset.shape.farWidthRatio / 2;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:96: points: [
```

Pourquoi les points actuels `(64,128)`, `(64,192)`, `(112,176)`, `(112,144)` apparaissent dans les tests :

```text
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96
anchor = (0.5, 1) => (64, 160)
direction = (1, 0)
lengthRatio = 0.5 => length = 48
nearWidthRatio = 1 => near half width = 32
farWidthRatio = 0.5 => far half width = 16
```

La géométrie V2 actuelle permet déjà une ombre Pokemon-like simple :

- direction authorée ;
- longueur courte ;
- largeur proche contrôlée ;
- largeur lointaine contrôlée ;
- anchor et offset par élément ;
- aucune projection automatique ;
- aucune dépendance à l'asset PNG au runtime.

## 9. Audit renderer runtime projectedPolygon

Fichier principal :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

Constats :

- `projectedPolygon` est rendu via `Canvas.drawPath(...)`.
- Le rendu utilise `Paint.style = fill`.
- `Paint.isAntiAlias = false`.
- `colorHexRgb` est appliqué directement après conversion RGB.
- `opacity` est convertie en alpha arrondi.
- Les polygons à 4 points utilisent `createProjectedStaticShadowOpacityBands()`.
- Les polygons qui n'ont pas exactement 4 points utilisent un fallback de fill plat.
- Les tests runtime vérifient que le near alpha est plus fort que le far alpha.

Extraits utiles :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:44: canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:50: for (final band in createProjectedStaticShadowOpacityBands()) {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:86: final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:96: ..isAntiAlias = false
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:139: test('draws projectedPolygon with stronger near alpha than far alpha',
```

Bandes d'opacité :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:11: const defaultProjectedStaticShadowFillBandCount = 7;
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:12: const defaultProjectedStaticShadowNearOpacityScale = 1.0;
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:13: const defaultProjectedStaticShadowFarOpacityScale = 0.52;
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:237: List<ProjectedStaticShadowOpacityBand> createProjectedStaticShadowOpacityBands({
```

Interprétation :

```text
projectedPolygon n'est pas un fill plat en cas nominal 4 points.
Il est rendu en bandes hard-edge de 7 tranches.
Ces bandes modulent l'opacité du preset entre environ 1.0 côté proche et 0.52 côté lointain.
```

Pour la cible V0, les bandes existantes sont acceptables :

- elles ne sont pas un blur ;
- elles ne sont pas un shader ;
- elles restent pixel-art friendly via `isAntiAlias=false` ;
- elles existent déjà dans runtime et editor ;
- les supprimer maintenant toucherait deux chemins de rendu et plusieurs tests.

## 10. Audit painter editor projectedPolygon

Fichier principal :

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Constats :

- le painter editor utilise aussi `Canvas.drawPath(...)` ;
- le painter editor utilise aussi `isAntiAlias=false` ;
- le painter editor parse `colorHexRgb` et applique `opacity` ;
- le painter editor utilise aussi `createProjectedStaticShadowOpacityBands()` pour les polygons à 4 points ;
- les tests editor vérifient aussi le différentiel near/far alpha.

Extraits utiles :

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:26: ..isAntiAlias = false;
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:38: case EditorStaticShadowPreviewShapeKind.projectedPolygon:
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:48: for (final band in createProjectedStaticShadowOpacityBands()) {
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:51: instruction.opacity * band.opacityScale,
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:60: canvas.drawPath(
```

Conclusion :

```text
Runtime et editor sont alignés pour le rendu projectedPolygon V2.
La calibration ne doit pas diverger entre runtime et editor.
Elle doit passer par les mêmes données ShadowV2.
```

## 11. Audit tests visuels ShadowV2 actuels

Tests actuellement centraux :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Valeurs observées :

- `123ABC` est utilisé comme couleur distincte dans les tests V2 runtime/editor.
- `010203` est utilisé comme sentinelle V1 dans les tests de coexistence/suppression.
- `0.18` est utilisé comme opacité ShadowV2 dans plusieurs micro-fixtures.
- Les tests pixel vérifient surtout `alpha > 0` et `alpha == 0`, ce qui est robuste.
- Les tests renderer/painter vérifient que les bandes rendent le near alpha plus fort que le far alpha.

Interprétation :

```text
123ABC est une couleur de test, pas une calibration visuelle.
0.18 est une valeur stable pour preuve de pipeline, pas une décision artistique.
Les tests de pipeline doivent rester capables de distinguer V2/V1, mais le Lot 32 peut introduire une micro-fixture calibrée séparée ou remplacer les valeurs dans les tests dédiés ShadowV2.
```

Tests à ne pas surcharger au Lot 32 :

- les tests unitaires génériques du renderer doivent rester centrés sur la mécanique `projectedPolygon` ;
- les tests anti-dérive doivent rester indépendants de l'esthétique ;
- les tests de suppression V1 same-element doivent rester centrés sur la présence/absence de V1, pas sur le goût visuel.

## 12. Audit données projet / Selbrume lecture seule

Audit lecture seule de `/Users/karim/Desktop/selbrume/project.json` :

```json
{
  "projectExists": true,
  "elementCount": 63,
  "projectedBuildingShadowPresetCount": 0,
  "projectedBuildingShadowElementCount": 0,
  "containsShadowA": false,
  "contains123ABC": false,
  "firstProjectedElementIds": []
}
```

Audit lecture seule de `/Users/karim/Desktop/selbrume/maps` :

```json
{
  "mapFileCount": 2,
  "placedElementCount": 2181,
  "shadowOverrideNonNull": 0,
  "filesContainingProjectedBuildingShadow": 0,
  "files": [
    {
      "file": "Selbrume.json",
      "placedElements": 2105,
      "shadowOverrideNonNull": 0,
      "containsProjectedBuildingShadow": false
    },
    {
      "file": "route 1.json",
      "placedElements": 76,
      "shadowOverrideNonNull": 0,
      "containsProjectedBuildingShadow": false
    }
  ]
}
```

Conclusion Selbrume :

- Selbrume ne contient actuellement aucun preset ShadowV2 ;
- Selbrume ne contient actuellement aucune config `projectedBuildingShadow` ;
- Selbrume ne contient pas `shadow-a` ni `123ABC` ;
- le Lot 32 doit rester micro-fixture/test-only ou sample local contrôlé ;
- le Lot 32 ne doit pas modifier Selbrume.

## 13. Audit anti-dérive

Commande exécutée :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy|matchesGoldenFile|SHADOW_SCREENSHOT|reports/shadows/baselines|selbrume" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test
```

Synthèse des hits :

- `ProjectValidator` et `MapValidator` existent dans les validateurs et repositories : hits attendus, hors calibration V2.
- `diagnoseProjectedBuildingShadows` existe dans `map_core` et ses tests ShadowV2 : diagnostic attendu, ne doit pas devenir une condition de rendu/calibration.
- `genericProjection`, `resolveProjectedStaticShadowGeometry`, `resolveStaticShadowFamilyProjectionSpec`, `static_shadow_family_projection` et `element_auto_shadow_policy` apparaissent dans l'historique V1 et des tests V1 : hits attendus, à ne pas réutiliser pour ShadowV2.
- `selbrume` apparaît dans des tests/fixtures historiques de collision/environnement : hits attendus, hors Lot 31.
- aucun besoin d'utiliser `matchesGoldenFile`, `SHADOW_SCREENSHOT` ou `reports/shadows/baselines` pour la calibration V0.

Risque à éviter au Lot 32 :

```text
Ne pas transformer la calibration artistique en auto-projection,
ne pas faire dépendre le rendu d'un diagnostic,
ne pas créer de baseline Selbrume,
ne pas réintroduire une policy V1.
```

## 14. Options de calibration étudiées

### Option A — Calibration par preset uniquement

Principe :

```text
Créer ou recommander un preset V2 standard bien calibré,
sans modifier renderer ni géométrie.
```

Avantages :

- plus petit changement ;
- respecte le système authoré ;
- aligne runtime et editor par les mêmes données ;
- ne touche pas aux modèles ;
- ne touche pas aux codecs ;
- ne touche pas au renderer/painter ;
- compatible avec les tests de pipeline existants.

Limites :

- ne supprime pas les bandes hard-edge existantes ;
- ne règle pas les assets qui exigent une forme spécifique ;
- nécessite plus tard une UI authoring pour ajuster par asset.

Décision : retenue.

### Option B — Calibration par changement renderer/painter

Principe :

```text
Modifier le rendu projectedPolygon pour changer les bandes, l'opacité ou le fill.
```

Avantages :

- permettrait un fill complètement plat ;
- pourrait rapprocher certains cas d'une ombre pixel-art uniforme.

Rejet :

- touche runtime et editor ;
- casse probablement les tests near/far alpha existants ;
- mélange calibration de données et changement moteur ;
- prématuré tant que le preset seul n'a pas été essayé.

### Option C — Plusieurs presets par taille de bâtiment

Principe :

```text
small-building-shadow
medium-building-shadow
large-building-shadow
tower-shadow
```

Avantages :

- plus flexible ;
- utile pour tours et bâtiments très larges ;
- meilleur contrôle artistique futur.

Rejet V0 :

- trop d'authoring sans UI dédiée ;
- augmente la surface de test ;
- risque de masquer le besoin réel d'une calibration standard simple.

### Option D — Calibration par anchor/offset instance-level

Principe :

```text
Garder un preset stable,
mais régler anchor/localOffset par élément.
```

Avantages :

- nécessaire pour certains assets ;
- permet d'éviter les façades ou portes particulières.

Rejet V0 comme stratégie principale :

- demande un workflow authoring ;
- risque de devenir manuel trop tôt ;
- doit rester un ajustement par élément, pas la base du V0.

### Option E — Calibration via asset-specific hand-authored shapes

Principe :

```text
Chaque bâtiment a une shape/tuning propre.
```

Avantages :

- meilleur résultat possible à long terme ;
- compatible avec une direction artistique fine.

Rejet V0 :

- beaucoup trop manuel ;
- pas nécessaire pour prouver une bonne base ;
- ralentit le chantier avant d'avoir un preset standard.

## 15. Décisions de calibration recommandées

### Couleur

Recommandation :

```text
606060
```

Pourquoi :

- gris neutre ;
- pas bleu, pas violet, pas sale ;
- plus contrôlable que `000000` avec une opacité moyenne ;
- cohérent avec les ombres simples de référence ;
- évite de conserver `123ABC`, qui est une couleur sentinelle de test.

### Opacité

Recommandation :

```text
0.30
```

Pourquoi :

- `0.18` devient très léger avec les bandes, surtout en extrémité ;
- `0.35` risque de revenir vers l'effet plaque sale si combiné à des assets sombres ;
- `0.30` donne une base lisible ;
- les bandes existantes abaissent déjà l'extrémité vers environ 0.16-0.17 effectif.

### Direction

Recommandation :

```text
ProjectedShadowDirection(x: 0.8, y: 0.35)
```

Pourquoi :

- direction bas-droite cohérente avec une lumière haut-gauche ;
- moins artificielle qu'une projection purement horizontale ;
- assez peu verticale pour ne pas avaler la façade ;
- proche de l'esprit des ombres Pokemon-like visibles derrière/sous les bâtiments.

### Shape tuning

Recommandation :

```text
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
```

Pourquoi :

- longueur courte, donc pas de grande plaque ;
- near width proche de la largeur du bâtiment, mais pas pleine largeur ;
- far width légèrement plus étroite, ce qui garde une silhouette contrôlée ;
- compatible avec les petits bâtiments et les maisons moyennes ;
- pour les très grands bâtiments, un preset dédié pourra venir plus tard.

### Anchor / localOffset

Recommandation :

```text
ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96)
ProjectedShadowOffset(x: 0, y: 0)
```

Pourquoi :

- ancre centrée horizontalement ;
- ancre très proche du pied du bâtiment ;
- départ légèrement remonté par rapport à `yRatio: 1`, ce qui garde l'ombre attachée sans trop décoller visuellement ;
- aucun offset magique en V0 ;
- les ajustements par asset restent possibles plus tard.

### Nombre de presets V0

Recommandation :

```text
1 preset standard en V0.
```

Pourquoi :

- le système n'a pas encore d'UI authoring complète ;
- une base unique rend les tests plus lisibles ;
- les presets par taille doivent venir après preuve visuelle, pas avant.

### Divergence runtime/editor

Recommandation :

```text
Aucune divergence.
La calibration doit passer par les données ShadowV2.
```

Pourquoi :

- runtime et editor partagent déjà la logique de bandes ;
- changer un seul côté créerait une preview mensongère ;
- le Lot 28 a justement aligné editor sur la géométrie core.

## 16. Preset V0 recommandé

Option recommandée : Option A — calibration par preset uniquement.

Preset V0 recommandé :

```dart
ProjectBuildingShadowPreset(
  id: 'pokemon-building-shadow-v0',
  name: 'Pokemon-like building shadow V0',
  direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
  shape: ProjectedShadowShapeTuning(
    lengthRatio: 0.32,
    nearWidthRatio: 0.90,
    farWidthRatio: 0.72,
  ),
  appearance: ProjectedShadowAppearance(
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
  timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
)
```

Config element recommandée :

```dart
ProjectElementProjectedBuildingShadowConfig(
  enabled: true,
  presetId: 'pokemon-building-shadow-v0',
  anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
  localOffset: ProjectedShadowOffset(x: 0, y: 0),
)
```

Points attendus sur la micro-fixture historique si le Lot 32 reprend :

```text
tileWidth = 32
tileHeight = 32
placed.pos = (1, 2)
source width = 2
source height = 3
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96
```

Points calculés :

```text
nearLeft  = (75.54, 129.77)
nearRight = (52.46, 182.55)
farRight  = (82.91, 189.58)
farLeft   = (101.38, 147.36)
```

Pixel intérieur recommandé pour test alpha :

```text
(80, 150)
```

Pixel extérieur recommandé :

```text
(10, 10)
```

Pourquoi :

- `(80,150)` reste à l'intérieur du polygone recommandé ;
- `(10,10)` reste clairement hors ombre ;
- les tests doivent vérifier alpha, pas couleur exacte fragile ;
- les points peuvent être vérifiés avec `closeTo`.

Pourquoi les autres options sont rejetées :

- changer renderer/painter est trop large pour une calibration V0 ;
- multiplier les presets est prématuré ;
- régler chaque asset à la main exige un workflow authoring ;
- les shapes entièrement hand-authored sont une étape future, pas un V0.

## 17. Plan précis du Lot 32

```text
ShadowV2-32 — Projected Building Shadow Visual Calibration V0
```

Objectif :

```text
Verrouiller la calibration V0 recommandée dans une micro-fixture contrôlée,
sans Selbrume,
sans screenshot massif,
sans UI authoring,
sans shader,
sans blur,
sans modification renderer/painter.
```

Fichiers à créer :

```text
reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

Fichiers à modifier :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers à modifier seulement si les assertions existantes l'exigent :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
packages/map_editor/test/map_grid_painter_test.dart
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
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Tests à ajouter/modifier :

```text
map_core:
- ajouter ou ajuster un test de géométrie pour le preset pokemon-building-shadow-v0.

map_runtime:
- ajuster le visual POC ou ajouter une sous-section calibrée.
- vérifier instruction V2 colorHexRgb == '606060'.
- vérifier opacity == 0.30.
- vérifier points calibrés avec closeTo.
- vérifier pixel intérieur alpha > 0.
- vérifier pixel extérieur alpha == 0.

map_editor:
- ajuster la preview builder micro-fixture avec les mêmes valeurs.
- vérifier shape projectedPolygon.
- vérifier points/bounds cohérents.
- vérifier absence de dépendance map_runtime inchangée.
```

Assertions obligatoires :

```text
- id preset V0 utilisé dans micro-fixture : pokemon-building-shadow-v0
- direction : (0.8, 0.35)
- lengthRatio : 0.32
- nearWidthRatio : 0.90
- farWidthRatio : 0.72
- opacity : 0.30
- colorHexRgb : 606060
- timeOfDayMode : fixed
- anchor : (0.5, 0.96)
- localOffset : (0, 0)
- points attendus vérifiés avec closeTo
- pixel intérieur alpha > 0
- pixel extérieur alpha == 0
- aucun genericProjection
- aucun screenshot/baseline
- aucun Selbrume
```

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "123ABC|0.18|pokemon-building-shadow-v0|606060|0.30|lengthRatio|nearWidthRatio|farWidthRatio" packages/map_core/test packages/map_runtime/test packages/map_editor/test

cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart

cd packages/map_runtime && flutter analyze test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart

cd /Users/karim/Project/pokemonProject
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|matchesGoldenFile|SHADOW_SCREENSHOT|reports/shadows/baselines|selbrume" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

```text
- aucun fichier de production modifié ;
- aucun modèle/codec/generated modifié ;
- aucun renderer/painter modifié ;
- aucun Selbrume ;
- aucun screenshot/baseline ;
- micro-fixture calibrée runtime et editor alignée ;
- tests ciblés passent ;
- analyzes ciblés passent ;
- git diff --check propre ;
- git status final conforme.
```

## 18. Tests recommandés pour le Lot 32

Test `map_core` recommandé :

```text
resolves pokemon-building-shadow-v0 geometry with calibrated points
```

Assertions :

- géométrie non null ;
- points attendus avec `closeTo` ;
- opacity `0.30` ;
- color `606060` ;
- `followsSun` non utilisé.

Test `map_runtime` recommandé :

```text
runtime projected building visual POC renders calibrated V2 polygon pixels
```

Assertions :

- provider contient une V2 `projectedPolygon` ;
- V1 same-element absente ;
- color `606060` ;
- opacity `0.30` ;
- points calibrés ;
- pixel intérieur alpha > 0 ;
- pixel extérieur alpha == 0.

Test `map_editor` recommandé :

```text
buildEditorProjectedBuildingShadowPreviewInstructions builds calibrated V2 preview
```

Assertions :

- 1 instruction ;
- shape `projectedPolygon` ;
- color `606060` ;
- opacity `0.30` ;
- points calibrés ;
- bounds cohérents ;
- aucune dépendance `map_runtime`.

Anti-dérive :

```text
aucun genericProjection
aucune auto-policy
aucun diagnostic bloquant
aucun matchesGoldenFile
aucun SHADOW_SCREENSHOT
aucun Selbrume
```

## 19. Fichiers explicitement interdits au Lot 32

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Le Lot 32 ne doit pas créer :

```text
screenshot
baseline
fixture Selbrume
nouveau renderer
nouveau painter
nouveau modèle
nouveau codec
generated file
UI authoring
shader
blur
auto-shadow policy
```

## 20. Risques / réserves

- Les bandes hard-edge sont acceptées en V0, mais elles peuvent être visibles sur grands aplats. Si elles jurent artistiquement, il faudra un design gate renderer/painter dédié.
- `opacity: 0.30` avec `606060` devrait être lisible sans salir, mais le rendu dépendra du fond réel de map.
- Une seule calibration standard ne couvrira pas parfaitement les tours et bâtiments très atypiques.
- `anchor.yRatio: 0.96` est un compromis. Certains assets demanderont plus tard un réglage par élément.
- Selbrume ne contient pas encore de données ShadowV2 : ce lot ne prouve pas un résultat Selbrume réel.
- Le Lot 32 doit rester micro-fixture/test-only pour éviter de confondre calibration moteur et migration de données.

## 21. Auto-critique

- Le lot est-il bien design-only ? Oui, seul ce rapport est créé.
- Le rapport propose-t-il une vraie calibration utilisable ? Oui : preset, config element, points micro-fixture et pixels recommandés sont définis.
- La calibration peut-elle être faite sans modifier renderer/painter ? Oui : les champs existants suffisent.
- Le preset recommandé est-il assez simple ? Oui : un seul preset, une seule direction, une shape courte.
- Le preset recommandé évite-t-il l'effet "grosse plaque sale" ? Oui : longueur `0.32`, near `0.90`, far `0.72`, gris `606060`, opacité `0.30`.
- Le preset recommandé est-il aligné avec une référence Pokemon-like ? Oui : ombre dure, grise, courte, bas-droite, sans blur ni shader.
- Le plan Lot 32 est-il strictement borné ? Oui : tests/micro-fixture et rapport, pas de production.
- Le plan Lot 32 évite-t-il Selbrume/screenshot/baseline massive ? Oui.
- Le rapport contient-il toutes les preuves ? Oui : commandes, synthèses d'audit, Selbrume lecture seule, git status, git diff/check.

## 22. Regard critique sur le prompt

Le prompt est correctement borné : il impose un design gate, interdit les modifications et demande un plan Lot 32 concret.

Point de vigilance : "visual calibration" peut naturellement pousser vers des screenshots. Le prompt l'interdit explicitement, ce qui force une décision prudente : calibrer d'abord une micro-fixture contrôlée, puis seulement plus tard regarder des données réelles.

Autre point utile : le prompt demande de trancher renderer/painter vs preset. L'audit montre que runtime et editor sont déjà alignés ; toucher les chemins de rendu maintenant serait prématuré.

## 23. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

rg -n "ProjectBuildingShadowPreset|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAppearance|ProjectedShadowAnchor|ProjectedShadowOffset|ProjectedShadowTimeOfDayMode|lengthRatio|nearWidthRatio|farWidthRatio|opacity|colorHexRgb|followsSun|fixed" packages/map_core/lib packages/map_core/test reports/shadows

rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|lengthRatio|nearWidthRatio|farWidthRatio|direction|anchor|localOffset|StaticShadowVisualMetrics" packages/map_core/lib packages/map_core/test reports/shadows

rg -n "ShadowRuntimeRenderer|projectedPolygon|renderCollectionPass|renderInstruction|drawPath|createProjectedStaticShadowOpacityBands|opacityBands|shadowRuntimePaintForInstruction|isAntiAlias|hardEdge|colorHexRgb|opacity" packages/map_runtime/lib packages/map_runtime/test/shadow

rg -n "paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewShapeKind.projectedPolygon|drawPath|opacity|colorHexRgb|opacityBands|isAntiAlias|hardEdge" packages/map_editor/lib packages/map_editor/test

rg -n "123ABC|010203|0.18|projectedPolygon|alpha|pixel|PictureRecorder|rawRgba|runtime_projected_building_shadow_visual_poc|editor_projected_building_shadow_preview|projected building shadow preview" packages/map_runtime/test packages/map_editor/test reports/shadows

test -f /Users/karim/Desktop/selbrume/project.json && rg -n '"projectedBuildingShadow"|"projectedBuildingShadowCatalog"|"ProjectBuildingShadowPreset"|"shadow-a"|"123ABC"|"colorHexRgb"|"opacity"|"lengthRatio"|"nearWidthRatio"|"farWidthRatio"' /Users/karim/Desktop/selbrume/project.json || true

test -d /Users/karim/Desktop/selbrume/maps && rg -n '"projectedBuildingShadow"|"shadowOverride"|"elementId"' /Users/karim/Desktop/selbrume/maps || true

rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy|matchesGoldenFile|SHADOW_SCREENSHOT|reports/shadows/baselines|selbrume" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test

sed -n '1,220p' packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
sed -n '1,260p' packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
sed -n '260,520p' packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart

rg -n "final direction|anchorWorldX|anchorWorldY|final length|nearHalfWidth|farHalfWidth|farCenterX|points:|followsSun" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_core/lib/src/models/projected_building_shadow.dart
rg -n "projectedPolygon|createProjectedStaticShadowOpacityBands|isAntiAlias|drawPath|shadowRuntimePaintForInstruction|opacity" packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
rg -n "projectedPolygon|createProjectedStaticShadowOpacityBands|isAntiAlias|drawPath|opacity|colorHexRgb" packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
rg -n "defaultProjectedStaticShadowFillBandCount|defaultProjectedStaticShadowNearOpacityScale|defaultProjectedStaticShadowFarOpacityScale|createProjectedStaticShadowOpacityBands|bandCount|opacityScale" packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart

python3 - <<'PY'
import math
left, top = 32, 64
width, height = 64, 96
anchor = (left + width * 0.5, top + height * 0.96)
dx, dy = 0.8, 0.35
mag = math.hypot(dx, dy)
dx, dy = dx / mag, dy / mag
perp = (-dy, dx)
length = height * 0.32
near_half = width * 0.90 / 2
far_half = width * 0.72 / 2
far_center = (anchor[0] + dx * length, anchor[1] + dy * length)
points = [
    ('nearLeft', (anchor[0] - perp[0] * near_half, anchor[1] - perp[1] * near_half)),
    ('nearRight', (anchor[0] + perp[0] * near_half, anchor[1] + perp[1] * near_half)),
    ('farRight', (far_center[0] + perp[0] * far_half, far_center[1] + perp[1] * far_half)),
    ('farLeft', (far_center[0] - perp[0] * far_half, far_center[1] - perp[1] * far_half)),
]
for name, point in points:
    print(name, f'({point[0]:.2f}, {point[1]:.2f})')
PY

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Pour les sorties volumineuses, Context Mode a été utilisé afin de conserver les résultats indexés et de ne reporter ici que les extraits utiles et synthèses précises.

Tests lancés :

```text
Aucun. Le lot est design-only et aucun fichier de production/test n'a été modifié.
```

## 24. git diff --stat

Sortie finale constatée pour les fichiers suivis :

```text
(aucune ligne)
```

Note : le rapport Lot 31 est nouveau et non suivi ; `git diff --stat` ne liste pas les fichiers non suivis.

## 25. git diff --name-status

Sortie finale constatée pour les fichiers suivis :

```text
(aucune ligne)
```

Note : le rapport Lot 31 est nouveau et non suivi ; `git diff --name-status` ne liste pas les fichiers non suivis.

## 26. git diff --check

Sortie finale constatée :

```text
(aucune ligne)
```

## 27. git status final

Sortie finale constatée :

```text
?? reports/shadows/v2/shadow_v2_31_projected_building_shadow_visual_calibration_design.md
```

Fichiers créés :

```text
reports/shadows/v2/shadow_v2_31_projected_building_shadow_visual_calibration_design.md
```

Fichiers modifiés :

```text
Aucun.
```

Fichiers supprimés :

```text
Aucun.
```

Generated / screenshots / baselines :

```text
Aucun.
```

Confirmation :

```text
Un seul rapport Markdown a été créé.
Le rapport courant est le fichier créé ; il ne s'auto-inclut pas récursivement.
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
- [x] Modèles ShadowV2 audités
- [x] Géométrie ShadowV2 auditée
- [x] Renderer runtime projectedPolygon audité
- [x] Painter editor projectedPolygon audité
- [x] Tests visuels actuels audités
- [x] Données projet/Selbrume lues en lecture seule ou inaccessibilité documentée
- [x] Anti-dérive vérifié
- [x] Options de calibration comparées
- [x] Option recommandée unique
- [x] Preset V0 précis recommandé
- [x] Plan ShadowV2-32 précis
- [x] Fichiers interdits au Lot 32 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme
