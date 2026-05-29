# NS-STORYLINES-SEED-00 — Selbrume Storylines Demo Seed V0

## 1. Executive summary

Selbrume Storylines V1 seed delivered as project data only.

Target modified:

```text
selbrume/project.json
```

Seeded content:

- 1 main storyline: `story_main_brume_phare`;
- 3 sideQuest storylines: `story_side_salt_crystals`, `story_side_goelise_port`, `story_side_lighthouse_cabin`;
- 7 chapters total;
- 30 story steps total;
- 3 explicit sideQuest relationships using `sideQuestAvailableDuring`;
- 0 `StorylineSceneLink`.

No Dart code, tests, widgets, runtime, gameplay, battle, generated files, events, scenes, facts, world rules, Yarn dialogue, cinematics, or battles were modified/imported.

Validation status:

- JSON syntax valid.
- `ProjectManifest.fromJson` decodes the seeded project.
- Core Storylines tests passed.
- Targeted analyzes passed.
- Product-code anti-hardcode search returned empty output.
- Editor Storylines shell test failed on a pre-existing Visual Gate golden file absence: `writes V1-12 polished graph screenshots`.

## 2. Inputs read

Required governance inputs:

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
```

Required Storylines V1 report:

```text
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_12_visual_graph_enrichment.md
```

Read-only code inputs:

```text
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
```

Selbrume source input:

```text
MVP Selbrume/selbrume.md
```

Source evidence:

```text
2260 MVP Selbrume/selbrume.md
```

Important source notes:

- The source contains detailed main story steps 1 through 12.
- The source contains sideQuest sections for `Les cristaux de sel`, `Le Goélise du port`, and `La cabane du phare`.
- The source mentions `step_unlock_passage` in the chapter summary, but the detailed narrative step is `Convaincre Soline d’ouvrir le passage`; this seed uses `step_report_to_soline` and does not create `step_unlock_passage`.

## 3. Target project manifest

Target manifest:

```text
selbrume/project.json
```

Why this is the target:

```text
path selbrume/project.json
name 'Selbrume'
maps list 10
scenarios list 3
storylines '<missing>'
map_ids ['route 1', 'Selbrume', 'house 1', 'house 2', 'house 3', 'house 4', 'house 5', 'pokémon center', 'pub', 'lab']
scenario_ids_scopes [('global_story', 'globalStory', 'Global Story'), ('test', 'localEventFlow', 'test'), ('p6_03_first_interaction', 'localEventFlow', 'P6-03 First Narrative Interaction')]
```

Candidate scan found many build/test manifests, but only one project manifest under the Selbrume demo project directory:

```text
./selbrume/project.json
```

No existing `ProjectManifest.storylines` field was present before the seed. No non-seed StorylineAsset ID collision existed.

## 4. Seed scope

Seeded:

- `ProjectManifest.storylines`;
- main storyline;
- sideQuest storylines;
- chapters;
- story steps;
- explicit sideQuest attachments to main story steps;
- V1 metadata markers.

Not seeded:

- events;
- scenes;
- Dialogue Yarn;
- cinematics;
- battles;
- facts;
- world rules;
- validator rules;
- scene outcome runtime data;
- real scene links.

Seed metadata used:

```json
{
  "seed": "selbrume_storylines_v0",
  "source": "selbrume.md",
  "seedScope": "storylines_v1_only"
}
```

## 5. Seeded main storyline

Main storyline:

```text
id: story_main_brume_phare
type: main
status: draft
title: La brume du phare
description: Le joueur enquête sur une brume étrange qui perturbe Selbrume, découvre que le vieux phare amplifie involontairement l’énergie d’un Pokémon effrayé, puis l’apaise pour rétablir l’équilibre de l’île.
```

Main chapters:

```text
chapter_1_port | Le port | order 0 | 4 steps
chapter_2_marais | Les marais | order 1 | 3 steps
chapter_3_phare | Le phare | order 2 | 3 steps
chapter_4_epilogue | Épilogue | order 3 | 2 steps
```

Main steps:

```text
chapter_1_port:
- step_intro_selbrume | Introduction à Selbrume | order 0
- step_receive_mission | Recevoir la mission de Maël | order 1
- step_go_to_port | Aller au Port des Brisants | order 2
- step_rival_battle | Affronter Lysa | order 3

