import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

void main() {
  test('unique source event lookup retains one immutable event across queries',
      () async {
    final source = await trainerSource();
    final hash = source.canonicalHash;
    final original = source.maps.single.map.events.single;
    final event = source.uniqueEventAt(417, 23);

    expect(event, isNotNull);
    expect(event!.toJson(), original.toJson());
    for (var lookup = 0; lookup < 1000; lookup++) {
      expect(source.uniqueEventAt(417, 23), same(event));
    }
    expect(() => event.toJson()['name'] = 'Changed', throwsUnsupportedError);
    expect(() => event.pages.clear(), throwsUnsupportedError);
    expect(source.canonicalHash, hash);
  });

  test('unique source event lookup refuses missing maps and events', () async {
    final source = await trainerSource();

    expect(source.uniqueEventAt(416, 23), isNull);
    expect(source.uniqueEventAt(417, 24), isNull);
    expect(source.uniqueEventAt(0, 23), isNull);
    expect(source.uniqueEventAt(417, 0), isNull);
    expect(source.uniqueEventAt(417, 23), isNotNull);
  });

  test('source event lookup is owned by its normalized source instance',
      () async {
    final first = await trainerSource(eventName: 'First original trainer');
    final second =
        await trainerSource(eventName: 'Independent original trainer');
    final firstEvent = first.uniqueEventAt(417, 23)!;
    final secondEvent = second.uniqueEventAt(417, 23)!;

    expect(firstEvent.name, 'First original trainer');
    expect(secondEvent.name, 'Independent original trainer');
    expect(firstEvent, isNot(same(secondEvent)));
    expect(first.uniqueEventAt(417, 23), same(firstEvent));
    expect(second.uniqueEventAt(417, 23), same(secondEvent));
  });
}
