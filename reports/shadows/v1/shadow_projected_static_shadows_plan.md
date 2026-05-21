# Projected Static Shadows / Auto Authoring Plan

## 1. Verdict

La bonne solution n'est pas seulement de mieux remplir `footprint`.

Le rendu vise par la reference utilisateur correspond a des ombres portees directionnelles : formes plates, attachees aux objets, souvent polygonales ou trapezoidales. Le renderer actuel des static shadows dessine des ovales via `Canvas.drawOval(...)`; meme avec des footprints corrects, il produitra encore des galettes.

Decision recommandee :

- garder les ombres PNJ / joueur en contact blob ovale ;
- ajouter un rendu polygonal pour les ombres statiques d'objets ;
- calculer cette projection depuis la geometrie `map_core` existante ;
- ajouter ensuite une generation automatique des configs d'ombre d'element ;
- ne pas introduire tout de suite de lumiere globale persistante.

Estimation : 7 lots precis apres ce plan.

Chemin rapide visible : lots 35 a 38.
Chemin automatique complet : lots 35 a 41.

## 2. Cible visuelle

Reference utilisateur :

- maisons : ombre large, basse, portee vers un cote, proche d'un trapeze ;
- lampadaires : ombre fine et coherente, attachee au pied, pas une ellipse massive ;
- panneaux / puits / stands : ombre locale, plate, lisible ;
- PNJ / joueur : contact shadow actuel acceptable.

Donc deux familles doivent coexister :

- `actorContact` : blob ovale sous acteurs dynamiques ;
- `groundStatic` : ombre projetee directionnelle sous elements statiques.

## 3. Audit actuel

### 3.1 `map_core`

Fichiers audites :

```text
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/operations/static_shadow_geometry.dart
```

Etat actuel :

- `ShadowCasterMode` contient `none`, `contactBlob`, `ellipse` ;
- `ShadowRenderPass` contient `groundStatic`, `actorContact` ;
- `StaticShadowFootprintConfig` existe ;
- `resolveStaticShadowGeometry(...)` calcule une ellipse finale via `left/top/width/height` ;
- aucune geometrie de projection polygonale n'existe.

Conclusion :

- `resolveStaticShadowGeometry(...)` reste utile comme base ;
- il faut ajouter une operation pure supplementaire pour transformer cette base en path/projection ;
- pas besoin de changer les codecs JSON dans le premier lot de projection.

### 3.2 `map_runtime`

Fichiers audites :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

Etat actuel :

- `ShadowRuntimeShapeKind` contient `contactBlob`, `ellipse` ;
- `ShadowRuntimeRenderInstruction` porte seulement rectangle + taille ;
- `ShadowRuntimeRenderer.renderInstruction(...)` construit un `Rect` puis appelle `canvas.drawOval(...)` ;
- `MapLayersComponent` appelle le renderer dans `_paintShadows(...)` ;
- l'ordre runtime reste : surfaces -> shadows -> placed elements -> actors / overlays.

Conclusion :

- le bon point d'extension runtime est `ShadowRuntimeRenderInstruction` + `ShadowRuntimeRenderer` ;
- il ne faut pas creer un nouveau Flame Component ;
- il ne faut pas modifier `MapLayersComponent`, sauf si un test revele un besoin d'ordre de rendu.

### 3.3 `map_editor`

