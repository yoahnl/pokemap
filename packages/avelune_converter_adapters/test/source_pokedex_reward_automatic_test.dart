import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Object? _marshal(Object? value) => switch (value) {
      List() => value.map(_marshal).toList(),
      Map() when value.containsKey('__class__') =>
        LiteralFixtureObject(value['__class__'] as String, {
          for (final entry in value.entries.where((e) => e.key != '__class__'))
            '@${entry.key}': _marshal(entry.value)
        }),
      _ => value,
    };

Future<SourceEventDefinition> _analyze(
    {bool machine = false, String defect = ''}) async {
  final bindings = jsonDecode(await File(
          '../avelune_converter_core/test/fixtures/synthetic_declared_programs.json')
      .readAsString()) as List;
  final binding = bindings
      .cast<Map>()
      .singleWhere((row) => row['family'] == 'pokedexReward');
  final pages = (binding['pages'] as Map).values.cast<Map>().toList();
  final commands = (pages.first['list'] as List).cast<Map>();
  if (machine) {
    commands[13]['parameters'] = [12, r'!$bag.has?(:HM05)'];
    commands[14] = {
      'code': 355,
      'indent': 3,
      'parameters': ['pbReceiveItem(:HM05)']
    };
    commands.removeRange(15, 18);
    commands.insert(15, {'code': 0, 'indent': 3, 'parameters': []});
    commands.insert(commands.indexWhere((c) => c['code'] == 209), {
      'code': 355,
      'indent': 2,
      'parameters': [r'$game_self_switches[[27,31,"A"]]=true']
    });
    (commands[10]['parameters'] as List)[3] = 10;
  }
  if (defect == 'unknown') {
    commands.insert(0, {
      'code': 355,
      'indent': 0,
      'parameters': ['Kernel.eval("x")']
    });
  }
  if (defect == 'threshold') (commands[10]['parameters'] as List)[1] = 99;
  if (defect == 'grantMismatch') {
    commands.singleWhere((c) =>
        c['code'] == 355 &&
        (c['parameters'] as List).single.toString().startsWith(
            'pbReceiveItem'))['parameters'] = ['pbReceiveItem(:HM04)'];
  }
  if (defect == 'choice') {
    commands.singleWhere((c) => c['code'] == 102)['parameters'] = [
      ['Accept', 'Decline'],
      1
    ];
  }
  if (defect == 'foreignExpression') {
    commands.singleWhere((c) =>
        c['code'] == 355 &&
        (c['parameters'] as List)
            .single
            .toString()
            .startsWith(r'$game_self_switches'))['parameters'] = [
      r'$game_self_switches[[27,pbGet(31),"A"]]=true'
    ];
  }
  if (defect == 'seenDexMismatch') {
    commands.firstWhere((c) => c['code'] == 355)['parameters'] = [
      r'pbSet(6,$player.pokedex.seen_count(2))'
    ];
  }
  if (defect == 'rewardFactMismatch') {
    commands.singleWhere((c) => c['code'] == 123)['parameters'] = ['B', 0];
  }
  if (defect == 'facingRouteMismatch') {
    final parameters =
        commands.firstWhere((c) => c['code'] == 209)['parameters'] as List;
    ((parameters[1] as Map)['list'] as List).first['code'] = 24;
  }
  if (defect == 'thirdPage') pages.add(Map.from(pages.last));
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 75, width: 7, height: 7, layers: [
        List.filled(49, 384),
        List.filled(49, 0),
        List.filled(49, 0)
      ], events: [
        LiteralFixtureEvent(id: 3, x: 3, y: 3, name: 'Aide', pages: [
          for (final entry in pages.indexed)
            LiteralFixtureEventPage(
              characterName: 'Aide',
              selfSwitch: entry.$1 == 1 ? 'A' : null,
              moveType: machine ? 3 : 0,
              autonomousRouteCodes: const [24, 0],
              commands: [
                for (final c in entry.$2['list'] as List)
                  LiteralFixtureEventCommand(c['code'] as int,
                      (c['parameters'] as List).map(_marshal).toList(),
                      indent: c['indent'] as int)
              ],
            ),
        ]),
      ])
    ],
  );
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {75},
      includeEventSystem: true,
      interpretationProfile: syntheticSourceInterpretationProfile);
  return SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze()
      .eventAt(75, 3)!;
}

void main() {
  test('ordinary dex reward is discovered without a declared event template',
      () async {
    final event = await _analyze();
    expect(
        event.pages.first.body.nodes
            .whereType<SourcePokedexRewardProgramNode>(),
        hasLength(1));
    final node =
        event.pages.first.body.nodes.single as SourcePokedexRewardProgramNode;
    expect(node.declaredProgram.automaticallyDiscovered, isTrue);
    expect(node.minimumCount, 3);
    expect(node.pickup!.sourceSymbol, 'TOKEN');
  });
  test('machine dex reward retains threshold and exact foreign self switch',
      () async {
    final event = await _analyze(machine: true);
    expect(
        event.pages.first.body.nodes
            .whereType<SourcePokedexRewardProgramNode>(),
        hasLength(1));
    final node =
        event.pages.first.body.nodes.single as SourcePokedexRewardProgramNode;
    expect(node.minimumCount, 10);
    expect(node.pickup!.sourceSymbol, 'HM05');
    expect(node.toJson()['skipGrantWhenOwned'], isTrue);
    expect(node.toJson()['foreignRewardFactIds'], hasLength(1));
  });
  for (final defect in [
    'unknown',
    'threshold',
    'grantMismatch',
    'choice',
    'foreignExpression',
    'seenDexMismatch',
    'rewardFactMismatch',
    'facingRouteMismatch',
    'thirdPage'
  ]) {
    test('closed dex reward refuses $defect', () async {
      final event = await _analyze(machine: true, defect: defect);
      expect(
          event.pages
              .expand((p) => p.body.nodes)
              .whereType<SourcePokedexRewardProgramNode>(),
          isEmpty);
    });
  }
}
