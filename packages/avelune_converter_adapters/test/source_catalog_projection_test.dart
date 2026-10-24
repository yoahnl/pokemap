import 'dart:convert';
import 'package:avelune_converter_adapters/src/source_catalog_projection.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_catalog_preservation.dart';

final class _Symbol {
  const _Symbol(this.text);
  final String text;
}

final class _Object {
  const _Object(this.name, this.fields);
  final String name;
  final Map<String, Object?> fields;
}

List<int> _packed(int n) {
  if (n == 0) return [0];
  if (n > 0 && n < 123) return [n + 5];
  if (n < 0 && n > -124) return [(n - 5) & 255];
  var width = 1;
  while (n >= (1 << (width * 8)) || n < -(1 << (width * 8))) {
    width++;
  }
  return [
    n >= 0 ? width : (-width) & 255,
    for (var i = 0; i < width; i++) (n >> (i * 8)) & 255
  ];
}

List<int> _value(Object? v) {
  if (v == null) return [48];
  if (v is int) return [105, ..._packed(v)];
  if (v is String || v is _Symbol) {
    final bytes = utf8.encode(v is String ? v : (v as _Symbol).text);
    return [v is String ? 34 : 58, ..._packed(bytes.length), ...bytes];
  }
  if (v is Map) {
    return [
      123,
      ..._packed(v.length),
      for (final e in v.entries) ...[..._value(e.key), ..._value(e.value)]
    ];
  }
  if (v is _Object) {
    return [
      111,
      ..._value(_Symbol(v.name)),
      ..._packed(v.fields.length),
      for (final e in v.fields.entries) ...[
        ..._value(_Symbol(e.key)),
        ..._value(e.value)
      ]
    ];
  }
  throw StateError('$v');
}

List<int> _compiled(List<String> order) => [
      4,
      8,
      ..._value({
        for (final symbol in order)
          _Symbol(symbol): _Object('GameData::Species',
              {'@id': _Symbol(symbol), '@species': _Symbol(symbol), '@form': 0})
      })
    ];

String _species(String symbol,
        {String? evolution, String moves = '1,TACKLE,5,QUICKATTACK'}) =>
    '''[$symbol]
Name = Shared name
Types = NORMAL
BaseStats = 30,56,35,72,25,35
GenderRatio = Female50Percent
GrowthRate = Medium
BaseExp = 51
CatchRate = 255
Happiness = 50
Abilities = RUNAWAY
Moves = $moves
EggGroups = Field
HatchSteps = 3840
Generation = 1
${evolution == null ? '' : 'Evolutions = $evolution,Level,20'}
''';

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _fixture(
    {String? pokemon,
    String? forms,
    String encounters = '[098]\nLand,11\n80,RATTATA,14,17\n70,SPEAROW,13,17\n',
    String? trainers,
    String? items,
    bool compiled = true,
    bool missingQuick = false,
    String namespace = 'original-catalog',
    List<String> order = const ['UNSELECTED', 'SPEAROW', 'RATTATA', 'RATICATE'],
    Map<String, List<int>> extra = const {}}) async {
  final f = await LiteralTileFixture.create(namespace: namespace, maps: [
    LiteralFixtureMap(id: 98)
  ], extraFiles: {
    'PBS/pokemon.txt': utf8.encode(pokemon ??
        '${_species('RATTATA', evolution: 'RATICATE')}${_species('RATICATE')}${_species('SPEAROW')}'),
    if (forms != null) 'PBS/pokemon_forms.txt': utf8.encode(forms),
    'PBS/types.txt': utf8.encode('[NORMAL]\nName = Normal\n'),
    'PBS/abilities.txt': utf8
        .encode('[RUNAWAY]\nName = Run Away\nDescription = Source ability\n'),
    'PBS/moves.txt': utf8.encode('''[TACKLE]
Name = Tackle
Type = NORMAL
Category = Physical
Power = 40
Accuracy = 100
TotalPP = 35
Target = NearOther
FunctionCode = None
${missingQuick ? '' : '[QUICKATTACK]\nName = Quick Attack\nType = NORMAL\nCategory = Physical\nPower = 40\nAccuracy = 100\nTotalPP = 30\nPriority = 1\nTarget = NearOther\nFunctionCode = UnmappedEffect\n'}'''),
    'PBS/encounters.txt': utf8.encode(encounters),
    if (trainers != null) 'PBS/trainers.txt': utf8.encode(trainers),
    if (trainers != null)
      'PBS/trainer_types.txt': utf8.encode('[CAMPER]\nName = Camper\n'),
    if (items != null) 'PBS/items.txt': utf8.encode(items),
    if (compiled) 'Data/species.dat': _compiled(order),
    ...extra,
  });
  final pbs =
      await const SourcePbsParser().read(snapshot: f.snapshot, files: f.files);
  return (fixture: f, pbs: pbs);
}

