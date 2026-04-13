# Phase R1 — Lot 14 — Consommation minimale de Poké Ball + gating capture par le bag

## 1. Résumé exécutif honnête

Le lot 14 a été fermé par un patch strictement local à `map_runtime`.

Le trou métier réel était double :
- `RuntimeBattleSetupMapper` autorisait encore `allowCapture` sans regarder le bag réel du joueur ;
- `applyRuntimeBattleOutcomeToGameState(...)` ajoutait déjà le Pokémon capturé à la party, mais sans consommer de Poké Ball.

Le correctif livré fait exactement ceci :
- `allowCapture` n’est vrai que pour un combat sauvage, avec une party non pleine et au moins une Poké Ball (`itemId == 'poke-ball'`, `categoryId == 'items'`) dans le bag ;
- une capture réussie consomme exactement 1 Poké Ball au moment du write-back runtime ;
- si la quantité tombe à 0, l’entrée disparaît proprement du bag ;
- un `captured` forcé sans Poké Ball, hors combat sauvage, ou avec une party pleine continue d’échouer explicitement ;
- la persistance save/load reste cohérente pour la party, le bag et la progression `caught/seen`.

Je n’ai pas touché `map_battle`, `map_core`, `PlayableMapGame`, l’overlay battle, ni le host d’exemple, parce que l’audit réel montrait que le lot 14 se ferme honnêtement sans rouvrir ces couches.

## 2. État initial audité réel

### 2.1. Code déjà en place avant le patch

Audit réel confirmé dans le worktree :
- `packages/map_battle/lib/src/battle_setup.dart` porte déjà `allowCapture`.
- `packages/map_battle/lib/src/battle_session.dart` interdit déjà `Capture` en trainer battle et quand `allowCapture == false`.
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` calculait déjà `allowCapture`, mais seulement avec :
  - `request is WildBattleStartRequest`
  - `gameState.party.members.length < 6`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` ajoutait déjà le Pokémon capturé à la party pour `BattleOutcomeType.captured`, mais sans coût inventaire.
- `packages/map_core/lib/src/models/save_data.dart` contient déjà :
  - `Bag`
  - `BagEntry`
  - `quantity > 0` obligatoire
  - normalisation du bag par fusion déterministe des doublons
- `packages/map_core/lib/src/operations/game_state_persistence.dart` normalise déjà `party -> caught -> seen`.

### 2.2. Constats précis issus de l’audit

1. Le bag existe déjà et est exploitable sans rouvrir `map_core`.
2. L’identifiant canonique de Poké Ball déjà utilisé dans les tests du repo est bien :
   - `itemId == 'poke-ball'`
   - `categoryId == 'items'`
3. `BagEntry.quantity` doit rester strictement positive :
   - une entrée à `0` est invalide ;
   - si la Poké Ball tombe à `0`, il faut supprimer l’entrée.
4. Le moteur battle n’a pas besoin d’être rouvert :
   - il respecte déjà `allowCapture` ;
   - le trou du lot 14 est purement runtime.

## 3. Problèmes confirmés / non confirmés

### 3.1. Confirmés

- Confirmé : `allowCapture` côté runtime ne regardait pas le bag.
- Confirmé : une capture réussie n’avait pas encore de coût Poké Ball réel.
- Confirmé : le repo utilise déjà `poke-ball` / `items` comme id canonique.
- Confirmé : le bag ne peut pas conserver une entrée à quantité `0`.

### 3.2. Non confirmés

- Non confirmé : besoin de modifier `map_battle`.
- Non confirmé : besoin de modifier `map_core`.
- Non confirmé : besoin de modifier `PlayableMapGame`.
- Non confirmé : besoin d’un nouveau service d’inventaire ou de capture.

## 4. Cause racine réelle

La cause racine n’était pas un manque du moteur battle.

Le problème venait du fait que le lot 13 avait fermé la capture sauvage minimale par le couple :
- `BattleSetup.allowCapture`
- `BattleOutcomeType.captured`

mais que le runtime ne branchait pas encore cette capture sur la vraie possession d’une Poké Ball dans `GameState.bag`.

En pratique :
- la décision “peut-on proposer Capture ?” était incomplète dans le mapper runtime ;
- l’écriture “capture réussie” était incomplète dans l’applier runtime.

## 5. Décisions retenues / rejetées

### 5.1. Retenues

- Garder le guard de disponibilité côté runtime via `allowCapture`.
- Ajouter un helper local dans `RuntimeBattleSetupMapper` pour détecter une Poké Ball exploitable dans le bag.
- Ajouter un helper local dans `runtime_battle_outcome_apply.dart` pour consommer exactement une Poké Ball ou lever un `StateError`.
- Réutiliser la normalisation existante `normalizeLoadedGameState(...)` pour laisser `caught/seen` cohérents après ajout à la party.

### 5.2. Rejetées

- Rejeté : toucher `map_battle`.
  - Pas nécessaire : le moteur battle consomme déjà honnêtement `allowCapture`.
- Rejeté : créer un `BagService`, `CaptureService`, `InventoryService` ou équivalent.
  - Hors scope et disproportionné.
- Rejeté : toucher `map_core`.
  - Le bag et la persistance existants suffisent déjà.
- Rejeté : ouvrir un système de type de ball, de formule de capture, ou de bag UI.
  - Hors lot 14.

## 6. Périmètre inclus / exclu

### 6.1. Inclus

- gating runtime de `Capture` par présence réelle d’une Poké Ball ;
- consommation de 1 Poké Ball sur capture réussie ;
- persistance save/load cohérente du bag après capture ;
- tests runtime/save ciblés ;
- commentaires de maintenance ciblés dans le code.

### 6.2. Exclu

- bag UI
- vraie consommation d’inventaire générique
- choix de type de ball
- formule probabiliste de capture
- XP / rewards / level up
- box / PC
- heal / whiteout
- host d’exemple
- `map_editor`
- refonte de combat
- lots 15+

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### 7.1. Modifiés

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`

### 7.2. Créés

- `reports/phase-r1-lot-14-pokeball-consumption-report.md`

### 7.3. Supprimés

- Aucun

## 8. Justification fichier par fichier

### `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

Ajout du vrai gating `allowCapture` basé sur :
- combat sauvage
- party non pleine
- présence d’au moins une Poké Ball dans le bag

