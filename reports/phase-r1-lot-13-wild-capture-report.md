# Phase R1 — Lot 13 — Capture sauvage persistante minimale

## 1. Résumé exécutif honnête

Le lot 13 a été livré dans un périmètre strict et borné.

Ce qui est maintenant réellement en place :
- une action `Capture` existe côté moteur de combat ;
- elle n’est disponible qu’en combat sauvage quand la party du joueur a encore de la place ;
- elle termine immédiatement le combat avec un outcome explicite `captured` ;
- le runtime écrit alors un vrai `PlayerPokemon` capturé dans la party du joueur ;
- la persistance `caught/seen` reste cohérente via la normalisation lot 12 ;
- la sauvegarde / le rechargement conservent réellement cet état ;
- la capture trainer reste interdite, y compris en appel forcé ;
- si la party est pleine, la capture n’est pas proposée et un appel forcé est rejeté explicitement.

Ce qui n’a volontairement pas été fait :
- aucune consommation de Poké Ball ;
- aucune vraie formule canonique de capture ;
- aucun bag ;
- aucun PC / boxes ;
- aucun reward / XP / level up ;
- aucune UI Pokédex ;
- aucun lot 14+.

## 2. État initial audité réel

Audit du code réel avant modification :

### `map_battle`
- `BattleSession.getAvailableChoices()` ne proposait que `Fight` et `Run`.
- `BattleSession.applyChoice(...)` savait produire `victory`, `defeat` et `runaway`, mais rien pour une capture.
- Le guard lot 11 existait déjà pour interdire `Run` en trainer battle.
- Le moteur n’avait donc aucun contrat explicite pour une capture sauvage persistante minimale.

### `map_runtime`
- `RuntimeBattleSetupMapper` construisait déjà le `BattleSetup` réel depuis la vraie party joueur, les vraies espèces sauvages et la vraie team trainer.
- `applyRuntimeBattleOutcomeToGameState(...)` écrivait déjà les PV post-combat et le flag `trainer_defeated` uniquement en cas de victoire trainer.
- La boucle sauvage lot 11 était déjà réelle et testée.
- Le lot 12 marquait déjà `seen` au moment du handoff sauvage réel, et la normalisation core synchronisait `party -> caught -> seen`.
- Le vrai trou restant était donc bien la capture sauvage minimale : aucune action moteur, aucun outcome capture, aucun write-back runtime de Pokémon capturé.

### `map_core`
- `PlayerPokemon` et `PlayerParty` existaient déjà comme vraie source de vérité save/runtime.
- `PlayerProgression` portait déjà `seenSpeciesIds` et `caughtSpeciesIds` grâce au lot 12.
- `_normalizePokedexProgression(...)` assurait déjà la règle `party -> caught -> seen`.
- Il n’y avait donc pas besoin de nouveau modèle de capture ni de nouveau pipeline save.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés
- aucune capture sauvage réelle n’existait côté moteur battle ;
- aucun `BattleOutcomeType` ne représentait une capture ;
- aucun write-back runtime n’ajoutait un Pokémon capturé à la party ;
- aucune garde explicite n’empêchait une capture forcée en trainer battle ;
- aucune garde explicite n’empêchait une capture forcée quand la party est pleine.

### Problèmes non confirmés
- aucun besoin de refondre `PlayableMapGame` n’a été confirmé ;
- aucun besoin de toucher le host d’exemple n’a été confirmé ;
- aucun besoin de toucher `map_editor` n’a été confirmé ;
- aucun besoin d’ajouter un bag, une Poké Ball ou une formule canonique de capture n’a été confirmé.

## 4. Cause racine réelle

La cause racine était localisée et non architecturale :
- le moteur battle n’exposait pas de contrat capture ;
- le runtime n’avait donc rien à appliquer au `GameState` ;
- le core possédait déjà la bonne destination persistante (`party`, `caught`, `seen`), mais aucun événement capture ne l’alimentait.

Le lot 13 n’exigeait donc pas un nouveau système, seulement un petit prolongement cohérent du contrat battle/runtime déjà posé par les lots 9 à 12.

## 5. Décisions retenues / rejetées

### Décisions retenues
- Ajouter une nouvelle action joueur `PlayerBattleChoiceCapture` dans `map_battle`.
- Ajouter un nouvel outcome terminal `BattleOutcomeType.captured`.
- Ajouter un booléen `allowCapture` dans `BattleSetup` pour que le runtime contrôle honnêtement si la capture peut être proposée.
- Étendre `BattleCombatantData` / `BattleCombatant` avec `abilityId` pour transporter une ability réelle jusqu’à l’outcome final, sans nouveau modèle parallèle.
- Construire le Pokémon capturé côté runtime à partir du vrai combattant ennemi final : `speciesId`, `level`, `moves`, `abilityId`, `currentHp`.
- Utiliser une nature MVP déterministe `hardy` faute de vraie génération runtime déjà existante.
- Rejeter explicitement la capture forcée :
  - en trainer battle ;
  - quand `allowCapture == false` ;
  - côté runtime si un outcome `captured` arrive alors que la party est déjà pleine.
- Réutiliser la normalisation lot 12 pour synchroniser `caught/seen` à partir de la party, au lieu d’inventer un deuxième pipeline Pokédex.

### Décisions rejetées
- nouveau système de capture global ;
- consommation réelle de Poké Ball ;
- formule complète de capture canonique ;
- PC / box système ;
- refonte de `PlayableMapGame` ;
- nouveau store runtime ;
- nouveau modèle concurrent à `PlayerPokemon` ;
- ouverture des lots 14+.

## 6. Périmètre inclus / exclu

### Inclus
- capture sauvage minimale réelle ;
- outcome capture terminal explicite ;
- écriture réelle du Pokémon capturé dans `GameState.party` ;
- cohérence `caught/seen` via la normalisation lot 12 ;
- garde trainer et garde party full ;
- persistance save/load ;
- tests battle/runtime/save ciblés.

### Exclu
- capture trainer ;
- bag / objets / Poké Balls ;
- rewards / XP / level up ;
- whiteout-lite / heal center ;
- switch complet ;
- multi-combattants ;
- UI Pokédex riche ;
- lot 14+.

## 7. Gameplay final du lot 13 en français simple

### Quand on capture un sauvage
- En combat sauvage, si la party du joueur a moins de 6 Pokémon, l’action `Capture` apparaît dans les choix.
- Choisir `Capture` termine immédiatement le combat avec un outcome de capture réussie.
- Le runtime revient ensuite proprement à l’overworld.
- Le Pokémon capturé est réellement ajouté à la party du joueur.
- Comme il est désormais réellement possédé, il est aussi présent dans `caught` et donc dans `seen`.

