# NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract

## 1. Résumé exécutif

Statut proposé : **DONE documentaire**.

Ce lot cadre le futur authoring des chemins manuels cinématiques, sans modifier le code produit. La décision retenue pour V1-107 est un modèle stage-local `CinematicManualPath` stocké dans `CinematicStageContext.manualPaths`, composé en V0 uniquement d'une liste ordonnée de références vers des Repères de scène, et possédé en V0 par un bloc `actorMove`.

Règle produit centrale :

```text
La Destination reste le lieu d'arrivée du déplacement.
Le Trajet décrit la manière d'y aller.
Le Chemin manuel est une option de Trajet.
Le Chemin manuel contient uniquement les points de passage intermédiaires.
```

Formule utilisateur cible :

```text
Jean se déplace vers Repère 4 avec un trajet manuel via 2 points.
```

V1-106 ne crée aucun modèle Dart, aucune UI, aucun runtime, aucun playback, aucune Visual Gate et aucun changement Xcode.

## 2. Gate 0

Commandes demandées au démarrage :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
50c1bba6 update selbrume
4523a1e0 update selbrume
530bbc33 build(macos): add BUILD-MACOS-01 documentation and roadmap
97509364 doc(narrativeStudio): split V1-104-bis Xcode modifications to BUILD-MACOS-01
fc0b2d74 doc(narrativeStudio): close NS-SCENES-V1-104 and compile evidence pack
9fc7bc5c build(macos): bump minimum macOS deployment target to 12.0
dc9859c1 feat(narrative_studio): implement V1-104 - Cinematic ActorMove Target from Stage Points
```

Interprétation :

- `git status --short --untracked-files=all` : sortie vide au démarrage ;
- `git diff --stat` : sortie vide au démarrage ;
- `git diff --name-only` : sortie vide au démarrage ;
- branche : `main`.

## 3. Fichiers lus

Règles :

- `AGENTS.md` : présent et lu ;
- `agent_rules.md` : présent et lu ;
- `codex_rule.md` : présent et lu ;
- `codex_rules.md` : absent, écart documenté.

Rapports et roadmaps :

- `reports/narrativeStudio/scenes/ns_scenes_v1_100_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability_evidence_repair.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_103_bis_actor_initial_placement_stage_point_evidence_visual_truth_closure.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_scope_repair.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Code lu en lecture seule :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`

Tests lus en lecture seule :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`
- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

Tous les fichiers obligatoires ci-dessus existent, sauf `codex_rules.md`.

## 4. Contexte V1-100 à V1-105

V1-100 a cadré l'édition spatiale cinématique et a déjà identifié les chemins manuels comme un futur contrat, sans modèle.

V1-101 a introduit `CinematicStagePoint` dans `CinematicStageContext.stagePoints`, avec JSON backward-compatible, ordre stable, description facultative et diagnostics de base.

V1-102 et V1-102-bis ont rendu les Repères manipulables dans la preview et découvrables côté UX.

V1-103 a permis le placement initial d'un acteur depuis un Repère.

V1-104 a permis à une Destination d'actorMove de référencer un Repère via `CinematicMovementTargetBindingKind.stagePoint`.

V1-105 a clarifié le vocabulaire visible : `Repère` pour l'espace, `Destination` pour l'arrivée, `Marqueur temps` pour la timeline, `Trajet` / `Chemin` pour la manière d'aller vers la destination.

V1-106 doit donc éviter de réintroduire `Cible`, `Point abstrait`, `Point de scène`, `binding`, `sourceId`, `targetId` comme vocabulaire utilisateur principal.

## 5. Problème produit

Aujourd'hui, un auteur peut dire :

```text
Jean démarre sur Repère 1.
Jean va vers Repère 4.
```

Il ne peut pas encore dire dans un seul bloc lisible :

```text
Jean va vers Repère 4,
en passant d'abord par Repère 2,
puis Repère 3.
```

Le système actuel permet de créer plusieurs blocs `actorMove` successifs, mais cela allonge le Déroulé, fragmente l'intention et rend la relecture moins claire. Le besoin produit est donc de représenter un trajet manuel comme propriété authoring d'un déplacement, pas comme playback runtime.

## 6. Passes d'audit A-G

### Pass A — Audit Stage Points / Stage Context