Ce fichier est le bon point de décision car c’est là que le runtime possède encore les vraies données save/runtime nécessaires pour autoriser ou non la capture.

### `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

Ajout de la consommation réelle d’une Poké Ball au moment du write-back `captured`.

Ce fichier est le bon point d’écriture car :
- la capture n’est “réelle” qu’au moment où elle modifie effectivement le `GameState` ;
- on peut y défendre explicitement les appels forcés trainer/full/no-ball ;
- on ne pollue pas le moteur battle avec la logique de bag runtime.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Adaptation de la matrice du mapper pour prouver :
- sauvage + Poké Ball + place => `allowCapture == true`
- sauvage + pas de Poké Ball => `allowCapture == false`
- sauvage + party pleine même avec Poké Ball => `allowCapture == false`
- trainer + Poké Ball => `allowCapture == false`

### `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`

Adaptation de la matrice de write-back pour prouver :
- décrément exact d’une Poké Ball ;
- disparition propre de l’entrée si quantité `1 -> 0` ;
- ajout réel du Pokémon à la party ;
- cohérence `caught/seen` ;
- `StateError` sur trainer/full/no-ball.

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Renforcement de la preuve verticale :
- rencontre sauvage réelle ;
- setup runtime réel ;
- `allowCapture` faux sans Poké Ball ;
- capture réelle avec décrément du bag ;
- retour d’état cohérent party/bag/progression.

### `packages/map_runtime/test/file_game_save_repository_test.dart`

Renforcement de la preuve save/load :
- l’état après capture conserve bien la party ;
- le bag décrémenté persiste ;
- `caught/seen` persistent aussi.

## 9. Commandes réellement exécutées

### 9.1. Audit

```bash
find . -name AGENTS.md -print
git status --short
git diff --stat
git ls-files --others --exclude-standard
rg -n "allowCapture|PlayerBattleChoiceCapture|BagEntry|class Bag|poke-ball|caughtSpeciesIds|seenSpeciesIds|captured" packages/map_runtime packages/map_core packages/map_battle -g'*.dart'
sed -n '1,260p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,340p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '220,340p' packages/map_core/test/save_data_test.dart
sed -n '1,280p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,320p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
sed -n '1,340p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '120,240p' packages/map_runtime/test/file_game_save_repository_test.dart
```

### 9.2. Format

```bash
dart format packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_runtime/test/runtime_battle_setup_mapper_test.dart packages/map_runtime/test/runtime_battle_outcome_apply_test.dart packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart packages/map_runtime/test/file_game_save_repository_test.dart
```

Puis, après incident de PATH :

```bash
/opt/homebrew/bin/dart format packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_runtime/test/runtime_battle_setup_mapper_test.dart packages/map_runtime/test/runtime_battle_outcome_apply_test.dart packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart packages/map_runtime/test/file_game_save_repository_test.dart
```

### 9.3. Analyse

```bash
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_outcome_apply.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/file_game_save_repository_test.dart
```

### 9.4. Tests

```bash
/opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/file_game_save_repository_test.dart
```

## 10. Résultats réels de format / analyze / tests

### 10.1. Format

- `dart format ...` : échec réel
  - `zsh:1: command not found: dart`
- `/opt/homebrew/bin/dart format ...` : succès
  - première passe : `Formatted packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - seconde passe : `Formatted 6 files (0 changed) in 0.02 seconds.`

### 10.2. Analyse

Première passe :
- échec sur lints
  - `prefer_const_constructors`
  - puis `unnecessary_const`

Après correction des helpers de test :
- `/opt/homebrew/bin/flutter analyze --no-pub ...` : succès
  - `No issues found! (ran in 2.4s)`

### 10.3. Tests

- `/opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/file_game_save_repository_test.dart`
  - succès
  - `00:02 +33: All tests passed!`

## 11. Incidents rencontrés

1. `dart` n’était pas présent sur le `PATH`.
   - Contournement honnête : utilisation de `/opt/homebrew/bin/dart`.

2. Première passe d’analyse non verte à cause de lints de tests (`prefer_const_constructors`, puis `unnecessary_const`).
   - Corrigé immédiatement avant de continuer.

3. Tentative d’usage de sub-agents pour audit parallèle.
   - Les appels ont échoué à cause d’une limite de threads déjà atteinte dans la session (`agent thread limit reached (max 6)`).
   - Le travail a continué en audit local, sans bloquer.

4. La sortie de `flutter test` contient des logs attendus du save repository.
   - Ce ne sont pas des échecs.

## 12. État git utile

### 12.1. `git status --short`

```text
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/file_game_save_repository_test.dart
 M packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/phase-r1-lot-14-pokeball-consumption-report.md
```

### 12.2. `git diff --stat`

```text
 .../application/runtime_battle_outcome_apply.dart  | 63 ++++++++++++++--
 .../application/runtime_battle_setup_mapper.dart   | 35 ++++++++-
 .../test/file_game_save_repository_test.dart       | 15 ++++
 .../test/runtime_battle_outcome_apply_test.dart    | 83 ++++++++++++++++++++++
 .../test/runtime_battle_setup_mapper_test.dart     | 48 ++++++++++++-
 .../test/wild_battle_end_to_end_flow_test.dart     | 61 +++++++++++++++-
 6 files changed, 293 insertions(+), 12 deletions(-)
