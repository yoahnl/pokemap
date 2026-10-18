import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'native_mutation_batches.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_psdk_catalog.dart';
import 'native_trainer_catalog_bindings.dart';
import 'native_encounter_catalog_bindings.dart';
import 'source_catalog_projection.dart';
import 'source_catalog_selection.dart';
import 'native_trainer_catalog_qualification.dart';
import 'source_encounter_consumers.dart';
import 'source_event_item_bindings.dart';
import 'source_semantic_study_composer.dart';

const sourceCatalogStudyWriteLimits = NativeWriteLimits(
  maxArtifacts: 512,
  maxMutations: 1024,
  maxTotalImagePixels: 33554432,
  jsonLimits: ContractLimits(maxTextCodeUnits: 8388608),
);

const _sourceWorldStudyWriteLimits = NativeWriteLimits(
  maxArtifacts: nativeMaxUniqueArtifacts,
  maxMutations: nativeMaxLogicalMutations,
  maxArtifactBytes: 67108864,
  maxTotalArtifactBytes: 268435456,
  maxTotalDraftJsonBytes: 268435456,
  maxImagePixels: 16777216,
  maxTotalImagePixels: 33554432,
  maxMapCells: 4194304,
  jsonLimits: ContractLimits(
    maxDepth: 64,
    maxNodes: 4000000,
    maxStringCodeUnits: 1048576,
    maxTextCodeUnits: 16777216,
  ),
);

NativeWriteLimits sourceCatalogStudyWriteLimitsFor(int selectedMapCount,
    {bool includeNativeCatalog = false}) {
  if (includeNativeCatalog || selectedMapCount > 8) {
    return _sourceWorldStudyWriteLimits;
  }
  final mapCount = selectedMapCount.clamp(1, 8);
  return NativeWriteLimits(
    maxArtifacts:
        (sourceCatalogStudyWriteLimits.maxArtifacts * mapCount).clamp(1, 1024),
    maxMutations:
        (sourceCatalogStudyWriteLimits.maxMutations * mapCount).clamp(1, 2048),
    maxArtifactBytes: sourceCatalogStudyWriteLimits.maxArtifactBytes,
    maxTotalArtifactBytes: sourceCatalogStudyWriteLimits.maxTotalArtifactBytes,
    maxTotalDraftJsonBytes:
        sourceCatalogStudyWriteLimits.maxTotalDraftJsonBytes,
    maxImagePixels: sourceCatalogStudyWriteLimits.maxImagePixels,
    maxTotalImagePixels: sourceCatalogStudyWriteLimits.maxTotalImagePixels,
    maxMapCells: sourceCatalogStudyWriteLimits.maxMapCells,
    jsonLimits: sourceCatalogStudyWriteLimits.jsonLimits,
  );
}

final class SourceCatalogStudyComposition {
  const SourceCatalogStudyComposition(
      {required this.draft, required this.projection});
  final NativeProjectDraft draft;
  final SourceCatalogProjection projection;
}

final class SourceCatalogStudyComposer {
  const SourceCatalogStudyComposer(
      {this.nativeTrainerMovePolicy =
          NativeTrainerMovePolicy.nativeAveluneDefaults,
      this.nativeEncounterQualification,
      this.nativeTrainerCatalog,
      this.nativeTrainerQualification,
      this.automaticNativeEncounters = true,
      this.includeNativeEncounterConsumers = false});
  final NativeTrainerMovePolicy nativeTrainerMovePolicy;
  final NativeEncounterCatalogQualification? nativeEncounterQualification;
  final NativePsdkCatalog? nativeTrainerCatalog;
  final NativeTrainerCatalogQualification? nativeTrainerQualification;
  final bool automaticNativeEncounters;
  final bool includeNativeEncounterConsumers;

