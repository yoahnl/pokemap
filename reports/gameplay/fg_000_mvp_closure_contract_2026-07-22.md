# Phase 1 / Task 1.3 — Contrats transversaux de clôture MVP

**Date :** 2026-07-22
**Verdict produit :** `NO-GO`
**Portée :** vérité documentaire ; aucune promotion canonique à `DONE`

## 1. Résumé et scope

La checklist produit de `pokemap_roadmap_mecaniques_fangame.md` §2.2 contient
exactement 19 critères. Baseline signée : **11 `SUPPORTED`, 3 `PARTIAL`,
5 `BLOCKED`**. `SUPPORTED` signifie qu'un chemin minimal possède une preuve
locale, pas que tous ses lots canoniques sont `DONE`.

Deux fichiers seulement appartiennent au lot : le présent rapport créé et
`pokemap_roadmap_mecaniques_fangame.md` modifié. Aucun code, test, fixture,
généré ou rapport historique n'est modifié.

## 2. Audit initial

### Audit critique du prompt

L'obligation générique de `codex_rule.md` de modifier des tests et d'utiliser
des sub-agents contredit le scope direct « fichiers EXACTS » et « ne spawn
pas ». L'instruction directe prévaut : tests existants réexécutés, aucun
troisième fichier, et cinq passes séparées nommées dans §11.

Les preuves locales confirment la baseline : stockage actuel plat plutôt que
boxes stables, progression/level-up forgés dans plusieurs fixtures, et briques
shop/soin pures sans parcours joueur câblé.

### Git initial

```text
git rev-parse HEAD
1145fdc8023eb9e48971e336cca8e0529818ce03

git status --short --branch --untracked-files=all
## main...origin/main [ahead 86]
```

L'absence de ligne fichier prouve un worktree initial propre.

### Inventaire de preuve inspecté

- New Game/starter : `packages/map_core/test/project_new_game_config_test.dart`,
  `packages/map_gameplay/test/new_game_state_builder_test.dart`,
  `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart`,
  `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` ;
- capture/services : `packages/map_gameplay/test/capture_destination_operations_test.dart`,
  `packages/map_gameplay/test/party_bag_heal_operations_test.dart`,
  `packages/map_gameplay/test/surf_evaluation_test.dart` ;
- Selbrume/runtime : `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart`,
  `packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart`,
  `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` ;
- fermeture : `reports/gameplay/fg_000_pokemap_mvp_closure_roadmap_2026-07-22.md`
  et `reports/gameplay/fg_185_mvp_release_gate_v0.md`.

## 3. Matrice des 19 critères

`[existant]` est une preuve locale ; `[planifié]` est un engagement de la
closure roadmap et ne prouve rien aujourd'hui.

