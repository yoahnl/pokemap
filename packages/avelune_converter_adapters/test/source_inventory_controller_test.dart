import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_inventory_controller_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

typedef InventoryControllerInput = ({
  NormalizedSourceProject source,
  LiteralFixtureFiles files,
  SourceEventAnalysis analysis,
  Map<String, SourceEventItemBinding> items,
  Map<int, MapData> maps,
});

Future<InventoryControllerInput> createInventoryControllerInput({
  String defect = '',
  String localWriter = '',
}) async {
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
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
      'PBS/items.txt': utf8.encode('[SECRETKEY]\nName = Secret Key\n'
          'NamePlural = Secret Keys\nPocket = 8\nPrice = 0\nFlags = KeyItem\n'
          'Consumable = false\nDescription = A key.\n'),
      'Data/items.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol('SECRETKEY'):
            const LiteralFixtureObject('GameData::Item', {
          '@id': LiteralFixtureSymbol('SECRETKEY'),
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
        1: const [
          LiteralFixtureEventCommand(355, ['pbReceiveItem(:SECRETKEY)'])
        ],
    },
    maps: [
      LiteralFixtureMap(id: 58, width: 5, height: 5, layers: [
        List.filled(25, 384),
        List.filled(25, 0),
        List.filled(25, 0),
      ], events: [
        if (defect != 'targetMissing')
          const LiteralFixtureEvent(
              id: 11,
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
            id: 16,
            name: 'Door controller',
            x: 2,
            y: 2,
            pages: [
              LiteralFixtureEventPage(trigger: 4, commands: [
                LiteralFixtureEventCommand(111, [
                  12,
                  defect == 'unknownCondition'
                      ? r'$bag.quantity(:SECRETKEY)>0 && arbitrary()'
                      : r'$bag.quantity(:SECRETKEY)>0'
                ]),
                LiteralFixtureEventCommand(
                    355,
                    [
                      defect == 'foreignReset'
                          ? 'pbSetSelfSwitch(11,"A",false)'
                          : 'pbSetSelfSwitch(11,"A",true)'
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
          const LiteralFixtureEvent(
              id: 17,
              name: 'Second controller',
              x: 3,
              y: 2,
              pages: [
                LiteralFixtureEventPage(trigger: 4, commands: [
                  LiteralFixtureEventCommand(
                      111, [12, r'$bag.quantity(:SECRETKEY)>0']),
                  LiteralFixtureEventCommand(
                      355, ['pbSetSelfSwitch(11,"A",true)'],
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
        if (localWriter.isNotEmpty)
          LiteralFixtureEvent(id: 20, x: 4, y: 4, pages: [
            LiteralFixtureEventPage(commands: [
              if (localWriter == 'quarantinedGive')
                const LiteralFixtureEventCommand(355, ['unknown()']),
              if (localWriter == 'commonEvent')
                const LiteralFixtureEventCommand(117, [1])
              else if (const ['guardTrue', 'guardFalse'].contains(localWriter))
                LiteralFixtureEventCommand(355,
                    ['pbSetSelfSwitch(16,"A",${localWriter == 'guardTrue'})'])
              else
                const LiteralFixtureEventCommand(
                    355, ['pbReceiveItem(:SECRETKEY)']),
              if (localWriter == 'sameMapWarp')
                const LiteralFixtureEventCommand(201, [0, 58, 1, 1, 2, 1]),
              const LiteralFixtureEventCommand(0, []),
            ]),
          ]),
      ]),
      LiteralFixtureMap(id: 200, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(commands: [
            LiteralFixtureEventCommand(355, ['pbReceiveItem(:SECRETKEY)']),
            LiteralFixtureEventCommand(0, []),
          ]),
        ]),
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
  expect(source.canPlan, isTrue);
  expect(analysis.profile.isQualified, isTrue);
  final items = await const SourceEventItemBindingResolver().read(
    snapshot: snapshot,
    files: files,
    symbols: ['SECRETKEY'],
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
    expect(program.toJson()['activation'], 'mapEnter');
    expect(program.toJson()['sourceItemSymbol'], 'SECRETKEY');
  });

  test(
      'inventory controller projects a finite map-enter scene and no parallel loop',
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
            NarrativeEventSourceKind.mapEnter)
        .toList();
    expect(records, hasLength(1));
    final scene = projected.scenes.singleWhere(
        (scene) => scene.id == records.single.definitionOrNull!.sceneId);
    final serialized = jsonEncode(scene.toJson());
    expect(serialized, contains('inventoryItem'));
    expect(serialized, contains(input.items['SECRETKEY']!.definition.id));
    expect(serialized, isNot(contains('actorRoute')));
    expect(records.single.definitionOrNull!.conditionExpression, isNotNull);
  });

  for (final defect in [
    'unknownCondition',
    'foreignReset',
    'ownReset',
    'falseBranch',
    'extraEffect',
    'openEffect',
    'targetMissing',
    'multipleControllers'
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
  for (final writer in [
    'give',
    'quarantinedGive',
    'commonEvent',
    'sameMapWarp'
  ]) {
    test('inventory controller refuses acquisition during the visit: $writer',
        () async {
      final input = await createInventoryControllerInput(localWriter: writer);
      expect(
          sourceInventoryControllerPrograms(
              source: input.source, analysis: input.analysis),
          isEmpty);
    });
  }
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
      'inventory controller cannot hide a local acquisition by trimming supplied analysis',
      () async {
    final input = await createInventoryControllerInput(localWriter: 'give');
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
}
