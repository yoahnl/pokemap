import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as path;

final class ConverterPlayableStartSpawn {
  const ConverterPlayableStartSpawn({required this.id, required this.name});
  final String id;
  final String name;
}

final class ConverterPlayableStartMap {
  ConverterPlayableStartMap(
      {required this.id,
      required this.name,
      required Iterable<ConverterPlayableStartSpawn> spawns})
      : spawns = List.unmodifiable(spawns);
  final String id;
  final String name;
  final List<ConverterPlayableStartSpawn> spawns;
}

final class ConverterPlayableStartAvatar {
  const ConverterPlayableStartAvatar({required this.id, required this.name});
  final String id;
  final String name;
}

final class ConverterPlayableStartSpecies {
  const ConverterPlayableStartSpecies({required this.id, required this.name});
  final String id;
  final String name;
}

final class ConverterPlayableStartInspection {
  ConverterPlayableStartInspection(
      {required this.revision,
      required Iterable<ConverterPlayableStartMap> maps,
      required Iterable<ConverterPlayableStartAvatar> avatars,
      required Iterable<ConverterPlayableStartSpecies> species,
      this.configured = false,
      this.existingNewGame = false,
      this.resumable = false})
      : maps = List.unmodifiable(maps),
        avatars = List.unmodifiable(avatars),
        species = List.unmodifiable(species);
  final String revision;
  final List<ConverterPlayableStartMap> maps;
  final List<ConverterPlayableStartAvatar> avatars;
  final List<ConverterPlayableStartSpecies> species;
  final bool configured;
  final bool existingNewGame;
  final bool resumable;
}

final class ConverterPlayableStartReceipt {
  const ConverterPlayableStartReceipt(
      {required this.newGameReceipt,
      required this.preSessionReceipt,
      required this.finalRevision,
      required this.resumed});
  final AuthoringReceipt newGameReceipt;
  final AuthoringReceipt preSessionReceipt;
  final String finalRevision;
  final bool resumed;
}

final class ConverterPlayableStartException implements Exception {
  const ConverterPlayableStartException(this.code, this.message,
      {this.newGameReceipt, this.preSessionReceipt, this.revision});
  final String code;
  final String message;
  final AuthoringReceipt? newGameReceipt;
  final AuthoringReceipt? preSessionReceipt;
  final String? revision;
  @override
  String toString() => '$code: $message';
}

final class ConverterPlayableStartService {
  const ConverterPlayableStartService();

  static const sceneId = 'converter-native-start';

  Future<ConverterPlayableStartInspection> inspect(
      {required String projectPath, required String allowedRootPath}) async {
    final session = await _StartSession.open(projectPath, allowedRootPath);
    try {
      final snapshot = await session.load();
      final config = snapshot.manifest.newGame;
      final owned = _ownedConfig(config);
      final scene =
          snapshot.manifest.scenes.where((entry) => entry.id == sceneId);
      final resumable =
          owned && config.preSessionSceneId == null && scene.isEmpty;
      if (config.enabled && !resumable) {
        _validateExistingNewGame(snapshot);
        return ConverterPlayableStartInspection(
            revision: snapshot.revision,
            maps: [
              for (final map in snapshot.maps)
                ConverterPlayableStartMap(id: map.id, name: map.name, spawns: [
                  for (final entity in map.entities)
                    if (_playerSpawn(entity))
                      ConverterPlayableStartSpawn(
                          id: entity.id, name: entity.name),
                ]),
            ],
            avatars: const [],
            species: const [],
            configured: true,
            existingNewGame: true);
      }
      final data = await _loadData(session, snapshot);
      return ConverterPlayableStartInspection(
          revision: snapshot.revision,
          maps: [
            for (final map in snapshot.maps)
              ConverterPlayableStartMap(id: map.id, name: map.name, spawns: [
                for (final entity in map.entities)
                  if (_playerSpawn(entity))
                    ConverterPlayableStartSpawn(
                        id: entity.id, name: entity.name),
              ])
          ],
          avatars: [
            ConverterPlayableStartAvatar(
                id: data.avatar.id, name: data.avatar.name)
          ],
          species: [
            for (final species in data.species.values)
              ConverterPlayableStartSpecies(
                  id: species.id,
                  name:
                      species.names['fr'] ?? species.names['en'] ?? species.id)
          ],
          resumable: resumable);
    } finally {
      await session.close();
    }
  }

