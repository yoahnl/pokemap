# NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0

Date : 2026-06-03
Statut : DONE
Type : editor / UX help / interaction locale non persistante
Lot precedent : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`
Prochain lot recommande : `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0`

## Resume

V1-66 ajoute une aide locale `Aide repère` dans le Cinematic Builder. Elle apparait seulement quand le repere souris local existe et explique, en quatre lignes courtes, la difference entre selection inspectee, repere temporel local, alignement/snap et preview future.

Phrase canonique : V1-66 explique le repere temporel. V1-66 ne donne aucun nouveau pouvoir a la timeline.

## Gate 0

Commande executee depuis la racine avant toute modification V1-66 :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. Le working tree etait propre avant V1-66.

## Design Gate

- V1-65 etait deja reversible : bouton `Effacer le repère`, microcopy `Repère local : inspection uniquement.`, Escape local, TextFields proteges.
- Le manque restant etait explicatif : l'utilisateur pouvait confondre `Selection` et `Repere`.
- Placement retenu : bouton `Aide repère` dans l'en-tete de timeline, pres de `Effacer le repère`, visible seulement avec probe actif.
- Panneau retenu : local a la timeline, quatre lignes, pas de modal, pas d'inspecteur, pas de transport.
- Texte exact :
  - `Sélection : bloc inspecté.`
  - `Repère : position temporelle locale.`
  - `Alignement : repère calé sur une borne utile.`
  - `Preview : lecture réelle à venir.`

## Implementation

- Ajout de l'etat local `_timelineProbeHelpOpen` dans `_TimelinePlaceholderState`.
- Ajout du toggle `_toggleTimelineProbeHelp()` qui demande le focus local timeline puis ouvre/ferme uniquement le panneau.
- Fermeture automatique du panneau si le probe est efface.
- Ajout du controle `Aide repère`, affiche uniquement quand `timelineProbeTimeMs != null`.
- Ajout de `_TimelineProbeHelpPanel` et `_TimelineProbeHelpLine`, bases sur `PokeMapCard` et les tokens du design system.
- Preservation de l'ancien en-tete quand aucun repere n'est actif, pour garder les proportions V1-56.

## Tests

Test RED ajoute avant implementation :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows local time probe help explaining selection and probe'
```

Echec attendu :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Aide repère": []>
```

Tests ajoutes/modifies :

- `shows local time probe help explaining selection and probe`
- `clears local time probe with Escape after probe help is open`
- capture conditionnelle `captures V1-66 cinematic timeline mouse probe help when requested`

Couverture prouvee :

- aide invisible avant probe ;
- aide visible seulement avec probe actif ;
- toggle sans changement de selection ;
- contenu Selection/Repere/Alignement/Preview ;
- aucune mutation `ProjectManifest` via `project.toJson()` et `onProjectChanged == 0` ;
- transports toujours disabled ;
- coexistence avec `Aide clavier` ;
- clear et Escape encore fonctionnels apres ouverture ;
- TextFields, hover et snap preserves par les tests V1-65/V1-64 existants.

## Visual Gate

Commande demandee :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_66_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_HELP=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat final :

```text
00:12 +68: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png
```

Note d'iteration : une premiere tentative de Visual Gate a revele un overflow d'en-tete, puis un placement de badge trop loin dans la zone horizontale. La solution finale garde l'ancien layout sans probe et utilise un en-tete flexible seulement quand le probe est actif.

## Commandes executees

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows local time probe help explaining selection and probe'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'clears local time probe with Escape after probe help is open'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_66_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_HELP=true --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter analyze
```

Resultats :

- Builder cible V1-66 : `+1`, puis `All tests passed!`
- Escape apres aide : `+1`, puis `All tests passed!`
- Proportions timeline : `+1`, puis `All tests passed!`
- Visual Gate / suite Builder : `+68`, puis `All tests passed!`
- Suite Builder sans define : `+68`, puis `All tests passed!`
- Suite Library : `+10`, puis `All tests passed!`
- Analyse cible editor : `No issues found!`
- Core time layout : `+4`, puis `All tests passed!`
- Core lane read model : `+2`, puis `All tests passed!`
- `map_core` analyze : `No issues found!`
- `map_editor` analyze global : rouge, `344 issues found`, sur dettes preexistantes hors lot, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## Checks anti-scope

- Aucun changement `map_core`.
- Aucun changement `map_runtime`, `map_gameplay`, `map_battle` ou examples.
- Aucun `ProjectManifest` modifie dans le code V1-66.
- Aucun mot interdit dans le widget modifie : `playback`, `seek`, `scrub`, `temps courant`, `runtime position`.
- Les occurrences `playback` / `seek` / `scrub` dans le test sont uniquement des assertions negatives `findsNothing`.

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md`

## Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_66_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png`

## Limites

- L'aide explique seulement le repere local ; elle ne lance pas de lecture reelle.
- Le bouton n'apparait pas hors etat probe actif.
- Les transports restent des placeholders disabled.
- Le prochain polish recommande est la visibilite/scroll de la timeline, sans demarrer V1-67 dans ce lot.

## Verdict

V1-66 est DONE. Le lot respecte V1-65, preserve les proportions existantes, ajoute une explication locale no-code, et ne donne aucun nouveau pouvoir temporel a la timeline.
