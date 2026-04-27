# Lot 0 — Audit réel de couverture battle du projet + plan de fondation à challenger avec ChatGPT

## 1. Résumé exécutif honnête

### Verdict global

Le moteur battle/runtime local est **réel et déjà utile** sur un sous-ensemble singles 1v1 borné, mais le projet **n’est pas aujourd’hui “battle-ready” sur un vrai contenu versionné**.

Le point le plus important de ce lot est double :

1. **Le repo ne versionne pas aujourd’hui un vrai projet authored battleable complet**.
   - Confirmé par lecture du filesystem : **0** `project.json` versionné hors `tests` / `build` / `.dart_tool` / `reports`.
   - Confirmé par lecture du filesystem : **0** map JSON versionnée hors zones de test/build/report.
   - Confirmé par lecture du filesystem : **0** trainer JSON versionné hors zones de test/build/report.
   - Confirmé par lecture du filesystem : **0** encounter JSON versionné hors zones de test/build/report.
   - Donc la question “combien de combats authored du repo démarrent aujourd’hui ?” a une réponse brutale : **aucun contenu authored complet n’est versionné pour le mesurer directement**.

2. **Le moteur et le handoff runtime sont plus avancés que le scaffold data versionné**.
   - Le seed bootstrap moves versionné dans l’editor contient **21 moves**, dont **12** projettent réellement jusqu’au moteur battle aujourd’hui.
   - Le reste échoue pour deux raisons distinctes :
     - seed/bootstrap trop étroit ou en retard sur le moteur ;
     - bridge/moteur encore incapables d’absorber certaines mécaniques pourtant marquées `structuredSupported`.
   - Les fixtures runtime synthétiques sont beaucoup plus riches et donnent une image plus flatteuse : elles prouvent des seams et un sous-ensemble moteur réel, **mais elles ne prouvent pas la battleability du contenu versionné**.

### Ce qui est déjà solide

- Le moteur singles 1v1 local sait faire un vrai sous-ensemble honnête :
  - ordre/priorité/vitesse,
  - accuracy/PP,
  - STAB/type chart/immunités,
  - crits,
  - statuts majeurs `par/brn/psn/tox`,
  - volatiles utiles `protect/requireRecharge/chargeThenStrike/breakProtect`,
  - `rain`, `sandstorm`, `trickRoom`,
  - réserves/switch/remplacement post-K.O.,
  - timeline ordonnée du tour.
- Le runtime sait mapper un `BattleStartRequest` vers un `BattleSetup` avec lineup indices stables et réserves, puis réappliquer le résultat dans le runtime local.
- Les tests battle/runtime ciblés déjà présents passent et verrouillent bien ce sous-ensemble.

### Ce qui est encore très loin d’une vraie parité Showdown singles ciblée

- Pas de vrai modèle `Side`/`slot`.
- Modèle de décision/requests **existant mais trop étroit** pour converger proprement vers le modèle Showdown.
- Pas de mini event/condition engine.
- Pas de vraie action queue riche façon Showdown.
- Modèles `BattleMove`, `BattleFieldState`, `BattleVolatileState`, `BattleCombatant` encore trop fermés pour absorber beaucoup plus de mécanique sans dette.
- Couverture moves/catalogues réelle trop faible sur le scaffold bootstrap.

### Niveau actuel de proximité avec Showdown

Réponse franche :

- **pas proche** d’une vraie parité Showdown singles au sens architecture/comportement global ;
- **oui** pour un prototype singles honnête sur un sous-ensemble moteur borné ;
- **non** pour une exploitation crédible du “vrai contenu versionné” du repo, parce que ce contenu battleable versionné est presque inexistant et le scaffold bootstrap est trop étroit.

### Principaux blockers structurels

1. **Absence de contenu authored versionné battle-ready**.
2. **Couverture bootstrap/scaffold moves trop faible** pour rendre un projet frais réellement battleable.
3. **Gap seed/bridge/moteur** sur certains moves déjà seedés (`absorb`, `double_slap`, `u_turn`, `whirlwind`).
4. **Fondations encore trop petites** pour converger vers Showdown singles : modèle de décision par tour trop simple, pas de `Side`/`slot`, pas d’event engine, pas de queue riche.

---

## 2. Pré-gates exécutés + résultats

### Git read-only au début

Commandes réellement exécutées :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultat :

- `git status --short` : vide
- `git diff --stat` : vide
- `git ls-files --others --exclude-standard` : vide

Conclusion :

- worktree propre au début du lot ;
- aucun bruit préalable à distinguer de ce lot.

### Vérifications ciblées battle/runtime

