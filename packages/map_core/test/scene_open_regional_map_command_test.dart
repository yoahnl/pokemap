import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('regional map command round-trips as an awaitable read-only interaction',
      () {
    final command =
        SceneInteractiveCommand.fromJson({'kind': 'openRegionalMap'});
    expect(command.kind.name, 'openRegionalMap');
    expect(command.outputPortIds, ['completed', 'cancelled']);
    expect(command.toJson(), {'kind': 'openRegionalMap'});
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });

  test('canonical guided builder exposes the regional map command', () {
    final descriptor =
        NarrativeCommandCatalog.canonical().byId('openRegionalMap');
    expect(descriptor, isNotNull);
    expect(descriptor!.parameters, isEmpty);
    expect(descriptor.isAwaitable, isTrue);
    expect(descriptor.isPersistent, isFalse);
    expect(descriptor.isPublishable, isTrue);
    final payload = buildScenePayloadForNarrativeCommand(
        commandId: descriptor.id, parameters: const {}) as SceneActionPayload;
    expect(payload.interactiveCommand!.toJson(), {'kind': 'openRegionalMap'});
  });

  test('regional map does not expose travel or unqualified spatial commands', () {
    expect(
        () => SceneInteractiveCommand.fromJson(
            {'kind': 'openRegionalMap', 'allowFly': true}),
        throwsFormatException);
    expect(
        () => buildScenePayloadForNarrativeCommand(
            commandId: 'openRegionalMap', parameters: const {'allowFly': 'true'}),
        throwsFormatException);
    expect(SpatialGameplayCapabilities.commandIds, isNot(contains('openRegionalMap')));
  });
}
