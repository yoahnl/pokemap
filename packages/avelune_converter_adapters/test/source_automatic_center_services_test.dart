import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/declared_program_fixture.dart';

List<Map<String, Object?>> _bindings() => (jsonDecode(jsonEncode(
            fixtureSourceInterpretationProfile.toJson()['declaredPrograms']))
        as List)
    .cast<Map<String, Object?>>()
    .where((binding) =>
        const {'centerPc', 'centerNurse'}.contains(binding['family']))
    .toList();

Future<SourceEventAnalysis> _analyze(String family,
    {String mutation = '', int mapId = 17, int eventId = 19}) async {
  final binding =
      _bindings().singleWhere((binding) => binding['family'] == family);
  final pages = (binding['pages'] as Map).values.cast<Map>().toList();
  for (final page in pages) {
    if (family == 'centerPc') (page['graphic'] as Map)['tile_id'] = 0;
    final commands = (page['list'] as List).cast<Map>();
    if (family == 'centerNurse') {
      final charset = (page['graphic'] as Map)['character_name'];
      for (final command in commands) {
        if (command['code'] == 209) {
          final route =
              ((command['parameters'] as List)[1] as Map)['list'] as List;
          for (final step in route.cast<Map>()) {
            if (step['code'] == 41) (step['parameters'] as List)[0] = charset;
          }
        }
        if (command['code'] == 509) {
          final step = (command['parameters'] as List).single as Map;
          if (step['code'] == 41) (step['parameters'] as List)[0] = charset;
        }
      }
    }
  }
  final commands = pages.first['list'] as List;
  if (mutation == 'unknown') {
    commands.insert(0, {
      '__class__': 'RPG::EventCommand',
      'code': 355,
      'indent': 0,
      'parameters': ['unqualified_service()']
    });
  }
  if (mutation == 'party heal') {
    (commands
            .cast<Map>()
            .singleWhere((command) => command['code'] == 314)['parameters']
        as List)[0] = 1;
  }
  if (mutation == 'wrong choice branch') {
    (commands
            .cast<Map>()
            .firstWhere((command) => command['code'] == 402)['parameters']
        as List)[0] = 1;
  }
  if (mutation == 'wrong reset') {
    final reset = (pages.last['list'] as List)
        .cast<Map>()
        .singleWhere((command) => command['code'] == 123);
    reset['parameters'] = ['B', 1];
  }
  final fixture = await createDeclaredProgramFixture(
      namespace: 'auto-$family-$mapId-$eventId',
      profile: syntheticSourceInterpretationProfile,
      maps: {
        mapId: [
          DeclaredProgramFixtureEvent(
              id: eventId,
              name: 'Un nom quelconque',
              x: 2,
              y: 3,
              pages:
                  pages.map((page) => Map<String, Object?>.from(page)).toList())
        ]
      });
  return SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
}