| # | Critère exact | Statut | Preuve réelle / limite | Phase | Test d'acceptation exact | Lots exacts requis |
|---:|---|---|---|---|---|---|
| MVP-01 | Créer une nouvelle partie | `SUPPORTED` | `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart` prouve le boot sans save. | P5/P6 | `[existant] packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` | FG-010, FG-011, FG-016, FG-180, FG-182 |
| MVP-02 | Choisir un starter | `SUPPORTED` | `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` prouve réception unique et chemin party existante. | P5/P6 | `[existant] packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` | FG-012, FG-013, FG-180, FG-182 |
| MVP-03 | Explorer 2–3 maps connectées | `SUPPORTED` | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` charge le parcours Selbrume ; l'E2E produit sera renforcé. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-180, FG-181, FG-182 |
| MVP-04 | Parler à des PNJ | `SUPPORTED` | L'intégration starter déclenche Maël par input runtime. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-080, FG-082, FG-092, FG-093, FG-180, FG-182 |
| MVP-05 | Avoir des dialogues conditionnels | `SUPPORTED` | `packages/map_runtime/test/runtime_story_branching_test.dart` couvre les branches de faits/flags. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-081, FG-082, FG-088, FG-093, FG-180, FG-182 |
| MVP-06 | Déclencher des cutscenes simples | `SUPPORTED` | `packages/map_runtime/test/cutscene_runtime_runner_test.dart` prouve le runner. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-082, FG-092, FG-093, FG-180, FG-182 |
| MVP-07 | Faire des rencontres sauvages en herbe | `SUPPORTED` | `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart` prouve la rencontre de route. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-180, FG-182 |
| MVP-08 | Capturer des Pokémon | `SUPPORTED` | La Golden Slice route et `runtime_battle_outcome_apply_test.dart` prouvent la capture minimale ; formule et Ball acquérable restent à fermer. | P2/P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-049, FG-083, FG-180, FG-182 |
| MVP-09 | Envoyer automatiquement au PC si la party est pleine | `PARTIAL` | `capture_destination_operations_test.dart` prouve `storedPokemon`, pas des boxes stables ni leur saturation. | P3/P5/P6 | `[planifié] packages/map_gameplay/test/player_storage_operations_test.dart` | FG-022, FG-023, FG-024, FG-025, FG-029, FG-030, FG-180, FG-182 |
| MVP-10 | Combattre des trainers | `SUPPORTED` | `p6_selbrume_first_trainer_battle_golden_slice_test.dart` prouve setup/session/write-back, avec outcome contrôlé. | P2/P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-086, FG-140, FG-141, FG-180, FG-182 |
| MVP-11 | Gagner XP + argent | `BLOCKED` | La fixture trainer appelle directement `applyBattleRewards`; `PlayerPokemon` ne persiste pas l'XP totale. | P2/P5/P6 | `[planifié] packages/map_gameplay/test/battle_progression_service_test.dart` | FG-020, FG-021, FG-040, FG-043, FG-044, FG-048, FG-051, FG-180, FG-182 |
| MVP-12 | Level-up | `BLOCKED` | Le niveau est injecté par `levelUpsByPartyIndex`, pas calculé depuis XP/participants/courbe. | P2/P5/P6 | `[planifié] packages/map_gameplay/test/battle_progression_service_test.dart` | FG-020, FG-021, FG-040, FG-044, FG-045, FG-047, FG-048, FG-180, FG-182 |
| MVP-13 | Apprendre une attaque | `BLOCKED` | `runtime_pokemon_learnset_loader_test.dart` ne prouve pas apprendre/remplacer/refuser après level-up. | P2/P5/P6 | `[planifié] packages/map_gameplay/test/battle_move_learning_test.dart` | FG-020, FG-021, FG-040, FG-041, FG-046, FG-048, FG-180, FG-182 |
| MVP-14 | Obtenir un badge ou flag | `PARTIAL` | Flags et `badgeIds` persistent, mais `BadgeDefinition` projet et grant no-code manquent. | P3/P4/P5/P6 | `[planifié] packages/map_core/test/badge_definition_test.dart` | FG-051, FG-089, FG-143, FG-180, FG-182 |
| MVP-15 | Débloquer Surf ou Cut | `PARTIAL` | `packages/map_gameplay/test/surf_evaluation_test.dart` prouve l'évaluation pure ; grant et gate authoré manquent. Surf seul est retenu. | P4/P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-089, FG-120, FG-129, FG-180, FG-182 |
| MVP-16 | Utiliser un shop | `BLOCKED` | Une mutation d'achat pure existe, sans stock projet, écran joueur ni callback runtime de production. | P3/P4/P5/P6 | `[planifié] examples/playable_runtime_host/test/in_game_shop_page_test.dart` | FG-060, FG-069, FG-070, FG-082, FG-091, FG-093, FG-180, FG-182 |
| MVP-17 | Se soigner dans un centre Pokémon | `BLOCKED` | Des soins purs existent ; `HealParty` et le flow centre HP/PP/statuts ne sont pas câblés. | P3/P4/P5/P6 | `[planifié] examples/playable_runtime_host/test/in_game_heal_flow_test.dart` | FG-060, FG-062, FG-063, FG-071, FG-085, FG-093, FG-180, FG-182 |
| MVP-18 | Sauvegarder / charger proprement | `SUPPORTED` | `file_game_save_repository_test.dart` et `p6_selbrume_save_load_golden_slice_test.dart` prouvent le round-trip ; rollback complet reste FG-014. | P5/P6 | `[planifié] packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart` | FG-014, FG-163, FG-180, FG-182, FG-183, FG-185 |
| MVP-19 | Finir une mini-histoire | `SUPPORTED` | `selbrume_player_journey_e2e_test.dart` atteint les fins ; P5 retirera outcomes forgés et mutations directes. | P5/P6 | `[existant] examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | FG-080, FG-081, FG-082, FG-088, FG-092, FG-093, FG-140, FG-141, FG-146, FG-147, FG-180, FG-181, FG-182, FG-183, FG-185 |

Contrôle : 11 `SUPPORTED` + 3 `PARTIAL` + 5 `BLOCKED` = 19.

## 4. Décisions signées

1. XP totale cumulée persistée via `int? experience` ; `null` est legacy.
2. PP actuels persistés via `Map<String, int>? currentPpByMoveId` ; les PP max
   restent dérivés du catalogue.
3. Évolution MVP uniquement par niveau.
4. Storage par boxes à IDs stables, ordre/capacité explicites et erreur typée
   quand toutes sont pleines.
5. Shop à stock projet typé ; le catalogue item n'est pas un stock de shop.
6. Badge projet typé ; acquisition dans `TrainerProfile.badgeIds`, sans registre
   parallèle.
