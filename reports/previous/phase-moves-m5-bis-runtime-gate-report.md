# M5-bis — Gate runtime explicite des moves partiellement supportés au handoff battle

## 1. Résumé exécutif honnête

M5-bis est livré comme un mini-fix strict et local à `map_runtime`.

Le handoff runtime -> `BattleMoveData` refuse maintenant explicitement tout move dont `engineSupportLevel` n'est pas `structuredSupported`. En pratique :
- `structuredSupported` passe ;
- `structuredPartial` échoue explicitement ;
- `catalogOnly` échoue explicitement.

Le gate vit bien dans `RuntimeBattleSetupMapper`, pas dans `RuntimeMoveCatalogLoader`. Le loader continue donc de charger honnêtement tout le canonique, tandis que le mapper devient le point de décision sur ce qui peut encore être projeté vers le bridge battle MVP.

Le diff reste petit : un helper de garde dans le mapper, deux tests ciblés, aucun changement dans le loader, aucun changement dans `map_battle`, aucun changement dans `map_core`, aucun changement dans `map_editor`.

## 2. État initial audité réel

Audit réellement relu :
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_core/lib/src/models/pokemon_move.dart`

Constat réel avant patch :
- le loader runtime M5 chargeait déjà strictement le canonique et conservait `engineSupportLevel` / `unsupportedReasons` ;
- le mapper projetait encore tout move résolu vers `BattleMoveData(id, name, power)` dès lors qu'il existait dans le catalogue ;
- le commentaire du mapper documentait encore une politique M5 où `catalogOnly` / `structuredPartial` continuaient le handoff avec `power: 0` ;
- il n’existait pas encore de gate runtime explicite fondé sur `engineSupportLevel`.

Autrement dit :
- le seam de chargement était propre ;
- le seam de projection restait trop permissif.

Sub-agent d’audit/design utilisé : `Planck`.

Retour utile retenu :
- le gate devait bien vivre dans le mapper, pas dans le loader ;
- le plus petit patch sain était une garde locale dans `_resolveBattleMoves()` ;
- le loader devait continuer à charger honnêtement `catalogOnly` / `structuredPartial` sans devenir un policy engine.

## 3. Problème exact traité

Le problème traité est très précis :

Un move canoniquement chargé, mais déjà marqué comme non suffisamment supporté pour le moteur (`structuredPartial` ou `catalogOnly`), pouvait encore atteindre le bridge battle MVP et être transformé en `BattleMoveData`.

C'était trompeur parce que :
- le runtime savait déjà que le move n’était pas prêt pour une projection honnête ;
- mais le handoff battle l’acceptait encore ;
- le cas le plus visible restait un move riche ou non standard qui se retrouvait artificiellement ramené à `power: 0`.

## 4. Cause racine

La cause racine n'était pas dans le loader.

Elle était dans `RuntimeBattleSetupMapper._resolveBattleMoves()` :
- le mapper vérifiait seulement l’existence du move dans le catalogue ;
- il ne vérifiait pas encore son niveau de support runtime->battle ;
- il projetait donc directement vers `BattleMoveData` après lookup.

Le bug était donc un **trou de policy au point de projection**, pas un problème de lecture ou de validation du catalogue canonique.

## 5. Décisions retenues / rejetées

### Décisions retenues

1. **Le gate vit dans le mapper, pas dans le loader.**
   - Raison : le loader doit rester un chargeur strict du canonique, pas devenir un policy engine.

2. **Le signal utilisé est exactement `engineSupportLevel`.**
   - Raison : il existe déjà dans le modèle canonique et c’est précisément le but de ce champ.

3. **Le refus est explicite, sans fallback.**
   - Raison : éviter tout downgrade silencieux vers `power: 0` ou tout filtrage opportuniste.

4. **Le message d’erreur expose les détails utiles.**
   - `combatantLabel`
   - `moveId`
   - `moveName`
   - `engineSupportLevel`
   - `unsupportedReasons`

### Décisions rejetées

1. **Mettre le gate dans `RuntimeMoveCatalogLoader`.**
   - Rejeté : ce serait transformer le loader en policy engine et perdre le rôle honnête de transport du canonique.

2. **Ouvrir `map_battle` pour décider quoi faire des moves partiels.**
   - Rejeté : ce serait rouvrir M8 en douce.

3. **Filtrer silencieusement les moves refusés pour continuer avec moins de moves.**
   - Rejeté : le prompt a raison ici, ce serait trompeur.

4. **Introduire un nouveau framework de policy.**
   - Rejeté : totalement disproportionné pour M5-bis.

## 6. Périmètre inclus / exclu

### Inclus

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `reports/phase-moves-m5-bis-runtime-gate-report.md`

### Exclus

- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_battle/...`
- `packages/map_core/...`
- `packages/map_editor/...`

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

