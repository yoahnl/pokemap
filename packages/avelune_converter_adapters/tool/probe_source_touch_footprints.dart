import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3 ||
      [args[0], args[1], ...args.skip(3)].any((argument) => !File(argument).isAbsolute)) {
    throw ArgumentError('Expected absolute source, profile, map:event pairs and optional supplemental roots.');
  }
  final ids = args[2].split(',').map((pair) {
    final parts = pair.split(':').map(int.parse).toList();
    if (parts.length != 2 || parts.any((part) => part < 1 || part > 99999)) {
      throw ArgumentError('Map and event IDs must be bounded positive pairs.');
    }
    return (parts[0], parts[1]);
  }).toSet();
  final profile = SourceInterpretationProfile.fromJson(
      jsonDecode(await File(args[1]).readAsString()));
  final tree = await SupplementedSourceTree.open(args[0],
      supplementalRootPaths: args.skip(3).toList());
  try {
    final snapshot = await SourceScanner().scan(source: tree,
        logicalProjectNamespace: ConverterId('touch-footprint-readonly-probe'));
    final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final selectedMapIds = ids.map((id) => id.$1).toSet();
    var source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files, selectedMapIds: selectedMapIds,
        includeEventSystem: true, interpretationProfile: profile);
    final destinationIds = <int>{
      for (final map in source.maps)
        for (final event in map.map.events.where((event) =>
            ids.contains((map.map.sourceMapId, event.sourceEventId))))
          for (final page in event.pages)
            for (final command in page.commands)
              if (command.code == 201 && command.parameters.length == 6 &&
                  command.parameters[0] == 0 && command.parameters[1] is int)
                command.parameters[1] as int,
    };
    if (!selectedMapIds.containsAll(destinationIds)) {
      source = await const RmxpSourceNormalizer().normalize(
          snapshot: snapshot, files: files,
          selectedMapIds: {...selectedMapIds, ...destinationIds},
          includeEventSystem: true, interpretationProfile: profile);
    }
    final analysis = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(source)).analyze();
    final resolver = SourceSemanticResolver.forProject(source);
    var qualified = 0;
    var pageCount = 0;
    for (final id in ids) {
      final event = analysis.eventAt(id.$1, id.$2)!;
      final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .allMatches(event.name).toList();
      for (final page in event.pages.where((page) => page.triggerCode == 1 && !page.isEmpty)) {
        pageCount++;
        final result = resolver.resolveEventTouchFootprint(event: event,
            page: page, mapEvents: analysis.events,
            width: sizes.length == 1 ? int.parse(sizes.single.group(1)!) : 0,
            height: sizes.length == 1 ? int.parse(sizes.single.group(2)!) : 0);
        if (result.kind != SourceEventTouchKind.unqualified) qualified++;
        stdout.writeln(jsonEncode({'mapId': id.$1, 'eventId': id.$2,
          'pageIndex': page.originalPageIndex, 'kind': result.kind.name,
          'reason': result.reason, 'profileQualified': analysis.profile.isQualified,
          'eventQuarantined': event.isQuarantined, 'pageQuarantined': page.isQuarantined,
          'conditionQualified': page.condition.isQualified,
          'pageDiagnosticCodes': page.diagnostics.map((diagnostic) => diagnostic.code).toList(),
          'bodyKinds': page.body.nodes.map((node) => node.runtimeType.toString()).toList()}));
      }
    }
    await files.verifyUnchanged();
    stdout.writeln(jsonEncode({'kind': 'sourceTouchFootprintReadOnlyProbe',
      'candidateCount': ids.length, 'pageCount': pageCount,
      'qualifiedPageCount': qualified, 'sourceUnchanged': true,
      'nativeEventPublicationCertified': false}));
  } finally {
    await tree.close();
  }
}
