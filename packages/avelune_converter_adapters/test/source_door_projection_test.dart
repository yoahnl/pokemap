import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:map_core/map_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

final class _FrozenFiles implements SourceFilePort {
  _FrozenFiles(this.bytes);
  final Map<ConverterId, List<int>> bytes;
  @override
  Future<List<int>> read(ConverterId id) async => List.of(bytes[id]!);
}

final class _OriginalFiles implements SourceFilePort {
  _OriginalFiles(this.source, this.root);
  final NormalizedSourceProject source;
  final String root;
  @override
  Future<List<int>> read(ConverterId id) => File(
          '$root/${source.snapshot.entries.singleWhere((entry) => entry.fileId == id).relativePath}')
      .readAsBytes();
}

final class _OverlayFiles implements SourceFilePort {
  _OverlayFiles(this.delegate, this.overrides);
  final SourceFilePort delegate;
  final Map<ConverterId, List<int>> overrides;
  @override
  Future<List<int>> read(ConverterId id) async =>
      overrides.containsKey(id) ? List.of(overrides[id]!) : delegate.read(id);
}

Future<(NormalizedSourceProject, SourceFilePort)> _withSourceFile(
    NormalizedSourceProject source,
    String root,
    String path,
    List<int> bytes) async {
  final snapshot = source.snapshot;
  final id = snapshot.entries
          .where((entry) => entry.relativePath == path)
          .firstOrNull
          ?.fileId ??
      ConverterId('unimported-extra-file');
  final withExtra = SourceSnapshot(
      logicalProjectNamespace: snapshot.logicalProjectNamespace,
      policyHash: snapshot.policyHash,
      entries: [
        ...snapshot.entries.where((entry) => entry.fileId != id),
        SourceFileEntry(
            fileId: id,
            relativePath: path,
            kind: SourceNodeKind.file,
            byteLength: bytes.length,
            sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
            format: 'ruby-marshal',
            family: 'unknown')
      ],
      diagnostics: snapshot.diagnostics,
      excludedPaths: snapshot.excludedPaths,
      profileEvidence: snapshot.profileEvidence,
      state: snapshot.state);
  final files = _OverlayFiles(_OriginalFiles(source, root), {id: bytes});
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: withExtra,
      files: files,
      selectedMapIds: source.selectedSourceMapIds.toSet(),
      includeEventSystem: true,
      includeConnections: true);
  return (normalized, files);
}

Future<NormalizedSourceProject> _original(String folder) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final snapshot = SourceSnapshot(
    logicalProjectNamespace:
        ConverterId(input['logicalProjectNamespace'] as String),
    policyHash: Sha256Hash(input['policyHash'] as String),
    entries: [
      for (final dynamic row in input['entries'])
        SourceFileEntry(
          fileId: ConverterId(row['fileId'] as String),
          relativePath: row['relativePath'] as String,
          kind: SourceNodeKind.values.byName(row['kind'] as String),
          byteLength: row['byteLength'] as int,
          sha256: row['sha256'] == null
              ? null
              : Sha256Hash(row['sha256'] as String),
          format: row['format'] as String,
          family: row['family'] as String,
        )
    ],
    diagnostics: [],
    excludedPaths: (input['excludedPaths'] as List).cast<String>(),
    profileEvidence: [
      for (final dynamic row in input['profileEvidence'])
        SourceProfileEvidence(
          relativePath: row['relativePath'] as String,
          fileHash: Sha256Hash(row['fileHash'] as String),
          version: row['version'] as String,
          line: row['line'] as int,
          excerpt: row['excerpt'] as String,
        )
    ],
    state: SourceScanState.values.byName(input['state'] as String),
  );
  expect(snapshot.canonicalHash.value, input['canonicalHash']);
  final files = _FrozenFiles({
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  });
  final source = await const RmxpSourceNormalizer().normalize(
    snapshot: snapshot,
    files: files,
    selectedMapIds:
        (frozen['selectedSourceMapIds'] as List).cast<int>().toSet(),
    includeEventSystem: true,
    includeConnections: true,
  );
  expect(source.archive.canonicalHash.value, frozen['archiveHash']);
  final hashInput = Map<String, dynamic>.from(frozen)..remove('archive');
  expect(
      source.canonicalHash,
      canonicalHashOf(hashInput,
          limits: const ContractLimits(
              maxNodes: 40000000,
              maxStringCodeUnits: 1048576,
              maxTextCodeUnits: 134217728)));
  return source;
}

