import 'dart:io';

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
    value == 0 ? 0 : value + 5,
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
  group('source typed static door context', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceStaticDoorProgram> programs;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late SourceEventDefinition door;
    late SourceEventSoundBinding sound;
    late MapInstanceRetentionPolicy retention;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {6, 7}, supplementalRoots: supplementalRoots);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      maps = _maps(source);
      door = analysis.eventAt(7, 1)!;
      programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
      contexts = await const SourceEventExecutionContextResolver()
          .readStaticTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: files,
              programs: programs,
              analysis: analysis);
      sound = await const SourceEventSoundResolver()
          .read(source: source, files: files, name: 'Exit Door');
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
    });

    SourceEventProjection project(
            {Map<int, MapData>? nativeMaps,
            Map<String, SourceEventSoundBinding>? sounds,
            bool keepRetention = true,
            Map<ConverterId, SourceEventExecutionContext>?
                executionContexts}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: nativeMaps ?? maps,
            staticDoorPrograms: programs,
            staticDoorContexts: executionContexts ?? contexts,
            soundBindings: sounds ?? {'Exit Door': sound},
            retentionPolicy: keepRetention ? retention : null);

    test('actual nonpinned Map7 exit has a local exact context and scene', () {
      final context = contexts[door.identity]!;
      expect(context.isQualified, isTrue, reason: context.refusals.toString());
      expect(context.staticDoorIdentity, door.identity);
      expect(context.supportsRouteBarrierOnSourceMap(7), isFalse);
      final proof = context.toJson()['proof'] as Map;
      expect((proof['sourceMapExecutionScope'] as Map)['attestedSourceMapIds'],
          [6, 7, 71, 135, 137]);
      expect(
          (proof['mapAutonomyAudit'] as Map)['ambientMovementParityQualified'],
          false);
      final result = project();
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == door.identity.value);
      expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
      final scenes = result.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] == door.identity.value)
          .toList();
      expect(scenes, hasLength(1));
      final commands = scenes.single.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((action) => action.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .map((command) => command.toJson())
          .toList();
      expect(commands.where((command) => command['kind'] == 'actorRoute'),
          isEmpty);
      expect(
          commands.where((command) => command['kind'] == 'waitForActorRoutes'),
          isEmpty);
      expect(result.allEnabledOriginalEventsHaveExecutionContext, isTrue);
    });

    for (final scenario in [
      'missingContext',
      'changedMap',
      'missingSound',
      'missingRetention',
      'blockedArrival'
    ]) {
      test('$scenario leaves the whole nonpinned door inactive', () {
        final changed = {...maps};
        if (scenario == 'changedMap') {
          changed[7] = maps[7]!.copyWith(name: 'Changed');
        }
        if (scenario == 'blockedArrival') {
          final target = maps[6]!;
          final cells =
              List<bool>.filled(target.size.width * target.size.height, false);
          cells[7 * target.size.width + 12] = true;
          changed[6] = target.copyWith(layers: [
            MapLayer.collision(
                id: 'blocked', name: 'Blocked arrival', collisions: cells)
          ]);
        }
        final result = project(
            nativeMaps: changed,
            sounds: scenario == 'missingSound' ? {} : null,
            keepRetention: scenario != 'missingRetention',
            executionContexts: scenario == 'missingContext' ? {} : null);
        expect(
            result.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] == door.identity.value),
            isEmpty);
      });
    }

    for (final scenario in [
      'parallel',
      'autonomyScript',
      'automaticCommonEvent',
      'compiledPlugin'
    ]) {
      test('freshly reattested $scenario cannot borrow a static context',
          () async {
        final path = scenario == 'automaticCommonEvent'
            ? 'Data/CommonEvents.rxdata'
            : scenario == 'compiledPlugin'
                ? 'Data/PluginScripts.rxdata'
                : 'Data/Map006.rxdata';
        final changed = await _variant(source, files, path, (document, bytes) {
          if (scenario == 'parallel') {
            return _integer(
                bytes, _field(document, _page(document, 15, 0), '@trigger'), 4);
          }
          if (scenario == 'autonomyScript') {
            final event = analysis.events.firstWhere((event) =>
                event.sourceMapId == 6 &&
                event.pages.any((page) => page.graphic?.moveType == 3));
            final page =
                event.pages.firstWhere((page) => page.graphic?.moveType == 3);
            final route = document.node(page.graphic!.moveRouteNodeId);
            final first =
                document.node(_field(document, route, '@list').elements.first);
            return _integer(bytes, _field(document, first, '@code'), 45);
          }
          if (scenario == 'automaticCommonEvent') {
            final record = document.node(document
                .node(document.rootId)
                .elements
                .firstWhere(
                    (id) => document.node(id).kind == MarshalKind.object));
            return _integer(bytes, _field(document, record, '@trigger'), 1);
          }
          return [...bytes.take(bytes.length - 1), bytes.last ^ 1];
        });
        final parsed = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        final staticPrograms =
            sourceStaticDoorPrograms(source: changed.source, analysis: parsed);
        final nativeMaps = _maps(changed.source);
        final contexts = await const SourceEventExecutionContextResolver()
            .readStaticTransfers(
                source: changed.source,
                base: _base(changed.source, nativeMaps),
                nativeMaps: nativeMaps,
                files: changed.files,
                programs: staticPrograms,
                analysis: parsed);
        final context = contexts[parsed.eventAt(7, 1)!.identity]!;
        expect(context.isQualified, false);
        expect(
            context.refusals,
            contains(switch (scenario) {
              'parallel' => 'sourceParallelEventUnsupported',
              'autonomyScript' => 'sourceMapAutonomyContextUnsupported',
              'automaticCommonEvent' => 'sourceAutomaticCommonEventUnsupported',
              _ => 'sourcePluginRouteContextUnsupported',
            }));
      });
    }

    for (final forgery in ['omitted actor', 'altered actor graphic']) {
      test('caller analysis cannot hide unsafe autonomy through $forgery',
          () async {
        final unsafeActor = analysis.events.firstWhere((event) =>
            event.sourceMapId == 6 &&
            event.pages.any((page) => page.graphic?.moveType == 3));
        final unsafePage =
            unsafeActor.pages.firstWhere((page) => page.graphic?.moveType == 3);
        final changed = await _variant(source, files, 'Data/Map006.rxdata',
            (document, bytes) {
          final route = document.node(unsafePage.graphic!.moveRouteNodeId);
          final step =
              document.node(_field(document, route, '@list').elements.first);
          return _integer(bytes, _field(document, step, '@code'), 45);
        });
        final actual = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        final exactDoor = actual.eventAt(7, 1)!;
        final safeGraphic = actual.events
            .where((event) => event.sourceMapId == 6)
            .expand((event) => event.pages)
            .firstWhere((page) => page.graphic?.moveType == 0)
            .graphic!;
        final alteredActor =
            actual.eventAt(unsafeActor.sourceMapId, unsafeActor.sourceEventId)!;
        final forgedActor = SourceEventDefinition(
            sourceMapId: alteredActor.sourceMapId,
            sourceEventId: alteredActor.sourceEventId,
            sourceFileId: alteredActor.sourceFileId,
            identity: alteredActor.identity,
            name: alteredActor.name,
            x: alteredActor.x,
            y: alteredActor.y,
            locator: alteredActor.locator,
            pages: [
              for (final page in alteredActor.pages)
                if (page.originalPageIndex != unsafePage.originalPageIndex)
                  page
                else
                  SourceEventPageAnalysis(
                      sourcePage: page.sourcePage,
                      locator: page.locator,
                      condition: page.condition,
                      graphic: safeGraphic,
                      body: page.body,
                      rawDataRef: page.rawDataRef,
                      diagnostics: page.diagnostics)
            ]);
        final forged = SourceEventAnalysis(
            profile: actual.profile,
            diagnostics: [],
            events: forgery == 'omitted actor'
                ? [exactDoor]
                : [
                    for (final event in actual.events)
                      if (event.identity == alteredActor.identity)
                        forgedActor
                      else
                        event,
                  ]);
        final forgedPrograms =
            sourceStaticDoorPrograms(source: changed.source, analysis: forged);
        expect(forgedPrograms[exactDoor.identity], isNotNull);
        final nativeMaps = _maps(changed.source);
        final base = _base(changed.source, nativeMaps);
        final contexts = await const SourceEventExecutionContextResolver()
            .readStaticTransfers(
                source: changed.source,
                base: base,
                nativeMaps: nativeMaps,
                files: changed.files,
                programs: forgedPrograms,
                analysis: forged);
        final context = contexts[exactDoor.identity]!;
        expect(context.isQualified, false, reason: context.refusals.toString());
        expect(
            context.refusals, contains('sourceMapAutonomyContextUnsupported'));
        final single = await const SourceEventExecutionContextResolver().read(
            source: changed.source,
            base: base,
            nativeMaps: nativeMaps,
            files: changed.files,
            staticDoorProgram: forgedPrograms[exactDoor.identity],
            staticDoorAnalysis: forged);
        expect(single.isQualified, false, reason: single.refusals.toString());
        expect(
            single.refusals, contains('sourceMapAutonomyContextUnsupported'));
        final withoutCallerAnalysis =
            await const SourceEventExecutionContextResolver().read(
                source: changed.source,
                base: base,
                nativeMaps: nativeMaps,
                files: changed.files,
                staticDoorProgram: forgedPrograms[exactDoor.identity]);
        expect(withoutCallerAnalysis.isQualified, false);
        expect(withoutCallerAnalysis.refusals,
            contains('sourceMapAutonomyContextUnsupported'));
      });
    }

    test('changed source witness bytes refuse before context admission',
        () async {
      final entry = source.snapshot.entries.singleWhere(
          (entry) => entry.relativePath == 'Data/PluginScripts.rxdata');
      final bytes = await files.read(entry.fileId);
      await expectLater(
          const SourceEventExecutionContextResolver().readStaticTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: _ChangedFiles(files, entry.fileId,
                  [...bytes.take(bytes.length - 1), bytes.last ^ 1]),
              programs: programs,
              analysis: analysis),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.execution.witness.changed')));
    });

    for (final field in ['opacity', 'alwaysOnTop']) {
      test('empty source graphic $field is inert for static door projection',
          () async {
        final changed = await _variant(source, files, 'Data/Map007.rxdata',
            (document, bytes) {
          final page = _page(document, 1, 0);
          if (field == 'opacity') {
            final graphic = _field(document, page, '@graphic');
            return _integer(bytes, _field(document, graphic, '@opacity'), 0);
          }
          final node = _field(document, page, '@always_on_top');
          expect(node.kind, MarshalKind.boolean);
          final result = List<int>.of(bytes);
          result[node.location.byteOffset] = 0x54;
          return result;
        });
        final parsed = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        final staticPrograms =
            sourceStaticDoorPrograms(source: changed.source, analysis: parsed);
        final nativeMaps = _maps(changed.source);
        final contexts = await const SourceEventExecutionContextResolver()
            .readStaticTransfers(
                source: changed.source,
                base: _base(changed.source, nativeMaps),
                nativeMaps: nativeMaps,
                files: changed.files,
                programs: staticPrograms,
                analysis: parsed);
        final effect = await const SourceEventSoundResolver().read(
            source: changed.source, files: changed.files, name: 'Exit Door');
        final projected = const SourceEventProjector().project(
            source: changed.source,
            analysis: parsed,
            nativeMaps: nativeMaps,
            staticDoorPrograms: staticPrograms,
            staticDoorContexts: contexts,
            soundBindings: {'Exit Door': effect},
            retentionPolicy: retention);
        expect(
            projected.scenes.any((scene) =>
                scene.metadata['sourceEventIdentity'] == door.identity.value),
            true);
      });
    }

    test('actual static door survives composer, disk writer and strict reopen',
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
              selectedSourceMapIds: [6, 7],
              projectName: 'Static door source',
              parentPath: temporary.path,
              folderName: 'static-door-source',
              dependencyDecisions: decisions,
              limits: limits);
      final probe = await literal([]);
      final decisions = [
        for (final dependency in probe.dependencies)
          if (!const {6, 7}.contains(dependency.targetSourceMapId))
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
        final native = loaded.mapById(events.draft.mapIds[7]!)!;
        expect(native.triggers, isNotEmpty);
        expect(
            loaded.manifest.eventRegistry!.records.any((record) =>
                record.definitionOrNull?.sceneId ==
                events.projection.scenes
                    .singleWhere((scene) =>
                        scene.metadata['sourceEventIdentity'] ==
                        door.identity.value)
                    .id),
            isTrue);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: root == null || snapshot == null || !Platform.isMacOS);
}