Objectif : vérifier si les Repères sont déjà un socle stable pour des points de passage.

Éléments lus :

- `CinematicStageContext`
- `CinematicStagePoint`
- opérations `addCinematicStagePoint`, `updateCinematicStagePoint`, `removeCinematicStagePoint`
- diagnostics Stage Point existants

Constats :

- `CinematicStageContext` stocke déjà `stagePoints` à côté des placements et destinations.
- `CinematicStagePoint` possède `id`, `label`, `x`, `y`, `description?`.
- Les opérations existantes valident l'id, le label, les coordonnées finies et les doublons.
- Les diagnostics actuels détectent Repères sans map, id vide, label vide, duplicats, coordonnées invalides ou hors map.

Risques :

- stocker des coordonnées inline dans un chemin dupliquerait les Repères ;
- supprimer un Repère peut casser plusieurs usages futurs ;
- le vocabulaire technique `Stage Point` reste dans le code, mais l'UX doit dire `Repère`.

Verdict : les Repères de scène sont le bon support V0 pour les points de passage.

### Pass B — Audit actorMove / Destination / pathMode

Objectif : vérifier comment un déplacement acteur est représenté aujourd'hui.

Éléments lus :

- `CinematicTimelineStepKind.actorMove`
- `CinematicMovementTargetRef`
- `CinematicMovementTargetBinding`
- `CinematicTimelineActorPathMode`
- `_buildActorMoveStep`
- `updateCinematicTimelineActorMoveStep`
- diagnostics actorMove

Constats :

- `actorMove` garde `actorId`, `targetId`, `durationMs` et metadata authoring.
- `CinematicTimelineActorPathMode` ne contient aujourd'hui que `direct`.
- `_buildActorMoveStep` écrit toujours `actor.pathMode = direct`.
- `isCinematicTimelineActorMoveStep` exige actuellement `pathMode == direct`.
- `movementTargetBinding` résout la Destination vers position libre, personnage/objet de map, déclencheur de map ou Repère.
- Les diagnostics refusent tout pathMode différent de `direct`.

Risques :

- ajouter un mode manuel sans adapter le diagnostic rendrait les blocs invalides ;
- mélanger Destination finale et points de passage casserait la clarté V1-105 ;
- stocker le chemin directement dans le step risquerait de gonfler le payload timeline.

Verdict : V1-107 doit étendre prudemment `pathMode` vers `manual`, mais la Destination finale doit rester portée par le mécanisme existant de Destination.

### Pass C — Options modèle / stockage

Objectif : comparer les stratégies de stockage.

Éléments lus :

- `CinematicStageContext`
- `CinematicTimelineStep`
- roadmaps V1-100 à V1-105

Constats :

- Stage Context est déjà le lieu des données spatiales authoring.
- Timeline est le lieu des actions temporelles.
- Les Repères et les bindings de Destination sont stage-local, pas globaux projet.

Risques :

- un modèle réutilisable trop tôt créerait une bibliothèque interne de chemins ;
- un modèle inline trop simple serait difficile à diagnostiquer globalement ;
- un ownership flou créerait des chemins orphelins.

Verdict : retenir un modèle stage-local, mais owned par un `actorMove` en V0.

### Pass D — UX no-code / vocabulary review

Objectif : garantir que le contrat respecte V1-105.

Éléments lus :

- rapport V1-105 ;
- libellés Builder actuels ;
- prompt V1-106.

Constats :

- `Repère` est spatial.
- `Marqueur temps` est temporel.
- `Destination` est l'arrivée.
- `Trajet` est la manière d'aller vers la Destination.
- `Chemin manuel` est une option de Trajet.

Risques :

- réintroduire `Cible` brouillerait la distinction Destination/Trajet ;
- utiliser `Repère temporel` pour la timeline brouillerait spatial/temporel ;
- exposer `manualPathId` ou `targetId` casserait l'expérience no-code.

Verdict : l'UX doit parler de `Trajet direct`, `Trajet manuel`, `Points de passage`, jamais de `binding` ou d'id.

### Pass E — Diagnostics / validation future

Objectif : cadrer les futurs diagnostics sans les coder.

Éléments lus :

- `cinematic_diagnostics.dart`
- diagnostics Stage Point et actorMove existants

Constats :

