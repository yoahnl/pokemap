part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspaceInspector on CinematicWorkspaceController {
  ProjectManifest projectWith(CinematicAsset asset) => _with(asset);

  bool editFromInspector(
    String ownerId,
    CinematicAsset Function(CinematicAsset) transform,
    CinematicInputState inputs,
  ) {
    if (active?.asset.id != ownerId) return false;
    final accepted = edit((current) => _keepPaths(current, transform(current)));
    if (!accepted) {
      inputs.error = inputs.inspectorError = error;
    } else if (inputs.error == inputs.inspectorError) {
      inputs.error = inputs.inspectorError = null;
    }
    return accepted;
  }
}

const cinematicStepDurationError =
    'Saisissez une durée entière strictement positive.';
const cinematicJumpDurationError =
    'La durée du saut doit être comprise entre 200 et 30000 ms.';
const cinematicJumpHeightError =
    'La hauteur doit être supérieure à 0 et au plus égale à 4 cases.';
const cinematicAnimationCountError =
    'Saisissez une valeur entière strictement positive.';

String cinematicInvalidNumberError(String label) =>
    'Valeur invalide pour « $label ».';

double? parseCinematicCommandNumber(
  String text, {
  double? max,
  bool integer = false,
}) {
  final number = double.tryParse(text);
  if (number == null ||
      !number.isFinite ||
      number < 0 ||
      (max != null && number > max) ||
      (integer && number != number.roundToDouble())) {
    return null;
  }
  return number;
}

String? cinematicStepDurationProblem(CinematicTimelineStep step, int? duration) {
  if (isCinematicTimelineActorJumpStep(step) &&
      (duration == null ||
          duration < cinematicTimelineActorMoveMinimumDurationMs ||
          duration > cinematicTimelineMaximumDurationMs)) {
    return cinematicJumpDurationError;
  }
  if (duration == null || duration <= 0) return cinematicStepDurationError;
  return null;
}

double? parseCinematicJumpHeight(String text) {
  final height = double.tryParse(text);
  if (height == null ||
      !height.isFinite ||
      height <= 0 ||
      height > cinematicTimelineActorJumpMaximumHeightCells) {
    return null;
  }
  return height;
}

int? parseCinematicAnimationCount(String text) {
  final number = int.tryParse(text);
  return number == null || number <= 0 ? null : number;
}

CharacterCustomAnimationPlayback cinematicAnimationPlaybackFor(
  String kind,
) => switch (kind) {
  'repeatCount' => CharacterCustomAnimationPlayback.repeatCount(2),
  'forDuration' => CharacterCustomAnimationPlayback.forDuration(1000),
  _ => CharacterCustomAnimationPlayback.once(),
};

CharacterCustomAnimationPlayback cinematicAnimationPlaybackWithCount(
  CharacterCustomAnimationPlayback playback,
  int count,
) => playback.kind == CharacterCustomAnimationPlaybackKind.repeatCount
    ? CharacterCustomAnimationPlayback.repeatCount(count)
    : CharacterCustomAnimationPlayback.forDuration(count);

CharacterCustomAnimationRuntimeCommand cinematicAnimationCommandWith(
  CharacterCustomAnimationRuntimeCommand command, {
  CharacterCustomAnimationClip? clip,
  CharacterCustomAnimationPlayback? playback,
}) => CharacterCustomAnimationRuntimeCommand(
  actorId: command.actorId,
  definitionId: clip?.definitionId ?? command.definitionId,
  direction: clip == null ? command.direction : clip.direction,
  playback: playback ?? command.playback,
  interruptionPolicy: command.interruptionPolicy,
  fallbackPolicy: command.fallbackPolicy,
);

extension CinematicWorkspaceInspectorInputs on CinematicWorkspaceController {
  bool commitCommandNumber(
    String ownerId,
    CinematicInputState inputs,
    String label,
    String text,
    CinematicAsset Function(CinematicAsset, double) transform, {
    double? max,
    bool integer = false,
  }) {
    final message = cinematicInvalidNumberError(label);
    final number = parseCinematicCommandNumber(
      text,
      max: max,
      integer: integer,
    );
    if (number == null) {
      inputs.error = message;
      return false;
    }
    final accepted = editFromInspector(
      ownerId,
      (asset) => transform(asset, number),
      inputs,
    );
    if (accepted && inputs.error == message) inputs.error = null;
    return accepted;
  }

  bool commitStepDuration(
    String ownerId,
    CinematicInputState inputs,
    CinematicTimelineStep step,
    String text,
  ) {
    if (active?.asset.id != ownerId) return false;
    final duration = int.tryParse(text);
    final problem = cinematicStepDurationProblem(step, duration);
    if (problem != null) {
      inputs.error = problem;
      return false;
    }
    final accepted = updateDuration(step.id, duration!);
    if (accepted &&
        (inputs.error == cinematicStepDurationError ||
            inputs.error == cinematicJumpDurationError)) {
      inputs.error = null;
    }
    return accepted;
  }

  bool commitJumpHeight(
    String ownerId,
    CinematicInputState inputs,
    CinematicTimelineStep step,
    String text,
  ) {
    final height = parseCinematicJumpHeight(text);
    if (height == null) {
      inputs.error = cinematicJumpHeightError;
      return false;
    }
    final accepted = editFromInspector(
      ownerId,
      (asset) => updateCinematicTimelineActorJumpStep(
        _with(asset),
        cinematicId: asset.id,
        stepId: step.id,
        heightCells: height,
      ).cinematic,
      inputs,
    );
    if (accepted && inputs.error == cinematicJumpHeightError) {
      inputs.error = null;
    }
    return accepted;
  }

  bool updateAnimationFromInspector(
    String ownerId,
    CinematicInputState inputs,
    String stepId,
    CharacterCustomAnimationRuntimeCommand command,
  ) {
    if (activeId != ownerId) return false;
    final accepted = updateAnimation(stepId, command);
    if (!accepted) {
      inputs.error = inputs.inspectorError = error;
    } else if (inputs.error == inputs.inspectorError) {
      inputs.error = inputs.inspectorError = null;
    }
    return accepted;
  }

  bool commitAnimationCount(
    String ownerId,
    CinematicInputState inputs,
    String stepId,
    CharacterCustomAnimationRuntimeCommand command,
    String text,
  ) {
    final count = parseCinematicAnimationCount(text);
    if (count == null) {
      inputs.error = inputs.inspectorError = cinematicAnimationCountError;
      return false;
    }
    return updateAnimationFromInspector(
      ownerId,
      inputs,
      stepId,
      cinematicAnimationCommandWith(
        command,
        playback: cinematicAnimationPlaybackWithCount(command.playback, count),
      ),
    );
  }
}
