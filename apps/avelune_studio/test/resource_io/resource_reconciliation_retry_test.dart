import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart' show AssetCatalog;

import 'resource_fixture.dart';

void main() {
  for (final kind in ['manifest', 'asset-only']) {
    test(
      '$kind publication receipt re-reads current revision without replay',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        final imported = await fixture.import();
        var failRefresh = true;
        final adapter = LocalResourceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          beforeReconciliation: () async {
            if (failRefresh) throw StateError('Injected UI acceptance failure');
          },
        );
        addTearDown(adapter.dispose);
        ResourceFailure? failure;
        try {
          if (kind == 'manifest') {
            final prepared = await adapter
                .prepareOperation('tileset.metadata.update', {
                  'tilesetId': imported.createdTilesetId,
                  'name': 'Façades été',
                  'folderId': null,
                });
            await adapter.applyPrepared(prepared);
          } else {
            final file = File(
              '${fixture.root.path}/assets/.pokemap-assets.json',
            );
            final catalogue = AssetCatalog.fromJson(
              jsonDecode(await file.readAsString()),
            );
            await adapter.mutate('asset.move', {
              'assetId': catalogue.records.single.id,
              'logicalPath': 'library/renamed.png',
            });
          }
        } on ResourceFailure catch (error) {
          failure = error;
        }
        expect(failure, isNotNull);
        final receipt = failure!.partialReceipt;
        expect(receipt, isNotNull);
        final project = await fixture.manifestFile.readAsBytes();
        final map = await fixture.mapFile.readAsBytes();
        final assetFile = File(
          '${fixture.root.path}/assets/.pokemap-assets.json',
        );
        final assets = await assetFile.readAsBytes();
        failRefresh = false;
        await adapter.reconcileReceipt(receipt!);
        expect(await fixture.manifestFile.readAsBytes(), project);
        expect(await fixture.mapFile.readAsBytes(), map);
        expect(await assetFile.readAsBytes(), assets);
        if (kind == 'manifest') {
          final reopened = LocalMapWorkspaceAdapter();
          expect(
            (await reopened.loadProject(fixture.session)).tilesets.single.name,
            'Façades été',
          );
        }
      },
    );
  }
}
