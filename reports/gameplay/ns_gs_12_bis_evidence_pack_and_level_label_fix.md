# NS-GS-12-bis — Evidence Pack & Level Label Fix Only

## 1. Résumé exécutif

NS-GS-12-bis ferme uniquement la dette documentaire de NS-GS-12.

Verdict vérifié :

```text
NS-GS-12 valide un Golden Slice générique au niveau Level 2 Application.
NS-GS-12 ne valide pas encore un vrai projet créé dans l'éditeur.
NS-GS-12 ne valide pas encore PlayableMapGame au niveau Flame.
NS-GS-12 ne valide pas encore un project.json chargé depuis disque.
NS-GS-12 reste néanmoins utile car il prouve la composition des briques NS-GS-05 à NS-GS-11 au niveau application.
```

Le titre historique "Editor-authored Golden Slice Validation" est conservé pour la roadmap, mais le résultat réel doit être lu comme :

```text
Application-level Golden Slice Validation for editor-authorable mechanics
```

NS-GS-13 n'a pas été démarré.

## 2. Périmètre du bis

Inclus :

```text
- relire la roadmap vivante ;
- vérifier le rapport NS-GS-12 ;
- vérifier le test NS-GS-12 ;
- relancer le test ciblé ;
- relancer l'analyze ciblé ;
- corriger l'Evidence Pack manquant ;
- ajouter une ligne de fermeture documentaire dans road_map.md.
```

Exclus :

```text
- modifier du code de production ;
- modifier map_core / map_gameplay / map_battle / map_runtime/lib / map_editor/lib ;
- ajouter un nouveau test fonctionnel ;
- créer une fixture Selbrume finale ;
- créer un project.json Selbrume ;
- commencer NS-GS-13.
```

Fichier de skill local :

```text
skills/README.md missing
```

## 3. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
?? reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
```

Interprétation :

```text
NS-GS-12 avait déjà modifié road_map.md et créé deux fichiers untracked.
Le bis part donc d'une dette documentaire réelle : git diff ne couvre pas les fichiers untracked.
```

## 4. Vérification du niveau de preuve réel

Le rapport NS-GS-12 contient bien :

```text
Level 2 — Application layer ✅ (prouvé)
Level 3 — Flame runtime ❌ (non prouvé)
Level 4 — Disk project ❌ (exclu par contrat)
```

Lecture vérifiée du test :

```text
Le test instancie ScenarioRuntimeExecutor, MapEntityRuntimePredicateEvaluator,
createNewGameState, saveDataFromGameState / gameStateFromSaveData et
normalizeLoadedGameState.
```

Ce qui est prouvé :

```text
new game
party vide
entityInteract -> source node
givePokemon
setFlag
completeStep
save/load
world rule predicate
dialogue outcome
sourceOutcome
trainer battle effect
dispatchContinuation victory/defeat
post-battle state persistence
```

Ce qui n'est pas prouvé :

```text
PlayableMapGame n'est pas instancié.
Aucun GameWidget Flame n'est rendu.
Aucun project.json n'est chargé depuis disque.
Aucun vrai projet créé manuellement dans l'éditeur n'est exécuté.
```

Verdict :

```text
Level 2 Application : oui.
Level 3 Flame : non.
Level 4 disk project / vrai projet éditeur : non.
```

## 5. Vérification des ids interdits

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten" packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
```

Sortie exacte :

```text
34:/// All ids are generic test_*. No Selbrume ids.
40:  // Golden Slice Scenario Graphs (generic, non-Selbrume)
955:  // Test 10: No Selbrume ids used anywhere in this test file
958:  group('10. No Selbrume ids guard', () {
969:      // No forbidden Selbrume ids.
971:        'mael', 'Maël', 'lysa', 'Lysa', 'soline', 'Soline',
972:        'selbrume', 'Selbrume', 'Bourg de Selbrume',
973:        'map_bourg_selbrume', 'map_port_brisants',
974:        'npc_mael', 'npc_lysa', 'npc_soline',
975:        'trainer_lysa_port', 'battle_rival_port',
976:        'scene_mael_intro', 'scene_rival_meet',
977:        'Sproutle', 'Sparkitten',
992:            reason: 'Forbidden Selbrume id found: $forbidden');
```

