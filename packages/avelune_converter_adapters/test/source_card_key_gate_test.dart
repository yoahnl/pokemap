import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:image/image.dart' as image;
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/native_media_source_fixture.dart';
import 'support/source_map_music_fixture.dart';

const _charset = 'OBJ_FRLG_Silph Gate_H';
const _explorationSymbols = [
  'REPEL',
  'SUPERREPEL',
  'MAXREPEL',
  'ESCAPEROPE',
  'BICYCLE',
  'OLDROD',
  'GOODROD',
  'SUPERROD'
];

List<LiteralFixtureEventCommand> _commands(
        {String defect = '', bool quantityVariant = false}) =>
    [
      LiteralFixtureEventCommand(111, [
        12,
        defect == 'wrongQuantity'
            ? r'$bag.quantity(:CARDKEY)>1'
            : defect == 'quantitySideEffect'
                ? r'$bag.quantity(:CARDKEY)>0 && undeclaredEffect()'
                : quantityVariant
                    ? r'$bag.quantity(:CARDKEY)>0'
                    : r'$bag.has?(:CARDKEY)'
      ]),
      const LiteralFixtureEventCommand(
          250,
          [
            LiteralFixtureObject('RPG::AudioFile',
                {'@name': 'ItemGet', '@volume': 100, '@pitch': 100})
          ],
          indent: 1),
      const LiteralFixtureEventCommand(
          101, [r'Bingo!\nThe Card Key opened the door!\wtnp[35]'],
          indent: 1),
      LiteralFixtureEventCommand(
          250,
          [
            LiteralFixtureObject('RPG::AudioFile', {
              '@name': defect == 'sound' ? 'Other' : 'frlg_gateopen',
              '@volume': 100,
              '@pitch': defect == 'pitch' ? 120 : 100
            })
          ],
          indent: 1),
      LiteralFixtureEventCommand(123, [defect == 'letter' ? 'B' : 'A', 0],
          indent: 1),
      const LiteralFixtureEventCommand(0, [], indent: 1),
      const LiteralFixtureEventCommand(411, []),
      const LiteralFixtureEventCommand(101, [r'No!\nIt needs a Card Key!'],
          indent: 1),
      const LiteralFixtureEventCommand(0, [], indent: 1),
      const LiteralFixtureEventCommand(412, []),
      if (defect == 'effect') const LiteralFixtureEventCommand(121, [1, 1, 0]),
      const LiteralFixtureEventCommand(0, []),
    ];

