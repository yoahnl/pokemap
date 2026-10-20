import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_trainer_catalog_qualification.dart';
import 'native_psdk_catalog.dart';
import 'source_catalog_selection.dart';
import 'source_gym_leader_binding.dart';

final class SourceTrainerEventBindings {
  SourceTrainerEventBindings._(
      Map<ConverterId, SourceTrainerEventBinding> bindings,
      Map<ConverterId, String> refusals,
      this.qualification)
      : byEventIdentity = Map.unmodifiable(bindings),
        refusals = Map.unmodifiable(refusals);
  final Map<ConverterId, SourceTrainerEventBinding> byEventIdentity;
  final Map<ConverterId, String> refusals;
  final NativeTrainerCatalogQualification? qualification;
}

final class SourceTrainerEventBinding {
  SourceTrainerEventBinding._({
    required this.sourceIdentity,
    required this.nativeTrainer,
    required this.sourceRosterFile,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.sourceTrainerPbsHash,
    required this.nativeBundleHash,
    required this.qualificationHash,
    required this.loseText,
    required this.loseTextLocator,
    required this.eventIdentity,
    required this.sourceMapId,
    required this.sourceEventId,
    required this.eventHash,
    this.gymLeader,
    required List<ProjectItemDefinition> battleItemDefinitions,
    required List<SourceTrainerProgramNode> programs,
  })  : programs = List.unmodifiable(programs),
        battleItemDefinitions = List.unmodifiable(battleItemDefinitions),
        nativeTrainerHash = canonicalHashOf(nativeTrainer.toJson());

  final SourcePbsIdentity sourceIdentity;
  final ProjectTrainerEntry nativeTrainer;
  final SourceFileEntry sourceRosterFile;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      sourceTrainerPbsHash,
      nativeBundleHash,
      qualificationHash,
      nativeTrainerHash,
      eventHash;
  final String? loseText;
  final SourceLocator? loseTextLocator;
  final ConverterId eventIdentity;
  final int sourceMapId, sourceEventId;
  final List<SourceTrainerProgramNode> programs;
  final SourceGymLeaderBinding? gymLeader;
  final List<ProjectItemDefinition> battleItemDefinitions;

