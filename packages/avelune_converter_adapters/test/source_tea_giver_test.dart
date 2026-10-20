import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_external_original_fixture.dart';
import 'support/source_map_music_fixture.dart';

List<LiteralFixtureEventCommand> _route(int actor, List<int> codes,
    {int indent = 0, bool skippable = true}) {
  final steps = [
    for (final code in codes)
      LiteralFixtureObject('RPG::MoveCommand', {
        '@code': code,
        '@parameters': code == 15 ? <Object?>[2] : <Object?>[],
      })
  ];
  return [
    LiteralFixtureEventCommand(
        209,
        [
          actor,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': false,
            '@skippable': skippable,
            '@list': [
              ...steps,
              const LiteralFixtureObject(
                  'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
            ],
          })
        ],
        indent: indent),
    for (final step in steps)
      LiteralFixtureEventCommand(509, [step], indent: indent),
  ];
}

LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var axis = 0; axis < 3; axis++) {
    bytes.setFloat64(axis * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

LiteralFixtureEvent _entrance(String defect) =>
    LiteralFixtureEvent(id: 4, x: 4, y: 1, name: 'Secret entrance', pages: [
      LiteralFixtureEventPage(trigger: 1, pattern: 1, commands: [
        LiteralFixtureEventCommand(223, [_tone(-255), 6]),
        const LiteralFixtureEventCommand(106, [8]),
        const LiteralFixtureEventCommand(201, [0, 36, 2, 2, 8, 1]),
        LiteralFixtureEventCommand(223, [_tone(0), 6]),
        const LiteralFixtureEventCommand(0, []),
      ]),
      LiteralFixtureEventPage(
          trigger: defect == 'parallel' ? 4 : 3,
          pattern: 1,
          globalSwitch: 22,
          commands: [
            const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
            const LiteralFixtureEventCommand(208, [0], indent: 1),
            ..._route(
                defect == 'foreignActor' ? 5 : 0, [15, 17, 15, 18, 15, 19, 15],
                indent: 1),
            const LiteralFixtureEventCommand(210, [], indent: 1),
            const LiteralFixtureEventCommand(208, [1], indent: 1),
            ..._route(-1, [1], indent: 1),
            const LiteralFixtureEventCommand(210, [], indent: 1),
            ..._route(0, [18, 15, 17, 15, 16, 15], indent: 1),
            const LiteralFixtureEventCommand(210, [], indent: 1),
            const LiteralFixtureEventCommand(0, [], indent: 1),
            const LiteralFixtureEventCommand(412, []),
            if (defect == 'variable')
              const LiteralFixtureEventCommand(122, [7, 7, 0, 0, 1]),
            if (defect == 'unknown')
              const LiteralFixtureEventCommand(355, ['unqualifiedEffect()']),
            if (defect != 'missingTermination')
              const LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
            const LiteralFixtureEventCommand(0, []),
          ]),
    ]);

Future<
    ({
      NormalizedSourceProject source,
      SourceEventAnalysis analysis,
      SourceEventProjection projection,
      ProjectCharacterEntry character,
      SourceEventItemBinding item,
    })> _fixture({String defect = '', bool forgeArrival = false}) async {
  final skin =
      image.encodePng(image.Image(width: 96, height: 48, numChannels: 4));
  final icon =
      image.encodePng(image.Image(width: 18, height: 32, numChannels: 4));
  final audio = sourceMapMusicFixtureWav();
  Map<String, Object?> pin(String path, List<int> bytes) => {
        'relativePath': path,
        'sha256': literalFixtureHash(bytes).value,
      };
  const skinPath = 'Graphics/Windowskins/tea.png';
  const iconPath = 'Graphics/Icons/key-items.png';
  const audioPath = 'Audio/ME/key-item.wav';
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'presentationBindings': {
      'characterSubstitutions': [],
      'routedDoorPatterns': [],
      'pickupFeedbackByRegion': [
        {
          'regionId': 1,
          'windowskinPinnedAsset': pin(skinPath, skin),
          'iconsByPocket': {'8': pin(iconPath, icon)},
          'audioByItemKind': {'keyItem': pin(audioPath, audio)},
        }
      ],
    },
  });
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: profile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      switchNames: List.generate(
          23, (index) => index == 22 ? 's:tsOff?("A")' : 'Flag $index'),
      variableNames: List.generate(8, (index) => 'Value $index'),
      maps: [
        LiteralFixtureMap(id: 36, width: 7, height: 7, layers: [
          List.filled(49, 384),
          List.filled(49, 0),
          List.filled(49, 0)
        ]),
        LiteralFixtureMap(id: 42, width: 7, height: 7, layers: [
          List.filled(49, 384),
          List.filled(49, 0),
          List.filled(49, 0)
        ], events: [
          _entrance(defect),
          LiteralFixtureEvent(id: 5, x: 4, y: 5, name: 'Tea giver', pages: [
            LiteralFixtureEventPage(characterName: 'TeaGiver', commands: [
              const LiteralFixtureEventCommand(101, ['Try this instead.']),
              const LiteralFixtureEventCommand(355, ['pbReceiveItem(:TEA)']),
              const LiteralFixtureEventCommand(101, ['Enjoy the tea.']),
              const LiteralFixtureEventCommand(123, ['A', 0]),
              ..._route(0, [25], skippable: false),
              const LiteralFixtureEventCommand(0, []),
            ]),
            LiteralFixtureEventPage(
                characterName: 'TeaGiver',
                selfSwitch: 'A',
                commands: [
                  const LiteralFixtureEventCommand(
                      101, ['My Pokémon keep me company.']),
                  ..._route(0, [25], skippable: false),
                  const LiteralFixtureEventCommand(0, []),
                ]),
          ]),
        ]),
      ],
      extraFiles: {
        'Graphics/Characters/TeaGiver.png':
            image.encodePng(image.Image(width: 128, height: 192)),
        skinPath: skin,
        iconPath: icon,
        audioPath: audio,
        'Data/map_metadata.dat': literalFixtureMarshal({
          42: const LiteralFixtureObject('GameData::MapMetadata', {
            '@id': 42,
            '@town_map_position': [1, 0, 0],
            '@real_name': 'Tea House'
          })
        }),
        'Data/items.dat': literalFixtureMarshal({
          const LiteralFixtureSymbol('TEA'):
              const LiteralFixtureObject('GameData::Item', {
            '@id': LiteralFixtureSymbol('TEA'),
            '@real_name': 'Tea',
            '@real_name_plural': 'Tea',
            '@real_portion_name': null,
            '@real_portion_name_plural': null,
            '@pocket': 8,
            '@price': 0,
            '@sell_price': 0,
            '@bp_price': 1,
            '@field_use': 0,
            '@battle_use': 0,
            '@flags': ['KeyItem'],
            '@consumable': false,
            '@show_quantity': null,
            '@move': null,
            '@real_description': 'A refreshing tea.',
            '@pbs_file_suffix': '',
          }),
        }),
      });
  final source = fixture.source;
  var analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  if (forgeArrival) {
    final original = analysis.eventAt(42, 4)!;
    analysis = SourceEventAnalysis(
        profile: analysis.profile,
        diagnostics: analysis.diagnostics,
        events: [
          for (final event in analysis.events)
            event.identity != original.identity
                ? event
                : SourceEventDefinition(
                    identity: original.identity,
                    sourceFileId: original.sourceFileId,
                    sourceMapId: original.sourceMapId,
                    sourceEventId: original.sourceEventId,
                    name: original.name,
                    x: original.x + 1,
                    y: original.y,
                    locator: original.locator,
                    pages: original.pages)
        ]);
  }
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: source.snapshot,
      files: fixture.files,
      symbols: ['TEA'],
      eventProfile: analysis.profile);
  final item = items.bindings['TEA']!;
  final pickup = await const SourcePickupFeedbackResolver().read(
      source: source,
      files: fixture.files,
      item: item,
      sourceMapId: 42,
      helper: SourceItemGrantHelper.receiveItem);
  final character = await const SourceEventCharacterImporter().read(
      snapshot: source.snapshot,
      files: fixture.files,
      charsetName: 'TeaGiver',
      sourcePattern: 0,
      sourceDirection: 2);
  final projection = const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: {
        for (final id in [36, 42])
          id: MapData(
              id: 'map_$id',
              name: 'Map $id',
              size: const GridSize(width: 7, height: 7)),
      },
      itemBindings: items.bindings,
      pickupBindings: {
        sourcePickupFeedbackBindingKey(
            sourceMapId: 42,
            sourceSymbol: 'TEA',
            helper: SourceItemGrantHelper.receiveItem): pickup
      },
      characterBindings: {character.bindingKey: character.binding});
  return (
    source: source,
    analysis: analysis,
    projection: projection,
    character: character.character,
    item: item
  );
}