Commandes réellement exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_flow_integration_test.dart test/battle_session_flow_test.dart test/battle_switch_test.dart test/battle_field_test.dart test/battle_volatiles_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_outcome_apply.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/battle_overlay_component.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart
```

Résultats :

- `map_battle` tests ciblés : vert
- `map_runtime` tests ciblés : vert
- `map_battle` analyze : vert
- `map_runtime` analyze ciblé : vert

Classification honnête :

- utile pour confirmer que le sous-ensemble moteur/runtime actuellement revendiqué n’est pas rouge ;
- insuffisant pour prouver la battleability d’un contenu authored, puisqu’un tel contenu versionné n’existe pas dans le repo.

---

## 3. Méthode réelle utilisée

### Ce que j’ai lu côté local

Code battle/runtime relu directement :

- [packages/map_battle/lib/src/battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
- [packages/map_battle/lib/src/battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart)
- [packages/map_battle/lib/src/battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart)
- [packages/map_battle/lib/src/battle_action.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart)
- [packages/map_battle/lib/src/battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart)
- [packages/map_battle/lib/src/battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart)
- [packages/map_battle/lib/src/battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart)
- [packages/map_battle/lib/src/battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart)
- [packages/map_battle/lib/src/battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart)
- [packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart)
- [packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart)
- [packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart)
- [packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart)
- [packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)
- [packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart)

Loaders/runtime data relus :

- [packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart)
- [packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart)
- [packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart)
- [packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart)
- [packages/map_runtime/lib/src/application/runtime_map_bundle.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_map_bundle.dart)
- [packages/map_runtime/lib/src/application/encounter_to_battle_request.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/encounter_to_battle_request.dart)
- [packages/map_runtime/lib/src/application/trainer_battle_request.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart)

Tests/runtime examples relus :

- [packages/map_runtime/test/runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart)
- [packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart)
- [packages/map_runtime/test/runtime_battle_setup_mapper_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart)
- [examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart)
- [examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart)

### Ce que j’ai lu côté données projet

- [packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart)
- [packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
- [packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/README.md](/Users/karim/Project/pokemonProject/packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/README.md)
- `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/{species,learnsets,evolutions,media}`
- `reports/pokedex-import-pack-10/{species,learnsets,evolutions,media}` comme source secondaire utile, pas comme source de vérité runtime

### Ce que j’ai exécuté pour mesurer la couverture réelle

J’ai utilisé des scripts temporaires **hors repo** sous `/tmp` pour interroger les vraies classes runtime via les `package_config.json` des packages concernés. Aucun de ces scripts n’a été écrit dans le dépôt.

Scripts/mesures réalisés :

- export du seed bootstrap moves vers JSON ;
- mesure réelle de bridgeabilité du seed bootstrap via `RuntimeBattleMoveBridge` ;
- mesure réelle d’un catalogue runtime de fixture via `RuntimeBattleCombatantSeedBuilder` ;
- mesure des packs import sample (`manual_pokemon_import_pack_10` et `reports/pokedex-import-pack-10`) contre le seed bootstrap actuel ;
- agrégation d’une matrice moves issue :
  - du seed bootstrap,
  - des fixtures runtime de tests,
  - des learnsets des packs import sample,
  - des moves explicites vus dans les tests/examples.

### Skills / méthode réellement utilisés

- `Brainstorming` :
  - utilisé pour cadrer la vraie question utile de ce lot ;
  - adapté sans phase interactive longue, parce que le prompt imposait un audit end-to-end sans arrêt intermédiaire.
- `Writing Plans` :
  - utilisé pour structurer le lot en audit -> mesures -> synthèse -> plan -> review.
- `Subagent Driven Development` / `Dispatching Parallel Agents` :
  - utilisés pour séparer audit data coverage et audit architecture/plan.
- `Requesting Code Review` / `Receiving Code Review` :
  - utilisés via reviewers séparés pour challenger le cadrage du report.
- `Verification Before Completion` :
  - utilisée en relançant git read-only, tests ciblés et analyze ciblés avant finalisation.
- `Systematic Debugging` :
  - non utilisée comme workflow principal, car je n’ai pas rencontré de bug moteur incohérent à corriger ; le sujet était la mesure de couverture réelle.

### Commandes structurantes réellement exécutées

En plus des lectures `rg` / `sed` / `cat`, commandes structurantes réellement exécutées :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
rg --files -g 'AGENTS.md'

python3 - <<'PY'
# scan project.json / maps / trainers / encounters / species / learnsets hors build/.dart_tool/reports
PY

/opt/homebrew/bin/dart --packages=/Users/karim/Project/pokemonProject/packages/map_editor/.dart_tool/package_config.json /tmp/export_bootstrap_moves.dart > /tmp/bootstrap_moves.json
/opt/homebrew/bin/dart --packages=/Users/karim/Project/pokemonProject/packages/map_runtime/.dart_tool/package_config.json /tmp/analyze_bootstrap_move_bridge.dart
/opt/homebrew/bin/dart --packages=/Users/karim/Project/pokemonProject/packages/map_runtime/.dart_tool/package_config.json /tmp/analyze_runtime_fixture_catalog.dart
/opt/homebrew/bin/dart --packages=/Users/karim/Project/pokemonProject/packages/map_runtime/.dart_tool/package_config.json /tmp/analyze_manual_pack_with_bootstrap.dart
/opt/homebrew/bin/dart --packages=/Users/karim/Project/pokemonProject/packages/map_runtime/.dart_tool/package_config.json /tmp/analyze_report_pack_with_bootstrap.dart

git -C /tmp/pokemon-showdown-audit rev-parse HEAD
git -C /tmp/pokemon-showdown-audit remote get-url origin

cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_flow_integration_test.dart test/battle_session_flow_test.dart test/battle_switch_test.dart test/battle_field_test.dart test/battle_volatiles_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_outcome_apply.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/battle_overlay_component.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart
```

### Incidents rencontrés

1. Première tentative ratée sur l’export bootstrap :
   - j’ai d’abord tenté un `dart run` trop naïf depuis `/tmp` ;
   - le script ne voyait pas les packages du monorepo ;
   - correction honnête : invocation explicite avec `--packages=.../package_config.json`.

2. Pas de projet authored versionné :
   - ce n’est pas un “incident d’outillage” ;
   - c’est un résultat d’audit ;
   - il a obligé à mesurer par proxy (scaffold bootstrap, import packs, fixtures runtime).

### Référence Showdown réellement utilisée

Clone lu en lecture seule :

- origine : `https://github.com/smogon/pokemon-showdown.git`
- commit lu : `f76228a1354b5d0f307ca2d16101294ad3a2308b`
- chemin local audit : `/tmp/pokemon-showdown-audit`

Modules relus :

- `/tmp/pokemon-showdown-audit/sim/battle.ts`
- `/tmp/pokemon-showdown-audit/sim/battle-actions.ts`
- `/tmp/pokemon-showdown-audit/sim/battle-queue.ts`
- `/tmp/pokemon-showdown-audit/sim/side.ts`
- `/tmp/pokemon-showdown-audit/sim/field.ts`
- `/tmp/pokemon-showdown-audit/sim/pokemon.ts`
- `/tmp/pokemon-showdown-audit/sim/state.ts`
- `/tmp/pokemon-showdown-audit/sim/dex-moves.ts`
- `/tmp/pokemon-showdown-audit/data/moves.ts`
- `/tmp/pokemon-showdown-audit/data/conditions.ts`

