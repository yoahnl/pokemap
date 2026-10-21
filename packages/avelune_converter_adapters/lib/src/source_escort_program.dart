import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'native_project_writer.dart';
import 'source_event_character_import.dart';
import 'source_event_sound_binding.dart';
import 'source_player_character_import.dart';

final class SourceEscortProgram {
  SourceEscortProgram._(
      this.event,
      this.nodes,
      this.actorEventId,
      this.doorEventId,
      this.sourceHash,
      this.normalizedHash,
      this.profileHash,
      this.fingerprint);
  final SourceEventDefinition event;
  final List<SourceEventNode> nodes;
  final int actorEventId, doorEventId;
  final Sha256Hash sourceHash, normalizedHash, profileHash, fingerprint;
  SourceMusicNode get music => nodes[1] as SourceMusicNode;
  SourceForcedMoveRouteNode get approach =>
      nodes[6] as SourceForcedMoveRouteNode;
  SourceForcedMoveRouteNode get actorWalk =>
      nodes[11] as SourceForcedMoveRouteNode;
  SourceForcedMoveRouteNode get playerWalk =>
      nodes[12] as SourceForcedMoveRouteNode;
  List<SourceEventNode> get cinematicNodes => nodes.sublist(1, 14);
  SourceWarpNode get transfer => nodes[26] as SourceWarpNode;
  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
          SourceEventDefinition candidate) =>
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizedHash &&
      analysis.profile.canonicalHash == profileHash &&
      _fingerprint(candidate) == fingerprint &&
      _shape(candidate) != null;
  Map<String, Object?> toJson() => {
        'kind': 'closedEscortToInterior',
        'version': 1,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'actorEventId': actorEventId,
        'doorEventId': doorEventId,
        'sourceSnapshotHash': sourceHash.value,
        'normalizationHash': normalizedHash.value,
        'profileHash': profileHash.value,
        'programHash': fingerprint.value,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'presentationAdaptation': 'nativeCinematicMusicRestoredBeforeDoorEntry',
        'sourceTemporalParity': false,
      };
}

Map<ConverterId, SourceEscortProgram> sourceEscortPrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash ||
      !analysis.profile.isQualified) {
    return const {};
  }
  final original = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  return Map.unmodifiable({
    for (final event in analysis.events)
      if (_shape(event) case final shape?)
        if (original.eventAt(event.sourceMapId, event.sourceEventId)
            case final raw?)
          if (_fingerprint(raw) == _fingerprint(event))
            event.identity: SourceEscortProgram._(
                event,
                shape.$1,
                shape.$2,
                shape.$3,
                source.snapshot.canonicalHash,
                source.canonicalHash,
                analysis.profile.canonicalHash,
                _fingerprint(event))
  });
}

