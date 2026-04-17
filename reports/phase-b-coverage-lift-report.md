# Phase B — Coverage lift borné report


## 1. Résumé exécutif honnête

Verdict honnête : **Gate A était bien satisfait**, mais seulement de façon étroite.

Le lift effectivement exécuté est un unique lot bootstrap/scaffold de 5 moves :
- `scratch`
- `ember`
- `quick_attack`
- `tail_whip`
- `water_gun`

Le lot est valide parce qu’il n’ouvre aucune nouvelle mécanique battle et reste strictement dans des seams déjà absorbés par le bridge + moteur.

En revanche, après durcissement de la mesure pour la faire coller à la vraie sévérité du seed builder runtime, le constat Gate B est plus sévère qu’au milieu du lot :
- le golden slice Phase A reste vert et inchangé côté produit ;
- le scaffold/bootstrap s’améliore réellement ;
- mais les blockers restants dominants retombent déjà sur des moves ou mécaniques qui ne rentrent plus proprement dans un second lift coverage-compatible rentable.

Chiffres utiles :
- golden slice Phase A reruné : `1 / 1` wild et `1 / 1` trainer, toujours verts
- bootstrap courant reruné via la mesure Phase A : `18 / 26` moves bridgeables
- import pack scaffold coverage (niveau 10, helper runtime partagée, vraie sévérité de seed builder) :
  - baseline `full_damage_ready` : `1`
  - current `full_damage_ready` : `4`
  - baseline `blocked` : `9`
  - current `blocked` : `6`
  - espèces strictement améliorées : `3`

Le lot améliore donc bien la battleability du scaffold, mais il ne laisse plus assez de couverture simple propre pour justifier un deuxième mini-lift Phase B sans discussion de fondation.

## 2. Pré-gates exécutés + résultats

### 2.1. Git read-only initial

```text
M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
 M packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
```


Constat initial honnête : au premier contrôle git de cette exécution, le worktree n’était déjà pas propre. Deux fichiers `map_editor` étaient déjà modifiés dans la zone exacte du lift pressenti. J’ai traité cet état comme base locale du lot, puis j’ai audité avant de décider si la Phase B restait légitime.

### 2.2. Audit documentaire et code réellement relus
- `reports/lot0-real-battle-coverage-and-showdown-plan.md`
- `reports/phase-a-golden-battle-slice-report.md`
- `reports/phase-a-battle-coverage.md`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
- `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/**`
- `pokemon-showdown-master/data/moves.ts` pour les 5 moves retenus

### 2.3. Gate A
Gate A est **confirmé** parce que :
- le golden slice versionné existe réellement ;
- le smoke test local canonique existe réellement ;
- ce smoke test rerun reste vert ;
- la mesure Phase A est relançable localement ;
- il restait encore un vrai problème de scaffold/bootstrap sous-couvert, distinct des fondations.


## 3. Méthode réelle utilisée

### Confirmé par lecture de code
- le golden slice Phase A était déjà battleable avant ce lot ;
- les 5 moves retenus sont déjà absorbés honnêtement par le bridge et le moteur ;
- les blockers type `selfSwitch`, `forceSwitch`, hazards, terrains riches, side/slot, queue riche restent hors Phase B ;
- le pack d’import 10 Pokémon est un proxy scaffold, pas une vérité produit.

### Confirmé par exécution locale
- `map_editor` test ciblé vert
- `map_editor` analyze ciblé vert
- `map_runtime` analyze ciblé vert
- `runtime_battle_combatant_seed_builder_test.dart` + smoke Phase A verts
- script `generate_phase_b_scaffold_pack_coverage.sh` vert
- rerun temporaire de `phase_a_battle_coverage.dart` avec bootstrap courant vert

### Inférences raisonnables
- le premier lift améliore réellement le scaffold ;
- il existe encore un ou deux candidats coverage simples isolés (`thundershock` surtout), mais ils ne dominent plus les blockers restants.

### Points explicitement incertains
- aucune nouvelle vérité produit authored au-delà du golden slice n’a été versionnée dans ce lot ;
- l’impact d’un futur chantier fondation sur le bootstrap n’est pas mesurable avant conception.


## 4. Audit réel avant modification

### 4.1. Ce qui était déjà vert
- golden slice Phase A : wild `1/1`, trainer `1/1`
- runtime handoff / setup / write-back réels sur le sous-ensemble Phase A
- filtrage local des moves non bridgeables déjà ouvert dans le seed builder

### 4.2. Ce qui restait faible
- bootstrap embarqué plus étroit que le moteur/runtime réel
- espèces du pack d’import versionné encore largement bloquées faute de moves bootstrap simples manquants
- trop grande tentation d’interpréter des seeds “partiels” comme battleables, alors que la vraie sévérité runtime bloque sur move manquant

### 4.3. Classification initiale des blockers

#### Coverage-compatible au moment du choix
- `scratch`
- `ember`
- `quick_attack`
- `tail_whip`
- `water_gun`

#### Restants mais refusés dans ce lot
- `thundershock`, `lick`, `pound`, `defense_curl` laissés pour ne pas élargir le lot

#### Foundation-required ou refusés explicitement
- `u_turn`, `whirlwind`
- `stealth_rock`, `electric_terrain`, `healing_wish`
- `solar_beam`
- `wrap`, `twister`
- `confuse_ray`, `hypnosis`, `sing`, `disable`
- `counter`, `endure`
- `bite` laissé refusé faute de vérité canonique assez nette dans ce lot


## 5. Critique explicite du prompt

### Ce que le prompt forçait bien
- Gate A avant code
- un seul lot Phase B
- interdiction des mécaniques structurelles prématurées
- exigence d’une décision Gate B objectivable

### Ce qui était discutable
- la focalisation sur le golden slice pouvait faire croire que la vraie valeur de Phase B devait venir de `examples/` ; dans le repo réel, le levier encore rentable était surtout bootstrap/scaffold
- le prompt pouvait être lu comme si un second lift serait probablement encore rentable ; la mesure durcie montre que ce n’est plus vrai de façon dominante

### Ce qui aurait été dangereux
- traiter le pack d’import comme vérité produit
- mesurer avec une policy plus permissive que le runtime réel
- gonfler le bridge ou glisser vers `solar_beam` / secondaries plus riches


## 6. Décisions retenues / rejetées

### Retenues
1. Confirmer Gate A avant toute nouvelle implémentation.
2. Garder le lot dans bootstrap/scaffold sans toucher `examples/`.
3. Limiter le lift à 5 moves simples.
4. Ajouter un outillage de mesure local borné.
5. Après review, partager la helper runtime learnset et la helper runtime de résolution de moves pour que l’outil mesure le vrai seam.

### Rejetées
1. Ouvrir `solar_beam`.
2. Ouvrir `thundershock` dans ce même lot.
3. Ajouter `lick`, `pound`, `defense_curl` dans le même patch.
4. Toucher `map_battle`.
5. Toucher `examples/` par confort.


## 7. Périmètre inclus / exclu

### Inclus
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart`
- `scripts/generate_phase_b_scaffold_pack_coverage.sh`
- `reports/phase-b-scaffold-pack-coverage.md`
- ce report final

### Exclus
- `examples/`
- `packages/map_battle/`
- nouvelles mécaniques battle
- request model / `Side` / event engine / queue
- toute écriture git


## 8. Plan local retenu

1. Vérifier Gate A sur la base du golden slice canonique déjà vert.
2. Identifier un lift bootstrap strictement coverage-compatible.
3. Mesurer le gain réel sur le pack d’import versionné.
4. Ne pas modifier le moteur battle.
5. Utiliser la review séparée pour durcir la vérité de la mesure.


## 9. Justification précise du lot choisi

Le lot retenu est cohérent avec la roadmap Phase B parce qu’il reste dans des seams déjà ouverts :
- dégâts simples
- priorité simple
- stat drop simple
- petit secondary status déjà supporté

Il ne demande ni `Side`, ni queue enrichie, ni event engine, ni request model plus riche.

## 10. Golden slice / vérité produit


Le golden slice n’a pas été modifié. La validation utile ici était donc : **rerun le smoke test existant**, pas inventer un autre smoke test.

Rerun temporaire de la mesure Phase A avec le bootstrap courant :

```text
# Phase A Battle Coverage

## Executive Summary

- Bootstrap moves bridgeables: 18 / 26
- Golden slice moves bridgeables: 3 / 3
- Player seeds bridgeables: 2 / 2
- Trainer seeds bridgeables: 1 / 1
- Wild seeds bridgeables: 1 / 1
- Wild battles startable: 1 / 1
- Trainer battles startable: 1 / 1

## Bootstrap Move Coverage

| moveId | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- |
| absorb | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:drain |
| double_slap | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:multi_hit |
| electric_terrain | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.durationCallback, showdown_callback:condition.onBasePower, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldStart, showdown_callback:condition.onSetStatus, showdown_callback:condition.onTryAddVolatile, unsupported_mechanic:condition |
| ember | structuredSupported | yes |  |  |
| feint | structuredSupported | yes |  |  |
| growl | structuredSupported | yes |  |  |
| healing_wish | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSwap, showdown_callback:condition.onSwitchIn, showdown_callback:onTryHit, unsupported_mechanic:condition, unsupported_mechanic:selfdestruct |
| hyper_beam | structuredSupported | yes |  |  |
| leer | structuredSupported | yes |  |  |
| quick_attack | structuredSupported | yes |  |  |
| rain_dance | structuredSupported | yes |  |  |
| razor_leaf | structuredSupported | yes |  |  |
| scratch | structuredSupported | yes |  |  |
| solar_beam | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:onBasePower, showdown_callback:onTryMove, unsupported_mechanic:weather_charge_shortcuts |
| stealth_rock | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSideStart, showdown_callback:condition.onSwitchIn, unsupported_mechanic:condition |
| swift | structuredSupported | yes |  |  |
| swords_dance | structuredSupported | yes |  |  |
| tackle | structuredSupported | yes |  |  |
| tail_whip | structuredSupported | yes |  |  |
| thunder_wave | structuredSupported | yes |  |  |
| thunderbolt | structuredSupported | yes |  |  |
| trick_room | structuredPartial | yes |  | unsupported_mechanic:turn_order_inversion, showdown_callback:condition.durationCallback, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldRestart, showdown_callback:condition.onFieldStart, unsupported_mechanic:condition |
| u_turn | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:self_switch |
| vine_whip | structuredSupported | yes |  |  |
| water_gun | structuredSupported | yes |  |  |
| whirlwind | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:force_switch |