### Ce que je n’ai pas pu vérifier

- nombre réel de combats authored d’une campagne versionnée, parce qu’il n’y a pas de projet authored versionné complet à lancer ;
- battleability d’un vrai projet utilisateur externe, puisque ce lot devait rester strictement local au repo ;
- couverture exhaustive des espèces/moves au-delà des seeds/bootstrap/fixtures/import samples versionnés.

---

## 4. Cartographie code local

| Sous-système | Source de vérité locale | Rôle réel |
| --- | --- | --- |
| Boucle de tour battle | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart) | Orchestration centrale du tour, choix disponibles, application des actions, résiduels, remplacements |
| État battle global | [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart) | Actifs joueur/ennemi, réserves, issue, field state, identité stable limitée |
| Contrat de restitution | [battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart) | `BattleTurnResult`, timeline, buckets catégoriels, issue du tour |
| Modèle de choix/actions | [battle_action.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart) | `PlayerBattleChoice*`, `BattleAction*`, request model singles minimal |
| Statuts majeurs | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart) | `par/brn/psn/tox`, compteur toxique local |
| Volatiles utiles | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart) | `protect`, `mustRecharge`, `pendingCharge` |
| Field state | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart) | weather + pseudoWeather bornés |
| Switch/remplacement | [battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart) | évènements de switch/remplacement |
| Bridge move canonique -> battle | [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart) | point dur de vérité sur ce qui est projetable honnêtement |
| Assemblage des seeds | [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart) | sélection/filtrage des moves, construction des seeds battle |
| Mapping request -> battle setup | [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart) | actif, réserves, lineup indices, chemins wild/trainer/player |
| Write-back post-battle | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart) | réécriture du state runtime après combat |
| Démarrage runtime | [playable_map_game.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) | handoff runtime -> battle |
| Restitution UI battle | [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart) | narration locale du tour, désormais basée sur `timeline` |

---

## 5. Cartographie data réelle

### Ce qui est vraiment versionné et pertinent

| Source | Statut | Rôle réel | Limite |
| --- | --- | --- | --- |
| [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart) | versionnée | seed moves d’un projet frais | seed explicitement curaté/incomplet, pas un Pokédex battle-ready |
| [initialize_pokemon_project_storage_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart) | versionnée | scaffolding projet local | seed réellement `moves.json`, laisse le reste vide/scaffoldé |
| `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10` | versionnée | fixture d’import UI/editor | pas de `project.json`, pas de `moves.json`, pas de maps/trainers/encounters |
| `reports/pokedex-import-pack-10` | versionnée | source secondaire/report artifact | utile comme proxy de learnsets, pas comme runtime source de vérité |
| Tests runtime | versionnés | créent des mini-projets synthétiques temporaires | prouvent des seams, pas un contenu authored |
| Example host | versionné | charge un `project.json` externe choisi par l’utilisateur | n’embarque pas lui-même de projet authored battle-ready |

### Ce qui n’existe pas aujourd’hui dans le repo

Confirmé par scan filesystem :

- `project.json` versionné hors tests/build/reports : **0**
- map JSON versionnée hors tests/build/reports : **0**
- trainer JSON versionné hors tests/build/reports : **0**
- encounter/zone JSON versionnés hors tests/build/reports : **0**

Conséquence :

- il n’existe pas aujourd’hui de “vrai projet battleable versionné” à lancer de bout en bout dans le repo ;
- les vrais chiffres de battleability authored doivent donc être mesurés par **proxy** :
  - scaffold bootstrap,
  - packs import sample,
  - mini-projets synthétiques de tests.

---

## 6. Cartographie Showdown utile

| Module Showdown | Sujet | Pourquoi pertinent ici |
| --- | --- | --- |
| `/tmp/pokemon-showdown-audit/sim/battle.ts` | état global, orchestration | référence structurante pour `Battle`, requests, faint queue, turn loop |
| `/tmp/pokemon-showdown-audit/sim/battle-actions.ts` | résolution des actions | équivalent conceptuel du gros de `battle_session.dart` |
| `/tmp/pokemon-showdown-audit/sim/battle-queue.ts` | queue/action ordering | référence clé pour ce qui manque côté queue/interruption |
| `/tmp/pokemon-showdown-audit/sim/side.ts` | side, active slots, requests | montre le gap local sur side/slot/request richness |
| `/tmp/pokemon-showdown-audit/sim/field.ts` | weather/terrain/pseudoWeather | référence pour le gap field state local |
| `/tmp/pokemon-showdown-audit/sim/pokemon.ts` | état riche du combattant | référence pour le gap `BattleCombatant` local |
| `/tmp/pokemon-showdown-audit/sim/state.ts` | state snapshots/serialization | utile pour comparer la granularité de l’état |
| `/tmp/pokemon-showdown-audit/sim/dex-moves.ts` | normalisation moves | utile pour comparer la richesse du contrat move |
| `/tmp/pokemon-showdown-audit/data/moves.ts` | move data canonique | utile pour rattacher les gaps de couverture réelle |
| `/tmp/pokemon-showdown-audit/data/conditions.ts` | conditions/weather/side/slot | utile pour situer les gaps event/condition engine |

---

## 7. Matrices de couverture réelles

### 7.1. Couverture réelle des moves rencontrés

#### Synthèse globale

| Univers audité | Total | Bridgeables maintenant | Non bridgeables maintenant | Statut honnête |
| --- | --- | --- | --- | --- |
| Seed bootstrap moves versionné | 21 | 12 | 9 | scaffold très partiel |
| Fixture runtime riche du seed builder | 21 | 20 | 1 | sous-ensemble moteur beaucoup plus large que le bootstrap |
| Fixture runtime riche du setup mapper | 19 | 18 | 1 | idem, plus étroite que la fixture précédente |
| Moves uniques des learnsets du manual import pack | 32 | 6 présents + bridgeables dans le bootstrap | 26 hors bootstrap | fraîchement importé, presque pas battleable sur scaffold actuel |
| Moves explicites vus dans tests/examples handoff | 20 | 8 bridgeables sur bootstrap / 17 bridgeables sur fixture riche | bootstrap très en retard | seam tests > contenu scaffold |

