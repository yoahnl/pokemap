import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final count in [16, 10000]) {
    test(
      'targeted map metadata preserves branches and wrapping with $count maps',
      () {
        var entriesRead = 0;
        final entries = ProjectMapEntries.prepare([
          for (var i = 0; i < count; i++)
            ProjectMapEntry(
              id: 'map-$i',
              name: 'Map $i',
              relativePath: 'maps/$i.json',
            ),
        ], onEntryRead: () => entriesRead++);
        final manifest = ProjectManifest(
          name: 'Maps',
          maps: entries,
          tilesets: const [],
        );
        expect(identical(manifest.maps, entries), isTrue);
        final unchanged = entries.lookup('map-${count - 1}');
        entriesRead = 0;
        var copied = 0;
        var next = entries.applySelected(
          upserts: [entries.lookup('map-0')!.copyWith(name: 'Changed')],
          onNodeCopied: () => copied++,
        );
        final updated = manifest.copyWith(maps: next);
        expect(identical(updated.maps, next), isTrue);
        expect(identical(next.lookup('map-${count - 1}'), unchanged), isTrue);
        expect(entries.lookup('map-0')!.name, 'Map 0');
        expect(next.lookup('map-0')!.name, 'Changed');
        expect(copied, lessThan(32));
        expect(entriesRead, lessThan(12));
        for (var iteration = 0; iteration < 1000; iteration++) {
          copied = 0;
          next = next.applySelected(
            upserts: [
              next.lookup('map-0')!.copyWith(name: 'Repeat $iteration'),
            ],
            onNodeCopied: () => copied++,
          );
          expect(copied, lessThan(32));
          expect(next.length, count);
        }
      },
    );
  }

  test(
    'structural changes stay bounded without retaining removed generations',
    () {
      var entries = ProjectMapEntries.prepare([
        for (var i = 0; i < 1024; i++)
          ProjectMapEntry(
            id: 'map-$i',
            name: 'Map $i',
            relativePath: 'maps/$i.json',
          ),
      ]);
      final unchanged = entries.lookup('map-1023');
      for (var i = 0; i < 1000; i++) {
        var copied = 0;
        entries = entries.applySelected(
          removedIds: {'map-$i'},
          upserts: [
            ProjectMapEntry(
              id: 'new-$i',
              name: 'New $i',
              relativePath: 'maps/new-$i.json',
            ),
          ],
          onNodeCopied: () => copied++,
        );
        expect(entries.length, 1024);
        expect(entries.lookup('map-$i'), isNull);
        expect(entries.lookup('new-$i')!.name, 'New $i');
        expect(entries.lookup('map-1023'), same(unchanged));
        expect(copied, lessThan(128));
      }
      expect(entries.first.id, 'map-1000');
      expect(entries.last.id, 'new-999');
    },
  );

  for (final removed in [
    {'c', 'b'},
    {'b', 'c'},
  ]) {
    for (final reverseUpdates in [false, true]) {
      test(
        'canonical batch replacement ignores removal and upsert order $removed/$reverseUpdates',
        () {
          final entries = ProjectMapEntries.prepare([
            for (final id in ['a', 'b', 'c', 'd'])
              ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
          ]);
          const updates = [
            ProjectMapEntry(id: 'x', name: 'x', relativePath: 'maps/x.json'),
            ProjectMapEntry(id: 'y', name: 'y', relativePath: 'maps/y.json'),
          ];
          final changed = entries.applySelected(
            upserts: reverseUpdates ? updates.reversed : updates,
            removedIds: removed,
            positions: {'x': 1, 'y': 2},
          );
          expect(changed.map((entry) => entry.id), ['a', 'x', 'y', 'd']);
          expect(changed.lookup('b'), isNull);
          expect(changed.lookup('c'), isNull);
          expect(changed.lookup('a'), same(entries.lookup('a')));
          expect(changed.lookup('d'), same(entries.lookup('d')));
          expect(entries.map((entry) => entry.id), ['a', 'b', 'c', 'd']);
        },
      );
    }
  }

  test('canonical identity replacement keeps the removed catalog position', () {
    final entries = ProjectMapEntries.prepare([
      for (final id in ['a', 'b', 'c'])
        ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
    ]);
    final renamed = entries.applySelected(
      upserts: const [
        ProjectMapEntry(
          id: 'renamed',
          name: 'Renamed',
          relativePath: 'maps/renamed.json',
        ),
      ],
      removedIds: {'b'},
      positions: {'renamed': 1},
    );
    expect(renamed.map((entry) => entry.id), ['a', 'renamed', 'c']);
    expect(renamed.lookup('b'), isNull);
    expect(entries.lookup('b')!.name, 'b');
  });

  test(
    'targeted insertion and deletion preserve order and JSON compatibility',
    () {
      var entries = ProjectMapEntries.prepare([
        for (final id in ['a', 'b', 'c'])
          ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
      ]);
      entries = entries.applySelected(
        upserts: const [
          ProjectMapEntry(id: 'd', name: 'D', relativePath: 'maps/d.json'),
        ],
        removedIds: {'b'},
      );
      expect(entries.map((entry) => entry.id), ['a', 'c', 'd']);
      expect(entries.lookup('b'), isNull);
      expect(
        () => entries.add(
          const ProjectMapEntry(id: 'e', name: 'e', relativePath: 'e.json'),
        ),
        throwsUnsupportedError,
      );
      final manifest = ProjectManifest(
        name: 'Maps',
        maps: entries,
        tilesets: const [],
      );
      expect(
        ProjectManifest.fromJson(manifest.toJson()).maps,
        entries.toList(),
      );
    },
  );
}
