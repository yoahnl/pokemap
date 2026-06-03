# NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0

Date : 2026-06-03  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`  
Prochain lot recommande : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`

## 1. Resume executif

V1-60 remplace le badge long `Navigation clavier : ← → ↑ ↓ Home End` par un controle compact `Aide clavier` dans la timeline du Cinematic Builder. Un clic ouvre un panneau local qui explique les raccourcis clavier sans ajouter de lecture, seek, scrubber, drag/drop, playhead souris, runtime ou mutation projet.

## 2. Phrase canonique

V1-60 explique la navigation clavier. V1-60 ne donne pas de nouveaux pouvoirs a la timeline.

## 3. Gate 0

Commande initiale executee depuis la racine :

```bash
git status --short --untracked-files=all && git diff --name-only && git branch --show-current && git log --oneline -3
```

Sortie utile :

```text
main
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
```

Interpretation : `git status --short --untracked-files=all` et `git diff --name-only` etaient vides avant modification.

## 4. Probleme constate

Le badge long melangeait statut et aide, consommait la rangee de badges et n'expliquait pas la difference entre navigation horizontale, navigation verticale et Home/End.

## 5. Option retenue

Option C : controle compact `Aide clavier`, panneau local toggle par clic. Cette option reste lisible et non intrusive tout en gardant le contenu complet disponible.

## 6. Etat local

L'etat vit uniquement dans `_TimelinePlaceholderState` via `_timelineKeyboardHelpOpen`. Il n'est pas stocke dans `ProjectManifest`, `CinematicAsset`, `CinematicTimelineStep`, le core ou le runtime.

## 7. Ouverture et fermeture

Le clic sur `Aide clavier` appelle `_toggleTimelineKeyboardHelp()`, qui redonne le focus local a la timeline et inverse l'etat du panneau. Un second clic referme le panneau.

## 8. Focus

Le focus clavier existant reste porte par `_timelineFocusNode`. Le controle d'aide ne capture pas les fleches globalement et ne modifie pas la protection des TextFields.

## 9. Contenu exact

Le panneau affiche :

```text
← / → : Bloc précédent / suivant
↑ / ↓ : Piste précédente / suivante
Home : Premier bloc
End : Dernier bloc
Sélection uniquement — pas de lecture ni déplacement temporel.
```

## 10. Absence de nouvelle capability

Le texte precise que l'aide concerne seulement la selection. Aucun playback, seek, scrubber, drag/drop, resize, reorder, playhead souris ou mutation temporelle n'est ajoute.

## 11. Compatibilite V1-57

ArrowLeft, ArrowRight, Home et End gardent leur comportement par ordre lineaire `stepIndex`. Le test de navigation locale V1-57 reste vert.

## 12. Compatibilite V1-59

ArrowUp et ArrowDown gardent le contrat V1-59 : prochaine lane non vide et cible par proximite `centerMs`. Le panneau d'aide ne change pas le helper vertical.

## 13. TextFields proteges

Les tests existants `keeps keyboard shortcuts local and protects text fields` et `keeps vertical keyboard shortcuts local and protects text fields` restent verts.

## 14. Proportions V1-56

Le premier essai avec `PokeMapButton` augmentait l'entete de timeline de 2 px. Le GREEN final utilise un badge compact interactif pour conserver le test `balances sandbox preview and useful timeline grid proportions`.

## 15. Hover V1-55

Le panneau d'aide est un overlay separe. Il ne lit pas `hoveredStepId` et ne selectionne rien au survol.

## 16. Transports V1-53

Les boutons Reset / Play / Stop restent disabled. Aucun callback, timer ou etat de lecture n'est ajoute.

## 17. Playhead souris hors scope

Le playhead souris type Final Cut est documente comme desir produit futur, mais reste hors V1-60. Le prochain lot exact devient un contrat de preparation, pas une implementation.

## 18. Implementation

Fichier UI modifie : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`.

Changements :

- ajout de `_timelineKeyboardHelpOpen` ;
- ajout de `_toggleTimelineKeyboardHelp()` ;
- remplacement du badge long par `_TimelineKeyboardHelpBadge` ;
- ajout du panneau `_TimelineKeyboardHelpPanel` ;
- ajout des lignes `_TimelineKeyboardHelpRow`.

## 19. Tests ajoutes ou modifies

Fichier test modifie : `packages/map_editor/test/cinematic_builder_workspace_test.dart`.

Test ajoute :

- `shows compact keyboard navigation help without changing timeline selection`

Tests modifies :

- attente V1-57 du controle compact au lieu du badge long ;
- capture V1-57 mise a jour ;
- capture V1-59 mise a jour ;
- capture V1-60 ajoutee.

## 20. RED

Commande RED :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows compact keyboard navigation help without changing timeline selection'
```

Resultat RED : echec attendu, le finder `cinematic-builder-keyboard-help-button` trouvait 0 widget.

## 21. GREEN

La meme commande passe apres implementation :

```text
00:02 +1: All tests passed!
```

## 22. Visual Gate

Capture generee :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff  241206 Jun  3 01:55 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png
sha256 f1e0e6fee50e24105a95b07c1b7ddeb70cd2926d09e85d6e259af6eb0b961f4b
```

Observation : panneau ouvert, `step_face` selectionne, curseur aligne, inspecteur coherent, transports disabled.

## 23. Contrats core

Les tests core time layout et lane read model restent verts. V1-60 ne modifie aucun modele core.

## 24. Design system

Le code UI utilise `PokeMapBadge`, `PokeMapCard`, `PokeMapPanel` et `context.pokeMapColors`. Aucune couleur hardcodee n'est ajoutee dans le widget.

## 25. Non-mutation ProjectManifest

Le test V1-60 compare `project.toJson()` avant/apres et verifie `projectChangeCount == 0`.

## 26. Anti-scope

Les checks production sont vides pour runtime/gameplay/battle/examples, playback/seek/scrub/drag dans le widget, et persistance core. Les seules mentions `Professor` ajoutees sont des assertions de fixture test existante autour de `step_face`.

## 27. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_60_evidence_pack.md`

## 28. Commandes executees

Les commandes completes sont reprises dans l'Evidence Pack V1-60. Toutes les commandes de verification executees apres GREEN sont passees.

## 29. Limites connues

V1-60 n'ajoute pas Escape pour fermer le panneau, par choix de scope. Le panneau se ferme par second clic sur `Aide clavier`.

## 30. Roadmaps

Les roadmaps marquent V1-60 comme DONE et positionnent V1-61 comme prochain lot exact.

## 31. Prochain lot

`NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`

Ce lot devra cadrer le futur playhead souris/scrub avant toute implementation.
