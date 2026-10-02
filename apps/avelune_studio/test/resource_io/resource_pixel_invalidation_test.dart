import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart' show AssetCatalog;

import 'resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'canonical pixels invalidate only their consumers and removed brush releases its image',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final first = await fixture.import();
      final second = await fixture.import();
      final a = first.createdTilesetId!;
      final b = second.createdTilesetId!;
      final added = await fixture.resources.saveElement(fixture.element(a));
      final view = MapWorkspaceViewState()
        ..brush = added.manifest.elements.single
        ..tool = StudioMapTool.paint;
      addTearDown(view.dispose);
      final resources = await StudioMapResources.load(
        fixture.session,
        added.manifest,
      );
      addTearDown(resources.dispose);
      final owner = Object();
      resources.retain(owner, {a, b});
      resources.setBrush(added.manifest.elements.single, null);
      await resources.settled;
      final beforeA = resources.images[a];
      final beforeB = resources.images[b];
      final renamed = await fixture.resources.prepareOperation(
        'tileset.metadata.update',
        {'tilesetId': a, 'name': 'Été en pixels', 'folderId': null},
      );
      final metadata = await fixture.resources.applyPrepared(renamed);
      view.reconcileResources(metadata.manifest);
      expect(view.brush!.id, 'tree');
      expect(view.tool, StudioMapTool.paint);
      await resources.updateCatalog(
        metadata.manifest,
        changedRelativePaths: metadata.changedPaths.toSet(),
      );
      expect(resources.images[a], same(beforeA));
      expect(resources.images[b], same(beforeB));
      final file = File('${fixture.root.path}/assets/.pokemap-assets.json');
      final assets = AssetCatalog.fromJson(
        jsonDecode(await file.readAsString()),
      );
      final asset = assets.records.singleWhere(
        (asset) =>
            asset.logicalPath ==
            metadata.manifest.tilesets
                .firstWhere((t) => t.id == a)
                .relativePath,
      );
      final pixels = image.Image(width: 64, height: 48);
      image.fill(pixels, color: image.ColorRgb8(220, 25, 25));
      await fixture.source.writeAsBytes(image.encodePng(pixels));
      final receipt = await fixture.resources.replaceAsset(
        asset.id,
        fixture.source.path,
      );
      await resources.updateCatalog(
        receipt.manifest,
        changedRelativePaths: receipt.changedPaths.toSet(),
      );
      await resources.settled;
      expect(resources.images[a], isNot(same(beforeA)));
      expect(resources.images[b], same(beforeB));
      expect(resources.store.decoder.decodes, 2);
      resources.release(owner);
      final removed = await fixture.resources.removeUnusedElement(
        'tree',
        confirm: true,
      );
      view.reconcileResources(removed.manifest);
      expect(view.brush, isNull);
      expect(view.tool, StudioMapTool.select);
      await resources.updateCatalog(
        removed.manifest,
        changedRelativePaths: removed.changedPaths.toSet(),
      );
      expect(resources.elements, isNot(contains('tree')));
      expect(resources.store.priority, isEmpty);
    },
  );
}