(List<SourceEventNode>, int, int)? _shape(SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.length != 2) {
    return null;
  }
  final first = event.pages.first, terminal = event.pages.last;
  final terminalGuard =
      terminal.condition.kind == SourceEventConditionKind.all &&
              terminal.condition.children.length == 1
          ? terminal.condition.children.single
          : terminal.condition;
  if (first.originalPageIndex != 0 ||
      terminal.originalPageIndex != 1 ||
      first.triggerCode != 1 ||
      terminal.triggerCode != 0 ||
      !terminal.isEmpty ||
      first.condition.kind != SourceEventConditionKind.always ||
      terminalGuard.kind != SourceEventConditionKind.variableAtLeast ||
      terminalGuard.minimum != 1 ||
      !_blank(first.graphic) ||
      !_blank(terminal.graphic)) {
    return null;
  }
  final n = first.body.nodes.where((n) => n is! SourceAnnotationNode).toList();
  if (n.length != 28 ||
      n[0] is! SourceSwitchNode ||
      n[1] is! SourceMusicNode ||
      n[2] is! SourceTextNode ||
      n[3] is! SourceForcedMoveRouteNode ||
      n[4] is! SourceExclamationNode ||
      n[5] is! SourceMoveRouteBarrierNode ||
      n[6] is! SourceForcedMoveRouteNode ||
      n[7] is! SourceMoveRouteBarrierNode ||
      n[8] is! SourceTextNode ||
      n[9] is! SourceTextNode ||
      n[10] is! SourceTextNode ||
      n[11] is! SourceForcedMoveRouteNode ||
      n[12] is! SourceForcedMoveRouteNode ||
      n[13] is! SourceMoveRouteBarrierNode ||
      n[14] is! SourceForcedMoveRouteNode ||
      n[15] is! SourceMoveRouteBarrierNode ||
      n[16] is! SourceForcedMoveRouteNode ||
      n[17] is! SourceForcedMoveRouteNode ||
      n[18] is! SourceMoveRouteBarrierNode ||
      n[19] is! SourcePlayerVisibilityNode ||
      n[20] is! SourceForcedMoveRouteNode ||
      n[21] is! SourceMoveRouteBarrierNode ||
      n[22] is! SourceToneNode ||
      n[23] is! SourceWaitNode ||
      n[24] is! SourceForcedMoveRouteNode ||
      n[25] is! SourcePlayerVisibilityNode ||
      n[26] is! SourceWarpNode ||
      n[27] is! SourceToneNode) {
    return null;
  }
  final flag = n[0] as SourceSwitchNode, music = n[1] as SourceMusicNode;
  final face = n[3] as SourceForcedMoveRouteNode,
      exclaim = n[4] as SourceExclamationNode;
  final approach = n[6] as SourceForcedMoveRouteNode;
  final actor = approach.targetSourceCharacterId;
  final actorWalk = n[11] as SourceForcedMoveRouteNode,
      playerWalk = n[12] as SourceForcedMoveRouteNode;
  final open = n[14] as SourceForcedMoveRouteNode,
      close = n[20] as SourceForcedMoveRouteNode;
  final door = open.targetSourceCharacterId;
  if (!flag.value ||
      flag.factIds.length != 1 ||
      music.name.isEmpty ||
      music.pitch != 100 ||
      music.volume != 100 ||
      !_route(face, -1, false, const [SourceMoveRouteStepKind.turnDown]) ||
      exclaim.targetSourceCharacterId != -1 ||
      actor < 1 ||
      door < 1 ||
      actor == door ||
      approach.repeat ||
      approach.skippable ||
      approach.steps.isEmpty ||
      approach.steps.length > 16 ||
      approach.steps.any((s) => !const {
            SourceMoveRouteStepKind.moveUp,
            SourceMoveRouteStepKind.moveRight
          }.contains(s.kind)) ||
      actorWalk.targetSourceCharacterId != actor ||
      actorWalk.repeat ||
      actorWalk.skippable ||
      playerWalk.targetSourceCharacterId != -1 ||
      playerWalk.repeat ||
      playerWalk.skippable ||
      actorWalk.steps.length < 3 ||
      actorWalk.steps.length > 32 ||
      playerWalk.steps.length != actorWalk.steps.length ||
      actorWalk.steps.last.kind != SourceMoveRouteStepKind.turnUp ||
      playerWalk.steps.first.kind != SourceMoveRouteStepKind.throughOn ||
      actorWalk.steps
          .take(actorWalk.steps.length - 1)
          .any((s) => !_cardinal(s.kind)) ||
      playerWalk.steps.skip(1).any((s) => !_cardinal(s.kind))) {
    return null;
  }
  if (!_route(open, door, true, const [
        SourceMoveRouteStepKind.soundEffect,
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnLeft,
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnRight,
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnUp,
        SourceMoveRouteStepKind.wait
      ]) ||
      open.steps.first.soundPitch != 100 ||
      open.steps.first.soundVolume != 100 ||
      !_route(close, door, true, const [
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnRight,
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnLeft,
        SourceMoveRouteStepKind.wait,
        SourceMoveRouteStepKind.turnDown,
        SourceMoveRouteStepKind.wait
      ]) ||
      [...open.steps, ...close.steps]
          .where((s) => s.kind == SourceMoveRouteStepKind.wait)
          .any((s) => s.durationTicks != 2) ||
      !_route(n[16] as SourceForcedMoveRouteNode, actor, true, const [
        SourceMoveRouteStepKind.throughOn,
        SourceMoveRouteStepKind.moveUp,
        SourceMoveRouteStepKind.hide,
        SourceMoveRouteStepKind.throughOff
      ]) ||
      !_route(n[17] as SourceForcedMoveRouteNode, -1, true, const [
        SourceMoveRouteStepKind.throughOn,
        SourceMoveRouteStepKind.moveRight,
        SourceMoveRouteStepKind.moveUp,
        SourceMoveRouteStepKind.hide,
        SourceMoveRouteStepKind.throughOff
      ]) ||
      (n[19] as SourcePlayerVisibilityNode).visible ||
      !(n[25] as SourcePlayerVisibilityNode).visible ||
      !_route(n[24] as SourceForcedMoveRouteNode, -1, false,
          const [SourceMoveRouteStepKind.show])) {
    return null;
  }
  final black = n[22] as SourceToneNode, restore = n[27] as SourceToneNode;
  final transfer = n[26] as SourceWarpNode;
  if (black.red != -255 ||
      black.green != -255 ||
      black.blue != -255 ||
      black.gray != 0 ||
      black.durationMs != 300 ||
      restore.red != 0 ||
      restore.green != 0 ||
      restore.blue != 0 ||
      restore.gray != 0 ||
      restore.durationMs != 300 ||
      (n[23] as SourceWaitNode).durationMs != 400 ||
      transfer.targetSourceMapId == event.sourceMapId ||
      transfer.x < 0 ||
      transfer.y < 0 ||
      n
          .whereType<SourceTextNode>()
          .any((n) => n.followingChoice != null || n.annotations.isNotEmpty)) {
    return null;
  }
  return (List.unmodifiable(n), actor, door);
}

