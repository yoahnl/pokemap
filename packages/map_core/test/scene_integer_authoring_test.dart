import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('canonical command catalog and builder expose typed numerical commands', () {
    final catalog = NarrativeCommandCatalog.canonical();
    for (final id in ['calculateIntegerFacts', 'adjustMoney', 'inputIntegerToFact', 'tryPayMoney']) {
      expect(catalog.commands.where((command) => command.id == id).single.capabilities.isPublishable, isTrue);
    }
    final calculation = buildScenePayloadForNarrativeCommand(commandId: 'calculateIntegerFacts', parameters: {
      'factIds': '["a","b"]', 'operation': 'assign', 'operandSource': 'integerFact', 'operandFactId': 'a',
      'minimum': '-99', 'maximum': '99', 'zeroDivisorPolicy': 'reject', 'boundaryPolicy': 'clamp',
    }) as SceneActionPayload;
    expect((calculation.consequence as SceneCalculateIntegerFactsConsequence).operand, SceneIntegerOperand.integerFact('a'));
    final number = buildScenePayloadForNarrativeCommand(commandId: 'inputIntegerToFact', parameters: {
      'factId': 'a', 'prompt': 'Combien ?', 'digits': '2', 'minimum': '0', 'maximum': '99', 'allowCancel': 'false',
    }) as SceneActionPayload;
    expect((number.interactiveCommand as SceneInputIntegerToFactInteractiveCommand).allowCancel, isFalse);
  });
}