chapter_2_marais:
- step_enter_marais | Entrer dans les Marais Salants | order 0
- step_find_three_clues | Trouver les indices de la brume | order 1
- step_report_to_soline | Convaincre Soline d’ouvrir le passage | order 2

chapter_3_phare:
- step_reach_lighthouse | Rejoindre le Vieux Phare d’Écume | order 0
- step_climb_lighthouse | Explorer le phare | order 1
- step_final_confrontation | Apaiser le Pokémon du phare | order 2

chapter_4_epilogue:
- step_return_to_port | Retourner au port | order 0
- step_main_story_completed | La lumière revient sur Selbrume | order 1
```

## 6. Seeded side quests

SideQuest `story_side_salt_crystals`:

```text
title: Les cristaux de sel
description: Mado a perdu trois cristaux de sel qui réagissent à la brume et demande au joueur de les retrouver.
chapter: chapter_salt_crystals
steps:
- step_crystals_talk_to_mado | Parler à Mado | order 0
- step_crystals_collect_three | Retrouver les trois cristaux | order 1
- step_crystals_return_to_mado | Rapporter les cristaux à Mado | order 2
- step_crystals_completed | Cristaux de sel terminée | order 3
```

SideQuest `story_side_goelise_port`:

```text
title: Le Goélise du port
description: Un Goélise vole les repas des pêcheurs parce que son nid a été perturbé par la brume.
chapter: chapter_goelise_port
steps:
- step_goelise_talk_to_fisher | Parler au pêcheur | order 0
- step_goelise_find_nest | Trouver le nid | order 1
- step_goelise_choice | Décider quoi faire de l’objet brillant | order 2
- step_goelise_return | Retourner voir le pêcheur | order 3
- step_goelise_completed | Goélise du port terminée | order 4
```

SideQuest `story_side_lighthouse_cabin`:

```text
title: La cabane du phare
description: Yvon cherche la clé de son ancienne cabane, qui contient un carnet expliquant l’histoire de la lentille du phare.
chapter: chapter_lighthouse_cabin
steps:
- step_cabin_talk_to_yvon | Parler à Yvon | order 0
- step_cabin_find_key | Trouver la clé | order 1
- step_cabin_open_door | Ouvrir la cabane | order 2
- step_cabin_read_journal | Lire le carnet du gardien | order 3
- step_cabin_completed | Cabane du phare terminée | order 4
```

## 7. Side quest attachments

Relationships seeded:

```text
relationship_salt_crystals_available_enter_marais
sourceStorylineId: story_side_salt_crystals
targetStorylineId: story_main_brume_phare
kind: sideQuestAvailableDuring
availability.startAnchor.kind: step
availability.startAnchor.targetId: step_enter_marais
notes: La quête devient disponible après rencontre de Mado / entrée dans les marais.

relationship_goelise_port_available_rival_battle
sourceStorylineId: story_side_goelise_port
targetStorylineId: story_main_brume_phare
kind: sideQuestAvailableDuring
availability.startAnchor.kind: step
availability.startAnchor.targetId: step_rival_battle
notes: La quête devient disponible après le combat rival au port.

