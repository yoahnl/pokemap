import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const validator = PokemonCatalogCoherenceValidator();

  test('accepts a complete beta catalog without network access', () {
    final report = validator.validate(_validSnapshot());

    expect(report.canExport, isTrue);
    expect(report.canPlaytest, isTrue);
    expect(report.diagnostics, isEmpty);
  });

  test('reports invalid ids, stats, capture rate, growth and references', () {
    final invalid = _species(
      id: '',
      nationalDex: 0,
      types: const ['missing-type'],
      primaryAbility: 'missing-ability',
      growthRateId: 'missing-growth',
      catchRate: 0,
      stats: const PokemonSpeciesBaseStats(
        hp: 0,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 999,
      ),
      learnsetRef: 'missing-learnset',
      evolutionRef: 'missing-evolution',
      mediaRef: 'missing-media',
    );

    final report = validator.validate(
      _validSnapshot(species: [_document('species/invalid.json', invalid)]),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'species.id_empty',
        'species.national_dex_invalid',
        'species.stat_invalid',
        'species.stat_total_mismatch',
        'species.catch_rate_invalid',
        'species.growth_rate_missing_in_catalog',
        'species.type_missing_in_catalog',
        'species.ability_missing_in_catalog',
        'species.learnset_ref_missing',
        'species.evolution_ref_missing',
        'species.media_ref_missing',
      }),
    );
  });

  test(
    'reports duplicate ids and unknown learnset moves deterministically',
    () {
      final duplicateSpecies = _species();
      final unknownMove = _learnset(
        startingMoves: const ['missing-move'],
        levelUp: const [
          PokemonLearnsetLevelUpEntry(
            moveId: 'tackle',
            level: 0,
            source: 'level_up',
            versionGroup: 'beta',
          ),
        ],
      );
      final forward = _validSnapshot(
        species: [
          _document('species/b.json', duplicateSpecies),
          _document('species/a.json', duplicateSpecies),
        ],
        learnsets: [_document('learnsets/bulbasaur.json', unknownMove)],
      );
      final reverse = PokemonCatalogCoherenceSnapshot(
        ruleset: forward.ruleset,
        catalogs: forward.catalogs.reversed,
        species: forward.species.reversed,
        learnsets: forward.learnsets.reversed,
        evolutions: forward.evolutions.reversed,
        media: forward.media.reversed,
        availableAssetPaths: forward.availableAssetPaths.toList().reversed,
      );

      final first = validator.validate(forward);
      final second = validator.validate(reverse);

      expect(
        first.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>{
          'species.duplicate_id',
          'learnset.move_missing_in_catalog',
          'learnset.level_up_level_invalid',
        }),
      );
      expect(second.toJson(), first.toJson());
    },
  );

  test('reports unsupported evolutions, unknown targets and cycles', () {
    final bulbasaurEvolution = _evolution(
      speciesId: 'bulbasaur',
      entries: const [
        PokemonEvolutionEntry(targetSpeciesId: 'ivysaur', method: 'moon_phase'),
      ],
    );
    final ivysaurEvolution = _evolution(
      speciesId: 'ivysaur',
      entries: const [
        PokemonEvolutionEntry(
          targetSpeciesId: 'bulbasaur',
          method: 'level_up',
          minLevel: 101,
        ),
        PokemonEvolutionEntry(
          targetSpeciesId: 'missing',
          method: 'level_up',
          minLevel: 16,
        ),
      ],
    );

    final report = validator.validate(
      _validSnapshot(
        species: [
          _document('species/bulbasaur.json', _species()),
          _document(
            'species/ivysaur.json',
            _species(
              id: 'ivysaur',
              nationalDex: 2,
              learnsetRef: 'ivysaur',
              evolutionRef: 'ivysaur',
              mediaRef: 'ivysaur',
            ),
          ),
        ],
        learnsets: [
          _document('learnsets/bulbasaur.json', _learnset()),
          _document('learnsets/ivysaur.json', _learnset(speciesId: 'ivysaur')),
        ],
        evolutions: [
          _document('evolutions/bulbasaur.json', bulbasaurEvolution),
          _document('evolutions/ivysaur.json', ivysaurEvolution),
        ],
        media: [
          _document('media/bulbasaur.json', _media()),
          _document('media/ivysaur.json', _media(speciesId: 'ivysaur')),
        ],
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'evolution.method_unsupported',
        'evolution.target_species_missing',
        'evolution.level_above_ruleset_max',
        'evolution.cycle_detected',
      }),
    );
  });

  test('reports a form without a base species and required media gaps', () {
    final form = _species(
      id: 'bulbasaur-mega',
      forms: const PokemonSpeciesForms(
        isBaseForm: false,
        baseFormId: 'missing-base',
        formId: 'mega',
      ),
    );
    final media = _media(
      variant: const PokemonMediaVariant(
        frontStatic: 'assets/pokemon/missing-front.png',
      ),
    );

    final report = validator.validate(
      _validSnapshot(
        species: [_document('species/bulbasaur-mega.json', form)],
        media: [_document('media/bulbasaur.json', media)],
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'species.form_base_missing',
        'media.back_static_missing',
        'media.asset_missing',
      }),
    );
  });

  test('reports unsupported schema versions with actionable diagnostics', () {
    final catalog = PokemonCatalogFile(
      schemaVersion: currentPokemonDataSchemaVersion + 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(description: 'Moves'),
      entries: const [
        {'id': 'tackle'},
      ],
    );

    final report = validator.validate(
      _validSnapshot(catalogs: [_document('catalogs/moves.json', catalog)]),
    );
    final diagnostic = report.diagnostics.singleWhere(
      (candidate) => candidate.code == 'catalog.schema_version_unsupported',
    );

    expect(diagnostic.severity, PokemonCatalogDiagnosticSeverity.error);
    expect(diagnostic.path, 'catalogs/moves.json.schemaVersion');
    expect(diagnostic.recommendedAction, isNotEmpty);
    expect(report.canExport, isFalse);
    expect(report.canPlaytest, isFalse);
  });

  test('warnings remain non-blocking and the full report JSON is stable', () {
    final snapshot = _validSnapshot(
      catalogs: _validCatalogs()
          .where((document) => document.value.catalog != 'abilities')
          .toList(growable: false),
    );

    final report = validator.validate(snapshot);

    expect(report.canExport, isTrue);
    expect(report.canPlaytest, isTrue);
    expect(report.toJson(), <String, Object?>{
      'canExport': true,
      'canPlaytest': true,
      'errorCount': 0,
      'warningCount': 1,
      'diagnostics': <Object?>[
        <String, Object?>{
          'code': 'catalog.abilities_missing',
          'severity': 'warning',
          'path': 'catalogs/abilities',
          'message':
              'The abilities catalog is unavailable; ability references were not checked.',
          'recommendedAction':
              'Add the abilities catalog before enabling authored abilities.',
        },
      ],
    });
  });
}

