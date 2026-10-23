import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_interaction_program.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

LiteralFixtureObject _step(int code, [List<Object?> parameters = const []]) =>
    LiteralFixtureObject(
        'RPG::MoveCommand', {'@code': code, '@parameters': parameters});

List<int> _characterPng(int red, int green, int blue) {
  final raster = image.Image(width: 128, height: 192, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 8; y < 40; y++) {
        for (var x = 8; x < 24; x++) {
          raster.setPixelRgba(
              column * 32 + x, row * 48 + y, red, green, blue, 255);
        }
      }
    }
  }
  final encoded = image.encodePng(raster);
  final inspected = image.decodePng(encoded)!;
  expect(inspected.getPixel(0, 0).a, 0);
  expect(inspected.getPixel(16, 24).a, 255);
  expect(inspected.getPixel(16, 24).r, red);
  return encoded;
}

Future<SourceEventProjection> _project(
    {int mapId = 31,
    int ownerId = 62,
    int actorId = 85,
    String? variant,
    bool noContext = false,
    bool noRetention = false,
    bool automatic = false}) async {
  final routeIndent = variant == 'playerChoice' ? 1 : 0;
  final parallel = variant == 'parallel' || variant == 'parallelCollision';
  final steps = variant == 'jump'
      ? [
          _step(37),
          _step(14, [-1, 0]),
          _step(38)
        ]
      : parallel
          ? [
              if (variant == 'parallel') _step(37),
              _step(2),
              _step(2),
              if (variant == 'parallel') _step(38)
            ]
          : [
              _step(2),
              _step(15, [5]),
              _step(19)
            ];
  final otherSteps = [_step(37), _step(4), _step(38)];
  final otherRoute = LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': false,
    '@skippable': true,
    '@list': [...otherSteps, _step(0)],
  });
  if (variant == 'visibility') {
    steps.insert(0, _step(42, [0]));
    steps.add(_step(42, [255]));
  }
  final appearancePair = variant == 'appearancePair' ||
      variant == 'unrestoredAppearance' ||
      variant == 'missingAppearance' ||
      variant == 'appearanceHue' ||
      variant == 'appearanceSameDirection';
  if (appearancePair) {
    if (variant == 'appearanceSameDirection') {
      steps
        ..clear()
        ..add(_step(2));
    }
    steps.insert(
        0,
        _step(41, [
          'Costume',
          variant == 'appearanceHue' ? 10 : 0,
          variant == 'appearanceSameDirection' ? 2 : 6,
          1
        ]));
    if (variant != 'unrestoredAppearance') {
      steps.add(_step(41, ['Wanderer', 0, 2, 0]));
    }
  }
  if (variant == 'appearance') {
    steps.insert(0, _step(41, ['OtherGraphic', 0, 2, 0]));
  }
  if (variant == 'through') steps.insert(0, _step(37));
  if (variant == 'unrestoredVisibility') steps.insert(0, _step(42, [0]));
  final route = LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': variant == 'repeat',
    '@skippable': variant != 'nonSkippable',
    '@list': [...steps, _step(0)],
  });
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        'Data/map_connections.dat': literalFixtureMarshal([]),
        'Data/map_metadata.dat': literalFixtureMarshal({}),
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Wanderer\n'),
        if (variant != 'missingAppearance')
          'Graphics/Characters/Costume.png': _characterPng(70, 120, 210),
        'Graphics/Characters/Wanderer.png': _characterPng(170, 90, 50)
      },
      maps: [
        LiteralFixtureMap(id: mapId, width: 5, height: 3, layers: [
          List.filled(15, 384),
          List.filled(15, 0),
          List.filled(15, 0)
        ], events: [
          LiteralFixtureEvent(
              id: ownerId,
              x: 0,
              y: 0,
              name: 'A different director',
              pages: [
                LiteralFixtureEventPage(commands: [
                  if (variant == 'playerChoice') ...const [
                    LiteralFixtureEventCommand(102, [
                      ['Move', 'Wait'],
                      0
                    ]),
                    LiteralFixtureEventCommand(402, [0, 'Move']),
                  ],
                  LiteralFixtureEventCommand(
                      209,
                      [
                        variant == 'missing'
                            ? 99
                            : variant == 'player' || variant == 'playerChoice'
                                ? -1
                                : actorId,
                        route
                      ],
                      indent: routeIndent),
                  for (final step in steps)
                    LiteralFixtureEventCommand(
                        509, [variant == 'alteredRaw' ? _step(3) : step],
                        indent: routeIndent),
                  if (variant == 'wrongScope')
                    LiteralFixtureEventCommand(201, [0, mapId + 1, 1, 1, 0, 0]),
                  if (parallel) ...[
                    LiteralFixtureEventCommand(209, [actorId + 1, otherRoute]),
                    for (final step in otherSteps)
                      LiteralFixtureEventCommand(509, [step]),
                  ],
                  LiteralFixtureEventCommand(210, [], indent: routeIndent),
                  LiteralFixtureEventCommand(101, ['Everybody arrived.'],
                      indent: routeIndent),
                  if (variant == 'playerChoice') ...const [
                    LiteralFixtureEventCommand(0, [], indent: 1),
                    LiteralFixtureEventCommand(402, [1, 'Wait']),
                    LiteralFixtureEventCommand(101, ['Wait here.'], indent: 1),
                    LiteralFixtureEventCommand(0, [], indent: 1),
                    LiteralFixtureEventCommand(404, []),
                  ],
                  const LiteralFixtureEventCommand(0, []),
                ]),
              ]),
          LiteralFixtureEvent(
              id: actorId,
              x: variant == 'bounds' ? 0 : 3,
              y: 1,
              name: 'Unrelated performer',
              pages: [
                LiteralFixtureEventPage(
                    directionFix: variant == 'directionFixed',
                    walkAnime: variant != 'walkDisabled',
                    characterName: 'Wanderer',
                    commands: [LiteralFixtureEventCommand(0, [])])
              ]),
          if (parallel)
            LiteralFixtureEvent(
                id: actorId + 1,
                x: 3,
                y: 2,
                name: 'Another unrelated performer',
                pages: const [
                  LiteralFixtureEventPage(
                      characterName: 'Wanderer',
                      commands: [LiteralFixtureEventCommand(0, [])])
                ]),
        ])
      ]);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final programs =
      sourceInteractionPrograms(source: source, analysis: analysis);
  final maps = {
    mapId: MapData(
        id: 'stage_$mapId',
        name: 'Other stage',
        size: const GridSize(width: 5, height: 3))
  };
  final composition = {'kind': 'finiteRouteFixture'};
  final base = NativeProjectDraft(
      source: source,
      projectName: 'Finite routes',
      parentPath: '/private/tmp',
      folderName: 'unused-finite-routes',
      mapIds: {
        mapId: maps[mapId]!.id
      },
      artifacts: [],
      mutations: [
        NativeMutation(
            operationId: ConverterId('create-finite-stage'),
            actionId: 'map.create',
            sourceEntityIds: [
              source.mapIdentity(mapId)
            ],
            targetEntityIds: [
              ConverterId(maps[mapId]!.id)
            ],
            parameters: {
              'mapId': maps[mapId]!.id,
              'name': 'Other stage',
              'width': 5,
              'height': 3
            }),
        NativeMutation(
            operationId: ConverterId('save-finite-stage'),
            actionId: 'map.save',
            sourceEntityIds: [source.mapIdentity(mapId)],
            targetEntityIds: [ConverterId(maps[mapId]!.id)],
            parameters: {'map': maps[mapId]!.toJson()}),
      ],
      compositionEvidence: {
        'kind': 'literalTileComposition',
        'version': 2,
        'composition': composition,
        'compositionHash': canonicalHashOf(composition).value,
        'sourceSemantics': {}
      });
  final contexts = await const SourceEventExecutionContextResolver()
      .readProgramContexts(
          source: source,
          base: base,
          nativeMaps: maps,
          files: fixture.files,
          analysis: analysis,
          eventIdentities: programs.keys.toSet(),
          interactionPrograms: programs);
  if (automatic) {
    final requested = variant == 'appearancePair'
        ? Platform.environment['AVELUNE_STD06_APPEARANCE_FIXTURE_ROOT']
        : null;
    final output = requested == null
        ? null
        : await Directory(requested).create(recursive: true);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: fixture.files,
        selectedSourceMapIds: [mapId],
        projectName: 'Appearance import',
        parentPath: output?.path ?? '/private/tmp',
        folderName: 'converted-appearance');
    final semantic = await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: fixture.files);
    final events = await const SourceEventStudyComposer()
        .compose(source: source, base: semantic!, files: fixture.files);
    if (output != null) {
      await _exportAppearanceFixture(
          events!, source, output, mapId, ownerId, actorId);
    }
    return events!.projection;
  }
  final imported = await const SourceEventCharacterImporter().read(
      snapshot: fixture.snapshot,
      files: fixture.files,
      charsetName: 'Wanderer',
      sourcePattern: 0,
      sourceDirection: 2);
  final costume = appearancePair && variant != 'missingAppearance'
      ? await const SourceEventCharacterImporter().read(
          snapshot: fixture.snapshot,
          files: fixture.files,
          charsetName: 'Costume',
          sourcePattern: 1,
          sourceDirection: variant == 'appearanceSameDirection' ? 2 : 6)
      : null;
  return const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: maps,
      programContexts: noContext ? const {} : contexts,
      retentionPolicy: noRetention
          ? null
          : MapInstanceRetentionPolicy(
              viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1),
      characterBindings: {
        imported.bindingKey: imported.binding,
        if (costume != null) costume.bindingKey: costume.binding
      });
}