relationship_lighthouse_cabin_available_report_soline
sourceStorylineId: story_side_lighthouse_cabin
targetStorylineId: story_main_brume_phare
kind: sideQuestAvailableDuring
availability.startAnchor.kind: step
availability.startAnchor.targetId: step_report_to_soline
notes: La quête devient pertinente quand le passage vers le phare est débloqué.
```

All anchors target real steps in the seeded main storyline.

## 8. Unsupported Selbrume data intentionally not seeded

Intentionally excluded from the seed:

```text
Events
Scenes
Dialogue Yarn
Cinematics
Battles
Facts
World Rules
Validator rules
Scene Outcomes runtime
SceneLinks réels
```

These belong to future workspaces/phases. They were not forced into `metadata`.

## 9. Idempotence / collision handling

Before seeding:

```text
storylines '<missing>'
storylines_count 0
```

Collision state:

```text
No existing StorylineAsset IDs.
No existing non-seed StorylineAsset ID collision.
```

Idempotence marker:

```text
metadata.seed == selbrume_storylines_v0
```

The inserted storylines are deterministic and all four seed-owned storylines carry the seed marker. A later seed rerun can safely identify and replace these seed-owned records without deleting non-seed user data.

## 10. Validation results

JSON syntax:

```text
json.tool OK: /tmp/selbrume_project_json_check.json
```

Seed shape:

```text
storylines_total 4
seed_storylines_total 4
types {'main': 1, 'sideQuest': 3}
seed_ids ['story_main_brume_phare', 'story_side_salt_crystals', 'story_side_goelise_port', 'story_side_lighthouse_cabin']
scene_links_total 0
scenario_ids_scopes [('global_story', 'globalStory'), ('test', 'localEventFlow'), ('p6_03_first_interaction', 'localEventFlow')]
```

`ProjectManifest.fromJson` validation:

```text
ProjectManifest.fromJson OK
seeded=4 main=1 sideQuest=3 sceneLinks=0 relationships=3
```

Core tests:

```text
packages/map_core/test/storyline_asset_test.dart: All tests passed!
packages/map_core/test/storyline_asset_json_test.dart: All tests passed!
packages/map_core/test/project_manifest_storylines_test.dart: All tests passed!
```

Editor test:

```text
packages/map_editor/test/storylines_workspace_shell_test.dart: Some tests failed.
Failing test: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots
Failure location: packages/map_editor/test/storylines_workspace_shell_test.dart:1227
Cause observed: golden Visual Gate screenshot files for V1-12 are absent in the current repo.
No test or screenshot was modified in this seed lot.
```

Analyses:

```text
map_core targeted analyze: No issues found!
map_editor targeted analyze: No issues found! (ran in 1.6s)
```

Anti-hardcode product search:

```text
Sortie : <vide>
```

## 11. Commands run

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

```bash
find . -iname "project.json" -o -iname "*manifest*.json" -o -iname "*.pokemap"
find . -iname "*selbrume*" -o -iname "*Selbrume*"
rg "Selbrume|ProjectManifest|storylines" . --glob "*.json" --glob "*.md" --glob "*.dart"
```

```bash
python3 -m json.tool "selbrume/project.json" > /tmp/selbrume_project_json_check.json
```

```bash
cd packages/map_core && dart --packages=.dart_tool/package_config.json /tmp/validate_selbrume_project_manifest.dart ../../selbrume/project.json
```

```bash
cd packages/map_core && dart test --reporter=compact test/storyline_asset_test.dart
cd packages/map_core && dart test --reporter=compact test/storyline_asset_json_test.dart
cd packages/map_core && dart test --reporter=compact test/project_manifest_storylines_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
```

```bash
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart lib/src/models/project_manifest.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart
```

```bash
rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
```

## 12. Roadmap update

Updated:

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Roadmap changes:

- added `NS-STORYLINES-SEED-00 — Selbrume Storylines Demo Seed V0`;
- status set to `DONE`;
- current lot set to `NS-STORYLINES-SEED-00`;
- next recommended lot remains `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`;
- changelog notes data-only seed, no product code, no unsupported workspace imports, and the editor golden test limitation.

## 13. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Chemin exact du ProjectManifest modifié

```text
selbrume/project.json
```

### Preuve que ce fichier est bien le projet Selbrume

```text
path selbrume/project.json
name 'Selbrume'
maps list 10
scenarios list 3
map_ids ['route 1', 'Selbrume', 'house 1', 'house 2', 'house 3', 'house 4', 'house 5', 'pokémon center', 'pub', 'lab']
scenario_ids_scopes [('global_story', 'globalStory', 'Global Story'), ('test', 'localEventFlow', 'test'), ('p6_03_first_interaction', 'localEventFlow', 'P6-03 First Narrative Interaction')]
```

### Diff complet du fichier projet modifié

```text
selbrume/project.json:
- Added top-level ProjectManifest.storylines.
- Added story_main_brume_phare with four chapters and twelve steps.
- Added story_side_salt_crystals with one chapter and four steps.
- Added story_side_goelise_port with one chapter and five steps.
- Added story_side_lighthouse_cabin with one chapter and five steps.
- Added three sideQuestAvailableDuring relationships.
- Added zero StorylineSceneLink entries.
- Existing maps, scenarios, scripts, catalogs, runtime data and localEventFlow scenarios were left unchanged.
```

### Liste exacte des storylines seedées

```text
story_main_brume_phare | main | La brume du phare
story_side_salt_crystals | sideQuest | Les cristaux de sel
story_side_goelise_port | sideQuest | Le Goélise du port
story_side_lighthouse_cabin | sideQuest | La cabane du phare
```

### Liste exacte des chapters seedés

```text
story_main_brume_phare:
- chapter_1_port
- chapter_2_marais
- chapter_3_phare
- chapter_4_epilogue

