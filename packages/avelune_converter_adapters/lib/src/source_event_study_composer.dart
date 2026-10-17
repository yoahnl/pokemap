import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';
import 'source_center_recovery_binding.dart';
import 'source_event_execution_context.dart';
import 'source_event_sound_binding.dart';
import 'source_event_character_import.dart';
import 'source_event_item_bindings.dart';
import 'source_pickup_feedback_binding.dart';
import 'source_trainer_event_bindings.dart';
import 'source_pokedex_reward_binding.dart';
import 'source_town_map_binding.dart';
import 'source_field_obstacle_binding.dart';
import 'source_party_trade_binding.dart';
import 'source_healing_display_binding.dart';
import 'source_external_warp_binding.dart';
import 'source_map_music_binding.dart';
import 'source_semantic_study_composer.dart';
import 'source_connection_study_composer.dart';
import 'source_directed_jump_study_composer.dart';

final class SourceEventStudyComposition {
  const SourceEventStudyComposition(
      {required this.draft,
      required this.projection,
      this.musicBindings = const {}});
  final NativeProjectDraft draft;
  final SourceEventProjection projection;
  final Map<int, SourceMapMusicBinding> musicBindings;
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
    final recording = SourceSemanticWitnessFiles(
        source.snapshot, files, limits, cancellation);
    final connections = await const SourceConnectionStudyComposer().compose(
        source: source, nativeMaps: nativeMaps, files: recording,
        limits: limits, cancellation: cancellation);
    final baseConnections = base.mutations.where((entry) =>
        entry.actionId == 'connection.create_bidirectional_apply').toList();
    if (canonicalJsonOf([for (var i = 0; i < baseConnections.length; i++)
          baseConnections[i].toJson(i)], limits: limits.jsonLimits) !=
        canonicalJsonOf([for (var i = 0; i < connections.mutations.length; i++)
          connections.mutations[i].toJson(i)], limits: limits.jsonLimits)) {
      throw const NativeWriteException('events.base.connections',
          'Event maps require the exact preceding source connections');
    }
    nativeMaps.addAll(connections.nativeMaps);
    var borderProject = sourceSemanticNativeProject(draft: base, maps: nativeMaps,
        mutations: base.mutations, limits: limits);
    var borderResources = SourceBorderReplayResources();
    for (final mutation in base.mutations.where((entry) =>
        entry.actionId.startsWith('border.') || entry.actionId.startsWith('border_layer.'))) {
      final replay = await replaySourceBorderMutation(project: borderProject,
          resources: borderResources,
          maps: {for (final map in nativeMaps.values) map.id: map}, mutation: mutation,
          artifacts: base.artifacts, limits: limits, cancellation: cancellation);
      borderProject = replay.project;
      borderResources = replay.resources;
      for (final entry in base.mapIds.entries) { nativeMaps[entry.key] = replay.maps[entry.value]!; }
    }
    ProjectValidator.validate(borderProject, maps: nativeMaps.values);
    for (final map in nativeMaps.values) { MapValidator.validate(map, projectDialogueContext: borderProject); }

