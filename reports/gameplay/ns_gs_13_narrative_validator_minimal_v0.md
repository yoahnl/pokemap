# NS-GS-13 — Narrative Validator Minimal V0

## 1. Résumé exécutif

NS-GS-13 ajoute un validator narratif minimal générique dans `map_core`.

Résultat :

```text
PokeMap dispose maintenant d'un rapport de diagnostics narratifs V0,
pure Dart, sans Flutter, sans Flame, sans map_runtime et sans map_editor.
```

Le validator diagnostique sans exécuter, sans muter et sans corriger :

```text
Event déclenche.
Scene orchestre.
Battle résout.
World Rule projette.
Validator diagnostique.
```

Statut proposé :

```text
NS-GS-13 : DONE.
Prochain lot recommandé : NS-GS-14 — Item Pickup / GiveItem Authoring Readiness.
```

## 2. Roadmap lue et statut initial

Fichier lu avant modification :

```text
MVP Selbrume/road_map.md
```

Statut initial observé :

```text
PHASE 5 — Sécurité no-code
🔜 NS-GS-13   — Narrative Validator Minimal V0

# Prochain lot exact
🔜 NS-GS-13 — Narrative Validator Minimal V0
```

Git status initial exact :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
(no output)
```

## 3. Périmètre exact du lot

Inclus :

```text
- audit du validator existant ;
- ajout d'un validator narratif V0 multi-diagnostics ;
- ajout de tests ciblés ;
- export public depuis map_core ;
- mise à jour de road_map.md ;
- rapport Evidence Pack.
```

Exclus :

```text
- Selbrume final ;
- project.json ;
- fixture disque ;
- UI Narrative Studio ;
- map_runtime ;
- map_editor ;
- map_battle ;
- build_runner ;
- auto-fix des erreurs projet.
```

## 4. Frontière Event / Scene / Battle / World Rule / Validator

Frontière respectée :

```text
Event = source runtime, par exemple sourceEntityInteract ou sourceOutcome.
Scene = graphe ScenarioAsset et ses actions/branches.
Battle = effet startTrainerBattle ; le validator vérifie les refs, il ne résout pas le combat.
World Rule = predicates de map entity, lus passivement.
Validator = diagnostic statique, aucun effet runtime.
```

Le validator ne devient pas executor :

```text
- aucune GameState mutation ;
- aucun dispatch scénario ;
- aucun chargement disque ;
- aucun widget ;
- aucune correction automatique.
```

## 5. Audit initial

Commandes obligatoires exécutées :

```bash
rg "Validator|Validation|Diagnostic|diagnose|diagnostic|severity|warning|error" packages/map_core packages/map_editor packages/map_runtime --type dart

rg "ScenarioAsset|ScenarioNode|ScenarioNodeType|sourceNode|actionKind|condition|trueBranch|falseBranch|nextNode|dialogueId|trainerId|battleId|outcomeId|flagIsSet|stepCompleted|sourceOutcome|entityInteract" packages/map_core packages/map_runtime --type dart

