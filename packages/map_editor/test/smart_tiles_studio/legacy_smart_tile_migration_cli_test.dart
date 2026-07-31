import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  test('migration refuses map paths outside the project root', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap-smart-tile-migration-',
    );
    addTearDown(() => sandbox.delete(recursive: true));

    final projectRoot = Directory(p.join(sandbox.path, 'project'));
    await projectRoot.create();
    final outsideMap = File(p.join(sandbox.path, 'outside-map.json'));
    await outsideMap.writeAsString('{"sentinel":true}\n');
    final originalOutsideBytes = await outsideMap.readAsBytes();

    const manifest = ProjectManifest(
      name: 'Traversal fixture',
      tilesets: <ProjectTilesetEntry>[],
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'outside',
          name: 'Outside',
          relativePath: '../outside-map.json',
        ),
      ],
    );
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
    );

    final result = await Process.run(
      'dart',
      <String>[
        'tool/migrate_legacy_smart_tiles.dart',
        '--project-root',
        projectRoot.path,
        '--apply',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 65);
    expect(result.stderr, contains('escapes the project directory'));
    expect(await outsideMap.readAsBytes(), originalOutsideBytes);
    expect(
      await Directory(p.join(projectRoot.path, '.pokemap')).exists(),
      isFalse,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