- les diagnostics existants ont severity, code, message, target, suggestedFixLabel.
- les diagnostics actuels bloquent déjà actorMove invalide.
- plusieurs messages existants contiennent encore `Stage Point` ou `binding`, mais V1-107/V1-108 devront présenter des messages utilisateur plus doux.

Risques :

- un chemin manuel avec Repère supprimé pourrait paraître valide si la validation ne traverse pas les références ;
- un chemin vide en mode manuel serait une fausse fonctionnalité ;
- un chemin orphelin pourrait rester dans `StageContext`.

Verdict : V1-107 doit ajouter diagnostics core, et V1-108 doit les reformuler en vocabulaire utilisateur.

### Pass F — Runtime anti-scope

Objectif : protéger le lot et la suite immédiate contre un démarrage runtime prématuré.

Éléments lus :

- prompt V1-106 ;
- package boundaries AGENTS ;
- historique V1-40 et V1-100+.

Constats :

- le Cinematic Runtime Adapter existe mais le playback visuel de chemins n'est pas ouvert.
- V1-106 est explicitement documentaire.
- V1-107 doit être core model V0, pas playback.

Risques :

- utiliser le mot `path` peut attirer pathfinding/collision/interpolation ;
- afficher une ligne dans la preview peut être confondu avec exécution runtime ;
- des champs `currentTimeMs` ou `playbackTimeMs` seraient hors scope.

Verdict : aucun runtime, Flame, timer, interpolation, pathfinding ou GameState avant un lot playback dédié.

### Pass G — Final architecture decision

Objectif : trancher V1-107.

Verdict :

```text
V1-107 doit créer un modèle core authoring-only :
CinematicManualPath dans CinematicStageContext.manualPaths.
V0 : liste ordonnée de waypointStagePointIds.
V0 : chemin owned par actorMove via ownerActorMoveStepId.
actorMove garde targetId comme Destination finale.
pathMode peut devenir direct/manual.
```

## 7. Options comparées

| Option | Description | Avantages | Risques | Verdict |
|---|---|---|---|---|
| A | Chemin inline dans actorMove | Simple, proche du bloc, suppression avec le bloc. | Gonfle le step, diagnostics moins centralisés, duplication dans timeline. | Refusée pour V0 comme stockage principal. |
| B | `CinematicStageContext.manualPaths` réutilisable | Centralisé, nommable, diagnostics propres, réutilisable. | Trop de complexité, risque de mini-library et d'IDs exposés. | Trop large pour V0 si réutilisable. |
| C | Chemin stage-local owned par actorMove | Centralisation + ownership clair, suppression synchronisée, diagnostics stage-level. | Nécessite gérer orphelins et ownerStepId. | Retenue avec D. |
| D | Suite de Repères uniquement | Cohérent V1-101/V1-105, pas de duplication de coordonnées, le trajet suit si un Repère bouge. | L'auteur doit créer des Repères pour les points intermédiaires. | Retenue pour V0. |
| E | Points de passage dédiés | Souple, points anonymes possibles. | Double les Repères, UX plus difficile, validation plus lourde. | Refusée V0, possible V2 si besoin prouvé. |
| F | Coordonnées libres inline | Apparente simplicité technique. | Mauvais no-code, duplication, casse silencieuse, pas aligné Repères. | Refusée V0. |
| G | Aucun modèle, actorMove multiples | Déjà faisable partiellement, pas de nouveau modèle. | Déroulé plus long, pas d'objet trajet, édition/relecture faibles. | Fallback temporaire, pas solution cible. |

Décision : **Option C + D**.

## 8. Décision retenue

Nom recommandé du futur modèle :

```text
CinematicManualPath
```

Nom utilisateur :

```text
Chemin manuel
```

Emplacement :

```text
CinematicStageContext.manualPaths
```

Relation avec Stage Context :

- le chemin est une donnée spatiale authoring-local ;
- il appartient à la cinématique, pas au projet global ;
- il est validé avec les Repères et la map stage.

Relation avec Repères :

- V0 référence uniquement des `CinematicStagePoint.id` ;
- les coordonnées ne sont pas dupliquées ;
- renommer ou déplacer un Repère met à jour l'affichage du trajet par résolution dynamique.

Relation avec actorMove :