story_side_salt_crystals:
- chapter_salt_crystals

story_side_goelise_port:
- chapter_goelise_port

story_side_lighthouse_cabin:
- chapter_lighthouse_cabin
```

### Liste exacte des steps seedées

```text
chapter_1_port:
- step_intro_selbrume
- step_receive_mission
- step_go_to_port
- step_rival_battle

chapter_2_marais:
- step_enter_marais
- step_find_three_clues
- step_report_to_soline

chapter_3_phare:
- step_reach_lighthouse
- step_climb_lighthouse
- step_final_confrontation

chapter_4_epilogue:
- step_return_to_port
- step_main_story_completed

chapter_salt_crystals:
- step_crystals_talk_to_mado
- step_crystals_collect_three
- step_crystals_return_to_mado
- step_crystals_completed

chapter_goelise_port:
- step_goelise_talk_to_fisher
- step_goelise_find_nest
- step_goelise_choice
- step_goelise_return
- step_goelise_completed

chapter_lighthouse_cabin:
- step_cabin_talk_to_yvon
- step_cabin_find_key
- step_cabin_open_door
- step_cabin_read_journal
- step_cabin_completed
```

### Liste exacte des relationships seedées

```text
relationship_salt_crystals_available_enter_marais | story_side_salt_crystals -> story_main_brume_phare | step_enter_marais
relationship_goelise_port_available_rival_battle | story_side_goelise_port -> story_main_brume_phare | step_rival_battle
relationship_lighthouse_cabin_available_report_soline | story_side_lighthouse_cabin -> story_main_brume_phare | step_report_to_soline
```

### Liste des éléments Selbrume non seedés volontairement

```text
Events
Scenes
Dialogue Yarn
Cinematics
Battles
Facts
World Rules
Validator rules
Scene Outcomes runtime
SceneLinks réels
step_unlock_passage
```

### Sortie exacte de python3 -m json.tool

```text
json.tool OK: /tmp/selbrume_project_json_check.json
```

### Sorties exactes des tests lancés

```text
cd packages/map_core && dart test --reporter=compact test/storyline_asset_test.dart
Result: All tests passed!

