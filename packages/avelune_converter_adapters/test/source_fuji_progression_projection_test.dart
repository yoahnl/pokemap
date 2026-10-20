import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<
        ({
          NormalizedSourceProject source,
          SourceEventProjection projection,
          SourceEventAnalysis analysis,
          ProjectCharacterEntry character,
          Map<String, SourceEventItemBinding> items
        })>
    _fixture(
        {bool omitOldSeaMap = false, bool unsupportedEffect = false}) async {
  final skin =
      image.encodePng(image.Image(width: 96, height: 48, numChannels: 4));
  final icon =
      image.encodePng(image.Image(width: 18, height: 32, numChannels: 4));
  final audio = sourceMapMusicFixtureWav();
  const skinPath = 'Graphics/Windowskins/neutral.png';
  const iconPath = 'Graphics/Icons/key-items.png';
  const audioPath = 'Audio/ME/key-item.wav';
  Map<String, Object?> pin(String path, List<int> bytes) => {
        'relativePath': path,
        'sha256': literalFixtureHash(bytes).value,
      };
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
          'audioByItemKind': {'keyItem': pin(audioPath, audio)}
        }
      ]
    },
  });
  final steps = [
    for (final code in [26, 15, 25])
      LiteralFixtureObject('RPG::MoveCommand', {
        '@code': code,
        '@parameters': code == 15 ? <Object?>[8] : <Object?>[]
      })
  ];
  final route = LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': false,
    '@skippable': false,
    '@list': [
      ...steps,
      const LiteralFixtureObject(
          'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
    ]
  });
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: profile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      switchNames: List.generate(65, (i) => 'Flag $i'),
      variableNames: List.generate(39, (i) => 'Count $i'),
      maps: [
        LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
          List.filled(9, 384),
          List.filled(9, 0),
          List.filled(9, 0)
        ], events: [
          LiteralFixtureEvent(id: 16, x: 1, y: 1, name: 'Mr Fuji', pages: [
            LiteralFixtureEventPage(
                characterName: 'Fuji',
                globalSwitch: 64,
                commands: const [
                  LiteralFixtureEventCommand(101, ['A dedication to Pokémon.']),
                  LiteralFixtureEventCommand(
                      111, [12, r'$bag.quantity(:POKEFLUTE) == 0']),
                  LiteralFixtureEventCommand(355, ['pbReceiveItem(:POKEFLUTE)'],
                      indent: 1),
                  LiteralFixtureEventCommand(0, [], indent: 1),
                  LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(
                      101, ['Use the flute for sleeping obstacles.']),
                  LiteralFixtureEventCommand(123, ['A', 0]),
                  LiteralFixtureEventCommand(0, []),
                ]),
            LiteralFixtureEventPage(
                characterName: 'Fuji',
                selfSwitch: 'A',
                commands: [
                  const LiteralFixtureEventCommand(111, [1, 38, 0, 5, 0]),
                  const LiteralFixtureEventCommand(
                      101, ['You visited the old laboratory.'],
                      indent: 1),
                  LiteralFixtureEventCommand(209, [0, route], indent: 1),
                  for (final step in steps)
                    LiteralFixtureEventCommand(509, [step], indent: 1),
                  const LiteralFixtureEventCommand(210, [], indent: 1),
                  const LiteralFixtureEventCommand(
                      101, ['Take this to the sailor.'],
                      indent: 1),
                  const LiteralFixtureEventCommand(
                      111, [12, r'$bag.quantity(:OLDSEAMAP) == 0'],
                      indent: 1),
                  const LiteralFixtureEventCommand(
                      355, ['pbReceiveItem(:OLDSEAMAP)'],
                      indent: 2),
                  const LiteralFixtureEventCommand(0, [], indent: 2),
                  const LiteralFixtureEventCommand(412, [], indent: 1),
                  const LiteralFixtureEventCommand(
                      101, ['Please take care of her.'],
                      indent: 1),
                  const LiteralFixtureEventCommand(122, [38, 38, 0, 0, -1],
                      indent: 1),
                  if (unsupportedEffect)
                    const LiteralFixtureEventCommand(
                        355, ['unqualifiedEffect()'],
                        indent: 1),
                  const LiteralFixtureEventCommand(0, [], indent: 1),
                  const LiteralFixtureEventCommand(411, []),
                  const LiteralFixtureEventCommand(
                      101, ['Has the flute helped?'],
                      indent: 1),
                  const LiteralFixtureEventCommand(0, [], indent: 1),
                  const LiteralFixtureEventCommand(412, []),
                  const LiteralFixtureEventCommand(0, []),
                ]),
          ])
        ])
      ],
      extraFiles: {
        'Graphics/Characters/Fuji.png':
            image.encodePng(image.Image(width: 128, height: 192)),
        skinPath: skin,
        iconPath: icon,
        audioPath: audio,
        'Data/map_metadata.dat': literalFixtureMarshal({
          1: const LiteralFixtureObject('GameData::MapMetadata', {
            '@id': 1,
            '@town_map_position': [1, 0, 0],
            '@real_name': 'Fuji House'
          })
        }),
        'Data/items.dat': literalFixtureMarshal({
          for (final symbol in ['POKEFLUTE', 'OLDSEAMAP'])
            LiteralFixtureSymbol(symbol):
                LiteralFixtureObject('GameData::Item', {
              '@id': LiteralFixtureSymbol(symbol),
              '@real_name': symbol,
              '@real_name_plural': symbol,
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
              '@real_description': 'A key item.',
              '@pbs_file_suffix': '',
            })
        }),
      });
  final source = fixture.source;
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: source.snapshot,
      files: fixture.files,
      symbols: ['POKEFLUTE', 'OLDSEAMAP'],
      eventProfile: analysis.profile);
  expect(items.bindings, hasLength(2), reason: '${items.quarantinedSymbols}');
  final pickups = <String, SourcePickupFeedbackBinding>{};
  for (final item in items.bindings.values) {
    if (omitOldSeaMap && item.sourceSymbol == 'OLDSEAMAP') continue;
    pickups[sourcePickupFeedbackBindingKey(
            sourceMapId: 1,
            sourceSymbol: item.sourceSymbol,
            helper: SourceItemGrantHelper.receiveItem)] =
        await const SourcePickupFeedbackResolver().read(
            source: source,
            files: fixture.files,
            item: item,
            sourceMapId: 1,
            helper: SourceItemGrantHelper.receiveItem);
  }
  final character = await const SourceEventCharacterImporter().read(
      snapshot: source.snapshot,
      files: fixture.files,
      charsetName: 'Fuji',
      sourcePattern: 0,
      sourceDirection: 2);
  return (
    source: source,
    analysis: analysis,
    character: character.character,
    items: items.bindings,
    projection: const SourceEventProjector().project(
        source: source,
        analysis: analysis,
        nativeMaps: {
          1: const MapData(
              id: 'fuji-map',
              name: 'Fuji House',
              size: GridSize(width: 3, height: 3))
        },
        characterBindings: {character.bindingKey: character.binding},
        pickupBindings: pickups,
        itemBindings: items.bindings)
  );
}

