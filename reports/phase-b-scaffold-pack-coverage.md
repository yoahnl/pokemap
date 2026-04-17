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
