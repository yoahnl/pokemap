import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_api.dart' show AuthoringPayload;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';

    test('$transport calculates effective Standard and custom trainer stats',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before =
          await File('${fixture.root.path}/project.json').readAsBytes();
      final page = await fixture.query(_request(), jsonl);
      expect(page.items, hasLength(3));
      final standard = page.items[1];
      expect(standard, {
        'id': 'alpha:1',
        'trainerId': 'alpha',
        'pokemonIndex': 1,
        'speciesId': 'test_species',
        'level': 50,
        'natureId': 'hardy',
        'ivs': _spread(15),
        'evs': _spread(0),
        'stats': _stats([167, 112, 112, 112, 112, 112]),
      });
      expect(page.items[2]['stats'], standard['stats']);
      expect(page.items[0]['natureId'], 'adamant');
      expect(page.items[0]['ivs'], _spread(31));
      expect(page.items[0]['evs'],
          {..._spread(0), 'hp': 252, 'attack': 252, 'speed': 6});
      expect(page.items[0]['stats'], _stats([207, 167, 120, 108, 120, 121]));
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          before);
    });

    test('$transport preserves generic queries, masks, filters and cursors',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final first = await fixture.query(
          _request(
            filters: const {'trainerId': 'alpha'},
            sort: const [
              AuthoringQuerySort(field: 'pokemonIndex', descending: true)
            ],
            fieldMask: const ['stats.hp'],
            pageSize: 1,
          ),
          jsonl);
      expect(first.totalAvailable, 2);
      expect(first.items.single, {
        'id': 'alpha:1',
        'stats': {'hp': 167}
      });
      final second = await fixture.query(
          _request(
            filters: const {'trainerId': 'alpha'},
            sort: const [
              AuthoringQuerySort(field: 'pokemonIndex', descending: true)
            ],
            fieldMask: const ['stats.hp'],
            pageSize: 1,
            cursor: first.nextCursor,
          ),
          jsonl);
      expect(second.items.single, {
        'id': 'alpha:0',
        'stats': {'hp': 207}
      });
      expect(second.nextCursor, isNull);
      final selected = await fixture.query(
          _request(
            filters: const {'trainerId': 'alpha', 'pokemonIndex': 1},
            fieldMask: const ['id', 'natureId', 'ivs', 'evs', 'stats'],
          ),
          jsonl);
      expect(selected.items.single['id'], 'alpha:1');
      for (final operation in [
        AuthoringQueryOperation.get,
        AuthoringQueryOperation.batchGet
      ]) {
        final result = await fixture.query(
            _request(operation: operation, ids: const ['alpha:1']), jsonl);
        expect(result.items.single['id'], 'alpha:1');
      }
      final search = await fixture.query(
          _request(
              operation: AuthoringQueryOperation.search, searchTerm: 'beta'),
          jsonl);
      expect(search.items.single['trainerId'], 'beta');
      final summary = await fixture.query(
          _request(operation: AuthoringQueryOperation.summary), jsonl);
      expect(summary.totalAvailable, 3);
      expect(summary.items[1]['stats'], _stats([167, 112, 112, 112, 112, 112]));
      await expectLater(
          fixture.query(
              _request(
                filters: const {'trainerId': 'beta'},
                pageSize: 1,
                cursor: first.nextCursor,
              ),
              jsonl),
          throwsA(anything));
      await expectLater(
          fixture.query(
              _request(
                operation: AuthoringQueryOperation.get,
                ids: const ['alpha:99'],
              ),
              jsonl),
          throwsA(anything));
    });

    for (final invalid in [
      'missing',
      'malformed',
      'identity',
      'fractional',
      'zero',
      'incomplete'
    ]) {
      test('$transport refuses $invalid species without leaking source data',
          () async {
        final fixture = await _Fixture.create(invalidSpecies: invalid);
        addTearDown(fixture.dispose);
        await expectLater(fixture.query(_request(), jsonl),
            throwsA(predicate((error) {
          final value = error is AuthoringError
              ? jsonEncode(error.toJson())
              : error.toString();
          return value.contains('query.trainer_pokemon_species_unavailable') &&
              !value.contains(fixture.root.path) &&
              !value.contains('private-invalid-source');
        })));
      });
    }
  }

  for (final storage in ['inline', 'stored', 'payload']) {
    test('canonical async query reads $storage species bytes', () async {
      final bytes = utf8.encode(jsonEncode(_species));
      final payload = AuthoringPayload.inline(bytes, storageKey: _speciesPath);
      final identity = pokemonSpeciesResourceIdentity('test_species');
      var captures = 0;
      final snapshot = ProjectSnapshot(
        projectHandle: ProjectHandle('prj_trainer_stats'),
        revision: 'sha256:${'a' * 64}',
        manifest: _manifest,
        maps: const [],
        resourceFingerprints: {identity: payload.resourceRevision},
        resourceStorageKeys: {identity: _speciesPath},
        resourceBytes: storage == 'inline' ? {identity: bytes} : const {},
        storedResources: storage == 'stored'
            ? {
                identity: ProjectStoredResource(
                  byteLength: payload.byteLength,
                  rawSha256: payload.rawSha256,
                  resourceRevision: payload.resourceRevision,
                ),
              }
            : const {},
        payloadResources: storage == 'payload' ? {identity: payload} : const {},
        resourcePayloadReader: (handle, key, descriptor, source) async {
          captures++;
          expect(key, _speciesPath);
          expect(source == null, storage != 'payload');
          return AuthoringPayload.inline(bytes, storageKey: key);
        },
      );
      final page =
          await const ProjectQueryService().queryAsync(snapshot, _request());
      expect(page.items[0]['stats'], _stats([207, 167, 120, 108, 120, 121]));
      expect(captures, storage == 'inline' ? 0 : 1);
      expect(snapshot.inlineResourceBytes.containsKey(identity),
          storage == 'inline');
      expect(
          () => const ProjectQueryService().query(snapshot, _request()),
          throwsA(isA<AuthoringQueryException>()
              .having((error) => error.code, 'code', 'query.async_required')));
    });
  }

  test('snapshot fallback loads a species referenced only by trainer teams',
      () async {
    final fixture = await _Fixture.create(inventory: false);
    addTearDown(fixture.dispose);
    final page = await fixture.query(_request(), false);
    expect(page.items[1]['stats'], _stats([167, 112, 112, 112, 112, 112]));
  });

  test('publishes derived read-only discovery and explicit parity facets', () {
    final resource = AuthoringResourceKindRegistry.canonical()
        .require('trainerPokemonStats');
    expect(resource.version, 1);
    expect(resource.extensions,
        containsPair('queryIdFormat', '<trainerId>:<pokemonIndex>'));
    expect(resource.extensions, containsPair('readOnly', true));
    expect(resource.extensions, containsPair('derived', true));
    expect(resource.extensions['statKeys'], _keys);
    expect(canonicalQueryableResourceKindIds, contains('trainerPokemonStats'));
    final action = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((value) => value.id == 'campaign.trainer.upsert');
    expect(action.extensions['trainerPokemonStats'], {
      'fields': [
        'value.team[].natureId',
        'value.team[].ivs',
        'value.team[].evs'
      ],
      'standard': {'natureId': 'hardy', 'ivs': _spread(15), 'evs': _spread(0)},
      'iv': {'min': 0, 'max': 31, 'integer': true},
      'ev': {'min': 0, 'max': 252, 'integer': true, 'totalMax': 510},
      'aiIndependent': true,
      'previewResourceKind': 'trainerPokemonStats',
    });
    final parity = AuthoringFullParityCatalog.canonical()
        .resources
        .singleWhere((value) => value.resourceKind == 'trainerPokemonStats');
    for (final capability in [
      AuthoringParityCapability.mutation,
      AuthoringParityCapability.durability,
      AuthoringParityCapability.replay,
      AuthoringParityCapability.history,
    ]) {
      expect(parity.cells[capability]!.status,
          AuthoringParityStatus.notApplicable);
      expect(parity.cells[capability]!.justification, contains('read-only'));
    }
    final missing = AuthoringFullParityCatalog.canonical(
      queryableResourceKinds: canonicalQueryableResourceKindIds.toSet()
        ..remove('trainerPokemonStats'),
    )
        .resources
        .singleWhere((value) => value.resourceKind == 'trainerPokemonStats');
    expect(missing.cells[AuthoringParityCapability.read]!.status,
        AuthoringParityStatus.missing);
  });
}

