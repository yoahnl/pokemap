import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_transfer_controller_test.dart'
    show PackTestPort;

class _FailingRecoveryPort extends PackTestPort {
  int recoveryAttempts = 0;
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'start_recovery' && ++recoveryAttempts == 1) {
      throw const ResourceFailure('Relecture indisponible');
    }
    return super.transfer(verb, input);
  }
}

void main() {
  test('retained reconciliationRequired keeps its phase and close block until a retry succeeds', () async {
    final port = PackTestPort();
    var accepts = 0;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/retained.aveluneassets',
      accept: (_) async {
        if (++accepts <= 2) throw const ResourceFailure('Relecture indisponible');
      },
    );
    addTearDown(controller.dispose);
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.phase, ResourcePackTransferPhase.reconciliationRequired);
    expect(port.applies, 1);
    expect(controller.blocksClose, isTrue);
    expect(await controller.requestClose(), isFalse);

    expect(await controller.retryReconciliation(), isFalse);
    expect(controller.phase, ResourcePackTransferPhase.reconciliationRequired);
    expect(controller.error, 'Relecture indisponible');
    expect(controller.blocksClose, isTrue);
    expect(port.applies, 1);
    expect(await controller.requestClose(), isFalse);

    expect(await controller.retryReconciliation(), isTrue);
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(controller.error, isNull);
    expect(controller.blocksClose, isFalse);
    expect(port.applies, 1);
    expect(accepts, 3);
  });

  test('retained recoveryRequired keeps its phase and close block until recovery succeeds', () async {
    final port = _FailingRecoveryPort()..lateFailure = true;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/retained.aveluneassets',
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.phase, ResourcePackTransferPhase.recoveryRequired);
    expect(controller.blocksClose, isTrue);

    await controller.recover();
    expect(controller.phase, ResourcePackTransferPhase.recoveryRequired);
    expect(controller.error, 'Relecture indisponible');
    expect(controller.blocksClose, isTrue);
    expect(port.recoveredOperation, isNull);

    await controller.recover();
    expect(controller.phase, isNot(ResourcePackTransferPhase.recoveryRequired));
    expect(controller.error, isNull);
    expect(port.recoveredOperation, port.appliedOperation);
    expect(port.applies, 1);
    expect(controller.blocksClose, isFalse);
  });

  test('marks survive a query that hides them and clearMarks empties them', () {
    final state = ResourceLibraryState();
    const tree = ResourceItem(id: 'tree', name: 'Arbre', kind: ResourceKind.decors);
    const rock = ResourceItem(id: 'rock', name: 'Rocher', kind: ResourceKind.decors);
    state
      ..toggleMark(tree)
      ..toggleMark(rock);
    expect(state.marked, {tree.identity, rock.identity});
    state.query = 'Arbre';
    expect(state.visibleItems([tree, rock]), [tree]);
    expect(state.marked, {tree.identity, rock.identity});
    expect(state.markedItems([tree, rock]), [tree, rock]);
    state.query = '';
    state.sort = ResourceSort.nameDescending;
    expect(state.marked, {tree.identity, rock.identity});
    state.clearMarks();
    expect(state.marked, isEmpty);
    expect(state.marking, isTrue);
    state.toggleMark(tree);
    state.clearMarks(stopMarking: true);
    expect(state.marking, isFalse);
  });
}
