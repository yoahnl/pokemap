import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';

void main() {
  const service = ProgressiveLocalCatalogLookupService<_FakeCatalogEntry>(
    idOf: _entryId,
    labelOf: _entryLabel,
    searchTermsOf: _entrySearchTerms,
  );

  group('ProgressiveLocalCatalogLookupService', () {
    test('finds an entry by exact local id', () {
      final entry = service.findById(_entries, 'tackle');

      expect(entry, isNotNull);
      expect(entry!.name, 'Tackle');
    });

    test('search ranks exact label before partial matches', () {
      final results = service.search(_entries, 'growl');

      expect(results.first.id, 'growl');
    });

    test('search returns prefix then partial matches with stable ordering', () {
      final results = service.search(_entries, 'vi');

      expect(
        results.map((entry) => entry.id).toList(growable: false),
        <String>['vine_whip', 'vital_throw'],
      );
    });

    test('returns an empty result when limit is zero', () {
      final results = service.search(_entries, 'tackle', limit: 0);

      expect(results, isEmpty);
    });
  });
}

class _FakeCatalogEntry {
  const _FakeCatalogEntry({
    required this.id,
    required this.name,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final List<String> tags;
}

const List<_FakeCatalogEntry> _entries = <_FakeCatalogEntry>[
  _FakeCatalogEntry(id: 'growl', name: 'Growl', tags: <String>['status']),
  _FakeCatalogEntry(id: 'tackle', name: 'Tackle', tags: <String>['physical']),
  _FakeCatalogEntry(
    id: 'vital_throw',
    name: 'Vital Throw',
    tags: <String>['fighting'],
  ),
  _FakeCatalogEntry(
    id: 'vine_whip',
    name: 'Vine Whip',
    tags: <String>['grass'],
  ),
];

String _entryId(_FakeCatalogEntry entry) => entry.id;

String _entryLabel(_FakeCatalogEntry entry) => entry.name;

Iterable<String> _entrySearchTerms(_FakeCatalogEntry entry) {
  return <String>[entry.id, entry.name, ...entry.tags];
}