## Golden Slice Move Coverage

| moveId | occurrences | sources | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- | --- | --- |
| growl | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| tackle | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| vine_whip | 1 | player_party[0] | structuredSupported | yes |  |  |

## Player Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| player_party[0]:active:sproutle | tackle, growl, vine_whip | tackle, growl, vine_whip | bridgeable |  |
| player_party[1]:reserve:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Trainer Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| trainer:trainer_rookie[0]:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Wild Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | tackle, growl | tackle, growl | bridgeable |  |

## Authored Battle Startability

| kind | label | startable | reason |
| --- | --- | --- | --- |
| wild | wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | yes |  |
| trainer | trainer:golden_field:npc_trainer_rookie:trainer_rookie | yes |  |

## Notes

- Wild battle opportunities are measured at the authored `zone -> table entry` level.
- Trainer battles are measured at the authored NPC trainer hook level.
- Player truth comes from the versioned launch save, not from test-only fixtures.
- This report is generated locally from the real golden slice and the real embedded bootstrap seed.

```


Lecture honnête :
- le slice produit reste vert ;
- le bootstrap courant s’élargit ;
- la vérité produit n’a pas été dégradée.


## 11. Alignement bootstrap/scaffold

### Moves ajoutés
- `scratch`
- `ember`
- `quick_attack`
- `tail_whip`
- `water_gun`

### Pourquoi eux
- présents dans des learnsets versionnés du pack d’import
- déjà honnêtement supportés par le bridge et le moteur
- cohérents comme mini-famille early-game

### Pourquoi pas plus
Parce qu’un lift plus large aurait brouillé la décision Gate B et augmenté le risque de mensonge sur le support.

## 12. Rapport de couverture réel


```markdown
# Phase B Scaffold Pack Coverage

## Executive Summary

- Import pack directory: `/Users/karim/Project/pokemonProject/packages/map_editor/test/fixtures/manual_pokemon_import_pack_10`
- Level analyzed with the shared runtime learnset helper: `10`
- Species seeds analyzed: `10`
- Baseline descriptor: `/tmp/phase_b_bootstrap_before.json (sha256:adceb058c1ed6cc344b34f3ba389dafdb2a7bb6e14e3294e5c23605a7d9ea3ab)`
- Baseline fully covered damage-ready species: `1`
- Baseline partial damage-ready species: `0`
- Baseline partial status-only species: `0`
- Baseline blocked species: `9`
- Current fully covered damage-ready species: `4`
- Current partial damage-ready species: `0`
- Current partial status-only species: `0`
- Current blocked species: `6`
- Species with a strictly better status after the lift: `3`

## Current Candidate Move Coverage

| moveId | occurrences | species | baselineStatus | currentStatus | currentBridgeFailure | currentUnsupportedReasons |
| --- | --- | --- | --- | --- | --- | --- |
| bite | 1 | meowth | missing_from_bootstrap | missing_from_bootstrap |  |  |
| confuse_ray | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| counter | 1 | riolu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| defense_curl | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| disable | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| ember | 1 | charmander | missing_from_bootstrap | bridgeable |  |  |
| endure | 1 | riolu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| growl | 4 | bulbasaur, charmander, meowth, pikachu | bridgeable | bridgeable |  |  |
| hypnosis | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| leer | 1 | dratini | bridgeable | bridgeable |  |  |
| lick | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| pound | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| quick_attack | 3 | eevee, pikachu, riolu | missing_from_bootstrap | bridgeable |  |  |
| scratch | 2 | charmander, meowth | missing_from_bootstrap | bridgeable |  |  |
| sing | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| tackle | 3 | bulbasaur, eevee, squirtle | bridgeable | bridgeable |  |  |
| tail_whip | 2 | eevee, squirtle | missing_from_bootstrap | bridgeable |  |  |
| thundershock | 1 | pikachu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| twister | 1 | dratini | missing_from_bootstrap | missing_from_bootstrap |  |  |
| vine_whip | 1 | bulbasaur | bridgeable | bridgeable |  |  |
| water_gun | 1 | squirtle | missing_from_bootstrap | bridgeable |  |  |
| wrap | 1 | dratini | missing_from_bootstrap | missing_from_bootstrap |  |  |

## Current Species Coverage

| speciesId | candidateMoveIds | builtMoveIds | missingMoveIds | rejectedMoveIds | status |
| --- | --- | --- | --- | --- | --- |
| bulbasaur | tackle, growl, vine_whip | tackle, growl, vine_whip |  |  | full_damage_ready |
| charmander | scratch, growl, ember | scratch, growl, ember |  |  | full_damage_ready |
| dratini | wrap, leer, twister |  | wrap, twister |  | blocked |
| eevee | tackle, tail_whip, quick_attack | tackle, tail_whip, quick_attack |  |  | full_damage_ready |
| gastly | lick, confuse_ray, hypnosis |  | lick, confuse_ray, hypnosis |  | blocked |
| jigglypuff | sing, pound, defense_curl, disable |  | sing, pound, defense_curl, disable |  | blocked |
| meowth | scratch, growl, bite |  | bite |  | blocked |
| pikachu | thundershock, growl, quick_attack |  | thundershock |  | blocked |
| riolu | quick_attack, endure, counter |  | endure, counter |  | blocked |
| squirtle | tackle, tail_whip, water_gun | tackle, tail_whip, water_gun |  |  | full_damage_ready |

## Baseline vs Current Species Delta

| speciesId | beforeStatus | afterStatus | beforeBuiltMoveIds | afterBuiltMoveIds | delta |
| --- | --- | --- | --- | --- | --- |
| bulbasaur | full_damage_ready | full_damage_ready | tackle, growl, vine_whip | tackle, growl, vine_whip |  |
| charmander | blocked | full_damage_ready |  | scratch, growl, ember | fully_unblocked_damage_ready |
| dratini | blocked | blocked |  |  |  |
| eevee | blocked | full_damage_ready |  | tackle, tail_whip, quick_attack | fully_unblocked_damage_ready |
| gastly | blocked | blocked |  |  |  |
| jigglypuff | blocked | blocked |  |  |  |
| meowth | blocked | blocked |  |  |  |
| pikachu | blocked | blocked |  |  |  |
| riolu | blocked | blocked |  |  |  |
| squirtle | blocked | full_damage_ready |  | tackle, tail_whip, water_gun | fully_unblocked_damage_ready |

## Notes

- This report is **not** a product truth report like Phase A.
- It measures scaffold/import-pack truth with the real bootstrap and the real runtime bridge.
- `full_damage_ready` means every candidate move is bridgeable and at least one built move is offensive.
- `partial_damage_ready` means the seed remains usable in battle, but some candidate moves are still missing or rejected.
- `partial_status_only` means the seed can still be built, but only with non-offensive moves after filtering.
- `blocked` means no bridgeable move remains after filtering.

```


Lecture honnête de cette mesure :
- elle est plus sévère que ma première version parce qu’elle passe maintenant par les mêmes helpers runtime que la production ;
- elle montre que le lift a sauvé exactement trois espèces complètes (`charmander`, `eevee`, `squirtle`) ;
- elle montre aussi que `meowth`, `pikachu`, `riolu`, `dratini`, `gastly`, `jigglypuff` restent bloqués sous la vraie sévérité runtime.


## 13. Commandes réellement exécutées

### Git read-only
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

### Audit / lecture
- `sed -n ... reports/lot0-real-battle-coverage-and-showdown-plan.md`
- `sed -n ... reports/phase-a-golden-battle-slice-report.md`
- `sed -n ... reports/phase-a-battle-coverage.md`
- `sed -n ... packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `sed -n ... packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
- `python3` / `jq` ad hoc pour inspecter le pack d’import
- `rg -n` / `sed -n` dans `pokemon-showdown-master/data/moves.ts`

### Validation / exécution
- `cd packages/map_editor && /opt/homebrew/bin/flutter test test/pokemon_moves_bootstrap_seed_test.dart`
- `cd packages/map_editor && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart test/pokemon_moves_bootstrap_seed_test.dart tool/export_embedded_pokemon_moves_bootstrap.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_combatant_seed_builder.dart tool/phase_b_scaffold_pack_coverage.dart test/runtime_battle_combatant_seed_builder_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_combatant_seed_builder_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `FLUTTER_BIN=/opt/homebrew/bin/flutter ./scripts/generate_phase_b_scaffold_pack_coverage.sh /tmp/phase_b_bootstrap_before.json`
- export + rerun temporaire de `phase_a_battle_coverage.dart` vers `/tmp/phase_b_phase_a_current.md`


## 14. Résultats réels format / analyze / tests / smoke / scripts

- `dart format` ciblé : vert
- `map_editor` test ciblé : vert
- `map_editor` analyze ciblé : vert
- `map_runtime` analyze ciblé : vert
- `runtime_battle_combatant_seed_builder_test.dart` : vert
- `phase_a_golden_battle_slice_smoke_test.dart` : vert
- `generate_phase_b_scaffold_pack_coverage.sh` : vert
- rerun temporaire Phase A coverage : vert


## 15. Incidents rencontrés

1. Flutter startup lock dû à des validations parallèles. Résolu en repassant les commandes en série.
2. Bug local dans l’outil Phase B (`const` + élément conditionnel). Corrigé puis rerun analyze.
3. First review (Lovelace) : l’outil sur-vendait l’usage de la policy runtime et n’exposait pas le vrai motif de rejet bridge. Corrigé.
4. Second review (Gauss) : la mesure species overclaimait encore la battleability en tolérant des moves catalogue manquants. Corrigé en faisant passer le statut global par la vraie helper runtime de résolution.
5. Wrapper Phase B initialement trop peu portable et baseline non traçable. Corrigé via `FLUTTER_BIN` et `baselineLabel` avec checksum.
6. Un artefact parasite `reports/phase-b-battle-coverage.md` a été supprimé.

## 16. État git utile final

### `git status --short --untracked-files=all`

```text
M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
 M packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
?? packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart
?? reports/phase-b-coverage-lift-report.md
?? reports/phase-b-scaffold-pack-coverage.md
?? scripts/generate_phase_b_scaffold_pack_coverage.sh
```

### `git diff --stat`

