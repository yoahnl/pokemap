import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../tool/ac14_catalog_reference_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_catalog_preservation.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test('source-only study refuses an explicit active encounter release',
      () async {
    final fixture = await LiteralTileFixture.create();
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Conflicting study policy',
        parentPath: '/private/tmp',
        folderName: 'unused');
    await expectLater(
        SourceCatalogStudyComposer(
                automaticNativeEncounters: false,
                nativeEncounterQualification:
                    NativeEncounterCatalogQualification.builtinKantoV1())
            .compose(
                source: fixture.source,
                base: literal.draft!,
                files: fixture.files),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'catalogs.encounters.policy')));
  });

  test('PBS alone cannot qualify an unattested literal study', () async {
    final fixture = await LiteralTileFixture.create(extraFiles: {
      'PBS/pokemon.txt': utf8.encode('[ORIGINAL]\nName = Original\n'),
      'PBS/encounters.txt': utf8.encode('[001]\nLand,11\n100,ORIGINAL,2,3\n'),
    });
    final literal = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'Unqualified catalogue',
      parentPath: '/private/tmp',
      folderName: 'unused-ac14',
    );
    expect(
      await const SourceCatalogStudyComposer().compose(
        source: fixture.source,
        base: literal.draft!,
        files: fixture.files,
      ),
      isNull,
    );
  });

  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  group('source-bound catalogue native conversion', () {
    late Directory temporary;
    late Ac14CatalogReferenceComposition composition;
    setUpAll(() async {
      temporary = await Directory.systemTemp.createTemp('ac14-catalog-tests-');
      composition = await composeAc14CatalogReferenceFixture(
        sourceScriptsPath: scriptsPath!,
        outputParentPath: temporary.path,
      );
    });
    tearDownAll(() async {
      await temporary.delete(recursive: true);
    });

    test('explicit source-only study records its encounter preparation policy',
        () {
      final evidence =
          composition.draft.compositionEvidence['sourceCatalogs'] as Map;
      expect(evidence['automaticNativeEncounters'], isFalse);
    });

    test('public default composer diagnoses unsupported source encounters',
        () async {
      final fixture = composition.sourceFixture;
      final literal = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: const [98],
          projectName: 'Unsupported automatic encounters',
          parentPath: temporary.path,
          folderName: 'unsupported-default',
          limits: ac14CatalogReferenceLimits);
      final semantic = await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: literal,
          files: fixture.files,
          limits: ac14CatalogReferenceLimits);
      expect(semantic, isNotNull);
      await expectLater(
          const SourceCatalogStudyComposer().compose(
              source: fixture.source,
              base: semantic!,
              files: fixture.files,
              limits: ac14CatalogReferenceLimits),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
                      'native_species.native_base_identity')));
    });

    for (final value in [true, 'false', null]) {
      test('forged automatic encounter policy $value refuses before staging',
          () async {
        final evidence =
            jsonDecode(jsonEncode(composition.draft.compositionEvidence))
                as Map<String, dynamic>;
        (evidence['sourceCatalogs'] as Map)['automaticNativeEncounters'] =
            value;
        await _refuseBeforeStage(
            _copyDraft(composition.draft, evidence: evidence),
            'native.semantics.regeneration');
      });
    }

    const ignoredTrainerCalls = {
      'double expression interpolation':
          r'TrainerBattle.start(:CAMPER, "Jo#{name}", 2)',
      'double instance interpolation':
          r'TrainerBattle.start(:CAMPER, "Jo#@name", 2)',
      'double global interpolation':
          r'TrainerBattle.start(:CAMPER, "Jo#$name", 2)',
      'escaped double quote': r'''TrainerBattle.start(:CAMPER, "J\"o", 2)''',
      'escaped double backslash': r'TrainerBattle.start(:CAMPER, "J\\o", 2)',
      'escaped single quote': r"TrainerBattle.start(:CAMPER, 'J\'o', 2)",
      'escaped single backslash': r"TrainerBattle.start(:CAMPER, 'J\\o', 2)",
    };
    for (final entry in ignoredTrainerCalls.entries) {
      test('trainer literal selection ignores ${entry.key}', () async {
        final candidate = await composeAc14CatalogReferenceFixture(
          sourceScriptsPath: scriptsPath!,
          outputParentPath: temporary.path,
          includeBrokenReferences: false,
          trainerCall: entry.value,
        );
        final marker =
            candidate.draft.compositionEvidence['sourceCatalogs'] as Map;
        expect(marker['requestedTrainerKeys'], isEmpty);
        expect(
            preservedCatalogTrainers(candidate.catalogs.projection), isEmpty);
        expect(
            candidate.draft.mutations.where(
                (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
            isEmpty);
      });
    }

    const literalTrainerNames = {
      'plain name': 'Jo',
      'single expression interpolation': r'Jo#{name}',
      'single instance interpolation': 'Jo#@name',
      'single global interpolation': r'Jo#$name',
    };
    for (final entry in literalTrainerNames.entries) {
      test('trainer literal selection preserves ${entry.key}', () async {
        final trainerCall = entry.key == 'plain name'
            ? 'TrainerBattle.start(:CAMPER, "Jo", 2)'
            : "TrainerBattle.start(:CAMPER, '${entry.value}', 2)";
        final candidate = await composeAc14CatalogReferenceFixture(
          sourceScriptsPath: scriptsPath!,
          outputParentPath: temporary.path,
          includeBrokenReferences: false,
          trainerCall: trainerCall,
        );
        final marker =
            candidate.draft.compositionEvidence['sourceCatalogs'] as Map;
        final expected = SourcePbsIdentity(
          namespace: candidate.sourceFixture.snapshot.logicalProjectNamespace,
          family: SourcePbsFamily.trainers,
          trainerType: 'CAMPER',
          trainerName: entry.value,
          version: 2,
        );
        expect(marker['requestedTrainerKeys'], [expected.toJson()]);
        expect(preservedCatalogTrainers(candidate.catalogs.projection),
            hasLength(entry.key == 'plain name' ? 1 : 0));
        if (entry.key == 'plain name') {
          expect(
              preservedCatalogTrainers(candidate.catalogs.projection)
                  .single
                  .team
                  .single
                  .level,
              15);
        }
      });
    }

    test('source-only study keeps runtime-unbound data out of active mutations',
        () {
      expect(preservedCatalogItems(composition.catalogs.projection)!.entries,
          isNotEmpty);
      expect(
          composition.draft.mutations.where((mutation) =>
              mutation.actionId == 'pokemon.configuration.set_enabled' &&
              mutation.parameters['enabled'] == true),
          isEmpty);
      expect(composition.catalogs.projection.documents, isEmpty);
      expect(preservedCatalogDocuments(composition.catalogs.projection),
          isNotEmpty);
      expect(composition.catalogs.projection.trainers, isEmpty);
      expect(preservedCatalogTrainers(composition.catalogs.projection),
          isNotEmpty);
      expect(composition.catalogs.projection.encounterTables, isEmpty);
      expect(preservedCatalogEncounters(composition.catalogs.projection),
          isNotEmpty);
      expect(
          composition.draft.mutations.where((mutation) => const {
                'pokemon.documents.write',
                'campaign.trainer.upsert',
                'campaign.encounter_table.upsert',
              }.contains(mutation.actionId)),
          isEmpty);
      expect(
          composition.draft.mutations.where(
              (mutation) => mutation.actionId == 'pokemon.catalog.write'),
          isEmpty);
      expect(composition.catalogs.projection.mergedItemCatalog, isNull);
    });

    test(
        'qualifies only the exact semantic source and preserves data authority',
        () {
      final marker =
          composition.draft.compositionEvidence['sourceCatalogs'] as Map;
      expect(marker['kind'], 'sourceCatalogStudy');
      expect(marker['version'], 1);
      expect(marker['sourceSnapshotHash'],
          composition.sourceFixture.snapshot.canonicalHash.value);
      final projection = composition.catalogs.projection;
      expect(projection.evidence['runtimeReady'], isFalse);
      expect(projection.evidence['battleAuthority'], 'aveluneNative');
      expect(projection.evidence['sourceBattleScriptsExecuted'], isFalse);
      final moves = preservedCatalogDocuments(projection)
          .singleWhere((document) =>
              document.kind == SourceCatalogDocumentKind.catalog &&
              document.document['catalog'] == 'moves')
          .document['entries'] as List;
      expect(moves, hasLength(2));
      for (final entry in moves) {
        final move =
            PokemonMove.fromJson(Map<String, dynamic>.from(entry as Map));
        expect(
            move.engineSupportLevel, PokemonMoveEngineSupportLevel.catalogOnly);
        expect(move.effects, isEmpty);
        expect(move.sourceRefs.showdownMoveId, isNull);
      }
      expect(jsonEncode(projection.evidence),
          contains('OriginalUnqualifiedEffect'));
      final item = preservedCatalogItems(projection)!.entries.single;
      expect(item.displayName, 'Original cure');
      expect((item.buyPrice, item.sellPrice), (321, 123));
      expect(item.uses, isEmpty);
      expect(
          composition.draft.mutations.where(
              (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
          isEmpty);
      expect(
          composition.draft.mutations.where((mutation) =>
              mutation.actionId == 'campaign.encounter_table.upsert'),
          isEmpty);
      expect(
          composition.draft.mutations.where(
              (mutation) => mutation.actionId == 'pokemon.documents.write'),
          isEmpty);
    });

    test(
        'native writer preserves source-only documents in companion without runtime publication',
        () async {
      final draft = composition.draft;
      expect(draft.mutations.any((m) => m.actionId == 'asset.import_batch'),
          isTrue);
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await const NativeProjectWriter().write(
          approval.plan, approval.context, draft,
          limits: ac14CatalogReferenceLimits);
      expect(receipt.verified, isTrue);
      final opened = await _open(receipt);
      try {
        final native = opened.snapshot;
        expect(native.loadDiagnostics, isEmpty);
        expect(native.manifest.pokemon.enabled, isFalse);
        final validation =
            await opened.api.validateProject(native.projectHandle);
        expect(validation.valid, isTrue,
            reason: jsonEncode(validation.toJson()));
        final projection = composition.catalogs.projection;
        for (final document in preservedCatalogDocuments(projection)) {
          expect(
              await File(path.join(receipt.projectPath, document.relativePath))
                  .exists(),
              isFalse,
              reason: document.relativePath);
        }
        expect(native.manifest.encounterTables, isEmpty);
        expect(native.manifest.trainers, isEmpty);
        expect(native.itemCatalog, isNull);
        final species = preservedCatalogDocuments(projection)
            .where((document) =>
                document.kind == SourceCatalogDocumentKind.species)
            .map((document) => PokemonSpeciesFile.fromJson(
                Map<String, dynamic>.from(document.document)))
            .toList();
        expect(species, hasLength(3));
        expect(species.map((entry) => entry.id).toSet(), hasLength(3));
        final base = species.singleWhere(
            (entry) => entry.forms.isBaseForm && entry.nationalDex == 3);
        final form = species.singleWhere((entry) => !entry.forms.isBaseForm);
        expect(base.baseStats.toJson(), {
          'hp': 31,
          'atk': 41,
          'def': 51,
          'spa': 71,
          'spd': 81,
          'spe': 61,
          'bst': 336
        });
        expect(form.baseStats.toJson(), {
          'hp': 32,
          'atk': 42,
          'def': 52,
          'spa': 72,
          'spd': 82,
          'spe': 62,
          'bst': 342
        });
        expect(form.nationalDex, 3);
        expect(form.forms.formId, '1');
        expect(form.forms.baseFormId, base.id);
        expect(base.forms.otherForms, contains('1'));
        expect(
            base.id,
            SourcePbsIdentity(
              namespace:
                  composition.sourceFixture.snapshot.logicalProjectNamespace,
              family: SourcePbsFamily.species,
              sourceSymbol: 'REEDLING',
            ).sourceId.value);
        expect(
            form.id,
            SourcePbsIdentity(
              namespace:
                  composition.sourceFixture.snapshot.logicalProjectNamespace,
              family: SourcePbsFamily.species,
              sourceSymbol: 'REEDLING',
              form: 1,
            ).sourceId.value);
        expect(species.map((entry) => entry.names.values.single).toSet(),
            {'Shared name'});
        final config = native.manifest.pokemon;
        for (final entry in species) {
          expect(entry.classification.isEnabledInProject, isFalse);
          for (final reference in [
            (config.learnsetsDir, entry.refs.learnset),
            (config.evolutionsDir, entry.refs.evolution),
            (config.mediaDir, entry.refs.media),
          ]) {
            final relativePath =
                path.posix.join(reference.$1, '${reference.$2}.json');
            expect(
                preservedCatalogDocuments(projection)
                    .any((document) => document.relativePath == relativePath),
                isTrue,
                reason: relativePath);
            expect(
                await File(path.join(receipt.projectPath, relativePath))
                    .exists(),
                isFalse);
          }
        }
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(
                native.resourceBytes(assetCatalogResourceIdentity))) as Map));
        final evidence =
            await _projectionEvidence(receipt.projectPath, catalog);
        expect(evidence['kind'], 'sourceCatalogProjection');
        expect(evidence['projection'], projection.toJson());
        final preserved =
            (evidence['preservedSourceFiles'] as List).cast<Map>();
        for (final witness in preserved.where(
            (row) => (row['relativePath'] as String).startsWith('PBS/'))) {
          final bytes = await _reconstruct(receipt.projectPath, witness);
          expect(bytes,
              composition.sourceFixture.sourceBytes[witness['relativePath']]);
          expect(literalFixtureHash(bytes).value, witness['rawSha256']);
        }
        expect(
            await ac14CatalogDirectoryHashes(
                composition.sourceFixture.sourceRootPath!),
            composition.sourceHashes);
      } finally {
        opened.close();
      }
    });

    test('missing species and incomplete trainer preserve whole blocked units',
        () {
      final projection = composition.catalogs.projection;
      expect(preservedCatalogEncounters(projection), hasLength(1));
      expect(preservedCatalogTrainers(projection), hasLength(1));
      expect(
          projection.diagnostics.any((diagnostic) =>
              diagnostic.blocking &&
              diagnostic.code == 'source.catalog.reference_missing'),
          isTrue);
      expect(
          projection.diagnostics.any((diagnostic) =>
              diagnostic.blocking &&
              diagnostic.code == 'source.catalog.trainer_incomplete'),
          isTrue);
      for (final diagnostic
          in projection.diagnostics.where((entry) => entry.blocking)) {
        expect(diagnostic.identityKey, isNotNull);
        expect(diagnostic.locator, isNotNull);
      }
      expect(jsonEncode(projection.evidence), contains('MISSING'));
      expect(jsonEncode(projection.evidence), contains('Incomplete'));
      expect(preservedCatalogTrainers(projection).single.team.single.level, 15);
    });

    test(
        'unexpected native species document is rejected by exact inventory verification',
        () async {
      final draft = composition.draft;
      final approval = approveNativeFixtureDraft(draft);
      final species = preservedCatalogDocuments(composition.catalogs.projection)
          .firstWhere(
              (document) => document.kind == SourceCatalogDocumentKind.species);
      await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
          if (stage == NativeWriteStage.beforeNativeVerify) {
            await Directory(path.join(projectPath!, 'data/pokemon/species'))
                .create(recursive: true);
            await File(path.join(
                    projectPath,
                    path.posix.dirname(species.relativePath),
                    'unexpected.json'))
                .writeAsString(jsonEncode({
              ...species.document,
              'id': 'unexpected',
              'slug': 'unexpected'
            }));
          }
        }).write(approval.plan, approval.context, draft,
            limits: ac14CatalogReferenceLimits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.verify.pokemon_inventory')),
      );
    });

    for (final field in ['stats', 'id', 'form', 'ref']) {
      test('rehashed and reapproved $field alteration refuses before staging',
          () async {
        final sourceDocument =
            preservedCatalogDocuments(composition.catalogs.projection)
                .singleWhere((document) =>
                    document.kind == SourceCatalogDocumentKind.species &&
                    (document.document['forms'] as Map)['isBaseForm'] == false);
        final draft = _alterSpecies(composition.draft, field, sourceDocument);
        expect(draft.canonicalHash, isNot(composition.draft.canonicalHash));
        await _refuseBeforeStage(draft, 'native.semantics.regeneration');
      });
    }

    test('rehashed source witness alteration refuses before staging', () async {
      final draft = _alterWitness(composition.draft);
      expect(draft.canonicalHash, isNot(composition.draft.canonicalHash));
      await _refuseBeforeStage(draft, 'native.semantics.witness');
    });

    test('PBS over one MiB reconstructs exactly from bounded native chunks',
        () async {
      const limits =
          NativeWriteLimits(maxArtifacts: 128, maxArtifactBytes: 1048576);
      final large = await composeAc14CatalogReferenceFixture(
        sourceScriptsPath: scriptsPath!,
        outputParentPath: temporary.path,
        largePbsWitness: true,
        limits: limits,
      );
      final original = large.sourceFixture.sourceBytes['PBS/pokemon.txt']!;
      expect(original.length, greaterThan(1048576));
      expect(large.draft.artifacts.length + large.draft.sourceArtifacts.length,
          lessThanOrEqualTo(ac14CatalogReferenceLimits.maxArtifacts));
      expect(large.draft.mutations.length,
          lessThanOrEqualTo(ac14CatalogReferenceLimits.maxMutations));
      expect(
          large.draft.artifacts
              .where((artifact) =>
                  artifact.reference.mediaType == 'application/json')
              .every((artifact) => artifact.bytes.length <= 1048576),
          isTrue);
      final approval = approveNativeFixtureDraft(large.draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, large.draft, limits: limits);
      final opened = await _open(receipt);
      try {
        expect(
            (await opened.api.validateProject(opened.snapshot.projectHandle))
                .valid,
            isTrue);
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(opened.snapshot
                .resourceBytes(assetCatalogResourceIdentity))) as Map));
        final evidence =
            await _projectionEvidence(receipt.projectPath, catalog);
        final witness = (evidence['preservedSourceFiles'] as List)
            .cast<Map>()
            .singleWhere((row) => row['relativePath'] == 'PBS/pokemon.txt');
        expect(witness['chunks'] as List, hasLength(greaterThan(1)));
        expect(await _reconstruct(receipt.projectPath, witness), original);
        expect(
            await ac14CatalogDirectoryHashes(
                large.sourceFixture.sourceRootPath!),
            large.sourceHashes);
      } finally {
        opened.close();
      }
    });

    for (final tamper in [
      'component',
      'owner',
      'target',
      'parameter',
      'artifact',
      'order',
      'identity'
    ]) {
      test('rehashed catalog batch $tamper tamper is refused before staging',
          () async {
        final draft = composition.draft;
        final evidence = Map<String, Object?>.from(
            jsonDecode(jsonEncode(draft.compositionEvidence)) as Map);
        final marker = evidence['sourceCatalogs'] as Map;
        final row = (marker['mutationBatches'] as List).first as Map;
        final oldId = row['operationId'] as String;
        final components = (row['components'] as List).cast<Map>();
        expect(components.length, greaterThan(1));
        final first = components.first;
        switch (tamper) {
          case 'component':
            components.removeLast();
          case 'owner':
            (first['sourceEntityIds'] as List).removeAt(0);
          case 'target':
            final value = first['targetEntityIds'];
            first['targetEntityIds'] = components[1]['targetEntityIds'];
            components[1]['targetEntityIds'] = value;
          case 'parameter':
            (first['parameters'] as Map)['tags'] = ['forged'];
          case 'artifact':
            (first['parameters'] as Map)['artifactHandle'] = draft.artifacts
                .firstWhere((artifact) =>
                    artifact.handle !=
                    (first['parameters'] as Map)['artifactHandle'])
                .handle;
          case 'order':
            final value = components[0];
            components[0] = components[1];
            components[1] = value;
          case 'identity':
            first['operationId'] = 'forged-component';
        }
        row['components'] = components;
        final id =
            'native-batch-${canonicalHashOf(components, limits: ac14CatalogReferenceLimits.jsonLimits).value}';
        row['operationId'] = id;
        marker['operationIds'] = [
          for (final value in marker['operationIds'] as List)
            value == oldId ? id : value
        ];
        final forged = NativeMutation(
            operationId: ConverterId(id),
            actionId: 'asset.import_batch',
            sourceEntityIds: components
                .expand((entry) =>
                    (entry['sourceEntityIds'] as List).cast<String>())
                .toSet()
                .map(ConverterId.new)
                .toList(),
            targetEntityIds: components
                .expand((entry) =>
                    (entry['targetEntityIds'] as List).cast<String>())
                .toSet()
                .map(ConverterId.new)
                .toList(),
            parameters: {
              'entries': [
                for (final component in components) component['parameters']
              ]
            },
            limits: ac14CatalogReferenceLimits);
        await _refuseBeforeStage(
            _copyDraft(draft,
                mutations: [
                  for (final mutation in draft.mutations)
                    mutation.operationId.value == oldId ? forged : mutation
                ],
                evidence: evidence),
            'native.semantics.regeneration');
        expect(
            await ac14CatalogDirectoryHashes(
                composition.sourceFixture.sourceRootPath!),
            composition.sourceHashes);
      });
    }

    test('a smaller caller budget refuses without a stage or source mutation',
        () async {
      final draft = composition.draft;
      final approval = approveNativeFixtureDraft(draft);
      final stages = <NativeWriteStage>[];
      await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(
          approval.plan,
          approval.context,
          draft,
          limits: const NativeWriteLimits(maxArtifacts: 1),
        ),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft')),
      );
      expect(stages, isEmpty);
      expect(
          await ac14CatalogDirectoryHashes(
              composition.sourceFixture.sourceRootPath!),
          composition.sourceHashes);
    });

    test('projection over one MiB preserves bounded unknown source fields',
        () async {
      const limits =
          NativeWriteLimits(maxArtifacts: 128, maxArtifactBytes: 1048576);
      final large = await composeAc14CatalogReferenceFixture(
        sourceScriptsPath: scriptsPath!,
        outputParentPath: temporary.path,
        largeProjectionEvidence: true,
        limits: limits,
      );
      final original = large.sourceFixture.sourceBytes['PBS/pokemon.txt']!;
      expect(original.length, lessThan(1048576));
      expect(
          LineSplitter.split(utf8.decode(original)).every((line) =>
              line.length <= const SourcePbsLimits().maxLineCodeUnits),
          isTrue);
      final projection = large.catalogs.projection.toJson();
      final projectionBytes = utf8.encode(canonicalJsonOf(projection));
      expect(projectionBytes.length, greaterThan(1048576));
      expect(_longestString(projection), lessThan(1048576));
      final entries = large.catalogs.projection.evidence['entries'] as List;
      final selected = entries.cast<Map>().singleWhere((entry) =>
          (entry['source'] as Map)['identity'] is Map &&
          ((entry['source'] as Map)['identity'] as Map)['sourceSymbol'] ==
              'REEDLING' &&
          ((entry['source'] as Map)['identity'] as Map)['form'] == 0);
      final fields = ((selected['source'] as Map)['fields'] as List)
          .cast<Map>()
          .where(
              (field) => (field['key'] as String).startsWith('OriginalUnknown'))
          .toList();
      expect(fields, hasLength(40));
      for (final field in fields) {
        expect((field['rawValue'] as String).length, 16384);
        expect(field['schemaFormat'], isNull);
        expect((field['locator'] as Map)['file'], 'PBS/pokemon.txt');
        expect((field['locator'] as Map)['line'], isA<int>());
      }
      expect(large.draft.artifacts.length + large.draft.sourceArtifacts.length,
          lessThanOrEqualTo(limits.maxArtifacts));
      expect(
          large.draft.mutations.length, lessThanOrEqualTo(limits.maxMutations));
      expect(
          large.draft.artifacts
              .where((artifact) =>
                  artifact.reference.mediaType == 'application/json')
              .every((artifact) => artifact.bytes.length <= 1048576),
          isTrue);
      final approval = approveNativeFixtureDraft(large.draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, large.draft, limits: limits);
      final opened = await _open(receipt);
      try {
        expect(
            (await opened.api.validateProject(opened.snapshot.projectHandle))
                .valid,
            isTrue);
        final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(opened.snapshot
                .resourceBytes(assetCatalogResourceIdentity))) as Map));
        final evidence =
            await _projectionEvidence(receipt.projectPath, catalog);
        expect(evidence['projection'], projection);
        final witness = (evidence['preservedSourceFiles'] as List)
            .cast<Map>()
            .singleWhere((row) => row['relativePath'] == 'PBS/pokemon.txt');
        expect(await _reconstruct(receipt.projectPath, witness), original);
        expect(
            await ac14CatalogDirectoryHashes(
                large.sourceFixture.sourceRootPath!),
            large.sourceHashes);
      } finally {
        opened.close();
      }
    });
    test('catalog companion exceeds record text quota and replays exact chunks',
        () async {
      const limits = NativeWriteLimits(
          maxArtifacts: 128,
          jsonLimits: ContractLimits(maxTextCodeUnits: 1048576));
      final large = await composeAc14CatalogReferenceFixture(
        sourceScriptsPath: scriptsPath!,
        outputParentPath: temporary.path,
        largeProjectionEvidence: true,
        limits: limits,
      );
      final artifacts = large.draft.artifacts;
      final companion = artifacts
          .where((a) => a.reference.mediaType == 'application/json')
          .map((a) => jsonDecode(utf8.decode(a.bytes)) as Map)
          .singleWhere(
              (value) => value['kind'] == 'sourceCatalogProjectionChunks');
      final bytes = <int>[];
      for (final descriptor in companion['chunks'] as List) {
        expect(descriptor['offset'], bytes.length);
        final chunk = artifacts
            .singleWhere((a) => a.handle == descriptor['artifactHandle']);
        final payload = jsonDecode(utf8.decode(chunk.bytes)) as Map;
        final part = base64Decode(payload['bytesBase64'] as String);
        expect(part.length, descriptor['byteLength']);
        bytes.addAll(part);
      }
      final restored = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      expect(
          () => canonicalJsonOf(restored, limits: limits.jsonLimits),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'json.textQuota')));
      expect(restored['projection'], large.catalogs.projection.toJson());
      expect(bytes.length, companion['byteLength']);
      expect(nativeFixtureHash(bytes).value, companion['sha256']);
      expect(
          artifacts
              .where((a) => a.reference.mediaType == 'application/json')
              .every((a) => a.bytes.length <= 1048576),
          isTrue);
      final approval = approveNativeFixtureDraft(large.draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, large.draft, limits: limits);
      expect(receipt.verified, isTrue);
    });

    test('local native conversion preserves over sixty bounded components',
        () async {
      const limits =
          NativeWriteLimits(maxArtifacts: 128, maxArtifactBytes: 1048576);
      final large = await composeAc14CatalogReferenceFixture(
        sourceScriptsPath: scriptsPath!,
        outputParentPath: temporary.path,
        highMutationCount: true,
        limits: limits,
      );
      final original = large.sourceFixture.sourceBytes['PBS/pokemon.txt']!;
      expect(original.length, lessThan(const SourcePbsLimits().maxFileBytes));
      final logicalCount = large.draft.mutations.fold<int>(
          0,
          (sum, mutation) =>
              sum +
              switch (mutation.actionId) {
                'asset.import_batch' =>
                  (mutation.parameters['entries'] as List).length,
                'element.batch_upsert' =>
                  (mutation.parameters['elements'] as List).length,
                _ => 1,
              });
      expect(logicalCount, greaterThan(60));
      expect(
          large.draft.mutations.length, lessThanOrEqualTo(limits.maxMutations));
      expect(large.draft.artifacts.length + large.draft.sourceArtifacts.length,
          lessThanOrEqualTo(limits.maxArtifacts));
      expect(
          large.draft.artifacts
              .where((artifact) =>
                  artifact.reference.mediaType == 'application/json')
              .every((artifact) => artifact.bytes.length <= 1048576),
          isTrue);
      final approval = approveNativeFixtureDraft(large.draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, large.draft, limits: limits);
      expect(receipt.verified, isTrue);
      final opened = await _open(receipt);
      try {
        final validation =
            await opened.api.validateProject(opened.snapshot.projectHandle);
        expect(validation.valid, isTrue,
            reason: jsonEncode(validation.toJson()));
        expect(opened.snapshot.manifest.trainers, isEmpty);
        expect(opened.snapshot.manifest.encounterTables, isEmpty);
        expect(
            await ac14CatalogDirectoryHashes(
                large.sourceFixture.sourceRootPath!),
            large.sourceHashes);
      } finally {
        opened.close();
      }
    }, timeout: const Timeout(Duration(seconds: 120)));
  }, skip: scriptsPath == null);
}

