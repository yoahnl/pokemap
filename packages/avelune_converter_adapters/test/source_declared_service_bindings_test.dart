import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/source_center_recovery_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_party_trade_binding.dart';
import 'package:avelune_converter_adapters/src/source_pokedex_reward_binding.dart';
import 'package:avelune_converter_adapters/src/source_town_map_binding.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/declared_program_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

List<Map<String, Object?>> _programs() {
  final values = (jsonDecode(jsonEncode(
              fixtureSourceInterpretationProfile.toJson()['declaredPrograms']))
          as List)
      .cast<Map<String, Object?>>()
      .where((b) => const {'centerNurse', 'partyTrade', 'pokedexReward'}
          .contains(b['family']))
      .toList();
  for (final b in values.where((b) => b['family'] == 'pokedexReward')) {
    for (final page in (b['pages'] as Map).values.cast<Map>()) {
      for (final command in (page['list'] as List).cast<Map>()) {
        final p = command['parameters'] as List;
        for (var i = 0; i < p.length; i++) {
          if (p[i] is String) {
            p[i] = (p[i] as String).replaceAll('_count(1)', '_count(2)');
          }
        }
        if (command['code'] == 111 && p.length == 5 && p[0] == 1) p[3] = 1;
      }
    }
  }
  return values;
}

Map<String, List<int>> _catalogFiles() => {
      'Data/regional_dexes.dat': literalFixtureMarshal([
        null,
        [],
        [
          const LiteralFixtureSymbol('EMBERDRAGON'),
          const LiteralFixtureSymbol('SHELLLING')
        ]
      ]),
      'Data/species.dat': literalFixtureMarshal({
        for (final row in [
          ('EMBERDRAGON', 'Charizard'),
          ('SHELLLING', 'Squirtle')
        ])
          LiteralFixtureSymbol(row.$1):
              LiteralFixtureObject('GameData::Species', {
            '@id': LiteralFixtureSymbol(row.$1),
            '@species': LiteralFixtureSymbol(row.$1),
            '@form': 0,
            '@real_name': row.$2,
          })
      }),
      'PBS/pokemon.txt': utf8.encode(
          '[EMBERDRAGON]\nName = Charizard\n[SHELLLING]\nName = Squirtle\n'),
      'Data/items.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol('TOKEN'):
            const LiteralFixtureObject('GameData::Item', {
          '@id': LiteralFixtureSymbol('TOKEN'),
          '@real_name': 'Token',
          '@real_name_plural': 'Tokens',
          '@real_portion_name': null,
          '@real_portion_name_plural': null,
          '@pocket': 1,
          '@price': 10,
          '@sell_price': 5,
          '@bp_price': 0,
          '@field_use': 0,
          '@battle_use': 0,
          '@flags': [],
          '@consumable': true,
          '@show_quantity': true,
          '@move': null,
          '@real_description': 'An authored reward.',
          '@pbs_file_suffix': '',
        })
      }),
    };