  void _validateExistingNewGame(ProjectSnapshot snapshot) {
    try {
      final config = snapshot.manifest.newGame;
      final project = const CampaignContentActions()
          .updateNewGame(snapshot.manifest, config, maps: snapshot.maps);
      final map = snapshot.mapById(config.startMapId.trim());
      if (map == null) throw StateError('Missing authored start map.');
      MapValidator.validate(map, projectDialogueContext: project);
      final configuredSpawn = config.startSpawnId?.trim();
      final defaultSpawn = map.mapMetadata.defaultSpawnId?.trim();
      final preferred = configuredSpawn?.isNotEmpty == true
          ? configuredSpawn
          : defaultSpawn?.isNotEmpty == true
              ? defaultSpawn
              : null;
      final candidates = map.entities.where(_playerSpawn).toList()
        ..sort((left, right) => left.id.compareTo(right.id));
      final spawn = preferred == null
          ? candidates.firstOrNull
          : map.entities.where((entity) => entity.id == preferred).firstOrNull;
      if (spawn == null ||
          !_playerSpawn(spawn) ||
          spawn.pos.x < 0 ||
          spawn.pos.y < 0 ||
          spawn.pos.x >= map.size.width ||
          spawn.pos.y >= map.size.height) {
        throw StateError('Missing or invalid authored player spawn.');
      }
      final sceneId = config.preSessionSceneId?.trim();
      if (sceneId != null && sceneId.isNotEmpty) {
        final scene =
            project.scenes.singleWhere((entry) => entry.id == sceneId);
        if (!buildSceneRuntimePlan(scene).canBuild) {
          throw StateError(
              'The authored entry Scene cannot build a native plan.');
        }
      }
      final state = createNewGameStateFromProject(
          project: project,
          startMap: map,
          initialRecoveryMap:
              snapshot.mapById(config.initialRecoveryPoint?.mapId ?? ''),
          tileWidthPx: project.settings.tileWidth,
          tileHeightPx: project.settings.tileHeight);
      if (state.currentMapId != map.id || state.playerPosition != spawn.pos) {
        throw StateError(
            'The native builder did not preserve the authored entry.');
      }
    } on Object {
      throw const ConverterPlayableStartException(
          'playable_start.existing_invalid',
          'Le démarrage déclaré est invalide. Vérifiez sa carte, son point de départ, sa scène et son point de récupération dans Studio.');
    }
  }