```text
.../seeds/pokemon_moves_bootstrap_seed.dart        | 113 +++++++++
 .../test/pokemon_moves_bootstrap_seed_test.dart    |  77 ++++++
 .../runtime_battle_combatant_seed_builder.dart     | 270 ++++++++++++---------
 3 files changed, 339 insertions(+), 121 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart
reports/phase-b-coverage-lift-report.md
reports/phase-b-scaffold-pack-coverage.md
scripts/generate_phase_b_scaffold_pack_coverage.sh
```


## 17. Checklist finale

- [x] ai-je audité le repo réel avant de modifier ?
- [x] ai-je vérifié honnêtement que Gate A était satisfait ?
- [x] ai-je distingué coverage-compatible vs foundation-required ?
- [x] ai-je choisi un unique lot Phase B borné ?
- [x] ai-je évité toute nouvelle grosse mécanique battle ?
- [x] ai-je évité toute refonte de fondation prématurée ?
- [x] ai-je évité `examples/` faute de nécessité stricte ?
- [x] ai-je réaligné le bootstrap sans mentir sur la couverture ?
- [x] ai-je produit une mesure réelle avant/après ?
- [x] ai-je rerun le smoke test local canonique ?
- [x] ai-je utilisé un sub-agent coverage/data ?
- [x] ai-je utilisé un sub-agent architecture/scope ?
- [x] ai-je utilisé un reviewer séparé ?
- [x] ai-je intégré les remarques valides du reviewer ?
- [x] ai-je évité toute écriture Git interdite ?
- [x] ai-je signalé les points discutables du prompt ?
- [x] ai-je laissé une décision Gate B objectivable ?


## 18. Retour du sub-agent

### Copernicus — audit architecture/scope
Retenu :
- Gate A encore légitime, mais étroitement ;
- un seul mini-lift encore défendable ;
- refus explicite de `solar_beam` et des mécaniques structurelles.

### Faraday — audit coverage/data
Retenu :
- le vrai gain venait du scaffold/import pack, pas du golden slice ;
- le premier lot retenu était la bonne famille de moves.

Point révisé après durcissement local :
- la première lecture de milieu de lot était trop optimiste parce qu’elle n’appliquait pas encore la même sévérité runtime sur les moves manquants. La version finale du report corrige ce point.


## 19. Retour du reviewer séparé

### Lovelace
Findings initiaux retenus :
1. overclaim sur la policy learnset runtime ;
2. confusion entre raison catalog et vrai rejet du bridge.

Après correction : Lovelace a explicitement confirmé que ces points étaient résolus et qu’aucun nouveau finding matériel n’était visible.

### Gauss
Findings retenus :
1. la mesure species utilisait encore une sévérité trop permissive par rapport au vrai seed builder ;
2. baseline non traçable ;
3. wrapper trop dépendant d’un path Flutter machine-spécifique.

Après correction : je n’ai pas reçu de re-review exploitable dans le temps du lot, mais j’ai intégré les trois remarques et relancé toute la validation locale.


## 20. Corrections appliquées après review

1. extraction de `deriveBattleCandidateMoveIdsFromLearnset`
2. extraction de `resolveBattleMovesForSeed`
3. outil Phase B recâblé sur les helpers runtime partagées
4. ajout de `currentBridgeFailure`
5. ajout de `baselineLabel` + checksum
6. wrapper portable via `FLUTTER_BIN`
7. reruns complets après ces corrections


## 21. Autocritique finale

Le lot est correct, mais il m’a fallu deux passes de review pour éliminer un biais important : ma première mesure racontait une battleability scaffold trop optimiste. Sans le reviewer séparé, la décision Gate B aurait été trop flatteuse.

La version finale est moins brillante mais plus utile : elle montre que le lot est bon, tout en révélant que le reste du gain coverage simple est désormais trop mince pour justifier honnêtement une Phase B prolongée.


## 22. Décision finale Gate B recommandée

Le lift actuel est réussi, mais la nouvelle mesure durcie change la conclusion :
- `charmander`, `eevee`, `squirtle` sont vraiment sauvés proprement
- `pikachu` resterait sauvable avec `thundershock`, mais cela devient presque un cas isolé
- `meowth`, `riolu`, `dratini`, `gastly`, `jigglypuff` retombent déjà sur des moves ou ensembles de moves non rentables dans une logique Phase B stricte

Autrement dit : les blockers dominants restants ne sont plus des blockers coverage simples assez nombreux pour justifier un second mini-lift propre.

**La Phase B doit s’arrêter ici et le projet doit basculer sur les fondations.**


## 23. Contenu complet de tous les fichiers modifiés / créés / supprimés

Le report s’exclut lui-même de l’annexe pour éviter une récursion infinie.

### `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/pokemon_project_data_models.dart';

/// Version logique du seed embarqué des moves bootstrap.
///
/// On ne crée pas ici un nouveau schéma JSON ni un framework de seed générique.
/// La "version" utile pour ce lot est simplement :
/// - un entier local, facile à relire dans le code ;
/// - reporté aussi dans les notes du catalogue seedé ;
/// - assez simple pour tracer les évolutions sans rouvrir `PokemonDataMeta`.
const int embeddedPokemonMovesSeedVersion = 1;

/// Construit le catalogue `moves` embarqué pour le bootstrap projet.
///
/// Choix d'architecture volontaire :
/// - le seed est codé en Dart, pas en asset Flutter ;
/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
/// - le seed passe par les vrais modèles canoniques `PokemonMove`, puis
///   sérialise `toJson()` ;
/// - la copie dans le projet reste un simple write JSON, sans génération live.
///
/// Pourquoi pas un asset JSON pour M4 :
/// - `map_editor` ne versionne pas déjà ce type de seed via `flutter/assets` ;
/// - le use case d'initialisation est aujourd'hui un seam applicatif simple,
///   testable sans plomberie Flutter ;
/// - ajouter une lecture d'asset ici ouvrirait une couche de packaging plus
///   large que nécessaire pour ce seul lot.
///
/// Pourquoi pas le catalogue Showdown complet :
/// - cela demanderait soit du tooling de génération versionné, soit un gros
///   artefact généré hors scope M4 ;
/// - M4 doit fixer le seam bootstrap, pas ouvrir un chantier "catalog dump".
///
/// Le seed reste donc volontairement :
/// - canonique ;
/// - offline ;
/// - substantiel ;
/// - mais encore curaté.
PokemonCatalogFile buildEmbeddedPokemonMovesBootstrapSeed() {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: const PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>[
        'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
        'Curated from Showdown-backed move data and versioned in the repository.',
        'bootstrap_seed_version:$embeddedPokemonMovesSeedVersion',
      ],
    ),
    entries: _embeddedPokemonMovesSeedEntries
        .map((move) => move.toJson())
        .toList(growable: false),
  );
}

/// Le seed n'essaie pas d'être tout Showdown.
///
/// On prend un sous-ensemble volontairement utile pour un projet frais :
/// - attaques simples courantes ;
/// - quelques statuts et boosts ;
/// - quelques moves plus "structurels" pour garder des entrées qui montrent
///   honnêtement les limites actuelles (`catalog_only` quand nécessaire).
final List<PokemonMove> _embeddedPokemonMovesSeedEntries = <PokemonMove>[
  ..._structuredSupportedSeedMoves,
  ..._catalogOnlySeedMoves,
];