### Si la party est pleine
- L’action `Capture` n’est pas proposée.
- Si un call site force quand même une capture alors que la party est pleine, le code rejette explicitement ce cas.
- Aucun Pokémon ne disparaît silencieusement dans une boîte ou un stockage magique, parce que ces systèmes sont hors scope.

### En trainer battle
- L’action `Capture` n’est jamais proposée.
- Si un appel moteur forcé tente quand même une capture trainer, il est rejeté explicitement.
- Un trainer battle ne peut donc jamais produire un `captured` valide.

### Hors scope volontaire
- aucune Poké Ball réelle ;
- aucune probabilité canonique de capture ;
- aucun PC ;
- aucune récompense ;
- aucune UI Pokédex.

## 8. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_session_flow_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`

### Créés
- aucun

### Supprimés
- aucun

## 9. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_action.dart`
Ajout du choix joueur `PlayerBattleChoiceCapture`, strictement local au moteur battle.

### `packages/map_battle/lib/src/battle_setup.dart`
Ajout de `allowCapture` et transport de `abilityId` dans `BattleCombatantData` pour que le runtime puisse exposer la capture seulement quand elle est honnête et persister une ability réelle du sauvage capturé.

### `packages/map_battle/lib/src/battle_state.dart`
Transport de `abilityId` dans `BattleCombatant` jusqu’à l’outcome final, sans changer le moteur de dégâts.

### `packages/map_battle/lib/src/battle_resolution.dart`
Ajout de `BattleOutcomeType.captured` et du getter `isCaptured`.

### `packages/map_battle/lib/src/battle_session.dart`
Cœur métier du lot 13 : exposition conditionnelle de `Capture`, garde trainer/party full via `allowCapture`, outcome terminal `captured`.

### `packages/map_battle/test/battle_session_test.dart`
Preuves ciblées sur la disponibilité/non-disponibilité de `Capture` dans les choix battle.

### `packages/map_battle/test/battle_session_flow_test.dart`
Preuves ciblées sur la résolution capture, le guard trainer, le guard capture-disallowed, et la non-régression des outcomes existants.

### `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
Propage les vraies abilities au setup battle et décide honnêtement si la capture doit être proposée (`party.members.length < 6` en sauvage).

### `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
Applique réellement la capture au `GameState` : ajout à la party, garde explicite trainer/full party, réutilisation de la normalisation lot 12 pour `caught/seen`.

### `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
Affichage correct du nouveau choix `Capture` et du nouvel outcome terminal `captured`.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
Prouve que le mapper battle réel autorise/interdit correctement la capture selon sauvage/trainer et party non pleine/pleine.

### `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
Prouve que l’outcome `captured` écrit réellement le Pokémon dans la party et garde des garde-fous explicites trainer/full party.

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
Preuve verticale lot 13 : vraie rencontre sauvage, vrai setup, vraie capture, vrai write-back runtime, cohérence `party/caught/seen`.

### `packages/map_runtime/test/file_game_save_repository_test.dart`
Preuve de persistance réelle après capture : save/load conserve le Pokémon capturé et la progression `caught/seen` cohérente.

## 10. Commandes réellement exécutées

### Audit
```bash
find /Users/karim/Project/pokemonProject -path '*/AGENTS.md' -print
git status --short
git diff --stat
rg -n "PlayerBattleChoice|BattleOutcomeType|runaway|capture|captur|caught|seen|BattleSetup|BattleSession|getAvailableChoices|applyChoice|wild battle|trainer battle" packages/map_battle packages/map_runtime packages/map_core -g'*.dart'
sed -n '1,240p' packages/map_battle/lib/src/battle_action.dart
sed -n '1,260p' packages/map_battle/lib/src/battle_setup.dart
sed -n '1,260p' packages/map_battle/lib/src/battle_resolution.dart
sed -n '1,340p' packages/map_battle/lib/src/battle_session.dart
sed -n '340,460p' packages/map_battle/lib/src/battle_session.dart
sed -n '1,260p' packages/map_battle/lib/src/battle_state.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '260,760p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '2960,3185p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,260p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,240p' packages/map_core/lib/src/operations/game_state_persistence.dart
rg -n "party full|members.length|at most|max.*party|party.*6|PlayerParty" packages/map_core packages/map_runtime packages/map_battle -g'*.dart'
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,240p' packages/map_battle/test/battle_session_test.dart
sed -n '1,320p' packages/map_battle/test/battle_session_flow_test.dart
sed -n '340,390p' packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
sed -n '1,260p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1,260p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
sed -n '1,200p' packages/map_battle/lib/map_battle.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/battle_start_request.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/encounter_to_battle_request.dart
rg -n "natureId|abilityId|hardy|unknown|overgrow|torrent|pressure|heldItemId|isShiny|statusId" packages/map_runtime packages/map_core packages/map_battle -g'*.dart'
rg -n "BattleOutcomeType|isRunaway|isVictory|isDefeat|outcome.type|runaway|victory|defeat" packages/map_runtime packages/map_battle -g'*.dart'
sed -n '300,520p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '220,520p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1,220p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,220p' packages/map_runtime/lib/map_runtime.dart
```

### Format
```bash
/opt/homebrew/bin/dart format packages/map_battle/lib/src/battle_action.dart packages/map_battle/lib/src/battle_setup.dart packages/map_battle/lib/src/battle_state.dart packages/map_battle/lib/src/battle_resolution.dart packages/map_battle/lib/src/battle_session.dart packages/map_battle/test/battle_session_test.dart packages/map_battle/test/battle_session_flow_test.dart packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart packages/map_runtime/test/runtime_battle_setup_mapper_test.dart packages/map_runtime/test/runtime_battle_outcome_apply_test.dart packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart packages/map_runtime/test/file_game_save_repository_test.dart
/opt/homebrew/bin/dart format packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
```

### Analyze
```bash
cd packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_action.dart lib/src/battle_setup.dart lib/src/battle_state.dart lib/src/battle_resolution.dart lib/src/battle_session.dart test/battle_session_test.dart test/battle_session_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_outcome_apply.dart lib/src/presentation/flame/battle_overlay_component.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/file_game_save_repository_test.dart
```

### Tests
```bash
cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart test/battle_session_flow_test.dart test/battle_flow_integration_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/file_game_save_repository_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/trainer_battle_request_test.dart
```

