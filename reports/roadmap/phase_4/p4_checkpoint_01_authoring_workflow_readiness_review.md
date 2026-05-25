# P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

## 1. Résumé exécutif

Verdict : Phase 4 clôturable avec réserves mineures.

La Phase 4 a suffisamment prouvé les workflows authoring minimaux pour passer à
la Phase 5. La preuve est volontairement bornée : elle est pure Dart,
`map_core`, in-memory et testée. Elle ne prouve pas encore une UI editor, un
projet disque complet, une boucle runtime, ni une expérience produit finale.

Ce qui est clôturable :

- read models / pickers V0 pour les références narratives nécessaires ;
- draft scenario minimal et compilation déterministe vers `ScenarioAsset` ;
- opérations authoring Event Source ;
- opérations authoring Outcome / Battle Outcome ;
- drafts Predicate / Visibility Rule / Conditional Dialogue ;
- adapter de diagnostics authoring sans auto-fix ;
- golden path P4-07 chaînant les briques Phase 4.

Décision :

```text
Phase 4 : clôturée avec réserves mineures.
Phase suivante : Phase 5 — Gameplay Gaps Prioritaires.
Prochain lot exact : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit.
```

Le nom de Phase 5 reprend le nom exact déjà présent dans
`MVP Selbrume/road_map_global.md`.

## 2. Scope du checkpoint

Inclus :

- audit des lots P4-00 à P4-07 ;
- classement des preuves authoring ;
- distinction entre preuve authoring pure, UI editor, runtime, disque et produit
  final ;
- décision de clôture Phase 4 ;
- recommandation Phase 5 ;
- mise à jour `MVP Selbrume/road_map_phase_4.md` ;
- mise à jour `MVP Selbrume/road_map_global.md` ;
- création `MVP Selbrume/road_map_phase_5.md` ;
- création de ce rapport checkpoint.

Exclus :

- code de production ;
- tests P4 ;
- fixtures P4 ;
- nouveau test ;
- nouvelle API ;
- UI ;
- Scene Builder ;
- Cinematic Builder ;
- Selbrume final ;
- rewards / money / XP en code ;
- runtime ;
- P5-00.

## 3. Sources lues

Instructions et roadmaps :

- `AGENTS.md`
- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- tentative de lecture de `MVP Selbrume/road_map_phase_5.md` avant création :
  fichier absent.

Rapports Phase 4 :

- `reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md`
- `reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md`
- `reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md`
- `reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md`
- `reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md`
- `reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md`
- `reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md`
- `reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md`
- `reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md`

Fichiers de preuve inspectés :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `packages/map_core/test/narrative_scenario_authoring_draft_test.dart`
- `packages/map_core/test/narrative_event_source_authoring_operations_test.dart`
- `packages/map_core/test/narrative_outcome_authoring_operations_test.dart`
- `packages/map_core/test/narrative_predicate_authoring_draft_test.dart`
- `packages/map_core/test/narrative_validator_authoring_adapter_test.dart`
- `packages/map_core/test/narrative_authoring_golden_path_test.dart`

Checkpoints précédents :

- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`
- `reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md`

Aucun fichier obligatoire Phase 4 n'a été constaté absent.

## 4. État des lots Phase 4

| Lot | Livrable | Statut | Valeur produite | Preuve | Réserve | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| P4-00 | Rapport audit/recalibration | Terminé | Roadmap recalibrée vers preuves concrètes | Documentaire gouvernance | Pas de code, volontaire | Accepté |
| P4-01 | Read models / picker options | Terminé | Story Step, Event Source, Predicate Reference V0 en plus de Scenario/Outcome/Battle | Code pur + tests | Pas UI picker | Accepté |
| P4-01-bis | Evidence pack completion | Terminé | Preuves documentaires P4-01 complétées | Documentation | Aucun code | Accepté |
| P4-02 | Scenario authoring draft | Terminé | Draft scenario, validation, compilation `ScenarioAsset` | Code pur + tests | Pas authoring UI | Accepté |
| P4-03 | Event Source operations | Terminé | Option -> source draft, validation, remplacement, compilation des 4 sources | Code pur + tests | Pas Event Builder | Accepté |
| P4-04 | Outcome / Battle operations | Terminé | Declare/emit/receive outcome, startTrainerBattle, helpers flags, diagnostics | Code pur + tests | Pas battle complet/rewards | Accepté |
| P4-05 | Predicate / World Rule draft | Terminé | Predicate, visibility rule, conditional dialogue drafts vers modèles runtime existants | Code pur + tests | Pas FactRegistry/WorldRuleRegistry ni UI | Accepté |
| P4-06 | Validator authoring adapter | Terminé | Diagnostics techniques -> vues authoring lisibles, sans auto-fix | Code pur + tests | Pas Validator UI | Accepté |
| P4-07 | Golden path authoring | Terminé | Chaînage read models -> drafts -> compilation -> diagnostics authoring | Test pur | Pas runtime/disque/UI | Accepté |

## 5. Matrice de preuve authoring

| Sujet | Preuve produite | Lot(s) | Niveau atteint | Limite restante | Décision |
| --- | --- | --- | --- | --- | --- |
| Scenario picker / scenario selection | `NarrativeScenarioPickerOption` et builder existants confirmés/testés | P4-01 | Authoring pur / read model | Pas UI de sélection | Suffisant pour Phase 5 |
| Outcome picker | `NarrativeOutcomePickerOption` couvre déclarés/émis/consommés | P4-01, P4-07 | Authoring pur / read model | Pas Outcome Builder UI | Suffisant |
| Battle reference picker | `NarrativeBattleReferencePickerOption` + victory/defeat | P4-01, P4-07 | Authoring pur / read model | Pas combat complet | Suffisant |
| Story Step picker | `NarrativeStoryStepPickerOption` depuis metadata Step Studio / legacy | P4-01 | Authoring pur / read model | Pas Step Studio UI final | Suffisant |
| Event Source picker | `NarrativeEventSourcePickerOption` pour mapEnter/triggerEnter/entityInteract/outcomeReceived | P4-01, P4-03, P4-07 | Authoring pur / read model | Pas Event Builder UI | Suffisant |
| Predicate reference picker | `NarrativePredicateReferencePickerOption` pour flags/steps/cutscenes/outcomes/battle outcomes | P4-01, P4-05, P4-07 | Authoring pur / read model | Pas Fact UI | Suffisant |
| Scenario authoring draft | `NarrativeScenarioAuthoringDraft` | P4-02, P4-07 | Authoring pur / draft | Pas persistence draft | Suffisant |
| Draft validation | `validateNarrativeScenarioAuthoringDraft` | P4-02, P4-07 | Authoring pur / diagnostics | Ne remplace pas validator global | Suffisant |
| Draft -> ScenarioAsset compilation | `compileNarrativeScenarioAuthoringDraftToScenarioAsset` | P4-02, P4-07 | Authoring pur -> modèle existant | Pas écriture disque | Suffisant |
| Event source option -> source draft | `createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption` | P4-03, P4-07 | Authoring pur / opération | Pas UI | Suffisant |
| Event source validation against options | `validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions` | P4-03, P4-07 | Authoring pur / diagnostics | Pas validation runtime joueur | Suffisant |
| Draft source replacement | `replaceNarrativeScenarioAuthoringDraftSource` | P4-03 | Authoring pur / immutabilité | Pas éditeur visuel | Suffisant |
| Declared outcome authoring | `addDeclaredOutcomeToNarrativeScenarioAuthoringDraft` | P4-04, P4-07 | Authoring pur / opération | Pas UI Outcome Builder | Suffisant |
| emitOutcome authoring | `addEmitOutcomeActionToNarrativeScenarioAuthoringDraft` | P4-04, P4-07 | Authoring pur / opération | Pas branches riches | Suffisant |
| outcomeReceived source authoring | `createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption` | P4-04, P4-07 | Authoring pur / opération | Pas graph UI | Suffisant |
| startTrainerBattle authoring | `addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft` | P4-04, P4-07 | Authoring pur / opération | Pas combat/rewards | Suffisant |
| scenario.outcome.* helper | `narrativeScenarioOutcomeFlagReference` | P4-04, P4-05, P4-07 | Authoring pur / helper | Reste flag technique | Suffisant |
| battle:* helper | `narrativeBattleOutcomeFlagReference` | P4-04, P4-05, P4-07 | Authoring pur / helper | Pas BattleRegistry | Suffisant |
| Outcome/Battle diagnostics | `validateNarrativeOutcomeAuthoringDraft` | P4-04 | Authoring pur / diagnostics | Pas validator UI | Suffisant |
| Predicate draft | `NarrativePredicateAuthoringDraft` | P4-05, P4-07 | Authoring pur / draft | Pas FactRegistry | Suffisant |
| Visibility rule draft | `NarrativeVisibilityRuleAuthoringDraft` -> `MapEntityNpcVisibilityRule` | P4-05, P4-07 | Authoring pur -> modèle runtime existant | Pas world rule UI | Suffisant |
| Conditional dialogue draft | `NarrativeConditionalDialogueAuthoringDraft` -> `MapEntityConditionalDialogue` | P4-05, P4-07 | Authoring pur -> modèle runtime existant | Pas Yarn UI complet | Suffisant |
| Predicate diagnostics | `validateNarrativePredicateAuthoringDraft` et validations liées | P4-05 | Authoring pur / diagnostics | Pas validator UI | Suffisant |
| Validator authoring adapter | `buildNarrativeAuthoringDiagnosticView(s)` | P4-06, P4-07 | Authoring pur / adapter | Pas UI de rendu | Suffisant |
| Authoring diagnostic categories | Catégories scenario/event/dialogue/battle/outcome/predicate/runtime/unknown | P4-06 | Authoring pur / présentation | Pas taxonomie finale | Suffisant |
| Authoring action hints | Hints sans mutation ni correction automatique | P4-06 | Authoring pur / aide auteur | Pas auto-fix | Suffisant |
| No auto-fix guarantee | `hasAutomaticFix == false` testé | P4-06, P4-07 | Authoring pur / garantie testée | Pas workflow correction UI | Suffisant |
| Minimal authoring golden path | `narrative_authoring_golden_path_test.dart` | P4-07 | Authoring pur / workflow in-memory | Pas disque/runtime/UI | Suffisant |
| No registry guarantee | Aucun Fact/World/Outcome/Battle/Event registry persistant créé | P4-01 à P4-07 | Garantie de scope | Références restent dérivées | Suffisant |
| No UI guarantee | Aucune UI créée ou modifiée | P4-00 à P4-07 | Garantie de non-scope | UI editor non prouvée | Report Phase 7 |

## 6. Ce que Phase 4 a prouvé

Phase 4 a prouvé :

- les read models nécessaires à l'authoring minimal existent en V0 ;
- le draft scenario minimal est validable et compilable ;
- les sources Event peuvent être choisies via read model puis transformées en
  source draft ;
- les outcomes scénario peuvent être déclarés, émis et reçus sans registry ;
- `startTrainerBattle` peut être authoré depuis une battle option ;
- `scenario.outcome.*` et `battle:*` restent séparés ;
- les predicates/world rules passifs peuvent être authorés comme drafts et
  compilés vers les structures runtime existantes ;
- les diagnostics techniques du validator peuvent être présentés en vues
  authoring stables et actionnables ;
- un golden path pur compose toutes ces briques sans JSON brut comme expérience
  principale et sans UI premium.

Réponses aux questions obligatoires 1 à 8 :

1. La Phase 4 est clôturable : oui, avec réserves mineures.
2. Les read models nécessaires à l'authoring minimal sont prouvés : oui, en V0.
3. Le draft scenario minimal est prouvé : oui.
4. Les opérations Event Source sont prouvées : oui.
5. Les opérations Outcome / Battle Outcome sont prouvées : oui.
6. Les drafts Predicate / World Rule passifs sont prouvés : oui.
7. L'adapter de diagnostics authoring est prouvé : oui.
8. Le golden path P4-07 prouve le chaînage : oui, en pur `map_core` in-memory.

## 7. Ce que Phase 4 n’a pas prouvé

Non prouvé côté UI editor :

- interface interactive de sélection ;
- panneaux editor ;
- forms no-code ;
- drag/drop Scene Builder ;
- Cinematic Builder ;
- Validator UI ;
- ergonomie produit finale.

Non prouvé côté runtime :

- boucle PlayableMapGame depuis les drafts P4 ;
- interactions joueur ;
- combat complet ;
- rewards/money/XP ;
- save menu runtime.

Non prouvé côté project disk / persistence :

- écriture des drafts vers `project.json` ;
- roundtrip disk des workflows authoring P4 ;
- migration de projets existants ;
- projet créé dans `map_editor` puis lancé dans host.

Non prouvé côté produit final :

- Selbrume réel ;
- campagne finale ;
- UI premium ;
- parité Pokémon officielle ;
- boucle RPG complète.

Réponses aux questions obligatoires 9 à 14 :

9. UI editor non prouvée : oui, elle reste explicitement reportée.
10. Runtime non prouvé par Phase 4 : oui, Phase 3 couvre le runtime technique,
    pas les workflows authoring P4 en runtime.
11. Project disk/persistence non prouvé par Phase 4 : oui.
12. Phase 5 doit traiter les gaps gameplay / RPG loop.
13. Phase 6 doit rester le Selbrume Golden Slice réel.
14. Phase 7 doit rester l'UI/UX moderne finale.

## 8. Réserves et risques restants

Réserves mineures :

- les preuves P4 sont in-memory et pures, pas intégrées dans `map_editor` ;
- les drafts ne sont pas encore persistés ;
- les diagnostics sont adaptables côté auteur, mais pas encore rendus dans une
  UI ;
- la compilation produit des `ScenarioAsset`, mais pas un projet disque complet ;
- les helpers outcome/battle restent techniques et doivent être présentés par
  des labels côté UI future ;
- gameplay rewards/money/XP reste complètement hors Phase 4.

Risques pour Phase 5 :

- ouvrir rewards/money/XP trop largement au lieu d'un contrat minimal ;
- transformer P5 en UI work alors qu'elle doit rester mechanics-first ;
- confondre progression gameplay et facts narratifs ;
- créer trop tôt un système complet de parité Pokémon ;
- utiliser Selbrume comme contenu à générer au lieu d'un futur test produit.

## 9. Décision de clôture Phase 4

Décision : Phase 4 clôturée avec réserves mineures.

Justification :

- tous les lots P4-00 à P4-07 existent et sont classés ;
- les lots concrets P4-01 à P4-07 ont produit du code pur/testable ou une preuve
  de chaînage ;
- les preuves couvrent le workflow authoring minimal demandé ;
- aucun registry persistant n'a été créé ;
- aucune UI premium n'a été créée ;
- les limites editor/runtime/disk sont explicites et non maquillées.

Réponses aux questions obligatoires 15 et 16 :

15. Prochaine phase : Phase 5 — Gameplay Gaps Prioritaires.
16. Prochain lot exact : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop
    Audit.

## 10. Recommandation Phase 5

Phase suivante : Phase 5 — Gameplay Gaps Prioritaires.

Objectif opérationnel :

```text
Fermer la boucle RPG minimale nécessaire à une bêta jouable : New Game, état
initial, party, bag, combat, capture, rewards, XP, heal center, save/load
runtime et validation de jouabilité.
```

Roadmap Phase 5 créée :

- P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
- P5-01 — New Game / Initial GameState Contract Review
- P5-02 — Starter / Initial Party Minimal Flow
- P5-03 — Runtime Party Menu Minimal Read Model
- P5-04 — Bag / Item Use Runtime Minimal Contract
- P5-05 — Heal Center Minimal Flow
- P5-06 — Battle Rewards / Money / XP Minimal Contract
- P5-07 — Capture Destination / Party-or-Box Decision
- P5-08 — Gameplay Save/Load Beta Roundtrip
- P5-09 — Beta Playability Validator Plan
- P5-CHECKPOINT-01 — Gameplay Loop Readiness Review

P5-00 doit rester un audit. P5-01 à P5-09 ne sont pas exécutés pendant ce
checkpoint.

## 11. Roadmaps mises à jour

Roadmaps mises à jour :

- `MVP Selbrume/road_map_phase_4.md`
- `MVP Selbrume/road_map_global.md`

Roadmap créée :

- `MVP Selbrume/road_map_phase_5.md`

Changements :

- P4-CHECKPOINT-01 marqué terminé ;
- Phase 4 marquée clôturée avec réserves mineures ;
- Phase courante globale déplacée vers Phase 5 ;
- roadmap Phase 5 créée ;
- prochain lot exact fixé à P5-00.

## 12. Prochain lot exact

```text
P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
```

P5-00 n'a pas été exécuté pendant ce checkpoint.

## 13. Modifications effectuées

Fichiers créés :

- `reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md`
- `MVP Selbrume/road_map_phase_5.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_4.md`
- `MVP Selbrume/road_map_global.md`

Aucun fichier de code, aucun test P4 et aucun fichier `packages/map_core/lib`
n'a été modifié.

## 14. Evidence Pack

### 14.1 git status initial exact

```text
(aucune sortie)
```

### 14.2 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,260p' AGENTS.md
sed -n '1,220p' skills/README.md || true
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1020p' "MVP Selbrume/road_map_phase_4.md"
for f in reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md; do echo "===== $f ====="; sed -n '1,260p' "$f"; done
find reports/roadmap/phase_4 -maxdepth 1 -type f | sort
rg -n "P4-00|P4-01|P4-02|P4-03|P4-04|P4-05|P4-06|P4-07|P4-CHECKPOINT|P5-00|Phase 5|Gameplay|RPG Loop|Authoring|registry|auto-fix|Scene Builder|Cinematic Builder|Selbrume" "MVP Selbrume" reports/roadmap/phase_4 packages/map_core/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,220p' skills/verification-before-completion/SKILL.md || true
sed -n '1,360p' pokemap_roadmap_mecaniques_fangame.md || true
sed -n '1,360p' "MVP Selbrume/road_map_phase_5.md" || true
sed -n '1,260p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
sed -n '1,220p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '1,220p' packages/map_core/test/narrative_scenario_authoring_draft_test.dart
sed -n '1,220p' packages/map_core/test/narrative_event_source_authoring_operations_test.dart
sed -n '1,220p' packages/map_core/test/narrative_outcome_authoring_operations_test.dart
sed -n '1,220p' packages/map_core/test/narrative_predicate_authoring_draft_test.dart
sed -n '1,220p' packages/map_core/test/narrative_validator_authoring_adapter_test.dart
sed -n '1,260p' packages/map_core/test/narrative_authoring_golden_path_test.dart
sed -n '1,260p' reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
sed -n '1,260p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
sed -n '1,300p' reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md
sed -n '360,760p' "MVP Selbrume/road_map_global.md"
rg -n "Phase 4|Phase 5|Historique|checkpoint|clôturée|Lot courant|Prochain lot|road_map_phase_5" "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_4.md"
sed -n '1,460p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,160p' "MVP Selbrume/road_map_global.md"
sed -n '399,520p' "MVP Selbrume/road_map_global.md"
sed -n '594,746p' "MVP Selbrume/road_map_global.md"
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core/lib
git diff --name-only -- packages/map_core/test
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

### 14.3 Sorties utiles

- Le `find reports/roadmap/phase_4` a listé les rapports P4-00 à P4-07 avant
  création du checkpoint.
- Le `rg` obligatoire a confirmé la présence des lots Phase 4, des contrôles
  anti-registry/anti-auto-fix/anti-UI et des mentions de P5 dans les roadmaps et
  rapports. La sortie est volumineuse ; elle contient aussi des mentions
  historiques de Selbrume dans les documents de gouvernance, pas une création
  de contenu Selbrume par ce checkpoint.
- La tentative de lecture de `MVP Selbrume/road_map_phase_5.md` avant création a
  retourné :

```text
sed: MVP Selbrume/road_map_phase_5.md: No such file or directory
```

### 14.4 Tests

Aucun test P4 n'a été relancé pendant ce checkpoint.

Justification : le contrat du checkpoint demande de ne pas lancer les tests P4
sauf raison exceptionnelle ; les rapports P4 contiennent déjà les sorties de
tests et ce lot ne modifie aucun code ni test.

### 14.5 Fichiers créés

```text
reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md
MVP Selbrume/road_map_phase_5.md
```

### 14.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_global.md
```

