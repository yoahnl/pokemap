import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/golden_item_system_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ITM-071 executes the deterministic Golden Item System flow', () async {
    final fixtureRoot = p.join(Directory.current.path, 'golden_item_system');
    final firstSaveRoot = await Directory.systemTemp.createTemp(
      'golden-item-system-first-',
    );
    final secondSaveRoot = await Directory.systemTemp.createTemp(
      'golden-item-system-second-',
    );
    addTearDown(() async {
      await firstSaveRoot.delete(recursive: true);
      await secondSaveRoot.delete(recursive: true);
    });

    final first = await GoldenItemSystemJourney.run(
      projectRootDirectory: fixtureRoot,
      saveRootDirectory: firstSaveRoot.path,
      sourceRevision: '0000000000000000000000000000000000000047',
      rngSeed: 47,
    );
    final second = await GoldenItemSystemJourney.run(
      projectRootDirectory: fixtureRoot,
      saveRootDirectory: secondSaveRoot.path,
      sourceRevision: '0000000000000000000000000000000000000047',
      rngSeed: 47,
    );

    expect(first.toJson(), second.toJson());
    expect(first.schemaVersion, 1);
    expect(first.projectId, 'golden_item_system');
    expect(first.sourceRevision, '0000000000000000000000000000000000000047');
    expect(first.rngSeed, 47);
    expect(first.fixtureSha256, hasLength(64));
    expect(first.finalStateSha256, hasLength(64));
    expect(first.steps, const <String>[
      'new_game',
      'initial_items',
      'pickup',
      'overworld_heal',
      'buy',
      'sell',
      'battle_item',
      'capture_attempt',
      'equip_held_item',
      'learn_move_tm',
      'learn_move_hm',
      'battle_reward',
      'save_reload',
    ]);
    expect(
      first.observations,
      containsAll(<String>{
        'new_game_from_project',
        'initial_bag_strict',
        'pickup_scenario_applied',
        'pickup_scenario_idempotent',
        'status_cured_overworld',
        'pp_restored_overworld',
        'hp_healed_overworld',
        'shop_purchase_applied',
        'shop_sale_applied',
        'battle_damage_applied',
        'battle_item_applied',
        'capture_succeeded',
        'held_item_equipped',
        'tm_learned',
        'hm_compatible_target_selected',
        'hm_learned_without_consumption',
        'field_ability_still_locked_after_hm',
        'trainer_reward_applied',
        'field_ability_unlocked_by_reward',
        'party_member_fainted_in_battle',
        'revived_overworld',
        'key_item_gate_preserved',
        'passive_item_preserved',
        'strict_save_wire_written',
        'runtime_save_reloaded',
        'hm_and_explicit_surf_gate_persisted',
      }),
    );
    expect(first.finalBagQuantities, const <String, int>{
      'ether': 1,
      'hm-surf': 1,
      'lab-key': 1,
      'lucky-charm': 1,
      'poke-ball': 2,
    });
    expect(first.finalMoney, 1090);
    expect(first.finalPartySpeciesIds, const <String>[
      'sproutle',
      'sparkitten',
    ]);
    expect(first.finalHeldItemIds, const <String>['leftovers', '']);
    expect(first.finalKnownMoveIds.first, const <String>[
      'tackle',
      'surf',
      'leech-seed',
      'protect',
    ]);
    expect(first.completedStepIds, contains('golden_item.pickup'));
    expect(first.storyFlagIds, contains('golden_item.pickup_collected'));
  });
}