### État git final
```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 11. Résultats réels de format / analyze / tests

### Format
Résultat : succès.

Sortie notable :
- `Formatted packages/map_battle/test/battle_session_flow_test.dart`
- `Formatted packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `Formatted packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `Formatted packages/map_runtime/test/file_game_save_repository_test.dart`
- `Formatted 14 files (4 changed) in 0.04 seconds.`
- relance ciblée : `Formatted 1 file (0 changed) in 0.01 seconds.`

### Analyze `map_battle`
Résultat : succès.

Sortie : `No issues found!`

### Analyze `map_runtime`
Résultat final : succès.

Sortie finale : `No issues found! (ran in 1.4s)`

Note honnête : la première passe a remonté une seule info de lint préexistante localisée sur `containsPoint` dans `battle_overlay_component.dart` (`annotate_overrides`). Elle a été corrigée immédiatement puis l’analyse a été relancée et est passée au vert.

### Tests `map_battle`
Résultat : succès.

Sortie finale : `All tests passed!`

### Tests `map_runtime`
Résultat : succès.

Sortie finale : `All tests passed!`

### Non-régression runtime trainer ciblée
Résultat : succès.

Sortie finale : `All tests passed!`

## 12. Incidents rencontrés

- La création de nouveaux sub-agents était bloquée par la limite de threads active. J’ai réutilisé des reviewers existants via `send_input`.
- Un reviewer runtime a recommandé une intégration sidecar plus large que nécessaire. Sa conclusion a été lue puis rejetée au profit d’une solution plus petite et plus cohérente avec le code réel.
- L’analyse runtime a remonté une seule info de lint (`@override` manquant sur `containsPoint`). Correctif local immédiat, sans changement de scope.
- Une commande Flutter a brièvement attendu le `startup lock` Flutter avant de terminer proprement. Aucun échec métier lié à ça.

## 13. État git utile

```text
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_setup.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_battle/test/battle_session_flow_test.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/file_game_save_repository_test.dart
 M packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/phase-r1-lot-13-wild-capture-report.md
```

## 14. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai fait aucune écriture Git interdite
- [x] je n’ai pas ouvert les lots 14+
- [x] la capture n’est possible qu’en sauvage
- [x] la capture est impossible en trainer battle, y compris en appel forcé
- [x] la capture ne ment pas sur la persistance
- [x] un Pokémon capturé rejoint réellement l’état du joueur si la capture réussit
- [x] seen/caught restent cohérents
- [x] les saves restent lisibles et cohérentes
- [x] j’ai ajouté les tests réellement utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] mon report markdown est ultra complet
- [x] mon report contient le contenu complet des fichiers touchés
- [x] je documente honnêtement tout ce que je n’ai pas fait

## 15. Conclusion honnête

Le lot 13 est défendable dans son périmètre minimal.

Ce qui est réellement livré :
- capture sauvage persistante minimale ;
- outcome battle explicite `captured` ;
- ajout réel à la party ;
- cohérence `caught/seen` ;
- compatibilité save/load ;
- garde trainer ;
- garde party full ;
- non-régressions sauvages/trainer utiles relancées.

Ce qui reste volontairement hors scope :
- formule canonique de capture ;
- Poké Balls / bag ;
- PC / boxes ;
- rewards / XP / level up ;
- lot 14+.

## 16. Annexe — contenu complet des fichiers touchés

Le report s’exclut lui-même de sa propre annexe pour éviter la récursion infinie.

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart

```dart
import 'battle_move.dart';

/// Choix disponible pour le joueur.
///
/// Représente une décision que le joueur peut prendre pendant son tour.
/// Ce modèle est utilisé par l'UI pour afficher les options disponibles.
sealed class PlayerBattleChoice {
  /// Constructeur constant pour les sous-classes.
  const PlayerBattleChoice();
}

/// Utiliser une attaque.
///
/// Le joueur choisit d'utiliser une de ses 4 attaques.
/// [moveIndex] est l'index dans la liste des attaques du Pokémon (0-3).
class PlayerBattleChoiceFight extends PlayerBattleChoice {
  /// Crée un choix d'attaque.
  ///
  /// [moveIndex] - L'index de l'attaque dans la liste (0-3).
  const PlayerBattleChoiceFight(this.moveIndex);

  /// L'index de l'attaque dans la liste des attaques du Pokémon.
  final int moveIndex;
}

/// Fuir le combat.
///
/// Le joueur choisit de tenter de fuir.
/// Pour ce MVP, la fuite est toujours réussie (simplification).
class PlayerBattleChoiceRun extends PlayerBattleChoice {
  /// Crée un choix de fuite.
  const PlayerBattleChoiceRun();
}

/// Capturer le Pokémon adverse.
///
/// Le lot 13 reste volontairement minimal :
/// - cette action n'est légitime qu'en combat sauvage ;
/// - elle ne modélise ni sac, ni consommation d'objet, ni formule canonique ;
/// - elle sert uniquement à produire un outcome explicite que le runtime
///   pourra écrire honnêtement dans la vraie party du joueur.
class PlayerBattleChoiceCapture extends PlayerBattleChoice {
  /// Crée un choix de capture.
  const PlayerBattleChoiceCapture();
}

/// Action résolue (interne au moteur de combat).
///
/// Contrairement à [PlayerBattleChoice] qui est un choix UI,
/// [BattleAction] représente l'action après résolution (attaque sélectionnée, etc.).
sealed class BattleAction {
  /// Constructeur constant pour les sous-classes.
  const BattleAction();
}

/// Utiliser une attaque (action résolue).
///
/// Contient l'attaque réelle à exécuter, pas juste l'index.
class BattleActionFight extends BattleAction {
  /// Crée une action d'attaque.
  ///
  /// [move] - L'attaque à exécuter.
  const BattleActionFight(this.move);

  /// L'attaque à exécuter.
  final BattleMove move;
}