/// Moves dont la structure utile est déjà correctement portée par le modèle.
///
/// Même si `map_battle` ne consomme pas encore tout cela, le modèle canonique
/// est capable de les décrire sans mensonge métier majeur.
final List<PokemonMove> _structuredSupportedSeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'absorb',
    showdownMoveId: 'absorb',
    name: 'Absorb',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 20,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.drain(numerator: 1, denominator: 2),
    ],
    shortDescription: 'User recovers 50% of the damage dealt.',
    description:
        'The user recovers 1/2 the HP lost by the target, rounded half up. '
        'If Big Root is held by the user, the HP recovered is 1.3x normal, '
        'rounded half down.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:drain',
    ],
  ),
  _showdownSeedMove(
    id: 'double_slap',
    showdownMoveId: 'doubleslap',
    name: 'Double Slap',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 15,
    accuracy: const PokemonMoveAccuracy.percent(value: 85),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
    ],
    shortDescription: 'Hits 2-5 times in one turn.',
    description:
        'Hits two to five times. Has a 35% chance to hit two or three times '
        'and a 15% chance to hit four or five times. If one of the hits '
        'breaks the target\'s substitute, it will take damage for the '
        'remaining hits. If the user has the Skill Link Ability, this move '
        'will always hit five times.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:multi_hit',
    ],
  ),
  // Phase B ajoute ici un seul lift bootstrap borné :
  // - des moves très fréquents en début de jeu ;
  // - déjà absorbés honnêtement par le bridge et le moteur ;
  // - choisis pour améliorer la battleability d'un scaffold frais sans ouvrir
  //   de nouvelle mécanique ni reclassifier artificiellement un seam limite.
  _showdownSeedMove(
    id: 'ember',
    showdownMoveId: 'ember',
    name: 'Ember',
    generation: 1,
    type: 'fire',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'brn'),
    ],
    shortDescription: '10% chance to burn the target.',
    description: 'Has a 10% chance to burn the target.',
  ),
  _showdownSeedMove(
    id: 'feint',
    showdownMoveId: 'feint',
    name: 'Feint',
    generation: 4,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 30,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    priority: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.breakProtect(),
    ],
    shortDescription: 'Nullifies Detect, Protect, and Quick/Wide Guard.',
    description: 'If this move is successful, it breaks through the target\'s '
        'Baneful Bunker, Detect, King\'s Shield, Protect, or Spiky Shield for '
        'this turn, allowing other Pokemon to attack the target normally. '
        'If the target\'s side is protected by Crafty Shield, Mat Block, '
        'Quick Guard, or Wide Guard, that protection is also broken for this '
        'turn and other Pokemon may attack the target\'s side normally.',
  ),
  _showdownSeedMove(
    id: 'growl',
    showdownMoveId: 'growl',
    name: 'Growl',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 40,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.sound,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Attack by 1.',
    description: 'Lowers the target\'s Attack by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'hyper_beam',
    showdownMoveId: 'hyperbeam',
    name: 'Hyper Beam',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    basePower: 150,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.recharge,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.requireRecharge(),
    ],
    shortDescription: 'User cannot move next turn.',
    description:
        'If this move is successful, the user must recharge on the following '
        'turn and cannot select a move.',
  ),
  _showdownSeedMove(
    id: 'leer',
    showdownMoveId: 'leer',
    name: 'Leer',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'quick_attack',
    showdownMoveId: 'quickattack',
    name: 'Quick Attack',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    priority: 1,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'Usually goes first.',
    description:
        'Nearly always goes first. No additional effect in the local subset.',
  ),
  _showdownSeedMove(
    id: 'rain_dance',
    showdownMoveId: 'raindance',
    name: 'Rain Dance',
    generation: 2,
    type: 'water',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setWeather(weatherId: 'raindance'),
    ],
    shortDescription: 'For 5 turns, heavy rain powers Water moves.',
    description: 'For 5 turns, the weather becomes Rain Dance. The damage of '
        'Water-type attacks is multiplied by 1.5 and the damage of Fire-type '
        'attacks is multiplied by 0.5 during the effect. Lasts for 8 turns if '
        'the user is holding Damp Rock. Fails if the current weather is Rain '
        'Dance.',
  ),
  _showdownSeedMove(
    id: 'razor_leaf',
    showdownMoveId: 'razorleaf',
    name: 'Razor Leaf',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 55,
    accuracy: const PokemonMoveAccuracy.percent(value: 95),
    pp: 25,
    critRatio: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.slicing,
    ],
    shortDescription: 'High critical hit ratio. Hits adjacent foes.',
    description: 'Has a higher chance for a critical hit.',
  ),
  _showdownSeedMove(
    id: 'scratch',
    showdownMoveId: 'scratch',
    name: 'Scratch',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'swords_dance',
    showdownMoveId: 'swordsdance',
    name: 'Swords Dance',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.dance,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        targetScope: PokemonMoveEffectTargetScope.self,
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: 2,
          ),
        ],
      ),
    ],
    shortDescription: 'Raises the user\'s Attack by 2.',
    description: 'Raises the user\'s Attack by 2 stages.',
  ),
  _showdownSeedMove(
    id: 'swift',
    showdownMoveId: 'swift',
    name: 'Swift',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 60,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'This move does not check accuracy. Hits foes.',
    description: 'This move does not check accuracy.',
  ),
  _showdownSeedMove(
    id: 'tackle',
    showdownMoveId: 'tackle',
    name: 'Tackle',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'tail_whip',
    showdownMoveId: 'tailwhip',
    name: 'Tail Whip',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'thunder_wave',
    showdownMoveId: 'thunderwave',
    name: 'Thunder Wave',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(statusId: 'par'),
    ],
    shortDescription: 'Paralyzes the target.',
    description:
        'Paralyzes the target. This move does not ignore type immunity.',
  ),
  _showdownSeedMove(
    id: 'thunderbolt',
    showdownMoveId: 'thunderbolt',
    name: 'Thunderbolt',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.special,
    basePower: 90,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 15,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'par'),
    ],
    shortDescription: '10% chance to paralyze the target.',
    description: 'Has a 10% chance to paralyze the target.',
  ),
  _showdownSeedMove(
    id: 'u_turn',
    showdownMoveId: 'uturn',
    name: 'U-turn',
    generation: 4,
    type: 'bug',
    category: PokemonMoveCategory.physical,
    basePower: 70,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.selfSwitch(),
    ],
    shortDescription: 'User switches out after damaging the target.',
    description:
        'If this move is successful and the user has not fainted, the user '
        'switches out even if it is trapped and is replaced immediately by a '
        'selected party member. The user does not switch out if there are no '
        'unfainted party members, or if the target switched out using an '
        'Eject Button or through the effect of the Emergency Exit or Wimp Out '
        'Abilities.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:self_switch',
    ],
  ),
  _showdownSeedMove(
    id: 'vine_whip',
    showdownMoveId: 'vinewhip',
    name: 'Vine Whip',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    basePower: 45,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'water_gun',
    showdownMoveId: 'watergun',
    name: 'Water Gun',
    generation: 1,
    type: 'water',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'whirlwind',
    showdownMoveId: 'whirlwind',
    name: 'Whirlwind',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    priority: -6,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.allyAnim,
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.wind,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.forceSwitch(),
    ],
    shortDescription: 'Forces the target to switch to a random ally.',
    description:
        'The target is forced to switch out and be replaced with a random '
        'unfainted ally. Fails if the target is the last unfainted Pokemon in '
        'its party, or if the target used Ingrain previously or has the '
        'Suction Cups Ability.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:force_switch',
    ],
  ),
];

/// Moves volontairement gardés dans le seed malgré un support encore limité.
///
/// On les garde parce qu'ils rendent le seed plus utile qu'une simple liste
/// d'attaques triviales, tout en exposant honnêtement les limites structurelles
/// actuelles via `catalog_only` et `unsupportedReasons`.
final List<PokemonMove> _catalogOnlySeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'stealth_rock',
    showdownMoveId: 'stealthrock',
    name: 'Stealth Rock',
    generation: 4,
    type: 'rock',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mustPressure,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
    ],
    shortDescription: 'Hurts foes on switch-in. Factors Rock weakness.',
    description:
        'Sets up a hazard on the opposing side of the field, damaging each '
        'opposing Pokemon that switches in. Fails if the effect is already '
        'active on the opposing side. Foes lose 1/32, 1/16, 1/8, 1/4, or 1/2 '
        'of their maximum HP, rounded down, based on their weakness to the '
        'Rock type; 0.25x, 0.5x, neutral, 2x, or 4x, respectively. Can be '
        'removed from the opposing side if any Pokemon uses Tidy Up, or if '
        'any opposing Pokemon uses Mortal Spin, Rapid Spin, or Defog '
        'successfully, or is hit by Defog.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSideStart',
      'showdown_callback:condition.onSwitchIn',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'electric_terrain',
    showdownMoveId: 'electricterrain',
    name: 'Electric Terrain',
    generation: 6,
    type: 'electric',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.nonSky,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
    ],
    shortDescription: '5 turns. Grounded: +Electric power, can\'t sleep.',
    description:
        'For 5 turns, the terrain becomes Electric Terrain. During the '
        'effect, the power of Electric-type attacks made by grounded Pokemon '
        'is multiplied by 1.3 and grounded Pokemon cannot fall asleep; Pokemon '
        'already asleep do not wake up. Grounded Pokemon cannot become '
        'affected by Yawn or fall asleep from its effect. Camouflage '
        'transforms the user into an Electric type, Nature Power becomes '
        'Thunderbolt, and Secret Power has a 30% chance to cause paralysis. '
        'Fails if the current terrain is Electric Terrain.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onBasePower',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldStart',
      'showdown_callback:condition.onSetStatus',
      'showdown_callback:condition.onTryAddVolatile',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onBasePower',
      'condition.onFieldEnd',
      'condition.onFieldStart',
      'condition.onSetStatus',
      'condition.onTryAddVolatile',
    ],
  ),
  _showdownSeedMove(
    id: 'healing_wish',
    showdownMoveId: 'healingwish',
    name: 'Healing Wish',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSlotCondition(conditionId: 'healingwish'),
    ],
    shortDescription: 'User faints. Next hurt Pokemon is fully healed.',
    description:
        'The user faints, and if the Pokemon brought out to replace it does '
        'not have full HP or has a non-volatile status condition, its HP is '
        'fully restored along with having any non-volatile status condition '
        'cured. The replacement is sent out at the end of the turn, and the '
        'healing happens before hazards take effect. This effect continues '
        'until a Pokemon that meets either of these conditions switches in at '
        'the user\'s position or gets swapped into the position with Ally '
        'Switch. Fails if the user is the last unfainted Pokemon in its party.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSwap',
      'showdown_callback:condition.onSwitchIn',
      'showdown_callback:onTryHit',
      'unsupported_mechanic:condition',
      'unsupported_mechanic:selfdestruct',
    ],
    showdownHooksPresent: <String>[
      'condition.onSwap',
      'condition.onSwitchIn',
      'onTryHit',
    ],
  ),
  _showdownSeedMove(
    id: 'solar_beam',
    showdownMoveId: 'solarbeam',
    name: 'Solar Beam',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 120,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.charge,
      PokemonMoveFlag.failInstruct,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noSleepTalk,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
    ],
    shortDescription: 'Charges turn 1. Hits turn 2. No charge in sunlight.',
    description:
        'This attack charges on the first turn and executes on the second. '
        'Power is halved if the weather is Primordial Sea, Rain Dance, '
        'Sandstorm, or Snow and the user is not holding Utility Umbrella. If '
        'the user is holding a Power Herb or the weather is Desolate Land or '
        'Sunny Day, the move completes in one turn. If the user is holding '
        'Utility Umbrella and the weather is Desolate Land or Sunny Day, the '
        'move still requires a turn to charge.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:onBasePower',
      'showdown_callback:onTryMove',
      'unsupported_mechanic:weather_charge_shortcuts',
    ],
    showdownHooksPresent: <String>[
      'onBasePower',
      'onTryMove',
    ],
  ),
  _showdownSeedMove(
    id: 'trick_room',
    showdownMoveId: 'trickroom',
    name: 'Trick Room',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    priority: -7,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trickroom'),
    ],
    shortDescription: 'Goes last. For 5 turns, turn order is reversed.',
    description:
        'For 5 turns, the Speed of every Pokemon is recalculated for the '
        'purposes of determining turn order. During the effect, each '
        'Pokemon\'s Speed is considered to be (10000 - its normal Speed), and '
        'if this value is greater than 8191, 8192 is subtracted from it. If '
        'this move is used during the effect, the effect ends.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
    unsupportedReasons: <String>[
      'unsupported_mechanic:turn_order_inversion',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onFieldEnd',
      'condition.onFieldRestart',
      'condition.onFieldStart',
    ],
  ),
];

/// Helper unique pour garder le seed compact sans créer de framework.
///
/// `source` vaut volontairement `showdown` :
/// - il décrit l'origine du contenu métier ;
/// - pas le mode de chargement ;
/// - le bootstrap reste local/offline car ce seed est déjà versionné ici.
PokemonMove _showdownSeedMove({
  required String id,
  required String showdownMoveId,
  required String name,
  required int generation,
  required String type,
  required PokemonMoveCategory category,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int basePower = 0,
  required PokemonMoveAccuracy accuracy,
  int pp = 0,
  bool noPpBoosts = false,
  int priority = 0,
  int critRatio = 1,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  String shortDescription = '',
  String description = '',
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
  List<String> showdownHooksPresent = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: generation,
    source: 'showdown',
    type: type,
    category: category,
    target: target,
    basePower: basePower,
    accuracy: accuracy,
    pp: pp,
    noPpBoosts: noPpBoosts,
    priority: priority,
    critRatio: critRatio,
    flags: flags,
    effects: effects,
    shortDescription: shortDescription,
    description: description,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
    sourceRefs: PokemonMoveSourceRefs(
      showdownMoveId: showdownMoveId,
      showdownHooksPresent: showdownHooksPresent,
    ),
  ).normalized();
}