7. Surf est le seul field gate MVP, avec unlock, refus avant acquisition et
   traversée réelle après acquisition.

## 5. Lots `DEFERRED`, jamais `DONE` pour le MVP

| Lots | Décision |
|---|---|
| FG-065 | Repel hors MVP. |
| FG-066 | Familles complètes de Balls hors MVP ; une Poké Ball minimale reste obligatoire. |
| FG-104 | Fishing hors MVP. |
| FG-105 | Headbutt hors MVP. |
| FG-121, FG-122, FG-123, FG-124, FG-125, FG-126, FG-127, FG-128 | Cut et field moves/templates avancés hors MVP ; Surf seul. |
| FG-142 | Rematches hors MVP. |

La recherche ciblée dans `reports/` ne trouve aucun Proposed status/`DONE` pour
ces lots. Les mentions Phase 9 déclarent FG-164 `DONE` pour son UI tout en
laissant explicitement FG-125 hors scope : aucune contradiction.

## 6. Réaudit frais des fondations

Cette table ne promeut rien. `Candidat DONE` signifie seulement « prêt pour un
Evidence Pack individuel » ; `PARTIAL` conserve un DoD non prouvé.

| Lots | Tests ciblés | Verdict sans promotion |
|---|---|---|
| FG-010 | `new_game_state_builder_test.dart`, `project_new_game_state_builder_test.dart` | `Candidat DONE` V0 : builder, validations, erreurs et round-trip passent ; aucune promotion. |
| FG-011 | `playable_map_game_project_new_game_boot_test.dart` | `Candidat DONE` V0 : boot sans save depuis le contrat projet passe ; aucune promotion. |
| FG-012 | `project_new_game_config_test.dart` | `Candidat DONE` V0 : modèle starter, références et round-trip passent ; aucune promotion. |
| FG-013 | `new_game_initial_party_test.dart`, `selbrume_new_game_starter_integration_test.dart` | `Candidat DONE` V0 : starter unique, chemin party existante et persistance passent ; aucune promotion. |
| FG-014 | `playable_map_game_checkpoint_load_safety_integration_test.dart`, `file_game_save_repository_test.dart` | `PARTIAL` : les sécurités/checkpoints passent, mais le rollback transactionnel après mutation destructive reste non prouvé. |
| FG-015 | `in_game_menu_test.dart` | `Candidat DONE` V0 : shell menu et input guard passent ; aucune promotion. |
| FG-016 | `phase_a_golden_slice_launch_test.dart` | `Candidat DONE` V0 : launch save et boot smoke passent ; aucune promotion. |
| FG-024 | `capture_destination_operations_test.dart` | `PARTIAL` : fallback flat-storage vert, boxes stables/saturation non prouvées. |
| FG-026 | `in_game_menu_test.dart` | `Candidat DONE` V0 : party read-only, niveau et moves sont affichés ; aucune promotion. |
| FG-027 | `in_game_menu_test.dart` | `PARTIAL` : résumé XP/statut/PP persistés à revalider après P2. |
| FG-140 | `trainer_defeated_test.dart`, `p6_selbrume_first_trainer_battle_golden_slice_test.dart` | `PARTIAL` : flags/fallbacks verts, mais outcome contrôlé et policy editor hors preuve. |
| FG-141 | `trainer_defeated_test.dart`, `p6_selbrume_first_trainer_battle_golden_slice_test.dart` | `PARTIAL` : branches de dialogue vertes, hook post-combat produit P5 hors preuve. |
| FG-160 | `in_game_menu_test.dart` | `Candidat DONE` V0 : navigation et flows reliés passent ; aucune promotion. |
| FG-163 | `in_game_menu_test.dart`, `runtime_launch_save_test.dart` | `Candidat DONE` V0 : callbacks, annulation et erreurs passent ; ne ferme pas FG-014. |

## 7. MVP global, GO Selbrume et non-objectifs

Le **MVP global** exige que tout créateur puisse authorer, exécuter et persister
les 19 critères sans code. Le **GO Selbrume** est une preuve d'un projet précis :
même `releaseCandidateCommit`, tree hash, package, receipt automatisé et
walkthrough humain. Un GO narratif borné Selbrume ne vaut pas GO MVP global.

Non-objectifs : lots différés §5, évolutions autres que niveau, doubles et
gimmicks, breeding/online, objets tenus et TM/HM, cloud/multiplateforme,
signature/notarisation et polish visuel sans dépendance mécanique.

## 8. Fichiers et zones modifiés

- Créé : `reports/gameplay/fg_000_mvp_closure_contract_2026-07-22.md` — présent
  document complet. Le recopier dans lui-même serait récursif ; cette exception
  anti-récursion satisfait l'inventaire sans créer une seconde source.