  Future<ConverterPlayableStartReceipt> apply(
      {required String projectPath,
      required String allowedRootPath,
      required String expectedRevision,
      required String mapId,
      required String spawnId,
      required List<String> starterSpeciesIds,
      int starterLevel = 5}) async {
    final session = await _StartSession.open(projectPath, allowedRootPath);
    AuthoringReceipt? newGameReceipt;
    AuthoringReceipt? preSessionReceipt;
    try {
      final snapshot = await session.load();
      if (snapshot.revision != expectedRevision) {
        throw const ConverterPlayableStartException(
            'playable_start.stale_revision',
            'Le projet a changé. Relis les choix avant de configurer son départ.');
      }
      final authored = snapshot.manifest.newGame;
      if (authored.enabled &&
          (!_ownedConfig(authored) || authored.preSessionSceneId != null)) {
        throw const ConverterPlayableStartException(
            'playable_start.already_authored',
            'Un départ ou une scène existe déjà. Il ne sera pas remplacé.');
      }
      final ids = List<String>.of(starterSpeciesIds)..sort();
      if (ids.length < 2 ||
          ids.length > 6 ||
          ids.toSet().length != ids.length ||
          ids.any((id) => id.isEmpty || id != id.trim()) ||
          starterLevel < 1 ||
          starterLevel > 100) {
        throw const ConverterPlayableStartException(
            'playable_start.invalid_selection',
            'Choisis entre deux et six starters différents et un niveau entre 1 et 100.');
      }
      final startMap = snapshot.mapById(mapId);
      if (startMap == null ||
          !startMap.entities
              .any((entity) => entity.id == spawnId && _playerSpawn(entity))) {
        throw const ConverterPlayableStartException(
            'playable_start.spawn_unavailable',
            'La carte et son point de départ joueur doivent exister.');
      }
      resolveInitialPlayerSpawn(startMap,
          preferredSpawnId: spawnId,
          tileWidthPx: snapshot.manifest.settings.tileWidth,
          tileHeightPx: snapshot.manifest.settings.tileHeight);
      final data = await _loadData(session, snapshot);
      final config = ProjectNewGameConfig(
          enabled: true,
          startMapId: mapId,
          startSpawnId: spawnId,
          playerAvatarCharacterIds: [
            data.avatar.id
          ],
          starterOptions: [
            for (final id in ids)
              ProjectStarterOption(
                  id: 'converter-starter-$id',
                  label: data.species[id]?.names['fr'] ??
                      data.species[id]?.names['en'] ??
                      id,
                  pokemon: data.starter(id, starterLevel, mapId))
          ]);
      final existing = snapshot.manifest.newGame;
      final resuming = _same(existing.toJson(), config.toJson());
      if ((!resuming &&
              !_same(
                  existing.toJson(), const ProjectNewGameConfig().toJson())) ||
          snapshot.manifest.scenes.any((entry) => entry.id == sceneId)) {
        throw const ConverterPlayableStartException(
            'playable_start.already_authored',
            'Un départ ou une scène existe déjà. Il ne sera pas remplacé.');
      }
      final projected = snapshot.manifest.copyWith(newGame: config);
      ProjectValidator.validate(projected, maps: snapshot.maps);
      const SceneActions().createPreSessionScene(projected,
          maps: snapshot.maps,
          sceneId: sceneId,
          name: 'Départ natif Avelune',
          templateId: 'identitySetup',
          setAsEntrypoint: true);
      await session.attach();
      final digest =
          sha256.convert(utf8.encode(jsonEncode(config.toJson()))).toString();
      final operation = 'converter-start-$digest';
      String nextRevision = expectedRevision;
      if (resuming) {
        final prior = await session.findReceipt('$operation-new-game');
        if (prior == null || prior.actionId != 'campaign.new_game.update') {
          throw const ConverterPlayableStartException(
              'playable_start.resume_unproven',
              'La configuration ressemble à un départ partiel mais son reçu canonique manque.');
        }
        newGameReceipt = prior;
      } else {
        final result = await session.mutate(
            'campaign.new_game.update',
            {'newGame': config.toJson()},
            expectedRevision,
            '$operation-new-game');
        newGameReceipt = result.receipt;
        if (result.snapshotRevision == null) {
          throw StateError(
              'La première action est enregistrée ; sa révision doit être relue.');
        }
        nextRevision = result.snapshotRevision!;
      }
      final afterFirst = await session.load();
      if (afterFirst.revision != nextRevision ||
          !_same(afterFirst.manifest.newGame.toJson(), config.toJson())) {
        throw StateError('Le départ a changé entre les deux actions.');
      }
      final result = await session.mutate(
          'scene.preSession.create',
          {
            'sceneId': sceneId,
            'name': 'Départ natif Avelune',
            'templateId': 'identitySetup',
            'setAsEntrypoint': true,
          },
          afterFirst.revision,
          '$operation-pre-session');
      preSessionReceipt = result.receipt;
      final finalSnapshot = await session.load();
      if (finalSnapshot.manifest.newGame.preSessionSceneId != sceneId) {
        throw StateError('La scène de départ n’est pas liée.');
      }
      return ConverterPlayableStartReceipt(
          newGameReceipt: newGameReceipt,
          preSessionReceipt: result.receipt,
          finalRevision: finalSnapshot.revision,
          resumed: resuming);
    } on Object catch (error) {
      if (newGameReceipt != null) {
        String? revision;
        try {
          revision = (await session.load()).revision;
        } on Object {
          revision = null;
        }
        throw ConverterPlayableStartException(
            preSessionReceipt == null
                ? 'playable_start.pre_session_failed'
                : 'playable_start.refresh_required',
            preSessionReceipt == null
                ? 'Le départ natif est enregistré, mais sa scène doit être relue puis reprise. $error'
                : 'Les deux actions natives sont enregistrées. Relis le projet pour vérifier leur résultat. $error',
            newGameReceipt: newGameReceipt,
            preSessionReceipt: preSessionReceipt,
            revision: revision);
      }
      rethrow;
    } finally {
      await session.close();
    }
  }

