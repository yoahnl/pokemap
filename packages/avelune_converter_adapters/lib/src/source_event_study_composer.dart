import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';
import 'source_event_character_import.dart';
import 'source_event_item_bindings.dart';
import 'source_pickup_feedback_binding.dart';
import 'source_semantic_study_composer.dart';

final class SourceEventStudyComposition {
  const SourceEventStudyComposition(
      {required this.draft, required this.projection});
  final NativeProjectDraft draft;
  final SourceEventProjection projection;
}

final class SourceEventStudyComposer {
  const SourceEventStudyComposer();

  Future<SourceEventStudyComposition?> compose({
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
        !base.compositionEvidence.containsKey('sourceSemantics')) {
      return null;
    }
    if (base.source.canonicalHash != source.canonicalHash ||
        base.compositionEvidence.containsKey('sourceEvents') ||
        base.compositionEvidence.containsKey('assetLibrary')) {
      throw const NativeWriteException('events.base.binding',
          'Event composition requires one exact source semantic draft before asset review merging');
    }
    final nativeMaps = <int, MapData>{};
    for (final mutation
        in base.mutations.where((entry) => entry.actionId == 'map.save')) {
      final map = MapData.fromJson(
          Map<String, dynamic>.from(mutation.parameters['map'] as Map));
      final sourceId =
          base.mapIds.entries.singleWhere((entry) => entry.value == map.id).key;
      nativeMaps[sourceId] = map;
    }
    if (nativeMaps.length != base.mapIds.length) {
      throw const NativeWriteException('events.base.maps',
          'Every event destination requires its exact preceding native map');
    }
    final analysis =
        SourceEventAnalyzer.forProject(source, profile: profile).analyze();
    final selectedEvents = analysis.events
        .where((event) => nativeMaps.containsKey(event.sourceMapId))
        .toList();
    final recording = SourceSemanticWitnessFiles(
        source.snapshot, files, limits, cancellation);
    final witnessPaths = {
      'Data/Scripts.rxdata',
      'Data/System.rxdata',
      for (final event in selectedEvents)
        source.snapshot.entries
            .singleWhere((entry) => entry.fileId == event.sourceFileId)
            .relativePath,
    };
    for (final entry in source.snapshot.entries
        .where((entry) => witnessPaths.contains(entry.relativePath))) {
      await recording.read(entry.fileId);
    }
    final pickupBindings = <String, SourcePickupFeedbackBinding>{};
    final pickupEvidence = <Map<String, Object?>>[];
    SourceEventItemBindings? items;
    final pickups = <(int, String)>{
      for (final event in selectedEvents.where((entry) => !entry.isQuarantined))
        for (final page in event.pages)
          for (final pickup in _pickups(page.body))
            (event.sourceMapId, pickup.sourceSymbol)
    }.toList()
      ..sort(
          (a, b) => a.$1 == b.$1 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    if (pickups.isNotEmpty) {
      try {
        items = await const SourceEventItemBindingResolver().read(
            snapshot: source.snapshot,
            files: recording,
            symbols: pickups.map((entry) => entry.$2),
            eventProfile: profile,
            cancellation: cancellation);
        for (final pickup in pickups) {
          final item = items.bindings[pickup.$2];
          if (item == null) {
            continue;
          }
          final key = sourcePickupFeedbackBindingKey(
              sourceMapId: pickup.$1, sourceSymbol: pickup.$2);
          try {
            final binding = await const SourcePickupFeedbackResolver().read(
                source: source,
                files: recording,
                item: item,
                sourceMapId: pickup.$1,
                limits: limits,
                cancellation: cancellation);
            pickupBindings[key] = binding;
            pickupEvidence.add(
                {'bindingKey': key, 'status': 'imported', ...binding.evidence});
          } on SourcePickupBindingUnavailable catch (error) {
            pickupEvidence.add({
              'bindingKey': key,
              'status': 'preservedOnly',
              'reason': error.reason
            });
          }
        }
      } on ContractError catch (error) {
        cancellation?.check();
        if (error.code.contains('quota') ||
            error.code.contains('limit') ||
            error.code.contains('changed') ||
            error.code.contains('hash')) {
          rethrow;
        }
        pickupEvidence.add({'status': 'preservedOnly', 'code': error.code});
      }
    }
    final bindings = <String, SourceEventCharacterBinding>{};
    final characterArtifacts = <NativeArtifact>[];
    final characterMutations = <NativeMutation>[];
    final characterEvidence = <Map<String, Object?>>[];
    final visited = <String>{};
    final characterCandidates = const SourceEventProjector()
        .characterImportCandidates(
            source: source,
            analysis: analysis,
            nativeMaps: nativeMaps,
            pickupBindings: pickupBindings,
            limits: limits);
    for (final event in characterCandidates) {
      for (final page in event.pages) {
        cancellation?.check();
        final graphic = page.graphic;
        if (graphic == null || graphic.characterName.isEmpty) continue;
        final key = sourceEventCharacterBindingKey(
            characterName: graphic.characterName,
            pattern: graphic.pattern,
            direction: graphic.direction);
        if (!visited.add(key)) continue;
        try {
          final imported = await const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: recording,
              charsetName: graphic.characterName,
              sourcePattern: graphic.pattern,
              sourceDirection: graphic.direction,
              limits: limits,
              cancellation: cancellation);
          bindings[key] = imported.binding;
          characterArtifacts.addAll(imported.artifacts);
          characterMutations.addAll(imported.mutations);
          characterEvidence.add(
              {'bindingKey': key, 'status': 'imported', ...imported.evidence});
        } on NativeWriteException catch (error) {
          cancellation?.check();
          if (error.code.contains('quota') ||
              error.code.contains('limit') ||
              error.code.contains('changed') ||
              error.code.contains('hash')) {
            rethrow;
          }
          characterEvidence.add({
            'bindingKey': key,
            'status': 'preservedOnly',
            'code': error.code
          });
        } on ContractError catch (error) {
          cancellation?.check();
          if (error.code.contains('quota') ||
              error.code.contains('limit') ||
              error.code.contains('changed') ||
              error.code.contains('hash')) {
            rethrow;
          }
          characterEvidence.add({
            'bindingKey': key,
            'status': 'preservedOnly',
            'code': error.code
          });
        }
      }
    }
    final projection = const SourceEventProjector().project(
        source: source,
        analysis: analysis,
        nativeMaps: nativeMaps,
        characterBindings: bindings,
        pickupBindings: pickupBindings,
        limits: limits);
    final usedPickupBindingKeys =
        (projection.semanticEvidence['usedPickupBindingKeys'] as List)
            .cast<String>()
            .toSet();
    final usedPickupBindings = pickupBindings.entries
        .where((entry) => usedPickupBindingKeys.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    final pickupArtifacts =
        usedPickupBindings.expand((entry) => entry.artifacts).toList();
    final pickupMutations =
        usedPickupBindings.expand((entry) => entry.mutations).toList();
    final owners = selectedEvents
        .map((event) => event.sourceFileId)
        .toSet()
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (owners.isEmpty) {
      owners.add(source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata')
          .fileId);
    }
    final preservedFileIds =
        selectedEvents.map((event) => event.sourceFileId.value).toSet();
    final systemFile = source.snapshot.entries
        .where((entry) => entry.relativePath == 'Data/System.rxdata')
        .firstOrNull;
    if (systemFile != null) preservedFileIds.add(systemFile.fileId.value);
    preservedFileIds.addAll(recording.evidence
        .where((entry) => const {
              'Data/items.dat',
              'Data/map_metadata.dat',
              'Graphics/Windowskins/speech hgss 1.png'
            }.contains(entry['relativePath']))
        .map((entry) => entry['fileId'] as String));
    final catalogMutations = <NativeMutation>[];
    if (projection.itemCatalog != null) {
      final config = const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1);
      final catalogPath = config.catalogFiles['items']!;
      final empty = const ProjectItemCatalog(schemaVersion: 1, entries: []);
      final catalogId = canonicalHashOf(projection.itemCatalog!.toJson())
          .value
          .substring(0, 24);
      catalogMutations.addAll([
        NativeMutation(
            operationId: ConverterId('ac13_items_enabled_$catalogId'),
            actionId: 'pokemon.configuration.set_enabled',
            sourceEntityIds: owners,
            targetEntityIds: [ConverterId('source_items')],
            parameters: {'enabled': true},
            limits: limits),
        NativeMutation(
            operationId: ConverterId('ac13_items_catalog_$catalogId'),
            actionId: 'pokemon.catalog.write',
            sourceEntityIds: owners,
            targetEntityIds: [ConverterId('source_items')],
            parameters: {
              'relativePath': catalogPath,
              'document': empty.toJson()
            },
            limits: limits),
        for (final item in projection.itemCatalog!.entries)
          NativeMutation(
              operationId: ConverterId('ac13_item_${item.id}'),
              actionId: 'item.create',
              sourceEntityIds: owners,
              targetEntityIds: [ConverterId(item.id)],
              parameters: {'definition': item.toJson()},
              limits: limits),
      ]);
    }
    final preservedArtifacts = <String, NativeArtifact>{};
    final preservedMutations = <NativeMutation>[];
    final preservedFiles = <Map<String, Object?>>[];
    for (final witness in recording.evidence
        .where((entry) => preservedFileIds.contains(entry['fileId']))) {
      final chunks = <Map<String, Object?>>[];
      final sourceChunks = <(NativeArtifact, int, int)>[];
      if (witness['encoding'] == 'png') {
        final original = recording.artifacts[witness['artifactHandle']]!;
        final bytes = original.bytes;
        for (var offset = 0;
            offset < bytes.length;
            offset += SourceSemanticWitnessFiles.chunkSize) {
          cancellation?.check();
          final end =
              offset + SourceSemanticWitnessFiles.chunkSize < bytes.length
                  ? offset + SourceSemanticWitnessFiles.chunkSize
                  : bytes.length;
          final artifact = NativeArtifact(
              bytes: utf8.encode(canonicalJsonOf({
                'kind': 'sourceSemanticByteChunk',
                'version': 1,
                'offset': offset,
                'bytesBase64': base64Encode(bytes.sublist(offset, end)),
              }, limits: limits.jsonLimits)),
              mediaType: 'application/json',
              limits: limits);
          sourceChunks.add((artifact, offset, end - offset));
        }
      } else {
        for (final chunk in witness['chunks'] as List) {
          sourceChunks.add((
            recording.artifacts[(chunk as Map)['artifactHandle']]!,
            chunk['offset'] as int,
            chunk['byteLength'] as int
          ));
        }
      }
      for (final chunk in sourceChunks) {
        final artifact = chunk.$1;
        final id =
            'ac13_source_chunk_${artifact.rawSha256.value.substring(0, 24)}';
        final logicalPath = 'assets/converter/$id.json';
        chunks.add({
          'artifactHandle': artifact.handle,
          'offset': chunk.$2,
          'byteLength': chunk.$3,
          'assetId': id,
          'logicalPath': logicalPath
        });
        if (preservedArtifacts.containsKey(artifact.handle)) continue;
        preservedArtifacts[artifact.handle] = artifact;
        preservedMutations.add(NativeMutation(
            operationId:
                ConverterId('ac13_source_chunk_${artifact.rawSha256.value}'),
            actionId: 'asset.import',
            sourceEntityIds: owners,
            targetEntityIds: [ConverterId(id)],
            parameters: {
              'artifactHandle': artifact.handle,
              'assetId': id,
              'logicalPath': logicalPath,
              'tags': ['preserved-source-bytes'],
              'usages': ['converter.sourceEventBytes'],
            },
            limits: limits));
      }
      final preserved = Map<String, Object?>.from(witness)
        ..remove('artifactHandle');
      preservedFiles.add({
        ...preserved,
        'encoding': 'canonicalJsonBase64Chunks',
        'chunks': chunks
      });
    }
    final companion = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({
          ...projection.semanticEvidence,
          'preservedSourceFiles': preservedFiles,
        }, limits: limits.jsonLimits)),
        mediaType: 'application/json',
        limits: limits);
    final companionId =
        'ac13_events_${companion.rawSha256.value.substring(0, 24)}';
    final companionMutation = NativeMutation(
        operationId:
            ConverterId('ac13_events_companion_${companion.rawSha256.value}'),
        actionId: 'asset.import',
        sourceEntityIds: owners,
        targetEntityIds: [ConverterId(companionId)],
        parameters: {
          'artifactHandle': companion.handle,
          'assetId': companionId,
          'logicalPath': 'assets/converter/$companionId.json',
          'tags': ['source-events', 'preserved-source-provenance'],
          'usages': ['converter.sourceEvents'],
        },
        limits: limits);
    final artifacts = {
      for (final entry in [
        ...base.artifacts,
        ...characterArtifacts,
        ...pickupArtifacts,
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
    final importedMutations = <NativeMutation>[];
    final operations = <ConverterId, NativeMutation>{};
    for (final entry in [
      ...characterMutations,
      ...pickupMutations,
      ...catalogMutations
    ]) {
      final prior = operations[entry.operationId];
      if (prior != null) {
        if (canonicalJsonOf(prior.toJson(0)) !=
            canonicalJsonOf(entry.toJson(0))) {
          throw const NativeWriteException('events.character.identity',
              'One source character operation cannot address conflicting imports');
        }
      } else {
        operations[entry.operationId] = entry;
        importedMutations.add(entry);
      }
    }
    final eventMutations = [
      ...preservedMutations,
      companionMutation,
      ...projection.mutations
    ];
    final evidence = {
      'kind': 'sourceEventStudy',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'profile': profile.toJson(),
      'projection': projection.semanticEvidence,
      'characters': characterEvidence,
      'items': items?.evidence,
      'pickups': pickupEvidence,
      'witnesses': recording.evidence,
      'actorDepthParityQualified': false,
      'actorDepthParityStatus':
          bindings.isEmpty ? 'notApplicable' : 'unqualified',
      'automatic': true,
      'aiCalls': 0,
      'playableCertified': false,
      'operationIds': [...importedMutations, ...eventMutations]
          .map((entry) => entry.operationId.value)
          .toList(),
    };
    return SourceEventStudyComposition(
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
            mutations: [
              ...base.mutations
                  .where((entry) => !entry.actionId.startsWith('map.')),
              ...importedMutations,
              ...base.mutations
                  .where((entry) => entry.actionId.startsWith('map.')),
              ...eventMutations,
            ],
            compositionEvidence: {
              ...base.compositionEvidence,
              'sourceEvents': evidence
            },
            defaultMapWidth: base.defaultMapWidth,
            defaultMapHeight: base.defaultMapHeight,
            limits: limits));
  }
}

Iterable<SourcePickupNode> _pickups(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    switch (node) {
      case SourceConditionalNode():
        if (node.condition.pickup != null) yield node.condition.pickup!;
        yield* _pickups(node.whenTrue);
        yield* _pickups(node.whenFalse);
      case SourceTextNode():
        final choice = node.followingChoice;
        if (choice != null) {
          for (final branch in choice.branches) {
            yield* _pickups(branch.body);
          }
          if (choice.cancelBranch != null) {
            yield* _pickups(choice.cancelBranch!);
          }
        }
      case SourceChoiceNode():
        for (final branch in node.branches) {
          yield* _pickups(branch.body);
        }
        if (node.cancelBranch != null) yield* _pickups(node.cancelBranch!);
      default:
        break;
    }
  }
}