Future<
        ({
          NormalizedSourceProject source,
          LiteralFixtureFiles files,
          SourceEventAnalysis analysis,
          Map<String, SourceEventCharacterBinding> characters,
          Map<String, SourceEventSoundBinding> sounds,
          Map<String, SourceEventItemBinding> items,
          SourceEventCharacterImport character
        })>
    _input(
        {String defect = '',
        bool quantityVariant = false,
        bool includeOtherMap = false,
        bool includeEncounter = false,
        bool explorationItems = false}) async {
  final charset = quantityVariant ? 'OBJ_FRLG_Silph Gate_V' : _charset;
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {
      ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
      for (final role in [
        'Messages',
        'MessageConfig',
        'DrawText',
        'Audio_Play'
      ])
        'events.$role': {
          'index': 0,
          'name': 'Synthetic',
          'sha256': literalFixtureHash(syntheticInterpretationSection).value
        }
    },
  });
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: profile,
      includeEventSystem: true,
      extraFiles: {
        if (includeEncounter)
          'PBS/encounters.txt': utf8.encode('[214]\nLand,11\n100,RATTATA,2,3\n'),
        'PBS/pokemon.txt': utf8
            .encode('[RATTATA]\nName = Rattata\n[RATICATE]\nName = Raticate\n'),
        'Data/species.dat': literalFixtureMarshal({
          for (final row in [('RATTATA', 'Rattata'), ('RATICATE', 'Raticate')])
            LiteralFixtureSymbol(row.$1):
                LiteralFixtureObject('GameData::Species', {
              '@id': LiteralFixtureSymbol(row.$1),
              '@species': LiteralFixtureSymbol(row.$1),
              '@form': 0,
              '@real_name': row.$2
            })
        }),
        'PBS/items.txt': utf8.encode(
            '[CARDKEY]\nName = Card Key\nNamePlural = Card Keys\nPocket = 8\nPrice = 0\nFlags = KeyItem\nConsumable = false\nDescription = A card key.\n${explorationItems ? [
                for (var i = 0; i < _explorationSymbols.length; i++)
                  '[${_explorationSymbols[i]}]\nName = ${_explorationSymbols[i]}\nNamePlural = ${_explorationSymbols[i]}s\nPocket = ${i >= 4 ? 8 : 1}\nPrice = 100\nSellPrice = 50\nFieldUse = 2\nFlags = ${i >= 4 ? 'KeyItem' : i == 3 ? '' : 'Repel,Fling_30'}\nConsumable = ${i < 4}\nDescription = Source exploration item\n'
              ].join() : ''}'),
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
        'PBS/map_metadata.txt': utf8.encode('[214]\nMapPosition = 1,0,0\n'),
        'Graphics/Characters/Player.png': image
            .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        'Graphics/Characters/$charset.png': image
            .encodePng(image.Image(width: 256, height: 256, numChannels: 4)),
        'Audio/SE/ItemGet.wav': sourceMapMusicFixtureWav(),
        if (defect != 'missingSound')
          'Audio/SE/frlg_gateopen.wav': sourceMapMusicFixtureWav(),
        'Data/items.dat': literalFixtureMarshal({
          const LiteralFixtureSymbol('CARDKEY'):
              const LiteralFixtureObject('GameData::Item', {
            '@id': LiteralFixtureSymbol('CARDKEY'),
            '@real_name': 'Card Key',
            '@real_name_plural': 'Card Keys',
            '@real_portion_name': null,
            '@real_portion_name_plural': null,
            '@pocket': 8,
            '@price': 0,
            '@sell_price': 0,
            '@bp_price': 0,
            '@field_use': 0,
            '@battle_use': 0,
            '@flags': ['KeyItem'],
            '@consumable': false,
            '@show_quantity': null,
            '@move': null,
            '@real_description': 'A card key.',
            '@pbs_file_suffix': ''
          }),
          if (explorationItems)
            for (var i = 0; i < _explorationSymbols.length; i++)
              LiteralFixtureSymbol(_explorationSymbols[i]):
                  LiteralFixtureObject('GameData::Item', {
                '@id': LiteralFixtureSymbol(_explorationSymbols[i]),
                '@real_name': _explorationSymbols[i],
                '@real_name_plural': '${_explorationSymbols[i]}s',
                '@real_portion_name': null,
                '@real_portion_name_plural': null,
                '@pocket': i >= 4 ? 8 : 1,
                '@price': 100,
                '@sell_price': 50,
                '@bp_price': 0,
                '@field_use': 2,
                '@battle_use': 0,
                '@flags': i >= 4
                    ? ['KeyItem']
                    : i == 3
                        ? <String>[]
                        : ['Repel', 'Fling_30'],
                '@consumable': i < 4,
                '@show_quantity': null,
                '@move': null,
                '@real_description': 'Source exploration item',
                '@pbs_file_suffix': '',
              }),
        }),
      },
      maps: [
        if (includeOtherMap) LiteralFixtureMap(id: 7),
        LiteralFixtureMap(id: 214, width: 5, height: 5, layers: [
          List.filled(25, 384),
          List.filled(25, 0),
          List.filled(25, 0)
        ], events: [
          LiteralFixtureEvent(
              id: 9,
              name: defect == 'size'
                  ? 'Silph Gate size(3,2)'
                  : 'Silph Gate size(2,2)',
              x: 2,
              y: 2,
              pages: [
                LiteralFixtureEventPage(
                    characterName: charset,
                    directionFix: !quantityVariant,
                    walkAnime: quantityVariant,
                    moveType: defect == 'autonomous' ? 1 : 0,
                    commands: _commands(
                        defect: defect, quantityVariant: quantityVariant)),
                LiteralFixtureEventPage(
                    selfSwitch: 'A',
                    through: defect != 'solidOpen',
                    commands: [
                      if (defect == 'openEffect')
                        const LiteralFixtureEventCommand(123, ['B', 0]),
                      const LiteralFixtureEventCommand(0, [])
                    ])
              ])
        ])
      ]);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
      policyHash: fixture.snapshot.policyHash,
      entries: [
        ...fixture.snapshot.entries,
        for (final row in [
          (
            'Game.exe',
            14732288,
            '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04'
          ),
          (
            'Game.ini',
            121,
            '5ca2b3b37b92767097a5db5a126c6c50cc6fc2602d3fa9776f06883838aba5f6'
          ),
          (
            'mkxp.json',
            6212,
            '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f'
          )
        ])
          SourceFileEntry(
              fileId: ConverterId('fixture-${row.$1}'),
              relativePath: row.$1,
              kind: SourceNodeKind.file,
              byteLength: row.$2,
              sha256: Sha256Hash(row.$3),
              format: 'unknown',
              family: 'project')
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: fixture.snapshot.profileEvidence,
      state: SourceScanState.complete);
  final files = LiteralFixtureFiles(snapshot, fixture.sourceBytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      interpretationProfile: profile,
      includeEventSystem: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final character = await const SourceEventCharacterImporter().read(
      snapshot: snapshot,
      files: files,
      charsetName: charset,
      sourcePattern: 0,
      sourceDirection: 2,
      fixedDirection: !quantityVariant);
  final sounds = <String, SourceEventSoundBinding>{};
  for (final name in [
    'ItemGet',
    if (defect != 'missingSound') 'frlg_gateopen'
  ]) {
    sounds[name] = await const SourceEventSoundResolver()
        .read(source: source, files: files, name: name);
  }
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: snapshot,
      files: files,
      symbols: ['CARDKEY'],
      eventProfile: analysis.profile);
  return (
    source: source,
    files: files,
    analysis: analysis,
    characters: {character.bindingKey: character.binding},
    sounds: sounds,
    items: items.bindings,
    character: character
  );
}