/// Fuir (action résolue).
///
/// Représente une tentative de fuite résolue.
class BattleActionRun extends BattleAction {
  /// Crée une action de fuite.
  const BattleActionRun();
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart

```dart
/// Configuration initiale d'un combat.
///
/// Modèle pur, sans dépendance runtime.
/// Construit depuis [BattleStartRequest] par le runtime via un mapper dédié.
///
/// Ce modèle contient uniquement les données nécessaires au moteur de combat,
/// sans aucune référence à l'orchestration runtime (OverworldReturnContext, etc.).
class BattleSetup {
  /// Crée une configuration de combat.
  ///
  /// [playerPokemon] - Le Pokémon du joueur qui combat.
  /// [enemyPokemon] - Le Pokémon adverse qui combat.
  /// [isTrainerBattle] - true si c'est un combat contre un dresseur.
  /// [trainerId] - L'identifiant du dresseur (non-null si [isTrainerBattle] est true).
  /// [allowCapture] - true si le runtime autorise explicitement la capture
  ///   pour ce combat. Le lot 13 l'utilise uniquement pour les rencontres
  ///   sauvages quand la party a encore de la place.
  const BattleSetup({
    required this.playerPokemon,
    required this.enemyPokemon,
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// true si c'est un combat contre un dresseur.
  ///
  /// Si false, c'est une rencontre sauvage (wild battle).
  final bool isTrainerBattle;

  /// L'identifiant du dresseur.
  ///
  /// Non-null si [isTrainerBattle] est true.
  /// Utilisé par le runtime pour marquer `trainer_defeated:{trainerId}` après victoire.
  final String? trainerId;

  /// true si l'action Capture doit être exposée au joueur.
  ///
  /// Invariants métier lot 13 :
  /// - jamais en combat trainer ;
  /// - seulement si le runtime sait qu'une capture réussie peut être écrite
  ///   proprement dans l'état joueur ;
  /// - on évite ainsi toute promesse mensongère quand la party est pleine.
  final bool allowCapture;
}

/// Données minimales d'un combattant pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleCombatant] est utilisé à la place.
class BattleCombatantData {
  /// Crée les données d'un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce (ex: "pikachu", "lapras").
  /// [level] - Le niveau du combattant.
  /// [maxHp] - Les points de vie maximum.
  /// [currentHp] - Les PV courants si le runtime les connaît déjà.
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  ///
  /// Le lot 9 du runtime -> battle handoff doit partir de la vraie party du
  /// joueur. On ajoute donc ce champ optionnel au setup pour éviter de soigner
  /// implicitement le Pokémon actif lors de l'ouverture du combat.
  /// [moves] - La liste des attaques disponibles (4 max).
  const BattleCombatantData({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Le niveau du combattant.
  final int level;

  /// Les points de vie maximum.
  final int maxHp;

  /// Les points de vie courants si le handoff runtime les fournit déjà.
  ///
  /// Si null, le moteur démarre le combat à pleine vie, ce qui conserve le
  /// comportement historique des tests et call sites qui n'ont pas besoin de
  /// porter cet état.
  final int? currentHp;

  /// L'ability réellement résolue si le runtime la connaît déjà.
  ///
  /// Le moteur de combat MVP n'utilise pas encore cette donnée pour ses
  /// calculs, mais le lot 13 en a besoin pour construire un Pokémon capturé
  /// sans réinventer un deuxième format intermédiaire.
  final String abilityId;

  /// La liste des attaques disponibles.
  final List<BattleMoveData> moves;
}

/// Données minimales d'une attaque pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleMove] est utilisé à la place.
class BattleMoveData {
  /// Crée les données d'une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  const BattleMoveData({
    required this.id,
    required this.name,
    required this.power,
  });

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Pour ce MVP, les dégâts sont calculés simplement :
  /// `damage = move.power` (pas de calculs complexes de stats).
  final int power;
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart

```dart
import 'battle_move.dart';
import 'battle_resolution.dart';

/// Phase du combat.
///
/// Représente l'état actuel du cycle de combat.
enum BattlePhase {
  /// En attente du choix du joueur.
  ///
  /// C'est la phase normale entre les tours.
  /// Le runtime doit appeler [BattleSession.getAvailableChoices()] pour
  /// afficher les options au joueur.
  playerChoice,

  /// Résolution en cours.
  ///
  /// Phase transitoire pendant laquelle le tour est en cours de résolution.
  /// Le runtime ne doit pas permettre de nouveaux choix pendant cette phase.
  resolving,

  /// Combat terminé.
  ///
  /// [BattleState.outcome] est non-null et contient le résultat final.
  /// Le runtime doit appeler `_onBattleFinished(outcome)` pour revenir à l'overworld.
  finished,
}

/// État immutable d'un combat.
///
/// Ce modèle représente l'état complet d'un combat à un instant donné.
/// Il est immutable : toutes les méthodes de modification retournent un nouvel état.
///
/// Invariants :
/// - Si [phase] == [BattlePhase.finished], alors [outcome] est non-null.
/// - Si [phase] != [BattlePhase.finished], alors [outcome] est null.
/// - [player.currentHp] est toujours entre 0 et [player.maxHp].
/// - [enemy.currentHp] est toujours entre 0 et [enemy.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  /// [player] - Le combattant joueur.
  /// [enemy] - Le combattant adverse.
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  const BattleState({
    required this.phase,
    required this.player,
    required this.enemy,
    this.currentTurn,
    this.outcome,
  });

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Le combattant joueur.
  final BattleCombatant player;

  /// Le combattant adverse.
  final BattleCombatant enemy;

  /// Le résultat du tour en cours.
  ///
  /// Null si aucun tour n'est en cours (phase [playerChoice] ou [finished]).
  final BattleTurnResult? currentTurn;

  /// Le résultat final du combat.
  ///
  /// Non-null uniquement si [phase] == [BattlePhase.finished].
  final BattleOutcome? outcome;

  /// true si le combat est terminé.
  ///
  /// Raccourci pour `phase == BattlePhase.finished`.
  bool get isFinished => phase == BattlePhase.finished;
}

/// Combattant en combat.
///
/// Représente un Pokémon avec ses PV courants.
/// Immutable : utiliser [withDamage] pour créer une copie avec des PV modifiés.
///
/// Invariants :
/// - [currentHp] est toujours entre 0 et [maxHp].
/// - [isFainted] est true si et seulement si [currentHp] <= 0.
class BattleCombatant {
  /// Crée un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce.
  /// [level] - Le niveau.
  /// [currentHp] - Les PV courants.
  /// [maxHp] - Les PV maximum.
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  /// [moves] - La liste des attaques disponibles.
  const BattleCombatant({
    required this.speciesId,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce.
  final String speciesId;

  /// Le niveau.
  final int level;

  /// Les PV courants.
  final int currentHp;

  /// Les PV maximum.
  final int maxHp;

  /// L'ability réellement résolue pour ce combattant.
  ///
  /// Le moteur lot 13 n'en tire toujours aucun calcul de combat. On la transporte
  /// néanmoins jusqu'à l'issue finale pour permettre au runtime de persister un
  /// Pokémon capturé à partir du vrai ennemi engagé, sans données inventées.
  final String abilityId;

  /// La liste des attaques disponibles.
  final List<BattleMove> moves;

  /// true si le combattant est K.O.
  ///
  /// Un combattant est K.O. si ses PV courants sont <= 0.
  bool get isFainted => currentHp <= 0;

  /// Crée une copie de ce combattant avec des dégâts appliqués.
  ///
  /// [damage] - La quantité de dégâts à appliquer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withDamage(int damage) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      maxHp: maxHp,
      abilityId: abilityId,
      moves: moves,
    );
  }

