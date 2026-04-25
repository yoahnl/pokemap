# Lot 24 - PSDK Field State / Terrain-Readable Moves

## Resume executif

Ce lot ajoute le premier contrat de champ global propre au lane PSDK Dart de
`packages/map_battle`.

Le scope final est volontairement plus petit que "weather/terrain complet" :

- stocker un terrain actif et une meteo active dans `PsdkBattleState`;
- propager ce champ depuis `PsdkBattleSetup` et `BattleEngineSetup`;
- exposer le champ via le barrel PSDK;
- porter les premiers moves qui lisent le terrain sans avoir besoin de setter,
  decrementer ou expirer les effets de champ;
- ajouter un scenario CLI qui permet aux sub-agents de tester rapidement un move
  dependant du terrain.

Moves ajoutes :

- `s_misty_explosion` -> `SelfDestructMoveBehavior.mistyExplosion`, `partial`;
- `s_terrain_boosting` -> `TerrainPowerMoveBehavior.terrainBoosting`, `ported`.

Le lot ne porte pas encore `s_terrain`, `s_weather`, `s_weather_ball`,
`s_rising_voltage`, `s_expanding_force`, `s_grassy_glide` ou
`s_terrain_pulse`.

## Pourquoi ce scope

L'audit PSDK montre deux familles tres differentes :

- des moves qui lisent seulement le terrain actif pour modifier leur puissance;
- des moves/effects qui creent, expirent, previennent ou transforment le champ.

Porter `s_terrain` et `s_weather` maintenant aurait force a inventer trop de
contrats absents :

- ciblage du champ et side effects de fin de tour;
- decrementation des durees;
- extension de duree par item;
- prevention/remplacement de terrain et meteo;
- grounded/airborne state;
- callbacks d'effets terrain/meteo.

Le lot applique donc une tranche plus sure : on cree le contrat observable, puis
on porte uniquement les comportements qui peuvent etre prouves dessus.

## Sources PSDK auditees

- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainDamageMoves.rb`
  - `MistyExplosion` herite de `SelfDestruct`.
  - bonus de puissance quand le terrain Misty est actif.
  - `RisingVoltage`, `ExpandingForce`, `GrassyGlide` demandent des notions
    supplementaires et restent `missing`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainBoosting.rb`
  - `TerrainBoosting` applique un bonus si le move courant est mappe au terrain
    actif.
  - la table PSDK actuelle mappe `psyblade` vers `electric_terrain`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainMove.rb`
  - pose un effet de terrain et depend de la duree, de l'item, des preventions
    et des hooks terrain.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 WeatherMove.rb`
  - pose une meteo et depend des durees, preventions, items et callbacks meteo.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainPulse.rb`
  - change type et puissance selon le terrain.
- `pokemonsdk-development/scripts/5 Battle/06 Effects/07 Field Terrain Effects/001 FieldTerrainBase.rb`
  - definit les callbacks terrain PSDK qui seront necessaires dans un lot
    futur.

## Fichiers modifies / crees

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_field.dart`

Statut : cree.

Contenu principal :

- `PsdkBattleFieldState`
  - `terrain`;
  - `weather`;
  - `hasTerrain`;
  - `hasWeather`;
  - `isTerrainActive`;
  - `isWeatherActive`;
  - `withTerrain`;
  - `withWeather`.
- `PsdkBattleTerrainState`
  - `id`;
  - `remainingTurns`.
- `PsdkBattleWeatherState`
  - `id`;
  - `remainingTurns`.
- `PsdkBattleTerrainId`
  - `electricTerrain`;
  - `grassyTerrain`;
  - `mistyTerrain`;
  - `psychicTerrain`.
- `PsdkBattleWeatherId`
  - `rain`;
  - `sunny`;
  - `sandstorm`;
  - `hail`;
  - `snow`;
  - `fog`;
  - `hardrain`;
  - `hardsun`;
  - `strongWinds`.

Pourquoi :

- garder le champ PSDK separe de l'ancien `BattleFieldState` Showdown-era;
- offrir un contrat minimal, immutable et testable;
- permettre aux moves PSDK de lire un terrain/meteo sans coupler le clean lane
  aux anciennes structures.

Limite volontaire :

- `copyWith` ne sert pas encore a supprimer terrain/meteo;
- aucun tick de duree;
- aucun event de pose/expiration;
- aucune mutation automatique de fin de tour.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_setup.dart`

Statut : modifie.

Changement :

- ajout de `field = const PsdkBattleFieldState()` dans
  `PsdkBattleSetup.singles`;
- stockage de `final PsdkBattleFieldState field`.

Pourquoi :

- permettre aux tests, au CLI et aux futurs adapters de semer un champ
  deterministe au depart du combat.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`