#### Répartition bootstrap seed

| Classe | Nombre | Détail |
| --- | --- | --- |
| `structuredSupported` seedés | 16 | 12 projettent vraiment, 4 sont encore rejetés par le bridge |
| `catalogOnly` seedés | 5 | 0 bridgeable dans le bootstrap actuel |
| `structuredSupported` mais rejetés | 4 | `absorb`, `double_slap`, `u_turn`, `whirlwind` |
| `catalogOnly` encore seedés | 5 | `stealth_rock`, `electric_terrain`, `healing_wish`, `solar_beam`, `trick_room` |

#### Matrice moves à impact réel

| moveId | Sources rencontrées | Bootstrap maintenant | Fixture runtime riche | Impact réel aujourd’hui |
| --- | --- | --- | --- | --- |
| `tackle` | bootstrap, manual pack, runtime fixtures, tests/examples | bridgeable | bridgeable | move de base solide |
| `growl` | bootstrap, manual pack, runtime fixtures, tests/examples | bridgeable | bridgeable | move de base solide |
| `vine_whip` | bootstrap, manual pack, runtime fixtures, tests/examples | bridgeable | bridgeable | move de base solide |
| `razor_leaf` | bootstrap, manual pack, runtime fixtures, tests/examples | bridgeable | bridgeable | move de base solide |
| `thunder_wave` | bootstrap, runtime fixtures, tests/examples | bridgeable | bridgeable | prouve le support BE7 |
| `rain_dance` | bootstrap, runtime fixtures, tests/examples | bridgeable | bridgeable | prouve le support BE9 |
| `hyper_beam` | bootstrap, runtime fixtures, tests/examples | bridgeable | bridgeable | prouve `requireRecharge` |
| `feint` | bootstrap, runtime fixtures, tests/examples | bridgeable | bridgeable | prouve `breakProtect` |
| `solar_beam` | bootstrap, runtime fixtures, tests/examples | **rejeté** (`catalogOnly`) | bridgeable | seed bootstrap en retard sur le moteur BE8 |
| `trick_room` | bootstrap, runtime fixtures, tests/examples | **rejeté** (`catalogOnly`) | bridgeable | seed bootstrap en retard sur le moteur BE9 |
| `absorb` | bootstrap | **rejeté** (`unsupported_effect_kind:drain`) | absent | gap bridge/moteur réel |
| `double_slap` | bootstrap | **rejeté** (`unsupported_effect_kind:multi_hit`) | absent | gap bridge/moteur réel |
| `u_turn` | bootstrap | **rejeté** (`unsupported_effect_kind:self_switch`) | absent | gap bridge/moteur réel |
| `whirlwind` | bootstrap | **rejeté** (`unsupported_effect_kind:force_switch`) | absent | gap bridge/moteur réel |
| `scratch` | manual pack, runtime fixtures | absent du bootstrap | bridgeable | bloque 6 cas manual pack + 6 cas report pack |
| `tail_whip` | manual pack, runtime fixtures, tests/examples | absent du bootstrap | bridgeable | bloque 6 cas manual pack + 6 cas report pack |
| `lick` | manual pack / report pack | absent du bootstrap | absent | bloque 3 cas manual + 3 cas report |
| `thundershock` | manual pack / report pack | absent du bootstrap | absent | bloque 3 cas manual + 3 cas report |
| `wrap` | manual pack | absent du bootstrap | absent | bloque 3 cas manual |
| `quick_attack` | manual pack, runtime fixtures, tests/examples | absent du bootstrap | bridgeable | bloque 2 cas manual |
| `sing` | manual pack / report pack | absent du bootstrap | absent | bloque 2 cas manual + 3 cas report |
| `endure` | manual pack | absent du bootstrap | absent | bloque 1 cas manual |
| `pound` | manual pack | absent du bootstrap | absent | bloque 1 cas manual |
| `teleport` | report pack, runtime fixtures, tests/examples | absent du bootstrap | **rejeté** | refus explicite utile, pas battleable |
| `ember` | manual pack, runtime fixtures, tests/examples | absent du bootstrap | bridgeable | bon exemple de move supporté mais non seedé |
| `water_gun` | manual pack, runtime fixtures, tests/examples | absent du bootstrap | bridgeable | bon exemple de move supporté mais non seedé |
| `protect` | runtime fixtures, tests/examples | absent du bootstrap | bridgeable | moteur BE8 prêt, scaffold non aligné |
| `sandstorm` | runtime fixtures, tests/examples | absent du bootstrap | bridgeable | moteur BE9 prêt, scaffold non aligné |
| `mud_slap` | runtime fixtures, tests/examples | absent du bootstrap | bridgeable | support moteur plus large que le scaffold |
| `stealth_rock` | bootstrap | **rejeté** (`catalogOnly`) | absent | hors scope fondation actuelle |
| `electric_terrain` | bootstrap | **rejeté** (`catalogOnly`) | absent | hors scope fondation actuelle |
| `healing_wish` | bootstrap | **rejeté** (`catalogOnly`) | absent | hors scope fondation actuelle |

#### Raisons de rejet dominantes observées

| Catégorie | Exemples | Impact observé |
| --- | --- | --- |
| Bootstrap absent du catalogue | `scratch`, `tail_whip`, `lick`, `thundershock`, `quick_attack`, `water_gun`, `ember`, `protect`, `sandstorm` | bloque aujourd’hui la majorité des cas des packs import sample |
| Seed bootstrap en retard sur le moteur | `solar_beam`, `trick_room` | faux négatifs de scaffold |
| Bridge/moteur encore insuffisants malgré seed structuré | `absorb`, `double_slap`, `u_turn`, `whirlwind` | montre que le problème n’est pas “juste ajouter plus de moves au seed” |
| Refus explicites hors scope | `stealth_rock`, `electric_terrain`, `healing_wish`, `teleport` | refus honnêtes, pas bugs |

