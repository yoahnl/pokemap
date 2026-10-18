import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog admission verifies bytes and bounds JSON before decoding', () {
    int admit(String source, {CatalogStorageLimits? limits}) {
      final bytes = utf8.encode(source);
      return PortableCatalogPublication.validateCatalogObjectBytes(
        CatalogObjectReference(
          sha256: crypto.sha256.convert(bytes).toString(),
          byteLength: bytes.length,
        ),
        bytes,
        limits: limits,
      );
    }

    final maximum = '${'[' * 64}null${']' * 64}';
    expect(admit(maximum), 65);
    expect(() => admit('[$maximum]'), throwsFormatException);
    expect(admit('[1]', limits: CatalogStorageLimits(maxJsonValues: 2)), 2);
    expect(
      () => admit('[1,2]', limits: CatalogStorageLimits(maxJsonValues: 2)),
      throwsFormatException,
    );
    expect(
      () => PortableCatalogPublication.validateCatalogObjectBytes(
        CatalogObjectReference(sha256: '0' * 64, byteLength: 1),
        [123],
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'reason',
          contains('digest'),
        ),
      ),
    );
  });

  test(
    'opens metadata without reading unrelated graphical definitions',
    () async {
      final project = ProjectManifest(
        name: 'Selective',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: [
          for (var i = 0; i < 1500; i++)
            ProjectTilesetEntry(
              id: 'tile-$i',
              name: '$i',
              relativePath: '$i.png',
            ),
        ],
        globalProperties: {'payload': 'x' * 10000},
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final graphical = <String>{
        for (final entry in built.storage.objects.entries)
          if ((jsonDecode(utf8.decode(entry.value)) as Map)['key'] case {
            'kind': 'tileset',
          })
            entry.key,
      };
      final read = <String>{};
      expect(graphical, hasLength(1500));
      final catalog = await PortableProjectCatalog.open(
        built.descriptor,
        readObject: (reference) async {
          read.add(reference.sha256);
          return built.storage.objects[reference.sha256]!;
        },
      );
      expect(catalog.projectMetadata.name, 'Selective');
      expect(catalog.projectMetadata.tilesets, isEmpty);
      expect(
        catalog.projectMetadata.globalProperties,
        project.globalProperties,
      );
      expect(read.intersection(graphical), isEmpty);
      final unit = await catalog.lookup(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile-1499'),
      );
      expect(unit, isNotNull);
      final selected = catalog.projectWithDefinitions([unit!]);
      expect(selected.tilesets.single.id, 'tile-1499');
      expect(read.intersection(graphical), hasLength(1));
      expect(selected.globalProperties, project.globalProperties);
    },
  );
}