Future<void> _exportAppearanceFixture(
    SourceEventStudyComposition events,
    NormalizedSourceProject source,
    Directory output,
    int mapId,
    int ownerId,
    int actorId) async {
  final approval = approveNativeFixtureDraft(events.draft);
  final receipt = await NativeProjectWriter()
      .write(approval.plan, approval.context, events.draft);
  expect(receipt.verified, isTrue);
  final handles = WorkspaceHandleStore();
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(receipt.projectPath);
  try {
    final loaded = await ProjectSnapshotLoader(handles: handles)
        .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
    expect(loaded.loadDiagnostics, isEmpty);
    final nativeMapId = events.draft.mapIds[mapId]!;
    final map = loaded.mapById(nativeMapId)!;
    final row = _owner(events.projection);
    final eventId =
        ((row['pages'] as List).first as Map)['nativeEventId'] as String;
    final definition = events.projection.registry.records
        .map((record) => record.definitionOrNull)
        .whereType<NarrativeEventDefinition>()
        .singleWhere((event) => event.id == eventId);
    final scene = events.projection.scenes
        .singleWhere((scene) => scene.id == definition.sceneId);
    final route = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((action) => action.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>()
        .single;
    final bindings =
        events.projection.semanticEvidence['characterBindings'] as Map;
    String character(String name, int pattern, int direction) =>
        (bindings[sourceEventCharacterBindingKey(
            characterName: name,
            pattern: pattern,
            direction: direction)] as Map)['characterId'] as String;
    final costume = character('Costume', 1, 6),
        base = character('Wanderer', 0, 2);
    expect(
        loaded.manifest.characters.any((character) => character.id == costume),
        isTrue);
    expect(loaded.manifest.characters.any((character) => character.id == base),
        isTrue);
    expect(map.entities.any((entity) => entity.id == route.target.entityId),
        isTrue);
    final reference = {
      'kind': 'std06ConvertedAppearanceFixture',
      'projectFilePath': receipt.projectPath,
      'mapId': nativeMapId,
      'ownerAnchorEntityId': definition.source.toJson()['entityId'],
      'eventId': definition.id,
      'sceneId': definition.sceneId,
      'actorId': route.target.entityId,
      'spawnId': map.mapMetadata.defaultSpawnId,
      'spawn': {'x': 0, 'y': 1},
      'ownerPosition': {'x': 0, 'y': 0},
      'interactionFacing': 'north',
      'actorStart': {'x': 3, 'y': 1},
      'actorEnd': {'x': 2, 'y': 1},
      'expectedFinalFacing': 'south',
      'expectedCostumeRgb': [70, 120, 210],
      'expectedBaseRgb': [170, 90, 50],
      'expectedCostumeCharacterId': costume,
      'expectedBaseCharacterId': base,
      'sourceMapId': mapId,
      'sourceOwnerEventId': ownerId,
      'sourceActorEventId': actorId,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'nativeWriterVerified': receipt.verified,
      'strictReopenVerified': true,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
    };
    await File('${output.path}/reference.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(reference)}\n');
    stdout.writeln(jsonEncode(reference));
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

Map _owner(SourceEventProjection result) =>
    (result.semanticEvidence['events'] as List).cast<Map>().first;

void main() {
  for (final ids in [(31, 62, 85), (207, 14, 29)]) {
    test(
        'projects finite route barrier dialogue with unrelated identities $ids',
        () async {
      final result =
          await _project(mapId: ids.$1, ownerId: ids.$2, actorId: ids.$3);
      expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
      expect(((_owner(result)['pages'] as List).first as Map)['nativeEventId'],
          isNotNull);
      final actions = result.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneActorRouteInteractiveCommand>();
      expect(actions, hasLength(1));
      expect(actions.single.steps.map((step) => step.kind), [
        SceneActorRouteStepKind.move,
        SceneActorRouteStepKind.wait,
        SceneActorRouteStepKind.face
      ]);
      expect(actions.single.transientScope, ActorRouteTransientScope.route);
      expect(result.cinematics, isEmpty);
    });
  }
  for (final variant in [
    'missing',
    'bounds',
    'repeat',
    'through',
    'unrestoredVisibility',
    'directionFixed',
    'walkDisabled',
    'appearance',
    'alteredRaw',
    'unrestoredAppearance',
    'missingAppearance',
    'appearanceHue',
  ]) {
    test('refuses $variant as a route diagnostic without diagnosing a door',
        () async {
      final result = await _project(variant: variant);
      expect(_owner(result)['gaps'], isNotEmpty);
      expect(_owner(result)['gaps'],
          isNot(contains('sourceDoorProgramUnsupported')));
      expect(((_owner(result)['pages'] as List).first as Map)['nativeEventId'],
          isNull);
    });
  }
  test(
      'a transfer cannot move an actor route barrier into a different execution scope',
      () async {
    final result = await _project(variant: 'wrongScope');
    expect(_owner(result)['gaps'], isNotEmpty);
    expect(((_owner(result)['pages'] as List).first as Map)['nativeEventId'],
        isNull);
    expect(result.cinematics, isEmpty);
  });
  test(
      'player relative route keeps runtime bounds authority on its qualified map',
      () async {
    final result = await _project(variant: 'player');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
    final routes = result.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>();
    expect(routes.single.target.kind, SceneActorTargetKind.player);
    expect(routes.single.target.mapId, 'stage_31');
    final receipt =
        (result.semanticEvidence['interactionPrograms'] as List).single as Map;
    expect(receipt['authoredRouteBoundsQualified'], isFalse);
    expect(receipt['playerRouteBoundsAuthority'],
        'aveluneCurrentPositionOnQualifiedMap');
  });
  test(
      'player route branches preserve symbolic position bounds without an event minus one',
      () async {
    final result = await _project(variant: 'playerChoice');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
  });
  for (final missing in ['context', 'retention']) {
    test('player route refuses absent $missing qualification', () async {
      final result = await _project(
          variant: 'player',
          noContext: missing == 'context',
          noRetention: missing == 'retention');
      expect(
          _owner(result)['gaps'],
          contains(missing == 'context'
              ? 'sourceExecutionContextUnknown'
              : 'sourceMapInstanceRetentionMissing'));
      expect(((_owner(result)['pages'] as List).first as Map)['nativeEventId'],
          isNull);
    });
  }
  test(
      'parallel through routes share native timeline groups and relative actor origins',
      () async {
    final result = await _project(variant: 'parallel');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
    final cinematic = result.cinematics.single;
    final plan = buildCinematicTimelineSchedule(cinematic);
    expect(plan.issues, isEmpty);
    expect(plan.groups.first.members, hasLength(2));
    expect(plan.groups.first.members.map((step) => step.startMs).toSet(), {0});
    expect(plan.totalDurationMs, 500);
    expect(
        cinematic.stageContext!.stagePoints
            .every((point) => point.toJson()['relativeToActorId'] != null),
        isTrue);
    expect(cinematic.metadata['converter.sourceTemporalParity'], 'false');
  });
  test('parallel routes without explicit through refuse collision loss',
      () async {
    final result = await _project(variant: 'parallelCollision');
    expect(_owner(result)['gaps'],
        contains('sourceParallelRouteCollisionUnsupported'));
    expect(result.cinematics, isEmpty);
  });
  test(
      'literal source jump uses a native jump timeline without flattening to a walk',
      () async {
    final result = await _project(variant: 'jump');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
    final cinematic = result.cinematics.single;
    expect(cinematic.timeline.steps.single.kind,
        CinematicTimelineStepKind.actorJump);
    expect(
        cinematicTimelineActorJumpValidationErrorOf(
            cinematic, cinematic.timeline.steps.single),
        isNull);
  });

  test(
      'appearance with unchanged original direction preserves the intervening west movement facing',
      () async {
    final result = await _project(variant: 'appearanceSameDirection');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
    final route = result.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>()
        .single;
    expect(route.steps.map((step) => step.kind.name),
        ['appearance', 'move', 'appearance']);
  });
  for (final automatic in [false, true]) {
    test(
        'closed source appearance pair imports exact graphics and restores its source pose automatic=$automatic',
        () async {
      final result =
          await _project(variant: 'appearancePair', automatic: automatic);
      expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
      final routes = result.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneActorRouteInteractiveCommand>();
      final steps = routes.single.steps.map((step) => step.toJson()).toList();
      expect(steps.where((step) => step['kind'] == 'appearance'), hasLength(2));
      expect(steps[1], {'kind': 'face', 'direction': 'east', 'durationMs': 0});
      expect(
          steps.last, {'kind': 'face', 'direction': 'south', 'durationMs': 0});
      expect(
          (result.semanticEvidence['characterBindings'] as Map)
              .keys
              .any((key) => key.toString().contains('Costume')),
          isTrue);
    });
  }

  test('preserves explicit temporary visibility steps in native route scope',
      () async {
    final result = await _project(variant: 'visibility');
    expect(_owner(result)['gaps'], isEmpty, reason: '${_owner(result)}');
    final json = result.scenes.map((scene) => scene.toJson()).toString();
    expect(json, contains('visibility'));
    expect(json, contains('visible: false'));
    expect(json, contains('visible: true'));
  });
}