Interprétation honnête :

```text
Le rg exact trouve des occurrences.
Ces occurrences sont dans des commentaires et dans la liste de garde-fou
qui vérifie l'absence des ids interdits dans les ids de fixture.
Elles ne sont pas utilisées comme ids de scénario, map, NPC, trainer,
battle, dialogue, espèce, fact ou step du Golden Slice.
```

Preuve complémentaire :

```text
forbidden_in_scenario_fixture_window=(none)
```

Verdict :

```text
Pas d'id Selbrume final dans les données de scénario/runtime exécutées.
Présence volontaire des chaînes interdites dans le garde-fou négatif du test.
```

## 6. Vérification du test NS-GS-12

Fichier :

```text
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
```

Inventaire :

```text
996 lignes
39789 octets
untracked au début du bis
```

Nombre exact de tests :

```text
14
```

Liste complète :

```text
1. createNewGameState starts with empty party on test_start_map
2. interacting with mentor NPC gives pokemon and sets facts/steps
3. save/load round-trip preserves party, facts, and steps
4. rival is hidden before mentor scene
5. rival is visible after starter + mission facts
6. rival visibility survives save/load
7. rival dialogue emits outcome and sets outcome flag
8. outcome flag triggers battle scene via sourceOutcome
9. battle effect contains battleId trainerId npcEntityId
10. victory flag → victory path → fact + step completed
11. defeat flag → defeat path → fact + step completed
12. full golden slice state survives save/load (victory path)
13. world rule still resolves correctly after full save/load
14. all fixture ids use test_* prefix
```

Groupes de test :

```text
1. New game + empty party
2. Mentor scene → GivePokemon + completeStep
3. Save/load preserves pokemon + progression
4. World Rule unlocks rival NPC
5. Outcome → Branch
6. Trainer Battle → Battle Effect
7. Victory continuation
8. Defeat continuation
9. Save/load preserves final state
10. No Selbrume ids guard
```

Refs runtime de fixture relevées :

```text
test_start_map
test_port_map
test_mentor_npc
test_rival_npc
test_scene_mentor_gives_pokemon
test_scene_rival_dialogue
test_scene_rival_battle
test_trainer
test_battle_victory_fact
test_battle_defeat_fact
test_dialogue_outcome_confident
test_given_starter_fact
test_mission_started_fact
test_rival_default_dialogue
test_rival_post_battle_dialogue
```

Nuance documentaire :

```text
Le rapport NS-GS-12 dit "ids génériques test_*".
Les refs de domaine exposées au runtime sont bien génériques et en test_*.
Le fichier contient aussi des ids techniques de noeuds/actions comme
source_mentor, battle_node, condition_victory, set_victory_fact.
Ils sont génériques et non-Selbrume, mais ne sont pas tous préfixés test_*.
```

Verdict :

```text
Le test prouve bien 14 cas Level 2 Application.
Il ne prouve pas Flame.
Il ne prouve pas disk project.
Aucune fixture Selbrume finale n'est créée.
```

## 7. Vérification du rapport NS-GS-12

Fichier :

```text
reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
```

Inventaire :

```text
512 lignes
17328 octets
untracked au début du bis
```

Le rapport est cohérent sur le fond :

```text
- il annonce Level 2 Application ;
- il exclut Level 3 Flame ;
- il exclut Level 4 disk project ;
- il annonce 14 tests ;
- il ne prétend pas avoir créé un project.json Selbrume ;
- il recommande NS-GS-13 ensuite.
```

Dettes corrigées par ce bis :