- actorMove conserve son acteur, sa durée, son mode marche/course et sa Destination finale ;
- actorMove peut passer de `Trajet direct` à `Trajet manuel` ;
- en V0, chaque chemin manuel est owned par un actorMove via `ownerActorMoveStepId`.

Relation avec Destination :

- Destination finale reste portée par l'existant (`targetId` côté step et résolution par binding côté Stage Context) ;
- le chemin manuel ne contient pas la Destination finale ;
- le chemin manuel contient seulement les points de passage intermédiaires.

Relation avec `pathMode` :

- `direct` reste le défaut ;
- V1-107 peut ajouter un futur mode conceptuel `manual` ;
- le mode manuel est invalide sans chemin manuel assigné et valide ;
- si le chemin est supprimé, l'authoring doit soit revenir à `Trajet direct`, soit produire un diagnostic bloquant.

Ownership / suppression :

- V0 : un chemin manuel est possédé par un seul actorMove ;
- supprimer l'actorMove supprime son chemin ;
- supprimer un chemin depuis l'inspecteur revient à repasser le bloc en `Trajet direct` ;
- un chemin sans owner est un diagnostic `manualPathOrphaned`.

JSON backward-compatible attendu :

- ancien JSON sans `manualPaths` se lit comme liste vide ;
- les actorMove existants restent `direct` ;
- aucun migration destructive ;
- ordre des points de passage stable dans la liste.

## 9. Vocabulaire utilisateur

Vocabulaire principal :

- `Destination` : lieu d'arrivée ;
- `Déplacement` : action de l'acteur ;
- `Trajet` : manière d'aller vers la Destination ;
- `Trajet direct` : déplacement sans points de passage ;
- `Trajet manuel` : déplacement via un Chemin manuel ;
- `Chemin manuel` : liste ordonnée de points de passage ;
- `Point de passage` : Repère utilisé au milieu du trajet ;
- `Repère` / `Repère de scène` : point spatial posé dans l'aperçu ;
- `Marqueur temps` : position temporelle locale dans la timeline ;
- `Problème` : diagnostic visible ;
- `Tout est prêt` : état sans problème.

Termes réservés aux sections techniques :

- `targetId`
- `sourceId`
- `binding`
- `stagePointId`
- `pathMode`
- `manualPathId`

Termes à ne pas remettre comme UX principale :

- `Cible`
- `Point abstrait`
- `Point de scène`
- `Cibles de déplacement`
- `Repère temporel`
- `payload`
- `JSON`

## 10. Relation Destination / Trajet / Repères

Réponses explicites aux questions du prompt :

1. Un chemin manuel cinématique est une liste authoring ordonnée de points de passage spatiaux pour un déplacement acteur.
2. Oui, il doit être stocké dans le Stage Context, car il est spatial et local à la cinématique.
3. Il ne doit pas être inline dans actorMove, mais il doit être owned par actorMove en V0.
4. Oui, la décision retient un objet stage-local owned par actorMove.
5. En V0, il référence uniquement des Repères de scène.
6. Non en V0, pas de coordonnées libres.
7. Non en V0, pas de points de passage dédiés distincts des Repères.
8. Oui, la Destination finale d'actorMove reste séparée du chemin.
9. Non, le dernier point du chemin n'est pas la Destination finale ; il est le dernier point intermédiaire.
10. On évite les duplications en stockant des références de Repères, pas des coordonnées.
11. Un Repère supprimé déclenche un diagnostic sur les chemins qui l'utilisent.
12. La timeline affiche un résumé : `Jean se déplace vers Repère 4 via 2 points`.
13. La preview peut afficher une ligne authoring-only `départ -> points de passage -> destination`.
14. L'auteur ajoute, retire et réordonne des points de passage via l'inspecteur actorMove.
15. V1-107 peut commencer par le modèle, les opérations et diagnostics purs, sans runtime.

Cas de divergence :

- si le dernier point de passage n'est pas proche de la Destination, ce n'est pas une erreur en soi ;
- la preview montre explicitement le segment final vers la Destination ;
- si la Destination n'est pas résoluble spatialement, le chemin manuel devient incompatible pour l'affichage spatial et doit produire `actorMoveManualPathIncompatibleTarget`.

## 11. Relation actorMove / pathMode / movementTargetBinding

Contrat futur :