SourceEventProjection _project(
    NormalizedSourceProject source,
    Map<String, SourceEventSoundBinding> sounds,
    MapInstanceRetentionPolicy? policy,
    {SourceEventAnalysis? analysis,
    bool includeSolidTerrain = true,
    SourceEventExecutionContext? executionContext}) {
  final graphic = source.snapshot.entries.singleWhere((entry) =>
      entry.relativePath == 'Graphics/Characters/OBJ_FRLG_Doors3.png');
  return const SourceEventProjector().project(
    source: source,
    analysis: analysis ??
        SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.kantoForProject(source))
            .analyze(),
    nativeMaps: _maps(source, includeSolidTerrain: includeSolidTerrain),
    soundBindings: sounds,
    retentionPolicy: policy,
    executionContext: executionContext,
    characterBindings: {
      sourceEventCharacterBindingKey(
              characterName: 'OBJ_FRLG_Doors3', pattern: 3, direction: 2):
          SourceEventCharacterBinding(
              characterId: 'door_character',
              sourceSnapshotHash: source.snapshot.canonicalHash,
              sourceFileId: graphic.fileId,
              sourceFileHash: graphic.sha256!,
              sourcePattern: 3,
              sourceDirection: 2),
    },
  );
}

Map<int, MapData> _maps(NormalizedSourceProject source,
    {bool includeSolidTerrain = true}) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'source_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: [
            if (includeSolidTerrain)
              MapLayer.collision(
                  id: 'source_collision_${ir.map.sourceMapId}',
                  name: 'Source collision',
                  collisions: SourceCollisionProjection.resolve(
                          cells: [
                        for (var y = 0; y < ir.map.height; y++)
                          for (var x = 0; x < ir.map.width; x++)
                            resolver.cellAt(ir.map.sourceMapId, x, y)
                      ],
                          resolver: resolver,
                          mapSize: GridSize(
                              width: ir.map.width, height: ir.map.height))
                      .fullyBlockedCells)
          ])
  };
}

NativeProjectDraft _freshBase(
        NormalizedSourceProject source, Map<int, MapData> maps,
        {List<NativeMutation> extraMutations = const [],
        Map<String, Object?> extraEvidence = const {}}) =>
    NativeProjectDraft(
        source: source,
        projectName: 'Original door context',
        parentPath: '/private/tmp',
        folderName: 'Original door context',
        mapIds: {
          for (final entry in maps.entries) entry.key: entry.value.id
        },
        artifacts: [],
        mutations: [
          for (final entry in maps.entries) ...[
            NativeMutation(
                operationId: ConverterId('create-${entry.value.id}'),
                actionId: 'map.create',
                sourceEntityIds: [
                  source.mapIdentity(entry.key)
                ],
                targetEntityIds: [
                  ConverterId(entry.value.id)
                ],
                parameters: {
                  'mapId': entry.value.id,
                  'name': entry.value.name,
                  'width': entry.value.size.width,
                  'height': entry.value.size.height
                }),
            NativeMutation(
                operationId: ConverterId('save-${entry.value.id}'),
                actionId: 'map.save',
                sourceEntityIds: [source.mapIdentity(entry.key)],
                targetEntityIds: [ConverterId(entry.value.id)],
                parameters: {'map': entry.value.toJson()})
          ],
          ...extraMutations
        ],
        compositionEvidence: {
          'kind': 'literalTileComposition',
          'version': 2,
          'compositionHash':
              canonicalHashOf({'kind': 'freshContextFixture'}).value,
          'composition': {'kind': 'freshContextFixture'},
          'sourceSemantics': {},
          ...extraEvidence,
        });

Future<SourceEventStudyComposition> _composeOriginal(
    NormalizedSourceProject source,
    SourceFilePort files,
    List<int> selected,
    NativeWriteLimits limits) async {
  var literal = await const LiteralTileComposer().compose(
      source: source,
      files: files,
      selectedSourceMapIds: selected,
      projectName: 'Original source qualification',
      parentPath: '/private/tmp',
      folderName: 'unused-original-source',
      allowFirstFrameAutotiles: true,
      limits: limits);
  final decisions = <LiteralDependencyDecision>[];
  for (final dependency in literal.dependencies) {
    final target = dependency.targetSourceMapId;
    if (dependency.kind == LiteralDependencyKind.staticTransfer &&
        target != null &&
        !selected.contains(target)) {
      decisions.add(LiteralDependencyDecision(
          sourceSnapshotHash: source.snapshot.canonicalHash,
          selectionHash: literalSelectionHash(source, selected),
          locator: dependency.locator,
          targetSourceMapId: target,
          decision: LiteralDependencyDisposition.excludeStudy));
    }
  }
  if (decisions.isNotEmpty) {
    literal = await const LiteralTileComposer().compose(
        source: source,
        files: files,
        selectedSourceMapIds: selected,
        projectName: 'Original source qualification',
        parentPath: '/private/tmp',
        folderName: 'unused-original-source',
        allowFirstFrameAutotiles: true,
        dependencyDecisions: decisions,
        limits: limits);
  }
  final semantic = await const SourceSemanticStudyComposer()
      .compose(source: source, base: literal, files: files, limits: limits);
  expect(semantic, isNotNull);
  return (await const SourceEventStudyComposer()
      .compose(source: source, base: semantic!, files: files, limits: limits))!;
}