Fichiers audites :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/application/shadow/editor_shadow_light_preview.dart
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
```

Etat actuel :

- la preview editor utilise `resolveStaticShadowGeometry(...)` ;
- le painter editor dessine aussi via `Canvas.drawOval(...)` ;
- Shadow-34 a ajoute une preview de lumiere editor-only ;
- Shadow-31 expose l'edition manuelle de `ProjectElementShadowConfig.footprint`.

Conclusion :

- l'editeur doit recevoir la meme projection que le runtime ;
- le painter doit accepter un path/polygon pour les static shadows ;
- l'UI auto-authoring doit rester dans `ElementShadowSection` ou un helper appele par cette section.

## 4. Audit Flame / Canvas

Version locale :

```text
flame: 1.37.0
```

API relevante :

- Flame `Component.render(Canvas canvas)` recoit un `Canvas` Flutter ;
- Flame `renderTree(Canvas canvas)` propage ce canvas dans l'arbre de composants ;
- `MapLayersComponent` est un `PositionComponent` et peint deja les shadows dans son rendu ;
- `ShadowRuntimeRenderer` recoit deja un `dart:ui Canvas`.

Implication :

- `Canvas.drawPath(Path, Paint)` est compatible avec le chemin Flame actuel ;
- pas besoin d'un nouveau composant Flame ;
- pas besoin d'un `saveLayer` ;
- pas besoin d'un atlas ou sprite d'ombre ;
- le rendu polygonal peut rester pixel-art friendly avec `Paint.isAntiAlias = false`.

API a utiliser :

```dart
final path = ui.Path()
  ..moveTo(p0.x, p0.y)
  ..lineTo(p1.x, p1.y)
  ..lineTo(p2.x, p2.y)
  ..lineTo(p3.x, p3.y)
  ..close();

canvas.drawPath(path, paint);
```

## 5. Architecture recommandee

### 5.1 Projection core

Ajouter une operation pure dans `map_core` :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

Elle doit partir de :

- `ResolvedStaticShadowGeometry` ;
- `StaticShadowVisualMetrics` ;
- une direction de projection V0 ;
- un ratio de longueur ;
- un facteur de taper.

Elle doit produire des points purs, sans Flutter :

```text
ProjectedStaticShadowGeometry
ProjectedStaticShadowPoint
```

Pas de `Offset`, pas de `Canvas`, pas de Flame dans `map_core`.

### 5.2 Runtime

Etendre l'instruction runtime :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
```

Ajouter :

- `ShadowRuntimeShapeKind.projectedPolygon` ;
- une petite classe pure `ShadowRuntimePoint` ;
- un champ optionnel `polygonPoints`.

Regle :

- `ellipse` / `contactBlob` gardent `worldLeft/worldTop/width/height` ;
- `projectedPolygon` doit porter au moins 3 points ;
- actor shadows restent ovales.

Renderer :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

- `ellipse` et `contactBlob` : `drawOval(...)` ;
- `projectedPolygon` : `drawPath(...)` ;
- meme paint hardEdge ;
- pas de blur.

### 5.3 Editor

Etendre :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Ajouter les points de polygon a `EditorStaticShadowPreviewInstruction`.

Painter :

- si instruction polygonale : `Canvas.drawPath(...)` ;
- sinon : `Canvas.drawOval(...)`.

### 5.4 Auto-authoring

