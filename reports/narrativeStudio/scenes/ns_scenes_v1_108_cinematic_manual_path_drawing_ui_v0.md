# NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0

## Résumé exécutif

Le lot **NS-SCENES-V1-108** expose dans le Cinematic Builder les trajets manuels ajoutés côté `map_core` par V1-107 / V1-107-bis.

L'implémentation présente dans le worktree provient majoritairement du passage Gemini, puis a été corrigée à la demande de Karim après revue Codex. Les corrections post-review traitent les points bloquants suivants :

- la Destination finale n'est plus proposée comme Point de passage ;
- le passage en mode Manuel réutilise un `CinematicManualPath` déjà owned par l'`actorMove` au lieu d'échouer silencieusement ;
- le retour en Direct passe par `clearActorMoveManualPath` et nettoie le chemin owned ;
- l'overlay du trajet manuel est peint au-dessus du foreground dans le rendu layer bitmap ;
- le `Colors.white` ajouté dans l'inspecteur a été remplacé par le token `colors.textInverse`.

Ce lot reste strictement **editor-only / authoring-only**. Aucun runtime, Flame, playback, interpolation, pathfinding, collision, save/load runtime ou GameState n'a été ajouté.

## Scope confirmé

Inclus :

- section **Trajet** dans l'inspecteur d'un bloc `actorMove` ;
- bascule Direct / Manuel ;
- création / réutilisation / nettoyage d'un `CinematicManualPath` owned par l'étape sélectionnée ;
- ajout, retrait et réordonnancement V0 de Points de passage basés sur des Repères existants ;
- overlay authoring-only dans la preview pour le trajet sélectionné ;
- tests widget couvrant le flux utilisateur et les régressions post-review.

Exclus :

- playback runtime ;
- déplacement réel d'acteur ;
- interpolation temporelle ;
- pathfinding ;
- collision ;
- modification `map_runtime`, `map_gameplay`, `map_battle` ou host runtime ;
- démarrage du lot V1-109.

## Audit initial

### Contrats existants

- `CinematicManualPath.ownerActorMoveStepId` est la source de vérité du lien vers un `actorMove`.
- Le mode `manual` existe dans `CinematicTimelineActorPathMode`.
- Les opérations core disponibles sont utilisées depuis l'UI :
  - `addCinematicManualPathForActorMove`
  - `addCinematicManualPathWaypoint`
  - `removeCinematicManualPathWaypointAt`
  - `reorderCinematicManualPathWaypoint`
  - `setActorMovePathMode`
  - `clearActorMoveManualPath`
- Le vocabulaire utilisateur reste : Destination finale séparée du Trajet, Points de passage intermédiaires uniquement.

### Risques identifiés en revue

- Le picker de Points de passage listait aussi la Destination finale, ce qui violait le prompt.
- Un état `direct + manualPath owned existant` pouvait bloquer la bascule en Manuel, car l'UI tentait de créer un second path.
- L'overlay layer bitmap était positionné avant le foreground, donc potentiellement masqué.
- Un hardcode `Colors.white` avait été introduit dans l'UI produit.
- Les rapports précédents affirmaient des validations non relancées dans ce tour.

## Fichiers modifiés

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Zones :

- callbacks de mise à jour d'asset cinématique ;
- `_toggleActorMovePathMode` ;
- `_ActorMoveControls` ;
- helper `_destinationStagePointId` ;
- badge numérique de waypoint ;
- picker `PopupMenuButton<CinematicStagePoint>`.

Raisons :

- réutiliser un path owned existant avant de créer un nouveau path ;
- supprimer le chemin owned quand l'auteur repasse en Direct ;
- filtrer la Destination finale du picker de Points de passage ;
- respecter les tokens du design system.

Impact :

- le modèle reste cohérent avec V1-107 ;
- les Points de passage ne dupliquent plus la Destination ;
- les erreurs core ne sont plus avalées dans le cas courant `direct + path existant`.

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`

Zones :

- insertion de `CinematicManualPathPreviewOverlay` dans les stacks de preview bitmap/layer bitmap.

Raison :

- dans le rendu layer bitmap, l'overlay est maintenant peint après le painter foreground.

Impact :

- la ligne authoring-only du trajet manuel reste visible au-dessus de la composition de décor.

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`

Statut :

- fichier créé par le passage V1-108 existant dans le worktree ;
- conservé comme composant overlay editor-only.

Rôle :

- résoudre départ, Points de passage et Destination ;
- dessiner une ligne pointillée non interactive ;
- afficher les badges numérotés des Points de passage.

### `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Zones :

- test `V1-108 — Cinematic Manual Path Drawing UI V0` ;
- nouveau test `V1-108 — manual mode reuses an existing path owned by a direct actorMove`.

Raisons :

- prouver que la Destination n'est plus proposée dans le picker ;
- prouver qu'un path owned existant est réutilisé sans doublon ;
- conserver la couverture du flux V1-108 : Manuel, ajout, réordonnancement, retrait.

### Autres fichiers déjà modifiés par V1-108 dans le worktree

Ces fichiers étaient déjà modifiés avant la correction Codex et restent dans le scope V1-108 :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

Ils n'ont pas été réanalysés comme changements Codex principaux, mais ils restent listés dans le `git diff --name-only`.

## Tests et validations

Commandes relancées après correction :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-108"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

Résultats :

- `--name "V1-108"` : 3 tests passés, `All tests passed!`
- fichier complet `cinematic_builder_workspace_test.dart` : 207 tests passés, `All tests passed!`
- analyse ciblée : exit 0 ; 37 infos `prefer_const_*`, aucune erreur bloquante.

Validation Git :

```bash
git diff --check
```

Résultat : sortie vide, exit 0.

## Verdict des passes

- **Audit / Architecture** : valide. Les corrections utilisent les opérations core existantes et ne créent pas de nouvelle source de vérité.
- **Implémentation** : valide avec réserve. La correction est ciblée, mais le diff V1-108 global reste large car il contient le travail Gemini préexistant.
- **Tests** : valide pour le fichier builder. Les régressions identifiées sont couvertes.
- **Build / Validation** : partiel et honnête. Analyse ciblée passée ; suite complète `map_editor` non relancée dans ce tour.
- **Critique finale** : réserve maintenue sur le Visual Gate : la capture existante n'a pas été régénérée pendant cette correction.

## Limites connues

- Le screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png` existe dans le worktree, mais il n'a pas été régénéré dans cette passe Codex.
- Les rapports et roadmaps V1-108 sont encore non commités.
- La suite complète `packages/map_editor` n'a pas été relancée ; seul le fichier `cinematic_builder_workspace_test.dart` a été exécuté intégralement.
- Les infos `prefer_const_*` restent présentes et non bloquantes dans les fichiers analysés.

## Prochaine étape recommandée

Avant de clôturer définitivement V1-108 :

1. relancer ou vérifier le Visual Gate avec la capture attendue ;
2. décider si les rapports `V1-108-bis` doivent être conservés comme addendum ou fusionnés dans le rapport principal ;
3. relancer une validation plus large si Karim veut une clôture complète du package `map_editor`.
