import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_inventory_controller_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import '../../avelune_converter_core/test/support/trainer_program_fixture.dart'
    as trainer_fixture;
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart' show sourceMapMusicFixtureWav;

typedef InventoryControllerInput = ({
  NormalizedSourceProject source,
  LiteralFixtureFiles files,
  SourceEventAnalysis analysis,
  Map<String, SourceEventItemBinding> items,
  Map<int, MapData> maps,
});

Object? _writerRubyValue(Object? value) => switch (value) {
      trainer_fixture.TrainerRubyObject() => LiteralFixtureObject(value.name, {
          for (final entry in value.fields.entries)
            entry.key: _writerRubyValue(entry.value),
        }),
      List() => value.map(_writerRubyValue).toList(),
      Map() when value.containsKey('__class__') =>
        LiteralFixtureObject(value['__class__'] as String, {
          for (final entry
              in value.entries.where((entry) => entry.key != '__class__'))
            '@${entry.key}': _writerRubyValue(entry.value),
        }),
      _ => value,
    };

Future<List<LiteralFixtureEventPage>> _foreignGuardWriterPages(
    String kind, int sourceMapId, int controllerId,
    {String guardLetter = 'A'}) async {
  if (kind == 'trainer') {
    final pages = trainer_fixture.trainerPages();
    (pages.first.fields['@list'] as List).insert(
        6,
        trainer_fixture.trainerCommand(
            355, ['pbSetSelfSwitch($controllerId,"A",true)'],
            indent: 1));
    return [
      for (final entry in pages.indexed)
        LiteralFixtureEventPage(
            characterName: 'trainer_BUGCATCHER',
            selfSwitch: entry.$1 == 1 ? 'A' : null,
            trigger: entry.$1 == 0 ? 2 : 0,
            commands: [
              for (final command in (entry.$2.fields['@list'] as List)
                  .cast<trainer_fixture.TrainerRubyObject>())
                LiteralFixtureEventCommand(
                    command.fields['@code'] as int,
                    (command.fields['@parameters'] as List)
                        .map(_writerRubyValue)
                        .toList(),
                    indent: command.fields['@indent'] as int),
            ]),
    ];
  }
  if (kind != 'pokedex') return const [];
  final bindings = jsonDecode(await File(
          '../avelune_converter_core/test/fixtures/synthetic_declared_programs.json')
      .readAsString()) as List;
  final binding = bindings
      .cast<Map>()
      .singleWhere((row) => row['family'] == 'pokedexReward');
  final pages = (binding['pages'] as Map).values.cast<Map>().toList();
  final commands = (pages.first['list'] as List).cast<Map>();
  commands[13]['parameters'] = [12, r'!$bag.has?(:HM05)'];
  commands[14] = {
    'code': 355,
    'indent': 3,
    'parameters': ['pbReceiveItem(:HM05)'],
  };
  commands.removeRange(15, 18);
  commands.insert(15, {'code': 0, 'indent': 3, 'parameters': []});
  commands.insert(commands.indexWhere((command) => command['code'] == 209), {
    'code': 355,
    'indent': 2,
    'parameters': [
      '\$game_self_switches[[$sourceMapId,$controllerId,"$guardLetter"]]=true'
    ],
  });
  (commands[10]['parameters'] as List)[3] = 10;
  return [
    for (final entry in pages.indexed)
      LiteralFixtureEventPage(
          characterName: 'Aide',
          selfSwitch: entry.$1 == 1 ? 'A' : null,
          moveType: 3,
          autonomousRouteCodes: const [
            24,
            0
          ],
          commands: [
            for (final command in entry.$2['list'] as List)
              LiteralFixtureEventCommand(
                  command['code'] as int,
                  (command['parameters'] as List)
                      .map(_writerRubyValue)
                      .toList(),
                  indent: command['indent'] as int),
          ]),
  ];
}