int _longestString(Object? value) {
  if (value is String) return value.length;
  if (value is Iterable) {
    return value.fold(0, (longest, child) {
      final length = _longestString(child);
      return length > longest ? length : longest;
    });
  }
  if (value is Map) return _longestString([...value.keys, ...value.values]);
  return 0;
}

Future<Map<String, dynamic>> _jsonFile(
        String root, String relativePath) async =>
    Map<String, dynamic>.from(
        jsonDecode(await File(path.join(root, relativePath)).readAsString())
            as Map);

Future<Map<String, dynamic>> _projectionEvidence(
    String projectPath, AssetCatalog catalog) async {
  final companion = catalog.records.singleWhere(
      (record) => record.usages.contains('converter.sourceCatalogs'));
  final indexBytes =
      await File(path.join(projectPath, companion.logicalPath)).readAsBytes();
  expect(indexBytes.length, lessThanOrEqualTo(1048576));
  final index =
      Map<String, dynamic>.from(jsonDecode(utf8.decode(indexBytes)) as Map);
  expect(index['kind'], 'sourceCatalogProjectionChunks');
  expect(index['version'], 1);
  expect(index['encoding'], 'canonicalJsonBase64Chunks');
  final chunks = (index['chunks'] as List).cast<Map>();
  expect(chunks, isNotEmpty);
  expect(
      catalog.records
          .where((record) =>
              record.usages.contains('converter.sourceCatalogProjectionBytes'))
          .map((record) => record.id)
          .toSet(),
      chunks.map((chunk) => chunk['assetId']).toSet());
  final bytes = <int>[];
  for (final chunk in chunks) {
    expect(chunk['offset'], bytes.length);
    final record =
        catalog.records.singleWhere((record) => record.id == chunk['assetId']);
    expect(record.logicalPath, chunk['logicalPath']);
    expect(record.artifact.handle, chunk['artifactHandle']);
    final raw =
        await File(path.join(projectPath, record.logicalPath)).readAsBytes();
    expect(raw.length, lessThanOrEqualTo(1048576));
    expect(ContentArtifactRef.fromBytes(raw, mediaType: 'application/json'),
        record.artifact);
    final envelope =
        Map<String, dynamic>.from(jsonDecode(utf8.decode(raw)) as Map);
    expect(envelope['kind'], 'sourceCatalogProjectionByteChunk');
    expect(envelope['version'], 1);
    expect(envelope['offset'], bytes.length);
    final decoded = base64Decode(envelope['bytesBase64'] as String);
    expect(decoded.length, chunk['byteLength']);
    expect(decoded.length,
        lessThanOrEqualTo(SourceSemanticWitnessFiles.chunkSize));
    bytes.addAll(decoded);
  }
  expect(bytes.length, index['byteLength']);
  expect(literalFixtureHash(bytes).value, index['sha256']);
  final evidence =
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
  expect(evidence['kind'], 'sourceCatalogProjection');
  expect(evidence['version'], 1);
  expect(utf8.encode(canonicalJsonOf(evidence)), bytes);
  return evidence;
}

