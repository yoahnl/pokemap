import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

Future<NormalizedSourceProject> rotatingTrainerSource({
  List<int> route = const [17, 18, 0],
  void Function(List<TrainerRubyObject>)? mutate,
}) =>
    trainerSource(
        mapId: 239,
        eventId: 5,
        trainerName: 'Bryce',
        eventName: 'Camper Bryce Trainer(3)',
        mutate: (pages) {
          for (final page in pages) {
            page.fields['@move_type'] = 3;
            page.fields['@move_route'] = trainerRoute([
              for (final code in route) trainerMove(code),
            ], repeat: true);
            final graphic = page.fields['@graphic'] as TrainerRubyObject;
            graphic.fields['@character_name'] = 'trainer_FRLG_CAMPER';
            graphic.fields['@direction'] = 4;
          }
          pages.first.fields['@list'] = [
            trainerCommand(355, ['pbTrainerIntro(:FRLG_CAMPER)']),
            trainerCommand(355, ['pbNoticePlayer(get_self)']),
            trainerCommand(
                101, [r"\bYou know, everything tastes great when you're out "]),
            trainerCommand(401, ['in the wild.']),
            trainerCommand(
                111, [12, 'TrainerBattle.start(:FRLG_CAMPER, "Bryce")']),
            trainerCommand(123, ['A', 0], indent: 1),
            trainerCommand(0, [], indent: 1),
            trainerCommand(412, []),
            trainerCommand(355, ['pbTrainerEnd']),
            trainerCommand(0, []),
          ];
          pages.last.fields['@list'] = [
            trainerCommand(
                101, [r'\bThe water in volcanic regions is delicious.']),
            trainerCommand(0, []),
          ];
          mutate?.call(pages);
        });

void main() {
  for (final route in [
    [17, 18, 0],
    [24, 0],
    [18, 19, 17, 16, 0],
  ]) {
    test('recognizes two-page no-comment trainer rotations $route', () async {
      final source = await rotatingTrainerSource(route: route);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(239, 5)!;
      expect(event.isQuarantined, isFalse);
      final before =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      final after =
          event.pages.last.body.nodes.single as SourceTrainerProgramNode;
      expect(before.trainerType, 'FRLG_CAMPER');
      expect(before.trainerName, 'Bryce');
      expect(before.sourceMoveType, 3);
      expect(before.detectionDistance, 3);
      expect(before.endSpeechComment, isNull);
      expect(before.challengeLines, [
        r"\bYou know, everything tastes great when you're out in the wild."
      ]);
      expect(before.toJson()['sourceBattleVictoryTextBinding'],
          'pbsTrainerLoseText');
      expect(
          before.toJson()['sourceDefeatedCondition'], 'battleOutcomeEquals1');
      final win =
          before.victoryContinuation.nodes.single as SourceSelfSwitchNode;
      expect(win.factId, before.defeatedFactId);
      expect(win.value, isTrue);
      expect(after.kind, SourceTrainerProgramKind.afterWin);
      expect(after.facesPlayerAfterDialogue, isFalse);
      expect(after.afterWinLines,
          [r'\bThe water in volcanic regions is delicious.']);
      for (final program in [before, after]) {
        expect(
            program.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 239,
                event: source.maps.single.map.events.single),
            isTrue);
      }
    });
  }

  for (final defect in [
    'walking',
    'jump',
    'relativeTurn',
    'towardPlayer',
    'opacity',
    'script',
    'emptyRoute',
    'nonterminalZero',
    'missingTerminal',
    'routeParameters',
    'skippable',
    'nonRepeating',
    'changedRoute',
    'changedSpeed',
    'mixedMoveTypes',
    'directionFix',
    'alwaysActiveAfter',
    'thirdPage',
    'postRoute',
    'extraVictoryEffect',
    'missingEnd',
    'unknownScript',
  ]) {
    test('refuses no-comment rotating trainer defect $defect', () async {
      final source = await rotatingTrainerSource(mutate: (pages) {
        final before = pages.first.fields['@list'] as List;
        final after = pages.last.fields['@list'] as List;
        for (final page in pages) {
          final route = page.fields['@move_route'] as TrainerRubyObject;
          final steps = route.fields['@list'] as List;
          switch (defect) {
            case 'walking':
              steps[0] = trainerMove(1);
            case 'jump':
              steps[0] = trainerMove(14);
            case 'relativeTurn':
              steps[0] = trainerMove(20);
            case 'towardPlayer':
              steps[0] = trainerMove(25);
            case 'opacity':
              steps[0] = trainerMove(42);
            case 'script':
              steps[0] = trainerMove(45);
            case 'emptyRoute':
              route.fields['@list'] = [trainerMove(0)];
            case 'nonterminalZero':
              steps.insert(0, trainerMove(0));
            case 'missingTerminal':
              steps.removeLast();
            case 'routeParameters':
              (steps.first as TrainerRubyObject).fields['@parameters'] = [1];
            case 'skippable':
              route.fields['@skippable'] = true;
            case 'nonRepeating':
              route.fields['@repeat'] = false;
            case 'directionFix':
              page.fields['@direction_fix'] = true;
          }
        }
        switch (defect) {
          case 'changedRoute':
            pages.last.fields['@move_route'] = trainerRoute(
                [trainerMove(16), trainerMove(17), trainerMove(0)],
                repeat: true);
          case 'changedSpeed':
            pages.last.fields['@move_speed'] = 4;
          case 'mixedMoveTypes':
            pages.last.fields['@move_type'] = 0;
          case 'alwaysActiveAfter':
            (pages.last.fields['@condition'] as TrainerRubyObject)
                .fields['@self_switch_valid'] = false;
          case 'thirdPage':
            pages.add(trainerPages().last);
          case 'postRoute':
            after.insertAll(1, <TrainerRubyObject>[
              trainerCommand(209, [
                0,
                trainerRoute([trainerMove(25), trainerMove(0)])
              ]),
              trainerCommand(509, [trainerMove(25)])
            ]);
          case 'extraVictoryEffect':
            before.insert(5, trainerCommand(122, [1, 1, 1, 0, 1], indent: 1));
          case 'missingEnd':
            before.removeAt(8);
          case 'unknownScript':
            before.insert(2, trainerCommand(355, ['customEffect()']));
        }
      });
      expect(
          analyzeTrainerSource(source)
              .eventAt(239, 5)!
              .pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }

  test('rotating trainer raw binding rejects normalized route and page forgery',
      () async {
    final source = await rotatingTrainerSource();
    final analysis = analyzeTrainerSource(source);
    final program = analysis.eventAt(239, 5)!.pages.first.body.nodes.single
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
              sourceMapId: 239,
              event: SourceMapIr.fromJson(json).map.events.single),
          isFalse,
          reason: defect);
    }
  });
}