Map _giverRow(SourceEventProjection projection) =>
    (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => row['locator']['eventId'] == 5);

Future<GameState> _runTea(SourceEventProjection projection, SceneAsset scene,
    GameState initial, EntityFacing facing, List<String> order) async {
  var state = GameState.fromJson(jsonDecode(jsonEncode(initial.toJson())));
  final writer = NarrativeFactRuntimeWriter(
      NarrativeFactRuntimeResolver.fromFacts(projection.facts));
  final plan = buildSceneRuntimePlan(
      SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson()))));
  expect(plan.plan, isNotNull);
  final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) {
            expect(intent.conditionSource!.sourceKind,
                SceneConditionSourceKind.playerFacing);
            return intent.conditionSource!.playerFacingDirection == facing
                ? 'true'
                : 'false';
          },
          showDialogue: (_) {
            order.add('dialogue');
            return 'completed';
          },
          startBattle: (_) => throw StateError('No battle'),
          playCinematic: (_) => throw StateError('No cinematic'),
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand!;
            if (command is SceneGiveItemInteractiveCommand) {
              order.add('tea');
              final result =
                  executeSceneItemGift(command: command, gameState: state);
              state = result.gameState;
              return result.outcome.name;
            }
            if (command is SceneActorRouteInteractiveCommand) {
              expect(command.target.kind, SceneActorTargetKind.entity);
              expect(command.steps, hasLength(1));
              expect(
                  (command.steps.single as SceneActorFaceStep).direction,
                  switch (facing) {
                    EntityFacing.north => EntityFacing.south,
                    EntityFacing.south => EntityFacing.north,
                    EntityFacing.east => EntityFacing.west,
                    EntityFacing.west => EntityFacing.east,
                  });
              order.add('face');
            } else {
              expect(command, isA<SceneWaitForActorRoutesInteractiveCommand>());
              order.add('join');
            }
            return 'completed';
          },
          applyConsequence: (consequence) {
            final change = consequence as SceneSetFactConsequence;
            final result = writer.setFactValue(
                gameState: state,
                factId: change.factId,
                value: change.narrativeValue);
            expect(result.success, isTrue);
            state = result.gameState;
            order.add('selfA');
            return 'completed';
          })).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed,
      reason: result.message);
  return GameState.fromJson(jsonDecode(jsonEncode(state.toJson())));
}