Future<List<int>> _reconstruct(String projectPath, Map witness) async {
  final bytes = <int>[];
  for (final raw in witness['chunks'] as List) {
    final chunk =
        await _jsonFile(projectPath, (raw as Map)['logicalPath'] as String);
    bytes.addAll(base64Decode(chunk['bytesBase64'] as String));
  }
  return bytes;
}

Future<void> _refuseBeforeStage(NativeProjectDraft draft, String code) async {
  final approval = approveNativeFixtureDraft(draft);
  final stages = <NativeWriteStage>[];
  final before = await Directory(draft.parentPath)
      .list(followLinks: false)
      .map((entry) => entry.path)
      .toList();
  await expectLater(
    NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage)).write(
      approval.plan,
      approval.context,
      draft,
      limits: ac14CatalogReferenceLimits,
    ),
    throwsA(isA<NativeWriteException>()
        .having((error) => error.code, 'code', code)),
  );
  expect(stages, isEmpty);
  expect(
      await Directory(draft.parentPath)
          .list(followLinks: false)
          .map((entry) => entry.path)
          .toList(),
      before);
}

NativeProjectDraft _alterSpecies(NativeProjectDraft draft, String field,
    SourceCatalogDocument sourceDocument) {
  final parameters = <String, Object?>{
    'documents': [
      {
        'actionId': 'pokemon.species.write',
        'parameters': {
          'relativePath': sourceDocument.relativePath,
          'document': jsonDecode(jsonEncode(sourceDocument.document)),
        },
      }
    ]
  };
  final member = (parameters['documents'] as List).single as Map;
  final document = (member['parameters'] as Map)['document'] as Map;
  switch (field) {
    case 'stats':
      (document['baseStats'] as Map)['spe'] = 99;
    case 'id':
      document['id'] = 'altered-source-identity';
    case 'form':
      (document['forms'] as Map)['formId'] = '9';
    case 'ref':
      (document['refs'] as Map)['learnset'] = 'pokemon/learnsets/altered.json';
  }
  return _copyDraft(draft, mutations: [
    ...draft.mutations,
    NativeMutation(
        operationId: ConverterId('forged_source_species'),
        actionId: 'pokemon.documents.write',
        sourceEntityIds: draft.mutations.first.sourceEntityIds,
        targetEntityIds: [ConverterId('forged_source_species')],
        parameters: parameters),
  ]);
}

