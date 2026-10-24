import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'source_inventory_controller_test.dart'
    show createInventoryControllerInput;
import 'support/source_catalog_preservation.dart' show preservedCatalogItems;

void main() {
  test(
      'STD09 fresh PBS key item is non-sellable and tagged without a preceding binding',
      () async {
    final input = await createInventoryControllerInput(localWriter: 'give');
    final pbs = await const SourcePbsParser()
        .read(snapshot: input.source.snapshot, files: input.files);
    final projected = await const SourceCatalogProjector().read(
        source: input.source,
        pbs: pbs,
        files: input.files,
        nativeMapIds: const {58: 'original-map', 200: 'other-map'},
        requestedItemSymbols: const ['SECRETKEY']);
    expect(projected.hasBlockingDiagnostics, isFalse);
    final item = preservedCatalogItems(projected)!.entries.singleWhere(
        (item) => item.id == input.items['SECRETKEY']!.definition.id);
    expect(item.buyPrice, 0);
    expect(item.sellPrice, isNull);
    expect(item.tags, containsAll(['source-imported', 'key-item']));
  });

  test(
      'STD09 zero-price key item retains its compiled non-sellable binding through PBS projection',
      () async {
    final input = await createInventoryControllerInput(localWriter: 'give');
    final bound = input.items['SECRETKEY']!.definition;
    expect(bound.buyPrice, 0);
    expect(bound.sellPrice, isNull);
    final pbs = await const SourcePbsParser()
        .read(snapshot: input.source.snapshot, files: input.files);
    final projected = await const SourceCatalogProjector().read(
        source: input.source,
        pbs: pbs,
        files: input.files,
        nativeMapIds: const {58: 'original-map', 200: 'other-map'},
        existingItemCatalog:
            ProjectItemCatalog(schemaVersion: 1, entries: [bound]),
        requestedItemSymbols: const ['SECRETKEY']);
    expect(
        projected.diagnostics.where((diagnostic) =>
            diagnostic.code == 'source.catalog.item_binding_conflict'),
        isEmpty);
    final item = preservedCatalogItems(projected)!
        .entries
        .singleWhere((item) => item.id == bound.id);
    expect(item.buyPrice, 0);
    expect(item.sellPrice, isNull);
    expect(item.tags, contains('key-item'));
  });
  test('STD09 key-item price divergence remains a blocking catalogue conflict',
      () async {
    final input = await createInventoryControllerInput(localWriter: 'give');
    final compiled = input.items['SECRETKEY']!.definition;
    final existing = compiled.copyWith(buyPrice: 100);
    final pbs = await const SourcePbsParser()
        .read(snapshot: input.source.snapshot, files: input.files);
    final projected = await const SourceCatalogProjector().read(
        source: input.source,
        pbs: pbs,
        files: input.files,
        nativeMapIds: const {58: 'original-map', 200: 'other-map'},
        existingItemCatalog:
            ProjectItemCatalog(schemaVersion: 1, entries: [existing]),
        requestedItemSymbols: const ['SECRETKEY']);
    final conflict = projected.diagnostics.singleWhere((diagnostic) =>
        diagnostic.code == 'source.catalog.item_binding_conflict');
    expect(conflict.blocking, isTrue);
    expect(preservedCatalogItems(projected), isNull);
  });
}
