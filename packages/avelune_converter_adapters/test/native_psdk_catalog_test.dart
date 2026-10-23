import 'support/native_encounter_qualification_fixture.dart';
import 'dart:convert';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_media_source_fixture.dart';
import 'package:avelune_converter_adapters/src/native_catalog_publication_selection.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';

void main() {
  test('catalog projection isolates its qualified catalog between runs',
      () async {
    final catalog = _namedCatalog(['species_a']);
    final fixture = await LiteralTileFixture.create(
        extraFiles: nativeMediaSourceFiles(catalog));
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    final qualification = await NativeEncounterCatalogQualification.prepare(
        snapshot: fixture.snapshot,
        source: pbs,
        files: fixture.files,
        nativeCatalog: catalog,
        selectedSourceMapIds: [1]);
    Future<SourceCatalogProjection> project() =>
        const SourceCatalogProjector().read(
            source: fixture.source,
            pbs: pbs,
            files: fixture.files,
            nativeMapIds: {1: 'map-1'},
            nativeTrainerBundle: catalog,
            nativeEncounterQualification: qualification,
            nativeEncounterRatePolicy: NativeEncounterRatePolicy
                .adaptSourceBasePercentToNativeConstantChance);
    final first = await project();
    final escaped = qualification.bundle;
    escaped.speciesById['species_a']!.names['en'] = 'Changed outside run';
    final second = await project();
    expect(second.canonicalHash, first.canonicalHash);
    expect(
        second.documents
            .singleWhere((document) =>
                document.kind == SourceCatalogDocumentKind.species)
            .document['names'],
        {'en': 'Native species_a'});
    expect(qualification.bundle.speciesById['species_a']!.names['en'],
        'Native species_a');
    catalog.speciesById['species_a']!.names['en'] = 'Changed explicit catalog';
    await expectLater(project(), _code('integrity_mutation'));
  });

  for (final (speciesId, sourceSymbol) in [
    ('species_a', 'RENAMED_WILDLIFE'),
    ('species_b', 'OTHER_WILDLIFE'),
  ]) {
    test('publication requires only its source native family $speciesId',
        () async {
      final catalog = _namedCatalog(['species_a', 'species_b']);
      final sourceCatalog = _namedCatalog([speciesId]);
      final fixture = await LiteralTileFixture.create(
          namespace: 'independent-project',
          extraFiles: nativeMediaSourceFiles(sourceCatalog,
              sourceSymbols: {speciesId: sourceSymbol}));
      final pbs = await const SourcePbsParser()
          .read(snapshot: fixture.snapshot, files: fixture.files);
      final projection = await const SourceCatalogProjector().read(
          source: fixture.source,
          pbs: pbs,
          files: fixture.files,
          nativeMapIds: {1: 'map-1'},
          nativeTrainerBundle: catalog);
      expect(
          projection.documents
              .where((document) =>
                  document.kind == SourceCatalogDocumentKind.species)
              .map((document) => document.document['id']),
          [speciesId]);
      expect(
          projection.evidence['nativeCatalogIdentity'],
          containsPair(
              'canonicalHash', canonicalHashOf(catalog.toJson()).value));
    });
  }

  test('publication includes evolutions without unrelated families', () async {
    final catalog = _namedCatalog(['species_a', 'species_b', 'species_c'],
        evolution: ('species_a', 'species_b'));
    final fixture = await LiteralTileFixture.create(
        extraFiles:
            nativeMediaSourceFiles(_namedCatalog(['species_a', 'species_b'])));
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    final projection = await const SourceCatalogProjector().read(
        source: fixture.source,
        pbs: pbs,
        files: fixture.files,
        nativeMapIds: {1: 'map-1'},
        nativeTrainerBundle: catalog,
        requestedNativeSpeciesIds: ['species_a']);
    expect(
        projection.documents
            .where((document) =>
                document.kind == SourceCatalogDocumentKind.species)
            .map((document) => document.document['id']),
        ['species_a', 'species_b']);
    final moves = (projection.documents
            .singleWhere((document) =>
                document.relativePath == 'data/pokemon/catalogs/moves.json')
            .document['entries'] as List)
        .cast<Map>()
        .map((row) => row['id'])
        .toSet();
    for (final id in ['species_a', 'species_b']) {
      expect(
          moves,
          containsAll(catalog.learnsetsBySpeciesId[id]!.levelUp
              .map((entry) => entry.moveId)
              .toSet()));
    }
  });

  test('publication includes pre-evolution ancestors of intermediate roots',
      () {
    final raw = _json(_namedCatalog(['species_a', 'species_b', 'species_c'],
        evolution: ('species_b', 'species_c')).shards.values.single.toJson());
    final evolutions = (raw['evolutions'] as List).cast<Map>();
    evolutions.singleWhere(
        (row) => row['speciesId'] == 'species_b')['preEvolution'] = 'species_a';
    final catalog = NativePsdkCatalogManifest.compose(
        [NativePsdkTrainerBundle.fromJson(raw)]);
    final selected =
        NativeCatalogPublicationSelection.select(catalog, ['species_b']);
    expect(selected.speciesIds, {'species_a', 'species_b', 'species_c'});
  });

  test('publication refuses a required evolution missing from the source',
      () async {
    final catalog = _namedCatalog(['species_a', 'species_b'],
        evolution: ('species_a', 'species_b'));
    final fixture = await LiteralTileFixture.create(
        extraFiles: nativeMediaSourceFiles(_namedCatalog(['species_a'])));
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    await expectLater(
        const SourceCatalogProjector().read(
            source: fixture.source,
            pbs: pbs,
            files: fixture.files,
            nativeMapIds: {1: 'map-1'},
            nativeTrainerBundle: catalog,
            requestedNativeSpeciesIds: ['species_a']),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_species.native_base_source_identity')));
  });

  test(
      'publication refuses requested identities absent from the native catalog',
      () {
    expect(
        () => NativeCatalogPublicationSelection.select(
            _namedCatalog(['species_a']), ['missing_native_species']),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_catalog.publication_species_missing')));
  });

  test('native references include all branches and ignore display names', () {
    expect(
        nativeSpeciesReferences([
          {
            'name': 'not_a_reference',
            'branches': [
              {'speciesId': 'species_b'},
              {
                'reward': {'speciesId': 'species_a'}
              },
              {
                'evolution': {'targetSpeciesId': 'species_c'}
              },
              {
                'trade': {'requiredPartnerSpeciesId': 'species_d'}
              },
              {'speciesId': 'species_b'},
            ]
          }
        ]),
        ['species_a', 'species_b', 'species_c', 'species_d']);
    Object? deep = {'speciesId': 'species_a'};
    for (var i = 0; i < 65; i++) {
      deep = [deep];
    }
    expect(
        () => nativeSpeciesReferences([deep]),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_catalog.publication_quota')));
  });

  for (final (action, builtin) in [
    ('scene.upsert', false),
    ('campaign.new_game.update', false),
    ('campaign.new_game.update', true)
  ]) {
    test(
        'composer publishes native references without trainers for $action builtin=$builtin',
        () async {
      final speciesId = builtin ? 'rattata' : 'species_a';
      final catalog = builtin
          ? NativePsdkCatalogManifest.builtin()
          : _namedCatalog(['species_a', 'species_b']);
      final fixture = await LiteralTileFixture.create(
        interpretationProfile: fixtureSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          ...nativeMediaSourceFiles(builtin
              ? NativePsdkTrainerBundle.builtin()
              : _namedCatalog(['species_a'])),
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = NativePlayer\n'),
          'Graphics/Characters/NativePlayer.png': image
              .encodePng(image.Image(width: 128, height: 128, numChannels: 4)),
        },
      );
      const limits = NativeWriteLimits(maxArtifacts: 128);
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [1],
          projectName: 'Independent native references',
          parentPath: '/private/tmp',
          folderName: 'unused-native-references',
          limits: limits);
      final semantic = (await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: literal,
          files: fixture.files,
          limits: limits))!;
      final gift = SceneInteractiveCommand.receivePokemonFromCatalog(
          speciesId: speciesId,
          formId: '0',
          level: 1,
          nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
          nicknameMaxGraphemes: 10,
          pokedexPresentationPolicy: ScenePokemonGiftPokedexPresentationPolicy
              .whenNewAndPokedexVisible);
      final scene = SceneAsset(
          id: 'native-gift',
          name: 'Native gift',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'gift',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(gift)),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: [
            SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'gift',
                kind: SceneEdgeKind.defaultFlow),
            for (final port in gift.outputPortIds)
              SceneEdge(
                  id: 'gift-$port',
                  fromNodeId: 'gift',
                  fromPortId: port,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted),
          ]));
      final pokemon = PlayerPokemon(
          speciesId: speciesId,
          natureId: 'hardy',
          abilityId: catalog.speciesById[speciesId]!.abilities.primary,
          level: 1,
          currentHp: 10);
      final value = action == 'scene.upsert'
          ? scene.toJson()
          : ProjectNewGameConfig(
              enabled: true,
              startMapId: semantic.mapIds[1]!,
              starterOptions: [
                  ProjectStarterOption(
                      id: 'starter', label: 'Starter', pokemon: pokemon)
                ]).toJson();
      final base = NativeProjectDraft(
          source: semantic.source,
          projectName: semantic.projectName,
          parentPath: semantic.parentPath,
          folderName: semantic.folderName,
          mapIds: semantic.mapIds,
          artifacts: semantic.artifacts,
          sourceArtifacts: semantic.sourceArtifacts,
          compositionEvidence: semantic.compositionEvidence,
          limits: limits,
          mutations: [
            ...semantic.mutations,
            NativeMutation(
                operationId: ConverterId('native-reference-consumer'),
                actionId: action,
                sourceEntityIds: [fixture.source.maps.single.map.sourceFileId],
                targetEntityIds: [ConverterId('native-reference')],
                parameters: {
                  action == 'scene.upsert' ? 'scene' : 'newGame': value
                },
                limits: limits)
          ]);
      final result = (await SourceCatalogStudyComposer(
              automaticNativeEncounters: false,
              nativeTrainerCatalog: builtin ? null : catalog)
          .compose(
              source: fixture.source,
              base: base,
              files: fixture.files,
              limits: limits))!;
      expect(result.projection.trainers, isEmpty);
      expect(result.projection.encounterTables, isEmpty);
      final writes = expandNativeMutationBatches(result.draft, limits);
      expect(
          [
            for (final batch in writes
                .where((entry) => entry.actionId == 'pokemon.documents.write'))
              for (final document in batch.parameters['documents'] as List)
                if ((document as Map)['actionId'] == 'pokemon.species.write')
                  (document['parameters'] as Map)['document']['id'],
          ],
          unorderedEquals(
              NativeCatalogPublicationSelection.select(catalog, [speciesId])
                  .speciesIds));
      expect(
          writes
              .where((entry) =>
                  entry.actionId == 'pokemon.configuration.set_enabled')
              .any((entry) => entry.parameters['enabled'] == true),
          isTrue);
    });
  }

  test('automatic catalogue covers the complete canonical Kanto dex', () {
    final catalog = NativePsdkCatalogManifest.builtin();
    final kanto = catalog.speciesById.values
        .where((species) =>
            species.forms.formId == '0' &&
            species.nationalDex >= 1 &&
            species.nationalDex <= 151)
        .toList();
    expect(kanto, hasLength(151));
    expect(kanto.map((species) => species.nationalDex).toSet(), hasLength(151));
  });

  for (final domain in [
    'species',
    'learnsets',
    'evolutions',
    'media',
    'catalogs',
    'shardAlias'
  ]) {
    test('rejects $domain nested mutation before returning manifest identity',
        () {
      final shards = [
        _shard(
            [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)]),
        _shard(
            [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 2)]),
      ];
      if (domain == 'evolutions') {
        for (var index = 0; index < shards.length; index++) {
          final raw = _json(shards[index].toJson());
          ((raw['evolutions'] as List).first as Map)['evolutions'] = [
            {
              'targetSpeciesId': 'species_a',
              'method': 'level_up',
              'minLevel': 1
            }
          ];
          shards[index] = NativePsdkTrainerBundle.fromJson(raw);
        }
      }
      final catalog = NativePsdkCatalogManifest.compose(shards);
      final before = canonicalJsonOf(catalog.toJson());
      expect(before, isNotEmpty);
      switch (domain) {
        case 'species':
          catalog.speciesById['species_a']!.names['en'] = 'Changed';
        case 'learnsets':
          catalog.learnsetsBySpeciesId['species_a']!.startingMoves[0] =
              'changed';
        case 'evolutions':
          catalog.evolutionsBySpeciesId['species_a']!.evolutions[0] =
              const PokemonEvolutionEntry(
                  targetSpeciesId: 'species_a',
                  method: 'level_up',
                  minLevel: 2);
        case 'media':
          catalog.mediaBySpeciesId['species_a']!.variants.remove('0');
        case 'catalogs':
          catalog.catalogs['types']!.entries[0] = {
            ...catalog.catalogs['types']!.entries.first,
            'id': 'changed',
          };
          for (final entry in catalog.shards.entries) {
            expect(
                canonicalHashOf(entry.value.toJson(),
                        limits: nativePsdkCatalogShardJsonLimits)
                    .value,
                entry.key);
          }
        case 'shardAlias':
          final alias = catalog.shards.values.firstWhere((shard) => !identical(
              shard.speciesById['species_a'],
              catalog.speciesById['species_a']));
          alias.speciesById['species_a']!.names['en'] =
              'Changed outside published species';
      }
      expect(catalog.toJson, _code('integrity_mutation'));
    });
  }

  test('rejects mutation during asynchronous catalog publication', () async {
    final raw = _json(_shard(
            [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)])
        .toJson());
    for (final key in [
      'sourceRosterFile',
      'sourceTrainerRosters',
      'sourceTrainerKeys',
      'sourceRosterLocators'
    ]) {
      (raw['evidence'] as Map).remove(key);
    }
    final catalog = NativePsdkCatalogManifest.compose(
        [NativePsdkTrainerBundle.fromJson(raw)]);
    final fixture = await LiteralTileFixture.create(extraFiles: {
      ...nativeMediaSourceFiles(catalog),
      'PBS/trainers.txt':
          utf8.encode('[TEST,Unqualified]\nPokemon = SPECIES_A,1\n'),
    });
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    final mediaId = fixture.snapshot.entries
        .firstWhere((file) =>
            file.relativePath == 'Graphics/Pokemon/Back/SPECIES_A.png')
        .fileId;
    final files = _MutatingFiles(
        fixture.files,
        mediaId,
        () => catalog.catalogs['types']!.entries.first['id'] =
            'Changed during publication');
    await expectLater(
        const SourceCatalogProjector().read(
            source: fixture.source,
            pbs: pbs,
            files: files,
            nativeMapIds: {1: 'map-1'},
            nativeTrainerBundle: catalog),
        _code('integrity_mutation'));
  });

  test(
      'composer omits unused native species and automatic encounters for an injected catalog',
      () async {
    final raw = _json(_shard(
            [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)])
        .toJson());
    for (final key in [
      'sourceRosterFile',
      'sourceTrainerRosters',
      'sourceTrainerKeys',
      'sourceRosterLocators'
    ]) {
      (raw['evidence'] as Map).remove(key);
    }
    final catalog = NativePsdkCatalogManifest.compose(
        [NativePsdkTrainerBundle.fromJson(raw)]);
    final fixture = await LiteralTileFixture.create(
      interpretationProfile: fixtureSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        ...nativeMediaSourceFiles(catalog),
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = NativePlayer\n'),
        'Graphics/Characters/NativePlayer.png': image
            .encodePng(image.Image(width: 128, height: 128, numChannels: 4)),
        'PBS/encounters.txt':
            utf8.encode('[1]\nLand,11\n100,UNSUPPORTED_NATIVE,14\n'),
      },
    );
    expect(
        SourceEventProfile.forProject(
          fixture.source,
          interpretationProfile: fixtureSourceInterpretationProfile,
        ).isQualified,
        isTrue);
    const limits = NativeWriteLimits(maxArtifacts: 128);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Injected native catalog',
        parentPath: '/private/tmp',
        folderName: 'unused-injected-native-catalog',
        limits: limits);
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: literal,
        files: fixture.files,
        limits: limits);
    expect(semantic, isNotNull);
    final composition =
        await SourceCatalogStudyComposer(nativeTrainerCatalog: catalog).compose(
            source: fixture.source,
            base: semantic!,
            files: fixture.files,
            limits: limits);
    expect(composition, isNotNull);
    expect(composition!.projection.trainers, isEmpty);
    expect(composition.projection.encounterTables, isEmpty);
    expect(
        composition.projection.evidence.containsKey('nativeEncounterBindings'),
        isFalse);
    expect(
        composition.projection.documents
            .where(
                (doc) => doc.relativePath.startsWith('data/pokemon/species/'))
            .map((doc) => doc.document['id']),
        isEmpty);
    expect(
        composition.draft.compositionEvidence['sourceCatalogs'],
        containsPair(
            'automaticEncounterReleaseSuppressedForExplicitCatalog', true));
    await expectLater(
        SourceCatalogStudyComposer(
                nativeTrainerCatalog: catalog,
                nativeEncounterQualification:
                    await syntheticNativeEncounterQualification())
            .compose(
                source: fixture.source,
                base: semantic,
                files: fixture.files,
                limits: limits),
        throwsA(isA<ContractError>().having((e) => e.code, 'code',
            'native_catalog.encounter_qualification_identity')));
  });

  test('publishes a composite without admitting unqualified trainers',
      () async {
    final requests = [
      NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)
    ];
    final raw = _json(_shard(requests).toJson());
    for (final key in [
      'sourceRosterFile',
      'sourceTrainerRosters',
      'sourceTrainerKeys',
      'sourceRosterLocators'
    ]) {
      (raw['evidence'] as Map).remove(key);
    }
    final catalog = NativePsdkCatalogManifest.compose(
        [NativePsdkTrainerBundle.fromJson(raw)]);
    final fixture = await LiteralTileFixture.create(extraFiles: {
      ...nativeMediaSourceFiles(catalog),
      'PBS/trainers.txt':
          utf8.encode('[TEST,Unqualified]\nPokemon = SPECIES_A,1\n'),
    });
    final pbs = await const SourcePbsParser()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    final projection = await const SourceCatalogProjector().read(
        source: fixture.source,
        pbs: pbs,
        files: fixture.files,
        nativeMapIds: {1: 'map-1'},
        nativeTrainerBundle: catalog);
    expect(projection.trainers, isEmpty);
    expect(projection.evidence.containsKey('nativeTrainerBindings'), isFalse);
    expect(
        projection.documents.where(
            (doc) => doc.relativePath == 'data/pokemon/species/species_a.json'),
        hasLength(1));
    expect(projection.evidence['runtimeReady'], isFalse);
    expect(projection.evidence['nativeCatalogIdentity'],
        containsPair('canonicalHash', canonicalHashOf(catalog.toJson()).value));
    await expectLater(
        const SourceCatalogProjector().read(
            source: fixture.source,
            pbs: pbs,
            files: fixture.files,
            nativeMapIds: {1: 'map-1'},
            nativeTrainerBundle: catalog,
            nativeEncounterQualification:
                await syntheticNativeEncounterQualification()),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_catalog.encounter_qualification_identity')));
  });

  test('rejects incomplete dependency closure and dishonest request moves', () {
    final shard = _shard(
        [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)]);
    for (final kind in ['learnset', 'evolution', 'binding']) {
      final raw = _json(shard.toJson());
      if (kind == 'learnset') {
        ((raw['sourceLearnsets'] as List).first as Map)['startingMoves'] = [
          'missing_move'
        ];
      } else if (kind == 'evolution') {
        ((raw['evolutions'] as List).first as Map)['evolutions'] = [
          {
            'targetSpeciesId': 'missing_species',
            'method': 'level_up',
            'minLevel': 2
          }
        ];
      } else {
        (((raw['evidence'] as Map)['nativeRequestMoveBindings'] as List).first
            as Map)['moveIds'] = ['missing_move'];
      }
      expect(
          () => NativePsdkCatalogManifest.compose(
              [NativePsdkTrainerBundle.fromJson(raw)]),
          _code('dependency_closure'));
    }
  });

  test('builds bounded shards for more than 256 requests and 128 species',
      () async {
    final requests = [
      for (var i = 0; i < 130; i++)
        for (var level = 1; level <= 3; level++)
          NativePsdkCatalogRequest(baseId: 'species_$i', form: 0, level: level),
    ];
    final admitted = <int>[];
    Future<NativePsdkTrainerBundle> load(
        List<NativePsdkCatalogRequest> batch) async {
      if (batch.map((r) => r.baseId).toSet().length > 64) {
        throw ContractError(
            'native_trainer.requested_base_quota', r'$', 'bounded');
      }
      admitted.add(batch.length);
      return _shard(batch);
    }

    final catalog = await const NativePsdkCatalogBuilder()
        .build(requests: requests, buildShard: load);
    expect(catalog.speciesById.length, 130);
    expect(catalog.evidence['catalogRequests'], hasLength(390));
    expect(admitted.every((count) => count <= 256), isTrue);
    expect(catalog.shards.length, greaterThan(1));
    expect(catalog.movesById.length,
        NativePsdkTrainerBundle.builtin().movesById.length);
    expect(catalog.evidence['runtimeBattleBuilderQualified'], isFalse);
    expect(catalog.evidence['sourceScriptsExecuted'], 0);
    expect(catalog.evidence['sources'],
        NativePsdkTrainerBundle.builtin().evidence['sources']);
    final reversed = await const NativePsdkCatalogBuilder()
        .build(requests: requests.reversed.toList(), buildShard: load);
    expect(
        canonicalJsonOf(catalog.toJson()), canonicalJsonOf(reversed.toJson()));
    expect(
        canonicalJsonOf(catalog.toJson()),
        canonicalJsonOf(NativePsdkCatalogManifest.fromJson(catalog.toJson(),
            shards: {
              for (final shard in catalog.shards.entries)
                shard.key: shard.value.toJson()
            }).toJson()));
  });

  test('preserves native forms and explicit move ordering', () {
    final original = NativePsdkTrainerBundle.builtin();
    final a = _json(original.toJson());
    final b = _json(original.toJson());
    for (final json in [a, b]) {
      (json['evidence'] as Map)['nativeFormNamesBySpeciesId'] =
          <String, Object>{};
    }
    (b['evidence'] as Map)['catalogRequests'] = [
      NativePsdkCatalogRequest(baseId: 'beedrill', form: 0, level: 1).toJson()
    ];
    (b['evidence'] as Map)['nativeRequestMoveBindings'] = [
      {
        'baseId': 'beedrill',
        'form': 0,
        'level': 1,
        'movePolicy': 'nativeDefaults',
        'moveIds': nativeTrainerDefaultMoveIds(
            original.learnsetsBySpeciesId['beedrill']!, 1)
      }
    ];
    (a['evidence'] as Map)['catalogRequests'] = [
      NativePsdkCatalogRequest(
          baseId: 'beedrill',
          form: 30,
          level: 20,
          explicitMoveIds: ['cut', 'tackle']).toJson()
    ];
    (a['evidence'] as Map)['nativeRequestMoveBindings'] = [
      {
        'baseId': 'beedrill',
        'form': 30,
        'level': 20,
        'movePolicy': 'explicit',
        'moveIds': ['cut', 'tackle']
      }
    ];
    final catalog = NativePsdkCatalogManifest.compose([
      NativePsdkTrainerBundle.fromJson(a),
      NativePsdkTrainerBundle.fromJson(b)
    ]);
    expect(
        catalog.speciesById.keys, original.speciesById.keys.toList()..sort());
    expect(catalog.speciesById, contains('beedrill_form30'));
    expect(catalog.learnsetsBySpeciesId['beedrill_form30']!.toJson(),
        original.learnsetsBySpeciesId['beedrill_form30']!.toJson());
    final bindings =
        (catalog.evidence['nativeRequestMoveBindings'] as List).cast<Map>();
    expect(
        bindings
            .singleWhere((row) => row['movePolicy'] == 'explicit')['moveIds'],
        ['cut', 'tackle']);
    expect(
        canonicalJsonOf(catalog.toJson()),
        canonicalJsonOf(NativePsdkCatalogManifest.compose(
                catalog.shards.values.toList().reversed.toList())
            .toJson()));
  });

  test('rejects missing, changed, duplicate and extra shards', () {
    final shard = _shard(
        [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)]);
    final catalog = NativePsdkCatalogManifest.compose([shard]);
    final hash = catalog.shards.keys.single;
    expect(
        () => NativePsdkCatalogManifest.fromJson(catalog.toJson(), shards: {}),
        _code('missing_shard'));
    final changed = _json(shard.toJson());
    ((changed['species'] as List).first as Map)['names'] = {'en': 'Tampered'};
    expect(
        () => NativePsdkCatalogManifest.fromJson(catalog.toJson(),
            shards: {hash: changed}),
        _code('shard_hash'));
    final duplicate = _json(catalog.toJson());
    (duplicate['shards'] as List).add((duplicate['shards'] as List).first);
    expect(
        () => NativePsdkCatalogManifest.fromJson(duplicate,
            shards: {hash: shard.toJson()}),
        _code('duplicate_shard'));
    expect(
        () => NativePsdkCatalogManifest.fromJson(catalog.toJson(),
            shards: {hash: shard.toJson(), '0' * 64: shard.toJson()}),
        _code('unexpected_shard'));
    expect(() => NativePsdkCatalogManifest.compose([shard, shard]),
        _code('duplicate_shard'));
  });

  for (final table in [
    'species',
    'sourceLearnsets',
    'evolutions',
    'media',
    'catalogs',
    'sources'
  ]) {
    test('rejects conflicting $table identities across shards', () {
      final first = _shard(
          [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)]);
      final second = _json(_shard([
        NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 2)
      ]).toJson());
      if (table == 'sources') {
        (((second['evidence'] as Map)['sources'] as List).first
            as Map)['sha256'] = '0' * 64;
      } else if (table == 'catalogs') {
        final moves = (second['catalogs'] as List)
            .cast<Map>()
            .singleWhere((row) => row['catalog'] == 'moves');
        ((moves['entries'] as List).first as Map)['pp'] = 999;
      } else {
        final row = (second[table] as List).first as Map;
        switch (table) {
          case 'species':
            row['names'] = {'en': 'Different'};
          case 'sourceLearnsets':
            row['tm'] = [
              {'moveId': 'cut'}
            ];
          case 'evolutions':
            row['evolutions'] = [
              {
                'targetSpeciesId': 'species_a',
                'method': 'level_up',
                'minLevel': 2
              }
            ];
          case 'media':
            row['variants'] = {
              '0': {
                'frontStatic': 'different.png',
                'backStatic': 'different.png'
              }
            };
        }
      }
      expect(
          () => NativePsdkCatalogManifest.compose(
              [first, NativePsdkTrainerBundle.fromJson(second)]),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              startsWith('native_catalog.conflict'))));
    });
  }

  test('enforces aggregate quotas and does not split semantic failures',
      () async {
    final first = _shard(
        [NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)]);
    final second = _shard(
        [NativePsdkCatalogRequest(baseId: 'species_b', form: 0, level: 1)]);
    expect(
        () => NativePsdkCatalogManifest.compose([first, second],
            limits: const NativePsdkCatalogLimits(maxSpecies: 1)),
        _code('quota'));
    for (final limit in [
      const NativePsdkCatalogLimits(maxShards: 1),
      const NativePsdkCatalogLimits(maxRequests: 1),
      const NativePsdkCatalogLimits(maxMoves: 1),
      const NativePsdkCatalogLimits(maxSourceFiles: 1),
      const NativePsdkCatalogLimits(maxSourceBytes: 1),
      const NativePsdkCatalogLimits(maxEncodedBytes: 1),
    ]) {
      expect(
          () =>
              NativePsdkCatalogManifest.compose([first, second], limits: limit),
          _code('quota'));
    }
    var calls = 0;
    await expectLater(
        const NativePsdkCatalogBuilder().build(
            requests: [
              NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)
            ],
            buildShard: (_) async {
              calls++;
              throw ContractError(
                  'native_trainer.source_missing', r'$', 'missing');
            }),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'native_trainer.source_missing')));
    expect(calls, 1);
    await expectLater(
        const NativePsdkCatalogBuilder().build(requests: [
          NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1),
          NativePsdkCatalogRequest(baseId: 'species_a', form: 0, level: 1)
        ], buildShard: (_) async => first),
        _code('duplicate_request'));
  });
}

