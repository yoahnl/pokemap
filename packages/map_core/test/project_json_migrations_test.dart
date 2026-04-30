import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('project JSON migrations', () {
    test('project manifest migration is exported and currently preserves input',
        () {
      final raw = <String, dynamic>{
        'id': 'project',
        'name': 'Project',
      };

      final migrated = migrateProjectManifestJson(raw);

      expect(identical(migrated, raw), isTrue);
    });

    test('map data migration is exported and currently preserves input', () {
      final raw = <String, dynamic>{
        'id': 'map',
        'name': 'Map',
      };

      final migrated = migrateMapDataJson(raw);

      expect(identical(migrated, raw), isTrue);
    });
  });
}
