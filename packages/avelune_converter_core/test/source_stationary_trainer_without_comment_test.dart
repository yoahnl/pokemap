import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

const _cases = [
  (
    map: 239,
    event: 15,
    type: 'FRLG_FISHERMAN',
    name: 'Tommy',
    distance: 0,
    direction: 4,
    afterTrigger: 2,
    challenge: r"\bWait! Wait a second!\nI think I've hooked a big one!",
    after: [r'\bNot only did I lose, the big one got away from me, ', 'too!']
  ),
  (
    map: 301,
    event: 13,
    type: 'FRLG_JUGGLER',
    name: 'Edward',
    distance: 3,
    direction: 8,
    afterTrigger: 0,
    challenge: r"\bI'm practicing in secret so no one can see me.",
    after: [
      r"\bAs a performer, I don't want people to know about ",
      'the effort I put in.'
    ]
  ),
  (
    map: 303,
    event: 6,
    type: 'FRLG_HIKER',
    name: 'Daryl',
    distance: 2,
    direction: 2,
    afterTrigger: 0,
    challenge: r'\bA battle with you, so high up!',
    after: [r'\bExperience the joy of climbing!']
  ),
];

Future<NormalizedSourceProject> _source(int index,
    {void Function(List<TrainerRubyObject>)? mutate}) {
  final sample = _cases[index];
  return trainerSource(
      mapId: sample.map,
      eventId: sample.event,
      trainerName: sample.name,
      eventName: '${sample.name} Trainer(${sample.distance})',
      mutate: (pages) {
        for (final page in pages) {
          final graphic = page.fields['@graphic'] as TrainerRubyObject;
          graphic.fields['@character_name'] = 'trainer_${sample.type}';
          graphic.fields['@direction'] = sample.direction;
        }
        pages.first.fields['@list'] = [
          trainerCommand(355, ['pbTrainerIntro(:${sample.type})']),
          trainerCommand(355, ['pbNoticePlayer(get_self)']),
          trainerCommand(101, [sample.challenge]),
          trainerCommand(111,
              [12, 'TrainerBattle.start(:${sample.type}, "${sample.name}")']),
          trainerCommand(123, ['A', 0], indent: 1),
          trainerCommand(0, [], indent: 1),
          trainerCommand(412, []),
          trainerCommand(355, ['pbTrainerEnd']),
          trainerCommand(0, []),
        ];
        pages.last.fields['@trigger'] = sample.afterTrigger;
        pages.last.fields['@list'] = [
          trainerCommand(101, [sample.after.first]),
          for (final line in sample.after.skip(1)) trainerCommand(401, [line]),
          trainerCommand(0, []),
        ];
        mutate?.call(pages);
      });
}