  Future<_StartData> _loadData(
      _StartSession session, ProjectSnapshot snapshot) async {
    final project = snapshot.manifest;
    if (!project.pokemon.enabled) {
      throw const ConverterPlayableStartException(
          'playable_start.catalog_disabled',
          'Active le catalogue Pokémon natif avant de configurer le départ.');
    }
    final avatarId = project.settings.defaultPlayerCharacterId;
    final avatars =
        project.characters.where((entry) => entry.id == avatarId).toList();
    if (avatars.length != 1) {
      throw const ConverterPlayableStartException(
          'playable_start.avatar_unavailable',
          'Le personnage joueur importé doit être disponible.');
    }
    final coherence = await session.snapshots
        .validatePokemonCatalog(session.project, project);
    if (!coherence.canPlaytest) {
      throw ConverterPlayableStartException(
          'playable_start.catalog_invalid',
          'Le catalogue Pokémon natif contient ${coherence.errorCount} erreur(s) : '
              '${coherence.diagnostics.where((entry) => entry.severity == PokemonCatalogDiagnosticSeverity.error).take(3).map((entry) => entry.code).join(', ')}.');
    }
    final species = <String, PokemonSpeciesFile>{};
    final learnsets = <String, PokemonLearnsetFile>{};
    final maxPp = <String, int>{};
    for (final entry in snapshot.resourceStorageKeys.entries) {
      if (!entry.key.startsWith('pokemonSpecies:') &&
          !entry.key.startsWith('pokemonLearnset:') &&
          entry.key != 'pokemonCatalog:moves') {
        continue;
      }
      final bytes = await snapshot.readResourceBytes(entry.key);
      if (bytes == null) continue;
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (entry.key.startsWith('pokemonSpecies:')) {
        final value = PokemonSpeciesFile.fromJson(json);
        species[value.id] = value;
      } else if (entry.key.startsWith('pokemonLearnset:')) {
        final value = PokemonLearnsetFile.fromJson(json);
        learnsets[value.speciesId] = value;
      } else {
        final moves = PokemonCatalogFile.fromJson(json);
        for (final move in moves.entries) {
          if (move['id'] is String && move['pp'] is num) {
            maxPp[move['id'] as String] = (move['pp'] as num).toInt();
          }
        }
      }
    }
    if (species.isEmpty || maxPp.isEmpty) {
      throw const ConverterPlayableStartException(
          'playable_start.catalog_unavailable',
          'Les espèces et capacités natives doivent être résolues.');
    }
    return _StartData(
        avatars.single, species, learnsets, maxPp, project.pokemon.ruleset);
  }
}

bool _playerSpawn(MapEntity entity) =>
    entity.kind == MapEntityKind.spawn &&
    entity.spawn?.role == EntitySpawnRole.playerStart;

bool _ownedConfig(ProjectNewGameConfig config) =>
    config.enabled &&
    config.initialParty.isEmpty &&
    config.starterOptions.length >= 2 &&
    config.starterOptions.every((option) =>
        option.pokemon.provenance?.sourceId ==
        ConverterPlayableStartService.sceneId);

bool _same(Object? left, Object? right) =>
    jsonEncode(left) == jsonEncode(right);

final class _StartData {
  _StartData(
      this.avatar, this.species, this.learnsets, this.maxPp, this.ruleset);
  final ProjectCharacterEntry avatar;
  final Map<String, PokemonSpeciesFile> species;
  final Map<String, PokemonLearnsetFile> learnsets;
  final Map<String, int> maxPp;
  final PokemonRulesetProfile ruleset;