```text
- pas de git diff --check dans NS-GS-12 ;
- pas de git diff --stat dans NS-GS-12 ;
- pas de git diff --name-only dans NS-GS-12 ;
- preuve insuffisante pour les deux fichiers untracked ;
- section "Fichiers créés / modifiés" oublie road_map.md ;
- titre "Editor-authored" à lire comme Level 2 Application, pas vrai projet éditeur.
```

Verdict :

```text
NS-GS-12 est techniquement utile.
NS-GS-12 avait une dette documentaire.
NS-GS-12-bis corrige cette dette sans modifier le test.
```

## 8. Vérification de road_map.md

État vérifié avant modification bis :

```text
PHASE 4 — Validation depuis l'éditeur
✅ NS-GS-12   — Editor-authored Golden Slice Validation (Level 2 Application — 14 tests)

PHASE 5 — Sécurité no-code
🔜 NS-GS-13   — Narrative Validator Minimal V0

# Prochain lot exact
🔜 NS-GS-13 — Narrative Validator Minimal V0
```

Modification bis :

```text
Ajout d'une seule ligne dans la section "Mise à jour NS-GS-12 — 2026-05-24" :
Fermeture documentaire NS-GS-12-bis avec chemin du rapport.
```

Verdict :

```text
road_map.md indique NS-GS-12 terminé.
road_map.md garde NS-GS-13 comme prochain lot.
road_map.md documente maintenant la fermeture NS-GS-12-bis.
```

## 9. Tests relancés

Commande :

```bash
cd packages/map_runtime && flutter test test/ns_gs_12_golden_slice_validation_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
00:00 +0: 1. New game + empty party createNewGameState starts with empty party on test_start_map
00:00 +1: 2. Mentor scene → GivePokemon + completeStep interacting with mentor NPC gives pokemon and sets facts/steps
00:00 +2: 3. Save/load preserves pokemon + progression save/load round-trip preserves party, facts, and steps
00:00 +3: 4. World Rule unlocks rival NPC rival is hidden before mentor scene
00:00 +4: 4. World Rule unlocks rival NPC rival is visible after starter + mission facts
00:00 +5: 4. World Rule unlocks rival NPC rival visibility survives save/load
00:00 +6: 5. Outcome → Branch rival dialogue emits outcome and sets outcome flag
00:00 +7: 5. Outcome → Branch outcome flag triggers battle scene via sourceOutcome
00:00 +8: 6. Trainer Battle → Battle Effect battle effect contains battleId trainerId npcEntityId
00:00 +9: 7. Victory continuation victory flag → victory path → fact + step completed
00:00 +10: 8. Defeat continuation defeat flag → defeat path → fact + step completed
00:00 +11: 9. Save/load preserves final state full golden slice state survives save/load (victory path)
00:00 +12: 9. Save/load preserves final state world rule still resolves correctly after full save/load
00:00 +13: 10. No Selbrume ids guard all fixture ids use test_* prefix
00:00 +14: All tests passed!
```

Résultat :

```text
PASS — 14/14.
```

## 10. Analyzer

Commande :

```bash
cd packages/map_runtime && flutter analyze test/ns_gs_12_golden_slice_validation_test.dart
```

Sortie exacte :

```text
Analyzing ns_gs_12_golden_slice_validation_test.dart...         
No issues found! (ran in 2.1s)
```

Résultat :

```text
PASS — 0 diagnostic.
```

## 11. Evidence Pack corrigé

Fichiers NS-GS-12 couverts :

```text
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
MVP Selbrume/road_map.md
reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
```

Preuve untracked NS-GS-12 :

```text
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
     996   39789 packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
untracked
reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
     512   17328 reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
untracked
```

Preuve de contenu pour le test :

```text
14 tests listés en section 6.
10 groupes listés en section 6.
Refs runtime de fixture listées en section 6.
Sortie flutter test complète en section 9.
Sortie analyzer complète en section 10.
```

Preuve de contenu pour le rapport NS-GS-12 :

