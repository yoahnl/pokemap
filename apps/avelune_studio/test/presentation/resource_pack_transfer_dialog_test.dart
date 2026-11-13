import 'dart:async';

import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_transfer_controller_test.dart'
    show
        PackTestPort,
        ExportPackTestPort,
        ExportTestSink,
        PendingExportTestSink;

ResourcePackTransferController _export(
  ExportPackTestPort port, {
  PendingExportTestSink? sink,
}) {
  final controller = ResourcePackTransferController(
    port: port,
    picker: () async => null,
    exportSink: sink ?? ExportTestSink(),
    accept: (_) async {},
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _prepareExport(ResourcePackTransferController controller) async {
  await controller.beginExport();
  for (final entry in {
    'name': 'Pack',
    'author': 'Publisher',
    'universeId': 'original',
    'provenance': 'Original',
  }.entries) {
    await controller.setExportField(entry.key, entry.value);
  }
  await controller.selectFiltered();
  await controller.prepare();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export inventory remains a pending export until its native inventory returns', () async {
    final port = _SlowInventoryPort();
    final controller = _export(port);
    final opening = controller.beginExport();
    await port.inventoryStarted.future;
    expect(controller.exporting, isTrue);
    expect(controller.operationActive, isTrue);
    expect(controller.phase, ResourcePackTransferPhase.idle);
    expect(controller.inspection, isEmpty);
    port.inventory.complete();
    await opening;
    expect(controller.operationActive, isFalse);
    expect(controller.error, isNull);
    expect(controller.phase, ResourcePackTransferPhase.selecting);
  });

  test('an unknown publication retries status without prematurely declaring success', () async {
    final sink = PendingExportTestSink();
    final controller = _export(ExportPackTestPort(), sink: sink);
    await _prepareExport(controller);
    controller.setOrganizationAcknowledgement(true);
    await controller.export();
    expect(controller.requiresPublicationReconciliation, isTrue);
    expect(controller.outputPath, isNull);
    expect(controller.phase, ResourcePackTransferPhase.publicationRequired);
    await controller.retryPublication();
    expect(controller.outputPath, '/published.aveluneassets');
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(sink.requeries, 1);
  });

  test(
    'closing a reviewed export releases its prepared native handle once',
    () async {
      final port = ExportPackTestPort();
      final controller = _export(port);
      await _prepareExport(controller);
      expect(controller.error, isNull);
      controller.setOrganizationAcknowledgement(true);
      expect(controller.canExport, isTrue);
      expect(await controller.requestClose(), isTrue);
      expect(controller.phase, ResourcePackTransferPhase.closed);
      expect(
        port.released.where((handle) => handle == 'native-prepared-1'),
        hasLength(1),
      );
    },
  );

  test('completed import retains the explicit before-import and planned-write summary', () async {
    final controller = ResourcePackTransferController(
      port: PackTestPort(),
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    final preparedSummary = controller.preparedSummary;
    expect(preparedSummary, isNotEmpty);
    await controller.apply();
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(controller.preparedSummary, same(preparedSummary));
    expect(controller.preparedSummary, preparedSummary);
  });

  test(
    'server selection retains all 10000 selected roots and closes cleanly',
    () async {
      final controller = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.beginImport();
      await controller.selectFiltered();
      expect(controller.selectedCount, 10000);
      expect(await controller.requestClose(), isTrue);
      expect(controller.phase, ResourcePackTransferPhase.closed);
    },
  );
}

final class _SlowInventoryPort extends ExportPackTestPort {
  final inventory = Completer<void>();
  final inventoryStarted = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'selection.create') {
      inventoryStarted.complete();
      await inventory.future;
    }
    return super.transfer(verb, input);
  }
}
