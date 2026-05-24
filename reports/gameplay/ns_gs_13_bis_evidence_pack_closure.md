# NS-GS-13-bis — Evidence Pack Closure Only

## 1. Résumé exécutif

NS-GS-13-bis ferme uniquement la dette documentaire du lot NS-GS-13.

Le Narrative Validator Minimal V0 est accepté techniquement et reste inchangé dans ce bis. Aucun code fonctionnel, aucun test fonctionnel, aucun runtime, aucun éditeur, aucun contenu Selbrume final et aucun `project.json` n'ont été modifiés ou créés par ce bis.

Constat important : au moment de l'exécution de NS-GS-13-bis, `git status --short --untracked-files=all` ne liste aucune entrée initiale. Les fichiers NS-GS-13 ne sont donc plus untracked dans l'état local courant ; ils sont présents dans le commit `4c58ddff feat(NS-GS-13): add Narrative Validator Minimal V0 for no-code structural validation`. Le présent rapport ajoute néanmoins la preuve documentaire qui manquait : inventaire exact, tailles, hashes, imports, diagnostics, liste complète des 16 tests, commandes relancées, preuve d'absence des ids Selbrume interdits et statut Git final.

## 2. Périmètre du bis

Périmètre autorisé :

- création du présent rapport : `reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md` ;
- ajout d'une seule ligne de fermeture documentaire dans `MVP Selbrume/road_map.md`.

Périmètre explicitement non exécuté :

- pas de modification de `packages/map_core/lib/src/operations/narrative_validator.dart` ;
- pas de modification de `packages/map_core/test/narrative_validator_test.dart` ;
- pas de modification de `packages/map_core/lib/map_core.dart` ;
- pas de modification de `packages/map_runtime`, `packages/map_editor`, `packages/map_gameplay`, `packages/map_battle` ou `examples/playable_runtime_host` ;
- pas de NS-GS-14 démarré ;
- pas de contenu Selbrume final ;
- pas de `project.json` généré.

## 3. Git status initial

Commande exécutée au début du bis :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Interprétation : aucune ligne retournée.

## 4. Vérification du validator