Future<SourceEventProjection> _project(
    {String defect = '', bool quantityVariant = false}) async {
  final input = await _input(defect: defect, quantityVariant: quantityVariant);
  return const SourceEventProjector().project(
      source: input.source,
      analysis: input.analysis,
      nativeMaps: {
        214: MapData(
            id: 'silph2',
            name: 'Silph',
            size: const GridSize(width: 5, height: 5))
      },
      characterBindings: input.characters,
      soundBindings: input.sounds,
      itemBindings: input.items);
}

Future<({GameState state, List<String> effects})> _runGate(
    SourceEventProjection projection,
    SceneAsset scene,
    GameState initial) async {
  var state = initial;
  final effects = <String>[];
  final writer = NarrativeFactRuntimeWriter(
      NarrativeFactRuntimeResolver.fromFacts(projection.facts));
  final reloaded = SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson())));
  final plan = buildSceneRuntimePlan(reloaded);
  expect(plan.plan, isNotNull);
  final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) => evaluateSceneInventoryCondition(
                  source: intent.conditionSource!, gameState: state)
              ? 'true'
              : 'false',
          showDialogue: (_) {
            effects.add('dialogue');
            return 'completed';
          },
          startBattle: (_) => throw StateError('No battle'),
          playCinematic: (_) => throw StateError('No cinematic'),
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand!;
            if (command is! ScenePlaySoundEffectInteractiveCommand) {
              throw StateError('Unexpected command');
            }
            effects.add('sound');
            return 'completed';
          },
          applyConsequence: (consequence) {
            if (consequence is! SceneSetFactConsequence) {
              throw StateError('Unexpected effect');
            }
            final written = writer.setFactValue(
                gameState: state,
                factId: consequence.factId,
                value: consequence.narrativeValue);
            expect(written.success, isTrue);
            state = written.gameState;
            effects.add('ownA');
            return 'completed';
          })).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed);
  return (
    state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson()))),
    effects: effects
  );
}

void _testGateVariants(String name, Future<void> Function(bool) body) {
  for (final quantityVariant in [false, true]) {
    test('$name quantity=$quantityVariant', () => body(quantityVariant));
  }
}