SourceEventGraphic _graphicLike(SourceEventGraphic value,
        {int? tileId, int? moveType, String? characterName, bool? through}) =>
    SourceEventGraphic(
        tileId: tileId ?? value.tileId,
        characterName: characterName ?? value.characterName,
        hue: value.hue,
        direction: value.direction,
        pattern: value.pattern,
        opacity: value.opacity,
        blendType: value.blendType,
        moveType: moveType ?? value.moveType,
        moveSpeed: value.moveSpeed,
        moveFrequency: value.moveFrequency,
        walkAnime: value.walkAnime,
        stepAnime: value.stepAnime,
        directionFix: value.directionFix,
        through: through ?? value.through,
        alwaysOnTop: value.alwaysOnTop,
        moveRouteNodeId: value.moveRouteNodeId);

SourceEventPageAnalysis _pageLike(SourceEventPageAnalysis value,
        {SourceEventGraphic? graphic,
        SourceEventCondition? condition,
        SourceEventBlock? body,
        bool missingGraphic = false}) =>
    SourceEventPageAnalysis(
        sourcePage: value.sourcePage,
        locator: value.locator,
        condition: condition ?? value.condition,
        graphic: missingGraphic ? null : graphic ?? value.graphic,
        body: body ?? value.body,
        rawDataRef: value.rawDataRef,
        diagnostics: value.diagnostics);