rg "dialogues|scenarios|trainers|maps|entities|worldRules|visibleWhen|hiddenWhen|conditional" packages/map_core/lib/src/models packages/map_core/test --type dart
```

Conclusions :

```text
ProjectValidator existe déjà dans packages/map_core/lib/src/validation/validators.dart.
MapValidator existe déjà pour MapData et certains dialogues de map.
Des modèles de diagnostics existent ailleurs, notamment SurfaceCatalogDiagnostic.
ProjectManifest contient maps, dialogues, scripts, scenarios et trainers.
ScenarioAsset contient nodes/edges, binding et payload.
MapData contient entities et leurs NPC visibility/conditional dialogues.
```

## 6. Validator ou diagnostics existants

Existant caractérisé :

```text
ProjectValidator.validate(ProjectManifest)
MapValidator.validate(MapData)
ValidationException
SurfaceCatalogDiagnostic / SurfaceCatalogDiagnosticsReport
```

Limite de l'existant pour NS-GS-13 :

```text
ProjectValidator lève une ValidationException au premier problème.
Il ne produit pas de rapport multi-diagnostics.
Il ne couvre pas les warnings d'authoring no-code comme unreachable node
ou outcome emitted/consumed mismatch.
```

## 7. Décision après audit

Cas retenu :

```text
Cas B — Aucun validator narratif multi-diagnostics dédié,
mais les modèles sont suffisants pour une validation pure.
```

Décision :

```text
Créer une brique minimale dans map_core :
packages/map_core/lib/src/operations/narrative_validator.dart
```

Raison :

```text
Le validator doit être consommable plus tard par map_editor et map_runtime
sans dépendre d'eux.
```

## 8. API ajoutée ou caractérisée

API ajoutée :

```dart
NarrativeValidationReport diagnoseNarrativeProject(
  ProjectManifest manifest, {
  Iterable<MapData> maps = const [],
})
```

Types ajoutés :

```dart
NarrativeValidationSeverity
NarrativeValidationDiagnosticKind
NarrativeValidationDiagnostic
NarrativeValidationReport
```

Export public :

```dart
export 'src/operations/narrative_validator.dart';
```

Propriétés du rapport :

```text
diagnostics
count
errorCount
warningCount
hasDiagnostics
hasErrors
byKind(kind)
égalité stable
tri déterministe
```

## 9. Diagnostics V0 couverts

Erreurs :

```text
scenarioNodeReferencesUnknownNode
scenarioGraphHasNoSource
openDialogueReferencesUnknownDialogue
startTrainerBattleMissingTrainerId
startTrainerBattleReferencesUnknownTrainer
startTrainerBattleMissingNpcEntityId
startTrainerBattleBlankBattleId
sourceEntityInteractReferencesUnknownMap
sourceEntityInteractReferencesUnknownEntity
conditionalDialogueReferencesUnknownDialogue
```

Warnings :

```text
scenarioGraphHasUnreachableNode
sourceOutcomeWithoutMatchingEmitOutcome
emitOutcomeWithoutMatchingSourceOutcome
flagReadNeverProduced
setFlagNeverRead
stepReadNeverCompleted
completeStepNeverRead
```

## 10. Diagnostics volontairement hors scope

Hors scope V0 :

```text
- validation complète de tous les ProjectManifest models ;
- résolution de fichiers dialogue Yarn depuis disque ;
- validation des Yarn nodes ;
- validation complète battle/team/species/moves ;
- validation des scripts runtime externes ;
- validation de tous les facts potentiellement produits hors scénario ;
- correction automatique des graphes.
```

Limite précise :

```text
sourceEntityInteract valide l'entityId seulement lorsque le MapData concerné
est fourni à diagnoseNarrativeProject(..., maps: [...]).
ProjectManifest seul ne contient que les entrées de map, pas leurs entities.
```

## 11. Fichiers créés / modifiés

```text
CRÉÉ   packages/map_core/lib/src/operations/narrative_validator.dart
CRÉÉ   packages/map_core/test/narrative_validator_test.dart
MODIFIÉ packages/map_core/lib/map_core.dart
MODIFIÉ MVP Selbrume/road_map.md
CRÉÉ   reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
```

Inventaire avant rapport :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
     884   27837 packages/map_core/lib/src/operations/narrative_validator.dart
untracked
packages/map_core/test/narrative_validator_test.dart
     504   14763 packages/map_core/test/narrative_validator_test.dart
untracked
packages/map_core/lib/map_core.dart
     130    7250 packages/map_core/lib/map_core.dart
tracked
```

## 12. Tests ajoutés ou modifiés

Fichier :

```text
packages/map_core/test/narrative_validator_test.dart
```

16 tests :

```text
1. valid minimal golden slice returns no diagnostics
2. unknown edge target produces error
3. unreachable node produces warning
4. scenario without source produces error
5. openDialogue with unknown dialogue produces error
6. startTrainerBattle with unknown trainer produces error
7. startTrainerBattle with blank trainerId produces error
8. startTrainerBattle with blank npcEntityId produces error
9. startTrainerBattle with explicit blank battleId produces error
10. source entityInteract with unknown map produces error
11. source entityInteract with unknown entity produces error
12. sourceOutcome without matching emitOutcome produces warning
13. emitOutcome without matching sourceOutcome produces warning
14. setFlag used by condition does not warn as unused
15. completeStep used by world rule does not warn as unused
16. diagnostics are stable and sorted deterministically
```

Fixtures :

```text
Toutes les fixtures sont in-memory.
Ids génériques test_*.
Aucune fixture disque.
Aucun project.json.
Aucun id Selbrume final.
```

## 13. Commandes exécutées

```bash
git status --short --untracked-files=all

rg "Validator|Validation|Diagnostic|diagnose|diagnostic|severity|warning|error" packages/map_core packages/map_editor packages/map_runtime --type dart

rg "ScenarioAsset|ScenarioNode|ScenarioNodeType|sourceNode|actionKind|condition|trueBranch|falseBranch|nextNode|dialogueId|trainerId|battleId|outcomeId|flagIsSet|stepCompleted|sourceOutcome|entityInteract" packages/map_core packages/map_runtime --type dart

rg "dialogues|scenarios|trainers|maps|entities|worldRules|visibleWhen|hiddenWhen|conditional" packages/map_core/lib/src/models packages/map_core/test --type dart

cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart test --reporter compact
```

RED TDD :

