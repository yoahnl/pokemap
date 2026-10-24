import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _window(int start, int end) => {
  'kind': 'localTimeWindow',
  'refId': '',
  'timeWindow': {'startMinute': start, 'endMinute': end},
};

void main() {
  test('battle predicates participate in typed narrative dependency reads', () {
    final map = MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 4, height: 4),
      entities: const [
        MapEntity(
          id: 'guard',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
            trainerId: 'guard',
            trainerBattleWhen: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.badgeOwned,
              refId: 'badge',
            ),
          ),
        ),
      ],
    );
    final index = buildNarrativeDependencyIndex(
      project: ProjectManifest(name: 'Hours', maps: [], tilesets: []),
      maps: [map],
    );
    expect(
      index.usages.where((usage) => usage.target.id == 'badge').single.path,
      endsWith('.npc.trainerBattleWhen.refId'),
    );
  });
  test('local windows share validated midnight and 24:00 semantics', () {
    const day = LocalTimeWindow(startMinute: 240, endMinute: 1200);
    const night = LocalTimeWindow(startMinute: 1200, endMinute: 240);
    const wholeDay = LocalTimeWindow(startMinute: 0, endMinute: 1440);
    for (var minute = 0; minute < 1440; minute++) {
      expect(day.contains(minute), !night.contains(minute));
      expect(wholeDay.contains(minute), isTrue);
    }
    expect(wholeDay.contains(-1), isFalse);
    expect(wholeDay.contains(1440), isFalse);
    expect(LocalTimeWindow.fromJson(day.toJson()), day);
    expect(
      () => const LocalTimeWindow(startMinute: 10, endMinute: 10).validate(),
      throwsArgumentError,
    );
  });

  test('NPC time predicate round trips its typed minute window', () {
    final predicate = MapEntityRuntimePredicate.fromJson(_window(240, 1200));
    expect(predicate.toJson(), _window(240, 1200));
  });

  test('trainer battle eligibility has an independent persisted predicate', () {
    final npc = MapEntityNpcData.fromJson({
      'trainerId': 'night_guard',
      'dialogue': {'dialogueId': 'day_talk'},
      'trainerBattleWhen': _window(1200, 240),
    });
    expect(npc.toJson()['trainerBattleWhen'], _window(1200, 240));
    expect(MapEntityNpcData.fromJson(npc.toJson()), npc);
  });

  test('NPC time windows reject invalid or ambiguous JSON minutes', () {
    for (final window in [
      {'startMinute': -1, 'endMinute': 240},
      {'startMinute': 1440, 'endMinute': 240},
      {'startMinute': 240, 'endMinute': 1441},
      {'startMinute': 240, 'endMinute': 240},
      {'startMinute': 240.5, 'endMinute': 1200},
      {'startMinute': 240, 'endMinute': 1200, 'unknown': true},
    ]) {
      expect(
        () => MapEntityRuntimePredicate.fromJson({
          'kind': 'localTimeWindow',
          'refId': '',
          'timeWindow': window,
        }),
        throwsFormatException,
      );
    }
  });
}