  String get nativeVictorySpeech =>
      loseText == null || loseText!.isEmpty ? '...' : loseText!;

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        !analysis.profile.isQualified ||
        event.identity != eventIdentity ||
        event.sourceMapId != sourceMapId ||
        event.sourceEventId != sourceEventId ||
        canonicalHashOf(_eventFingerprint(event)) != eventHash) {
      return false;
    }
    final maps = source.maps.where((map) => map.map.sourceMapId == sourceMapId);
    if (maps.length != 1) return false;
    final originals = maps.single.map.events
        .where((event) => event.sourceEventId == sourceEventId);
    return originals.length == 1 &&
        (programs.first.gymLeader == null ? gymLeader == null :
            gymLeader?.isBoundTo(source, analysis.profile, programs.first) == true) &&
        programs.every((program) => program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: sourceMapId,
            event: originals.single));
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceTrainerEventBinding',
        if (gymLeader != null) 'gymLeader': gymLeader!.toJson(),
        'version': 1,
        'sourceIdentity': sourceIdentity.toJson(),
        'sourceEventIdentity': eventIdentity.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'eventHash': eventHash.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceTrainerPbsHash': sourceTrainerPbsHash.value,
        'sourceRosterFile': sourceRosterFile.toJson(),
        'qualificationHash': qualificationHash.value,
        'nativeBundleHash': nativeBundleHash.value,
        'nativeTrainerId': nativeTrainer.id,
        'nativeTrainerHash': nativeTrainerHash.value,
        'movePolicy': 'nativeDefaultsForUnspecifiedAndQualifiedAuthoredMoves',
        'battleItemDefinitions': battleItemDefinitions.map((item) => item.toJson()).toList(),
        'nativeAbilityPolicy': 'speciesPrimary',
        'nativeStatProfile': 'trainerV0',
        'loseText': loseText,
        'nativeVictorySpeech': nativeVictorySpeech,
        'sourceVictorySpeechFallback': 'ellipsisWhenMissingOrEmpty',
        'nativeVictorySpeechFallbackApplied': loseText?.isNotEmpty != true,
        'loseTextLocator': loseTextLocator?.toJson(),
        'victorySpeechAuthority': 'sourcePbsLoseText',
        'endSpeechComments':
            programs.map((program) => program.endSpeechComment).toList(),
        'sourcePrograms': programs.map((program) => program.toJson()).toList(),
        'nativeExecutionQualified': false,
        'fullSourceTrainerParityQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourceTrainerEventBindingResolver {
  const SourceTrainerEventBindingResolver();

  Future<SourceTrainerEventBindings> read({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceFilePort files,
    NativePsdkCatalog? nativeCatalog,
    NativeTrainerCatalogQualification? qualification,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw const NativeWriteException('events.trainer.source_binding',
          'Trainer event bindings require the exact source analysis.');
    }
    final bindings = <ConverterId, SourceTrainerEventBinding>{};
    final refusals = <ConverterId, String>{};
    final candidates = analysis.events
        .where((event) => event.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceTrainerProgramNode>()
            .isNotEmpty)
        .toList()
      ..sort(
          (left, right) => left.identity.value.compareTo(right.identity.value));
    if (candidates.isEmpty || !analysis.profile.isQualified) {
      return SourceTrainerEventBindings._(bindings, refusals, qualification);
    }
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot, files: files, cancellation: cancellation);
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze();
    final native = nativeCatalog ?? NativePsdkCatalogManifest.builtin();
    final requested =
        sourceCatalogSelection(source, source.selectedSourceMapIds.toSet())
            .trainers;
    if (!source.snapshot.entries
        .any((entry) => entry.relativePath == 'Data/trainers.dat')) {
      for (final event in candidates) {
        refusals[event.identity] = 'native_trainer.compiled_witness';
      }
      return SourceTrainerEventBindings._(bindings, refusals, null);
    }
    qualification ??= await NativeTrainerCatalogQualification.prepare(
        normalizedSource: source,
        source: pbs,
        files: files,
        nativeCatalog: native,
        requestedTrainers: requested,
        cancellation: cancellation);
    await qualification.validateContext(
        normalizedSource: source,
        source: pbs,
        files: files,
        nativeCatalog: native,
        requestedTrainers: requested,
        cancellation: cancellation);
    final nativeHash = canonicalHashOf(native.toJson(),
        limits: nativePsdkCatalogShardJsonLimits);
    final qualified = {
      for (final trainer in qualification.trainers) trainer.id: trainer
    };
    final rejected = {
      for (final refusal in qualification.refusals)
        refusal.identity.key: refusal
    };
    for (final event in candidates) {
      cancellation?.check();
      try {
        final original =
            expected.eventAt(event.sourceMapId, event.sourceEventId);
        if (original == null ||
            event.isQuarantined ||
            !const [2, 3, 4].contains(event.pages.length) ||
            canonicalJsonOf(_eventFingerprint(event)) !=
                canonicalJsonOf(_eventFingerprint(original))) {
          throw ContractError(
              'events.trainer.program_binding',
              event.identity.value,
              'All source trainer pages require their exact raw analysis.');
        }
        final programs = <SourceTrainerProgramNode>[];
        for (final page in event.pages) {
          if (page.originalPageIndex == 2 && page.isEmpty) continue;
          if (page.body.nodes.length != 1 ||
              page.body.nodes.single is! SourceTrainerProgramNode) {
            throw ContractError(
                'events.trainer.program_binding',
                event.identity.value,
                'The complete source trainer program is required.');
          }
          programs.add(page.body.nodes.single as SourceTrainerProgramNode);
        }
        final program = programs.first;
        if (event.pages.length == 4 && program.gymLeader == null) {
          throw ContractError('events.trainer.program_binding', event.identity.value,
              'Four source stages require the complete qualified gym grammar.');
        }
        final identity = SourcePbsIdentity(
            namespace: source.snapshot.logicalProjectNamespace,
            family: SourcePbsFamily.trainers,
            trainerType: program.trainerType,
            trainerName: program.trainerName,
            version: program.trainerVersion);
        final refusal = rejected[identity.key];
        if (refusal != null) {
          throw ContractError(refusal.code, identity.key, refusal.message);
        }
        final trainer = qualified[identity.sourceId.value];
        if (trainer == null) {
          throw ContractError('native_trainer.request_missing', identity.key,
              'The complete program requires its exact shared qualification.');
        }
        final entry = pbs.lookup(identity);
        if (entry == null ||
            entry.fields.any((field) =>
                !const {'LoseText', 'Pokemon'}.contains(field.key) &&
                !(program.gymLeader != null && field.key == 'Items') &&
                !(field.key == 'Moves' && entry.party.any((member) => member.fields.contains(field)))) ||
            entry.fieldsNamed('LoseText').length > 1) {
          throw ContractError('events.trainer.header_unsupported', identity.key,
              'Trainer metadata requires an explicit native semantic binding.');
        }
        final loseText = entry.field('LoseText');
        if (loseText != null &&
            (loseText.values.length != 1 ||
                loseText.values.single.length > 1024)) {
          throw ContractError('events.trainer.speech_unsupported', identity.key,
              'Trainer victory speech requires one bounded source literal.');
        }
        final document = pbs.documents.singleWhere((document) =>
            document.file.relativePath == entry.headerLocator.file);
        final binding = SourceTrainerEventBinding._(
            gymLeader: program.gymLeader == null ? null :
                await const SourceGymLeaderBindingResolver().read(source: source,
                    analysis: analysis, event: event, program: program, files: files,
                    limits: limits, cancellation: cancellation),
            sourceIdentity: identity,
            nativeTrainer: trainer,
            sourceRosterFile: document.file,
            sourceSnapshotHash: source.snapshot.canonicalHash,
            normalizationHash: source.canonicalHash,
            profileHash: analysis.profile.canonicalHash,
            sourceTrainerPbsHash: pbs.canonicalHash,
            nativeBundleHash: nativeHash,
            qualificationHash: qualification.evidenceHash,
            loseText: loseText?.values.single,
            loseTextLocator: loseText?.locator,
            eventIdentity: event.identity,
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            eventHash: canonicalHashOf(_eventFingerprint(original)),
            battleItemDefinitions: qualification.battleItemDefinitions
                .where((item) => trainer.battleItems.containsKey(item.id)).toList(),
            programs: programs);
        if (!binding.isBoundToEvent(
            source: source, analysis: analysis, event: event)) {
          throw ContractError(
              'events.trainer.program_binding',
              event.identity.value,
              'Trainer source programs cannot bypass their raw attestations.');
        }
        bindings[event.identity] = binding;
      } on ContractError catch (error) {
        refusals[event.identity] = error.code;
      }
    }
    return SourceTrainerEventBindings._(bindings, refusals, qualification);
  }
}

Map<String, Object?> _eventFingerprint(SourceEventDefinition event) => {
      'identity': event.identity.value,
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'quarantined': event.isQuarantined,
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'condition': page.condition.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'body': [
              for (final node in page.body.nodes)
                node is SourceTrainerProgramNode
                    ? node.toJson()
                    : {'kind': node.runtimeType.toString()}
            ],
            'graphic': page.graphic == null
                ? null
                : {
                    'tileId': page.graphic!.tileId,
                    'characterName': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blendType': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'moveRouteNodeId': page.graphic!.moveRouteNodeId,
                  },
          }
      ],
    };