Ajouter un helper editor-only :

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
```

Inputs :

- `ProjectElementEntry` ;
- `ProjectManifest.shadowCatalog` ;
- config existante optionnelle.

Output :

- `ProjectElementShadowConfig` stable ;
- `footprint` ;
- profile id ;
- opacity / offset / scale utiles.

Heuristique V0 :

- tall-thin : lampadaire, poteau ;
- building-large : maison, centre, gros batiment ;
- wide-low : stand, kiosque ;
- small-square : panneau, petit prop ;
- tiny-natural : ne pas forcer une ombre si element trop petit ou decor naturel identifiable.

Important :

- l'activation de `Projette une ombre` peut remplir automatiquement une suggestion si aucune config utile n'existe ;
- un bouton `Calculer automatiquement` permet de recalculer l'element courant ;
- pas d'ecriture silencieuse au chargement du projet.

## 6. Lots proposes

## Shadow-35 — Static Shadow Projection Geometry Core V0

But :

Creer la geometrie pure de projection polygonale.

Fichiers a creer :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

Fichiers a modifier :

```text
packages/map_core/lib/map_core.dart
```

Changements :

- ajouter `ProjectedStaticShadowPoint` ;
- ajouter `ProjectedStaticShadowGeometry` ;
- ajouter `StaticShadowProjectionPreset` ou equivalent non persistant ;
- ajouter `resolveProjectedStaticShadowGeometry(...)` ;
- utiliser `ResolvedStaticShadowGeometry` comme base ;
- calculer un quadrilatere ferme ;
- valider valeurs finies ;
- tester direction bas-droite, bas-gauche, longueur nulle, taper.

Pourquoi :

Runtime et editor doivent partager la meme projection. Sinon divergence garantie.

Non-objectifs :

- pas de runtime ;
- pas d'editor ;
- pas de JSON ;
- pas de lumiere persistante.

## Shadow-36 — Runtime Projected Shadow Instruction / Renderer V0

But :

Permettre au runtime de dessiner autre chose qu'un ovale.

Fichiers a modifier :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

Changements :

- ajouter `ShadowRuntimeShapeKind.projectedPolygon` ;
- ajouter `ShadowRuntimePoint` ;
- ajouter `polygonPoints` dans `ShadowRuntimeRenderInstruction` ;
- renderer `projectedPolygon` via `ui.Path` + `canvas.drawPath(...)` ;
- conserver `drawOval(...)` pour `ellipse` et `contactBlob` ;
- ajouter tests pixels : interieur polygon opaque, exterieur transparent, opacity 0 transparente.

Pourquoi :

La reference utilisateur est impossible a atteindre avec `drawOval(...)` seul.

Non-objectifs :

- pas d'integration static placed encore ;
- pas d'editor ;
- pas de blur ;
- pas de nouveau Flame Component.

## Shadow-37 — Runtime Static Object Projection Integration V0

But :

Faire produire des `projectedPolygon` aux static placed elements.

Fichiers a modifier :

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Changements :

- garder `actorContact` intact ;
- pour `groundStatic`, appeler la projection core apres `resolveStaticShadowGeometry(...)` ;
- produire une instruction `projectedPolygon` ;
- conserver `mode none` -> null ;
- conserver les validations `groundStatic` ;
- verifier que footprint element/override influe sur le polygon ;
- verifier ordre runtime inchange.

Pourquoi :

Visible dans le jeu. Corrige maisons/lampadaires/panneaux cote runtime.

Non-objectifs :

- pas de modele persistant ;
- pas de MapLayersComponent sauf surprise ;
- pas d'editor preview.

## Shadow-38 — Editor Static Projected Shadow Preview V0

But :

Afficher la meme ombre projetee dans le canvas editor.

Fichiers a modifier :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Changements :

- ajouter les points polygonaux a `EditorStaticShadowPreviewInstruction` ;
- utiliser la projection core ;
- painter `drawPath(...)` pour static projected shadows ;
- garder l'ordre sol/surfaces -> shadows -> placed elements ;
- garder `drawOval(...)` seulement pour les previews qui restent ovales.

Pourquoi :

L'auteur doit voir exactement ce que runtime va rendre.

Non-objectifs :

- pas de panel UI ;
- pas de modele ;
- pas de runtime.

## Shadow-39 — Element Auto Shadow Suggestion V0

But :

Ne plus demander a l'utilisateur de deviner les valeurs.

Fichiers a creer :

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
reports/shadows/shadow_lot_39_element_auto_shadow_suggestion.md
```

Fichiers a modifier :

```text
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
```

Changements :

- calculer une config depuis `ProjectElementEntry.frames.first.source` ;
- classer l'objet par dimensions : haut-fin, large, gros batiment, petit prop ;
- bouton `Calculer automatiquement` ;
- activation de `Projette une ombre` remplit une suggestion si shadow null ;
- preservation des champs existants sauf recalcul explicite ;
- tests lampadaire, maison, panneau, kiosque.

Pourquoi :

Le probleme produit est l'absence d'automatisation. Ce lot corrige l'authoring element par element.

Non-objectifs :

- pas de batch projet ;
- pas de runtime ;
- pas de nouveaux modeles.

## Shadow-40 — Bulk Auto Shadow Repair V0

But :

Corriger automatiquement un projet existant sans ouvrir chaque element.

Fichiers probables :

```text
packages/map_editor/lib/src/application/shadow/project_auto_shadow_repair.dart
packages/map_editor/test/application/shadow/project_auto_shadow_repair_test.dart
packages/map_editor/lib/src/ui/panels/tileset_palette/tileset_palette_panel.dart
packages/map_editor/test/features/tileset_library/tileset_palette_panel_test.dart
reports/shadows/shadow_lot_40_bulk_auto_shadow_repair.md
```