- `actorMove.targetId` reste la référence de Destination finale ;
- `movementTargetBinding` continue de résoudre cette Destination ;
- `pathMode` devient conceptuellement `direct` ou `manual` ;
- `direct` est le défaut et conserve tout comportement existant ;
- `manual` exige un `manualPathId` ou une relation owner unique entre le step et un `CinematicManualPath` ;
- `movementTargetBinding` ne doit pas être remplacé par le chemin manuel ;
- changer la Destination ne supprime pas automatiquement les points de passage ;
- changer vers `Trajet direct` désactive/détache ou supprime le chemin owned selon opération choisie.

Recommandation V1-107 :

```text
CinematicTimelineActorPathMode.direct reste par défaut.
CinematicTimelineActorPathMode.manual peut être ajouté.
Le lien actorMove -> manual path doit rester authoring-only.
```

Si le chemin manuel est supprimé :

- suppression depuis l'UI du bloc : repasser à `Trajet direct` ;
- suppression externe ou incohérence de données : diagnostic `actorMoveManualPathMissing` bloquant ;
- chemin orphelin sans actorMove : diagnostic `manualPathOrphaned` warning ou error selon politique de cleanup.

## 12. Pseudo-modèle recommandé pour V1-107

Pseudo-modèle documentaire, non Dart :

```text
CinematicManualPath
- id: identifiant stable interne
- label: nom utilisateur, ex. "Trajet de Jean"
- description?: note optionnelle
- ownerActorMoveStepId: id interne du bloc actorMove propriétaire en V0
- waypointStagePointIds: liste ordonnée de Repères intermédiaires
```

Extension conceptuelle du Stage Context :

```text
CinematicStageContext
- actorBindings
- actorAppearanceBindings
- initialPlacements
- movementTargetBindings
- stagePoints
- manualPaths
```

Extension conceptuelle actorMove :

```text
actorMove
- pathMode: direct | manual
- manualPathId?: référence interne authoring vers CinematicManualPath
- targetId: Destination finale existante, conservée
```

Champs utilisateur-facing :

- `label`
- `description`
- liste des Repères résolus en labels

Champs internes :

- `id`
- `ownerActorMoveStepId`
- `manualPathId`
- `waypointStagePointIds`

Contraintes :

- id non vide et unique dans `manualPaths` ;
- owner non vide en V0 ;
- owner doit référencer un actorMove existant ;
- la liste doit contenir au moins un point pour être utile ;
- les Repères doivent exister ;
- doublons dans la liste à warning minimum ;
- ordre stable et sérialisé tel quel.

## 13. Diagnostics futurs

| Code recommandé | Severity | Condition | Message utilisateur | Effet authoring | Runtime futur | Package futur | Tests futurs |
|---|---|---|---|---|---|---|---|
| `manualPathEmpty` | error si pathMode manual, warning si brouillon non assigné | chemin manuel sans point de passage | `Le trajet manuel ne contient aucun point de passage.` | bloquer validation du bloc manuel | bloquant | `map_core` | modèle + diagnostics |
| `manualPathStagePointMissing` | error | un point de passage référence un Repère supprimé | `Le trajet manuel utilise un repère qui n'existe plus.` | demander remplacement/retrait | bloquant | `map_core` | suppression Repère référencé |
| `manualPathStagePointDuplicate` | warning | même Repère répété dans un chemin | `Le même repère apparaît plusieurs fois dans le trajet manuel.` | autoriser avec avertissement | non bloquant sauf politique V2 | `map_core` | doublon liste |
| `manualPathWithoutStageMap` | warning | chemins présents sans map stage | `Le trajet manuel a besoin d'une map de scène pour être vérifié visuellement.` | afficher preview limitée | potentiellement bloquant playback | `map_core` | cinématique sans map |
| `manualPathStagePointOutOfMap` | error | Repère du chemin hors limites | `Un repère du trajet manuel est en dehors de la map.` | bloquer validation | bloquant | `map_core` | mapWidth/mapHeight |
| `actorMoveManualPathMissing` | error | actorMove en trajet manuel sans chemin assigné | `Ce déplacement est en trajet manuel, mais aucun chemin n'est défini.` | revenir direct ou créer chemin | bloquant | `map_core` | pathMode manual sans path |
| `actorMoveManualPathIncompatibleTarget` | error | Destination finale non résoluble spatialement pour preview manuelle | `La destination de ce déplacement ne peut pas être reliée au trajet manuel.` | choisir Destination résoluble ou direct | bloquant playback visuel | `map_core` + editor read model | destination cassée |
| `actorMoveManualPathTooShort` | warning ou error selon UX | trajet manuel avec moins d'un point utile | `Ajoutez au moins un point de passage ou repassez en trajet direct.` | guider l'auteur | bloquant si manual strict | `map_core` | liste vide/unique selon règle |
| `actorMoveManualPathCycleWarning` | warning | trajet revient plusieurs fois sur les mêmes Repères | `Le trajet manuel revient sur un repère déjà utilisé.` | autoriser mais signaler | non bloquant | `map_core` | répétition non adjacente |
| `actorMoveManualPathUnused` | warning | chemin valide non utilisé par son owner | `Ce chemin manuel n'est utilisé par aucun déplacement.` | proposer suppression | non bloquant | `map_core` | path non référencé |
| `manualPathOrphaned` | warning puis error si owner inexistant | ownerActorMoveStepId absent de la timeline | `Un trajet manuel n'est plus lié à un déplacement.` | proposer suppression | non bloquant tant que non exécuté | `map_core` | suppression actorMove |

