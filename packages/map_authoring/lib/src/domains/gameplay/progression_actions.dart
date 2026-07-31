import '../../contracts/action_descriptor.dart';

/// Detached post-battle progression surface.
///
/// Actions whose catalog names contain `apply` still operate only on the
/// sandbox copy returned by the gameplay preview service.
abstract final class ProgressionActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('progression.preview_xp', 'Preview battle XP grants'),
      ('progression.apply_xp', 'Apply XP to detached player state'),
      ('progression.preview_level_up', 'Preview level and stat changes'),
      ('progression.apply_level_up', 'Apply levels to detached player state'),
      (
        'progression.preview_move_learning',
        'Inspect pending move-learning decisions',
      ),
      (
        'progression.accept_move_learning',
        'Resolve an exact move-learning acceptance',
      ),
      (
        'progression.refuse_move_learning',
        'Resolve an exact move-learning refusal',
      ),
      ('progression.preview_evolution', 'Inspect pending evolution decisions'),
      ('progression.accept_evolution', 'Resolve an exact evolution acceptance'),
      ('progression.refuse_evolution', 'Resolve an exact evolution refusal'),
      ('progression.preview_rewards', 'Preview authored battle rewards'),
      ('progression.apply_rewards', 'Apply rewards to detached player state'),
      (
        'progression.apply_capture_destination',
        'Preview runtime-owned party or box capture destination',
      ),
      ('progression.apply_badge', 'Apply a badge to detached player state'),
      (
        'progression.apply_trainer_defeated',
        'Apply trainer-defeated facts to detached player state',
      ),
    ])
      _descriptor(entry.$1, entry.$2),
  ]);
}

AuthoringActionDescriptor _descriptor(String id, String summary) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring/$id.input.v1',
    outputSchemaId: 'pokemap.authoring/$id.output.v1',
    riskLevel: id.startsWith('progression.preview_')
        ? AuthoringRiskLevel.readOnly
        : AuthoringRiskLevel.low,
    resourceKinds: const ['battleProgression', 'sandboxPlayerState'],
    capabilityIds: const ['authoring.battle.progression'],
    requiredPermissions: const [AuthoringPermission.playtestControl],
    guarantees: const [AuthoringGuarantee.dryRun],
    extensions: const {
      'productionWriteAllowed': false,
      'sandboxOnly': true,
    },
  );
}