  Future<SourceCatalogStudyComposition?> compose({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    if (!automaticNativeEncounters && nativeEncounterQualification != null) {
      throw const NativeWriteException('catalogs.encounters.policy',
          'An explicit native encounter release requires active encounter preparation.');
    }
    final profile = SourceEventProfile.kantoForProject(source);
    if (!profile.isQualified ||
        !base.compositionEvidence.containsKey('sourceSemantics') ||
        !source.snapshot.entries.any((entry) =>
            entry.kind == SourceNodeKind.file &&
            entry.relativePath.startsWith('PBS/') &&
            entry.relativePath.endsWith('.txt'))) {
      return null;
    }
    if (base.source.canonicalHash != source.canonicalHash ||
        base.compositionEvidence.containsKey('sourceCatalogs') ||
        base.compositionEvidence.containsKey('assetLibrary')) {
      throw const NativeWriteException('catalogs.base.binding',
          'Catalog composition requires its exact preceding semantic study');
    }
    final recording = SourceSemanticWitnessFiles(
        source.snapshot, files, limits, cancellation,
        preservePngAsByteChunks: true);
    final scripts = source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    await recording.read(scripts.fileId);
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot,
        files: recording,
        profile: SourcePbsProfile.essentials21_1,
        cancellation: cancellation);
    if (pbs.documents.isEmpty) return null;
    if (nativeTrainerCatalog != null &&
        nativeEncounterQualification != null &&
        canonicalHashOf(nativeTrainerCatalog!.toJson(),
                limits: nativePsdkCatalogShardJsonLimits) !=
            canonicalHashOf(nativeEncounterQualification!.bundle.toJson(),
                limits: nativePsdkCatalogShardJsonLimits)) {
      throw ContractError(
          'native_catalog.encounter_qualification_identity',
          r'$',
          'An explicit native catalog requires its exact encounter qualification identity.');
    }
    final encounters = nativeEncounterQualification ??
        (automaticNativeEncounters && nativeTrainerCatalog == null
            ? await NativeEncounterCatalogQualification.prepareAutomatic(
                source: source,
                files: recording,
                pbs: pbs,
                selectedSourceMapIds: base.mapIds.keys,
                cancellation: cancellation)
            : null);
    final encounterRelease = encounters?.artifacts(limits: limits);
    final selection = sourceCatalogSelection(source, base.mapIds.keys.toSet());
    final existing = _precedingItemCatalog(base);
    final native = encounters?.bundle ?? nativeTrainerCatalog ??
        NativePsdkCatalogManifest.builtin();
    final sourceEvents = base.compositionEvidence['sourceEvents'];
    final nativePartyTrade =
        sourceEvents is Map && sourceEvents['partyTrade'] is Map;
    final giftEvidence = sourceEvents is Map ? sourceEvents['pokemonGiftBindings'] : null;
    final nativeGift = giftEvidence is Map && giftEvidence['activationQualified'] == true;
    if (nativeGift) {
      final bindings = giftEvidence['bindings'];
      final catalogHash = canonicalHashOf(native.toJson(), limits: nativePsdkCatalogShardJsonLimits).value;
      if (bindings is! List || bindings.isEmpty || bindings.any((binding) =>
          binding is! Map || binding['catalogHash'] != catalogHash ||
          binding['sourceSnapshotHash'] != source.snapshot.canonicalHash.value ||
          binding['normalizationHash'] != source.canonicalHash.value ||
          binding['profileHash'] != profile.canonicalHash.value)) {
        throw const NativeWriteException('catalogs.pokemon_gift.binding',
            'Active gifts require their exact shared native catalog and whole source event qualification.');
      }
    }
    final trainerQualification = nativeTrainerQualification ??
        (selection.trainers.isEmpty || !source.snapshot.entries.any(
                (entry) => entry.relativePath == 'Data/trainers.dat')
            ? null
            : await NativeTrainerCatalogQualification.prepare(
                normalizedSource: source, source: pbs, files: recording,
                nativeCatalog: native, requestedTrainers: selection.trainers,
                cancellation: cancellation));
    if (trainerQualification != null) {
      await trainerQualification.validateContext(
          normalizedSource: source, source: pbs, files: recording,
          nativeCatalog: native, requestedTrainers: selection.trainers,
          cancellation: cancellation);
    }
    final precedingTrainerBindings = sourceEvents is Map
        ? sourceEvents['trainerBindings'] : null;
    final precedingBindings = precedingTrainerBindings is Map
        ? precedingTrainerBindings['bindings'] : null;
    if (precedingBindings is List && precedingBindings.any((binding) =>
        binding is! Map || trainerQualification == null ||
        binding['qualificationHash'] != trainerQualification.evidenceHash.value ||
        binding['nativeBundleHash'] != trainerQualification.evidence['nativeCatalogHash'])) {
      throw const NativeWriteException('catalogs.trainer.event_binding',
          'Active trainer events require the same exact shared catalog qualification.');
    }
    final trainerRelease = trainerQualification?.artifacts(limits: limits);
    var projection = await const SourceCatalogProjector().read(
        source: source,
        pbs: pbs,
        files: recording,
        nativeMapIds: base.mapIds,
        existingItemCatalog: existing?.catalog,
        requestedItemSymbols: selection.items,
        requestedTrainerKeys: selection.trainers,
        nativeTrainerQualification: trainerQualification,
        nativeTrainerBundle: trainerQualification == null &&
                !nativePartyTrade &&
                nativeTrainerCatalog == null
            ? null
            : native,
        nativeEncounterQualification: encounters,
        nativeEncounterRatePolicy: encounters == null
            ? NativeEncounterRatePolicy.unresolved
            : NativeEncounterRatePolicy
                .adaptSourceBasePercentToNativeConstantChance,
        nativeEncounterFishingRatePolicy: encounters == null
            ? NativeEncounterFishingRatePolicy.unresolved
            : NativeEncounterFishingRatePolicy
                .adaptSourceBaseFishingBiteChanceToNativeTable,
        nativeTrainerMovePolicy: nativeTrainerMovePolicy,
        cancellation: cancellation);
    if (includeNativeEncounterConsumers) {
      projection = await _seedNativeExplorationItems(
          source: source,
          projection: projection,
          previous: existing?.catalog,
          files: recording,
          profile: profile,
          cancellation: cancellation);
    }
    final owners = pbs.documents
        .map((document) => document.file.fileId)
        .toSet()
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final mutations = <NativeMutation>[];
    NativeMutation mutation(
            String action, String target, Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('ac14_${canonicalHashOf({
                  'action': action,
                  'target': target,
                  'parameters': parameters,
                }, limits: limits.jsonLimits).value}'),
            actionId: action,
            sourceEntityIds: owners,
            targetEntityIds: [ConverterId(target)],
            parameters: parameters,
            limits: limits);
    for (final artifact
        in encounterRelease?.artifacts ?? const <NativeArtifact>[]) {
      final id =
          'native_encounter_release_${artifact.rawSha256.value.substring(0, 24)}';
      mutations.add(mutation('asset.import', id, {
        'artifactHandle': artifact.handle,
        'assetId': id,
        'logicalPath': 'assets/converter/$id.json',
        'tags': ['native-encounter-release', 'preserved-native-provenance'],
        'usages': ['converter.nativeEncounterQualificationBytes'],
      }));
    }
    for (final artifact in trainerRelease?.artifacts ?? const <NativeArtifact>[]) {
      final id = 'native_trainer_release_${artifact.rawSha256.value.substring(0, 24)}';
      mutations.add(mutation('asset.import', id, {
        'artifactHandle': artifact.handle,
        'assetId': id,
        'logicalPath': 'assets/converter/$id.json',
        'tags': ['native-trainer-release', 'preserved-native-provenance'],
        'usages': ['converter.nativeTrainerQualificationBytes'],
      }));
    }
    final nativeCatalogQualified =
        projection.evidence['nativeTrainerBindings'] is Map ||
            projection.evidence['nativeEncounterBindings'] is Map || nativeGift;
    final hasData = nativeCatalogQualified && projection.documents.isNotEmpty;
    if (hasData &&
        !base.mutations.any((entry) =>
            entry.actionId == 'pokemon.configuration.set_enabled' &&
            entry.parameters['enabled'] == true)) {
      mutations.add(mutation('pokemon.configuration.set_enabled',
          'source_catalogs', {'enabled': true}));
    }
    const config =
        ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1);
    final itemPath = config.catalogFiles['items']!;
    final documents = (nativeCatalogQualified
            ? projection.documents
            : const <SourceCatalogDocument>[])
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    final paths = <String>{};
    final speciesDocuments = <String, List<Map<String, Object?>>>{};
    for (final document in documents) {
      cancellation?.check();
      if (!paths.add(document.relativePath)) {
        throw const NativeWriteException('catalogs.document.identity',
            'A source catalog projection cannot replace a document twice');
      }
      if (document.relativePath == itemPath &&
          projection.mergedItemCatalog != null) {
        if (canonicalJsonOf(document.document) !=
            canonicalJsonOf(
                encodeProjectItemCatalog(projection.mergedItemCatalog!))) {
          throw const NativeWriteException('catalogs.items.binding',
              'The merged item catalog must match its projected document');
        }
        continue;
      }
      final action = switch (document.kind) {
        SourceCatalogDocumentKind.catalog => 'pokemon.catalog.write',
        SourceCatalogDocumentKind.species => 'pokemon.species.write',
        SourceCatalogDocumentKind.learnset => 'pokemon.learnset.write',
        SourceCatalogDocumentKind.evolution => 'pokemon.evolution.write',
        SourceCatalogDocumentKind.media => 'pokemon.media.write',
      };
      final parameters = <String, Object?>{
        'relativePath': document.relativePath,
        'document': document.document
      };
      if (document.kind == SourceCatalogDocumentKind.catalog) {
        mutations.add(mutation(
            action,
            'catalog_document_${canonicalHashOf(document.relativePath).value}',
            parameters));
      } else {
        final owner = document.kind == SourceCatalogDocumentKind.species
            ? document.document['id']
            : document.document['speciesId'];
        if (owner is! String || owner.isEmpty) {
          throw const NativeWriteException('catalogs.document.owner',
              'A native Pokemon document requires its exact species identity');
        }
        speciesDocuments.putIfAbsent(owner, () => []).add({
          'actionId': action,
          'parameters': parameters,
        });
      }
    }
    var batch = <Map<String, Object?>>[];
    void flush() {
      if (batch.isEmpty) return;
      mutations.add(mutation(
          'pokemon.documents.write',
          'source_catalog_documents_${canonicalHashOf(batch, limits: limits.jsonLimits).value}',
          {'documents': batch}));
      batch = [];
    }

    for (final group in speciesDocuments.values) {
      if (group.length > 200 ||
          !group.any((entry) => entry['actionId'] == 'pokemon.species.write')) {
        throw const NativeWriteException('catalogs.document.owner',
            'Each bounded document batch must include its native species definition');
      }
      if (batch.length + group.length > 200) flush();
      batch.addAll(group);
    }
    flush();
    if (projection.mergedItemCatalog != null) {
      mutations.add(mutation('pokemon.catalog.write', 'source_items', {
        'relativePath': itemPath,
        if (existing != null) 'beforeBytesBase64': base64Encode(existing.bytes),
        'document': encodeProjectItemCatalog(projection.mergedItemCatalog!),
      }));
    }
    for (final table in nativeCatalogQualified
        ? projection.encounterTables
        : const <ProjectEncounterTable>[]) {
      mutations.add(mutation('campaign.encounter_table.upsert', table.id,
          {'value': table.toJson()}));
    }
    final eventProjection = sourceEvents is Map ? sourceEvents['projection'] : null;
    final pending = eventProjection is Map
        ? List<Object?>.from(eventProjection['pendingCatalogCompanions'] as List? ?? const [])
        : const <Object?>[];
    SourceEncounterConsumers? consumers;
    if (includeNativeEncounterConsumers) {
      final binding = projection.evidence['nativeEncounterBindings'];
      if (encounters == null || binding is! Map<String, Object?>) {
        throw const NativeWriteException('catalogs.encounter_consumers.qualification',
            'Active encounter consumers require their exact native catalogue release.');
      }
      consumers = SourceEncounterConsumers.bind(source: source,
          nativeMapIds: base.mapIds, tables: projection.encounterTables,
          catalogEvidence: binding, qualification: encounters,
          pendingCompanions: pending, precedingMutations: base.mutations);
      for (final entry in consumers.zones.entries) {
        for (final zone in entry.value) {
          final mapId = base.mapIds[entry.key]!;
          final parameters = <String, Object?>{
            'mapId': mapId, 'zone': jsonDecode(jsonEncode(zone.toJson()))};
          final operation = mutation('gameplay_zone.create', zone.id, parameters);
          mutations.add(NativeMutation(operationId: operation.operationId,
              actionId: operation.actionId, sourceEntityIds: [...owners, source.mapIdentity(entry.key)],
              targetEntityIds: [ConverterId(mapId), ConverterId(zone.id)],
              parameters: parameters, limits: limits));
        }
      }
      for (final parameters in consumers.companions) {
        final mapId = parameters['mapId'] as String;
        final entityId = parameters['entityId'] as String;
        final operation = mutation('entity.set_interactive_encounter', entityId, parameters);
        mutations.add(NativeMutation(operationId: operation.operationId,
            actionId: operation.actionId, sourceEntityIds: [...owners, source.mapIdentity(
                base.mapIds.entries.singleWhere((entry) => entry.value == mapId).key)],
            targetEntityIds: [ConverterId(mapId), ConverterId(entityId)],
            parameters: parameters, limits: limits));
      }
    } else if (pending.isNotEmpty) {
      throw const NativeWriteException('catalogs.encounter_consumers.pending',
          'Deferred field encounters require their exact native catalogue consumers.');
    }
    for (final trainer in nativeCatalogQualified
        ? projection.trainers
        : const <ProjectTrainerEntry>[]) {
      mutations.add(mutation(
          'campaign.trainer.upsert', trainer.id, {'value': trainer.toJson()}));
    }
    mutations.addAll(projection.assetMutations);
    final preservedArtifacts = <String, NativeArtifact>{};
    final preservedFiles = <Map<String, Object?>>[];
    for (final witness in recording.evidence) {
      final chunks = <Map<String, Object?>>[];
      for (final sourceChunk
          in _catalogSourceChunks(witness, recording, limits)) {
        cancellation?.check();
        final artifact = sourceChunk.$1;
        final id = 'ac14_source_${artifact.rawSha256.value.substring(0, 24)}';
        final logicalPath = 'assets/converter/$id.json';
        chunks.add({
          'artifactHandle': artifact.handle,
          'offset': sourceChunk.$2,
          'byteLength': sourceChunk.$3,
          'assetId': id,
          'logicalPath': logicalPath
        });
        if (preservedArtifacts.containsKey(artifact.handle)) continue;
        preservedArtifacts[artifact.handle] = artifact;
        mutations.add(mutation('asset.import', id, {
          'artifactHandle': artifact.handle,
          'assetId': id,
          'logicalPath': logicalPath,
          'tags': ['preserved-source-bytes'],
          'usages': ['converter.sourceCatalogBytes'],
        }));
      }
      final preserved = Map<String, Object?>.from(witness)
        ..remove('artifactHandle');
      preservedFiles.add({
        ...preserved,
        'encoding': 'canonicalJsonBase64Chunks',
        'chunks': chunks
      });
    }
    final companionPayload = <String, Object?>{
      'kind': 'sourceCatalogProjection',
      'version': 1,
      'projection': projection.toJson(),
      if (consumers != null) 'nativeEncounterConsumers': consumers.evidence,
      if (encounterRelease != null)
        'nativeEncounterRelease': encounterRelease.evidence,
      if (trainerRelease != null)
        'nativeTrainerRelease': trainerRelease.evidence,
      'preservedSourceFiles': preservedFiles,
    };
    final companionBytes = utf8.encode(canonicalJsonOf(companionPayload,
        limits: limits.artifactEvidenceJsonLimits));
    if (companionBytes.length > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('native.quota.artifact',
          'Aggregate catalog evidence byte budget exceeded');
    }
    final companionChunks = <Map<String, Object?>>[];
    for (var offset = 0;
        offset < companionBytes.length;
        offset += SourceSemanticWitnessFiles.chunkSize) {
      cancellation?.check();
      final end = (offset + SourceSemanticWitnessFiles.chunkSize <
              companionBytes.length)
          ? offset + SourceSemanticWitnessFiles.chunkSize
          : companionBytes.length;
      final artifact = NativeArtifact(
          bytes: utf8.encode(canonicalJsonOf({
            'kind': 'sourceCatalogProjectionByteChunk',
            'version': 1,
            'offset': offset,
            'bytesBase64': base64Encode(companionBytes.sublist(offset, end)),
          }, limits: limits.jsonLimits)),
          mediaType: 'application/json',
          limits: limits);
      final id = 'ac14_projection_${artifact.rawSha256.value.substring(0, 24)}';
      final logicalPath = 'assets/converter/$id.json';
      companionChunks.add({
        'artifactHandle': artifact.handle,
        'offset': offset,
        'byteLength': end - offset,
        'assetId': id,
        'logicalPath': logicalPath,
      });
      preservedArtifacts[artifact.handle] = artifact;
      mutations.add(mutation('asset.import', id, {
        'artifactHandle': artifact.handle,
        'assetId': id,
        'logicalPath': logicalPath,
        'tags': ['source-catalogs', 'preserved-source-provenance'],
        'usages': ['converter.sourceCatalogProjectionBytes'],
      }));
    }
    final companion = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({
          'kind': 'sourceCatalogProjectionChunks',
          'version': 1,
          'encoding': 'canonicalJsonBase64Chunks',
          'sha256': canonicalHashOf(companionPayload,
                  limits: limits.artifactEvidenceJsonLimits)
              .value,
          'byteLength': companionBytes.length,
          'chunks': companionChunks,
        }, limits: limits.jsonLimits)),
        mediaType: 'application/json',
        limits: limits);
    final companionId =
        'ac14_catalogs_${companion.rawSha256.value.substring(0, 24)}';
    mutations.add(mutation('asset.import', companionId, {
      'artifactHandle': companion.handle,
      'assetId': companionId,
      'logicalPath': 'assets/converter/$companionId.json',
      'tags': ['source-catalogs', 'preserved-source-provenance'],
      'usages': ['converter.sourceCatalogs'],
    }));
    final grouped = batchNativeMutations(mutations,
        actionId: 'asset.import', limits: limits);
    final evidence = {
      'kind': 'sourceCatalogStudy',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'pbsProfile': pbs.profile.name,
      'pbsHash': pbs.canonicalHash.value,
      'automaticNativeEncounters': automaticNativeEncounters,
      'profile': profile.toJson(),
      if (nativeTrainerCatalog != null && nativeEncounterQualification == null)
        'automaticEncounterReleaseSuppressedForExplicitCatalog': true,
      'projectionHash': projection.canonicalHash.value,
      'projection': projection.evidence,
      if (nativeGift) 'nativePokemonGiftCatalogHash': canonicalHashOf(native.toJson(), limits: nativePsdkCatalogShardJsonLimits).value,
      if (includeNativeEncounterConsumers) 'includeNativeEncounterConsumers': true,
      if (consumers != null) 'nativeEncounterConsumers': consumers.evidence,
      if (encounterRelease != null)
        'nativeEncounterRelease': encounterRelease.evidence,
      if (trainerRelease != null)
        'nativeTrainerRelease': trainerRelease.evidence,
      'diagnostics':
          projection.diagnostics.map((entry) => entry.toJson()).toList(),
      'requestedItemSymbols': selection.items,
      'requestedTrainerKeys':
          selection.trainers.map((entry) => entry.toJson()).toList(),
      'witnesses': recording.evidence,
      'automatic': true,
      'aiCalls': 0,
      'activeCatalogPolicy': 'nativeBundleOnly',
      'sourceOnlyRuntimeDataPublished': false,
      'battleAuthority': 'aveluneNative',
      'sourceBattleScriptsExecuted': false,
      'playableCertified': false,
      'mutationBatches': grouped.evidence,
      'operationIds':
          grouped.mutations.map((entry) => entry.operationId.value).toList(),
    };
    final artifacts = {
      for (final entry in [
        ...base.artifacts,
        ...projection.artifacts,
        ...?encounterRelease?.artifacts,
        ...?trainerRelease?.artifacts,
        ...preservedArtifacts.values,
        companion
      ])
        entry.handle: entry
    }.values.toList()
      ..sort((a, b) => a.handle.compareTo(b.handle));
    final witnesses = {
      for (final entry in [
        ...base.sourceArtifacts,
        ...recording.artifacts.values
      ])
        entry.handle: entry
    }.values.toList()
      ..sort((a, b) => a.handle.compareTo(b.handle));
    validateNativeArtifactCount(artifacts: artifacts, sourceArtifacts: witnesses,
        limits: limits, quotaCode: 'catalogs.artifacts.quota');
    return SourceCatalogStudyComposition(
        projection: projection,
        draft: NativeProjectDraft(
            source: source,
            projectName: base.projectName,
            parentPath: base.parentPath,
            folderName: base.folderName,
            sourceRootPath: base.sourceRootPath,
            mapIds: base.mapIds,
            artifacts: artifacts,
            sourceArtifacts: witnesses,
            mutations: _mergeCatalogMutations(base.mutations, grouped.mutations,
                sourceOnlyTrainerIds: {
                  for (final key in selection.trainers) key.sourceId.value,
                }),
            compositionEvidence: {
              ...base.compositionEvidence,
              'sourceCatalogs': evidence
            },
            defaultMapWidth: base.defaultMapWidth,
            defaultMapHeight: base.defaultMapHeight,
            limits: limits));
  }
}

