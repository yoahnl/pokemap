import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_interaction_inventory_fixture.dart'
    as fixtures;
import '../tool/export_source_interaction_inventory.dart' as exporter;

void main() {
  test(
    'read-only CLI refuses existing, overlapping and symlink destinations',
    () async {
      final temp = await Directory.systemTemp.createTemp('inventory-guard-');
      addTearDown(() => temp.delete(recursive: true));
      final source = await Directory('${temp.path}/source').create();
      final supplement = await Directory('${temp.path}/supplement').create();
      final existing = await Directory('${temp.path}/existing').create();
      final link = Link('${temp.path}/alias');
      await link.create(source.path);
      for (final destination in [
        existing.path,
        '${source.path}/inventory',
        '${supplement.path}/inventory',
        '${link.path}/inventory',
      ]) {
        await expectLater(
          exporter.exportSourceInteractionInventory([
            source.path,
            destination,
            'test',
            'tool',
            '--supplemental',
            supplement.path,
          ]),
          throwsStateError,
        );
      }
      await expectLater(
        exporter.exportSourceInteractionInventory([
          source.path,
          '${temp.path}/fresh',
          'test',
          'tool',
          '--unknown',
          'x',
        ]),
        throwsArgumentError,
      );
      expect(await Directory('${temp.path}/fresh').exists(), false);
    },
  );

  test(
      'CLI exports a complete tiny source without native writes or source changes',
      () async {
    final created = await Directory.systemTemp.createTemp('inventory-export-');
    final temp = Directory(await created.resolveSymbolicLinks());
    addTearDown(() => temp.delete(recursive: true));
    final source = await Directory('${temp.path}/source').create();
    final files = fixtures.commonEventCallSourceFiles();
    for (final row in files.entries) {
      final target = File('${source.path}/${row.key}');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(row.value);
    }
    final destination = '${temp.path}/inventory';
    await exporter.exportSourceInteractionInventory([
      source.path,
      destination,
      'tiny-export',
      'tool-revision',
    ]);
    final json = jsonDecode(
      await File('$destination/inventory.json').readAsString(),
    );
    expect(json['eventCount'], 1);
    expect(json['pageCount'], 1);
    expect(json['rawCommandCount'], 2);
    expect(json['signalPageCounts']['commonEventCallUnresolved'], 1);
    expect(
      json['events'][0]['pages'][0]['unresolvedCommonEventCalls'][0]
          ['parameters'],
      [4],
    );
    expect(json['historicalQualification'], null);
    expect(await Directory(destination).list().length, 4);
    for (final row in files.entries) {
      expect(await File('${source.path}/${row.key}').readAsBytes(), row.value);
    }
  });
}
