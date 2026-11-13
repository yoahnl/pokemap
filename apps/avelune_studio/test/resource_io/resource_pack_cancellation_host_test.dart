import 'dart:async';



import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionCheckpoint, AuthoringTransactionSimulatedCrash;

import '../application/resource_pack_transfer_controller_test.dart'
    show PackTestPort;
import 'resource_pack_import_host_test.dart' show ResourcePackTestHost;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('late native crash keeps the project blocked until original operation recovery', () async {
    var injected = false;
    String? operation;
    final host = await ResourcePackTestHost.create(
      faultInjector: (context) {
        if (!injected &&
            context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted) {
          injected = true;
          operation = context.operationId;
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    expect(injected, isTrue);
    expect(host.transfer.requiresRecovery, isTrue);
    expect(await host.transfer.requestClose(), isFalse);
    await host.transfer.recover();
    expect(host.transfer.error, isNull);
    expect(host.transfer.requiresRecovery, isFalse);
    expect(operation, startsWith('studio_pack_'));
    expect((await host.reopen()).elements, isNotEmpty);
    expect(await host.transfer.requestClose(), isTrue);
  });
  test('close requested before start reply cancels and waits for terminal cancelled', () async {
    final port = DelayedPackPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
      pollInterval: Duration.zero,
    );
    final importing = controller.beginImport();
    await port.entered.future;
    var closed = false;
    final closing = controller.requestClose().then((value) {
      closed = value;
      return value;
    });
    expect(closed, isFalse);
    port.start.complete({
      'snapshot': {'jobId': 'staging', 'state': 'running'},
      'phase': 'staging',
      'cancelAllowed': true,
    });
    await port.cancelled.future;
    expect(closed, isFalse);
    port.terminal.complete();
    expect(await closing, isTrue);
    await importing;
    expect(port.verbs, isNot(contains('inspect')));
    expect(port.applies, 0);
    controller.dispose();
  });

  test('finalization refuses close and waits for actual receipt', () async {
    final port = FinalizingPackPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
      pollInterval: Duration.zero,
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    final applying = controller.apply();
    await port.entered.future;
    expect(await controller.requestClose(), isFalse);
    expect(port.verbs, isNot(contains('cancel')));
    port.terminal.complete();
    await applying;
    expect(controller.error, isNull);
    expect(await controller.requestClose(), isTrue);
    controller.dispose();
  });
}

class DelayedPackPort extends PackTestPort {
  final entered = Completer<void>(),
      cancelled = Completer<void>(),
      terminal = Completer<void>();
  final start = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'stage') {
      entered.complete();
      return start.future;
    }
    if (verb == 'cancel') {
      if (!cancelled.isCompleted) cancelled.complete();
      return {'state': 'cancelling', 'bounded': false};
    }
    if (verb == 'get') {
      await terminal.future;
      return {
        'snapshot': {'jobId': 'staging', 'state': 'cancelled'},
        'phase': 'cancelled',
        'cancelAllowed': false,
      };
    }
    return super.transfer(verb, input);
  }
}

class FinalizingPackPort extends PackTestPort {
  final entered = Completer<void>(), terminal = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'get') {
      entered.complete();
      await terminal.future;
      return settled({
        'receipt': {'receiptId': 'applied'},
      });
    }
    return super.transfer(verb, input);
  }

  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) async {
    applies++;
    await monitor({
      'snapshot': {'jobId': 'apply', 'state': 'running'},
      'phase': 'finalizing',
      'cancelAllowed': false,
    });
    return receipt;
  }
}