Matcher _code(String suffix) => throwsA(isA<ContractError>()
    .having((e) => e.code, 'code', 'native_catalog.$suffix'));
Map<String, dynamic> _json(Object value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

NativePsdkCatalogManifest _namedCatalog(List<String> ids,
    {(String, String)? evolution}) {
  final raw = _json(_shard([
    for (final id in ids)
      NativePsdkCatalogRequest(baseId: id, form: 0, level: 1),
  ]).toJson());
  for (final row in (raw['species'] as List).cast<Map>()) {
    (row['names'] as Map)['en'] = 'Native ${row['id']}';
  }
  if (evolution != null) {
    final row = (raw['evolutions'] as List)
        .cast<Map>()
        .singleWhere((row) => row['speciesId'] == evolution.$1);
    row['evolutions'] = [
      {'targetSpeciesId': evolution.$2, 'method': 'level_up', 'minLevel': 20}
    ];
  }
  return NativePsdkCatalogManifest.compose(
      [NativePsdkTrainerBundle.fromJson(raw)]);
}

NativePsdkTrainerBundle _shard(List<NativePsdkCatalogRequest> requests) {
  final builtin = NativePsdkTrainerBundle.builtin();
  final json = _json(builtin.toJson());
  final original = (json['species'] as List).first as Map;
  final originalId = original['id'];
  final learnset = (json['sourceLearnsets'] as List)
      .cast<Map>()
      .singleWhere((row) => row['speciesId'] == originalId);
  final ids = requests.map((r) => r.baseId).toSet().toList()..sort();
  json['species'] = [
    for (final id in ids)
      {
        ...original,
        'id': id,
        'forms': {
          'baseFormId': id,
          'isBaseForm': true,
          'formId': '0',
          'otherForms': <String>[]
        }
      }
  ];
  json['sourceLearnsets'] = [
    for (final id in ids) {...learnset, 'speciesId': id}
  ];
  json['evolutions'] = [
    for (final id in ids)
      {'schemaVersion': 1, 'speciesId': id, 'evolutions': <Object>[]}
  ];
  json['media'] = [
    for (final id in ids)
      {
        'schemaVersion': 1,
        'speciesId': id,
        'defaultFormId': '0',
        'variants': {
          '0': {
            'frontStatic': nativePsdkMediaTarget(id, 'front'),
            'backStatic': nativePsdkMediaTarget(id, 'back')
          }
        }
      }
  ];
  json['fallbackMedia'] = <Object>[];
  (json['evidence'] as Map)['catalogRequests'] =
      requests.map((r) => r.toJson()).toList();
  (json['evidence'] as Map)['nativeRequestMoveBindings'] = [
    for (final r in requests)
      {
        ...r.toJson(),
        'movePolicy': 'nativeDefaults',
        'moveIds': nativeTrainerDefaultMoveIds(
            builtin.learnsetsBySpeciesId[originalId]!, r.level)
      }
  ];
  (json['evidence'] as Map)['nativeFormNamesBySpeciesId'] = <String, Object>{};
  return NativePsdkTrainerBundle.fromJson(json);
}

final class _MutatingFiles implements SourceFilePort {
  const _MutatingFiles(this.delegate, this.fileId, this.mutate);
  final SourceFilePort delegate;
  final ConverterId fileId;
  final void Function() mutate;

  @override
  Future<List<int>> read(ConverterId id) async {
    if (id == fileId) mutate();
    return delegate.read(id);
  }
}
