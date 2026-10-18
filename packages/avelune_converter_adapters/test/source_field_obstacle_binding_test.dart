import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelRect;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_external_original_fixture.dart';
import 'source_cut_obstacle_projection_test.dart' show cutNativeMaps;
import 'support/native_writer_fixture.dart' show approveNativeFixtureDraft;

final class _ObservedFiles implements SourceFilePort {
  _ObservedFiles(this.source, this.delegate, {this.changedPath});
  final NormalizedSourceProject source;
  final SourceFilePort delegate;
  final String? changedPath;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final path = source.snapshot.entries
        .singleWhere((entry) => entry.fileId == id)
        .relativePath;
    reads.add(path);
    final bytes = List<int>.of(await delegate.read(id));
    if (path == changedPath) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

final class _ExplicitOriginalFieldFiles implements SourceFilePort {
  const _ExplicitOriginalFieldFiles(
      this.source, this.primaryRoot, this.donorRoots, this.delegate);
  final NormalizedSourceProject source;
  final String primaryRoot;
  final List<String> donorRoots;
  final SourceFilePort delegate;
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    if (entry.relativePath == 'Data/Scripts.rxdata' ||
        await File('$primaryRoot/${entry.relativePath}').exists()) {
      return delegate.read(id);
    }
    for (final donorRoot in donorRoots) {
      final file = File('$donorRoot/${entry.relativePath}');
      if (await file.exists()) return file.readAsBytes();
    }
    throw StateError(
        'Original source file absent from the explicit source roots: ${entry.relativePath}');
  }
}

final class _Symbol {
  const _Symbol(this.name);
  final String name;
}

List<int> _marshalFixture(Object? value) {
  List<int> packed(int value) {
    if (value == 0) return [0];
    if (value > 0 && value < 123) return [value + 5];
    var width = 1;
    while (value >= 1 << (width * 8)) {
      width++;
    }
    return [
      width,
      for (var index = 0; index < width; index++) (value >> (index * 8)) & 255
    ];
  }

  List<int> symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ...packed(bytes.length), ...bytes];
  }

  List<int> encode(Object? value) {
    if (value == null) return [0x30];
    if (value is int) return [0x69, ...packed(value)];
    if (value is _Symbol) return symbol(value.name);
    if (value is String) {
      final bytes = utf8.encode(value);
      return [0x22, ...packed(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ...packed(value.length),
        for (final child in value) ...encode(child)
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ...packed(value.length),
        for (final entry in value.entries) ...[
          ...encode(entry.key),
          ...encode(entry.value)
        ]
      ];
    }
    if (value case (final String name, final Map<String, Object?> fields)) {
      return [
        0x6f,
        ...symbol(name),
        ...packed(fields.length),
        for (final field in fields.entries) ...[
          ...symbol(field.key),
          ...encode(field.value)
        ]
      ];
    }
    throw ArgumentError('Unsupported bounded encounter fixture');
  }

  return [4, 8, ...encode(value)];
}

List<int> _compiledDeclaration(
        {bool table = true,
        bool chance = false,
        String rootKey = '274_0',
        String id = '274_0'}) =>
    _marshalFixture({
      _Symbol(rootKey): (
        'GameData::Encounter',
        <String, Object?>{
          '@id': _Symbol(id),
          '@map': 274,
          '@version': 0,
          '@step_chances': {if (chance) const _Symbol('RockSmash'): 11},
          '@types': {if (table) const _Symbol('RockSmash'): <Object?>[]},
          '@pbs_file_suffix': '',
        }
      ),
    });

List<int> _replaceOriginalAscii(List<int> source, String before, String after) {
  final old = ascii.encode(before), replacement = ascii.encode(after);
  if (old.length != replacement.length) {
    throw ArgumentError('Equal-length original edit required');
  }
  final matches = <int>[];
  for (var index = 0; index <= source.length - old.length; index++) {
    if (old.indexed.every((entry) => source[index + entry.$1] == entry.$2)) {
      matches.add(index);
    }
  }
  expect(matches, hasLength(1));
  final changed = List<int>.of(source);
  changed.setRange(
      matches.single, matches.single + replacement.length, replacement);
  expect(changed, isNot(source));
  return changed;
}