### 7.2. Couverture réelle des combattants / seeds

#### Vue par univers réellement mesuré

| Univers | Type | Total analysé | Bridgeables | Partiellement bridgeables | Non bridgeables | Cause principale |
| --- | --- | --- | --- | --- | --- | --- |
| Contenu authored versionné du repo | wild | 0 | 0 | 0 | 0 | pas de projet authored versionné |
| Contenu authored versionné du repo | trainer | 0 | 0 | 0 | 0 | pas de projet authored versionné |
| Contenu authored versionné du repo | player | 0 | 0 | 0 | 0 | pas de save/project authored versionné |
| Manual import pack + bootstrap current | wild proxy learnset | 30 | 3 | 0 | 27 | bootstrap catalog trop étroit |
| Report pack + bootstrap current | wild proxy learnset | 30 | 3 | 0 | 27 | bootstrap catalog trop étroit |
| Runtime fixture catalog riche | wild proxy learnset | 9 | 9 | 0 | 0 | fixture volontairement alignée sur le moteur |
| Player `knownMoveIds` explicites en tests runtime | player path | cas ciblés | oui dans les cas mixtes | oui si move unsupported filtré | oui si 0 move bridgeable restant | comportement cohérent, mais pas mesure de contenu réel |
| Trainer moves explicites en tests runtime | trainer path | cas ciblés | oui dans les cas mixtes | oui si filtrage utile | oui si 0 move bridgeable restant | idem |

#### Détail important : player/trainer/wild “réellement injectables”

Réponse honnête :

- **wild authored versionnés** : pas mesurables directement, aucun contenu authored complet n’est versionné ;
- **trainer authored versionnés** : pas mesurables directement, aucun trainer JSON versionné hors tests/build/reports ;
- **player authored versionnés** : pas mesurables directement, pas de save/project versionné battle-ready ;
- ce que j’ai pu mesurer honnêtement :
  - les chemins runtime réels ;
  - les mini-projets synthétiques des tests ;
  - les import packs versionnés comme proxy de couverture learnset ;
  - le scaffold bootstrap d’un projet frais.

### 7.3. Couverture réelle des combats

| Mesure | Résultat | Type de preuve |
| --- | --- | --- |
| Combats wild authored versionnés réellement démarrables | **0 / 0 mesurables** | confirmé par scan filesystem |
| Combats trainer authored versionnés réellement démarrables | **0 / 0 mesurables** | confirmé par scan filesystem |
| Combats wild plausibles sur projet frais + manual import pack | **3 / 30** breakpoint seed cases | confirmé par exécution du vrai seed builder |
| Combats wild plausibles sur projet frais + report pack secondaire | **3 / 30** breakpoint seed cases | confirmé par exécution du vrai seed builder |
| Espèces du manual import pack avec au moins un cas jouable sur scaffold actuel | **1 / 10** (`bulbasaur`) | confirmé par exécution |
| Espèces du report pack secondaire avec au moins un cas jouable sur scaffold actuel | **1 / 10** (`bulbasaur`) | confirmé par exécution |
| Combats synthétiques runtime délibérément construits pour le sous-ensemble moteur | oui | confirmé par tests existants |

#### Réponse métier simple

> Le projet est-il actuellement “battleable” sur une portion crédible de son vrai contenu ?

Réponse honnête :

- **non** si on parle de contenu versionné du repo, parce qu’il n’existe pas de vrai projet authored complet versionné ;
- **très peu** si on parle d’un projet frais scaffoldé avec le bootstrap actuel + les packs import sample versionnés ;
- **oui sur un sous-ensemble de démonstration synthétique** si on parle des fixtures runtime de tests soigneusement alignées sur le moteur.

### 7.4. Matrice Showdown parity

| Sous-système | Statut local | Référence Showdown | Statut | Criticité | Blocker prochain lot ? | Blocker vraie parité singles ? | Preuve |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Turn loop singles 1v1 | présent dans `battle_session.dart` | `sim/battle.ts` + `sim/battle-actions.ts` | très simplifié | élevée | non immédiat pour couverture data | oui | code + tests |
| Per-turn request/choice model | présent mais étroit (`PlayerBattleChoice*`, `BattleAction*`) | `sim/side.ts` requests/choices | partiel | élevée | oui bientôt | oui | code + tests + reviewer |
| Runtime battle-start request model | présent (`BattleStartRequest` -> `BattleSetup`) | entrée Showdown différente, mais conceptuellement comparable | partiel | moyenne | non | non direct | code + reviewer |
| Side / slot topology | absent | `sim/side.ts` | absent | élevée | pas pour quick coverage lifts | oui | code |
| Action queue riche | absente | `sim/battle-queue.ts` | structurellement incompatible | élevée | bientôt | oui | code |
| Event / condition engine | absent | `runEvent` / conditions in `battle.ts`, `conditions.ts` | absent | élevée | pas pour micro-lifts | oui | code |
| Combatant model | borné | `sim/pokemon.ts` | très simplifié | élevée | pas immédiat | oui | code |
| Move model | borné mais honnête | `sim/dex-moves.ts` + `data/moves.ts` | très simplifié | élevée | oui si on ouvre beaucoup plus de moves | oui | code |
| Major statuses | présents sur petit sous-ensemble | conditions/statuses Showdown | partiel | moyenne | non | non seul | code + tests |
| Useful volatiles | présents sur petit sous-ensemble | volatiles/conditions Showdown | partiel | moyenne | non | oui à terme | code + tests |
| Field state | weather + pseudoWeather bornés | `sim/field.ts` + `data/conditions.ts` | partiel | moyenne | non | oui | code + tests |
| Switch / reserves / replacement | présents en singles minimal | `battle-actions.ts` + `side.ts` | partiel | élevée | non pour coverage data | oui | code + tests |
| Runtime bridge | strict et honnête | Showdown n’a pas ce bridge | partiel local | moyenne | oui pour battleability pratique | indirect | code + tests |
| Seed builder filtering | présent et honnête | n/a | partiel local | moyenne | oui pour jouabilité pratique | non direct | code + tests |
| Outcome write-back | présent sur subset actuel | n/a | partiel local | moyenne | non | oui si moteur s’élargit beaucoup | code + tests |
| Overlay/timeline | désormais honnête sur subset actuel | Showdown log system plus riche | partiel | faible | non | non direct | code + tests |
| Data scaffold / catalog coverage | très faible | Showdown `data/moves.ts` + `data/learnsets.ts` riches | absent côté parité | élevée | **oui immédiatement** | oui | exécution + scan data |