SourceEventDefinition _eventLike(SourceEventDefinition value,
        {String? name, int? x, int? y, List<SourceEventPageAnalysis>? pages}) =>
    SourceEventDefinition(
        sourceMapId: value.sourceMapId,
        sourceEventId: value.sourceEventId,
        sourceFileId: value.sourceFileId,
        identity: value.identity,
        name: name ?? value.name,
        x: x ?? value.x,
        y: y ?? value.y,
        locator: value.locator,
        pages: pages ?? value.pages);

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original source door v5', () {
    late NormalizedSourceProject source;
    late Map<String, SourceEventSoundBinding> sounds;
    late MapInstanceRetentionPolicy policy;
    late SourceEventExecutionContext context;
    setUpAll(() async {
      source = await _original(archive!);
      sounds = {
        for (final name in ['frlg_pcdoor', 'Exit Door'])
          name: await const SourceEventSoundResolver().read(
              source: source, files: _OriginalFiles(source, root!), name: name)
      };
      policy = await sourceEventMapRetentionPolicy(
          source: source,
          files: _OriginalFiles(source, root!),
          nativeMapIds: {
            for (final map in source.maps)
              map.map.sourceMapId: 'source_${map.map.sourceMapId}'
          });
      final maps = _maps(source);
      context = await const SourceEventExecutionContextResolver().read(
          source: source,
          base: _freshBase(source, maps),
          nativeMaps: maps,
          files: _OriginalFiles(source, root));
    });

    test('profile is a new exact-hash contract with at-foot timing oracle', () {
      final profile = SourceEventProfile.kantoForProject(source);
      expect(profile.toJson()['profile'], 'kanto-events-static-v5');
      final timing = profile.toJson()['doorTiming'] as Map;
      expect(timing['playerStepMs'], 250);
      expect(timing['movementContext'], 'atFoot');
      expect(timing['faceSemantics'], 'routePassYield');
      expect(timing['globalRouteBarrierScope'],
          'allRepresentedForcedRoutesOnTheActiveNativeMap');
      expect(timing['sourceExecutionContext'],
          'freshNativeProjectWithoutImportedSourceFollowers');
      expect((profile.toJson()['oracleSections'] as Map).keys,
          containsAll(['032', '043', '046']));
    });

    test(
        'fresh context is derived from a new native draft and sealed witnesses',
        () async {
      final maps = _maps(source);
      final base = _freshBase(source, maps);
      final context = await const SourceEventExecutionContextResolver().read(
          source: source,
          base: base,
          nativeMaps: maps,
          files: _OriginalFiles(source, root!));
      expect(context.isQualified, isTrue);
      final json = context.toJson();
      expect(json['baseDraftHash'], base.canonicalHash.value);
      expect((json['proof'] as Map)['origin'], 'freshNativeProject');
      expect((json['proof'] as Map)['sourceCheckpoint'], 'notImported');
      expect((json['proof'] as Map)['followers'], 'newGameDeclaredEmpty');
      expect(
          context.isBoundTo(
              source, SourceEventProfile.kantoForProject(source), maps),
          isTrue);
      expect(
          context.isBoundTo(source, SourceEventProfile.kantoForProject(source),
              {100: maps[100]!}),
          isFalse);
      final altered = {
        ...maps,
        100: maps[100]!.copyWith(name: 'Other map state')
      };
      expect(
          context.isBoundTo(
              source, SourceEventProfile.kantoForProject(source), altered),
          isFalse);
      (json['proof'] as Map)['origin'] = 'forged';
      expect(
          (context.toJson()['proof'] as Map)['origin'], 'freshNativeProject');
    });

    for (final state in ['present', 'unknown']) {
      test('fresh context refuses a declared source checkpoint $state',
          () async {
        final maps = _maps(source);
        final context = await const SourceEventExecutionContextResolver().read(
            source: source,
            base: _freshBase(source, maps, extraEvidence: {
              'sourceCheckpoint': {'state': state}
            }),
            nativeMaps: maps,
            files: _OriginalFiles(source, root!));
        expect(context.isQualified, isFalse);
        expect(context.refusals, contains('sourceCheckpointImportUnsupported'));
      });
    }

    test('source save files do not become imported checkpoints', () async {
      final (variant, files) =
          await _withSourceFile(source, root!, 'Save001.rxdata', [4, 8, 48, 0]);
      final maps = _maps(variant);
      final fresh = await const SourceEventExecutionContextResolver().read(
          source: variant,
          base: _freshBase(variant, maps),
          nativeMaps: maps,
          files: files);
      expect(fresh.isQualified, isTrue, reason: fresh.refusals.toString());
      expect(
          (fresh.toJson()['proof'] as Map)['sourceCheckpoint'], 'notImported');
    });

    test('a changed plugin witness cannot create an execution proof', () async {
      final maps = _maps(source);
      final plugin = source.snapshot.entries.singleWhere(
          (entry) => entry.relativePath == 'Data/PluginScripts.rxdata');
      await expectLater(
          const SourceEventExecutionContextResolver().read(
              source: source,
              base: _freshBase(source, maps),
              nativeMaps: maps,
              files: _OverlayFiles(_OriginalFiles(source, root!), {
                plugin.fileId: [4, 8, 48, 0]
              })),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.execution.witness.changed')));
    });

    test('an added source plugin cannot hide behind the known compiled archive',
        () async {
      final (variant, files) = await _withSourceFile(
          source,
          root!,
          'Plugins/Unknown route/main.rb',
          utf8.encode('external_forced_route()'));
      final maps = _maps(variant);
      final context = await const SourceEventExecutionContextResolver().read(
          source: variant,
          base: _freshBase(variant, maps),
          nativeMaps: maps,
          files: files);
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourcePluginInventoryUnsupported'));
    });

    test('fresh context refuses runtime state import operations', () async {
      final maps = _maps(source);
      final context = await const SourceEventExecutionContextResolver().read(
          source: source,
          base: _freshBase(source, maps, extraMutations: [
            NativeMutation(
                operationId: ConverterId('checkpoint-import'),
                actionId: 'game_save.load',
                sourceEntityIds: [source.mapIdentity(100)],
                targetEntityIds: [ConverterId('source_100')],
                parameters: {})
          ]),
          nativeMaps: maps,
          files: _OriginalFiles(source, root!));
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceCheckpointImportUnsupported'));
    });

    for (final evidence in [
      {
        'externalState': {'followers': 'present'}
      },
      {'compositionHash': 'c' * 64},
    ]) {
      test(
          'fresh context refuses unsupported base evidence ${evidence.keys.single}',
          () async {
        final maps = _maps(source);
        final context = await const SourceEventExecutionContextResolver().read(
            source: source,
            base: _freshBase(source, maps, extraEvidence: evidence),
            nativeMaps: maps,
            files: _OriginalFiles(source, root!));
        expect(context.isQualified, isFalse);
        expect(context.refusals, contains('sourceExecutionBaseUnsupported'));
      });
    }

    for (final mapId in [98, 21]) {
      for (final trigger in [4, 0]) {
        test(
            'unprofiled represented or retained map $mapId trigger $trigger refuses doors',
            () async {
          final fixture = await LiteralTileFixture.create(maps: [
            LiteralFixtureMap(id: mapId, events: [
              LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
                LiteralFixtureEventPage(trigger: trigger, commands: [])
              ])
            ])
          ]);
          final path = 'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';
          final (changed, files) = await _withSourceFile(
              source, root!, path, fixture.files.bytes[path]!);
          final maps = _maps(changed);
          final rejected = await const SourceEventExecutionContextResolver()
              .read(
                  source: changed,
                  base: _freshBase(changed, maps),
                  nativeMaps: maps,
                  files: files);
          expect(rejected.isQualified, isFalse);
          expect(
              rejected.refusals,
              contains(trigger == 4
                  ? 'sourceParallelEventUnsupported'
                  : 'sourceExecutionWitnessUnqualified'));
          final projection =
              _project(changed, sounds, policy, executionContext: rejected);
          expect(
              projection.scenes.where((scene) =>
                  scene.name.startsWith('Center door /') ||
                  scene.name.startsWith('Exit /')),
              isEmpty);
        });
      }
    }

    test(
        'fresh context attests represented maps and retained source neighbours',
        () {
      final proof = context.toJson()['proof'] as Map;
      expect(proof['sourceMapExecutionScope'], isA<Map>());
      final scope = proof['sourceMapExecutionScope'] as Map;
      expect(scope['activeSourceMapIds'], [98, 100, 102]);
      expect(scope['retainedOnlySourceMapIds'], [21, 83]);
      expect(proof['parallelEvents'], 'noneOnRepresentedMaps');
      final witnesses = (proof['witnesses'] as List).cast<Map>();
      expect(
          witnesses.where((entry) =>
              RegExp(r'^Data/Map(?:021|083|098|100|102)\.rxdata$')
                  .hasMatch(entry['relativePath'] as String)),
          hasLength(5));
      expect(
          witnesses.any(
              (entry) => entry['relativePath'] == 'Data/map_connections.dat'),
          isTrue);
    });

    test('every original 210 emits a native map scoped route barrier', () {
      final result =
          _project(source, sounds, policy, executionContext: context);
      final barriers = result.scenes
          .where((scene) => scene.name.startsWith('Center door /'))
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand?.toJson())
          .whereType<Map<String, dynamic>>()
          .where((json) => json['kind'] == 'waitForActorRoutes')
          .toList();
      expect(barriers, hasLength(6));
      for (final barrier in barriers) {
        expect(barrier.keys, unorderedEquals(['kind', 'mapId']));
        expect(barrier['mapId'], 'source_100');
      }
    });

    for (final scenario in [
      'constant destination',
      'divergent branches',
      'old actor owner',
      'choice cancel fallthrough',
      'text choice cancel fallthrough',
      'choice cancel transfer'
    ]) {
      test('route barrier map scope handles $scenario after transfer', () {
        final analysis = SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.kantoForProject(source))
            .analyze();
        final door = analysis.eventAt(100, 8)!;
        final page = door.pages.first;
        final warp = page.body.nodes.whereType<SourceWarpNode>().single;
        final barrier =
            page.body.nodes.whereType<SourceMoveRouteBarrierNode>().first;
        final route =
            page.body.nodes.whereType<SourceForcedMoveRouteNode>().first;
        final conditional = door.pages.last.body.nodes
            .whereType<SourceConditionalNode>()
            .single;
        final choice = SourceChoiceNode(page.body.span,
            branches: [
              SourceChoiceBranch(0, 'Continue',
                  SourceEventBlock(nodes: [warp], span: page.body.span))
            ],
            cancelType: 5,
            cancelBranch: scenario == 'choice cancel transfer'
                ? SourceEventBlock(nodes: [warp], span: page.body.span)
                : null);
        final nodes = <SourceEventNode>[
          if (scenario == 'divergent branches')
            SourceConditionalNode(conditional.span,
                condition: conditional.condition,
                whenTrue: SourceEventBlock(nodes: [warp], span: page.body.span),
                whenFalse: SourceEventBlock(nodes: [], span: page.body.span))
          else if (scenario == 'text choice cancel fallthrough')
            SourceTextNode(page.body.span, 'Continue?', followingChoice: choice)
          else if (scenario.startsWith('choice cancel'))
            choice
          else
            warp,
          if (scenario == 'old actor owner') route,
          barrier,
        ];
        final changed = _eventLike(door, pages: [
          _pageLike(page,
              body: SourceEventBlock(nodes: nodes, span: page.body.span)),
          ...door.pages.skip(1)
        ]);
        final result = _project(source, sounds, policy,
            executionContext: context,
            analysis: SourceEventAnalysis(
                profile: analysis.profile,
                diagnostics: analysis.diagnostics,
                events: [
                  for (final event in analysis.events)
                    if (event.identity == door.identity) changed else event
                ]));
        final scenes = result.scenes
            .where((scene) => scene.name.startsWith('Center door /'));
        if (scenario == 'constant destination' ||
            scenario == 'choice cancel transfer') {
          final scene = scenes
              .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
          final command = scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .map((payload) => payload.interactiveCommand?.toJson())
              .whereType<Map<String, dynamic>>()
              .singleWhere((json) => json['kind'] == 'waitForActorRoutes');
          expect(command['mapId'], 'source_102');
        } else {
          expect(scenes, isEmpty);
          expect(jsonEncode(result.semanticEvidence),
              contains('sourceRouteMapScopeUnsupported'));
        }
      });
    }

    test(
        'original door activation requires an operational fresh import context',
        () {
      final result = _project(source, sounds, policy);
      expect(
          result.scenes.where((scene) =>
              scene.name.startsWith('Center door /') ||
              scene.name.startsWith('Exit /')),
          isEmpty);
      expect(jsonEncode(result.semanticEvidence),
          contains('sourceExecutionContextUnknown'));
      expect(result.allEnabledOriginalEventsHaveExecutionContext, isTrue);
    });

    test(
        'both original programs emit all three pages without a global TempA fact',
        () {
      final result =
          _project(source, sounds, policy, executionContext: context);
      final doorScenes = result.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] ==
              SourceEventAnalyzer.forProject(source,
                      profile: SourceEventProfile.kantoForProject(source))
                  .analyze()
                  .eventAt(100, 8)!
                  .identity
                  .value)
          .toList();
      expect(doorScenes, hasLength(2));
      expect(result.scenes.where((scene) => scene.name.startsWith('Exit /')),
          hasLength(1));
      final definitions = result.registry.records
          .map((record) => record.definitionOrNull)
          .whereType<NarrativeEventDefinition>()
          .where((definition) =>
              doorScenes.any((scene) => scene.id == definition.sceneId))
          .toList();
      expect(definitions.map((event) => event.source.kind), [
        NarrativeEventSourceKind.entityBump,
        NarrativeEventSourceKind.entityAutorun
      ]);
      expect(jsonEncode(definitions.first.conditionExpression.toJson()),
          contains('mapEventInstanceBoolean'));
      expect(jsonEncode(definitions.last.conditionExpression.toJson()),
          contains('mapEventInstanceBoolean'));
      expect(
          result.facts.where((fact) => fact.label.contains('temp')), isEmpty);
      expect(result.semanticEvidence['sourceAdmission'], isFalse);
      expect(result.playableCertified, isFalse);
    });

    test(
        'original route timing keeps return closing distinct and yield explicit',
        () {
      final result =
          _project(source, sounds, policy, executionContext: context);
      final actions = result.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .toList();
      final routes =
          actions.whereType<SceneActorRouteInteractiveCommand>().toList();
      expect(routes, hasLength(6));
      expect(
          routes
              .where(
                  (route) => route.target.kind == SceneActorTargetKind.player)
              .expand((route) => route.steps)
              .whereType<SceneActorMoveStep>()
              .map((step) => step.durationMs),
          [250, 250]);
      expect(
          routes
              .expand((route) => route.steps)
              .whereType<SceneActorFaceStep>()
              .every((step) => step.yieldAfter && step.durationMs == 0),
          isTrue);
      final closing = routes
          .where((route) => route.steps
              .whereType<SceneActorFaceStep>()
              .any((step) => step.direction == EntityFacing.south))
          .toList();
      expect(
          closing.map((route) => route.steps.first.kind),
          containsAll(
              [SceneActorRouteStepKind.wait, SceneActorRouteStepKind.face]));
      expect(
          actions
              .whereType<SceneWaitInteractiveCommand>()
              .map((command) => command.durationMs),
          [400, 400]);
    });

    test(
        'warp destinations are inert scene points and return owner is explicit',
        () {
      final result =
          _project(source, sounds, policy, executionContext: context);
      final warps =
          result.nativeMaps.values.expand((map) => map.warps).toList();
      expect(warps, hasLength(2));
      expect(
          warps.every(
              (warp) => warp.triggerMode == MapWarpTriggerMode.sceneOnly),
          isTrue);
      for (final map in result.nativeMaps.values) {
        expect(
            map.warps.every((warp) =>
                warp.targetMapId == map.id && warp.targetPos == warp.pos),
            isTrue);
      }
      final commands = result.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneWarpInteractiveCommand>()
          .toList();
      expect(commands, hasLength(2));
      expect(
          commands.every(
              (command) => command.transition == SceneWarpTransition.none),
          isTrue);
      expect(
          commands
              .singleWhere(
                  (command) => command.destinationMapId == 'source_100')
              .arrivalCollisionOwnerEntityId,
          isNotNull);
      expect(
          commands
              .singleWhere(
                  (command) => command.destinationMapId == 'source_102')
              .arrivalFacing,
          EntityFacing.north);
    });
    test(
        'original blocked exit is a terrain bump source without changing tiles',
        () {
      final resolver = SourceSemanticResolver.forProject(source);
      final raw =
          resolver.resolveConnectionEntryTile(resolver.cellAt(102, 9, 11));
      expect(raw.isPassable, isFalse);
      final result =
          _project(source, sounds, policy, executionContext: context);
      final exit = result.registry.records
          .map((r) => r.definitionOrNull)
          .whereType<NarrativeEventDefinition>()
          .singleWhere((e) => e.name == 'Exit / 1');
      expect(exit.source.kind, NarrativeEventSourceKind.triggerBump);
      final map = result.nativeMaps[102]!;
      final trigger = map.triggers
          .singleWhere((t) => t.id == exit.source.toJson()['triggerId']);
      expect(trigger.area.pos, const GridPos(x: 9, y: 11));
    });

    test('source touch classification preserves d0 through all raised layers',
        () {
      final resolver = SourceSemanticResolver.forProject(source);
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final exit = analysis.eventAt(102, 1)!;
      final originalCell = resolver.cellAt(102, 9, 11);
      for (final passages in [
        [0, 0, 0],
        [1, 2, 12]
      ]) {
        final cell = SourceSemanticCell(
            sourceMapId: 102,
            x: 9,
            y: 11,
            width: originalCell.width,
            height: originalCell.height,
            stack: [
              for (var z = 0; z < 3; z++)
                SourceSemanticTile(
                    sourceZ: z,
                    tileId: 490,
                    passage: passages[z],
                    priority: 1,
                    terrainTag: 0)
            ]);
        if (passages.first == 1) {
          expect(resolver.resolveCell(cell).blockedMask, 15);
        }
        final result = resolver.resolveEventTouch(
            cell: cell,
            event: exit,
            page: exit.pages.single,
            mapEvents: analysis.events);
        expect(result.kind, SourceEventTouchKind.enter);
        expect(result.reason, 'stationaryTilesAllowed');
      }
    });

    test('source terrain contact refuses missing metadata and dynamic contexts',
        () {
      final resolver = SourceSemanticResolver.forProject(source);
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final exit = analysis.eventAt(102, 1)!;
      final cell = resolver.cellAt(102, 9, 11);
      for (final context in [
        const SourceSemanticContext(mode: SourceMovementMode.surf),
        const SourceSemanticContext(mode: SourceMovementMode.cycling),
        const SourceSemanticContext(bridgeLevel: 1),
      ]) {
        expect(
            resolver
                .resolveEventTouch(
                    cell: cell,
                    event: exit,
                    page: exit.pages.single,
                    mapEvents: analysis.events,
                    context: context)
                .kind,
            SourceEventTouchKind.unqualified);
      }
      final unknown = SourceSemanticCell(
          sourceMapId: 102,
          x: 9,
          y: 11,
          width: cell.width,
          height: cell.height,
          stack: [
            const SourceSemanticTile(
                sourceZ: 2,
                tileId: 490,
                passage: null,
                priority: 0,
                terrainTag: 0),
            ...cell.stack.where((tile) => tile.sourceZ != 2)
          ]);
      expect(
          resolver
              .resolveEventTouch(
                  cell: unknown,
                  event: exit,
                  page: exit.pages.single,
                  mapEvents: analysis.events)
              .kind,
          SourceEventTouchKind.unqualified);
    });

    test(
        'unqualified page and overlapping tile pages quarantine the whole exit',
        () {
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final exit = analysis.eventAt(102, 1)!;
      final tileEvent = analysis.events.singleWhere((event) =>
          event.sourceMapId == 102 &&
          event.pages.any((page) => page.graphic?.tileId == 647));
      final badCondition = _eventLike(exit, pages: [
        _pageLike(exit.pages.single,
            condition: SourceEventCondition(
                kind: SourceEventConditionKind.unqualified,
                reason: 'events.invalid_page_condition'))
      ]);
      final overlap = _eventLike(tileEvent, x: exit.x, y: exit.y);
      final movingTile = _eventLike(tileEvent, pages: [
        for (final page in tileEvent.pages)
          _pageLike(page, graphic: _graphicLike(page.graphic!, moveType: 1))
      ]);
      final missingPage = _eventLike(tileEvent, pages: [
        ...tileEvent.pages,
        _pageLike(tileEvent.pages.first, missingGraphic: true)
      ]);
      for (final replacement in [
        badCondition,
        overlap,
        movingTile,
        missingPage
      ]) {
        final result = _project(source, sounds, policy,
            executionContext: context,
            analysis: SourceEventAnalysis(
                profile: analysis.profile,
                events: [
                  for (final event in analysis.events)
                    event.identity == replacement.identity ? replacement : event
                ],
                diagnostics: analysis.diagnostics));
        expect(
            result.scenes.where((scene) => scene.name == 'Exit / 1'), isEmpty);
        expect(jsonEncode(result.semanticEvidence),
            contains('sourceTouchContactUnqualified'));
      }
    });

    test('a terrain bump never invents a collider for the native exit', () {
      final result = _project(source, sounds, policy,
          executionContext: context, includeSolidTerrain: false);
      expect(result.scenes.where((scene) => scene.name == 'Exit / 1'), isEmpty);
      expect(jsonEncode(result.semanticEvidence),
          contains('sourceTerrainBumpUnqualified'));
    });

    test('retention uses the source viewport and metadata-backed clamp list',
        () {
      expect(policy.viewportWidthTiles, 16);
      expect(policy.viewportHeightTiles, 12);
      expect(policy.marginTiles, 6);
      expect(policy.clampViewportToMapIds, isEmpty);
      expect(MapInstanceRetentionPolicy.fromJson(policy.toJson()), policy);
      expect(
          _project(source, sounds, policy, executionContext: context)
              .retentionPolicy,
          policy);
    });
    test('selected original pipeline keeps explicit quotas authoritative',
        () async {
      final limits = sourceCatalogStudyWriteLimitsFor(3);
      final files = _OriginalFiles(source, root!);
      final events =
          await _composeOriginal(source, files, [98, 100, 102], limits);
      expect(
          events.projection.scenes.where((scene) =>
              scene.name.startsWith('Center door /') ||
              scene.name.startsWith('Exit /')),
          hasLength(3),
          reason: jsonEncode(events
              .projection.semanticEvidence['doorExecutionQualification']));
      final execution =
          (events.projection.semanticEvidence['doorExecutionQualification']
              as Map)['sourceExecutionContext'] as Map;
      expect(execution['qualified'], isTrue);
      expect(execution['sourceProfileHash'],
          SourceEventProfile.kantoForProject(source).canonicalHash.value);
      expect(
          execution['baseDraftHash'], isNot(events.draft.canonicalHash.value));
      final explicitSmall = NativeWriteLimits(
          maxArtifacts: limits.maxArtifacts,
          maxMutations: limits.maxMutations,
          maxArtifactBytes: limits.maxArtifactBytes,
          maxTotalArtifactBytes: limits.maxTotalArtifactBytes,
          maxTotalDraftJsonBytes: limits.maxTotalDraftJsonBytes,
          maxImagePixels: limits.maxImagePixels,
          maxTotalImagePixels: limits.maxTotalImagePixels,
          maxMapCells: limits.maxMapCells,
          jsonLimits: const ContractLimits());
      await expectLater(
          const SourceCatalogStudyComposer().compose(
              source: source,
              base: events.draft,
              files: files,
              limits: explicitSmall),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'json.textQuota')));
      final catalogs = await const SourceCatalogStudyComposer().compose(
          source: source, base: events.draft, files: files, limits: limits);
      expect(catalogs, isNotNull);
      expect(catalogs!.draft.compositionEvidence.keys,
          containsAll(['sourceEvents', 'sourceCatalogs']));
      expect(catalogs.draft.mapIds, events.draft.mapIds);
      expect(
          events.projection.scenes.where((scene) =>
              scene.name.startsWith('Center door /') ||
              scene.name.startsWith('Exit /')),
          hasLength(3));
      expect(events.projection.playableCertified, isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('unselected original doors do not attach their retention policy',
        () async {
      expect(source.maps.map((map) => map.map.sourceMapId),
          containsAll([100, 102]));
      final result = await _composeOriginal(
          source,
          _OriginalFiles(source, root!),
          [98],
          sourceCatalogStudyWriteLimitsFor(1));
      expect(result.draft.mapIds.keys, [98]);
      expect(result.projection.retentionPolicy, isNull);
      expect(
          (result.draft.compositionEvidence['sourceEvents'] as Map)
              .containsKey('mapInstanceRetention'),
          isFalse);
      expect(
          result.projection.scenes.where((scene) =>
              scene.name.startsWith('Center door /') ||
              scene.name.startsWith('Exit /')),
          isEmpty);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('missing retention proof keeps the original programs inactive', () {
      final result = _project(source, sounds, null, executionContext: context);
      expect(
          result.scenes
              .where((scene) => scene.name.startsWith('Center door /')),
          isEmpty);
      expect(jsonEncode(result.semanticEvidence),
          contains('sourceMapInstanceRetentionMissing'));
    });
    test('missing destination door does not emit an exit with a phantom owner',
        () {
      final result = _project(
          source, {'Exit Door': sounds['Exit Door']!}, policy,
          executionContext: context);
      expect(result.scenes.where((scene) => scene.name.startsWith('Exit /')),
          isEmpty);
      expect(result.nativeMaps.values.expand((map) => map.warps), isEmpty);
    });
  }, skip: archive == null || root == null);
}
