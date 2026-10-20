import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

const gymCases = [
  ('Brock', 11, 51, 'TM100'), ('Misty', 12, 52, 'TM089'),
  ('Surge', 13, 53, 'TM098'), ('Erika', 14, 54, 'TM065'),
  ('Koga', 15, 55, 'TM006'), ('Sabrina', 16, 56, 'TM090'),
];

Future<NormalizedSourceProject> gymSource((String, int, int, String) gym,
    {void Function(List<TrainerRubyObject>)? mutate}) => trainerSource(
    eventName: 'Gym leader ${gym.$1}',
    switchNames: List.generate(60, (id) => 'Flag $id'),
    variableNames: List.generate(40, (id) => 'Variable $id'),
    mutate: (pages) {
      pages.first.fields['@trigger'] = 0;
      pages.first.fields['@list'] = [
        trainerCommand(108, ['Gym battle.']),
        trainerCommand(101, ['Welcome.']),
        trainerCommand(355, ['pbTrainerIntro(:FRLG_LEADER_${gym.$1})']),
        trainerCommand(101, ['Ready?']),
        trainerCommand(108, ['EndSpeech: Good game!']),
        trainerCommand(111, [12, 'TrainerBattle.start(:FRLG_LEADER_${gym.$1}, "${gym.$1}")']),
        trainerCommand(355, ['\$player.badges[${gym.$2}]=true'], indent: 1),
        trainerCommand(101, [r'\PN received the badge!'], indent: 1),
        trainerCommand(249, [TrainerRubyObject('RPG::AudioFile', {
          '@name': 'FRLG Fanfare - Badge (Fanfare! Badge Obtained)',
          '@volume': 100, '@pitch': 100,
        })], indent: 1),
        trainerCommand(210, [], indent: 1),
        trainerCommand(101, ['Take this TM.'], indent: 1),
        trainerCommand(355, ['pbReceiveItem(:${gym.$4})'], indent: 1),
        trainerCommand(101, ['It teaches a move.'], indent: 1),
        trainerCommand(122, [30, 30, 1, 0, 1], indent: 1),
        trainerCommand(121, [gym.$3, gym.$3, 0], indent: 1),
        trainerCommand(0, [], indent: 1),
        trainerCommand(412, []), trainerCommand(355, ['pbTrainerEnd']),
        trainerCommand(0, []),
      ];
      final condition = pages.last.fields['@condition'] as TrainerRubyObject;
      condition.fields['@self_switch_valid'] = false;
      condition.fields['@switch1_valid'] = true;
      condition.fields['@switch1_id'] = gym.$3;
      mutate?.call(pages);
    });

Future<NormalizedSourceProject> extendedGymSource(String name,
    {void Function(List<TrainerRubyObject>)? mutate}) {
  final gym = name == 'Blaine' ? ('Blaine', 17, 57, 'TM038') : ('Giovanni', 18, 58, 'TM026');
  TrainerRubyUserDefined tone(double value) {
    final data = ByteData(32);
    for (var i = 0; i < 3; i++) { data.setFloat64(i * 8, value, Endian.little); }
    return TrainerRubyUserDefined('Tone', data.buffer.asUint8List());
  }
  return gymSource(gym, mutate: (pages) {
    final after = pages[1].fields['@list'] as List<TrainerRubyObject>;
    if (name == 'Blaine') {
      after.insertAll(1, [for (final expected in [5, -1]) ...[
        trainerCommand(111, [1, 38, 0, expected, 0]),
        trainerCommand(101, ['A complete memory $expected.'], indent: 1),
        trainerCommand(0, [], indent: 1), trainerCommand(412, []),
      ]]);
    } else {
      after.removeRange(1, after.length);
      after.addAll([
        trainerCommand(250, [TrainerRubyObject('RPG::AudioFile', {
          '@name': 'Exit Door', '@volume': 80, '@pitch': 100})]),
        trainerCommand(223, [tone(-255), 6]), trainerCommand(106, [8]),
        trainerCommand(123, ['A', 0]), trainerCommand(223, [tone(0), 6]),
        trainerCommand(0, []),
      ]);
      for (final letter in ['A', 'B']) {
        final page = trainerPages().last;
        (page.fields['@condition'] as TrainerRubyObject).fields['@self_switch_ch'] = letter;
        (page.fields['@graphic'] as TrainerRubyObject).fields['@character_name'] = '';
        page.fields['@through'] = true;
        page.fields['@list'] = letter == 'A' ? [
          trainerCommand(111, [12, 'pbItemBall(:MACHOBRACE)']),
          trainerCommand(123, ['B', 0], indent: 1), trainerCommand(0, [], indent: 1),
          trainerCommand(412, []), trainerCommand(0, []),
        ] : [trainerCommand(0, [])];
        pages.add(page);
      }
    }
    mutate?.call(pages);
  });
}