### Créés

- `reports/phase-moves-m5-bis-runtime-gate-report.md`

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

C'est le bon point de patch car :
- c'est ici que le runtime connaît à la fois le move canonique choisi **et** la cible de projection `BattleMoveData` ;
- c'est donc ici que l'on peut dire honnêtement si la projection est permise ou non ;
- le loader, lui, doit continuer à charger tout le canonique, y compris les moves non projetables pour le bridge actuel.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

C'est le bon fichier de preuve car :
- il couvre déjà la résolution réelle des moves côté mapper ;
- il permet de prouver séparément le chemin `knownMoveIds` et le chemin dérivé du learnset ;
- il permet de vérifier le `debugDetails` exact sans élargir artificiellement l’end-to-end.

## 9. Commandes réellement exécutées

### Audit / état Git

```text
git status --short
git diff --stat
git ls-files --others --exclude-standard
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
sed -n '1,200p' packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart
sed -n '1,280p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,260p' packages/map_runtime/test/runtime_move_catalog_loader_test.dart
sed -n '1,240p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '320,390p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '280,520p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
rg -n "_moveEntry\(|_writePokemonFixtures\(|trick_room|solar_beam|engineSupportLevel|unsupportedReasons|learnsets/sparkitten|learnsets/sproutle" packages/map_runtime/test/runtime_battle_setup_mapper_test.dart -n
sed -n '520,760p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
```

### Format

Depuis `packages/map_runtime` :

```text
/opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart test/runtime_battle_setup_mapper_test.dart
/opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart
```

### Analyze

Depuis `packages/map_runtime` :

```text
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_exception.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### Tests

Depuis `packages/map_runtime` :

```text
/opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
/opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

## 10. Résultats réels de format / analyze / tests

### Format

```text
Formatted 2 files (0 changed) in 0.01 seconds.
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Analyze

```text
No issues found! (ran in 1.6s)
No issues found! (ran in 1.2s)
```

### Tests

Premier run utile :

```text
00:01 +17: All tests passed!
```

Rerun après correction du commentaire suite à la review :

```text
00:01 +17: All tests passed!
```

## 11. Incidents rencontrés

1. **Flutter startup lock pendant l’exécution parallèle analyze/test.**
   - Rien de bloquant ; j’ai simplement attendu puis rerun proprement.

2. **Aucune erreur de compilation ni échec test métier.**
   - Le lot est resté petit et stable.

## 12. État git utile

### `git status --short`

```text
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? .DS_Store
?? reports/phase-moves-m5-bis-runtime-gate-report.md
```

### `git diff --stat`

```text
 .../application/runtime_battle_setup_mapper.dart   |  52 +++++-
 .../test/runtime_battle_setup_mapper_test.dart     | 182 ++++++++++++++++++++-
 2 files changed, 228 insertions(+), 6 deletions(-)
