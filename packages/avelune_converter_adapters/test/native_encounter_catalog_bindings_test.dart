import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_encounter_catalog_bindings.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/native_trainer_catalog_bindings.dart';
import 'package:avelune_converter_adapters/src/source_catalog_projection.dart';
import 'package:avelune_converter_adapters/src/source_catalog_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

List<int> _symbol(String text) => [58, text.length + 5, ...utf8.encode(text)];
List<int> _compiled(String symbol) => [
      4,
      8,
      123,
      6,
      ..._symbol(symbol),
      111,
      ..._symbol('GameData::Species'),
      8,
      ..._symbol('@id'),
      ..._symbol(symbol),
      ..._symbol('@species'),
      ..._symbol(symbol),
      ..._symbol('@form'),
      105,
      0,
    ];

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _source({
  String symbol = 'RATTATA',
  String methods = 'Land,11\n100,RATTATA,14,17\n100,RATTATA,14,17\n',
  Map<String, List<int>> extraFiles = const {},
  List<int>? scriptsBytes,
}) async {
  final fixture = await LiteralTileFixture.create(
      maps: [LiteralFixtureMap(id: 98)],
      scriptsBytes: scriptsBytes,
      includeEventSystem: scriptsBytes != null,
      extraFiles: {
        'PBS/pokemon.txt': utf8.encode('[$symbol]\nName = Source species\n'),
        'PBS/encounters.txt': utf8.encode('[098]\n$methods'),
        'Data/species.dat': _compiled(symbol),
        ...extraFiles,
      });
  final pbs = await const SourcePbsParser()
      .read(snapshot: fixture.snapshot, files: fixture.files);
  return (fixture: fixture, pbs: pbs);
}

Matcher _code(String code) =>
    throwsA(isA<ContractError>().having((error) => error.code, 'code', code));