const _keys = [
  'hp',
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed'
];
Map<String, int> _spread(int value) => {for (final key in _keys) key: value};
Map<String, int> _stats(List<int> values) => {
      for (var index = 0; index < _keys.length; index++)
        _keys[index]: values[index]
    };
const _speciesPath = 'data/pokemon/species/test_species.json';
const _species = {
  'schemaVersion': 1,
  'id': 'test_species',
  'slug': 'test-species',
  'nationalDex': 1,
  'names': {'en': 'Test Species'},
  'speciesName': {'en': 'Test'},
  'genIntroduced': 1,
  'typing': {
    'types': ['normal']
  },
  'baseStats': {
    'hp': 100,
    'atk': 100,
    'def': 100,
    'spa': 100,
    'spd': 100,
    'spe': 100,
    'bst': 600
  },
  'abilities': {'primary': 'test_ability'},
  'breeding': {},
  'progression': {},
  'refs': {
    'learnset': 'test_species',
    'evolution': 'test_species',
    'media': 'test_species'
  },
};
const _manifest = ProjectManifest(
  name: 'Trainer stat previews',
  maps: [],
  tilesets: [],
  pokemon: ProjectPokemonConfig(
      enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
  trainers: [
    ProjectTrainerEntry(
      id: 'alpha',
      name: 'Alpha',
      trainerClass: 'Trainer',
      battleDifficulty: 10,
      team: [
        ProjectTrainerPokemonEntry(
          speciesId: 'test_species',
          level: 50,
          natureId: 'adamant',
          ivs: PokemonStatSpread(
              hp: 31,
              attack: 31,
              defense: 31,
              specialAttack: 31,
              specialDefense: 31,
              speed: 31),
          evs: PokemonStatSpread(hp: 252, attack: 252, speed: 6),
        ),
        ProjectTrainerPokemonEntry(speciesId: 'test_species', level: 50),
      ],
    ),
    ProjectTrainerEntry(
      id: 'beta',
      name: 'Beta',
      trainerClass: 'Trainer',
      battleDifficulty: 1,
      team: [ProjectTrainerPokemonEntry(speciesId: 'test_species', level: 50)],
    ),
  ],
);

AuthoringQueryRequest _request({
  AuthoringQueryOperation operation = AuthoringQueryOperation.list,
  List<String> ids = const [],
  String? searchTerm,
  Map<String, Object?> filters = const {},
  List<AuthoringQuerySort> sort = const [],
  List<String> fieldMask = const [],
  int pageSize = 50,
  String? cursor,
}) =>
    AuthoringQueryRequest(
      resourceKind: 'trainerPokemonStats',
      operation: operation,
      view: AuthoringQueryView.detail,
      ids: ids,
      searchTerm: searchTerm,
      filters: filters,
      sort: sort,
      fieldMask: fieldMask,
      pageSize: pageSize,
      cursor: cursor,
    );

class _Fixture {
  _Fixture(this.root, this.api, this.opened, this.worker);
  final Directory root;
  final AuthoringReadApi api;
  final OpenedProject opened;
  final JsonlWorker worker;

  static Future<_Fixture> create(
      {String? invalidSpecies, bool inventory = true}) async {
    final root =
        await Directory.systemTemp.createTemp('trainer-stats-preview-');
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(_manifest.toJson()));
    final species = File('${root.path}/$_speciesPath');
    await species.parent.create(recursive: true);
    if (invalidSpecies != 'missing') {
      final document = Map<String, Object?>.from(_species);
      if (invalidSpecies == 'identity') document['id'] = 'other';
      if (invalidSpecies == 'fractional') {
        document['baseStats'] = {..._species['baseStats']! as Map, 'hp': 1.5};
      }
      if (invalidSpecies == 'zero') {
        document['baseStats'] = {..._species['baseStats']! as Map, 'hp': 0};
      }
      if (invalidSpecies == 'incomplete') document['baseStats'] = {'hp': 100};
      await species.writeAsString(invalidSpecies == 'malformed'
          ? 'private-invalid-source'
          : jsonEncode(document));
    }
    final ProjectFileReader reader =
        inventory ? const LocalProjectFileReader() : _NoInventoryReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final opened = await api.openProject(root.path);
    return _Fixture(root, api, opened, JsonlWorker(api: api));
  }

  Future<AuthoringQueryPage> query(
      AuthoringQueryRequest request, bool jsonl) async {
    if (!jsonl) return api.queryProject(opened.projectHandle, request);
    final result = AuthoringResult.fromJson(
        jsonDecode(await worker.processLine(jsonEncode({
      'id': 'preview',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson()
      },
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) throw result.error!;
    return AuthoringQueryPage.fromJson(Map<String, dynamic>.from(result.data));
  }

  Future<void> dispose() async {
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

class _NoInventoryReader implements ProjectFileReader {
  final _delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      _delegate.readBytes(projectRoot: projectRoot, relativePath: relativePath);
}