```

### 12.3. `git ls-files --others --exclude-standard`

```text
reports/phase-r1-lot-14-pokeball-consumption-report.md
```

## 13. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports précédents
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai fait aucune écriture Git interdite
- [x] je n’ai pas ouvert les lots 15+
- [x] `Capture` n’est proposée qu’en sauvage avec party non pleine ET Poké Ball disponible
- [x] `Capture` n’est jamais proposée en trainer battle
- [x] `Capture` n’est jamais proposée sans Poké Ball
- [x] une capture réussie consomme exactement 1 Poké Ball
- [x] une capture réussie ajoute réellement le Pokémon à la party
- [x] si la quantité de Poké Ball tombe à 0, le bag reste cohérent
- [x] `caught/seen` restent cohérents
- [x] save/load conservent correctement la party, le bag et la progression après capture
- [x] les guards trainer/full/no-ball existent réellement
- [x] je n’ai pas touché des couches non nécessaires sans justification forte
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] mon report est honnête
- [x] mon report contient le contenu complet de tous les fichiers texte touchés

## 14. Conclusion honnête

Le lot 14 est défendable et fermé dans son périmètre strict.

Gameplay final en français simple :
- en combat sauvage, `Capture` n’apparaît que si le joueur a de la place dans sa party et au moins une Poké Ball ;
- si la capture réussit, le Pokémon rejoint réellement la party et une Poké Ball est réellement consommée ;
- si la dernière Poké Ball est utilisée, l’entrée disparaît proprement du bag ;
- en combat trainer, `Capture` reste impossible ;
- si un call site force une capture trainer/full/no-ball, le runtime échoue explicitement avec un `StateError` ;
- rien d’autre n’a été ouvert : pas de bag UI, pas de type de ball, pas de capture ratée probabiliste, pas de PC/boxes, pas de rewards, pas d’XP.

## 15. Annexe — contenu complet de tous les fichiers texte touchés

Note :
- l’annexe inclut le contenu complet des 6 fichiers de code/test modifiés ;
- le présent report est volontairement exclu de sa propre annexe pour éviter une récursion infinie.

### 15.1. `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'battle_start_request.dart';
import 'runtime_map_bundle.dart';

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Exception levée quand le runtime ne peut pas construire un [BattleSetup]
/// honnête à partir des vraies données projet/save.
///
/// Le lot 9 supprime volontairement les placeholders hardcodés. Quand une
/// donnée réelle manque (catalogue moves absent, espèce introuvable, équipe
/// trainer vide, etc.), on préfère donc échouer explicitement plutôt que de
/// relancer un combat avec un Pokémon inventé.
class RuntimeBattleSetupException implements Exception {
  const RuntimeBattleSetupException(
    this.message, {
    this.debugDetails,
  });

  final String message;
  final String? debugDetails;