```

### `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

void main() {
  group('buildEmbeddedPokemonMovesBootstrapSeed', () {
    late Map<String, PokemonMove> movesById;

    setUp(() {
      final catalog = buildEmbeddedPokemonMovesBootstrapSeed();
      movesById = <String, PokemonMove>{
        for (final entry in catalog.entries)
          PokemonMove.fromJson(entry).id: PokemonMove.fromJson(entry),
      };
    });

    test(
        'keeps obviously unsupported switch and multi-hit seams out of supported bootstrap claims',
        () {
      expect(
        movesById['absorb']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['double_slap']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['u_turn']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['whirlwind']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
    });

    test('reflects the real BE8 and BE9 support that now exists locally', () {
      expect(
        movesById['solar_beam']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['trick_room']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredPartial),
      );
    });

    test(
        'adds only simple early-game moves that are already honestly supported by the bridge and battle engine',
        () {
      expect(
        movesById['scratch']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['tail_whip']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['ember']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['water_gun']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['quick_attack']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );

      // On verrouille quelques détails métier pour éviter un faux lift :
      // - `quick_attack` doit rester un vrai move de priorité ;
      // - `tail_whip` doit rester une vraie baisse déterministe de Défense ;
      // - `ember` ne doit pas perdre sa petite chance de brûlure.
      expect(movesById['quick_attack']!.priority, equals(1));
      expect(
        movesById['tail_whip']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (_) => null,
              applyVolatileStatus: (_) => null,
              modifyStats: (effect) => effect.stageChanges.single.stages,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(-1),
      );
      expect(
        movesById['ember']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (effect) => effect.chance,
              applyVolatileStatus: (_) => null,
              modifyStats: (_) => null,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(10),
      );
    });
  });
}

```

### `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Politique partagée de sélection des moves dérivés d'un learnset.
///
/// Cette extraction reste volontairement petite :
/// - elle ne crée pas un nouveau service ;
/// - elle ne change aucune règle métier ;
/// - elle évite simplement qu'un outil d'audit recopie silencieusement la
///   même logique et dérive ensuite du vrai runtime.
///
/// Règle conservée telle quelle :
/// - startingMoves
/// - relearnMoves
/// - levelUp <= niveau courant
/// - unicité préservant l'ordre
/// - 4 derniers moves maximum
List<String> deriveBattleCandidateMoveIdsFromLearnset({
  required RuntimePokemonLearnset learnset,
  required int level,
}) {
  final ordered = <String>[
    ...learnset.startingMoves,
    ...learnset.relearnMoves,
    ...learnset.levelUp
        .where((entry) => entry.level <= level)
        .map((entry) => entry.moveId),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final rawId in ordered) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    unique.add(normalizedId);
  }

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
}

/// Politique partagée de résolution runtime des moves candidats vers battle.
///
/// Cette helper donne à la fois :
/// - le comportement réel de filtrage des moves non bridgeables ;
/// - les hard failures sur moves absents du catalogue ;
/// - les hard failures sur refus bridge non filtrables.
///
/// Elle permet donc à un outil d'audit de mesurer le seam runtime avec la
/// même sévérité que la production, au lieu d'inventer une lecture plus
/// permissive.
List<BattleMoveData> resolveBattleMovesForSeed({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
}) {
  final candidateMoveIds = List<String>.unmodifiable(
    _normalizeUniqueMoveIdsPreserveOrder(moveIds)
        .take(4)
        .toList(growable: false),
  );

  if (candidateMoveIds.isEmpty) {
    throw RuntimeBattleSetupException(
      '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
    );
  }

  final moves = <BattleMoveData>[];
  final rejectedMoves = <_RejectedBridgeMove>[];

  for (final moveId in candidateMoveIds) {
    final move = lookupMove(moveId);
    if (move == null) {
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques ne contient pas "$moveId".',
        debugDetails: 'combatant=$combatantLabel',
      );
    }

    try {
      moves.add(
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        ),
      );
    } on RuntimeBattleSetupException catch (error) {
      final rejectedMove = _RejectedBridgeMove.fromBridgeRejection(
        move: move,
        debugDetails: error.debugDetails,
      );

      if (!rejectedMove.isFilterableDuringSeedAssembly) {
        rethrow;
      }

      rejectedMoves.add(rejectedMove);
    }
  }

  if (moves.isNotEmpty) {
    return List<BattleMoveData>.unmodifiable(moves);
  }

  throw RuntimeBattleSetupException(
    'Le combat ne peut pas démarrer car "$combatantLabel" n’a aucun move bridgeable restant après filtrage.',
    debugDetails: 'combatant=$combatantLabel, '
        'candidateMoveIds=${_formatDebugStringList(candidateMoveIds)}, '
        'rejectedMoveIds=${_formatDebugStringList(rejectedMoves.map((move) => move.moveId).toList(growable: false))}, '
        'rejectedMoves=[${rejectedMoves.map((move) => move.toDebugDetails()).join('; ')}], '
        'filterResult=no_bridgeable_moves_remaining_after_filtering',
  );
}

List<String> _normalizeUniqueMoveIdsPreserveOrder(List<String> rawIds) {
  final out = <String>[];
  final seen = <String>{};
  for (final rawId in rawIds) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    out.add(normalizedId);
  }
  return List<String>.unmodifiable(out);
}