cd packages/map_core && dart test --reporter=compact test/storyline_asset_json_test.dart
Result: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_storylines_test.dart
Result: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
Result: Some tests failed.
Failing test: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots
Failure location: packages/map_editor/test/storylines_workspace_shell_test.dart:1227
```

### Sortie exacte des analyses lancées

```text
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart lib/src/models/project_manifest.dart
Analyzing storyline_asset.dart, project_manifest.dart...
No issues found!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart
Analyzing 4 items...
No issues found! (ran in 1.6s)
```

### Sortie exacte du rg anti-hardcode produit

```text
Sortie : <vide>
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 777b3f9b..c647c8b5 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -316,6 +316,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-11 | Side Quest Attachment + Graph Integration V0 | editor graph | DONE | NS-STORYLINES-V1-12 |
 | NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | DONE | NS-STORYLINES-V1-CHECKPOINT |
 | NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | DONE | NS-SCENES-V1 |
+| NS-STORYLINES-SEED-00 | Selbrume Storylines Demo Seed V0 | demo data | DONE | NS-SCENES-V1 |
 
 ## 9. Detailed lots
 
@@ -897,7 +898,7 @@ Décision temporaire :
 
 ```text
 Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
-Current lot: NS-STORYLINES-V1-CHECKPOINT
+Current lot: NS-STORYLINES-SEED-00
 Current lot status: DONE
 Next recommended lot: NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation
 ```
@@ -966,6 +967,15 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-SEED-00
+
+- Selbrume Storylines Demo Seed V0 livré comme data-only dans `selbrume/project.json`.
+- Seed ajouté uniquement dans `ProjectManifest.storylines` : 1 main storyline, 3 sideQuests, chapters, steps et attachements explicites sideQuest -> main step.
+- Aucun code produit, test, runtime, gameplay, battle, event, scene, fact, world rule, dialogue, cinématique ou combat importé.
+- Source documentaire utilisée : `MVP Selbrume/selbrume.md`.
+- Validation JSON et tests core ciblés passent ; le test editor global `storylines_workspace_shell_test.dart` échoue sur le golden Visual Gate V1-12 absent du repo courant, sans modification de test dans ce lot.
+- Storylines V1 reste fermé par checkpoint ; prochaine phase recommandée : `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.
+
 ### 2026-05-29 — NS-STORYLINES-V1-CHECKPOINT
 
 - Storylines V1 Acceptance Checkpoint livré en audit-only / documentation-only.
```

### Contenu complet du rapport créé

Le présent fichier est le rapport créé pour `NS-STORYLINES-SEED-00`. Son contenu complet correspond aux sections `1` à `14`.

### Git status final exact

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
 M selbrume/project.json
?? reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md
```

### Git diff --stat final

```text
 .../storylines/road_map_storylines.md              |  12 +-
 selbrume/project.json                              | 432 +++++++++++++++++++++
 2 files changed, 443 insertions(+), 1 deletion(-)
```

### Git diff --name-only final

```text
reports/narrativeStudio/storylines/road_map_storylines.md
selbrume/project.json
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Seed is data-only and stays inside the demo manifest.
- Storylines content matches the requested V1-supported surface.
- Unsupported Selbrume systems were not hidden in metadata.
- `reports/narrativeStudio/storylines/selbrume.md` was not created because the source already exists in the repo at `MVP Selbrume/selbrume.md` and no inline source file content was provided in this turn.
- Editor test failure is not caused by seed data; it is the existing golden screenshot expectation with missing V1-12 artifacts in the current repo.

## 14. Self-review

This lot modified only the Selbrume demo project manifest and the Storylines roadmap, and created this report. No product code, tests, screenshots, generated files, runtime, gameplay, battle, or map core/editor source files were modified.

The seed creates exactly the Storylines V1 authoring layer requested: main story, sideQuests, chapters, steps, and explicit sideQuest attachments. It does not claim to import Selbrume scenes, events, facts, world rules, dialogue, cinematics, battles, or runtime outcomes.
