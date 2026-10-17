import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as image;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'support/native_writer_fixture.dart';
import 'support/literal_tile_fixture.dart';
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

SourceEventDefinition _withNodes(
    SourceEventDefinition event, List<SourceEventNode> nodes) {
  final page = event.pages.single;
  return SourceEventDefinition(
      sourceMapId: event.sourceMapId,
      sourceEventId: event.sourceEventId,
      sourceFileId: event.sourceFileId,
      identity: event.identity,
      name: event.name,
      x: event.x,
      y: event.y,
      locator: event.locator,
      pages: [
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: page.graphic,
            body: SourceEventBlock(nodes: nodes, span: page.body.span),
            rawDataRef: page.rawDataRef,
            diagnostics: [])
      ]);
}

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final supplemental =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((value) => value.isNotEmpty)
          .toList();
  group('complete bounded source stairs', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late Map<ConverterId, SourceStairProgram> programs;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {
            7,
            19,
            38,
            39,
            42,
            43,
            44,
            55,
            86,
            87,
            90,
            93,
            96,
            97,
            107,
            112,
            122,
            126,
            130,
            158,
            159,
            160,
            161,
            162,
            163,
            164,
            173,
            174,
            175,
            176,
            180,
            183,
            185,
            186,
            187,
            197,
            198,
            199,
            200,
            213,
            214,
            215,
            216,
            217,
            218,
            219,
            220,
            221,
            222,
            223
          },
          supplementalRoots: supplemental);
      source = fixture.source;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      programs = sourceStairPrograms(source: source, analysis: analysis);
    });
    test('all102 standard stairs plus two pre-restored programs are typed', () {
      expect(programs, hasLength(104));
      expect(programs.values.map((program) => program.family).toSet(),
          hasLength(19));
      for (final program in programs.values) {
        expect(
            program.isBoundTo(
                source: source,
                analysis: analysis,
                event: analysis.events.singleWhere(
                    (event) => event.identity == program.eventIdentity)),
            true);
      }
    });
    for (final pair in [
      (7, 2),
      (7, 3),
      (19, 17),
      (19, 3),
      (38, 9),
      (38, 10),
      (38, 50),
      (38, 51),
      (38, 4),
      (55, 23),
      (55, 24),
      (86, 3),
      (87, 1),
      (173, 1),
      (176, 3),
      (180, 1),
      (183, 2),
      (173, 3),
      (198, 5)
    ]) {
      test(
          'complete family ${pair.$1}/${pair.$2} preserves raw binding and rejects AST forgery',
          () {
        final event = analysis.eventAt(pair.$1, pair.$2)!;
        final program = programs[event.identity];
        expect(program, isNotNull);
        final body = event.pages.single.body.nodes;
        final conditional = body.singleOrNull is SourceConditionalNode
            ? body.single as SourceConditionalNode
            : null;
        final nodes = conditional?.whenTrue.nodes ?? body;
        final forgedNodes = [
          for (final node in nodes)
            if (node is SourceWarpNode)
              SourceWarpNode(node.span,
                  targetSourceMapId: node.targetSourceMapId,
                  x: node.x + 1,
                  y: node.y,
                  direction: node.direction,
                  fade: node.fade)
            else
              node
        ];
        final forged = _withNodes(
            event,
            conditional == null
                ? forgedNodes
                : [
                    SourceConditionalNode(conditional.span,
                        condition: conditional.condition,
                        whenTrue: SourceEventBlock(
                            nodes: forgedNodes,
                            span: conditional.whenTrue.span),
                        whenFalse: conditional.whenFalse)
                  ]);
        final selected = SourceEventAnalysis(
            profile: analysis.profile, events: [forged], diagnostics: []);
        expect(
            sourceStairPrograms(source: source, analysis: selected), isEmpty);
        expect(
            program!
                .isBoundTo(source: source, analysis: selected, event: forged),
            false);
      });
    }
    test('subset source analysis still has a fresh complete raw authority', () {
      final event = analysis.eventAt(7, 2)!;
      final subset = SourceEventAnalysis(
          profile: analysis.profile, events: [event], diagnostics: []);
      expect(sourceStairPrograms(source: source, analysis: subset).keys,
          [event.identity]);
      final nodes =
          (event.pages.single.body.nodes.single as SourceConditionalNode)
              .whenTrue
              .nodes;
      expect(
          nodes
              .whereType<SourceForcedMoveRouteNode>()
              .last
              .steps
              .map((step) => step.sourceCode),
          [38, 40]);
    });
  },
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);

  group('stair source and native authority', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceStairProgram> programs;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late MapInstanceRetentionPolicy retention;
    late Map<String, SourceEventSoundBinding> sounds;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {7}, supplementalRoots: supplemental);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      maps = _maps(source);
      programs = sourceStairPrograms(source: source, analysis: analysis);
      contexts = await const SourceEventExecutionContextResolver()
          .readTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: files,
              programs: const {},
              stairPrograms: programs,
              analysis: analysis);
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      sounds = {
        'Exit Door': await const SourceEventSoundResolver()
            .read(source: source, files: files, name: 'Exit Door')
      };
    });
    SourceEventProjection project(
            {Map<ConverterId, SourceEventExecutionContext>? supplied,
            Map<int, MapData>? nativeMaps,
            SourceEventAnalysis? selected,
            bool keepSound = true,
            bool keepRetention = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: selected ?? analysis,
            nativeMaps: nativeMaps ?? maps,
            staticDoorPrograms: const {},
            routedDoorPrograms: const {},
            stairPrograms: programs,
            stairContexts: supplied ?? contexts,
            soundBindings: keepSound ? sounds : const {},
            retentionPolicy: keepRetention ? retention : null);
    test(
        'exact native commands preserve direction timing flags and restoration',
        () {
      final event = analysis.eventAt(7, 2)!;
      final context = contexts[event.identity]!;
      expect(context.isQualified, true, reason: context.refusals.toString());
      expect(
          context.supportsRouteBarrierOnSourceMap(7,
              eventIdentity: event.identity),
          true);
      expect(context.supportsRouteBarrierOnSourceMap(7), false);
      expect(
          context.supportsRouteBarrierOnSourceMap(6,
              eventIdentity: event.identity),
          false);
      final result = project();
      final scene = result.scenes.singleWhere((scene) =>
          scene.metadata['sourceEventIdentity'] == event.identity.value);
      final commands = scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((action) => action.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .map((command) => command.toJson())
          .toList();
      final routes =
          commands.where((command) => command['kind'] == 'actorRoute').toList();
      expect(routes, hasLength(2));
      expect(routes.every((route) => route['transientScope'] == 'scene'), true);
      final forward =
          routes.singleWhere((route) => (route['steps'] as List).length == 5);
      expect((forward['steps'] as List).cast<Map>().map((step) => step['kind']),
          ['through', 'renderAboveMap', 'face', 'move', 'moveDiagonal']);
      final moves = (forward['steps'] as List).cast<Map>();
      expect(moves.where((step) => step['durationMs'] == 250), hasLength(2));
      expect(moves.singleWhere((step) => step['kind'] == 'face')['yieldAfter'],
          true);
      expect(
          (routes.singleWhere(
                      (route) => (route['steps'] as List).length == 2)['steps']
                  as List)
              .cast<Map>()
              .map((step) => step['enabled']),
          [false, false]);
      expect(
          commands.where((command) => command['kind'] == 'waitForActorRoutes'),
          hasLength(1));
      expect(commands.where((command) => command['kind'] == 'worldTone'),
          hasLength(2));
      expect(
          commands.singleWhere(
              (command) => command['kind'] == 'wait')['durationMs'],
          400);
    });
    for (final scenario in [
      'missingContext',
      'wrongEventContext',
      'nativeMapChanged',
      'missingSound',
      'missingRetention'
    ]) {
      test('$scenario refuses the whole stair event', () {
        final event = analysis.eventAt(7, 2)!;
        final supplied = scenario == 'missingContext'
            ? <ConverterId, SourceEventExecutionContext>{}
            : scenario == 'wrongEventContext'
                ? {event.identity: contexts[analysis.eventAt(7, 3)!.identity]!}
                : contexts;
        final result = project(
            supplied: supplied,
            nativeMaps: scenario == 'nativeMapChanged'
                ? {7: maps[7]!.copyWith(name: 'Changed')}
                : null,
            keepSound: scenario != 'missingSound',
            keepRetention: scenario != 'missingRetention');
        expect(
            result.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] == event.identity.value),
            isEmpty);
      });
    }
    test('a caller subset retains full source contact and arrival guards', () {
      final event = analysis.eventAt(7, 2)!;
      final result = project(
          selected: SourceEventAnalysis(
              profile: analysis.profile, events: [event], diagnostics: []));
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value),
          hasLength(1));
    });
    test('unknown native actor cannot produce a route-capable context',
        () async {
      final changed = {
        7: maps[7]!.copyWith(entities: [
          MapEntity(
              id: 'unknown',
              name: 'Unknown',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 1, y: 1),
              size: const GridSize(width: 1, height: 1),
              npc: const MapEntityNpcData(
                  characterId: 'unknown', displayName: 'Unknown'))
        ])
      };
      final refused = await const SourceEventExecutionContextResolver()
          .readTransfers(
              source: source,
              base: _base(source, changed),
              nativeMaps: changed,
              files: files,
              programs: const {},
              stairPrograms: programs,
              analysis: analysis);
      expect(
          refused.values.every((context) => context.refusals
              .contains('sourceForcedRouteActorSetUnsupported')),
          true);
    });
    test(
        'selective Border replay preserves all maps global resources and materialization',
        () async {
      final atlas = image.Image(width: 256, height: 64, numChannels: 4);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          atlas.setPixelRgba(x, y, 31, 41, 59, 255);
        }
      }
      for (var y = 48; y < 64; y++) {
        for (var x = 0; x < 32; x++) {
          atlas.setPixelRgba(x, y, 73, x, y, 255);
        }
      }
      final archive = source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
      final fixture = await LiteralTileFixture.create(
          includeEventSystem: true,
          scriptsBytes: await files.read(archive.fileId),
          extraFiles: {
            'PBS/metadata.txt':
                utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
            'Graphics/Characters/OriginalPlayer.png': image
                .encodePng(image.Image(width: 128, height: 192, numChannels: 4))
          },
          maps: [
            for (final id in [98, 99, 100])
              LiteralFixtureMap(id: id, width: 5, height: 5, layers: [
                List.filled(25, 384),
                [
                  for (var index = 0; index < 25; index++)
                    if (id != 100 && index == 12) 392 else 0
                ],
                List.filled(25, 0)
              ])
          ],
          tilesets: [
            LiteralFixtureTileset(
                id: 1,
                png: image.encodePng(atlas),
                passages: const {392: 7},
                terrainTags: const {392: 1})
          ]);
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [98, 99, 100],
          projectName: 'Scoped Border replay',
          parentPath: Directory.systemTemp.path,
          folderName: 'scoped-border-replay');
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: fixture.source, base: literal, files: fixture.files))!;
      final untouched = semantic.mutations
          .singleWhere((mutation) =>
              mutation.actionId == 'map.save' &&
              (mutation.parameters['map'] as Map)['id'] == semantic.mapIds[100])
          .parameters['map'];
      final events = (await const SourceEventStudyComposer().compose(
          source: fixture.source, base: semantic, files: fixture.files))!;
      expect(events.projection.nativeMaps.keys.toSet(), {98, 99, 100});
      expect(canonicalJsonOf(events.projection.nativeMaps[100]!.toJson()),
          canonicalJsonOf(untouched));
      for (final id in [98, 99]) {
        final border = events.projection.nativeMaps[id]!.layers
            .whereType<BorderLayer>()
            .single;
        expect(border.content.features.single.materialization!.placements,
            hasLength(1));
      }
      expect(
          events.draft.mutations.where(
              (mutation) => mutation.actionId == 'border.blueprint.publish'),
          isNotEmpty);
      expect(
          events.draft.mutations.where((mutation) =>
              mutation.actionId == 'border_layer.materialize_apply'),
          hasLength(2));
    });
    test('raw509 disagreement quarantines the complete program', () async {
      final changed = await _variant(source, files, 'Data/Map007.rxdata',
          (document, bytes) {
        final page = _page(document, 2, 0);
        final list = _field(document, page, '@list');
        final copy = document.node(list.elements[2]);
        final parameters = _field(document, copy, '@parameters');
        final step = document.node(parameters.elements.single);
        return _integer(bytes, _field(document, step, '@code'), 38);
      });
      final fresh = SourceEventAnalyzer.forProject(changed.source,
              profile: SourceEventProfile.kantoForProject(changed.source))
          .analyze();
      final event = fresh.eventAt(7, 2)!;
      expect(event.isQuarantined, true);
      expect(
          sourceStairPrograms(source: changed.source, analysis: fresh)
              .containsKey(event.identity),
          false);
      expect(
          programs[event.identity]!
              .isBoundTo(source: changed.source, analysis: fresh, event: event),
          false);
    });
  },
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);

  for (final journey in [
    (name: 'same-map', maps: {7}, events: [(7, 2), (7, 3)]),
    (name: 'two-map return', maps: {86, 87}, events: [(86, 3), (87, 1)]),
  ]) {
    test(
        'actual ${journey.name} stairs survive composer writer and strict reopen',
        () async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: journey.maps, supplementalRoots: supplemental);
      final source = fixture.source;
      final temporary = await Directory.systemTemp.createTemp('stair-writer-');
      addTearDown(() => temporary.delete(recursive: true));
      const limits = NativeWriteLimits(maxArtifacts: 96);
      Future<LiteralTileComposition> literal(
              List<LiteralDependencyDecision> decisions) =>
          const LiteralTileComposer().compose(
              source: source,
              files: fixture.files,
              selectedSourceMapIds: journey.maps.toList()..sort(),
              projectName: 'Complete stairs',
              parentPath: temporary.path,
              folderName: 'stairs',
              dependencyDecisions: decisions,
              limits: limits);
      final probe = await literal([]);
      final composed = await literal([
        for (final dependency in probe.dependencies)
          if (!journey.maps.contains(dependency.targetSourceMapId))
            LiteralDependencyDecision(
                sourceSnapshotHash: source.snapshot.canonicalHash,
                selectionHash: probe.selectionHash,
                locator: dependency.locator,
                targetSourceMapId: dependency.targetSourceMapId,
                decision: LiteralDependencyDisposition.excludeStudy)
      ]);
      expect(composed.draft, isNotNull,
          reason: composed.diagnostics.toString());
      final semantic = await const SourceSemanticStudyComposer().compose(
          source: source, base: composed, files: fixture.files, limits: limits);
      final events = await const SourceEventStudyComposer().compose(
          source: source,
          base: semantic!,
          files: fixture.files,
          limits: limits);
      expect(events, isNotNull);
      final parsed = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      for (final pair in journey.events) {
        final event = parsed.eventAt(pair.$1, pair.$2)!;
        final identity = event.identity.value;
        final evidence = (events!.projection.semanticEvidence['events'] as List)
            .cast<Map>()
            .singleWhere((row) => row['sourceIdentity'] == identity);
        expect(
            events.projection.scenes.where(
                (scene) => scene.metadata['sourceEventIdentity'] == identity),
            hasLength(1),
            reason: evidence.toString());
        final scene = events.projection.scenes.singleWhere(
            (scene) => scene.metadata['sourceEventIdentity'] == identity);
        final commands = scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((action) => action.interactiveCommand)
            .whereType<SceneInteractiveCommand>()
            .map((command) => command.toJson())
            .toList();
        final restore = commands
            .where((command) => command['kind'] == 'actorRoute')
            .singleWhere((route) => (route['steps'] as List).length == 2);
        final warp = event.pages.single.body.nodes
                .whereType<SourceWarpNode>()
                .singleOrNull ??
            (event.pages.single.body.nodes.single as SourceConditionalNode)
                .whenTrue
                .nodes
                .whereType<SourceWarpNode>()
                .single;
        expect((restore['target'] as Map)['mapId'],
            events.draft.mapIds[warp.targetSourceMapId]);
      }
      final approval = approveNativeFixtureDraft(events!.draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, events.draft, limits: limits);
      expect(receipt.verified, true);
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
        expect(loaded.manifest.eventRegistry!.records, isNotEmpty);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: root == null || snapshot == null
            ? 'External source witness paths required'
            : false);
  }
}
