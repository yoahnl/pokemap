import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_trainer_catalog_bindings.dart';
import 'source_catalog_projection.dart';
import 'source_semantic_study_composer.dart';

const sourceCatalogStudyWriteLimits = NativeWriteLimits(
  maxArtifacts: 512,
  maxMutations: 1024,
  jsonLimits: ContractLimits(maxTextCodeUnits: 8388608),
);

NativeWriteLimits sourceCatalogStudyWriteLimitsFor(int selectedMapCount) {
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
          NativeTrainerMovePolicy.nativeAveluneDefaults});
  final NativeTrainerMovePolicy nativeTrainerMovePolicy;

  Future<SourceCatalogStudyComposition?> compose({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
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
    final selection = _catalogSelection(source, base.mapIds.keys.toSet());
    final existing = _precedingItemCatalog(base);
    final native = NativePsdkTrainerBundle.builtin();
    final supported =
        (native.evidence['sourceTrainerKeys'] as List).cast<String>().toSet();
    final nativeKeys = selection.trainers
        .where((key) =>
            key.version == 0 &&
            supported.contains('${key.trainerType},${key.trainerName}'))
        .toList();
    final projection = await const SourceCatalogProjector().read(
        source: source,
        pbs: pbs,
        files: recording,
        nativeMapIds: base.mapIds,
        existingItemCatalog: existing?.catalog,
        requestedItemSymbols: selection.items,
        requestedTrainerKeys: selection.trainers,
        nativeTrainerKeys: nativeKeys,
        nativeTrainerBundle: nativeKeys.isEmpty ? null : native,
        nativeTrainerMovePolicy: nativeTrainerMovePolicy,
        cancellation: cancellation);
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
    final hasData =
        projection.documents.isNotEmpty || projection.mergedItemCatalog != null;
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
    final documents = projection.documents.toList()
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
    for (final table in projection.encounterTables) {
      mutations.add(mutation('campaign.encounter_table.upsert', table.id,
          {'value': table.toJson()}));
    }
    for (final trainer in projection.trainers) {
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
      'preservedSourceFiles': preservedFiles,
    };
    final companionBytes = utf8
        .encode(canonicalJsonOf(companionPayload, limits: limits.jsonLimits));
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
          'sha256': canonicalHashOf(companionPayload, limits: limits.jsonLimits)
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
    final evidence = {
      'kind': 'sourceCatalogStudy',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'pbsProfile': pbs.profile.name,
      'pbsHash': pbs.canonicalHash.value,
      'profile': profile.toJson(),
      'projectionHash': projection.canonicalHash.value,
      'projection': projection.evidence,
      'diagnostics':
          projection.diagnostics.map((entry) => entry.toJson()).toList(),
      'requestedItemSymbols': selection.items,
      'requestedTrainerKeys':
          selection.trainers.map((entry) => entry.toJson()).toList(),
      'witnesses': recording.evidence,
      'automatic': true,
      'aiCalls': 0,
      'battleAuthority': 'aveluneNative',
      'sourceBattleScriptsExecuted': false,
      'playableCertified': false,
      'operationIds':
          mutations.map((entry) => entry.operationId.value).toList(),
    };
    final artifacts = {
      for (final entry in [
        ...base.artifacts,
        ...projection.artifacts,
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
    if (artifacts.length + witnesses.length > limits.maxArtifacts) {
      throw NativeWriteException('catalogs.artifacts.quota',
          'Catalog composition requires ${artifacts.length + witnesses.length} artifacts (${artifacts.length} output, ${witnesses.length} source); the admitted limit is ${limits.maxArtifacts}.');
    }
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
            mutations: _mergeCatalogMutations(base.mutations, mutations),
            compositionEvidence: {
              ...base.compositionEvidence,
              'sourceCatalogs': evidence
            },
            defaultMapWidth: base.defaultMapWidth,
            defaultMapHeight: base.defaultMapHeight,
            limits: limits));
  }
}

List<NativeMutation> _mergeCatalogMutations(
    List<NativeMutation> base, List<NativeMutation> catalogs) {
  final declarations = {
    for (final mutation in catalogs)
      if (mutation.actionId == 'campaign.trainer.upsert')
        (mutation.parameters['value'] as Map)['id'] as String: mutation
  };
  final consumed = <String>{};
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
      references.addAll(scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneBattlePayload>()
          .map((payload) => payload.trainerId));
    }
    for (final reference in references) {
      if (declarations.containsKey(reference)) {
        consumed.add(reference!);
        if (insertionIndex < 0) insertionIndex = index;
      }
    }
  }
  if (insertionIndex < 0) return [...base, ...catalogs];
  final promoted = {
    for (final entry in declarations.entries)
      if (consumed.contains(entry.key)) entry.value.operationId
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

({List<String> items, List<SourcePbsIdentity> trainers}) _catalogSelection(
    NormalizedSourceProject source, Set<int> mapIds) {
  final items = <String>{};
  final trainers = <String, SourcePbsIdentity>{};
  for (final map
      in source.maps.where((entry) => mapIds.contains(entry.map.sourceMapId))) {
    for (final event in map.map.events) {
      for (final page in event.pages) {
        for (final command in page.commands) {
          String? text;
          if (command.code == 355 &&
              command.parameters.length == 1 &&
              command.parameters.single is String) {
            text = command.parameters.single as String;
          } else if (command.code == 111 &&
              command.parameters.length == 2 &&
              command.parameters.first == 12 &&
              command.parameters.last is String) {
            text = command.parameters.last as String;
          }
          if (text == null) continue;
          final call = _CatalogLiteralCall.read(text);
          if (call == null || call.arguments.isEmpty) continue;
          final first = call.arguments.first;
          if (first.$1 != 'symbol') continue;
          if ((call.name == 'pbItemBall' || call.name == 'pbReceiveItem') &&
              (call.arguments.length == 1 ||
                  (call.arguments.length == 2 &&
                      call.arguments[1].$1 == 'integer'))) {
            items.add(first.$2);
          } else if ((call.name == 'TrainerBattle.start' ||
                  (call.name == 'pbTrainerBattle' &&
                      call.arguments.length == 2)) &&
              call.arguments.length >= 2 &&
              call.arguments.length <= 3 &&
              call.arguments[1].$1 == 'string' &&
              (call.arguments.length == 2 ||
                  call.arguments[2].$1 == 'integer')) {
            final identity = SourcePbsIdentity(
                namespace: source.snapshot.logicalProjectNamespace,
                family: SourcePbsFamily.trainers,
                trainerType: first.$2,
                trainerName: call.arguments[1].$2,
                version: call.arguments.length == 3
                    ? int.parse(call.arguments[2].$2)
                    : 0);
            trainers[identity.key] = identity;
          }
        }
      }
    }
  }
  return (
    items: items.toList()..sort(),
    trainers: trainers.values.toList()..sort((a, b) => a.key.compareTo(b.key))
  );
}

final class _CatalogLiteralCall {
  const _CatalogLiteralCall(this.name, this.arguments);
  final String name;
  final List<(String, String)> arguments;

  static _CatalogLiteralCall? read(String text) {
    final match = RegExp(
            r'^(pbItemBall|pbReceiveItem|pbTrainerBattle|TrainerBattle\.start)\s*\((.*)\)$',
            dotAll: true)
        .firstMatch(text.trim());
    if (match == null) return null;
    final body = match[2]!;
    final arguments = <(String, String)>[];
    var offset = 0;
    void space() {
      while (offset < body.length && RegExp(r'\s').hasMatch(body[offset])) {
        offset++;
      }
    }

    while (offset < body.length) {
      space();
      if (offset == body.length) return null;
      final unit = body[offset];
      if (unit == ':') {
        offset++;
        final symbol = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*')
            .firstMatch(body.substring(offset));
        if (symbol == null) return null;
        arguments.add(('symbol', symbol[0]!));
        offset += symbol[0]!.length;
      } else if (unit == '"' || unit == "'") {
        offset++;
        final value = StringBuffer();
        var ended = false;
        while (offset < body.length) {
          final character = body[offset++];
          if (character == unit) {
            ended = true;
            break;
          }
          if (character == r'\') {
            return null;
          } else {
            value.write(character);
          }
        }
        final literal = value.toString();
        if (!ended ||
            (unit == '"' &&
                (literal.contains(r'#{') ||
                    literal.contains('#@') ||
                    literal.contains(r'#$')))) {
          return null;
        }
        arguments.add(('string', literal));
      } else {
        final integer =
            RegExp(r'^(0|[1-9][0-9]{0,9})').firstMatch(body.substring(offset));
        if (integer == null || int.parse(integer[0]!) > 2147483647) return null;
        arguments.add(('integer', integer[0]!));
        offset += integer[0]!.length;
      }
      space();
      if (offset == body.length) break;
      if (body[offset++] != ',') return null;
      space();
      if (offset == body.length || arguments.length >= 3) return null;
    }
    return _CatalogLiteralCall(match[1]!, List.unmodifiable(arguments));
  }
}