Future<({GameState state, List<String> order})> _run(
    SourceEventProjection projection, SceneAsset scene, GameState initial,
    {EntityFacing facing = EntityFacing.north}) async {
  var state = GameState.fromJson(jsonDecode(jsonEncode(initial.toJson())));
  final order = <String>[];
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final plan = buildSceneRuntimePlan(
      SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson()))));
  final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) {
            final condition = intent.conditionSource!;
            if (condition.sourceKind == SceneConditionSourceKind.playerFacing) {
              return condition.playerFacingDirection == facing
                  ? 'true'
                  : 'false';
            }
            if (condition.sourceKind ==
                SceneConditionSourceKind.inventoryItem) {
              final found = state.bag.entries.any((entry) =>
                  entry.itemId == condition.sourceId && entry.quantity > 0);
              return found ==
                      (condition.operator == SceneConditionOperator.isTrue)
                  ? 'true'
                  : 'false';
            }
            final fact = resolver.resolve(
                factId: condition.sourceId,
                runtimeState: state.narrativeFactRuntimeState,
                storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
            return fact.narrativeValue.matches(condition.resolvedFactOperator,
                    condition.resolvedExpectedFactValue)
                ? 'true'
                : 'false';
          },
          showDialogue: (intent) {
            order.add('dialogue');
            return 'completed';
          },
          startBattle: (_) => throw StateError('No battle'),
          playCinematic: (_) => throw StateError('No cinematic'),
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand!;
            if (command is SceneGiveItemInteractiveCommand) {
              order.add(command.itemId);
              final gift =
                  executeSceneItemGift(command: command, gameState: state);
              state = gift.gameState;
              return gift.outcome.name;
            }
            if (command is SceneActorRouteInteractiveCommand) {
              expect((command.steps.first as SceneActorFaceStep).direction,
                  facing);
              expect(
                  (command.steps.last as SceneActorFaceStep).direction,
                  switch (facing) {
                    EntityFacing.north => EntityFacing.south,
                    EntityFacing.south => EntityFacing.north,
                    EntityFacing.east => EntityFacing.west,
                    EntityFacing.west => EntityFacing.east,
                  });
            }
            order.add(command is SceneActorRouteInteractiveCommand
                ? 'away/wait/toward'
                : 'join');
            return 'completed';
          },
          applyConsequence: (consequence) {
            final change = consequence as SceneSetFactConsequence;
            order.add(change.factId);
            final result = writer.setFactValue(
                gameState: state,
                factId: change.factId,
                value: change.narrativeValue);
            expect(result.success, isTrue);
            state = result.gameState;
            return 'completed';
          })).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed,
      reason: result.message);
  return (
    state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson()))),
    order: order
  );
}

