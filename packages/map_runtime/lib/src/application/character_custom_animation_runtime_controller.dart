import 'dart:async';

import 'package:map_core/map_core.dart';

enum CharacterCustomAnimationRuntimeStatus {
  completed,
  interrupted,
  fallbackApplied,
  failed,
}

enum CharacterCustomAnimationRuntimeDiagnosticCode {
  actorAbsent,
  actorBusy,
  actorRemoved,
  definitionAbsent,
  directionRequired,
  directionNotAllowed,
  clipAbsent,
  sourceUnavailable,
}

final class CharacterCustomAnimationRuntimeResult {
  const CharacterCustomAnimationRuntimeResult({
    required this.actorId,
    required this.definitionId,
    required this.status,
    this.diagnosticCode,
  });

  final String actorId;
  final String definitionId;
  final CharacterCustomAnimationRuntimeStatus status;
  final CharacterCustomAnimationRuntimeDiagnosticCode? diagnosticCode;
}

abstract interface class CharacterCustomAnimationRuntimeActor {
  String get actorId;
  ProjectCharacterEntry get character;
  EntityFacing get facing;

  bool canPlayCustomAnimation(CharacterCustomAnimationClip clip);

  void playCustomAnimation(CharacterCustomAnimationClip clip);

  void restoreBase(EntityFacing facing);
}

typedef CharacterCustomAnimationRuntimeActorLookup
    = CharacterCustomAnimationRuntimeActor? Function(String actorId);

final class CharacterCustomAnimationRuntimeController {
  CharacterCustomAnimationRuntimeController({
    required this.manifest,
    required CharacterCustomAnimationRuntimeActorLookup actorLookup,
  }) : _actorLookup = actorLookup;

  final ProjectManifest manifest;
  final CharacterCustomAnimationRuntimeActorLookup _actorLookup;
  final Map<String, _ActiveCharacterCustomAnimation> _activeByActorId =
      <String, _ActiveCharacterCustomAnimation>{};
  final Map<String, CharacterCustomAnimationRuntimeResult>
      _lastResultByActorId = <String, CharacterCustomAnimationRuntimeResult>{};

  bool isActorPlaying(String actorId) => _activeByActorId.containsKey(actorId);

  CharacterCustomAnimationRuntimeResult? lastResultFor(String actorId) =>
      _lastResultByActorId[actorId];

  Future<CharacterCustomAnimationRuntimeResult> play(
    CharacterCustomAnimationRuntimeCommand command,
  ) {
    _lastResultByActorId.remove(command.actorId);
    final current = _activeByActorId[command.actorId];
    if (current != null) {
      if (command.interruptionPolicy ==
          CharacterCustomAnimationInterruptionPolicy.rejectIfBusy) {
        return Future<CharacterCustomAnimationRuntimeResult>.value(
          _result(
            command,
            CharacterCustomAnimationRuntimeStatus.failed,
            CharacterCustomAnimationRuntimeDiagnosticCode.actorBusy,
          ),
        );
      }
      _finish(
        current,
        CharacterCustomAnimationRuntimeStatus.interrupted,
      );
    }

    final actor = _actorLookup(command.actorId);
    if (actor == null) {
      return Future<CharacterCustomAnimationRuntimeResult>.value(
        _result(
          command,
          CharacterCustomAnimationRuntimeStatus.failed,
          CharacterCustomAnimationRuntimeDiagnosticCode.actorAbsent,
        ),
      );
    }
    final definition = _definition(command.definitionId);
    if (definition == null) {
      return _failureOrFallback(
        command,
        actor,
        CharacterCustomAnimationRuntimeDiagnosticCode.definitionAbsent,
      );
    }
    if (definition.mode == CharacterCustomAnimationMode.single &&
        command.direction != null) {
      return _failureOrFallback(
        command,
        actor,
        CharacterCustomAnimationRuntimeDiagnosticCode.directionNotAllowed,
      );
    }
    if (definition.mode == CharacterCustomAnimationMode.directional &&
        command.direction == null) {
      return _failureOrFallback(
        command,
        actor,
        CharacterCustomAnimationRuntimeDiagnosticCode.directionRequired,
      );
    }
    final clip = _clipFor(
      actor.character,
      definition,
      command.direction,
    );
    if (clip == null || clip.frames.isEmpty) {
      return _failureOrFallback(
        command,
        actor,
        CharacterCustomAnimationRuntimeDiagnosticCode.clipAbsent,
      );
    }
    if (!actor.canPlayCustomAnimation(clip)) {
      return _failureOrFallback(
        command,
        actor,
        CharacterCustomAnimationRuntimeDiagnosticCode.sourceUnavailable,
      );
    }

    final cycleDurationMs = clip.frames.fold<int>(
      0,
      (sum, frame) => sum + (frame.durationMs > 0 ? frame.durationMs : 1),
    );
    final completer = Completer<CharacterCustomAnimationRuntimeResult>();
    final active = _ActiveCharacterCustomAnimation(
      command: command,
      actor: actor,
      restoreFacing: actor.facing,
      completionDurationMs: command.playback.completionDurationMs(
        cycleDurationMs: cycleDurationMs,
      ),
      completer: completer,
    );
    _activeByActorId[command.actorId] = active;
    actor.playCustomAnimation(clip);
    return completer.future;
  }

