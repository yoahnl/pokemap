import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3 || args.any((argument) => !File(argument).isAbsolute)) {
    throw ArgumentError('Expected absolute source, profile, qualification and optional supplemental roots.');
  }
  final historical = jsonDecode(await File(args[2]).readAsString()) as Map;
  final candidates = (historical['events'] as List).cast<Map>().where((event) =>
      (event['gaps'] as List).contains('sourceTownMapFootprintUnqualified'));
  final mapIds = candidates.map((event) => (event['locator'] as Map)['mapId'] as int).toSet();
  final profile = SourceInterpretationProfile.fromJson(
      jsonDecode(await File(args[1]).readAsString()));
  final tree = await SupplementedSourceTree.open(args[0],
      supplementalRootPaths: args.skip(3).toList());
  try {
    final snapshot = await SourceScanner().scan(source: tree,
        logicalProjectNamespace: ConverterId('static-footprint-readonly-probe'));
    final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files, selectedMapIds: mapIds,
        includeEventSystem: true, interpretationProfile: profile);
    final analysis = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(source)).analyze();
    final resolver = SourceSemanticResolver.forProject(source);
    var qualified = 0;
    for (final candidate in candidates) {
      final locator = candidate['locator'] as Map;
      final event = analysis.eventAt(locator['mapId'] as int, locator['eventId'] as int)!;
      final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .allMatches(event.name).toList();
      final result = resolver.resolveStaticActionFootprint(
          event: event, page: event.pages.single, mapEvents: analysis.events,
          width: sizes.isEmpty ? 1 : int.parse(sizes.single.group(1)!),
          height: sizes.isEmpty ? 1 : int.parse(sizes.single.group(2)!));
      if (result.kind == SourceEventTouchKind.front) qualified++;
      stdout.writeln(jsonEncode({
        'mapId': event.sourceMapId,
        'eventId': event.sourceEventId,
        'name': event.name,
        'kind': result.kind.name,
        'reason': result.reason,
      }));
    }
    await files.verifyUnchanged();
    stdout.writeln(jsonEncode({
      'kind': 'sourceStaticFootprintReadOnlyProbe',
      'candidateCount': candidates.length,
      'qualifiedFootprintCount': qualified,
      'sourceUnchanged': true,
      'nativeEventPublicationCertified': false,
    }));
  } finally {
    await tree.close();
  }
}
