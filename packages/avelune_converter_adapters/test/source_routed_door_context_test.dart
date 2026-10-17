import 'dart:io';
import 'package:map_gameplay/map_gameplay.dart';

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
  group('source typed routed door context', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceRoutedDoorProgram> programs;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late MapInstanceRetentionPolicy retention;
    late Map<String, SourceEventSoundBinding> sounds;
    late SourceEventDefinition door;
    late Map<String, SourceEventCharacterBinding> characters;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {6, 9}, supplementalRoots: supplementalRoots);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      maps = _maps(source);
      door = analysis.eventAt(6, 2)!;
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
      final graphic = source.snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Graphics/Characters/OBJ_FRLG_Doors3.png');
      characters = {
        sourceEventCharacterBindingKey(
                characterName: 'OBJ_FRLG_Doors3', pattern: 1, direction: 2):
            SourceEventCharacterBinding(
                characterId: 'lab_door_character',
                sourceSnapshotHash: source.snapshot.canonicalHash,
                sourceFileId: graphic.fileId,
                sourceFileHash: graphic.sha256!,
                sourcePattern: 1,
                sourceDirection: 2)
      };
    });
    SourceEventProjection project(
            {Map<int, MapData>? nativeMaps,
            Map<ConverterId, SourceEventExecutionContext>? executionContexts,
            Map<String, SourceEventCharacterBinding>? characterBindings,
            Map<String, SourceEventSoundBinding>? soundBindings,
            bool keepRetention = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: nativeMaps ?? maps,
            routedDoorPrograms: programs,
            routedDoorContexts: executionContexts ?? contexts,
            characterBindings: characterBindings ?? characters,
            soundBindings: soundBindings ?? sounds,
            retentionPolicy: keepRetention ? retention : null);

    test('exact program local context admits both complete Map6 pages', () {
      final context = contexts[door.identity]!;
      expect(context.isQualified, true, reason: context.refusals.toString());
      expect(
          context.supportsRouteBarrierOnSourceMap(6,
              eventIdentity: door.identity),
          true);
      expect(
          context.supportsRouteBarrierOnSourceMap(9,
              eventIdentity: door.identity),
          false);
      expect(context.supportsRouteBarrierOnSourceMap(6), false);
      expect(
          context.supportsRouteBarrierOnSourceMap(6,
              eventIdentity: ConverterId('other_event')),
          false);
      final result = project();
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == door.identity.value);
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value),
          hasLength(2),
          reason: row.toString());
      final actions = result.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value)
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>();
      final commands = actions
          .map((action) => action.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .map((command) => command.toJson())
          .toList();
      expect(
          commands.where((command) => command['kind'] == 'waitForActorRoutes'),
          hasLength(6));
      expect(commands.where((command) => command['kind'] == 'actorRoute'),
          hasLength(6));
      expect(commands.where((command) => command['kind'] == 'actorVisibility'),
          hasLength(4));
      expect(canonicalJsonOf(result.semanticEvidence),
          contains('mapEventInstance'));
    });

    for (final scenario in [
      'missingContext',
      'changedNativeMap',
      'missingActor',
      'missingSound',
      'missingRetention',
      'blockedArrival'
    ]) {
      test('$scenario refuses the entire routed source event', () {
        final changed = {...maps};
        if (scenario == 'changedNativeMap') {
          changed[6] = maps[6]!.copyWith(name: 'Changed');
        }
        if (scenario == 'blockedArrival') {
          final target = maps[9]!;
          final cells =
              List<bool>.filled(target.size.width * target.size.height, true);
          changed[9] = target.copyWith(layers: [
            MapLayer.collision(
                id: 'blocked', name: 'Blocked', collisions: cells)
          ]);
        }
        final result = project(
            nativeMaps: changed,
            executionContexts: scenario == 'missingContext' ? {} : null,
            characterBindings: scenario == 'missingActor' ? {} : null,
            soundBindings: scenario == 'missingSound' ? {} : null,
            keepRetention: scenario != 'missingRetention');
        expect(
            result.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] == door.identity.value),
            isEmpty);
      });
    }

    test('public incomplete analysis cannot hide neighboring route autonomy',
        () async {
      final actor = analysis.events.firstWhere((event) =>
          event.sourceMapId == 6 &&
          event.pages.any((page) => page.graphic?.moveType == 3));
      final routeId = actor.pages
          .firstWhere((page) => page.graphic?.moveType == 3)
          .graphic!
          .moveRouteNodeId;
      final changed = await _variant(source, files, 'Data/Map006.rxdata',
          (document, bytes) {
        final step = document.node(
            _field(document, document.node(routeId), '@list').elements.first);
        return _integer(bytes, _field(document, step, '@code'), 45);
      });
      final actual = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      final forged = SourceEventAnalysis(
          profile: actual.profile,
          events: [actual.eventAt(6, 2)!],
          diagnostics: []);
      final selected =
          sourceRoutedDoorPrograms(source: changed.source, analysis: forged);
      final native = _maps(changed.source);
      final contexts = await const SourceEventExecutionContextResolver()
          .readRoutedTransfers(
              source: changed.source,
              base: _base(changed.source, native),
              nativeMaps: native,
              files: changed.files,
              programs: selected,
              analysis: forged);
      expect(contexts[door.identity]!.refusals,
          contains('sourceMapAutonomyContextUnsupported'));
    });

    test('fresh parallel page refuses routed map execution context', () async {
      final changed = await _variant(
          source,
          files,
          'Data/Map006.rxdata',
          (document, bytes) => _integer(
              bytes, _field(document, _page(document, 15, 0), '@trigger'), 4));
      final parsed = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      final selected =
          sourceRoutedDoorPrograms(source: changed.source, analysis: parsed);
      final native = _maps(changed.source);
      final contexts = await const SourceEventExecutionContextResolver()
          .readRoutedTransfers(
              source: changed.source,
              base: _base(changed.source, native),
              nativeMaps: native,
              files: changed.files,
              programs: selected,
              analysis: parsed);
      expect(contexts[door.identity]!.refusals,
          contains('sourceParallelEventUnsupported'));
    });

    test('raw forced route alteration cannot mint a complete program',
        () async {
      final changed = await _variant(source, files, 'Data/Map006.rxdata',
          (document, bytes) {
        final commands = _field(document, _page(document, 2, 0), '@list');
        final copy = document.node(commands.elements[3]);
        final parameters = _field(document, copy, '@parameters');
        return _integer(
            bytes,
            _field(
                document, document.node(parameters.elements.single), '@code'),
            18);
      });
      final parsed = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      expect(
          sourceRoutedDoorPrograms(source: changed.source, analysis: parsed)
              .containsKey(door.identity),
          false);
    });

    for (final code in [505, 509]) {
      test('extra raw $code cannot mint a whole program', () async {
        final changed = await _variant(source, files, 'Data/Map006.rxdata',
            (document, bytes) {
          final list = _field(document, _page(document, 2, 0), '@list');
          return _integer(
              bytes,
              _field(document, document.node(list.elements.last), '@code'),
              code);
        });
        final parsed = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        expect(
            sourceRoutedDoorPrograms(source: changed.source, analysis: parsed)
                .containsKey(door.identity),
            false);
      });
    }

    test('visible source pattern changes remain unsupported', () async {
      final changed = await _variant(source, files, 'Data/Map006.rxdata',
          (document, bytes) {
        final graphic = _field(document, _page(document, 2, 1), '@graphic');
        return _integer(bytes, _field(document, graphic, '@pattern'), 3);
      });
      final parsed = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      expect(parsed.eventAt(6, 2)!.isQuarantined, false);
      expect(
          sourceRoutedDoorPrograms(source: changed.source, analysis: parsed)
              .containsKey(door.identity),
          false);
    });

    test('actual invisible exit keeps both pages with an inert empty pattern',
        () async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {15, 19}, supplementalRoots: supplementalRoots);
      final changed =
          await _variant(fixture.source, fixture.files, 'Data/Map015.rxdata',
              (document, bytes) {
        final graphic = _field(document, _page(document, 23, 1), '@graphic');
        return _integer(bytes, _field(document, graphic, '@pattern'), 3);
      });
      final parsed = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      final event = parsed.eventAt(15, 23)!;
      expect(event.pages, hasLength(2));
      expect(
          event.pages.every((page) =>
              page.graphic!.characterName.isEmpty && page.graphic!.tileId == 0),
          true);
      final programs =
          sourceRoutedDoorPrograms(source: changed.source, analysis: parsed);
      expect(programs[event.identity], isNotNull);
      expect(
          programs[event.identity]!.isBoundTo(
              source: changed.source, analysis: parsed, event: event),
          true);
    });

    test('legitimate paired event selection keeps complete source context', () {
      final selected = SourceEventAnalysis(
          profile: analysis.profile, events: [door], diagnostics: []);
      final result = const SourceEventProjector().project(
          source: source,
          analysis: selected,
          nativeMaps: maps,
          staticDoorPrograms: const {},
          routedDoorPrograms: {door.identity: programs[door.identity]!},
          routedDoorContexts: {door.identity: contexts[door.identity]!},
          characterBindings: characters,
          soundBindings: sounds,
          retentionPolicy: retention);
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value),
          hasLength(2));
      expect(result.semanticEvidence['events'], hasLength(1));
    });

    test('omitted destination program cannot hide required arrival owner',
        () async {
      final exit = analysis.eventAt(9, 7)!;
      final selected =
          sourceStaticDoorPrograms(source: source, analysis: analysis);
      final staticContexts = await const SourceEventExecutionContextResolver()
          .readStaticTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: files,
              programs: selected,
              analysis: analysis);
      final subset = SourceEventAnalysis(
          profile: analysis.profile, events: [exit], diagnostics: []);
      for (final input in [analysis, subset]) {
        final result = const SourceEventProjector().project(
            source: source,
            analysis: input,
            nativeMaps: maps,
            staticDoorPrograms: selected,
            staticDoorContexts: staticContexts,
            routedDoorPrograms: programs,
            routedDoorContexts: const {},
            characterBindings: characters,
            soundBindings: sounds,
            retentionPolicy: retention);
        final row = (result.semanticEvidence['events'] as List)
            .cast<Map>()
            .singleWhere((row) => row['sourceIdentity'] == exit.identity.value);
        expect(
            result.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] == exit.identity.value),
            isEmpty);
        expect(row['gaps'], contains('warpArrivalOwnerUnavailable'));
      }
    });

    for (final scenario in [
      (
        name: 'routed contact',
        maps: {15, 19},
        ownerMap: 15,
        ownerEvent: 23,
        obstacleMap: 15,
        routed: true,
        arrival: false
      ),
      (
        name: 'static contact',
        maps: {6, 9},
        ownerMap: 9,
        ownerEvent: 7,
        obstacleMap: 9,
        routed: false,
        arrival: false
      ),
      (
        name: 'routed arrival',
        maps: {6, 9},
        ownerMap: 6,
        ownerEvent: 2,
        obstacleMap: 9,
        routed: true,
        arrival: true
      ),
      (
        name: 'static arrival',
        maps: {6, 7},
        ownerMap: 7,
        ownerEvent: 1,
        obstacleMap: 6,
        routed: false,
        arrival: true
      ),
    ]) {
      test('omitted source obstacle cannot weaken ${scenario.name}', () async {
        final fixture = await readExternalOriginalSource(root!, snapshot!,
            selectedMapIds: scenario.maps,
            supplementalRoots: supplementalRoots);
        final before = SourceEventAnalyzer.forProject(fixture.source,
                profile: SourceEventProfile.kantoForProject(fixture.source))
            .analyze();
        final original =
            before.eventAt(scenario.ownerMap, scenario.ownerEvent)!;
        final warp = original.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceWarpNode>()
            .single;
        final x = scenario.arrival ? warp.x : original.x;
        final y = scenario.arrival ? warp.y : original.y;
        final victim = before.events.firstWhere((event) =>
            event.sourceMapId == scenario.obstacleMap &&
            event.identity != original.identity &&
            event.pages.every((page) => page.graphic?.moveType == 0));
        final changed = await _variant(fixture.source, fixture.files,
            'Data/Map${scenario.obstacleMap.toString().padLeft(3, '0')}.rxdata',
            (document, bytes) {
          final pairs =
              _field(document, document.node(document.rootId), '@events');
          final raw = document.node(pairs.pairs
              .singleWhere((pair) =>
                  document.node(pair.key).integerValue ==
                  BigInt.from(victim.sourceEventId))
              .value);
          final image = _field(
              document, _page(document, victim.sourceEventId, 0), '@graphic');
          final edits = [
            (_field(document, raw, '@x'), x),
            (_field(document, raw, '@y'), y),
            (_field(document, image, '@tile_id'), 384)
          ]..sort((a, b) =>
              b.$1.location.byteOffset.compareTo(a.$1.location.byteOffset));
          var result = bytes;
          for (final edit in edits) {
            result = _integer(result, edit.$1, edit.$2);
          }
          return result;
        });
        final actual = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        final bound = actual.eventAt(scenario.ownerMap, scenario.ownerEvent)!;
        final forged = SourceEventAnalysis(
            profile: actual.profile, events: [bound], diagnostics: []);
        final staticPrograms = scenario.routed
            ? <ConverterId, SourceStaticDoorProgram>{}
            : sourceStaticDoorPrograms(
                source: changed.source, analysis: forged);
        final routedPrograms = scenario.routed
            ? sourceRoutedDoorPrograms(source: changed.source, analysis: forged)
            : <ConverterId, SourceRoutedDoorProgram>{};
        final native = _maps(changed.source);
        final contexts = await const SourceEventExecutionContextResolver()
            .readTransfers(
                source: changed.source,
                base: _base(changed.source, native),
                nativeMaps: native,
                files: changed.files,
                programs: staticPrograms,
                routedPrograms: routedPrograms,
                analysis: forged);
        expect(contexts[bound.identity]!.isQualified, true,
            reason: contexts[bound.identity]!.refusals.toString());
        final policy = await sourceEventMapRetentionPolicy(
            source: changed.source,
            files: changed.files,
            nativeMapIds: {for (final e in native.entries) e.key: e.value.id});
        final effects = {
          for (final name in ['Entering Door', 'Exit Door'])
            name: await const SourceEventSoundResolver()
                .read(source: changed.source, files: changed.files, name: name)
        };
        final sourceCharacters = <String, SourceEventCharacterBinding>{};
        for (final page in bound.pages) {
          final graphic = page.graphic!;
          if (graphic.characterName.isEmpty) continue;
          final file = changed.source.snapshot.entries.singleWhere((entry) =>
              entry.relativePath ==
              'Graphics/Characters/${graphic.characterName}.png');
          sourceCharacters[sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction)] =
              SourceEventCharacterBinding(
                  characterId: 'source_door_actor',
                  sourceSnapshotHash: changed.source.snapshot.canonicalHash,
                  sourceFileId: file.fileId,
                  sourceFileHash: file.sha256!,
                  sourcePattern: graphic.pattern,
                  sourceDirection: graphic.direction);
        }
        for (final selected in [actual, forged]) {
          final result = const SourceEventProjector().project(
              source: changed.source,
              analysis: selected,
              nativeMaps: native,
              staticDoorPrograms: staticPrograms,
              routedDoorPrograms: routedPrograms,
              staticDoorContexts: scenario.routed ? {} : contexts,
              routedDoorContexts: scenario.routed ? contexts : {},
              characterBindings: sourceCharacters,
              soundBindings: effects,
              retentionPolicy: policy);
          final row = (result.semanticEvidence['events'] as List)
              .cast<Map>()
              .singleWhere(
                  (row) => row['sourceIdentity'] == bound.identity.value);
          expect(
              result.scenes.where((scene) =>
                  scene.metadata['sourceEventIdentity'] ==
                  bound.identity.value),
              isEmpty,
              reason:
                  '${scenario.name} ${identical(selected, forged) ? 'subset' : 'full'} $row');
          expect(
              row['gaps'],
              contains(scenario.arrival
                  ? 'warpArrivalSourceActorUnqualified'
                  : 'sourceTouchContactUnqualified'));
        }
      });
    }

    test('forged complete event AST cannot reuse raw source references', () {
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
      final analysisWithForgery = SourceEventAnalysis(
          profile: analysis.profile, events: [forged], diagnostics: []);
      expect(
          sourceRoutedDoorPrograms(
              source: source, analysis: analysisWithForgery),
          isEmpty);
      expect(
          programs[door.identity]!.isBoundTo(
              source: source, analysis: analysisWithForgery, event: forged),
          false);
    });

    test('unknown existing native actor prevents closed route capability',
        () async {
      final native = {...maps};
      native[6] = maps[6]!.copyWith(entities: [
        MapEntity(
            id: 'unknown_actor',
            name: 'Unknown',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            size: const GridSize(width: 1, height: 1),
            npc: const MapEntityNpcData(
                characterId: 'unknown', displayName: 'Unknown'))
      ]);
      final contexts = await const SourceEventExecutionContextResolver()
          .readRoutedTransfers(
              source: source,
              base: _base(source, native),
              nativeMaps: native,
              files: files,
              programs: programs,
              analysis: analysis);
      expect(contexts[door.identity]!.refusals,
          contains('sourceForcedRouteActorSetUnsupported'));
    });

    test('static context cannot authorize a routed program barrier', () async {
      final selected =
          sourceStaticDoorPrograms(source: source, analysis: analysis);
      final staticContexts = await const SourceEventExecutionContextResolver()
          .readStaticTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: files,
              programs: selected,
              analysis: analysis);
      final result = project(executionContexts: {
        door.identity: staticContexts[analysis.eventAt(9, 7)!.identity]!
      });
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value),
          isEmpty);
    });

    test(
        'native instance lifetime preserves retained A and resets on different-map setup',
        () {
      var serial = 0;
      final initial = setupDifferentMapInstance(
          state: const MapInstanceWorldState.empty(),
          targetMapId: maps[6]!.id,
          allocateId: (_) => 'instance_${serial++}');
      final ref = initial.instanceRef(maps[6]!.id)!;
      final marked = initial.setEventBoolean(ref, 'door', 'A', true);
      expect(
          preserveSameMapInstance(state: marked, mapId: maps[6]!.id)
              .eventBoolean(ref, 'door', 'A'),
          true);
      final transferred = setupDifferentMapInstance(
          state: marked,
          targetMapId: maps[9]!.id,
          allocateId: (_) => 'instance_${serial++}');
      final returned = setupDifferentMapInstance(
          state: transferred,
          targetMapId: maps[6]!.id,
          allocateId: (_) => 'instance_${serial++}');
      expect(
          returned.eventBoolean(
              returned.instanceRef(maps[6]!.id)!, 'door', 'A'),
          false);
    });

    test('actual nonpinned Map6 lab door is a complete routed candidate', () {
      final candidates = sourceDoorEventProjectionCandidates(
          source: source, analysis: analysis);
      expect(
          candidates.map((event) => (event.sourceMapId, event.sourceEventId)),
          contains((6, 2)));
    });
    test('actual routed door survives composer, disk writer and strict reopen',
        () async {
      const limits = NativeWriteLimits(maxArtifacts: 96);
      final temporary =
          await Directory.systemTemp.createTemp('static-door-writer-');
      addTearDown(() => temporary.delete(recursive: true));
      Future<LiteralTileComposition> literal(
              List<LiteralDependencyDecision> decisions) =>
          const LiteralTileComposer().compose(
              source: source,
              files: files,
              selectedSourceMapIds: [6, 9],
              projectName: 'Static door source',
              parentPath: temporary.path,
              folderName: 'static-door-source',
              dependencyDecisions: decisions,
              limits: limits);
      final probe = await literal([]);
      final decisions = [
        for (final dependency in probe.dependencies)
          if (!const {6, 9}.contains(dependency.targetSourceMapId))
            LiteralDependencyDecision(
                sourceSnapshotHash: source.snapshot.canonicalHash,
                selectionHash: probe.selectionHash,
                locator: dependency.locator,
                targetSourceMapId: dependency.targetSourceMapId,
                decision: LiteralDependencyDisposition.excludeStudy)
      ];
      final composedLiteral = await literal(decisions);
      expect(composedLiteral.draft, isNotNull,
          reason: composedLiteral.diagnostics
              .map((value) => value.toJson())
              .toString());
      final semantic = await const SourceSemanticStudyComposer().compose(
          source: source, base: composedLiteral, files: files, limits: limits);
      expect(semantic, isNotNull);
      final events = await const SourceEventStudyComposer().compose(
          source: source, base: semantic!, files: files, limits: limits);
      expect(events, isNotNull);
      final projectedDoor = (events!.projection.semanticEvidence['events']
              as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == door.identity.value);
      expect(
          events.projection.scenes.any((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value),
          isTrue,
          reason: projectedDoor['gaps'].toString());
      expect(
          events.projection.scenes.any((scene) =>
              scene.metadata['sourceEventIdentity'] ==
              analysis.eventAt(9, 7)!.identity.value),
          true);
      final approval = approveNativeFixtureDraft(events.draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, events.draft, limits: limits);
      expect(receipt.verified, isTrue);
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
        final native = loaded.mapById(events.draft.mapIds[6]!)!;
        expect(native.triggers, isNotEmpty);
        expect(
            loaded.manifest.eventRegistry!.records.any((record) =>
                record.definitionOrNull?.sceneId ==
                events.projection.scenes
                    .firstWhere((scene) =>
                        scene.metadata['sourceEventIdentity'] ==
                        door.identity.value)
                    .id),
            isTrue);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  },
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);
}