  /// Crée une copie de ce combattant avec des PV restaurés.
  ///
  /// [healAmount] - La quantité de PV à restaurer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withHeal(int healAmount) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: (currentHp + healAmount).clamp(0, maxHp),
      maxHp: maxHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart

```dart
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_state.dart';

/// Résultat d'un tour de combat.
///
/// Contient les actions jouées et leurs exécutions.
/// Utilisé pour afficher le déroulement du tour au joueur.
class BattleTurnResult {
  /// Crée un résultat de tour.
  ///
  /// [playerAction] - L'action jouée par le joueur.
  /// [enemyAction] - L'action jouée par l'ennemi.
  /// [executions] - La liste des exécutions d'attaques (dans l'ordre).
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
  });

  /// L'action jouée par le joueur.
  final BattleAction playerAction;

  /// L'action jouée par l'ennemi.
  final BattleAction enemyAction;

  /// La liste des exécutions d'attaques.
  ///
  /// Ordonnées selon l'ordre de résolution (déterministe).
  /// Pour ce MVP : joueur joue en premier, puis ennemi.
  final List<BattleMoveExecution> executions;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attacker] - L'identifiant de l'attaquant ("player" ou "enemy").
  /// [move] - L'attaque utilisée.
  /// [target] - L'identifiant de la cible ("player" ou "enemy").
  /// [damage] - Les dégâts infligés.
  const BattleMoveExecution({
    required this.attacker,
    required this.move,
    required this.target,
    required this.damage,
  });

  /// L'identifiant de l'attaquant.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String attacker;

  /// L'attaque utilisée.
  final BattleMove move;

  /// L'identifiant de la cible.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String target;

  /// Les dégâts infligés.
  ///
  /// Pour ce MVP : `damage = move.power` (calcul simple, pas de stats).
  final int damage;
}

/// Type de résultat final d'un combat.
enum BattleOutcomeType {
  /// Le joueur a gagné (ennemi K.O.).
  victory,

  /// Le joueur a perdu (joueur K.O.).
  defeat,

  /// Le joueur a fui avec succès.
  runaway,

  /// Le joueur a capturé avec succès un Pokémon sauvage.
  ///
  /// Le lot 13 garde ce contrat volontairement petit :
  /// - l'issue termine immédiatement le combat ;
  /// - elle ne porte pas de formule de capture canonique ;
  /// - le runtime se charge ensuite d'écrire réellement le Pokémon capturé
  ///   dans la party/save du joueur.
  captured,
}

/// Résultat final d'un combat.
///
/// Contient le type de résultat et l'état final du combat.
/// Utilisé par le runtime pour déterminer les actions post-combat
/// (marquage trainer defeated, retour overworld, etc.).
class BattleOutcome {
  /// Crée un résultat de combat.
  ///
  /// [type] - Le type de résultat (victoire, défaite, fuite).
  /// [finalState] - L'état final du combat.
  const BattleOutcome({required this.type, required this.finalState});

  /// Le type de résultat.
  final BattleOutcomeType type;

  /// L'état final du combat.
  final BattleState finalState;

  /// true si le joueur a gagné.
  bool get isVictory => type == BattleOutcomeType.victory;

  /// true si le joueur a perdu.
  bool get isDefeat => type == BattleOutcomeType.defeat;

  /// true si le joueur a fui.
  bool get isRunaway => type == BattleOutcomeType.runaway;

  /// true si le joueur a capturé le Pokémon sauvage.
  bool get isCaptured => type == BattleOutcomeType.captured;
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart

```dart
import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(BattleSetup setup) {
  // Le runtime peut maintenant fournir les PV courants réels du Pokémon actif.
  // On garde néanmoins un fallback explicite sur les PV max pour préserver les
  // anciens call sites/tests qui n'avaient pas besoin de cet état.
  final playerCurrentHp = _clampHp(
    currentHp: setup.playerPokemon.currentHp,
    maxHp: setup.playerPokemon.maxHp,
  );
  final enemyCurrentHp = _clampHp(
    currentHp: setup.enemyPokemon.currentHp,
    maxHp: setup.enemyPokemon.maxHp,
  );

  // Convertir les données de setup en combattants
  final player = BattleCombatant(
    speciesId: setup.playerPokemon.speciesId,
    level: setup.playerPokemon.level,
    currentHp: playerCurrentHp,
    maxHp: setup.playerPokemon.maxHp,
    abilityId: setup.playerPokemon.abilityId,
    moves: setup.playerPokemon.moves
        .map((m) => BattleMove(id: m.id, name: m.name, power: m.power))
        .toList(),
  );

  final enemy = BattleCombatant(
    speciesId: setup.enemyPokemon.speciesId,
    level: setup.enemyPokemon.level,
    currentHp: enemyCurrentHp,
    maxHp: setup.enemyPokemon.maxHp,
    abilityId: setup.enemyPokemon.abilityId,
    moves: setup.enemyPokemon.moves
        .map((m) => BattleMove(id: m.id, name: m.name, power: m.power))
        .toList(),
  );

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    enemy: enemy,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [getAvailableChoices] récupère les choix disponibles
/// 3. [applyChoice] applique un choix et retourne une nouvelle session
/// 4. Répéter 2-3 jusqu'à ce que [state.isFinished] soit true
/// 5. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// À appeler quand [state.phase] == [BattlePhase.playerChoice].
  ///
  /// Retourne une liste de choix :
  /// - [PlayerBattleChoiceFight] pour chaque attaque disponible (0-3)
  /// - [PlayerBattleChoiceCapture] pour capturer, uniquement en sauvage quand
  ///   le runtime a explicitement autorisé cette issue
  /// - [PlayerBattleChoiceRun] pour fuir, uniquement en combat sauvage
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // wild: [Fight(0), Fight(1), Fight(2), Fight(3), Capture(), Run()]
  /// // trainer: [Fight(0), Fight(1), Fight(2), Fight(3)]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    // Créer un choix Fight pour chaque attaque disponible
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      fightChoices.add(PlayerBattleChoiceFight(i));
    }

    // Invariants métier lots 11 + 13 :
    // - la fuite est autorisée en sauvage pour garder une vraie boucle jouable ;
    // - la capture n'est autorisée qu'en sauvage ;
    // - la capture n'est proposée que si le runtime a validé qu'elle pourra
    //   être écrite honnêtement (party avec place, pas de trainer battle) ;
    // - trainer battle : ni Run ni Capture ne doivent apparaître.
    if (!setup.isTrainerBattle && setup.allowCapture) {
      fightChoices.add(const PlayerBattleChoiceCapture());
    }