Future<SourceCatalogProjection> _read(
        ({LiteralTileFixture fixture, SourcePbsProject pbs}) f,
        {ProjectItemCatalog? existing,
        List<String> items = const [],
        List<SourcePbsIdentity> trainers = const [],
        SourceCatalogProjectionLimits limits =
            const SourceCatalogProjectionLimits(),
        ScanCancellation? cancellation}) =>
    const SourceCatalogProjector().read(
        source: f.fixture.source,
        pbs: f.pbs,
        files: f.fixture.files,
        nativeMapIds: {98: 'native-route9'},
        existingItemCatalog: existing,
        requestedItemSymbols: items,
        requestedTrainerKeys: trainers,
        limits: limits,
        cancellation: cancellation);
List<Map<String, Object?>> _docs(
        SourceCatalogProjection p, SourceCatalogDocumentKind kind) =>
    preservedCatalogDocuments(p)
        .where((d) => d.kind == kind)
        .map((d) => d.document)
        .toList();
Matcher _code(String code) =>
    isA<ContractError>().having((e) => e.code, 'code', code);

PokemonCatalogCoherenceReport _coherence(SourceCatalogProjection p) =>
    const PokemonCatalogCoherenceValidator().validate(
        PokemonCatalogCoherenceSnapshot(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogs: [
          for (final d in preservedCatalogDocuments(p)
              .where((d) => d.kind == SourceCatalogDocumentKind.catalog))
            PokemonCatalogDocument(
                path: d.relativePath,
                value: PokemonCatalogFile.fromJson(
                    Map<String, dynamic>.from(d.document))),
          PokemonCatalogDocument(
              path: 'data/pokemon/catalogs/items.json',
              value: PokemonCatalogFile(
                  schemaVersion: 1,
                  kind: 'items',
                  catalog: 'items',
                  meta: const PokemonDataMeta(description: 'Imported items'),
                  entries: preservedCatalogItems(p)!
                      .entries
                      .map((e) => Map<String, dynamic>.from(e.toJson()))
                      .toList()))
        ],
            species: [
          for (final d in preservedCatalogDocuments(p)
              .where((d) => d.kind == SourceCatalogDocumentKind.species))
            PokemonCatalogDocument(
                path: d.relativePath,
                value: PokemonSpeciesFile.fromJson(
                    Map<String, dynamic>.from(d.document)))
        ],
            learnsets: [
          for (final d in preservedCatalogDocuments(p)
              .where((d) => d.kind == SourceCatalogDocumentKind.learnset))
            PokemonCatalogDocument(
                path: d.relativePath,
                value: PokemonLearnsetFile.fromJson(
                    Map<String, dynamic>.from(d.document)))
        ],
            evolutions: [
          for (final d in preservedCatalogDocuments(p)
              .where((d) => d.kind == SourceCatalogDocumentKind.evolution))
            PokemonCatalogDocument(
                path: d.relativePath,
                value: PokemonEvolutionFile.fromJson(
                    Map<String, dynamic>.from(d.document)))
        ],
            media: [
          for (final d in preservedCatalogDocuments(p)
              .where((d) => d.kind == SourceCatalogDocumentKind.media))
            PokemonCatalogDocument(
                path: d.relativePath,
                value: PokemonMediaFile.fromJson(
                    Map<String, dynamic>.from(d.document)))
        ]));

