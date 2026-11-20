import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/transport_certification_catalog_fixture.dart';
import 'package:test/test.dart';

void main() {
  test('removes only new admissions for exact trial project roots', () async {
    final scratch = await Directory.systemTemp.createTemp(
      'catalog-admissions-',
    );
    addTearDown(() => scratch.delete(recursive: true));
    final directory = Directory(await scratch.resolveSymbolicLinks());
    final owned = p.join(directory.path, 'trial', 'editor');
    final startedAt = DateTime.now().subtract(const Duration(seconds: 2));

    Future<File> admission(String digit, Object? contents) =>
        File(p.join(directory.path, '${digit * 64}.json'))
            .writeAsString(jsonEncode(contents));

    final structural = await admission('a', {
      'admission': {'projectRoot': owned},
      'storedBytes': 940,
    });
    final metadata = await admission('b', {
      'projectRoot': owned,
      'metadataIndexVersion': 3,
    });
    final outside = await admission('c', {'projectRoot': '$owned-other'});
    final old = await admission('d', {'projectRoot': owned});
    await old.setLastModified(startedAt.subtract(const Duration(seconds: 1)));
    final unrelated = await File(p.join(directory.path, 'notes.json'))
        .writeAsString(jsonEncode({'projectRoot': owned}));

    await removeCatalogFixtureAdmissions(
      directory,
      ownedProjectRoots: {owned},
      startedAt: startedAt,
    );

    expect(await structural.exists(), isFalse);
    expect(await metadata.exists(), isFalse);
    expect(await outside.exists(), isTrue);
    expect(await old.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });
}
