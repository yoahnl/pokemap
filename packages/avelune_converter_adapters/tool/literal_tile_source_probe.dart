import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<void> main(List<String> arguments) async {
  if ((arguments.length != 3 && arguments.length != 5) ||
      arguments[0] != '--offline' ||
      arguments[1] != '--source' ||
      !arguments[2].startsWith('/') ||
      (arguments.length == 5 && arguments[3] != '--maps')) {
    stderr.writeln(
        'Usage: literal-tile-source-probe --offline --source ABSOLUTE_DIRECTORY [--maps ID,ID]');
    exitCode = 64;
    return;
  }
  Set<int>? selected;
  if (arguments.length == 5) {
    final parsed = arguments[4].split(',').map(int.tryParse).toList();
    if (parsed.isEmpty ||
        parsed.any((id) => id == null || id <= 0) ||
        parsed.toSet().length != parsed.length) {
      stderr.writeln('Source map IDs must be unique positive integers.');
      exitCode = 64;
      return;
    }
    selected = parsed.cast<int>().toSet();
  }
  final source = await MacOsSourceTree.open(arguments[2]);
  try {
    final snapshot = await SourceScanner().scan(
      source: source,
      logicalProjectNamespace: ConverterId('literal-tile-source-qualification'),
    );
    final files = await SnapshotSourceFiles.bind(
      source: source,
      snapshot: snapshot,
    );
    final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: selected,
    );
    final mapSummaries = <Map<String, Object?>>[];
    for (final sourceMap in normalized.maps) {
      final map = sourceMap.map;
      final staticTransferTargets = <int>{};
      var unresolvedTransferCommands = 0;
      for (final command in map.events
          .expand((event) => event.pages)
          .expand((page) => page.commands)) {
        if (command.code != 201) continue;
        final parameters = command.parameters;
        if (parameters.length >= 2 &&
            parameters[0] == 0 &&
            parameters[1] is int &&
            (parameters[1] as int) > 0) {
          staticTransferTargets.add(parameters[1] as int);
        } else {
          unresolvedTransferCommands++;
        }
      }
      final counts = <String, int>{
        'empty': 0,
        'reserved': 0,
        'autotile': 0,
        'regular': 0,
      };
      final sourceTileIds = <int>{};
      for (final layer in map.layers) {
        for (final id in layer.cells) {
          sourceTileIds.add(id);
          final category = id == 0
              ? 'empty'
              : id < 48
                  ? 'reserved'
                  : id < 384
                      ? 'autotile'
                      : 'regular';
          counts[category] = counts[category]! + 1;
        }
      }
      mapSummaries.add({
        'sourceMapId': map.sourceMapId,
        'name': map.name,
        'sourceTilesetId': map.sourceTilesetId,
        'width': map.width,
        'height': map.height,
        'sourceZ': map.layers.map((layer) => layer.sourceZ).toList(),
        'eventCount': map.events.length,
        'staticTransferTargets': staticTransferTargets.toList()..sort(),
        'unresolvedTransferCommands': unresolvedTransferCommands,
        'cellCounts': counts,
        'uniqueTileIds': sourceTileIds.length,
        'maxSourceTileId': sourceTileIds.fold<int>(0, (a, b) => a > b ? a : b),
        'regularOnly': counts['reserved'] == 0 && counts['autotile'] == 0,
      });
    }
    final preview = selected == null
        ? null
        : await const LiteralTileComposer().compose(
            source: normalized,
            files: files,
            selectedSourceMapIds: selected.toList()..sort(),
            projectName: 'Read-only literal tile qualification',
            parentPath: Directory.systemTemp.path,
            folderName: 'unwritten-literal-preview',
            sourceRootPath: arguments[2],
          );
    await files.verifyUnchanged();
    stdout.writeln(jsonEncode({
      'schemaVersion': 1,
      'lot': 'AC-06',
      'proofKind': 'readOnlyLiteralTileSourceInspection',
      'offline': true,
      'sourceRoot': arguments[2],
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'normalizedSourceHash': normalized.canonicalHash.value,
      'sourceProfileState': snapshot.profile.state.name,
      'humanProductionApproval': false,
      'sourceUnchanged': true,
      'normalizedMaps': normalized.maps.length,
      'canPlan': normalized.canPlan,
      'blockingDiagnostics':
          normalized.diagnostics.where((value) => value.blocksPlanning).length,
      'diagnosticCounts': {
        for (final code
            in normalized.diagnostics.map((value) => value.code).toSet())
          code: normalized.diagnostics
              .where((value) => value.code == code)
              .length,
      },
      'regularOnlySourceMapIds': mapSummaries
          .where((map) => map['regularOnly'] == true)
          .map((map) => map['sourceMapId'])
          .toList(),
      'maps': mapSummaries,
      'literalPreview': preview == null
          ? null
          : {
              'compositionHash': preview.compositionHash.value,
              'draftPrepared': preview.draft != null,
              'playableCertified': preview.playableCertified,
              'mapIds': {
                for (final entry in preview.mapIds.entries)
                  entry.key.toString(): entry.value,
              },
              'tilesetIds': {
                for (final entry in preview.tilesetIds.entries)
                  entry.key.toString(): entry.value,
              },
              'crops': preview.crops.map((crop) => crop.toJson()).toList(),
              'layerProvenance': preview.layerProvenance
                  .map((layer) => layer.toJson())
                  .toList(),
              'dependencies': preview.dependencies
                  .map((dependency) => dependency.toJson())
                  .toList(),
              'diagnostics': preview.diagnostics
                  .map((diagnostic) => diagnostic.toJson())
                  .toList(),
            },
      'nativeDraftWritten': false,
      'published': false,
    }));
  } finally {
    await source.close();
  }
}