String _formatDebugStringList(List<String> values) {
  if (values.isEmpty) {
    return '[]';
  }
  return '[${values.join(', ')}]';
}

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: combatantLabel,
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );
    final stats = _calculateStatsSnapshot(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      stats: stats,
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: request.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: teamMember.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    return deriveBattleCandidateMoveIdsFromLearnset(
      learnset: learnset,
      level: level,
    );
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    // Le builder garde désormais sa vraie policy de résolution dans une helper
    // partagée, afin que l'outillage Phase B puisse mesurer le même seam sans
    // reconstruire une variante plus permissive.
    return resolveBattleMovesForSeed(
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      lookupMove: movesCatalog.lookup,
      battleMoveBridge: battleMoveBridge,
    );
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  BattleStatsSnapshot _calculateStatsSnapshot({
    required RuntimePokemonSpecies species,
    required int level,
    PokemonStatSpread ivs = const PokemonStatSpread(),
    PokemonStatSpread evs = const PokemonStatSpread(),
  }) {
    // BE2 résout ici les stats battle non-HP pour une raison simple :
    // - `map_runtime` possède encore la donnée projet (species, niveau, IV/EV) ;
    // - `map_battle` ne doit jamais relire le JSON projet brut ;
    // - le handoff battle doit donc déjà recevoir un snapshot typé, prêt à
    //   l'emploi, au lieu d'un bricolage `power + stages`.
    //
    // Politique volontairement bornée :
    // - joueur : on utilise les IV/EV réellement présents dans la sauvegarde ;
    // - sauvage / trainer : IV/EV par défaut à 0, déterministes, documentés ;
    // - nature neutre pour tout le monde dans BE2 ;
    // - `speed` est déjà transportée pour préparer la suite, sans être
    //   consommée pour l'ordre d'action dans ce lot.
    return BattleStatsSnapshot(
      attack: _calculateResolvedNonHpStat(
        baseStat: species.baseAttack,
        level: level,
        iv: ivs.attack,
        ev: evs.attack,
      ),
      defense: _calculateResolvedNonHpStat(
        baseStat: species.baseDefense,
        level: level,
        iv: ivs.defense,
        ev: evs.defense,
      ),
      specialAttack: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialAttack,
        level: level,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
      ),
      specialDefense: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialDefense,
        level: level,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
      ),
      speed: _calculateResolvedNonHpStat(
        baseStat: species.baseSpeed,
        level: level,
        iv: ivs.speed,
        ev: evs.speed,
      ),
    );
  }

  BattleTypingSnapshot _buildBattleTypingSnapshot(
    RuntimePokemonSpecies species,
  ) {
    // BE5 garde la frontière propre :
    // - le loader species lit et valide le typing projet ;
    // - le builder l'adapte vers le petit contrat battle ;
    // - `map_battle` reçoit ensuite une donnée déjà prête à consommer sans
    //   jamais relire le JSON projet brut.
    return BattleTypingSnapshot(
      primaryType: species.typing.first,
      secondaryType: species.typing.length > 1 ? species.typing[1] : null,
    );
  }

  int _calculateResolvedNonHpStat({
    required int baseStat,
    required int level,
    int iv = 0,
    int ev = 0,
  }) {
    final safeBaseStat = _clampInt(baseStat, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(iv, min: 0, max: 31);
    final safeEv = _clampInt(ev, min: 0, max: 252);

    // Formule volontairement Pokémon-like, mais limitée et déterministe :
    // floor(((2 * base + iv + floor(ev / 4)) * level) / 100) + 5
    //
    // BE2 ne gère pas encore les natures. On garde donc ici un multiplicateur
    // neutre implicite de 1.0 au lieu d'introduire une mécanique partielle.
    final resolved =
        (((2 * safeBaseStat + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) + 5;
    return _clampInt(resolved, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Snapshot local d'un move candidat rejeté par le bridge runtime -> battle.
///
/// Ce type reste volontairement petit et local au builder :
/// - il évite d'ouvrir un nouveau contrat public juste pour un message
///   d'erreur de handoff ;
/// - il garde tout le contexte nécessaire pour expliquer pourquoi aucun move
///   bridgeable n'est finalement resté après filtrage ;
/// - il permet d'améliorer le message final sans élargir le bridge lui-même.
final class _RejectedBridgeMove {
  const _RejectedBridgeMove({
    required this.moveId,
    required this.moveName,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    this.bridgeLimit,
  });

  factory _RejectedBridgeMove.fromBridgeRejection({
    required PokemonMove move,
    required String? debugDetails,
  }) {
    return _RejectedBridgeMove(
      moveId: move.id,
      moveName: move.name,
      engineSupportLevel: move.engineSupportLevel.name,
      unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
      bridgeLimit: _extractBridgeLimit(debugDetails),
    );
  }

  final String moveId;
  final String moveName;
  final String engineSupportLevel;
  final List<String> unsupportedReasons;
  final String? bridgeLimit;

  bool get isFilterableDuringSeedAssembly {
    final limit = bridgeLimit;
    if (limit == null) {
      return false;
    }
    if (limit.startsWith('invalid_')) {
      return false;
    }
    if (limit == 'empty_modify_stats_not_supported') {
      return false;
    }
    return true;
  }

  String toDebugDetails() {
    final reasons = unsupportedReasons.isEmpty
        ? '[]'
        : '[${unsupportedReasons.join(', ')}]';
    final limit = bridgeLimit == null ? '' : ', bridgeLimit=$bridgeLimit';
    return 'moveId=$moveId, '
        'moveName=$moveName, '
        'engineSupportLevel=$engineSupportLevel, '
        'unsupportedReasons=$reasons$limit';
  }

  static String? _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.trim().isEmpty) {
      return null;
    }
    final match =
        RegExp(r'bridgeLimit=([^,]+)$').firstMatch(debugDetails.trim());
    return match?.group(1);
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    required this.typing,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData({
    int lineupIndex = 0,
  }) {
    // BE10 garde la frontière propre :
    // - le seed builder ne connaît toujours pas la vraie party runtime ;
    // - mais le mapper peut maintenant lui demander de projeter ce seed vers
    //   un `BattleCombatantData` portant une identité de lineup stable ;
    // - cela évite de dupliquer à la main tout le DTO battle dans le mapper.
    return BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

```

### `packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final config = _CliConfig.fromArgs(args);
  const renderer = _PhaseBScaffoldPackCoverageRenderer(
    bridge: RuntimeBattleMoveBridge(),
  );

  final report = await renderer.render(
    bootstrapJsonPath: config.bootstrapJsonPath,
    baselineBootstrapJsonPath: config.baselineBootstrapJsonPath,
    baselineLabel: config.baselineLabel,
    importPackDirectory: config.importPackDirectory,
    level: config.level,
  );

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(report);
  stdout.writeln(
    'Phase B scaffold pack coverage written to ${outputFile.path}',
  );
}

class _CliConfig {
  const _CliConfig({
    required this.bootstrapJsonPath,
    required this.importPackDirectory,
    required this.outputPath,
    required this.level,
    required this.baselineBootstrapJsonPath,
    required this.baselineLabel,
  });

  final String bootstrapJsonPath;
  final String importPackDirectory;
  final String outputPath;
  final int level;
  final String? baselineBootstrapJsonPath;
  final String? baselineLabel;

  static _CliConfig fromArgs(List<String> args) {
    String readRequiredFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        throw ArgumentError('Missing required flag $name');
      }
      return args[index + 1];
    }

    String? readOptionalFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        return null;
      }
      return args[index + 1];
    }

    final rawLevel = readOptionalFlag('--level');
    final level = rawLevel == null ? 10 : int.parse(rawLevel);
    if (level <= 0) {
      throw ArgumentError('--level must be a positive integer');
    }

    return _CliConfig(
      bootstrapJsonPath: readRequiredFlag('--bootstrap-json'),
      importPackDirectory: readRequiredFlag('--import-pack'),
      outputPath: readRequiredFlag('--output'),
      level: level,
      baselineBootstrapJsonPath: readOptionalFlag('--baseline-bootstrap-json'),
      baselineLabel: readOptionalFlag('--baseline-label'),
    );
  }
}

/// Phase B mesure volontairement autre chose que Phase A.
///
/// Phase A mesurait la vérité produit du golden slice versionné.
/// Phase B doit répondre à une autre question :
/// - est-ce qu'un mini-lift bootstrap améliore réellement la battleability du
///   scaffold/import le plus proche de la réalité versionnée aujourd'hui ;
/// - sans pour autant prendre ce pack d'import pour "la vérité produit".
///
/// On reste donc délibérément sur un audit local et borné :
/// - un bootstrap exporté depuis `map_editor` ;
/// - un pack d'import versionné ;
/// - la même helper de sélection de learnset que le runtime ;
/// - le vrai bridge runtime -> battle.
class _PhaseBScaffoldPackCoverageRenderer {
  const _PhaseBScaffoldPackCoverageRenderer({
    required this.bridge,
  });

  final RuntimeBattleMoveBridge bridge;

  Future<String> render({
    required String bootstrapJsonPath,
    required String? baselineBootstrapJsonPath,
    required String? baselineLabel,
    required String importPackDirectory,
    required int level,
  }) async {
    final currentCatalog = await _loadBootstrapCatalog(bootstrapJsonPath);
    final baselineCatalog = baselineBootstrapJsonPath == null
        ? null
        : await _loadBootstrapCatalog(baselineBootstrapJsonPath);
    final speciesSeeds = await _loadImportPackSpeciesSeeds(
      importPackDirectory: importPackDirectory,
      level: level,
    );

    final currentSpeciesRows = speciesSeeds
        .map((seed) => _evaluateSpeciesSeed(seed, currentCatalog))
        .toList(growable: false)
      ..sort((left, right) => left.speciesId.compareTo(right.speciesId));
    final baselineSpeciesRowsById = baselineCatalog == null
        ? const <String, _SpeciesCoverageRow>{}
        : <String, _SpeciesCoverageRow>{
            for (final seed in speciesSeeds)
              seed.speciesId: _evaluateSpeciesSeed(seed, baselineCatalog),
          };

    final moveRows = _buildMoveRows(
      speciesSeeds: speciesSeeds,
      currentCatalog: currentCatalog,
      baselineCatalog: baselineCatalog,
    )..sort((left, right) => left.moveId.compareTo(right.moveId));

    final currentSummary = _summarizeSpeciesRows(currentSpeciesRows);
    final baselineSummary = baselineCatalog == null
        ? null
        : _summarizeSpeciesRows(
            baselineSpeciesRowsById.values.toList(growable: false),
          );
    final deltaRows = baselineCatalog == null
        ? const <_SpeciesDeltaRow>[]
        : currentSpeciesRows
            .map(
              (row) => _SpeciesDeltaRow(
                speciesId: row.speciesId,
                beforeStatus: baselineSpeciesRowsById[row.speciesId]!.status,
                afterStatus: row.status,
                beforeBuiltMoveIds:
                    baselineSpeciesRowsById[row.speciesId]!.builtMoveIds,
                afterBuiltMoveIds: row.builtMoveIds,
                deltaLabel: _classifyDelta(
                  before: baselineSpeciesRowsById[row.speciesId]!.status,
                  after: row.status,
                ),
              ),
            )
            .toList(growable: false);

    final improvedSpecies =
        deltaRows.where((row) => row.deltaLabel != '').toList(growable: false);

    return <String>[
      '# Phase B Scaffold Pack Coverage',
      '',
      '## Executive Summary',
      '',
      '- Import pack directory: `${p.normalize(importPackDirectory)}`',
      '- Level analyzed with the shared runtime learnset helper: `$level`',
      '- Species seeds analyzed: `${speciesSeeds.length}`',
      if (baselineSummary != null && baselineLabel != null)
        '- Baseline descriptor: `$baselineLabel`',
      if (baselineSummary != null) ...<String>[
        '- Baseline fully covered damage-ready species: '
            '`${baselineSummary.fullDamageReady}`',
        '- Baseline partial damage-ready species: '
            '`${baselineSummary.partialDamageReady}`',
        '- Baseline partial status-only species: '
            '`${baselineSummary.partialStatusOnly}`',
        '- Baseline blocked species: `${baselineSummary.blocked}`',
      ],
      '- Current fully covered damage-ready species: '
          '`${currentSummary.fullDamageReady}`',
      '- Current partial damage-ready species: '
          '`${currentSummary.partialDamageReady}`',
      '- Current partial status-only species: '
          '`${currentSummary.partialStatusOnly}`',
      '- Current blocked species: `${currentSummary.blocked}`',
      if (baselineSummary != null)
        '- Species with a strictly better status after the lift: '
            '`${improvedSpecies.length}`',
      '',
      '## Current Candidate Move Coverage',
      '',
      _markdownTable(
        <String>[
          'moveId',
          'occurrences',
          'species',
          if (baselineSummary != null) 'baselineStatus',
          'currentStatus',
          'currentBridgeFailure',
          'currentUnsupportedReasons',
        ],
        moveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.occurrenceCount.toString(),
                row.speciesIds.join(', '),
                if (baselineSummary != null) row.baselineStatus,
                row.currentStatus,
                row.currentBridgeFailure,
                row.currentUnsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Current Species Coverage',
      '',
      _markdownTable(
        const <String>[
          'speciesId',
          'candidateMoveIds',
          'builtMoveIds',
          'missingMoveIds',
          'rejectedMoveIds',
          'status',
        ],
        currentSpeciesRows
            .map(
              (row) => <String>[
                row.speciesId,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.missingMoveIds.join(', '),
                row.rejectedMoveIds.join(', '),
                row.status,
              ],
            )
            .toList(growable: false),
      ),
      if (baselineSummary != null) ...<String>[
        '',
        '## Baseline vs Current Species Delta',
        '',
        _markdownTable(
          const <String>[
            'speciesId',
            'beforeStatus',
            'afterStatus',
            'beforeBuiltMoveIds',
            'afterBuiltMoveIds',
            'delta',
          ],
          deltaRows
              .map(
                (row) => <String>[
                  row.speciesId,
                  row.beforeStatus,
                  row.afterStatus,
                  row.beforeBuiltMoveIds.join(', '),
                  row.afterBuiltMoveIds.join(', '),
                  row.deltaLabel,
                ],
              )
              .toList(growable: false),
        ),
      ],
      '',
      '## Notes',
      '',
      '- This report is **not** a product truth report like Phase A.',
      '- It measures scaffold/import-pack truth with the real bootstrap and the '
          'real runtime bridge.',
      '- `full_damage_ready` means every candidate move is bridgeable and at '
          'least one built move is offensive.',
      '- `partial_damage_ready` means the seed remains usable in battle, but '
          'some candidate moves are still missing or rejected.',
      '- `partial_status_only` means the seed can still be built, but only '
          'with non-offensive moves after filtering.',
      '- `blocked` means no bridgeable move remains after filtering.',
      '',
    ].join('\n');
  }

  Future<_BootstrapCatalog> _loadBootstrapCatalog(String jsonPath) async {
    final decoded = jsonDecode(await File(jsonPath).readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Bootstrap JSON must decode to an object: $jsonPath');
    }

    final entries = (decoded['entries'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .map(PokemonMove.fromJson)
        .toList(growable: false);

    return _BootstrapCatalog(
      movesById: <String, PokemonMove>{
        for (final move in entries) move.id: move,
      },
    );
  }

  Future<List<_ImportPackSpeciesSeed>> _loadImportPackSpeciesSeeds({
    required String importPackDirectory,
    required int level,
  }) async {
    final learnsetsDirectory = Directory(
      p.join(importPackDirectory, 'learnsets'),
    );
    if (!await learnsetsDirectory.exists()) {
      throw StateError(
        'Import pack learnsets directory not found: ${learnsetsDirectory.path}',
      );
    }

    final files = learnsetsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.json')
        .toList(growable: false)
      ..sort((left, right) => left.path.compareTo(right.path));

    final seeds = <_ImportPackSpeciesSeed>[];
    for (final file in files) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError(
          'Learnset JSON must decode to an object: ${file.path}',
        );
      }

      final learnset = RuntimePokemonLearnset(
        startingMoves:
            ((decoded['startingMoves'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false)),
        relearnMoves:
            ((decoded['relearnMoves'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false)),
        levelUp: ((decoded['levelUp'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .map(
              (entry) => RuntimePokemonLevelUpMove(
                moveId: (entry['moveId'] as String?)?.trim() ?? '',
                level: (entry['level'] as num?)?.toInt() ?? 0,
              ),
            )
            .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
            .toList(growable: false)),
      );

      seeds.add(
        _ImportPackSpeciesSeed(
          speciesId: p.basenameWithoutExtension(file.path),
          candidateMoveIds: deriveBattleCandidateMoveIdsFromLearnset(
            learnset: learnset,
            level: level,
          ),
        ),
      );
    }

    return seeds;
  }

  _SpeciesCoverageRow _evaluateSpeciesSeed(
    _ImportPackSpeciesSeed seed,
    _BootstrapCatalog catalog,
  ) {
    final diagnostics = _diagnoseSpeciesSeed(seed, catalog);

    // Point de vérité important pour Gate B :
    // - le statut global du seed ne vient PAS du diagnostic move par move ;
    // - il vient de la helper runtime partagée qui reproduit exactement la
    //   sévérité réelle du handoff seed -> battle ;
    // - les listes `missingMoveIds` / `rejectedMoveIds` restent des indices
    //   explicatifs, mais elles ne doivent plus piloter un verdict optimiste.
    List<String> builtMoveIds;
    var status = 'blocked';
    try {
      final builtMoves = resolveBattleMovesForSeed(
        moveIds: seed.candidateMoveIds,
        combatantLabel: 'Phase B scaffold audit:${seed.speciesId}',
        lookupMove: catalog.lookup,
        battleMoveBridge: bridge,
      );
      builtMoveIds = builtMoves.map((move) => move.id).toList(growable: false);
      final hasOffensiveMove = builtMoveIds.any((moveId) {
        final move = catalog.lookup(moveId);
        return move != null && _isOffensiveMove(move);
      });
      status = switch ((
        hasOffensiveMove,
        seed.candidateMoveIds.length == builtMoveIds.length
      )) {
        (false, true) => 'full_status_only',
        (false, false) => 'partial_status_only',
        (true, true) => 'full_damage_ready',
        (true, false) => 'partial_damage_ready',
      };
    } on RuntimeBattleSetupException {
      builtMoveIds = const <String>[];
    }

    return _SpeciesCoverageRow(
      speciesId: seed.speciesId,
      candidateMoveIds: seed.candidateMoveIds,
      builtMoveIds: List<String>.unmodifiable(builtMoveIds),
      missingMoveIds: List<String>.unmodifiable(diagnostics.missingMoveIds),
      rejectedMoveIds: List<String>.unmodifiable(diagnostics.rejectedMoveIds),
      status: status,
    );
  }

  _SpeciesDiagnostics _diagnoseSpeciesSeed(
    _ImportPackSpeciesSeed seed,
    _BootstrapCatalog catalog,
  ) {
    final missingMoveIds = <String>[];
    final rejectedMoveIds = <String>[];

    for (final moveId in seed.candidateMoveIds) {
      final move = catalog.lookup(moveId);
      if (move == null) {
        missingMoveIds.add(moveId);
        continue;
      }

      try {
        bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Phase B scaffold diagnostic:${seed.speciesId}',
        );
      } on RuntimeBattleSetupException {
        rejectedMoveIds.add(moveId);
      }
    }

    return _SpeciesDiagnostics(
      missingMoveIds: List<String>.unmodifiable(missingMoveIds),
      rejectedMoveIds: List<String>.unmodifiable(rejectedMoveIds),
    );
  }

  List<_MoveCoverageRow> _buildMoveRows({
    required List<_ImportPackSpeciesSeed> speciesSeeds,
    required _BootstrapCatalog currentCatalog,
    required _BootstrapCatalog? baselineCatalog,
  }) {
    final usagesByMoveId = <String, _MoveUsage>{};
    for (final seed in speciesSeeds) {
      for (final moveId in seed.candidateMoveIds) {
        final current = usagesByMoveId[moveId];
        usagesByMoveId[moveId] = current == null
            ? _MoveUsage(
                moveId: moveId,
                occurrenceCount: 1,
                speciesIds: <String>[seed.speciesId],
              )
            : current.addSpecies(seed.speciesId);
      }
    }

    return usagesByMoveId.values.map((usage) {
      final currentEvaluation = _evaluateMoveStatus(
        usage.moveId,
        currentCatalog,
      );
      final baselineEvaluation = baselineCatalog == null
          ? null
          : _evaluateMoveStatus(
              usage.moveId,
              baselineCatalog,
            );
      return _MoveCoverageRow(
        moveId: usage.moveId,
        occurrenceCount: usage.occurrenceCount,
        speciesIds: usage.speciesIds,
        baselineStatus: baselineEvaluation?.statusLabel ?? '',
        currentStatus: currentEvaluation.statusLabel,
        currentBridgeFailure: currentEvaluation.bridgeFailure,
        currentUnsupportedReasons: currentEvaluation.unsupportedReasons,
      );
    }).toList(growable: false);
  }

  _MoveStatusEvaluation _evaluateMoveStatus(
    String moveId,
    _BootstrapCatalog catalog,
  ) {
    final move = catalog.movesById[moveId];
    if (move == null) {
      return const _MoveStatusEvaluation(
        statusLabel: 'missing_from_bootstrap',
        bridgeFailure: '',
        unsupportedReasons: '',
      );
    }

    try {
      bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Phase B scaffold audit move:$moveId',
      );
      return const _MoveStatusEvaluation(
        statusLabel: 'bridgeable',
        bridgeFailure: '',
        unsupportedReasons: '',
      );
    } on RuntimeBattleSetupException catch (error) {
      return _MoveStatusEvaluation(
        statusLabel: 'present_not_bridgeable',
        bridgeFailure: _extractBridgeFailure(error),
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    }
  }

  _CoverageSummary _summarizeSpeciesRows(List<_SpeciesCoverageRow> rows) {
    var fullDamageReady = 0;
    var partialDamageReady = 0;
    var partialStatusOnly = 0;
    var blocked = 0;

    for (final row in rows) {
      switch (row.status) {
        case 'full_damage_ready':
          fullDamageReady++;
        case 'partial_damage_ready':
          partialDamageReady++;
        case 'full_status_only':
        case 'partial_status_only':
          partialStatusOnly++;
        case 'blocked':
          blocked++;
      }
    }

    return _CoverageSummary(
      fullDamageReady: fullDamageReady,
      partialDamageReady: partialDamageReady,
      partialStatusOnly: partialStatusOnly,
      blocked: blocked,
    );
  }

  bool _isOffensiveMove(PokemonMove move) {
    // Garde-fou volontairement simple :
    // - pour ce lot, on cherche surtout à distinguer un vrai move offensif
    //   simple d'un set réduit à des moves de statut ;
    // - on ne tente pas ici de reproduire toute la sémantique Showdown ;
    // - dans le scope Phase B choisi, la catégorie du move suffit.
    return move.category != PokemonMoveCategory.status;
  }

  String _classifyDelta({
    required String before,
    required String after,
  }) {
    if (before == after) {
      return '';
    }
    return switch ((before, after)) {
      ('blocked', 'partial_status_only') => 'unblocked_status_only',
      ('blocked', 'partial_damage_ready') => 'unblocked_damage_ready',
      ('blocked', 'full_damage_ready') => 'fully_unblocked_damage_ready',
      ('partial_status_only', 'partial_damage_ready') =>
        'status_only_to_damage_ready',
      ('partial_status_only', 'full_damage_ready') =>
        'status_only_to_full_damage_ready',
      ('partial_damage_ready', 'full_damage_ready') =>
        'partial_to_full_damage_ready',
      (_, 'full_damage_ready') => 'improved_to_full_damage_ready',
      (_, 'partial_damage_ready') => 'improved_to_damage_ready',
      _ => 'changed',
    };
  }
}

class _BootstrapCatalog {
  const _BootstrapCatalog({
    required this.movesById,
  });

  final Map<String, PokemonMove> movesById;

  PokemonMove? lookup(String moveId) => movesById[moveId.trim()];
}

class _ImportPackSpeciesSeed {
  const _ImportPackSpeciesSeed({
    required this.speciesId,
    required this.candidateMoveIds,
  });

  final String speciesId;
  final List<String> candidateMoveIds;
}

class _SpeciesCoverageRow {
  const _SpeciesCoverageRow({
    required this.speciesId,
    required this.candidateMoveIds,
    required this.builtMoveIds,
    required this.missingMoveIds,
    required this.rejectedMoveIds,
    required this.status,
  });

  final String speciesId;
  final List<String> candidateMoveIds;
  final List<String> builtMoveIds;
  final List<String> missingMoveIds;
  final List<String> rejectedMoveIds;
  final String status;
}

class _SpeciesDiagnostics {
  const _SpeciesDiagnostics({
    required this.missingMoveIds,
    required this.rejectedMoveIds,
  });

  final List<String> missingMoveIds;
  final List<String> rejectedMoveIds;
}

class _SpeciesDeltaRow {
  const _SpeciesDeltaRow({
    required this.speciesId,
    required this.beforeStatus,
    required this.afterStatus,
    required this.beforeBuiltMoveIds,
    required this.afterBuiltMoveIds,
    required this.deltaLabel,
  });

  final String speciesId;
  final String beforeStatus;
  final String afterStatus;
  final List<String> beforeBuiltMoveIds;
  final List<String> afterBuiltMoveIds;
  final String deltaLabel;
}

class _CoverageSummary {
  const _CoverageSummary({
    required this.fullDamageReady,
    required this.partialDamageReady,
    required this.partialStatusOnly,
    required this.blocked,
  });

  final int fullDamageReady;
  final int partialDamageReady;
  final int partialStatusOnly;
  final int blocked;
}

class _MoveUsage {
  const _MoveUsage({
    required this.moveId,
    required this.occurrenceCount,
    required this.speciesIds,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> speciesIds;

  _MoveUsage addSpecies(String speciesId) {
    if (speciesIds.contains(speciesId)) {
      return this;
    }
    return _MoveUsage(
      moveId: moveId,
      occurrenceCount: occurrenceCount + 1,
      speciesIds: <String>[...speciesIds, speciesId],
    );
  }
}

class _MoveCoverageRow {
  const _MoveCoverageRow({
    required this.moveId,
    required this.occurrenceCount,
    required this.speciesIds,
    required this.baselineStatus,
    required this.currentStatus,
    required this.currentBridgeFailure,
    required this.currentUnsupportedReasons,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> speciesIds;
  final String baselineStatus;
  final String currentStatus;
  final String currentBridgeFailure;
  final String currentUnsupportedReasons;
}

class _MoveStatusEvaluation {
  const _MoveStatusEvaluation({
    required this.statusLabel,
    required this.bridgeFailure,
    required this.unsupportedReasons,
  });

  final String statusLabel;
  final String bridgeFailure;
  final String unsupportedReasons;
}

String _extractBridgeFailure(RuntimeBattleSetupException error) {
  final debugDetails = error.debugDetails?.trim() ?? '';
  if (debugDetails.isEmpty) {
    return '';
  }

  final bridgeLimitMatch = RegExp(r'bridgeLimit=([^,]+)').firstMatch(
    debugDetails,
  );
  if (bridgeLimitMatch != null) {
    return bridgeLimitMatch.group(1) ?? '';
  }

  return debugDetails;
}

String _markdownTable(List<String> headers, List<List<String>> rows) {
  final buffer = StringBuffer()
    ..writeln('| ${headers.join(' | ')} |')
    ..writeln('| ${List<String>.filled(headers.length, '---').join(' | ')} |');
  for (final row in rows) {
    buffer.writeln('| ${row.join(' | ')} |');
  }
  return buffer.toString().trimRight();
}

```

### `scripts/generate_phase_b_scaffold_pack_coverage.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Wrapper Phase B volontairement simple :
# - exporte d'abord le bootstrap embarqué courant depuis map_editor ;
# - mesure ensuite le pack d'import versionné avec le vrai bridge runtime ;
# - accepte en option un bootstrap baseline capturé avant le lift pour
#   documenter honnêtement le delta de ce run ;
# - écrit enfin le report markdown sous reports/.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_BOOTSTRAP_JSON="$(mktemp)"
trap 'rm -f "$CURRENT_BOOTSTRAP_JSON"' EXIT
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  echo "Flutter binary not found on PATH. Set FLUTTER_BIN if needed." >&2
  exit 1
fi

BASELINE_ARGS=()
if [[ $# -ge 1 ]]; then
  BASELINE_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  if command -v shasum >/dev/null 2>&1; then
    BASELINE_SHA="$(shasum -a 256 "$BASELINE_PATH" | awk "{print \$1}")"
  else
    BASELINE_SHA="$(sha256sum "$BASELINE_PATH" | awk "{print \$1}")"
  fi
  BASELINE_ARGS+=(
    --baseline-bootstrap-json "$BASELINE_PATH"
    --baseline-label "$BASELINE_PATH (sha256:$BASELINE_SHA)"
  )
fi

(
  cd "$REPO_ROOT/packages/map_editor"
  "$FLUTTER_BIN" pub run tool/export_embedded_pokemon_moves_bootstrap.dart > "$CURRENT_BOOTSTRAP_JSON"
)

(
  cd "$REPO_ROOT/packages/map_runtime"
  "$FLUTTER_BIN" pub run tool/phase_b_scaffold_pack_coverage.dart \
    --bootstrap-json "$CURRENT_BOOTSTRAP_JSON" \
    "${BASELINE_ARGS[@]}" \
    --import-pack "$REPO_ROOT/packages/map_editor/test/fixtures/manual_pokemon_import_pack_10" \
    --level 10 \
    --output "$REPO_ROOT/reports/phase-b-scaffold-pack-coverage.md"
)

echo "Coverage report written to $REPO_ROOT/reports/phase-b-scaffold-pack-coverage.md"

```

### `reports/phase-b-scaffold-pack-coverage.md`

```markdown
# Phase B Scaffold Pack Coverage

## Executive Summary

- Import pack directory: `/Users/karim/Project/pokemonProject/packages/map_editor/test/fixtures/manual_pokemon_import_pack_10`
- Level analyzed with the shared runtime learnset helper: `10`
- Species seeds analyzed: `10`
- Baseline descriptor: `/tmp/phase_b_bootstrap_before.json (sha256:adceb058c1ed6cc344b34f3ba389dafdb2a7bb6e14e3294e5c23605a7d9ea3ab)`
- Baseline fully covered damage-ready species: `1`
- Baseline partial damage-ready species: `0`
- Baseline partial status-only species: `0`
- Baseline blocked species: `9`
- Current fully covered damage-ready species: `4`
- Current partial damage-ready species: `0`
- Current partial status-only species: `0`
- Current blocked species: `6`
- Species with a strictly better status after the lift: `3`

## Current Candidate Move Coverage

| moveId | occurrences | species | baselineStatus | currentStatus | currentBridgeFailure | currentUnsupportedReasons |
| --- | --- | --- | --- | --- | --- | --- |
| bite | 1 | meowth | missing_from_bootstrap | missing_from_bootstrap |  |  |
| confuse_ray | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| counter | 1 | riolu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| defense_curl | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| disable | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| ember | 1 | charmander | missing_from_bootstrap | bridgeable |  |  |
| endure | 1 | riolu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| growl | 4 | bulbasaur, charmander, meowth, pikachu | bridgeable | bridgeable |  |  |
| hypnosis | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| leer | 1 | dratini | bridgeable | bridgeable |  |  |
| lick | 1 | gastly | missing_from_bootstrap | missing_from_bootstrap |  |  |
| pound | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| quick_attack | 3 | eevee, pikachu, riolu | missing_from_bootstrap | bridgeable |  |  |
| scratch | 2 | charmander, meowth | missing_from_bootstrap | bridgeable |  |  |
| sing | 1 | jigglypuff | missing_from_bootstrap | missing_from_bootstrap |  |  |
| tackle | 3 | bulbasaur, eevee, squirtle | bridgeable | bridgeable |  |  |
| tail_whip | 2 | eevee, squirtle | missing_from_bootstrap | bridgeable |  |  |
| thundershock | 1 | pikachu | missing_from_bootstrap | missing_from_bootstrap |  |  |
| twister | 1 | dratini | missing_from_bootstrap | missing_from_bootstrap |  |  |
| vine_whip | 1 | bulbasaur | bridgeable | bridgeable |  |  |
| water_gun | 1 | squirtle | missing_from_bootstrap | bridgeable |  |  |
| wrap | 1 | dratini | missing_from_bootstrap | missing_from_bootstrap |  |  |

## Current Species Coverage

| speciesId | candidateMoveIds | builtMoveIds | missingMoveIds | rejectedMoveIds | status |
| --- | --- | --- | --- | --- | --- |
| bulbasaur | tackle, growl, vine_whip | tackle, growl, vine_whip |  |  | full_damage_ready |
| charmander | scratch, growl, ember | scratch, growl, ember |  |  | full_damage_ready |
| dratini | wrap, leer, twister |  | wrap, twister |  | blocked |
| eevee | tackle, tail_whip, quick_attack | tackle, tail_whip, quick_attack |  |  | full_damage_ready |
| gastly | lick, confuse_ray, hypnosis |  | lick, confuse_ray, hypnosis |  | blocked |
| jigglypuff | sing, pound, defense_curl, disable |  | sing, pound, defense_curl, disable |  | blocked |
| meowth | scratch, growl, bite |  | bite |  | blocked |
| pikachu | thundershock, growl, quick_attack |  | thundershock |  | blocked |
| riolu | quick_attack, endure, counter |  | endure, counter |  | blocked |
| squirtle | tackle, tail_whip, water_gun | tackle, tail_whip, water_gun |  |  | full_damage_ready |

## Baseline vs Current Species Delta

| speciesId | beforeStatus | afterStatus | beforeBuiltMoveIds | afterBuiltMoveIds | delta |
| --- | --- | --- | --- | --- | --- |
| bulbasaur | full_damage_ready | full_damage_ready | tackle, growl, vine_whip | tackle, growl, vine_whip |  |
| charmander | blocked | full_damage_ready |  | scratch, growl, ember | fully_unblocked_damage_ready |
| dratini | blocked | blocked |  |  |  |
| eevee | blocked | full_damage_ready |  | tackle, tail_whip, quick_attack | fully_unblocked_damage_ready |
| gastly | blocked | blocked |  |  |  |
| jigglypuff | blocked | blocked |  |  |  |
| meowth | blocked | blocked |  |  |  |
| pikachu | blocked | blocked |  |  |  |
| riolu | blocked | blocked |  |  |  |
| squirtle | blocked | full_damage_ready |  | tackle, tail_whip, water_gun | fully_unblocked_damage_ready |

## Notes

- This report is **not** a product truth report like Phase A.
- It measures scaffold/import-pack truth with the real bootstrap and the real runtime bridge.
- `full_damage_ready` means every candidate move is bridgeable and at least one built move is offensive.
- `partial_damage_ready` means the seed remains usable in battle, but some candidate moves are still missing or rejected.
- `partial_status_only` means the seed can still be built, but only with non-offensive moves after filtering.
- `blocked` means no bridgeable move remains after filtering.

```
