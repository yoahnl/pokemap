import 'dart:io';
import 'dart:convert';
import 'support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  final pattern = [0x22, old.length + 5, ...old];
  for (var index = 0; index <= bytes.length - pattern.length; index++) {
    if (List.generate(pattern.length, (slot) => bytes[index + slot])
        .indexed
        .every((entry) => entry.$2 == pattern[entry.$1])) {
      return [
        ...bytes.take(index),
        0x22,
        next.length + 5,
        ...next,
        ...bytes.skip(index + pattern.length)
      ];
    }
  }
  throw StateError('Expected source literal not found.');
}

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('original external Kanto transitions', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = (await readExternalOriginalSource(root!, snapshot!)).source;
      expect(source.canPlan, isTrue);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
    });
    for (final pair in [
      (100, 6),
      (100, 7),
      (100, 13),
      (166, 1),
      (205, 2),
      (205, 4)
    ]) {
      test('recognizes the entire transfer ${pair.$1}:${pair.$2}', () {
        final event = analysis.eventAt(pair.$1, pair.$2)!;
        final page = event.pages.first;
        expect(event.isQuarantined, isFalse);
        expect(page.body.nodes, hasLength(1));
        expect(page.body.nodes.single, isA<SourceWarpNode>());
        expect(page.body.nodes.single.span.firstCommandIndex, 0);
        expect(page.body.nodes.single.span.lastCommandIndex,
            page.sourcePage.commands.length - 1);
      });
    }
    test('retains the six real destinations, facings and overlapping timing',
        () {
      for (final row in [
        (100, 6, 205, 3, 13, 6, SourceExternalWarpPresentation.illustrated),
        (100, 7, 166, 24, 7, 8, SourceExternalWarpPresentation.caveEntrance),
        (100, 13, 205, 7, 40, 8, SourceExternalWarpPresentation.illustrated),
        (166, 1, 100, 8, 24, 2, SourceExternalWarpPresentation.caveExit),
        (205, 2, 100, 7, 45, 2, SourceExternalWarpPresentation.fade),
        (205, 4, 100, 2, 42, 4, SourceExternalWarpPresentation.fade),
      ]) {
        final node = analysis
            .eventAt(row.$1, row.$2)!
            .pages
            .first
            .body
            .nodes
            .single as SourceWarpNode;
        final program = node.originalProgram!;
        expect((node.targetSourceMapId, node.x, node.y, node.direction),
            (row.$3, row.$4, row.$5, row.$6));
        expect(program.presentation, row.$7);
        expect(program.matches(node), isTrue);
        expect(program.sound.name, 'Exit Door');
        expect(program.fadeOutMs, 300);
        expect(program.transferDelayMs, 400);
        expect(program.revealMs, 300);
        expect(program.toJson()['sourceScriptsExecuted'], 0);
        expect(program.toJson()['nativeExecutionQualified'], isFalse);
        if (program.illustrationName != null) {
          expect(program.illustrationHoldMs, 1000);
          expect(program.illustrationFadeMs, 1500);
        }
        expect(
            program.matches(SourceWarpNode(node.span,
                targetSourceMapId: node.targetSourceMapId,
                x: node.x + 1,
                y: node.y,
                direction: node.direction,
                fade: false,
                originalProgram: program)),
            isFalse);
      }
    });
    for (final row in [
      (100, 7, 'pbCaveEntrance', 'pbCaveEntrance; unknown_call'),
      (166, 1, 'pbCaveExit', 'pbCaveExit; unknown_call'),
      (100, 6, 'dpic_powerplant', 'dpic_unknown'),
    ]) {
      test('freshly attested raw alteration refuses ${row.$3}', () async {
        final file = source.archive.files.values.singleWhere(
            (file) => file.entry.relativePath == 'Data/Map${row.$1}.rxdata');
        final changed = (await readExternalOriginalSource(root!, snapshot!,
                overrideBytes: {
              file.entry.relativePath:
                  _replaceLiteral(file.rawBytes, row.$3, row.$4)
            }))
            .source;
        expect(changed.snapshot.canonicalHash,
            isNot(source.snapshot.canonicalHash));
        final result = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        expect(result.eventAt(row.$1, row.$2)!.isQuarantined, isTrue);
        expect(
            result
                .eventAt(row.$1, row.$2)!
                .pages
                .first
                .body
                .nodes
                .whereType<SourceWarpNode>()
                .every((node) => node.originalProgram == null),
            isTrue);
      });
    }
    test(
        'rebinding rejects forged identities, page references and every command link',
        () {
      for (final pair in [
        (100, 6),
        (100, 7),
        (100, 13),
        (166, 1),
        (205, 2),
        (205, 4)
      ]) {
        final ir =
            source.maps.singleWhere((map) => map.map.sourceMapId == pair.$1);
        final original = ir.map.events
            .singleWhere((event) => event.sourceEventId == pair.$2);
        final program = (analysis
                .eventAt(pair.$1, pair.$2)!
                .pages
                .first
                .body
                .nodes
                .single as SourceWarpNode)
            .originalProgram!;
        bool bound(SourceEvent event) => program.isBoundToSourceEvent(
            source: source, profile: analysis.profile, event: event);
        expect(bound(original), isTrue);
        for (final mutate in <void Function(Map<String, dynamic>)>[
          (event) => event['x'] = (event['x'] as int) + 1,
          (event) => event['name'] = 'borrowed transfer',
          (event) => (event['pages'] as List).first['rawDataRef'] = null,
          (event) => (event['pages'] as List).first['conditionsDataRef'] = null,
          (event) => (event['pages'] as List).first['triggerCode'] = 0,
          (event) =>
              ((event['pages'] as List).first['commands'] as List).removeLast(),
          (event) => ((event['pages'] as List).first['commands'] as List)[0]
              ['indent'] = 1,
          (event) => ((event['pages'] as List).first['commands'] as List)[0]
              ['parameters'] = ['unattested sound'],
          (event) {
            final command =
                ((event['pages'] as List).first['commands'] as List)[0] as Map;
            command['originalIndex'] = 99;
            (command['sourceLocator'] as Map)['commandIndex'] = 99;
          },
        ]) {
          final json =
              jsonDecode(jsonEncode(ir.toJson())) as Map<String, dynamic>;
          final event = (json['map']['events'] as List)
              .cast<Map<String, dynamic>>()
              .singleWhere((event) => event['sourceEventId'] == pair.$2);
          mutate(event);
          final forged = SourceMapIr.fromJson(json)
              .map
              .events
              .singleWhere((event) => event.sourceEventId == pair.$2);
          expect(bound(forged), isFalse);
        }
        expect(
            program.isBoundToSourceEvent(
                source: source,
                profile: SourceEventProfile.forProject(source,
                    scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
),
                event: original),
            isFalse);
      }
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