void main() {
  group('native battle form evolution publication', () {
    NativePsdkTrainerBundle catalog(PokemonEvolutionEntry rule) {
      final raw = (jsonDecode(jsonEncode(
          NativePsdkTrainerBundle.builtin().toJson())) as Map)
          .cast<String, dynamic>();
      final template = (raw['species'] as List).first as Map;
      final media = (raw['media'] as List).cast<Map>().firstWhere(
          (row) => row['speciesId'] == template['id']);
      final fallback = (raw['fallbackMedia'] as List).cast<Map>();
      final front = fallback.firstWhere((row) =>
          (row['targetPath'] as String).endsWith('_front.png'));
      final back = fallback.firstWhere((row) =>
          (row['targetPath'] as String).endsWith('_back.png'));
      raw['species'] = [for (final id in ['alpha', 'beta']) {
        ...template, 'id': id, 'slug': id, 'names': {'en': id},
        'forms': {'baseFormId': id, 'formId': '0',
          'isBaseForm': true, 'otherForms': <String>[]},
        'refs': {'learnset': id, 'evolution': id, 'media': id},
      }];
      raw['sourceLearnsets'] = [for (final id in ['alpha', 'beta'])
        PokemonLearnsetFile(speciesId: id, startingMoves: const ['tackle'])
            .toJson()];
      raw['media'] = [for (final id in ['alpha', 'beta'])
        {...media, 'speciesId': id, 'variants': {'0': {
          'frontStatic': front['targetPath'],
          'backStatic': back['targetPath'],
        }}}];
      raw['fallbackMedia'] = [front, back];
      raw['evolutions'] = [
        PokemonEvolutionFile(speciesId: 'alpha', evolutions: [rule,
          const PokemonEvolutionEntry(targetSpeciesId: 'beta',
              method: 'level_up', minLevel: 20)]).toJson(),
        const PokemonEvolutionFile(speciesId: 'beta').toJson(),
      ];
      return NativePsdkTrainerBundle.fromJson(raw);
    }
    Future<SourceCatalogProjection> publish(NativePsdkTrainerBundle bundle)
        async {
      final f = await _fixture(encounters: '');
      return const SourceCatalogProjector().read(
          source: f.fixture.source, pbs: f.pbs, files: f.fixture.files,
          nativeMapIds: {98: 'native-fixture'}, nativeTrainerBundle: bundle,
          requestedNativeSpeciesIds: ['alpha']);
    }
    PokemonEvolutionFile evolution(SourceCatalogProjection projection) =>
        PokemonEvolutionFile.fromJson(Map<String, dynamic>.from(
            projection.documents.singleWhere((row) => row.relativePath ==
                'data/pokemon/evolutions/alpha.json').document));
    List<String> graphErrors(SourceCatalogProjection projection) =>
        const PokemonCatalogCoherenceValidator().validate(
            PokemonCatalogCoherenceSnapshot(
                ruleset: PokemonRulesetProfile.pokeMapBetaV1,
                species: [for (final row in projection.documents.where(
                    (row) => row.kind == SourceCatalogDocumentKind.species))
                  PokemonCatalogDocument(path: row.relativePath,
                      value: PokemonSpeciesFile.fromJson(
                          Map<String, dynamic>.from(row.document)))],
                evolutions: [for (final row in projection.documents.where(
                    (row) => row.kind == SourceCatalogDocumentKind.evolution))
                  PokemonCatalogDocument(path: row.relativePath,
                      value: PokemonEvolutionFile.fromJson(
                          Map<String, dynamic>.from(row.document)))],
            )).diagnostics.where((row) => const {
              'evolution.self_target', 'evolution.cycle_detected'
            }.contains(row.code)).map((row) => row.code).toList();

    test('preserves exact gemme evidence outside the progression graph',
        () async {
      const rule = PokemonEvolutionEntry(targetSpeciesId: 'alpha',
          method: 'conditional', conditionText: {
            'psdk': '[{"type":"gemme","value":"fixture_orb"}]'});
      final bundle = catalog(rule);
      final before = canonicalHashOf(bundle.toJson(),
          limits: nativePsdkCatalogShardJsonLimits);
      final projected = await publish(bundle);
      expect(evolution(projected).evolutions.single.targetSpeciesId, 'beta');
      expect(graphErrors(projected), isEmpty);
      final adaptation =
          (projected.evidence['nativeEvolutionAdaptations'] as List).single
              as Map;
      expect(adaptation['speciesId'], 'alpha');
      expect(adaptation['sourceEvolution'], rule.toJson());
      expect(adaptation['runtimeBattleTransformationQualified'], isFalse);
      expect(adaptation['progressionEvolutionPublished'], isFalse);
      expect(bundle.evolutionsBySpeciesId['alpha']!.evolutions.first.toJson(),
          rule.toJson());
      expect(canonicalHashOf(bundle.toJson(),
          limits: nativePsdkCatalogShardJsonLimits), before);
    });

    test('keeps gemme with typed progression or extra text constraints',
        () async {
      for (final typedProgression in [true, false]) {
        final projected = await publish(catalog(PokemonEvolutionEntry(
            targetSpeciesId: 'alpha', method: 'conditional',
            minLevel: typedProgression ? 20 : null,
            conditionText: {
              'psdk': '[{"type":"gemme","value":"fixture_orb"}]',
              if (!typedProgression) 'other': 'Authored restriction',
            })));
        expect(evolution(projected).evolutions.first.targetSpeciesId, 'alpha');
        expect(graphErrors(projected), containsAll([
          'evolution.self_target', 'evolution.cycle_detected']));
        expect(projected.evidence['nativeEvolutionAdaptations'] ?? const [],
            isEmpty);
      }
    });

    for (final (label, method, text) in [
      ('non gemme', 'conditional',
          '[{"type":"futureCondition","value":"fixture_orb"}]'),
      ('malformed', 'conditional', 'invalid json'),
      ('mixed', 'conditional',
          '[{"type":"gemme","value":"fixture_orb"},{"type":"minLevel","value":20}]'),
      ('unknown key', 'conditional',
          '[{"type":"gemme","value":"fixture_orb","extra":true}]'),
      ('invalid symbol', 'conditional',
          '[{"type":"gemme","value":"../fixture_orb"}]'),
      ('wrong method', 'level_up',
          '[{"type":"gemme","value":"fixture_orb"}]'),
    ]) {
      test('keeps $label self-targets subject to the coherence gate', () async {
        final projected = await publish(catalog(PokemonEvolutionEntry(
            targetSpeciesId: 'alpha', method: method,
            minLevel: method == 'level_up' ? 20 : null,
            conditionText: {'psdk': text})));
        expect(evolution(projected).evolutions.first.targetSpeciesId, 'alpha');
        expect(graphErrors(projected), containsAll([
          'evolution.self_target', 'evolution.cycle_detected']));
        expect(projected.evidence['nativeEvolutionAdaptations'] ?? const [],
            isEmpty);
      });
    }
  });

  test('attested PBS entry references fit without duplicating source fields',
      () async {
    final f = await _fixture(
        pokemon: '${_species('RATTATA')}OriginalUnknown = ${'x' * 12000}\n');
    final p = await _read(f,
        limits:
            const SourceCatalogProjectionLimits(maxEvidenceCodeUnits: 45000));
    expect(p.evidence['version'], 2);
    final references = (p.evidence['entries'] as List).cast<Map>();
    expect(references, isNotEmpty);
    expect(
        references.every((row) =>
            (row['source'] as Map)['kind'] == 'sourcePbsEntryReference'),
        isTrue);
    final restored = p.restoreSourceEntries(pbs: f.pbs);
    for (var i = 0; i < restored.length; i++) {
      final reference = references.elementAt(i)['source'] as Map;
      final expected = f.pbs.entries.singleWhere((entry) =>
          canonicalJsonOf(entry.headerLocator.toJson()) ==
          canonicalJsonOf(reference['headerLocator']));
      expect(restored[i]['source'], expected.toJson());
    }
    final rattata = restored.singleWhere((row) =>
        ((row['source'] as Map)['identity'] as Map)['sourceSymbol'] ==
        'RATTATA');
    expect(
        ((rattata['source'] as Map)['fields'] as List).cast<Map>().singleWhere(
            (field) => field['key'] == 'OriginalUnknown')['rawValue'],
        'x' * 12000);
  });

  test('PBS entry restoration refuses foreign PBS and altered references',
      () async {
    final f = await _fixture();
    final p = await _read(f);
    final foreign = await _fixture(namespace: 'foreign');
    expect(() => p.restoreSourceEntries(pbs: foreign.pbs),
        throwsA(_code('source.catalog.entry_reference')));
    final changed =
        await _fixture(pokemon: _species('RATTATA', moves: '1,TACKLE'));
    expect(() => p.restoreSourceEntries(pbs: changed.pbs),
        throwsA(_code('source.catalog.entry_reference')));
    for (final field in [
      'canonicalHash',
      'identity',
      'headerLocator',
      'version'
    ]) {
      final evidence =
          jsonDecode(jsonEncode(p.evidence)) as Map<String, Object?>;
      final reference =
          ((evidence['entries'] as List).first as Map)['source'] as Map;
      reference[field] = field == 'version' ? 7 : 'altered';
      expect(
          () => SourceCatalogProjection(evidence: evidence)
              .restoreSourceEntries(pbs: f.pbs),
          throwsA(_code('source.catalog.entry_reference')));
    }
  });

  test('entry restoration retains blocked duplicate locators and multiplicity',
      () async {
    final f =
        await _fixture(pokemon: '${_species('RATTATA')}${_species('RATTATA')}');
    final p = await _read(f);
    final duplicates = f.pbs.entries
        .where((entry) => entry.identity?.sourceSymbol == 'RATTATA')
        .toList();
    expect(duplicates, hasLength(2));
    expect(duplicates.every((entry) => entry.isBlocked), isTrue);
    final evidence = <String, Object?>{
      ...p.evidence,
      'entries': [
        for (final entry in duplicates)
          {
            'source': {
              'kind': 'sourcePbsEntryReference',
              'version': 1,
              'identity': entry.identity!.toJson(),
              'headerLocator': entry.headerLocator.toJson(),
              'canonicalHash': canonicalHashOf(entry.toJson()).value,
            },
            'dataImported': false,
          }
      ],
    };
    final restored = SourceCatalogProjection(evidence: evidence)
        .restoreSourceEntries(pbs: f.pbs);
    expect(restored.map((row) => row['source']),
        duplicates.map((entry) => entry.toJson()));
    expect((restored.first['source'] as Map)['headerLocator'],
        isNot((restored.last['source'] as Map)['headerLocator']));
    final rows = evidence['entries'] as List;
    rows.add(rows.first);
    expect(
        () => SourceCatalogProjection(evidence: evidence)
            .restoreSourceEntries(pbs: f.pbs),
        throwsA(_code('source.catalog.entry_reference')));
  });

  test('entry restoration requires versioned context and honors cancellation',
      () async {
    final f = await _fixture();
    final p = await _read(f);
    for (final field in [
      'version',
      'profile',
      'namespace',
      'sourceSnapshotHash',
      'pbsHash'
    ]) {
      final evidence = <String, Object?>{...p.evidence, field: 'altered'};
      expect(
          () => SourceCatalogProjection(evidence: evidence)
              .restoreSourceEntries(pbs: f.pbs),
          throwsA(_code('source.catalog.entry_reference')));
    }
    expect(
        () => p.restoreSourceEntries(
            pbs: f.pbs, cancellation: ScanCancellation()..cancel()),
        throwsA(_code('source.cancelled')));
  });

  test('duplicate source ability slots project unique native identities',
      () async {
    final f = await _fixture(
        pokemon:
            '${_species('RATTATA').replaceFirst('Abilities = RUNAWAY', 'Abilities = RUNAWAY,RUNAWAY')}${_species('SPEAROW')}');
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.species,
        sourceSymbol: 'RATTATA');
    final sourceField = f.pbs.lookup(key)!.field('Abilities')!;
    final before = f.pbs.canonicalHash;
    expect(sourceField.values, ['RUNAWAY', 'RUNAWAY']);
    final p = await _read(f);
    final report = _coherence(p);
    expect(report.errorCount, 0, reason: jsonEncode(report.toJson()));
    final species = PokemonSpeciesFile.fromJson(Map<String, dynamic>.from(
        _docs(p, SourceCatalogDocumentKind.species)
            .singleWhere((s) => s['id'] == key.sourceId.value)));
    final abilityId = f.pbs
        .lookup(SourcePbsIdentity(
            namespace: f.pbs.logicalProjectNamespace,
            family: SourcePbsFamily.abilities,
            sourceSymbol: 'RUNAWAY'))!
        .identity!
        .sourceId
        .value;
    expect(species.abilities.primary, abilityId);
    expect(species.abilities.secondary, isNull);
    expect(species.abilities.hidden, isNull);
    expect(p.hasBlockingDiagnostics, false);
    expect(p.evidence['sourceAbilitySlotSemanticsQualified'], false);
    final preserved = (p.evidence['preservedFields'] as List)
        .cast<Map>()
        .singleWhere((e) =>
            e['identityKey'] == key.key && e['kind'] == 'sourceAbilitySlots');
    expect(preserved['abilities'], ['RUNAWAY', 'RUNAWAY']);
    expect(preserved['hiddenAbilities'], isEmpty);
    expect(preserved['sourceAbilitySlotSemanticsQualified'], false);
    expect((preserved['fields'] as List).single, sourceField.toJson());
    expect(
        p.diagnostics.any((d) =>
            d.code == 'source.catalog.ability_slot_semantics_unqualified' &&
            d.identityKey == key.key &&
            !d.blocking &&
            d.locator == sourceField.locator),
        true);
    expect(
        f.pbs.lookup(key)!.field('Abilities')!.values, ['RUNAWAY', 'RUNAWAY']);
    expect(f.pbs.canonicalHash, before);
  });
  test('hidden ability collision is preserved without invented native slot',
      () async {
    final f = await _fixture(
        pokemon:
            '${_species('RATTATA')}HiddenAbilities = RUNAWAY\n${_species('SPEAROW')}');
    final p = await _read(f);
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.species,
        sourceSymbol: 'RATTATA');
    final species = PokemonSpeciesFile.fromJson(Map<String, dynamic>.from(
        _docs(p, SourceCatalogDocumentKind.species)
            .singleWhere((s) => s['id'] == key.sourceId.value)));
    final report = _coherence(p);
    expect(report.errorCount, 0, reason: jsonEncode(report.toJson()));
    expect(species.abilities.secondary, isNull);
    expect(species.abilities.hidden, isNull);
    final preserved = (p.evidence['preservedFields'] as List)
        .cast<Map>()
        .singleWhere((e) =>
            e['identityKey'] == key.key && e['kind'] == 'sourceAbilitySlots');
    expect(preserved['abilities'], ['RUNAWAY']);
    expect(preserved['hiddenAbilities'], ['RUNAWAY']);
    expect(f.pbs.lookup(key)!.field('HiddenAbilities')!.values, ['RUNAWAY']);
    expect(p.hasBlockingDiagnostics, false);
  });
  test('distinct normal and hidden abilities retain their native roles',
      () async {
    final f = await _fixture(
        pokemon:
            '${_species('RATTATA').replaceFirst('Abilities = RUNAWAY', 'Abilities = RUNAWAY,EARLYBIRD')}HiddenAbilities = PICKUP\n${_species('SPEAROW')}',
        extra: {
          'PBS/abilities.txt': utf8.encode(
              '[RUNAWAY]\nName = Run Away\n[EARLYBIRD]\nName = Early Bird\n[PICKUP]\nName = Pickup\n')
        });
    final p = await _read(f);
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.species,
        sourceSymbol: 'RATTATA');
    final species = PokemonSpeciesFile.fromJson(Map<String, dynamic>.from(
        _docs(p, SourceCatalogDocumentKind.species)
            .singleWhere((s) => s['id'] == key.sourceId.value)));
    String abilityId(String symbol) => f.pbs
        .lookup(SourcePbsIdentity(
            namespace: f.pbs.logicalProjectNamespace,
            family: SourcePbsFamily.abilities,
            sourceSymbol: symbol))!
        .identity!
        .sourceId
        .value;
    expect(species.abilities.primary, abilityId('RUNAWAY'));
    expect(species.abilities.secondary, abilityId('EARLYBIRD'));
    expect(species.abilities.hidden, abilityId('PICKUP'));
    final report = _coherence(p);
    expect(report.errorCount, 0, reason: jsonEncode(report.toJson()));
    expect(p.hasBlockingDiagnostics, false);
  });
  test(
      'closes selected encounter dependencies and preserves exact slots inactive',
      () async {
    final f = await _fixture();
    final p = await _read(f);
    expect(_docs(p, SourceCatalogDocumentKind.species), hasLength(3));
    final table = preservedCatalogEncounters(p).single;
    expect(table.chancePerStep, 0);
    expect(table.entries.map((e) => (e.weight, e.minLevel, e.maxLevel)),
        [(80, 14, 17), (70, 13, 17)]);
    expect(
        table.entries[0].speciesId,
        f.pbs
            .lookup(SourcePbsIdentity(
                namespace: f.pbs.logicalProjectNamespace,
                family: SourcePbsFamily.species,
                sourceSymbol: 'RATTATA'))!
            .identity!
            .sourceId
            .value);
    expect(p.evidence['runtimeReady'], false);
    expect(p.assetMutations, isEmpty);
    expect(p.artifacts, isEmpty);
    expect(p.hasBlockingDiagnostics, false);
  });
  test(
      'national rank uses full compiled insertion order including unselected species',
      () async {
    final p = await _read(await _fixture());
    final sourceIds = (p.evidence['nationalDex'] as Map)['numbers'] as Map;
    expect(sourceIds['RATTATA'], 3);
    expect(sourceIds['SPEAROW'], 2);
    expect(
        _docs(p, SourceCatalogDocumentKind.species)
            .map((s) => s['nationalDex'])
            .toSet(),
        {2, 3, 4});
    expect(
        _docs(p, SourceCatalogDocumentKind.species).every(
            (s) => (s['classification'] as Map)['isEnabledInProject'] == false),
        true);
  });
  test(
      'same names and source forms retain different stable identities and inheritance',
      () async {
    final f = await _fixture(
        forms: '[RATTATA,1]\nFormName = Shared name\nTypes = NORMAL\n');
    final p = await _read(f);
    final species = _docs(p, SourceCatalogDocumentKind.species);
    expect(species, hasLength(4));
    expect(species.map((s) => s['id']).toSet(), hasLength(4));
    final form =
        species.singleWhere((s) => (s['forms'] as Map)['formId'] == '1');
    expect(form['nationalDex'], 3);
    expect((form['baseStats'] as Map)['spe'], 72);
    expect((form['forms'] as Map)['isBaseForm'], false);
  });
  test(
      'catalog moves preserve unsupported function source and never claim execution',
      () async {
    final p = await _read(await _fixture());
    final moves = _docs(p, SourceCatalogDocumentKind.catalog)
        .singleWhere((c) => c['catalog'] == 'moves')['entries'] as List;
    expect(moves, hasLength(2));
    for (final raw in moves) {
      final m = PokemonMove.fromJson(Map<String, dynamic>.from(raw as Map));
      expect(m.engineSupportLevel, PokemonMoveEngineSupportLevel.catalogOnly);
      expect(m.effects, isEmpty);
      expect(m.sourceRefs.showdownMoveId, isNull);
    }
    expect(jsonEncode(p.evidence), contains('UnmappedEffect'));
  });
  test(
      'missing dependency quarantines entire encounter table and dependent species',
      () async {
    final p = await _read(await _fixture(missingQuick: true));
    expect(preservedCatalogEncounters(p), isEmpty);
    expect(_docs(p, SourceCatalogDocumentKind.species), isEmpty);
    expect(
        p.diagnostics.any(
            (d) => d.code == 'source.catalog.reference_missing' && d.blocking),
        true);
    expect(jsonEncode(p.evidence), contains('QUICKATTACK'));
  });
  test('missing compiled dex does not invent required national number',
      () async {
    final p = await _read(await _fixture(compiled: false));
    expect(_docs(p, SourceCatalogDocumentKind.species), isEmpty);
    expect(preservedCatalogEncounters(p), isEmpty);
    expect(
        p.diagnostics
            .any((d) => d.code == 'source.catalog.national_dex_unqualified'),
        true);
  });
  test('duplicate source identity blocks dependent unit', () async {
    final p = await _read(await _fixture(
        pokemon:
            '${_species('RATTATA')}${_species('RATTATA')}${_species('SPEAROW')}'));
    expect(preservedCatalogEncounters(p), isEmpty);
    expect(p.hasBlockingDiagnostics, true);
  });
  test('item merge retains AC13 ID and existing native use without duplication',
      () async {
    final f = await _fixture(
        items:
            '[BURNHEAL]\nName = Burn Heal\nPocket = 2\nPrice = 200\nSellPrice = 50\nDescription = Source description\n');
    final id =
        sourcePbsItemBindingId(f.pbs.logicalProjectNamespace, 'BURNHEAL').value;
    final old = ProjectItemDefinition(
        id: id,
        displayName: 'Burn Heal',
        pocketId: 'medicine',
        buyPrice: 200,
        sellPrice: 50,
        description: 'Source description',
        uses: [
          const ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.cureStatus(
                  mode: ProjectItemStatusCureMode.listed, statusIds: {'burn'}))
        ]);
    final p = await _read(f,
        items: ['BURNHEAL'],
        existing: ProjectItemCatalog(schemaVersion: 1, entries: [old]));
    expect(preservedCatalogItems(p)!.entries.single, old);
    expect(p.assetMutations.where((m) => m.actionId == 'item.create'), isEmpty);
  });
  test(
      'source item changed since AC13 blocks merge instead of losing use provenance',
      () async {
    final f = await _fixture(
        items:
            '[BURNHEAL]\nName = Burn Heal\nPocket = 2\nPrice = 999\nSellPrice = 50\n');
    final id =
        sourcePbsItemBindingId(f.pbs.logicalProjectNamespace, 'BURNHEAL').value;
    final p = await _read(f,
        items: ['BURNHEAL'],
        existing: ProjectItemCatalog(schemaVersion: 1, entries: [
          ProjectItemDefinition(
              id: id,
              displayName: 'Burn Heal',
              pocketId: 'medicine',
              buyPrice: 200,
              sellPrice: 50)
        ]));
    expect(preservedCatalogItems(p), isNull);
    expect(
        p.diagnostics
            .any((d) => d.code == 'source.catalog.item_binding_conflict'),
        true);
  });
  test(
      'literal trainer party closes refs without attaching battle and rejects incomplete group',
      () async {
    final f = await _fixture(
        trainers: '[CAMPER,Jo,2]\nPokemon = RATTATA,15\nMoves = TACKLE\n');
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.trainers,
        trainerType: 'CAMPER',
        trainerName: 'Jo',
        version: 2);
    final p = await _read(f, trainers: [key]);
    expect(preservedCatalogTrainers(p).single.team.single.level, 15);
    expect(preservedCatalogTrainers(p).single.preBattleDialogueId, isNull);
    final incomplete = await _fixture(
        trainers: '[CAMPER,Jo,2]\nPokemon = MISSING,15\nMoves = TACKLE\n');
    final q = await _read(incomplete, trainers: [key]);
    expect(preservedCatalogTrainers(q), isEmpty);
    expect(q.hasBlockingDiagnostics, true);
  });
  test(
      'trainer unsupported per-pokemon overrides preserve whole party without defaults',
      () async {
    final f = await _fixture(
        trainers:
            '[CAMPER,Jo]\nPokemon = RATTATA,15\nMoves = TACKLE\nIV = 31\n');
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.trainers,
        trainerType: 'CAMPER',
        trainerName: 'Jo');
    final p = await _read(f, trainers: [key]);
    expect(preservedCatalogTrainers(p), isEmpty);
    expect(
        p.diagnostics
            .any((d) => d.code == 'source.catalog.trainer_field_unsupported'),
        true);
    expect(jsonEncode(p.restoreSourceEntries(pbs: f.pbs)), contains('IV'));
  });
  test('source compiled bytes are hash bound and reject mutation', () async {
    final f = await _fixture();
    f.fixture.files.overrides['Data/species.dat'] = _compiled(['RATTATA']);
    await expectLater(_read(f), throwsA(_code('source.catalog.file_changed')));
  });
  test(
      'same source repeated gives canonical hash and IDs independent of manifest order',
      () async {
    final f = await _fixture();
    final a = await _read(f), b = await _read(f);
    expect(a.canonicalHash, b.canonicalHash);
    expect(
        () => (a.evidence['entries'] as List).clear(), throwsUnsupportedError);
  });
  test('source profile/snapshot binding cannot be substituted', () async {
    final f = await _fixture(), g = await _fixture(namespace: 'foreign');
    await expectLater(
        const SourceCatalogProjector().read(
            source: f.fixture.source,
            pbs: g.pbs,
            files: f.fixture.files,
            nativeMapIds: {98: 'native-route9'}),
        throwsA(_code('source.catalog.binding')));
  });
  test('closure quota and cancellation interrupt before unbounded projection',
      () async {
    final f = await _fixture();
    await expectLater(
        _read(f,
            limits: const SourceCatalogProjectionLimits(maxClosureEntries: 1)),
        throwsA(_code('source.catalog.quota')));
    final cancellation = ScanCancellation()..cancel();
    await expectLater(_read(f, cancellation: cancellation),
        throwsA(_code('source.cancelled')));
  });
  test(
      'native companion refs close and all documents validate without catalog fallback',
      () async {
    final p =
        await _read(await _fixture(forms: '[RATTATA,1]\nFormName = Variant\n'));
    final report = _coherence(p);
    expect(report.errorCount, 0, reason: jsonEncode(report.toJson()));
    expect(report.warningCount, greaterThan(0));
  });
  test(
      'last repeated encounter method replaces slots and excludes overwritten missing refs',
      () async {
    final p = await _read(await _fixture(
        encounters:
            '[098]\nLand,20\n100,MISSING,3\nWater,5\n10,SPEAROW,7\nLand\n80,RATTATA,14,17\n'));
    expect(preservedCatalogEncounters(p), hasLength(2));
    final land = preservedCatalogEncounters(p)
        .singleWhere((t) => t.encounterKind == EncounterKind.walk);
    expect(land.entries.map((e) => e.weight), [80]);
    expect(p.hasBlockingDiagnostics, false);
    expect(jsonEncode(p.evidence), contains('MISSING'));
  });
  test(
      'source evolution trailing optional parameter stays empty and target closes',
      () async {
    final pokemon =
        '${_species('RATTATA')}Evolutions = RATICATE,Happiness,\n${_species('RATICATE')}${_species('SPEAROW')}';
    final p = await _read(await _fixture(pokemon: pokemon));
    expect(_docs(p, SourceCatalogDocumentKind.species), hasLength(3));
    final evolutions = _docs(p, SourceCatalogDocumentKind.evolution)
        .expand((d) => d['evolutions'] as List)
        .toList();
    expect(evolutions, hasLength(1));
    expect((evolutions.single as Map)['conditionText'], {'en': 'Happiness()'});
    expect(p.hasBlockingDiagnostics, false);
  });
  test('invalid compiled species shape stays unqualified without text coercion',
      () async {
    final broken = [
      4,
      8,
      ..._value({
        _Symbol('RATTATA'): _Object('GameData::Species',
            {'@id': _Symbol('RATTATA'), '@species': 0, '@form': 0})
      })
    ];
    final p = await _read(await _fixture(extra: {'Data/species.dat': broken}));
    expect((p.evidence['nationalDex'] as Map)['qualified'], false);
    expect(_docs(p, SourceCatalogDocumentKind.species), isEmpty);
  });
  test('empty trainer whole unit reports source scoped diagnostic', () async {
    final f =
        await _fixture(trainers: '[CAMPER,Incomplete]\nLoseText = Oops\n');
    final key = SourcePbsIdentity(
        namespace: f.pbs.logicalProjectNamespace,
        family: SourcePbsFamily.trainers,
        trainerType: 'CAMPER',
        trainerName: 'Incomplete');
    final p = await _read(f, trainers: [key]);
    expect(preservedCatalogTrainers(p), isEmpty);
    expect(
        p.diagnostics.any((d) =>
            d.code == 'source.catalog.trainer_incomplete' &&
            d.locator != null &&
            d.identityKey == key.key),
        true);
  });
}
