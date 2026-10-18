import 'dart:convert';
import 'support/declared_program_fixture.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _project(
        {required String namespace,
        required int mapId,
        required int eventId,
        required String name,
        required int x,
        required int y,
        List<LiteralFixtureEventCommand>? commands}) =>
    LiteralTileFixture.create(
        namespace: namespace,
        scriptsBytes: syntheticInterpretationArchive,
        interpretationProfile: SourceInterpretationProfile.fromJson({
          ...syntheticSourceInterpretationProfile.toJson(),
          'capabilities': ['events']
        }),
        includeEventSystem: true,
        maps: [
          LiteralFixtureMap(id: mapId, width: 6, height: 6, layers: [
            List.filled(36, 384),
            List.filled(36, 0),
            List.filled(36, 0)
          ], events: [
            LiteralFixtureEvent(id: eventId, name: name, x: x, y: y, pages: [
              LiteralFixtureEventPage(
                  commands: commands ??
                      const [
                        LiteralFixtureEventCommand(101, ['Un plan local.']),
                        LiteralFixtureEventCommand(355, ['pbShowMap']),
                        LiteralFixtureEventCommand(0, []),
                      ])
            ])
          ])
        ]);

List<Map<String, Object?>> _bindings(int displayId, int targetMapId) {
  final bindings = (jsonDecode(jsonEncode(
              fixtureSourceInterpretationProfile.toJson()['declaredPrograms']))
          as List)
      .cast<Map<String, Object?>>()
      .where((b) =>
          const {
            'centerNurse',
            'centerPc',
            'partyTrade',
            'pokedexReward',
            'healingDisplay'
          }.contains(b['family']) ||
          b['id'] == 'synthetic-externalWarp')
      .toList();
  for (final binding in bindings) {
    for (final page in (binding['pages'] as Map).values.cast<Map>()) {
      if (binding['family'] == 'centerPc') {
        (page['graphic'] as Map)['tile_id'] = 0;
      }
      for (final c in (page['list'] as List).cast<Map>()) {
        final p = c['parameters'] as List;
        if (binding['family'] == 'centerNurse' &&
            c['code'] == 209 &&
            p.first == 4) {
          p[0] = displayId;
        }
        if (binding['family'] == 'centerNurse' &&
            c['code'] == 355 &&
            p.single == 'get_character(4).pattern = 0') {
          p[0] = 'get_character($displayId).pattern = 0';
        }
        if (binding['family'] == 'externalWarp' && c['code'] == 201) {
          p[1] = targetMapId;
        }
      }
    }
  }
  return bindings;
}

SourceInterpretationProfile _declaredProfile(
        List<Map<String, Object?>> bindings) =>
    SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'capabilities': ['events'],
      'declaredPrograms': bindings
    });

