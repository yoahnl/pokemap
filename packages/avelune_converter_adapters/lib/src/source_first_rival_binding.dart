import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_trainer_catalog_qualification.dart';
import 'source_catalog_selection.dart';
import 'source_event_sound_binding.dart';

final class SourceFirstRivalBinding {
  SourceFirstRivalBinding._(this.program, this.sourceIdentity, this.trainers,
      this.loseTexts, this.music, this.qualificationHash, this.eventHash);
  final SourceFirstRivalProgram program;
  final ConverterId sourceIdentity;
  final Map<int, ProjectTrainerEntry> trainers;
  final Map<int, String> loseTexts;
  final SourceEventSoundBinding music;
  final Sha256Hash qualificationHash, eventHash;

  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
      SourceEventDefinition event) {
    if (event.identity != sourceIdentity ||
        program.sourceSnapshotHash != source.snapshot.canonicalHash ||
        program.normalizationHash != source.canonicalHash ||
        program.profileHash != analysis.profile.canonicalHash ||
        eventHash != canonicalHashOf(_fingerprint(event)) ||
        music.sourceSnapshotHash != source.snapshot.canonicalHash ||
        music.kind != SourceEventAudioKind.music ||
        music.policy != SourceEventSoundPolicy.sourceEngineGain) {
      return false;
    }
    final map = source.maps
        .where((m) => m.map.sourceMapId == program.sourceMapId)
        .singleOrNull;
    final raw = map?.map.events
        .where((e) => e.sourceEventId == program.sourceEventId)
        .singleOrNull;
    return raw != null &&
        program.isBoundTo(
            source: source, profile: analysis.profile, event: raw) &&
        trainers.keys
            .toSet()
            .containsAll(program.battles.map((b) => b.trainerVersion));
  }

  Map<String, Object?> toJson() => {
        'kind': 'attestedFirstRivalBinding',
        'sourceEventIdentity': sourceIdentity.value,
        'program': program.toJson(),
        'qualificationHash': qualificationHash.value,
        'eventHash': eventHash.value,
        'music': music.evidence,
        'nativeTrainerIds': {
          for (final e in trainers.entries) '${e.key}': e.value.id
        },
        'nativeBattleEngine': 'avelune',
        'hiddenCompanionFacing':
            'typedLogicalFacingOnlyPreservesCurrentPosition',
        'visibleCompanionFacing': 'nativeActorRoute',
        'sourceTemporalAudioParity': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourceFirstRivalBindings {
  const SourceFirstRivalBindings(
      this.byEventIdentity, this.refusals, this.qualification);
  final Map<ConverterId, SourceFirstRivalBinding> byEventIdentity;
  final Map<ConverterId, String> refusals;
  final NativeTrainerCatalogQualification? qualification;
}

final class SourceFirstRivalBindingResolver {
  const SourceFirstRivalBindingResolver();
  Future<SourceFirstRivalBindings> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      NativePsdkCatalog? nativeCatalog,
      NativeTrainerCatalogQualification? qualification,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    final candidates = analysis.events
        .where((e) => e.pages.any((p) =>
            p.body.nodes.whereType<SourceFirstRivalProgramNode>().isNotEmpty))
        .toList();
    if (candidates.isEmpty) {
      return SourceFirstRivalBindings(const {}, const {}, qualification);
    }
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot, files: files, cancellation: cancellation);
    final native = nativeCatalog ?? NativePsdkCatalogManifest.builtin();
    final requested =
        sourceCatalogSelection(source, source.selectedSourceMapIds.toSet())
            .trainers;
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
    final qualified = {
      for (final trainer in qualification.trainers) trainer.id: trainer
    };
    final bound = <ConverterId, SourceFirstRivalBinding>{};
    final refused = <ConverterId, String>{};
    for (final event in candidates) {
      cancellation?.check();
      try {
        final original =
            SourceEventAnalyzer.forProject(source, profile: analysis.profile)
                .analyzeEventAt(event.sourceMapId, event.sourceEventId);
        if (original == null ||
            canonicalJsonOf(_fingerprint(original)) !=
                canonicalJsonOf(_fingerprint(event))) {
          throw const NativeWriteException('events.first_rival.source',
              'The supplied analysis must match the raw source.');
        }
        final nodes = event.pages
            .expand((p) => p.body.nodes)
            .whereType<SourceFirstRivalProgramNode>()
            .toList();
        if (nodes.length != 2 ||
            nodes.any((n) =>
                n.program.programHash != nodes.first.program.programHash)) {
          throw const NativeWriteException('events.first_rival.program',
              'All three source pages are required.');
        }
        final program = nodes.first.program;
        final trainers = <int, ProjectTrainerEntry>{};
        final texts = <int, String>{};
        for (final battle in program.battles) {
          final identity = SourcePbsIdentity(
              namespace: source.snapshot.logicalProjectNamespace,
              family: SourcePbsFamily.trainers,
              trainerType: battle.trainerType,
              trainerName: battle.trainerName,
              version: battle.trainerVersion);
          final trainer = qualified[identity.sourceId.value];
          final entry = pbs.lookup(identity);
          final lose = entry?.field('LoseText');
          if (entry != null &&
              (lose == null ||
                  lose.values.length != 1 ||
                  lose.values.single.trim().isEmpty ||
                  lose.values.single.length > 1024)) {
            throw const NativeWriteException('events.first_rival.speech',
                'One bounded source lose text is required.');
          }
          if (trainer == null ||
              entry == null ||
              trainer.battleItems.isNotEmpty ||
              trainer.victoryDialogueId != null ||
              trainer.defeatDialogueId != null ||
              entry.fields.any((f) =>
                  !const {'LoseText', 'Pokemon'}.contains(f.key) &&
                  !(f.key == 'Moves' &&
                      entry.party.any((m) => m.fields.contains(f)))) ||
              entry.fieldsNamed('LoseText').length > 1) {
            throw const NativeWriteException('events.first_rival.roster',
                'Every literal rival roster requires shared native qualification.');
          }
          trainers[battle.trainerVersion] = trainer;
          texts[battle.trainerVersion] = lose!.values.single;
        }
        final music = await const SourceEventSoundResolver().read(
            source: source,
            files: files,
            name: 'FRLG Battle Intro - Rival (Rival Appears)',
            kind: SourceEventAudioKind.music,
            limits: limits,
            cancellation: cancellation);
        final binding = SourceFirstRivalBinding._(
            program,
            event.identity,
            Map.unmodifiable(trainers),
            Map.unmodifiable(texts),
            music,
            qualification.evidenceHash,
            canonicalHashOf(_fingerprint(event)));
        if (!binding.isBoundTo(source, analysis, event)) {
          throw const NativeWriteException('events.first_rival.source',
              'The entire source program must remain unchanged.');
        }
        bound[event.identity] = binding;
      } on NativeWriteException catch (error) {
        if (error.code.contains('changed') ||
            error.code.contains('quota') ||
            error.code.contains('hash')) {
          rethrow;
        }
        refused[event.identity] = error.code;
      } on SourceEventSoundBindingUnavailable catch (error) {
        refused[event.identity] = 'events.first_rival.${error.reason}';
      }
    }
    return SourceFirstRivalBindings(
        Map.unmodifiable(bound), Map.unmodifiable(refused), qualification);
  }
}

