import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NPC counter interaction sides round trip as cardinal enum values', () {
    final npc = MapEntityNpcData.fromJson({
      'displayName': 'Nurse',
      'counterInteractionSides': ['south', 'north', 'east', 'west'],
    });
    expect(npc.toJson()['counterInteractionSides'], [
      'south',
      'north',
      'east',
      'west',
    ]);
    expect(npc.displayName, 'Nurse');
  });

  test('NPC counter interaction defaults to no remote interaction', () {
    expect(
      const MapEntityNpcData().toJson()['counterInteractionSides'],
      isEmpty,
    );
  });

  test(
    'NPC counter interaction rejects invalid directions and malformed lists',
    () {
      for (final value in [
        <String>['diagonal'],
        'south',
        <Object?>[null],
        2,
      ]) {
        expect(
          () => MapEntityNpcData.fromJson({'counterInteractionSides': value}),
          throwsA(isA<Object>()),
        );
      }
    },
  );
}
