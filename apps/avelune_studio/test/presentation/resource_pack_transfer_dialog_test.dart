import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_pack_review_projection.dart';
import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_pack_route_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_transfer_controller_test.dart'
    show
        PackTestPort,
        ExportPackTestPort,
        ExportTestSink,
        PendingExportTestSink;
import '../resource_io/resource_pack_import_host_test.dart'
    show ResourcePackTestHost;

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

  test('an oversized derived draft keeps its human notice without a dependency label', () {
    final notice = resourcePackImportRowLabel({
      'kind': 'authoringDraftNotice',
      'label': 'Eau animée',
      'message': 'Le terrain publié reste disponible pour peindre. Son brouillon dépasse les limites du catalogue.',
    });
    expect(
      notice,
      startsWith(
        'Eau animée : Le terrain publié reste disponible pour peindre.',
      ),
    );
    expect(notice, isNot(contains('Nécessaire')));
    expect(notice, isNot(contains('null')));
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

  test('native conflict names the resource and copy produces an applicable preview', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.transfer.beginImport();
    await host.transfer.setFilter(kind: 'element');
    await host.transfer.selectFiltered();
    await host.transfer.prepare();
    await host.transfer.apply();
    final element = host.workspace.project!.elements.first;
    await host.navigation.accept(
      await host.resources.saveElement(
        element.copyWith(name: 'Mon décor local'),
      ),
    );
    await host.transfer.beginImport();
    await host.transfer.setFilter(kind: 'environmentPreset');
    await host.transfer.selectFiltered();
    await host.transfer.prepare();
    expect(host.transfer.error, isNull);
    expect(host.transfer.conflictCount, greaterThan(0));
    final named = host.transfer.preview.firstWhere(
      (row) => row['conflict'] != null,
    );
    expect(named['label'], contains('Original'));
    expect(named['message'], contains('modifiée'));
    final notice = resourcePackImportRowLabel(named);
    expect(notice, '${named['label']} : ${named['message']}');
    expect(notice, isNot(contains('dependency_modified_or_missing:')));
    await host.transfer.prepare(importCopy: true);
    expect(host.transfer.error, isNull);
    expect(host.transfer.canApply, isTrue);
    expect(
      host.transfer.preparedSummary['copiedDefinitionCount'],
      greaterThan(0),
    );
    expect(
      host.workspace.project!.elements
          .singleWhere((entry) => entry.id == element.id)
          .name,
      'Mon décor local',
    );
  });

  test(
    'cancelling the native picker closes without accepting a mutation',
    () async {
      var mutations = 0;
      final controller = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () async => null,
        accept: (_) async {
          mutations++;
        },
      );
      addTearDown(controller.dispose);
      await runResourcePackImport(
        controller: controller,
        present: () async {
          await controller.requestClose();
        },
      );
      expect(controller.routeActive, isFalse);
      expect(controller.phase, ResourcePackTransferPhase.closed);
      expect(controller.error, isNull);
      expect(mutations, 0);
    },
  );

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