Map<String, Object?> _fingerprint(SourceEventDefinition e) => {
      'identity': e.identity.value,
      'map': e.sourceMapId,
      'event': e.sourceEventId,
      'x': e.x,
      'y': e.y,
      'name': e.name,
      'quarantined': e.isQuarantined,
      'pages': [
        for (final p in e.pages)
          {
            'source': p.sourcePage.toJson(),
            'condition': p.condition.toJson(),
            'graphic': p.graphic == null
                ? null
                : {
                    'tileId': p.graphic!.tileId,
                    'name': p.graphic!.characterName,
                    'direction': p.graphic!.direction,
                    'hue': p.graphic!.hue,
                    'pattern': p.graphic!.pattern,
                    'opacity': p.graphic!.opacity,
                    'blend': p.graphic!.blendType,
                    'moveType': p.graphic!.moveType,
                    'speed': p.graphic!.moveSpeed,
                    'frequency': p.graphic!.moveFrequency,
                    'walk': p.graphic!.walkAnime,
                    'step': p.graphic!.stepAnime,
                    'fixed': p.graphic!.directionFix,
                    'through': p.graphic!.through,
                    'top': p.graphic!.alwaysOnTop,
                    'route': p.graphic!.moveRouteNodeId
                  },
            'nodes': [
              for (final n in p.body.nodes)
                n is SourceFirstRivalProgramNode
                    ? n.toJson()
                    : {
                        'type': n.runtimeType.toString(),
                        'span': n.span.toJson()
                      }
            ]
          }
      ],
    };
