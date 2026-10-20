import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

Future<NormalizedSourceProject> _source({
  List<int> inactiveRoute = const [24, 0],
  void Function(List<TrainerRubyObject>)? mutate,
}) =>
    trainerSource(
        mapId: 94,
        eventId: 7,
        eventName: 'Supernerd Aidan Trainer(4)',
        trainerName: 'Aidan',
        mutate: (pages) {
          pages.first.fields['@move_route'] = trainerRoute([
            for (final code in inactiveRoute) trainerMove(code),
          ], repeat: true);
          mutate?.call(pages);
        });

void main() {
  for (final route in [
    [24, 0],
    [17, 16, 0],
    [19, 18, 17, 16, 24, 0],
  ]) {
    test('stationary trainer retains unequal inactive rotation routes $route',
        () async {
      final source = await _source(inactiveRoute: route);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(94, 7)!;
      expect(event.isQuarantined, isFalse);
      expect(event.pages, hasLength(2));
      final programs = event.pages
          .expand((page) => page.body.nodes)
          .whereType<SourceTrainerProgramNode>()
          .toList();
      expect(programs, hasLength(2));
      final encounter = programs.first, after = programs.last;
      expect(encounter.sourceMoveType, 0);
      expect(after.sourceMoveType, 0);
      expect(encounter.kind, SourceTrainerProgramKind.encounter);
      expect(after.kind, SourceTrainerProgramKind.afterWin);
      expect(after.facesPlayerAfterDialogue, isTrue);
      expect(encounter.trainerName, 'Aidan');
      expect(encounter.detectionDistance, 4);
      expect(encounter.victoryContinuation.nodes, hasLength(1));
      final win =
          encounter.victoryContinuation.nodes.single as SourceSelfSwitchNode;
      expect(win.factId, encounter.defeatedFactId);
      expect(win.letter, 'A');
      expect(win.value, isTrue);
      expect(encounter.toJson()['sourceDefeatedCondition'],
          'battleOutcomeEquals1');
      for (final program in programs) {
        expect(
            program.isBoundToSourceEvent(
                source: source,
                profile: analysis.profile,
                sourceMapId: 94,
                event: source.maps.single.map.events.single),
            isTrue);
      }
    });
  }

  for (final route in [
    [24, 0],
    [17, 16, 0],
  ]) {
    test('stationary trainer retains inactive frequency 4 to 3 $route',
        () async {
      final source = await _source(
          inactiveRoute: route,
          mutate: (pages) => pages.first.fields['@move_frequency'] = 4);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(94, 7)!;
      expect(event.isQuarantined, isFalse);
      expect(event.pages.map((page) => page.graphic!.moveFrequency), [4, 3]);
      final program =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 94,
              event: source.maps.single.map.events.single),
          isTrue);
      final sameFrequency = await _source(inactiveRoute: route);
      final other = analyzeTrainerSource(sameFrequency)
          .eventAt(94, 7)!
          .pages
          .first
          .body
          .nodes
          .single as SourceTrainerProgramNode;
      expect(program.templateHash, isNot(other.templateHash));
    });
  }

  for (final defect in [
    'firstRandomMovement',
    'secondCustomMovement',
    'bothCustomMovement',
    'unknownMovementType',
    'inactiveWalking',
    'inactiveScript',
    'inactiveRelativeTurn',
    'skippable',
    'nonRepeating',
    'missingTerminal',
    'nonterminalZero',
    'routeParameter',
    'routeExtraField',
    'changedSpeed',
    'randomMovementFrequency',
    'customMovementFrequency',
    'changedDirection',
    'bodyFacingChanged',
    'changedCondition',
    'extraVictoryEffect',
    'thirdPage',
  ]) {
    test('inactive route equivalence refuses $defect', () async {
      final source = await _source(mutate: (pages) {
        final route = pages.first.fields['@move_route'] as TrainerRubyObject;
        final steps = route.fields['@list'] as List;
        switch (defect) {
          case 'firstRandomMovement':
            pages.first.fields['@move_type'] = 1;
          case 'secondCustomMovement':
            pages.last.fields['@move_type'] = 3;
          case 'bothCustomMovement':
            for (final page in pages) {
              page.fields['@move_type'] = 3;
            }
          case 'unknownMovementType':
            for (final page in pages) {
              page.fields['@move_type'] = 7;
            }
          case 'inactiveWalking':
            steps[0] = trainerMove(1);
          case 'inactiveScript':
            steps[0] = trainerMove(45)
              ..fields['@parameters'] = ['customEffect()'];
          case 'inactiveRelativeTurn':
            steps[0] = trainerMove(25);
          case 'skippable':
            route.fields['@skippable'] = true;
          case 'nonRepeating':
            route.fields['@repeat'] = false;
          case 'missingTerminal':
            steps.removeLast();
          case 'nonterminalZero':
            steps.insert(0, trainerMove(0));
          case 'routeParameter':
            (steps.first as TrainerRubyObject).fields['@parameters'] = [1];
          case 'routeExtraField':
            route.fields['@custom'] = true;
          case 'changedSpeed':
            pages.last.fields['@move_speed'] = 4;
          case 'randomMovementFrequency':
          case 'customMovementFrequency':
            for (final page in pages) {
              page.fields['@move_type'] =
                  defect == 'randomMovementFrequency' ? 1 : 3;
              page.fields['@move_route'] =
                  trainerRoute([trainerMove(24), trainerMove(0)], repeat: true);
            }
            pages.first.fields['@move_frequency'] = 4;
          case 'changedDirection':
            (pages.last.fields['@graphic'] as TrainerRubyObject)
                .fields['@direction'] = 4;
          case 'bodyFacingChanged':
            final commands = pages.last.fields['@list'] as List;
            commands[1] = trainerCommand(209, [
              0,
              trainerRoute([trainerMove(26), trainerMove(0)])
            ]);
            commands[2] = trainerCommand(509, [trainerMove(26)]);
          case 'changedCondition':
            (pages.last.fields['@condition'] as TrainerRubyObject)
                .fields['@self_switch_ch'] = 'B';
          case 'extraVictoryEffect':
            (pages.first.fields['@list'] as List)
                .insert(6, trainerCommand(123, ['B', 0], indent: 1));
          case 'thirdPage':
            pages.add(trainerPages().last);
        }
      });
      expect(
          analyzeTrainerSource(source)
              .eventAt(94, 7)!
              .pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }

  test('inactive route equivalence preserves complete source binding',
      () async {
    final source = await _source();
    final analysis = analyzeTrainerSource(source);
    final program = analysis.eventAt(94, 7)!.pages.first.body.nodes.single
        as SourceTrainerProgramNode;
    for (final defect in ['rawPage', 'conditionRef', 'position', 'text']) {
      final json = jsonDecode(jsonEncode(source.maps.single.toJson()))
          as Map<String, dynamic>;
      final event = (json['map']['events'] as List).single as Map;
      final pages = event['pages'] as List;
      switch (defect) {
        case 'rawPage':
          pages[0]['rawDataRef'] = pages[1]['rawDataRef'];
        case 'conditionRef':
          pages[0]['conditionsDataRef'] = pages[1]['conditionsDataRef'];
        case 'position':
          event['x'] = 0;
        case 'text':
          pages[0]['commands'][2]['parameters'] = ['Forged challenge'];
      }
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 94,
              event: SourceMapIr.fromJson(json).map.events.single),
          isFalse,
          reason: defect);
    }
    final altered = await _source(inactiveRoute: [17, 16, 0]);
    final alteredAnalysis = analyzeTrainerSource(altered);
    expect(
        program.isBoundToSourceEvent(
            source: altered,
            profile: alteredAnalysis.profile,
            sourceMapId: 94,
            event: altered.maps.single.map.events.single),
        isFalse);
  });
}
