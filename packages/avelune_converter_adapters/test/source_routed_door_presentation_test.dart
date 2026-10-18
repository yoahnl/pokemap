import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'package:map_gameplay/map_gameplay.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

final class _ChangedFiles implements SourceFilePort {
  _ChangedFiles(this.original, this.fileId, this.bytes);
  final SourceFilePort original;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) =>
      id == fileId ? Future.value(List.of(bytes)) : original.read(id);
}

MarshalNode _field(MarshalDocument document, MarshalNode owner, String name) =>
    document.node(owner.instanceVariables
        .singleWhere((pair) => document.node(pair.key).name == name)
        .value);

MarshalNode _page(MarshalDocument document, int eventId, int index) {
  final events = _field(document, document.node(document.rootId), '@events');
  final event = document.node(events.pairs
      .singleWhere((pair) =>
          document.node(pair.key).integerValue == BigInt.from(eventId))
      .value);
  return document.node(_field(document, event, '@pages').elements[index]);
}

List<int> _integer(List<int> bytes, MarshalNode node, int value) {
  final offset = node.location.byteOffset;
  expect(node.kind, MarshalKind.integer);
  expect(bytes[offset], 0x69);
  final marker = bytes[offset + 1];
  final signed = marker < 128 ? marker : marker - 256;
  final length = signed != 0 && signed.abs() <= 4 ? 2 + signed.abs() : 2;
  return [
    ...bytes.take(offset),
    0x69,
    ...value == 0
        ? [0]
        : value > 0 && value < 123
            ? [value + 5]
            : value < 0 && value > -124
                ? [(value - 5) & 255]
                : [2, value & 255, (value >> 8) & 255],
    ...bytes.skip(offset + length)
  ];
}

Future<({NormalizedSourceProject source, SourceFilePort files})> _variant(
    NormalizedSourceProject source,
    SourceFilePort files,
    String path,
    List<int> Function(MarshalDocument, List<int>) change) async {
  final entry = source.snapshot.entries
      .singleWhere((entry) => entry.relativePath == path);
  final bytes = await files.read(entry.fileId);
  final changed =
      change(const MarshalDecoder().decode(bytes, sourcePath: path), bytes);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      policyHash: source.snapshot.policyHash,
      entries: [
        for (final current in source.snapshot.entries)
          if (current.fileId != entry.fileId)
            current
          else
            SourceFileEntry(
                fileId: current.fileId,
                relativePath: current.relativePath,
                kind: current.kind,
                byteLength: changed.length,
                sha256: Sha256Hash(crypto.sha256.convert(changed).toString()),
                format: current.format,
                family: current.family)
      ],
      diagnostics: source.snapshot.diagnostics,
      excludedPaths: source.snapshot.excludedPaths,
      profileEvidence: source.snapshot.profileEvidence,
      state: source.snapshot.state);
  final overlay = _ChangedFiles(files, entry.fileId, changed);
  return (
    source: await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        files: overlay,
        selectedMapIds: source.selectedSourceMapIds.toSet(),
        includeEventSystem: true,
        includeConnections: true),
    files: overlay
  );
}

Map<int, MapData> _maps(NormalizedSourceProject source) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'static_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Source',
                collisions: SourceCollisionProjection.resolve(
                        cells: [
                      for (var y = 0; y < ir.map.height; y++)
                        for (var x = 0; x < ir.map.width; x++)
                          resolver.cellAt(ir.map.sourceMapId, x, y),
                    ],
                        resolver: resolver,
                        mapSize: GridSize(
                            width: ir.map.width, height: ir.map.height))
                    .fullyBlockedCells),
          ])
  };
}