void main() {
  test('a declared binding elsewhere does not suppress automatic PC discovery',
      () async {
    final raw = syntheticSourceInterpretationProfile.toJson();
    raw['declaredPrograms'] = [
      _bindings().singleWhere((entry) => entry['family'] == 'centerPc')
    ];
    final profile = SourceInterpretationProfile.fromJson(raw);
    final binding =
        _bindings().singleWhere((entry) => entry['family'] == 'centerPc');
    final pages = (binding['pages'] as Map).values.cast<Map>().toList();
    for (final page in pages) {
      (page['graphic'] as Map)['tile_id'] = 0;
      (page['graphic'] as Map)['character_name'] = 'OtherTerminal';
    }
    final fixture = await createDeclaredProgramFixture(
        namespace: 'partial-declared-pc',
        profile: profile,
        maps: {
          17: [
            DeclaredProgramFixtureEvent(
                id: 2,
                name: 'Other PC',
                x: 2,
                y: 3,
                pages: pages
                    .map((page) => Map<String, Object?>.from(page))
                    .toList())
          ]
        });
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final program = analysis.events.single.pages.first.body.nodes.single
        as SourceCenterServiceProgramNode;
    expect(program.declaredProgram.automaticallyDiscovered, isTrue);
  });

  for (final mutation in [
    '',
    'wrong branch',
    'extra effect',
    'off condition'
  ]) {
    test('conditional automatic PC retains the denial branch: $mutation',
        () async {
      final binding =
          _bindings().singleWhere((entry) => entry['family'] == 'centerPc');
      final pages = (binding['pages'] as Map).values.cast<Map>().toList();
      for (final page in pages) {
        (page['graphic'] as Map)['tile_id'] = 0;
      }
      Map<String, Object?> command(
              int code, List<Object?> parameters, int indent) =>
          {
            '__class__': 'RPG::EventCommand',
            'code': code,
            'parameters': parameters,
            'indent': indent
          };
      pages.first['list'] = [
        command(111, [0, 86, mutation == 'off condition' ? 1 : 0], 0),
        command(123, ['A', 0], mutation == 'wrong branch' ? 0 : 1),
        command(0, [], 1),
        command(411, [], 0),
        command(101, ['The usual PC services are unavailable.'], 1),
        if (mutation == 'extra effect') command(121, [2, 2, 0], 1),
        command(0, [], 1),
        command(412, [], 0),
        command(0, [], 0)
      ];
      final fixture = await createDeclaredProgramFixture(
          namespace: 'conditional-pc-${mutation.replaceAll(' ', '-')}',
          profile: syntheticSourceInterpretationProfile,
          maps: {
            17: [
              DeclaredProgramFixtureEvent(
                  id: 2,
                  name: 'PC',
                  x: 2,
                  y: 3,
                  pages: pages
                      .map((page) => Map<String, Object?>.from(page))
                      .toList())
            ]
          });
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final programs = analysis.events.single.pages
          .expand((page) => page.body.nodes)
          .whereType<SourceCenterServiceProgramNode>()
          .toList();
      if (mutation.isNotEmpty) {
        expect(programs, isEmpty);
      } else {
        expect(programs, hasLength(2));
        expect(programs.first.pcAvailabilityCondition!.factId,
            endsWith(':switch:86'));
        expect(programs.first.pcDenialText!.text,
            'The usual PC services are unavailable.');
        expect(
            programs.first.pcAvailabilityCondition!.evaluate(facts: {
              programs.first.pcAvailabilityCondition!.factId!: false
            }),
            isFalse);
      }
    });
  }

  test('automatic nurse dialogue groups have distinct command spans', () async {
    final analysis = await _analyze('centerNurse');
    final program = analysis.events.single.pages.first.body.nodes.single
        as SourceCenterServiceProgramNode;
    final spans = [
      for (final group in ['greeting', 'acceptance', 'completion', 'refusal'])
        canonicalJsonOf(program.textGroupSpan(group).toJson())
    ];
    expect(spans.toSet(), hasLength(4));
  });

  for (final mode in ['valid', 'speed', 'dimensions', 'quota']) {
    test('automatic healing display derives verified source rows: $mode',
        () async {
      final bindings = (jsonDecode(jsonEncode(fixtureSourceInterpretationProfile
                      .toJson()['declaredPrograms'])
                  .replaceAll('SyntheticCenterNurse', 'SyntheticCenternurse'))
              as List)
          .cast<Map>();
      final nurse =
          bindings.singleWhere((binding) => binding['family'] == 'centerNurse');
      final display = bindings
          .singleWhere((binding) => binding['family'] == 'healingDisplay');
      final displayPages =
          (display['pages'] as Map).values.cast<Map>().toList();
      if (mode == 'speed') displayPages[1]['move_speed'] = 4;
      final png = image.encodePng(
          image.Image(width: mode == 'dimensions' ? 257 : 256, height: 192));
      final fixture = await createDeclaredProgramFixture(
          namespace: 'automatic-display-$mode',
          profile: syntheticSourceInterpretationProfile,
          extraFiles: {
            for (final page in displayPages.skip(1))
              'Graphics/Characters/${(page['graphic'] as Map)['character_name']}.png':
                  png,
          },
          maps: {
            17: [
              DeclaredProgramFixtureEvent(
                  id: 2,
                  name: 'Nurse',
                  x: 2,
                  y: 3,
                  pages: (nurse['pages'] as Map)
                      .values
                      .map((page) => Map<String, Object?>.from(page as Map))
                      .toList()),
              DeclaredProgramFixtureEvent(
                  id: 4,
                  name: 'Display',
                  x: 3,
                  y: 3,
                  pages: displayPages
                      .map((page) => Map<String, Object?>.from(page))
                      .toList())
            ]
          });
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final future = const SourceHealingDisplayBindingResolver().read(
          source: fixture.source,
          analysis: analysis,
          sourceMapId: 17,
          sourceEventId: 4,
          files: fixture.files,
          limits: mode == 'quota'
              ? const NativeWriteLimits(maxArtifactBytes: 1)
              : const NativeWriteLimits());
      if (mode == 'valid') {
        final result = await future;
        expect(result!.elements, hasLength(6));
        expect(result.elements.every((element) => element.frames.length == 4),
            isTrue);
        for (final variant in result.elements.indexed) {
          final direction =
              (displayPages[variant.$1 + 1]['graphic'] as Map)['direction'];
          for (final frame in variant.$2.frames.indexed) {
            expect(frame.$2.source.x, frame.$1);
            expect(frame.$2.source.y, const [2, 4, 6, 8].indexOf(direction));
            expect(frame.$2.source.width, 1);
            expect(frame.$2.source.height, 1);
            expect(frame.$2.durationMs, 125);
          }
        }
        final atlases = result.mutations
            .where((mutation) => mutation.actionId == 'tileset.import_image');
        expect(atlases, isNotEmpty);
        for (final atlas in atlases) {
          expect(atlas.parameters['tileWidth'], 64);
          expect(atlas.parameters['tileHeight'], 48);
        }
        expect(result.evidence['presentationOrigin'],
            'automaticSourceCharsetRows');
      } else {
        await expectLater(
            future, throwsA(isA<SourceHealingDisplayBindingUnavailable>()));
      }
    });
  }
  for (final complete in [true, false]) {
    test(
        'automatic healing display requires its complete linked nurse: $complete',
        () async {
      final bindings = (jsonDecode(jsonEncode(fixtureSourceInterpretationProfile
                      .toJson()['declaredPrograms'])
                  .replaceAll('SyntheticCenterNurse', 'SyntheticCenternurse'))
              as List)
          .cast<Map>();
      final nurse =
          bindings.singleWhere((binding) => binding['family'] == 'centerNurse');
      final display = bindings
          .singleWhere((binding) => binding['family'] == 'healingDisplay');
      final fixture = await createDeclaredProgramFixture(
          namespace: 'automatic-linked-display-$complete',
          profile: syntheticSourceInterpretationProfile,
          maps: {
            17: [
              if (complete)
                DeclaredProgramFixtureEvent(
                    id: 2,
                    name: 'Service',
                    x: 2,
                    y: 3,
                    pages: (nurse['pages'] as Map)
                        .values
                        .map((page) => Map<String, Object?>.from(page as Map))
                        .toList()),
              DeclaredProgramFixtureEvent(
                  id: 4,
                  name: 'Display',
                  x: 3,
                  y: 3,
                  pages: (display['pages'] as Map)
                      .values
                      .map((page) => Map<String, Object?>.from(page as Map))
                      .toList()),
            ]
          });
      final event = fixture.source.maps.single.map.events
          .singleWhere((event) => event.sourceEventId == 4);
      final program = resolveSourceHealingDisplayProgram(
          source: fixture.source,
          profile: SourceEventProfile.forProject(fixture.source),
          sourceMapId: 17,
          event: event);
      expect(program != null, complete);
      if (program != null) {
        expect(program.sourceNurseEventId, 2);
        expect(program.declaredProgram.automaticallyDiscovered, isTrue);
      }
    });
  }
  for (final family in ['centerPc', 'centerNurse']) {
    test(
        'automatic $family follows complete raw pages without declared bindings',
        () async {
      for (final row in [(17, 19), (83, 31)]) {
        final analysis = await _analyze(family, mapId: row.$1, eventId: row.$2);
        expect(
            analysis.profile.interpretationProfile!.declaredPrograms, isEmpty);
        final event = analysis.events.single;
        expect(event.isQuarantined, isFalse,
            reason: jsonEncode(event.pages
                .map((page) => page.diagnostics.map((d) => d.toJson()).toList())
                .toList()));
        expect(
            event.pages
                .expand((page) => page.body.nodes)
                .whereType<SourceCenterServiceProgramNode>(),
            hasLength(2));
      }
    });
    test('automatic $family refuses additional Ruby atomically', () async {
      final analysis = await _analyze(family, mutation: 'unknown');
      expect(
          analysis.events.single.pages
              .expand((page) => page.body.nodes)
              .whereType<SourceCenterServiceProgramNode>(),
          isEmpty);
    });
  }
  for (final mutation in ['party heal', 'wrong choice branch']) {
    test('automatic nurse refuses $mutation', () async {
      final analysis = await _analyze('centerNurse', mutation: mutation);
      expect(
          analysis.events.single.pages
              .expand((page) => page.body.nodes)
              .whereType<SourceCenterServiceProgramNode>(),
          isEmpty);
    });
  }
  test('automatic PC refuses reset of a different self switch', () async {
    final analysis = await _analyze('centerPc', mutation: 'wrong reset');
    expect(
        analysis.events.single.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceCenterServiceProgramNode>(),
        isEmpty);
  });
}
