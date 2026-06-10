# NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0

Statut : **DONE**

## Description

Ce lot permet d'utiliser un `CinematicStagePoint` existant comme cible de déplacement pour une étape `actorMove` dans la timeline cinématique. Au lieu de restreindre les cibles à des coordonnées géométriques libres (points abstraits), des entités de map (PNJ) ou des événements (triggers), la cible peut désormais être reliée à un Stage Point. Cela permet de centraliser et d'harmoniser le placement initial et les destinations des mouvements de scène sans duplication d'informations, tout en préservant une rétrocompatibilité JSON descendante complète.

De plus, l'édition immuable des bindings nettoie proprement les identifiants sources (`sourceId`) lors des transitions de type de cible afin d'éviter tout identifiant zombie résiduel.

## Scope Réalisé

1. **Modèles Core, Sérialisation et Transitions (`packages/map_core`) :**
   - Ajout du cas `stagePoint` à `CinematicMovementTargetBindingKind` dans `cinematic_asset.dart`.
   - Mise à jour de `_movementTargetBindingRequiresSource` dans `cinematic_authoring_operations.dart` pour forcer la présence d'une source lorsque le binding est de type `stagePoint`.
   - Implémentation de tests de transition robustes garantissant la remise à zéro de `sourceId` lors des changements de types de cible (`stagePoint` -> `abstractPoint`, `mapEntity`, `mapEvent`, ainsi que lors du reset/clear).

2. **Diagnostics Statiques et Cohérence (`packages/map_core` & `packages/map_editor`) :**
   - Implémentation de diagnostics d'authoring dans `cinematic_diagnostics.dart` :
     - `movementTargetBindingStagePointMissing` (Erreur) : Si le point de scène référencé est inexistant ou a été supprimé.
     - `movementTargetBindingStagePointWithoutStageMap` (Avertissement) : Si un point de scène est choisi mais qu'aucune map d'arrière-plan n'est associée.
     - `movementTargetBindingStagePointOutOfMap` (Erreur) : Si le point de scène référencé est en dehors des dimensions géométriques de la carte.
   - Enregistrement et localisation des messages de diagnostic dans `cinematic_stage_preview_readiness.dart`.

3. **Read Models (`CinematicActorDisplayPreviewModel` & `CinematicTimelineLaneReadModel`) :**
   - Résolution géométrique : Si la cible de mouvement est liée à un Stage Point, ses coordonnées sont résolues dynamiquement dans `cinematic_actor_display_preview_model.dart` via le helper `_positionFromStagePoint`.
   - Rendu de la timeline : Dans `cinematic_timeline_lane_read_model.dart`, l'affichage de l'action de mouvement résout le label du point cible (ex : `Professor → Point 2`), ou affiche `[Point de scène manquant]` si l'identifiant n'existe plus.

4. **Interface Utilisateur de l'Inspecteur (`packages/map_editor`) :**
   - Ajout du choix d'option bouton `"Point de scène"` dans la ligne d'édition de cible de mouvement.
   - Si l'option est sélectionnée, affichage des coordonnées en cours et d'un sélecteur d'options `_StagePointSourcePicker` listant tous les Stage Points existants du contexte.
   - Gestion de l'état vide : Affiche `"Aucun Point de scène disponible."` s'il n'y a aucun point configuré.

## Preuves et Validation

### Tests Automatisés
- **Tests Core (`map_core`) :**
  - Validation des résolutions de positions avec cibles de type Stage Point.
  - Validation du formateur de labels de timeline en présence d'un point existant ou manquant.
  - Validation des diagnostics (`missing`, `without map`, `out of bounds`).
  - Validation des transitions sans valeurs zombies.
- **Tests Widget (`map_editor`) :**
  - Validation de l'interaction UI d'association d'une cible de mouvement à un Stage Point et modification immuable du manifeste du projet.

### Rendu Visual Gate
La Visual Gate a été générée via le test de golden file sous :
`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png`

Preuves du fichier généré :
- **Taille** : 304K
- **Format** : PNG image data, 1663 x 926, 8-bit/color RGBA
- **SHA-256 Checksum** : `ffbd6fe9f0ffdf231656f0acffb2007dbae69529449827e43838bf5896087049`

*Note sur les diagnostics de la Visual Gate* : Contrairement à V1-103 où l'actorMove `target_center` générait un avertissement de cible non résolue (binding manquant), la liaison de la cible `Centre scène` au point valide `Point 2` fait disparaître ce diagnostic spécifique de la liste.

## Limites
- Pas de tracé de chemin manuel (prévu au lot V1-106).
- Pas d'interpolation graphique en cours de timeline ou de playback.
- Aucune dépendance runtime / Flame.

## Prochain lot recommandé
`NS-SCENES-V1-105 — Cinematic Manual Path Authoring Prep Contract` : Définir le contrat d'authoring et de structure pour les chemins de mouvement manuels.
