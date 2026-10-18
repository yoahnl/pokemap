import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'loads distributed catalog objects and rejects changed or escaped objects',
    () async {
      final root = await Directory.systemTemp.createTemp('partitioned-loader-');
      final outside = await Directory.systemTemp.createTemp(
        'partitioned-outside-',
      );
      addTearDown(() async {
        await root.delete(recursive: true);
        await outside.delete(recursive: true);
      });
      final project = ProjectManifest(
        name: 'Partitioned',
        version: ProjectVersion.v8,
        maps: [],
        tilesets: [],
      );
      final publication = PortableCatalogPublication.encodeProject(project);
      final manifest = File(p.join(root.path, 'project.json'));
      await manifest.writeAsString(jsonEncode(publication.descriptor));
      for (final object in publication.storage.objects.entries) {
        final file = File(
          p.join(root.path, 'catalog/objects/${object.key}.json'),
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(object.value);
      }
      expect(
        (await loadProjectManifestFromFile(manifest.path)).name,
        'Partitioned',
      );
      await manifest.writeAsString(
        jsonEncode(publication.descriptor)
            .replaceFirst('{', '{"format":"overwritten",'),
      );
      await expectLater(
        loadProjectManifestFromFile(manifest.path),
        throwsA(isA<ProjectLoadException>()),
      );
      await manifest.writeAsString(jsonEncode(publication.descriptor));
      final object = publication.storage.objects.entries.first;
      final file = File(
        p.join(root.path, 'catalog/objects/${object.key}.json'),
      );
      await file.writeAsString('{}');
      await expectLater(
        loadProjectManifestFromFile(manifest.path),
        throwsA(isA<ProjectLoadException>()),
      );
      final external = File(p.join(outside.path, 'object.json'));
      await external.writeAsBytes(object.value);
      await file.delete();
      await Link(file.path).create(external.path);
      await expectLater(
        loadProjectManifestFromFile(manifest.path),
        throwsA(isA<ProjectLoadException>()),
      );
    },
  );
}