String? _selectedScene(SourceEventProjection projection,
    ProjectCharacterEntry character, GameState state) {
  final map = projection.nativeMaps[1]!;
  final project = ProjectManifest(
      name: 'Fuji',
      tilesets: const [],
      maps: [
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/fuji.json')
      ],
      eventRegistry: projection.registry,
      facts: projection.facts,
      scenes: projection.scenes,
      dialogues: projection.dialogues,
      characters: [character]);
  final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(projection.registry),
      occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract(
              map.id, map.entities.single.id)),
      factResolver: NarrativeFactRuntimeResolver.fromFacts(projection.facts),
      projectCatalog:
          buildNarrativeEventProjectCatalog(project: project, maps: [map]),
      project: project,
      maps: [map]);
  expect(authority, isA<NarrativeEventDispatchAuthorityReady>(),
      reason: authority is NarrativeEventDispatchAuthorityBlocked
          ? '${authority.reason}: ${authority.diagnostics}'
          : null);
  final decision = (authority as NarrativeEventDispatchAuthorityReady)
      .plan(gameState: state);
  return decision is NarrativeEventDispatchHandled ? decision.sceneId : null;
}

void main() {
  late Future<
      ({
        NormalizedSourceProject source,
        SourceEventProjection projection,
        SourceEventAnalysis analysis,
        ProjectCharacterEntry character,
        Map<String, SourceEventItemBinding> items
      })> shared;
  setUpAll(() {
    shared = _fixture();
  });
  test('Fuji keeps both conditional key-item grants and source relative route',
      () async {
    final fixture = await shared;
    final row =
        (fixture.projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    expect(fixture.projection.scenes, hasLength(2));
    expect(fixture.projection.itemCatalog!.entries.map((i) => i.id).toSet(),
        fixture.items.values.map((i) => i.definition.id).toSet());
  });
  test(
      'Fuji flute grant is conditional and does not duplicate an existing flute',
      () async {
    final fixture = await shared;
    final projection = fixture.projection;
    final scene = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '0');
    final first =
        await _run(projection, scene, const GameState(saveId: 'fuji'));
    final flute = fixture.items['POKEFLUTE']!.definition.id;
    expect(first.state.bag.entries.single.itemId, flute);
    expect(first.state.bag.entries.single.quantity, 1);
    expect(first.order.where((v) => v == flute), hasLength(1));
    final replay = await _run(projection, scene, first.state);
    expect(replay.state.bag.toJson(), first.state.bag.toJson());
    expect(replay.order, isNot(contains(flute)));
  });
  test(
      'Fuji page selection preserves global64 then persistent self A precedence',
      () async {
    final fixture = await shared;
    final projection = fixture.projection;
    final analyzer = SourceEventAnalyzer.forProject(fixture.source,
        profile: fixture.analysis.profile);
    final writer = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(projection.facts));
    final first = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '0');
    final after = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '1');
    const initial = GameState(saveId: 'fuji');
    expect(_selectedScene(projection, fixture.character, initial), isNull);
    final ready = writer
        .setFactValue(
            gameState: initial,
            factId: sourceEventFactBindingId(analyzer.globalFactId(64)),
            value: NarrativeValue.boolean(true))
        .gameState;
    expect(_selectedScene(projection, fixture.character, ready), first.id);
    final result = await _run(projection, first, ready);
    expect(
        _selectedScene(projection, fixture.character, result.state), after.id);
    final cleared = writer
        .setFactValue(
            gameState: result.state,
            factId: sourceEventFactBindingId(analyzer.globalFactId(64)),
            value: NarrativeValue.boolean(false))
        .gameState;
    expect(_selectedScene(projection, fixture.character, cleared), after.id);
  });
  test(
      'Fuji does not duplicate an existing sea map while completing variable38',
      () async {
    final fixture = await shared;
    final projection = fixture.projection;
    final analyzer = SourceEventAnalyzer.forProject(fixture.source,
        profile: fixture.analysis.profile);
    final factId =
        sourceEventIntegerVariableBindingId(analyzer.variableFactId(38));
    final writer = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(projection.facts));
    final itemId = fixture.items['OLDSEAMAP']!.definition.id;
    final gift = executeSceneItemGift(
        command: SceneGiveItemInteractiveCommand(itemId: itemId, quantity: 1),
        gameState: const GameState(saveId: 'fuji'));
    final ready = writer
        .setFactValue(
            gameState: gift.gameState,
            factId: factId,
            value: NarrativeValue.integer(5))
        .gameState;
    final result = await _run(
        projection,
        projection.scenes
            .singleWhere((s) => s.metadata['sourcePageIndex'] == '1'),
        ready);
    expect(result.state.bag.toJson(), ready.bag.toJson());
    expect(result.order, isNot(contains(itemId)));
    expect(result.order.last, factId);
  });
  test(
      'Fuji keeps its ordered grant sequence in all four interaction directions',
      () async {
    final fixture = await shared;
    final projection = fixture.projection;
    final analyzer = SourceEventAnalyzer.forProject(fixture.source,
        profile: fixture.analysis.profile);
    final factId =
        sourceEventIntegerVariableBindingId(analyzer.variableFactId(38));
    final writer = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(projection.facts));
    final ready = writer
        .setFactValue(
            gameState: const GameState(saveId: 'fuji'),
            factId: factId,
            value: NarrativeValue.integer(5))
        .gameState;
    final scene = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '1');
    for (final facing in EntityFacing.values) {
      final result = await _run(projection, scene, ready, facing: facing);
      expect(result.order, [
        'dialogue',
        'away/wait/toward',
        'join',
        'dialogue',
        'dialogue',
        fixture.items['OLDSEAMAP']!.definition.id,
        'dialogue',
        'dialogue',
        factId
      ]);
    }
  });
  for (final value in [0, 4, 5, -1]) {
    test(
        'Fuji lab condition $value preserves gift then variable38 and save state',
        () async {
      final fixture = await shared;
      final projection = fixture.projection;
      final analyzer = SourceEventAnalyzer.forProject(fixture.source,
          profile: fixture.analysis.profile);
      final factId =
          sourceEventIntegerVariableBindingId(analyzer.variableFactId(38));
      final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts(projection.facts));
      final initial = writer
          .setFactValue(
              gameState: const GameState(saveId: 'fuji'),
              factId: factId,
              value: NarrativeValue.integer(value))
          .gameState;
      final scene = projection.scenes
          .singleWhere((s) => s.metadata['sourcePageIndex'] == '1');
      final result = await _run(projection, scene, initial);
      final map = fixture.items['OLDSEAMAP']!.definition.id;
      if (value == 5) {
        expect(result.order, [
          'dialogue',
          'away/wait/toward',
          'join',
          'dialogue',
          'dialogue',
          map,
          'dialogue',
          'dialogue',
          factId
        ]);
        expect(result.state.bag.entries.single.itemId, map);
        final replay = await _run(projection, scene, result.state);
        expect(replay.order, ['dialogue']);
        expect(replay.state.toJson(), result.state.toJson());
      } else {
        expect(result.order, ['dialogue']);
        expect(result.state.toJson(), initial.toJson());
      }
    });
  }
  for (final variant in ['missingBinding', 'unsupportedEffect']) {
    test('Fuji refuses the whole event for $variant', () async {
      final fixture = await _fixture(
          omitOldSeaMap: variant == 'missingBinding',
          unsupportedEffect: variant == 'unsupportedEffect');
      final row =
          (fixture.projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'quarantinedWholeEvent');
      expect(fixture.projection.scenes, isEmpty);
    });
  }
}