### 14.7 git diff --check exact

```text
(aucune sortie)
```

### 14.8 git diff --stat exact

```text
 MVP Selbrume/road_map_global.md  | 89 ++++++++++++++++++++++++++--------------
 MVP Selbrume/road_map_phase_4.md | 33 ++++++++++++---
 2 files changed, 85 insertions(+), 37 deletions(-)
```

### 14.9 git diff --name-only exact

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_4.md
```

### 14.10 git status final exact

```text
 M "MVP Selbrume/road_map_global.md"
 M "MVP Selbrume/road_map_phase_4.md"
?? "MVP Selbrume/road_map_phase_5.md"
?? reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md
```

### 14.11 Contrôles hors scope

Contrôle explicite qu'aucun code n'a été modifié :

```text
(aucune sortie pour git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host)
```

Contrôle explicite qu'aucun test P4 n'a été modifié :

```text
(aucune sortie pour git diff --name-only -- packages/map_core/test)
```

Contrôle explicite qu'aucun fichier `map_core/lib` n'a été modifié :

```text
(aucune sortie pour git diff --name-only -- packages/map_core/lib)
```

Contrôle explicite que P5-00 n'a pas été exécuté :

```text
P5-00 apparaît seulement comme prochain lot exact dans les roadmaps et ce
rapport. Aucun fichier de code, test ou rapport P5-00 n'a été créé.
```

Contrôle explicite que Selbrume final n'a pas été créé :

```text
Aucun fichier de contenu Selbrume final, fixture Selbrume ou projet Selbrume n'a
été créé.
```

Contrôle explicite qu'aucun reward/money/XP n'a été ajouté :

```text
Rewards / money / XP sont uniquement mentionnés comme scope Phase 5. Aucun code
ou modèle gameplay n'a été ajouté.
```

Contrôle explicite qu'aucune UI premium n'a été créée :

```text
Aucun fichier map_editor, widget Flutter, Scene Builder ou Cinematic Builder
n'a été modifié ou créé.
```

## 15. Auto-review critique

- Le checkpoint clôture Phase 4 parce que les preuves demandées existent, mais
  il ne les transforme pas en preuve UI.
- La Phase 4 ne doit pas être vendue comme un end-to-end auteur final : elle
  prouve un socle pur exploitable.
- Le nom Phase 5 utilisé reprend `road_map_global.md` : `Phase 5 — Gameplay
  Gaps Prioritaires`, même si l'objectif opérationnel est la boucle RPG
  minimale.
- Les tests n'ont pas été relancés volontairement, conformément au contrat du
  checkpoint.

## 16. Regard critique sur le prompt

Le prompt est strict et utile : il force à ne pas transformer le checkpoint en
lot d'implémentation. La principale tension vient du nom Phase 5 : le prompt
propose `Gameplay / RPG Loop Minimal`, tandis que la roadmap globale existante
nomme déjà la phase `Gameplay Gaps Prioritaires`. Le checkpoint conserve le nom
global existant et inscrit l'objectif RPG loop minimal dans la roadmap Phase 5.