    // On filtre donc Run ici pour que l'UI/runtime n'ait pas de bouton
    // de fuite à afficher en trainer battle.
    if (!setup.isTrainerBattle) {
      fightChoices.add(const PlayerBattleChoiceRun());
    }

    return fightChoices;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (choice is PlayerBattleChoiceRun && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (choice is PlayerBattleChoiceCapture && !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _chooseEnemyAction();

    // Phase 3: Résoudre le tour
    final turnResult = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Appliquer les dégâts et vérifier l'état
    final newPlayer = _applyDamageToCombatant(
      state.player,
      turnResult.executions.where((e) => e.target == 'player'),
    );
    final newEnemy = _applyDamageToCombatant(
      state.enemy,
      turnResult.executions.where((e) => e.target == 'enemy'),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(newPlayer, newEnemy);

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: newPlayer,
      enemy: newEnemy,
      currentTurn: outcome == null ? turnResult : null,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
    );
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        return BattleActionFight(state.player.moves[choice.moveIndex]);
      }
      // Fallback: première attaque si index invalide
      return BattleActionFight(state.player.moves.first);
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    }
    // Fallback: première attaque
    return BattleActionFight(state.player.moves.first);
  }

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // IA simple : toujours utiliser la première attaque disponible
    // (pour le déterminisme, pas de random)
    if (state.enemy.moves.isNotEmpty && !state.enemy.isFainted) {
      return BattleActionFight(state.enemy.moves.first);
    }
    // Si aucune attaque, ne rien faire (cas edge)
    return const BattleActionRun();
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne un [BattleTurnResult] avec les exécutions.
  ///
  /// Ordre de résolution (déterministe, simple) :
  /// 1. Joueur exécute son attaque (si pas une fuite)
  /// 2. Ennemi exécute son attaque (si pas une fuite et encore en vie)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleTurnResult _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];

    // 1. Joueur exécute son attaque
    if (playerAction is BattleActionFight && !state.enemy.isFainted) {
      final damage = playerAction.move.power;
      executions.add(BattleMoveExecution(
        attacker: 'player',
        move: playerAction.move,
        target: 'enemy',
        damage: damage,
      ));
    }

    // 2. Ennemi exécute son attaque (seulement si encore en vie après l'attaque du joueur)
    if (enemyAction is BattleActionFight) {
      // Vérifier si l'ennemi est encore en vie après l'attaque du joueur
      var enemyHpAfterPlayerAttack = state.enemy.currentHp;
      if (executions.isNotEmpty) {
        enemyHpAfterPlayerAttack -= executions.first.damage;
      }

      if (enemyHpAfterPlayerAttack > 0) {
        final damage = enemyAction.move.power;
        executions.add(BattleMoveExecution(
          attacker: 'enemy',
          move: enemyAction.move,
          target: 'player',
          damage: damage,
        ));
      }
    }

    return BattleTurnResult(
      playerAction: playerAction,
      enemyAction: enemyAction,
      executions: executions,
    );
  }

  /// Applique les dégâts à un combattant.
  ///
  /// [combatant] - Le combattant à modifier.
  /// [executions] - Les exécutions qui ciblent ce combattant.
  ///
  /// Retourne un nouveau combattant avec les PV mis à jour.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleCombatant _applyDamageToCombatant(
    BattleCombatant combatant,
    Iterable<BattleMoveExecution> executions,
  ) {
    var newCombatant = combatant;
    for (final execution in executions) {
      newCombatant = newCombatant.withDamage(execution.damage);
    }
    return newCombatant;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Règles :
  /// - Si enemy.isFainted → victoire
  /// - Si player.isFainted → défaite
  /// - Sinon → combat continue (null)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
      BattleCombatant player, BattleCombatant enemy) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (player.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
      bool allowCapture = false,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices exposes capture in wild battle when allowed', () {
      final setup = createTestSetup(allowCapture: true);
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(4));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceCapture>());
      expect(choices[3], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('getAvailableChoices does not expose capture in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
        allowCapture: true,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait avoir pris 5 dégâts
      expect(newSession.state.enemy.currentHp, equals(20)); // 25 - 5 = 20
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait avoir pris des dégâts de la contre-attaque (power=5)
      expect(newSession.state.player.currentHp, equals(15)); // 20 - 5 = 15
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(setup);

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_flow_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession flow hardening', () {
    // Helper pour créer une session de test simple
    BattleSession createTestSession({
      int playerHp = 20,
      int enemyHp = 20,
      int playerMovePower = 5,
      int enemyMovePower = 5,
      bool isTrainerBattle = false,
      bool allowCapture = false,
    }) {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: playerHp,
          moves: [
            BattleMoveData(
                id: 'tackle', name: 'Charge', power: playerMovePower),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: enemyHp,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: enemyMovePower),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: isTrainerBattle ? 'trainer_1' : null,
        allowCapture: allowCapture,
      );
      return createBattleSession(setup);
    }

    test('applyChoice processes only one choice at a time (anti-spam)', () {
      final session = createTestSession();

      // Premier choix
      final sessionAfterChoice1 =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // La session devrait avoir évolué (PV changés, tour résolu)
      expect(sessionAfterChoice1.state.currentTurn, isNotNull);
      expect(sessionAfterChoice1.state.currentTurn!.executions.length,
          greaterThan(0));

      // Deuxième choix immédiat (simule spam)
      final sessionAfterChoice2 =
          sessionAfterChoice1.applyChoice(const PlayerBattleChoiceFight(0));

      // Le deuxième choix devrait aussi être traité normalement
      // (le vrai anti-spam est dans le runtime, pas dans la logique métier)
      expect(sessionAfterChoice2.state.currentTurn, isNotNull);
    });

    test('battle finishes after enemy faints', () {
      // Créer un ennemi avec très peu de PV
      final session = createTestSession(enemyHp: 3, playerMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait être K.O.
      expect(sessionAfterChoice.state.enemy.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isVictory, isTrue);
    });

    test('battle finishes after player faints', () {
      // Créer un joueur avec très peu de PV et un ennemi puissant
      final session = createTestSession(playerHp: 3, enemyMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait être K.O.
      expect(sessionAfterChoice.state.player.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isDefeat, isTrue);
    });

    test('runaway choice finishes the battle immediately', () {
      final session = createTestSession(playerHp: 50);

      final sessionAfterRun =
          session.applyChoice(const PlayerBattleChoiceRun());

      expect(sessionAfterRun.state.isFinished, isTrue);
      expect(sessionAfterRun.state.outcome, isNotNull);
      expect(sessionAfterRun.state.outcome!.isRunaway, isTrue);
      expect(sessionAfterRun.state.currentTurn, isNull);
      expect(sessionAfterRun.state.player.currentHp, equals(50));
      expect(sessionAfterRun.state.enemy.currentHp, equals(20));
    });

    test('capture choice finishes a wild battle immediately', () {
      final session = createTestSession(
        playerHp: 50,
        enemyHp: 18,
        allowCapture: true,
      );

      final choices = session.getAvailableChoices();
      expect(choices.whereType<PlayerBattleChoiceCapture>(), hasLength(1));

      final sessionAfterCapture =
          session.applyChoice(const PlayerBattleChoiceCapture());

      expect(sessionAfterCapture.state.isFinished, isTrue);
      expect(sessionAfterCapture.state.outcome, isNotNull);
      expect(sessionAfterCapture.state.outcome!.isCaptured, isTrue);
      expect(sessionAfterCapture.state.currentTurn, isNull);
      expect(sessionAfterCapture.state.player.currentHp, equals(50));
      expect(sessionAfterCapture.state.enemy.currentHp, equals(18));
    });

    test('multiple turns can be played sequentially', () {
      final session = createTestSession(
          playerHp: 50, enemyHp: 50, playerMovePower: 5, enemyMovePower: 5);

      var currentSession = session;
      var turnCount = 0;

      // Jouer plusieurs tours jusqu'à la fin
      while (!currentSession.state.isFinished && turnCount < 20) {
        currentSession =
            currentSession.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }

      // Le combat devrait se terminer
      expect(currentSession.state.isFinished, isTrue);
      expect(turnCount, lessThan(20)); // Ne devrait pas prendre 20 tours
    });

    test('trainer battle setup creates correct session', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('forced runaway choice is rejected in trainer battles', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.state.outcome, isNull);
    });

    test('forced capture choice is rejected in trainer battles', () {
      final session = createTestSession(
        isTrainerBattle: true,
        allowCapture: true,
      );

      expect(
        () => session.applyChoice(const PlayerBattleChoiceCapture()),
        throwsA(isA<StateError>()),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.state.outcome, isNull);
    });

    test('capture choice is rejected when capture is not allowed', () {
      final session = createTestSession(
        allowCapture: false,
      );

      expect(
          session.getAvailableChoices().whereType<PlayerBattleChoiceCapture>(),
          isEmpty);
      expect(
        () => session.applyChoice(const PlayerBattleChoiceCapture()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('BattleOutcome types', () {
    test('victory outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 100)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isVictory, isTrue);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('defeat outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: [BattleMoveData(id: 'psychic', name: 'Psyko', power: 100)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isDefeat, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('runaway outcome exposes a real runaway result', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 50,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession = session.applyChoice(const PlayerBattleChoiceRun());

      expect(resultSession.state.isFinished, isTrue);
      expect(resultSession.state.outcome, isNotNull);
      expect(resultSession.state.outcome!.isRunaway, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.player.currentHp, equals(50));
      expect(resultSession.state.enemy.currentHp, equals(20));
    });

    test('captured outcome exposes a real capture result', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 50,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          abilityId: 'water-absorb',
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
        allowCapture: true,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceCapture());

      expect(resultSession.state.isFinished, isTrue);
      expect(resultSession.state.outcome, isNotNull);
      expect(resultSession.state.outcome!.isCaptured, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
      expect(resultSession.state.enemy.abilityId, equals('water-absorb'));
    });
  });
}
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'battle_start_request.dart';
import 'runtime_map_bundle.dart';

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
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6,
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'story_flags_manager.dart';

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
/// - le lot 13 ne gère que la capture sauvage minimale ;
/// - aucun sac, aucune récompense, aucun switch n'est ouvert ici ;
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

    // Garde-fou lot 13 :
    // le moteur ne doit normalement jamais proposer Capture si la party est
    // pleine, mais on revalide ici pour qu'un call site forcé ne fasse jamais
    // "disparaître" un Pokémon capturé faute de boîte/PC implémentés.
    if (stateWithPlayerHp.party.members.length >= 6) {
      throw StateError(
        'Impossible d’ajouter un Pokémon capturé : la party du joueur est pleine.',
      );
    }

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

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Composant UI d'overlay de combat.
///
/// Affiche l'état courant du combat et permet au joueur de choisir une action.
/// Ne contient AUCUNE logique métier de combat — pure UI.
///
/// La logique métier est dans `map_battle` (BattleSession).
/// Ce composant se contente de :
/// - Afficher les PV des combattants
/// - Afficher les choix disponibles
/// - Notifier le runtime du choix du joueur via [onPlayerChoice]
///
/// **Interaction** : L'utilisateur peut cliquer sur un choix pour le sélectionner.
/// Le clic appelle [onPlayerChoice] avec le choix correspondant.
///
/// **IMPORTANT** : Ce composant stocke une référence mutable vers la session
/// courante. Quand le runtime appelle [updateState()], la session interne
/// est mise à jour pour refléter le nouvel état. Toutes les méthodes d'affichage
/// lisent [session] qui est donc toujours à jour.
class BattleOverlayComponent extends PositionComponent with TapCallbacks {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// **Mutable** : mise à jour par [updateState()] pour refléter le nouvel état.
  /// Toutes les méthodes d'affichage lisent cette propriété, donc l'UI est
  /// toujours synchronisée avec l'état réel du combat.
  BattleSession _session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;

  /// Composant de texte pour afficher le résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts.
  TextComponent? _turnResultText;

  /// Composants de choix (pour mise à jour dynamique).
  /// Chaque composant est associé à un index de choix.
  final List<_ChoiceComponent> _choiceComponents = [];

  /// Index du choix actuellement sélectionné.
  ///
  /// Utilisé pour la navigation clavier (↑/↓) et pour afficher visuellement
  /// le choix sélectionné avec un style différent.
  ///
  /// Invariant : `_selectedIndex` est toujours entre 0 et `_choiceComponents.length - 1`.
  int _selectedIndex = 0;

  /// Composant de surbrillance pour le choix sélectionné.
  ///
  /// Affiché derrière le choix sélectionné pour le mettre en évidence visuellement.
  RectangleComponent? _selectionHighlight;

  @override
  Future<void> onLoad() async {
    // Fond sombre
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    // Panneau principal
    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    _panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(_panel!);

    // Bordure du panneau
    final panelBorder = RectangleComponent(
      size: _panel!.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    _panel!.add(panelBorder);

    // Titre
    final title = TextComponent(
      text: _getTitleForSession(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    _panel!.add(title);

    // PV du joueur
    _playerHpText = TextComponent(
      text: _getPlayerHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_playerHpText!);

    // PV de l'ennemi
    _enemyHpText = TextComponent(
      text: _getEnemyHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_enemyHpText!);

    // Titre des choix
    final choicesTitle = TextComponent(
      text: 'Que doit faire le joueur ?',
      anchor: Anchor.topLeft,
      position: Vector2(22, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(choicesTitle);

    // Choix disponibles
    _renderChoices();

    // Astuce
    final hint = TextComponent(
      text: 'Utilisez les flèches ↑/↓ et E pour choisir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(hint);
  }

  /// Met à jour l'affichage avec un nouvel état de session.
  ///
  /// [newSession] - La nouvelle session avec l'état mis à jour.
  ///
  /// **IMPORTANT** : Cette méthode met à jour [_session] pour que toutes les
  /// méthodes d'affichage (_getChoiceText, etc.) lisent le bon état.
  ///
  /// Cette méthode gère aussi la cohérence de la sélection :
  /// - Si le combat est fini, la sélection est désactivée
  /// - Si la sélection est hors bornes (moins de choix), elle est clampée
  /// - Si un tour est en cours, affiche le résultat du tour (attaques + dégâts)
  void updateState(BattleSession newSession) {
    // Mettre à jour la session interne — CRITIQUE pour la cohérence
    _session = newSession;

    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpText();
    _enemyHpText?.text = _getEnemyHpText();

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.getAvailableChoices();
      if (_selectedIndex >= choices.length) {
        _selectedIndex = choices.length - 1;
      }
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      // Re-render pour mettre à jour les choix et la surbrillance
      _renderChoices();
    }
  }

  /// Met à jour l'affichage du résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts infligés.
  void _updateTurnResult() {
    // Supprimer l'ancien texte de résultat du tour
    _turnResultText?.removeFromParent();
    _turnResultText = null;

    final turnResult = _session.state.currentTurn;
    if (turnResult == null) {
      return;
    }

    // Construire le texte du résultat du tour
    final lines = <String>[];
    for (final execution in turnResult.executions) {
      final attacker = execution.attacker == 'player' ? 'Joueur' : 'Ennemi';
      lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts');
    }

    if (lines.isEmpty) {
      return;
    }

    // Afficher le résultat du tour
    _turnResultText = TextComponent(
      text: lines.join('\n'),
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_turnResultText!);
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
      BattleOutcomeType.captured => 'Capture réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory || outcome.isCaptured
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  ///
  /// Cette méthode :
  /// 1. Récupère les choix disponibles depuis [_session]
  /// 2. Crée un composant visuel pour chaque choix
  /// 3. Ajoute un composant de surbrillance pour le choix sélectionné
  /// 4. Met à jour [_selectionHighlight] pour le rendu visuel
  void _renderChoices() {
    // Lit [_session] qui est toujours à jour grâce à updateState()
    final choices = _session.getAvailableChoices();
    var y = 190.0;

    // Nettoyer les anciens composants de choix
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    // Nettoyer l'ancienne surbrillance
    _selectionHighlight?.removeFromParent();
    _selectionHighlight = null;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(choice);
      final choiceComponent = _ChoiceComponent(
        choice: choice,
        text: text,
        position: Vector2(22, y),
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);

      // Créer la surbrillance pour le choix sélectionné
      if (i == _selectedIndex) {
        _selectionHighlight = RectangleComponent(
          size: Vector2(280, 28),
          position: Vector2(24, y + 2),
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x40FFFFFF) // Blanc semi-transparent
            ..style = PaintingStyle.fill,
          priority: 2,
        );
        _panel!.add(_selectionHighlight!);
      }

      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getChoiceText(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  /// Retourne le titre pour la session.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getTitleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getPlayerHpText() {
    return 'Joueur: ${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi: ${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
  }

  /// Déplace la sélection vers le haut (choix précédent).
  ///
  /// Si la sélection est déjà au premier choix, reste au premier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      debugPrint('[battle-overlay] moveSelectionUp: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionUp: already at first choice (index=$_selectedIndex)');
    return false;
  }

  /// Déplace la sélection vers le bas (choix suivant).
  ///
  /// Si la sélection est déjà au dernier choix, reste au dernier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionDown() {
    if (_selectedIndex < _choiceComponents.length - 1) {
      _selectedIndex++;
      debugPrint(
          '[battle-overlay] moveSelectionDown: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionDown: already at last choice (index=$_selectedIndex, max=${_choiceComponents.length - 1})');
    return false;
  }

  /// Retourne le choix actuellement sélectionné.
  ///
  /// Retourne null si aucun choix n'est disponible.
  PlayerBattleChoice? getSelectedChoice() {
    if (_choiceComponents.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _choiceComponents.length) {
      return null;
    }
    return _choiceComponents[_selectedIndex].choice;
  }

  /// Valide le choix actuellement sélectionné.
  ///
  /// Appelle [onPlayerChoice] avec le choix sélectionné.
  ///
  /// Retourne true si un choix a été validé, false si aucun choix n'est disponible.
  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice != null) {
      debugPrint(
          '[battle-overlay] validateSelectedChoice: choice=$selectedChoice');
      onPlayerChoice(selectedChoice);
      return true;
    }
    debugPrint('[battle-overlay] validateSelectedChoice: no choice selected');
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Vérifier si un choix a été cliqué
    final tapPos = event.localPosition;
    for (var i = 0; i < _choiceComponents.length; i++) {
      final choiceComponent = _choiceComponents[i];
      if (choiceComponent.containsPoint(tapPos)) {
        // Mettre à jour la sélection visuelle
        _selectedIndex = i;
        _renderChoices();

        // Choix cliqué — notifier le runtime
        onPlayerChoice(choiceComponent.choice);
        return;
      }
    }
  }
}

/// Composant de choix avec référence au choix associé.
///
/// Permet de détecter les clics sur un choix spécifique et de notifier
/// le runtime via [onPlayerChoice].
class _ChoiceComponent extends PositionComponent {
  _ChoiceComponent({
    required this.choice,
    required String text,
    required Vector2 position,
  }) : super(
          size: Vector2(300, 32),
          position: position,
          anchor: Anchor.topLeft,
        ) {
    // Ajouter le texte du choix
    add(TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  /// Le choix associé à ce composant.
  final PlayerBattleChoice choice;

  /// Vérifie si un point est dans les bounds de ce composant.
  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart

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

GameState _playerStateForTests() {
  return const GameState(
    saveId: 'save-test',
    party: PlayerParty(
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_outcome_apply_test.dart

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
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
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
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart

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
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(updatedState.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });
  });
}

GameState _playerState() {
  return const GameState(
    saveId: 'wild-flow-save',
    party: PlayerParty(
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/file_game_save_repository_test.dart

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