- Modifié : `pokemap_roadmap_mecaniques_fangame.md` — tables des lots différés
  et §14 remplacé par les 19 critères avec lots/tests exacts.

Diff précis : `git diff -- pokemap_roadmap_mecaniques_fangame.md`.

## 9. Tests, analyse, build et Git final

Aucun test créé/modifié : le scope direct interdit un troisième fichier. Les
commandes et résultats frais sont consignés dans §10.

Build applicatif non applicable à deux fichiers Markdown. Alternatives : tests
ciblés, tests dashboard, `dart analyze` Core, dashboard strict, contrôles `rg`
et `git diff --check`.

**État Git de validation pré-commit :** limité aux deux fichiers du lot ; la
sortie exacte finale est consignée dans §10. L'état post-commit et son hash sont
fournis dans le handoff, sans créer une boucle de commit documentaire.

## 10. Commandes et résultats exacts

```bash
cd packages/map_core
dart test test/project_new_game_config_test.dart test/game_state_persistence_test.dart
```

Résultat : exit `0`, `+18: All tests passed!`.

```bash
cd packages/map_gameplay
dart test test/new_game_state_builder_test.dart test/project_new_game_state_builder_test.dart test/new_game_initial_party_test.dart test/capture_destination_operations_test.dart
```

Résultat : exit `0`, `+62: All tests passed!`.

```bash
cd packages/map_runtime
flutter test test/playable_map_game_project_new_game_boot_test.dart test/selbrume_new_game_starter_integration_test.dart test/playable_map_game_checkpoint_load_safety_integration_test.dart test/file_game_save_repository_test.dart test/trainer_defeated_test.dart test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

Résultat : exit `0`, `+40: All tests passed!`. Les stack traces de saves
invalides/corrompues sont les sorties attendues de tests négatifs, pas des
échecs de suite.

```bash
cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart test/in_game_menu_test.dart test/runtime_launch_save_test.dart
```

Résultat : exit `0`, `+15: All tests passed!`.

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
```

Résultat : exit `0`, résumé exact
`DONE: 5 · PARTIAL: 1 · BLOCKED: 0 · TODO: 81 · DEFERRED: 21`.

```bash
cd packages/map_core
dart test test/gameplay_roadmap_dashboard_test.dart test/gameplay_roadmap_repository_consistency_test.dart && dart analyze
```

Résultat : exit `0`, `+15: All tests passed!`, puis `No issues found!`.

```bash
rg -c '^\| MVP-[0-9]{2} \|' reports/gameplay/fg_000_mvp_closure_contract_2026-07-22.md pokemap_roadmap_mecaniques_fangame.md
rg -c '^\| FG-(065|066|104|105|121|122|123|124|125|126|127|128|142) .*`⏸ DEFERRED`' pokemap_roadmap_mecaniques_fangame.md
```

Résultat : `19` lignes dans chaque matrice, baseline vérifiée séparément à
`11/3/5`, et `13` lignes `DEFERRED` exactes. Aucun range `FG-nnn à FG-nnn` ne
subsiste dans §14.

```bash
rg -n 'FG-(065|066|104|105|121|122|123|124|125|126|127|128|142)' reports --glob '*.md' | rg -i 'proposed status|statut proposé|`DONE`|✅ DONE'
```

Résultat : deux mentions de FG-125, toutes deux rattachées au `DONE` UI de
FG-164 et disant explicitement que Fly FG-125 reste hors scope ; aucune
proposition `DONE` contradictoire pour un lot différé.

```bash
git diff --check
git status --short --branch --untracked-files=all
```

Résultat : `git diff --check` sans sortie, puis :

```text
## main...origin/main [ahead 86]
 M pokemap_roadmap_mecaniques_fangame.md
?? reports/gameplay/fg_000_mvp_closure_contract_2026-07-22.md
```

Ces deux chemins sont exactement le scope attendu avant stage.

## 11. Passes séparées et critique

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — baseline 11/3/5 et frontières confirmées, sans promotion canonique. |
| Implémentation | PASS — scope limité aux deux fichiers et plages vagues de §14 remplacées. |
| Tests | PASS — quatre groupes ciblés, dashboard et cohérence Core verts ; limites partielles conservées. |
| Build / Validation | PASS — build non applicable ; analyse Core, dashboard strict et contrôles documentaires utilisés. |
| Critique finale | PASS — 19 critères et baseline exacts, 13 différés exacts, aucune plage vague dans §14, aucun fichier accidentel et aucune promotion canonique. |

Risques : un E2E partagé peut masquer un critère non traversé ; les migrations
XP/PP/boxes/shop/badge restent à prouver ; chaque lot exact garde son Evidence
Pack individuel ; aucun GO final sans receipts automatisé et humain du même
candidat.
