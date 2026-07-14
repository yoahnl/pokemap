import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';

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
    const manifest = ProjectManifest(
      name: 'Provider',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
    transaction.manifestPort.applyInMemory(manifest);
    expect(applied, same(manifest));
  });
}
