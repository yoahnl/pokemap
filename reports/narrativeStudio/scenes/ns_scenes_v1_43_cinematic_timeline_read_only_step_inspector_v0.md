# NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0

## 1. Resume executif

Le lot est DONE. Le Cinematic Builder V0 affiche maintenant les steps reels d'un `CinematicAsset` canonique, permet une selection locale de bloc et montre un inspecteur detaille lecture seule avec diagnostics contextualises. Aucun contrat core/runtime n'a ete modifie.

## 2. Gate 0

- Branche : `main`.
- Worktree avant lot : propre.
- Derniers commits observes : V1-42-bis, V1-42, V1-41, V1-40-bis, V1-40.
- Strategie : changement editor-only dans `map_editor`, sans operation Git write.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapports V1-41, V1-42, V1-42-bis
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`

## 4. Design Gate — Cinematic Timeline Read-only / Step Inspector V0

1. Les donnees de steps detailles existent deja dans `CinematicAsset.timeline.steps`.
2. Le read model Library reste un resume ; pas d'enrichissement `map_core`.
3. La Library passe l'asset canonique complet au Builder via `findCinematicById`.
4. La selection vit dans `_CinematicBuilderWorkspaceState._selectedStepId`.
5. `didUpdateWidget` nettoie la selection si la cinematique change ou si le step n'existe plus.
6. La timeline est rendue par cartes `PokeMapCard`, sans callback de mutation.
7. L'inspecteur utilise uniquement `_KeyValue`, `PokeMapBadge` et textes lecture seule.
8. Champs exposes : titre, id, index, kind, duree, actorId, targetId, dialogue, assetRef, metadata.
9. Les diagnostics viennent de `diagnoseCinematicAsset(asset)` filtres par `stepId`.
10. La preview reste sandbox ; elle rappelle seulement le bloc selectionne.
11. Les couleurs viennent du design system et de `context.pokeMapColors`.
12. La visual gate est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.

## 5. Scope realise

- Builder converti en `StatefulWidget` pour porter une selection locale.
- Timeline remplacee par une liste ordonnee des steps existants.
- Cartes de step avec index, label fallback, kind, duree, acteur, cible, assetRef et badge diagnostic.
- Inspecteur de step selectionne complet et lecture seule.
- Empty state sans selection conserve.
- Palette verrouillee et boutons header toujours inactifs.

## 6. Donnees timeline / read model

Decision : `map_core` n'a pas besoin de nouveau read model pour V1-43. La Library continue d'utiliser `CinematicsLibraryEntry` pour l'exploration et transmet l'asset complet au Builder uniquement pour afficher les details.

## 7. Selection locale de step

La selection est locale, non serialisee et non propagee. Elle persiste tant que le meme asset reste ouvert et que le step selectionne est encore present.

## 8. Timeline read-only

Chaque step affiche son ordre, un titre lisible, son kind et les champs disponibles. L'etat vide reste honnete et ne propose aucune action.

## 9. Step Inspector read-only

Sans selection : `Aucun bloc selectionne` avec une aide courte. Avec selection : details du step, metadata triee, statut preview/runtime lecture seule, et diagnostics propres au bloc.

## 10. Diagnostics contextualises

Les diagnostics de step sont affiches dans l'inspecteur du bloc selectionne. Les diagnostics globaux deja exposes par la Library restent visibles quand ils ne ciblent pas le bloc courant.

## 11. Preview sandbox inchangée

La preview ne joue rien. Elle conserve le message sandbox et affiche seulement un badge indiquant le step selectionne.

## 12. Legacy bridge policy inchangée

Les bridges legacy restent exclus du Builder canonique. Les tests Library continuent de verifier que seuls les assets canoniques ouvrent le Builder.

## 13. Design system

Les nouvelles surfaces utilisent `PokeMapPanel`, `PokeMapCard`, `PokeMapBadge`, `PokeMapButton`, `PokeMapIconTile` et les tokens de theme. Aucun hardcode couleur n'a ete ajoute dans les fichiers UI modifies.

## 14. Tests ajoutes ou modifies

- Liste ordonnee des steps avec labels, kind, duree, acteur/cible/dialogue/assetRef.
- Selection locale de step et mise a jour de l'inspecteur.
- Diagnostics de step sans activation d'action.
- Etat timeline vide conserve.
- Non-mutation via comparaison `ProjectManifest.toJson()`.
- Capture V1-43 avec timeline multi-step et step selectionne.

## 15. Visual Gate

- Fichier cree : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.
- Contenu verifie visuellement : Builder ouvert, timeline multi-step, bloc dialogue selectionne, inspecteur detaille, palette verrouillee, preview sandbox.

## 16. Commandes executees

- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE=true --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`
- Checks de perimetre code : packages runtime/gameplay/battle/examples, `map_core`, couleurs UI, references runtime interdites, operations de timeline hors scope, donnees produit nommees.
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

