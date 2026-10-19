import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('integer adjustment is a discoverable persistent command', () {
    final command = NarrativeCommandCatalog.canonical().byId(
      'adjustIntegerFact',
    );
    expect(command, isNotNull);
    expect(command!.isPublishable, isTrue);
    expect(command.isPersistent, isTrue);
    expect(command.wireId, 'SceneConsequence.adjustIntegerFact');
    expect(command.parameters.map((parameter) => parameter.id), [
      'factId',
      'delta',
      'minimum',
      'maximum',
    ]);
    expect(command.parameters.first.kind, NarrativeCommandParameterKind.fact);
    expect(
      command.parameters.skip(1).map((parameter) => parameter.kind),
      everyElement(NarrativeCommandParameterKind.integer),
    );
    expect(
      SpatialGameplayCapabilities.commandIds,
      contains('adjustIntegerFact'),
    );
  });

  test(
    'the canonical builder preserves signed arithmetic and clamp bounds',
    () {
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: 'adjustIntegerFact',
                parameters: const {
                  'factId': 'counter',
                  'delta': '-3',
                  'minimum': '-8',
                  'maximum': '0',
                },
              )
              as SceneActionPayload;
      expect(
        payload.consequence,
        SceneConsequence.adjustIntegerFact(
          factId: 'counter',
          delta: -3,
          minimum: -8,
          maximum: 0,
        ),
      );
    },
  );

  test('the canonical builder rejects malformed or incomplete adjustments', () {
    const valid = {
      'factId': 'counter',
      'delta': '1',
      'minimum': '0',
      'maximum': '5',
    };
    for (final parameters in [
      {...valid}..remove('minimum'),
      {...valid, 'maximum': '-1'},
      {...valid, 'delta': '1.5'},
      {...valid, 'delta': '+1'},
      {...valid, 'delta': '01'},
      {...valid, 'delta': '9007199254740992'},
      {...valid, 'unrecognized': 'yes'},
    ]) {
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: 'adjustIntegerFact',
          parameters: parameters,
        ),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
  });
}