  PlayerPokemon starter(String id, int level, String mapId) {
    final entry = species[id];
    final learnset = learnsets[id];
    if (entry == null || learnset == null) {
      throw const ConverterPlayableStartException(
          'playable_start.species_unavailable',
          'Une espèce choisie ou son apprentissage est absent du catalogue natif.');
    }
    final hash = sha256.convert(utf8.encode('$id:$level')).toString();
    try {
      final generated = const WildPlayerPokemonGenerator().generate(
          seed: int.parse(hash.substring(0, 7), radix: 16),
          level: level,
          ruleset: ruleset,
          species: WildPokemonGenerationSpecies(
              id: id,
              formId: entry.forms.formId,
              baseStats: PokemonBaseStats(
                  hp: entry.baseStats.hp,
                  attack: entry.baseStats.atk,
                  defense: entry.baseStats.def,
                  specialAttack: entry.baseStats.spa,
                  specialDefense: entry.baseStats.spd,
                  speed: entry.baseStats.spe),
              primaryAbilityId: entry.abilities.primary,
              standardAbilityIds: [
                entry.abilities.primary,
                if (entry.abilities.secondary != null)
                  entry.abilities.secondary!
              ],
              allowedAbilityIds: [
                entry.abilities.primary,
                if (entry.abilities.secondary != null)
                  entry.abilities.secondary!,
                if (entry.abilities.hidden != null) entry.abilities.hidden!
              ],
              genderRatio: entry.breeding.genderRatio,
              growthRateId: entry.progression.growthRateId,
              baseFriendship: entry.progression.baseFriendship),
          learnset: WildPokemonGenerationLearnset(
              startingMoves: learnset.startingMoves,
              relearnMoves: learnset.relearnMoves,
              levelUp: [
                for (final move in learnset.levelUp)
                  WildPokemonLevelUpMove(moveId: move.moveId, level: move.level)
              ]),
          maxPpByMoveId: maxPp,
          context: WildPokemonGenerationContext(
              mapId: mapId, sourceId: ConverterPlayableStartService.sceneId));
      if (generated.pokemon.knownMoveIds.isEmpty ||
          generated.pokemon.currentHp <= 0) {
        throw const FormatException(
            'Le starter n’a aucune capacité utilisable.');
      }
      return generated.pokemon.copyWith(
          individualId: '',
          provenance: PlayerPokemonProvenance(
              kind: PlayerPokemonOriginKind.starter,
              mapId: mapId,
              sourceId: ConverterPlayableStartService.sceneId,
              metLevel: level));
    } on Object catch (error) {
      throw ConverterPlayableStartException('playable_start.starter_invalid',
          'Le starter $id ne peut pas être préparé par les règles natives : $error');
    }
  }
}

final class _StartSession {
  _StartSession(this.opener, this.snapshots, this.policy, this.root,
      this.project, this.workspace);
  final ProjectOpenService opener;
  final ProjectSnapshotLoader snapshots;
  final WorkspacePolicy policy;
  final String root;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  LocalMapAuthoringMutationApi? mutations;

  static Future<_StartSession> open(
      String projectPath, String allowedRootPath) async {
    if (!path.isAbsolute(projectPath) || !path.isAbsolute(allowedRootPath)) {
      throw const ConverterPlayableStartException(
          'playable_start.absolute_path_required',
          'Le projet et sa racine autorisée doivent être absolus.');
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowedRootPath], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(projectPath);
    return _StartSession(
        opener,
        snapshots,
        policy,
        await Directory(projectPath).resolveSymbolicLinks(),
        opened.projectHandle,
        opened.workspaceHandle);
  }

  Future<ProjectSnapshot> load() => snapshots.load(project);

  Future<void> attach() async {
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await api.attachProject(
        projectRootPath: root,
        workspaceHandle: workspace,
        projectHandle: project);
    mutations = api;
  }

  Future<AuthoringReceipt?> findReceipt(String operationId) async {
    String? cursor;
    do {
      final page = await mutations!
          .listMutationHistory(project, limit: 100, cursor: cursor);
      for (final entry in page.entries) {
        if (entry.operationId == operationId) return entry.receipt;
      }
      cursor = page.nextCursor?.wireValue;
    } while (cursor != null);
    return null;
  }

  Future<AuthoringMutationResult> mutate(
      String actionId,
      Map<String, Object?> parameters,
      String revision,
      String operationId) async {
    final plan = await mutations!.planMutation(
        project,
        AuthoringRequest(
            requestId: operationId,
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: workspace.value,
            expectedRevision: revision,
            idempotencyKey: operationId,
            parameters: parameters));
    if (!plan.applicable) {
      throw ConverterPlayableStartException('playable_start.plan_rejected',
          'Le plan natif est refusé : ${plan.nonApplicableReason}.');
    }
    return mutations!
        .applyMutation(project, planId: plan.planId, operationId: operationId);
  }

  Future<void> close() async {
    await mutations?.detachWorkspace(workspace);
    opener.closeWorkspace(workspace);
  }
}
