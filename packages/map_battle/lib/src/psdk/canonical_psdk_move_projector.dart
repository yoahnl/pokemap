import 'package:map_core/map_core.dart';

import '../battle_type_chart.dart';
import '../data/generated/psdk_move_registry_manifest.dart';
import '../data/psdk_move_method_index.dart';
import 'domain/psdk_battle_move.dart';

class CanonicalPsdkMoveProjectionException implements Exception {
  const CanonicalPsdkMoveProjectionException(this.reason);

  final String reason;
}

class CanonicalPsdkMoveProjector {
  const CanonicalPsdkMoveProjector();

  PsdkBattleMoveData project({
    required PokemonMove move,
    int? currentPp,
  }) {
    final battleEngineMethod = resolveBattleEngineMethod(move);
    if (battleEngineMethod == null) {
      throw CanonicalPsdkMoveProjectionException(
          'psdk_battle_engine_method_not_found');
    }
    final registryStatus = registryStatusFor(battleEngineMethod);
    if (registryStatus != PsdkPortStatus.ported.name) {
      throw CanonicalPsdkMoveProjectionException(
          'psdk_battle_engine_method_not_ported:$battleEngineMethod');
    }

    return PsdkBattleMoveData(
      id: move.id,
      dbSymbol: move.id,
      name: move.name,
      type: _translateType(move),
      category: _translatePsdkCategory(move.category),
      power: move.basePower < 0 ? 0 : move.basePower,
      accuracy: _translatePsdkAccuracy(move.accuracy),
      pp: move.pp,
      currentPp: currentPp,
      priority: move.priority,
      criticalRate: move.critRatio,
      battleEngineMethod: battleEngineMethod,
      target: _translatePsdkTarget(move.target),
      contact: move.flags.contains(PokemonMoveFlag.contact),
      sound: move.flags.contains(PokemonMoveFlag.sound),
      bite: move.flags.contains(PokemonMoveFlag.bite),
      pulse: move.flags.contains(PokemonMoveFlag.pulse),
      wind: move.flags.contains(PokemonMoveFlag.wind),
      ballistics: move.flags.contains(PokemonMoveFlag.bullet),
      dance: move.flags.contains(PokemonMoveFlag.dance),
      heal: move.flags.contains(PokemonMoveFlag.heal),
      charge: move.flags.contains(PokemonMoveFlag.charge),
      recharge: move.flags.contains(PokemonMoveFlag.recharge),
      snatchable: move.flags.contains(PokemonMoveFlag.snatch),
      magicCoatAffected: move.flags.contains(PokemonMoveFlag.reflectable),
      statuses: _psdkStatusesFor(move),
      stageMods: _psdkStageModsFor(move),
    );
  }

  String? resolveBattleEngineMethod(PokemonMove move) {
    final explicitMethod = _extractUnsupportedReasonValue(
      move.unsupportedReasons,
      'psdk_method:',
    );
    if (explicitMethod != null) {
      return explicitMethod;
    }

    final normalizedMoveId = move.id.trim().toLowerCase();
    final normalizedShowdownMoveId =
        move.sourceRefs.showdownMoveId?.trim().toLowerCase();
    final sourceIds = <String>{
      normalizedMoveId,
      if (normalizedShowdownMoveId != null &&
          normalizedShowdownMoveId.isNotEmpty)
        normalizedShowdownMoveId,
    };

    for (final sourceId in sourceIds) {
      final method = _knownPsdkMethodByMoveId[sourceId];
      if (method != null) {
        return method;
      }
      final psdkMethod = psdkBattleEngineMethodForMoveId(sourceId);
      if (psdkMethod != null) {
        return psdkMethod;
      }
    }

    if (move.usesStandardDamageFlow) {
      return 's_basic';
    }

    return null;
  }

  String? registryStatusFor(String? battleEngineMethod) {
    if (battleEngineMethod == null) {
      return null;
    }
    for (final entry in psdkMoveRegistryManifest) {
      if (entry.battleEngineMethod == battleEngineMethod) {
        return entry.status.name;
      }
    }
    return null;
  }

