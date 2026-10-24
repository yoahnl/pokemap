import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import '../source_inventory_controller_test.dart'
    show createInventoryControllerInput;
import '../std08_presentation_player_fixture_test.dart'
    show std08PresentationFixture;
import 'literal_tile_fixture.dart';
import 'native_trainer_fixture.dart';

import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart'
    show syntheticInterpretationSection;

final class Std09OriginalSourceFixture {
  const Std09OriginalSourceFixture({
    required this.root,
    required this.namespace,
    required this.profile,
    required this.sourceHashes,
    required this.engineProvenance,
  });

  final String root;
  final String namespace;
  final SourceInterpretationProfile profile;
  final Map<String, Sha256Hash> sourceHashes;
  final Map<String, Object?> engineProvenance;

  static Future<Std09OriginalSourceFixture> create(String root,
      {required String namespace,
      bool missingPicture = false,
      bool withPokemon = true}) async {
    final presentation =
        await std08PresentationFixture(missingPicture: missingPicture);
    final inventory = await createInventoryControllerInput(
        localWriter: 'give', playerFixture: true);
    final engine =
        await _trainerEngine(inventory.source.interpretationProfile!);
    final roster = (type: 'YOUNGSTER', name: 'Original Scout', version: 0);
    final trainer = nativeTrainerFixtureEvent(roster, 6);
    final fixture = await LiteralTileFixture.create(
      namespace: namespace,
      scriptsBytes: presentation.sourceBytes['Data/Scripts.rxdata'],
      interpretationProfile: inventory.source.interpretationProfile,
      includeEventSystem: true,
      switchNames: const [null, 's:tsOff?("A")'],
      commonEvents: const {
        1: [
          LiteralFixtureEventCommand(101, ['Original common event']),
          LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9]),
          LiteralFixtureEventCommand(115, []),
          LiteralFixtureEventCommand(101, ['Unreachable common tail']),
        ],
      },
      maps: [
        LiteralFixtureMap(id: 41, width: 12, height: 8, layers: [
          List.filled(96, 384),
          List.filled(96, 0),
          List.filled(96, 0),
        ], events: [
          const LiteralFixtureEvent(
              id: 1,
              x: 2,
              y: 3,
              name: 'Original guide',
              pages: [
                LiteralFixtureEventPage(characterName: 'Player', commands: [
                  LiteralFixtureEventCommand(
                      101, ['Original qualification guide']),
                  LiteralFixtureEventCommand(102, [
                    ['Continue', 'Cancel'],
                    2
                  ]),
                  LiteralFixtureEventCommand(402, [0, 'Continue']),
                  LiteralFixtureEventCommand(117, [1], indent: 1),
                  LiteralFixtureEventCommand(402, [1, 'Cancel']),
                  LiteralFixtureEventCommand(101, ['Cancelled safely'],
                      indent: 1),
                  LiteralFixtureEventCommand(404, []),
                  LiteralFixtureEventCommand(0, []),
                ]),
                LiteralFixtureEventPage(
                    characterName: 'Player',
                    variableId: 1,
                    variableThreshold: 9,
                    through: true,
                    commands: [
                      LiteralFixtureEventCommand(
                          101, ['Common variable persisted']),
                      LiteralFixtureEventCommand(0, []),
                    ]),
              ]),
          const LiteralFixtureEvent(
              id: 2,
              x: 4,
              y: 2,
              name: 'Original key donor',
              pages: [
                LiteralFixtureEventPage(characterName: 'Player', commands: [
                  LiteralFixtureEventCommand(
                      355, ['pbReceiveItem(:SECRETKEY)']),
                  LiteralFixtureEventCommand(123, ['A', 0]),
                  LiteralFixtureEventCommand(0, []),
                ]),
                LiteralFixtureEventPage(
                    selfSwitch: 'A',
                    through: true,
                    commands: [
                      LiteralFixtureEventCommand(0, []),
                    ]),
              ]),
          const LiteralFixtureEvent(
              id: 3,
              x: 6,
              y: 2,
              name: 'Original conditional passage',
              pages: [
                LiteralFixtureEventPage(characterName: 'Player', commands: [
                  LiteralFixtureEventCommand(
                      101, ['The original passage is closed']),
                  LiteralFixtureEventCommand(0, []),
                ]),
                LiteralFixtureEventPage(
                    selfSwitch: 'A',
                    through: true,
                    trigger: 1,
                    commands: [
                      LiteralFixtureEventCommand(201, [0, 83, 2, 2, 2, 1]),
                      LiteralFixtureEventCommand(0, []),
                    ]),
              ]),
          const LiteralFixtureEvent(
              id: 4,
              x: 6,
              y: 1,
              name: 'Original parallel owner',
              pages: [
                LiteralFixtureEventPage(trigger: 4, commands: [
                  LiteralFixtureEventCommand(
                      111, [12, r'$bag.quantity(:SECRETKEY)>0']),
                  LiteralFixtureEventCommand(
                      355, ['pbSetSelfSwitch(3,"A",true)'],
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
          if (withPokemon)
            const LiteralFixtureEvent(
                id: 5,
                x: 3,
                y: 5,
                name: 'Original partner gift',
                pages: [
                  LiteralFixtureEventPage(characterName: 'Player', commands: [
                    LiteralFixtureEventCommand(355, ['pbAddPokemon(:ARBOK,5)']),
                    LiteralFixtureEventCommand(123, ['A', 0]),
                    LiteralFixtureEventCommand(0, []),
                  ]),
                  LiteralFixtureEventPage(
                      characterName: 'Player',
                      selfSwitch: 'A',
                      commands: [
                        LiteralFixtureEventCommand(0, []),
                      ]),
                ]),
          if (withPokemon)
            LiteralFixtureEvent(
                id: trainer.id,
                x: 8,
                y: 5,
                name: trainer.name,
                pages: trainer.pages),
          const LiteralFixtureEvent(
              id: 7,
              x: 9,
              y: 5,
              name: 'Original opaque negative',
              pages: [
                LiteralFixtureEventPage(characterName: 'Player', commands: [
                  LiteralFixtureEventCommand(101, ['Must remain quarantined']),
                  LiteralFixtureEventCommand(355, ['originalUnknownPlugin()']),
                  LiteralFixtureEventCommand(0, []),
                ]),
              ]),
          const LiteralFixtureEvent(
              id: 8,
              x: 10,
              y: 2,
              name: 'Original touch trigger',
              pages: [
                LiteralFixtureEventPage(trigger: 1, through: true, commands: [
                  LiteralFixtureEventCommand(101, ['Original touch feedback']),
                  LiteralFixtureEventCommand(0, []),
                ]),
              ]),
        ]),
        LiteralFixtureMap(id: 83),
      ],
    );
    final sourceBytes = <String, List<int>>{
      ...presentation.sourceBytes,
      ...inventory.files.bytes,
      ...fixture.sourceBytes,
      ...nativeTrainerFixtureFiles([roster],
          team: [(species: 'RATTATA', level: 3)]),
      'Graphics/Characters/OriginalTrainer.png': literalFixtureAtlas(),
      'PBS/pokemon.txt': utf8.encode(
          '[ARBOK]\nName = Arbok\nTypes = POISON\nBaseStats = 60,95,69,80,65,79\nAbilities = INTIMIDATE\n[RATTATA]\nName = Rattata\nTypes = NORMAL\nBaseStats = 30,56,35,72,25,35\nAbilities = RUNAWAY\nEvolutions = RATICATE,Level,20\n[RATICATE]\nName = Raticate\nTypes = NORMAL\nBaseStats = 55,81,60,97,50,70\nAbilities = RUNAWAY\n'),
      'PBS/types.txt':
          utf8.encode('[POISON]\nName = Poison\n[NORMAL]\nName = Normal\n'),
      'PBS/abilities.txt': utf8.encode(
          '[INTIMIDATE]\nName = Intimidate\nDescription = Original catalogue description.\n[RUNAWAY]\nName = Run Away\nDescription = Original catalogue description.\n'),
      'Data/species.dat': literalFixtureMarshal({
        for (final symbol in ['ARBOK', 'RATTATA', 'RATICATE'])
          LiteralFixtureSymbol(symbol):
              LiteralFixtureObject('GameData::Species', {
            '@id': LiteralFixtureSymbol(symbol),
            '@species': LiteralFixtureSymbol(symbol),
            '@form': 0,
            '@real_name': switch (symbol) {
              'ARBOK' => 'Arbok',
              'RATTATA' => 'Rattata',
              _ => 'Raticate',
            },
          }),
      }),
      'Graphics/Pokemon/Front/RATTATA.png':
          inventory.files.bytes['Graphics/Pokemon/Front/ARBOK.png']!,
      'Graphics/Pokemon/Back/RATTATA.png':
          inventory.files.bytes['Graphics/Pokemon/Back/ARBOK.png']!,
      'Graphics/Pokemon/Front/RATICATE.png':
          inventory.files.bytes['Graphics/Pokemon/Front/ARBOK.png']!,
      'Graphics/Pokemon/Back/RATICATE.png':
          inventory.files.bytes['Graphics/Pokemon/Back/ARBOK.png']!,
      'Data/Map083.rxdata': presentation.sourceBytes['Data/Map083.rxdata']!,
      'Data/map_metadata.dat': literalFixtureMarshal({
        for (final mapId in [41, 83])
          mapId: LiteralFixtureObject('GameData::MapMetadata', {
            '@id': mapId,
            '@town_map_position': [1, 0, 0],
            '@real_name': '$namespace original map $mapId',
          }),
      }),
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
      'Data/Scripts.rxdata': engine.bytes,
    }..removeWhere((path, _) =>
        path == 'Data/Map058.rxdata' ||
        path == 'Data/Map200.rxdata' ||
        (!withPokemon &&
            (path.startsWith('Graphics/Pokemon/') ||
                path == 'Graphics/Characters/OriginalTrainer.png' ||
                const {
                  'PBS/pokemon.txt',
                  'PBS/pokemon_forms.txt',
                  'PBS/types.txt',
                  'PBS/abilities.txt',
                  'PBS/trainers.txt',
                  'PBS/trainer_types.txt',
                  'Data/species.dat',
                  'Data/trainers.dat',
                  'Data/trainer_types.dat',
                }.contains(path))));
    final hashes = <String, Sha256Hash>{};
    for (final entry in sourceBytes.entries) {
      final file = File('$root/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
      hashes[entry.key] = literalFixtureHash(entry.value);
    }
    return Std09OriginalSourceFixture(
        root: root,
        namespace: namespace,
        profile: engine.profile,
        engineProvenance: engine.provenance,
        sourceHashes: Map.unmodifiable(hashes));
  }
}

List<int> _marshalLength(int value) => value == 0
    ? [0]
    : value < 123
        ? [value + 5]
        : value < 256
            ? [1, value]
            : [2, value & 255, value >> 8];

List<int> _scriptRow(String name, List<int> compressed) {
  final label = utf8.encode(name);
  return [
    91,
    8,
    105,
    0,
    34,
    ..._marshalLength(label.length),
    ...label,
    34,
    ..._marshalLength(compressed.length),
    ...compressed
  ];
}

Future<
    ({
      List<int> bytes,
      SourceInterpretationProfile profile,
      Map<String, Object?> provenance
    })> _trainerEngine(SourceInterpretationProfile synthetic) async {
  final archivePath = Platform.environment['AVELUNE_STD09_ENGINE_ARCHIVE'];
  final syntheticBytes = [
    4,
    8,
    91,
    6,
    ..._scriptRow('Synthetic', zlib.encode(syntheticInterpretationSection))
  ];
  if (archivePath == null) {
    return (
      bytes: syntheticBytes,
      profile: synthetic,
      provenance: {
        'provider': 'originalSyntheticSource',
        'trainerDefeatOracleQualified': false,
      }
    );
  }
  final archive = File(archivePath);
  if (!archive.isAbsolute || await archive.length() > 8388608) {
    throw StateError(
        'STD09 engine archive requires a bounded explicit absolute file.');
  }
  final bytes = await archive.readAsBytes();
  final document = const MarshalDecoder().decode(bytes,
      sourcePath: archivePath,
      limits: const MarshalDecodeLimits(
          maxInputBytes: 8388608,
          maxNodes: 100000,
          maxObjects: 100000,
          maxStringBytes: 8388608,
          maxTotalStringBytes: 8388608));
  final root = document.node(document.rootId);
  final rows = <List<int>>[
    _scriptRow('Synthetic', zlib.encode(syntheticInterpretationSection))
  ];
  final sections = <String, Map<String, Object?>>{};
  for (final oracle in [
    (
      name: 'Battle',
      sha256:
          'd61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b',
      lines: [131, 134]
    ),
    (
      name: 'Overworld_BattleStarting',
      sha256:
          '7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04',
      lines: [492, 527]
    ),
  ]) {
    final sourceRow = root.elements.map(document.node).singleWhere((row) =>
        row.kind == MarshalKind.array &&
        row.elements.length == 3 &&
        document.node(row.elements[1]).text().text == oracle.name);
    final compressed = document.node(sourceRow.elements[2]).bytes!;
    final expanded = const BoundedZlibDecoder().decode(compressed,
        sourcePath: archivePath,
        limits: const ZlibDecodeLimits(
            maxInputBytes: 8388608, maxOutputBytes: 33554432));
    if (literalFixtureHash(expanded).value != oracle.sha256) {
      throw StateError('STD09 source engine oracle differs: ${oracle.name}.');
    }
    sections['events.${oracle.name}'] = {
      'index': rows.length,
      'name': oracle.name,
      'sha256': oracle.sha256,
      'lines': oracle.lines,
    };
    rows.add(_scriptRow(oracle.name, compressed));
  }
  final composed = [
    4,
    8,
    91,
    ..._marshalLength(rows.length),
    ...rows.expand((row) => row)
  ];
  final profile = SourceInterpretationProfile.fromJson({
    ...synthetic.toJson(),
    'profileId': 'std09-original-with-attested-trainer-engine',
    'scriptsArchive': {
      'relativePath': 'Data/Scripts.rxdata',
      'sha256': literalFixtureHash(composed).value
    },
    'sections': {...synthetic.sections, ...sections},
  });
  return (
    bytes: composed,
    profile: profile,
    provenance: {
      'provider': 'attestedInertSourceTrainerEngineSections',
      'sourceArchivePath': archivePath,
      'sourceArchiveSha256': literalFixtureHash(bytes).value,
      'composedArchiveSha256': literalFixtureHash(composed).value,
      'sections': sections,
      'sourceScriptsExecuted': 0,
      'mapsAndMedia': 'originalSyntheticFixtures',
    }
  );
}
