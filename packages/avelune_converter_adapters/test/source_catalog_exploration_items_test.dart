import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _symbols = [
  'REPEL',
  'SUPERREPEL',
  'MAXREPEL',
  'ESCAPEROPE',
  'BICYCLE',
  'OLDROD',
  'GOODROD',
  'SUPERROD'
];

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value < 123) return [value + 5];
  var width = 1;
  while (value >= 1 << (width * 8)) {
    width++;
  }
  return [width, for (var i = 0; i < width; i++) (value >> (i * 8)) & 255];
}

List<int> _marshal(Object? value) {
  if (value == null) return [48];
  if (value is bool) return [value ? 84 : 70];
  if (value is int) return [105, ..._packed(value)];
  if (value is String || value is _Symbol) {
    final bytes = utf8.encode(value is _Symbol ? value.value : value as String);
    return [value is _Symbol ? 58 : 34, ..._packed(bytes.length), ...bytes];
  }
  if (value is List) {
    return [
      91,
      ..._packed(value.length),
      for (final v in value) ..._marshal(v)
    ];
  }
  if (value is Map) {
    return [
      123,
      ..._packed(value.length),
      for (final e in value.entries) ...[
        ..._marshal(e.key),
        ..._marshal(e.value)
      ]
    ];
  }
  final object = value as LiteralFixtureObject;
  return [
    111,
    ..._marshal(_Symbol(object.name)),
    ..._packed(object.fields.length),
    for (final e in object.fields.entries) ...[
      ..._marshal(_Symbol(e.key)),
      ..._marshal(e.value)
    ]
  ];
}

List<int> _compiledItems({bool qualify = true, String? omitSymbol}) => [
      4,
      8,
      ..._marshal({
        for (final symbol in _symbols.where((symbol) => symbol != omitSymbol))
          _Symbol(symbol): LiteralFixtureObject('GameData::Item', {
            '@id': _Symbol(symbol),
            '@real_name': symbol,
            '@real_name_plural': '${symbol}s',
            '@real_portion_name': null,
            '@real_portion_name_plural': null,
            '@pocket': _symbols.indexOf(symbol) >= 4 ? 8 : 1,
            '@price': 100,
            '@sell_price': 50,
            '@bp_price': 0,
            '@field_use': qualify ? 2 : 1,
            '@battle_use': 0,
            '@flags': _symbols.indexOf(symbol) >= 4
                ? ['KeyItem']
                : symbol == 'ESCAPEROPE'
                    ? <String>[]
                    : ['Repel', 'Fling_30'],
            '@consumable': _symbols.indexOf(symbol) < 4,
            '@show_quantity': null,
            '@move': null,
            '@real_description': 'Source exploration item',
            '@pbs_file_suffix': '',
          })
      })
    ];

