# NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0 — Evidence Pack

## 1. Gate 0 Complet

```text
/Users/karim/Project/pokemonProject
main
d0c4d3f2 feat(narrativeStudio): resolve NS-SCENES-V1-99-bis visual polish and fidelity
2ecd9f5f fix(cinematic): fix centering and coordinate mappings for actor sprite preview renderer, resolve rival south/north animation inversion
c920f5ef feat(map_editor): add cinematic actor sprite preview, refine UI, and update project files
343bb31a doc(cinematics): document cinematic actor display preview sprite resolver contract (V1-97)
de216dc0 feat(cinematics): implement cinematic backdrop real map editor ordering fix (V1-96-bis)
89f172b7 feat(cinematics): implement cinematic backdrop depth / Z-order parity polish V0
0d95818f update selbrume
0ccc4c33 update selbrume
b3477664 feat(map_editor): refine cinematic backdrop preview and update scene reports
e093213f update selbrume
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
adc0b197 update selbrume
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
```

Le working tree était entièrement propre et sans modifications en cours.

## 2. Liste des fichiers lus

Les fichiers du workspace de PokeMap suivants ont été consultés pour l'audit d'architecture :
- `AGENTS.md` (règles de maintenance, validation et Git safety)
- `packages/map_core/lib/src/models/cinematic_asset.dart` (déclaration de `stageContext` et des bindings de cibles de mouvement)
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart` (résolution des coordonnées géométriques d'acteurs de preview)
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart` (formules géométriques du viewport)
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart` (overlay Flutter des acteurs)
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart` (panel principal et gestionnaires de pan/zoom)

## 3. Notes des sub-agents / Passes spécialisées

### Sub-agent A — Current Stage Context Audit
- `stageContext.initialPlacements` : Kind de placements possibles : `unset`, `fromMapEntity` et `fromMovementTarget`.
- `stageContext.movementTargetBindings` : Kind de bindings : `abstractPoint`, `mapEntity` et `mapEvent`.
- `abstractPoint` sert de cible conceptuelle mais génère un avertissement de coordonnées non résolues.
- Insertion : Une liste `stagePoints` de type `CinematicStagePoint` dans `stageContext`.
- Nouveaux types : `CinematicActorInitialPlacementKind.fromStagePoint` et `CinematicMovementTargetBindingKind.stagePoint`.

### Sub-agent B — Viewport Click Mapping Audit
- Conversion : `localOffset` -> Zone carte -> Coordonnées de tuiles.
- Formule avec pan & zoom en mode Vue scène :
  `tileX = (localOffset.dx - frame.left) / (frame.width / mapWidth) + panTiles.dx`
  `tileY = (localOffset.dy - frame.top) / (frame.height / mapHeight) + panTiles.dy`
- Snap à la tuile : `tileX.floor() + 0.5`, stocké en double.

### Sub-agent C — Product UX / Interaction Model
- Outil toolbar preview : Une barre flottante locale contenant l'outil "Sélection" et l'outil "Ajouter un Stage Point".
- Mode Outil (Option C) retenu : Prévient les clics accidentels et les conflits avec le pan. Un clic gauche place un point, bascule l'inspecteur vers l'édition de ce point, puis réactive Sélection.
- Drag-and-drop de points existants sur la grille en mode Sélection.

### Sub-agent D — Data Model Options
- Rejet de l'intégration dans `MapData` (maintient l'isolation cinématique) et des entités temporaires de carte.
- Stockage local ordonné `stagePoints` dans `stageContext`.

### Sub-agent E — Placement / Target Integration
- Résolution directe des positions `(x, y)` dans `_resolvePosition` pour `fromStagePoint`.
- Les timeline steps `actorMove` interpoleront directement vers les coordonnées résolues du Stage Point.

### Sub-agent F — Manual Path Future Contract
- Pas de pathfinding ni d'évitement d'obstacles dynamically en cinématique.
- Tracé séquentiel de Stage Points pour former le chemin `CinematicManualPath`.

### Sub-agent G — Diagnostics / Validation
- 8 diagnostics d'intégrité définis pour prévenir les ID dupliqués, les sorties de carte, et les références orphelines (ex: Stage Point supprimé mais ciblé).

### Sub-agent H — Tests / Visual Gate Future
- Tests JSON, opérations pures d'édition de points et tests widgets de drag-and-drop sur CustomPaint planifiés.

