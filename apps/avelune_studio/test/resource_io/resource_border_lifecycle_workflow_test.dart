import 'package:avelune_studio/features/resources/application/resource_border_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_border_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_replacement_fixture.dart';

Future<ResourceReplacementFixture> _open({
  Future<void> Function()? beforeReconciliation,
}) async {
  final host = await ResourceReplacementFixture.create(
    beforeReconciliation: beforeReconciliation,
  );
  for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
    await host.navigation.accept(
      await host.fixture.resources.saveElement(
        host.fixture
            .element(host.item.id, id: id)
            .copyWith(
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
      ),
    );
  }
  for (final request in [
    const BorderCreationRequest(
      blueprintId: 'fence',
      name: 'Clôture',
      capElementId: 'cap',
      straightElementId: 'straight',
      cornerElementId: 'corner',
    ),
    const BorderCreationRequest(
      blueprintId: 'draft',
      name: 'Préparation',
      publish: false,
    ),
  ]) {
    await host.navigation.accept(
      await host.fixture.resources.createBorder(request),
    );
  }
  return host;
}

Future<void> _manage(
  ResourceReplacementFixture host,
  BorderResourceAction action,
  Future<void> Function(ResourceBorderLifecycleController) present, {
  String id = 'fence',
}) => runBorderResourceManagement(
  navigation: host.navigation,
  record: host.navigation.workspace.project!.borderCatalog.recordById(id)!,
  action: action,
  isActive: () => true,
  present: present,
  presentUsages: (_, _, _) async {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'deprecation and reactivation preserve published revisions and sources',
    () async {
      final host = await _open();
      final before = await host.reopen();
      final map = await host.fixture.mapFile.readAsBytes();
      final original = before.borderCatalog.recordById('fence')!;
      final results = <String?>[];
      for (final action in [
        BorderResourceAction.deprecate,
        BorderResourceAction.reactivate,
      ]) {
        await _manage(host, action, (controller) async {
          await controller.prepare();
          controller.confirm(true);
          results.add(await controller.apply());
        });
        final current = (await host.reopen()).borderCatalog.recordById(
          'fence',
        )!;
        expect(current.isDeprecated, action == BorderResourceAction.deprecate);
        expect(current.latestPublished, original.latestPublished);
        expect(current.draft, original.draft);
      }
      final after = await host.reopen();
      expect(results, [null, null]);
      expect(after.elements, before.elements);
      expect(after.tilesets, before.tilesets);
      expect(await host.fixture.mapFile.readAsBytes(), map);
      expect(host.navigation.managementDialogActive, isFalse);
    },
  );

  test(
    'a dirty border owner refuses withdrawal without deleting its draft',
    () async {
      final host = await _open();
      final before = await host.fixture.manifestFile.readAsBytes();
      host.navigation.borderEditorOwners['draft'] = () => true;
      String? refusal;
      bool? canApply;
      await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
        await controller.prepare();
        controller.confirm(true);
        refusal = controller.error;
        canApply = controller.canApply;
      }, id: 'draft');
      expect(refusal, contains('Préparation'));
      expect(canApply, isFalse);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test(
    'cancelling a border mutation releases its canonical preparation',
    () async {
      final host = await _open();
      final before = await host.fixture.manifestFile.readAsBytes();
      late ResourceMutationPreparation preparation;
      await _manage(host, BorderResourceAction.deleteDraft, (controller) async {
        await controller.prepare();
        preparation = controller.preparation!;
      }, id: 'draft');
      await expectLater(
        host.navigation.applyPrepared(preparation, confirmDestructive: true),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test(
    'stale border confirmation preserves the publication and concurrent draft',
    () async {
      final host = await _open();
      final before = (await host.reopen()).borderCatalog.recordById('fence');
      String? result;
      await _manage(host, BorderResourceAction.deprecate, (controller) async {
        await controller.prepare();
        await host.fixture.resources.createBorder(
          const BorderCreationRequest(
            blueprintId: 'concurrent',
            name: 'Travail concurrent',
            publish: false,
          ),
        );
        controller.confirm(true);
        result = await controller.apply();
      });
      final reopened = await host.reopen();
      expect(result, isNotNull);
      expect(reopened.borderCatalog.recordById('fence'), before);
      expect(reopened.borderCatalog.recordById('concurrent'), isNotNull);
      expect(reopened.borderCatalog.records, hasLength(3));
    },
  );

  test('border publication retains its receipt and prevents replay after reconciliation', () async {
    var fail = false;
    final host = await _open(
      beforeReconciliation: () async {
        if (fail) throw StateError('Injected refresh failure');
      },
    );
    fail = true;
    String? error, replayError;
    bool? retained, recovered;
    List<int>? published, afterReplay;
    await _manage(host, BorderResourceAction.deprecate, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      error = await controller.apply();
      retained = host.navigation.pendingReceipt != null;
      published = await host.fixture.manifestFile.readAsBytes();
      fail = false;
      recovered = await host.navigation.retryReconciliation();
      replayError = await controller.apply();
      afterReplay = await host.fixture.manifestFile.readAsBytes();
    });
    expect(error, contains('Publication effectuée'));
    expect(retained, isTrue);
    expect(recovered, isTrue);
    expect(replayError, isNotNull);
    expect(published, isNotNull);
    expect(afterReplay, published);
    expect(
      (await host.reopen()).borderCatalog.recordById('fence')!.isDeprecated,
      isTrue,
    );
  });

  test(
    'usage management targets the exact blueprint without preparing a mutation',
    () async {
      final host = await _open();
      final before = await host.fixture.manifestFile.readAsBytes();
      ResourceUsageTarget? target;
      String? name;
      var confirmations = 0;
      await runBorderResourceManagement(
        navigation: host.navigation,
        record: host.navigation.workspace.project!.borderCatalog.recordById(
          'fence',
        )!,
        action: BorderResourceAction.usages,
        isActive: () => true,
        present: (_) async {
          confirmations++;
        },
        presentUsages: (value, label, _) async {
          target = value;
          name = label;
        },
      );
      expect(target!.family, 'borders');
      expect(target!.id, 'fence');
      expect(name, 'Clôture');
      expect(confirmations, 0);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(host.navigation.managementDialogActive, isFalse);
    },
  );
}