---

## 8. Faux positifs dangereux

1. **Les tests runtime verts ne signifient pas que le contenu versionné est battleable.**
   - Ils construisent des mini-projets synthétiques temporaires.
   - Ils prouvent des seams et un sous-ensemble moteur.
   - Ils ne prouvent pas l’état réel du contenu scaffoldé/versionné.

2. **Le bootstrap seed donne une illusion de “catalogue battle initial” plus large qu’en réalité.**
   - 21 moves seedés semble respectable.
   - En pratique, seulement 12 projettent réellement aujourd’hui.

3. **`structuredSupported` n’implique pas automatiquement “bridgeable maintenant”.**
   - Exemples confirmés : `absorb`, `double_slap`, `u_turn`, `whirlwind`.

4. **Le runtime fixture universe sur-vend la readiness du projet.**
   - Les fixtures riches prouvent que le moteur/runtime est plus large que le bootstrap.
   - Elles ne prouvent pas qu’un projet frais ou authored versionné est prêt.

5. **Le host d’exemple n’embarque pas de projet authored.**
   - Il demande explicitement un `project.json` externe.
   - Il ne constitue donc pas une preuve de battleability du repo seul.

6. **Le filtrage des moves non bridgeables au seed assembly évite des annulations inutiles, mais peut masquer la pauvreté réelle du moveset résultant.**
   - C’est honnête pour la stabilité.
   - Ce n’est pas une preuve de parité ni même de qualité de contenu.

---

## 9. Problèmes confirmés / non confirmés

### Confirmés

- Pas de projet authored battle-ready versionné dans le repo.
- Bootstrap/scaffold moves trop étroit pour rendre un projet frais réellement battleable.
- Seed bootstrap en retard sur le moteur pour au moins `solar_beam` et `trick_room`.
- Bridge/runtime encore insuffisants pour certains moves seedés `structuredSupported`.
- Les import packs versionnés ne deviennent presque jamais battleables sur le scaffold bootstrap actuel.
- Le moteur reste structurellement très en dessous de Showdown singles sur `Side`/`slot`, event engine et queue.

### Non confirmés / à ne pas sur-vendre

- “Le projet utilisateur externe typique est largement battleable” : **non mesuré**.
- “Il faut immédiatement refondre tout le moteur” : **non prouvé par ce lot**.
- “Le prochain lot doit forcément être un lot de fondation plutôt qu’un lot de couverture” : **discutable**, dépend du niveau d’ambition court terme.

### Incertains

- Taille exacte du gain pratique d’un lot coverage lift unique avant de toucher aux fondations.
- Nombre d’espèces réellement sauvées par simple alignement bootstrap -> moteur supporté.

---

## 10. Blockers structurels

### Blockers immédiats pour rendre le projet plus réellement exploitable

1. **Bootstrap/scaffold coverage trop faible**.
2. **Absence de contenu authored versionné servant de golden slice battle-ready**.
3. **Gap seed/bridge sur quelques moves déjà seedés**.

### Blockers de fondation pour converger vers Showdown singles ciblée

1. **Modèle de décision par tour trop petit**, bien qu’existant.
   - Le repo a déjà un `BattleStartRequest` et un modèle local `PlayerBattleChoice*`.
   - Le vrai manque est un **request/decision protocol plus riche par tour**, pas “zéro request model”.

2. **Absence de `Side` / `slot` explicites**.

3. **Absence d’event/condition engine**.

4. **Absence de vraie queue d’actions/faint/switch riche**.

5. **Contrats de données battle encore trop fermés** :
   - move,
   - combatant,
   - field,
   - volatile.

6. **Runtime write-back encore calibré sur le subset actuel**.

### Critique explicite du prompt

#### Ce que le prompt a bien forcé

- regarder les **vraies données versionnées** et pas seulement l’architecture locale ;
- mesurer la couverture réelle au lieu de rester dans des phrases vagues ;
- comparer à Showdown de façon concrète et utile ;
- séparer battle engine, runtime handoff, data scaffold et UI.

#### Ce qui était discutable

- la demande “combien de combats wild/trainer authored peuvent démarrer aujourd’hui ?” supposait implicitement qu’un projet authored complet était versionné ;
- en réalité ce repo versionne surtout des seeds, fixtures et seams, pas une campagne battle-ready.

#### Ce qui aurait été dangereux si suivi aveuglément

- traiter les import packs editor comme du vrai contenu runtime canonique ;
- traiter les fixtures runtime comme une preuve de readiness produit ;
- conclure “il faut forcément refondre tout le moteur” sans d’abord distinguer scaffold coverage et fondations Showdown.

#### Recadrage retenu

- j’ai répondu à la question “combats authored versionnés” par **0 mesurable**, au lieu d’inventer un proxy silencieux ;
- puis j’ai ajouté des mesures de **combat plausibles par proxy** :
  - scaffold bootstrap + import packs,
  - fixtures runtime synthétiques.

---

## 11. Plan court terme pragmatique

### Recommandation nette

Le meilleur prochain mouvement n’est **pas** d’ouvrir immédiatement une nouvelle mécanique Showdown-like.

Le meilleur plan court terme est :