PokemonCatalogCoherenceSnapshot _validSnapshot({
  Iterable<PokemonCatalogDocument<PokemonCatalogFile>>? catalogs,
  Iterable<PokemonCatalogDocument<PokemonSpeciesFile>>? species,
  Iterable<PokemonCatalogDocument<PokemonLearnsetFile>>? learnsets,
  Iterable<PokemonCatalogDocument<PokemonEvolutionFile>>? evolutions,
  Iterable<PokemonCatalogDocument<PokemonMediaFile>>? media,
}) => PokemonCatalogCoherenceSnapshot(
  catalogs: catalogs ?? _validCatalogs(),
  species: species ?? [_document('species/bulbasaur.json', _species())],
  learnsets: learnsets ?? [_document('learnsets/bulbasaur.json', _learnset())],
  evolutions:
      evolutions ?? [_document('evolutions/bulbasaur.json', _evolution())],
  media: media ?? [_document('media/bulbasaur.json', _media())],
  availableAssetPaths: const <String>{
    'assets/pokemon/bulbasaur-front.png',
    'assets/pokemon/bulbasaur-back.png',
  },
  assetInventoryComplete: true,
  ruleset: PokemonRulesetProfile.pokeMapBetaV1,
);

List<PokemonCatalogDocument<PokemonCatalogFile>> _validCatalogs() => [
  _catalog('types', const ['grass']),
  _catalog('abilities', const ['overgrow']),
  _catalog('moves', const ['tackle']),
  _catalog('growth_rates', const ['medium_slow']),
  _catalog('items', const ['moon-stone']),
];

PokemonCatalogDocument<PokemonCatalogFile> _catalog(
  String catalog,
  List<String> ids,
) => _document(
  'catalogs/$catalog.json',
  PokemonCatalogFile(
    schemaVersion: currentPokemonDataSchemaVersion,
    kind: 'pokemon_catalog',
    catalog: catalog,
    meta: PokemonDataMeta(description: catalog),
    entries: [
      for (final id in ids) <String, dynamic>{'id': id},
    ],
  ),
);

PokemonSpeciesFile _species({
  String id = 'bulbasaur',
  int nationalDex = 1,
  List<String> types = const ['grass'],
  String primaryAbility = 'overgrow',
  String growthRateId = 'medium_slow',
  int catchRate = 45,
  PokemonSpeciesBaseStats stats = const PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  String learnsetRef = 'bulbasaur',
  String evolutionRef = 'bulbasaur',
  String mediaRef = 'bulbasaur',
  PokemonSpeciesForms forms = const PokemonSpeciesForms(),
}) => PokemonSpeciesFile(
  id: id,
  slug: id,
  nationalDex: nationalDex,
  names: <String, String>{'en': id},
  speciesName: const <String, String>{'en': 'Seed Pokemon'},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: types),
  baseStats: stats,
  abilities: PokemonSpeciesAbilities(primary: primaryAbility),
  breeding: const PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: growthRateId,
    baseExp: 64,
    catchRate: catchRate,
    baseFriendship: 50,
  ),
  forms: forms,
  refs: PokemonSpeciesRefs(
    learnset: learnsetRef,
    evolution: evolutionRef,
    media: mediaRef,
  ),
);

PokemonLearnsetFile _learnset({
  String speciesId = 'bulbasaur',
  List<String> startingMoves = const ['tackle'],
  List<PokemonLearnsetLevelUpEntry> levelUp = const [],
}) => PokemonLearnsetFile(
  speciesId: speciesId,
  startingMoves: startingMoves,
  levelUp: levelUp,
);

PokemonEvolutionFile _evolution({
  String speciesId = 'bulbasaur',
  List<PokemonEvolutionEntry> entries = const [],
}) => PokemonEvolutionFile(speciesId: speciesId, evolutions: entries);

PokemonMediaFile _media({
  String speciesId = 'bulbasaur',
  PokemonMediaVariant variant = const PokemonMediaVariant(
    frontStatic: 'assets/pokemon/bulbasaur-front.png',
    backStatic: 'assets/pokemon/bulbasaur-back.png',
  ),
}) => PokemonMediaFile(
  speciesId: speciesId,
  defaultFormId: 'base',
  variants: <String, PokemonMediaVariant>{'base': variant},
);

PokemonCatalogDocument<T> _document<T>(String path, T value) =>
    PokemonCatalogDocument<T>(path: path, value: value);