void main() {
  test(
      'regional map bindings share a catalogue and preserve every represented static map association',
      () async {
    Future<LiteralTileFixture> fixture({bool badIdentity = false}) =>
        LiteralTileFixture.create(
            namespace: 'regional-places',
            interpretationProfile: syntheticSourceInterpretationProfile,
            scriptsBytes: syntheticInterpretationArchive,
            includeEventSystem: true,
            maps: [
              LiteralFixtureMap(id: 7),
              LiteralFixtureMap(id: 91)
            ],
            extraFiles: {
              'Data/map_metadata.dat': literalFixtureMarshal({
                for (final row in [(7, 1), (91, 2)])
                  row.$1: LiteralFixtureObject('GameData::MapMetadata', {
                    '@id': badIdentity && row.$1 == 91 ? 92 : row.$1,
                    '@town_map_size': null,
                    '@town_map_position': [3, row.$2, row.$2],
                  })
              }),
              'Data/town_map.dat': literalFixtureMarshal({
                3: const LiteralFixtureObject('GameData::TownMap', {
                  '@id': 3,
                  '@flags': [],
                  '@pbs_file_suffix': '',
                  '@real_name': 'Distant Archipelago',
                  '@filename': 'regional_view.png',
                  '@point': [
                    [1, 1, 'Harbour', null, null, null, null, null],
                    [2, 2, 'Observatory', null, null, null, null, null]
                  ],
                })
              }),
              'Graphics/UI/Town Map/regional_view.png': literalFixtureAtlas(),
            });
    final f = await fixture();
    final bindings = <SourceTownMapBinding>[];
    for (final id in [7, 91]) {
      bindings.add(await const SourceTownMapBindingResolver().read(
          source: f.source,
          files: f.files,
          sourceMapId: id,
          nativeMapIds: const {7: 'native7', 91: 'native91'}));
    }
    expect(canonicalJsonOf(bindings.first.catalog.toJson()),
        canonicalJsonOf(bindings.last.catalog.toJson()));
    expect(bindings.first.catalog.pointsOfInterest.map((p) => p.mapIds), [
      ['native7'],
      ['native91']
    ]);
    expect(bindings.first.mutations.map((m) => m.toJson(0)).toList(),
        bindings.last.mutations.map((m) => m.toJson(0)).toList());
    final bad = await fixture(badIdentity: true);
    await expectLater(
        const SourceTownMapBindingResolver().read(
            source: bad.source,
            files: bad.files,
            sourceMapId: 7,
            nativeMapIds: const {7: 'native7', 91: 'native91'}),
        throwsA(isA<SourceTownMapBindingUnavailable>()));
  });

  test(
      'two centres trades and dex rewards bind independently and project by complete source identity',
      () async {
    final programs = _programs();
    final profile = SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'capabilities': ['events', 'walking'],
      'declaredPrograms': programs,
    });
    final sourceEvents = <int, List<DeclaredProgramFixtureEvent>>{};
    for (final mapId in [17, 86]) {
      sourceEvents[mapId] = [
        for (final (index, b) in programs.indexed)
          DeclaredProgramFixtureEvent(
              id: 20 + index,
              name: 'Service $mapId/$index',
              x: 3 + index * 4,
              y: 8,
              pages: (b['pages'] as Map)
                  .values
                  .map((p) => Map<String, Object?>.from(p as Map))
                  .toList())
      ];
    }
    final fixture = await createDeclaredProgramFixture(
        namespace: 'two-service-neighbourhoods',
        profile: profile,
        maps: sourceEvents,
        tilesets: [
          LiteralFixtureTileset(id: 1, passages: const {385: 143})
        ],
        tileOverrides: {
          for (final id in sourceEvents.keys) id: {(3, 9): 385}
        },
        extraFiles: {
          ..._catalogFiles(),
          for (final b in programs)
            for (final p in (b['pages'] as Map).values)
              if ((p['graphic']['character_name'] as String).isNotEmpty)
                'Graphics/Characters/${p['graphic']['character_name']}.png':
                    literalFixtureAtlas(),
          'Audio/ME/synthetic_recovery.wav': sourceMapMusicFixtureWav(),
        });
    final source = fixture.source,
        analysis = SourceEventAnalyzer.forProject(fixture.source,
                profile: SourceEventProfile.forProject(fixture.source))
            .analyze();
    final recoveries = <ConverterId, SourceCenterRecoveryBinding>{};
    final trades = <ConverterId, SourcePartyTradeBinding>{};
    final rewards = <ConverterId, SourcePokedexRewardBinding>{};
    final catalog = NativePsdkCatalogManifest.builtin();
    final originalTradeCatalog = NativePsdkTrainerBundle.builtin();
    final selectedData = jsonDecode(jsonEncode(originalTradeCatalog.toJson()))
        as Map<String, dynamic>;
    selectedData['evolutions'] = [
      for (final row in (selectedData['evolutions'] as List).cast<Map>())
        {...row, 'evolutions': []}
    ];
    final selectedTradeCatalog = NativePsdkTrainerBundle.fromJson(selectedData);
    final selectedRulesHash = canonicalHashOf({
      for (final e in selectedTradeCatalog.evolutionsBySpeciesId.entries)
        e.key: e.value.toJson()
    });
    expect(
        selectedRulesHash,
        isNot(canonicalHashOf({
          for (final e in originalTradeCatalog.evolutionsBySpeciesId.entries)
            e.key: e.value.toJson()
        })));
    for (final event in analysis.events) {
      final nodes = event.pages.expand((p) => p.body.nodes).toList();
      if (nodes.any((n) => n is SourceCenterServiceProgramNode)) {
        recoveries[event.identity] = await const SourceCenterRecoveryResolver()
            .read(
                source: source,
                files: fixture.files,
                sourceMapId: event.sourceMapId,
                sourceEventId: event.sourceEventId);
      }
      if (nodes.any((n) => n is SourcePartyTradeProgramNode)) {
        trades[event.identity] = const SourcePartyTradeBindingResolver()
            .resolve(
                source: source,
                analysis: analysis,
                sourceMapId: event.sourceMapId,
                sourceEventId: event.sourceEventId,
                nativeCatalog: selectedTradeCatalog)!;
      }
      if (nodes.any((n) => n is SourcePokedexRewardProgramNode)) {
        rewards[event.identity] =
            (await const SourcePokedexRewardBindingResolver().read(
                source: source,
                analysis: analysis,
                files: fixture.files,
                sourceMapId: event.sourceMapId,
                sourceEventId: event.sourceEventId,
                nativeCatalog: catalog))!;
      }
    }
    expect(recoveries, hasLength(2));
    expect(trades, hasLength(2));
    for (final binding in trades.values) {
      expect(binding.nativeEvolutionRulesHash, selectedRulesHash);
    }
    expect(rewards, hasLength(2));
    for (final binding in rewards.values) {
      expect(binding.range.firstNationalDex, 6);
      expect(binding.range.lastNationalDex, 7);
      expect(binding.item.sourceSymbol, 'TOKEN');
      expect(binding.programs.first.sourceDexIndex, 2);
    }
    final nativeMaps = {
      for (final id in sourceEvents.keys)
        id: MapData(
            id: 'native_$id',
            name: 'Neighbourhood $id',
            size: const GridSize(width: 64, height: 64),
            layers: [
              MapLayer.collision(
                  id: 'collision',
                  name: 'Collision',
                  collisions:
                      List.generate(4096, (index) => index == 9 * 64 + 3))
            ])
    };
    final candidates = const SourceEventProjector().characterImportCandidates(
        source: source,
        analysis: analysis,
        nativeMaps: nativeMaps,
        centerRecoveryBinding: recoveries,
        partyTradeBinding: trades,
        pokedexRewardBinding: rewards);
    expect(candidates.map((e) => e.identity).toSet(),
        containsAll({...trades.keys, ...rewards.keys}));
    final characters = <String, SourceEventCharacterBinding>{};
    for (final event in analysis.events) {
      for (final page in event.pages) {
        final graphic = page.graphic!;
        final file = source.snapshot.entries.singleWhere((f) =>
            f.relativePath ==
            'Graphics/Characters/${graphic.characterName}.png');
        characters[sourceEventCharacterBindingKey(
                characterName: graphic.characterName,
                pattern: graphic.pattern,
                direction: graphic.direction)] =
            SourceEventCharacterBinding(
                characterId: 'character_${file.fileId.value.hashCode.abs()}',
                sourceSnapshotHash: source.snapshot.canonicalHash,
                sourceFileId: file.fileId,
                sourceFileHash: file.sha256!,
                sourcePattern: graphic.pattern,
                sourceDirection: graphic.direction);
      }
    }
    final projection = const SourceEventProjector().project(
        source: source,
        analysis: analysis,
        nativeMaps: nativeMaps,
        characterBindings: characters,
        centerRecoveryBinding: recoveries,
        partyTradeBinding: trades,
        pokedexRewardBinding: rewards);
    final admitted = (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .where((e) => e['status'] == 'adaptedStaticSemantics')
        .toList();
    expect(admitted.map((e) => e['sourceIdentity']).toSet(),
        containsAll([...trades.keys, ...rewards.keys].map((id) => id.value)));
    expect(projection.scenes, hasLength(8));
    expect(projection.dialogues, isNotEmpty);
    for (final id in [17, 86]) {
      expect(projection.nativeMaps[id]!.entities, hasLength(3));
    }
    final conditions = projection.scenes
        .expand((s) => s.graph.nodes)
        .map((n) => n.payload)
        .whereType<SceneConditionPayload>()
        .map((p) => p.conditionSource)
        .whereType<SceneConditionSource>()
        .where(
            (c) => c.sourceKind == SceneConditionSourceKind.pokedexCaughtCount)
        .toList();
    expect(conditions, hasLength(2));
    for (final condition in conditions) {
      expect(condition.pokedexSpeciesRange!.firstNationalDex, 6);
      expect(condition.pokedexSpeciesRange!.lastNationalDex, 7);
      expect(condition.pokedexMinimumCaughtCount, 1);
    }
    final wrong = trades.values.first;
    final other = analysis.events.singleWhere((e) =>
        trades.containsKey(e.identity) && e.sourceMapId != wrong.sourceMapId);
    expect(
        wrong.isBoundToEvent(source: source, analysis: analysis, event: other),
        isFalse);
    final original = canonicalJsonOf(source.archive.toJson());
    final rejected = const SourceEventProjector().characterImportCandidates(
        source: source,
        analysis: analysis,
        nativeMaps: nativeMaps,
        partyTradeBinding: {for (final id in trades.keys) id: wrong},
        pokedexRewardBinding: rewards,
        centerRecoveryBinding: recoveries);
    expect(rejected.map((e) => e.identity), isNot(contains(other.identity)));
    expect(canonicalJsonOf(source.archive.toJson()), original);
  });
}
