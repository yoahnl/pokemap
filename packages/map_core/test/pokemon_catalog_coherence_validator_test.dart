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
        assetProbeStatuses: Map<String, PokemonAssetProbeStatus>.fromEntries(
          forward.assetProbeStatuses.entries.toList().reversed,
        ),
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

  test(
    'disabled species can retain incomplete artwork with a visible warning',
    () {
      final disabled = PokemonSpeciesFile.fromJson({
        ..._species().toJson(),
        'classification': {'isEnabledInProject': false},
      });
      final report = const PokemonCatalogCoherenceValidator().validate(
        _validSnapshot(
          species: [_document('species/bulbasaur.json', disabled)],
          media: [
            _document(
              'media/bulbasaur.json',
              _media(variant: const PokemonMediaVariant()),
            ),
          ],
        ),
      );
      expect(report.errorCount, 0);
      expect(
        report.diagnostics.map((entry) => entry.code),
        contains('species.disabled_in_project'),
      );
    },
  );

  test(
    'preserves documented catalog-only evolutions without allowing execution',
    () {
      final report = const PokemonCatalogCoherenceValidator().validate(
        _validSnapshot(
          evolutions: [
            _document(
              'evolutions/bulbasaur.json',
              _evolution(
                entries: const [
                  PokemonEvolutionEntry(
                    targetSpeciesId: 'bulbasaur',
                    method: 'conditional',
                    minLevel: 30,
                    conditionText: {'en': 'Level up while it is raining.'},
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      final codes = report.diagnostics.map((entry) => entry.code);
      expect(codes, contains('evolution.method_catalog_only'));
      expect(codes, contains('evolution.self_target'));
      expect(codes, isNot(contains('evolution.method_unsupported')));
    },
  );

  test('catalog-only rules still reject missing references and conditions', () {
    final report = const PokemonCatalogCoherenceValidator().validate(
      _validSnapshot(
        evolutions: [
          _document(
            'evolutions/bulbasaur.json',
            _evolution(
              entries: const [
                PokemonEvolutionEntry(
                  targetSpeciesId: 'missing',
                  method: 'conditional',
                  itemId: 'missing_item',
                  requiredMoveId: 'missing_move',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    expect(
      report.diagnostics.map((entry) => entry.code),
      containsAll([
        'evolution.target_species_missing',
        'evolution.condition_text_missing',
        'evolution.item_missing',
        'evolution.required_move_missing',
      ]),
    );
  });

  test('reports unsupported evolutions, unknown targets and cycles', () {
    final bulbasaurEvolution = _evolution(
      speciesId: 'bulbasaur',
      entries: const [
        PokemonEvolutionEntry(targetSpeciesId: 'ivysaur', method: 'moon_phase'),
        PokemonEvolutionEntry(
          targetSpeciesId: 'ivysaur',
          method: 'use_item',
          itemId: 'moon-stone',
        ),
        PokemonEvolutionEntry(
          targetSpeciesId: 'ivysaur',
          method: 'use_item',
          itemId: 'missing-stone',
        ),
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
        'evolution.item_missing',
      }),
    );
    expect(
      report.diagnostics
          .where((diagnostic) => diagnostic.code == 'evolution.item_missing')
          .length,
      1,
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
        assetProbeStatuses: const <String, PokemonAssetProbeStatus>{
          'assets/pokemon/missing-front.png': PokemonAssetProbeStatus.missing,
        },
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

  test('accepts one reciprocal form graph with matching media variants', () {
    final report = validator.validate(
      _validSnapshot(
        species: [
          _document(
            'species/bulbasaur.json',
            _species(
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: true,
                formId: 'base',
                otherForms: ['mega'],
              ),
            ),
          ),
          _document(
            'species/bulbasaur-mega.json',
            _species(
              id: 'bulbasaur-mega',
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: false,
                formId: 'mega',
                otherForms: ['base'],
              ),
              learnsetRef: 'bulbasaur-mega',
              evolutionRef: 'bulbasaur-mega',
              mediaRef: 'bulbasaur',
            ),
          ),
        ],
        learnsets: [
          _document('learnsets/bulbasaur.json', _learnset()),
          _document(
            'learnsets/bulbasaur-mega.json',
            _learnset(speciesId: 'bulbasaur-mega'),
          ),
        ],
        evolutions: [
          _document('evolutions/bulbasaur.json', _evolution()),
          _document(
            'evolutions/bulbasaur-mega.json',
            _evolution(speciesId: 'bulbasaur-mega'),
          ),
        ],
        media: [
          _document(
            'media/bulbasaur.json',
            _media(
              variants: const {
                'base': PokemonMediaVariant(
                  frontStatic: 'assets/pokemon/bulbasaur-front.png',
                  backStatic: 'assets/pokemon/bulbasaur-back.png',
                ),
                'mega': PokemonMediaVariant(
                  frontStatic: 'assets/pokemon/bulbasaur-front.png',
                  backStatic: 'assets/pokemon/bulbasaur-back.png',
                ),
              },
            ),
          ),
        ],
      ),
    );

    expect(report.diagnostics, isEmpty);
  });

  test('reports invalid base identities, duplicate forms and broken links', () {
    final report = validator.validate(
      _validSnapshot(
        species: [
          _document(
            'species/base.json',
            _species(
              forms: const PokemonSpeciesForms(
                baseFormId: 'wrong-base',
                isBaseForm: true,
                formId: 'base',
                otherForms: ['mega', 'missing'],
              ),
            ),
          ),
          _document(
            'species/mega-a.json',
            _species(
              id: 'mega-a',
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: false,
                formId: 'mega',
              ),
            ),
          ),
          _document(
            'species/mega-b.json',
            _species(
              id: 'mega-b',
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: false,
                formId: 'mega',
              ),
            ),
          ),
        ],
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'species.form_base_identity_mismatch',
        'species.form_id_duplicate',
        'species.other_form_missing',
        'species.other_form_not_reciprocal',
      }),
    );
  });

  test('reports media variants missing from or unknown to the form graph', () {
    final report = validator.validate(
      _validSnapshot(
        species: [
          _document(
            'species/bulbasaur.json',
            _species(
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: true,
                formId: 'base',
                otherForms: ['mega'],
              ),
            ),
          ),
          _document(
            'species/bulbasaur-mega.json',
            _species(
              id: 'bulbasaur-mega',
              forms: const PokemonSpeciesForms(
                baseFormId: 'bulbasaur',
                isBaseForm: false,
                formId: 'mega',
                otherForms: ['base'],
              ),
              learnsetRef: 'bulbasaur-mega',
              evolutionRef: 'bulbasaur-mega',
              mediaRef: 'bulbasaur',
            ),
          ),
        ],
        media: [
          _document(
            'media/bulbasaur.json',
            _media(
              variants: const {
                'base': PokemonMediaVariant(
                  frontStatic: 'assets/pokemon/bulbasaur-front.png',
                  backStatic: 'assets/pokemon/bulbasaur-back.png',
                ),
                'shadow': PokemonMediaVariant(
                  frontStatic: 'assets/pokemon/bulbasaur-front.png',
                  backStatic: 'assets/pokemon/bulbasaur-back.png',
                ),
              },
            ),
          ),
        ],
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'media.form_variant_missing',
        'media.form_variant_unknown',
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

  test('blocks every typed asset probe failure with a distinct diagnostic', () {
    final media = _media(
      variant: const PokemonMediaVariant(
        frontStatic: 'assets/pokemon/front.png',
        backStatic: 'assets/pokemon/back.png',
        frontShinyStatic: 'assets/pokemon/front-shiny.png',
        icon: '../unsafe-icon.png',
        cry: 'assets/pokemon/cry.ogg',
        animations: <String, PokemonMediaAnimationRef>{
          'idle': PokemonMediaAnimationRef(
            sheet: 'assets/pokemon/idle.png',
            animationId: 'idle',
          ),
        },
      ),
    );

    final report = validator.validate(
      _validSnapshot(
        media: [_document('media/bulbasaur.json', media)],
        assetProbeStatuses: const <String, PokemonAssetProbeStatus>{
          'assets/pokemon/front.png': PokemonAssetProbeStatus.exists,
          'assets/pokemon/back.png': PokemonAssetProbeStatus.missing,
          'assets/pokemon/front-shiny.png':
              PokemonAssetProbeStatus.inventoryUnavailable,
          '../unsafe-icon.png': PokemonAssetProbeStatus.unsafePath,
          'assets/pokemon/cry.ogg': PokemonAssetProbeStatus.accessDenied,
          'assets/pokemon/idle.png': PokemonAssetProbeStatus.missing,
        },
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<String>{
        'media.asset_missing',
        'media.asset_inventory_unavailable',
        'media.asset_path_unsafe',
        'media.asset_access_denied',
      }),
    );
    expect(
      report.diagnostics
          .where((diagnostic) => diagnostic.code == 'media.asset_missing')
          .map((diagnostic) => diagnostic.path),
      containsAll(<String>{
        'media/bulbasaur.json.variants.base.backStatic',
        'media/bulbasaur.json.variants.base.animations.idle.sheet',
      }),
    );
    expect(report.canExport, isFalse);
    expect(report.canPlaytest, isFalse);
  });

  test('rejects an authored animation without a sheet asset path', () {
    final report = validator.validate(
      _validSnapshot(
        media: [
          _document(
            'media/bulbasaur.json',
            _media(
              variant: const PokemonMediaVariant(
                frontStatic: 'assets/pokemon/bulbasaur-front.png',
                backStatic: 'assets/pokemon/bulbasaur-back.png',
                animations: <String, PokemonMediaAnimationRef>{
                  'idle': PokemonMediaAnimationRef(
                    sheet: '',
                    animationId: 'idle',
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );

    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      contains('media.animation_sheet_missing'),
    );
  });

  test('missing required catalogs block export and playtest', () {
    final snapshot = _validSnapshot(
      catalogs: _validCatalogs()
          .where((document) => document.value.catalog != 'abilities')
          .toList(growable: false),
    );

    final report = validator.validate(snapshot);

    expect(report.canExport, isFalse);
    expect(report.canPlaytest, isFalse);
    expect(report.toJson(), <String, Object?>{
      'canExport': false,
      'canPlaytest': false,
      'errorCount': 1,
      'warningCount': 0,
      'diagnostics': <Object?>[
        <String, Object?>{
          'code': 'catalog.abilities_missing',
          'severity': 'error',
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
  Map<String, PokemonAssetProbeStatus>? assetProbeStatuses,
}) => PokemonCatalogCoherenceSnapshot(
  catalogs: catalogs ?? _validCatalogs(),
  species: species ?? [_document('species/bulbasaur.json', _species())],
  learnsets: learnsets ?? [_document('learnsets/bulbasaur.json', _learnset())],
  evolutions:
      evolutions ?? [_document('evolutions/bulbasaur.json', _evolution())],
  media: media ?? [_document('media/bulbasaur.json', _media())],
  assetProbeStatuses:
      assetProbeStatuses ??
      const <String, PokemonAssetProbeStatus>{
        'assets/pokemon/bulbasaur-front.png': PokemonAssetProbeStatus.exists,
        'assets/pokemon/bulbasaur-back.png': PokemonAssetProbeStatus.exists,
      },
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
  PokemonSpeciesForms? forms,
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
  forms:
      forms ??
      PokemonSpeciesForms(baseFormId: id, isBaseForm: true, formId: 'base'),
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
  Map<String, PokemonMediaVariant>? variants,
}) => PokemonMediaFile(
  speciesId: speciesId,
  defaultFormId: 'base',
  variants: variants ?? <String, PokemonMediaVariant>{'base': variant},
);

PokemonCatalogDocument<T> _document<T>(String path, T value) =>
    PokemonCatalogDocument<T>(path: path, value: value);