void main() {
  for (var index = 0; index < _cases.length; index++) {
    final sample = _cases[index];
    test(
        'recognizes stationary ${sample.map}/${sample.event} without EndSpeech',
        () async {
      final source = await _source(index);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(sample.map, sample.event)!;
      expect(event.isQuarantined, isFalse);
      final encounter =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      final after =
          event.pages.last.body.nodes.single as SourceTrainerProgramNode;
      expect(encounter.trainerType, sample.type);
      expect(encounter.trainerName, sample.name);
      expect(encounter.trainerVersion, 0);
      expect(encounter.detectionDistance, sample.distance);
      expect(encounter.challengeLines, [sample.challenge]);
      expect(encounter.endSpeechComment, isNull);
      expect(encounter.toJson()['sourceBattleVictoryTextBinding'],
          'pbsTrainerLoseText');
      expect(encounter.toJson()['sourceDefeatedCondition'],
          'battleOutcomeEquals1');
      expect(encounter.victoryContinuation.nodes, hasLength(1));
      final victory =
          encounter.victoryContinuation.nodes.single as SourceSelfSwitchNode;
      expect(victory.factId, encounter.defeatedFactId);
      expect(victory.value, isTrue);
      expect(after.kind, SourceTrainerProgramKind.afterWin);
      expect(after.facesPlayerAfterDialogue, isFalse);
      expect(after.afterWinLines, [sample.after.join()]);
      expect(
          encounter.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: sample.map,
              event: source.maps.single.map.events.single),
          isTrue);
    });
  }

  for (final defect in [
    'autonomous',
    'movementChanges',
    'skippableStoredRoute',
    'alwaysActivePostPage',
    'thirdPage',
    'postRoute',
    'unknownScript',
    'introMismatch',
    'victoryOutsideBattle',
    'victoryFalse',
    'extraVictoryWrite',
    'extraAfterEffect',
    'missingEnd',
    'missingNotice',
    'unknownComment',
  ]) {
    test('refuses stationary no-comment trainer defect $defect', () async {
      final source = await _source(2, mutate: (pages) {
        final encounter = pages.first.fields['@list'] as List;
        final after = pages.last.fields['@list'] as List;
        switch (defect) {
          case 'autonomous':
            for (final page in pages) {
              page.fields['@move_type'] = 3;
            }
          case 'movementChanges':
            pages.last.fields['@move_type'] = 3;
          case 'skippableStoredRoute':
            for (final page in pages) {
              final route = trainerRoute([
                trainerMove(2),
                trainerMove(2),
                trainerMove(3),
                trainerMove(3),
                trainerMove(0),
              ], repeat: true);
              route.fields['@skippable'] = true;
              page.fields['@move_route'] = route;
            }
          case 'alwaysActivePostPage':
            (pages.last.fields['@condition'] as TrainerRubyObject)
                .fields['@self_switch_valid'] = false;
          case 'thirdPage':
            pages.add(trainerPages().last);
          case 'postRoute':
            after.insertAll(after.length - 1, <TrainerRubyObject>[
              trainerCommand(209, [
                0,
                trainerRoute([trainerMove(25), trainerMove(0)])
              ]),
              trainerCommand(509, [trainerMove(25)]),
            ]);
          case 'unknownScript':
            encounter.insert(2, trainerCommand(355, ['customEffect()']));
          case 'introMismatch':
            encounter[0] = trainerCommand(355, ['pbTrainerIntro(:OTHER)']);
          case 'victoryOutsideBattle':
            encounter.removeAt(4);
            encounter.insert(7, trainerCommand(123, ['A', 0]));
          case 'victoryFalse':
            encounter[4] = trainerCommand(123, ['A', 1], indent: 1);
          case 'extraVictoryWrite':
            encounter.insert(
                4, trainerCommand(122, [1, 1, 1, 0, 1], indent: 1));
          case 'extraAfterEffect':
            after.insert(1, trainerCommand(123, ['B', 0]));
          case 'missingEnd':
            encounter.removeAt(7);
          case 'missingNotice':
            encounter.removeAt(1);
          case 'unknownComment':
            encounter.insert(3, trainerCommand(108, ['Different annotation']));
        }
      });
      expect(
          analyzeTrainerSource(source)
              .eventAt(303, 6)!
              .pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }

  test('no-comment trainer binding rejects normalized/raw divergence',
      () async {
    final source = await _source(2);
    final analysis = analyzeTrainerSource(source);
    final program = analysis.eventAt(303, 6)!.pages.first.body.nodes.single
        as SourceTrainerProgramNode;
    for (final defect in ['text', 'position', 'conditionRef', 'commandIndex']) {
      final json = jsonDecode(jsonEncode(source.maps.single.toJson()))
          as Map<String, dynamic>;
      final event = (json['map']['events'] as List).single as Map;
      final pages = event['pages'] as List;
      switch (defect) {
        case 'text':
          pages[0]['commands'][2]['parameters'] = ['Forged challenge'];
        case 'position':
          event['x'] = 0;
        case 'conditionRef':
          pages[0]['conditionsDataRef'] = pages[1]['conditionsDataRef'];
        case 'commandIndex':
          pages[0]['commands'][2]['originalIndex'] = 99;
          pages[0]['commands'][2]['sourceLocator']['commandIndex'] = 99;
      }
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 303,
              event: SourceMapIr.fromJson(json).map.events.single),
          isFalse,
          reason: defect);
    }
  });
}
