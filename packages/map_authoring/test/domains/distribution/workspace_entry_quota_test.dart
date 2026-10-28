import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('workspace-entry-quota-');
    root = Directory(await root.resolveSymbolicLinks());
    await File(p.join(root.path, 'project.json')).writeAsString(
      jsonEncode(
        const ProjectManifest(name: 'quota', maps: [], tilesets: []).toJson(),
      ),
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<void> writeFiles(String directory, int count) async {
    for (var index = 0; index < count; index++) {
      final file = File(p.join(root.path, directory, 'entry-$index.json'));
      await file.parent.create(recursive: true);
      await file.writeAsString('{}');
    }
  }

  Future<RuntimeProjectProjection> build() =>
      const RuntimeProjectProjectionBuilder(maxWorkspaceEntries: 20).build(
        projectRoot: root,
        profile: GamePackageExportProfile(
          gameId: 'games.test.quota',
          gameVersion: '0.1.0',
          title: 'Quota',
          authorName: 'Tester',
          defaultLocale: 'en',
          supportedLocales: const ['en'],
        ),
      );

  test('excluded authoring folders do not count against the quota', () async {
    await writeFiles('.pokemap/journal', 30);
    await writeFiles('catalog/objects', 30);

    final projection = await build();

    expect(
      projection.payloadFiles.keys.where(
        (path) => path.contains('/.pokemap/') || path.contains('/catalog/'),
      ),
      isEmpty,
    );
  });

  test('caps the projected payload at the package security policy', () {
    expect(
      const RuntimeProjectProjectionBuilder().maxTotalPayloadBytes,
      GamePackageSecurityPolicy.maxTotalPayloadBytesV1,
    );
  });

  test('walked workspace entries still count against the quota', () async {
    await writeFiles('notes', 30);

    await expectLater(
      build(),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'workspaceEntryQuotaExceeded',
        ),
      ),
    );
  });
}