Messages techniques internes peuvent porter des ids dans `referenceId`, mais les messages utilisateur doivent rester sans `targetId`, `sourceId`, `binding`, `JSON`.

## 14. Opérations pures futures

| Opération | Entrée | Sortie | Validations | Erreurs attendues | Impact |
|---|---|---|---|---|---|
| `addCinematicManualPath` | project, cinematicId, ownerActorMoveStepId, label?, waypointStagePointIds | `CinematicStageContextAuthoringResult` ou résultat dédié | cinématique existe, owner actorMove existe, Repères existent, id unique | owner inconnu, Repère inconnu, doublon id | ajoute dans Stage Context et peut mettre actorMove en manual |
| `renameCinematicManualPath` | project, cinematicId, manualPathId, label, description? | résultat dédié | path existe, label non vide | path inconnu, label vide | met à jour label/description |
| `removeCinematicManualPath` | project, cinematicId, manualPathId, mode cleanup | résultat dédié | path existe | path inconnu, path utilisé sans cleanup | supprime path, peut repasser actorMove en direct |
| `addManualPathStagePoint` | project, cinematicId, manualPathId, stagePointId, index? | résultat dédié | path et Repère existent | Repère inconnu, index invalide | ajoute un point de passage |
| `removeManualPathStagePoint` | project, cinematicId, manualPathId, index ou stagePointId occurrence | résultat dédié | occurrence existe | index invalide | retire un passage sans supprimer le Repère |
| `reorderManualPathStagePoint` | project, cinematicId, manualPathId, fromIndex, toIndex | résultat dédié | indices valides | index hors limites | réordonne liste stable |
| `updateActorMovePathMode` | project, cinematicId, stepId, mode | `CinematicTimelineStepUpdateResult` | step actorMove existe, mode valide | step inconnu, mode incompatible | bascule direct/manual |
| `assignManualPathToActorMove` | project, cinematicId, stepId, manualPathId | résultat dédié | owner compatible, actorMove existe | owner mismatch, path inconnu | lie le chemin au déplacement |
| `clearActorMoveManualPath` | project, cinematicId, stepId, cleanupPath bool | résultat dédié | step actorMove existe | step inconnu | revient au Trajet direct |

Tests futurs :

- JSON ancien sans `manualPaths` ;
- ajout/suppression/rename/reorder ;
- owner actorMove supprimé ;
- Repère supprimé ;
- pathMode direct inchangé ;
- pathMode manual invalide sans path ;
- diagnostics listés ci-dessus.

## 15. UX future V1-108

### Inspecteur actorMove

Structure cible :

```text
Déplacement de Jean

Destination
Repère 4

Trajet
○ Direct
● Manuel

Points de passage
1. Repère 1
2. Repère 2
3. Repère 3

[Ajouter un repère au trajet]
```

Contrat UX :

