import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NPC presence consequence round-trips as a typed persistent command',
      () {
    final consequence = SceneConsequence.setNpcPresence(
      mapId: 'map.selbrume',
      entityId: 'npc.guard',
      present: false,
    );

    final roundTrip = SceneConsequence.fromJson(consequence.toJson());

    expect(roundTrip, consequence);
    expect(roundTrip, isA<SceneSetNpcPresenceConsequence>());
  });

  test('NPC movement command round-trips with explicit blocked output', () {
    final command = SceneInteractiveCommand.moveNpc(
      mapId: 'map.selbrume',
      entityId: 'npc.guard',
      warpId: 'warp.exit',
    );

    final roundTrip = SceneInteractiveCommand.fromJson(command.toJson());

    expect(roundTrip, command);
    expect(roundTrip.outputPortIds, ['completed', 'blocked']);
  });
}