Statut : modifie.

Changements :

- ajout de `field` dans le constructeur;
- `PsdkBattleState.fromSetup` copie `setup.field`;
- `copyWith` accepte `PsdkBattleFieldState? field`.

Pourquoi :

- rendre le champ observable pendant la resolution des moves;
- conserver le champ lors des `replaceBattler` / `updateBattler`;
- eviter de propager un etat global par un singleton ou un service cache.

### `packages/map_battle/lib/src/domain/battle/battle_setup.dart`

Statut : modifie.

Changement :

- `BattleEngineSetup.singles` accepte maintenant
  `PsdkBattleFieldState field = const PsdkBattleFieldState()`.

Pourquoi :

- garder la facade clean architecture au meme niveau que le setup PSDK interne;
- eviter que les tests/consommateurs aient besoin de construire un
  `PsdkBattleSetup` brut juste pour injecter un terrain.

### `packages/map_battle/lib/src/psdk/psdk_battle.dart`

Statut : modifie.

Changement :

- export de `domain/psdk_battle_field.dart`.

Pourquoi :

- rendre `PsdkBattleFieldState`, `PsdkBattleTerrainId` et
  `PsdkBattleWeatherId` accessibles via `package:map_battle/map_battle.dart`.

### `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`

Statut : modifie.

Changements :

- ajout de `_SelfDestructKind.mistyExplosion`;
- ajout du constructeur `SelfDestructMoveBehavior.mistyExplosion()`;
- `battleEngineMethod = 's_misty_explosion'`;
- resolution de puissance :
  - puissance normale hors Misty Terrain;
  - `(power * 1.5).floor()` sous `PsdkBattleTerrainId.mistyTerrain`.

Pourquoi :

- Pokemon SDK implemente `MistyExplosion` comme une variation de
  `SelfDestruct`;
- le self-KO, l'ordre des degats et les cas miss/immunity/protect etaient deja
  couverts par le lot 23;
- il ne manquait que la lecture du terrain.

Statut manifest :

- `partial`.

Raison du `partial` :

- `Damp` n'existe pas encore dans `PsdkBattleCombatant`;
- grounded/airborne state n'est pas encore modelise;
- les callbacks complets de terrain PSDK ne sont pas encore portes.

### `packages/map_battle/lib/src/domain/move/behaviors/terrain_power_move_behavior.dart`

Statut : cree.

Comportement :

- enregistre `s_terrain_boosting`;
- execute le pipeline Basic standard;
- remplace uniquement la puissance utilisee par le calculateur de degats;
- mappe `psyblade` vers `PsdkBattleTerrainId.electricTerrain`;
- applique `(movePower * 1.5).floor()` si le terrain requis est actif.

Pourquoi :

- c'est le sous-ensemble PSDK exact actuellement portable sans ajouter les
  systemes de pose/expiration de terrain;
- `TerrainBoosting` est aujourd'hui une lecture pure du champ.

Statut manifest :

- `ported`.

Raison :

- la table PSDK actuelle de cette classe est limitee a `psyblade` /
  Electric Terrain, et le comportement Dart couvre cette formule.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Statut : modifie.

Changements :

- import de `terrain_power_move_behavior.dart`;
- ajout de `SelfDestructMoveBehavior.mistyExplosion()`;
- ajout de `TerrainPowerMoveBehavior.terrainBoosting()`.

Pourquoi :

- brancher `s_misty_explosion` et `s_terrain_boosting` dans le registre
  executable PSDK Dart.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Statut : modifie.

Changements :

- sortie texte enrichie avec `terrain` et `weather`;
- sortie JSON enrichie avec `terrain` et `weather`;
- scenario `terrain_boosting` / `terrain-boosting`;
- setup du scenario avec `Electric Terrain`;
- move `psyblade` en `s_terrain_boosting`.

Pourquoi :

- fournir un smoke test CLI exploitable par les sub-agents;
- verifier que le champ traverse setup -> state -> move behavior -> sortie CLI.

Resultat CLI verifie :

```json
{
  "outcome": "ongoing",
  "turns": 1,
  "playerHp": 100,
  "opponentHp": 78,
  "terrain": "electric_terrain",
  "weather": "none"
}
```

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Statut : modifie.

Changements :

- `s_misty_explosion` marque `partial` avec
  `SelfDestructMoveBehavior.mistyExplosion`;
- `s_terrain_boosting` marque `ported` avec
  `TerrainPowerMoveBehavior.terrainBoosting`;
- `s_terrain`, `s_weather`, `s_rising_voltage` restent sans mapping Dart et
  donc `missing`.

Pourquoi :

- maintenir la matrice honnete : le champ est stocke, mais les setters et les
  moves qui demandent des contrats additionnels ne sont pas encore portes.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Statut : regenere.