NativeProjectDraft _base(
        NormalizedSourceProject source, Map<int, MapData> maps) =>
    NativeProjectDraft(
        source: source,
        projectName: 'Static doors',
        parentPath: Directory.systemTemp.path,
        folderName: 'static-door-context',
        mapIds: {
          for (final entry in maps.entries) entry.key: entry.value.id
        },
        artifacts: [],
        compositionEvidence: const {
          'sourceSemantics': {}
        },
        mutations: [
          for (final entry in maps.entries)
            NativeMutation(
                operationId: ConverterId('map_${entry.key}'),
                actionId: 'map.save',
                sourceEntityIds: [
                  source.mapIdentity(entry.key)
                ],
                targetEntityIds: [
                  ConverterId(entry.value.id)
                ],
                parameters: {
                  'mapId': entry.value.id,
                  'map': entry.value.toJson(),
                })
        ]);

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((value) => value.isNotEmpty)
          .toList();
  group('native stable departure door skin', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late SourceEventDefinition door;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceRoutedDoorProgram> programs;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late MapInstanceRetentionPolicy retention;
    late Map<String, SourceEventSoundBinding> sounds;
    late Map<String, SourceEventCharacterBinding> characters;
    late List<SourceEventCharacterImport> imports;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {27, 30}, supplementalRoots: supplementalRoots);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      door = analysis.eventAt(27, 17)!;
      maps = _maps(source);
      programs = sourceRoutedDoorPrograms(source: source, analysis: analysis);
      contexts = await const SourceEventExecutionContextResolver()
          .readRoutedTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: files,
              programs: programs,
              analysis: analysis);
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      sounds = {
        for (final name in ['Entering Door', 'Exit Door'])
          name: await const SourceEventSoundResolver()
              .read(source: source, files: files, name: name)
      };
      imports = [
        for (final page in door.pages)
          await const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: files,
              charsetName: page.graphic!.characterName,
              sourcePattern: page.graphic!.pattern,
              sourceDirection: page.graphic!.direction)
      ];
      characters = {
        for (final imported in imports) imported.bindingKey: imported.binding
      };
    });
    SourceEventProjection project(
            {SourceEventAnalysis? selected,
            Map<ConverterId, SourceRoutedDoorProgram>? selectedPrograms}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: selected ?? analysis,
            nativeMaps: maps,
            staticDoorPrograms: const {},
            routedDoorPrograms: selectedPrograms ?? programs,
            routedDoorContexts: contexts,
            characterBindings: characters,
            soundBindings: sounds,
            retentionPolicy: retention);

    test(
        'complete source programs declare only the bounded presentation change',
        () {
      final program = programs[door.identity];
      expect(program, isNotNull);
      final evidence = program!.toJson();
      expect(evidence['presentationAdaptation'], {
        'kind': 'nativeStableDepartureDoorSkin',
        'sourceCharset': 'OBJ_FRLG_Doors4',
        'departurePattern': 1,
        'arrivalPattern': 0,
        'nativePattern': 1,
        'sourceSelectedPagePatternPlaybackQualified': false,
      });
      expect(program.isBoundTo(source: source, analysis: analysis, event: door),
          true);
      expect(door.pages.map((page) => page.graphic!.pattern), [1, 0]);
    });

    test(
        'full source recognition adds exactly the 23 audited complete door programs',
        () async {
      final input = jsonDecode(await File(snapshot!).readAsString()) as Map;
      final ids = (input['entries'] as List)
          .cast<Map>()
          .map((entry) => RegExp(r'^Data/Map(\d+)\.rxdata$')
              .firstMatch(entry['relativePath'] as String))
          .whereType<RegExpMatch>()
          .map((match) => int.parse(match.group(1)!))
          .toSet();
      final fixture = await readExternalOriginalSource(root!, snapshot,
          selectedMapIds: ids, supplementalRoots: supplementalRoots);
      final parsed = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final selected =
          sourceRoutedDoorPrograms(source: fixture.source, analysis: parsed);
      expect(fixture.source.maps, hasLength(383));
      final adapted = selected.values
          .where((program) =>
              program.toJson().containsKey('presentationAdaptation'))
          .toList();
      expect(
          adapted
              .map((program) => (program.sourceMapId, program.sourceEventId))
              .toSet(),
          {
            (27, 17),
            (27, 18),
            (27, 19),
            (225, 5),
            (225, 4),
            (229, 4),
            (234, 5),
            (234, 6),
            (234, 2),
            (234, 3),
            (234, 4),
            (240, 1),
            (274, 7),
            (274, 8),
            (274, 9),
            (284, 3),
            (284, 4),
            (289, 12),
            (296, 3),
            (301, 1),
            (301, 2),
            (310, 4),
            (317, 3),
          });
      expect(selected.length, 161,
          reason: "adapted=${adapted.map((program) => (
                program.sourceMapId,
                program.sourceEventId
              )).toList()}");
      expect(selected.length - adapted.length, 138);
      expect(
          selected.values.every((program) => program.isBoundTo(
              source: fixture.source,
              analysis: parsed,
              event:
                  parsed.eventAt(program.sourceMapId, program.sourceEventId)!)),
          true);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test(
        'both native pages retain one departure actor, routes, anchor guard and temp reset',
        () {
      final context = contexts[door.identity];
      expect(context, isNotNull);
      expect(context!.isQualified, true, reason: context.refusals.toString());
      final result = project();
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == door.identity.value);
      expect(row['gaps'], isEmpty);
      final scenes = result.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value)
          .toList();
      expect(scenes, hasLength(2), reason: row.toString());
      final entities = result.mutations
          .where((mutation) =>
              mutation.actionId == 'entity.upsert' &&
              (mutation.parameters['entity'] as Map)['properties'] is Map &&
              ((mutation.parameters['entity'] as Map)['properties']
                      as Map)['sourceEventIdentity'] ==
                  door.identity.value)
          .toList();
      expect(entities, hasLength(1));
      final entity = MapEntity.fromJson(Map<String, dynamic>.from(
          entities.single.parameters['entity'] as Map));
      expect(entity.npc!.characterId, imports.first.character.id);
      expect(entity.npc!.characterId, isNot(imports.last.character.id));
      expect(entity.blocksMovement, true);
      final json =
          canonicalJsonOf(scenes.map((scene) => scene.toJson()).toList());
      expect(json, contains('playerAtEntityAnchor'));
      expect(json, contains('setMapEventInstanceBoolean'));
      expect(json, contains('"key":"A"'));
      expect(json, contains('"value":true'));
      final commands = scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((action) => action.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .map((command) => command.toJson())
          .toList();
      expect(commands.where((command) => command['kind'] == 'actorRoute'),
          hasLength(6));
      expect(
          commands.where((command) => command['kind'] == 'waitForActorRoutes'),
          hasLength(6));
      expect(commands.where((command) => command['kind'] == 'actorVisibility'),
          hasLength(4));
      final routeSounds = commands
          .where((command) => command['kind'] == 'actorRoute')
          .expand((command) => (command['steps'] as List).cast<Map>())
          .where((step) => step['kind'] == 'sound')
          .toList();
      expect(routeSounds, hasLength(2));
      expect(
          routeSounds.every((step) => sounds.values
              .any((binding) => binding.mediaId == step['mediaAssetId'])),
          true);
      expect(json, contains('warp'));
      final arrival = scenes
          .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '1');
      final conditionNode = arrival.graph.nodes
          .singleWhere((node) => node.payload is SceneConditionPayload);
      final condition =
          (conditionNode.payload as SceneConditionPayload).conditionSource!;
      final nativeMap = result.nativeMaps[27]!;
      for (final atAnchor in [true, false]) {
        final playerPos = atAnchor
            ? entity.pos
            : GridPos(x: entity.pos.x, y: entity.pos.y + 1);
        final world =
            GameplayWorldState.initial(map: nativeMap, playerPos: playerPos);
        expect(
            evaluateScenePlayerAtEntityAnchor(
                source: condition, world: world, currentMapId: nativeMap.id),
            atAnchor);
      }
      final resetNode = arrival.graph.nodes.singleWhere((node) =>
          node.payload is SceneActionPayload &&
          (node.payload as SceneActionPayload).consequence
              is SceneSetMapEventInstanceBooleanConsequence);
      final reset = (resetNode.payload as SceneActionPayload).consequence
          as SceneSetMapEventInstanceBooleanConsequence;
      expect(reset.mapId, nativeMap.id);
      expect(reset.eventId, entity.id);
      expect(reset.key, 'A');
      expect(reset.value, true);
      expect(
          arrival.graph.edges
              .singleWhere((edge) =>
                  edge.fromNodeId == conditionNode.id &&
                  edge.fromPortId == 'false')
              .toNodeId,
          resetNode.id);
      final scope = MapInstanceRef(
          mapId: nativeMap.id, instanceId: 'native-door-instance');
      final state = GameState(
          saveId: 'native-door-save',
          mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
            nativeMap.id: MapInstanceRuntimeState(instanceId: scope.instanceId),
          }));
      final ready = SceneConditionSource.mapEventInstanceBoolean(
          mapId: nativeMap.id, eventId: entity.id, key: 'A', expected: false);
      expect(
          evaluateSceneMapEventInstanceBoolean(
              source: ready, gameState: state, map: nativeMap, scope: scope),
          true);
      final after = applySceneMapEventInstanceBoolean(
          gameState: state,
          consequence: reset,
          map: nativeMap,
          expectedInstance: scope);
      expect(
          evaluateSceneMapEventInstanceBoolean(
              source: ready, gameState: after, map: nativeMap, scope: scope),
          false);
      final ownRecords = result.registry.records
          .where((record) => scenes
              .any((scene) => scene.id == record.definitionOrNull?.sceneId))
          .toList();
      expect(ownRecords, hasLength(2));
      expect(
          ownRecords
              .singleWhere((record) => record.definitionOrNull!.priority == 1)
              .definitionOrNull!
              .conditions
              .map((condition) => condition.toJson())
              .toList(),
          [
            {
              'kind': 'mapEventInstanceBoolean',
              'mapId': nativeMap.id,
              'eventId': entity.id,
              'key': 'A',
              'expectedValue': false
            }
          ]);
      final registryJson = canonicalJsonOf(result.registry.toJson());
      expect(registryJson, contains('mapEventInstanceBoolean'));
      expect(registryJson, contains('entityBump'));
      expect(registryJson, contains('entityAutorun'));
    });

    test(
        'opening phases select the same departure pixel column for all four directions',
        () {
      final imported = imports.first;
      final native = image.decodePng(Uint8List.fromList(imported.outputBytes))!;
      final original =
          image.decodePng(Uint8List.fromList(imported.imageBytes))!;
      expect(imported.character.animations, hasLength(4));
      for (var row = 0; row < 4; row++) {
        final clip = imported.character.animations[row];
        expect(clip.frames.single.source.x, imported.sourcePattern * 64);
        expect(clip.frames.single.source.y, row * 64);
        for (var y = 0; y < imported.frameHeightPx; y++) {
          for (var x = 0; x < imported.frameWidthPx; x++) {
            final expected = original.getPixel(
                imported.sourcePattern * imported.frameWidthPx + x,
                row * imported.frameHeightPx + y);
            final actual = native.getPixel(
                imported.sourcePattern * 64 + imported.sourceOffsetXPx + x,
                row * 64 + imported.sourceOffsetYPx + y);
            expect([actual.r, actual.g, actual.b, actual.a],
                [expected.r, expected.g, expected.b, expected.a]);
          }
        }
      }
    });

    for (final scenario in [
      'arrivalPattern',
      'direction',
      'opacity',
      'hue',
      'blend',
      'moveSpeed',
      'through',
      'raw509',
      'sourceCharset',
      'arrivalSwitch',
      'arrivalTrigger'
    ]) {
      test('$scenario cannot expand the complete presentation capability',
          () async {
        final changed = await _variant(source, files, 'Data/Map027.rxdata',
            (document, bytes) {
          final page = _page(document, 17, 1);
          if (scenario == 'raw509') {
            final list = _field(document, _page(document, 17, 0), '@list');
            return _integer(
                bytes,
                _field(document, document.node(list.elements.last), '@code'),
                509);
          }
          if (scenario == 'arrivalSwitch') {
            final condition = _field(document, page, '@condition');
            return _integer(
                bytes, _field(document, condition, '@switch1_id'), 23);
          }
          if (scenario == 'arrivalTrigger') {
            return _integer(bytes, _field(document, page, '@trigger'), 0);
          }
          if (scenario == 'sourceCharset') {
            final changed = List<int>.of(bytes);
            for (var index = 0; index < 2; index++) {
              final graphic =
                  _field(document, _page(document, 17, index), '@graphic');
              final name = _field(document, graphic, '@character_name');
              expect(name.bytes!.last, 0x34);
              changed[name.dataOffset! + name.bytes!.length - 1] = 0x33;
            }
            return changed;
          }
          final graphic = _field(document, page, '@graphic');
          if (scenario == 'through') {
            final node = _field(document, page, '@through');
            final changed = List<int>.of(bytes);
            changed[node.location.byteOffset] = 0x54;
            return changed;
          }
          if (scenario == 'moveSpeed') {
            return _integer(bytes, _field(document, page, '@move_speed'), 6);
          }
          final (field, value) = switch (scenario) {
            'arrivalPattern' => ('@pattern', 2),
            'direction' => ('@direction', 4),
            'opacity' => ('@opacity', 200),
            'hue' => ('@character_hue', 1),
            _ => ('@blend_type', 1),
          };
          return _integer(bytes, _field(document, graphic, field), value);
        });
        final parsed = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.forProject(changed.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        expect(
            sourceRoutedDoorPrograms(source: changed.source, analysis: parsed)
                .containsKey(door.identity),
            false);
        expect(
            programs[door.identity]!.isBoundTo(
                source: changed.source,
                analysis: parsed,
                event: parsed.eventAt(27, 17)!),
            false);
      });
    }

    test('graphic changes without a qualifying full program remain refused',
        () {
      final result = project(selectedPrograms: const {});
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == door.identity.value);
      expect(row['gaps'], contains('pageGraphicChanges'));
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value),
          isEmpty);
    });

    for (final selected in [
      ({27, 30}, 27, 17),
      ({225, 228}, 225, 4)
    ]) {
      test(
          'real ${selected.$2}/${selected.$3} complete program composes writes and strictly reopens',
          () async {
        const limits = NativeWriteLimits(maxArtifacts: 128, maxMutations: 512);
        final fixture = await readExternalOriginalSource(root!, snapshot!,
            selectedMapIds: selected.$1, supplementalRoots: supplementalRoots);
        final temporary =
            await Directory.systemTemp.createTemp('native-door-skin-');
        addTearDown(() => temporary.delete(recursive: true));
        Future<LiteralTileComposition> literal(
                List<LiteralDependencyDecision> decisions) =>
            const LiteralTileComposer().compose(
                source: fixture.source,
                files: fixture.files,
                selectedSourceMapIds: selected.$1.toList()..sort(),
                projectName: 'Native door skin',
                parentPath: temporary.path,
                folderName: 'native-door-skin',
                dependencyDecisions: decisions,
                limits: limits);
        print('door proof ${selected.$2}/${selected.$3}: literal probe');
        final probe = await literal([]);
        final decisions = [
          for (final dependency in probe.dependencies)
            if (!selected.$1.contains(dependency.targetSourceMapId))
              LiteralDependencyDecision(
                  sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
                  selectionHash: probe.selectionHash,
                  locator: dependency.locator,
                  targetSourceMapId: dependency.targetSourceMapId,
                  decision: LiteralDependencyDisposition.excludeStudy)
        ];
        print('door proof ${selected.$2}/${selected.$3}: literal selected');
        final composed = await literal(decisions);
        expect(composed.draft, isNotNull,
            reason:
                composed.diagnostics.map((entry) => entry.toJson()).toString());
        print('door proof ${selected.$2}/${selected.$3}: semantic');
        final semantic = await const SourceSemanticStudyComposer().compose(
            source: fixture.source,
            base: composed,
            files: fixture.files,
            limits: limits);
        print('door proof ${selected.$2}/${selected.$3}: events');
        final events = await const SourceEventStudyComposer().compose(
            source: fixture.source,
            base: semantic!,
            files: fixture.files,
            limits: limits);
        expect(events, isNotNull);
        final parsed = SourceEventAnalyzer.forProject(fixture.source,
                profile: SourceEventProfile.forProject(fixture.source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        final event = parsed.eventAt(selected.$2, selected.$3)!;
        final scenes = events!.projection.scenes
            .where((scene) =>
                scene.metadata['sourceEventIdentity'] == event.identity.value)
            .toList();
        final row = (events.projection.semanticEvidence['events'] as List)
            .cast<Map>()
            .singleWhere(
                (row) => row['sourceIdentity'] == event.identity.value);
        expect(scenes, hasLength(2), reason: row.toString());
        final forgedEvidence =
            jsonDecode(canonicalJsonOf(events.draft.compositionEvidence))
                as Map<String, Object?>;
        final sourceEvents = forgedEvidence['sourceEvents'] as Map;
        final projection = sourceEvents['projection'] as Map;
        final doorQualification =
            projection['doorExecutionQualification'] as Map;
        final routedPrograms = doorQualification['routedDoorPrograms'] as List;
        final ownProgram = routedPrograms.cast<Map>().singleWhere(
            (program) => program['eventIdentity'] == event.identity.value);
        final presentation = ownProgram['presentationAdaptation'] as Map;
        presentation['nativePattern'] =
            ((presentation['nativePattern'] as int) + 1) % 4;
        final forged = NativeProjectDraft(
            source: events.draft.source,
            projectName: events.draft.projectName,
            parentPath: events.draft.parentPath,
            folderName: events.draft.folderName,
            mapIds: events.draft.mapIds,
            artifacts: events.draft.artifacts,
            sourceArtifacts: events.draft.sourceArtifacts,
            compositionEvidence: forgedEvidence,
            mutations: events.draft.mutations,
            limits: limits);
        final forgedApproval = approveNativeFixtureDraft(forged);
        final stages = <NativeWriteStage>[];
        print('door proof ${selected.$2}/${selected.$3}: forged policy');
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(forgedApproval.plan, forgedApproval.context, forged,
                    limits: limits),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'native.semantics.regeneration')));
        expect(stages, isEmpty);
        expect(
            await Directory('${temporary.path}/${forged.folderName}').exists(),
            isFalse);
        final approval = approveNativeFixtureDraft(events.draft);
        print('door proof ${selected.$2}/${selected.$3}: writer');
        final receipt = await NativeProjectWriter().write(
            approval.plan, approval.context, events.draft,
            limits: limits);
        expect(receipt.verified, true);
        print('door proof ${selected.$2}/${selected.$3}: strict reopen');
        final handles = WorkspaceHandleStore();
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
        final opener = ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles);
        final opened = await opener.openProject(receipt.projectPath);
        try {
          final loaded = await ProjectSnapshotLoader(handles: handles).load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.strict);
          expect(loaded.loadDiagnostics, isEmpty);
          final map = loaded.mapById(events.draft.mapIds[selected.$2]!)!;
          final entity = map.entities.singleWhere((entity) =>
              entity.properties['sourceEventIdentity'] == event.identity.value);
          final imported = await const SourceEventCharacterImporter().read(
              snapshot: fixture.source.snapshot,
              files: fixture.files,
              charsetName: event.pages.first.graphic!.characterName,
              sourcePattern: event.pages.first.graphic!.pattern,
              sourceDirection: event.pages.first.graphic!.direction);
          expect(entity.npc!.characterId, imported.character.id);
          expect(
              loaded.manifest.eventRegistry!.records.where((record) =>
                  scenes.any(
                      (scene) => scene.id == record.definitionOrNull?.sceneId)),
              hasLength(2));
          for (final scene in scenes) {
            expect(
                loaded.manifest.scenes
                    .singleWhere((asset) => asset.id == scene.id)
                    .toJson(),
                scene.toJson());
          }
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }, timeout: const Timeout(Duration(minutes: 15)));
    }

    test('forged native AST cannot reuse exact raw event authority', () {
      final page = door.pages.first;
      final forged = SourceEventDefinition(
          sourceMapId: door.sourceMapId,
          sourceEventId: door.sourceEventId,
          sourceFileId: door.sourceFileId,
          identity: door.identity,
          name: door.name,
          x: door.x,
          y: door.y,
          locator: door.locator,
          pages: [
            SourceEventPageAnalysis(
                sourcePage: page.sourcePage,
                locator: page.locator,
                condition: page.condition,
                graphic: page.graphic,
                body: SourceEventBlock(nodes: [
                  for (final node in page.body.nodes)
                    if (node is SourceWaitNode)
                      SourceWaitNode(node.span,
                          durationTicks: node.durationTicks + 1,
                          profileHash: node.profileHash)
                    else
                      node
                ], span: page.body.span),
                rawDataRef: page.rawDataRef,
                diagnostics: []),
            door.pages.last
          ]);
      final forgedAnalysis = SourceEventAnalysis(
          profile: analysis.profile, events: [forged], diagnostics: []);
      expect(sourceRoutedDoorPrograms(source: source, analysis: forgedAnalysis),
          isEmpty);
      expect(() => project(selected: forgedAnalysis),
          throwsA(isA<NativeWriteException>()));
    });
  }, skip: root == null || snapshot == null || !Platform.isMacOS);
}