String _selectedTeaScene(SourceEventProjection projection,
    ProjectCharacterEntry character, GameState state) {
  final map = projection.nativeMaps[42]!;
  final giver = map.entities.single;
  final project = ProjectManifest(
      name: 'Tea',
      tilesets: const [],
      maps: [
        for (final nativeMap in projection.nativeMaps.values)
          ProjectMapEntry(
              id: nativeMap.id,
              name: nativeMap.name,
              relativePath: 'maps/${nativeMap.id}.json')
      ],
      eventRegistry: projection.registry,
      facts: projection.facts,
      scenes: projection.scenes,
      dialogues: projection.dialogues,
      characters: [character]);
  final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(projection.registry),
      occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract(map.id, giver.id)),
      factResolver: NarrativeFactRuntimeResolver.fromFacts(projection.facts),
      projectCatalog: buildNarrativeEventProjectCatalog(
          project: project, maps: projection.nativeMaps.values.toList()),
      project: project,
      maps: projection.nativeMaps.values.toList());
  expect(authority, isA<NarrativeEventDispatchAuthorityReady>(),
      reason: authority is NarrativeEventDispatchAuthorityBlocked
          ? '${authority.reason}: ${authority.diagnostics}'
          : null);
  return ((authority as NarrativeEventDispatchAuthorityReady)
          .plan(gameState: state) as NarrativeEventDispatchHandled)
      .sceneId;
}

Iterable<Map> _evidenceMaps(Object? value) sync* {
  if (value is Map) {
    yield value;
    for (final child in value.values) {
      yield* _evidenceMaps(child);
    }
  } else if (value is List) {
    for (final child in value) {
      yield* _evidenceMaps(child);
    }
  }
}