Changements visibles :

- `s_misty_explosion` -> `partial`;
- `s_terrain_boosting` -> `ported`;
- `s_rising_voltage` -> `missing`;
- `s_terrain` -> `missing`;
- `s_weather` -> `missing`.

### `reports/psdk-move-porting-matrix.md`

Statut : regenere.

Resultat :

- Total registered methods: 330.
- `ported`: 20.
- `partial`: 24.
- `missing`: 286.

### `reports/psdk-effect-porting-matrix.md`

Statut : regenere.

Impact :

- regeneration de coherence apres l'audit terrain/meteo;
- aucun comportement Dart d'effet terrain/meteo n'est encore declare porte.

## Tests crees ou modifies

### `packages/map_battle/test/psdk_battle_field_test.dart`

Statut : cree.

Couvre :

- etat par defaut sans terrain/meteo;
- champ seme depuis `PsdkBattleSetup`;
- immutabilite de `PsdkBattleFieldState`;
- preservation du champ apres un move standard.

### `packages/map_battle/test/psdk_move_families/terrain_power_move_behavior_test.dart`

Statut : cree.

Couvre :

- `s_terrain_boosting` booste Psyblade sous Electric Terrain;
- pas de boost sans terrain;
- pas de boost sous Grassy Terrain.

### `packages/map_battle/test/psdk_move_families/self_destruct_move_behavior_test.dart`

Statut : modifie.

Ajout :

- `s_misty_explosion` inflige plus de degats sous Misty Terrain;
- le self-KO du lanceur reste conserve.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Statut : modifie.

Ajouts :

- test Lot 24 du manifest :
  - `s_misty_explosion` `partial`;
  - `s_terrain_boosting` `ported`;
  - `s_expanding_force`, `s_grassy_glide`, `s_rising_voltage`,
    `s_terrain`, `s_terrain_pulse`, `s_weather`, `s_weather_ball`
    restent `missing`.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Statut : modifie.

Ajout :

- scenario CLI `terrain_boosting`;
- verification JSON :
  - `terrain = electric_terrain`;
  - `weather = none`;
  - `opponentHp = 78`;
  - un seul event `damage` pour `psyblade`.

## Commandes executees

Tests rouges initiaux :

- `dart test test/psdk_battle_field_test.dart`
- `dart test test/psdk_move_families/terrain_power_move_behavior_test.dart`
- `dart test test/psdk_move_families/self_destruct_move_behavior_test.dart --name s_misty_explosion`
- `dart test test/psdk_battle_cli_test.dart --name terrain-boosting`
- `dart test test/psdk_registry_manifest_test.dart --name 'Lot 24|Lot 23 SelfDestruct'`

Regeneration :

- `dart run tool/extract_psdk_move_registry.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-move-porting-matrix.md --manifest lib/src/data/generated/psdk_move_registry_manifest.dart`
- `dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-effect-porting-matrix.md`

Validation finale :

- `dart analyze`
- `dart test`
- `dart run bin/psdk_battle_cli.dart --scenario terrain_boosting --format json`

Resultats :

- `dart analyze` : OK, no issues found.
- `dart test` : OK, 410 tests passed.
- CLI : OK, `psyblade` sous Electric Terrain inflige 22 degats et laisse
  l'adversaire a 78 PV.

## Points de vigilance pour les prochains lots

### Terrain setters

Avant de porter `s_terrain`, il faut definir :

- evenement de pose de terrain;
- remplacement d'un terrain existant;
- prevention si le meme terrain est deja actif;
- duree 5 tours par defaut;
- extension de duree par item;
- decrement de fin de tour;
- expiration et event associe;
- interaction avec grounded/airborne.

### Weather setters

Avant de porter `s_weather`, il faut definir :

- evenement de pose de meteo;
- remplacement meteo;
- weather impossible / weather deja actif;
- duree et duration item;
- hard weather (`hardrain`, `hardsun`, `strongWinds`);
- callbacks de fin de tour.

### Terrain damage moves restants

Les moves suivants restent `missing` parce qu'ils demandent plus que la lecture
simple du terrain :

- `s_rising_voltage` : demande target grounded/terrain;
- `s_expanding_force` : demande terrain + ciblage multi-target;
- `s_grassy_glide` : demande priorite dynamique;
- `s_terrain_pulse` : demande type dynamique et puissance dynamique;
- `s_weather_ball` : demande type dynamique selon meteo.

## Etat git

Le worktree etait deja fortement modifie/non suivi avant ce lot, avec les
tranches precedentes de `packages/map_battle`, `map_core`, `map_editor` et de
nombreux rapports non suivis.

Je n'ai pas revert, nettoye ou reorganise les changements existants.

