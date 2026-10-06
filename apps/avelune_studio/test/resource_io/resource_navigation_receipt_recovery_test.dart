import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart' show AssetCatalog;
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in ['prepared metadata', 'asset-only mutation']) {
    test(
      '$kind retains publication receipt and reconciles without replay',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        final imported = await fixture.import();
        var fail = true;
        final adapter = LocalResourceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          beforeReconciliation: () async {
            if (fail) throw StateError('Injected reconciliation failure');
          },
        );
        addTearDown(adapter.dispose);
        final workspace = MapWorkspaceController(fixture.session, fixture.maps);
        await workspace.initialize();
        addTearDown(workspace.dispose);
        final navigation = ResourceNavigation(
          workspace: workspace,
          port: adapter,
          visuals: WorkspaceTestVisuals(),
          onUse: (_) {},
        );
        addTearDown(navigation.dispose);
        if (kind == 'prepared metadata') {
          final preparation = await navigation
              .prepareOperation('tileset.metadata.update', {
                'tilesetId': imported.createdTilesetId,
                'name': 'Publication conservée',
                'folderId': null,
              });
          await expectLater(
            navigation.applyPrepared(preparation),
            throwsA(isA<ResourceFailure>()),
          );
        } else {
          final assets = AssetCatalog.fromJson(
            jsonDecode(
              await File(
                '${fixture.root.path}/assets/.pokemap-assets.json',
              ).readAsString(),
            ),
          );
          await expectLater(
            navigation.mutate('asset.move', {
              'assetId': assets.records.single.id,
              'logicalPath': 'library/retained.png',
            }),
            throwsA(isA<ResourceFailure>()),
          );
        }
        expect(navigation.pendingReceipt, isNotNull);
        expect(navigation.error, contains('publication'));
        final manifest = await fixture.manifestFile.readAsBytes();
        final map = await fixture.mapFile.readAsBytes();
        final assetFile = File(
          '${fixture.root.path}/assets/.pokemap-assets.json',
        );
        final assets = await assetFile.readAsBytes();
        fail = false;
        expect(await navigation.retryReconciliation(), true);
        expect(navigation.pendingReceipt, isNull);
        expect(navigation.error, isNull);
        expect(await fixture.manifestFile.readAsBytes(), manifest);
        expect(await fixture.mapFile.readAsBytes(), map);
        expect(await assetFile.readAsBytes(), assets);
      },
    );
  }
  for (final owner in ['decor', 'environment']) {
    test(
      '$owner rebases only its published draft after a refresh failure',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        final imported = await fixture.import();
        final element = fixture.element(imported.createdTilesetId!);
        await fixture.resources.saveElement(element);
        var fail = true;
        late ResourceNavigation navigation;
        final adapter = LocalResourceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          beforeReconciliation: () async {
            if (!fail) return;
            if (owner == 'decor') {
              navigation.decor!.name = 'Saisie ultérieure';
            } else {
              navigation.environment!.name = 'Saisie ultérieure';
            }
            throw StateError('Injected reconciliation failure');
          },
        );
        addTearDown(adapter.dispose);
        final workspace = MapWorkspaceController(fixture.session, fixture.maps);
        await workspace.initialize();
        addTearDown(workspace.dispose);
        navigation = ResourceNavigation(
          workspace: workspace,
          port: adapter,
          visuals: WorkspaceTestVisuals(),
          onUse: (_) {},
        );
        addTearDown(navigation.dispose);
        Future<void> save() => owner == 'decor'
            ? navigation.saveDecor(navigation.decor!.build())
            : navigation.saveEnvironment();
        if (owner == 'decor') {
          final current = workspace.project!.elements.single;
          navigation.edit(
            ResourceItem(
              id: current.id,
              name: current.name,
              kind: ResourceKind.decors,
              element: current,
            ),
          );
          navigation.decor!.name = 'Publication conservée';
        } else {
          navigation.openEnvironment();
          navigation.environment!
            ..name = 'Publication conservée'
            ..add(element.id);
        }
        await expectLater(save(), throwsA(isA<ResourceFailure>()));
        expect(navigation.pendingReceipt, isNotNull);
        expect(navigation.dirty, isTrue);
        expect(
          navigation.page,
          owner == 'decor' ? ResourcePage.decor : ResourcePage.environment,
        );
        final published = await fixture.manifestFile.readAsBytes();
        final manifest = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(published)),
        );
        expect(
          owner == 'decor'
              ? manifest.elements.single.name
              : manifest.environmentPresets.single.name,
          'Publication conservée',
        );
        fail = false;
        expect(await navigation.retryReconciliation(), isTrue);
        expect(await fixture.manifestFile.readAsBytes(), published);
        expect(
          owner == 'decor'
              ? navigation.decor!.name
              : navigation.environment!.name,
          'Saisie ultérieure',
        );
        await save();
        final reopened = ProjectManifest.fromJson(
          jsonDecode(await fixture.manifestFile.readAsString()),
        );
        expect(
          owner == 'decor'
              ? reopened.elements.single.name
              : reopened.environmentPresets.single.name,
          'Saisie ultérieure',
        );
        expect(navigation.pendingReceipt, isNull);
      },
    );
  }
}
