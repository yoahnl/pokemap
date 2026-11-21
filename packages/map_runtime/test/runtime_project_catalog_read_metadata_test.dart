import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-read-metadata-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  final project = ProjectManifest(
    name: 'Light metadata',
    version: ProjectVersion.v9,
    settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    maps: const [
      ProjectMapEntry(id: 'start', name: 'Start', relativePath: 'maps/a.json'),
    ],
    tilesets: const [],
    presentationCinematics: [
      PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 1000000,
        tracks: [
          PresentationTrack(
            id: 'markers',
            label: 'Markers',
            kind: PresentationTrackKind.marker,
            clips: [
              PresentationMarkerClip(
                id: 'cue',
                startUs: 500000,
                label: 'Cue',
                markerKind: PresentationMarkerKind.interactionCue,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Future<File> writePortable() async {
    final publication = PortableCatalogPublication.encodeProject(project);
    final file = File(p.join(root.path, 'project.json'));
    await file.writeAsString(jsonEncode(publication.descriptor));
    for (final object in publication.storage.objects.entries) {
      final target = File(
        p.join(root.path, 'catalog/objects/${object.key}.json'),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(object.value);
    }
    return file;
  }

  test('reads the requested fields as the full catalog does', () async {
    final file = await writePortable();
    final light = await RuntimeProjectCatalog.readMetadata(
      file.path,
      fields: const {'presentationCinematics'},
      expectedSourceSha256: sha256.convert(await file.readAsBytes()).toString(),
    );
    final catalog = await RuntimeProjectCatalog.open(file.path);
    addTearDown(catalog.dispose);
    final full = catalog.projectMetadata;
    expect(light.name, full.name);
    expect(light.settings.toJson(), full.settings.toJson());
    expect(light.settings.dimension, ProjectDimension.threeD);
    expect(
      jsonEncode(light.toJson()['presentationCinematics']),
      jsonEncode(full.toJson()['presentationCinematics']),
    );
    expect(light.presentationCinematics, hasLength(1));
    expect(full.maps, hasLength(1));
    expect(light.maps, isEmpty);
  });

  test('rejects project bytes other than the admitted ones', () async {
    final file = await writePortable();
    await expectLater(
      RuntimeProjectCatalog.readMetadata(
        file.path,
        fields: const {'presentationCinematics'},
        expectedSourceSha256: '0' * 64,
      ),
      throwsFormatException,
    );
  });

  test('rejects a tampered catalog object it reads', () async {
    final file = await writePortable();
    await for (final object in Directory(
      p.join(root.path, 'catalog/objects'),
    ).list(recursive: true)) {
      if (object is File) await object.writeAsString('{}');
    }
    await expectLater(
      RuntimeProjectCatalog.readMetadata(
        file.path,
        fields: const {'presentationCinematics'},
      ),
      throwsA(anything),
    );
  });

  test('reads a single-document project through the full decoder', () async {
    final file = File(p.join(root.path, 'project.json'));
    await file.writeAsString(
      jsonEncode(
        project
            .copyWith(
              version: ProjectVersion.v8,
              settings: const ProjectSettings(),
            )
            .toJson(),
      ),
    );
    final light = await RuntimeProjectCatalog.readMetadata(
      file.path,
      fields: const {'presentationCinematics'},
    );
    expect(light.settings.dimension, ProjectDimension.twoD);
    expect(light.presentationCinematics.single.id, 'opening');
  });
}