- l'auteur choisit `Direct` ou `Manuel` dans l'inspecteur du déplacement ;
- passer à `Manuel` crée un chemin owned par le bloc si aucun n'existe ;
- `Ajouter un repère au trajet` ouvre un picker de Repères existants ;
- réordonnancement par boutons haut/bas en V0, drag éventuel plus tard ;
- suppression retire seulement le point de passage, pas le Repère ;
- empty state : `Ajoutez un repère au trajet ou repassez en trajet direct.`;
- retour à direct demande si le chemin doit être supprimé.

### Preview

Contrat visuel futur :

- ligne authoring-only entre position de départ, points de passage et Destination ;
- points de passage numérotés ;
- style distinct des Repères eux-mêmes ;
- sélection du bloc met en évidence son trajet ;
- V0 peut être non interactif, l'édition restant dans l'inspecteur ;
- aucune interpolation, aucun playback.

### Timeline

Contrat timeline futur :

- un actorMove reste un seul bloc ;
- label compact : `Jean -> Repère 4` ;
- détail/tooltip : `Trajet manuel via 3 points` ;
- pas de multiplication automatique en plusieurs blocs ;
- le Déroulé reste lisible au niveau intention, pas micro-steps.

### Gestion des Repères

Contrat futur :

- un Repère utilisé dans un trajet doit afficher ses usages ;
- suppression d'un Repère utilisé : confirmation forte ou blocage V0 recommandé ;
- rename du Repère met à jour les labels partout par résolution dynamique ;
- déplacement d'un Repère met à jour le trajet dynamiquement.

## 16. Tests futurs V1-107/V1-108

V1-107 core :

- `CinematicStageContext` lit ancien JSON sans `manualPaths` ;
- `CinematicManualPath` sérialise/désérialise ordre et description ;
- opération add path crée un path owned par actorMove ;
- opération remove actorMove path nettoie le Stage Context ;
- diagnostics Repère manquant, doublon, hors map, owner orphelin ;
- actorMove direct existant reste valide.

V1-108 editor :

- inspector actorMove affiche Trajet direct par défaut ;
- bascule manuel crée/assigne un chemin sans exposer id ;
- ajout de point via picker Repère ;
- reorder haut/bas ;
- suppression point de passage ;
- retour direct ;
- preview affiche ligne et numéros en mode selected ;
- timeline affiche `via N points`.

Non-régressions :

- V1-105 vocabulaire conservé ;
- `Marqueur temps` reste temporel ;
- `Destination` reste arrivée ;
- anciens actorMove directs restent modifiables.

## 17. Anti-scope runtime/playback/Flame

Explicitement hors scope :

- runtime cinematic playback ;
- Flame ;
- `PlayableMapGame` ;
- timer ;
- interpolation ;
- pathfinding ;
- collision ;
- movement execution ;
- animation tick ;
- `currentTimeMs` ;
- `playbackTimeMs` ;
- `isPlaying` ;
- `GameState` ;
- save/load ;
- runtime actor movement.

Le chemin manuel reste un artefact d'authoring jusqu'à ouverture explicite d'un lot playback/runtime.

## 18. Roadmap update

Roadmaps mises à jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Changement attendu :

```text
NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract | DONE
Prochain lot recommandé : NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0
```

Décalage V1-105 préservé :

```text
V1-106 : Manual Path Authoring Prep Contract
V1-107 : Manual Path Core Model V0
V1-108 : Manual Path Drawing UI V0
V1-109 : Cinematic Preview Playback Prep Contract
```

## 19. Commandes exécutées

Commandes Git lecture seule :

