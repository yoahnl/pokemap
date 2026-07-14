import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileBorderPublicationManifestPort', () {
    late Directory projectRoot;
    late File manifestFile;
    late ProjectManifest previous;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_manifest_',
      );
      manifestFile = File(p.join(projectRoot.path, 'project.json'));
      previous = _manifest('Previous', ProjectVersion.v1);
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(previous.toJson()),
        flush: true,
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test('atomically replaces the manifest and cleans its sibling stage',
        () async {
      ProjectManifest? applied;
      final port = FileBorderPublicationManifestPort(
        manifestPath: manifestFile.path,
        applyInMemoryManifest: (manifest) => applied = manifest,
        stageIdFactory: () => 'publish_success',
      );
      final next = _manifest('Published', ProjectVersion.v2);

      await port.atomicallyReplace(
        previousManifest: previous,
        nextManifest: next,
      );

      final decoded = ProjectManifest.fromJson(
        migrateProjectManifestJson(
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
        ),
      );
      expect(decoded, next);
      expect(applied, isNull);
      port.applyInMemory(next);
      expect(applied, same(next));
      expect(
        projectRoot
            .listSync()
            .whereType<File>()
            .map((file) => p.basename(file.path)),
        <String>['project.json'],
      );
    });

    test('invalid staged JSON never replaces the previous manifest', () async {
      final previousBytes = await manifestFile.readAsBytes();
      final port = FileBorderPublicationManifestPort(
        manifestPath: manifestFile.path,
        applyInMemoryManifest: (_) {},
        stageIdFactory: () => 'publish_corrupt',
        beforeOperation: (operation, stagedPath) async {
          if (operation ==
              BorderPublicationManifestOperation.validateStagedManifest) {
            await File(stagedPath).writeAsString('{broken', flush: true);
          }
        },
      );

      await expectLater(
        port.atomicallyReplace(
          previousManifest: previous,
          nextManifest: _manifest('Next', ProjectVersion.v2),
        ),
        throwsA(
          isA<BorderPublicationManifestException>().having(
            (error) => error.code,
            'code',
            BorderPublicationManifestErrorCode.stagedManifestInvalid,
          ),
        ),
      );

      expect(await manifestFile.readAsBytes(), previousBytes);
      expect(
        projectRoot
            .listSync()
            .whereType<File>()
            .map((file) => p.basename(file.path)),
        <String>['project.json'],
      );
    });

    test('replacement failure preserves the old bytes and removes temp data',
        () async {
      final previousBytes = await manifestFile.readAsBytes();
      final port = FileBorderPublicationManifestPort(
        manifestPath: manifestFile.path,
        applyInMemoryManifest: (_) {},
        stageIdFactory: () => 'publish_fail',
        atomicFileReplace: (staged, destination) {
          throw FileSystemException(
            'injected replacement failure',
            destination.path,
          );
        },
      );

      await expectLater(
        port.atomicallyReplace(
          previousManifest: previous,
          nextManifest: _manifest('Next', ProjectVersion.v2),
        ),
        throwsA(
          isA<BorderPublicationManifestException>().having(
            (error) => error.code,
            'code',
            BorderPublicationManifestErrorCode.atomicReplaceFailed,
          ),
        ),
      );

      expect(await manifestFile.readAsBytes(), previousBytes);
      expect(
        projectRoot
            .listSync()
            .whereType<File>()
            .map((file) => p.basename(file.path)),
        <String>['project.json'],
      );
    });

    test('rejects unsafe stage identifiers before touching the manifest',
        () async {
      final previousBytes = await manifestFile.readAsBytes();
      final port = FileBorderPublicationManifestPort(
        manifestPath: manifestFile.path,
        applyInMemoryManifest: (_) {},
        stageIdFactory: () => '../outside',
      );

      await expectLater(
        port.atomicallyReplace(
          previousManifest: previous,
          nextManifest: _manifest('Next', ProjectVersion.v2),
        ),
        throwsA(
          isA<BorderPublicationManifestException>().having(
            (error) => error.code,
            'code',
            BorderPublicationManifestErrorCode.invalidStageId,
          ),
        ),
      );
      expect(await manifestFile.readAsBytes(), previousBytes);
    });

    test('rejects a manifest changed after the publication candidate was built',
        () async {
      final external = _manifest('External update', ProjectVersion.v2);
      final port = FileBorderPublicationManifestPort(
        manifestPath: manifestFile.path,
        applyInMemoryManifest: (_) {},
        stageIdFactory: () => 'publish_stale',
        beforeOperation: (operation, _) async {
          if (operation == BorderPublicationManifestOperation.atomicReplace) {
            await manifestFile.writeAsString(
              const JsonEncoder.withIndent('  ').convert(external.toJson()),
              flush: true,
            );
          }
        },
      );

      await expectLater(
        port.atomicallyReplace(
          previousManifest: previous,
          nextManifest: _manifest('Candidate', ProjectVersion.v2),
        ),
        throwsA(
          isA<BorderPublicationManifestException>().having(
            (error) => error.code,
            'code',
            BorderPublicationManifestErrorCode.staleManifest,
          ),
        ),
      );

      expect(await _readManifest(manifestFile), external);
      expect(
        projectRoot
            .listSync()
            .whereType<File>()
            .map((file) => p.basename(file.path)),
        <String>['project.json'],
      );
    });
  });
}

Future<ProjectManifest> _readManifest(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(migrateProjectManifestJson(json));
}

ProjectManifest _manifest(String name, ProjectVersion version) {
  return ProjectManifest(
    name: name,
    version: version,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}
