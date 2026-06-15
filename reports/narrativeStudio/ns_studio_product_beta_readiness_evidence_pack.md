# NS-STUDIO-AUDIT-001 — Evidence Pack

## 1. Gate 0

Commandes exécutées au début du lot :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 12
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont retourné aucune ligne au Gate 0 : le worktree était propre avant l'audit.

## 2. Règles lues

Fichiers lus avant analyse :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
skills/test-driven-development/SKILL.md
```

Note :

```text
codex_rules.md
```

au pluriel est absent. Le fichier présent et lu est :

```text
codex_rule.md
```

## 3. Fichiers lus

Sources produit et roadmaps :

```text
MVP Selbrume/narrative_studio.md
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/selbrume.md
MVP Selbrume/road_map.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_3.md
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_phase_5.md
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_phase_7.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md
reports/narrativeStudio/scenes/ns_scenes_v1_137_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md
```

Sources data :

```text
selbrume/project.json
selbrume/project.shadow59.before.json
selbrume/maps/*.json
selbrume/dialogues/*.yarn
```

Sources code auditées par recherche ciblée :

```text
packages/map_core/lib
packages/map_editor/lib
packages/map_runtime/lib
packages/map_gameplay/lib
packages/map_core/test
packages/map_editor/test
packages/map_runtime/test
packages/map_gameplay/test
```

## 4. Commandes d'inventaire

### 4.1 Répertoire reports

Commande :

```bash
test -d reports/narrativeStudio && echo reports/narrativeStudio exists
```

Sortie :

```text
reports/narrativeStudio exists
```

Décision : les livrables ont été créés dans `reports/narrativeStudio/`, pas dans le fallback `reports/narrativeStudio/scenes/`.

### 4.2 Fichiers vision Selbrume

Commande :

```bash
find 'MVP Selbrume' -maxdepth 1 -type f -print | sort
```

Sortie exacte :

```text
MVP Selbrume/.gitignore
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/road_map.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_3.md
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_phase_5.md
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_phase_7.md
MVP Selbrume/selbrume.md
```

### 4.3 Inventaire Selbrume project.json

Commande :

```bash
jq '{maps:(.maps|length), characters:(.characters|length), dialogues:(.dialogues|length), scenes:(.scenes|length), cinematics:(.cinematics|length), storylines:(.storylines|length), facts:(.facts|length), worldRules:(.worldRules|length), trainers:(.trainers|length), encounterTables:(.encounterTables|length)}' selbrume/project.json
```

Sortie exacte :

```json
{
  "maps": 10,
  "characters": 5,
  "dialogues": 2,
  "scenes": 1,
  "cinematics": 1,
  "storylines": 4,
  "facts": 1,
  "worldRules": 0,
  "trainers": 1,
  "encounterTables": 1
}
```

### 4.4 Preuves V1-138

Commande :

```bash
rg -n "NOT_READY|V1-139|V1-138-bis|lyra|lysa|Port des Brisants|worldRules|cinematic_uwu|scene_test|fact_test|g\\.yarn" reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md
```

Lignes utiles exactes :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:72:reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md:18:Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:309:  "worldRules": 0,
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:425:Decision : `g.yarn` est placeholder ; `test.yarn` est un prototype meteo Marc/Lea, pas un dialogue Mael/Lysa.
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:455:cinematic_uwu	UwU	step_wait	wait	Attente	300
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:473:story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_go_to_port	Aller au Port des Brisants		
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:490:lyra	lyra	lyra	8	0
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md:507:  "id": "fact_test",
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md:470:| Lysa/Lyra/rival non tranche | Characters | Risque de creer le mauvais personnage. | P0_BLOCKER | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md:471:| Port des Brisants non tranche | Maps | Risque d'ecrire events au mauvais endroit. | P0_BLOCKER | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md:499:V1-139_SHOULD_WAIT
```

## 5. Fichiers / symboles trouvés

### 5.1 UI Narrative Studio

Commande :

```bash
rg -n "Storylines|Scènes|Builder à venir|Étapes|Cinématiques|Dialogues|Facts|Règles du monde|Validateur|Non branché" packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Lignes utiles exactes :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:83:                  label: 'Storylines',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:91:                  label: 'Scènes',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:92:                  subtitle: 'Builder à venir',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:99:                  label: 'Étapes',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:107:                  label: 'Cinématiques',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:115:                  label: 'Dialogues',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:126:                  label: 'Facts',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:134:                  label: 'Règles du monde',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:145:                  label: 'Validateur',
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart:146:                  subtitle: 'Non branché',
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:598:      EditorWorkspaceMode.facts => _buildFactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:604:      EditorWorkspaceMode.worldRules => _buildFactsWorldRulesWorkspace(
```

### 5.2 Vision produit

Recherche dans `MVP Selbrume/narrative_studio.md` et roadmaps phase.

Lignes utiles exactes :

```text
MVP Selbrume/road_map_phase_1.md:46:Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn,
MVP Selbrume/road_map_phase_1.md:47:Fact, World Rule et Validator.
MVP Selbrume/road_map_phase_1.md:125:- Event = déclenche.
MVP Selbrume/road_map_phase_1.md:126:- Scene = orchestre.
MVP Selbrume/road_map_phase_1.md:127:- Cinematic = met en scène linéairement.
MVP Selbrume/road_map_phase_1.md:128:- Yarn = dialogue + outcomes.
MVP Selbrume/road_map_phase_1.md:129:- Fact = vérité lisible du monde.
MVP Selbrume/road_map_phase_1.md:130:- World Rule = projection passive du GameState.
MVP Selbrume/road_map_phase_1.md:132:- Validator = diagnostique.
MVP Selbrume/road_map_phase_1.md:136:- Scene ≠ Cinematic
MVP Selbrume/road_map_phase_1.md:137:- Event ≠ Scene
MVP Selbrume/road_map_phase_1.md:138:- Yarn ≠ moteur principal de progression
MVP Selbrume/road_map_phase_1.md:139:- Fact ≠ flag technique exposé à l’utilisateur
MVP Selbrume/road_map_phase_1.md:140:- World Rule ≠ Event
MVP Selbrume/narrative_studio.md:706:Ce PNJ lance quel Event quand on lui parle ?
MVP Selbrume/narrative_studio.md:707:Cette zone déclenche quelle Scene quand on y entre ?
MVP Selbrume/narrative_studio.md:709:Cet objet disparaît après quel Fact ?
MVP Selbrume/narrative_studio.md:1530:Ne pas exposer les flags techniques comme UX principale.
MVP Selbrume/narrative_studio.md:1531:Ne pas mélanger Scene et Cinematic.
MVP Selbrume/narrative_studio.md:1579:Yarn influence la Scene. La Scene émet un outcome. L’Event ou le Narrative System décide de persister.
MVP Selbrume/narrative_studio.md:1581:## Décision 6 — La map doit porter Events + World Rules
MVP Selbrume/narrative_studio.md:1585:## Décision 7 — Le Validator est central
MVP Selbrume/narrative_studio.md:1760:Parler au rival → Yarn outcome → Scene branch → Cinematic → Combat → Fact → Step completed → World Rule.
MVP Selbrume/narrative_studio.md:1854:Le Narrative Studio ne doit pas être un éditeur de flags.
MVP Selbrume/narrative_studio.md:1855:Il doit être un éditeur de situations, de décisions, de scènes et de conséquences.
```

### 5.3 Event

Symboles et fichiers trouvés :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
```

Preuves utiles :

```text
MapEventDefinition : événement de map à pages conditionnelles.
MapEventSceneTarget : contrat authoring qui pointe vers une SceneAsset.
event_properties_panel.dart : libellé `Scene V1`, dropdown `event-scene-target-dropdown`.
event_properties_panel.dart : message `Lien authoring uniquement, runtime Scene à venir.`
event_properties_panel.dart : conditions incluant `rawJson`.
```

Décision : Event est `PARTIAL`, avec un gap P0 sur le flux produit.

### 5.4 Scene Builder

Symboles et fichiers trouvés :

```text
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes/scenes_workspace.dart
```

Preuves utiles :

```text
SceneGraphReadOnlyView : graph nodes/edges/ports + layout local.
SceneNodeReadOnlyInspector : payloads yarnDialogue, battle, cinematic, condition, action, branchByOutcome, merge.
SceneNodeReadOnlyInspector : certains modes restent `Lecture seule` ou `Authoring V0`.
```

Décision : Scene Builder est `PARTIAL`, pas encore creator-ready pour Selbrume complète.

### 5.5 Facts / World Rules

Symboles et fichiers trouvés :

```text
packages/map_core/lib/src/models/narrative_fact.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart
packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
packages/map_editor/lib/src/ui/canvas/facts_world_rules_workspace.dart
```

Diagnostics trouvés :

```text
worldRuleSourceMissing
worldRuleSourceUnknown
worldRuleSourceUnsupported
worldRuleTargetMissing
worldRuleTargetUnknown
worldRuleEffectMissing
worldRuleEffectUnsupported
worldRuleEffectTargetMismatch
worldRuleConflict
worldRuleUsesRawTechnicalId
worldRuleLegacyPredicateLeak
```

Décision : système `READY_WITH_GAPS`, contenu Selbrume `NOT_READY`.

### 5.6 Validator

Symboles et fichiers trouvés :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
```

Décision :

```text
Validator core/domain : PARTIAL_READY
Validator Narrative Studio UI : MISSING
Validator beta : NOT_READY
```

### 5.7 Runtime / persistence

Symboles et fichiers trouvés :

```text
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_runtime/lib/src/application/runtime_story_branching.dart
packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart
packages/map_runtime/lib/src/application/save/file_game_save_repository.dart
```

Décision : runtime foundation `PARTIAL_READY`, product authoring loop `PARTIAL`.

## 6. Tests existants inventoriés

Commande d'inventaire :

```bash
rg --files packages | rg -i "storyline|story|scene|cinematic|dialogue|yarn|fact|world|rule|validator|event|runtime|save|load"
```

Synthèse utile :

```text
packages/map_core/test : 57 fichiers narratifs/cinématiques, 661 tests détectés.
packages/map_editor/test : 45 fichiers narratifs/cinématiques, 671 tests détectés.
packages/map_runtime/test : 152 fichiers narratifs/runtime, 1493 tests détectés.
packages/map_gameplay/test : 4 fichiers pertinents, 18 tests détectés.
```

Exemples core :

```text
packages/map_core/test/beta_playability_validator_test.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/narrative_validator_authoring_adapter_test.dart
packages/map_core/test/scene_runtime_executor_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
packages/map_core/test/storyline_authoring_operations_test.dart
packages/map_core/test/world_rule_authoring_operations_test.dart
packages/map_core/test/world_rule_diagnostics_test.dart
packages/map_core/test/world_rule_projection_test.dart
```

Exemples editor :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
packages/map_editor/test/facts_world_rules_manager_test.dart
packages/map_editor/test/global_story_studio_authoring_test.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/dialogue_editor_validation_test.dart
```

Exemples runtime :

```text
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart
packages/map_runtime/test/runtime_story_branching_test.dart
packages/map_runtime/test/file_game_save_repository_test.dart
```

Décision tests : la couverture de briques est forte. Le trou n'est pas l'absence totale de tests, mais l'absence de fermeture produit no-code globale validée par l'UI et le Validator.

## 7. Preuves par domaine

| Domaine | Preuve | Décision |
|---|---|---|
| Narrative shell | Sidebar montre les surfaces et `Validateur — Non branché`. | UI partielle. |
| Storyline | Modèles/UI/tests présents. | PARTIAL_READY. |
| Event | Contrat Scene Target et diagnostics présents ; runtime annoncé à venir. | P0 gap. |
| Scene | Graph/runtime/tests présents ; builder encore partiellement read-only. | PARTIAL. |
| Cinematic | V1 fermé par V1-136/V1-136-bis. | READY_WITH_RESERVES. |
| Dialogue | Studio/adapters/tests présents ; contenu Selbrume placeholder. | PARTIAL. |
| Facts/World Rules | Modèle/UI/tests présents ; Selbrume a 0 rule. | READY_WITH_GAPS. |
| Validator | Core présent ; UI Narrative Studio non branchée. | P0 gap. |
| Runtime | Hooks/adapters/save tests présents. | PARTIAL_READY. |
| Selbrume | V1-138 recommande V1-138-bis. | NOT_READY. |

## 8. Fichiers créés

```text
reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md
reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md
```

## 9. Fichiers modifiés

Fichiers modifiés par ce lot :

```text
reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md
reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md
```

Aucun fichier produit n'a été modifié.

## 10. Fichiers supprimés

```text
<aucun>
```

## 11. Contenu des fichiers créés

Le rapport principal créé contient les sections complètes suivantes :

```text
1. Résumé exécutif
2. Verdict global
3. Rappel de l'objectif produit
4. Méthode d'audit
5. État de l'UI observée
6. Matrice des concepts Narrative Studio
7. Analyse Storylines / Steps
8. Analyse Events
9. Analyse Scene Builder
10. Analyse Cinematic Builder
11. Analyse Dialogue Yarn
12. Analyse Facts / World Rules
13. Analyse Validator
14. Analyse runtime / persistence narrative
15. Analyse Golden Slice Selbrume
16. Matrice bêta Narrative Studio
17. Matrice UX no-code
18. Gaps bloquants
19. Backlog V2
20. Proposition de prochains lots
21. Décision recommandée
22. Non-objectifs confirmés
23. Auto-critique finale
24. Critique du prompt
```

Le présent Evidence Pack est le deuxième fichier créé et contient les preuves factuelles du lot.

## 12. Auto-review indépendante

| Point vérifié | Verdict |
|---|---|
| Le rapport répond à l'objectif produit. | OK |
| Le rapport distingue modèle, UI, runtime et persistance. | OK |
| Les vrais blockers bêta sont identifiés. | OK |
| Selbrume n'est pas confondu avec le produit générique. | OK |
| Le Cinematic Builder n'est pas rouvert. | OK |
| Le statut Validator est clair. | OK |
| Le statut Event Builder est clair. | OK |
| Les prochains lots sont petits et actionnables. | OK |
| Aucun code produit n'est modifié. | À confirmer par anti-scope final. |

## 13. Critique du prompt

Le prompt est utile mais très large. Il demande un audit produit, code, runtime, UX, tests et Selbrume dans un seul lot. Cela donne un bon verdict transversal, mais une session UI manuelle restera nécessaire avant une décision bêta finale.

Les zones les plus mouvantes sont :

- Scene Builder ;
- Event Builder / Map Event inspector ;
- Validator UI ;
- Golden Slice Selbrume.

Le prochain lot recommandé devrait viser Event Builder / Event Scene Bridge avant de reprendre l'authoring Selbrume. V1-138-bis reste aussi nécessaire pour les IDs canoniques de contenu.

## 14. Validations finales

### 14.1 git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

Verdict : OK.

### 14.2 Anti-scope produit

Commande :

```bash
git diff --name-only -- packages examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

Verdict : aucun fichier produit, exemple, asset, Selbrume ou `pubspec.yaml` n'a été modifié.

### 14.3 État Git final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

Sortie utile exacte :

```text
?? reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md
?? reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md
```

`git diff --stat` et `git diff --name-only` ne retournent aucune ligne car les deux rapports sont de nouveaux fichiers non trackés.

Verdict final anti-scope :

```text
NS-STUDIO-AUDIT-001 : DONE documentaire.
Aucun code produit modifié.
Aucun fichier Selbrume modifié.
Aucune Visual Gate créée.
```
