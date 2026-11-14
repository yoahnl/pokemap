import 'dart:async';

import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_pack_transfer_test_ports.dart';

void main() {
  test('pack notification preserves busy ownership of an ordinary resource mutation', () async {
    final workspace = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    await workspace.initialize();
    final resource = WaitingResourcePort();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: resource,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
      packPort: PackTestPort(),
      packPicker: () async => '/chosen.aveluneassets',
    );
    await navigation.packTransfer!.beginImport();
    final mutation = navigation.mutate('test.wait', {});
    await navigation.packTransfer!.setFilter(context: 'interior');
    expect(navigation.busy, isTrue);
    resource.completion.complete(PackTestPort().receipt);
    await mutation;
    expect(navigation.busy, isFalse);
    navigation.dispose();
    workspace.dispose();
  });
  test(
    'obsolete filter failures and disposed picker failures are ignored',
    () async {
      final port = DelayedQueryPackPort();
      final controller = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await controller.beginImport();
      final oldPage = controller.setFilter(context: 'exterior');
      await port.entered.future;
      await controller.setFilter(context: 'interior');
      port.result.completeError(StateError('obsolete page'));
      await oldPage;
      expect(controller.error, isNull);
      expect(controller.visibleCount, 1);
      controller.dispose();
      final picker = Completer<String?>();
      final disposed = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () => picker.future,
        accept: (_) async {
          fail('old session cannot accept');
        },
      );
      final pending = disposed.beginImport();
      await Future<void>.delayed(Duration.zero);
      disposed.dispose();
      picker.completeError(StateError('old picker'));
      await pending;
    },
  );
  test(
    'picker cancellation and invalid inspection preserve the project',
    () async {
      final port = PackTestPort();
      final cancelled = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        accept: (_) async {},
      );
      await cancelled.beginImport();
      expect(port.verbs, isEmpty);
      port.invalidInspection = true;
      final invalid = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await invalid.beginImport();
      expect(invalid.error, isNotNull);
      expect(port.applies, 0);
      expect(port.authorized, '/chosen.aveluneassets');
      cancelled.dispose();
      invalid.dispose();
    },
  );

  test('select all is server side and hidden selection is retained', () async {
    final port = PackTestPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
    );
    await controller.beginImport();
    await controller.selectFiltered();
    expect(controller.selectedCount, 10000);
    await controller.setFilter(context: 'interior', familyId: 'forest');
    expect(controller.filter['familyId'], 'forest');
    expect(controller.families.single['label'], 'Forêt');
    await controller.selectFiltered();
    expect(
      (port.inputs.lastWhere((input) => input.containsKey('filter'))['filter']
          as Map)['familyId'],
      'forest',
    );
    expect(controller.selectedCount, 10000);
    expect(controller.visibleCount, 1);
    expect(controller.entries.length, 1);
    final request =
        port.inputs[port.verbs.indexOf('selection.select_filtered')];
    expect(
      request.keys,
      containsAll(['selectionHandle', 'revision', 'filter']),
    );
    expect(request.keys, isNot(contains('add')));
    controller.dispose();
  });

  test('successful commit with failed refresh retries reconciliation without apply', () async {
    final port = PackTestPort();
    var accepts = 0;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {
        if (++accepts == 1) throw const ResourceFailure('refresh failed');
      },
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.requiresReconciliation, isTrue);
    expect(controller.notice, contains('Import terminé'));
    expect(await controller.requestClose(), isFalse);
    expect(await controller.retryReconciliation(), isTrue);
    expect(port.applies, 1);
    expect(accepts, 2);
    controller.dispose();
  });

  test('late failed job remains blocked until canonical recovery', () async {
    final port = PackTestPort()..lateFailure = true;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.requiresRecovery, isTrue);
    expect(await controller.requestClose(), isFalse);
    await controller.recover();
    expect(controller.requiresRecovery, isFalse);
    expect(port.recoveredOperation, port.appliedOperation);
    expect(port.applies, 1);
    controller.dispose();
  });
}
