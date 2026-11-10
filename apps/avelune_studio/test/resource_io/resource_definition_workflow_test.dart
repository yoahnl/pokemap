import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_definition_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

Future<
  ({ResourceFixture fixture, ResourceNavigation navigation, ResourceItem item})
>
_open({
  bool placed = false,
  Future<void> Function()? beforeReconciliation,
}) async {
  final parent = Directory(
    '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/resource-definition',
  );
  await parent.create(recursive: true);
  final fixture = await ResourceFixture.create(parent: parent);
  addTearDown(() async {
    await fixture.dispose();
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  });
  final imported = await fixture.import();
  await fixture.resources.mutate('element_category.upsert', {
    'category': {'id': 'nature', 'name': 'Nature'},
  });
  await fixture.resources.saveElement(
    fixture.element(imported.createdTilesetId!).copyWith(categoryId: 'nature'),
  );
  if (placed) {
    final document = await fixture.loadMap();
    await fixture.maps.saveMap(
      fixture.session,
      document,
      document.map.copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'placed-tree',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
  }
  final adapter = LocalResourceAdapter(
    session: fixture.session,
    mapAdapter: fixture.maps,
    beforeReconciliation: beforeReconciliation,
  );
  addTearDown(adapter.dispose);
  final workspace = MapWorkspaceController(fixture.session, fixture.maps);
  addTearDown(workspace.dispose);
  await workspace.initialize();
  final navigation = ResourceNavigation(
    workspace: workspace,
    port: adapter,
    visuals: WorkspaceTestVisuals(),
    onUse: (_) {},
  );
  addTearDown(navigation.dispose);
  return (
    fixture: fixture,
    navigation: navigation,
    item: resourceCatalog(workspace.project!)
        .singleWhere((item) => item.element?.id == 'tree'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'duplicate publishes an independent definition and preserves the map',
    () async {
      final host = await _open(placed: true);
      final navigation = host.navigation;
      final before = navigation.workspace.project!;
      final map = await host.fixture.mapFile.readAsBytes();
      var confirmations = 0;
      String? result = 'Not presented';
      await runResourceDefinitionDuplicate(
        navigation: navigation,
        item: host.item,
        isActive: () => true,
        confirmOwnerSave: () async {
          confirmations++;
          return true;
        },
        present: (session) async {
          session.name = 'Copie indépendante';
          result = await session.apply();
        },
      );
      final reopened = await host.fixture.maps.loadProject(
        host.fixture.session,
      );
      final copied = reopened.elements.singleWhere(
        (element) => element.name == 'Copie indépendante',
      );
      expect(result, isNull);
      expect(confirmations, 0);
      expect(copied.id, isNot(host.item.id));
      expect(copied.frames, host.item.element!.frames);
      expect(copied.tilesetId, host.item.element!.tilesetId);
      expect(reopened.tilesets, before.tilesets);
      expect(await host.fixture.mapFile.readAsBytes(), map);
      expect(navigation.decor!.original!.id, copied.id);
      expect(navigation.managementDialogActive, isFalse);
    },
  );

  test(
    'duplicate cancellation keeps the focused owner and its saved source',
    () async {
      final host = await _open();
      final navigation = host.navigation;
      navigation.edit(host.item);
      navigation.decor!.name = 'Brouillon conservé';
      final before = await host.fixture.manifestFile.readAsBytes();
      var presentations = 0;
      await runResourceDefinitionDuplicate(
        navigation: navigation,
        item: host.item,
        isActive: () => true,
        confirmOwnerSave: () async => false,
        present: (_) async {
          presentations++;
        },
      );
      expect(presentations, 0);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(
        navigation.decorDraftFor(host.item.id)!.name,
        'Brouillon conservé',
      );
      expect(navigation.managementDialogActive, isFalse);
    },
  );

  test('duplicate saves the owner only after explicit agreement', () async {
    final host = await _open();
    final navigation = host.navigation;
    navigation.edit(host.item);
    navigation.decor!.name = 'Nom enregistré';
    var confirmations = 0;
    String? initialName;
    String? result = 'Not presented';
    await runResourceDefinitionDuplicate(
      navigation: navigation,
      item: host.item,
      isActive: () => true,
      confirmOwnerSave: () async {
        confirmations++;
        return true;
      },
      present: (session) async {
        initialName = session.name;
        result = await session.apply();
      },
    );
    final reopened = await host.fixture.maps.loadProject(host.fixture.session);
    expect(confirmations, 1);
    expect(initialName, 'Nom enregistré — copie');
    expect(result, isNull);
    expect(
      reopened.elements.map((element) => element.name),
      containsAll(['Nom enregistré', 'Nom enregistré — copie']),
    );
  });

  test(
    'used removal refuses without changing persisted data and opens usages',
    () async {
      final host = await _open(placed: true);
      final before = await host.fixture.manifestFile.readAsBytes();
      final map = await host.fixture.mapFile.readAsBytes();
      var usages = 0;
      var managementActiveWhenOpeningUsages = true;
      ResourceMutationPreparation? preparation;
      String? preparationError;
      String? result;
      await runResourceDefinitionRemoval(
        navigation: host.navigation,
        item: host.item,
        isActive: () => true,
        confirmOwnerSave: () async => true,
        present: (controller) async {
          await controller.prepare();
          preparation = controller.preparation;
          preparationError = controller.error;
          controller.confirm(true);
          result = await controller.apply();
          controller.requestUsages();
        },
        openUsages: () async {
          managementActiveWhenOpeningUsages =
              host.navigation.managementDialogActive;
          usages++;
        },
      );
      expect(usages, 1);
      expect(managementActiveWhenOpeningUsages, isFalse);
      expect(preparation, isNull);
      expect(preparationError, isNotNull);
      expect(result, isNotNull);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(await host.fixture.mapFile.readAsBytes(), map);
    },
  );

  test('cancelled removal releases the prepared mutation', () async {
    final host = await _open();
    final before = await host.fixture.manifestFile.readAsBytes();
    late ResourceMutationPreparation preparation;
    await runResourceDefinitionRemoval(
      navigation: host.navigation,
      item: host.item,
      isActive: () => true,
      confirmOwnerSave: () async => true,
      present: (controller) async {
        await controller.prepare();
        preparation = controller.preparation!;
      },
    );
    await expectLater(
      host.navigation.applyPrepared(preparation, confirmDestructive: true),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await host.fixture.manifestFile.readAsBytes(), before);
    expect(host.navigation.managementDialogActive, isFalse);
  });

  for (final duplicate in [false, true]) {
    test(
      '${duplicate ? 'duplicate' : 'removal'} reconciles without replaying publication',
      () async {
        var failReconciliation = true;
        final host = await _open(
          beforeReconciliation: () async {
            if (failReconciliation) {
              throw StateError('Injected refresh failure');
            }
          },
        );
        final navigation = host.navigation;
        final map = await host.fixture.mapFile.readAsBytes();
        String? publicationError;
        String? replayError;
        bool? receiptRetained;
        bool? receiptCleared;
        bool? reconciled;
        List<int>? published;
        List<int>? afterReplay;
        Future<void> publishAndReconcile(
          Future<String?> Function() apply,
        ) async {
          publicationError = await apply();
          receiptRetained = navigation.pendingReceipt != null;
          published = await host.fixture.manifestFile.readAsBytes();
          failReconciliation = false;
          reconciled = await navigation.retryReconciliation();
          receiptCleared = navigation.pendingReceipt == null;
          replayError = await apply();
          afterReplay = await host.fixture.manifestFile.readAsBytes();
        }

        if (duplicate) {
          await runResourceDefinitionDuplicate(
            navigation: navigation,
            item: host.item,
            isActive: () => true,
            confirmOwnerSave: () async => true,
            present: (session) => publishAndReconcile(session.apply),
          );
        } else {
          await runResourceDefinitionRemoval(
            navigation: navigation,
            item: host.item,
            isActive: () => true,
            confirmOwnerSave: () async => true,
            present: (controller) async {
              await controller.prepare();
              controller.confirm(true);
              await publishAndReconcile(controller.apply);
            },
          );
        }
        final reopened = await host.fixture.maps.loadProject(
          host.fixture.session,
        );
        expect(publicationError, contains('Publication effectuée'));
        expect(receiptRetained, isTrue);
        expect(reconciled, isTrue);
        expect(receiptCleared, isTrue);
        expect(replayError, isNotNull);
        expect(published, isNotNull);
        expect(afterReplay, published);
        expect(reopened.elements, hasLength(duplicate ? 2 : 0));
        expect(await host.fixture.mapFile.readAsBytes(), map);
        expect(navigation.managementDialogActive, isFalse);
      },
    );
  }
}
