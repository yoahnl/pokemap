import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart' show AssetCatalog;

import 'resource_fixture.dart';

void main() {
  test(
    'asset-only mutation retains manifest bytes and reports catalogue change',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      await fixture.import();
      final catalog = File('${fixture.root.path}/assets/.pokemap-assets.json');
      final assets = AssetCatalog.fromJson(
        jsonDecode(await catalog.readAsString()) as Map<String, dynamic>,
      );
      final projectBefore = await fixture.manifestFile.readAsBytes();
      final mapBefore = await fixture.mapFile.readAsBytes();
      final receipt = await fixture.resources.mutate('asset.move', {
        'assetId': assets.records.single.id,
        'logicalPath': 'library/renamed.png',
      });
      expect(receipt.changedPaths.toSet(), {
        'assets/.pokemap-assets.json',
        assets.records.single.logicalPath,
        'library/renamed.png',
      });
      expect(receipt.resourceRevisions, isNotEmpty);
      expect(receipt.snapshotBeforeRevision, isNotNull);
      expect(receipt.revision, receipt.beforeRevision);
      expect(receipt.manifest, receipt.before);
      expect(await fixture.manifestFile.readAsBytes(), projectBefore);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      final reopened = AssetCatalog.fromJson(
        jsonDecode(await catalog.readAsString()) as Map<String, dynamic>,
      );
      expect(reopened.records.single.logicalPath, 'library/renamed.png');
      expect(reopened.records.single.id, assets.records.single.id);
      expect(reopened.records.single.artifact, assets.records.single.artifact);
    },
  );
}