    final analysis =
        SourceEventAnalyzer.forProject(source, profile: profile).analyze();
    final selectedEvents = analysis.events
        .where((event) => nativeMaps.containsKey(event.sourceMapId))
        .toList();
    final originalDoorIds = sourceDoorEventProjectionCandidates(source: source, analysis: analysis)
        .where((event) => nativeMaps.containsKey(event.sourceMapId))
        .map((event) => event.identity).toSet();
    SourceExternalWarpBinding? externalWarps;
    final externalWarpEvidence = <Map<String, Object?>>[];
    try {
      externalWarps = await const SourceExternalWarpBindingResolver().read(
          source: source, analysis: analysis, files: recording,
          policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState,
          limits: limits, cancellation: cancellation);
      if (externalWarps != null) externalWarpEvidence.add({'status': 'attested', ...externalWarps.evidence});
    } on SourceExternalWarpBindingUnavailable catch (error) {
      externalWarpEvidence.add({'status': 'preservedOnly', 'reason': error.reason});
    }
    final transitionIds = {...originalDoorIds, ...?externalWarps?.programs.keys};
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
    final itemGiverMapIds = {
      for (final event in selectedEvents.where((event) => !event.isQuarantined))
        if (event.pages.any((page) => _pickups(page.body).any(
            (pickup) => pickup.helper == SourceItemGrantHelper.receiveItem))) event.sourceMapId,
    };
    final musicBindings = <int, SourceMapMusicBinding>{};
    final musicEvidence = <Map<String, Object?>>[];
    final musicMapIds = nativeMaps.keys.toList()..sort();
    for (final sourceMapId in musicMapIds) {
      try {
        final binding = await const SourceMapMusicResolver().read(
            source: source,
            files: recording,
            sourceMapId: sourceMapId,
            policy: itemGiverMapIds.contains(sourceMapId)
                ? SourceMapMusicPolicy.nativeAuthoredVolume : SourceMapMusicPolicy.sourceEngineGain,
            limits: limits,
            cancellation: cancellation);
        if (binding == null) continue;
        musicBindings[sourceMapId] = binding;
        musicEvidence.add({'status': 'imported', ...binding.evidence});
        final map = nativeMaps[sourceMapId]!;
        nativeMaps[sourceMapId] = map.copyWith(
            mapMetadata: map.mapMetadata.copyWith(
                musicPath: binding.mapMusicPath,
                musicVolume: binding.nativeVolume));
      } on SourceMapMusicBindingUnavailable catch (error) {
        musicEvidence.add({
          'sourceMapId': sourceMapId,
          'status': 'preservedOnly',
          'reason': error.reason
        });
      }
    }
    final pickupBindings = <String, SourcePickupFeedbackBinding>{};
    final pickupEvidence = <Map<String, Object?>>[];
    SourceEventItemBindings? items;
    final pickups = <(int, String, SourceItemGrantHelper)>{
      for (final event in selectedEvents.where((entry) => !entry.isQuarantined))
        for (final page in event.pages)
          for (final pickup in _pickups(page.body))
            (event.sourceMapId, pickup.sourceSymbol, pickup.helper)
    }.toList()
      ..sort(
          (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1)
              : a.$2 != b.$2 ? a.$2.compareTo(b.$2)
              : a.$3.name.compareTo(b.$3.name));
    final itemSymbols = {
      for (final event in selectedEvents.where((entry) => !entry.isQuarantined))
        for (final page in event.pages) ..._itemSymbols(page.body),
    };
    if (itemSymbols.isNotEmpty) {
      try {
        items = await const SourceEventItemBindingResolver().read(
            snapshot: source.snapshot,
            files: recording,
            symbols: itemSymbols,
            eventProfile: profile,
            cancellation: cancellation);
        for (final pickup in pickups) {
          final item = items.bindings[pickup.$2];
          if (item == null) {
            continue;
          }
          final key = sourcePickupFeedbackBindingKey(
              sourceMapId: pickup.$1, sourceSymbol: pickup.$2, helper: pickup.$3);
          try {
            final binding = await const SourcePickupFeedbackResolver().read(
                source: source,
                files: recording,
                item: item,
                sourceMapId: pickup.$1,
                helper: pickup.$3,
                music: musicBindings[pickup.$1],
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
    final transitionSounds = {
      for (final event in selectedEvents.where((event) => !event.isQuarantined &&
          transitionIds.contains(event.identity)))
        for (final page in event.pages) ..._soundNames(page.body),
    };
    final sounds = <String, SourceEventSoundBinding>{};
    final soundEvidence = <Map<String, Object?>>[];
    for (final name in {
      for (final event in selectedEvents.where((event) => !event.isQuarantined &&
          (transitionIds.contains(event.identity) || event.pages.any((page) =>
              _pickups(page.body).any((pickup) => pickup.helper == SourceItemGrantHelper.receiveItem)))))
        for (final page in event.pages) ..._soundNames(page.body),
    }.toList()..sort()) {
      try {
        final binding = await const SourceEventSoundResolver().read(
          source: source, files: recording, name: name, limits: limits,
          policy: transitionSounds.contains(name) ? SourceEventSoundPolicy.sourceEngineGain
              : SourceEventSoundPolicy.nativeAuthoredVolume,
          cancellation: cancellation);
        sounds[name] = binding;
        soundEvidence.add({'sourceName': name, 'status': 'imported', ...binding.evidence});
      } on SourceEventSoundBindingUnavailable catch (error) {
        soundEvidence.add({'sourceName': name, 'status': 'preservedOnly', 'reason': error.reason});
      }
    }
    SourceCenterRecoveryBinding? centerRecovery;
    final centerRecoveryEvidence = <Map<String, Object?>>[];
    if (selectedEvents.any((event) => event.sourceMapId == 102 && event.sourceEventId == 2)) {
      try {
        centerRecovery = await const SourceCenterRecoveryResolver().read(
            source: source, files: recording, limits: limits, cancellation: cancellation);
        centerRecoveryEvidence.add({'status': 'attested', ...centerRecovery.evidence});
      } on SourceCenterRecoveryBindingUnavailable catch (error) {
        centerRecoveryEvidence.add({'status': 'preservedOnly', 'reason': error.reason});
      }
    }
    SourceHealingDisplayBinding? healingDisplay;
    final healingDisplayEvidence = <Map<String, Object?>>[];
    try {
      healingDisplay = await const SourceHealingDisplayBindingResolver().read(
          source: source, analysis: analysis, files: recording,
          limits: limits, cancellation: cancellation);
      if (healingDisplay != null) {
        healingDisplayEvidence.add({'status': 'attested', ...healingDisplay.evidence});
      }
    } on SourceHealingDisplayBindingUnavailable catch (error) {
      healingDisplayEvidence.add({'status': 'preservedOnly', 'reason': error.reason});
    }
    final trainerBindings = await const SourceTrainerEventBindingResolver().read(
        source: source, analysis: analysis, files: recording,
        limits: limits, cancellation: cancellation);
    final pokedexReward = await const SourcePokedexRewardBindingResolver().read(
        source: source, analysis: analysis, files: recording, cancellation: cancellation);
    final partyTrade = const SourcePartyTradeBindingResolver().resolve(source: source, analysis: analysis,
        visualPolicy: SourcePartyTradeVisualPolicy.nativeWoman2ForExactGuard);
    SourceTownMapBinding? townMap;
    if(selectedEvents.any((event)=>event.pages.expand((page)=>page.body.nodes).any((node)=>node is SourceTownMapProgramNode))) {
      try {
        townMap=await const SourceTownMapBindingResolver().read(source:source,files:recording,
          nativeMapIds:{for(final entry in nativeMaps.entries)entry.key:entry.value.id},limits:limits,cancellation:cancellation);
      } on SourceTownMapBindingUnavailable {
        townMap=null;
      }
    }
    SourceFieldObstacleBindings? fieldObstacles;
    final fieldBindingEvidence = <Map<String, Object?>>[];
    try {
      fieldObstacles = await const SourceFieldObstacleBindingResolver().read(
          source: source, analysis: analysis, files: recording,
          sourceMapIds: nativeMaps.keys.toSet(),
          limits: limits, cancellation: cancellation);
      if (fieldObstacles != null) {
        fieldBindingEvidence.add({'status': 'attested', ...fieldObstacles.evidence});
      }
    } on SourceFieldObstacleBindingUnavailable catch (error) {
      fieldBindingEvidence.add({'status': 'preservedOnly', 'reason': error.reason});
    }
    final bindings = <String, SourceEventCharacterBinding>{};
    final retentionBinding = transitionIds.isNotEmpty
      ? await _sourceEventMapRetentionBinding(source: source, files: recording,
          nativeMapIds: base.mapIds, cancellation: cancellation) : null;
    final retentionPolicy = retentionBinding?.policy;
    final executionContext = transitionIds.isEmpty ? null :
        await const SourceEventExecutionContextResolver().read(source: source,
          base: base, nativeMaps: nativeMaps, files: recording, limits: limits,
          cancellation: cancellation);
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
            itemBindings: items?.bindings ?? const {},
            soundBindings: sounds,
            centerRecoveryBinding: centerRecovery,
            trainerBindings: trainerBindings.byEventIdentity,
            pokedexRewardBinding: pokedexReward,
            townMapBinding: townMap,
            partyTradeBinding: partyTrade,
            healingDisplayBinding: healingDisplay,
            externalWarpBinding: externalWarps,
            fieldObstacleBindings: fieldObstacles?.byEventIdentity ?? const {},
            fieldObstacleRefusals: fieldObstacles?.refusals ?? const {},
            retentionPolicy: retentionPolicy,
            executionContext: executionContext,
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
        final visualAdaptation = partyTrade != null &&
                partyTrade.isBoundToEvent(source: source, analysis: analysis, event: event)
            ? partyTrade.visualAdaptation : null;
        try {
          final imported = await const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: recording,
              charsetName: visualAdaptation?.actualCharsetName ?? graphic.characterName,
              sourcePattern: graphic.pattern,
              sourceDirection: graphic.direction,
              limits: limits,
              cancellation: cancellation);
          bindings[key] = imported.binding;
          characterArtifacts.addAll(imported.artifacts);
          characterMutations.addAll(imported.mutations);
          characterEvidence.add(
              {'bindingKey': key, 'status': 'imported', ...imported.evidence,
                'requestedGraphic': graphic.characterName,
                if (visualAdaptation != null) 'visualAdaptation': visualAdaptation.toJson()});
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
        itemBindings: items?.bindings ?? const {},
        soundBindings: sounds,
        centerRecoveryBinding: centerRecovery,
        trainerBindings: trainerBindings.byEventIdentity,
            pokedexRewardBinding: pokedexReward,
            townMapBinding: townMap,
            partyTradeBinding: partyTrade,
            healingDisplayBinding: healingDisplay,
            externalWarpBinding: externalWarps,
            fieldObstacleBindings: fieldObstacles?.byEventIdentity ?? const {},
            fieldObstacleRefusals: fieldObstacles?.refusals ?? const {},
        retentionPolicy: retentionPolicy,
        executionContext: executionContext,
        limits: limits);
    final usedExternalWarps = projection.semanticEvidence['usedExternalWarps'] == true
        ? externalWarps : null;
    final usedHealingDisplay = projection.semanticEvidence['usedHealingDisplay'] == true
        ? healingDisplay : null;
    final usedCenterRecovery = projection.semanticEvidence['usedCenterRecovery'] == true
        ? centerRecovery : null;
    final usedPickupBindingKeys =
        (projection.semanticEvidence['usedPickupBindingKeys'] as List)
            .cast<String>()
            .toSet();
    final usedTownMap=projection.semanticEvidence['usedTownMap']==true?townMap:null;
    final usedFieldObstacles = projection.semanticEvidence['usedFieldObstacles'] == true
        ? fieldObstacles : null;
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
    if (usedExternalWarps != null) {
      preservedFileIds.addAll(usedExternalWarps.files.map((file) => file.fileId.value));
    }
    preservedFileIds.addAll(trainerBindings.byEventIdentity.values
        .map((binding) => binding.sourceRosterFile.fileId.value));
    if (pokedexReward != null) {
      preservedFileIds.addAll(pokedexReward.archive.files.keys.map((id) => id.value));
      preservedFileIds.addAll(pokedexReward.itemArchive.files.keys.map((id) => id.value));
    }
    if(usedTownMap!=null) {
      preservedFileIds.addAll((usedTownMap.evidence['sourceFiles'] as List).cast<Map>().map((file)=>file['fileId'] as String));
    }
    if (usedFieldObstacles != null) {
      preservedFileIds.addAll((usedFieldObstacles.evidence['sourceFiles'] as List)
          .cast<Map>().map((file) => file['fileId'] as String));
    }
    if (usedHealingDisplay != null) {
      preservedFileIds.addAll((usedHealingDisplay.evidence['sourceImages'] as List)
          .cast<Map>().map((file) => file['fileId'] as String));
    }
    final systemFile = source.snapshot.entries
        .where((entry) => entry.relativePath == 'Data/System.rxdata')
        .firstOrNull;
    if (systemFile != null) preservedFileIds.add(systemFile.fileId.value);
    preservedFileIds.addAll(recording.evidence
        .where((entry) => const {
              'Data/items.dat',
              'Data/map_metadata.dat',
              'Data/PluginScripts.rxdata',
              'Data/CommonEvents.rxdata',
              'Graphics/Windowskins/speech hgss 1.png'
            }.contains(entry['relativePath']) ||
            (executionContext != null &&
                (entry['relativePath'] == 'Data/map_connections.dat' ||
                    RegExp(r'^Data/Map\d+\.rxdata$')
                        .hasMatch(entry['relativePath'] as String))))
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
        if(usedTownMap!=null)usedTownMap.artifact,
        if (usedFieldObstacles != null) ...usedFieldObstacles.artifacts,
        ...characterArtifacts,
        if (usedHealingDisplay != null) ...usedHealingDisplay.artifacts,
        if (usedExternalWarps != null) ...usedExternalWarps.artifacts,
        if (usedCenterRecovery != null) usedCenterRecovery.artifact,
        ...pickupArtifacts,
        ...sounds.values.map((binding) => binding.artifact),
        ...musicBindings.values.expand((entry) => entry.artifacts),
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
      if (usedExternalWarps != null) ...usedExternalWarps.mutations,
      ...characterMutations,
      if (usedHealingDisplay != null) ...usedHealingDisplay.mutations,
      if (usedFieldObstacles != null) ...usedFieldObstacles.mutations,
      if (usedTownMap != null)
        ...usedTownMap.mutations.where((entry) => entry.actionId == 'asset.import'),
      if (usedCenterRecovery != null) usedCenterRecovery.mutation,
      ...pickupMutations,
      ...sounds.values.map((binding) => binding.mutation),
      ...musicBindings.values.expand((entry) => entry.importMutations),
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
      if (usedTownMap != null)
        ...usedTownMap.mutations.where((entry) => entry.actionId != 'asset.import'),
      for (final sourceMapId in musicMapIds)
        if (musicBindings.containsKey(sourceMapId))
          musicBindings[sourceMapId]!
              .mapMutation(nativeMapId: base.mapIds[sourceMapId]!),
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
      'diagnostics': {
        for (final binding in usedPickupBindings)
          for (final diagnostic in (binding.evidence['diagnostics'] as List? ?? const []).cast<Map>())
            canonicalJsonOf(diagnostic): diagnostic,
      }.values.toList(),
      'sounds': soundEvidence,
      'externalWarpBindings': externalWarpEvidence,
      if (usedExternalWarps != null) 'externalWarps': usedExternalWarps.evidence,
      'centerRecovery': centerRecoveryEvidence,
      'healingDisplayBindings': healingDisplayEvidence,
      if (usedHealingDisplay != null) 'healingDisplay': usedHealingDisplay.evidence,
      'pokedexRewardBinding': pokedexReward?.toJson(),
      if(usedTownMap!=null)'townMap':usedTownMap.evidence,
      if (projection.semanticEvidence['usedPartyTrade'] == true) 'partyTrade': partyTrade!.evidence,
      if (usedFieldObstacles != null) 'fieldObstacles': usedFieldObstacles.evidence,
      'fieldObstacleBindings': fieldBindingEvidence,
      'trainerBindings': {
        'bindings': trainerBindings.byEventIdentity.values
            .map((binding) => binding.toJson()).toList(),
        'refusals': [for (final refusal in trainerBindings.refusals.entries) {
          'sourceEventIdentity': refusal.key.value, 'reason': refusal.value,
        }],
      },
      if (retentionPolicy != null) 'mapInstanceRetention': {
        ...retentionBinding!.evidence,
        'policy': retentionPolicy.toJson(),
        'sourceMetadataFile': source.snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Data/map_metadata.dat').toJson(),
        'sourceOracle': {'viewport': '000:684-686', 'margin': '043:475-495',
          'clamp': '042:322-341'},
      },
      'mapMusic': musicEvidence,
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
        musicBindings: Map.unmodifiable(musicBindings),
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
                  .where((entry) => !entry.actionId.startsWith('map.') &&
                    entry.actionId != 'connection.create_bidirectional_apply' &&
                    !entry.actionId.startsWith('border_layer.')),
              ...importedMutations,
              ...base.mutations
                  .where((entry) => entry.actionId.startsWith('map.')),
              ...baseConnections,
              ...base.mutations.where((entry) => entry.actionId.startsWith('border_layer.')),
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

Iterable<String> _soundNames(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    switch (node) {
      case SourceSoundEffectNode():
        yield node.name;
      case SourceWarpNode():
        if (node.originalProgram != null) yield node.originalProgram!.sound.name;
      case SourceForcedMoveRouteNode():
        for (final step in node.steps) {
          if (step.soundName != null) yield step.soundName!;
        }
      case SourceConditionalNode():
        yield* _soundNames(node.whenTrue);
        yield* _soundNames(node.whenFalse);
      case SourceTextNode():
        final choice = node.followingChoice;
        if (choice != null) {
          for (final branch in choice.branches) {
            yield* _soundNames(branch.body);
          }
          if (choice.cancelBranch != null) {
            yield* _soundNames(choice.cancelBranch!);
          }
        }
      case SourceChoiceNode():
        for (final branch in node.branches) {
          yield* _soundNames(branch.body);
        }
        if (node.cancelBranch != null) yield* _soundNames(node.cancelBranch!);
      default:
        break;
    }
  }
}

Future<MapInstanceRetentionPolicy> sourceEventMapRetentionPolicy({
  required NormalizedSourceProject source, required SourceFilePort files,
  required Map<int, String> nativeMapIds, ScanCancellation? cancellation,
}) async => (await _sourceEventMapRetentionBinding(source: source, files: files,
    nativeMapIds: nativeMapIds, cancellation: cancellation)).policy;

Future<({MapInstanceRetentionPolicy policy, Map<String, Object?> evidence})>
    _sourceEventMapRetentionBinding({required NormalizedSourceProject source,
      required SourceFilePort files, required Map<int, String> nativeMapIds,
      ScanCancellation? cancellation}) async {
  cancellation?.check();
  final entries = source.snapshot.entries.where((entry) =>
    sourcePathCollisionKey(entry.relativePath) == 'data/map_metadata.dat').toList();
  if (!SourceEventProfile.kantoForProject(source).isQualified || entries.length != 1 ||
      entries.single.relativePath != 'Data/map_metadata.dat') {
    throw const NativeWriteException('events.retention.metadata',
      'Map retention requires the exact source map metadata');
  }
  final entry = entries.single;
  final archive = SourceArchive(limits: const SourceArchiveLimits(maxFiles: 1,
    maxFileBytes: 4194304, maxTotalBytes: 4194304,
    maxTotalNodes: 100000, maxTotalEntries: 400000, maxReferences: 1));
  final bytes = await files.read(entry.fileId);
  cancellation?.check();
  final document = archive.add(entry, bytes).document;
  archive.seal();
  Never invalid() => throw const NativeWriteException(
    'events.retention.metadata',
    'Map metadata must use its plain source schema',
  );
  bool undecorated(MarshalNode node) =>
      node.extensions.isEmpty &&
      node.userClass == null &&
      node.instanceVariables.isEmpty;
  bool plainScalar(MarshalNode node) =>
      undecorated(node) && node.encoding == null;
  bool plainValueShape(MarshalNode node) {
    if (node.extensions.isNotEmpty || node.userClass != null) {
      return false;
    }
    if (node.instanceVariables.isEmpty) {
      return node.encoding == null;
    }
    if ((node.kind != MarshalKind.string && node.kind != MarshalKind.symbol) ||
        node.instanceVariables.length != 1) {
      return false;
    }
    final attribute = node.instanceVariables.single;
    final key = document.node(attribute.key);
    final value = document.node(attribute.value);
    return key.kind == MarshalKind.symbol &&
        plainScalar(key) &&
        key.name == 'E' &&
        value.kind == MarshalKind.boolean &&
        plainScalar(value) &&
        node.encoding == (value.booleanValue == true ? 'UTF-8' : 'US-ASCII');
  }

  for (final node in document.nodes) {
    if (node.kind == MarshalKind.object) {
      if (node.extensions.isNotEmpty || node.userClass != null ||
          node.encoding != null) {
        invalid();
      }
    } else if (!plainValueShape(node)) {
      invalid();
    }
  }
  final visited = <int>{};
  final active = <int>{};
  void validateValue(int nodeId) {
    if (active.contains(nodeId)) {
      invalid();
    }
    if (visited.contains(nodeId)) {
      return;
    }
    final node = document.node(nodeId);
    if (!plainValueShape(node) ||
        !const {
          MarshalKind.nil,
          MarshalKind.boolean,
          MarshalKind.integer,
          MarshalKind.bigInteger,
          MarshalKind.floating,
          MarshalKind.string,
          MarshalKind.symbol,
          MarshalKind.array,
          MarshalKind.hash,
        }.contains(node.kind) ||
        (node.encoding != null &&
            node.kind != MarshalKind.string &&
            node.kind != MarshalKind.symbol)) {
      invalid();
    }
    active.add(nodeId);
    for (final child in node.elements) {
      validateValue(child);
    }
    for (final pair in node.pairs) {
      validateValue(pair.key);
      validateValue(pair.value);
    }
    final defaultId = node.defaultValue;
    if (defaultId != null) {
      final value = document.node(defaultId);
      if (value.kind != MarshalKind.nil || !plainScalar(value)) {
        invalid();
      }
    }
    active.remove(nodeId);
    visited.add(nodeId);
  }

  final root = document.node(document.rootId);
  if (root.kind != MarshalKind.hash ||
      !plainScalar(root) ||
      root.pairs.length > 4096) {
    invalid();
  }
  final defaultId = root.defaultValue;
  if (defaultId != null) {
    final value = document.node(defaultId);
    if (value.kind != MarshalKind.nil || !plainScalar(value)) {
      invalid();
    }
  }
  const knownFields = {
    '@id',
    '@real_name',
    '@outdoor_map',
    '@announce_location',
    '@can_bicycle',
    '@always_bicycle',
    '@teleport_destination',
    '@weather',
    '@town_map_position',
    '@dive_map_id',
    '@dark_map',
    '@safari_map',
    '@snap_edges',
    '@still_reflections',
    '@random_dungeon',
    '@battle_background',
    '@wild_battle_BGM',
    '@trainer_battle_BGM',
    '@wild_victory_BGM',
    '@trainer_victory_BGM',
    '@wild_capture_ME',
    '@town_map_size',
    '@battle_environment',
    '@flags',
    '@pbs_file_suffix',
  };
  final records = <int, Map<String, int>>{};
  for (final pair in root.pairs) {
    final key = document.node(pair.key);
    final mapId = key.integerValue?.toInt();
    if (key.kind != MarshalKind.integer ||
        !plainScalar(key) ||
        mapId == null ||
        mapId < 1 ||
        mapId > 2147483647 ||
        records.containsKey(mapId)) {
      invalid();
    }
    final record = document.node(pair.value);
    if (record.kind != MarshalKind.object ||
        record.className != 'GameData::MapMetadata' ||
        record.extensions.isNotEmpty ||
        record.userClass != null ||
        record.encoding != null) {
      invalid();
    }
    final fields = <String, int>{};
    for (final field in record.instanceVariables) {
      final name = document.node(field.key);
      if (name.kind != MarshalKind.symbol ||
          !plainScalar(name) ||
          !knownFields.contains(name.name) ||
          fields.containsKey(name.name)) {
        invalid();
      }
      validateValue(field.value);
      fields[name.name!] = field.value;
    }
    final id = fields['@id'];
    if (id == null) {
      invalid();
    }
    final identity = document.node(id);
    if (identity.kind != MarshalKind.integer ||
        !plainScalar(identity) ||
        identity.integerValue != BigInt.from(mapId)) {
      invalid();
    }
    final snapId = fields['@snap_edges'];
    if (snapId != null) {
      final snap = document.node(snapId);
      if (!plainScalar(snap) ||
          (snap.kind != MarshalKind.nil && snap.kind != MarshalKind.boolean)) {
        invalid();
      }
    }
    records[mapId] = fields;
  }
  final clamps = <String>{};
  final values = <String, Object?>{};
  for (final map in nativeMapIds.entries) {
    final fields = records[map.key];
    if (fields == null) {
      values['${map.key}'] = {
        'nativeMapId': map.value,
        'snapEdges': null,
        'record': 'absent',
      };
      continue;
    }
    final nodeId = fields['@snap_edges'];
    if (nodeId == null) {
      values['${map.key}'] = {
        'nativeMapId': map.value,
        'snapEdges': null,
        'field': 'absent',
      };
      continue;
    }
    final value = document.node(nodeId);
    values['${map.key}'] = {
      'nativeMapId': map.value,
      'snapEdges': value.kind == MarshalKind.nil ? null : value.booleanValue,
      'kind': value.kind.name,
    };
    if (value.booleanValue == true) clamps.add(map.value);
  }
  return (policy: MapInstanceRetentionPolicy(viewportWidthTiles: 16, viewportHeightTiles: 12,
    marginTiles: 6, clampViewportToMapIds: clamps),
    evidence: {'sourceMetadataFile': entry.toJson(),
      'sourceMetadataArchiveHash': archive.canonicalHash.value, 'selectedMapValues': values});
}

Iterable<SourcePickupNode> _pickups(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    switch (node) {
      case SourcePickupNode():
        yield node;
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

Iterable<String> _itemSymbols(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    switch (node) {
      case SourcePickupNode():
        yield node.sourceSymbol;
      case SourceConditionalNode():
        if (node.condition.sourceItemSymbol != null) yield node.condition.sourceItemSymbol!;
        if (node.condition.pickup != null) yield node.condition.pickup!.sourceSymbol;
        yield* _itemSymbols(node.whenTrue);
        yield* _itemSymbols(node.whenFalse);
      case SourceTextNode():
        if (node.followingChoice != null) {
          for (final branch in node.followingChoice!.branches) { yield* _itemSymbols(branch.body); }
          if (node.followingChoice!.cancelBranch != null) yield* _itemSymbols(node.followingChoice!.cancelBranch!);
        }
      case SourceChoiceNode():
        for (final branch in node.branches) { yield* _itemSymbols(branch.body); }
        if (node.cancelBranch != null) yield* _itemSymbols(node.cancelBranch!);
      default:
        break;
    }
  }
}
