import '../../contracts/action_descriptor.dart';

/// Protocol-neutral battle playtest surface.
///
/// Stateful pause/resume, arbitrary RNG probes, manual target selection and
/// production outcome application are intentionally not advertised.
abstract final class BattleActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('battle.setup_validate', 'Validate a map_battle setup'),
      ('battle.setup_build_wild', 'Build a wild battle setup'),
      ('battle.setup_build_trainer', 'Build a trainer battle setup'),
      ('battle.setup_build_static', 'Build a static encounter setup'),
      ('battle.inspect_state', 'Inspect one simulation state snapshot'),
      ('battle.inspect_timeline', 'Inspect the ordered simulation trace'),
      ('battle.choose_move', 'Script one exact move choice'),
      ('battle.switch', 'Script one exact reserve switch'),
      ('battle.capture', 'Script one capture attempt'),
      ('battle.run', 'Script one flee attempt'),
      ('battle.advance', 'Advance one forced continuation'),
      ('battle.resolve_all', 'Resolve until a terminal outcome'),
      ('battle.inject_seed', 'Select the deterministic simulation seed'),
      ('battle.apply_outcome_plan', 'Preview terminal write-back data'),
      ('battle.simulate', 'Run one seeded deterministic battle'),
      ('battle.receipt_get', 'Read the deterministic simulation receipt'),
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
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['battleProgression'],
    capabilityIds: const ['authoring.battle.simulation'],
    requiredPermissions: const [AuthoringPermission.playtestControl],
    guarantees: const [AuthoringGuarantee.dryRun],
    extensions: const {
      'deterministic': true,
      'productionWriteAllowed': false,
    },
  );
}