Changements :

- action `Auto-calibrer les ombres du projet` ;
- appliquer les suggestions aux elements actifs sans footprint ou aux elements selectionnes selon UX retenue ;
- ne pas ecraser les overrides d'instance ;
- afficher un resume : modifies, ignores, deja personnalises ;
- tests : elements actifs modifies, configs manuelles preservees, tiny props ignores si regle retenue.

Pourquoi :

Selbrume et les vieux projets ne doivent pas exiger 60 actions manuelles.

Non-objectifs :

- pas d'ecriture silencieuse au chargement ;
- pas de migration JSON ;
- pas de runtime.

## Shadow-41 — Selbrume Visual QA / Golden Slice Shadow Pass V0

But :

Verifier sur les vrais cas utilisateur.

Fichiers probables :

```text
reports/shadows/shadow_lot_41_selbrume_visual_shadow_qa.md
```

Changements :

- captures avant/apres si infra disponible ;
- checks cibles lampadaire / maison / panneau / puits / kiosque ;
- eventuel ajustement mineur des heuristiques de Shadow-39 si tests visuels prouvent un mauvais rendu.

Pourquoi :

Les tests unitaires ne suffisent pas pour juger une ombre RPG.

Non-objectifs :

- pas de nouvelle architecture ;
- pas de lumiere persistante.

## Shadow-42 — Persistent Light / Time-of-Day Decision V0

But :

Decider si l'heure de jour doit devenir une donnee projet/map/runtime.

Fichiers a creer :

```text
reports/shadows/shadow_lot_42_persistent_light_time_of_day_decision.md
```

Questions :

- lumiere globale par projet ou par map ?
- preview editor seulement ou runtime canonique ?
- quelles valeurs persistent ?
- interaction avec Shadow-34 ?

Pourquoi :

La lumiere globale doit venir apres une base d'ombre saine. Sinon on etire des galettes.

## 7. Estimation

Plan recommande :

```text
Shadow-35 : 1 lot
Shadow-36 : 1 lot
Shadow-37 : 1 lot
Shadow-38 : 1 lot
Shadow-39 : 1 lot
Shadow-40 : 1 lot
Shadow-41 : 1 lot
Shadow-42 : optionnel / decision
```

Donc :

- minimum visible propre : 4 lots ;
- automatique utilisable : 6 lots ;
- validation visuelle solide : 7 lots ;
- avec decision time-of-day persistante : 8 lots.

Je recommande 7 lots avant de reparler de lumiere persistante.

## 8. Risques

- `drawPath(...)` hard-edge peut etre trop anguleux si les valeurs sont mauvaises. V0 assume un style pixel-art plat.
- Les heuristiques ne comprendront pas toujours la semantique d'un sprite. D'ou le bouton manuel et le batch avec resume.
- Changer `ShadowRuntimeRenderInstruction` touche plusieurs tests runtime. A faire en lot separe.
- Ajouter une lumiere persistante trop tot figerait un mauvais modele.

## 9. Non-objectifs globaux

Ne pas faire maintenant :

- blur ;
- `saveLayer` ;
- atlas/sprites d'ombre ;
- nouveau Flame Component ;
- Shadow Studio ;
- migration JSON ;
- `WorldLightState` ;
- `timeOfDay` persistant ;
- modification des shadows PNJ/joueur.

## 10. Tests globaux a prevoir

Core :

```bash
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
```

Runtime :

```bash
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Editor :

```bash
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas lib/src/ui/panels/tileset_palette test/application/shadow test/ui/canvas test/features/tileset_library
```

## 11. Validation de la solution

Oui, la direction est bonne si elle est formulee ainsi :

```text
Ombres statiques = projection polygonale directionnelle.
Ombres acteurs = contact blob actuel.
Authoring element = suggestion automatique.
Projet existant = batch repair explicite.
Lumiere persistante = plus tard.
```

Ce n'est pas :

```text
continuer a regler des ovales.
```

La reference utilisateur ne sera pas atteinte par des ellipses mieux calibrees. Elle demande un changement de forme de rendu.

