import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'package:avelune_converter_adapters/src/source_actor_preparation_program.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test(
      'original actor pose cycle is closed and rejects altered route semantics',
      () async {
    final f = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((p) => p.isNotEmpty)
                .toList());
    final analysis = SourceEventAnalyzer.forProject(f.source,
            profile: SourceEventProfile.forProject(f.source))
        .analyze();
    final event = analysis.eventAt(9, 8)!;
    final programs =
        sourceActorPreparationPrograms(source: f.source, analysis: analysis);
    expect(programs.keys, contains(event.identity));
    expect(
        programs[event.identity]!.isBoundTo(f.source, analysis, event), isTrue);
    for (final mutation in ['unknown', 'barrier', 'dialogue', 'flag']) {
      final first = event.pages.first;
      final changed = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: event.name,
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: [
            SourceEventPageAnalysis(
                sourcePage: first.sourcePage,
                locator: first.locator,
                condition: first.condition,
                graphic: first.graphic,
                rawDataRef: first.rawDataRef,
                diagnostics: first.diagnostics,
                body: SourceEventBlock(
                    span: first.body.span,
                    diagnostics: mutation == 'unknown'
                        ? [
                            SourceEventDiagnostic(
                                'events.script.unsupported', first.locator)
                          ]
                        : [],
                    nodes: [
                      for (final n in first.body.nodes)
                        if (!(mutation == 'barrier' &&
                            n is SourceMoveRouteBarrierNode))
                          if (mutation == 'dialogue' && n is SourceTextNode)
                            SourceTextNode(n.span, 'Changed',
                                followingChoice: n.followingChoice)
                          else if (mutation == 'flag' && n is SourceSwitchNode)
                            SourceSwitchNode(n.span,
                                firstId: n.firstId,
                                lastId: n.lastId,
                                factIds: n.factIds,
                                value: !n.value)
                          else
                            n
                    ])),
            ...event.pages.skip(1)
          ]);
      final altered = SourceEventAnalysis(
          profile: analysis.profile,
          diagnostics: analysis.diagnostics,
          events: [
            for (final e in analysis.events)
              if (e.identity == event.identity) changed else e
          ]);
      expect(programs[event.identity]!.isBoundTo(f.source, altered, changed),
          isFalse,
          reason: mutation);
      expect(
          sourceActorPreparationPrograms(source: f.source, analysis: altered)
              .containsKey(event.identity),
          isFalse,
          reason: mutation);
    }
    if (Platform.environment['AVELUNE_POSE_DUMP'] case final dump?) {
      Map<String, Object?> dumpEvent(SourceEventDefinition e) => {
            'id': e.sourceEventId,
            'x': e.x,
            'y': e.y,
            'pages': [
              for (final p in e.pages)
                {
                  'condition': p.condition.toJson(),
                  'graphic': p.graphic == null
                      ? null
                      : {
                          'name': p.graphic!.characterName,
                          'direction': p.graphic!.direction,
                          'pattern': p.graphic!.pattern,
                          'through': p.graphic!.through
                        },
                  'trigger': p.triggerCode,
                  'nodes': p.body.nodes
                      .map((n) => switch (n) {
                            SourceTextNode() => {
                                'kind': 'text',
                                'span': n.span.toJson(),
                                'text': n.text
                              },
                            SourceWaitNode() => {
                                'kind': 'wait',
                                'span': n.span.toJson(),
                                'ticks': n.durationTicks
                              },
                            SourceForcedMoveRouteNode() => n.toJson(),
                            SourceActorPoseSequenceNode() => n.toJson(),
                            _ => {
                                'kind': n.runtimeType.toString(),
                                'span': n.span.toJson()
                              }
                          })
                      .toList()
                }
            ]
          };
      await File(dump).writeAsString(jsonEncode({
        'event': dumpEvent(event),
        'actors': [
          for (final id in [13, 14, 75])
            if (analysis.eventAt(9, id) case final a?) dumpEvent(a)
        ]
      }));
    }
    expect(event.isQuarantined, isFalse,
        reason: event.pages
            .map((p) => p.diagnostics.map((d) => d.code).toList())
            .toList()
            .toString());
    final pose = event.pages.first.body.nodes
        .whereType<SourceActorPoseSequenceNode>()
        .single;
    expect(pose.targetSourceCharacterId, 14);
    expect(pose.characterName, 'trainer_FRLG_RIVAL1');
    expect(pose.hue, 0);
    expect(pose.direction, 8);
    expect(pose.durationTicks, 8);
    expect(pose.span.firstCommandIndex, 44);
    expect(pose.span.lastCommandIndex, 52);
    expect(pose.rawDataRefs, hasLength(9));
    expect(
        pose.isBoundToSourceEvent(
            source: f.source, profile: analysis.profile, event: event),
        isTrue);
    final scripts = await f.files.read(f.source.snapshot.entries
        .singleWhere((e) => e.relativePath == 'Data/Scripts.rxdata')
        .fileId);
    final interpretation = SourceInterpretationProfile.fromJson(
        jsonDecode(await File(profile!).readAsString()));
    for (final change in [
      'none',
      'frame',
      'name',
      'hue',
      'direction',
      'wait',
      'copy',
      'repeat',
      'skippable',
      'target',
      'sideEffect'
    ]) {
      LiteralFixtureObject step(int code, List<Object?> parameters) =>
          LiteralFixtureObject(
              'RPG::MoveCommand', {'@code': code, '@parameters': parameters});
      final steps = <LiteralFixtureObject>[
        for (final (index, pattern) in [1, 2, 3, 0].indexed) ...[
          step(41, [
            change == 'name' && index == 2 ? 'other' : 'trainer_FRLG_RIVAL1',
            change == 'hue' && index == 2 ? 1 : 0,
            change == 'direction' && index == 2 ? 6 : 8,
            change == 'frame' && index == 3 ? 1 : pattern
          ]),
          step(15, [change == 'wait' && index == 2 ? 3 : 2])
        ],
        if (change == 'sideEffect') step(45, ['effect()']),
      ];
      final commands = [
        LiteralFixtureEventCommand(209, [
          change == 'target' ? -1 : 14,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': change == 'repeat',
            '@skippable': change == 'skippable',
            '@list': [...steps, step(0, [])]
          })
        ]),
        for (final (index, s) in steps.indexed)
          LiteralFixtureEventCommand(509, [
            change == 'copy' && index == 2 ? step(15, [2]) : s
          ])
      ];
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: interpretation,
          scriptsBytes: scripts,
          includeEventSystem: true,
          maps: [
            LiteralFixtureMap(id: 1, events: [
              LiteralFixtureEvent(
                  id: 1,
                  x: 1,
                  y: 0,
                  pages: [LiteralFixtureEventPage(commands: commands)])
            ])
          ]);
      final a = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final nodes = a.events.single.pages.single.body.nodes
          .whereType<SourceActorPoseSequenceNode>();
      expect(nodes.length, change == 'none' ? 1 : 0, reason: change);
      if (change != 'none') {
        expect(a.events.single.isQuarantined, isTrue, reason: change);
      }
    }
  },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: root == null || snapshot == null || profile == null);
}
