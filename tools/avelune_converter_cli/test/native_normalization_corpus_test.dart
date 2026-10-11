import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  final sourcePath = Platform.environment['AVELUNE_CONVERTER_TEST_SOURCE'];
  test(
    'normalizes an explicitly selected local RMXP map corpus with snapshot proof',
    () async {
      final source = await MacOsSourceTree.open(sourcePath!);
      try {
        final snapshot = await SourceScanner().scan(
          source: source,
          logicalProjectNamespace: ConverterId('pmon-world-kanto'),
        );
        expect(snapshot.state, SourceScanState.complete);
        final files = await SnapshotSourceFiles.bind(
          source: source,
          snapshot: snapshot,
        );
        final result = await const RmxpSourceNormalizer().normalize(
          snapshot: snapshot,
          files: files,
        );
        await files.verifyUnchanged();
        final sourceIds = snapshot.entries
            .map((entry) => RegExp(r'^Data/Map([0-9]+)\.rxdata$')
                .firstMatch(entry.relativePath))
            .whereType<RegExpMatch>()
            .map((match) => int.parse(match.group(1)!))
            .toSet();
        final normalizedIds =
            result.maps.map((map) => map.map.sourceMapId).toSet();
        final blockedIds = result.diagnostics
            .where((item) => item.blocksPlanning)
            .map((item) => item.locator.mapId)
            .whereType<int>()
            .toSet();
        expect(normalizedIds, isNotEmpty);
        expect(
            sourceIds.difference({
              ...normalizedIds,
              ...blockedIds,
              ...result.unprocessedSourceMapIds,
            }),
            isEmpty);
        if (result.unprocessedSourceMapIds.isNotEmpty) {
          expect(result.canPlan, isFalse);
          expect(result.diagnostics.any((item) => item.blocksPlanning), isTrue);
        }
        expect(normalizedIds.length, result.maps.length);
        expect(result.archive.isSealed, isTrue);
        final diagnostics = <String, int>{};
        for (final item in result.diagnostics) {
          diagnostics.update(item.code, (count) => count + 1,
              ifAbsent: () => 1);
        }
        final summary = {
          'snapshotHash': snapshot.canonicalHash.value,
          'normalizedHash': result.canonicalHash.value,
          'profileState': snapshot.profile.state.name,
          'sourceMaps': sourceIds.length,
          'normalizedMaps': result.maps.length,
          'refusedMaps': sourceIds.difference(normalizedIds).toList()..sort(),
          'unprocessedMaps': result.unprocessedSourceMapIds,
          'hierarchyEntries': result.mapHierarchy.length,
          'tilesets': result.tilesets.length,
          'events': result.maps
              .fold<int>(0, (sum, map) => sum + map.map.events.length),
          'commands': result.maps.fold<int>(
              0,
              (sum, map) =>
                  sum +
                  map.map.events.fold<int>(
                      0,
                      (sum, event) =>
                          sum +
                          event.pages.fold<int>(
                              0, (sum, page) => sum + page.commands.length))),
          'cells': result.maps.fold<int>(
              0,
              (sum, map) =>
                  sum +
                  map.map.layers
                      .fold<int>(0, (sum, layer) => sum + layer.cells.length)),
          'archivedFiles': result.archive.files.length,
          'archivedBytes': result.archive.files.values
              .fold<int>(0, (sum, file) => sum + file.rawBytes.length),
          'preservedReferences': result.archive.references.length,
          'preservedParameters': result.preservedParameterRefs.length,
          'resolvedImages': [
            ...result.tilesets.expand((tileset) => tileset.images),
            ...result.eventImages,
          ].where((image) => image.state == 'resolved').length,
          'blockingDiagnostics':
              result.diagnostics.where((item) => item.blocksPlanning).length,
          'canPlan': result.canPlan,
          'diagnosticCodes': diagnostics,
        };
        print('NORMALIZATION_CORPUS_JSON ${jsonEncode(summary)}');
      } finally {
        await source.close();
      }
    },
    skip: sourcePath == null || !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
