import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('publication transaction is unavailable without an open project', () {
    final container = ProviderContainer(
      overrides: <Override>[
        editorProjectRootPathProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(borderPublicationTransactionProvider), isNull);
  });

  test('publication transaction uses project-local filesystem adapters',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_border_publication_provider_',
    );
    addTearDown(() => root.delete(recursive: true));
    ProjectManifest? applied;
    final container = ProviderContainer(
      overrides: <Override>[
        editorProjectRootPathProvider.overrideWithValue(root.path),
        borderPublicationApplyInMemoryManifestProvider.overrideWithValue(
          (manifest) => applied = manifest,
        ),
      ],
    );
    addTearDown(container.dispose);

    final transaction = container.read(borderPublicationTransactionProvider);

    expect(transaction, isNotNull);
    expect(transaction!.snapshotStore, isA<FileBorderAssetSnapshotStore>());
    expect(
      transaction.manifestPort,
      isA<FileBorderPublicationManifestPort>(),
    );
    final validator = transaction.candidateValidator;
    expect(validator, isA<CoreBorderPublicationCandidateValidator>());
    expect(
      (validator as CoreBorderPublicationCandidateValidator).enabledTemplates,
      <BorderBlueprintTemplate>{BorderBlueprintTemplate.organicEdge},
    );
    const manifest = ProjectManifest(
      name: 'Provider',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
    transaction.manifestPort.applyInMemory(manifest);
    expect(applied, same(manifest));
  });

  test('publication coordinator follows project availability', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_border_coordinator_provider_',
    );
    addTearDown(() => root.delete(recursive: true));
    final withoutProject = ProviderContainer(
      overrides: <Override>[
        editorProjectRootPathProvider.overrideWithValue(null),
      ],
    );
    addTearDown(withoutProject.dispose);
    expect(
      withoutProject.read(borderStudioPublicationCoordinatorProvider),
      isNull,
    );

    final withProject = ProviderContainer(
      overrides: <Override>[
        editorProjectRootPathProvider.overrideWithValue(root.path),
        borderPublicationApplyInMemoryManifestProvider.overrideWithValue(
          (_) {},
        ),
      ],
    );
    addTearDown(withProject.dispose);
    expect(
      withProject.read(borderStudioPublicationCoordinatorProvider),
      isNotNull,
    );
  });

  test(
    'in-memory publication callback refuses to write into another project',
    () {
      const originalManifest = ProjectManifest(
        name: 'Original project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      const replacementManifest = ProjectManifest(
        name: 'Replacement project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/projects/original',
        project: originalManifest,
      );
      final transaction = container.read(borderPublicationTransactionProvider)!;

      notifier.state = const EditorState(
        projectRootPath: '/projects/replacement',
        project: replacementManifest,
      );

      expect(
        () => transaction.manifestPort.applyInMemory(originalManifest),
        throwsStateError,
      );
      expect(container.read(editorNotifierProvider).projectRootPath,
          '/projects/replacement');
      expect(
        container.read(editorNotifierProvider).project,
        same(replacementManifest),
      );
    },
  );

  test(
    'in-memory publication callback refuses a changed manifest at the same root',
    () {
      const originalManifest = ProjectManifest(
        name: 'Original project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      const replacementManifest = ProjectManifest(
        name: 'Replacement at same root',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/projects/original',
        project: originalManifest,
      );
      final transaction = container.read(borderPublicationTransactionProvider)!;

      notifier.state = const EditorState(
        projectRootPath: '/projects/original',
        project: replacementManifest,
      );

      expect(
        () => transaction.manifestPort.applyInMemory(originalManifest),
        throwsStateError,
      );
      expect(
        container.read(editorNotifierProvider).project,
        same(replacementManifest),
      );
    },
  );

  test(
    'real publication transaction cannot overwrite a draft changed while disk commit waits',
    () async {
      final originalManifest = _manifestWithDraft();
      final publishedManifest = originalManifest.copyWith(
        name: 'Published result',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/original',
        project: originalManifest,
      );
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier);
      final guardedApply = container.read(
        borderPublicationApplyInMemoryManifestProvider,
      );
      final manifestPort = _DelayedManifestPort(guardedApply);
      final transaction = BorderPublicationTransaction(
        snapshotStore: _EmptySnapshotStore(),
        manifestPort: manifestPort,
        candidateValidator: const _AllowEveryCandidate(),
      );

      final publication = transaction.publish(
        BorderPublicationRequest(
          previousManifest: originalManifest,
          nextManifest: publishedManifest,
          blueprintId: 'coast',
          resolverVersion: 1,
          snapshotIntegrity: const <String, BorderVisualSnapshotIntegrity>{},
          canonicalGalleryReport: BorderPublicationGalleryReport(
            resolverVersion: 1,
            canonicalGalleryVersion: borderCanonicalGalleryVersion,
            candidateFingerprint: 'sha256:${'a' * 64}',
            samples: const <BorderPublicationGallerySample>[],
          ),
          files: const <BorderSnapshotFilePayload>[],
        ),
      );
      await manifestPort.replaceStarted.future;

      controller.renameBlueprint('Edited while publication was pending');
      manifestPort.allowReplace.complete();

      await expectLater(
        publication,
        throwsA(
          isA<BorderPublicationTransactionException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationTransactionErrorCode
                    .publishedButMemoryRefreshFailed,
              )
              .having(
                (error) => error.manifestCommitted,
                'manifestCommitted',
                isTrue,
              ),
        ),
      );
      expect(manifestPort.atomicallyReplaced, isTrue);
      expect(
        controller.state.workingDraft!.blueprint.definition.name,
        'Edited while publication was pending',
      );
      expect(
        container.read(editorNotifierProvider).project,
        same(originalManifest),
      );
    },
  );
}

