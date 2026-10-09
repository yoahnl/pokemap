import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('compact manifest writer preserves all unrelated root values', () {
    final manifest = ProjectManifest(
      name: 'Évidence',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      newGame:
          const ProjectNewGameConfig(enabled: true, startMapId: 'first-map'),
      globalProperties: const {'campaign': 'original', 'checkpoint': 7},
    );
    final raw = {
      ...manifest.toJson(),
      'unmodeledRoot': {
        'order': [3, 1, 2],
        'text': '  conservé  '
      }
    };
    final before = utf8.encode(const JsonEncoder.withIndent('  ').convert(raw));
    final fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: before),
    ]);
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_codec'),
      revision: fingerprint,
      manifest: manifest,
      maps: const [],
      resourceFingerprints: {'project': fingerprint},
      resourceBytes: {'project': before},
    );
    final after = encodeProjectAuthoringDocument(snapshot, manifest);
    expect(after.length, lessThan(before.length));
    expect(utf8.decode(after), isNot(contains('\n')));
    final decoded = jsonDecode(utf8.decode(after));
    expect(decoded, raw);
    expect(ProjectManifest.fromJson(decoded as Map<String, dynamic>), manifest);
    expect(snapshot.resourceBytes('project'), before);
  });
}