```

### Fichiers non suivis

```text
.DS_Store
reports/phase-moves-m5-bis-runtime-gate-report.md
```

Note : `.DS_Store` est hors scope et n’a pas été touché.

## 13. Checklist finale

- [x] j’ai audité le code réel avant de coder
- [x] j’ai challengé le prompt
- [x] j’ai confirmé que le gate devait vivre dans le mapper
- [x] j’ai confirmé qu’il ne devait pas vivre dans le loader
- [x] je n’ai pas touché `map_battle`
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai pas modifié le loader runtime
- [x] le gate est réellement en place au handoff battle
- [x] `structuredPartial` échoue explicitement
- [x] `catalogOnly` échoue explicitement
- [x] il n’y a aucun fallback silencieux
- [x] le diff reste petit
- [x] les tests couvrent `knownMoveIds`
- [x] les tests couvrent le chemin dérivé du learnset
- [x] les tests conservent un happy path vert
- [x] les tests vérifient des détails d’erreur utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai intégré sa remarque valide
- [x] je n’ai fait aucune écriture Git interdite
- [x] le rapport est honnête
- [x] l’autocritique est présente
- [x] la critique explicite du prompt est présente

## 14. Retour du reviewer séparé

Reviewer utilisé : `Mill`.

Agent d’audit/design séparé utilisé plus tôt : `Planck`.

Retour initial :
- une remarque faible mais valide : le commentaire au-dessus de la projection `BattleMoveData(... power: ...)` était resté en version M5 et ne reflétait plus la politique M5-bis.

Retour utile résumé :
- le code était cohérent ;
- pas de fuite de scope ;
- pas d’autre finding matériel ;
- seul le commentaire devait être réaligné avec la nouvelle politique.

## 15. Corrections appliquées suite à la review

J’ai mis à jour le commentaire de `runtime_battle_setup_mapper.dart` pour qu’il dise explicitement :
- que les moves `catalogOnly` / `structuredPartial` n’atteignent plus la projection ;
- que le `power: 0` restant ne s’applique plus qu’aux moves autorisés par le gate, mais sans flow de dégâts standard dans le bridge MVP ;
- que l’extension réelle de cette politique appartient toujours à M8.

Puis j’ai rerun analyze/tests ciblés.

## 16. Autocritique finale

### Ce qui est solide

- le gate vit au bon endroit ;
- le loader garde son rôle propre ;
- le diff est petit et lisible ;
- les deux chemins métier demandés sont prouvés.

### Ce qui reste seulement acceptable

- l’erreur échoue au niveau du setup entier, donc un seul move non supporté bloque tout le combat ;
- c’est volontaire pour M5-bis, mais c’est une politique dure.

### Principal risque restant

Le principal risque restant est que `engineSupportLevel` soit encore une approximation de support moteur, pas une preuve d’exécutabilité complète. On ferme donc un trou évident, mais on ne résout pas encore toute la sémantique runtime -> battle.

### Ce que je ferais dans un M5-bis-bis si on me le demandait

- centraliser éventuellement la formulation du `debugDetails` si plusieurs gates runtime analogues apparaissent ;
- ajouter une preuve encore plus ciblée sur un trainer learnset-derived path si l’équipe veut verrouiller aussi cette variante, même si le chemin learnset player suffit déjà ici.

## 17. Critique explicite du prompt reçu

### Ce qui était juste

- la localisation du gate dans le mapper, pas dans le loader ;
- l’usage de `engineSupportLevel` comme signal ;
- l’exigence d’un refus explicite sans fallback ;
- le refus d’ouvrir `map_battle` ;
- la demande de tests `knownMoveIds` + learnset-derived.

### Ce qui était discutable

- la préférence implicite pour ne toucher “probablement” que le mapper et ses tests était bonne, mais il fallait la vérifier contre le code réel et ne pas la traiter comme un dogme.

### Ce qui aurait été dangereux si suivi aveuglément

- lire “gater les moves partiellement supportés” comme une raison de déplacer cette policy dans le loader ;
- traiter `engineSupportLevel` comme une vérité absolue du moteur et non comme le signal de support disponible aujourd’hui ;
- élargir ce petit fix en M8 déguisé sur l’exécution réelle des effets.

### Ce que j’ai corrigé / recadré

- j’ai explicitement maintenu le loader comme frontière de transport du canonique ;
- j’ai gardé le gate exclusivement dans le mapper ;
- j’ai refusé d’élargir le lot vers `map_battle` ou vers une policy plus générale que le simple refus `!= structuredSupported`.

### Pourquoi

Parce que c’est la version la plus saine pour le repo réel :
- minimale ;
- cohérente avec M5 ;
- compatible avec un futur M8 sans refaire encore le seam.

## 18. Conclusion honnête

M5-bis ferme bien le trou restant de M5.

Le runtime ne se contente plus de charger honnêtement les moves canoniques : il refuse désormais explicitement de projeter vers le battle bridge MVP les moves déjà marqués comme partiellement ou non supportés. Le loader reste pur, le mapper devient le vrai point de gate, et le diff reste court.

C’est un petit lot, mais c’est un vrai durcissement de contrat.

## 19. Annexe — contenu complet des fichiers texte touchés

Le report s’exclut lui-même de cette annexe pour éviter la récursion infinie.

## `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'battle_start_request.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// On garde malgré tout ici un reader JSON minimal pour les espèces/learnsets
/// parce que :
/// - la source de vérité des données Pokémon de runtime est le workspace projet ;
/// - `map_runtime` ne doit pas dépendre des modèles internes de `map_editor` ;
/// - M5 n'ouvre pas encore un loader spécialisé pour toute la base Pokémon.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;

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
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );

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
    required RuntimeMoveCatalog movesCatalog,
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
    required RuntimeMoveCatalog movesCatalog,
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
    required RuntimeMoveCatalog movesCatalog,
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
    required RuntimeMoveCatalog movesCatalog,
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
      _ensureMoveCanBeProjectedToBattle(
        move: move,
        combatantLabel: combatantLabel,
      );
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.name,
          // Le moteur battle MVP reste borné :
          // - il ne connaît encore ni accuracy, ni effets structurés, ni
          //   support level ;
          // - il consomme uniquement une puissance de base simplifiée.
          //
          // M5-bis change volontairement la frontière :
          // - seuls les moves déjà marqués `structuredSupported` arrivent
          //   jusqu'ici ;
          // - `catalogOnly` et `structuredPartial` échouent explicitement un
          //   peu plus haut, avant toute projection vers `BattleMoveData`.
          //
          // Ce `power: 0` restant n'est donc plus un downgrade silencieux
          // d'un move partiellement supporté. Il ne sert plus qu'aux moves
          // réellement autorisés par le gate runtime, mais qui suivent un flow
          // de dégâts non standard ou purement status dans le bridge MVP.
          //
          // Conséquence assumée pour ce lot :
          // - si le move suit le flow de dégâts standard, on transmet
          //   `basePower` ;
          // - sinon on garde `0`, exactement comme les vieux status moves du
          //   MVP battle.
          //
          // On documente explicitement cette limite au lieu de l'étendre ici :
          // décider quels `effects`/support levels deviennent réellement
          // exécutables appartient au futur pont runtime -> battle (M8), pas
          // à ce seam de chargement M5.
          power: move.usesStandardDamageFlow ? move.basePower : 0,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  /// Refuse explicitement les moves déjà marqués comme non projetables vers le
  /// handoff battle actuel.
  ///
  /// Pourquoi le gate vit ici, et pas dans le loader :
  /// - le loader runtime doit rester un transport strict du canonique ;
  /// - il doit continuer à charger honnêtement `catalogOnly` et
  ///   `structuredPartial` pour le runtime au sens large ;
  /// - c'est seulement ici, au moment précis où l'on s'apprête à écraser le
  ///   move canonique riche vers le pont MVP `BattleMoveData(id, name, power)`,
  ///   que l'on sait si cette projection est honnête ou trompeuse.
  ///
  /// Conséquence assumée de M5-bis :
  /// - `structuredSupported` passe ;
  /// - `structuredPartial` et `catalogOnly` échouent immédiatement ;
  /// - aucun filtrage silencieux, aucun downgrade vers `power: 0`.
  void _ensureMoveCanBeProjectedToBattle({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
        PokemonMoveEngineSupportLevel.structuredSupported) {
      return;
    }

    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le handoff battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons',
    );
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
///
/// Le catalogue moves a été extrait dans [RuntimeMoveCatalogLoader] pour
/// éviter qu'un second parser canonique vive caché dans ce reader local.
class _RuntimePokemonProjectReader {
  const _RuntimePokemonProjectReader({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

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

```

## `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

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
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
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

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'rejects an explicitly known move when its runtime support level is only partial',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-unsupported-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['growl', 'vine_whip'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('ne sait pas projeter honnêtement'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('moveId=growl'),
                  contains('moveName=Growl'),
                  contains('engineSupportLevel=structuredPartial'),
                  contains(
                    'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'rejects a learnset-derived move when its runtime support level is catalog only',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-unsupported-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=tackle'),
              contains('moveName=Tackle'),
              contains('engineSupportLevel=catalogOnly'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:legacy_damage_bridge]',
              ),
            ),
          ),
        ),
      );
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

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: 'normal',
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
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