Future<SourceCatalogProjection> _seedNativeExplorationItems({
  required NormalizedSourceProject source,
  required SourceCatalogProjection projection,
  required ProjectItemCatalog? previous,
  required SourceFilePort files,
  required SourceEventProfile profile,
  ScanCancellation? cancellation,
}) async {
  const symbols = [
    'REPEL',
    'SUPERREPEL',
    'MAXREPEL',
    'ESCAPEROPE',
    'BICYCLE',
    'OLDROD',
    'GOODROD',
    'SUPERROD',
  ];
  final bindings = await const SourceEventItemBindingResolver().read(
      snapshot: source.snapshot,
      files: files,
      symbols: symbols,
      eventProfile: profile,
      cancellation: cancellation);
  if (projection.mergedItemCatalog == null ||
      bindings.quarantinedSymbols.isNotEmpty ||
      bindings.bindings.length != symbols.length ||
      bindings.bindings.values.any((binding) =>
          binding.definition.uses.length != 1 ||
          binding.definition.uses.single.target !=
              ProjectItemTargetKind.world)) {
    throw NativeWriteException('catalogs.exploration_items.unqualified',
        'Native encounter consumers require all eight exact source exploration definitions: ${canonicalJsonOf(bindings.quarantinedSymbols)}');
  }
  final items = {
    for (final item in projection.mergedItemCatalog!.entries) item.id: item
  };
  final previousIds =
      previous?.entries.map((item) => item.id).toSet() ?? <String>{};
  final newlySeeded = <Map<String, Object?>>[];
  for (final binding in bindings.bindings.values) {
    final definition = binding.definition;
    final projected = items[definition.id];
    if (projected != null &&
        (projected.displayName != definition.displayName ||
            projected.pocketId != definition.pocketId ||
            projected.buyPrice != definition.buyPrice ||
            projected.sellPrice != definition.sellPrice ||
            projected.description != definition.description ||
            (projected.uses.isNotEmpty && projected != definition))) {
      throw NativeWriteException('catalogs.exploration_items.conflict',
          'The source exploration definition conflicts with its preceding catalog item: ${binding.sourceSymbol}');
    }
    items[definition.id] = definition;
    if (!previousIds.contains(definition.id)) newlySeeded.add(binding.toJson());
  }
  final merged = ProjectItemCatalog(
      schemaVersion: 1,
      entries: items.values.toList()..sort((a, b) => a.id.compareTo(b.id)));
  final evidence = <String, Object?>{
    ...projection.evidence,
    'sourceOnlyData': {
      ...Map<String, Object?>.from(
          projection.evidence['sourceOnlyData'] as Map),
      'mergedItemCatalog': merged.toJson(),
    },
    'nativeExplorationItemDefinitions': {
      'kind': 'sourceBoundNativeExplorationDefinitions',
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'sourceProfile': profile.toJson(),
      'previousNativeCatalog': {
        'itemIds':
            previous?.entries.map((item) => item.id).toList() ?? <String>[],
        'canonicalHash':
            previous == null ? null : canonicalHashOf(previous.toJson()).value,
      },
      'newlySeededSourceDefinitions': newlySeeded,
      'bindings': bindings.evidence,
      'initialPlayerStateMutated': false,
      'inventoryGranted': false,
      'progressionGranted': false,
      'sourceScriptsExecuted': 0,
      'fullSourceExplorationParityQualified': false,
    },
  };
  return SourceCatalogProjection(
      documents: projection.documents,
      mergedItemCatalog: merged,
      encounterTables: projection.encounterTables,
      trainers: projection.trainers,
      artifacts: projection.artifacts,
      assetMutations: projection.assetMutations,
      diagnostics: projection.diagnostics,
      evidence: evidence);
}