  String _translateType(PokemonMove move) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      throw const CanonicalPsdkMoveProjectionException('invalid_type:empty');
    }
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      throw CanonicalPsdkMoveProjectionException(
          'unsupported_type:$normalizedType');
    }
    return normalizedType;
  }

  PsdkBattleMoveCategory _translatePsdkCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => PsdkBattleMoveCategory.physical,
      PokemonMoveCategory.special => PsdkBattleMoveCategory.special,
      PokemonMoveCategory.status => PsdkBattleMoveCategory.status,
    };
  }

  int _translatePsdkAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => accuracy.value,
      alwaysHits: (_) => 0,
    );
  }

  PsdkBattleMoveTarget _translatePsdkTarget(PokemonMoveTarget target) {
    return switch (target) {
      PokemonMoveTarget.adjacentAlly => PsdkBattleMoveTarget.adjacentAlly,
      PokemonMoveTarget.adjacentAllyOrSelf =>
        PsdkBattleMoveTarget.adjacentAllyOrSelf,
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.normal =>
        PsdkBattleMoveTarget.adjacentFoe,
      PokemonMoveTarget.all => PsdkBattleMoveTarget.allBattlers,
      PokemonMoveTarget.allAdjacent => PsdkBattleMoveTarget.allAdjacent,
      PokemonMoveTarget.allAdjacentFoes => PsdkBattleMoveTarget.allAdjacentFoes,
      PokemonMoveTarget.allies ||
      PokemonMoveTarget.allyTeam =>
        PsdkBattleMoveTarget.allAllies,
      PokemonMoveTarget.allySide => PsdkBattleMoveTarget.userSide,
      PokemonMoveTarget.any => PsdkBattleMoveTarget.anyFoe,
      PokemonMoveTarget.foeSide => PsdkBattleMoveTarget.foeSide,
      PokemonMoveTarget.randomNormal => PsdkBattleMoveTarget.randomFoe,
      PokemonMoveTarget.scripted => PsdkBattleMoveTarget.none,
      PokemonMoveTarget.self => PsdkBattleMoveTarget.user,
    };
  }

  List<PsdkBattleMoveStatus> _psdkStatusesFor(PokemonMove move) {
    final statuses = <PsdkBattleMoveStatus>[];
    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) {},
        multiHit: (_) {},
        applyStatus: (effect) {
          final status = _psdkMajorStatusFor(effect.statusId);
          if (status != null) {
            statuses.add(
              PsdkBattleMoveStatus(
                status: status,
                chance: effect.chance ?? 100,
              ),
            );
          }
        },
        applyVolatileStatus: (effect) {
          final status = _psdkVolatileStatusFor(effect.volatileStatusId);
          if (status != null) {
            statuses.add(
              PsdkBattleMoveStatus.volatile(
                status: status,
                chance: effect.chance ?? 100,
              ),
            );
          }
        },
        modifyStats: (_) {},
        heal: (_) {},
        drain: (_) {},
        recoil: (_) {},
        setWeather: (_) {},
        setTerrain: (_) {},
        setPseudoWeather: (_) {},
        selfSwitch: (_) {},
        forceSwitch: (_) {},
        breakProtect: (_) {},
        requireRecharge: (_) {},
        chargeThenStrike: (_) {},
        setSideCondition: (_) {},
        setSlotCondition: (_) {},
      );
    }
    return List<PsdkBattleMoveStatus>.unmodifiable(statuses);
  }

  List<PsdkBattleMoveStageMod> _psdkStageModsFor(PokemonMove move) {
    final stageMods = <PsdkBattleMoveStageMod>[];
    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) {},
        multiHit: (_) {},
        applyStatus: (_) {},
        applyVolatileStatus: (_) {},
        modifyStats: (effect) {
          for (final change in effect.stageChanges) {
            stageMods.add(
              PsdkBattleMoveStageMod(
                stat: _psdkStatNameFor(change.stat),
                stages: change.stages,
                chance: effect.chance,
              ),
            );
          }
        },
        heal: (_) {},
        drain: (_) {},
        recoil: (_) {},
        setWeather: (_) {},
        setTerrain: (_) {},
        setPseudoWeather: (_) {},
        selfSwitch: (_) {},
        forceSwitch: (_) {},
        breakProtect: (_) {},
        requireRecharge: (_) {},
        chargeThenStrike: (_) {},
        setSideCondition: (_) {},
        setSlotCondition: (_) {},
      );
    }
    return List<PsdkBattleMoveStageMod>.unmodifiable(stageMods);
  }

  PsdkBattleMajorStatus? _psdkMajorStatusFor(String statusId) {
    return switch (statusId.trim().toLowerCase()) {
      'par' || 'paralysis' => PsdkBattleMajorStatus.paralysis,
      'brn' || 'burn' => PsdkBattleMajorStatus.burn,
      'psn' || 'poison' => PsdkBattleMajorStatus.poison,
      'tox' || 'toxic' => PsdkBattleMajorStatus.toxic,
      'slp' || 'sleep' => PsdkBattleMajorStatus.sleep,
      'frz' || 'freeze' => PsdkBattleMajorStatus.freeze,
      _ => null,
    };
  }

  PsdkBattleVolatileStatus? _psdkVolatileStatusFor(String statusId) {
    return switch (statusId.trim().toLowerCase()) {
      'confusion' || 'confused' => PsdkBattleVolatileStatus.confusion,
      'flinch' => PsdkBattleVolatileStatus.flinch,
      _ => null,
    };
  }

  String _psdkStatNameFor(PokemonMoveStatId stat) {
    return switch (stat) {
      PokemonMoveStatId.attack => 'attack',
      PokemonMoveStatId.defense => 'defense',
      PokemonMoveStatId.specialAttack => 'specialAttack',
      PokemonMoveStatId.specialDefense => 'specialDefense',
      PokemonMoveStatId.speed => 'speed',
      PokemonMoveStatId.accuracy => 'accuracy',
      PokemonMoveStatId.evasion => 'evasion',
    };
  }
}

String? _extractUnsupportedReasonValue(List<String> reasons, String prefix) {
  for (final reason in reasons) {
    if (reason.startsWith(prefix)) {
      final value = reason.substring(prefix.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

const _knownPsdkMethodByMoveId = <String, String>{
  'baton_pass': 's_baton_pass',
  'copycat': 's_mirror_move',
  'counter': 's_counter',
  'endure': 's_protect',
  'helping_hand': 's_helping_hand',
  'helpinghand': 's_helping_hand',
  'protect': 's_protect',
  'quick_guard': 's_protect',
  'quickguard': 's_protect',
  'transform': 's_transform',
};