List<Map<String, Object?>> _assertReopenedFieldMechanics(
    ProjectManifest project, List<MapData> maps) {
  final initialConfig = project.newGame.toJson();
  final badgeDefinitions =
      project.badges.map((badge) => badge.toJson()).toList();
  final results = <Map<String, Object?>>[];
  for (final kind in FieldObstacleKind.values) {
    ({MapData map, MapEntity entity, GameplayWorldState world})? selected;
    for (final map in maps) {
      for (final entity in map.entities
          .where((entity) => entity.fieldObstacle?.kind == kind)) {
        for (final direction in Direction.values) {
          final approach = GridPos(
              x: entity.pos.x - direction.dx, y: entity.pos.y - direction.dy);
          final world = GameplayWorldState.initial(
              map: map,
              project: project,
              playerPos: approach,
              playerFacing: direction,
              tileWidth: project.settings.tileWidth,
              tileHeight: project.settings.tileHeight);
          if (world.isBlocked(approach.x, approach.y)) continue;
          final destination = GridPos(
              x: entity.pos.x + direction.dx, y: entity.pos.y + direction.dy);
          if (kind == FieldObstacleKind.strengthBoulder &&
              world.isBlocked(destination.x, destination.y)) {
            continue;
          }
          selected = (map: map, entity: entity, world: world);
          break;
        }
        if (selected != null) break;
      }
      if (selected != null) break;
    }
    expect(selected, isNotNull,
        reason:
            'No free real approach${kind == FieldObstacleKind.strengthBoulder ? ' and push destination' : ''} for ${kind.name} among reopened objects: ${[
          for (final map in maps)
            for (final entity in map.entities)
              if (entity.fieldObstacle?.kind == kind)
                '${map.id}:${entity.id}@${entity.pos.x},${entity.pos.y}'
        ]}');
    final (map: map, entity: entity, world: world) = selected!;
    final ability = entity.fieldObstacle!.ability;
    final badge = project.badges
        .singleWhere((badge) => badge.fieldAbilityUnlock == ability);
    final pokemon = PlayerPokemon(
        speciesId: 'machop',
        natureId: 'hardy',
        abilityId: 'guts',
        level: 20,
        currentHp: 30,
        knownMoveIds: [ability.moveId],
        currentPpByMoveId: {ability.moveId: 1});
    final locked = GameState(
        saveId: 'cv02a-memory-${kind.name}',
        currentMapId: map.id,
        playerPosition: world.player.pos,
        playerFacing: world.player.facing.asFacing,
        party: PlayerParty(members: [pokemon]),
        mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
          map.id:
              MapInstanceRuntimeState(instanceId: 'cv02a-memory-${kind.name}')
        }));
    void unavailable(GameState state, FieldObstacleBlockReason reason) {
      expect(
          evaluateFieldObstacleAttempt(
              map: map, gameState: state, entityId: entity.id),
          isA<FieldObstacleUnavailable>()
              .having((value) => value.reason, 'reason', reason));
    }

    unavailable(locked, FieldObstacleBlockReason.locked);
    final usable = const GameStateMutations().applyBattleRewards(locked,
        reward: BattleReward(
            sourceKind: BattleRewardSourceKind.trainer,
            trainerId: 'cv02a-in-memory-only',
            badgeId: badge.id,
            fieldAbilityUnlock: badge.fieldAbilityUnlock));
    expect(usable.trainerProfile.badgeIds, contains(badge.id));
    unavailable(
        usable.copyWith(
            party: PlayerParty(members: [pokemon.copyWith(knownMoveIds: [])])),
        FieldObstacleBlockReason.missingMove);
    unavailable(
        usable.copyWith(
            party: PlayerParty(members: [pokemon.copyWith(currentHp: 0)])),
        FieldObstacleBlockReason.missingMove);
    expect(
        evaluateFieldObstacleAttempt(
            map: map, gameState: usable, entityId: entity.id),
        isA<CanUseFieldObstacle>());
    expect(world.isBlocked(entity.pos.x, entity.pos.y), isTrue);
    final instance = usable.mapInstanceWorldState.instanceRef(map.id)!;
    FieldObstacleTicket ticket(GameState state, int revision) =>
        FieldObstacleTicket(
            fieldAction: FieldActionTicket(
                ability: ability,
                targetCell: entity.pos,
                issuedAtStateRevision: revision),
            instance: instance,
            entityId: entity.id,
            playerPosition: state.playerPosition,
            playerPixelPosition: state.playerPixelPosition,
            playerFacing: state.playerFacing);
    final result = <String, Object?>{
      'nativeMapId': map.id,
      'entityId': entity.id,
      'kind': kind.name,
      'approach': usable.playerPosition.toJson(),
      'facing': usable.playerFacing.name,
      'gateChecks': ['locked', 'missingMove', 'faintedMissingMove', 'usable'],
      'gameStateOnly': true
    };
    late GameState changedState;
    late MapData changedMap;
    if (kind == FieldObstacleKind.strengthBoulder) {
      final activation = commitStrengthActivation(
          ticket: ticket(usable, 1),
          map: map,
          gameState: usable,
          currentStateRevision: 1,
          confirmedEntityId: entity.id,
          authoringMap: map,
          project: project,
          collisionWorld: world);
      expect(activation, isA<FieldObstacleApplied>());
      final active = (activation as FieldObstacleApplied).gameState;
      expect(active.mapInstanceWorldState.isStrengthActive(instance), isTrue);
      final destination = GridPos(
          x: entity.pos.x + world.player.facing.dx,
          y: entity.pos.y + world.player.facing.dy);
      final blocked = commitStrengthPush(
          ticket: ticket(active, 2),
          world: world,
          gameState: active,
          currentStateRevision: 2,
          authoringMap: map,
          project: project,
          characterReservations: [
            PixelRect(
                leftPx: destination.x * world.tileWidthPx,
                topPx: destination.y * world.tileHeightPx,
                widthPx: world.tileWidthPx,
                heightPx: world.tileHeightPx)
          ]);
      expect(
          blocked,
          isA<FieldObstacleRefused>().having(
              (value) => value.evaluation,
              'evaluation',
              isA<FieldObstacleUnavailable>().having((value) => value.reason,
                  'reason', FieldObstacleBlockReason.blockedDestination)));
      final pushed = commitStrengthPush(
          ticket: ticket(active, 2),
          world: world,
          gameState: active,
          currentStateRevision: 2,
          authoringMap: map,
          project: project);
      expect(pushed, isA<StrengthPushApplied>());
      final applied = pushed as StrengthPushApplied;
      expect(
          applied.gameState.mapInstanceWorldState
              .fieldObstaclePosition(instance, entity.id),
          destination);
      expect(
          applied.movement.world.map.entities
              .singleWhere((value) => value.id == entity.id)
              .pos,
          destination);
      expect(applied.gameState.playerPosition, entity.pos);
      changedState = applied.gameState;
      changedMap = applied.movement.world.map;
      result.addAll({
        'pushFrom': entity.pos.toJson(),
        'pushTo': destination.toJson(),
        'reservedDestinationRejected': true
      });
    } else {
      final commit = commitDestructibleFieldObstacleAction(
          ticket: ticket(usable, 1),
          map: map,
          gameState: usable,
          currentStateRevision: 1,
          confirmedEntityId: entity.id,
          authoringMap: map,
          project: project,
          collisionWorld: world);
      expect(commit, isA<FieldObstacleApplied>());
      final cleared = (commit as FieldObstacleApplied).gameState;
      unavailable(cleared, FieldObstacleBlockReason.alreadyCleared);
      final clearedMap = applyFieldObstacleWorldStateToMap(
          map: map,
          authoringMap: map,
          instances: cleared.mapInstanceWorldState,
          instance: instance,
          project: project);
      expect(
          clearedMap.entities.any((value) => value.id == entity.id), isFalse);
      final clearedWorld = GameplayWorldState.initial(
          map: clearedMap,
          project: project,
          playerPos: usable.playerPosition,
          playerFacing: world.player.facing,
          tileWidth: project.settings.tileWidth,
          tileHeight: project.settings.tileHeight);
      expect(clearedWorld.isBlocked(entity.pos.x, entity.pos.y), isFalse);
      changedState = cleared;
      changedMap = clearedMap;
      result['clearedAndCollisionReleased'] = true;
    }
    final reloadedInstances = MapInstanceWorldState.fromJson(
        Map<String, dynamic>.from(
            jsonDecode(jsonEncode(changedState.mapInstanceWorldState.toJson()))
                as Map));
    expect(reloadedInstances.instanceRef(map.id), instance);
    final sameInstances =
        preserveSameMapInstance(state: reloadedInstances, mapId: map.id);
    final sameMap = applyFieldObstacleWorldStateToMap(
        map: changedMap,
        authoringMap: map,
        instances: sameInstances,
        instance: instance,
        project: project);
    if (kind == FieldObstacleKind.strengthBoulder) {
      expect(sameInstances.isStrengthActive(instance), isTrue);
      expect(
          sameInstances.fieldObstaclePosition(instance, entity.id),
          changedMap.entities
              .singleWhere((value) => value.id == entity.id)
              .pos);
      expect(
          sameMap.entities.singleWhere((value) => value.id == entity.id).pos,
          changedMap.entities
              .singleWhere((value) => value.id == entity.id)
              .pos);
    } else {
      expect(sameInstances.isFieldObstacleCleared(instance, entity.id), isTrue);
      expect(sameMap.entities.any((value) => value.id == entity.id), isFalse);
    }
    final freshInstances = setupDifferentMapInstance(
        state: sameInstances,
        targetMapId: map.id,
        allocateId: (_) => '${instance.instanceId}-reloaded');
    final freshInstance = freshInstances.instanceRef(map.id)!;
    expect(freshInstance, isNot(instance));
    expect(freshInstances.isFieldObstacleCleared(freshInstance, entity.id),
        isFalse);
    expect(
        freshInstances.fieldObstaclePosition(freshInstance, entity.id), isNull);
    expect(freshInstances.isStrengthActive(freshInstance), isFalse);
    final resetMap = applyFieldObstacleWorldStateToMap(
        map: sameMap,
        authoringMap: map,
        instances: freshInstances,
        instance: freshInstance,
        project: project);
    final resetEntity =
        resetMap.entities.singleWhere((value) => value.id == entity.id);
    expect(resetEntity.toJson(), entity.toJson());
    expect(resetMap.size, map.size);
    expect(resetMap.layers, map.layers);
    expect(resetMap.placedElements, map.placedElements);
    final resetWorld = GameplayWorldState.initial(
        map: resetMap,
        project: project,
        playerPos: usable.playerPosition,
        playerFacing: world.player.facing,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight);
    expect(resetWorld.isBlocked(entity.pos.x, entity.pos.y), isTrue);
    if (kind == FieldObstacleKind.strengthBoulder) {
      final destination = GridPos(
          x: entity.pos.x + world.player.facing.dx,
          y: entity.pos.y + world.player.facing.dy);
      expect(resetWorld.isBlocked(destination.x, destination.y), isFalse);
    }
    expect(
        evaluateFieldObstacleAttempt(
            map: resetMap,
            gameState: usable.copyWith(mapInstanceWorldState: freshInstances),
            entityId: entity.id),
        isA<CanUseFieldObstacle>());
    result['mapInstanceReset'] = {
      'sameInstanceReloadPreservesTemporaryState': true,
      'previousInstanceId': instance.instanceId,
      'freshInstanceId': freshInstance.instanceId,
      'authoredObjectRestoredBlocking': true,
      'authoredPositionRestored': true,
      'strengthActivationCleared': true
    };
    expect(map.entities.singleWhere((value) => value.id == entity.id).pos,
        entity.pos);
    results.add(result);
  }
  expect(project.newGame.toJson(), initialConfig);
  expect(
      project.badges.map((badge) => badge.toJson()).toList(), badgeDefinitions);
  return results;
}

