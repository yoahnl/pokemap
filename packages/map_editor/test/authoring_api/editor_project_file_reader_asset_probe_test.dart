import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('preserves directory listing and typed resource probes', () async {
    final root = await Directory.systemTemp.createTemp(
      'editor-project-file-reader-probe-',
    );
    addTearDown(() => root.delete(recursive: true));
    final asset = File(p.join(root.path, 'assets', 'front.png'));
    await asset.parent.create(recursive: true);
    await asset.writeAsBytes(<int>[1, 2, 3]);
    final canonicalRoot = await root.resolveSymbolicLinks();
    const reader = EditorProjectFileReader();

    final listed = await reader.listFiles(
      projectRoot: canonicalRoot,
      relativeDirectory: 'assets',
    );
    final existing = await reader.probeResource(
      projectRoot: canonicalRoot,
      relativePath: 'assets/front.png',
    );
    final missing = await reader.probeResource(
      projectRoot: canonicalRoot,
      relativePath: 'assets/missing.png',
    );

    expect(listed, <String>['assets/front.png']);
    expect(existing.status, ProjectResourceProbeStatus.exists);
    expect(missing.status, ProjectResourceProbeStatus.missing);
  });
}