  @override
  String toString() {
    final details = debugDetails?.trim();
    if (details == null || details.isEmpty) {
      return message;
    }
    return '$message ($details)';
  }
}

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// On garde ici un reader JSON minimal parce que :
/// - la source de vérité des données Pokémon de runtime est le workspace projet ;
/// - `map_runtime` ne doit pas dépendre des modèles internes de `map_editor` ;
/// - le lot 9 ne justifie pas une nouvelle architecture partagée.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper();

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final reader = _RuntimePokemonProjectReader(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final movesCatalog = await reader.readMovesCatalog();

    final playerSeed = await _buildPlayerCombatantSeed(
      reader: reader,
      movesCatalog: movesCatalog,
      gameState: gameState,
      playerPartyIndex: playerPartyIndex,
    );

    final enemySeed = switch (request) {
      WildBattleStartRequest() => await _buildWildCombatantSeed(
          reader: reader,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => await _buildTrainerCombatantSeed(
          reader: reader,
          movesCatalog: movesCatalog,
          manifest: bundle.manifest,
          request: request,
        ),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(),
      enemyPokemon: enemySeed.toBattleCombatantData(),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildPlayerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
    required GameState gameState,
    int? playerPartyIndex,
  }) async {
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final species = await reader.readSpeciesById(playerPokemon.speciesId);
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            reader: reader,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon actif du joueur',
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildWildCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await reader.readSpeciesById(request.speciesId);
    final moveIds = await _deriveLearnsetMoveIds(
      reader: reader,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildTrainerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
    required ProjectManifest manifest,
    required TrainerBattleStartRequest request,
  }) async {
    final trainer = _findTrainer(manifest, request.trainerId);
    if (trainer.team.isEmpty) {
      throw RuntimeBattleSetupException(
        'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
        debugDetails: 'trainerId=${trainer.id}',
      );
    }

    // Le moteur battle MVP reste mono-combattant : on prend donc le premier
    // Pokémon authoré de l’équipe, sans inventer une seconde logique de party.
    final teamMember = trainer.team.first;
    final species = await reader.readSpeciesById(teamMember.speciesId);
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            reader: reader,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "${trainer.name}" (${teamMember.speciesId})',
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  /// Retourne le Pokémon joueur qui doit être injecté dans [BattleSetup].
  ///
  /// Deux cas :
  /// - lot 9 seul : on prend le premier membre jouable ;
  /// - lot 10 : le runtime fournit [playerPartyIndex] pour garantir que le
  ///   combat et le write-back visent exactement le même slot.
  ///
  /// On refuse explicitement un index invalide ou un slot déjà K.O. pour éviter
  /// tout glissement silencieux vers un autre membre de la party.
  PlayerPokemon _selectPlayerPartyMember(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final resolvedIndex =
        playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (resolvedIndex < 0 || resolvedIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, partyLength=${party.members.length}',
      );
    }

    final member = party.members[resolvedIndex];
    if (member.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, speciesId=${member.speciesId}',
      );
    }

    return member;
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required _RuntimePokemonProjectReader reader,
    required _RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await reader.readLearnsetByRef(
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    // On construit la liste de moves disponibles en respectant uniquement les
    // familles déjà exploitées ailleurs dans le projet :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    //
    // Ensuite on garde les 4 derniers IDs uniques. Cela reste simple, lisible
    // et suffisamment proche d’un move set plausible sans inventer un nouveau
    // moteur de sélection.
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required _RuntimeMovesCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final normalizedMoveIds = _normalizeUniqueIdsPreserveOrder(moveIds);
    if (normalizedMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    for (final moveId in normalizedMoveIds.take(4)) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.displayName,
          power: move.power,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
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

    // Formule Pokémon simplifiée mais vraie dans son intention :
    // elle part bien des stats projet/save au lieu d’une constante hardcodée.
    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
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

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}

class _RuntimeBattleCombatantSeed {
  const _RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

/// Reader JSON ultra-ciblé pour le runtime battle handoff.
///
/// Il relit uniquement ce que le lot 9 doit mapper :
/// - espèces (id, base HP, ref learnset)
/// - learnsets
/// - catalogue moves
///
/// Il n’essaie pas de devenir une nouvelle couche Pokémon partagée.
class _RuntimePokemonProjectReader {
  const _RuntimePokemonProjectReader({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

  Future<_RuntimeMovesCatalog> readMovesCatalog() async {
    final relativePath = pokemonConfig.catalogFiles['moves']?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de charger le catalogue local des attaques pour démarrer le combat.',
        debugDetails: 'ProjectPokemonConfig.catalogFiles["moves"] is empty',
      );
    }

    final json = await _readJsonAtProjectRelativePath(
      relativePath,
      label: 'Moves catalog',
    );
    final rawEntries = (json['entries'] as List?) ?? const <Object?>[];
    final entries = <String, _RuntimeMoveCatalogEntry>{};
    for (final rawEntry in rawEntries.whereType<Map>()) {
      final entry = rawEntry.cast<String, dynamic>();
      final id = (entry['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      entries[id] = _RuntimeMoveCatalogEntry(
        id: id,
        displayName: ((entry['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (entry['name'] as String).trim()
            : id,
        power: (entry['power'] as num?)?.toInt() ?? 0,
      );
    }

    if (entries.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Le catalogue local des attaques est vide; combat impossible.',
      );
    }

    return _RuntimeMovesCatalog(entries);
  }

  Future<_RuntimePokemonSpecies> readSpeciesById(String speciesId) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Une espèce Pokémon vide ne peut pas être mappée vers le combat.',
      );
    }

    final speciesDirectory = Directory(
      _resolveProjectPath(
        _normalizeConfiguredRelativePath(
          pokemonConfig.speciesDir,
          fallback: 'data/pokemon/species',
        ),
      ),
    );
    if (!await speciesDirectory.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les espèces Pokémon locales pour démarrer le combat.',
        debugDetails: 'Missing species directory: ${speciesDirectory.path}',
      );
    }

    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is! File ||
          p.extension(entity.path).toLowerCase() != '.json') {
        continue;
      }
      final rawJson = await _readJsonFile(
        entity,
        label: 'Pokemon species file',
      );
      final declaredId = (rawJson['id'] as String?)?.trim() ?? '';
      if (declaredId != normalizedSpeciesId) {
        continue;
      }

      final baseStats =
          (rawJson['baseStats'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{
            'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
          };
      final abilities =
          (rawJson['abilities'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      return _RuntimePokemonSpecies(
        id: declaredId,
        baseHp: (baseStats['hp'] as num?)?.toInt() ?? 1,
        primaryAbilityId: (abilities['primary'] as String?)?.trim() ?? '',
        learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
      );
    }

    throw RuntimeBattleSetupException(
      'Espèce Pokémon introuvable pour démarrer le combat.',
      debugDetails: 'speciesId=$speciesId',
    );
  }

  Future<_RuntimePokemonLearnset> readLearnsetByRef({
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final learnsetId =
        speciesRef.trim().isEmpty ? fallbackSpeciesId : speciesRef;
    final learnsetsDirectory = _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
    final relativePath = p.join(learnsetsDirectory, '$learnsetId.json');
    final json = await _readJsonAtProjectRelativePath(
      relativePath,
      label: 'Pokemon learnset "$learnsetId"',
    );

    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return _RuntimePokemonLearnset(
      startingMoves: ((json['startingMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      relearnMoves: ((json['relearnMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .map(
            (entry) => _RuntimePokemonLevelUpMove(
              moveId: (entry['moveId'] as String?)?.trim() ?? '',
              level: (entry['level'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(relativePath)),
      label: label,
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required String label,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label file not found: ${file.path}',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label parse failed: $error',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawPath, {
    required String fallback,
  }) {
    final trimmed = rawPath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolveProjectPath(String relativeOrAbsolutePath) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

class _RuntimePokemonSpecies {
  const _RuntimePokemonSpecies({
    required this.id,
    required this.baseHp,
    required this.primaryAbilityId,
    required this.learnsetRef,
  });

  final String id;
  final int baseHp;
  final String primaryAbilityId;
  final String learnsetRef;
}

class _RuntimePokemonLearnset {
  const _RuntimePokemonLearnset({
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<_RuntimePokemonLevelUpMove> levelUp;
}

class _RuntimePokemonLevelUpMove {
  const _RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}

class _RuntimeMovesCatalog {
  const _RuntimeMovesCatalog(this.entriesById);

  final Map<String, _RuntimeMoveCatalogEntry> entriesById;

  _RuntimeMoveCatalogEntry? lookup(String moveId) => entriesById[moveId.trim()];
}

class _RuntimeMoveCatalogEntry {
  const _RuntimeMoveCatalogEntry({
    required this.id,
    required this.displayName,
    required this.power,
  });

  final String id;
  final String displayName;
  final int power;
}
```

### 15.2. `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Contexte runtime strictement nécessaire pour faire le write-back lot 10.
///
/// Invariant critique :
/// - [playerPartyIndex] est l'index exact du slot utilisé au moment du handoff
///   vers le combat ;
/// - il ne doit jamais être recalculé à la fin du combat ;
/// - même si le Pokémon actif finit K.O., on doit réécrire les PV sur ce slot
///   précis, pas sur "le premier Pokémon encore vivant".
///
/// Cette structure reste volontairement petite :
/// - la requête d'origine pour savoir si le combat était wild ou trainer ;
/// - l'index du slot joueur utilisé ;
/// - rien de plus.
class RuntimeActiveBattleContext {
  const RuntimeActiveBattleContext({
    required this.request,
    required this.playerPartyIndex,
  });

  final BattleStartRequest request;
  final int playerPartyIndex;
}

/// Applique le résultat final du combat à l'état runtime.
///
/// Ce helper porte le write-back lot 10 dans un seul chemin explicite :
/// 1. écrire les PV finaux du Pokémon joueur sur le slot exact mémorisé ;
/// 2. marquer le trainer battu uniquement en cas de victoire trainer ;
/// 3. laisser intact tout ce qui appartient aux lots 11+.
///
/// Important :
/// - on ne soigne jamais implicitement le joueur ;
/// - on ne téléporte jamais ;
/// - le lot 13/14 ne gère qu'une capture sauvage minimale ;
/// - le lot 14 consomme exactement une Poké Ball au write-back runtime ;
/// - aucun bag UI, aucune récompense, aucun switch n'est ouvert ici ;
/// - on ne recalculera jamais naïvement le slot actif après le combat.
GameState applyRuntimeBattleOutcomeToGameState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
}) {
  final stateWithPlayerHp = _writePlayerCurrentHpBackToExactPartySlot(
    gameState: gameState,
    partyIndex: context.playerPartyIndex,
    currentHp: outcome.finalState.player.currentHp,
  );

  final request = context.request;
  if (outcome.isCaptured) {
    if (request is! WildBattleStartRequest) {
      throw StateError(
        'BattleOutcomeType.captured est interdit hors combat sauvage.',
      );
    }

    // Garde-fou lot 13/14 :
    // le moteur ne doit normalement jamais proposer Capture si la party est
    // pleine ou sans Poké Ball, mais on revalide ici pour qu'un call site forcé
    // ne fasse jamais "disparaître" un Pokémon capturé faute de boîte/PC ou
    // contourne le coût réel de capture introduit par le lot 14.
    if (stateWithPlayerHp.party.members.length >= 6) {
      throw StateError(
        'Impossible d’ajouter un Pokémon capturé : la party du joueur est pleine.',
      );
    }

    final bagAfterConsumption =
        _consumeOnePokeBallOrThrow(stateWithPlayerHp.bag);
    final capturedPokemon = _buildCapturedWildPlayerPokemon(
      enemy: outcome.finalState.enemy,
    );
    final nextMembers = List<PlayerPokemon>.of(
      stateWithPlayerHp.party.members,
      growable: true,
    )..add(capturedPokemon);

    // Lot 12 garantit déjà "party -> caught -> seen". On réutilise donc cette
    // normalisation partagée au lieu d'introduire un deuxième pipeline Pokédex.
    return normalizeLoadedGameState(
      stateWithPlayerHp.copyWith(
        party: stateWithPlayerHp.party.copyWith(members: nextMembers),
        bag: bagAfterConsumption,
      ),
    );
  }

  if (outcome.isVictory && request is TrainerBattleStartRequest) {
    return storyFlagsManager.markTrainerDefeated(
      stateWithPlayerHp,
      request.trainerId,
    );
  }

  return stateWithPlayerHp;
}

const _capturedPokemonDefaultNatureId = 'hardy';
const _capturedPokemonFallbackAbilityId = 'unknown';

/// Construit le Pokémon réellement ajouté à la party après une capture sauvage.
///
/// Le lot 13 reste volontairement minimal :
/// - l'espèce, le niveau, l'ability et les moves viennent du vrai combattant
///   sauvage réellement engagé dans le moteur battle ;
/// - la nature reste un fallback MVP déterministe (`hardy`) faute de véritable
///   génération runtime existante ;
/// - on ne tente pas d'inventer ivs/evs/status/shiny/held item au-delà des
///   defaults du modèle `PlayerPokemon`.
///
/// Invariant important :
/// - une capture réussie ne doit jamais produire un Pokémon owned déjà K.O. ;
/// - si un call site forge un outcome capturé incohérent avec `enemyHp <= 0`,
///   on clamp donc les PV du Pokémon capturé à 1 minimum.
PlayerPokemon _buildCapturedWildPlayerPokemon({
  required BattleCombatant enemy,
}) {
  final normalizedAbilityId = enemy.abilityId.trim().isEmpty
      ? _capturedPokemonFallbackAbilityId
      : enemy.abilityId.trim();
  final normalizedMoveIds = enemy.moves
      .map((move) => move.id.trim())
      .where((moveId) => moveId.isNotEmpty)
      .toSet()
      .toList(growable: false);

  return PlayerPokemon(
    speciesId: enemy.speciesId.trim(),
    natureId: _capturedPokemonDefaultNatureId,
    abilityId: normalizedAbilityId,
    level: enemy.level,
    knownMoveIds: normalizedMoveIds,
    currentHp: enemy.currentHp <= 0 ? 1 : enemy.currentHp,
  );
}

/// Consomme exactement une Poké Ball du bag runtime.
///
/// Pourquoi le coût est appliqué ici :
/// - le moteur battle n'a pas à connaître le bag réel du joueur ;
/// - la capture n'est "réelle" qu'au moment où le runtime accepte d'écrire le
///   résultat dans le `GameState` ;
/// - cela donne une frontière de sécurité unique contre les appels forcés :
///   si aucun `poke-ball` n'existe, le write-back échoue explicitement.
///
/// Le lot 14 reste volontairement minimal :
/// - une seule ressource est concernée (`poke-ball` / `items`) ;
/// - aucune UI d'inventaire n'est ouverte ;
/// - aucun autre item n'est touché ;
/// - aucune entrée à quantité 0 ne doit survivre, car `BagEntry` l'interdit.
Bag _consumeOnePokeBallOrThrow(Bag bag) {
  final nextEntries = <BagEntry>[];
  var didConsumePokeBall = false;

  for (final entry in bag.entries) {
    final isCaptureBall =
        entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
            entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId;
    if (!isCaptureBall || didConsumePokeBall) {
      nextEntries.add(entry);
      continue;
    }

    didConsumePokeBall = true;
    final nextQuantity = entry.quantity - 1;
    if (nextQuantity > 0) {
      nextEntries.add(
        entry.copyWith(quantity: nextQuantity),
      );
    }
  }

  if (!didConsumePokeBall) {
    throw StateError(
      'Impossible d’appliquer BattleOutcomeType.captured sans Poké Ball dans le bag du joueur.',
    );
  }

  return Bag(entries: nextEntries).normalized();
}

/// Réécrit les PV du combattant joueur dans la vraie party runtime.
///
/// Ce helper encode la règle produit la plus importante du lot 10 :
/// l'écriture se fait sur [partyIndex], qui correspond au slot réellement
/// utilisé pendant le handoff lot 9.
///
/// On ne tente surtout pas de retrouver "le Pokémon actif" à partir de l'état
/// post-combat, car ce recalcul pourrait pointer vers un autre membre si le
/// combattant actif vient de tomber à 0 HP.
GameState _writePlayerCurrentHpBackToExactPartySlot({
  required GameState gameState,
  required int partyIndex,
  required int currentHp,
}) {
  final members = gameState.party.members;
  if (partyIndex < 0 || partyIndex >= members.length) {
    throw StateError(
      'RuntimeActiveBattleContext pointe vers un slot party invalide: '
      'index=$partyIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final currentMember = nextMembers[partyIndex];
  nextMembers[partyIndex] = currentMember.copyWith(
    currentHp: currentHp < 0 ? 0 : currentHp,
  );

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}
```

### 15.3. `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'aqua_ring'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'aqua_ring'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'aqua_ring',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45),
        _moveEntry('razor_leaf', 'Razor Leaf', 55),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40),
        _moveEntry('flame_wheel', 'Flame Wheel', 60),
        _moveEntry('water_gun', 'Water Gun', 40),
        _moveEntry('aqua_ring', 'Aqua Ring', 0),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'type': 'normal',
    'category': power == 0 ? 'status' : 'special',
    'power': power == 0 ? null : power,
    'pp': 35,
  };
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}
```

### 15.4. `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  group('applyRuntimeBattleOutcomeToGameState', () {
    test('writes back the exact party slot used for the battle handoff', () {
      const initialState = GameState(
        saveId: 'save-slot',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 40,
              knownMoveIds: <String>['a'],
              currentHp: 91,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_stays_alive',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(91));
      expect(updatedState.party.members[1].currentHp, equals(0));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test('trainer victory writes player hp and marks trainer as defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.victory,
          playerCurrentHp: 14,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(14));
      expect(
        updatedState.storyFlags.activeFlags,
        contains('trainer_defeated:ace_jules'),
      );
    });

    test('trainer defeat writes player hp without marking trainer defeated',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(0));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('runaway writes player hp without marking trainer defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.runaway,
          playerCurrentHp: 11,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(11));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('captured wild battle appends the pokemon and syncs caught/seen', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch', 'leer'],
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(19));
      expect(updatedState.party.members, hasLength(3));

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('wildmon'));
      expect(captured.level, equals(12));
      expect(captured.abilityId, equals('intimidate'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch', 'leer']));
      expect(captured.currentHp, equals(7));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
    });

    test('captured outcome removes the poke-ball entry when quantity reaches 0',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState().copyWith(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
            ],
          ),
        ),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch'],
        ),
      );

      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
    });

    test('captured outcome is rejected for trainer battles', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState(),
          context: RuntimeActiveBattleContext(
            request: _trainerRequest(trainerId: 'ace_jules'),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the party is already full', () {
      final fullPartyState = _baseState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._baseState().party.members,
            const PlayerPokemon(
              speciesId: 'party_2',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_3',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_4',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_5',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
          ],
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: fullPartyState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the bag has no poke-ball', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState().copyWith(
            bag: const Bag(
              entries: <BagEntry>[
                BagEntry(
                  itemId: 'potion',
                  categoryId: 'medicine',
                  quantity: 3,
                ),
              ],
            ),
          ),
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
      ],
    ),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
        PlayerPokemon(
          speciesId: 'benchmon',
          natureId: 'hardy',
          abilityId: 'pressure',
          level: 18,
          knownMoveIds: <String>['leer'],
          currentHp: 17,
        ),
      ],
    ),
  );
}

BattleOutcome _finishedOutcome({
  required BattleOutcomeType type,
  required int playerCurrentHp,
  String enemySpeciesId = 'aquafi',
  int enemyLevel = 18,
  int enemyCurrentHp = 0,
  String enemyAbilityId = 'torrent',
  List<String> enemyMoveIds = const <String>['water_gun'],
}) {
  final finalState = BattleState(
    phase: BattlePhase.finished,
    player: BattleCombatant(
      speciesId: 'sproutle',
      level: 12,
      currentHp: playerCurrentHp,
      maxHp: 32,
      moves: const <BattleMove>[
        BattleMove(id: 'growl', name: 'Growl', power: 0),
      ],
    ),
    enemy: BattleCombatant(
      speciesId: enemySpeciesId,
      level: enemyLevel,
      currentHp: enemyCurrentHp,
      maxHp: 35,
      abilityId: enemyAbilityId,
      moves: enemyMoveIds
          .map(
            (moveId) => BattleMove(
              id: moveId,
              name: moveId,
              power: 10,
            ),
          )
          .toList(growable: false),
    ),
    currentTurn: null,
    outcome: null,
  );

  return BattleOutcome(
    type: type,
    finalState: finalState,
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'wildmon',
    level: 12,
    minLevel: 12,
    maxLevel: 12,
    weight: 30,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest({required String trainerId}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: const GridPos(x: 1, y: 1),
  );
}
```

### 15.5. `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wild battle runtime flow lot 11', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('wild_battle_flow_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('real wild encounter chain resolves to victory and writes back hp',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      // On part bien du vrai chemin overworld minimal :
      // 1. world gameplay avec spawn réel
      // 2. déplacement d'une case vers une zone de rencontre
      // 3. check de rencontre sur la case atteinte
      final initialWorld = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final stepResult = stepGameplayWorld(
        initialWorld,
        const MoveIntent(Direction.east),
      );
      expect(stepResult, isA<Moved>());
      final movedWorld = stepResult.world;
      expect(movedWorld.player.pos, const GridPos(x: 1, y: 0));

      final encounterCheck = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.speciesId, equals('sparkitten'));
      expect(encounter.level, equals(6));

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      expect(request.kind, equals(RuntimeBattleKind.wild));
      expect(request.source, equals(RuntimeBattleSourceKind.encounterZone));

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);
      expect(stateWithSeen.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        stateWithSeen.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );

      final session = createBattleSession(setup);
      final afterTurn1 = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn1.state.isFinished, isFalse);
      final afterTurn2 =
          afterTurn1.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn2.state.outcome, isNotNull);
      expect(afterTurn2.state.outcome!.isVictory, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'wild-request',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field_map',
              playerPos: GridPos(x: 1, y: 0),
              playerFacing: Direction.east,
            ),
            mapId: 'field_map',
            zoneId: 'encounter_grass',
            tableId: 'field_grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'sparkitten',
            level: 6,
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
            playerPos: GridPos(x: 1, y: 0),
          ),
          playerPartyIndex: 0,
        ),
        outcome: afterTurn2.state.outcome!,
      );

      expect(updatedState.party.members.first.currentHp, equals(15));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('run choice produces a real runaway outcome without trainer flags',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);

      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceRun())
          .state
          .outcome!;
      expect(outcome.isRunaway, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members.first.currentHp, equals(20));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('wild capture is disabled when the player has no poke-ball', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(
          bag: const Bag(),
        ),
        request: request,
      );

      expect(setup.allowCapture, isFalse);
    });

    test('capture choice produces a persistent captured pokemon', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      expect(setup.allowCapture, isTrue);

      final stateWithSeen = markSpeciesSeenInGameState(
        _playerState(),
        setup.enemyPokemon.speciesId,
      );
      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceCapture())
          .state
          .outcome!;

      expect(outcome.isCaptured, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members, hasLength(2));
      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('sparkitten'));
      expect(captured.level, equals(6));
      expect(captured.abilityId, equals('blaze'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch']));
      expect(captured.currentHp, equals(outcome.finalState.enemy.currentHp));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
          ],
        ),
      );
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(updatedState.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });
  });
}