Future<InventoryControllerInput> createInventoryControllerInput({
  String defect = '',
  String localWriter = '',
  int sourceMapId = 58,
  int controllerId = 16,
  int targetId = 11,
  String itemSymbol = 'SECRETKEY',
  bool secondMapController = false,
  bool dormantDevice = false,
  bool processWritesDormantGuard = false,
  bool playerFixture = false,
}) async {
  List<int> png(int width, int height) {
    final raster = image.Image(width: width, height: height, numChannels: 4);
    raster.clear(image.ColorRgba8(248, 248, 248, 255));
    return image.encodePng(raster);
  }

  final pickupIcon = playerFixture ? png(18, 32) : const <int>[];
  final pickupSkin = playerFixture ? png(96, 48) : const <int>[];
  final pickupAudio =
      playerFixture ? sourceMapMusicFixtureWav() : const <int>[];
  Map<String, Object?> pin(String path, List<int> bytes) => {
        'relativePath': path,
        'sha256': literalFixtureHash(bytes).value,
      };
  final specializedWriterPages = await _foreignGuardWriterPages(
      localWriter == 'pokedexDormant' ? 'pokedex' : localWriter,
      sourceMapId,
      localWriter == 'pokedexDormant' ? 30 : controllerId,
      guardLetter: localWriter == 'pokedexDormant' ? 'C' : 'A');
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    if (playerFixture)
      'presentationBindings': {
        'pickupFeedbackByRegion': [
          {
            'regionId': 1,
            'windowskinPinnedAsset':
                pin('Graphics/Windowskins/std07-panel.png', pickupSkin),
            'iconsByPocket': {
              '8': pin('Graphics/Icons/std07-key-pocket.png', pickupIcon),
            },
            'audioByItemKind': {
              'keyItem': pin('Audio/ME/std07-key.wav', pickupAudio),
            },
          },
        ],
      },
    'sections': {
      ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
      for (final role in ['Messages', 'MessageConfig', 'DrawText'])
        'events.$role': {
          'index': 0,
          'name': 'Synthetic',
          'sha256': literalFixtureHash(syntheticInterpretationSection).value,
        },
    },
  });
  final fixture = await LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: profile,
    includeEventSystem: true,
    extraFiles: {
      if (playerFixture) ...{
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
        'Graphics/Characters/Player.png': literalFixtureAtlas(),
        'Data/map_metadata.dat': literalFixtureMarshal({
          for (final mapId in [sourceMapId, 200])
            mapId: LiteralFixtureObject('GameData::MapMetadata', {
              '@id': mapId,
              '@town_map_position': [1, 0, 0],
              '@real_name': 'STD07 map $mapId',
            }),
        }),
        'Data/map_connections.dat': literalFixtureMarshal([]),
        'PBS/pokemon.txt': utf8.encode('[ARBOK]\nName = Arbok\n'),
        'Data/species.dat': literalFixtureMarshal({
          const LiteralFixtureSymbol('ARBOK'):
              const LiteralFixtureObject('GameData::Species', {
            '@id': LiteralFixtureSymbol('ARBOK'),
            '@species': LiteralFixtureSymbol('ARBOK'),
            '@form': 0,
            '@real_name': 'Arbok',
          }),
        }),
        'Graphics/Pokemon/Front/ARBOK.png': png(32, 32),
        'Graphics/Pokemon/Back/ARBOK.png': png(32, 32),
        'Graphics/Icons/std07-key-pocket.png': pickupIcon,
        'Graphics/Windowskins/std07-panel.png': pickupSkin,
        'Audio/ME/std07-key.wav': pickupAudio,
      },
      'PBS/items.txt': utf8.encode('[$itemSymbol]\nName = Secret Key\n'
          'NamePlural = Secret Keys\nPocket = 8\nPrice = 0\nFlags = KeyItem\n'
          'Consumable = false\nDescription = A key.\n'),
      'Data/items.dat': literalFixtureMarshal({
        LiteralFixtureSymbol(itemSymbol):
            LiteralFixtureObject('GameData::Item', {
          '@id': LiteralFixtureSymbol(itemSymbol),
          '@real_name': 'Secret Key',
          '@real_name_plural': 'Secret Keys',
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
          '@real_description': 'A key.',
          '@pbs_file_suffix': '',
        }),
      }),
    },
    commonEvents: {
      if (localWriter == 'commonEvent')
        1: [
          LiteralFixtureEventCommand(355, ['pbReceiveItem(:$itemSymbol)'])
        ],
    },
    maps: [
      LiteralFixtureMap(id: sourceMapId, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0),
      ], events: [
        if (defect != 'targetMissing')
          LiteralFixtureEvent(
              id: targetId,
              name: 'Bound door',
              x: 2,
              y: 3,
              pages: [
                LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(101, ['The door is locked...']),
                  LiteralFixtureEventCommand(0, []),
                ])
              ]),
        LiteralFixtureEvent(
            id: controllerId,
            name: 'Door controller',
            x: 2,
            y: 2,
            pages: [
              LiteralFixtureEventPage(trigger: 4, commands: [
                LiteralFixtureEventCommand(111, [
                  12,
                  defect == 'unknownCondition'
                      ? '\$bag.quantity(:$itemSymbol)>0 && arbitrary()'
                      : '\$bag.quantity(:$itemSymbol)>0'
                ]),
                LiteralFixtureEventCommand(
                    355,
                    [
                      processWritesDormantGuard
                          ? 'pbSetSelfSwitch(30,"C",true)'
                          : defect == 'foreignReset'
                              ? 'pbSetSelfSwitch($targetId,"A",false)'
                              : 'pbSetSelfSwitch($targetId,"A",true)'
                    ],
                    indent: 1),
                LiteralFixtureEventCommand(
                    123, ['A', defect == 'ownReset' ? 1 : 0],
                    indent: 1),
                const LiteralFixtureEventCommand(0, [], indent: 1),
                if (defect == 'falseBranch') ...[
                  const LiteralFixtureEventCommand(411, []),
                  const LiteralFixtureEventCommand(123, ['B', 0], indent: 1),
                  const LiteralFixtureEventCommand(0, [], indent: 1),
                ],
                const LiteralFixtureEventCommand(412, []),
                if (defect == 'extraEffect')
                  const LiteralFixtureEventCommand(121, [1, 1, 0]),
                const LiteralFixtureEventCommand(0, []),
              ]),
              LiteralFixtureEventPage(selfSwitch: 'A', trigger: 0, commands: [
                if (defect == 'openEffect')
                  const LiteralFixtureEventCommand(121, [1, 1, 0]),
                const LiteralFixtureEventCommand(0, []),
              ]),
            ]),
        if (defect == 'multipleControllers')
          LiteralFixtureEvent(
              id: 17,
              name: 'Second controller',
              x: 3,
              y: 2,
              pages: [
                LiteralFixtureEventPage(trigger: 4, commands: [
                  LiteralFixtureEventCommand(
                      111, [12, '\$bag.quantity(:$itemSymbol)>0']),
                  LiteralFixtureEventCommand(
                      355, ['pbSetSelfSwitch($targetId,"A",true)'],
                      indent: 1),
                  LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                  LiteralFixtureEventCommand(0, [], indent: 1),
                  LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(0, []),
                ]),
                LiteralFixtureEventPage(selfSwitch: 'A', commands: [
                  LiteralFixtureEventCommand(0, []),
                ]),
              ]),
        if (dormantDevice)
          const LiteralFixtureEvent(
              id: 30,
              name: 'Dormant device',
              x: 4,
              y: 3,
              pages: [
                LiteralFixtureEventPage(selfSwitch: 'C', trigger: 4, commands: [
                  LiteralFixtureEventCommand(355, ['opaqueDeviceEffect()']),
                  LiteralFixtureEventCommand(0, []),
                ]),
                LiteralFixtureEventPage(selfSwitch: 'D', commands: [
                  LiteralFixtureEventCommand(0, []),
                ]),
              ]),
        if (specializedWriterPages.isNotEmpty)
          LiteralFixtureEvent(
              id: 20,
              name: localWriter == 'trainer'
                  ? 'Foreign writer Trainer(0)'
                  : 'Aide',
              x: 4,
              y: 4,
              pages: specializedWriterPages),
        if (localWriter.isNotEmpty && specializedWriterPages.isEmpty)
          LiteralFixtureEvent(id: 20, x: 4, y: 4, pages: [
            LiteralFixtureEventPage(commands: [
              if (localWriter == 'quarantinedGive')
                const LiteralFixtureEventCommand(355, ['unknown()']),
              if (localWriter == 'commonEvent')
                const LiteralFixtureEventCommand(117, [1])
              else if (const ['guardTrue', 'guardFalse'].contains(localWriter))
                LiteralFixtureEventCommand(355, [
                  'pbSetSelfSwitch($controllerId,"A",${localWriter == 'guardTrue'})'
                ])
              else
                LiteralFixtureEventCommand(
                    355, ['pbReceiveItem(:$itemSymbol)']),
              if (localWriter == 'sameMapWarp')
                LiteralFixtureEventCommand(201, [0, sourceMapId, 1, 1, 2, 1]),
              const LiteralFixtureEventCommand(0, []),
            ]),
          ]),
      ]),
      LiteralFixtureMap(id: 200, height: 2, layers: [
        List.filled(6, 384),
        List.filled(6, 0),
        List.filled(6, 0),
      ], events: [
        if (playerFixture)
          const LiteralFixtureEvent(id: 2, x: 2, y: 1, pages: [
            LiteralFixtureEventPage(characterName: 'Player', commands: [
              LiteralFixtureEventCommand(355, ['pbAddPokemon(:ARBOK,5)']),
              LiteralFixtureEventCommand(123, ['A', 0]),
              LiteralFixtureEventCommand(0, []),
            ]),
            LiteralFixtureEventPage(
                characterName: 'Player',
                selfSwitch: 'A',
                commands: [LiteralFixtureEventCommand(0, [])]),
          ]),
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(commands: [
            LiteralFixtureEventCommand(355, ['pbReceiveItem(:$itemSymbol)']),
            LiteralFixtureEventCommand(0, []),
          ]),
        ]),
        if (secondMapController) ...[
          const LiteralFixtureEvent(id: 7, x: 1, y: 1, pages: [
            LiteralFixtureEventPage(commands: [
              LiteralFixtureEventCommand(101, ['Another locked door.']),
              LiteralFixtureEventCommand(0, []),
            ]),
          ]),
          LiteralFixtureEvent(id: 29, x: 0, y: 1, pages: [
            LiteralFixtureEventPage(trigger: 4, commands: [
              LiteralFixtureEventCommand(
                  111, [12, '\$bag.quantity(:$itemSymbol)>0']),
              const LiteralFixtureEventCommand(
                  355, ['pbSetSelfSwitch(7,"A",true)'],
                  indent: 1),
              const LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
              const LiteralFixtureEventCommand(0, [], indent: 1),
              const LiteralFixtureEventCommand(412, []),
              const LiteralFixtureEventCommand(0, []),
            ]),
            const LiteralFixtureEventPage(selfSwitch: 'A', commands: [
              LiteralFixtureEventCommand(0, []),
            ]),
          ]),
        ],
      ]),
    ],
  );
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
        ),
      ])
        SourceFileEntry(
            fileId: ConverterId('fixture-${row.$1}'),
            relativePath: row.$1,
            kind: SourceNodeKind.file,
            byteLength: row.$2,
            sha256: Sha256Hash(row.$3),
            format: 'unknown',
            family: 'project'),
    ],
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: fixture.snapshot.profileEvidence,
    state: SourceScanState.complete,
  );
  final files = LiteralFixtureFiles(snapshot, fixture.sourceBytes);
  final source = await const RmxpSourceNormalizer().normalize(
    snapshot: snapshot,
    files: files,
    interpretationProfile: profile,
    includeEventSystem: true,
  );
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  expect(source.canPlan, isTrue,
      reason:
          '${source.diagnostics.map((diagnostic) => diagnostic.toJson()).toList()}');
  expect(analysis.profile.isQualified, isTrue);
  final items = await const SourceEventItemBindingResolver().read(
    snapshot: snapshot,
    files: files,
    symbols: [itemSymbol],
    eventProfile: analysis.profile,
  );
  return (
    source: source,
    files: files,
    analysis: analysis,
    items: items.bindings,
    maps: {
      for (final map in source.maps)
        map.map.sourceMapId: MapData(
            id: 'map_${map.map.sourceMapId}',
            name: map.map.name,
            size: GridSize(width: map.map.width, height: map.map.height))
    }
  );
}

