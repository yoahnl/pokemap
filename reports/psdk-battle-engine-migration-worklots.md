# Pokemon SDK Battle Engine Migration Worklots

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` or `superpowers:executing-plans`
> to execute these lots. Each lot is intended to be a reviewable PR boundary.

**Goal:** Replace the current Showdown-inspired battle system with a pure Dart,
clean architecture adaptation of Pokemon SDK battle logic.

**Architecture:** `map_battle` owns the deterministic battle simulation.
`map_core` owns serializable Pokemon SDK Studio data contracts. `map_editor`
imports and normalizes Studio data. `map_runtime` maps game state to battle
setup and consumes battle timelines for UI/animations.

**Tech Stack:** Dart 3, Flutter/Flame in runtime/editor only, Freezed/JSON in
`map_core`, plain Dart in `map_battle`, Pokemon SDK Ruby scripts as mechanical
reference, Pokemon SDK Studio JSON as data source.

---

## 0. Regles communes a tous les lots

### Frontieres non negociables

- `packages/map_battle` reste pur Dart : aucun import Flutter, Flame, editor,
  runtime ou filesystem.
- `packages/map_core` reste un contrat de donnees : aucune execution de regles
  combat.
- `packages/map_runtime` ne reconstruit pas les regles : il construit le setup,
  envoie les decisions, consomme la timeline.
- `packages/map_editor` ne connait pas les details d'execution de `map_battle` :
  il importe et edite des catalogues.
- Les animations deja faites ne sont pas refaites ici. Le nouveau moteur doit
  seulement produire une timeline assez precise.
- Aucun fallback Showdown ne doit etre conserve dans le nouveau chemin produit.

### Definition d'un lot termine

Chaque lot doit livrer :

- les fichiers listes dans le lot ;
- les tests listes dans le lot ;
- une compilation/analyse ciblee ;
- une note de migration courte dans le commit ou la PR ;
- aucun changement opportuniste hors perimetre.

### Strategie de compatibilite

Pendant la migration, on peut garder des facades temporaires pour que le runtime
compile, mais elles doivent etre nommees explicitement comme adaptateurs de
migration. Exemple autorise :

```dart
/// Temporary facade used while the runtime moves to the PSDK engine.
/// It must not contain battle rules.
final class BattleSession {
  BattleSession(this._engine);

  final BattleEngine _engine;

  BattleTurnResult submit(BattleDecision decision) {
    return _engine.submit(decision);
  }
}
```

Exemple interdit :

```dart
// Interdit : recree une regle de move dans runtime ou dans une facade legacy.
if (move.id == 'thunder_wave') {
  target.status = BattleStatus.paralysis;
}
```

---

## Lot 1 - Contrats PSDK Studio dans `map_core`

### But

Remplacer les champs Showdown du modele `PokemonMove` par des contrats issus de
Pokemon SDK Studio : `dbSymbol`, `battleEngineMethod`, target Studio, flags,
stat mods et statuts. Ce lot ne change pas encore le moteur.

### Fichiers a modifier

- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/pokemon_move_test.dart`

### Fichiers generes a modifier via build_runner

- `packages/map_core/lib/src/models/pokemon_move.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move.g.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.g.dart`

### Fichiers a supprimer a la fin du lot

Aucun fichier entier. Les champs Showdown doivent disparaitre des modeles
publics.

### Logique a mettre en place

- `PokemonMove.source` devient `pokemon_sdk_studio` pour les moves importes.
- `PokemonMoveSourceRefs` ne reference plus Showdown.
- Le move expose directement la cle d'execution PSDK :
  `battleEngineMethod`.
- Le target utilise la taxonomie Studio brute ou normalisee, pas la taxonomie
  Showdown.
- Les flags ne declenchent pas la logique eux-memes. Ils informent le moteur.
- `PokemonMoveEffect` cesse d'etre le coeur comportemental. Il peut rester un
  payload serialisable d'affichage/import, mais l'execution viendra du registre
  `BattleMoveBehavior` dans `map_battle`.

### Code a mettre en place

Exemple de structure cible dans
`packages/map_core/lib/src/models/pokemon_move.dart` :

```dart
@freezed
class PokemonMove with _$PokemonMove {
  const factory PokemonMove({
    required String id,
    required String name,
    required String dbSymbol,
    required String type,
    required PokemonMoveCategory category,
    required int power,
    required int accuracy,
    required int pp,
    required int priority,
    required String battleEngineMethod,
    required PokemonMoveAimedTarget battleEngineAimedTarget,
    @Default(0) int criticalRate,
    @Default(100) int effectChance,
    @Default(PokemonMoveFlags()) PokemonMoveFlags flags,
    @Default(<PokemonMoveBattleStageMod>[])
    List<PokemonMoveBattleStageMod> battleStageMods,
    @Default(<PokemonMoveStatus>[]) List<PokemonMoveStatus> moveStatuses,
    @Default('pokemon_sdk_studio') String source,
    PokemonMoveSourceRefs? sourceRefs,
  }) = _PokemonMove;

  factory PokemonMove.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveFromJson(json);
}

@freezed
class PokemonMoveSourceRefs with _$PokemonMoveSourceRefs {
  const factory PokemonMoveSourceRefs({
    required String psdkStudioMoveId,
    required String psdkDbSymbol,
    required String psdkBattleEngineMethod,
    String? psdkScriptClass,
    String? psdkScriptPath,
    String? psdkAnimationId,
  }) = _PokemonMoveSourceRefs;

  factory PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveSourceRefsFromJson(json);
}
```

Exemple de flags Studio :

```dart
@freezed
class PokemonMoveFlags with _$PokemonMoveFlags {
  const factory PokemonMoveFlags({
    @Default(false) bool direct,
    @Default(false) bool blocable,
    @Default(false) bool mirrorMove,
    @Default(false) bool gravity,
    @Default(false) bool punch,
    @Default(false) bool soundAttack,
    @Default(false) bool slicingAttack,
    @Default(false) bool wind,
    @Default(false) bool heal,
    @Default(false) bool bite,
    @Default(false) bool pulse,
    @Default(false) bool powder,
    @Default(false) bool dance,
    @Default(false) bool mental,
    @Default(false) bool ballistics,
    @Default(false) bool unfreeze,
    @Default(false) bool authentic,
  }) = _PokemonMoveFlags;

  factory PokemonMoveFlags.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveFlagsFromJson(json);
}
```

Exemple de target :

```dart
enum PokemonMoveAimedTarget {
  adjacentAlly,
  adjacentAllyOrSelf,
  adjacentFoe,
  allAdjacent,
  allAdjacentFoes,
  allBattlers,
  allFoes,
  allAllies,
  anyFoe,
  bank,
  randomFoe,
  self,
  user,
  userSide,
  foeSide,
  none,
}
```

### Pourquoi ce lot existe

Tant que `map_core` garde `showdownMoveId` et des hooks Showdown, tous les
autres paquets sont forces de raisonner avec l'ancien modele. Ce lot coupe la
source du probleme sans encore toucher a l'execution.

### Comment le mettre en place

1. Modifier les classes Freezed.
2. Adapter les tests de serialization/deserialization.
3. Regenerer le code.
4. Corriger les imports barrels.
5. Ne pas modifier le runtime dans ce lot, sauf compilation stricte si un champ
   renomme casse une reference directe.

### Tests et commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/pokemon_move_test.dart
dart analyze
```

### Points d'attention

- Ne pas supprimer les anciens champs des JSON projet sans migration de lecture.
  Si des fixtures les contiennent encore, ajouter une lecture tolerante qui les
  ignore.
- Garder les `id` internes existants si des fixtures runtime les referencent.
  `dbSymbol` devient la cle PSDK, pas forcement le remplacement immediat de
  tous les `id` historiques.

---

## Lot 2 - Source locale Pokemon SDK Studio dans `map_editor`

### But

Remplacer le fetch/import Showdown par une source locale Pokemon SDK Studio qui
lit `Data/Studio`. Ce lot fournit les payloads bruts et les convertisseurs, sans
encore refaire toute l'UI.

### Fichiers a creer

- `packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_source.dart`
- `packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_payload.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_species_converter.dart`
- `packages/map_editor/test/application/services/pokemon_sdk_move_catalog_converter_test.dart`
- `packages/map_editor/test/infrastructure/external/pokemon_sdk_studio_source_test.dart`

### Fichiers a modifier

- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`
- `packages/map_editor/test/application/services/external_pokemon_catalog_normalizer_test.dart`

### Fichiers a supprimer plus tard, pas dans ce lot si l'UI compile encore avec eux

- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`

### Logique a mettre en place

- Lire un dossier racine PSDK qui contient `Data/Studio`.
- Charger au minimum :
  - `Data/Studio/moves/*.json`
  - `Data/Studio/abilities/*.json`
  - `Data/Studio/items/*.json`
  - `Data/Studio/types/*.json`
  - `Data/Studio/pokemon/*.json`
- Retourner des payloads bruts typables.
- Convertir un move Studio en `PokemonMove` du Lot 1.
- Ne pas injecter de logique de combat dans le converter.

### Code a mettre en place

Source filesystem :

```dart
import 'dart:convert';
import 'dart:io';

final class PokemonSdkStudioSource {
  const PokemonSdkStudioSource();

  Future<PokemonSdkStudioProjectPayload> loadProject(String projectRootPath) async {
    final studioDir = Directory('$projectRootPath/Data/Studio');
    if (!studioDir.existsSync()) {
      throw const PokemonSdkStudioSourceException(
        'Pokemon SDK Studio folder not found: expected Data/Studio',
      );
    }

    return PokemonSdkStudioProjectPayload(
      moves: await _readJsonDirectory('${studioDir.path}/moves'),
      abilities: await _readJsonDirectory('${studioDir.path}/abilities'),
      items: await _readJsonDirectory('${studioDir.path}/items'),
      types: await _readJsonDirectory('${studioDir.path}/types'),
      pokemon: await _readJsonDirectory('${studioDir.path}/pokemon'),
    );
  }

  Future<List<Map<String, dynamic>>> _readJsonDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      return const <Map<String, dynamic>>[];
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final payloads = <Map<String, dynamic>>[];
    for (final file in files) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        payloads.add(decoded);
      } else {
        throw PokemonSdkStudioSourceException(
          'Invalid Studio JSON object: ${file.path}',
        );
      }
    }
    return payloads;
  }
}

final class PokemonSdkStudioSourceException implements Exception {
  const PokemonSdkStudioSourceException(this.message);
  final String message;

  @override
  String toString() => message;
}
```

Payload :

```dart
final class PokemonSdkStudioProjectPayload {
  const PokemonSdkStudioProjectPayload({
    required this.moves,
    required this.abilities,
    required this.items,
    required this.types,
    required this.pokemon,
  });

  final List<Map<String, dynamic>> moves;
  final List<Map<String, dynamic>> abilities;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> types;
  final List<Map<String, dynamic>> pokemon;
}
```

Converter move :

```dart
final class PokemonSdkMoveCatalogConverter {
  const PokemonSdkMoveCatalogConverter();

  PokemonMove convert(Map<String, dynamic> json) {
    final dbSymbol = _string(json, 'dbSymbol', fallbackKey: 'db_symbol');
    final method = _string(
      json,
      'battleEngineMethod',
      fallbackKey: 'battle_engine_method',
    );

    return PokemonMove(
      id: dbSymbol,
      dbSymbol: dbSymbol,
      name: _localizedName(json, fallback: dbSymbol),
      type: _string(json, 'type'),
      category: _category(json['category']),
      power: _int(json, 'power'),
      accuracy: _int(json, 'accuracy'),
      pp: _int(json, 'pp'),
      priority: _int(json, 'priority'),
      criticalRate: _int(json, 'criticalRate', fallbackKey: 'critical_rate'),
      effectChance: _int(json, 'effectChance', fallbackKey: 'effect_chance'),
      battleEngineMethod: method,
      battleEngineAimedTarget: _aimedTarget(
        _string(
          json,
          'battleEngineAimedTarget',
          fallbackKey: 'battle_engine_aimed_target',
        ),
      ),
      flags: _flags(json),
      battleStageMods: _stageMods(json),
      moveStatuses: _statuses(json),
      sourceRefs: PokemonMoveSourceRefs(
        psdkStudioMoveId: _string(json, 'id', fallback: dbSymbol),
        psdkDbSymbol: dbSymbol,
        psdkBattleEngineMethod: method,
      ),
    );
  }
}
```

### Pourquoi ce lot existe

Le moteur PSDK ne fonctionne pas avec un snapshot Showdown. Les scripts Ruby
decrivent les comportements, mais les catalogues reels viennent de Studio. Ce
lot donne au projet une source de donnees coherent avec PSDK.

### Comment le mettre en place

- Garder le repository externe actuel en facade si beaucoup de code depend de
  lui.
- Ajouter les methodes PSDK au port existant.
- Faire passer les tests converters avant de brancher les use cases.
- Ne pas toucher au moteur de combat dans ce lot.

### Tests et commandes

```bash
cd packages/map_editor
flutter test test/infrastructure/external/pokemon_sdk_studio_source_test.dart
flutter test test/application/services/pokemon_sdk_move_catalog_converter_test.dart
flutter analyze
```

### Points d'attention

- Les noms JSON PSDK peuvent etre camelCase ou snake_case selon export/source.
  Le converter doit accepter les deux pour faciliter les fixtures.
- Garder les messages d'erreur avec le chemin du fichier lu. Les imports
  Studio echoueront sinon de facon penible.

---

## Lot 3 - Synchronisation et bootstrap des catalogues PSDK

### But

Brancher les use cases editor sur la source PSDK et produire un catalogue moves
projet utilisable par runtime/tests.

### Fichiers a creer

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_sdk_project_use_case.dart`
- `packages/map_editor/tool/export_pokemon_sdk_studio_catalog.dart`
- `packages/map_editor/test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart`

### Fichiers a modifier

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`
- `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`

### Fichiers a supprimer a la fin du lot ou du Lot 19

- Les seeds Showdown embarques, si le catalogue PSDK couvre les fixtures.
- Les warnings `showdown_callback:*`.

### Logique a mettre en place

- Un use case prend un chemin de projet PSDK.
- Il charge `Data/Studio`.
- Il convertit les moves.
- Il merge par `dbSymbol`, pas par `showdownMoveId`.
- Il ecrit les catalogues projet existants dans le format attendu par
  `map_core`.
- Le bootstrap minimal vient de PSDK Studio, pas de Showdown.

### Code a mettre en place

Use case :

```dart
final class SyncPokemonSdkMovesCatalogUseCase {
  const SyncPokemonSdkMovesCatalogUseCase({
    required PokemonSdkStudioSource source,
    required PokemonSdkMoveCatalogConverter converter,
    required PokemonProjectCatalogRepository repository,
  })  : _source = source,
        _converter = converter,
        _repository = repository;

  final PokemonSdkStudioSource _source;
  final PokemonSdkMoveCatalogConverter _converter;
  final PokemonProjectCatalogRepository _repository;

  Future<SyncPokemonSdkMovesCatalogResult> call({
    required String psdkProjectRootPath,
    required String projectRootPath,
  }) async {
    final studio = await _source.loadProject(psdkProjectRootPath);
    final moves = studio.moves.map(_converter.convert).toList()
      ..sort((a, b) => a.dbSymbol.compareTo(b.dbSymbol));

    await _repository.writeMovesCatalog(
      projectRootPath: projectRootPath,
      moves: moves,
    );

    return SyncPokemonSdkMovesCatalogResult(
      importedMoves: moves.length,
      source: 'pokemon_sdk_studio',
    );
  }
}

final class SyncPokemonSdkMovesCatalogResult {
  const SyncPokemonSdkMovesCatalogResult({
    required this.importedMoves,
    required this.source,
  });

  final int importedMoves;
  final String source;
}
```

CLI export :

```dart
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/export_pokemon_sdk_studio_catalog.dart '
      '<psdk-project-root> <output-project-root>',
    );
    exitCode = 64;
    return;
  }

  final useCase = SyncPokemonSdkMovesCatalogUseCase(
    source: const PokemonSdkStudioSource(),
    converter: const PokemonSdkMoveCatalogConverter(),
    repository: FilePokemonProjectCatalogRepository(),
  );

  final result = await useCase(
    psdkProjectRootPath: args[0],
    projectRootPath: args[1],
  );
  stdout.writeln('Imported ${result.importedMoves} PSDK moves');
}
```

### Pourquoi ce lot existe

Le moteur ne peut pas etre teste correctement si les fixtures continuent de
porter des moves Showdown. Ce lot rend le catalogue PSDK disponible avant le
cutover moteur.

### Comment le mettre en place

- Implementer le chemin PSDK en parallele du chemin historique si l'UI ne peut
  pas basculer tout de suite.
- Adapter le bootstrap seed avec un petit set PSDK : `tackle`,
  `thunder_wave`, `vine_whip`, `protect`, `stealth_rock`, `hyper_beam`.
- Mettre a jour la fixture golden runtime uniquement si elle compile avec les
  nouveaux champs du Lot 1.

### Tests et commandes

```bash
cd packages/map_editor
flutter test test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart
dart run tool/export_pokemon_sdk_studio_catalog.dart \
  ../../pokémon_sdk_test_project \
  ../../examples/playable_runtime_host/golden_battle_slice
```

### Points d'attention

- Les fixtures avec accents dans le chemin `pokémon_sdk_test_project` doivent
  etre manipulees avec des APIs de chemin Dart, pas concatenees de facon fragile
  dans les tests.
- Si le repository de projet existant n'a pas encore `writeMovesCatalog`, ce lot
  doit l'ajouter avec un test de roundtrip JSON.

---

## Lot 4 - Squelette clean architecture de `map_battle`

### But

Poser la nouvelle architecture interne sans porter toutes les regles. Ce lot
cree les couches `domain`, `application`, `data` et une facade publique stable.

### Fichiers a creer

- `packages/map_battle/lib/src/application/battle_engine.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/application/battle_session_facade.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/battle/battle_setup.dart`
- `packages/map_battle/lib/src/domain/battle/battle_outcome.dart`
- `packages/map_battle/lib/src/domain/decision/battle_decision.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline.dart`
- `packages/map_battle/test/psdk_engine_smoke_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`

### Fichiers a supprimer plus tard

Aucun dans ce lot. Les fichiers legacy restent tant que le runtime n'est pas
branche sur le nouveau moteur.

### Logique a mettre en place

- `BattleEngine` devient le point d'entree.
- `BattleContext` est mutable et interne a `map_battle`.
- `BattleStateSnapshot` ou `BattlePublicState` est immuable en sortie.
- `BattleTimeline` est la seule sortie descriptive pour runtime.
- `BattleTurnRunner` execute un tour a partir de decisions.
- La facade historique peut deleguer au nouveau moteur, sans regle interne.

### Code a mettre en place

Engine :

```dart
final class BattleEngine {
  BattleEngine({
    required BattleSetup setup,
    required BattleCatalogs catalogs,
    required BattleRngStreams rng,
    BattleAiPolicy? aiPolicy,
  }) : _context = BattleContext.fromSetup(
          setup: setup,
          catalogs: catalogs,
          rng: rng,
          aiPolicy: aiPolicy ?? const NoopBattleAiPolicy(),
        );

  final BattleContext _context;

  BattleDecisionRequest get currentRequest {
    return BattleDecisionRequestBuilder(_context).build();
  }

  BattleTurnResult submit(BattleDecision decision) {
    final runner = BattleTurnRunner(_context);
    return runner.run(decision);
  }

  BattlePublicState snapshot() => BattlePublicState.fromContext(_context);
}
```

Turn runner :

```dart
final class BattleTurnRunner {
  BattleTurnRunner(this._context);

  final BattleContext _context;

  BattleTurnResult run(BattleDecision playerDecision) {
    final timeline = BattleTimelineBuilder();
    final actions = _context.actionFactory.createTurnActions(playerDecision);
    final sorted = _context.actionScheduler.sort(actions);

    for (final action in sorted) {
      if (!_context.canBattleContinue) {
        break;
      }
      action.execute(_context, timeline);
    }

    _context.handlers.endTurn.process(timeline);
    final outcome = _context.handlers.battleEnd.resolve();

    return BattleTurnResult(
      state: BattlePublicState.fromContext(_context),
      timeline: timeline.build(),
      outcome: outcome,
      nextRequest: outcome.isFinished
          ? null
          : BattleDecisionRequestBuilder(_context).build(),
    );
  }
}
```

### Pourquoi ce lot existe

On ne peut pas porter PSDK proprement en ajoutant encore des champs au moteur
actuel. Ce lot met en place les points de rattachement pour les lots suivants.

### Comment le mettre en place

- Creer les nouveaux fichiers sans supprimer le legacy.
- Exporter les nouveaux types depuis `map_battle.dart`.
- Ecrire un smoke test qui instancie un combat minimal et obtient une
  `BattleDecisionRequest`.
- Ne pas brancher encore le runtime.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_engine_smoke_test.dart
dart analyze
```

### Points d'attention

- Ne pas creer une architecture trop generique. Les couches doivent servir les
  concepts PSDK : Logic, Actions, Handlers, Effects, Move.
- `BattleContext` peut etre mutable car il est interne. Les sorties publiques
  doivent rester faciles a tester.

---

## Lot 5 - Battlers, banks, parties et topology PSDK

### But

Remplacer le modele `player/enemy` par le modele PSDK : bank, position, party,
slot actif, reserves et battler mutable.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/domain/battle/battle_bank.dart`
- `packages/map_battle/lib/src/domain/battle/battle_party.dart`
- `packages/map_battle/lib/src/domain/battle/battle_slot.dart`
- `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- `packages/map_battle/lib/src/domain/battle/battle_stats.dart`
- `packages/map_battle/test/psdk_battle_topology_test.dart`
- `packages/map_battle/test/psdk_battler_state_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/battle/battle_setup.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_topology.dart`

### Fichiers a supprimer plus tard

- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_topology.dart`

La suppression se fait quand le runtime ne depend plus des types legacy.

### Logique a mettre en place

- Un combat contient plusieurs banks.
- Une bank contient une ou plusieurs parties.
- Une position active reference un battler.
- Un battler connait :
  - `bank`
  - `position`
  - `partyId`
  - `partyIndex`
  - PV courants/max
  - stats calculees
  - stages
  - moves instances
  - ability
  - held item
  - effects
  - histories
- La topology sait calculer allies, foes, adjacent foes, alive battlers,
  battlers actifs, slots vides et remplacements possibles.

### Code a mettre en place

Battler ref :

```dart
final class BattleSlotRef {
  const BattleSlotRef({
    required this.bank,
    required this.position,
  });

  final int bank;
  final int position;

  @override
  bool operator ==(Object other) =>
      other is BattleSlotRef &&
      other.bank == bank &&
      other.position == position;

  @override
  int get hashCode => Object.hash(bank, position);
}
```

Battler :

```dart
final class BattleBattler {
  BattleBattler({
    required this.instanceId,
    required this.speciesId,
    required this.displayName,
    required this.bank,
    required this.position,
    required this.partyId,
    required this.partyIndex,
    required this.level,
    required this.types,
    required this.stats,
    required this.hp,
    required this.maxHp,
    required this.moves,
    required this.abilityId,
    required this.heldItemId,
    BattleStatStages? stages,
    BattleEffectStack? effects,
  })  : stages = stages ?? BattleStatStages.neutral(),
        effects = effects ?? BattleEffectStack();

  final String instanceId;
  final String speciesId;
  final String displayName;
  final int bank;
  int position;
  final int partyId;
  final int partyIndex;
  final int level;
  BattleTypes types;
  BattleComputedStats stats;
  int hp;
  int maxHp;
  final List<BattleMoveInstance> moves;
  String? abilityId;
  String? heldItemId;
  final BattleStatStages stages;
  final BattleEffectStack effects;
  final BattleBattlerHistory history = BattleBattlerHistory();

  bool get isAlive => hp > 0;
  bool get isKo => hp <= 0;
  BattleSlotRef get slot => BattleSlotRef(bank: bank, position: position);
}
```

Topology :

```dart
final class BattleTopology {
  const BattleTopology(this._banks);

  final List<BattleBank> _banks;

  Iterable<BattleBattler> get allBattlers sync* {
    for (final bank in _banks) {
      for (final slot in bank.slots) {
        final battler = slot.activeBattler;
        if (battler != null) {
          yield battler;
        }
      }
    }
  }

  Iterable<BattleBattler> get aliveBattlers =>
      allBattlers.where((battler) => battler.isAlive);

  Iterable<BattleBattler> foesOf(BattleBattler battler) {
    return aliveBattlers.where((other) => other.bank != battler.bank);
  }

  Iterable<BattleBattler> alliesOf(BattleBattler battler) {
    return aliveBattlers.where(
      (other) => other.bank == battler.bank && other != battler,
    );
  }

  Iterable<BattleBattler> adjacentFoesOf(BattleBattler battler) {
    return foesOf(battler).where(
      (other) => (other.position - battler.position).abs <= 1,
    );
  }
}
```

### Pourquoi ce lot existe

PSDK trie, cible, switch et applique les effects avec `bank` et `position`.
Garder une structure `player/enemy` empecherait de porter proprement doubles,
targets, hazards, switch force et effets de side.

### Comment le mettre en place

- Construire la topology depuis `BattleSetup`.
- Adapter les tests existants de topology vers le nouveau modele.
- Garder des helpers `playerActive` et `opponentActive` uniquement comme vues
  pour le runtime singles.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_battle_topology_test.dart
dart test test/psdk_battler_state_test.dart
```

### Points d'attention

- Ne pas encoder "player = bank 0, enemy = bank 1" partout. Cela peut etre une
  convention de setup, pas une hypothese dans chaque handler.
- `partyIndex` ne doit pas changer quand un Pokemon switch. `position` change.

---

## Lot 6 - RNG streams et timeline riche

### But

Porter le modele PSDK de RNG separees et remplacer les buckets de resolution
par une timeline typable, consommable par runtime/animations.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/rng/battle_rng_streams.dart`
- `packages/map_battle/lib/src/domain/rng/battle_seeded_rng.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_builder.dart`
- `packages/map_battle/test/psdk_rng_streams_test.dart`
- `packages/map_battle/test/psdk_timeline_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_rng.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`

### Fichiers a supprimer plus tard

- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_rng.dart`

### Logique a mettre en place

RNG streams :

- `moveDamage`
- `moveCritical`
- `moveAccuracy`
- `generic`

Timeline events minimaux :

- turn started/ended ;
- decision requested ;
- action started/ended ;
- move declared ;
- move failed ;
- move missed ;
- move immune ;
- animation cue ;
- damage ;
- heal ;
- status change ;
- stat stage change ;
- effect added/removed/ticked ;
- switch out/in ;
- item used/consumed ;
- ability triggered ;
- weather/terrain changed ;
- capture attempt ;
- flee attempt ;
- battle ended.

### Code a mettre en place

RNG :

```dart
final class BattleRngStreams {
  BattleRngStreams({
    required int moveDamageSeed,
    required int moveCriticalSeed,
    required int moveAccuracySeed,
    required int genericSeed,
  })  : moveDamage = BattleSeededRng(moveDamageSeed),
        moveCritical = BattleSeededRng(moveCriticalSeed),
        moveAccuracy = BattleSeededRng(moveAccuracySeed),
        generic = BattleSeededRng(genericSeed);

  final BattleSeededRng moveDamage;
  final BattleSeededRng moveCritical;
  final BattleSeededRng moveAccuracy;
  final BattleSeededRng generic;

  BattleRngSeeds get seeds => BattleRngSeeds(
        moveDamage: moveDamage.seed,
        moveCritical: moveCritical.seed,
        moveAccuracy: moveAccuracy.seed,
        generic: generic.seed,
      );
}
```

Timeline event :

```dart
sealed class BattleTimelineEvent {
  const BattleTimelineEvent({required this.turn});
  final int turn;
}

final class BattleMoveDeclaredEvent extends BattleTimelineEvent {
  const BattleMoveDeclaredEvent({
    required super.turn,
    required this.user,
    required this.moveId,
    required this.moveDbSymbol,
    required this.targets,
  });

  final BattleSlotRef user;
  final String moveId;
  final String moveDbSymbol;
  final List<BattleSlotRef> targets;
}

final class BattleDamageEvent extends BattleTimelineEvent {
  const BattleDamageEvent({
    required super.turn,
    required this.target,
    required this.amount,
    required this.remainingHp,
    required this.maxHp,
    required this.effectiveness,
    required this.critical,
  });

  final BattleSlotRef target;
  final int amount;
  final int remainingHp;
  final int maxHp;
  final double effectiveness;
  final bool critical;
}
```

Builder :

```dart
final class BattleTimelineBuilder {
  final List<BattleTimelineEvent> _events = <BattleTimelineEvent>[];

  void add(BattleTimelineEvent event) {
    _events.add(event);
  }

  BattleTimeline build() {
    return BattleTimeline(List<BattleTimelineEvent>.unmodifiable(_events));
  }
}
```

### Pourquoi ce lot existe

PSDK a plusieurs RNG afin que degats, critical, accuracy et effets generiques
soient reproductibles separement. La timeline remplace les appels directs Ruby
a `scene.display_message_and_wait` et `visual.show_hp_animations`.

### Comment le mettre en place

- Injecter `BattleRngStreams` dans `BattleContext`.
- Remplacer progressivement les events legacy par `BattleTimelineEvent`.
- Les tests doivent verifier l'ordre exact des events pour des cas simples.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_rng_streams_test.dart
dart test test/psdk_timeline_test.dart
```

### Points d'attention

- La timeline ne doit pas contenir d'objets runtime/Flame.
- Les events doivent contenir des ids stables et des refs de battlers, pas des
  pointeurs UI.

---

## Lot 7 - Move data, move instance et registry `battleEngineMethod`

### But

Remplacer le DTO `BattleMove` par le triptyque PSDK :
`BattleMoveData`, `BattleMoveInstance`, `BattleMoveBehavior`.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/move/battle_move_data.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_instance.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/test/psdk_move_registry_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`

### Fichiers a supprimer plus tard

- `packages/map_battle/lib/src/battle_move.dart`

### Logique a mettre en place

- `BattleMoveData` correspond aux donnees Studio.
- `BattleMoveInstance` porte PP, PP max, usage, usage consecutif, damage dealt,
  original target.
- `BattleMoveBehavior` execute la logique.
- `BattleMoveRegistry` resolve `battleEngineMethod`.
- Si un method n'est pas encore porte, le moteur doit echouer explicitement en
  dev/test avec un event ou une exception controlee, pas simuler Showdown.

### Code a mettre en place

Data :

```dart
final class BattleMoveData {
  const BattleMoveData({
    required this.id,
    required this.dbSymbol,
    required this.name,
    required this.type,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.priority,
    required this.criticalRate,
    required this.effectChance,
    required this.battleEngineMethod,
    required this.target,
    required this.flags,
    required this.stageMods,
    required this.statuses,
  });

  final String id;
  final String dbSymbol;
  final String name;
  final BattleType type;
  final BattleMoveCategory category;
  final int power;
  final int accuracy;
  final int pp;
  final int priority;
  final int criticalRate;
  final int effectChance;
  final String battleEngineMethod;
  final BattleMoveTarget target;
  final BattleMoveFlags flags;
  final List<BattleStageMod> stageMods;
  final List<BattleMoveStatus> statuses;
}
```

Instance :

```dart
final class BattleMoveInstance {
  BattleMoveInstance({
    required this.data,
    required this.pp,
    required this.maxPp,
  });

  final BattleMoveData data;
  int pp;
  int maxPp;
  bool used = false;
  int consecutiveUseCount = 0;
  int damageDealt = 0;
  List<BattleSlotRef> originalTargets = <BattleSlotRef>[];

  bool get hasPp => pp > 0;

  void markUsed({required bool decreasePp}) {
    used = true;
    consecutiveUseCount += 1;
    if (decreasePp && pp > 0) {
      pp -= 1;
    }
  }

  void resetConsecutiveUse() {
    consecutiveUseCount = 0;
  }
}
```

Behavior registry :

```dart
abstract interface class BattleMoveBehavior {
  String get battleEngineMethod;

  void execute(BattleMoveExecution execution);
}

final class BattleMoveRegistry {
  BattleMoveRegistry(Iterable<BattleMoveBehavior> behaviors)
      : _behaviors = {
          for (final behavior in behaviors)
            behavior.battleEngineMethod: behavior,
        };

  final Map<String, BattleMoveBehavior> _behaviors;

  BattleMoveBehavior resolve(String battleEngineMethod) {
    final behavior = _behaviors[battleEngineMethod];
    if (behavior == null) {
      throw UnsupportedBattleMoveBehavior(battleEngineMethod);
    }
    return behavior;
  }
}

final class UnsupportedBattleMoveBehavior implements Exception {
  const UnsupportedBattleMoveBehavior(this.battleEngineMethod);
  final String battleEngineMethod;

  @override
  String toString() =>
      'Unsupported Pokemon SDK battleEngineMethod: $battleEngineMethod';
}
```

### Pourquoi ce lot existe

Le champ cle de PSDK est `battleEngineMethod`. Sans registry, on retombe dans un
DTO gonfle par des champs dedies comme `setsSpikes`, `selfVolatileStatus` ou
`weatherEffect`.

### Comment le mettre en place

- Convertir les moves catalogues vers `BattleMoveData` dans une factory de test.
- Ajouter une registry minimale avec `s_basic` et `s_status` en stub fonctionnel
  pour les tests smoke.
- Ne pas porter la formule de degats complete avant le Lot 9.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_move_registry_test.dart
```

### Points d'attention

- Ne pas nommer la registry par move id. Elle mappe des comportements, pas des
  attaques concretes.
- Plusieurs moves Studio doivent pouvoir pointer vers le meme behavior.

---

## Lot 8 - Procedure de move, targeting et accuracy

### But

Porter le pipeline PSDK `Move#proceed` et `Move#proceed_internal_precheck` en
Dart, sans encore finaliser tous les degats/effects.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/move/battle_move_execution.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_accuracy_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/test/psdk_move_procedure_test.dart`
- `packages/map_battle/test/psdk_targeting_test.dart`
- `packages/map_battle/test/psdk_accuracy_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`

### Fichiers a supprimer plus tard

- Les portions de `_resolveHitCheck` dans `packages/map_battle/lib/src/battle_session.dart`

### Logique a mettre en place

Procedure standard :

1. ignorer si user KO ;
2. fixer user, move, targets demandes ;
3. resoudre cibles possibles selon target Studio ;
4. gerer target single avec fallback adjacent PSDK ;
5. executer `moveUsableByUser` ;
6. emettre `BattleMoveDeclaredEvent` ;
7. executer hooks pre accuracy ;
8. check no target ;
9. check accuracy ;
10. remap user/targets pour Snatch/Magic Coat plus tard ;
11. check immunites et blocks ;
12. executer hooks post accuracy ;
13. emettre animation cue ;
14. executer behavior specifique ;
15. enregistrer histories.

### Code a mettre en place

Execution object :

```dart
final class BattleMoveExecution {
  BattleMoveExecution({
    required this.context,
    required this.timeline,
    required this.user,
    required this.move,
    required this.requestedTarget,
  });

  final BattleContext context;
  final BattleTimelineBuilder timeline;
  BattleBattler user;
  final BattleMoveInstance move;
  final BattleSlotRef? requestedTarget;
  List<BattleBattler> actualTargets = <BattleBattler>[];
}
```

Procedure :

```dart
final class BattleMoveProcedure {
  const BattleMoveProcedure({
    required BattleTargetResolver targetResolver,
    required BattleAccuracyResolver accuracyResolver,
  })  : _targetResolver = targetResolver,
        _accuracyResolver = accuracyResolver;

  final BattleTargetResolver _targetResolver;
  final BattleAccuracyResolver _accuracyResolver;

  void execute(BattleMoveExecution execution, BattleMoveBehavior behavior) {
    if (!execution.user.isAlive) {
      return;
    }

    final targets = _targetResolver.resolve(execution);
    if (!_moveUsableByUser(execution, targets)) {
      execution.timeline.add(BattleMoveFailedEvent(
        turn: execution.context.turn,
        user: execution.user.slot,
        moveDbSymbol: execution.move.data.dbSymbol,
        reason: BattleMoveFailureReason.unusableByUser,
      ));
      execution.user.history.addFailedMove(execution.move.data.dbSymbol);
      return;
    }

    execution.timeline.add(BattleMoveDeclaredEvent(
      turn: execution.context.turn,
      user: execution.user.slot,
      moveId: execution.move.data.id,
      moveDbSymbol: execution.move.data.dbSymbol,
      targets: targets.map((target) => target.slot).toList(),
    ));

    execution.context.effects.dispatchPreAccuracy(execution, targets);
    final accurateTargets = _accuracyResolver.filterAccurateTargets(
      execution,
      targets,
    );
    final unblockedTargets = execution.context.effects
        .filterTargetsAfterImmunityAndProtection(execution, accurateTargets);

    if (unblockedTargets.isEmpty) {
      execution.user.history.addMove(execution.move.data.dbSymbol, const []);
      return;
    }

    execution.actualTargets = unblockedTargets;
    execution.context.effects.dispatchPostAccuracy(execution);
    execution.timeline.add(BattleAnimationCueEvent.move(
      turn: execution.context.turn,
      user: execution.user.slot,
      moveDbSymbol: execution.move.data.dbSymbol,
      targets: unblockedTargets.map((target) => target.slot).toList(),
    ));

    behavior.execute(execution);
    execution.user.history.addSuccessfulMove(
      execution.move.data.dbSymbol,
      unblockedTargets.map((target) => target.slot).toList(),
    );
  }

  bool _moveUsableByUser(
    BattleMoveExecution execution,
    List<BattleBattler> targets,
  ) {
    if (!execution.move.hasPp) {
      return false;
    }
    return execution.context.effects.canUseMove(execution, targets);
  }
}
```

Accuracy :

```dart
final class BattleAccuracyResolver {
  const BattleAccuracyResolver();

  List<BattleBattler> filterAccurateTargets(
    BattleMoveExecution execution,
    List<BattleBattler> targets,
  ) {
    if (_bypassAccuracy(execution, targets)) {
      return targets;
    }

    final result = <BattleBattler>[];
    for (final target in targets) {
      final chance = _chanceOfHit(execution, target);
      final roll = execution.context.rng.moveAccuracy.nextInt(100);
      if (roll < chance) {
        result.add(target);
      } else {
        execution.timeline.add(BattleMoveMissedEvent(
          turn: execution.context.turn,
          user: execution.user.slot,
          target: target.slot,
          moveDbSymbol: execution.move.data.dbSymbol,
          hitChance: chance,
          roll: roll,
        ));
      }
    }
    return result;
  }
}
```

### Pourquoi ce lot existe

La procedure PSDK est le coeur de toutes les attaques. Elle decide quand les
hooks peuvent agir. Sans elle, les effects et moves speciaux seront impossibles
a porter correctement.

### Comment le mettre en place

- Porter d'abord le pipeline avec `s_basic`.
- Ajouter `s_status` une fois les status handlers disponibles.
- Garder les remaps Snatch/Magic Coat sous forme de hooks vides typables si les
  effects ne sont pas encore portes.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_move_procedure_test.dart
dart test test/psdk_targeting_test.dart
dart test test/psdk_accuracy_test.dart
```

### Points d'attention

- L'accuracy PSDK utilise `move_accuracy_rng.rand(100)` et rate si `roll >= chance`.
  En Dart, `nextInt(100)` donne 0..99 ; hit si `roll < chance`.
- `accuracy == 0` signifie bypass dans PSDK.

---

## Lot 9 - Damage formula et type processing PSDK

### But

Porter la formule de degats PSDK et le traitement des types avec hooks.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/move/battle_damage_formula.dart`
- `packages/map_battle/lib/src/domain/move/battle_damage_context.dart`
- `packages/map_battle/lib/src/domain/type/battle_type.dart`
- `packages/map_battle/lib/src/domain/type/battle_type_chart.dart`
- `packages/map_battle/lib/src/domain/type/battle_type_effectiveness.dart`
- `packages/map_battle/test/psdk_damage_formula_test.dart`
- `packages/map_battle/test/psdk_type_processing_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_stats.dart`
- `packages/map_battle/lib/src/battle_typing.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`

### Fichiers a supprimer plus tard

- L'ancien `_computeMoveDamage` dans `battle_session.dart`
- L'ancien type chart si incompatible avec hooks PSDK.

### Logique a mettre en place

Formule cible :

- level ;
- base power reel ;
- attack ou special attack ;
- defense ou special defense ;
- stages ;
- critical ;
- modifier 1 ;
- random 85..100 ;
- STAB ;
- type multiplier ;
- burn modifier ;
- modifier 2 ;
- modifier 3 ;
- clamp minimum 1 si move damaging et effectiveness > 0.

Hooks requis dans le calcul :

- base power multiplier/overwrite ;
- move type overwrite ;
- single type multiplier overwrite ;
- attack stat modifier ;
- defense stat modifier ;
- final damage modifier ;
- critical prevention/change.

### Code a mettre en place

Damage context :

```dart
final class BattleDamageContext {
  BattleDamageContext({
    required this.user,
    required this.target,
    required this.move,
    required this.critical,
    required this.typeEffectiveness,
  });

  final BattleBattler user;
  final BattleBattler target;
  final BattleMoveInstance move;
  bool critical;
  double typeEffectiveness;
  int basePower = 0;
  int attack = 0;
  int defense = 0;
  double modifier = 1.0;
}
```

Formula :

```dart
final class BattleDamageFormula {
  const BattleDamageFormula();

  BattleDamageResult compute(BattleMoveExecution execution, BattleBattler target) {
    final move = execution.move;
    final user = execution.user;
    final critical = execution.context.criticalResolver.isCritical(
      user: user,
      target: target,
      move: move,
    );
    final effectiveness = execution.context.typeChart.effectiveness(
      moveType: execution.context.effects.resolveMoveType(user, target, move),
      targetTypes: target.types,
      execution: execution,
    );

    if (effectiveness.multiplier == 0) {
      return BattleDamageResult.noDamage(
        critical: critical,
        effectiveness: effectiveness.multiplier,
      );
    }

    final context = BattleDamageContext(
      user: user,
      target: target,
      move: move,
      critical: critical,
      typeEffectiveness: effectiveness.multiplier,
    );

    context.basePower = execution.context.effects.resolveBasePower(context);
    context.attack = execution.context.effects.resolveAttackStat(context);
    context.defense = execution.context.effects.resolveDefenseStat(context);

    final base = (((((2 * user.level / 5) + 2) *
                    context.basePower *
                    context.attack /
                    context.defense) /
                50) +
            2)
        .floor();

    final random = execution.context.rng.moveDamage.nextIntInclusive(85, 100);
    final stab = user.types.contains(effectiveness.moveType) ? 1.5 : 1.0;
    final burn = execution.context.effects.resolveBurnDamageModifier(context);
    final modifier = execution.context.effects.resolveFinalDamageModifier(
      context,
      baseModifier:
          random / 100 * stab * effectiveness.multiplier * burn,
    );

    final damage = (base * modifier).floor().clamp(1, target.hp);
    return BattleDamageResult(
      amount: damage,
      critical: critical,
      effectiveness: effectiveness.multiplier,
    );
  }
}
```

### Pourquoi ce lot existe

La precision du moteur depend de la formule de degats. Beaucoup d'abilities,
items et moves PSDK n'ajoutent pas "un effet final" ; ils se branchent dans le
calcul lui-meme.

### Comment le mettre en place

- Ajouter des tests avec RNG fixe pour `tackle`.
- Ajouter des tests de type : super efficace, peu efficace, immune.
- Ajouter des tests STAB.
- Ajouter un test burn physique.
- Ajouter un test critical qui ignore les mauvais stages de l'attaquant ou les
  bons stages du defenseur selon la regle portee.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_damage_formula_test.dart
dart test test/psdk_type_processing_test.dart
```

### Points d'attention

- Utiliser des doubles pour les multiplicateurs, mais convertir aux memes
  moments que PSDK pour eviter des ecarts.
- L'ordre des modifiers doit etre teste. Les futurs ability/item effects en
  dependent.

---

## Lot 10 - Effect stack et hooks PSDK

### But

Remplacer `BattleConditionEngine`, volatiles et side condition files par un
systeme generique d'effects et de hooks inspire de PSDK.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_dispatcher.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_scope.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- `packages/map_battle/test/psdk_effect_stack_test.dart`
- `packages/map_battle/test/psdk_effect_dispatcher_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_condition_side_conditions.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`

### Fichiers a supprimer plus tard

- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_condition_side_conditions.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`

### Logique a mettre en place

Un effect :

- a un `id` stable ;
- a un scope : battler, bank, position, field, weather, terrain ;
- peut expirer ;
- peut reagir a des hooks ;
- peut emettre des events timeline ;
- ne connait pas Flutter/Flame.

Hooks prioritaires :

- move prevention ;
- pre accuracy ;
- post accuracy ;
- target immunity ;
- move blocked by target ;
- move priority change ;
- base power change ;
- type change ;
- type multiplier overwrite ;
- damage prevention/change ;
- post damage ;
- status prevention/change ;
- stat prevention/change ;
- switch in/out ;
- end turn ;
- weather/terrain change ;
- item/ability change.

### Code a mettre en place

Effect base :

```dart
abstract class BattleEffect {
  BattleEffect({
    required this.id,
    required this.scope,
    int? turnCount,
  }) : remainingTurns = turnCount;

  final String id;
  final BattleEffectScope scope;
  int? remainingTurns;
  bool _dead = false;

  bool get isDead => _dead || remainingTurns == 0;

  void kill() {
    _dead = true;
  }

  void tick(BattleContext context, BattleTimelineBuilder timeline) {
    final turns = remainingTurns;
    if (turns != null && turns > 0) {
      remainingTurns = turns - 1;
    }
  }

  void onDelete(BattleContext context, BattleTimelineBuilder timeline) {}
}
```

Stack :

```dart
final class BattleEffectStack {
  final List<BattleEffect> _effects = <BattleEffect>[];

  Iterable<BattleEffect> get effects => List.unmodifiable(_effects);

  bool has(String id) => _effects.any((effect) => effect.id == id);

  T? get<T extends BattleEffect>() {
    for (final effect in _effects) {
      if (effect is T) {
        return effect;
      }
    }
    return null;
  }

  void add(BattleEffect effect) {
    _effects.add(effect);
  }

  void replaceWhere(BattleEffect effect, bool Function(BattleEffect) test) {
    for (final existing in _effects.where(test)) {
      existing.kill();
    }
    purgeDead(null, null);
    add(effect);
  }

  void purgeDead(BattleContext? context, BattleTimelineBuilder? timeline) {
    final dead = _effects.where((effect) => effect.isDead).toList();
    _effects.removeWhere((effect) => effect.isDead);
    if (context != null && timeline != null) {
      for (final effect in dead) {
        effect.onDelete(context, timeline);
      }
    }
  }
}
```

Hook interface example :

```dart
abstract interface class DamagePreventionHook {
  DamagePreventionResult onDamagePrevention({
    required BattleContext context,
    required int damage,
    required BattleBattler target,
    BattleBattler? launcher,
    BattleMoveInstance? move,
  });
}
```

### Pourquoi ce lot existe

PSDK ne code pas les regles transverses dans un switch geant. Les regles sont
des effects qui s'accrochent aux handlers. Ce lot rend possible les 409 effects
PSDK.

### Comment le mettre en place

- Commencer avec une stack sans effects concrets.
- Ajouter le dispatcher qui parcourt les scopes dans un ordre documente.
- Brancher `BattleContext.effects` comme point d'acces unique.
- Adapter les tests existants de protect/recharge/hazards plus tard, pas dans
  ce lot.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_effect_stack_test.dart
dart test test/psdk_effect_dispatcher_test.dart
```

### Points d'attention

- Le dispatcher ne doit pas avaler silencieusement les conflits. Si deux hooks
  retournent un overwrite incompatible, l'ordre doit etre explicite et teste.
- Les effects ne doivent pas modifier la timeline sans passer par le builder.

---

## Lot 11 - Handlers fondamentaux PSDK

### But

Sortir les mutations majeures du moteur central et les placer dans des handlers
comme PSDK : damage, heal, status, stat, switch, end turn.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/handler/battle_handlers.dart`
- `packages/map_battle/lib/src/domain/handler/change_handler_base.dart`
- `packages/map_battle/lib/src/domain/handler/damage_handler.dart`
- `packages/map_battle/lib/src/domain/handler/status_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/stat_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/switch_handler.dart`
- `packages/map_battle/lib/src/domain/handler/end_turn_handler.dart`
- `packages/map_battle/test/psdk_damage_handler_test.dart`
- `packages/map_battle/test/psdk_status_change_handler_test.dart`
- `packages/map_battle/test/psdk_stat_change_handler_test.dart`
- `packages/map_battle/test/psdk_switch_handler_test.dart`
- `packages/map_battle/test/psdk_end_turn_handler_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_dispatcher.dart`
- `packages/map_battle/lib/src/battle_switch.dart`

### Fichiers a supprimer plus tard

- Les mutations directes HP/status/stats dans `battle_session.dart`
- `packages/map_battle/lib/src/battle_switch.dart` si remplace totalement.

### Logique a mettre en place

Handlers :

- `DamageHandler.damage`: applique prevention, damage, KO, histories, events.
- `DamageHandler.heal`: applique heal block, clamp, event.
- `StatusChangeHandler`: applique prevention, changement, cure.
- `StatChangeHandler`: applique stage clamp -6..+6, prevention, event.
- `SwitchHandler`: switch out/in, reset states, entry hooks.
- `EndTurnHandler`: tick effects, residuals, forced requests.

### Code a mettre en place

Container :

```dart
final class BattleHandlers {
  BattleHandlers(BattleContext context)
      : damage = DamageHandler(context),
        status = StatusChangeHandler(context),
        stat = StatChangeHandler(context),
        switchHandler = SwitchHandler(context),
        endTurn = EndTurnHandler(context);

  final DamageHandler damage;
  final StatusChangeHandler status;
  final StatChangeHandler stat;
  final SwitchHandler switchHandler;
  final EndTurnHandler endTurn;
}
```

Damage :

```dart
final class DamageHandler {
  DamageHandler(this._context);

  final BattleContext _context;

  bool damage({
    required int amount,
    required BattleBattler target,
    BattleBattler? launcher,
    BattleMoveInstance? move,
    required BattleTimelineBuilder timeline,
    double effectiveness = 1,
    bool critical = false,
  }) {
    if (!target.isAlive) {
      return false;
    }

    final resolved = _context.effects.resolveDamagePrevention(
      amount: amount,
      target: target,
      launcher: launcher,
      move: move,
      timeline: timeline,
    );
    if (resolved.prevented) {
      return false;
    }

    final applied = resolved.amount.clamp(0, target.hp);
    target.hp -= applied;
    move?.damageDealt += applied;
    target.history.addDamage(applied, launcher?.slot, move?.data.dbSymbol);

    timeline.add(BattleDamageEvent(
      turn: _context.turn,
      target: target.slot,
      amount: applied,
      remainingHp: target.hp,
      maxHp: target.maxHp,
      effectiveness: effectiveness,
      critical: critical,
    ));

    if (target.isKo) {
      timeline.add(BattleKoEvent(turn: _context.turn, target: target.slot));
      _context.effects.dispatchPostDamageDeath(
        damage: applied,
        target: target,
        launcher: launcher,
        move: move,
        timeline: timeline,
      );
    } else {
      _context.effects.dispatchPostDamage(
        damage: applied,
        target: target,
        launcher: launcher,
        move: move,
        timeline: timeline,
      );
    }
    return true;
  }
}
```

Status :

```dart
final class StatusChangeHandler {
  StatusChangeHandler(this._context);

  final BattleContext _context;

  bool applyStatus({
    required BattleBattler target,
    required BattleMajorStatus status,
    BattleBattler? launcher,
    BattleMoveInstance? move,
    required BattleTimelineBuilder timeline,
  }) {
    if (!_context.effects.canApplyStatus(
      target: target,
      status: status,
      launcher: launcher,
      move: move,
      timeline: timeline,
    )) {
      return false;
    }

    target.effects.replaceWhere(
      BattleMajorStatusEffect(status: status),
      (effect) => effect is BattleMajorStatusEffect,
    );
    timeline.add(BattleStatusChangedEvent(
      turn: _context.turn,
      target: target.slot,
      status: status,
    ));
    return true;
  }
}
```

### Pourquoi ce lot existe

PSDK centralise les mutations dans des handlers qui donnent des points de hook
aux effects. C'est indispensable pour abilities/items/status.

### Comment le mettre en place

- Brancher les handlers dans `BattleContext`.
- Faire utiliser `DamageHandler` par `s_basic`.
- Faire utiliser `StatusChangeHandler` par `s_status` ou `Thunder Wave`.
- Faire utiliser `StatChangeHandler` par les moves de stage simples.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_damage_handler_test.dart
dart test test/psdk_status_change_handler_test.dart
dart test test/psdk_stat_change_handler_test.dart
dart test test/psdk_switch_handler_test.dart
dart test test/psdk_end_turn_handler_test.dart
```

### Points d'attention

- Ne pas laisser les moves modifier `target.hp` directement.
- Ne pas laisser les effects modifier `target.hp` directement sauf cas
  explicitement encapsule par handler.

---

## Lot 12 - Status, weather, terrain et hazards comme effects

### But

Porter les conditions actuelles vers le nouveau systeme d'effects et supprimer
les fichiers dedies a terme.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/effect/status/status_effects.dart`
- `packages/map_battle/lib/src/domain/effect/status/poison_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/paralysis_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/burn_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/asleep_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/frozen_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/toxic_effect.dart`
- `packages/map_battle/lib/src/domain/effect/field/weather_effects.dart`
- `packages/map_battle/lib/src/domain/effect/field/terrain_effects.dart`
- `packages/map_battle/lib/src/domain/effect/move/protect_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/stealth_rock_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/spikes_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/toxic_spikes_effect.dart`
- `packages/map_battle/test/psdk_status_effects_test.dart`
- `packages/map_battle/test/psdk_weather_effects_test.dart`
- `packages/map_battle/test/psdk_hazard_effects_test.dart`
- `packages/map_battle/test/psdk_protect_effect_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/domain/handler/end_turn_handler.dart`
- `packages/map_battle/lib/src/domain/handler/switch_handler.dart`

### Fichiers a supprimer a la fin du lot si le runtime compile

- `packages/map_battle/lib/src/battle_spikes.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`

Les fichiers status/field legacy peuvent rester jusqu'au cutover runtime.

### Logique a mettre en place

Status :

- paralysis : chance de ne pas agir + speed modifier ;
- burn : residual + physical damage modifier ;
- poison : residual ;
- toxic : counter + residual croissant ;
- asleep : compteur + move prevention sauf exceptions ;
- frozen : move prevention + thaw conditions.

Weather :

- rain/sun/sandstorm/hail/snow au minimum ;
- residual sand/hail ;
- water/fire modifiers ;
- ability hooks plus tard.

Hazards :

- stealth rock sur side/position ;
- spikes layers ;
- toxic spikes layers ;
- apply on switch in via `SwitchHandler`.

### Code a mettre en place

Paralysis :

```dart
final class ParalysisEffect extends BattleEffect
    implements MovePreventionHook, SpeedModifierHook {
  ParalysisEffect()
      : super(
          id: 'paralysis',
          scope: BattleEffectScope.battler,
        );

  @override
  BattleMovePreventionResult onMovePrevention({
    required BattleMoveExecution execution,
  }) {
    final roll = execution.context.rng.generic.nextInt(100);
    if (roll < 25) {
      execution.timeline.add(BattleMoveFailedEvent(
        turn: execution.context.turn,
        user: execution.user.slot,
        moveDbSymbol: execution.move.data.dbSymbol,
        reason: BattleMoveFailureReason.paralysis,
      ));
      return BattleMovePreventionResult.prevented;
    }
    return BattleMovePreventionResult.allowed;
  }

  @override
  int modifySpeed(BattleBattler battler, int currentSpeed) {
    return (currentSpeed / 2).floor().clamp(1, currentSpeed);
  }
}
```

Stealth Rock :

```dart
final class StealthRockEffect extends BattleEffect
    implements SwitchInHook {
  StealthRockEffect({required this.ownerBank})
      : super(
          id: 'stealth_rock',
          scope: BattleEffectScope.bank,
        );

  final int ownerBank;

  @override
  void onSwitchIn({
    required BattleContext context,
    required BattleBattler battler,
    required BattleTimelineBuilder timeline,
  }) {
    if (battler.bank == ownerBank) {
      return;
    }
    final multiplier = context.typeChart.effectiveness(
      moveType: BattleType.rock,
      targetTypes: battler.types,
      execution: null,
    ).multiplier;
    final damage = (battler.maxHp * multiplier / 8).floor().clamp(1, battler.hp);
    context.handlers.damage.damage(
      amount: damage,
      target: battler,
      timeline: timeline,
      effectiveness: multiplier,
    );
  }
}
```

Protect :

```dart
final class ProtectEffect extends BattleEffect
    implements MoveBlockHook {
  ProtectEffect({required this.owner})
      : super(id: 'protect', scope: BattleEffectScope.battler);

  final BattleSlotRef owner;

  @override
  bool blocksMove({
    required BattleMoveExecution execution,
    required BattleBattler target,
  }) {
    return target.slot == owner && execution.move.data.flags.blocable;
  }
}
```

### Pourquoi ce lot existe

Le moteur actuel traite ces mecanismes comme des cas dedies. PSDK les traite
comme des effects. Ce lot aligne le moteur sur le modele qui permettra ensuite
abilities/items/moves complexes.

### Comment le mettre en place

- Porter d'abord status + protect + stealth rock.
- Ajouter spikes/toxic spikes apres le switch handler.
- Remplacer les tests legacy par des tests effects.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_status_effects_test.dart
dart test test/psdk_weather_effects_test.dart
dart test test/psdk_hazard_effects_test.dart
dart test test/psdk_protect_effect_test.dart
```

### Points d'attention

- Les residuals doivent etre des events de timeline.
- Les hazards doivent etre attaches au camp/side adverse, pas au move qui les a
  crees.

---

## Lot 13 - Actions et scheduler PSDK

### But

Remplacer `battle_session_scheduler.dart` et `battle_queue.dart` par des actions
executables et un tri PSDK-like.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/action/battle_action.dart`
- `packages/map_battle/lib/src/domain/action/attack_action.dart`
- `packages/map_battle/lib/src/domain/action/pre_attack_action.dart`
- `packages/map_battle/lib/src/domain/action/item_action.dart`
- `packages/map_battle/lib/src/domain/action/high_priority_item_action.dart`
- `packages/map_battle/lib/src/domain/action/switch_action.dart`
- `packages/map_battle/lib/src/domain/action/flee_action.dart`
- `packages/map_battle/lib/src/domain/action/no_action.dart`
- `packages/map_battle/lib/src/domain/action/shift_action.dart`
- `packages/map_battle/lib/src/domain/action/battle_action_scheduler.dart`
- `packages/map_battle/test/psdk_action_scheduler_test.dart`
- `packages/map_battle/test/psdk_action_execution_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`

### Fichiers a supprimer a la fin du cutover

- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_queue.dart`

### Logique a mettre en place

Ordre de tri PSDK a supporter par tranches :

1. high priority item ;
2. pursuit/pre-attack ;
3. shift ;
4. item ;
5. switch ;
6. priority de move ;
7. stall ;
8. lagging tail/full incense ;
9. Mycelium Might ;
10. Trick Room ;
11. speed ;
12. speed tie via RNG.

### Code a mettre en place

Action base :

```dart
abstract class BattleAction {
  const BattleAction({
    required this.actor,
    required this.kind,
  });

  final BattleSlotRef actor;
  final BattleActionKind kind;

  bool isValid(BattleContext context);

  void execute(BattleContext context, BattleTimelineBuilder timeline);
}

enum BattleActionKind {
  highPriorityItem,
  preAttack,
  shift,
  item,
  switchAction,
  attack,
  flee,
  noAction,
}
```

Attack action :

```dart
final class AttackAction extends BattleAction {
  const AttackAction({
    required super.actor,
    required this.moveSlot,
    required this.target,
  }) : super(kind: BattleActionKind.attack);

  final int moveSlot;
  final BattleSlotRef? target;

  @override
  bool isValid(BattleContext context) {
    final battler = context.battlerAt(actor);
    return battler != null && battler.isAlive && moveSlot < battler.moves.length;
  }

  @override
  void execute(BattleContext context, BattleTimelineBuilder timeline) {
    final user = context.battlerAt(actor);
    if (user == null || !user.isAlive) {
      return;
    }
    final move = user.moves[moveSlot];
    final behavior = context.moveRegistry.resolve(move.data.battleEngineMethod);
    context.moveProcedure.execute(
      BattleMoveExecution(
        context: context,
        timeline: timeline,
        user: user,
        move: move,
        requestedTarget: target,
      ),
      behavior,
    );
  }
}
```

Scheduler :

```dart
final class BattleActionScheduler {
  const BattleActionScheduler();

  List<BattleAction> sort(BattleContext context, Iterable<BattleAction> actions) {
    final valid = actions.where((action) => action.isValid(context)).toList();
    valid.sort((a, b) => _compare(context, a, b));
    return valid;
  }

  int _compare(BattleContext context, BattleAction a, BattleAction b) {
    final kindCompare = _kindRank(a.kind).compareTo(_kindRank(b.kind));
    if (kindCompare != 0) {
      return kindCompare;
    }

    final priorityCompare = _movePriority(context, b).compareTo(
      _movePriority(context, a),
    );
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final speedA = context.effectiveSpeed(a.actor);
    final speedB = context.effectiveSpeed(b.actor);
    final trickRoom = context.fieldEffects.has('trick_room');
    final speedCompare = trickRoom
        ? speedA.compareTo(speedB)
        : speedB.compareTo(speedA);
    if (speedCompare != 0) {
      return speedCompare;
    }

    return context.rng.generic.nextBool() ? -1 : 1;
  }
}
```

### Pourquoi ce lot existe

Le tour Pokemon n'est pas juste "joueur puis adversaire". PSDK modelise tout en
actions triees. Cela permet switch, items, forced moves, pre-attack et moves de
priorite correctement.

### Comment le mettre en place

- Brancher `BattleTurnRunner` sur le scheduler.
- Garder un test speed/priorite simple.
- Ajouter Trick Room apres le field effect.
- Ajouter items/switch apres leurs handlers si necessaire.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_action_scheduler_test.dart
dart test test/psdk_action_execution_test.dart
```

### Points d'attention

- Les actions doivent etre creees depuis les decisions, pas depuis l'UI.
- L'IA doit produire les memes actions que le joueur.

---

## Lot 14 - Behaviors de moves : tranche fondamentale

### But

Porter les mechanics PSDK de base pour rendre le moteur utile rapidement sans
porter les 272 definitions d'un coup.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/move/behaviors/basic_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/status_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/stat_stage_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/self_stat_stage_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/heal_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/drain_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/recoil_move_behavior.dart`
- `packages/map_battle/test/psdk_tackle_parity_test.dart`
- `packages/map_battle/test/psdk_thunder_wave_parity_test.dart`
- `packages/map_battle/test/psdk_vine_whip_parity_test.dart`
- `packages/map_battle/test/psdk_stat_move_parity_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`

### Fichiers a supprimer

Aucun.

### Logique a mettre en place

Tranche 1 des `battleEngineMethod` :

- `s_basic` : damage standard ;
- `s_status` : applique status Studio ;
- `s_stat` : applique stage mods sur target ;
- `s_self_stat` : applique stage mods sur user ;
- `s_self_status` : applique status sur user si Studio en contient ;
- heal/drain/recoil de base si les moves de test en ont besoin.

### Code a mettre en place

Basic :

```dart
final class BasicMoveBehavior implements BattleMoveBehavior {
  const BasicMoveBehavior();

  @override
  String get battleEngineMethod => 's_basic';

  @override
  void execute(BattleMoveExecution execution) {
    for (final target in execution.actualTargets) {
      final result = execution.context.damageFormula.compute(execution, target);
      if (result.amount <= 0) {
        continue;
      }
      execution.context.handlers.damage.damage(
        amount: result.amount,
        target: target,
        launcher: execution.user,
        move: execution.move,
        timeline: execution.timeline,
        effectiveness: result.effectiveness,
        critical: result.critical,
      );
    }
    execution.move.markUsed(decreasePp: true);
  }
}
```

Status :

```dart
final class StatusMoveBehavior implements BattleMoveBehavior {
  const StatusMoveBehavior();

  @override
  String get battleEngineMethod => 's_status';

  @override
  void execute(BattleMoveExecution execution) {
    final statuses = execution.move.data.statuses;
    for (final target in execution.actualTargets) {
      for (final status in statuses) {
        execution.context.handlers.status.applyStatus(
          target: target,
          status: status.majorStatus,
          launcher: execution.user,
          move: execution.move,
          timeline: execution.timeline,
        );
      }
    }
    execution.move.markUsed(decreasePp: true);
  }
}
```

Stat stages :

```dart
final class StatStageMoveBehavior implements BattleMoveBehavior {
  const StatStageMoveBehavior();

  @override
  String get battleEngineMethod => 's_stat';

  @override
  void execute(BattleMoveExecution execution) {
    for (final target in execution.actualTargets) {
      for (final mod in execution.move.data.stageMods) {
        execution.context.handlers.stat.changeStage(
          target: target,
          stat: mod.stat,
          delta: mod.delta,
          launcher: execution.user,
          move: execution.move,
          timeline: execution.timeline,
        );
      }
    }
    execution.move.markUsed(decreasePp: true);
  }
}
```

### Pourquoi ce lot existe

Il donne un premier moteur PSDK-like testable avec des moves reels : Tackle,
Vine Whip, Thunder Wave, Tail Whip/Growl selon fixtures.

### Comment le mettre en place

- Commencer par des fixtures PSDK Studio de 4 a 8 moves.
- Ajouter une factory de test `BattleFixtures.psdkSingles`.
- Comparer les events timeline attendus plutot que seulement les PV finaux.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_tackle_parity_test.dart
dart test test/psdk_thunder_wave_parity_test.dart
dart test test/psdk_vine_whip_parity_test.dart
dart test test/psdk_stat_move_parity_test.dart
```

### Points d'attention

- Ne pas coder `Thunder Wave` par id dans `StatusMoveBehavior`. Le status vient
  de Studio.
- Ne pas coder `Tackle` par id dans `BasicMoveBehavior`. La puissance/type
  viennent de `BattleMoveData`.

---

## Lot 15 - Extraction PSDK et matrice de portage moves/effects

### But

Creer des outils pour suivre le port des `Move.register(:s_xxx, Klass)` et des
effects Ruby PSDK. Ce lot evite de porter a l'aveugle.

### Fichiers a creer

- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/tool/extract_psdk_effect_matrix.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`

### Fichiers a modifier

- `packages/map_battle/pubspec.yaml` si un package CLI est necessaire. Par
  defaut, rester sans dependance externe et utiliser `dart:io`.

### Fichiers a supprimer

Aucun.

### Logique a mettre en place

Move extractor :

- scanner `pokemonsdk-development/scripts/5 Battle/10 Move`;
- detecter `Move.register(:method, ClassName)`;
- produire :
  - method ;
  - class ;
  - Ruby path ;
  - Dart behavior cible ;
  - statut : `ported`, `partial`, `missing`.

Effect extractor :

- scanner `pokemonsdk-development/scripts/5 Battle/06 Effects`;
- detecter classes et hooks `on_*`;
- produire :
  - effect id/famille ;
  - hooks ;
  - Ruby path ;
  - Dart path cible ;
  - statut.

### Code a mettre en place

Move extractor minimal :

```dart
import 'dart:io';

final registerPattern = RegExp(
  r'Move\.register\(:([a-zA-Z0-9_]+),\s*([A-Za-z0-9_:]+)\)',
);

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/extract_psdk_move_registry.dart '
      '<psdk-5-battle-dir> <output-md>',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(args[0]);
  final rows = <MoveRegistryRow>[];
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.rb')) {
      continue;
    }
    final content = await file.readAsString();
    for (final match in registerPattern.allMatches(content)) {
      rows.add(MoveRegistryRow(
        method: match.group(1)!,
        rubyClass: match.group(2)!,
        rubyPath: file.path,
      ));
    }
  }
  rows.sort((a, b) => a.method.compareTo(b.method));
  await File(args[1]).writeAsString(renderMoveMatrix(rows));
}
```

Generated manifest shape :

```dart
final class PsdkMoveRegistryManifestEntry {
  const PsdkMoveRegistryManifestEntry({
    required this.battleEngineMethod,
    required this.rubyClass,
    required this.rubyPath,
    required this.dartBehavior,
    required this.status,
  });

  final String battleEngineMethod;
  final String rubyClass;
  final String rubyPath;
  final String dartBehavior;
  final PsdkPortStatus status;
}

enum PsdkPortStatus {
  ported,
  partial,
  missing,
}
```

### Pourquoi ce lot existe

Le scope est enorme : 272 move definitions, 409 effects, 216 ability effects,
62 item effects. Sans matrice, on ne sait pas ce qui est porte ni ce qui manque.

### Comment le mettre en place

- Executer les outils sur le dossier PSDK fourni.
- Committer les matrices markdown pour revue.
- Utiliser la matrice pour decouper les lots de portage move par familles.

### Tests et commandes

```bash
cd packages/map_battle
dart run tool/extract_psdk_move_registry.dart \
  ../../pokemonsdk-development/scripts/5\ Battle \
  ../../reports/psdk-move-porting-matrix.md
dart run tool/extract_psdk_effect_matrix.dart \
  ../../pokemonsdk-development/scripts/5\ Battle \
  ../../reports/psdk-effect-porting-matrix.md
dart test test/psdk_registry_manifest_test.dart
```

### Points d'attention

- Les extracteurs ne remplacent pas une analyse humaine. Ils donnent une carte.
- Les matrices peuvent vivre dans `reports/` car elles sont des artefacts de
  migration explicitement demandes.

---

## Lot 16 - Portage des familles de moves avancees

### But

Porter les mechanics PSDK par familles, en gardant chaque sous-famille testable.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/two_turn_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/recharge_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/hazard_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/weather_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/terrain_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/force_switch_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/switch_after_hit_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/fixed_damage_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/custom_power_move_behavior.dart`
- tests parity par famille sous `packages/map_battle/test/psdk_move_families/`

### Fichiers a modifier

- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `reports/psdk-move-porting-matrix.md`

### Fichiers a supprimer

Aucun.

### Logique a mettre en place

Ordre recommande :

1. `s_multi_hit`, `s_2hits`, `s_double_kick` ;
2. two-turn/out-of-reach ;
3. recharge ;
4. drain/recoil/heal weather ;
5. hazards : Spikes, Toxic Spikes, Stealth Rock, Sticky Web ;
6. weather/terrain setters ;
7. force switch : Roar/Whirlwind/Dragon Tail ;
8. switch after hit : U-Turn/Volt Switch/Parting Shot ;
9. fixed damage : Seismic Toss/Night Shade/Super Fang ;
10. custom power : Low Kick, Heavy Slam, Electro Ball, Revenge, Payback ;
11. copy/redirect : Mirror Move, Copycat, Snatch, Magic Coat ;
12. rare/special definitions : Metronome, Transform, Future Sight.

### Code a mettre en place

Multi-hit :

```dart
final class MultiHitMoveBehavior implements BattleMoveBehavior {
  const MultiHitMoveBehavior({
    required this.battleEngineMethod,
    required this.hitCountResolver,
  });

  @override
  final String battleEngineMethod;

  final BattleHitCountResolver hitCountResolver;

  @override
  void execute(BattleMoveExecution execution) {
    final hits = hitCountResolver.resolve(execution);
    for (var hit = 0; hit < hits; hit += 1) {
      for (final target in execution.actualTargets.where((target) => target.isAlive)) {
        final result = execution.context.damageFormula.compute(execution, target);
        execution.context.handlers.damage.damage(
          amount: result.amount,
          target: target,
          launcher: execution.user,
          move: execution.move,
          timeline: execution.timeline,
          effectiveness: result.effectiveness,
          critical: result.critical,
        );
      }
    }
    execution.timeline.add(BattleMultiHitSummaryEvent(
      turn: execution.context.turn,
      user: execution.user.slot,
      moveDbSymbol: execution.move.data.dbSymbol,
      hits: hits,
    ));
    execution.move.markUsed(decreasePp: true);
  }
}
```

Hazard setter :

```dart
final class HazardMoveBehavior implements BattleMoveBehavior {
  const HazardMoveBehavior({
    required this.battleEngineMethod,
    required this.createEffect,
  });

  @override
  final String battleEngineMethod;

  final BattleEffect Function(BattleMoveExecution execution) createEffect;

  @override
  void execute(BattleMoveExecution execution) {
    final targetBank = execution.context.topology.foeBankOf(execution.user);
    execution.context.bankEffects(targetBank).add(createEffect(execution));
    execution.timeline.add(BattleEffectAddedEvent(
      turn: execution.context.turn,
      scope: BattleEffectScopeRef.bank(targetBank),
      effectId: createEffect(execution).id,
    ));
    execution.move.markUsed(decreasePp: true);
  }
}
```

### Pourquoi ce lot existe

Les moves avances doivent s'appuyer sur procedure/handlers/effects. Les porter
avant les lots 8 a 12 produirait une duplication fragile.

### Comment le mettre en place

- Un commit par famille.
- Un test parity par move representatif.
- Mettre a jour la matrice apres chaque famille.
- Ne jamais coder des conditions par nom d'attaque dans le scheduler ou les
  handlers.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_move_families
dart test
```

### Points d'attention

- Certains moves PSDK ont une classe dediee meme s'ils partagent une famille.
  La registry peut mapper vers une classe specifique quand la famille generique
  ne suffit pas.
- Les moves rares doivent rester explicites et testes plutot que caches dans un
  behavior trop abstrait.

---

## Lot 17 - Ability effects et item effects

### But

Porter les talents et objets de combat en effects, afin que les moves PSDK
soient fiables dans les interactions.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/effect/ability/ability_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/ability_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- `packages/map_battle/lib/src/domain/item/battle_item_data.dart`
- `packages/map_battle/lib/src/domain/ability/battle_ability_data.dart`
- tests sous `packages/map_battle/test/psdk_ability_effects/`
- tests sous `packages/map_battle/test/psdk_item_effects/`

### Fichiers a modifier

- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_dispatcher.dart`
- `packages/map_battle/lib/src/domain/handler/damage_handler.dart`
- `packages/map_battle/lib/src/domain/handler/status_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/stat_change_handler.dart`
- `packages/map_battle/lib/src/domain/action/item_action.dart`
- `reports/psdk-effect-porting-matrix.md`

### Fichiers a supprimer

Aucun.

### Logique a mettre en place

Ability families prioritaires :

- immunites status ;
- immunites type ;
- weather setters ;
- terrain setters ;
- stat modifiers ;
- damage modifiers ;
- move type changers ;
- switch prevention ;
- post damage triggers.

Item families prioritaires :

- berries heal/status ;
- type resist berries ;
- type boosting items ;
- choice items ;
- leftovers/black sludge ;
- focus sash ;
- life orb ;
- weather rocks ;
- battle medicine from bag.

### Code a mettre en place

Ability registry :

```dart
abstract interface class AbilityEffectFactory {
  String get abilityId;
  BattleEffect create(BattleBattler owner, BattleAbilityData data);
}

final class AbilityEffectRegistry {
  AbilityEffectRegistry(Iterable<AbilityEffectFactory> factories)
      : _factories = {
          for (final factory in factories) factory.abilityId: factory,
        };

  final Map<String, AbilityEffectFactory> _factories;

  BattleEffect? createFor(BattleBattler owner, BattleAbilityData data) {
    return _factories[data.id]?.create(owner, data);
  }
}
```

Item action :

```dart
final class ItemAction extends BattleAction {
  const ItemAction({
    required super.actor,
    required this.itemId,
    required this.target,
  }) : super(kind: BattleActionKind.item);

  final String itemId;
  final BattleSlotRef target;

  @override
  bool isValid(BattleContext context) {
    return context.bagFor(actor.bank).hasItem(itemId);
  }

  @override
  void execute(BattleContext context, BattleTimelineBuilder timeline) {
    final item = context.catalogs.items.require(itemId);
    final targetBattler = context.battlerAt(target);
    if (targetBattler == null) {
      return;
    }
    context.itemEffectRegistry.resolve(item.battleEffectId).applyFromBag(
          context: context,
          item: item,
          target: targetBattler,
          timeline: timeline,
        );
    context.bagFor(actor.bank).consume(itemId, 1);
    timeline.add(BattleItemUsedEvent(
      turn: context.turn,
      userBank: actor.bank,
      itemId: itemId,
      target: target,
    ));
  }
}
```

### Pourquoi ce lot existe

Beaucoup de comportements PSDK ne sont pas dans `10 Move`, mais dans `06 Effects`
ability/item. Dire que les attaques sont portees sans ces hooks donnerait un
moteur faux sur les combats reels.

### Comment le mettre en place

- Commencer par les effects qui interagissent avec les moves deja portes.
- Ajouter une factory lors de la creation du battler pour installer ability/item
  effects actifs.
- Garder les bag items volontaires via `ItemAction`.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_ability_effects
dart test test/psdk_item_effects
```

### Points d'attention

- L'objet tenu et l'objet utilise depuis le sac n'ont pas le meme cycle de vie.
- Les abilities neutralisees/supprimees doivent rester modelisees comme effects
  modifiables, pas comme booleens disperses.

---

## Lot 18 - AI PSDK-like

### But

Remplacer `BattleOpponentPolicy` par une IA de combat pure Dart inspiree de
`scripts/5 Battle/30 AI`.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/ai/battle_ai_policy.dart`
- `packages/map_battle/lib/src/domain/ai/battle_ai_level.dart`
- `packages/map_battle/lib/src/domain/ai/battle_ai_capabilities.dart`
- `packages/map_battle/lib/src/domain/ai/generic_battle_ai.dart`
- `packages/map_battle/lib/src/domain/ai/move_heuristic.dart`
- `packages/map_battle/lib/src/domain/ai/switch_heuristic.dart`
- `packages/map_battle/lib/src/domain/ai/item_heuristic.dart`
- `packages/map_battle/test/psdk_battle_ai_policy_test.dart`
- `packages/map_battle/test/psdk_battle_ai_heuristics_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/domain/battle/battle_setup.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`

### Fichiers a supprimer a la fin du cutover

- `packages/map_battle/lib/src/battle_opponent_policy.dart`

### Logique a mettre en place

Capabilities PSDK :

- see power ;
- see effectiveness ;
- see move kind ;
- can switch ;
- can use item ;
- can heal ;
- can choose target ;
- can flee ;
- can read opponent movepool ;
- can mega evolve, si le projet le garde.

L'IA retourne des `BattleAction`, pas un simple move index.

### Code a mettre en place

Policy :

```dart
abstract interface class BattleAiPolicy {
  BattleAction chooseAction({
    required BattleContext context,
    required BattleBattler battler,
  });
}

final class GenericBattleAi implements BattleAiPolicy {
  const GenericBattleAi({
    required this.level,
    required this.moveHeuristic,
    required this.switchHeuristic,
    required this.itemHeuristic,
  });

  final BattleAiLevel level;
  final MoveHeuristic moveHeuristic;
  final SwitchHeuristic switchHeuristic;
  final ItemHeuristic itemHeuristic;

  @override
  BattleAction chooseAction({
    required BattleContext context,
    required BattleBattler battler,
  }) {
    final itemAction = itemHeuristic.choose(context, battler, level);
    if (itemAction != null) {
      return itemAction;
    }

    final switchAction = switchHeuristic.choose(context, battler, level);
    if (switchAction != null) {
      return switchAction;
    }

    return moveHeuristic.choose(context, battler, level);
  }
}
```

Move heuristic :

```dart
final class MoveHeuristic {
  const MoveHeuristic();

  AttackAction choose(
    BattleContext context,
    BattleBattler battler,
    BattleAiLevel level,
  ) {
    final scored = <ScoredMoveAction>[];
    for (var index = 0; index < battler.moves.length; index += 1) {
      final move = battler.moves[index];
      if (!move.hasPp) {
        continue;
      }
      final target = context.targetResolver.bestDefaultTarget(battler, move);
      final score = _score(context, battler, move, target, level);
      scored.add(ScoredMoveAction(index, target?.slot, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    return AttackAction(
      actor: battler.slot,
      moveSlot: best.moveSlot,
      target: best.target,
    );
  }
}
```

### Pourquoi ce lot existe

Le runtime ne doit pas choisir les actions adverses. PSDK garde l'IA dans la
logique combat, ce qui rend les tests deterministes et les niveaux trainer
portables.

### Comment le mettre en place

- Mapper wild battle vers un niveau simple.
- Mapper trainer battle vers un niveau configure dans setup.
- Ajouter d'abord heuristique "meilleur damage attendu".
- Ajouter switch/item par capabilities ensuite.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_battle_ai_policy_test.dart
dart test test/psdk_battle_ai_heuristics_test.dart
```

### Points d'attention

- L'IA doit utiliser les memes resolvers que le joueur, pas dupliquer type chart
  ou damage formula.
- Les decisions IA doivent etre deterministes avec `generic_rng`.

---

## Lot 19 - Capture, fuite, EXP et fin de combat

### But

Remplacer les simplifications actuelles : capture auto-success, flee
auto-success, outcome minimal.

### Fichiers a creer

- `packages/map_battle/lib/src/domain/handler/flee_handler.dart`
- `packages/map_battle/lib/src/domain/handler/catch_handler.dart`
- `packages/map_battle/lib/src/domain/handler/exp_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_end_handler.dart`
- `packages/map_battle/lib/src/domain/capture/capture_formula.dart`
- `packages/map_battle/lib/src/domain/outcome/battle_outcome_writer.dart`
- `packages/map_battle/test/psdk_catch_handler_test.dart`
- `packages/map_battle/test/psdk_flee_handler_test.dart`
- `packages/map_battle/test/psdk_exp_handler_test.dart`
- `packages/map_battle/test/psdk_battle_end_handler_test.dart`

### Fichiers a modifier

- `packages/map_battle/lib/src/domain/action/flee_action.dart`
- `packages/map_battle/lib/src/domain/action/item_action.dart`
- `packages/map_battle/lib/src/domain/battle/battle_outcome.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/battle_session.dart`

### Fichiers a supprimer

- Toute logique legacy de capture/fuite dans `battle_session.dart` une fois la
  facade retiree.

### Logique a mettre en place

- `FleeHandler` interdit flee en trainer battle sauf regle speciale.
- `CatchHandler` produit :
  - nombre de shakes ;
  - success/failure ;
  - ball used ;
  - caught battler ;
  - ball fetch ou hooks plus tard.
- `BattleEndHandler` decide victory/defeat/flee/caught/draw.
- `ExpHandler` produit une sortie claire pour runtime, meme si l'application de
  l'EXP reste cote gameplay/runtime.

### Code a mettre en place

Catch result :

```dart
final class BattleCatchResult {
  const BattleCatchResult({
    required this.success,
    required this.shakes,
    required this.ballItemId,
    required this.target,
  });

  final bool success;
  final int shakes;
  final String ballItemId;
  final BattleSlotRef target;
}
```

Catch handler :

```dart
final class CatchHandler {
  CatchHandler(this._context);

  final BattleContext _context;

  BattleCatchResult attempt({
    required String ballItemId,
    required BattleBattler target,
    required BattleTimelineBuilder timeline,
  }) {
    if (!_context.rules.allowCapture || _context.rules.isTrainerBattle) {
      timeline.add(BattleCaptureBlockedEvent(
        turn: _context.turn,
        ballItemId: ballItemId,
        target: target.slot,
      ));
      return BattleCatchResult(
        success: false,
        shakes: 0,
        ballItemId: ballItemId,
        target: target.slot,
      );
    }

    final shakes = CaptureFormula(_context).shakeCount(
      ballItemId: ballItemId,
      target: target,
    );
    final success = shakes >= 4;
    timeline.add(BattleCaptureAttemptEvent(
      turn: _context.turn,
      ballItemId: ballItemId,
      target: target.slot,
      shakes: shakes,
      success: success,
    ));

    if (success) {
      _context.outcome = BattleOutcome.caught(target.instanceId);
    }
    return BattleCatchResult(
      success: success,
      shakes: shakes,
      ballItemId: ballItemId,
      target: target.slot,
    );
  }
}
```

### Pourquoi ce lot existe

Capture/fuite/EXP sont des parties visibles du combat Pokemon. Les garder en
MVP simplifie casse le contrat "100% PSDK".

### Comment le mettre en place

- Porter d'abord les sorties et les blocks trainer/wild.
- Ajouter la formule capture exacte ensuite.
- Garder l'application persistante au runtime : le moteur retourne l'outcome,
  il ne modifie pas la sauvegarde.

### Tests et commandes

```bash
cd packages/map_battle
dart test test/psdk_catch_handler_test.dart
dart test test/psdk_flee_handler_test.dart
dart test test/psdk_exp_handler_test.dart
dart test test/psdk_battle_end_handler_test.dart
```

### Points d'attention

- Le moteur peut calculer l'EXP, mais le runtime/gameplay decide comment
  l'appliquer a la sauvegarde.
- La capture doit produire assez d'events pour l'animation des shakes.

---

## Lot 20 - Cutover `map_runtime`

### But

Brancher le runtime sur le nouveau moteur PSDK et supprimer le bridge de moves
Showdown.

### Fichiers a creer

- `packages/map_runtime/lib/src/application/runtime_battle_psdk_setup_adapter.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_psdk_catalog_adapter.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_psdk_timeline_adapter.dart`
- `packages/map_runtime/test/runtime_battle_psdk_setup_adapter_test.dart`
- `packages/map_runtime/test/runtime_battle_psdk_timeline_adapter_test.dart`

### Fichiers a modifier

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart`
- battle overlay/menu files under `packages/map_runtime/lib/src/presentation/flame/`

### Fichiers a supprimer a la fin du lot

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

### Logique a mettre en place

- Adapter les catalogues runtime vers `BattleCatalogs`.
- Adapter party/reserves vers banks/parties/slots.
- Envoyer `BattleDecision` riche au moteur.
- Consommer `BattleDecisionRequest` pour menus.
- Consommer `BattleTimeline` pour animations/messages.
- Appliquer `BattleOutcome` a la sauvegarde.
- Remplacer `showdownMoveId` par `psdkDbSymbol` ou `animationMoveId`.

### Code a mettre en place

Setup adapter :

```dart
final class RuntimeBattlePsdkSetupAdapter {
  const RuntimeBattlePsdkSetupAdapter({
    required RuntimeBattlePsdkCatalogAdapter catalogAdapter,
  }) : _catalogAdapter = catalogAdapter;

  final RuntimeBattlePsdkCatalogAdapter _catalogAdapter;

  BattleSetup buildSetup(RuntimeBattleLaunchContext context) {
    return BattleSetup(
      rules: BattleRules(
        isTrainerBattle: context.trainerBattle != null,
        allowCapture: context.trainerBattle == null,
        allowExp: true,
      ),
      banks: <BattleBankSetup>[
        _playerBank(context),
        _opponentBank(context),
      ],
      catalogs: _catalogAdapter.buildCatalogs(context.projectCatalogs),
      rngSeeds: BattleRngSeeds.fromBaseSeed(context.battleSeed),
    );
  }
}
```

Visual resolver :

```dart
String resolveMoveAnimationKey({
  required PokemonMove canonicalMove,
  required BattleMoveData battleMove,
}) {
  final explicit = canonicalMove.sourceRefs?.psdkAnimationId;
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  return canonicalMove.sourceRefs?.psdkDbSymbol ?? battleMove.dbSymbol;
}
```

Timeline adapter :

```dart
final class RuntimeBattlePsdkTimelineAdapter {
  const RuntimeBattlePsdkTimelineAdapter();

  List<BattleAnimationStep> toAnimationSteps(BattleTimeline timeline) {
    final steps = <BattleAnimationStep>[];
    for (final event in timeline.events) {
      switch (event) {
        case BattleMoveDeclaredEvent():
          steps.add(BattleAnimationStep.messageForMove(event.moveDbSymbol));
        case BattleAnimationCueEvent():
          steps.add(BattleAnimationStep.playMoveAnimation(
            moveDbSymbol: event.moveDbSymbol,
            user: event.user,
            targets: event.targets,
          ));
        case BattleDamageEvent():
          steps.add(BattleAnimationStep.hpChange(
            target: event.target,
            delta: -event.amount,
            remainingHp: event.remainingHp,
            maxHp: event.maxHp,
          ));
        case BattleStatusChangedEvent():
          steps.add(BattleAnimationStep.status(event.target, event.status));
        default:
          steps.add(BattleAnimationStep.fromTimelineEvent(event));
      }
    }
    return steps;
  }
}
```

### Pourquoi ce lot existe

Le runtime est l'endroit ou l'ancien moteur devient visible. Tant que le bridge
existe, on n'a pas vraiment coupe Showdown.

### Comment le mettre en place

- Brancher un combat wild simple d'abord.
- Brancher trainer battle ensuite.
- Brancher bag/switch/capture apres handlers.
- Adapter les tests golden seulement quand les events timeline sont stables.

### Tests et commandes

```bash
cd packages/map_runtime
flutter test test/runtime_battle_psdk_setup_adapter_test.dart
flutter test test/runtime_battle_psdk_timeline_adapter_test.dart
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
flutter analyze
```

### Points d'attention

- Ne pas deplacer les regles dans les adapters runtime.
- Les overlays doivent afficher ce que `BattleDecisionRequest` autorise, pas
  recalculer les choix autorises.

---

## Lot 21 - Cutover `map_editor` UI et suppression Showdown

### But

Faire disparaitre Showdown de l'experience editor : wording, providers,
repository, tests et use cases.

### Fichiers a creer

- `packages/map_editor/lib/src/app/providers/pokedex/pokemon_sdk_import_providers.dart`
- `packages/map_editor/test/ui/pokemon_sdk_import_flow_test.dart`

### Fichiers a modifier

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- tests provider/use case/UI qui mentionnent Showdown.

### Fichiers a supprimer

- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`
- `packages/map_editor/test/application/services/showdown_move_catalog_converter_test.dart`
- `packages/map_editor/test/application/services/showdown_pokemon_species_converter_test.dart`
- `packages/map_editor/test/infrastructure/external/showdown_snapshot_source_test.dart`

### Logique a mettre en place

- Le bouton/action devient "Importer Pokemon SDK".
- L'UI demande un dossier projet PSDK ou `Data/Studio`.
- Les warnings parlent de Studio data manquantes, pas de callbacks Showdown.
- La normalisation principale est `normalizePokemonSdkStudioCatalog`.
- PokeAPI reste uniquement comme enrichissement non-combat si accepte.

### Code a mettre en place

Provider :

```dart
final pokemonSdkStudioSourceProvider = Provider<PokemonSdkStudioSource>((ref) {
  return const PokemonSdkStudioSource();
});

final pokemonSdkMoveCatalogConverterProvider =
    Provider<PokemonSdkMoveCatalogConverter>((ref) {
  return const PokemonSdkMoveCatalogConverter();
});

final syncPokemonSdkMovesCatalogUseCaseProvider =
    Provider<SyncPokemonSdkMovesCatalogUseCase>((ref) {
  return SyncPokemonSdkMovesCatalogUseCase(
    source: ref.watch(pokemonSdkStudioSourceProvider),
    converter: ref.watch(pokemonSdkMoveCatalogConverterProvider),
    repository: ref.watch(pokemonProjectCatalogRepositoryProvider),
  );
});
```

Normalizer :

```dart
PokemonCatalogNormalizationResult normalizePokemonSdkStudioCatalog({
  required List<PokemonMove> moves,
}) {
  final byDbSymbol = <String, PokemonMove>{};
  final warnings = <String>[];
  for (final move in moves) {
    final previous = byDbSymbol[move.dbSymbol];
    if (previous != null) {
      warnings.add('duplicate_psdk_move:${move.dbSymbol}');
    }
    byDbSymbol[move.dbSymbol] = move;
  }
  return PokemonCatalogNormalizationResult(
    moves: byDbSymbol.values.toList()
      ..sort((a, b) => a.dbSymbol.compareTo(b.dbSymbol)),
    warnings: warnings,
  );
}
```

### Pourquoi ce lot existe

La suppression Showdown ne doit pas etre seulement technique. Si l'UI continue
de proposer Showdown, les donnees projet resteront hybrides.

### Comment le mettre en place

- Supprimer les imports Showdown en une fois dans editor.
- Adapter les tests de wording.
- Garder un seul chemin principal : Pokemon SDK Studio.

### Tests et commandes

```bash
cd packages/map_editor
flutter test test/ui/pokemon_sdk_import_flow_test.dart
flutter test
flutter analyze
```

### Points d'attention

- Le package `http` peut rester si PokeAPI reste utilisee ailleurs. Ne pas le
  retirer sans verifier tout `map_editor`.
- Les tests de provider wiring sont souvent les premiers a casser apres renommage.

---

## Lot 22 - Golden runtime host et fixtures projet

### But

Mettre les fixtures runtime sur les catalogues PSDK et prouver un combat jouable
de bout en bout.

### Fichiers a modifier

- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`
- `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`
- `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- tests sous `examples/playable_runtime_host/test/`

### Fichiers a creer

- `examples/playable_runtime_host/test/psdk_golden_battle_launch_test.dart`
- `examples/playable_runtime_host/test/psdk_golden_capture_flow_test.dart`

### Fichiers a supprimer

- Fixtures moves qui ne contiennent que des refs Showdown, si remplacees par
  PSDK.

### Logique a mettre en place

- Moves demo doivent avoir `dbSymbol` et `battleEngineMethod`.
- La party demo utilise des moves couverts par les lots 14/16.
- Le golden battle slice couvre :
  - move damaging ;
  - status move ;
  - switch ou forced replacement ;
  - capture wild si fixture wild ;
  - animation cue par `dbSymbol`.

### Code a mettre en place

Seed demo :

```dart
const runtimeDemoMoveDbSymbols = <String>[
  'tackle',
  'vine_whip',
  'thunder_wave',
  'protect',
];

RuntimeDemoPartySeed buildRuntimeDemoPartySeed(PokemonCatalogs catalogs) {
  final moves = runtimeDemoMoveDbSymbols
      .map(catalogs.moves.requireByDbSymbol)
      .toList(growable: false);
  return RuntimeDemoPartySeed.withMoves(moves);
}
```

### Pourquoi ce lot existe

Le moteur peut passer les tests unitaires et casser l'integration reelle. Le
golden host verrouille le chemin complet : catalogues -> setup -> engine ->
timeline -> runtime.

### Comment le mettre en place

- Remplacer le catalogue moves avec l'outil du Lot 3.
- Verifier que les moves demo existent dans le registry du Lot 14/16.
- Mettre a jour les assertions golden autour de la timeline, pas autour des
  anciens buckets.

### Tests et commandes

```bash
cd examples/playable_runtime_host
flutter test test/psdk_golden_battle_launch_test.dart
flutter test
flutter analyze
```

### Points d'attention

- Ne pas inclure un move non porte dans la party demo.
- Garder les fixtures petites pour faciliter les diffs.

---

## Lot 23 - Suppression finale du legacy battle Showdown/MVP

### But

Retirer les anciens fichiers et references Showdown/MVP une fois le cutover
termine.

### Fichiers a supprimer dans `map_battle`

- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_condition_side_conditions.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/battle_move.dart`, si remplace totalement.

### Fichiers a supprimer dans `map_runtime`

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

### Fichiers a supprimer dans `map_editor`

- Tous les fichiers Showdown listes dans le Lot 21.

### Fichiers a modifier

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- tous les tests qui importent des legacy types.

### Logique a mettre en place

- Le barrel public exporte uniquement les nouveaux types PSDK.
- Les tests legacy sont supprimes ou reecrits vers PSDK.
- `rg` ne trouve plus Showdown dans le code actif.
- Les docs v3 restent historiques, pas source canonique.

### Code a mettre en place

Barrel final `packages/map_battle/lib/map_battle.dart` :

```dart
library map_battle;

export 'src/application/battle_engine.dart';
export 'src/application/battle_session_facade.dart';
export 'src/domain/action/battle_action.dart';
export 'src/domain/ai/battle_ai_policy.dart';
export 'src/domain/battle/battle_battler.dart';
export 'src/domain/battle/battle_context.dart' show BattlePublicState;
export 'src/domain/battle/battle_outcome.dart';
export 'src/domain/battle/battle_setup.dart';
export 'src/domain/decision/battle_decision.dart';
export 'src/domain/effect/battle_effect.dart';
export 'src/domain/move/battle_move_data.dart';
export 'src/domain/move/battle_move_instance.dart';
export 'src/domain/move/battle_move_registry.dart';
export 'src/domain/timeline/battle_timeline.dart';
export 'src/domain/timeline/battle_timeline_event.dart';
export 'src/domain/type/battle_type.dart';
```

Verification de purge :

```bash
rg -n \
  "showdown|Showdown|Pokemon Showdown|showdownMoveId|showdownHooksPresent|showdown_callback" \
  packages examples docs
```

Resultat attendu :

- aucune occurrence dans `packages/` et `examples/` ;
- occurrences acceptees uniquement dans anciens rapports historiques, si on
  choisit de ne pas les nettoyer.

### Pourquoi ce lot existe

La migration n'est finie que quand le code legacy n'existe plus dans le chemin
actif. Sinon les prochains devs continueront a brancher des choses au mauvais
endroit.

### Comment le mettre en place

- Faire ce lot apres runtime/editor cutover.
- Supprimer fichiers, lancer analyse, corriger imports.
- Ne pas melanger avec de nouvelles features battle.

### Tests et commandes

```bash
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
rg -n "showdown|Showdown|Pokemon Showdown|showdownMoveId|showdownHooksPresent|showdown_callback" packages examples docs
```

### Points d'attention

- Les anciens rapports dans `reports/` peuvent mentionner Showdown. Ce n'est pas
  un probleme si le code actif est propre.
- Ne pas supprimer une fixture encore utilisee par un test golden sans la
  remplacer dans le meme lot.

---

## Lot 24 - Docs canoniques v4 PSDK

### But

Documenter le nouveau combat comme source de verite et rendre les docs v3
historiques.

### Fichiers a creer

- `docs/combat/battle-canonical-state-v4-psdk.md`
- `docs/combat/battle-roadmap-v4-psdk.md`

### Fichiers a modifier

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`

### Fichiers a supprimer

Aucun, sauf decision explicite de nettoyage documentaire.

### Logique a mettre en place

La doc v4 doit contenir :

- sources PSDK utilisees ;
- structure `map_battle` ;
- contrats `map_core` ;
- import Studio ;
- battle setup ;
- decision request ;
- action scheduler ;
- move procedure ;
- damage formula ;
- effect hooks ;
- timeline ;
- runtime cutover ;
- politique de tests parity ;
- statut des matrices move/effect.

### Code/document a mettre en place

Entete conseille :

```markdown
# Battle Canonical State v4 - Pokemon SDK Engine

Status: canonical
Date: 2026-04-24

This document supersedes `battle-canonical-state-v3.1.md` for active battle
development. Version 3.1 remains historical context for the pre-PSDK MVP.
```

### Pourquoi ce lot existe

La refonte est assez large pour necessiter une source de verite stable. Sinon
le code, les fixtures et les rapports vont diverger.

### Comment le mettre en place

- Rediger v4 apres que les contrats des lots 1, 4, 6, 7, 10 soient stabilises.
- Mettre un court avertissement en tete des docs v3.1.
- Ne pas recopier le rapport entier ; documenter l'etat canonique final.

### Tests et commandes

```bash
rg -n "canonical|Pokemon SDK|Showdown|BattleTimeline|BattleEffect" docs/combat
```

### Points d'attention

- Le dossier `docs/` est partiellement ignore dans ce repo. Verifier que les
  nouveaux fichiers sont bien suivis si on veut les versionner.

---

## Ordre recommande des lots

1. Lot 1 : contrats `map_core`.
2. Lot 2 : source Studio + converter.
3. Lot 3 : sync/bootstrap catalogues.
4. Lot 4 : squelette moteur.
5. Lot 5 : battlers/topology.
6. Lot 6 : RNG/timeline.
7. Lot 7 : move registry.
8. Lot 10 : effect stack.
9. Lot 11 : handlers.
10. Lot 8 : move procedure.
11. Lot 9 : damage/type.
12. Lot 12 : status/weather/hazards.
13. Lot 13 : actions/scheduler.
14. Lot 14 : tranche fondamentale de moves.
15. Lot 15 : matrices de portage.
16. Lot 16 : familles moves avancees.
17. Lot 17 : abilities/items.
18. Lot 18 : AI.
19. Lot 19 : capture/fuite/EXP/end.
20. Lot 20 : cutover runtime.
21. Lot 21 : cutover editor UI.
22. Lot 22 : golden host.
23. Lot 24 : docs v4.
24. Lot 23 : suppression finale legacy.

Les lots 15 et 24 peuvent demarrer plus tot en parallele s'ils ne bloquent pas
les contrats en cours.

---

## Matrice de validation finale

Commandes finales a executer apres Lot 23 :

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
rg -n "showdown|Showdown|Pokemon Showdown|showdownMoveId|showdownHooksPresent|showdown_callback" packages examples docs
```

Resultat attendu :

- tous les tests passent ;
- aucune reference Showdown dans `packages/` ou `examples/` ;
- les seules references Showdown restantes sont historiques, dans `reports/` ou
  docs explicitement archivees ;
- le runtime lance un combat demo base sur moves PSDK Studio ;
- les animations consomment `BattleTimeline` et `dbSymbol`/`animationMoveId`.

