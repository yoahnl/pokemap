# PSDK Battle Migration - Lot 10 CLI Scenarios

## Nom exact du lot

Lot 10 - Scenarios CLI de comportement de combat pour sub-agents.

## Resume executif

Le CLI `psdk_battle_cli.dart` n'est plus seulement un smoke fixture unique.
Il peut maintenant lancer des scenarios courts et deterministes pour verifier
des comportements de combat precis sans Flutter, sans runtime et sans test
unitaire a ecrire a la main.

Objectif direct : permettre au thread principal et aux sub-agents d'appeler le
CLI comme sonde stable pendant les prochains lots.

## Fichiers modifies

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Ajouts :

- option `--scenario`;
- parse et validation des scenarios;
- configuration par scenario;
- execution jusqu'a KO pour le scenario par defaut;
- execution sur un tour pour les scenarios de comportement;
- outcome `ongoing` quand le scenario une-tour ne finit pas le combat.

Scenarios supportes :

- `default` / `smoke` : ancien combat smoke, comportement inchangé;
- `immunity` : Electric vs Ground, attend `move_immune` sans animation/damage;
- `miss` : move accuracy faible avec seed deterministe de miss;
- `super_effective` / `super-effective` : Fire STAB vs Grass, degat `24`;
- `critical` : move avec `criticalRate: 4`, critique garanti.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Ajouts :

- test du scenario `immunity`;
- test du scenario `miss`;
- test de rejet d'un scenario inconnu.

## Logique mise en place

### Parse CLI

Syntaxe :

```bash
dart run bin/psdk_battle_cli.dart --scenario immunity --format json
```

Ordre des options libre :

```bash
dart run bin/psdk_battle_cli.dart --format json --scenario miss
```

Erreurs explicites :

- `Missing value for --scenario.`
- `Unknown --scenario value "...". Expected default, immunity, miss, super_effective, or critical.`

### Execution

Le scenario par defaut garde le comportement historique :

- boucle jusqu'a outcome;
- garde-fou `20` tours;
- JSON identique au lot precedent.

Les scenarios de comportement :

- executent exactement `1` tour;
- retournent `outcome: "ongoing"` si aucun KO;
- conservent `playerHp`, `opponentHp`, `turns`, `events`.

L'adversaire utilise un move `opponent_wait` avec `accuracy: 1` pour rater de
maniere deterministe et ne pas polluer les scenarios avec une animation ou des
degats adverses.

## Tests crees / modifies

### `prints an immunity scenario for behavior-focused subagents`

Verifie :

- exit code `0`;
- `outcome == "ongoing"`;
- `turns == 1`;
- `opponentHp == 100`;
- event `move_immune`;
- pas d'`animation_cue`;
- pas de `damage`.

### `prints a miss scenario without animation or damage`

Verifie :

- exit code `0`;
- `outcome == "ongoing"`;
- `turns == 1`;
- event `miss`;
- pas d'`animation_cue`;
- pas de `damage`.

### `rejects an unknown scenario with a non-zero exit code`

Verifie :

- exit code `64`;
- message contenant `Unknown --scenario value`.

## Commandes de test lancees

Depuis `packages/map_battle` :

```bash
dart test test/psdk_battle_cli_test.dart
```

Resultat exact :

```text
00:00 +5: All tests passed!
```

```bash
dart test test/psdk_battle_cli_test.dart test/psdk_type_damage_test.dart test/psdk_move_procedure_test.dart test/psdk_rng_streams_test.dart test/psdk_engine_smoke_test.dart
```

Resultat exact :

```text
00:00 +30: All tests passed!
```

```bash
dart test
```

Resultat exact :

```text
00:00 +274: All tests passed!
```

## Commandes d'analyse

Depuis `packages/map_battle` :

```bash
dart analyze
```

Resultat exact :

```text
Analyzing map_battle...
No issues found!
```

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Resultat exact :

```text
Generated: /tmp/pokemon_project_psdk_battle_cli
```

Depuis la racine :

```bash
git diff --check
```

Resultat exact :

```text
<no output>
```

## Smoke CLI

### Scenario par defaut

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Resultat exact :

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

### Immunity

```bash
dart run bin/psdk_battle_cli.dart --scenario immunity --format json
```

Resultat observe :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":100,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"thunder_shock","moveName":"thunder_shock"},{"kind":"move_immune","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"thunder_shock"},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

### Miss

```bash
dart run bin/psdk_battle_cli.dart --scenario miss --format json
```

Resultat observe :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":100,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"tackle","moveName":"tackle"},{"kind":"miss","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"tackle"},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

### Super effective

```bash
dart run bin/psdk_battle_cli.dart --scenario super_effective --format json
```

Resultat observe :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":76,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"ember","moveName":"ember"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"ember"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"ember","damage":24,"remainingHp":76},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

### Critical

```bash
dart run bin/psdk_battle_cli.dart --scenario critical --format json
```

Resultat observe :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":81,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"karate_chop","moveName":"karate_chop"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"karate_chop"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"karate_chop","damage":19,"remainingHp":81},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

## Limites conservees

- Pas encore de scenario CLI `no_target`, car le moteur singles standard a
  toujours un adversaire actif; le cas reste couvert par
  `psdk_move_procedure_test.dart`.
- Les scenarios sont hardcodes dans le CLI. Un prochain lot pourra lire des
  fixtures JSON si besoin.
- Les scenarios une-tour retournent `ongoing`, ce qui est volontaire pour tester
  un comportement local sans forcer un KO.

## Prochaines etapes proposees

- Lot 11 : effets secondaires clean (`stageMods`, status riders offensifs,
  chances d'effet) et scenarios CLI correspondants.
- Ajouter un mode CLI de chargement fixture quand les premiers packs Studio
  seront branches au moteur.