### Sub-agent I — Product Reviewer
- Validation du workflow : L'auteur peut positionner précisément ses décors sans repasser par le Map Editor ou polluer le fichier de carte global.

## 4. Résultats des recherches structurantes (rg)

### Recherche A : CinematicStageContext et bindings
```text
packages/map_core/lib/src/models/cinematic_asset.dart:203:    List<CinematicMovementTargetBinding> movementTargetBindings =
packages/map_core/lib/src/models/cinematic_asset.dart:213:        movementTargetBindings =
packages/map_core/lib/src/models/cinematic_asset.dart:240:      movementTargetBindings: _readObjectList(
packages/map_core/lib/src/models/cinematic_asset.dart:252:  final List<CinematicMovementTargetBinding> movementTargetBindings;
packages/map_core/lib/src/models/cinematic_asset.dart:262:        'movementTargetBindings':
packages/map_core/lib/src/models/cinematic_asset.dart:277:          _listEquals(other.movementTargetBindings, movementTargetBindings);
packages/map_core/lib/src/models/cinematic_asset.dart:285:        Object.hashAll(movementTargetBindings),
```

### Recherche B : Viewport et transformations
```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart:29:final class CinematicMapBackdropViewportTransform {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart:54:  Rect tileRect({required int tileX, required int tileY}) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart:68:  Offset tileCenterBottom({required int tileX, required int tileY}) {
```

### Recherche C : actorMove et cibles
```text
packages/map_core/lib/src/models/cinematic_asset.dart:6:  actorMove,
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:785:    if (step.kind == CinematicTimelineStepKind.actorMove) {
```

## 5. Options comparées et arbitrage final

L'option de stockage des Stage Points sous la forme d'une liste `stagePoints` propre à l'objet `CinematicStageContext` (Option A) a été préférée au stockage inline (Option B) car elle permet de définir des points génériques (comme un waypoint ou un repère de caméra) non associés à un acteur ou une cible de mouvement immédiate. Elle évite également les duplications de coordonnées. Les options de stockage physique dans `MapData` (Option D) et d'entités virtuelles uniquement en mémoire (Option E) ont été formellement rejetées pour respecter l'étanchéité vis-à-vis du Map Editor et préserver la persistance no-code.

## 6. Hunks complets des roadmaps modifiées

### Hunks `reports/narrativeStudio/scenes/road_map_scenes.md`
```diff
@@ -158,14 +158,37 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0 | DONE | Implémentation purement logique et synchrone du résolveur de sprites statiques avec tests unitaires de parité complets sans rendu visuel. |
 | NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0 | DONE | Intégrer les sprites acteurs résolus au rendu de la preview du Cinematic Builder avec fallbacks et gestion de profondeur. |
 | NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0 | DONE | Prouver la fidélité visuelle du rendu avec un vrai sprite de personnage (Timi) et des tests robustes de non-platitude et hors-limites. |
+| NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0 | DONE | Cadrage spatial de la preview du Cinematic Builder : modèle Stage Point décorrélé de MapData/mapEntities/mapEvents, transformation click->tile avec pan/zoom, modèle UX (Option C), intégration avec placements/cibles/timeline et waypoints futurs. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`
+`NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`
 
-Raison : V1-99-bis a consolidé la fidélité visuelle de l'affichage du sprite d'acteur. Le prochain verrou logique est de cadrer le playback temporel et le scrubber interactif local pour la future V1-100.
+Raison : V1-100 a cadré l'édition spatiale. Le prochain verrou logique est d'implémenter la structure de données CinematicStagePoint et sa sérialisation JSON dans map_core de façon backward-compatible, avec validations de diagnostics et opérations pures.
 
