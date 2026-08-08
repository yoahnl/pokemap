import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('projects a committed map post-image without rereading other bytes', () {
    final manifestBytes = utf8.encode(_manifestJson);
    final beforeBytes = utf8.encode(_mapJson('Before'));
    final afterBytes = utf8.encode(_mapJson('After'));
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_before'),
      revision: computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/alpha.json',
          bytes: beforeBytes,
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      manifest: ProjectManifest.fromJson(
        jsonDecode(_manifestJson) as Map<String, dynamic>,
      ),
      maps: [
        MapData.fromJson(jsonDecode(_mapJson('Before'))),
      ],
      resourceFingerprints: {
        'map:alpha': _fingerprint('maps/alpha.json', beforeBytes),
        'project': _fingerprint('project.json', manifestBytes),
      },
      resourceBytes: {
        'map:alpha': beforeBytes,
        'project': manifestBytes,
      },
      resourceStorageKeys: const {
        'map:alpha': 'maps/alpha.json',
        'project': 'project.json',
      },
    );

    final projected = const ProjectSnapshotMapProjector().project(
      snapshot,
      [
        AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'alpha',
            revision: _fingerprint('maps/alpha.json', beforeBytes),
          ),
          storageKey: 'maps/alpha.json',
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
    );

    expect(projected, isNotNull);
    expect(projected!.mapById('alpha')!.name, 'After');
    expect(projected.resourceBytes('map:alpha'), afterBytes);
    expect(projected.resourceBytes('project'), manifestBytes);
    expect(projected.revision, isNot(snapshot.revision));
  });
}

String _fingerprint(String path, List<int> bytes) =>
    computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(relativePath: path, bytes: bytes),
    ]);

const _manifestJson = '''
{
  "name": "Projection",
  "version": "v6",
  "maps": [{"id": "alpha", "name": "Alpha", "relativePath": "maps/alpha.json"}],
  "tilesets": []
}
''';

String _mapJson(String name) => '''
{
  "id": "alpha",
  "name": "$name",
  "version": "v6",
  "size": {"width": 1, "height": 1},
  "layers": []
}
''';
