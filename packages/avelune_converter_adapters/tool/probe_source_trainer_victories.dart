import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3 ||
      [args[0], args[1], ...args.skip(3)].any((path) => !File(path).isAbsolute)) {
    throw ArgumentError('Expected absolute source, profile, map:event pairs and optional supplemental roots.');
  }
  final pairs = args[2].split(',').map((value) {
    final pair = value.split(':').map(int.parse).toList();
    if (pair.length != 2 || pair.any((id) => id < 1 || id > 99999)) {
      throw ArgumentError('Expected bounded map:event pairs.');
    }
    return (pair.first, pair.last);
  }).toSet();
  final profile = SourceInterpretationProfile.fromJson(
      jsonDecode(await File(args[1]).readAsString()));
  final tree = await SupplementedSourceTree.open(args[0],
      supplementalRootPaths: args.skip(3).toList());
  try {
    final snapshot = await SourceScanner().scan(source: tree,
        logicalProjectNamespace: ConverterId('trainer-victory-readonly-probe'));
    final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files,
        selectedMapIds: pairs.map((pair) => pair.$1).toSet(),
        includeEventSystem: true, interpretationProfile: profile);
    final analysis = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(source)).analyze();
    final bindings = await const SourceTrainerEventBindingResolver()
        .read(source: source, analysis: analysis, files: files);
    final gymItems = {for (final event in analysis.events)
      for (final program in event.pages.expand((page) => page.body.nodes).whereType<SourceTrainerProgramNode>())
        if (program.gymLeader != null) ...[program.gymLeader!.rewardSymbol,
          if (program.gymLeader!.sourceBadgeIndex == 18) 'MACHOBRACE']};
    if (gymItems.isNotEmpty) {
      final items = await const SourceEventItemBindingResolver().read(
          snapshot: source.snapshot, files: files, symbols: gymItems,
          eventProfile: analysis.profile);
      for (final pair in pairs) {
        final program = analysis.eventAt(pair.$1, pair.$2)!.pages.first.body.nodes
            .whereType<SourceTrainerProgramNode>().firstOrNull;
        if (program?.gymLeader == null) continue;
        final music = await const SourceMapMusicResolver().read(source: source,
            files: files, sourceMapId: pair.$1, policy: SourceMapMusicPolicy.nativeAuthoredVolume);
        for (final symbol in [program!.gymLeader!.rewardSymbol,
          if (program.gymLeader!.sourceBadgeIndex == 18) 'MACHOBRACE']) {
          final item = items.bindings[symbol];
          String? refusal;
          var feedback = false;
          if (item != null) {
            try {
              await const SourcePickupFeedbackResolver().read(source: source,
                  files: files, item: item, sourceMapId: pair.$1, music: music,
                  helper: symbol == 'MACHOBRACE' ? SourceItemGrantHelper.itemBall : SourceItemGrantHelper.receiveItem);
              feedback = true;
            } on SourcePickupBindingUnavailable catch (error) {
              refusal = error.reason;
            } on ContractError catch (error) {
              refusal = error.code;
            }
          }
          stdout.writeln(jsonEncode({'kind': 'gymItemBinding', 'mapId': pair.$1,
            'symbol': symbol, 'bagAttributionBound': item?.pickupQualified == true,
            'feedbackBound': feedback, 'feedbackRefusal': refusal,
            'useGaps': item?.useGaps.toList(),
            'itemRefusal': items.quarantinedSymbols[symbol]}));
        }
      }
    }
    var recognized = 0, nativeBound = 0;
    for (final pair in pairs) {
      final event = analysis.eventAt(pair.$1, pair.$2)!;
      final programs = event.pages.expand((page) => page.body.nodes)
          .whereType<SourceTrainerProgramNode>().where((program) =>
              program.kind == SourceTrainerProgramKind.encounter).toList();
      if (programs.length == 1) recognized++;
      if (bindings.byEventIdentity.containsKey(event.identity)) nativeBound++;
      stdout.writeln(jsonEncode({'mapId': pair.$1, 'eventId': pair.$2,
        'sourceProgramRecognized': programs.length == 1,
        'sourceQuarantined': event.isQuarantined,
        'nativeRosterBound': bindings.byEventIdentity.containsKey(event.identity),
        'bindingRefusal': bindings.refusals[event.identity],
        'continuation': programs.map((program) =>
            program.toJson()['victoryContinuation']).toList(),
      }));
    }
    await files.verifyUnchanged();
    stdout.writeln(jsonEncode({'kind': 'sourceTrainerVictoryReadOnlyProbe',
      'candidateCount': pairs.length, 'recognizedCount': recognized,
      'nativeRosterBoundCount': nativeBound, 'sourceUnchanged': true,
      'nativeEventPublicationCertified': false}));
  } finally {
    await tree.close();
  }
}
