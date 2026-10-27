import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('party trade is a closed awaitable scene command', () {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'openPartyTrade',
    });
    expect(command.kind.name, 'openPartyTrade');
    expect(command.outputPortIds, ['completed', 'cancelled']);
    expect(command.toJson(), {'kind': 'openPartyTrade'});
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });
  test(
    'the canonical guided catalog exposes native party trade and its commit',
    () {
      final descriptor = NarrativeCommandCatalog.canonical().byId(
        'openPartyTrade',
      );
      expect(descriptor, isNotNull);
      expect(descriptor!.parameters, isEmpty);
      expect(descriptor.isAwaitable, isTrue);
      expect(descriptor.isPersistent, isTrue);
      expect(descriptor.isPublishable, isTrue);
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: descriptor.id,
                parameters: const {},
              )
              as SceneActionPayload;
      expect(payload.interactiveCommand!.toJson(), {'kind': 'openPartyTrade'});
    },
  );
  test(
    'trade cannot inject a party slot or an external pokemon in parameters',
    () {
      for (final key in [
        'partyIndex',
        'sourceVariable',
        'pokemon',
        'storageId',
      ]) {
        expect(
          () => SceneInteractiveCommand.fromJson({
            'kind': 'openPartyTrade',
            key: 1,
          }),
          throwsFormatException,
        );
        expect(
          () => buildScenePayloadForNarrativeCommand(
            commandId: 'openPartyTrade',
            parameters: {key: '1'},
          ),
          throwsFormatException,
        );
      }
      expect(
        SpatialGameplayCapabilities.commandIds,
        contains('openPartyTrade'),
      );
    },
  );
}
