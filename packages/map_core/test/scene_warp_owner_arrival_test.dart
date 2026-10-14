import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> wire({Object? owner = 'centre-door'}) => {
    'kind': 'warp',
    'destinationMapId': 'route10',
    'warpId': 'centre-return',
    'transition': 'none',
    'arrivalCollisionOwnerEntityId': owner,
  };

  test('warp retains its explicit arrival collision owner on round-trip', () {
    final json = wire();
    final command = SceneInteractiveCommand.fromJson(json);
    expect(command.toJson(), json);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });

  test('arrival collision owner participates in warp identity', () {
    final ordinary = wire()..remove('arrivalCollisionOwnerEntityId');
    final values = {
      SceneInteractiveCommand.fromJson(ordinary),
      SceneInteractiveCommand.fromJson(wire()),
      SceneInteractiveCommand.fromJson(wire(owner: 'other-door')),
    };
    expect(values, hasLength(3));
    expect(SceneInteractiveCommand.fromJson(ordinary).toJson(), ordinary);
  });

  test('warp refuses malformed arrival owner declarations', () {
    for (final owner in <Object?>[
      null,
      '',
      ' ',
      ' centre-door ',
      8,
      true,
      <String>[],
      <String, dynamic>{},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson(wire(owner: owner)),
        throwsFormatException,
        reason: '$owner',
      );
    }
  });
}