## 17. Resultats des tests

- RED initial : compilation bloquee car `CinematicBuilderWorkspace` n'avait pas encore le parametre `asset`.
- Builder final : `+7 All tests passed!`
- Library final : `+7 All tests passed!`
- Visual gate final : `+7 All tests passed!`

## 18. Analyze

`flutter analyze --no-fatal-infos` sur les quatre fichiers cibles : `No issues found!`.

## 19. Checks anti-scope

- `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples` : aucun fichier modifie.
- `packages/map_core` : aucun fichier modifie.
- UI cinematics : aucun hardcode couleur detecte.
- UI/tests V1-43 : aucune reference runtime interdite detectee.
- UI/tests V1-43 : aucune operation de timeline hors scope detectee.
- UI/tests V1-43 : aucune donnee produit nommee ajoutee.
- `git diff --check` : OK.
- Etat Git final : 5 fichiers modifies suivis et 2 fichiers non suivis crees pour le rapport et la capture.

## 20. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`

## 21. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 22. Roadmaps mises a jour

- V1-43 ajoute en DONE.
- Prochain lot recommande : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.

## 23. Limites connues

- Pas d'edition de blocs.
- Pas de changement d'ordre.
- Pas de persistance de selection.
- Pas de vrai player visuel.
- Pas de migration legacy.
- Pas de nouveau contrat core.

## 24. Non-objectifs confirmes

- Aucun changement runtime/gameplay/battle/examples.
- Aucune mutation du `ProjectManifest` depuis le Builder.
- Aucun bouton d'action de timeline actif.
- Aucun callback de sauvegarde de deroule.
- Aucun champ editable dans l'inspecteur de step.

## 25. Evidence Pack

- `CinematicBuilderWorkspace` prend maintenant `asset`, garde `_selectedStepId` et derive `selectedStep`.
- `_TimelineStepCard` rend les cartes de step avec `selected` et `onTap` local.
- `_SelectedStepInspector` affiche les champs du step avec helpers `_stepTitle`, `_stepDurationLabel`, `_metadataLabel`.
- `_stepDiagnostics` filtre `diagnoseCinematicAsset(asset).diagnostics` par `stepId`.
- `CinematicsLibraryWorkspace` resolve l'asset canonique avec `findCinematicById`.
- Les tests fixtures `_richCinematic` et `_diagnosticCinematic` couvrent les champs detailles et le diagnostic de duree negative.

## 26. Auto-review critique

Risque principal : l'inspecteur appelle `diagnoseCinematicAsset` pour chaque carte/selection. Le volume V0 est faible ; si les timelines deviennent longues, un cache local par build pourra etre ajoute.

Point surveille : la selection est detruite au retour Library, ce qui est volontaire pour V1-43 mais devra etre reconsidere si un futur lot ajoute une navigation multi-pane persistante.

## 27. Recommandation pour le prochain lot

Lancer `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` seulement avec operations pures, tests de non-regression et UI no-code bornee. V1-43 fournit maintenant la surface d'inspection necessaire pour verifier ces futurs drafts.