GameState _playerState({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
    ],
  ),
}) {
  return GameState(
    saveId: 'wild-flow-save',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 10,
          knownMoveIds: <String>['vine_whip'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

MapData _buildMap() {
  return const MapData(
    id: 'field_map',
    name: 'Field Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_start',
        name: 'Spawn Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'spawn_start',
    ),
  );
}

RuntimeMapBundle _buildBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
  MapData map,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ProjectManifest> _writeProjectManifest(Directory projectRoot) async {
  const manifest = ProjectManifest(
    name: 'Wild Battle Flow Test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'field_grass',
        name: 'Field Grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
          ),
        ],
      ),
    ],
    pokemon: ProjectPokemonConfig(
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'data/pokemon/catalogs/moves.json',
      },
    ),
  );

  await File(
    p.join(projectRoot.path, 'project.json'),
  ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  await _writePokemonFixtures(projectRoot);
  return manifest;
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 35,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 305,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'startingMoves': <String>['vine_whip'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Wild battle flow test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('vine_whip', 'Vine Whip', 12),
        _moveEntry('scratch', 'Scratch', 5),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'type': 'normal',
    'category': power == 0 ? 'status' : 'physical',
    'power': power == 0 ? null : power,
    'pp': 35,
  };
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() {
    if (nextDoubleValues.isEmpty) {
      return 0.0;
    }
    final index = _doubleIndex < nextDoubleValues.length
        ? _doubleIndex++
        : nextDoubleValues.length - 1;
    return nextDoubleValues[index];
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    if (nextIntValues.isEmpty) {
      return 0;
    }
    final index = _intIndex < nextIntValues.length
        ? _intIndex++
        : nextIntValues.length - 1;
    return nextIntValues[index] % max;
  }
}
```

### 15.6. `packages/map_runtime/test/file_game_save_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileGameSaveRepository E2E', () {
    late _TestFileGameSaveRepository repository;
    late Directory testDirectory;

    setUp(() async {
      testDirectory = await Directory.systemTemp.createTemp('game_save_test_');
      repository = _TestFileGameSaveRepository(testDirectory);
    });

    tearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    test('save → load → GameState identical', () async {
      const originalState = GameState(
        saveId: 'test_save_001',
        currentMapId: 'pallet_town',
        playerPosition: GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        playerMovementMode: MovementMode.walk,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'squirtle',
            natureId: 'bold',
            abilityId: 'torrent',
            level: 12,
            ivs: PokemonStatSpread(
              hp: 31,
              attack: 30,
              defense: 29,
              specialAttack: 28,
              specialDefense: 27,
              speed: 26,
            ),
            knownMoveIds: ['surf', 'water_gun'],
            currentHp: 30,
            heldItemId: 'mystic-water',
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['boulder', 'cascade'],
          money: 2500,
          playtimeSeconds: 1800,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 10),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
          seenSpeciesIds: ['pidgey'],
          caughtSpeciesIds: ['pidgey'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': ScriptVariableValue.int(3),
        }),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.saveId, equals(originalState.saveId));
      expect(loadedState.currentMapId, equals(originalState.currentMapId));
      expect(loadedState.playerPosition, equals(originalState.playerPosition));
      expect(loadedState.playerFacing, equals(originalState.playerFacing));
      expect(loadedState.playerMovementMode,
          equals(originalState.playerMovementMode));
      expect(loadedState.party.members.length,
          equals(originalState.party.members.length));
      expect(loadedState.trainerProfile, equals(originalState.trainerProfile));
      expect(loadedState.bag, equals(originalState.bag));
      expect(loadedState.progression.unlockedFieldAbilities,
          equals(originalState.progression.unlockedFieldAbilities));
      expect(
        loadedState.progression.seenSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
      expect(
        loadedState.progression.caughtSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
      expect(loadedState.storyFlags.activeFlags,
          equals(originalState.storyFlags.activeFlags));
      expect(
          loadedState.consumedEventIds, equals(originalState.consumedEventIds));
    });

    test('save → load → storyFlags contains trainer_defeated:{id}', () async {
      const trainerId = 'gym_leader_1';
      const originalState = GameState(
        saveId: 'test_save_002',
        currentMapId: 'pallet_town',
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
          'intro_done',
        }),
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags,
          contains('trainer_defeated:$trainerId'));
    });

    test(
        'save → load preserves a captured wild pokemon in party and progression',
        () async {
      const originalState = GameState(
        saveId: 'test_save_capture_001',
        currentMapId: 'field_map',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 20,
            ),
            PlayerPokemon(
              speciesId: 'sparkitten',
              natureId: 'hardy',
              abilityId: 'blaze',
              level: 6,
              knownMoveIds: <String>['scratch'],
              currentHp: 17,
            ),
          ],
        ),
        progression: PlayerProgression(
          seenSpeciesIds: <String>['sparkitten'],
          caughtSpeciesIds: <String>['sparkitten'],
        ),
      );

      await repository.save(originalState);
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.party.members, hasLength(2));
      expect(loadedState.party.members.last.speciesId, equals('sparkitten'));
      expect(loadedState.party.members.last.abilityId, equals('blaze'));
      expect(
        loadedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );
      expect(
        loadedState.progression.caughtSpeciesIds,
        contains('sparkitten'),
      );
      expect(
        loadedState.progression.seenSpeciesIds,
        contains('sparkitten'),
      );
    });

    test(
        'load migrates legacy progression.storyFlags into storyFlags.activeFlags',
        () async {
      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final legacyJson = <String, dynamic>{
        'saveId': 'legacy_save',
        'currentMapId': 'vova_center',
        'progression': <String, dynamic>{
          'unlockedFieldAbilities': <String>[],
          'storyFlags': <String>[
            'met_professor',
            'trainer_defeated:jean_michel'
          ],
        },
        'storyFlags': <String, dynamic>{
          'activeFlags': <String>[],
        },
      };
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(legacyJson));

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags, contains('met_professor'));
      expect(
        loadedState.storyFlags.activeFlags,
        contains('trainer_defeated:jean_michel'),
      );
    });

    test('load when no save exists → returns null', () async {
      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('exists() returns true after save', () async {
      const state = GameState(
        saveId: 'test_save_003',
        currentMapId: 'pallet_town',
      );

      expect(await repository.exists(), isFalse);

      await repository.save(state);

      expect(await repository.exists(), isTrue);
    });

    test('delete → load → returns null', () async {
      const state = GameState(
        saveId: 'test_save_004',
        currentMapId: 'pallet_town',
      );

      await repository.save(state);
      expect(await repository.exists(), isTrue);

      await repository.delete();
      expect(await repository.exists(), isFalse);

      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('JSON file structure is valid', () async {
      const trainerId = 'test_trainer';
      const state = GameState(
        saveId: 'test_save_005',
        currentMapId: 'test_map',
        playerPosition: GridPos(x: 10, y: 5),
        playerFacing: EntityFacing.east,
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
        }),
      );

      await repository.save(state);

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json['saveId'], equals('test_save_005'));
      expect(json['currentMapId'], equals('test_map'));
      expect(json['playerPosition'], isA<Map<String, dynamic>>());
      expect(json['playerFacing'], equals('east'));
      expect(json['playerMovementMode'], equals('walk'));
      expect(json['trainerProfile'], isA<Map<String, dynamic>>());
      expect(json['bag'], isA<Map<String, dynamic>>());
      expect(json['progression'], isA<Map<String, dynamic>>());
      expect(json['storyFlags'], isA<Map<String, dynamic>>());

      final storyFlags = json['storyFlags'] as Map<String, dynamic>;
      expect(storyFlags['activeFlags'], isA<List>());
      expect(
          (storyFlags['activeFlags'] as List)
              .contains('trainer_defeated:$trainerId'),
          isTrue);
    });

    test(
        'load migrates legacy party members and save rewrites normalized phase 9 data',
        () async {
      const originalState = GameState(
        saveId: 'legacy_phase_9',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 4, y: 7),
        playerFacing: EntityFacing.west,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            level: 30,
            knownMoveIds: ['surf', 'ice_beam'],
            currentHp: 22,
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade'],
          money: 1200,
          playtimeSeconds: 600,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': ScriptVariableValue.int(3),
        }),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );
      final legacyJson = originalState.toJson();
      final party = legacyJson['party'] as Map<String, dynamic>;
      final members = party['members'] as List<dynamic>;
      final member = members.single as Map<String, dynamic>;
      member
        ..remove('natureId')
        ..remove('abilityId')
        ..remove('ivs')
        ..remove('evs')
        ..remove('currentHp')
        ..remove('statusId')
        ..remove('isShiny')
        ..remove('heldItemId')
        ..['id'] = 'party_1'
        ..['nickname'] = 'Ferry'
        ..['isFainted'] = false;

      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(legacyJson),
      );

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.party.members.single.speciesId, 'lapras');
      expect(loadedState.party.members.single.natureId, 'hardy');
      expect(loadedState.party.members.single.abilityId, 'unknown');
      expect(loadedState.party.members.single.currentHp, 1);
      expect(loadedState.progression.caughtSpeciesIds, contains('lapras'));
      expect(loadedState.progression.seenSpeciesIds, contains('lapras'));
      expect(
        loadedState.scriptVariables.values['rival_battles_won'],
        const ScriptVariableValue.int(3),
      );
      expect(
        loadedState.storyFlags.activeFlags,
        equals(originalState.storyFlags.activeFlags),
      );
      expect(
        loadedState.consumedEventIds,
        equals(originalState.consumedEventIds),
      );
      expect(loadedState.metadata, equals(originalState.metadata));

      await repository.save(loadedState);

      final normalizedJson =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final normalizedParty = normalizedJson['party'] as Map<String, dynamic>;
      final normalizedMembers = normalizedParty['members'] as List<dynamic>;
      final normalizedMember = normalizedMembers.single as Map<String, dynamic>;

      expect(normalizedMember['speciesId'], 'lapras');
      expect(normalizedMember['natureId'], 'hardy');
      expect(normalizedMember['abilityId'], 'unknown');
      expect(normalizedMember['currentHp'], 1);
      expect(normalizedMember.containsKey('id'), isFalse);
      expect(normalizedMember.containsKey('nickname'), isFalse);
      expect(normalizedMember.containsKey('isFainted'), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('save writes normalized phase 9 data', () async {
      const state = GameState(
        saveId: ' test_save_005b ',
        currentMapId: ' test_map ',
        trainerProfile: TrainerProfile(
          name: ' Red ',
          badgeIds: ['cascade', 'boulder', 'cascade'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: ' potion ', categoryId: ' medicine ', quantity: 2),
            BagEntry(itemId: ' poke-ball ', categoryId: ' items ', quantity: 5),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );

      await repository.save(state);

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final trainerProfile = json['trainerProfile'] as Map<String, dynamic>;
      final bag = json['bag'] as Map<String, dynamic>;
      final entries = bag['entries'] as List<dynamic>;

      expect(json['saveId'], equals('test_save_005b'));
      expect(json['currentMapId'], equals('test_map'));
      expect(trainerProfile['name'], equals('Red'));
      expect(trainerProfile['badgeIds'], equals(['boulder', 'cascade']));
      expect(entries, [
        {
          'itemId': 'poke-ball',
          'categoryId': 'items',
          'quantity': 5,
        },
        {
          'itemId': 'potion',
          'categoryId': 'medicine',
          'quantity': 5,
        },
      ]);
    });

    test('save keeps project.json unchanged', () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const state = GameState(
        saveId: 'test_save_006',
        trainerProfile: TrainerProfile(name: 'Blue'),
      );

      await repository.save(state);

      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('invalid save does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(saveId: '');

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('corrupt load fails and does not rewrite save or project.json',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      const corruptContent = '''
{
  "saveId": "broken_save",
  "currentMapId": "vova_center",
  "party": {
    "members": [
      {
        "speciesId": "lapras",
        "knownMoveIds": ["surf"]
      }
    ]
  }
}
''';
      await file.writeAsString(corruptContent);

      await expectLater(
        () => repository.load(),
        throwsA(isA<GameSaveException>()),
      );

      expect(await file.readAsString(), corruptContent);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test(
        'invalid nested phase 9 data does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(
        saveId: 'test_save_007',
        trainerProfile: TrainerProfile(name: '   '),
      );

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });
  });
}

class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
```
