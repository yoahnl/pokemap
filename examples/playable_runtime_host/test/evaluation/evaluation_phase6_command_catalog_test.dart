import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_command_dispatcher.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_command_catalog.dart';

void main() {
  test('every applicable Phase 6 command has an explicit dispatcher path', () {
    const expected = <String>{
      'party.swap',
      'party.setLead',
      'bag.use',
      'service.pc.deposit',
      'service.pc.withdrawSlot',
      'service.pc.swap',
      'service.shop.sell',
      'battle.switch',
      'battle.chooseProgression',
      'battle.startTrainer',
      'battle.startStatic',
      'player.pause',
      'player.resume',
      'player.openOptions',
      'player.openPokedex',
      'player.saveSlot',
      'player.loadSlot',
    };

    expect(evaluationCommandCatalog.keys, containsAll(expected));
    expect(
      evaluationCommandCatalog.keys.toSet(),
      EvaluationCommandDispatcher.supportedOperations,
    );
    expect(
      expected.every(
        (operation) =>
            evaluationCommandCatalog[operation]?.sequenceKind ==
            EvaluationCommandSequenceKind.explicitUserAction,
      ),
      isTrue,
    );
    expect(
      evaluationCommandCatalog['player.pause']?.availability,
      EvaluationCommandAvailability.attachedPlayerShell,
    );
  });

  test('manual target choice is explicit capability truth, not a fake command',
      () {
    expect(evaluationCommandCatalog, isNot(contains('battle.chooseTarget')));
    expect(
      evaluationUnavailableCommandCapabilities['battle.chooseTarget']?.reason,
      contains('single-target'),
    );
  });
}