NativeProjectDraft _alterWitness(NativeProjectDraft draft) {
  final evidence = Map<String, Object?>.from(
      jsonDecode(jsonEncode(draft.compositionEvidence)) as Map);
  final witness = ((evidence['sourceCatalogs'] as Map)['witnesses'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'PBS/pokemon_forms.txt');
  final handle =
      ((witness['chunks'] as List).single as Map)['artifactHandle'] as String;
  final old = draft.sourceArtifacts
      .singleWhere((artifact) => artifact.handle == handle);
  final chunk =
      Map<String, Object?>.from(jsonDecode(utf8.decode(old.bytes)) as Map);
  final raw = base64Decode(chunk['bytesBase64'] as String);
  raw[raw.indexOf(0x31)] = 0x39;
  chunk['bytesBase64'] = base64Encode(raw);
  final replacement = NativeArtifact(
      bytes: utf8.encode(canonicalJsonOf(chunk)),
      mediaType: 'application/json',
      limits: ac14CatalogReferenceLimits);
  final rewritten =
      jsonDecode(jsonEncode(evidence).replaceAll(handle, replacement.handle));
  return _copyDraft(draft,
      sourceArtifacts: draft.sourceArtifacts
          .map((artifact) => identical(artifact, old) ? replacement : artifact)
          .toList(),
      evidence: Map<String, Object?>.from(rewritten as Map));
}

NativeProjectDraft _copyDraft(
  NativeProjectDraft draft, {
  List<NativeMutation>? mutations,
  List<NativeArtifact>? sourceArtifacts,
  Map<String, Object?>? evidence,
}) =>
    NativeProjectDraft(
      source: draft.source,
      projectName: draft.projectName,
      parentPath: draft.parentPath,
      folderName: draft.folderName,
      sourceRootPath: draft.sourceRootPath,
      mapIds: draft.mapIds,
      artifacts: draft.artifacts,
      sourceArtifacts: sourceArtifacts ?? draft.sourceArtifacts,
      mutations: mutations ?? draft.mutations,
      compositionEvidence: evidence ?? draft.compositionEvidence,
      defaultMapWidth: draft.defaultMapWidth,
      defaultMapHeight: draft.defaultMapHeight,
      limits: ac14CatalogReferenceLimits,
    );

final class _Opened {
  const _Opened(this.snapshot, this.api, this.opener, this.workspace);
  final ProjectSnapshot snapshot;
  final AuthoringReadApi api;
  final ProjectOpenService opener;
  final WorkspaceHandle workspace;
  void close() => opener.closeWorkspace(workspace);
}

Future<_Opened> _open(NativeWriteReceipt receipt) async {
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(receipt.projectPath);
  final loader = ProjectSnapshotLoader(handles: handles);
  try {
    final snapshot = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    return _Opened(
        snapshot,
        AuthoringReadApi(openService: opener, snapshotLoader: loader),
        opener,
        opened.workspaceHandle);
  } catch (_) {
    opener.closeWorkspace(opened.workspaceHandle);
    rethrow;
  }
}