bool _blank(SourceEventGraphic? g) =>
    g != null &&
    g.characterName.isEmpty &&
    g.tileId == 0 &&
    g.hue == 0 &&
    g.opacity == 255 &&
    g.blendType == 0 &&
    g.moveType == 0 &&
    g.through &&
    !g.alwaysOnTop &&
    !g.stepAnime &&
    !g.directionFix;
bool _cardinal(SourceMoveRouteStepKind k) => const {
      SourceMoveRouteStepKind.moveUp,
      SourceMoveRouteStepKind.moveDown,
      SourceMoveRouteStepKind.moveLeft,
      SourceMoveRouteStepKind.moveRight
    }.contains(k);
bool _route(SourceForcedMoveRouteNode r, int target, bool skippable,
        List<SourceMoveRouteStepKind> kinds) =>
    r.targetSourceCharacterId == target &&
    !r.repeat &&
    r.skippable == skippable &&
    canonicalJsonOf(r.steps.map((s) => s.kind.name).toList()) ==
        canonicalJsonOf(kinds.map((k) => k.name).toList());
Sha256Hash _fingerprint(SourceEventDefinition e) => canonicalHashOf({
      'identity': e.identity.value,
      'map': e.sourceMapId,
      'event': e.sourceEventId,
      'file': e.sourceFileId.value,
      'name': e.name,
      'x': e.x,
      'y': e.y,
      'pages': [
        for (final p in e.pages)
          {
            'index': p.originalPageIndex,
            'trigger': p.triggerCode,
            'condition': p.condition.toJson(),
            'commands': p.sourcePage.commands.map((c) => c.toJson()).toList(),
            'graphic': p.graphic == null
                ? null
                : [
                    p.graphic!.characterName,
                    p.graphic!.tileId,
                    p.graphic!.hue,
                    p.graphic!.direction,
                    p.graphic!.pattern,
                    p.graphic!.opacity,
                    p.graphic!.blendType,
                    p.graphic!.moveType,
                    p.graphic!.moveSpeed,
                    p.graphic!.moveFrequency,
                    p.graphic!.walkAnime,
                    p.graphic!.stepAnime,
                    p.graphic!.directionFix,
                    p.graphic!.through,
                    p.graphic!.alwaysOnTop,
                    p.graphic!.moveRouteNodeId
                  ],
            'nodes': [
              for (final n in p.body.nodes)
                switch (n) {
                  SourceAnnotationNode() => n.toJson(),
                  SourceSwitchNode() => [n.factIds, n.value],
                  SourceTextNode() => {
                      'text': n.text,
                      'choice': n.followingChoice?.span.toJson()
                    },
                  SourceMusicNode() => n.toJson(),
                  SourceForcedMoveRouteNode() => n.toJson(),
                  SourceMoveRouteBarrierNode() => n.toJson(),
                  SourceExclamationNode() => n.toJson(),
                  SourcePlayerVisibilityNode() => n.toJson(),
                  SourceToneNode() => n.toJson(),
                  SourceWaitNode() => n.toJson(),
                  SourceWarpNode() => {
                      'map': n.targetSourceMapId,
                      'x': n.x,
                      'y': n.y,
                      'direction': n.direction,
                      'fade': n.fade,
                      'span': n.span.toJson()
                    },
                  _ => {
                      'kind': n.runtimeType.toString(),
                      'span': n.span.toJson()
                    },
                }
            ],
          }
      ],
    });