Fichier vérifié :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
```

Inventaire :

```text
884 lignes
27837 octets
SHA-256 6bfaacc3f554bdb05959c59f2471d7bf6b9cb08c107b8d56cc4e5f1934afd0de
```

Imports observés :

```text
import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_entity_payloads.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';
```

Conclusion sur les dépendances :

- le validator est bien dans `map_core` ;
- il ne dépend pas de Flutter ;
- il ne dépend pas de Flame ;
- il ne dépend pas de `map_runtime` ;
- il ne dépend pas de `map_editor` ;
- il reste pure Dart côté modèle/opération.

API publique vérifiée dans `packages/map_core/lib/map_core.dart` :

```text
73:export 'src/operations/narrative_validator.dart';
```

Diagnostics V0 présents dans le code :

```text
scenarioNodeReferencesUnknownNode
scenarioGraphHasUnreachableNode
scenarioGraphHasNoSource
openDialogueReferencesUnknownDialogue
startTrainerBattleMissingTrainerId
startTrainerBattleReferencesUnknownTrainer
startTrainerBattleMissingNpcEntityId
startTrainerBattleBlankBattleId
sourceEntityInteractReferencesUnknownMap
sourceEntityInteractReferencesUnknownEntity
sourceOutcomeWithoutMatchingEmitOutcome
emitOutcomeWithoutMatchingSourceOutcome
conditionalDialogueReferencesUnknownDialogue
flagReadNeverProduced
setFlagNeverRead
stepReadNeverCompleted
completeStepNeverRead
```

Preuve de présence issue de `rg` :

```text
packages/map_core/lib/src/operations/narrative_validator.dart:33:enum NarrativeValidationDiagnosticKind {
packages/map_core/lib/src/operations/narrative_validator.dart:34:  scenarioNodeReferencesUnknownNode,
packages/map_core/lib/src/operations/narrative_validator.dart:35:  scenarioGraphHasUnreachableNode,
packages/map_core/lib/src/operations/narrative_validator.dart:36:  scenarioGraphHasNoSource,
packages/map_core/lib/src/operations/narrative_validator.dart:37:  openDialogueReferencesUnknownDialogue,
packages/map_core/lib/src/operations/narrative_validator.dart:38:  startTrainerBattleMissingTrainerId,
packages/map_core/lib/src/operations/narrative_validator.dart:39:  startTrainerBattleReferencesUnknownTrainer,
packages/map_core/lib/src/operations/narrative_validator.dart:40:  startTrainerBattleMissingNpcEntityId,
packages/map_core/lib/src/operations/narrative_validator.dart:41:  startTrainerBattleBlankBattleId,
packages/map_core/lib/src/operations/narrative_validator.dart:42:  sourceEntityInteractReferencesUnknownMap,
packages/map_core/lib/src/operations/narrative_validator.dart:43:  sourceEntityInteractReferencesUnknownEntity,
packages/map_core/lib/src/operations/narrative_validator.dart:44:  sourceOutcomeWithoutMatchingEmitOutcome,
packages/map_core/lib/src/operations/narrative_validator.dart:45:  emitOutcomeWithoutMatchingSourceOutcome,
packages/map_core/lib/src/operations/narrative_validator.dart:46:  conditionalDialogueReferencesUnknownDialogue,
packages/map_core/lib/src/operations/narrative_validator.dart:47:  flagReadNeverProduced,
packages/map_core/lib/src/operations/narrative_validator.dart:48:  setFlagNeverRead,
packages/map_core/lib/src/operations/narrative_validator.dart:49:  stepReadNeverCompleted,
packages/map_core/lib/src/operations/narrative_validator.dart:50:  completeStepNeverRead,
```

## 5. Vérification des tests

Fichier vérifié :

```text
packages/map_core/test/narrative_validator_test.dart
```

Inventaire :

```text
504 lignes
14763 octets
SHA-256 81e94b9fecd0f10751dbdb19f8590cc72e4b9ca8f45eaf83c9f34577fe2db4af
```

Imports observés :

```text
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
```

Liste complète des 16 tests :

```text
6:    test('valid minimal golden slice returns no diagnostics', () {
16:    test('unknown edge target produces error', () {
37:    test('unreachable node produces warning', () {
60:    test('scenario without source produces error', () {
84:    test('openDialogue with unknown dialogue produces error', () {
115:    test('startTrainerBattle with unknown trainer produces error', () {
133:    test('startTrainerBattle with blank trainerId produces error', () {
149:    test('startTrainerBattle with blank npcEntityId produces error', () {
166:    test('startTrainerBattle with explicit blank battleId produces error', () {
182:    test('source entityInteract with unknown map produces error', () {
200:    test('source entityInteract with unknown entity produces error', () {
218:    test('sourceOutcome without matching emitOutcome produces warning', () {
233:    test('emitOutcome without matching sourceOutcome produces warning', () {
248:    test('setFlag used by condition does not warn as unused', () {
264:    test('completeStep used by world rule does not warn as unused', () {
280:    test('diagnostics are stable and sorted deterministically', () {
```

Conclusion :

- le fichier contient bien 16 tests ciblés ;
- les tests utilisent `map_core` et `package:test`, pas Flutter/Flame ;
- les fixtures sont génériques (`test_map`, `test_entity`, `test_dialogue`, `test_trainer`, `test_outcome`, `test_fact`, `test_step` dans les helpers et données exécutées) ;
- aucun contenu Selbrume final n'est créé.

## 6. Vérification des ids Selbrume interdits

Commande exécutée :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten" \
  packages/map_core/lib/src/operations/narrative_validator.dart \
  packages/map_core/test/narrative_validator_test.dart \
  packages/map_core/lib/map_core.dart
```

Sortie exacte :

```text
```

Interprétation : aucune occurrence dans le validator, le test ou l'export public `map_core.dart`.

## 7. Vérification du rapport NS-GS-13

Fichier vérifié :

```text
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
```

Inventaire :

```text
646 lignes
17608 octets
SHA-256 55c015d79fb4eba63df43f01c91166dc3bb63b1c4be28b6adefd4a79bd82ee28
```

Structure complète des sections :

```text
3:## 1. Résumé exécutif
31:## 2. Roadmap lue et statut initial
61:## 3. Périmètre exact du lot
88:## 4. Frontière Event / Scene / Battle / World Rule / Validator
110:## 5. Audit initial
133:## 6. Validator ou diagnostics existants
153:## 7. Décision après audit
176:## 8. API ajoutée ou caractérisée
216:## 9. Diagnostics V0 couverts
245:## 10. Diagnostics volontairement hors scope
267:## 11. Fichiers créés / modifiés
291:## 12. Tests ajoutés ou modifiés
330:## 13. Commandes exécutées
355:## 14. Résultats des tests
416:## 15. Résultat analyzer
431:## 16. Résultat git diff --check
451:## 17. Mise à jour road_map.md
475:## 18. Limites restantes
487:## 19. Prochain lot recommandé
501:## 20. Evidence Pack
615:## 21. Auto-review critique
```

Résumé des preuves qu'il contient :

- audit initial ;
- décision Cas B ;
- API ajoutée ;
- diagnostics V0 couverts ;
- diagnostics hors scope ;
- fichiers créés/modifiés ;
- liste des tests ajoutés ;
- commandes tests/analyze/git exécutées ;
- limites restantes ;
- prochain lot recommandé.

Cohérence avec les fichiers réels :

- le validator annoncé existe bien à `packages/map_core/lib/src/operations/narrative_validator.dart` ;
- le test annoncé existe bien à `packages/map_core/test/narrative_validator_test.dart` ;
- l'export annoncé existe bien dans `packages/map_core/lib/map_core.dart` ;
- les 16 tests annoncés existent réellement ;
- les diagnostics V0 annoncés existent réellement dans l'enum et dans les tests ;
- le niveau de preuve reste un validator générique `map_core`, pas une validation runtime/editor/Flame.

Point corrigé par ce bis :

- le rapport NS-GS-13 ne fournissait pas assez de preuve de contenu pour les fichiers alors untracked ;
- ce rapport bis ajoute une preuve d'inventaire, hashes, diagnostics, tests, sorties de commandes et statut final ;
- dans l'état courant du dépôt, ces fichiers ne sont plus untracked.

## 8. Vérification de road_map.md

Fichier vérifié :

```text
MVP Selbrume/road_map.md
```

État observé avant modification du bis :

```text
406:## NS-GS-13 — Narrative Validator Minimal V0
437:## NS-GS-14 — Item Pickup / GiveItem Authoring Readiness
569:✅ NS-GS-13   — Narrative Validator Minimal V0
572:🔜 NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
582:🔜 NS-GS-14 — Item Pickup / GiveItem Authoring Readiness
788:# Mise à jour NS-GS-13 — 2026-05-24
792:| Lot exécuté | NS-GS-13 — Narrative Validator Minimal V0 |
802:| Prochain lot | NS-GS-14 — Item Pickup / GiveItem Authoring Readiness |
```

Mise à jour effectuée par ce bis :

```text
| Fermeture documentaire | NS-GS-13-bis — Evidence Pack Closure Only. Rapport : `reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md` |
```

Conclusion :

- `road_map.md` indique bien NS-GS-13 terminé ;
- `road_map.md` indique bien NS-GS-14 comme prochain lot ;
- ce bis ajoute uniquement la fermeture documentaire NS-GS-13-bis.

## 9. Tests relancés

Commande obligatoire ciblée exécutée :

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
```

Sortie complète utile :

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
```

Commande obligatoire package exécutée :

```bash
cd packages/map_core && dart test --reporter compact
```

Sortie finale exacte :

```text
00:03 +1921: All tests passed!
```

Conclusion :

- les 16 tests ciblés passent ;
- le package `map_core` complet passe avec 1921 tests.

## 10. Analyzer

Commande obligatoire exécutée :

```bash
cd packages/map_core && dart analyze
```

Sortie complète :

```text
Analyzing map_core...
No issues found!
```

Conclusion : analyzer clean pour `map_core`.

## 11. Evidence Pack corrigé pour les fichiers untracked

Constat initial du bis :

```text
git status --short --untracked-files=all
```

n'a retourné aucune ligne. Il n'y avait donc aucun fichier untracked à couvrir dans l'état local courant.

Les fichiers qui étaient concernés par la dette documentaire NS-GS-13 sont néanmoins inventoriés ici :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
```

Preuve que les fichiers NS-GS-13 sont présents dans l'historique courant :

```bash
git show --stat --oneline --no-renames HEAD -- \
  packages/map_core/lib/src/operations/narrative_validator.dart \
  packages/map_core/test/narrative_validator_test.dart \
  packages/map_core/lib/map_core.dart \
  reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md \
  "MVP Selbrume/road_map.md"
```

Sortie :

```text
4c58ddff feat(NS-GS-13): add Narrative Validator Minimal V0 for no-code structural validation
 MVP Selbrume/road_map.md                           |  32 +-
 packages/map_core/lib/map_core.dart                |   1 +
 .../lib/src/operations/narrative_validator.dart    | 884 +++++++++++++++++++++
 .../map_core/test/narrative_validator_test.dart    | 504 ++++++++++++
 .../ns_gs_13_narrative_validator_minimal_v0.md     | 646 +++++++++++++++
 5 files changed, 2060 insertions(+), 7 deletions(-)
```

Preuve `no-index` pour le fichier validator :

```bash
git diff --no-index --stat /dev/null packages/map_core/lib/src/operations/narrative_validator.dart || true
```

Sortie :

```text
 .../lib/src/operations/narrative_validator.dart    | 884 +++++++++++++++++++++
 1 file changed, 884 insertions(+)
```

Preuve `no-index` pour le fichier test :

```bash
git diff --no-index --stat /dev/null packages/map_core/test/narrative_validator_test.dart || true
```

Sortie :

```text
 .../map_core/test/narrative_validator_test.dart    | 504 +++++++++++++++++++++
 1 file changed, 504 insertions(+)
```

Preuve par tailles et hashes :

```text
6bfaacc3f554bdb05959c59f2471d7bf6b9cb08c107b8d56cc4e5f1934afd0de  packages/map_core/lib/src/operations/narrative_validator.dart
81e94b9fecd0f10751dbdb19f8590cc72e4b9ca8f45eaf83c9f34577fe2db4af  packages/map_core/test/narrative_validator_test.dart
55c015d79fb4eba63df43f01c91166dc3bb63b1c4be28b6adefd4a79bd82ee28  reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
```

Note sur le présent rapport :

```text
reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
```

Son contenu visible constitue sa preuve documentaire. Son nombre de lignes final vérifié après écriture est reporté dans la section Git status final.

## 12. Git diff --check

Commande exécutée après écriture du rapport et mise à jour de la roadmap :

```bash
git diff --check
```

Sortie exacte :

```text
```

Interprétation : aucune erreur whitespace.

## 13. Git diff --stat

Commande exécutée après écriture du rapport et mise à jour de la roadmap :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map.md | 1 +
 1 file changed, 1 insertion(+)
```

Note : `git diff --stat` ne liste pas les fichiers untracked. Le rapport bis apparaît donc dans `git status final`.

## 14. Git diff --name-only

Commande exécutée après écriture du rapport et mise à jour de la roadmap :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map.md
```

Note : `git diff --name-only` ne liste pas les fichiers untracked. Le rapport bis apparaît donc dans `git status final`.

## 15. Git status final

Commande exécutée après écriture du rapport et mise à jour de la roadmap :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
?? reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
```

Nombre de lignes du présent rapport après écriture :

```text
557 reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
```

## 16. Verdict final

NS-GS-13 est fermé techniquement et documentairement.

Le Narrative Validator Minimal V0 est validé dans `map_core`. Les diagnostics V0 sont prouvés par 16 tests ciblés, le package `map_core` complet passe, et `dart analyze` ne remonte aucun diagnostic.

Ce bis n'a pas modifié le validator, les tests, le runtime, l'éditeur, `map_gameplay`, `map_battle` ni `examples/playable_runtime_host`.

Aucun contenu Selbrume final n'a été créé. Aucun `project.json` Selbrume n'a été généré.

Prochain lot recommandé : NS-GS-14 — Item Pickup / GiveItem Authoring Readiness.

## 17. Auto-review critique

- Scope mechanics-first respecté : ce bis est documentaire uniquement.
- Aucun code fonctionnel modifié.
- Aucun test fonctionnel modifié.
- NS-GS-14 non démarré.
- Le statut initial réel ne montrait aucun fichier untracked ; la dette documentaire historique est néanmoins couverte par l'inventaire, les hashes, les diagnostics, la liste complète des tests et les preuves `git show` / `no-index`.
- Limite honnête : le validator reste V0, mémoire, générique, sans chargement disque ni validation Flame/editor.
- À surveiller : les prochains lots doivent conserver cette séparation. Le validator diagnostique ; il ne doit pas devenir executor, mutateur de projet ou correcteur automatique.
