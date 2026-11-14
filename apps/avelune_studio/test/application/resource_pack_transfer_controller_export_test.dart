import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_pack_transfer_export_fakes.dart';
import 'resource_pack_transfer_test_ports.dart';

void main() {
  test('a reached memory edit after preview resets acknowledgement before building', () async {
    final port = ExportPackTestPort();
    var signature = 'before';
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: ExportTestSink(),
      localDrafts: () => [
        ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'late',
          label: 'Late border',
          signature: signature,
        ),
      ],
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    signature = 'after';
    await c.export();
    expect(port.lastExport, isNull);
    expect(c.organizationAcknowledged, isFalse);
    expect(c.localNotices.single.signature, 'after');
    expect(c.notice, contains('ont changé'));
    c.setOrganizationAcknowledgement(true);
    await c.export();
    expect(c.outputPath, isNotNull);
    expect(port.applies, 0);
  });

  test('native export stages several licences, previews exact selection and completes only after publication', () async {
    final port = ExportPackTestPort();
    final sink = ExportTestSink();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      pickLicenses: () async => ['/one.txt', '/two.txt'],
      exportSink: sink,
      localDrafts: () => [
        const ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'late',
          label: 'Late border',
          signature: 'draft-1',
        ),
        const ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: 'neighbour',
          label: 'Neighbour',
          signature: 'unrelated',
        ),
      ],
      accept: (_) async {
        fail('export cannot accept a mutation');
      },
    );
    addTearDown(controller.dispose);
    await controller.beginExport();
    for (final entry in {
      'name': 'My pack',
      'version': '1.2.3',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original work',
    }.entries) {
      await controller.setExportField(entry.key, entry.value);
    }
    await controller.selectFiltered();
    await controller.addLicenseDocuments();
    expect(controller.licenseDocuments, hasLength(2));
    expect(port.authorizedPaths, ['/one.txt', '/two.txt']);
    await controller.prepare();
    expect(controller.error, isNull);
    expect(controller.direction, ResourcePackTransferDirection.exporting);
    expect(controller.localNotices.map((row) => row.id), ['late']);
    expect(controller.preview, hasLength(1));
    expect(controller.requiresOrganizationAcknowledgement, isTrue);
    expect(controller.canExport, isFalse);
    controller.setOrganizationAcknowledgement(true);
    expect(controller.canExport, isTrue);
    await controller.export();
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(controller.outputPath, '/published.aveluneassets');
    expect(sink.bytes, [1, 2, 3]);
    expect(port.lastExport, {
      'preparedExportHandle': 'native-prepared-1',
      'acknowledgeOrganizationRemoval': true,
    });
    expect(port.applies, 0);
    expect(
      port.verbs.where((verb) => verb == 'selection.create'),
      hasLength(1),
    );
    expect(
      port.inputs
          .firstWhere((input) => input['mode'] == 'native')
          .containsKey('mapId'),
      isFalse,
    );
  });
  test('export edits release one native owner, reset acknowledgement and retain chosen licences', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      pickLicenses: () async => ['/one.txt'],
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    await c.beginExport();
    for (final e in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await c.setExportField(e.key, e.value);
    }
    await c.selectFiltered();
    await c.addLicenseDocuments();
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    await c.setExportField('name', 'Changed');
    expect(c.organizationAcknowledged, isFalse);
    expect(c.canExport, isFalse);
    expect(c.licenseDocuments, hasLength(1));
    expect(port.released.where((h) => h == 'native-prepared-1'), hasLength(1));
    expect(port.released, isNot(contains('native-preview-1')));
    await c.prepare();
    c.setOrganizationAcknowledgement(true);
    await c.removeLicenseDocument(c.licenseDocuments.single.handle);
    expect(c.organizationAcknowledged, isFalse);
    expect(c.licenseDocuments, isEmpty);
    expect(port.released, contains('license-1'));
  });
  test(
    'close waits for an export sink after its canonical job has finished',
    () async {
      final port = ExportPackTestPort();
      final sink = ExportTestSink(wait: true);
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: sink,
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await c.beginExport();
      for (final e in {
        'name': 'Pack',
        'author': 'Publisher',
        'universeId': 'original',
        'provenance': 'Original',
      }.entries) {
        await c.setExportField(e.key, e.value);
      }
      await c.selectFiltered();
      await c.prepare();
      expect(c.error, isNull);
      c.setOrganizationAcknowledgement(true);
      expect(c.canExport, isTrue);
      final writing = c.export();
      await sink.entered.future;
      var closed = false;
      final closing = c.requestClose().then((v) {
        closed = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.operationActive, isTrue);
      expect(closed, isFalse);
      sink.gate.complete();
      await writing;
      expect(await closing, isTrue);
      expect(c.outputPath, isNull);
      expect(c.phase, ResourcePackTransferPhase.closed);
    },
  );

  test(
    'concurrent close shares cleanup and a later import closes again',
    () async {
      final port = StrictClosePackPort();
      final controller = ResourcePackTransferController(
        port: port,
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      await controller.beginImport();
      final first = controller.requestClose();
      await port.entered.future;
      final second = controller.requestClose();
      port.gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(port.released, ['selection', 'inspection', 'archive']);
      await controller.beginImport();
      expect(await controller.requestClose(), isTrue);
      expect(port.released, hasLength(6));
      controller.dispose();
    },
  );
}
