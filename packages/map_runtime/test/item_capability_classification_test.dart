import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_menu_model.dart';

void main() {
  final resolver = ItemCapabilityResolver(
    ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'aurora-orb',
            displayName: 'Aurora Orb',
            pocketId: 'curios',
            capture: ProjectCaptureItemDefinition(
              rateNumerator: 3,
              rateDenominator: 2,
              allowedEncounterKinds: <EncounterKind>{EncounterKind.walk},
            ),
          ),
          ProjectItemDefinition(
            id: 'ember-tonic',
            displayName: 'Ember Tonic',
            pocketId: 'curios',
            uses: <ProjectItemUseDefinition>[
              ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.battle,
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 37,
                ),
              ),
            ],
          ),
          ProjectItemDefinition(
            id: 'poke-ball',
            displayName: 'Decorative Poke Ball',
            pocketId: 'balls',
          ),
        ],
      ),
    ),
  );

  test('capture classification comes from capture capability', () {
    expect(
      classifyBattleBagItem(itemId: 'aurora-orb', resolver: resolver),
      BattleBagItemKind.captureBall,
    );
  });

  test('medicine classification comes from a canonical battle use', () {
    expect(
      classifyBattleBagItem(itemId: 'ember-tonic', resolver: resolver),
      BattleBagItemKind.medicine,
    );
  });

  test('a familiar id without capability receives no special treatment', () {
    expect(
      classifyBattleBagItem(itemId: 'poke-ball', resolver: resolver),
      BattleBagItemKind.unsupported,
    );
  });
}
