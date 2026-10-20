import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

Future<NormalizedSourceProject> _source({
  List<String> lines = const [
    r'EndSpeech: You made it clear to me that\nI should ',
    'stick with school.',
  ],
  void Function(List<TrainerRubyObject>)? mutate,
}) =>
    trainerSource(
        mapId: 94,
        eventId: 8,
        trainerName: 'Leslie',
        eventName: 'Dresseur Leslie Trainer(6)',
        mutate: (pages) {
          final commands = pages.first.fields['@list'] as List;
          commands[3] = trainerCommand(108, [lines.first]);
          commands.insertAll(4, <TrainerRubyObject>[
            for (final line in lines.skip(1)) trainerCommand(408, [line]),
          ]);
          mutate?.call(pages);
        });

void main() {
  for (final lines in [
    [r'EndSpeech: You made it clear to me that\nI should ', 'stick with school.'],
    ['EndSpeech: Première ligne.', 'Deuxième ligne.', 'Troisième ligne.'],
  ]) {
    test('retains complete contiguous EndSpeech 108/408 ${lines.length} lines',
        () async {
      final source = await _source(lines: lines);
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(94, 8)!;
      expect(event.isQuarantined, isFalse);
      final program =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(program.endSpeechComment, lines.join('\n'));
      expect(program.toJson()['sourceEndSpeechCommentRuntimeDialogue'], isFalse);
      expect(program.toJson()['sourceBattleVictoryTextBinding'],
          'pbsTrainerLoseText');
      expect(program.victoryContinuation.nodes, hasLength(1));
      final win =
          program.victoryContinuation.nodes.single as SourceSelfSwitchNode;
      expect(win.factId, program.defeatedFactId);
      expect(win.value, isTrue);
      expect(
          program.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 94,
              event: source.maps.single.map.events.single),
          isTrue);
      final other = await _source(lines: [lines.first, 'Changed continuation']);
      final otherProgram = analyzeTrainerSource(other)
          .eventAt(94, 8)!
          .pages
          .first
          .body
          .nodes
          .single as SourceTrainerProgramNode;
      expect(program.templateHash, isNot(otherProgram.templateHash));
    });
  }

  for (final defect in [
    'unknownComment',
    'continuationIndent',
    'continuationParameter',
    'scriptBetweenLines',
    'routeBetweenLines',
    'commentBetweenLines',
    'continuationAfterBattle',
    'afterFacingChanged',
  ]) {
    test('EndSpeech continuation refuses $defect', () async {
      final source = await _source(mutate: (pages) {
        final commands = pages.first.fields['@list'] as List;
        switch (defect) {
          case 'unknownComment':
            commands[3] = trainerCommand(108, ['Different comment']);
          case 'continuationIndent':
            commands[4] = trainerCommand(408, ['Continuation'], indent: 1);
          case 'continuationParameter':
            commands[4] = trainerCommand(408, [1]);
          case 'scriptBetweenLines':
            commands.insert(4, trainerCommand(355, ['customEffect()']));
          case 'routeBetweenLines':
            commands.insert(
                4,
                trainerCommand(209, [
                  0,
                  trainerRoute([trainerMove(25), trainerMove(0)])
                ]));
          case 'commentBetweenLines':
            commands.insert(4, trainerCommand(108, ['Other comment']));
          case 'continuationAfterBattle':
            final continuation = commands.removeAt(4);
            commands.insert(commands.length - 2, continuation);
          case 'afterFacingChanged':
            final after = pages.last.fields['@list'] as List;
            after[1] = trainerCommand(209, [
              0,
              trainerRoute([trainerMove(26), trainerMove(0)])
            ]);
            after[2] = trainerCommand(509, [trainerMove(26)]);
        }
      });
      expect(
          analyzeTrainerSource(source)
              .eventAt(94, 8)!
              .pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }

  test('multiline EndSpeech does not weaken raw continuation binding', () async {
    final source = await _source();
    final analysis = analyzeTrainerSource(source);
    final program = analysis.eventAt(94, 8)!.pages.first.body.nodes.single
        as SourceTrainerProgramNode;
    final json = jsonDecode(jsonEncode(source.maps.single.toJson()))
        as Map<String, dynamic>;
    final event = (json['map']['events'] as List).single as Map;
    event['pages'][0]['commands'][4]['parameters'] = ['Forged continuation'];
    expect(
        program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: 94,
            event: SourceMapIr.fromJson(json).map.events.single),
        isFalse);
  });
}
