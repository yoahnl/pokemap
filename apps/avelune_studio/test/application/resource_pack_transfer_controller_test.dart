import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_pack_transfer_export_fakes.dart';
export 'resource_pack_transfer_export_fakes.dart';
export 'resource_pack_transfer_test_ports.dart';

void main() {
  test(
    'exporting a library selection starts from exactly the marked resources',
    () async {
      final port = ExportPackTestPort();
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: ExportTestSink(),
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await c.beginExport(
        selection: [
          (kind: 'element', id: 'arbre'),
          (kind: 'borderBlueprint', id: 'cliff'),
        ],
      );
      expect(
        port.verbs.where((verb) => verb == 'selection.patch'),
        hasLength(1),
      );
      expect(port.inputs[port.verbs.indexOf('selection.patch')]['add'], [
        {'kind': 'element', 'id': 'arbre'},
        {'kind': 'borderBlueprint', 'id': 'cliff'},
      ]);
      expect(port.verbs, isNot(contains('selection.select_filtered')));
      expect(c.phase, ResourcePackTransferPhase.selecting);
    },
  );

  test('unknown publication blocks close until status-only reconciliation confirms publication', () async {
    final port = ExportPackTestPort();
    final sink = PendingExportTestSink();
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
    c.setOrganizationAcknowledgement(true);
    await c.export();
    expect(c.requiresPublicationReconciliation, isTrue);
    expect(c.outputPath, isNull);
    expect(await c.requestClose(), isFalse);
    final exports = port.verbs.where((verb) => verb == 'export').length;
    await c.retryPublication();
    expect(c.requiresPublicationReconciliation, isFalse);
    expect(c.outputPath, '/published.aveluneassets');
    expect(port.verbs.where((verb) => verb == 'export'), hasLength(exports));
    expect(sink.requeries, 1);
    expect(await c.requestClose(), isTrue);
  });

  for (final verb in ['stage_license', 'prepare', 'export']) {
    test(
      'late successful export $verb reply is owned and released while close waits',
      () async {
        final port = LateExportPackPort();
        final c = ResourcePackTransferController(
          port: port,
          picker: () async => null,
          pickLicenses: () async => ['/LICENSE'],
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
        if (verb == 'export') {
          await c.prepare();
          c.setOrganizationAcknowledgement(true);
        }
        port.lateVerb = verb;
        final operation = verb == 'stage_license'
            ? c.addLicenseDocuments()
            : verb == 'prepare'
            ? c.prepare()
            : c.export();
        await port.entered.future;
        var done = false;
        final close = c.requestClose().then((v) {
          done = true;
          return v;
        });
        await Future<void>.delayed(Duration.zero);
        expect(done, isFalse);
        port.gate.complete();
        await operation;
        expect(await close, isTrue);
        final handle = verb == 'stage_license'
            ? 'license-1'
            : verb == 'prepare'
            ? 'native-prepared-1'
            : 'artifact';
        expect(port.released.where((h) => h == handle), hasLength(1));
        expect(port.released, isNot(contains('native-preview-1')));
        expect(c.outputPath, isNull);
      },
    );
  }
  test(
    'late failed native preview cannot report an error after the route closes',
    () async {
      final port = LatePreviewExportPort();
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
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
      await c.prepare();
      port.delay = true;
      final reading = c.nextPreviewPage();
      await port.entered.future;
      final close = c.requestClose();
      port.gate.completeError(StateError('obsolete preview'));
      await reading;
      expect(await close, isTrue);
      expect(c.error, isNull);
    },
  );

  test('native owner release failure is observable and close retries the shared owner once', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
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
    await c.prepare();
    expect(c.error, isNull);
    port.failNativeRelease = true;
    await c.setExportField('name', 'Changed');
    expect(c.error, contains('cleanup'));
    expect(await c.requestClose(), isTrue);
    expect(port.released, isNot(contains('native-preview-1')));
  });
  test('repreparing retries a failed native owner cleanup before creating another owner', () async {
    final port = ExportPackTestPort();
    final c = ResourcePackTransferController(
      port: port,
      picker: () async => null,
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
    await c.prepare();
    port.failNativeRelease = true;
    await c.setExportField('name', 'Changed');
    expect(c.error, contains('cleanup'));
    await c.prepare();
    expect(c.error, isNull);
    expect(
      port.released.where((handle) => handle == 'native-prepared-1'),
      hasLength(2),
    );
    expect(port.preparations, 2);
    expect(await c.requestClose(), isTrue);
    expect(port.released, isNot(contains('native-preview-1')));
  });
}