void main() {
  test(
      'complete map display program follows structure in two relocated renamed projects',
      () async {
    for (final row in [
      (17, 9, 'Panneau ouest', 1, 2),
      (86, 33, 'Carnet des rues', 4, 1)
    ]) {
      final fixture = await _project(
          namespace: 'relocated-${row.$1}',
          mapId: row.$1,
          eventId: row.$2,
          name: row.$3,
          x: row.$4,
          y: row.$5);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final event = analysis.eventAt(row.$1, row.$2)!;
      expect(event.isQuarantined, isFalse);
      final node = event.pages.single.body.nodes.single;
      expect(node, isA<SourceTownMapProgramNode>());
      expect((node as SourceTownMapProgramNode).text.text, 'Un plan local.');
      expect(
          node.isBoundToSourceEvent(
              source: fixture.source,
              profile: analysis.profile,
              sourceMapId: row.$1,
              event: fixture.source.maps.single.map.events.single),
          isTrue);
    }
  });
  test(
      'declared native families follow complete programs in two renamed relocated projects',
      () async {
    for (final row in [(17, 20, 'Premier'), (86, 40, 'Second')]) {
      final mapId = row.$1,
          offset = row.$2,
          targetMapId = mapId + 11,
          displayId = offset + 4;
      final bindings = _bindings(displayId, targetMapId);
      final events = <DeclaredProgramFixtureEvent>[];
      for (final (index, binding) in bindings.indexed) {
        events.add(DeclaredProgramFixtureEvent(
            id: binding['family'] == 'healingDisplay'
                ? displayId
                : offset + index + 10,
            name: '${row.$3} panneau $index',
            x: index + 1,
            y: 8 + index,
            pages: (binding['pages'] as Map)
                .values
                .map((p) => Map<String, Object?>.from(p as Map))
                .toList()));
      }
      final fixture = await createDeclaredProgramFixture(
          namespace: 'declared-${row.$1}',
          profile: _declaredProfile(bindings),
          extraFiles: {
            for (final b in bindings)
              for (final p in (b['pages'] as Map).values)
                if ((p['graphic']['character_name'] as String).isNotEmpty)
                  'Graphics/Characters/${p['graphic']['character_name']}.png':
                      literalFixtureAtlas()
          },
          maps: {
            mapId: events,
            targetMapId: []
          });
      final profile = SourceEventProfile.forProject(fixture.source);
      final analysis =
          SourceEventAnalyzer.forProject(fixture.source, profile: profile)
              .analyze();
      final kinds = <SourceDeclaredProgramFamily>{};
      for (final event in events) {
        final analyzed = analysis.eventAt(mapId, event.id)!;
        expect(analyzed.isQuarantined, isFalse,
            reason:
                '${row.$3} ${event.name} ${analyzed.pages.map((p) => p.diagnostics.map((d) => d.code).toList()).toList()}');
        final raw = fixture.source.maps
            .singleWhere((m) => m.map.sourceMapId == mapId)
            .map
            .events
            .singleWhere((e) => e.sourceEventId == event.id);
        final match = matchSourceDeclaredProgram(
            source: fixture.source,
            profile: profile,
            sourceMapId: mapId,
            event: raw,
            families: SourceDeclaredProgramFamily.values.toSet());
        expect(match, isNotNull);
        kinds.add(match!.binding.family);
        expect(match.toJson()['mode'], 'declaredProgramBinding');
        expect(match.toJson()['rubySemanticsAutomaticallyCertified'], isFalse);
        if (match.binding.family ==
            SourceDeclaredProgramFamily.healingDisplay) {
          final display = resolveSourceHealingDisplayProgram(
              source: fixture.source,
              profile: profile,
              sourceMapId: mapId,
              event: raw);
          expect(display, isNotNull);
          expect(display!.sourceEventId, displayId);
          expect(display.x, event.x);
          expect(display.y, event.y);
        } else {
          expect(analyzed.pages.expand((p) => p.body.nodes), isNotEmpty);
          if (match.binding.family ==
              SourceDeclaredProgramFamily.pokedexReward) {
            final reward = analyzed.pages
                .expand((p) => p.body.nodes)
                .whereType<SourcePokedexRewardProgramNode>()
                .singleWhere((p) => p.pickup != null);
            expect(reward.minimumCount, 3);
            expect(reward.pickup!.sourceSymbol, 'TOKEN');
          }
          if (match.binding.family ==
              SourceDeclaredProgramFamily.externalWarp) {
            final warp =
                analyzed.pages.first.body.nodes.single as SourceWarpNode;
            expect(warp.originalProgram, isNotNull);
            expect(warp.targetSourceMapId, targetMapId);
          }
        }
      }
      expect(
          kinds,
          containsAll({
            SourceDeclaredProgramFamily.centerNurse,
            SourceDeclaredProgramFamily.centerPc,
            SourceDeclaredProgramFamily.partyTrade,
            SourceDeclaredProgramFamily.pokedexReward,
            SourceDeclaredProgramFamily.healingDisplay,
            SourceDeclaredProgramFamily.externalWarp
          }));
    }
  });
  test(
      'declarations reject unknown Ruby malformed operators and extra native operations before source admission',
      () {
    for (final change in <void Function(List<Map<String, Object?>>)>[
      (bindings) {
        final pc = bindings.singleWhere((b) => b['family'] == 'centerPc');
        (((pc['pages'] as Map)['open'] as Map)['list'] as List)
            .first['parameters'] = ['pbPokeCenterPC; unknownEffect()'];
      },
      (bindings) {
        final trade = bindings.singleWhere((b) => b['family'] == 'partyTrade');
        ((((trade['pages'] as Map)['program'] as Map)['list'] as List)
            .first['parameters'] as List)[2] = 9;
      },
      (bindings) {
        final nurse = bindings.singleWhere((b) => b['family'] == 'centerNurse');
        final list = ((nurse['pages'] as Map)['choice'] as Map)['list'] as List;
        list.insert(list.length - 1, {
          '__class__': 'RPG::EventCommand',
          'code': 314,
          'indent': 0,
          'parameters': [0]
        });
      },
      (bindings) {
        final nurse = bindings.singleWhere((b) => b['family'] == 'centerNurse');
        ((nurse['parameters'] as Map)['textGroups'] as Map)['choice']
            ['completion'] = [];
      },
      (bindings) {
        final pc = bindings.singleWhere((b) => b['family'] == 'centerPc');
        (pc['pages'] as Map)['open']['graphic']['opacity'] = 'opaque';
      },
      (bindings) {
        final nurse = bindings.singleWhere((b) => b['family'] == 'centerNurse');
        final list = (nurse['pages'] as Map)['choice']['list'] as List;
        final route = list.firstWhere((c) => c['code'] == 209)['parameters'][1];
        route['repeat'] = true;
      },
    ]) {
      final bindings = _bindings(24, 28);
      change(bindings);
      expect(() => _declaredProfile(bindings), throwsA(isA<ContractError>()));
    }
  });
  test(
      'ambiguous declared family bindings leave the complete event quarantined',
      () async {
    final binding =
        _bindings(24, 28).singleWhere((b) => b['family'] == 'centerPc');
    final fixture = await createDeclaredProgramFixture(
        namespace: 'ambiguous-declaration',
        profile: _declaredProfile([
          binding,
          {...binding, 'id': 'second-same-program'}
        ]),
        maps: {
          17: [
            DeclaredProgramFixtureEvent(
                id: 9,
                name: 'Console',
                x: 2,
                y: 2,
                pages: (binding['pages'] as Map)
                    .values
                    .map((p) => Map<String, Object?>.from(p as Map))
                    .toList())
          ]
        });
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    expect(analysis.eventAt(17, 9)!.isQuarantined, isTrue);
  });

  test('unknown or extra script never becomes a native map display program',
      () async {
    for (final script in ['pbShowMap; unknownEffect()', 'unknownEffect()']) {
      final fixture = await _project(
          namespace: 'rejected-program',
          mapId: 17,
          eventId: 9,
          name: 'Panneau',
          x: 1,
          y: 2,
          commands: [
            const LiteralFixtureEventCommand(101, ['Un plan local.']),
            LiteralFixtureEventCommand(355, [script]),
            const LiteralFixtureEventCommand(0, [])
          ]);
      final event = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze()
          .eventAt(17, 9)!;
      expect(event.isQuarantined, isTrue);
      expect(
          event.pages
              .expand((p) => p.body.nodes)
              .whereType<SourceTownMapProgramNode>(),
          isEmpty);
    }
  });
}
