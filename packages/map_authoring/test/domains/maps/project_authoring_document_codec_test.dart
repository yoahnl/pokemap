import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'native scoped writer preserves unrelated raw documents and nested fields',
      () {
    const trainer = ProjectTrainerEntry(
        id: 'selected',
        name: 'Before',
        trainerClass: 'Trainer',
        team: [ProjectTrainerPokemonEntry(speciesId: 'first', level: 5)]);
    final before = const ProjectManifest(name: 'Scoped', maps: [], tilesets: [])
        .copyWith(trainers: [trainer]);
    final rawTrainer = trainer.toJson();
    rawTrainer['futureTrainer'] = {'keep': true};
    (rawTrainer['team'] as List).first['futureMember'] = 'keep';
    final unrelated = {
      'id': 'foreign',
      'futureSchema': [
        1,
        {'opaque': true}
      ],
    };
    final raw = {
      ...before.toJson(),
      'trainers': [unrelated, rawTrainer],
      'maps': [
        {'id': 'unknown-map', 'futureLayout': true}
      ],
      'tilesets': [
        {'id': 'foreign-resource', 'futureAsset': true}
      ],
      'futureRoot': {'keep': true},
    };
    final after = before.copyWith(trainers: [
      trainer.copyWith(name: 'After', team: [
        trainer.team.single.copyWith(level: 6),
        const ProjectTrainerPokemonEntry(speciesId: 'second', level: 7),
      ]),
      const ProjectTrainerEntry(
          id: 'new', name: 'New', trainerClass: 'Trainer'),
    ]);
    final decoded = _encodeScoped(raw, before, after, sections: {
      'trainers'
    }, documents: {
      'trainers': {'selected', 'new'}
    });
    expect(decoded['maps'], raw['maps']);
    expect(decoded['tilesets'], raw['tilesets']);
    expect(decoded['futureRoot'], raw['futureRoot']);
    final trainers = decoded['trainers'] as List;
    expect(
        trainers.map((value) => value['id']), ['foreign', 'selected', 'new']);
    expect(trainers.first, unrelated);
    expect(trainers[1]['name'], 'After');
    expect(trainers[1]['futureTrainer'], {'keep': true});
    expect(trainers[1]['team'][0]['futureMember'], 'keep');
    expect(trainers[1]['team'][0]['level'], 6);
    expect(trainers[1]['team'][1]['speciesId'], 'second');
  });

  test(
      'native scoped aggregate edits preserve unknown Pokemon and New Game data',
      () {
    const before = ProjectManifest(
        name: 'Scoped',
        maps: [],
        tilesets: [],
        pokemon:
            ProjectPokemonConfig(ruleset: PokemonRulesetProfile.standardV1));
    final raw = {
      ...before.toJson(),
      'pokemon': {
        ...before.pokemon.toJson(),
        'futureRules': {'untouched': true},
      },
      'newGame': {'futureStartContract': true},
      'settings': {'futureDimension': 'untouched'},
    };
    final after = before.copyWith(
        pokemon: before.pokemon
            .copyWith(ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    final decoded = _encodeScoped(raw, before, after, sections: {'pokemon'});
    expect((decoded['pokemon'] as Map)['futureRules'], {'untouched': true});
    expect((decoded['pokemon'] as Map)['ruleset'],
        after.pokemon.toJson()['ruleset']);
    expect(decoded['newGame'], raw['newGame']);
    expect(decoded['settings'], raw['settings']);
  });

  test('native scoped Event registry merges selected records and appends IDs',
      () {
    const selected = 'evt_00000000-0000-7000-8000-000000000001';
    const added = 'evt_00000000-0000-7000-8000-000000000002';
    final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: [_event(selected, 'Before')],
        legacyClaims: []);
    final before = const ProjectManifest(name: 'Scoped', maps: [], tilesets: [])
        .copyWith(eventRegistry: registry);
    final record = registry.records.single.toJson();
    (record['definition'] as Map)['futureDefinition'] = true;
    final foreign = {
      'state': 'future',
      'futureRecord': [3, 2, 1]
    };
    final raw = {
      ...before.toJson(),
      'eventRegistry': {
        ...registry.toJson(),
        'records': [foreign, record],
        'legacyClaims': [
          {'futureClaim': true}
        ],
        'futureRegistry': true,
      },
    };
    final after = before.copyWith(
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: registry.mode,
            records: [_event(selected, 'After'), _event(added, 'Added')],
            legacyClaims: []));
    final decoded = _encodeScoped(raw, before, after, sections: {
      'eventRegistry'
    }, documents: {
      'eventRegistry': {selected, added}
    });
    final result = decoded['eventRegistry'] as Map;
    expect(result['futureRegistry'], isTrue);
    expect(result['legacyClaims'], [
      {'futureClaim': true}
    ]);
    final records = result['records'] as List;
    expect(records.first, foreign);
    expect(records[1]['definition']['name'], 'After');
    expect(records[1]['definition']['futureDefinition'], isTrue);
    expect(records[2]['definition']['id'], added);
  });

  test('native scoped document removal keeps unrelated raw entries', () {
    const selected = ProjectTrainerEntry(
        id: 'selected', name: 'Selected', trainerClass: 'Trainer');
    final before = const ProjectManifest(name: 'Scoped', maps: [], tilesets: [])
        .copyWith(trainers: [selected]);
    final foreign = {'id': 'foreign', 'future': true};
    final raw = {
      ...before.toJson(),
      'trainers': [selected.toJson(), foreign]
    };
    final decoded =
        _encodeScoped(raw, before, before.copyWith(trainers: []), sections: {
      'trainers'
    }, documents: {
      'trainers': {'selected'}
    });
    expect(decoded['trainers'], [foreign]);
  });

  test('native scoped writer rejects unavailable sections and document IDs',
      () {
    const before = ProjectManifest(name: 'Scoped', maps: [], tilesets: []);
    final raw = before.toJson();
    expect(
        () => _encodeScoped(raw, before, before.copyWith(name: 'Outside'),
            sections: {'trainers'}),
        throwsA(isA<MapAuthoringException>().having((failure) => failure.code,
            'code', 'project.mutation_outside_scope')));
    expect(
        () => _encodeScoped(
            raw,
            before,
            before.copyWith(trainers: [
              const ProjectTrainerEntry(
                  id: 'selected', name: 'Selected', trainerClass: 'Trainer')
            ]),
            sections: {'trainers'}),
        throwsA(isA<MapAuthoringException>().having((failure) => failure.code,
            'code', 'project.manifest_scope_invalid')));
    expect(
        () => _encodeScoped(
                raw,
                before,
                before.copyWith(trainers: [
                  const ProjectTrainerEntry(
                      id: 'unselected',
                      name: 'Outside',
                      trainerClass: 'Trainer')
                ]),
                sections: {
                  'trainers'
                },
                documents: {
                  'trainers': {'selected'}
                }),
        throwsA(isA<MapAuthoringException>().having((failure) => failure.code,
            'code', 'project.manifest_scope_invalid')));
  });

  test('native scoped writer creates an absent Event registry', () {
    const before = ProjectManifest(name: 'Scoped', maps: [], tilesets: []);
    const id = 'evt_00000000-0000-7000-8000-000000000001';
    final after = before.copyWith(
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.legacyOnly,
            records: [_event(id, 'New')],
            legacyClaims: []));
    final decoded = _encodeScoped(before.toJson(), before, after, sections: {
      'eventRegistry'
    }, documents: {
      'eventRegistry': {id}
    });
    expect(NarrativeEventRegistry.fromJson(decoded['eventRegistry']),
        after.eventRegistry);
  });

  test(
      'native scoped writer rejects an existing ID omitted from its projection',
      () {
    const before = ProjectManifest(name: 'Scoped', maps: [], tilesets: []);
    const selected = ProjectTrainerEntry(
        id: 'selected', name: 'Existing', trainerClass: 'Trainer');
    final raw = {
      ...before.toJson(),
      'trainers': [selected.toJson()]
    };
    expect(
        () => _encodeScoped(raw, before, before.copyWith(trainers: [selected]),
                sections: {
                  'trainers'
                },
                documents: {
                  'trainers': {'selected'}
                }),
        throwsA(isA<MapAuthoringException>().having((failure) => failure.code,
            'code', 'project.manifest_scope_invalid')));
  });

  test('compact manifest writer preserves all unrelated root values', () {
    final manifest = ProjectManifest(
      name: 'Évidence',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      newGame:
          const ProjectNewGameConfig(enabled: true, startMapId: 'first-map'),
      globalProperties: const {'campaign': 'original', 'checkpoint': 7},
    );
    final raw = {
      ...manifest.toJson(),
      'unmodeledRoot': {
        'order': [3, 1, 2],
        'text': '  conservé  '
      }
    };
    final before = utf8.encode(const JsonEncoder.withIndent('  ').convert(raw));
    final fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: before),
    ]);
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_codec'),
      revision: fingerprint,
      manifest: manifest,
      maps: const [],
      resourceFingerprints: {'project': fingerprint},
      resourceBytes: {'project': before},
    );
    final after = encodeProjectAuthoringDocument(snapshot, manifest);
    expect(after.length, lessThan(before.length));
    expect(utf8.decode(after), isNot(contains('\n')));
    final decoded = jsonDecode(utf8.decode(after));
    expect(decoded, raw);
    expect(ProjectManifest.fromJson(decoded as Map<String, dynamic>), manifest);
    expect(snapshot.resourceBytes('project'), before);
  });
}

Map<String, dynamic> _encodeScoped(
    Map<String, Object?> raw, ProjectManifest before, ProjectManifest after,
    {required Set<String> sections, Map<String, Set<String>>? documents}) {
  final bytes = utf8.encode(jsonEncode(raw));
  final fingerprint =
      computeAuthoringBytesFingerprint(bytes, logicalName: 'project.json');
  final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('scoped'),
      revision: fingerprint,
      manifest: before,
      availableProjectSections: sections,
      availableProjectDocuments: documents,
      maps: const [],
      resourceFingerprints: {'project': fingerprint},
      resourceBytes: {'project': bytes});
  return jsonDecode(
          utf8.decode(encodeProjectAuthoringDocument(snapshot, after)))
      as Map<String, dynamic>;
}

NarrativeEventRecord _event(String id, String name) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: id,
            name: name,
            source: NarrativeEventSourceRef.mapEnter('room'),
            conditions: [],
            sceneId: 'scene',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0),
        enabled: true);