1. **Créer une vérité de contenu battleable versionnée**
   - versionner un petit golden project slice battle-ready réellement lançable ;
   - ou, à défaut, un pack runtime minimal officiel utilisé en CI.

2. **Aligner le scaffold/bootstrap avec le moteur réellement supporté**
   - pas pour “faire joli” ;
   - pour que le projet frais reflète enfin honnêtement le sous-ensemble moteur déjà livré.

3. **Mesurer à nouveau**
   - après cet alignement, re-mesurer :
     - combien d’espèces/imports deviennent battleables ;
     - quels blockers restent dominants.

4. **Décision gate**
   - si les blockers restants sont surtout des moves simples compatibles avec les contrats actuels : faire **un seul lot coverage lift borné** ;
   - si les blockers dominants tombent vite sur `selfSwitch`, `forceSwitch`, conditions, side/slot, callbacks : arrêter la croissance opportuniste et partir sur fondations.

### Quick wins réels

- Alignement bootstrap -> bridge/moteur pour les moves déjà réellement supportés (`solar_beam`, `trick_room`, probablement d’autres moves simples déjà prouvés en fixtures).
- Golden battle-ready project slice versionné.
- Rapport de couverture automatisable à la frontière runtime/seed builder.

### Faux quick wins

- Marquer arbitrairement plus de moves `structuredPartial` comme bridgeables.
- Ajouter plein de moves seedés sans stratégie de vérité ni re-mesure.
- Prendre les fixtures de tests pour une preuve de readiness produit.

### Blockers de contenu

- bootstrap narrow/stale ;
- absence de pack authored battle-ready ;
- import packs conçus pour l’UI/editor, pas comme dex battle-ready.

### Blockers moteur

- `drain`, `multi_hit`, `self_switch`, `force_switch` ne rentrent pas encore honnêtement ;
- puis, au-delà, `Side`/`slot`/event engine/queue.

---

## 12. Plan fondation Showdown singles ciblé

### Ordre recommandé

#### Lot F1 — Request/decision model singles enrichi

- Objectif :
  - passer d’un modèle de choix minimal à un vrai protocole de décisions singles par tour ;
  - préparer forced switch, pending replacement, disabled choices, richer runtime handoff.
- Pourquoi maintenant :
  - avant `Side`/`slot`, mais après avoir clarifié la vérité de couverture réelle.
- Risque :
  - glisser vers un moteur parallèle si mal conçu.

#### Lot F2 — `Side` / `slot` minimal local

- Objectif :
  - introduire enfin un vrai endroit pour side conditions, slot conditions, pending replacement, topology singles stable.
- Pourquoi maintenant :
  - impossible d’ouvrir hazards/forced switches honnêtement sans ça.

#### Lot F3 — Mini event/condition engine singles

- Objectif :
  - sortir des branches ad hoc dans `battle_session.dart` ;
  - porter conditions/weather/side logic plus proprement.
- Pourquoi maintenant :
  - prérequis avant hazards, abilities/items, beaucoup de secondaries.

#### Lot F4 — Queue d’actions/faints/switches plus riche

- Objectif :
  - gérer proprement insertions, interruptions, faint handling et remplacements plus proches de Showdown.

#### Lot F5 — Expansion des contrats move/combatant/field/volatile sur la nouvelle base

- Objectif :
  - ouvrir ensuite les moves et systèmes plus riches sans dette immédiate.

### Ce qui peut attendre

- doubles ;
- abilities/items complets ;
- terrains complets ;
- formes/transformations riches ;
- targeting riche beyond singles.

### Ce qui ne peut plus attendre si on vise la vraie parité singles

- `Side` / `slot`
- event/condition engine
- queue riche

### Erreurs stratégiques à éviter

- Continuer à empiler des champs one-off sur `BattleMove`.
- Ouvrir hazards avant `Side`.
- Ouvrir `selfSwitch` / `forceSwitch` avant request/queue/slot topology.

---

## 13. Consultation proposée avec ChatGPT

### Mon meilleur plan à challenger

1. **Ne pas ouvrir immédiatement une nouvelle feature moteur visible**.
2. **Faire d’abord un lot “vérité de couverture + scaffold alignment”** :
   - golden project slice versionné ;
   - bootstrap aligned on current supported subset ;
   - re-mesure.
3. **Ensuite décider** :
   - soit un unique coverage lift borné si les blockers restants sont encore compatibles avec les contrats actuels ;
   - soit passage immédiat aux fondations `request/side/event/queue`.

### Points que je veux voir challengés par ChatGPT

- Est-ce qu’un lot coverage/scaffold juste après ce Lot 0 est vraiment le meilleur move, ou est-ce qu’il faut sauter directement aux fondations ?
- Jusqu’où peut-on encore étendre honnêtement le moteur actuel avant que `Side`/`slot` deviennent non négociables ?
- Le prochain chantier de fondation doit-il être d’abord request model, ou d’abord `Side` ?
- Faut-il introduire un mini event engine avant les hazards, ou seulement juste avant le premier lot hazards/conditions ?

### Endroits où j’hésite encore

- ampleur réelle du gain qu’apporterait un lot bootstrap/scaffold alignment sur la battleability pratique ;
- seuil à partir duquel un coverage lift supplémentaire devient une erreur de fondation ;
- ordre exact `request model` vs `Side` comme premier lot structurel.

### Questions de design/architecture à poser à ChatGPT

1. Le prochain lot doit-il être un lot de **couverture/scaffold battle réel**, ou un lot de **fondation request/side** ?
2. Combien de features singles supplémentaires peut-on encore ajouter honnêtement avant d’introduire un vrai `Side` ?
3. Le mini event engine doit-il arriver **avant** hazards/force-switch, ou seulement en même temps ?
4. Faut-il versionner un **golden battle-ready project slice** avant de continuer la croissance moteur ?
5. Quels signaux mesurés doivent déclencher la bascule de “coverage lift incrémental” vers “refonte de fondation” ?

---

## 14. Retour du sub-agent audit/design