```text
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Commandes d'audit :

```text
sed -n '1,260p' /Users/karim/.codex/attachments/6480da04-86b1-41d3-8306-5e4de4d502c9/pasted-text.txt
sed -n '261,620p' /Users/karim/.codex/attachments/6480da04-86b1-41d3-8306-5e4de4d502c9/pasted-text.txt
sed -n '621,980p' /Users/karim/.codex/attachments/6480da04-86b1-41d3-8306-5e4de4d502c9/pasted-text.txt
sed -n '981,1320p' /Users/karim/.codex/attachments/6480da04-86b1-41d3-8306-5e4de4d502c9/pasted-text.txt
for f in AGENTS.md agent_rules.md codex_rule.md codex_rules.md; do ...; done
for f in [rapports obligatoires]; do ...; done
for f in [code/tests obligatoires]; do ...; done
rg -n "class CinematicStageContext|class CinematicStagePoint|CinematicActorInitialPlacement|CinematicMovementTargetBinding|CinematicTimelineActorMovementMode|CinematicTimelineActorPathMode|actorMove|pathMode|movementTargetBinding|stagePoints|movementTargetBindings" ...
rg -n "stagePoint|stagePoints|actorMove|pathMode|movementTarget|Destination|Repère|Trajet|Marqueur|timeline|lane|visualDuration|target" ...
```

Tests Dart/Flutter :

```text
Aucun test Dart/Flutter lancé : lot documentaire, aucun fichier package modifié.
```

Build :

```text
Aucun build lancé : lot documentaire, aucun code produit modifié.
```

## 20. git diff --check/stat/name-only/status final

Commande :

```text
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```text
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```text
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md        | 15 ++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md     | 19 ++++++++++++++++---
 2 files changed, 30 insertions(+), 4 deletions(-)
```

Commande :

```text
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_106_evidence_pack.md
```

Fichiers modifiés :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers créés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_106_evidence_pack.md`

Contenu complet des fichiers créés :

- le contenu complet du rapport principal est le présent fichier ;
- le contenu complet de l'Evidence Pack est dans `reports/narrativeStudio/scenes/ns_scenes_v1_106_evidence_pack.md` ;
- aucun fichier binaire, screenshot ou Visual Gate n'a été créé.

## 21. Risques restants

- `ownerActorMoveStepId` peut être trop strict si l'équipe veut réutiliser des chemins entre plusieurs déplacements ; ce choix est volontairement V0.
- Une liste de Repères uniquement peut obliger l'auteur à créer des Repères pour des points intermédiaires très ponctuels ; c'est assumé pour éviter les coordonnées libres.
- Le futur affichage preview devra résoudre la position de départ de l'acteur ; V1-106 ne tranche pas tous les cas d'acteur sans placement résolu.
- Les messages core existants utilisent encore parfois des termes techniques ; V1-107/V1-108 devront humaniser sans casser les codes internes.

## 22. Auto-critique

Ce qui est tranché :

- stockage stage-local ;
- points de passage = Repères uniquement en V0 ;
- Destination finale séparée du chemin ;
- pathMode futur direct/manual ;
- ownership actorMove en V0 ;
- pas de runtime/playback.

Ce qui reste incertain :

- le lien actorMove -> manual path doit-il être un champ direct du step ou une metadata authoring ? V1-107 devra choisir selon les conventions `CinematicTimelineStep`.
- suppression d'un Repère utilisé : blocage strict ou confirmation destructive ; le contrat recommande le blocage V0 mais laisse la décision UI finale à V1-108.
- `manualPathTooShort` doit-il être error ou warning pour les brouillons non assignés.

Ce qui pourrait être sur-designé :

- `label` et `description` sur un chemin owned par actorMove peuvent sembler lourds ; ils restent utiles pour diagnostics et inspector.

Ce qui pourrait être trop limité :

- refuser les coordonnées libres force l'usage de Repères même pour un point temporaire. C'est volontaire pour préserver l'UX no-code et éviter les duplications.

Respect V1-105 :

- oui : Repère spatial, Marqueur temps temporel, Destination comme arrivée, Trajet comme manière d'y aller.

V1-107 peut commencer sans ambiguïté :

- oui, à condition de rester core model/operations/diagnostics, sans UI et sans runtime.

Besoin d'un bis documentaire :

- pas nécessaire avant V1-107, sauf si l'équipe veut absolument des chemins réutilisables entre plusieurs actorMove dès V0.

## 23. Verdict final

```text
NS-SCENES-V1-106 : DONE documentaire.
Chemins manuels : contrat cadré.
Destination / Trajet / Repères : relation clarifiée.
V1-107 : Manual Path Core Model V0 recommandé, non démarré.
Aucun code produit modifié.
Aucun runtime.
Aucun Flame.
Aucun playback.
Aucun changement Xcode.
Aucune Visual Gate.
```

## 24. Prochain lot recommandé

```text
NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0
```

Objectif recommandé :

```text
Ajouter le modèle core authoring-only `CinematicManualPath`, son stockage dans `CinematicStageContext.manualPaths`, les opérations pures minimales et les diagnostics, sans UI, sans runtime et sans playback.
```