List<NativeMutation> _mergeCatalogMutations(
    List<NativeMutation> base, List<NativeMutation> catalogs,
    {required Set<String> sourceOnlyTrainerIds}) {
  final declarations = {
    for (final mutation in catalogs)
      if (mutation.actionId == 'campaign.trainer.upsert')
        (mutation.parameters['value'] as Map)['id'] as String: mutation
  };
  final activations = catalogs.where((mutation) =>
      mutation.actionId == 'pokemon.configuration.set_enabled' &&
      mutation.parameters['enabled'] == true);
  final consumed = <String>{};
  var requiresPokemonActivation = false;
  var insertionIndex = -1;
  for (var index = 0; index < base.length; index++) {
    final mutation = base[index];
    final references = <String?>[];
    if (mutation.actionId == 'entity.upsert') {
      final entity = MapEntity.fromJson(
          Map<String, dynamic>.from(mutation.parameters['entity'] as Map));
      references.add(entity.npc?.trainerId);
    } else if (mutation.actionId == 'scene.upsert') {
      final scene = SceneAsset.fromJson(
          Map<String, dynamic>.from(mutation.parameters['scene'] as Map));
      if (activations.isNotEmpty &&
          scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .any((payload) => payload.interactiveCommand
                  is SceneReceivePokemonFromCatalogInteractiveCommand)) {
        requiresPokemonActivation = true;
        if (insertionIndex < 0 || index < insertionIndex) insertionIndex = index;
      }
      references.addAll(scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneBattlePayload>()
          .map((payload) => payload.trainerId));
    }
    for (final reference in references) {
      if (sourceOnlyTrainerIds.contains(reference) &&
          !declarations.containsKey(reference)) {
        throw const NativeWriteException('catalogs.trainer.unqualified',
            'A source-only trainer cannot be referenced by an active native consumer');
      }
      if (declarations.containsKey(reference)) {
        consumed.add(reference!);
        if (insertionIndex < 0) insertionIndex = index;
      }
    }
  }
  if (insertionIndex < 0) return [...base, ...catalogs];
  final promoted = {
    for (final entry in declarations.entries)
      if (consumed.contains(entry.key)) entry.value.operationId,
    if (requiresPokemonActivation)
      for (final activation in activations) activation.operationId,
  };
  return [
    ...base.take(insertionIndex),
    ...catalogs.where((mutation) => promoted.contains(mutation.operationId)),
    ...base.skip(insertionIndex),
    ...catalogs.where((mutation) => !promoted.contains(mutation.operationId)),
  ];
}