```text
# NS-GS-12 — Editor-authored Golden Slice Validation
## 1. Résumé exécutif
## 2. Roadmap lue et statut initial
## 3. Frontière Event / Scene / Battle / World Rule
## 4. Niveau de preuve atteint
## 5. Décision d'implémentation
## 6. Fichiers créés / modifiés
## 7. Architecture du test : 3 graphes de scénario composés
## 8. Tests ajoutés — 14 tests
## 9. Commandes exécutées
## 10. Résultats des tests
## 11. Résultat analyzer
## 12. Ce que la validation prouve
## 13. Garde-fou contre faux positif
## 14. Respect mechanics-first
## 15. Limites et non-objectifs
## 16. Prochain lot recommandé
## 17. Mise à jour road_map.md
## 18. Evidence Pack
## 19. Auto-review
```

Recherche de project.json / contenu final :

```text
./examples/playable_runtime_host/golden_battle_slice/project.json
```

Interprétation :

```text
Le seul project.json trouvé par cette recherche est une fixture existante
dans examples/playable_runtime_host/golden_battle_slice.
NS-GS-12 et NS-GS-12-bis ne créent pas de project.json Selbrume.
```

## 12. Git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
EXIT:0
```

Interprétation :

```text
Aucune erreur whitespace détectée dans le diff tracked.
```

## 13. Git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map.md | 32 ++++++++++++++++++++++++++------
 1 file changed, 26 insertions(+), 6 deletions(-)
```

Interprétation :

```text
git diff --stat ne liste que le diff tracked.
Les fichiers untracked NS-GS-12 et NS-GS-12-bis sont couverts par inventaire
et contenu dans ce rapport.
```

## 14. Git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map.md
```

Interprétation :

```text
git diff --name-only ne liste que road_map.md car les rapports/tests restent untracked.
```

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
?? reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
?? reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
```

Inventaire final untracked :

```text
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
     996   39789 packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
untracked
reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
     512   17328 reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
untracked
reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
     631   16482 reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
untracked
```

Note :

```text
Le présent rapport a ensuite reçu les blocs finaux ci-dessus.
Son contenu complet constitue la preuve du fichier bis.
Le status final reste inchangé : le fichier est untracked jusqu'au commit manuel
du propriétaire.
```

## 16. Verdict final

```text
NS-GS-12 est fermé techniquement et documentairement.
Le niveau de preuve réel est Level 2 Application.
Le flux Golden Slice générique authorable est validé au niveau application.
Les gaps Flame/editor/disk project restent documentés.
Prochain lot recommandé : NS-GS-13 — Narrative Validator Minimal V0.
```

Statut proposé :

```text
NS-GS-12 : DONE, fermé par NS-GS-12-bis.
NS-GS-13 : TODO, prochain lot.
```

## 17. Auto-review critique

Points solides :

```text
- Evidence Pack manquant ajouté.
- Fichiers untracked NS-GS-12 inventoriés.
- Test ciblé relancé.
- Analyze ciblé relancé.
- Level 2 Application formulé sans ambiguïté.
- Level 3 Flame et Level 4 disk project restent non prouvés.
```

Limites restantes :

```text
- Le test NS-GS-12 reste un test application-layer, pas Flame.
- Le titre historique "Editor-authored" peut encore tromper s'il est lu hors contexte.
- Le garde-fou du test contient volontairement les chaînes Selbrume interdites,
  donc le rg brut n'est pas vide ; il faut lire ces occurrences comme une liste
  négative, pas comme des ids de fixture.
- "all fixture ids use test_* prefix" est vrai pour les refs de domaine runtime,
  mais le fichier contient aussi des ids techniques génériques non préfixés test_*.
- Les fichiers NS-GS-12 restent untracked tant que le propriétaire ne les commit pas.
```

Décision :

```text
Aucune correction de code ou test n'est requise pour fermer NS-GS-12.
Si l'équipe veut une preuve plus forte, le prochain vrai saut est un lot dédié
Flame/runtime harness ou disk project, pas ce bis.
```