void main() {
  late NativeEncounterCatalogQualification qualification;
  setUpAll(() async {
    qualification = NativeEncounterCatalogQualification.kantoV1(
      bundleBytes:
          await File('assets/native_kanto_encounter_bundle.json').readAsBytes(),
      attestationBytes:
          await File('assets/native_kanto_encounter_qualification.json')
              .readAsBytes(),
    );
  });

  Future<NativeEncounterCatalogBindingResult> bind(
          ({LiteralTileFixture fixture, SourcePbsProject pbs}) source,
          {NativeEncounterRatePolicy ratePolicy = NativeEncounterRatePolicy
              .adaptSourceBasePercentToNativeConstantChance,
          NativeEncounterFishingRatePolicy fishingRatePolicy =
              NativeEncounterFishingRatePolicy.unresolved}) =>
      const NativeEncounterCatalogBindings().bind(
        snapshot: source.fixture.snapshot,
        source: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {98: 'native-route9'},
        qualification: qualification,
        ratePolicy: ratePolicy,
        fishingRatePolicy: fishingRatePolicy,
      );

  test('binds native defaults at every inclusive level without any trainer',
      () async {
    final result = await bind(await _source());
    expect(result.tables, hasLength(1));
    final table = result.tables.single;
    expect(table.encounterKind, EncounterKind.walk);
    expect(table.chancePerStep, .11);
    expect(
        table.entries.map((entry) => entry.speciesId), ['rattata', 'rattata']);
    expect(table.entries.map((entry) => entry.weight), [100, 100]);
    expect(table.entries.first.minLevel, 14);
    expect(table.entries.first.maxLevel, 17);
    expect(result.evidence['qualifiedSpeciesLevelKeys'],
        ['rattata|0|14', 'rattata|0|15', 'rattata|0|16', 'rattata|0|17']);
    expect(result.evidence['terrainConsumersQualified'], isFalse);
    expect(result.evidence['runtimeBattleBuilderQualified'], isFalse);
    expect(result.evidence['sourceCadenceParityQualified'], isFalse);
  });

  test('preserves Cave Water and RockSmash rates and typed method mappings',
      () async {
    final result = await bind(await _source(
        methods:
            'Cave,5\n100,RATTATA,14\nWater,2\n100,RATTATA,14\nRockSmash,11\n100,RATTATA,14\n'));
    expect(result.tables.map((table) => table.encounterKind),
        [EncounterKind.walk, EncounterKind.surf, EncounterKind.special]);
    expect(result.tables.map((table) => table.chancePerStep), [.05, .02, .11]);
    expect(result.evidence['fieldConsumersQualified'], isFalse);
  });

  test('keeps fishing and absent rates unqualified without zero or certainty',
      () async {
    final result = await bind(await _source(
        methods: 'OldRod\n100,RATTATA,14\nLand\n100,RATTATA,14\n'));
    expect(result.tables, isEmpty);
    expect(result.unqualifiedMethods.map((entry) => entry['reason']),
        ['fishingRateUnqualified', 'sourceBaseRateMissing']);
  });

  test('refuses every level outside exact qualified default tuples', () async {
    await expectLater(
        bind(await _source(methods: 'Land,11\n100,RATTATA,13,14\n')),
        _code('native_encounter.tuple_unqualified'));
  });

  test('refuses unknown identities instead of fuzzy underscore matching',
      () async {
    await expectLater(
        bind(await _source(
            symbol: 'RAT_TATA', methods: 'Land,11\n100,RAT_TATA,14\n')),
        _code('native_encounter.species_identity'));
  });

  test('requires an explicit source base percent adaptation policy', () async {
    await expectLater(
        bind(await _source(), ratePolicy: NativeEncounterRatePolicy.unresolved),
        _code('native_encounter.rate_policy_required'));
  });

  test('rejects changed release bytes before their JSON can qualify itself',
      () async {
    final bundle =
        await File('assets/native_kanto_encounter_bundle.json').readAsBytes();
    final attestation =
        await File('assets/native_kanto_encounter_qualification.json')
            .readAsBytes();
    expect(
        () => NativeEncounterCatalogQualification.kantoV1(
            bundleBytes: [...bundle, 32], attestationBytes: attestation),
        _code('native_encounter.release_witness'));
    expect(
        () => NativeEncounterCatalogQualification.kantoV1(
            bundleBytes: bundle, attestationBytes: [...attestation, 32]),
        _code('native_encounter.release_witness'));
  });

  test('reconstructs only the exact release from ordered admitted artifacts',
      () {
    final release = qualification.artifacts();
    final restored = NativeEncounterCatalogQualification.fromArtifacts(
        evidence: release.evidence, artifacts: release.artifacts);
    expect(restored.evidence, qualification.evidence);
    expect(restored.wildCases, qualification.wildCases);
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: release.evidence, artifacts: release.artifacts.skip(1)),
        _code('native_encounter.release_artifacts'));
    final changed = Map<String, Object?>.from(release.evidence);
    changed['bundleChunks'] =
        (release.evidence['bundleChunks'] as List).reversed.toList();
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: changed, artifacts: release.artifacts),
        _code('native_encounter.release_artifacts'));
  });

  test('rejects a source species absent from the compiled form zero SET',
      () async {
    await expectLater(
        bind(await _source(extraFiles: {
          'Data/species.dat': _compiled('SPEAROW'),
        })),
        _code('native_encounter.species_identity'));
  });

  test(
      'uses the unique source header identity without importing blocked source learnsets',
      () async {
    final source = await _source(
        symbol: 'SLOWBRO',
        methods: 'Water,2\n100,SLOWBRO,40\n',
        extraFiles: {
          'PBS/pokemon.txt': utf8
              .encode('[SLOWBRO]\nName = Slowbro\nMoves = -1,FUTURESIGHT\n'),
        });
    expect(
        source.pbs.entries
            .singleWhere((entry) => entry.family == SourcePbsFamily.species)
            .isBlocked,
        isTrue);
    final result = await bind(source);
    expect(result.tables.single.entries.single.speciesId, 'slowbro');
    expect(result.evidence['sourceSpeciesFieldDataUsed'], isFalse);
  });

  Map<String, List<int>> nativeMedia() {
    final png =
        image.encodePng(image.Image(width: 1, height: 1, numChannels: 4));
    return {
      for (final species in qualification.bundle.speciesById.values)
        if (species.forms.formId == '0')
          for (final direction in ['Front', 'Back'])
            'Graphics/Pokemon/$direction/${species.id.toUpperCase()}.png': png,
    };
  }

  test('keeps pinned qualification intact after mutable bundle models escape',
      () async {
    final original = qualification.bundle;
    final originalHash = canonicalHashOf(original.toJson(),
        limits: const ContractLimits(
            maxNodes: 2000000,
            maxStringCodeUnits: 1048576,
            maxTextCodeUnits: 33554432));
    final escaped = qualification.bundle;
    escaped.speciesById['rattata']!.names['en'] = 'Forged native name';
    escaped.learnsetsBySpeciesId['rattata']!.levelUp[0] =
        const PokemonLearnsetLevelUpEntry(
            level: 1,
            moveId: 'splash',
            source: 'forged',
            versionGroup: 'forged');
    escaped.catalogs['moves']!.entries.first['name'] = 'Forged move name';
    final restored = qualification.bundle;
    expect(
        canonicalHashOf(restored.toJson(),
            limits: const ContractLimits(
                maxNodes: 2000000,
                maxStringCodeUnits: 1048576,
                maxTextCodeUnits: 33554432)),
        originalHash);
    expect(restored.speciesById['rattata']!.names['en'], 'Rattata');
    final source = await _source(extraFiles: nativeMedia());
    final projected = await const SourceCatalogProjector().read(
        source: source.fixture.source,
        pbs: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {98: 'native-route9'},
        nativeEncounterQualification: qualification,
        nativeEncounterRatePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);
    final rattata = projected.documents.singleWhere((document) =>
        document.kind == SourceCatalogDocumentKind.species &&
        document.document['id'] == 'rattata');
    expect((rattata.document['names'] as Map)['en'], 'Rattata');
    final result = await bind(source);
    expect(result.evidence['qualifiedSpeciesLevelKeys'],
        ['rattata|0|14', 'rattata|0|15', 'rattata|0|16', 'rattata|0|17']);
    expect(
        qualification.wildCases['rattata|0|14']!['requestedMoveIds'],
        nativeTrainerDefaultMoveIds(
            restored.learnsetsBySpeciesId['rattata']!, 14));
  });

  test('publishes the complete native catalogue and media without trainers',
      () async {
    final source = await _source(extraFiles: nativeMedia());
    final result = await const SourceCatalogProjector().read(
        source: source.fixture.source,
        pbs: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {98: 'native-route9'},
        nativeEncounterQualification: qualification,
        nativeEncounterRatePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);
    expect(result.trainers, isEmpty);
    expect(result.evidence.containsKey('nativeTrainerBindings'), isFalse);
    expect(result.evidence['nativeEncounterBindings'], isA<Map>());
    expect(result.encounterTables, hasLength(1));
    expect(
        result.documents.where(
            (document) => document.kind == SourceCatalogDocumentKind.species),
        hasLength(89));
    expect(
        result.documents.where(
            (document) => document.kind == SourceCatalogDocumentKind.learnset),
        hasLength(89));
    expect(result.assetMutations, hasLength(178));
    expect(result.mergedItemCatalog, isNotNull);
  });

  test(
      'keeps exact existing trainer roster references in the active native pack',
      () async {
    final source = await _source(extraFiles: {
      ...nativeMedia(),
      'PBS/trainers.txt': utf8.encode(
          '[FRLG_BUGCATCHER,Brent]\nPokemon = BEEDRILL,19\nPokemon = BEEDRILL,19\n'),
    });
    final key = source.pbs.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers)
        .identity!;
    final result = await const SourceCatalogProjector().read(
        source: source.fixture.source,
        pbs: source.pbs,
        files: source.fixture.files,
        nativeMapIds: {98: 'native-route9'},
        requestedTrainerKeys: [key],
        nativeTrainerKeys: [key],
        nativeTrainerBundle: NativePsdkTrainerBundle.builtin(),
        nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults,
        nativeEncounterQualification: qualification,
        nativeEncounterRatePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance);
    expect(result.trainers.single.id, key.sourceId.value);
    expect(result.trainers.single.team.map((member) => member.speciesId),
        ['beedrill', 'beedrill']);
    expect(result.trainers.single.team.first.moves,
        ['fury_attack', 'twineedle', 'rage', 'pursuit']);
    expect(result.evidence['nativeTrainerBindings'], isA<Map>());
    expect(result.evidence['nativeEncounterBindings'], isA<Map>());
    expect(result.documents.map((document) => document.relativePath).toSet(),
        hasLength(result.documents.length));
  });

  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  test('refuses fishing adaptation without its exact inert source oracle',
      () async {
    await expectLater(
        bind(await _source(methods: 'OldRod\n100,RATTATA,14\n'),
            fishingRatePolicy: NativeEncounterFishingRatePolicy
                .adaptSourceBaseFishingBiteChanceToNativeTable),
        _code('native_encounter.fishing_oracle'));
  });
  test(
      'keeps time-specific methods unpublished until native time conditions exist',
      () async {
    final result =
        await bind(await _source(methods: 'LandDay,11\n100,RATTATA,14\n'));
    expect(result.tables, isEmpty);
    expect(result.unqualifiedMethods.single['reason'],
        'sourceTimeConditionUnqualified');
  });
  test(
      'refuses ambiguous source headers instead of accepting a blocked duplicate',
      () async {
    await expectLater(
        bind(await _source(extraFiles: {
          'PBS/pokemon.txt': utf8
              .encode('[RATTATA]\nName = First\n[RATTATA]\nName = Second\n'),
        })),
        _code('native_encounter.species_identity'));
  });
  for (final (rod, expected) in [
    ('OldRod', .45),
    ('GoodRod', .70),
    ('SuperRod', .95),
  ]) {
    test(
        'adapts the attested $rod base bite chance instead of the absent or zero PBS step rate',
        () async {
      for (final sourceRate in ['', ',0']) {
        final source = await _source(
            scriptsBytes: await File(scriptsPath!).readAsBytes(),
            methods: '$rod$sourceRate\n100,RATTATA,14\n');
        final result = await bind(source,
            fishingRatePolicy: NativeEncounterFishingRatePolicy
                .adaptSourceBaseFishingBiteChanceToNativeTable);
        expect(result.tables.single.chancePerStep, expected);
        expect(
            result.tables.single.encounterKind,
            switch (rod) {
              'OldRod' => EncounterKind.oldRod,
              'GoodRod' => EncounterKind.goodRod,
              _ => EncounterKind.superRod,
            });
        expect(
            (result.evidence['tables'] as List).single['sourcePbsStepChance'],
            sourceRate.isEmpty ? null : 0);
        expect(result.evidence['sourceFishingTimingAndModifiersQualified'],
            isFalse);
        expect(result.evidence['fishingOracle'], isA<Map>());
      }
    }, skip: scriptsPath == null);
  }
  test(
      'composer and writer regenerate qualified encounters without trainers and refuse forgery before staging',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('native-encounters-');
    addTearDown(() => temporary.delete(recursive: true));
    final source = await _source(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        extraFiles: {
          ...nativeMedia(),
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 128, numChannels: 4)),
        });
    final limits = sourceCatalogStudyWriteLimitsFor(1);
    final literal = await const LiteralTileComposer().compose(
        source: source.fixture.source,
        files: source.fixture.files,
        selectedSourceMapIds: [98],
        projectName: 'Qualified native encounters',
        parentPath: temporary.path,
        folderName: 'native',
        limits: limits);
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: source.fixture.source,
        base: literal,
        files: source.fixture.files,
        limits: limits);
    expect(semantic, isNotNull);
    final composed = await SourceCatalogStudyComposer(
            nativeEncounterQualification: qualification)
        .compose(
            source: source.fixture.source,
            base: semantic!,
            files: source.fixture.files,
            limits: limits);
    expect(composed, isNotNull);
    final draft = composed!.draft;
    expect(
        draft.mutations.where(
            (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
        isEmpty);
    expect(
        draft.mutations.where((mutation) =>
            mutation.actionId == 'campaign.encounter_table.upsert'),
        hasLength(1));
    expect(
        draft.mutations.any((mutation) =>
            mutation.actionId == 'pokemon.configuration.set_enabled' &&
            mutation.parameters['enabled'] == true),
        isTrue);
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, draft, limits: limits);
    expect(receipt.verified, isTrue);
    final manifest = jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map;
    expect(manifest['encounterTables'], hasLength(1));
    expect((manifest['encounterTables'] as List).single['chancePerStep'], .11);

    final changed = jsonDecode(jsonEncode(draft.compositionEvidence))
        as Map<String, dynamic>;
    final release =
        (changed['sourceCatalogs'] as Map)['nativeEncounterRelease'] as Map;
    release['attestationSha256'] = '0' * 64;
    final forged = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: 'forged',
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: draft.mutations,
        compositionEvidence: changed,
        limits: limits);
    final forgedApproval = approveNativeFixtureDraft(forged);
    await expectLater(
        const NativeProjectWriter().write(
            forgedApproval.plan, forgedApproval.context, forged,
            limits: limits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(await Directory('${temporary.path}/forged').exists(), isFalse);
    expect(
        (await temporary.list().toList())
            .where((entry) => entry.path.contains('staging')),
        isEmpty);
  }, skip: scriptsPath == null, timeout: const Timeout(Duration(seconds: 120)));
}