void main() {
  test(
      'inventory controller binds its whole source and a remote key acquisition',
      () async {
    final input = await createInventoryControllerInput();
    final event = input.analysis.eventAt(58, 16)!;
    final programs = sourceInventoryControllerPrograms(
        source: input.source, analysis: input.analysis);
    expect(programs, contains(event.identity));
    final program = programs[event.identity]!;
    expect(
        program.isBoundTo(
            source: input.source, analysis: input.analysis, event: event),
        isTrue);
    expect(program.toJson()['activation'], 'parallel');
    expect(program.toJson()['sourceItemSymbol'], 'SECRETKEY');
    expect(program.toJson()['sourceSnapshotHash'],
        input.source.snapshot.canonicalHash.value);
    expect(program.toJson()['normalizationHash'],
        input.source.canonicalHash.value);
    expect(program.toJson()['programHash'], matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test(
      'inventory controller projects a finite scene with an owned parallel policy',
      () async {
    final input = await createInventoryControllerInput();
    final projected = const SourceEventProjector().project(
        source: input.source,
        analysis: input.analysis,
        nativeMaps: input.maps,
        itemBindings: input.items);
    final row = (projected.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) =>
            row['locator']['mapId'] == 58 && row['locator']['eventId'] == 16);
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    final records = projected.registry.records
        .where((record) =>
            record.definitionOrNull?.source.kind ==
                NarrativeEventSourceKind.entityAutorun &&
            record.definitionOrNull!.toJson()['parallelPolicy'] != null)
        .toList();
    expect(records, hasLength(1));
    final scene = projected.scenes.singleWhere(
        (scene) => scene.id == records.single.definitionOrNull!.sceneId);
    final serialized = jsonEncode(scene.toJson());
    expect(serialized, contains('inventoryItem'));
    expect(serialized, contains(input.items['SECRETKEY']!.definition.id));
    expect(serialized, isNot(contains('actorRoute')));
    expect(records.single.definitionOrNull!.conditionExpression, isNotNull);
    final definition = records.single.definitionOrNull!;
    final policy = definition.toJson()['parallelPolicy'] as Map;
    expect(policy['cadenceMs'], 100);
    expect(policy['ownerVariantId'], 'page_0');
    expect(definition.source.toJson()['mapId'], input.maps[58]!.id);
    expect(definition.source.toJson()['entityId'], isNotEmpty);
  });

  test('parallel controllers refuse spatial conversion explicitly', () async {
    final input = await createInventoryControllerInput();
    final projected = const SourceEventProjector().project(
        source: input.source,
        analysis: input.analysis,
        nativeMaps: {
          ...input.maps,
          58: input.maps[58]!.copyWith(
              version: ProjectVersion.v9,
              spatialScene: MapSpatialScene(width: 5, depth: 5)),
        },
        itemBindings: input.items);
    final row = (projected.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) =>
            row['locator']['mapId'] == 58 && row['locator']['eventId'] == 16);
    expect(row['gaps'], contains('sourceParallelSpatialUnsupported'));
  });

  test('independent controllers retain distinct source maps and owners',
      () async {
    final input = await createInventoryControllerInput(
        sourceMapId: 731,
        controllerId: 42,
        targetId: 9,
        itemSymbol: 'ACCESSPASS',
        secondMapController: true);
    final programs = sourceInventoryControllerPrograms(
        source: input.source, analysis: input.analysis);
    expect(programs, hasLength(2));
    for (final location in [(731, 42), (200, 29)]) {
      final event = input.analysis.eventAt(location.$1, location.$2)!;
      final program = programs[event.identity]!;
      expect(
          program.isBoundTo(
              source: input.source, analysis: input.analysis, event: event),
          isTrue);
      expect(program.sourceMapId, location.$1);
      expect(program.sourceEventId, location.$2);
      expect(program.sourceItemSymbol, 'ACCESSPASS');
    }
    final projected = const SourceEventProjector().project(
        source: input.source,
        analysis: input.analysis,
        nativeMaps: input.maps,
        itemBindings: input.items);
    final definitions = projected.registry.records
        .map((record) => record.definitionOrNull)
        .whereType<NarrativeEventDefinition>()
        .where((definition) => definition.toJson()['parallelPolicy'] != null)
        .toList();
    expect(definitions, hasLength(2));
    expect(definitions.map((definition) => definition.source.toJson()['mapId']),
        unorderedEquals(['map_731', 'map_200']));
    expect(
        definitions
            .map((definition) => definition.source.toJson()['entityId'])
            .toSet(),
        hasLength(2));
    for (final definition in definitions) {
      expect(definition.source.kind, NarrativeEventSourceKind.entityAutorun);
      final policy = definition.toJson()['parallelPolicy'] as Map;
      expect(policy['cadenceMs'], 100);
      expect(policy['ownerVariantId'], 'page_0');
    }
  });

  test('two controllers on one map have separate guards and bindings',
      () async {
    final input =
        await createInventoryControllerInput(defect: 'multipleControllers');
    final programs = sourceInventoryControllerPrograms(
        source: input.source, analysis: input.analysis);
    expect(programs, hasLength(2));
    expect(programs.values.map((program) => program.guardFactId).toSet(),
        hasLength(2));
  });

  for (final defect in [
    'unknownCondition',
    'foreignReset',
    'ownReset',
    'falseBranch',
    'extraEffect',
    'openEffect',
    'targetMissing',
  ]) {
    test('inventory controller refuses complete-program defect $defect',
        () async {
      final input = await createInventoryControllerInput(defect: defect);
      expect(
          sourceInventoryControllerPrograms(
              source: input.source, analysis: input.analysis),
          isEmpty);
    });
  }
  for (final writer in ['give', 'sameMapWarp']) {
    test(
        'inventory controller permits typed acquisition during the visit: $writer',
        () async {
      final input = await createInventoryControllerInput(localWriter: writer);
      expect(
          sourceInventoryControllerPrograms(
              source: input.source, analysis: input.analysis),
          hasLength(1));
    });
  }
  test('a page-bound item helper in a common call remains quarantined',
      () async {
    final input =
        await createInventoryControllerInput(localWriter: 'commonEvent');
    final writer = input.analysis.eventAt(58, 20)!;
    expect(writer.isQuarantined, isTrue);
    expect(
        writer.pages
            .expand((page) => page.diagnostics)
            .map((diagnostic) => diagnostic.code),
        contains('events.common_event_page_bound_program_unsupported'));
    expect(
        sourceInventoryControllerPrograms(
            source: input.source, analysis: input.analysis),
        isEmpty);
  });
  for (final kind in ['trainer', 'pokedex']) {
    test('a typed $kind foreign guard writer refuses the controller', () async {
      final input = await createInventoryControllerInput(localWriter: kind);
      final writer = input.analysis.eventAt(58, 20)!;
      expect(writer.isQuarantined, isFalse,
          reason:
              '${writer.pages.expand((page) => page.diagnostics).map((diagnostic) => diagnostic.toJson()).toList()}');
      final node = writer.pages.first.body.nodes.single;
      if (kind == 'trainer') {
        expect(node, isA<SourceTrainerProgramNode>());
        expect(
            (node as SourceTrainerProgramNode)
                .victoryContinuation
                .nodes
                .whereType<SourceSelfSwitchNode>()
                .map((write) => write.factId),
            contains(endsWith(':map:58:event:16:self:A')));
      } else {
        expect(node, isA<SourcePokedexRewardProgramNode>());
        expect((node as SourcePokedexRewardProgramNode).foreignRewardFactIds,
            contains(endsWith(':map:58:event:16:self:A')));
      }
      expect(
          sourceInventoryControllerPrograms(
              source: input.source, analysis: input.analysis),
          isEmpty);
    });
  }
  test('inventory controller refuses an opaque local acquisition writer',
      () async {
    final input =
        await createInventoryControllerInput(localWriter: 'quarantinedGive');
    expect(
        sourceInventoryControllerPrograms(
            source: input.source, analysis: input.analysis),
        isEmpty);
  });
  for (final writer in ['guardTrue', 'guardFalse']) {
    test('inventory controller refuses another writer of its guard: $writer',
        () async {
      final input = await createInventoryControllerInput(localWriter: writer);
      expect(
          sourceInventoryControllerPrograms(
              source: input.source, analysis: input.analysis),
          isEmpty);
    });
  }
  test(
      'inventory controller cannot hide a guard writer by trimming supplied analysis',
      () async {
    final input =
        await createInventoryControllerInput(localWriter: 'guardTrue');
    final trimmed = SourceEventAnalysis(
        profile: input.analysis.profile,
        events: input.analysis.events
            .where((event) => event.sourceEventId != 20)
            .toList(),
        diagnostics: input.analysis.diagnostics);
    expect(
        sourceInventoryControllerPrograms(
            source: input.source, analysis: trimmed),
        isEmpty);
  });
  test('inventory controller refuses an event changed after source binding',
      () async {
    final input = await createInventoryControllerInput();
    final event = input.analysis.eventAt(58, 16)!;
    final programs = sourceInventoryControllerPrograms(
        source: input.source, analysis: input.analysis);
    expect(programs, contains(event.identity));
    final forged = SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x + 1,
        y: event.y,
        locator: event.locator,
        pages: event.pages);
    expect(
        programs[event.identity]!.isBoundTo(
            source: input.source, analysis: input.analysis, event: forged),
        isFalse);
  });
  test('inventory controller rejects a page borrowing another raw reference',
      () async {
    final input = await createInventoryControllerInput();
    final event = input.analysis.eventAt(58, 16)!;
    final programs = sourceInventoryControllerPrograms(
        source: input.source, analysis: input.analysis);
    final page = event.pages.first;
    final forged = SourceEventDefinition(
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
              body: page.body,
              rawDataRef: event.pages.last.rawDataRef,
              diagnostics: page.diagnostics),
          event.pages.last,
        ]);
    expect(
        programs[event.identity]!.isBoundTo(
            source: input.source, analysis: input.analysis, event: forged),
        isFalse);
    final forgedAnalysis = SourceEventAnalysis(
        profile: input.analysis.profile,
        events: [
          for (final candidate in input.analysis.events)
            if (candidate.identity == event.identity) forged else candidate,
        ],
        diagnostics: input.analysis.diagnostics);
    expect(
        sourceInventoryControllerPrograms(
            source: input.source, analysis: forgedAnalysis),
        isEmpty);
  });

  test(
      'an exact executable page exemption preserves a cohabiting dormant device',
      () async {
    final input = await createInventoryControllerInput(dormantDevice: true);
    final process = input.analysis.eventAt(58, 16)!;
    final dormant = input.analysis.eventAt(58, 30)!;
    expect(process.isQuarantined, isFalse);
    expect(dormant.isQuarantined, isTrue);
    final audit = SourceParallelDormancyAuditor.forProject(input.source,
            profile: input.analysis.profile)
        .audit(activeSourceMapIds: {
      58
    }, executablePageReferences: {
      process.pages.first.rawDataRef!.id.value,
    });
    expect(audit.isQualified, isTrue, reason: '${audit.refusals}');
    expect(
        audit.permitsDormantParallelPage(
            58, 30, dormant.pages.first.sourcePage),
        isTrue);
    expect(
        audit.permitsDormantParallelPage(
            58, 16, process.pages.first.sourcePage),
        isFalse);
  });

  test(
      'an executable exemption cannot hide a write to a cohabiting dormant guard',
      () async {
    final input = await createInventoryControllerInput(
        dormantDevice: true, processWritesDormantGuard: true);
    final process = input.analysis.eventAt(58, 16)!;
    expect(process.isQuarantined, isFalse);
    final audit = SourceParallelDormancyAuditor.forProject(input.source,
            profile: input.analysis.profile)
        .audit(activeSourceMapIds: {
      58
    }, executablePageReferences: {
      process.pages.first.rawDataRef!.id.value,
    });
    expect(audit.isQualified, isFalse);
    expect(
        audit.refusals, contains('sourceDormancyControllerWriterExecutable'));
    final dormant = input.analysis.eventAt(58, 30)!;
    expect(
        audit.permitsDormantParallelPage(
            58, 30, dormant.pages.first.sourcePage),
        isFalse);
  });

  test('typed pokedex foreign writes remain in the dormant guard closure',
      () async {
    final input = await createInventoryControllerInput(
        dormantDevice: true, localWriter: 'pokedexDormant');
    final writer = input.analysis.eventAt(58, 20)!;
    expect(writer.isQuarantined, isFalse,
        reason:
            '${writer.pages.expand((page) => page.diagnostics).map((diagnostic) => diagnostic.toJson()).toList()}');
    final reward = writer.pages.first.body.nodes.single;
    expect(reward, isA<SourcePokedexRewardProgramNode>());
    expect((reward as SourcePokedexRewardProgramNode).foreignRewardFactIds,
        contains(endsWith(':map:58:event:30:self:C')));
    final process = input.analysis.eventAt(58, 16)!;
    final audit = SourceParallelDormancyAuditor.forProject(input.source,
            profile: input.analysis.profile)
        .audit(activeSourceMapIds: {
      58
    }, executablePageReferences: {
      process.pages.first.rawDataRef!.id.value,
    });
    expect(audit.isQualified, isFalse);
    expect(
        audit.refusals, contains('sourceDormancyControllerWriterExecutable'));
    expect(
        (audit.toJson()['nativeSourceWritesToControllerGuards'] as List),
        contains(predicate<Map>((write) =>
            (write['factId'] as String).endsWith(':map:58:event:30:self:C'))));
  });

  for (final invalidReference in [
    'blank',
    'terminal',
    'outsideScope',
    'quarantined',
  ]) {
    test('dormancy rejects an $invalidReference executable page exemption',
        () async {
      final input = await createInventoryControllerInput(
          dormantDevice: true, secondMapController: true);
      final process = input.analysis.eventAt(58, 16)!;
      final invalid = switch (invalidReference) {
        'blank' => '',
        'terminal' => process.pages.last.rawDataRef!.id.value,
        'quarantined' =>
          input.analysis.eventAt(58, 30)!.pages.first.rawDataRef!.id.value,
        _ => input.analysis.eventAt(200, 29)!.pages.first.rawDataRef!.id.value,
      };
      final audit = SourceParallelDormancyAuditor.forProject(input.source,
              profile: input.analysis.profile)
          .audit(activeSourceMapIds: {
        58
      }, executablePageReferences: {
        process.pages.first.rawDataRef!.id.value,
        invalid,
      });
      expect(audit.isQualified, isFalse);
    });
  }
}
