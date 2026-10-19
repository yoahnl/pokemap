import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

void main() {
  for (final sample in [
    (hidden: false, through: false, turn: true),
    (hidden: true, through: false, turn: false),
    (hidden: true, through: true, turn: false),
    (hidden: false, through: false, turn: false),
  ]) {
    final hidden = sample.hidden;
    test('global trainer override retains page priority and no battle $sample',
        () async {
      final source = await trainerSource(mutate: (pages) {
        final override = trainerPages()[1];
        final condition = override.fields['@condition'] as TrainerRubyObject;
        condition.fields['@self_switch_valid'] = false;
        condition.fields['@switch1_valid'] = true;
        override.fields['@through'] = sample.through;
        if (hidden) {
          override.fields['@list'] = [trainerCommand(0, [])];
          (override.fields['@graphic'] as TrainerRubyObject)
              .fields['@character_name'] = '';
        } else {
          ((override.fields['@list'] as List).first as TrainerRubyObject)
              .fields['@parameters'] = ['Le tournoi est terminé.'];
          if (!sample.turn) {
            override.fields['@list'] = [
              trainerCommand(101, ['Le tournoi est terminé.']),
              trainerCommand(0, [])
            ];
          }
        }
        pages.add(override);
      });
      final analysis = analyzeTrainerSource(source);
      final event = analysis.eventAt(417, 23)!;
      expect(event.isQuarantined, isFalse);
      expect(event.pages, hasLength(3));
      final encounter =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(encounter.kind, SourceTrainerProgramKind.encounter);
      expect(encounter.sourcePageRefs, hasLength(3));
      final original = source.maps.single.map.events.single;
      expect(
          encounter.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 417,
              event: original),
          isTrue);
      final forged = jsonDecode(jsonEncode(source.maps.single.toJson()))
          as Map<String, dynamic>;
      (((((forged['map'] as Map)['events'] as List).single['pages'] as List)[2]
              ['commands'] as List)
          .last as Map)['parameters'] = ['Injected'];
      expect(
          encounter.isBoundToSourceEvent(
              source: source,
              profile: analysis.profile,
              sourceMapId: 417,
              event: SourceMapIr.fromJson(forged).map.events.single),
          isFalse);
      final analyzer =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile);
      for (final won in [false, true]) {
        for (final global in [false, true]) {
          final page = event.selectPage(facts: {
            analyzer.selfFactId(417, 23, 'A'): won,
            analyzer.globalFactId(1): global,
          })!;
          expect(
              page.originalPageIndex,
              global
                  ? 2
                  : won
                      ? 1
                      : 0);
          if (global) {
            if (hidden) {
              expect(page.isEmpty, isTrue);
              expect(page.graphic!.characterName, isEmpty);
              expect(page.body.nodes.whereType<SourceTrainerProgramNode>(),
                  isEmpty);
            } else {
              final node = page.body.nodes.single as SourceTrainerProgramNode;
              expect(node.kind, SourceTrainerProgramKind.afterWin);
              expect(node.afterWinLines, ['Le tournoi est terminé.']);
              expect(node.facesPlayerAfterDialogue, sample.turn);
            }
          }
        }
      }
    });
  }
  for (final defect in ['unguarded', 'autorun', 'script', 'battle']) {
    test('refuses an unsafe global trainer override $defect', () async {
      final source = await trainerSource(mutate: (pages) {
        final override = trainerPages()[1];
        final condition = override.fields['@condition'] as TrainerRubyObject;
        condition.fields['@self_switch_valid'] = false;
        condition.fields['@switch1_valid'] = defect != 'unguarded';
        if (defect == 'autorun') override.fields['@trigger'] = 3;
        if (defect == 'script' || defect == 'battle') {
          override.fields['@list'] = [
            trainerCommand(355, [
              defect == 'script'
                  ? 'customOverride()'
                  : 'TrainerBattle.start(:FRLG_BUGCATCHER, "Brent")'
            ]),
            trainerCommand(0, []),
          ];
        }
        pages.add(override);
      });
      final event = analyzeTrainerSource(source).eventAt(417, 23)!;
      expect(
          event.pages
              .expand((page) => page.body.nodes)
              .whereType<SourceTrainerProgramNode>(),
          isEmpty);
    });
  }
}