```text
Le premier test ciblé a échoué avant implémentation avec :
Method not found: 'diagnoseNarrativeProject'
Undefined name 'NarrativeValidationDiagnosticKind'
Undefined name 'NarrativeValidationSeverity'
```

## 14. Résultats des tests

Commande obligatoire finale :

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
```

Sortie utile complète :

```text
00:00 +0: loading test/narrative_validator_test.dart
00:00 +0: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +14: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +14: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +15: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +15: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +16: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +16: All tests passed!
EXIT:0
```

Régression package après export public :

```bash
cd packages/map_core && dart test --reporter compact
```

Sortie finale :

```text
00:04 +1921: All tests passed!
EXIT:0
```

## 15. Résultat analyzer

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 16. Résultat git diff --check

Commande finale :

```bash
git diff --check
```

Sortie exacte :

```text
EXIT:0
```

Verdict :

```text
PASS — aucune erreur whitespace dans le diff tracked.
```

## 17. Mise à jour road_map.md

Changements appliqués :

```text
NS-GS-13 marqué ✅.
NS-GS-14 marqué 🔜.
Prochain lot exact remplacé par NS-GS-14.
Section "Mise à jour NS-GS-13 — 2026-05-24" ajoutée.
```

Résumé roadmap ajouté :

```text
Narrative Validator minimal ajouté dans map_core.
Cas B retenu.
16 tests ciblés.
Analyzer clean.
Limites V0 documentées.
Mechanics-first confirmé.
Aucune fixture Selbrume finale.
Aucun project.json.
```

## 18. Limites restantes

```text
Le validator V0 est in-memory.
Il ne charge pas les dialogues Yarn depuis disque.
Il ne valide pas les nodes Yarn internes.
Il ne valide pas les teams trainer / species / moves.
Il ne sait valider sourceEntityInteract.entityId que si MapData est fourni.
Les facts/steps peuvent être produits par d'autres systèmes hors scénario ;
les mismatches flag/step sont donc des warnings, pas des errors.
```

## 19. Prochain lot recommandé

```text
NS-GS-14 — Item Pickup / GiveItem Authoring Readiness
```

Justification :

```text
Le validator minimal est utilisable et testé.
Les diagnostics obligatoires V0 sont couverts ou documentés.
Pas de blocage structurel nécessitant NS-GS-13-bis.
```

## 20. Evidence Pack

### Git status initial

```text
(no output)
```

### Fichiers untracked couverts

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
```

Inventaire final :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
     884   27837 packages/map_core/lib/src/operations/narrative_validator.dart
untracked
packages/map_core/test/narrative_validator_test.dart
     504   14763 packages/map_core/test/narrative_validator_test.dart
untracked
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
     646   17608 reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
untracked
```

Preuve no-index stat :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
 .../lib/src/operations/narrative_validator.dart    | 884 +++++++++++++++++++++
 1 file changed, 884 insertions(+)
packages/map_core/test/narrative_validator_test.dart
 .../map_core/test/narrative_validator_test.dart    | 504 +++++++++++++++++++++
 1 file changed, 504 insertions(+)
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
 .../ns_gs_13_narrative_validator_minimal_v0.md     | 646 +++++++++++++++++++++
 1 file changed, 646 insertions(+)
```

### Absence d'ids Selbrume

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/test/narrative_validator_test.dart packages/map_core/lib/map_core.dart
```

Sortie :

```text
(no output)
```

### git diff --stat

Commande finale :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map.md            | 32 +++++++++++++++++++++++++-------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 26 insertions(+), 7 deletions(-)
```

Note :

```text
git diff --stat ne couvre que les fichiers tracked.
Les fichiers untracked sont couverts par inventaire et no-index stat ci-dessus.
```

### git diff --name-only

Commande finale :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map.md
packages/map_core/lib/map_core.dart
```

### git status final

Commande finale :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/narrative_validator.dart
?? packages/map_core/test/narrative_validator_test.dart
?? reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
```

## 21. Auto-review critique

Points solides :

```text
- validator pure Dart dans map_core ;
- pas de runtime/editor ;
- 16 tests ciblés ;
- diagnostics errors/warnings ;
- tri déterministe ;
- tests ciblés et package complet verts ;
- analyze clean ;
- roadmap mise à jour.
```

Limites et vigilance :

```text
- ProjectValidator reste throw-based ; le nouveau validator ne le remplace pas.
- V0 ne charge pas les fichiers projet depuis disque.
- V0 ne valide pas tout PokeMap.
- Les warnings flag/step peuvent signaler des productions/lectures hors scope ;
  ils doivent rester des warnings.
- Les fichiers créés restent untracked jusqu'au commit manuel.
```

Verdict :

```text
NS-GS-13 peut être proposé DONE.
Prochain lot recommandé : NS-GS-14.
```