void main() {
  test(
      'closed Card Key gate preserves both pages and its full four-cell footprint',
      () async {
    final projected = await _project();
    expect(
        (projected.semanticEvidence['events'] as List).single['gaps'], isEmpty);
    final entity = projected.nativeMaps[214]!.entities.single;
    expect(entity.pos, const GridPos(x: 2, y: 1));
    expect(entity.size, const GridSize(width: 2, height: 2));
    expect(resolveEntityCollisionCells(entity).toSet(), {
      const GridPos(x: 2, y: 1),
      const GridPos(x: 3, y: 1),
      const GridPos(x: 2, y: 2),
      const GridPos(x: 3, y: 2)
    });
    expect(entity.presentation!.variants, hasLength(2));
    expect(entity.presentation!.variants.first.characterId, isNull);
    expect(entity.presentation!.variants.first.blocksMovement, isFalse);
    expect(entity.presentation!.variants.last.blocksMovement, isTrue);
  });
  test('quantity predicate preserves the orientable vertical gate footprint',
      () async {
    final projected = await _project(quantityVariant: true);
    final row = (projected.semanticEvidence['events'] as List).single;
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    final entity = projected.nativeMaps[214]!.entities.single;
    expect(entity.pos, const GridPos(x: 2, y: 1));
    expect(entity.size, const GridSize(width: 2, height: 2));
    expect(entity.presentation!.variants, hasLength(2));
    expect(entity.presentation!.variants.first.blocksMovement, isFalse);
    expect(entity.presentation!.variants.last.blocksMovement, isTrue);
  });
  test('orientable quantity gate refuses a fixed-only character binding',
      () async {
    final input = await _input(quantityVariant: true);
    expect(input.character.fixedDirection, isFalse);
    final fixed = await const SourceEventCharacterImporter().read(
        snapshot: input.source.snapshot,
        files: input.files,
        charsetName: 'OBJ_FRLG_Silph Gate_V',
        sourcePattern: 0,
        sourceDirection: 2,
        fixedDirection: true);
    final projected = const SourceEventProjector().project(
        source: input.source,
        analysis: input.analysis,
        nativeMaps: {
          214: MapData(
              id: 'silph2',
              name: 'Silph',
              size: const GridSize(width: 5, height: 5))
        },
        characterBindings: {fixed.bindingKey: fixed.binding},
        soundBindings: input.sounds,
        itemBindings: input.items);
    expect((projected.semanticEvidence['events'] as List).single['gaps'],
        contains('characterBindingMissing'));
    expect(projected.nativeMaps[214]!.entities, isEmpty);
  });
  for (final defect in [
    'wrongQuantity',
    'quantitySideEffect',
    'size',
    'autonomous',
    'pitch',
    'letter',
    'sound',
    'effect',
    'openEffect',
    'solidOpen',
    'missingSound'
  ]) {
    test('closed gate refuses incomplete or changed program $defect', () async {
      final result = await _project(defect: defect);
      expect((result.semanticEvidence['events'] as List).single['gaps'],
          isNotEmpty);
      expect(result.nativeMaps[214]!.entities, isEmpty);
    });
  }
  test(
      'missing audio does not become silence under an unrelated synthetic oracle',
      () async {
    final input = await _input(defect: 'missingSound');
    input.files.reads.clear();
    await expectLater(
        const SourceMissingOptionalSoundResolver()
            .read(source: input.source, files: input.files,
                name: 'frlg_gateopen'),
        throwsA(isA<NativeWriteException>().having((e) => e.code, 'code',
            'events.optional_sound.audio_oracle_unqualified')));
    expect(input.files.reads, isEmpty);
  });
  _testGateVariants(
      'gate conditions, effect order and saved ownA select the inert open page',
      (quantityVariant) async {
    final input = await _input(quantityVariant: quantityVariant);
    final projection = const SourceEventProjector().project(
        source: input.source,
        analysis: input.analysis,
        nativeMaps: {
          214: MapData(
              id: 'silph2',
              name: 'Silph',
              size: const GridSize(width: 5, height: 5))
        },
        characterBindings: input.characters,
        soundBindings: input.sounds,
        itemBindings: input.items);
    final closed = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '0');
    final open = projection.scenes
        .singleWhere((s) => s.metadata['sourcePageIndex'] == '1');
    final empty =
        await _runGate(projection, closed, const GameState(saveId: 'gate'));
    expect(empty.effects, ['dialogue']);
    final item = input.items['CARDKEY']!.definition.id;
    final initial = GameState(
        saveId: 'gate',
        bag: Bag(entries: [BagEntry(itemId: item, quantity: 1)]));
    final opened = await _runGate(projection, closed, initial);
    expect(opened.effects, ['sound', 'dialogue', 'sound', 'ownA']);
    expect(opened.state.bag.toJson(), initial.bag.toJson());
    final map = MapData.fromJson(
        jsonDecode(jsonEncode(projection.nativeMaps[214]!.toJson())));
    final project = ProjectManifest(
        name: 'Gate',
        maps: [
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/silph2.json')
        ],
        tilesets: [],
        characters: [input.character.character],
        facts: projection.facts,
        eventRegistry: projection.registry,
        scenes: projection.scenes,
        dialogues: projection.dialogues,
        cinematicMediaAssets: [
          for (final binding in input.sounds.values)
            CinematicMediaAsset(
                id: binding.mediaId,
                label: binding.name,
                kind: CinematicMediaAssetKind.sound,
                relativePath:
                    binding.mutation.parameters['logicalPath'] as String)
        ]);
    final gate = map.entities.single;
    final before = resolveMapEntityPresentation(
        project: project, gameState: initial, map: map, entity: gate)!;
    final after = resolveMapEntityPresentation(
        project: project, gameState: opened.state, map: map, entity: gate)!;
    expect(before.blocksMovement, isTrue);
    expect(after.blocksMovement, isFalse);
    expect(after.characterId, isNull);
    for (final contact in [
      (const GridPos(x: 1, y: 1), Direction.east),
      (const GridPos(x: 1, y: 2), Direction.east),
      (const GridPos(x: 4, y: 1), Direction.west),
      (const GridPos(x: 4, y: 2), Direction.west),
      (const GridPos(x: 2, y: 0), Direction.south),
      (const GridPos(x: 3, y: 0), Direction.south),
      (const GridPos(x: 2, y: 3), Direction.north),
      (const GridPos(x: 3, y: 3), Direction.north),
    ]) {
      final world = GameplayWorldState.initial(
          map: map,
          playerPos: contact.$1,
          playerFacing: contact.$2,
          project: project,
          gameState: initial,
          tileWidth: 32,
          tileHeight: 32);
      expect(stepGameplayWorld(world, const InteractIntent()),
          isA<NpcInteracted>(),
          reason: '${contact.$1} ${contact.$2}');
      for (final cell in resolveEntityCollisionCells(gate)) {
        expect(
            world.isCellCenterBlockedLegacyForGridIndexedSystems(
                cell.x, cell.y),
            isTrue);
      }
      final afterWorld = GameplayWorldState.initial(
          map: map,
          playerPos: contact.$1,
          playerFacing: contact.$2,
          project: project,
          gameState: opened.state,
          tileWidth: 32,
          tileHeight: 32);
      for (final cell in resolveEntityCollisionCells(gate)) {
        expect(
            afterWorld.isCellCenterBlockedLegacyForGridIndexedSystems(
                cell.x, cell.y),
            isFalse);
      }
    }
    final authority = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(projection.registry),
        occurrence: NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.entityInteract(map.id, gate.id)),
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
        .plan(gameState: opened.state);
    expect((decision as NarrativeEventDispatchHandled).sceneId, open.id);
    final replay = await _runGate(projection, open, opened.state);
    expect(replay.effects, isEmpty);
    expect(replay.state.toJson(), opened.state.toJson());
  });
  for (final forgery in [
    'position',
    'rawPage',
    'graphic',
    'condition',
    'body'
  ]) {
    test('gate rejects source versus analysis divergence $forgery', () async {
      final input = await _input();
      final owner = input.analysis.events.single;
      final supplied = SourceEventDefinition(
          identity: owner.identity,
          sourceFileId: owner.sourceFileId,
          sourceMapId: owner.sourceMapId,
          sourceEventId: owner.sourceEventId,
          name: owner.name,
          x: forgery == 'position' ? 1 : owner.x,
          y: owner.y,
          locator: owner.locator,
          pages: [
            for (final page in owner.pages)
              SourceEventPageAnalysis(
                  sourcePage:
                      forgery == 'rawPage' && page.originalPageIndex == 0
                          ? owner.pages.last.sourcePage
                          : page.sourcePage,
                  locator: page.locator,
                  graphic: forgery == 'graphic' && page.originalPageIndex == 0
                      ? owner.pages.last.graphic
                      : page.graphic,
                  condition:
                      forgery == 'condition' && page.originalPageIndex == 0
                          ? owner.pages.last.condition
                          : page.condition,
                  rawDataRef: page.rawDataRef,
                  diagnostics: page.diagnostics,
                  body: forgery == 'body' && page.originalPageIndex == 0
                      ? owner.pages.last.body
                      : page.body)
          ]);
      final analysis = SourceEventAnalysis(
          profile: input.analysis.profile,
          diagnostics: input.analysis.diagnostics,
          events: [supplied]);
      expect(
          sourceCardKeyGatePrograms(source: input.source, analysis: analysis),
          isEmpty);
      final result = const SourceEventProjector().project(
          source: input.source,
          analysis: analysis,
          nativeMaps: {
            214: MapData(
                id: 'silph2',
                name: 'Silph',
                size: const GridSize(width: 5, height: 5))
          },
          characterBindings: input.characters,
          soundBindings: input.sounds,
          itemBindings: input.items);
      expect(result.nativeMaps[214]!.entities, isEmpty);
    });
  }

  _testGateVariants(
      'gate composer publishes its native scene and reopens all four collision cells strictly',
      (quantityVariant) async {
    final input = await _input(quantityVariant: quantityVariant, includeEncounter: true);
    final temporary = await Directory.systemTemp.createTemp('card-key-gate-');
    addTearDown(() => temporary.delete(recursive: true));
    final literal = await const LiteralTileComposer().compose(
        source: input.source,
        files: input.files,
        selectedSourceMapIds: [214],
        projectName: 'Gate',
        parentPath: temporary.path,
        folderName: 'native');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: input.source, base: literal, files: input.files))!;
    final bundle = NativePsdkTrainerBundle.builtin();
    const ids = {'rattata', 'raticate', 'rattata_form1', 'raticate_form1'};
    final media = bundle.mediaBySpeciesId.values
        .where((v) => ids.contains(v.speciesId))
        .toList();
    final pixels =
        image.encodePng(image.Image(width: 32, height: 32, numChannels: 4));
    final native = NativePsdkTrainerBundle.fromJson({
      ...bundle.toJson(),
      'species': bundle.speciesById.values
          .where((v) => ids.contains(v.id))
          .map((v) => v.toJson())
          .toList(),
      'sourceLearnsets': bundle.learnsetsBySpeciesId.values
          .where((v) => ids.contains(v.speciesId))
          .map((v) => v.toJson())
          .toList(),
      'evolutions': bundle.evolutionsBySpeciesId.values
          .where((v) => ids.contains(v.speciesId))
          .map((v) => v.toJson())
          .toList(),
      'media': media.map((v) => v.toJson()).toList(),
      'fallbackMedia': [
        for (final path in {
          for (final m in media)
            for (final v in m.variants.values) ...[
              v.frontStatic!,
              v.backStatic!
            ]
        })
          {
            'targetPath': path,
            'sourcePath': 'fixture/gate/$path',
            'bytesBase64': base64Encode(pixels),
            'sha256': literalFixtureHash(pixels).value
          }
      ],
    });
    final pbs = await const SourcePbsParser()
        .read(snapshot: input.source.snapshot, files: input.files);
    final release = await NativeEncounterCatalogQualification.prepare(
        snapshot: input.source.snapshot,
        source: pbs,
        files: input.files,
        nativeCatalog: native,
        selectedSourceMapIds: [214]);
    final composed = (await SourceEventStudyComposer(
            nativeEncounterQualification: release)
        .compose(source: input.source, base: semantic, files: input.files))!;
    expect(
        (composed.projection.semanticEvidence['events'] as List).single['gaps'],
        isEmpty);
    final catalog =
        (await SourceCatalogStudyComposer(nativeEncounterQualification: release)
            .compose(
                source: input.source,
                base: composed.draft,
                files: input.files))!;
    final approval = approveNativeFixtureDraft(catalog.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, catalog.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final snapshot = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(snapshot.loadDiagnostics, isEmpty);
      final entity = snapshot.maps.single.entities.singleWhere((e) =>
          e.properties['sourceEventIdentity'] ==
          input.analysis.events.single.identity.value);
      expect(resolveEntityCollisionCells(entity).length, 4);
      expect(entity.pos, const GridPos(x: 2, y: 1));
      expect(entity.presentation!.variants, hasLength(2));
      expect(
          snapshot.manifest.characters
              .singleWhere((c) => c.id == input.character.character.id)
              .frameHeight,
          2);
      expect(snapshot.manifest.cinematicMediaAssets.map((m) => m.label).toSet(),
          {'ItemGet', 'frlg_gateopen'});
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
  test(
      'a map selection without gates does not read or import excluded gate audio',
      () async {
    final input = await _input(includeOtherMap: true);
    final temporary =
        await Directory.systemTemp.createTemp('card-key-selection-');
    addTearDown(() => temporary.delete(recursive: true));
    final literal = await const LiteralTileComposer().compose(
        source: input.source,
        files: input.files,
        selectedSourceMapIds: [7],
        projectName: 'Selection',
        parentPath: temporary.path,
        folderName: 'unused');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: input.source, base: literal, files: input.files))!;
    input.files.reads.clear();
    final composed = (await const SourceEventStudyComposer()
        .compose(source: input.source, base: semantic, files: input.files))!;
    final paths = {
      for (final id in input.files.reads)
        input.source.snapshot.entries
            .singleWhere((entry) => entry.fileId == id)
            .relativePath
    };
    expect(paths.where((path) => path.startsWith('Audio/SE/')), isEmpty);
    expect(paths, isNot(contains('Graphics/Characters/$_charset.png')));
    expect(
        composed.draft.mutations
            .where((m) => m.actionId == 'scene.dialogue.audioMedia.import'),
        isEmpty);
    expect(
        (composed.draft.compositionEvidence['sourceEvents'] as Map)['sounds'],
        isEmpty);
  });
  test('empty admitted party trades do not request an unrelated native catalog',
      () async {
    final input = await _input();
    final literal = await const LiteralTileComposer().compose(
        source: input.source,
        files: input.files,
        selectedSourceMapIds: [214],
        projectName: 'No party trades',
        parentPath: '/private/tmp',
        folderName: 'unused');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: input.source, base: literal, files: input.files))!;
    final events = (await const SourceEventStudyComposer()
        .compose(source: input.source, base: semantic, files: input.files))!;
    expect(
        (events.draft.compositionEvidence['sourceEvents'] as Map)['partyTrade'],
        isEmpty);
    final catalogs = (await const SourceCatalogStudyComposer().compose(
        source: input.source, base: events.draft, files: input.files))!;
    expect(
        catalogs.draft.mutations
            .where((m) => m.actionId == 'pokemon.species.write'),
        isEmpty);
    expect(
        (catalogs.draft.compositionEvidence['sourceCatalogs']
            as Map)['projection'],
        isNot(contains('nativeMediaSpeciesBindings')));
  });
  final engineRoot = Platform.environment['AVELUNE_CARD_GATE_ENGINE_ROOT'];
  final configurationRoot =
      Platform.environment['AVELUNE_CARD_GATE_CONFIGURATION_ROOT'] ??
          engineRoot;
  test(
      'real workflow scans approves and publishes the Card Key gate with an explicit source audio oracle',
      () async {
    final input = await _input(explorationItems: true);
    final root = await Directory.systemTemp.createTemp('card-key-workflow-');
    final workflow = ConverterWorkflow(checkpoint: (phase, _, __) {
      stdout.writeln('card-key-workflow phase=${phase.name}');
    });
    try {
      final sourceRoot = await Directory('${root.path}/source').create();
      final output = await Directory('${root.path}/output').create();
      for (final entry in input.files.bytes.entries) {
        final file = File('${sourceRoot.path}/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value, flush: true);
      }
      final nativeSource =
          nativeMediaSourceFiles(NativePsdkCatalogManifest.builtin());
      nativeSource['PBS/encounters.txt'] =
          utf8.encode('[214]\nLand,11\n100,RATTATA,2,3\n');
      for (final entry in nativeSource.entries) {
        final file = File('${sourceRoot.path}/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value, flush: true);
      }
      const required = [
        (
          'Game.exe',
          14732288,
          '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04'
        ),
        (
          'Game.ini',
          121,
          '5ca2b3b37b92767097a5db5a126c6c50cc6fc2602d3fa9776f06883838aba5f6'
        ),
        (
          'mkxp.json',
          6212,
          '90a3aee82895e48e6c767f973b637d27856cccfd575f48b78d04191cb3e7d35f'
        ),
      ];
      final oracleHashes = <String, Sha256Hash>{};
      for (final entry in required) {
        final bytes = await File(
                '${entry.$1 == 'Game.exe' ? engineRoot : configurationRoot}/${entry.$1}')
            .readAsBytes();
        expect(bytes.length, entry.$2, reason: entry.$1);
        expect(literalFixtureHash(bytes).value, entry.$3, reason: entry.$1);
        oracleHashes[entry.$1] = literalFixtureHash(bytes);
        await File('${sourceRoot.path}/${entry.$1}')
            .writeAsBytes(bytes, flush: true);
      }
      final snapshot = await workflow.scanSource(ConverterSourceSelection(
          rootPath: await sourceRoot.resolveSymbolicLinks(),
          logicalProjectNamespace: ConverterId('card-key-real-workflow')));
      expect(snapshot.state, SourceScanState.complete);
      workflow.updateSettings(ConverterStudySettings(
          projectName: 'Card Key workflow',
          parentPath: await output.resolveSymbolicLinks(),
          folderName: 'native',
          selectedSourceMapIds: [214],
          interpretationProfile: input.source.interpretationProfile,
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason:
                  'Controlled original gate fixture with an explicit source audio oracle; binary bytes are never executed.')));
      final prepared = await workflow.prepareStudy();
      expect(prepared.canApprove, isTrue,
          reason: jsonEncode({
            'nativeDraft': prepared.nativeDraft != null,
            'normalization': prepared.normalizedSource.diagnostics
                .where((e) => e.blocksPlanning)
                .map((e) => e.toJson())
                .toList(),
            'findings': prepared.previewPlan?.findings
                .where((e) => e.blocksStudy)
                .map((e) => e.toJson())
                .toList(),
          }));
      final sourceEvents =
          prepared.nativeDraft!.compositionEvidence['sourceEvents'] as Map;
      final event =
          ((sourceEvents['projection'] as Map)['events'] as List).single as Map;
      expect(event['status'], 'adaptedStaticSemantics');
      expect(event['gaps'], isEmpty);
      expect(
          prepared.previewPlan!.operations.map((o) => o.targetActionId),
          containsAll([
            'entity.set_presentation',
            'scene.upsert',
            'scene.dialogue.audioMedia.import',
          ]));
      final approval = workflow.approvePrepared(
          sessionRevision: prepared.sessionRevision,
          preparationHash: prepared.preparationHash,
          humanConfirmed: true);
      expect(approval.approvedPlan.approvedByHuman, isTrue);
      final result = await workflow.writeApproved(approval);
      expect(result.published, isTrue);
      expect(result.receipt.verified, isTrue);
      expect(result.sourceUnchanged, isTrue);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [await output.resolveSymbolicLinks()],
          fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(result.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.loadDiagnostics, isEmpty);
        final gate = native.maps.single.entities.singleWhere((e) =>
            e.properties['sourceEventIdentity'] == event['sourceIdentity']);
        expect(gate.pos, const GridPos(x: 2, y: 1));
        expect(resolveEntityCollisionCells(gate).length, 4);
        expect(gate.presentation!.variants, hasLength(2));
        expect(native.manifest.cinematicMediaAssets.map((m) => m.label).toSet(),
            {'ItemGet', 'frlg_gateopen'});
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      for (final entry in oracleHashes.entries) {
        expect(
            literalFixtureHash(await File(
                    '${entry.key == 'Game.exe' ? engineRoot : configurationRoot}/${entry.key}')
                .readAsBytes()),
            entry.value);
      }
    } finally {
      await workflow.dispose();
      await root.delete(recursive: true);
    }
  },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: engineRoot == null
          ? 'Requires an explicit AVELUNE_CARD_GATE_ENGINE_ROOT; no engine binary is committed or executed.'
          : false);
}