final class SourceEscortBinding {
  SourceEscortBinding._(this.program, this.actor, this.actorImport, this.player,
      this.music, this.actorFingerprint);
  final SourceEscortProgram program;
  final SourceEventDefinition actor;
  final SourceEventCharacterImport actorImport;
  final SourcePlayerCharacterImport player;
  final SourceEventSoundBinding music;
  final Sha256Hash actorFingerprint;
  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
      SourceEventDefinition event) {
    final candidate = analysis.eventAt(event.sourceMapId, program.actorEventId);
    return candidate != null &&
        _fingerprint(candidate) == actorFingerprint &&
        program.isBoundTo(source, analysis, event) &&
        actorImport.sourceSnapshotHash == source.snapshot.canonicalHash &&
        player.sourceSnapshotHash == source.snapshot.canonicalHash &&
        music.sourceSnapshotHash == source.snapshot.canonicalHash;
  }
}

final class SourceEscortBindingResolver {
  const SourceEscortBindingResolver();
  Future<SourceEscortBinding> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEscortProgram program,
      required SourceFilePort files,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    if (!program.isBoundTo(source, analysis, program.event)) {
      throw const NativeWriteException('events.escort.source_changed',
          'Escort requires its exact complete source event.');
    }
    final actor =
        analysis.eventAt(program.event.sourceMapId, program.actorEventId);
    final original = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze()
        .eventAt(program.event.sourceMapId, program.actorEventId);
    if (actor == null ||
        original == null ||
        _fingerprint(actor) != _fingerprint(original) ||
        actor.isQuarantined ||
        actor.pages.length != 2 ||
        actor.pages.first.graphic == null ||
        actor.pages.first.graphic!.characterName.isEmpty ||
        actor.pages.first.graphic!.moveType != 0 ||
        actor.pages.first.graphic!.opacity != 255 ||
        actor.pages.first.graphic!.directionFix ||
        actor.pages.first.graphic!.stepAnime ||
        actor.pages.first.graphic!.alwaysOnTop ||
        actor.pages.first.body.nodes.any((n) => n is! SourceAnnotationNode) ||
        !actor.pages.last.isEmpty) {
      throw const NativeWriteException('events.escort.actor_unqualified',
          'Escort requires its complete stationary source actor.');
    }
    SourceEventCondition single(SourceEventCondition c) =>
        c.kind == SourceEventConditionKind.all && c.children.length == 1
            ? c.children.single
            : c;
    final sourceFlag = program.nodes.first as SourceSwitchNode;
    final actorGuard = single(actor.pages.first.condition);
    if (actorGuard.kind != SourceEventConditionKind.globalSwitch ||
        !actorGuard.expectedValue ||
        actorGuard.factId != sourceFlag.factIds.single ||
        canonicalJsonOf(actor.pages.last.condition.toJson()) !=
            canonicalJsonOf(program.event.pages.last.condition.toJson())) {
      throw const NativeWriteException('events.escort.actor_guard',
          'Guide presence must follow the exact source escort and completion facts.');
    }
    final g = actor.pages.first.graphic!;
    final imported = await const SourceEventCharacterImporter().read(
        snapshot: source.snapshot,
        files: files,
        charsetName: g.characterName,
        sourcePattern: g.pattern,
        sourceDirection: g.direction,
        limits: limits,
        cancellation: cancellation);
    final player = await const SourcePlayerCharacterImporter().read(
        snapshot: source.snapshot, files: files, cancellation: cancellation);
    final music = await const SourceEventSoundResolver().read(
        source: source,
        files: files,
        name: program.music.name,
        kind: SourceEventAudioKind.music,
        limits: limits,
        cancellation: cancellation);
    return SourceEscortBinding._(
        program, actor, imported, player, music, _fingerprint(actor));
  }
}
