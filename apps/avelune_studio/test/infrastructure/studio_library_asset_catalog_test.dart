import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/platform/rendering/studio_library_image_preview.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        AssetCatalog,
        AssetRecord,
        ContentArtifactRef,
        ProjectSnapshotException,
        assetBlobStorageKey,
        assetCatalogStorageKey;
import 'package:map_core/map_core.dart';

import '../support/resource_stress_fixture.dart';
import 'studio_resource_catalog_update_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'first library previews share the asset registry loaded for the map',
    () async {
      final fixture = await ResourceStressFixture.create();
      addTearDown(fixture.dispose);
      final registry = File(
        '${fixture.directory.path}/$assetCatalogStorageKey',
      );
      final validRegistry = jsonEncode(AssetCatalog().toJson());
      await registry.writeAsString(validRegistry);
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
      );
      addTearDown(resources.dispose);
      expect(resources.paths, contains(fixture.lateAtlasId));

      final source = AtlasPreviewSource(fixture.lateAtlasId);
      final preview = resources.scopedResourcePreview(
        source,
        fixture.manifest,
        size: 112,
      ) as StudioLibraryImagePreview;
      final thumbnails = await Future.wait([
        preview.cache.scope(source, fixture.manifest),
        preview.cache.scope(source, fixture.manifest),
      ]);
      for (final thumbnail in thumbnails) {
        expect(thumbnail?.tilesets, contains(fixture.lateAtlasId));
      }
      await resources.updateCatalog(fixture.manifest);
      expect(resources.assetCatalogReads, 1);

      await registry.writeAsString('{');
      await expectLater(
        resources.updateCatalog(fixture.manifest),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.asset_catalog_invalid',
          ),
        ),
      );
      await registry.writeAsString(validRegistry);
      await resources.updateCatalog(fixture.manifest);
      expect(await preview.cache.scope(source, fixture.manifest), isNotNull);
      expect(resources.assetCatalogReads, 3);
      await resources.updateCatalog(
        fixture.manifest,
        changedRelativePaths: {assetCatalogStorageKey},
      );
      expect(await preview.cache.scope(source, fixture.manifest), isNotNull);
      expect(resources.assetCatalogReads, 4);
    },
  );

  for (final warm in [false, true]) {
    test(
      '${warm ? 'refresh' : 'first preview'} observes a managed PNG imported after map opening',
      () async {
        final fixture = await ResourceStressFixture.create();
        addTearDown(fixture.dispose);
        final registry = File(
          '${fixture.directory.path}/$assetCatalogStorageKey',
        );
        await registry.writeAsString(jsonEncode(AssetCatalog().toJson()));
        final resources = await StudioMapResources.load(
          fixture.session,
          fixture.manifest,
        );
        addTearDown(resources.dispose);
        if (warm) {
          final oldSource = AtlasPreviewSource(fixture.lateAtlasId);
          final oldPreview = resources.scopedResourcePreview(
            oldSource,
            fixture.manifest,
            size: 112,
          ) as StudioLibraryImagePreview;
          expect(
            await oldPreview.cache.scope(oldSource, fixture.manifest),
            isNotNull,
          );
        }
        const id = 'imported';
        final png = await pngBytes(32, 16, 0xff147ad1);
        final artifact = ContentArtifactRef.fromBytes(
          png,
          mediaType: 'image/png',
        );
        final blob = File(
          '${fixture.directory.path}/${assetBlobStorageKey(artifact)}',
        );
        await blob.parent.create(recursive: true);
        await blob.writeAsBytes(png);
        final catalog = AssetCatalog(
          records: [
            AssetRecord(
              id: id,
              logicalPath: 'assets/imported.png',
              artifact: artifact,
            ),
          ],
        );
        await registry.writeAsString(jsonEncode(catalog.toJson()));
        if (warm) resources.refreshResourcePreviews();
        final project = fixture.manifest.copyWith(
          tilesets: [
            ...fixture.manifest.tilesets,
            const ProjectTilesetEntry(
              id: id,
              name: 'Import MCP',
              relativePath: 'assets/imported.png',
            ),
          ],
        );
        const source = AtlasPreviewSource(id);
        final preview = resources.scopedResourcePreview(
          source,
          project,
          size: 112,
        ) as StudioLibraryImagePreview;
        final thumbnail = (await preview.cache.scope(source, project))!;
        final loaded = Completer<void>();
        void changed() {
          if (!loaded.isCompleted &&
              (thumbnail.images.containsKey(id) ||
                  thumbnail.hasFailure({id}))) {
            loaded.complete();
          }
        }

        final owner = Object();
        thumbnail.addListener(changed);
        try {
          thumbnail.retain(owner, {id});
          await loaded.future.timeout(const Duration(seconds: 5));
          expect(thumbnail.images[id]?.width, 32);
          expect(thumbnail.images[id]?.height, 16);
          await resources.updateCatalog(project);
          expect(resources.paths[id], blob.resolveSymbolicLinksSync());
          expect(resources.assetCatalogReads, 2);
        } finally {
          thumbnail.removeListener(changed);
          thumbnail.release(owner);
        }
      },
    );
  }
}
