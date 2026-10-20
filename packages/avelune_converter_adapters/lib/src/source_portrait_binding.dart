import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_character_presentation_binding.dart';
import 'source_event_character_import.dart';
import 'source_npc_fixed_route_binding.dart';

final class SourcePortraitBinding {
  SourcePortraitBinding._(
      this.sourceHash,
      this.profileHash,
      this.programHash,
      this.actorIdentity,
      this.actorRawHash,
      this.actorImport,
      this.poseImport,
      this.presentation,
      this.scriptsFile,
      this.utilitiesHash,
      this.definitionId,
      this.mutations);
  final Sha256Hash sourceHash, profileHash, programHash, actorRawHash;
  final ConverterId actorIdentity;
  final SourceEventCharacterImport actorImport, poseImport;
  final SourceCharacterPresentationBinding presentation;
  final SourceFileEntry scriptsFile;
  final String utilitiesHash, definitionId;
  final List<NativeMutation> mutations;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
          SourcePortraitProgramNode program) =>
      source.snapshot.canonicalHash == sourceHash &&
      profile.canonicalHash == profileHash &&
      canonicalHashOf(program.toJson()) == programHash &&
      source.maps.any((ir) => ir.map.events.any((event) =>
          event.sourceEventId == program.actorEventId &&
          source.eventIdentity(ir.map.sourceMapId, event.sourceEventId) ==
              actorIdentity &&
          canonicalHashOf(event.toJson()) == actorRawHash));

  List<NativeArtifact> get artifacts => [
        for (final value in {
          actorImport.artifact.handle: actorImport.artifact,
          poseImport.artifact.handle: poseImport.artifact
        }.values)
          value,
      ];

  Map<String, Object?> toJson() => {
        'kind': 'sourcePortraitNativePresentation',
        'sourceSnapshotHash': sourceHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'actorIdentity': actorIdentity.value,
        'actorRawHash': actorRawHash.value,
        'actorCharacterId': actorImport.character.id,
        'poseDefinitionId': definitionId,
        'sourcePatterns': [1, 2, 3, 0],
        'sourceDirection': 8,
        'sourcePoseTicks': 2,
        'nativePoseDurationMs': 100,
        'nativePlayerWaitMs': 1000,
        'nativeAfterPoseWaitMs': 500,
        'presentation': presentation.toJson(),
        'scriptsFile': scriptsFile.toJson(),
        'utilitiesSha256': utilitiesHash,
        'sourceOracle': 'Utilities:194-213',
        'exclamationPresentation': 'nativeExclamationEmote',
        'sourceAnimationPixelsAndAudioParityQualified': false,
        'sourceTemporalParityQualified': false,
        'poseWaitPolicy': 'native400MsClipConcurrentWith500MsInterpreterWait',
        'sourceDirectionFixStateParityQualified': false,
        'autonomySuspension':
            'entireOwningSceneActivityIncludingDialogueAndWaits',
        'nativeAutonomyOracle':
            'playable_map_game_npc_fixed_routes:13-19,142-170;playable_map_game_interactions:30-43;playable_map_game:11990-12134',
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourcePortraitBindingResolver {
  const SourcePortraitBindingResolver();
  Future<SourcePortraitBinding> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event,
      required SourcePortraitProgramNode program,
      required SourceFilePort files,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    Never refuse(String reason) => throw NativeWriteException(
        'events.portrait.$reason',
        'Portrait presentation requires its exact source actor, scripts and poses.');
    final maps = source.maps
        .where((ir) => ir.map.sourceMapId == event.sourceMapId)
        .toList();
    if (maps.length != 1 || !analysis.profile.isQualified) {
      refuse('source');
    }
    final raw = maps.single.map.events
        .where((raw) => raw.sourceEventId == event.sourceEventId)
        .toList();
    if (raw.length != 1 ||
        !program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: event.sourceMapId,
            event: raw.single)) {
      refuse('program');
    }
    final actors = maps.single.map.events
        .where((raw) => raw.sourceEventId == program.actorEventId)
        .toList();
    final actor =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyzeEventAt(event.sourceMapId, program.actorEventId);
    if (actors.length != 1 ||
        actor == null ||
        actor.pages.length != 1 ||
        actor.pages.single.graphic == null ||
        actor.isQuarantined) {
      refuse('actor');
    }
    final graphic = actor.pages.single.graphic!;
    if (graphic.characterName.isEmpty ||
        graphic.hue != 0 ||
        graphic.opacity != 255 ||
        graphic.blendType != 0 ||
        graphic.directionFix ||
        graphic.through ||
        graphic.alwaysOnTop ||
        graphic.tileId != 0) {
      refuse('actor_graphic');
    }
    if (graphic.moveType != 0) {
      if (graphic.moveType != 3) {
        refuse('actor_autonomy');
      }
      try {
        final route = SourceNpcFixedRouteBindingResolver.forProject(source)
            .resolve(
                sourceMapId: event.sourceMapId,
                sourceEventId: program.actorEventId,
                sourcePageIndex: actor.pages.single.originalPageIndex);
        if (!route.isBoundToPage(
                source: source,
                profile: analysis.profile,
                event: actor,
                page: actor.pages.single) ||
            route.nativeMovement.routeSteps
                .any((step) => step.kind == MapEntityNpcRouteStepKind.move)) {
          refuse('actor_autonomy');
        }
      } on SourceNpcFixedRouteBindingUnavailable {
        refuse('actor_autonomy');
      }
    }
    final presentation = resolveSourceCharacterPresentation(
        snapshot: source.snapshot,
        profile: source.interpretationProfile,
        charsetName: program.sourcePoseCharset);
    if (presentation == null) {
      refuse('pose_missing');
    }
    final scripts = source.snapshot.entries
        .where((entry) =>
            sourcePathCollisionKey(entry.relativePath) ==
            sourcePathCollisionKey('Data/Scripts.rxdata'))
        .toList();
    final section = source.interpretationProfile?.sections['events.Utilities'];
    if (scripts.length != 1 ||
        scripts.single.relativePath != 'Data/Scripts.rxdata' ||
        scripts.single.kind != SourceNodeKind.file ||
        scripts.single.sha256 == null ||
        scripts.single.sha256 !=
            source.interpretationProfile?.scriptsArchiveHash ||
        section == null ||
        section['index'] is! int ||
        section['sha256'] is! String ||
        scripts.single.byteLength > limits.maxArtifactBytes) {
      refuse('utilities');
    }
    cancellation?.check();
    final bytes = await files.read(scripts.single.fileId);
    if (bytes.length != scripts.single.byteLength ||
        crypto.sha256.convert(bytes).toString() !=
            scripts.single.sha256!.value) {
      refuse('scripts_changed');
    }
    final document = const MarshalDecoder().decode(bytes);
    final rows = document.node(document.rootId).elements;
    final index = section['index'] as int;
    if (index < 0 || index >= rows.length) {
      refuse('utilities');
    }
    final row = document.node(rows[index]).elements;
    if (row.length != 3 ||
        document.node(row[2]).bytes == null ||
        utf8.decode(document.node(row[1]).bytes!) != section['name']) {
      refuse('utilities');
    }
    final decoded = const BoundedZlibDecoder().decode(
        document.node(row[2]).bytes!,
        limits: const ZlibDecodeLimits(
            maxInputBytes: 1048576, maxOutputBytes: 1048576, maxBlocks: 10000));
    if (crypto.sha256.convert(decoded).toString() != section['sha256']) {
      refuse('utilities_changed');
    }
    final actorImport = await const SourceEventCharacterImporter().read(
        snapshot: source.snapshot,
        files: files,
        charsetName: graphic.characterName,
        sourcePattern: graphic.pattern,
        sourceDirection: graphic.direction,
        limits: limits,
        cancellation: cancellation);
    final poseImport = await const SourceEventCharacterImporter().read(
        snapshot: source.snapshot,
        files: files,
        charsetName: presentation.actualCharsetName,
        sourcePattern: 0,
        sourceDirection: 8,
        limits: limits,
        cancellation: cancellation);
    if (actorImport.frameWidthPx != poseImport.frameWidthPx ||
        actorImport.frameHeightPx != poseImport.frameHeightPx ||
        actorImport.nativeFrameHeightPx != poseImport.nativeFrameHeightPx ||
        poseImport.sheetWidth % 4 != 0 ||
        poseImport.sheetHeight % 4 != 0) {
      refuse('pose_geometry');
    }
    final programHash = canonicalHashOf(program.toJson());
    final id = 'source-portrait-pose-${canonicalHashOf({
          'source': source.snapshot.canonicalHash.value,
          'program': programHash.value,
          'actor': actorImport.character.id,
          'pose': poseImport.imageFile.sha256!.value,
        }).value.substring(0, 24)}';
    final clip = CharacterCustomAnimationClip(
        definitionId: id,
        sourceAssetId: poseImport.assetId,
        loop: false,
        frames: [
          for (final pattern in [1, 2, 3, 0])
            CharacterAnimationFrame(
                source: TilesetSourceRect(
                    x: pattern * 64,
                    y: 3 * poseImport.nativeFrameHeightPx,
                    width: 64,
                    height: poseImport.nativeFrameHeightPx),
                durationMs: 100),
        ]);
    NativeMutation mutation(String action, String role,
            List<ConverterId> targets, Map<String, Object?> params) =>
        NativeMutation(
            operationId:
                ConverterId('ac13_portrait_${role}_${programHash.value}'),
            actionId: action,
            sourceEntityIds: [event.sourceFileId],
            targetEntityIds: targets,
            parameters: params,
            limits: limits);
    return SourcePortraitBinding._(
        source.snapshot.canonicalHash,
        analysis.profile.canonicalHash,
        programHash,
        actor.identity,
        canonicalHashOf(actors.single.toJson()),
        actorImport,
        poseImport,
        presentation,
        scripts.single,
        section['sha256'] as String,
        id,
        List.unmodifiable([
          if (poseImport.tilesetId != actorImport.tilesetId)
            poseImport.mutations.first,
          mutation('characterStudio.animationDefinition.create', 'definition',
              [ConverterId(id)], {'displayName': id, 'mode': 'single'}),
          mutation('characterStudio.animationClip.upsert', 'clip', [
            ConverterId(actorImport.character.id)
          ], {
            'characterId': actorImport.character.id,
            'kind': 'custom',
            ...clip.toJson()
          }),
        ]));
  }
}
