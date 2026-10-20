import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';
import 'package:avelune_converter_adapters/src/source_hole_native_program.dart';

SourceEventDefinition _copy(
  SourceEventDefinition event, {
  String? name,
  int? eventId,
  SourceEventPage? sourcePage,
  List<SourceEventNode>? nodes,
}) {
  final page = event.pages.single;
  return SourceEventDefinition(
    sourceMapId: event.sourceMapId,
    sourceEventId: eventId ?? event.sourceEventId,
    sourceFileId: event.sourceFileId,
    identity: event.identity,
    name: name ?? event.name,
    x: event.x,
    y: event.y,
    locator: event.locator,
    pages: [
      SourceEventPageAnalysis(
        sourcePage: sourcePage ?? page.sourcePage,
        locator: page.locator,
        condition: page.condition,
        graphic: page.graphic,
        body: nodes == null
            ? page.body
            : SourceEventBlock(
                nodes: nodes,
                span: page.body.span,
                diagnostics: page.body.diagnostics,
              ),
        rawDataRef: page.rawDataRef,
        diagnostics: page.diagnostics,
      ),
    ],
  );
}

SourceEventDefinition _commands(
  NormalizedSourceProject source,
  SourceEventDefinition event,
  void Function(List<dynamic>) mutate,
) {
  final ir = source.maps.singleWhere(
    (ir) => ir.map.sourceMapId == event.sourceMapId,
  );
  final json = jsonDecode(jsonEncode(ir.toJson())) as Map<String, dynamic>;
  final raw = (json['map']['events'] as List).cast<Map>().singleWhere(
        (row) => row['sourceEventId'] == event.sourceEventId,
      );
  mutate(raw['pages'][0]['commands'] as List<dynamic>);
  for (final (index, command)
      in (raw['pages'][0]['commands'] as List).indexed) {
    command['originalIndex'] = index;
    command['sourceLocator']['commandIndex'] = index;
  }
  final changed = SourceMapIr.fromJson(json)
      .map
      .events
      .singleWhere((row) => row.sourceEventId == event.sourceEventId);
  return _copy(event, sourcePage: changed.pages.single);
}

void main() {
  final root = Platform.environment['AVELUNE_HOLE_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_HOLE_SOURCE_SNAPSHOT'];
  group('complete native hole programs', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late List<SourceEventDefinition> holes;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(
        root!,
        snapshot!,
        selectedMapIds: {203, 204, 361, 362, 363, 364, 365, 366},
        supplementalRoots:
            (Platform.environment['AVELUNE_HOLE_SUPPLEMENTAL_ROOTS'] ?? '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList(),
      );
      source = fixture.source;
      analysis = SourceEventAnalyzer.forProject(
        source,
        profile: SourceEventProfile.forProject(source),
      ).analyze();
      holes = analysis.events.where(isSourceHoleNativeIdentity).toList();
    });
    Map<ConverterId, SourceHoleNativeProgram> programs(
      List<SourceEventDefinition> events,
    ) =>
        sourceHoleNativePrograms(
          source: source,
          analysis: SourceEventAnalysis(
            profile: analysis.profile,
            events: events,
            diagnostics: [],
          ),
        );
    test('all eighteen exact programs retain destination and source waits', () {
      expect(holes, hasLength(18));
      final bound = programs(holes);
      expect(bound, hasLength(18));
      for (final event in holes) {
        final program = bound[event.identity]!;
        expect(
          program.isBoundTo(source: source, analysis: analysis, event: event),
          true,
        );
        expect(program.waits.map((wait) => wait.durationMs), [200, 400]);
        expect(program.fallingSound.name, 'Falling Object');
        expect(program.landingSound.name, 'Landing Object');
        expect(program.warp.direction, 0);
      }
    });
    test('duplicate source identities refuse the family', () {
      expect(programs([...holes, holes.first]), isEmpty);
    });
    test('an outside identity cannot reuse an exact source program', () {
      expect(programs([_copy(holes.first, eventId: 999)]), isEmpty);
    });
    for (final change in [
      'remove509',
      'extra509',
      'change209Target',
      'changeDestination',
      'removeTerminator',
    ]) {
      test('$change cannot preserve native admission', () {
        final event = holes.first;
        final changed = _commands(source, event, (commands) {
          switch (change) {
            case 'remove509':
              commands.removeAt(1);
            case 'extra509':
              commands.insert(2, jsonDecode(jsonEncode(commands[1])));
            case 'change209Target':
              commands[0]['parameters'][0] = 0;
            case 'changeDestination':
              commands[7]['parameters'][1] = 361;
            case 'removeTerminator':
              commands.removeLast();
          }
        });
        expect(programs([changed]), isEmpty);
      });
    }
    test('a caller cannot delete opaque routes and retain source authority',
        () {
      final event = holes.first;
      final changed = _copy(
        event,
        nodes: event.pages.single.body.nodes
            .where((node) => node is! SourceUnknownNode)
            .toList(),
      );
      expect(programs([changed]), isEmpty);
    });
    test(
      'caller AST pitch or wait changes are refused even with original raw pages',
      () {
        final event = holes.first;
        for (final pitch in [true, false]) {
          final changed = _copy(
            event,
            nodes: [
              for (final node in event.pages.single.body.nodes)
                if (pitch && node is SourceSoundEffectNode)
                  SourceSoundEffectNode(
                    node.span,
                    name: node.name,
                    volume: node.volume,
                    pitch: 101,
                    rawDataRef: node.rawDataRef,
                    profileHash: node.profileHash,
                  )
                else if (!pitch && node is SourceWaitNode)
                  SourceWaitNode(
                    node.span,
                    durationTicks: node.durationTicks + 1,
                    profileHash: node.profileHash,
                  )
                else
                  node,
            ],
          );
          expect(programs([changed]), isEmpty);
        }
      },
    );
    test('raw owner metadata changes are refused', () {
      expect(programs([_copy(holes.first, name: 'Unattested Hole')]), isEmpty);
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
