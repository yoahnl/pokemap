import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test(
    'product map lifecycle providers persist canonical receipts and can undo removal',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'map-lifecycle-provider-',
      );
      addTearDown(() => root.delete(recursive: true));
      final workspace = ProjectFileSystem(root.path);
      const project = ProjectManifest(
        name: 'Map lifecycle provider',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      final manifestFile = File(workspace.projectManifestPath);
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          ...project.toJson(),
          'legacyMetadata': {'tag': 'retained'},
        }),
        flush: true,
      );
      final throwingProjects = _ThrowingProjectRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          mapRepositoryProvider.overrideWithValue(FileMapRepository()),
          projectRepositoryProvider.overrideWithValue(throwingProjects),
        ],
      );
      addTearDown(container.dispose);
      final mutations = container.read(authoringMutationAdapterProvider);
      addTearDown(mutations.closeAll);

      final creation = await container
          .read(createMapUseCaseProvider)
          .executeRevisioned(workspace, project, 'harbor', 2, 2);
      final harbor = creation.map;
      expect(creation.revision, isNotNull);
      expect(mutations.lastAppliedReceipt?.actionId, 'map.create');

      final repository = FileProjectRepository();
      final created = await repository.loadProject(
        workspace.projectManifestPath,
      );
      expect(created.maps.single.id, 'harbor');
      final original = await File(workspace.getMapPath('harbor')).readAsBytes();
      final duplicated = await container
          .read(duplicateMapUseCaseProvider)
          .execute(workspace, created, 'harbor');
      expect(mutations.lastAppliedReceipt?.actionId, 'map.duplicate');
      final copy = duplicated.maps.last;
      await expectLater(
        container
            .read(renameMapUseCaseProvider)
            .executeRevisioned(workspace, created, 'harbor', 'stale'),
        throwsA(isA<EditorConflictException>()),
      );
      expect(await File(workspace.getMapPath('stale')).exists(), isFalse);
      expect(mutations.lastAppliedReceipt?.actionId, 'map.duplicate');
      final renamed = await container
          .read(renameMapUseCaseProvider)
          .executeRevisioned(workspace, duplicated, copy.id, 'quay');
      expect(mutations.lastAppliedReceipt?.actionId, 'map.rename');
      expect(renamed.map?.id, 'quay');
      expect(renamed.revision, isNotNull);
      expect(await File(workspace.getMapPath(copy.id)).exists(), isFalse);

      final warp = await mutations.saveMap(
        harbor.copyWith(
          warps: const [
            MapWarp(
              id: 'go-to-quay',
              pos: GridPos(x: 0, y: 0),
              targetMapId: 'quay',
              targetPos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
        workspace.getMapPath('harbor'),
        expectedMapRevision: narrativeEventBytesFingerprint(original),
      );
      await expectLater(
        container
            .read(deleteMapUseCaseProvider)
            .execute(workspace, renamed.project, 'quay'),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.hasIncomingReferences,
            'incoming references',
            isTrue,
          ),
        ),
      );
      expect(await File(workspace.getMapPath('quay')).exists(), isTrue);
      await mutations.undo(
        root.path,
        entryId: warp.receipt.receiptId,
        idempotencyKey: 'undo-link-to-quay',
      );
      final harborFile = File(workspace.getMapPath('harbor'));
      await harborFile.delete();
      await expectLater(
        container
            .read(deleteMapUseCaseProvider)
            .execute(workspace, renamed.project, 'quay'),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.indexIssues.single.mapId,
            'missing map',
            'harbor',
          ),
        ),
      );
      expect(await File(workspace.getMapPath('quay')).exists(), isTrue);
      await harborFile.writeAsBytes(original, flush: true);

      final deleted = await container
          .read(deleteMapUseCaseProvider)
          .execute(workspace, renamed.project, 'quay');
      final removal = mutations.lastAppliedReceipt!;
      expect(removal.actionId, 'map.delete_apply');
      expect(removal.status, AuthoringReceiptStatus.applied);
      expect(deleted.maps.map((map) => map.id), ['harbor']);
      expect(await File(workspace.getMapPath('quay')).exists(), isFalse);

      await mutations.closeAll();
      await mutations.undo(
        root.path,
        entryId: removal.receiptId,
        idempotencyKey: 'undo-quay-removal',
      );
      final reopened = await repository.loadProject(
        workspace.projectManifestPath,
      );
      expect(reopened.maps.map((map) => map.id), ['harbor', 'quay']);
      expect(await File(workspace.getMapPath('quay')).exists(), isTrue);
      expect(
        await File(workspace.getMapPath('harbor')).readAsBytes(),
        original,
      );
      expect(jsonDecode(await manifestFile.readAsString())['legacyMetadata'], {
        'tag': 'retained',
      });
      expect(throwingProjects.saveCalls, 0);
    },
  );
}

final class _ThrowingProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls += 1;
    throw StateError('legacy project repository must not be called');
  }
}