void main() {
  for (final name in ['Blaine', 'Giovanni']) {
    test('recognizes complete multistage gym $name with raw stage binding', () async {
      final source = await extendedGymSource(name);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.events.single;
      expect(event.isQuarantined, isFalse);
      final programs = event.pages.map((p) => p.body.nodes.single as SourceTrainerProgramNode).toList();
      expect(programs.first.gymLeader!.sourceBadgeIndex, name == 'Blaine' ? 17 : 18);
      expect(programs[1].gymStageBody, isNotNull);
      expect(programs[1].gymStage, name == 'Blaine'
          ? SourceGymLeaderStage.afterVictory : SourceGymLeaderStage.departure);
      if (name == 'Blaine') {
        expect(programs[1].gymStageBody!.nodes.whereType<SourceConditionalNode>()
            .map((n) => n.condition.minimum).toList(), [5, -1]);
      } else {
        expect(programs[2].gymStage, SourceGymLeaderStage.hiddenPickup);
        expect(programs[3].gymStage, SourceGymLeaderStage.removed);
        expect(programs[3].gymStageBody!.nodes, isEmpty);
      }
      for (final program in programs) {
        expect(program.isBoundToSourceEvent(source: source, profile: analysis.profile,
            sourceMapId: 417, event: source.maps.single.map.events.single), isTrue);
      }
    });
  }
  for (final mutation in ['extraBranchEffect', 'wrongBranchVariable', 'wrongBranchValue',
    'missingDeparture', 'wrongFade', 'wrongPickupSwitch', 'wrongPickup', 'visibleHiddenPage', 'wrongRemovedCondition']) {
    test('rejects entire extended gym for $mutation', () async {
      final isBlaine = mutation.startsWith('extra') || mutation.startsWith('wrongBranch');
      final source = await extendedGymSource(isBlaine ? 'Blaine' : 'Giovanni', mutate: (pages) {
        final after = pages[1].fields['@list'] as List;
        switch (mutation) {
          case 'extraBranchEffect': after.insert(3, trainerCommand(123, ['A', 0], indent: 1));
          case 'wrongBranchVariable': after[1] = trainerCommand(111, [1, 39, 0, 5, 0]);
          case 'wrongBranchValue': after[1] = trainerCommand(111, [1, 38, 0, 6, 0]);
          case 'missingDeparture': after.removeAt(4);
          case 'wrongFade': (after[2] as TrainerRubyObject).fields['@parameters'] = [0, 6];
          case 'wrongPickupSwitch': (pages[2].fields['@list'] as List)[1] = trainerCommand(123, ['A', 0], indent: 1);
          case 'wrongPickup': (pages[2].fields['@list'] as List)[0] = trainerCommand(111, [12, 'pbItemBall(:POTION)']);
          case 'visibleHiddenPage': (pages[2].fields['@graphic'] as TrainerRubyObject).fields['@character_name'] = 'trainer_BUGCATCHER';
          case 'wrongRemovedCondition': (pages[3].fields['@condition'] as TrainerRubyObject).fields['@self_switch_ch'] = 'C';
        }
      });
      expect(analyzeTrainerSource(source).events.single.pages
          .expand((p) => p.body.nodes).whereType<SourceTrainerProgramNode>(), isEmpty);
    });
  }
  test('gym recognition remains bound to raw identity, metadata and reward commands', () async {
    final source = await gymSource(gymCases.first);
    final analysis = analyzeTrainerSource(source);
    final program = analysis.events.single.pages.first.body.nodes.single as SourceTrainerProgramNode;
    for (final variant in ['name', 'position', 'command', 'trigger', 'condition']) {
      final json = jsonDecode(jsonEncode(source.maps.single.toJson())) as Map<String, dynamic>;
      final event = (json['map']['events'] as List).single as Map;
      final pages = event['pages'] as List;
      switch (variant) {
        case 'name': event['name'] = 'Another gym leader';
        case 'position': event['x'] = 0;
        case 'command': (pages[0]['commands'] as List)[6]['parameters'] = [r'$player.badges[12]=true'];
        case 'trigger': pages[0]['triggerCode'] = 2;
        case 'condition': pages[1]['conditionsDataRef'] = pages[0]['conditionsDataRef'];
      }
      expect(program.isBoundToSourceEvent(source: source, profile: analysis.profile,
          sourceMapId: 417, event: SourceMapIr.fromJson(json).map.events.single),
          isFalse, reason: variant);
    }
  });
  for (final gym in gymCases) {
    test('recognizes complete source gym ${gym.$1} without ordinary trainer grammar', () async {
      final source = await gymSource(gym);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.events.single;
      expect(event.isQuarantined, isFalse);
      final program = event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(program.gymLeader!.sourceBadgeIndex, gym.$2);
      expect(program.gymLeader!.completionSwitchId, gym.$3);
      expect(program.gymLeader!.rewardSymbol, gym.$4);
      expect(program.detectionDistance, 0);
      expect(program.victoryContinuation.nodes.first, isA<SourceGymBadgePresentationNode>());
      expect(program.victoryContinuation.nodes.whereType<SourcePickupNode>().single.sourceSymbol, gym.$4);
      expect(program.isBoundToSourceEvent(source: source, profile: analysis.profile,
          sourceMapId: 417, event: source.maps.single.map.events.single), isTrue);
      expect((event.pages.last.body.nodes.single as SourceTrainerProgramNode).kind,
          SourceTrainerProgramKind.afterWin);
    });
  }
  for (final mutation in ['badge', 'switch', 'tm', 'lossReward', 'extraEffect',
    'missingBarrier', 'repeatCounter', 'hybrid', 'extraPage', 'afterWinBranch']) {
    test('rejects incomplete or hybrid gym program $mutation', () async {
      final source = await gymSource(gymCases.first, mutate: (pages) {
        final commands = pages.first.fields['@list'] as List;
        switch (mutation) {
          case 'badge': commands[6] = trainerCommand(355, [r'$player.badges[12]=true'], indent: 1);
          case 'switch': commands[14] = trainerCommand(121, [52, 52, 0], indent: 1);
          case 'tm': commands[11] = trainerCommand(355, ['pbReceiveItem(:TM999)'], indent: 1);
          case 'lossReward': commands[6] = trainerCommand(355, [r'$player.badges[11]=true']);
          case 'extraEffect': commands.insert(13, trainerCommand(355, ['arbitrary()'], indent: 1));
          case 'missingBarrier': commands.removeAt(9);
          case 'repeatCounter': commands.insert(14, trainerCommand(122, [30, 30, 1, 0, 1], indent: 1));
          case 'hybrid': commands[14] = trainerCommand(123, ['A', 0], indent: 1);
          case 'extraPage': pages.add(trainerPages().last);
          case 'afterWinBranch': (pages.last.fields['@list'] as List).insert(1,
              trainerCommand(111, [1, 38, 0, 5, 0]));
        }
      });
      expect(analyzeTrainerSource(source).events.single.pages.first.body.nodes
          .whereType<SourceTrainerProgramNode>(), isEmpty);
    });
  }
}