void main() {
  test('tea giver remains source-ordered beside an independent door arrival',
      () async {
    final value = await _fixture();
    final row = _giverRow(value.projection);
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    expect(row['gaps'], isEmpty);
    expect(
        value.projection.scenes.where((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            value.analysis.eventAt(42, 5)!.identity.value),
        hasLength(2));
  });
  for (final defect in [
    'foreignActor',
    'parallel',
    'variable',
    'unknown',
    'missingTermination'
  ]) {
    test('tea facing refuses an unqualified concurrent arrival $defect',
        () async {
      final value = await _fixture(defect: defect);
      final row = _giverRow(value.projection);
      expect(row['status'], 'quarantinedWholeEvent');
      expect(row['gaps'], contains('interactionFacingUnsupported'));
    });
  }
  test('tea facing refuses a forged arrival owner even with its original pages',
      () async {
    final value = await _fixture(forgeArrival: true);
    final row = _giverRow(value.projection);
    expect(row['status'], 'quarantinedWholeEvent');
    expect(row['gaps'], contains('interactionFacingUnsupported'));
  });
  for (final facing in EntityFacing.values) {
    test(
        'Tea grant and own A survive save reload without a second grant $facing',
        () async {
      final value = await _fixture();
      final projection = value.projection;
      final initial = GameState(saveId: 'tea', bag: const Bag());
      final firstId = _selectedTeaScene(projection, value.character, initial);
      final first =
          projection.scenes.singleWhere((scene) => scene.id == firstId);
      expect(first.metadata['sourcePageIndex'], '0');
      final order = <String>[];
      final saved = await _runTea(projection, first, initial, facing, order);
      expect(saved.bag.entries, hasLength(1));
      expect(saved.bag.entries.single.itemId, value.item.definition.id);
      expect(saved.bag.entries.single.quantity, 1);
      expect(order.where((entry) => entry == 'tea'), hasLength(1));
      expect(order.indexOf('tea'), lessThan(order.indexOf('selfA')));
      expect(order.indexOf('selfA'), lessThan(order.indexOf('face')));
      expect(order.last, 'join');
      final nextId = _selectedTeaScene(projection, value.character, saved);
      final next = projection.scenes.singleWhere((scene) => scene.id == nextId);
      expect(next.metadata['sourcePageIndex'], '1');
      final replay = <String>[];
      final after = await _runTea(projection, next, saved, facing, replay);
      expect(after.bag.toJson(), saved.bag.toJson());
      expect(after.narrativeFactRuntimeState.toJson(),
          saved.narrativeFactRuntimeState.toJson());
      expect(replay, ['dialogue', 'face', 'join']);
    });
  }
  test('arrival evidence stays separate from text self reset and playability',
      () async {
    final value = await _fixture();
    final facing = _evidenceMaps(_giverRow(value.projection))
        .where((entry) => entry.containsKey('independentDoorArrivals'))
        .toList();
    expect(facing, hasLength(2));
    for (final evidence in facing) {
      expect(evidence['concurrentTextSelfResetAutoruns'], isEmpty);
      expect(evidence['persistentFacingCertified'], isFalse);
      expect((evidence['independentDoorArrivals'] as List).single,
          containsPair('eventId', 4));
    }
    final arrival = (value.projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => row['locator']['eventId'] == 4);
    expect(arrival['status'], 'quarantinedWholeEvent');
  });

  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final oracle = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test('real Celadon Mansion Tea giver and arrival are independently admitted',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {36, 42},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final source = fixture.source;
    final temporary = await Directory.systemTemp.createTemp('tea-real-source-');
    addTearDown(() => temporary.delete(recursive: true));
    final limits =
        sourceCatalogStudyWriteLimitsFor(2, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: [36, 42],
            projectName: 'Tea source qualification',
            parentPath: temporary.path,
            folderName: 'unused',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!const {36, 42}.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    expect(base.draft, isNotNull,
        reason: '${base.diagnostics.map((entry) => entry.toJson()).toList()}');
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: source, base: base, files: fixture.files, limits: limits);
    expect(semantic, isNotNull);
    final events = await const SourceEventStudyComposer().compose(
        source: source, base: semantic!, files: fixture.files, limits: limits);
    expect(events, isNotNull);
    final rows =
        (events!.projection.semanticEvidence['events'] as List).cast<Map>();
    final giver = rows.singleWhere((row) =>
        row['locator']['mapId'] == 42 && row['locator']['eventId'] == 5);
    final arrival = rows.singleWhere((row) =>
        row['locator']['mapId'] == 42 && row['locator']['eventId'] == 4);
    final receipt = Platform.environment['AVELUNE_TEA_REAL_RECEIPT'];
    if (receipt != null) {
      expect(File(receipt).isAbsolute, isTrue);
      await File(receipt).writeAsString(jsonEncode({
        'kind': 'boundedCeladonMansionTeaSourceQualification',
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'sourceProfileHash':
            SourceEventProfile.forProject(source).canonicalHash.value,
        'sourceMapIds': [36, 42],
        'giver': giver,
        'arrival': arrival,
        'nativeProjectWritten': false,
        'fullCampaignCertified': false,
        'sourceScriptsExecuted': 0,
        'aiSourceInferenceCalls': 0,
      }));
    }
    expect(giver['status'], 'adaptedStaticSemantics',
        reason: '${giver['gaps']}');
    expect(giver['gaps'], isEmpty);
    expect(arrival['status'], 'adaptedStaticSemantics',
        reason: '${arrival['gaps']}');
    expect(arrival['gaps'], isEmpty);
  },
      timeout: const Timeout(Duration(minutes: 4)),
      skip: root == null || snapshot == null || oracle == null
          ? 'Requires explicit source root, snapshot and oracle profile.'
          : false);
}