({ProjectItemCatalog catalog, List<int> bytes})? _precedingItemCatalog(
    NativeProjectDraft base) {
  ProjectItemCatalog? catalog;
  List<int>? bytes;
  const config =
      ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1);
  for (final mutation in base.mutations) {
    if (mutation.actionId == 'pokemon.catalog.write' &&
        mutation.parameters['relativePath'] == config.catalogFiles['items']) {
      catalog = decodeProjectItemCatalog(mutation.parameters['document']);
      bytes = utf8.encode(
          '${const JsonEncoder.withIndent('  ').convert(encodeProjectItemCatalog(catalog))}\n');
    } else if (mutation.actionId == 'item.create') {
      if (catalog == null) {
        throw const NativeWriteException('catalogs.items.preimage',
            'A source item requires its preceding exact native catalog');
      }
      final item = ProjectItemDefinition.fromJson(
          Map<String, dynamic>.from(mutation.parameters['definition'] as Map));
      if (catalog.entries.any((entry) => entry.id == item.id)) {
        throw const NativeWriteException('catalogs.items.identity',
            'One source item cannot have duplicate preceding bindings');
      }
      catalog =
          catalog.copyWith(entries: [...catalog.entries, item]).normalized();
      bytes = utf8.encode(jsonEncode(encodeProjectItemCatalog(catalog)));
    }
  }
  return catalog == null ? null : (catalog: catalog, bytes: bytes!);
}

Iterable<(NativeArtifact, int, int)> _catalogSourceChunks(
    Map<String, Object?> witness,
    SourceSemanticWitnessFiles recording,
    NativeWriteLimits limits) sync* {
  if (witness['encoding'] != 'png') {
    for (final chunk in witness['chunks'] as List) {
      yield (
        recording.artifacts[(chunk as Map)['artifactHandle']]!,
        chunk['offset'] as int,
        chunk['byteLength'] as int
      );
    }
    return;
  }
  final original = recording.artifacts[witness['artifactHandle']]!.bytes;
  for (var offset = 0;
      offset < original.length;
      offset += SourceSemanticWitnessFiles.chunkSize) {
    final end =
        (offset + SourceSemanticWitnessFiles.chunkSize < original.length)
            ? offset + SourceSemanticWitnessFiles.chunkSize
            : original.length;
    yield (
      NativeArtifact(
          bytes: utf8.encode(canonicalJsonOf({
            'kind': 'sourceSemanticByteChunk',
            'version': 1,
            'offset': offset,
            'bytesBase64': base64Encode(original.sublist(offset, end)),
          }, limits: limits.jsonLimits)),
          mediaType: 'application/json',
          limits: limits),
      offset,
      end - offset
    );
  }
}