  void update(Duration delta) {
    final deltaMs = delta.inMilliseconds;
    if (deltaMs < 0) throw ArgumentError.value(delta, 'delta');
    if (deltaMs == 0 || _activeByActorId.isEmpty) return;
    for (final active in List<_ActiveCharacterCustomAnimation>.from(
      _activeByActorId.values,
    )) {
      if (!identical(_actorLookup(active.command.actorId), active.actor)) {
        _finish(
          active,
          CharacterCustomAnimationRuntimeStatus.failed,
          CharacterCustomAnimationRuntimeDiagnosticCode.actorRemoved,
        );
        continue;
      }
      active.elapsedMs += deltaMs;
      if (active.elapsedMs >= active.completionDurationMs) {
        _finish(active, CharacterCustomAnimationRuntimeStatus.completed);
      }
    }
  }

  bool interrupt(String actorId) {
    final active = _activeByActorId[actorId];
    if (active == null) return false;
    _finish(active, CharacterCustomAnimationRuntimeStatus.interrupted);
    return true;
  }

  void dispose() {
    for (final active in List<_ActiveCharacterCustomAnimation>.from(
      _activeByActorId.values,
    )) {
      _finish(active, CharacterCustomAnimationRuntimeStatus.interrupted);
    }
  }

  CharacterCustomAnimationDefinition? _definition(String definitionId) {
    for (final definition
        in manifest.characterStudioCatalog.customAnimationDefinitions) {
      if (definition.id == definitionId) return definition;
    }
    return null;
  }

  CharacterCustomAnimationClip? _clipFor(
    ProjectCharacterEntry character,
    CharacterCustomAnimationDefinition definition,
    EntityFacing? direction,
  ) {
    for (final clip in character.customAnimations) {
      if (clip.definitionId != definition.id) continue;
      if (definition.mode == CharacterCustomAnimationMode.single &&
          clip.direction == null) {
        return clip;
      }
      if (definition.mode == CharacterCustomAnimationMode.directional &&
          clip.direction == direction) {
        return clip;
      }
    }
    return null;
  }

  Future<CharacterCustomAnimationRuntimeResult> _failureOrFallback(
    CharacterCustomAnimationRuntimeCommand command,
    CharacterCustomAnimationRuntimeActor actor,
    CharacterCustomAnimationRuntimeDiagnosticCode diagnosticCode,
  ) {
    if (command.fallbackPolicy ==
        CharacterCustomAnimationFallbackPolicy.restoreBaseAndComplete) {
      actor.restoreBase(actor.facing);
      return Future<CharacterCustomAnimationRuntimeResult>.value(
        _result(
          command,
          CharacterCustomAnimationRuntimeStatus.fallbackApplied,
          diagnosticCode,
        ),
      );
    }
    return Future<CharacterCustomAnimationRuntimeResult>.value(
      _result(
        command,
        CharacterCustomAnimationRuntimeStatus.failed,
        diagnosticCode,
      ),
    );
  }

  void _finish(
    _ActiveCharacterCustomAnimation active,
    CharacterCustomAnimationRuntimeStatus status, [
    CharacterCustomAnimationRuntimeDiagnosticCode? diagnosticCode,
  ]) {
    if (!identical(_activeByActorId[active.command.actorId], active)) return;
    _activeByActorId.remove(active.command.actorId);
    active.actor.restoreBase(active.restoreFacing);
    if (!active.completer.isCompleted) {
      final result = _result(active.command, status, diagnosticCode);
      _lastResultByActorId[active.command.actorId] = result;
      active.completer.complete(
        result,
      );
    }
  }

  CharacterCustomAnimationRuntimeResult _result(
    CharacterCustomAnimationRuntimeCommand command,
    CharacterCustomAnimationRuntimeStatus status, [
    CharacterCustomAnimationRuntimeDiagnosticCode? diagnosticCode,
  ]) {
    return CharacterCustomAnimationRuntimeResult(
      actorId: command.actorId,
      definitionId: command.definitionId,
      status: status,
      diagnosticCode: diagnosticCode,
    );
  }
}

final class _ActiveCharacterCustomAnimation {
  _ActiveCharacterCustomAnimation({
    required this.command,
    required this.actor,
    required this.restoreFacing,
    required this.completionDurationMs,
    required this.completer,
  });

  final CharacterCustomAnimationRuntimeCommand command;
  final CharacterCustomAnimationRuntimeActor actor;
  final EntityFacing restoreFacing;
  final int completionDurationMs;
  final Completer<CharacterCustomAnimationRuntimeResult> completer;
  int elapsedMs = 0;
}