Future<
        ({
          LiteralTileFixture fixture,
          NativeProjectDraft base,
          ProjectItemCatalog previous
        })>
    _fixture(List<int> scripts,
        {bool qualify = true, String? omitSymbol}) async {
  final qualification = NativeEncounterCatalogQualification.builtinKantoV1();
  final png = image.encodePng(image.Image(width: 1, height: 1, numChannels: 4));
  final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

      scriptsBytes: scripts,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(id: 98, events: [
          LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
            LiteralFixtureEventPage(commands: [
              for (var i = 0; i < 47; i++)
                LiteralFixtureEventCommand(355, ['pbReceiveItem(:ITEM_$i)']),
              const LiteralFixtureEventCommand(0, []),
            ])
          ])
        ])
      ],
      extraFiles: {
        'Data/items.dat':
            _compiledItems(qualify: qualify, omitSymbol: omitSymbol),
        'Data/species.dat': [4, 8, 123, 0],
        'PBS/items.txt': utf8.encode([
          for (var i = 0; i < 47; i++)
            '[ITEM_$i]\nName = Item $i\nPocket = 1\nPrice = 100\nSellPrice = 50\nDescription = Source item $i\n'
        ].join('\n')),
        for (final species in qualification.bundle.speciesById.values)
          if (species.forms.formId == '0')
            for (final direction in ['Front', 'Back'])
              'Graphics/Pokemon/$direction/${species.id.toUpperCase()}.png':
                  png,
      });
  final previous = ProjectItemCatalog(schemaVersion: 1, entries: [
    for (var i = 0; i < 9; i++)
      ProjectItemDefinition(
          id: sourcePbsItemBindingId(
                  fixture.snapshot.logicalProjectNamespace, 'ITEM_$i')
              .value,
          displayName: 'Item $i',
          pocketId: 'items',
          buyPrice: 100,
          sellPrice: 50,
          description: 'Source item $i',
          tags: {
            'source-imported'
          },
          uses: const [
            ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.repel(steps: 100))
          ])
  ]).normalized();
  var index = 0;
  NativeMutation mutation(String action, Map<String, Object?> parameters) =>
      NativeMutation(
          operationId: ConverterId('preceding_${index++}'),
          actionId: action,
          sourceEntityIds: [],
          targetEntityIds: [],
          parameters: parameters);
  final base = NativeProjectDraft(
      source: fixture.source,
      projectName: 'Exploration catalogue',
      parentPath: '/private/tmp',
      folderName: 'unused-exploration-catalogue',
      mapIds: {98: 'map98'},
      artifacts: [],
      mutations: [
        mutation('pokemon.catalog.write', {
          'relativePath': const ProjectPokemonConfig(
                  ruleset: PokemonRulesetProfile.pokeMapBetaV1)
              .catalogFiles['items'],
          'document':
              const ProjectItemCatalog(schemaVersion: 1, entries: []).toJson()
        }),
        for (final item in previous.entries)
          mutation('item.create', {'definition': item.toJson()}),
      ],
      compositionEvidence: {'sourceSemantics': <String, Object?>{}},
      limits: sourceCatalogStudyWriteLimits);
  return (fixture: fixture, base: base, previous: previous);
}

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  group('catalogue exploration definitions', () {
    late List<int> scripts;
    setUpAll(() async {
      scripts = await File(scriptsPath!).readAsBytes();
    });

    test(
        'seeds 55 definitions and three typed rods without granting inventory or progression',
        () async {
      final fixture = await _fixture(scripts);
      final result = (await SourceCatalogStudyComposer(
              nativeEncounterQualification:
                  NativeEncounterCatalogQualification.builtinKantoV1(),
              includeNativeEncounterConsumers: true)
          .compose(
              source: fixture.fixture.source,
              base: fixture.base,
              files: fixture.fixture.files,
              limits: sourceCatalogStudyWriteLimits))!;
      final catalog = result.projection.mergedItemCatalog!;
      expect(catalog.entries, hasLength(55));
      for (final previous in fixture.previous.entries) {
        expect(catalog.entries.singleWhere((item) => item.id == previous.id),
            previous);
      }
      final rods = catalog.entries
          .expand((item) => item.uses)
          .map((use) => use.effect)
          .whereType<ProjectItemFishingEffectDefinition>();
      expect(rods.map((rod) => rod.rodKind).toSet(),
          ProjectFishingRodKind.values.toSet());
      for (final symbol in _symbols) {
        final id = sourcePbsItemBindingId(
                fixture.fixture.snapshot.logicalProjectNamespace, symbol)
            .value;
        expect(catalog.entries.singleWhere((item) => item.id == id).uses,
            hasLength(1));
      }
      expect(result.draft.mutations.take(fixture.base.mutations.length),
          fixture.base.mutations);
      final appended =
          result.draft.mutations.skip(fixture.base.mutations.length);
      expect(
          appended.where((mutation) =>
              mutation.actionId == 'item.create' ||
              mutation.actionId.contains('inventory') ||
              mutation.actionId.contains('progression') ||
              mutation.actionId.contains('grant') ||
              mutation.actionId.contains('award')),
          isEmpty);
      final write = appended.singleWhere((m) =>
          m.actionId == 'pokemon.catalog.write' &&
          m.parameters['relativePath'] ==
              const ProjectPokemonConfig(
                      ruleset: PokemonRulesetProfile.pokeMapBetaV1)
                  .catalogFiles['items']);
      expect(base64Decode(write.parameters['beforeBytesBase64'] as String),
          utf8.encode(jsonEncode(encodeProjectItemCatalog(fixture.previous))));
      final evidence =
          result.projection.evidence['nativeExplorationItemDefinitions'] as Map;
      expect((evidence['previousNativeCatalog'] as Map)['itemIds'],
          fixture.previous.entries.map((item) => item.id).toList());
      expect(evidence['newlySeededSourceDefinitions'], hasLength(8));
      expect(evidence['initialPlayerStateMutated'], false);
      expect(
          ((result.projection.evidence['itemCatalogMerge']
              as Map)['preservedExistingIds'] as List),
          hasLength(9));
      expect(
          (result.draft.compositionEvidence['sourceCatalogs']
              as Map)['witnesses'],
          contains(isA<Map>().having(
              (entry) => entry['relativePath'], 'path', 'Data/items.dat')));
    });

    test('default composition keeps the previous 47 item semantics', () async {
      final fixture = await _fixture(scripts);
      final result = (await SourceCatalogStudyComposer(
              nativeEncounterQualification:
                  NativeEncounterCatalogQualification.builtinKantoV1())
          .compose(
              source: fixture.fixture.source,
              base: fixture.base,
              files: fixture.fixture.files,
              limits: sourceCatalogStudyWriteLimits))!;
      expect(result.projection.mergedItemCatalog!.entries, hasLength(47));
      expect(
          result.projection.evidence
              .containsKey('nativeExplorationItemDefinitions'),
          false);
      final itemFile = fixture.fixture.snapshot.entries
          .singleWhere((e) => e.relativePath == 'Data/items.dat');
      expect(fixture.fixture.files.reads, isNot(contains(itemFile.fileId)));
    });

    test('unqualified source definitions cannot seed exploration capabilities',
        () async {
      final fixture = await _fixture(scripts, qualify: false);
      await expectLater(
          SourceCatalogStudyComposer(
                  nativeEncounterQualification:
                      NativeEncounterCatalogQualification.builtinKantoV1(),
                  includeNativeEncounterConsumers: true)
              .compose(
                  source: fixture.fixture.source,
                  base: fixture.base,
                  files: fixture.fixture.files,
                  limits: sourceCatalogStudyWriteLimits),
          throwsA(isA<NativeWriteException>().having((e) => e.code, 'code',
              'catalogs.exploration_items.unqualified')));
    });
    test('missing source symbols remain quarantined rather than manufactured',
        () async {
      final fixture = await _fixture(scripts, omitSymbol: 'SUPERROD');
      await expectLater(
          SourceCatalogStudyComposer(
                  nativeEncounterQualification:
                      NativeEncounterCatalogQualification.builtinKantoV1(),
                  includeNativeEncounterConsumers: true)
              .compose(
                  source: fixture.fixture.source,
                  base: fixture.base,
                  files: fixture.fixture.files,
                  limits: sourceCatalogStudyWriteLimits),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code',
                  'catalogs.exploration_items.unqualified')
              .having((e) => e.message, 'message',
                  contains('item.symbol_missing'))));
    });

    test('changed compiled bytes fail their source witness', () async {
      final fixture = await _fixture(scripts);
      final changed =
          List<int>.of(fixture.fixture.sourceBytes['Data/items.dat']!);
      changed[changed.length - 1] ^= 1;
      fixture.fixture.files.overrides['Data/items.dat'] = changed;
      await expectLater(
          SourceCatalogStudyComposer(
                  nativeEncounterQualification:
                      NativeEncounterCatalogQualification.builtinKantoV1(),
                  includeNativeEncounterConsumers: true)
              .compose(
                  source: fixture.fixture.source,
                  base: fixture.base,
                  files: fixture.fixture.files,
                  limits: sourceCatalogStudyWriteLimits),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'semantics.witness.changed')));
    });

    test('regenerates identical evidence and draft bytes for the same source',
        () async {
      final fixture = await _fixture(scripts);
      final composer = SourceCatalogStudyComposer(
          nativeEncounterQualification:
              NativeEncounterCatalogQualification.builtinKantoV1(),
          includeNativeEncounterConsumers: true);
      final first = (await composer.compose(
          source: fixture.fixture.source,
          base: fixture.base,
          files: fixture.fixture.files,
          limits: sourceCatalogStudyWriteLimits))!;
      final second = (await composer.compose(
          source: fixture.fixture.source,
          base: fixture.base,
          files: fixture.fixture.files,
          limits: sourceCatalogStudyWriteLimits))!;
      expect(first.draft.canonicalHash, second.draft.canonicalHash);
      expect(first.projection.canonicalHash, second.projection.canonicalHash);
      expect(first.draft.mutations.map((m) => m.toJson(0)),
          second.draft.mutations.map((m) => m.toJson(0)));
      expect(first.draft.artifacts.map((artifact) => artifact.bytes),
          second.draft.artifacts.map((artifact) => artifact.bytes));
    });
  },
      skip: scriptsPath == null
          ? 'Requires the exact attested source scripts archive.'
          : false);
}