### Audit/data coverage — Bernoulli

Apport retenu :

- confirmation brutale qu’il n’existe pas de vrai projet authored battle-ready versionné ;
- vérification que le bootstrap seed est le seul vrai seed battle versionné côté projet frais ;
- rappel utile que le host d’exemple charge un projet externe, et n’embarque pas de contenu authored battle-ready.

Ce que je retiens :

- la battleability authored versionnée du repo est effectivement nulle à mesurer directement ;
- il faut parler de seeds/fixtures/scaffold, pas de “contenu jeu”.

Ce que je rejette :

- rien de substantiel ; le retour est cohérent avec mes propres mesures.

### Architecture/plan — Hume

Apport retenu :

- bon recadrage : le prochain vrai move ne devait pas être une nouvelle feature battle visible ;
- bonne hiérarchie de fondation :
  - request/decision model singles,
  - `Side`/`slot`,
  - mini event engine,
  - queue plus riche.

Ce que je retiens :

- le prochain plan doit explicitement distinguer quick coverage lift et fondations.

Ce que je rejette / nuance :

- je ne reprends pas textuellement “missing request model” ; après review, je resserre en “request/decision model existant mais trop étroit”.

---

## 15. Retour du reviewer séparé

### Reviewer principal — Kant

Objections utiles :

1. Je surévaluais le manque “request model”.
   - Correction retenue :
     - le repo a déjà un request/start layer runtime et un modèle local `PlayerBattleChoice*` ;
     - le vrai manque est un protocole de décision par tour plus riche + `Side`/`slot`.

2. Je parlais trop vite d’un “univers fixture runtime unique”.
   - Correction retenue :
     - je distingue désormais :
       - la fixture riche du `runtime_battle_combatant_seed_builder_test.dart` (21 moves, 20 bridgeables),
       - la fixture riche du `runtime_battle_setup_mapper_test.dart` (19 moves, 18 bridgeables, `teleport` seul refus intentionnel).

3. Je sous-jouais le fait que le problème immédiat est un **gap seed/bridge**, pas seulement “seed breadth”.
   - Correction retenue :
     - le report insiste maintenant explicitement sur le double problème :
       - bootstrap absent/trop étroit,
       - bootstrap présent mais encore rejeté pour certains moves.

### Reviewer supplémentaire — Chandrasekhar

Objections utiles :

- il fallait éviter de traiter les fixtures import/editor comme s’il s’agissait d’un dex runtime canonique ;
- il fallait dire explicitement que le seed bootstrap est **curaté et incomplet par design**, donc le problème est “scaffold coverage” plus que “pseudo prod content en échec”.

Corrections retenues :

- le report sépare désormais strictement :
  - scaffold bootstrap,
  - import fixture UI/editor,
  - mini-projets synthétiques de tests,
  - contenu authored versionné.

---

## 16. Autocritique finale

- Le point le plus fragile de l’audit est l’absence de vrai contenu authored versionné : j’ai dû mesurer la battleability réelle **par proxy**, pas sur une campagne locale versionnée.
- J’ai de bonnes preuves sur :
  - le scaffold bootstrap,
  - les import packs versionnés,
  - les fixtures runtime synthétiques.
- J’ai moins de preuves sur :
  - la battleability d’un projet utilisateur externe réel,
  - la part exacte des futurs blockers qui tomberaient sur fondations plutôt que sur simple couverture.
- Le risque principal de cet audit serait de conclure trop vite :
  - soit “il suffit d’ajouter des moves” ;
  - soit “il faut tout refondre tout de suite”.
- La bonne lecture est plus nuancée :
  - **à court terme, la vérité du projet frais est surtout un problème de scaffold/couverture** ;
  - **à moyen terme, la vraie parité Showdown singles exigera des fondations plus riches**.

---

## 17. État git utile final

Commandes relancées après création du présent report :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réels :

- `git status --short`

```text
?? reports/lot0-real-battle-coverage-and-showdown-plan.md
```

- `git diff --stat`

```text

```

- `git ls-files --others --exclude-standard`

```text
reports/lot0-real-battle-coverage-and-showdown-plan.md
```

---

## 18. Checklist finale

- [x] j’ai audité le code réel battle/runtime
- [x] j’ai audité les vraies données versionnées pertinentes
- [x] j’ai distingué scaffold/bootstrap, fixtures synthétiques et contenu authored
- [x] j’ai comparé à du vrai code Showdown lu en lecture seule
- [x] j’ai donné des chiffres réels plutôt que des impressions
- [x] j’ai distingué data issue / bridge issue / moteur issue / architecture issue
- [x] j’ai utilisé au moins un sub-agent data coverage
- [x] j’ai utilisé au moins un sub-agent architecture/plan
- [x] j’ai utilisé une review séparée réelle
- [x] je n’ai modifié aucun fichier code produit
- [x] je n’ai pas touché `packages/map_core`
- [x] je n’ai pas touché `packages/map_editor`
- [x] je n’ai fait aucune écriture Git interdite
- [x] j’ai produit un plan court terme pragmatique
- [x] j’ai produit un plan fondation Showdown singles ciblé
- [x] j’ai inclus une section “Consultation proposée avec ChatGPT”
- [x] j’ai indiqué mes zones d’incertitude

---

## 19. Contenu complet de tous les fichiers modifiés / créés / supprimés

Ce lot est audit-only.

Fichiers de repo modifiés/créés/supprimés :

- créé : [reports/lot0-real-battle-coverage-and-showdown-plan.md](/Users/karim/Project/pokemonProject/reports/lot0-real-battle-coverage-and-showdown-plan.md)

Je n’inclus pas ici le contenu intégral du report lui-même, car ce fichier est précisément le document que vous lisez : l’auto-inclure textuellement créerait une récursion infinie sans ajouter d’information utile.

Tous les autres artefacts générés pendant l’audit (`/tmp/*.json`, `/tmp/*.dart`) ont été créés **hors dépôt** pour mesurer la couverture réelle sans toucher au code produit.