Future<List<Map<String, Object?>>> _retainedProjectInventory(
    String root) async {
  final rows = <Map<String, Object?>>[];
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    expect(entry, isNot(isA<Link>()));
    if (entry is File) {
      rows.add({
        'path': entry.path.substring(root.length + 1),
        'byteLength': await entry.length(),
        'sha256': (await crypto.sha256.bind(entry.openRead()).first).toString()
      });
    }
  }
  rows.sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  return rows;
}

void main() {
  final retainedProject =
      Platform.environment['AVELUNE_FIELD_RETAINED_PROJECT'];
  final retainedProof = Platform.environment['AVELUNE_FIELD_RETAINED_PROOF'];
  final retainedProofSha =
      Platform.environment['AVELUNE_FIELD_RETAINED_PROOF_SHA256'];
  test(
      'retained original four-map publication proves native mechanics and instance reset',
      () async {
    expect(await Directory(retainedProject!).resolveSymbolicLinks(),
        retainedProject);
    expect(
        retainedProject.startsWith(
            '/private/tmp/avelune_cv_import_20261017/evidence/field_obstacles/native_proof/'),
        isTrue);
    final proofFile = File(retainedProof!);
    expect((await crypto.sha256.bind(proofFile.openRead()).first).toString(),
        retainedProofSha);
    final proof = jsonDecode(await proofFile.readAsString()) as Map;
    expect(proof['kind'], 'cv02aPublicWorkflowAotQualification');
    expect(proof['status'], 'nativeStudyPublished');
    expect(proof['projectPath'], retainedProject);
    expect(proof['published'], isTrue);
    expect(proof['strictNativeReadPassed'], isTrue);
    expect(proof['sourceScriptsExecuted'], 0);
    expect(proof['aiCalls'], 0);
    final before = await _retainedProjectInventory(retainedProject);
    expect(before, proof['projectFiles']);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [retainedProject], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(retainedProject);
    late List<Map<String, Object?>> mechanics;
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      expect(native.maps, hasLength(4));
      expect(native.manifest.badges, hasLength(3));
      expect(native.manifest.badges.map((badge) => badge.toJson()).toList(),
          proof['badgeDefinitions']);
      expect(native.manifest.newGame.toJson(), proof['initialConfiguration']);
      expect(native.manifest.newGame.initialParty, isEmpty);
      expect(native.manifest.newGame.resolvedInitialFactValues, isEmpty);
      final expectedMaps = (proof['nativeMaps'] as List).cast<Map>();
      for (final map in native.maps) {
        expect(
            canonicalHashOf(jsonDecode(jsonEncode(map.toJson()))).value,
            expectedMaps
                .singleWhere((row) => row['id'] == map.id)['canonicalHash']);
      }
      mechanics = _assertReopenedFieldMechanics(native.manifest, native.maps);
      expect(mechanics, hasLength(3));
      expect(mechanics.every((row) => row['mapInstanceReset'] is Map), isTrue);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    expect(await _retainedProjectInventory(retainedProject), before);
    stdout.writeln(jsonEncode({
      'qualification': 'retainedNativeFieldMechanicsAndInstanceReset',
      'projectPath': retainedProject,
      'proofSha256': retainedProofSha,
      'inMemoryMechanics': mechanics,
      'sourceProgressionQualified': false,
      'nativeProjectBytesUnchanged': true
    }));
  },
      skip: retainedProject == null ||
              retainedProof == null ||
              retainedProofSha == null
          ? 'Requires an explicitly retained public four-map publication and exact proof SHA.'
          : false,
      timeout: const Timeout(Duration(minutes: 2)));
  final root = Platform.environment['AVELUNE_FIELD_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_FIELD_SOURCE_SNAPSHOT'];
  final scriptsRoot = Platform.environment['AVELUNE_FIELD_SCRIPTS_ROOT'];
  final proofParent = Platform.environment['AVELUNE_FIELD_NATIVE_PROOF_PARENT'];
  final supplementalRoots = (jsonDecode(
              Platform.environment['AVELUNE_FIELD_SUPPLEMENTAL_ROOTS'] ?? '[]')
          as List)
      .cast<String>();
  final skip = root == null || snapshot == null || scriptsRoot == null
      ? 'Requires the exact original Kanto inventory and explicit Johto script source.'
      : false;
  group('original closed field obstacle families CV-02A', () {
    late NormalizedSourceProject source;
    late ExternalOriginalFiles originalFiles;
    late SourceEventAnalysis analysis;
    late SourceFieldObstacleBindings bindings;
    late List<int> scripts;
    setUpAll(() async {
      if (proofParent != null) {
        final parent = Directory(proofParent);
        if (!parent.isAbsolute ||
            !await parent.exists() ||
            await parent.resolveSymbolicLinks() != parent.path) {
          throw StateError(
              'The explicit native proof parent must be an existing canonical absolute directory.');
        }
      }
      scripts = await File('$scriptsRoot/Data/Scripts.rxdata').readAsBytes();
      final original = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {98, 154, 245, 274},
          overrideBytes: {'Data/Scripts.rxdata': scripts});
      source = original.source;
      originalFiles = original.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      bindings = (await const SourceFieldObstacleBindingResolver()
          .read(source: source, analysis: analysis, files: originalFiles))!;
    });

    test(
        'binds original Cut, four Strength and absent-only Smash without progress grants',
        () {
      expect(bindings.byEventIdentity, hasLength(6));
      expect(bindings.refusals, hasLength(6));
      final kinds = bindings.byEventIdentity.values
          .map((binding) => binding.nativeKind)
          .toList();
      expect(kinds.where((kind) => kind == FieldObstacleKind.cutTree),
          hasLength(1));
      expect(kinds.where((kind) => kind == FieldObstacleKind.strengthBoulder),
          hasLength(4));
      expect(kinds.where((kind) => kind == FieldObstacleKind.rockSmashRock),
          hasLength(1));
      expect(bindings.badges.map((badge) => badge.fieldAbilityUnlock).toSet(),
          {FieldAbility.cut, FieldAbility.strength, FieldAbility.rockSmash});
      expect(bindings.artifacts, hasLength(3));
      expect(bindings.elements, hasLength(3));
      expect(bindings.evidence['initialPlayerStateMutated'], isFalse);
      expect(
          bindings.mutations.where((mutation) =>
              mutation.actionId.contains('award_badge') ||
              mutation.actionId.contains('unlock_field') ||
              mutation.actionId.contains('learn_move')),
          isEmpty);
      final strength = bindings.byEventIdentity.values.firstWhere(
          (binding) => binding.nativeKind == FieldObstacleKind.strengthBoulder);
      expect(strength.sourceBadgeIndex, 14);
      expect(strength.badgePolicyRegion, 1);
      expect(
          source.snapshot.entries
              .singleWhere(
                  (entry) => entry.relativePath == 'Data/Map245.rxdata')
              .sha256!
              .value,
          'cb2706cfdf3b80afa7486430b207333218b7cc18c5fe901816d6d05bed48dfd4');
      for (final binding in bindings.byEventIdentity.values) {
        final native = binding.createNativeEntity(
            'object_${binding.sourceMapId}_${binding.sourceEventId}');
        expect(native.kind, MapEntityKind.custom);
        expect(native.blocksMovement, isTrue);
        expect(native.size, const GridSize(width: 1, height: 1));
        expect(native.fieldObstacle!.resetPolicy,
            FieldObstacleResetPolicy.mapInstance);
        expect(native.fieldObstacle!.kind, binding.nativeKind);
        expect(native.npc, isNull);
      }
    });

    test(
        'keeps the six real cave encounters quarantined and their exact Ruby call preserved',
        () {
      for (final event in analysis.events
          .where((event) => bindings.refusals.containsKey(event.identity))) {
        expect(event.sourceMapId, 154);
        expect(bindings.refusals[event.identity],
            'sourceRockSmashEncounterRequiredUnqualified');
        final program = event.pages.single.body.nodes.single
            as SourceFieldObstacleProgramNode;
        expect(program.sourceCalls, contains('pbRockSmashRandomEncounter'));
      }
      final status =
          (bindings.evidence['rockSmashEncounters'] as List).cast<Map>();
      expect(status.singleWhere((row) => row['sourceMapId'] == 154)['status'],
          'requiredUnqualified');
      expect(status.singleWhere((row) => row['sourceMapId'] == 274)['status'],
          'absent');
    });

    test(
        'imports the three original sheets without pixel resampling or duplicate visuals',
        () {
      expect(
          bindings.artifacts
              .map((artifact) => artifact.rawSha256.value)
              .toSet(),
          {
            '68271cc5662b112111bec29ea8122466712535a4fd2381262a20a65064e974cb',
            '9800dab1498f66d53cbcfac8b50a570e556fdf782245e6e681881a057350e0bc',
            'd4fa3e710bf8147bf0e57e9d3974606087cf528e43841da6ab66560006f66fdf'
          });
      expect(bindings.evidence['sourcePixelsResampled'], isFalse);
      for (final element in bindings.elements) {
        expect(element.frames, hasLength(1));
        expect(
            element.frames.single.source, const TilesetSourceRect(x: 0, y: 0));
        expect(element.collisionProfile!.cells, [const GridPos(x: 0, y: 0)]);
      }
      expect(
          bindings.mutations.where(
              (mutation) => mutation.actionId == 'campaign.badge.upsert'),
          hasLength(3));
      expect(
          bindings.mutations
              .where((mutation) => mutation.actionId == 'tileset.import_image'),
          hasLength(3));
    });

    test('rejects a publicly rebuilt analysis before reading source witnesses',
        () async {
      final files = _ObservedFiles(source, originalFiles);
      final forged = SourceEventAnalysis(
          profile: analysis.profile,
          events: analysis.events,
          diagnostics: analysis.diagnostics);
      await expectLater(
          const SourceFieldObstacleBindingResolver()
              .read(source: source, analysis: forged, files: files),
          throwsA(isA<SourceFieldObstacleBindingUnavailable>().having(
              (error) => error.reason,
              'reason',
              'event_attestation_unqualified')));
      expect(files.reads, isEmpty);
    });

    test('binds a fresh canonical analysis and rejects altered complete events',
        () {
      final fresh =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile)
              .analyze();
      final binding = bindings.byEventIdentity.values.first;
      final event = fresh.eventAt(binding.sourceMapId, binding.sourceEventId)!;
      expect(
          binding.isBoundToEvent(source: source, analysis: fresh, event: event),
          isTrue);
      for (final changed in [
        SourceEventDefinition(
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourceFileId: event.sourceFileId,
            identity: event.identity,
            name: 'Forged',
            x: event.x,
            y: event.y,
            locator: event.locator,
            pages: event.pages),
        SourceEventDefinition(
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourceFileId: event.sourceFileId,
            identity: event.identity,
            name: event.name,
            x: event.x + 1,
            y: event.y,
            locator: event.locator,
            pages: event.pages),
      ]) {
        expect(
            binding.isBoundToEvent(
                source: source, analysis: fresh, event: changed),
            isFalse);
      }
    });

    test(
        'source attestation rejects altered analyzed guards, graphics and bodies',
        () {
      final binding = bindings.byEventIdentity.values.first;
      final event =
          analysis.eventAt(binding.sourceMapId, binding.sourceEventId)!;
      final page = event.pages.single;
      for (final variant in ['guard', 'graphic', 'body']) {
        final changedPage = SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: variant == 'guard'
                ? SourceEventCondition(
                    kind: SourceEventConditionKind.globalSwitch,
                    factId: 'forged')
                : page.condition,
            graphic: variant == 'graphic' ? null : page.graphic,
            body: variant == 'body'
                ? SourceEventBlock(nodes: const [], span: page.body.span)
                : page.body,
            rawDataRef: page.rawDataRef,
            diagnostics: page.diagnostics);
        final changed = SourceEventDefinition(
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourceFileId: event.sourceFileId,
            identity: event.identity,
            name: event.name,
            x: event.x,
            y: event.y,
            locator: event.locator,
            pages: [changedPage]);
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: changed),
            isFalse,
            reason: variant);
      }
    });

    for (final path in [
      'Data/Scripts.rxdata',
      'PBS/map_metadata.txt',
      'Data/encounters.dat',
      'PBS/encounters.txt',
      'Graphics/Characters/OBJ_FRLG_Strength Boulder.png'
    ]) {
      test('changed admitted original bytes refuse $path', () async {
        await expectLater(
            const SourceFieldObstacleBindingResolver().read(
                source: source,
                analysis: analysis,
                files:
                    _ObservedFiles(source, originalFiles, changedPath: path)),
            throwsA(isA<ContractError>().having((error) => error.code, 'code',
                'source.field_obstacle.source_changed')));
      });
    }

    Future<SourceFieldObstacleBindings> resolveVariant(
        Map<String, List<int>> overrides) async {
      final variant = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {98, 154, 245, 274},
          overrideBytes: {'Data/Scripts.rxdata': scripts, ...overrides});
      final analyzed = SourceEventAnalyzer.forProject(variant.source,
              profile: SourceEventProfile.forProject(variant.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      return (await const SourceFieldObstacleBindingResolver().read(
          source: variant.source, analysis: analyzed, files: variant.files))!;
    }

    test('a changed original compiled root key cannot hide another map table',
        () async {
      final compiled = await File('$root/Data/encounters.dat').readAsBytes();
      final changed = _replaceOriginalAscii(compiled, '154_0', '198_0');
      final result = await resolveVariant({'Data/encounters.dat': changed});
      expect(
          result.byEventIdentity.values.where((binding) =>
              binding.nativeKind == FieldObstacleKind.rockSmashRock),
          isEmpty);
      expect(result.refusals.values.toSet(), {
        'sourceRockSmashEncounterUnattested:encounter_compiled_identity_unqualified'
      });
      expect(result.evidence['rockSmashEncounters'], isEmpty);
    });

    test('compiled @id must agree with its root key and map/version fields',
        () async {
      final result = await resolveVariant(
          {'Data/encounters.dat': _compiledDeclaration(id: '154_0')});
      expect(
          result.byEventIdentity.values.where((binding) =>
              binding.nativeKind == FieldObstacleKind.rockSmashRock),
          isEmpty);
      expect(result.refusals.values.toSet(), {
        'sourceRockSmashEncounterUnattested:encounter_compiled_identity_unqualified'
      });
    });

    for (final declaration in ['empty table', 'chance without table']) {
      test('compiled $declaration never proves Rock Smash absence', () async {
        final result = await resolveVariant({
          'Data/encounters.dat': _compiledDeclaration(
              table: declaration == 'empty table',
              chance: declaration == 'chance without table')
        });
        final status =
            (result.evidence['rockSmashEncounters'] as List).cast<Map>();
        expect(status.singleWhere((row) => row['sourceMapId'] == 274)['status'],
            'requiredUnqualified');
        expect(
            result.byEventIdentity.values.where((binding) =>
                binding.nativeKind == FieldObstacleKind.rockSmashRock),
            isEmpty);
      });
    }

    for (final method in ['RockSmash,11', 'RockSmash,invalid']) {
      test('PBS declared $method with no slots never proves absence', () async {
        final result = await resolveVariant(
            {'PBS/encounters.txt': utf8.encode('[274]\n$method\n')});
        expect(
            result.byEventIdentity.values.where((binding) =>
                binding.nativeKind == FieldObstacleKind.rockSmashRock),
            isEmpty);
        expect(
            (result.evidence['rockSmashEncounters'] as List).cast<Map>().where(
                (row) =>
                    row['sourceMapId'] == 274 && row['status'] == 'absent'),
            isEmpty);
        expect(
            result.refusals.values,
            everyElement(anyOf('sourceRockSmashEncounterRequiredUnqualified',
                'sourceRockSmashEncounterUnattested:encounter_source_unqualified')));
      });
    }

    test(
        'projects exact typed semantic actions and preserves pending encounters',
        () {
      final projection = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: cutNativeMaps(source),
          fieldObstacleBindings: bindings.byEventIdentity,
          fieldObstacleRefusals: bindings.refusals);
      final objects = projection.nativeMaps.values
          .expand((map) => map.entities)
          .where((entity) => entity.fieldObstacle != null)
          .toList();
      expect(objects, hasLength(6));
      expect(
          projection.mutations.where(
              (mutation) => mutation.actionId == 'entity.set_field_obstacle'),
          hasLength(6));
      for (final mutation in projection.mutations
          .where((mutation) => mutation.actionId == 'entity.upsert')) {
        final entity = mutation.parameters['entity'] as Map;
        if (objects.any((object) => object.id == entity['id'])) {
          expect(entity['fieldObstacle'], isNull);
        }
      }
      final evidence =
          (projection.semanticEvidence['events'] as List).cast<Map>();
      for (final id in bindings.refusals.keys) {
        expect(
            evidence.singleWhere(
                (row) => row['sourceIdentity'] == id.value)['gaps'],
            contains('sourceRockSmashEncounterRequiredUnqualified'));
      }
    });

    final writeLimits = sourceCatalogStudyWriteLimitsFor(4);
    Directory? writerRoot;
    String? retainedProjectPath;
    var retainPublicationAttempt = false;
    Future<SourceEventStudyComposition>? writerComposition;
    tearDownAll(() async {
      if (retainedProjectPath != null) {
        stdout.writeln(jsonEncode({
          'retainedNativeProof': retainedProjectPath,
          'ownerDirectory': writerRoot!.path,
          'strictReopenVerified': true
        }));
      } else if (retainPublicationAttempt && writerRoot != null) {
        stdout.writeln(jsonEncode({
          'retainedNativeProofAttempt': writerRoot!.path,
          'strictReopenVerified': false
        }));
      } else if (writerRoot != null && await writerRoot!.exists()) {
        await writerRoot!.delete(recursive: true);
      }
    });
    Future<SourceEventStudyComposition> composeForWriter() =>
        writerComposition ??= (() async {
          writerRoot = await (proofParent == null
                  ? Directory.systemTemp
                  : Directory(proofParent))
              .createTemp('cv02a-original-fields-');
          final files = _ExplicitOriginalFieldFiles(
              source, root!, supplementalRoots, originalFiles);
          Future<LiteralTileComposition> literalWith(
                  List<LiteralDependencyDecision> decisions) =>
              const LiteralTileComposer().compose(
                  source: source,
                  files: files,
                  selectedSourceMapIds: const [98, 154, 245, 274],
                  projectName: 'Original field obstacle qualification',
                  parentPath: writerRoot!.path,
                  folderName: 'original-fields',
                  sourceRootPath: root,
                  allowFirstFrameAutotiles: true,
                  dependencyDecisions: decisions,
                  limits: writeLimits);
          var literal = await literalWith(const []);
          final decisions = [
            for (final dependency in literal.dependencies)
              if (dependency.kind == LiteralDependencyKind.staticTransfer &&
                  dependency.targetSourceMapId != null &&
                  !const {98, 154, 245, 274}
                      .contains(dependency.targetSourceMapId))
                LiteralDependencyDecision(
                    sourceSnapshotHash: source.snapshot.canonicalHash,
                    selectionHash:
                        literalSelectionHash(source, const [98, 154, 245, 274]),
                    locator: dependency.locator,
                    targetSourceMapId: dependency.targetSourceMapId!,
                    decision: LiteralDependencyDisposition.excludeStudy)
          ];
          if (decisions.isNotEmpty) literal = await literalWith(decisions);
          expect(literal.draft, isNotNull);
          final semantics = await const SourceSemanticStudyComposer().compose(
              source: source, base: literal, files: files, limits: writeLimits);
          expect(semantics, isNotNull);
          final composed = await const SourceEventStudyComposer().compose(
              source: source,
              base: semantics!,
              files: files,
              limits: writeLimits);
          expect(composed, isNotNull);
          final catalogs = await const SourceCatalogStudyComposer().compose(
              source: source,
              base: composed!.draft,
              files: files,
              limits: writeLimits);
          expect(catalogs, isNotNull);
          return SourceEventStudyComposition(
              draft: catalogs!.draft,
              projection: composed.projection,
              musicBindings: composed.musicBindings);
        })();

    for (final forged in ['targets', 'owners']) {
      test(
          'strict field writer refuses reapproved forged $forged before staging',
          () async {
        final composition = await composeForWriter();
        final draft = composition.draft;
        final index = draft.mutations.indexWhere(
            (mutation) => mutation.actionId == 'entity.set_field_obstacle');
        expect(index, greaterThanOrEqualTo(0));
        final original = draft.mutations[index];
        final sourceMapId = draft.mapIds.entries
            .singleWhere((entry) => entry.value == original.parameters['mapId'])
            .key;
        final replacement = NativeMutation(
            operationId: original.operationId,
            actionId: original.actionId,
            actionVersion: original.actionVersion,
            sourceEntityIds: forged == 'owners'
                ? original.sourceEntityIds
                    .where((id) => id != source.mapIdentity(sourceMapId))
                    .toList()
                : original.sourceEntityIds,
            targetEntityIds: forged == 'targets'
                ? [ConverterId(original.parameters['mapId'] as String)]
                : original.targetEntityIds,
            parameters: original.parameters,
            limits: writeLimits);
        final altered = NativeProjectDraft(
            source: draft.source,
            projectName: draft.projectName,
            parentPath: draft.parentPath,
            folderName: draft.folderName,
            mapIds: draft.mapIds,
            artifacts: draft.artifacts,
            sourceArtifacts: draft.sourceArtifacts,
            mutations: [
              for (final (ordinal, mutation) in draft.mutations.indexed)
                ordinal == index ? replacement : mutation
            ],
            compositionEvidence: draft.compositionEvidence,
            sourceRootPath: draft.sourceRootPath,
            defaultMapWidth: draft.defaultMapWidth,
            defaultMapHeight: draft.defaultMapHeight,
            limits: writeLimits);
        final approval = approveNativeFixtureDraft(altered);
        final stages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(approval.plan, approval.context, altered,
                    limits: writeLimits),
            throwsA(isA<NativeWriteException>().having(
                (error) => error.code,
                'code',
                anyOf('native.semantics.regeneration',
                    'native.semantics.evidence', 'native.map.identity'))));
        expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
        expect(await writerRoot!.list().toList(), isEmpty);
      }, timeout: const Timeout(Duration(minutes: 10)));
    }

    test(
        'strict original field publication reopens all three native kinds and closed badges',
        () async {
      retainPublicationAttempt = proofParent != null;
      final composition = await composeForWriter();
      final draft = composition.draft;
      final approval = approveNativeFixtureDraft(draft);
      final publication = await const NativeProjectPublication().begin(
          approval.plan, approval.context, draft,
          policy: NativePublicationPolicy(
              allowedParentRoots: [writerRoot!.path],
              sourceRoots: [root!, scriptsRoot!, ...supplementalRoots]));
      addTearDown(publication.close);
      final staged = await NativeProjectWriter(
              stagingFactory: publication.createStaging,
              checkpoint: publication.recordWriteCheckpoint)
          .write(approval.plan, approval.context, draft, limits: writeLimits);
      expect(staged.verified, isTrue);
      final files = _ExplicitOriginalFieldFiles(
          source, root, supplementalRoots, originalFiles);
      Future<void> verifyOriginalWitnesses() async {
        final rows = <String, Map>{};
        for (final key in [
          'sourceSemantics',
          'sourceEvents',
          'sourceCatalogs'
        ]) {
          for (final row
              in ((draft.compositionEvidence[key] as Map)['witnesses'] as List)
                  .cast<Map>()) {
            rows[row['fileId'] as String] = row;
          }
        }
        for (final id in rows.keys) {
          final entry = source.snapshot.entries
              .singleWhere((entry) => entry.fileId.value == id);
          final bytes = await files.read(entry.fileId);
          expect(bytes.length, entry.byteLength);
          expect(crypto.sha256.convert(bytes).toString(), entry.sha256!.value);
        }
      }

      final receipt = await publication.publish(
          stagedReceipt: staged,
          readCurrentContext: () async => approval.context,
          verifySourceUnchanged: verifyOriginalWitnesses);
      expect(receipt.published, isTrue);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [writerRoot!.path], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.loadDiagnostics, isEmpty);
        expect(native.maps, hasLength(4));
        final objects = native.maps
            .expand((map) => map.entities)
            .where((entity) => entity.fieldObstacle != null)
            .toList();
        expect(objects, hasLength(6));
        expect(objects.map((entity) => entity.fieldObstacle!.kind).toSet(),
            FieldObstacleKind.values.toSet());
        expect(
            native.manifest.badges
                .map((badge) => badge.fieldAbilityUnlock)
                .toSet(),
            {FieldAbility.cut, FieldAbility.strength, FieldAbility.rockSmash});
        expect(native.manifest.newGame.initialParty, isEmpty);
        expect(native.manifest.newGame.resolvedInitialFactValues, isEmpty);
        for (final map in native.maps) {
          expect(
              map.toJson(),
              composition.projection.nativeMaps.values
                  .singleWhere((expected) => expected.id == map.id)
                  .toJson());
        }
        if (proofParent != null) retainedProjectPath = receipt.projectPath;
        final mechanics =
            _assertReopenedFieldMechanics(native.manifest, native.maps);
        stdout.writeln(jsonEncode({
          'qualification': 'originalFieldPublicationAndStrictReopen',
          'published': receipt.published,
          'projectPath': receipt.projectPath,
          'ownerDirectory': writerRoot!.path,
          'mapCount': native.maps.length,
          'fieldObjects': objects.length,
          'fieldKinds': objects
              .map((entity) => entity.fieldObstacle!.kind.name)
              .toSet()
              .toList(),
          'lockedBadges': native.manifest.badges.length,
          'initialParty': native.manifest.newGame.initialParty.length,
          'initialFacts':
              native.manifest.newGame.resolvedInitialFactValues.length,
          'inMemoryMechanics': mechanics,
          'sourceProgressionQualified': false,
          'sourceScriptsExecuted': 0
        }));
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    }, timeout: const Timeout(Duration(minutes: 15)));

    test(
        'region subzones preserve raw metadata while sharing only badge policy',
        () async {
      final metadata = await File('$root/PBS/map_metadata.txt').readAsString();
      final pattern = RegExp(r'(\[0*98\][\s\S]*?MapPosition\s*=\s*)1(?=\s*,)');
      expect(pattern.allMatches(metadata), hasLength(1));
      final changed = metadata.replaceFirstMapped(
          pattern, (match) => '${match.group(1)}101');
      expect(changed, isNot(metadata));
      final variant = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {
            98
          },
          overrideBytes: {
            'Data/Scripts.rxdata': scripts,
            'PBS/map_metadata.txt': utf8.encode(changed)
          });
      final analyzed = SourceEventAnalyzer.forProject(variant.source,
              profile: SourceEventProfile.forProject(variant.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final result = (await const SourceFieldObstacleBindingResolver().read(
          source: variant.source, analysis: analyzed, files: variant.files))!;
      final binding = result.byEventIdentity.values.single;
      expect(binding.sourceRegion, 101);
      expect(binding.badgePolicyRegion, 1);
      expect(binding.sourceBadgeIndex, 12);
      expect(
          binding.nativeBadge.id,
          bindings.byEventIdentity.values
              .singleWhere(
                  (binding) => binding.nativeKind == FieldObstacleKind.cutTree)
              .nativeBadge
              .id);
    });

    test(
        'different badge requirements for one ability refuse the complete selected family',
        () async {
      final metadata = await File('$root/PBS/map_metadata.txt').readAsString();
      final pattern = RegExp(r'(\[0*98\][\s\S]*?MapPosition\s*=\s*)1(?=\s*,)');
      expect(pattern.allMatches(metadata), hasLength(1));
      final changed =
          metadata.replaceFirstMapped(pattern, (match) => '${match.group(1)}2');
      expect(changed, isNot(metadata));
      final variant = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {
            98,
            100
          },
          overrideBytes: {
            'Data/Scripts.rxdata': scripts,
            'PBS/map_metadata.txt': utf8.encode(changed)
          });
      final analyzed = SourceEventAnalyzer.forProject(variant.source,
              profile: SourceEventProfile.forProject(variant.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final result = (await const SourceFieldObstacleBindingResolver().read(
          source: variant.source, analysis: analyzed, files: variant.files))!;
      expect(result.byEventIdentity, isEmpty);
      expect(result.refusals, hasLength(5));
      expect(result.refusals.values.toSet(),
          {'sourceFieldObstacleConflictingBadgeLocks:CUT'});
      expect(result.badges, isEmpty);
      expect(result.artifacts, isEmpty);
      expect(result.mutations, isEmpty);
    });
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