ProjectManifest _manifestWithDraft() => ProjectManifest(
      name: 'Original project with draft',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          BorderBlueprintRecord(
            id: 'coast',
            draft: BorderBlueprintDraft(
              baseRevision: 0,
              definition: BorderBlueprintDraftDefinition(
                name: 'Coast',
                previewSeed: BorderSignedInt64.fromInt(7),
                template: BorderBlueprintTemplate.organicEdge,
                primitives: const <BorderPrimitiveDraft>[],
                defaults: BorderGenerationParams(
                  irregularityPermille: 250,
                  detailDensityPermille: 500,
                  variationPermille: 300,
                  maxOverlapPx: 4,
                  gapTolerancePx: 1,
                  depthRows: 1,
                ),
                sortOrder: 0,
              ),
            ),
          ),
        ],
      ),
    );

final class _DelayedManifestPort implements BorderPublicationManifestPort {
  _DelayedManifestPort(this._applyInMemory);

  final void Function(ProjectManifest) _applyInMemory;
  final Completer<void> replaceStarted = Completer<void>();
  final Completer<void> allowReplace = Completer<void>();
  bool atomicallyReplaced = false;

  @override
  Future<void> atomicallyReplace({
    required ProjectManifest previousManifest,
    required ProjectManifest nextManifest,
  }) async {
    replaceStarted.complete();
    await allowReplace.future;
    atomicallyReplaced = true;
  }

  @override
  void applyInMemory(ProjectManifest manifest) => _applyInMemory(manifest);
}

final class _EmptySnapshotStore implements BorderAssetSnapshotStore {
  @override
  Future<BorderAssetSnapshotStage> stage(
    List<BorderSnapshotFilePayload> files,
  ) async =>
      BorderAssetSnapshotStage(
        id: 'empty-stage',
        files: const <BorderStagedSnapshotFile>[],
      );

  @override
  Future<BorderAssetSnapshotFinalizeResult> finalize(
    BorderAssetSnapshotStage stage,
  ) async =>
      BorderAssetSnapshotFinalizeResult(
        createdRelativePaths: const <String>[],
        deduplicatedRelativePaths: const <String>[],
      );

  @override
  Future<void> discard(BorderAssetSnapshotStage stage) async {}
}

final class _AllowEveryCandidate
    implements BorderPublicationCandidateValidator {
  const _AllowEveryCandidate();

  @override
  BorderDiagnosticsReport validate(BorderPublicationRequest request) =>
      const BorderDiagnosticsReport.empty();
}