-Ordre apres V1-99-bis : `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract` pour le design-first du playback temporel.
+Ordre apres V1-100 :
+1. `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`
+2. `NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0`
+3. `NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0`
+4. `NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0`
+5. `NS-SCENES-V1-105 — Cinematic Manual Path Authoring Prep Contract`
+6. `NS-SCENES-V1-106 — Cinematic Manual Path Core Model V0`
+7. `NS-SCENES-V1-107 — Cinematic Manual Path Drawing UI V0`
+8. `NS-SCENES-V1-108 — Cinematic Preview Playback Prep Contract`
+
+## Mise a jour V1-100
+
+Statut : `NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0` est DONE.
+
+Demande : Cadrer l'édition spatiale des cinématiques directement dans la preview sans repasser par le Map Editor, définir le modèle de stockage local et décorrélé de la map de fond, la transformation géométrique bidirectionnelle écran-carte avec pan/zoom, les modèles d'interactions d'auteur (Option C), les liens avec la timeline (initialPlacements et targets), préparer les chemins manuels sans pathfinding ni collision au runtime, lister les diagnostics et la stratégie de tests.
+
+Decision : Cadrage documentaire complet. Modèle CinematicStagePoint autonome stocké sous stageContext.stagePoints. Formules d'inversion géométrique avec pan/zoom et snapping à la tuile. Interaction via barre d'outils locale (mode outil). Diagnostics statiques complets (8 nouveaux codes) et tests unitaires/widget prévus pour V1-101+.
+
+Preuve : Rapport de contrat ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md rédigé, Evidence Pack complet et roadmaps ajustées. Aucun code packages/ modifié (anti-scope respecté).
+
+Limites : Lot documentaire de cadrage théorique uniquement. Aucun code produit, modèle core, UI ou test créé.
+
+Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.
 
 ## Mise a jour V1-99 bis
@@ -179,7 +202,7 @@ Limites : preview statique de la première frame idle de l'acteur.
 
-Prochain lot exact recommande : `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`.
+Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.
 
 ## Mise a jour V1-99
```

### Hunks `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
```diff
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract
+NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0
 ```
 
 ## Principes
@@ -155,6 +155,20 @@ Limites : V1-94 ne lance toujours pas la cinematique. Aucun runtime, aucun Flame
 
 Prochain lot exact recommande : `NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0`.
 
+## Mise a jour V1-100
+
+Statut : `NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0` est DONE.
+
+Demande : Cadrer l'édition spatiale des cinématiques directement dans la preview sans repasser par le Map Editor, définir le modèle de stockage local et décorrélé de la map de fond, la transformation géométrique bidirectionnelle écran-carte avec pan/zoom, les modèles d'interactions d'auteur (Option C), les liens avec la timeline (initialPlacements et targets), préparer les chemins manuels sans pathfinding ni collision au runtime, lister les diagnostics et la stratégie de tests.
+
+Decision : Cadrage documentaire complet. Modèle CinematicStagePoint autonome stocké sous stageContext.stagePoints. Formules d'inversion géométrique avec pan/zoom et snapping à la tuile. Interaction via barre d'outils locale (mode outil). Diagnostics statiques complets (8 nouveaux codes) et tests unitaires/widget prévus pour V1-101+.
+
+Preuve : Rapport de contrat ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md rédigé, Evidence Pack complet et roadmaps ajustées. Aucun code packages/ modifié (anti-scope respecté).
+
+Limites : Lot documentaire de cadrage théorique uniquement. Aucun code produit, modèle core, UI ou test créé.
+
+Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.
+
 ## Mise a jour V1-99 bis
 
 Statut : `NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0` est DONE.
@@ -167,7 +181,7 @@ Preuve : Tous les tests unitaires et widget dans `cinematic_actor_sprite_preview
 
 Limites : preview statique de la première frame idle de l'acteur.
 
-Prochain lot exact recommande : `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`.
+Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.
 
 ## Mise a jour V1-99
 
@@ -181,7 +195,7 @@ Preuve : 17 tests unitaires de rendu validés dans `cinematic_actor_sprite_previ
 
 Limites : Rendu purement statique et sans playback temporel interactif ni interpolation.
 
-Prochain lot exact recommande : `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`.
+Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.
```

## 7. Sorties Git Finales

### Git Status
```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_100_evidence_pack.md
```

### Git Diff Stat
```text
 reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | 20 +++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md                 | 31 +++++++++++++++++++---
 2 files changed, 44 insertions(+), 7 deletions(-)
```

### Git Diff Check
La commande `git diff --check` s'est exécutée avec succès et n'a renvoyé aucune erreur de formatage (pas d'espace de fin ou de ligne vide orpheline).

## 8. Auto-Review Critique

- Aucun code produit n'a été altéré dans les packages.
- La roadmap a été proprement alignée avec le nouveau jalon d'édition spatiale no-code.
- La logique de conversion géométrique intègre la pan/zoom locale propre au canvas-first.
- Les non-objectifs ont été confirmés (pas d'implémentation logique de playhead, Flame, ou collision).
