import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

/// Récompense de progression après un boss — BETA-TRN-004.
///
/// Chaque brique existait (récompense exactly-once PRG-005, badge, capacité
/// terrain, flags, états de boutique conditionnels, conditions des tables de
/// rencontre), mais rien ne prouvait LA CHAÎNE : battre un boss applique
/// badge + Surf + flag en une transaction, et ce flag bascule une boutique
/// ET une zone de rencontre conditionnelles — puis tout survit au reload.
const String _bossFlag = 'story:harbor_boss_defeated';
const String _bossBadge = 'tide_badge';

BattleReward _bossReward() => BattleReward(
      sourceKind: BattleRewardSourceKind.trainer,
      trainerId: 'harbor_boss',
      money: 1200,
      badgeId: _bossBadge,
      fieldAbilityUnlock: FieldAbility.surf,
      flagIds: const <String>{_bossFlag},
    );

ShopDefinition _conditionalShop() => ShopDefinition(
      id: 'harbor_shop',
      label: 'Échoppe du port',
      entries: const <ShopEntryDefinition>[
        ShopEntryDefinition(itemId: 'potion', price: 200),
      ],
      states: <ShopStateDefinition>[
        ShopStateDefinition(
          id: 'champion_stock',
          label: 'Stock du champion',
          priority: 10,
          activation: const ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: <String, String>{
              ScriptConditionParams.flagName: _bossFlag,
            },
          ),
          storefrontLabel: 'Échoppe du champion',
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'super-potion', price: 600),
          ],
        ),
      ],
    );

ProjectManifest _projectWithConditionalGrass() => ProjectManifest(
      name: 'TRN-004 chain',
      pokemon: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        enabled: true,
      ),
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'harbor',
          name: 'Harbor',
          relativePath: 'maps/harbor.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      encounterTables: <ProjectEncounterTable>[
        ProjectEncounterTable(
          id: 'champion_grass',
          name: 'Champion grass',
          encounterKind: EncounterKind.walk,
          chancePerStep: 1,
          conditions: const <ScriptCondition>[
            ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: <String, String>{
                ScriptConditionParams.flagName: _bossFlag,
              },
            ),
          ],
          entries: const <ProjectEncounterEntry>[
            ProjectEncounterEntry(
              speciesId: 'rare_visitor',
              minLevel: 20,
              maxLevel: 20,
            ),
          ],
        ),
      ],
    );

MapData _mapWithGrass() => const MapData(
      id: 'harbor',
      name: 'Harbor',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 3),
      gameplayZones: <MapGameplayZone>[
        MapGameplayZone(
          id: 'champion_zone',
          name: 'Champion zone',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 3, height: 3),
          ),
          encounter: EncounterZonePayload(
            encounterTableId: 'champion_grass',
            encounterKind: EncounterKind.walk,
          ),
        ),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

GameplayEncounterCheckResult _checkGrass(GameState gameState) {
  final world = GameplayWorldState.fromMap(
    _mapWithGrass(),
    project: _projectWithConditionalGrass(),
    tileWidth: 16,
    tileHeight: 16,
  );
  return checkEncounterAtPlayerPosition(
    world: world,
    project: _projectWithConditionalGrass(),
    encounterKind: EncounterKind.walk,
    gameState: gameState,
    random: _AlwaysTriggerRandom(),
    policy: const GameplayEncounterPolicy(chancePerStep: 1),
  );
}

void main() {
  const mutations = GameStateMutations();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);

  group('BETA-TRN-004 one boss reward switches the world', () {
    final before = GameState(saveId: 'trn004');

    test('before the boss: locked shop, gated grass, no badge, no surf', () {
      expect(before.trainerProfile.badgeIds, isEmpty);
      expect(
        before.progression.unlockedFieldAbilities.contains(FieldAbility.surf),
        isFalse,
      );

      final shopState = const ShopStateResolver().resolve(
        shop: _conditionalShop(),
        gameState: before,
      );
      expect(shopState.isDefault, isTrue);

      expect(
        _checkGrass(before).status,
        GameplayEncounterCheckStatus.conditionsNotMet,
      );
    });

    test('the reward applies badge, surf and flag in one transaction, and '
        'the conditional shop and grass both switch', () {
      final after = mutations.applyBattleRewards(
        before,
        reward: _bossReward(),
        itemCatalog: itemCatalog,
      );

      expect(after.trainerProfile.badgeIds, <String>[_bossBadge]);
      expect(after.trainerProfile.money, 1200);
      expect(after.progression.unlockedFieldAbilities.contains(FieldAbility.surf), isTrue);
      expect(after.storyFlags.activeFlags, contains(_bossFlag));

      final shopState = const ShopStateResolver().resolve(
        shop: _conditionalShop(),
        gameState: after,
      );
      expect(shopState.stateId, 'champion_stock');
      expect(shopState.storefrontLabel, 'Échoppe du champion');

      final encounter = _checkGrass(after);
      expect(encounter.status, GameplayEncounterCheckStatus.triggered);
      expect(encounter.encounter!.speciesId, 'rare_visitor');
    });

    test('the switched world survives a save/reload round trip', () {
      final after = mutations.applyBattleRewards(
        before,
        reward: _bossReward(),
        itemCatalog: itemCatalog,
      );

      final reloaded = gameStateFromSaveData(saveDataFromGameState(after));

      expect(reloaded.trainerProfile.badgeIds, <String>[_bossBadge]);
      expect(
        reloaded.progression.unlockedFieldAbilities.contains(FieldAbility.surf),
        isTrue,
      );
      expect(
        const ShopStateResolver()
            .resolve(shop: _conditionalShop(), gameState: reloaded)
            .stateId,
        'champion_stock',
      );
      expect(
        _checkGrass(reloaded).status,
        GameplayEncounterCheckStatus.triggered,
      );
    });

    test('replaying the same reward grants nothing twice', () {
      final once = mutations.applyBattleRewards(
        before,
        reward: _bossReward(),
        itemCatalog: itemCatalog,
      );
      final twice = mutations.applyBattleRewards(
        once,
        reward: _bossReward(),
        itemCatalog: itemCatalog,
      );

      expect(
        twice.trainerProfile.badgeIds,
        <String>[_bossBadge],
        reason: 'the badge stays unique across a duplicate grant',
      );
      // L'argent, lui, est protégé par l'exactly-once du coordinateur
      // (completedBattleRequestIds) : au niveau mutation pure, il s'ajoute.
      expect(twice.trainerProfile.money, 2400);
    });
  });
}

final class _AlwaysTriggerRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
