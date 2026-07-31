import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('battle and progression actions are playtest-only and non-mutating', () {
    final descriptors = <AuthoringActionDescriptor>[
      ...BattleActions.descriptors,
      ...ProgressionActions.descriptors,
    ];

    expect(
      descriptors.map((entry) => entry.id),
      containsAll(<String>{
        'battle.setup_build_wild',
        'battle.setup_build_trainer',
        'battle.setup_build_static',
        'battle.simulate',
        'battle.inspect_timeline',
        'battle.apply_outcome_plan',
        'battle.receipt_get',
        'progression.preview_xp',
        'progression.preview_move_learning',
        'progression.accept_move_learning',
        'progression.preview_evolution',
        'progression.accept_evolution',
        'progression.preview_rewards',
        'progression.apply_capture_destination',
      }),
    );
    expect(
      descriptors.every(
        (entry) =>
            entry.requiredPermissions
                .contains(AuthoringPermission.playtestControl) &&
            !entry.requiredPermissions
                .contains(AuthoringPermission.projectWrite) &&
            entry.extensions['productionWriteAllowed'] == false,
      ),
      isTrue,
    );
    final battleActionIds =
        BattleActions.descriptors.map((entry) => entry.id).toSet();
    for (final unsupported in const <String>[
      'battle.choose_target',
      'battle.pause',
      'battle.resume',
      'battle.inject_rng_probe_only',
      'battle.apply_outcome_apply',
    ]) {
      expect(battleActionIds, isNot(contains(unsupported)));
    }
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((entry) => entry.id),
      isNot(contains('battle.simulate')),
    );
  });
}
