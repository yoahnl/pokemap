import 'dart:convert';
import 'dart:io';

import 'generated/psdk_move_registry_manifest.dart';

final class PsdkStudioMoveCoverageEntry {
  const PsdkStudioMoveCoverageEntry({
    required this.dbSymbol,
    required this.battleEngineMethod,
    required this.type,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.sourceFile,
    this.priority = 0,
    this.criticalRate = 1,
    this.effectChance = 0,
    this.battleStageModCount = 0,
    this.battleStageMods = const <PsdkStudioStageModCoverageEntry>[],
    this.moveStatusCount = 0,
    this.moveStatuses = const <PsdkStudioStatusCoverageEntry>[],
    this.target = '',
    this.protectable = true,
    this.sound = false,
    this.ballistics = false,
    this.kingRockUtility = false,
  });

  final String dbSymbol;
  final String battleEngineMethod;
  final String type;
  final String category;
  final int power;
  final String accuracy;
  final int pp;
  final String sourceFile;
  final int priority;
  final int criticalRate;
  final int effectChance;
  final int battleStageModCount;
  final List<PsdkStudioStageModCoverageEntry> battleStageMods;
  final int moveStatusCount;
  final List<PsdkStudioStatusCoverageEntry> moveStatuses;
  final String target;
  final bool protectable;
  final bool sound;
  final bool ballistics;
  final bool kingRockUtility;

  bool get isStrictPlainBasicDamage {
    if (battleEngineMethod != 's_basic') {
      return false;
    }
    if (!_hasStrictBasicDamageShape) {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictBasicDamageWithSupportedRider {
    if (battleEngineMethod != 's_basic') {
      return false;
    }
    if (!_hasStrictBasicDamageShape) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictBasicDamageRiderTargets.contains(normalizedTarget)) {
      return false;
    }
    if (effectChance < 1 || effectChance > 100) {
      return false;
    }
    if (battleStageModCount > 0) {
      if (moveStatusCount != 0 ||
          battleStageMods.length != battleStageModCount) {
        return false;
      }
      return battleStageMods.every((mod) {
        return mod.stages != 0 && _strictStatChangeStats.contains(mod.stat);
      });
    }
    if (moveStatusCount > 0) {
      if (battleStageModCount != 0 || moveStatuses.length != moveStatusCount) {
        return false;
      }
      return moveStatuses.every((status) {
        return _strictMajorStatuses.contains(status.status) ||
            status.status == 'confusion' ||
            status.status == 'flinch';
      });
    }
    return false;
  }

  bool get isStrictWeatherAccuracyBasic {
    if (battleEngineMethod != 's_basic' || dbSymbol != 'blizzard') {
      return false;
    }
    if (type.trim().toLowerCase() != 'ice' ||
        category.trim().toLowerCase() != 'special' ||
        power <= 0) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty && normalizedTarget != 'adjacent_all_foe') {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 1 &&
        moveStatuses.single.status == 'freeze' &&
        effectChance == 10;
  }

  bool get isStrictGenericZMovePlaceholder {
    if (battleEngineMethod != 's_basic') {
      return false;
    }
    final normalizedSymbol = dbSymbol.trim().toLowerCase();
    final expectedType = _strictGenericZMovePlaceholderTypes[normalizedSymbol];
    if (expectedType == null) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    final expectedCategory =
        normalizedSymbol.endsWith('2') ? 'special' : 'physical';
    final normalizedTarget = target.trim().toLowerCase();
    return type.trim().toLowerCase() == expectedType &&
        normalizedCategory == expectedCategory &&
        power == 0 &&
        accuracy.trim() == '0' &&
        pp == 1 &&
        priority == 0 &&
        criticalRate == 1 &&
        effectChance == 0 &&
        battleStageModCount == 0 &&
        battleStageMods.isEmpty &&
        moveStatusCount == 0 &&
        moveStatuses.isEmpty &&
        normalizedTarget == 'adjacent_pokemon' &&
        !protectable &&
        !sound &&
        !ballistics &&
        kingRockUtility;
  }

  bool get isStrictOffensiveSignatureZMove {
    if (battleEngineMethod != 's_z_move') {
      return false;
    }
    final normalizedSymbol = dbSymbol.trim().toLowerCase();
    final spec = _strictOffensiveSignatureZMoves[normalizedSymbol];
    if (spec == null) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    final targetMatches = spec.target == normalizedTarget ||
        (spec.target == 'adjacent_pokemon' &&
            normalizedTarget == 'adjacent_foe');
    if (!targetMatches) {
      return false;
    }
    final expectedStatuses = spec.statuses;
    final statusesMatch = expectedStatuses.isEmpty
        ? moveStatusCount == 0 && moveStatuses.isEmpty && effectChance == 0
        : moveStatusCount == expectedStatuses.length &&
            moveStatuses.length == expectedStatuses.length &&
            effectChance == 100 &&
            _sameStatusSet(moveStatuses, expectedStatuses);
    return type.trim().toLowerCase() == spec.type &&
        category.trim().toLowerCase() == spec.category &&
        power == spec.power &&
        accuracy.trim() == '0' &&
        pp == 1 &&
        priority == 0 &&
        criticalRate == spec.criticalRate &&
        battleStageModCount == 0 &&
        battleStageMods.isEmpty &&
        statusesMatch &&
        !protectable &&
        !sound &&
        !ballistics &&
        kingRockUtility;
  }

  bool get isStrictSecretSwordStudioAlias {
    if (battleEngineMethod != 's_basic' || dbSymbol != 'secret_sword') {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    return type.trim().toLowerCase() == 'fighting' &&
        category.trim().toLowerCase() == 'special' &&
        power == 85 &&
        accuracy.trim() == '100' &&
        pp == 10 &&
        priority == 0 &&
        criticalRate == 1 &&
        effectChance == 100 &&
        battleStageModCount == 0 &&
        battleStageMods.isEmpty &&
        moveStatusCount == 0 &&
        moveStatuses.isEmpty &&
        (normalizedTarget.isEmpty || normalizedTarget == 'adjacent_pokemon');
  }

  bool get _hasStrictBasicDamageShape {
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    return normalizedCategory == 'physical' || normalizedCategory == 'special';
  }

  bool get isStrictSelfStatBoost {
    if (battleEngineMethod != 's_self_stat') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    if (moveStatusCount != 0) {
      return false;
    }
    if (effectChance != 0 && effectChance != 100) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        normalizedTarget != 'user' &&
        normalizedTarget != 'self') {
      return false;
    }
    if (battleStageMods.isEmpty ||
        battleStageMods.length != battleStageModCount) {
      return false;
    }
    return battleStageMods.every((mod) {
      return mod.stages != 0 && _strictSelfStatBoostStats.contains(mod.stat);
    });
  }

  bool get isStrictDamagingSelfStatRider {
    if (battleEngineMethod != 's_self_stat') {
      return false;
    }
    if (!_hasStrictBasicDamageShape) {
      return false;
    }
    if (moveStatusCount != 0) {
      return false;
    }
    if (effectChance < 1 || effectChance > 100) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictSelfStatDamageTargets.contains(normalizedTarget)) {
      return false;
    }
    if (battleStageMods.isEmpty ||
        battleStageMods.length != battleStageModCount) {
      return false;
    }
    return battleStageMods.every((mod) {
      return mod.stages != 0 && _strictStatChangeStats.contains(mod.stat);
    });
  }

  bool get isStrictTargetStatChange {
    if (battleEngineMethod != 's_stat') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    if (effectChance != 0 && effectChance != 100) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictTargetStatChangeTargets.contains(normalizedTarget)) {
      return false;
    }
    if (battleStageMods.isEmpty ||
        battleStageMods.length != battleStageModCount) {
      return false;
    }
    final stageModsSupported = battleStageMods.every((mod) {
      return mod.stages != 0 && _strictStatChangeStats.contains(mod.stat);
    });
    if (!stageModsSupported) {
      return false;
    }
    if (moveStatusCount == 0) {
      return true;
    }
    if (moveStatuses.length != 1 || moveStatusCount != 1) {
      return false;
    }
    return _strictMajorStatuses.contains(moveStatuses.single.status) ||
        moveStatuses.single.status == 'confusion';
  }

  bool get isStrictMajorStatus {
    if (battleEngineMethod != 's_status') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    if (battleStageModCount != 0) {
      return false;
    }
    if (effectChance != 0 && effectChance != 100) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictMajorStatusTargets.contains(normalizedTarget)) {
      return false;
    }
    if (moveStatuses.length != 1 || moveStatusCount != 1) {
      return false;
    }
    return _strictMajorStatuses.contains(moveStatuses.single.status);
  }

  bool get isStrictVolatileStatus {
    if (battleEngineMethod != 's_status') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    if (battleStageModCount != 0) {
      return false;
    }
    if (effectChance != 0 && effectChance != 100) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictMajorStatusTargets.contains(normalizedTarget)) {
      return false;
    }
    if (moveStatuses.length != 1 || moveStatusCount != 1) {
      return false;
    }
    return moveStatuses.single.status == 'confusion';
  }

  bool get isStrictSelfStatus {
    if (battleEngineMethod != 's_self_status') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    if (battleStageModCount != 0) {
      return false;
    }
    if (effectChance != 0 && effectChance != 100) {
      return false;
    }
    if (moveStatuses.length != 1 || moveStatusCount != 1) {
      return false;
    }
    return _strictSelfStatuses.contains(moveStatuses.single.status);
  }

  bool get isStrictRandomMultiHit {
    if (battleEngineMethod != 's_multi_hit') {
      return false;
    }
    if (dbSymbol == 'water_shuriken') {
      return false;
    }
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory != 'physical' && normalizedCategory != 'special') {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictTwoTurnDamage {
    if (battleEngineMethod != 's_2turns') {
      return false;
    }
    if (dbSymbol == 'geomancy') {
      return isStrictTwoTurnStatusPayload;
    }
    if (!_strictTwoTurnDamageMoves.contains(dbSymbol)) {
      return false;
    }
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory != 'physical' && normalizedCategory != 'special') {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictTwoTurnDamageTargets.contains(normalizedTarget)) {
      return false;
    }
    if (battleStageModCount != 0) {
      return false;
    }
    if (moveStatusCount == 0) {
      return effectChance == 0;
    }
    if (effectChance <= 0) {
      return false;
    }
    return moveStatuses.every((status) {
      return _strictMajorStatuses.contains(status.status) ||
          status.status == 'confusion' ||
          status.status == 'flinch';
    });
  }

  bool get isStrictTwoTurnStatusPayload {
    if (battleEngineMethod != 's_2turns' || dbSymbol != 'geomancy') {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedCategory != 'status' ||
        power != 0 ||
        moveStatusCount != 0 ||
        effectChance != 0 ||
        normalizedTarget != 'user') {
      return false;
    }
    const expected = <String, int>{
      'specialAttack': 2,
      'specialDefense': 2,
      'speed': 2,
    };
    if (battleStageMods.length != expected.length) {
      return false;
    }
    for (final mod in battleStageMods) {
      if (expected[mod.stat] != mod.stages) {
        return false;
      }
    }
    return true;
  }

  bool get isStrictRechargeDamage {
    if (battleEngineMethod != 's_reload') {
      return false;
    }
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory != 'physical' && normalizedCategory != 'special') {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictRechargeDamageTargets.contains(normalizedTarget)) {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictRecoilDamage {
    if (battleEngineMethod != 's_recoil') {
      return false;
    }
    if (dbSymbol == 'mind_blown') {
      return _isStrictStudioMindBlownRecoil;
    }
    if (!_strictRecoilDamageMoves.contains(dbSymbol)) {
      return false;
    }
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory != 'physical' && normalizedCategory != 'special') {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictRecoilDamageTargets.contains(normalizedTarget)) {
      return false;
    }
    if (battleStageModCount != 0) {
      return false;
    }
    if (moveStatusCount == 0) {
      return true;
    }
    if (effectChance < 1 || effectChance > 100) {
      return false;
    }
    if (moveStatuses.length != moveStatusCount) {
      return false;
    }
    return moveStatuses.every((status) {
      return _strictMajorStatuses.contains(status.status) ||
          status.status == 'confusion' ||
          status.status == 'flinch';
    });
  }

  bool get _isStrictStudioMindBlownRecoil {
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    final normalizedTarget = target.trim().toLowerCase();
    return (normalizedCategory == 'physical' ||
            normalizedCategory == 'special') &&
        normalizedTarget == 'adjacent_all_pokemon' &&
        battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictAbsorbDrain {
    if (battleEngineMethod != 's_absorb') {
      return false;
    }
    if (power <= 0) {
      return false;
    }
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory != 'physical' && normalizedCategory != 'special') {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (dbSymbol == 'oblivion_wing' && normalizedTarget == 'all_ally') {
      return battleStageModCount == 0 &&
          moveStatusCount == 0 &&
          effectChance == 0;
    }
    if (normalizedTarget.isNotEmpty &&
        !_strictAbsorbDrainTargets.contains(normalizedTarget)) {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictSelfRecovery {
    if (!_strictSelfRecoveryMethods.contains(battleEngineMethod)) {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        !_strictSelfRecoveryTargets.contains(normalizedTarget)) {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictTargetHealPulse {
    if (battleEngineMethod != 's_heal' || dbSymbol != 'heal_pulse') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        normalizedTarget != 'any_other_pokemon') {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        (effectChance == 0 || effectChance == 100);
  }

  bool get isStrictRestRecovery {
    if (battleEngineMethod != 's_rest') {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        normalizedTarget != 'user' &&
        normalizedTarget != 'self') {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }

  bool get isStrictProtectBaseVariant {
    if (battleEngineMethod != 's_protect') {
      return false;
    }
    if (!_strictProtectCoveredMoves.contains(dbSymbol)) {
      return false;
    }
    if (category.trim().toLowerCase() != 'status' || power != 0) {
      return false;
    }
    final normalizedTarget = target.trim().toLowerCase();
    if (normalizedTarget.isNotEmpty &&
        normalizedTarget != 'user' &&
        normalizedTarget != 'self' &&
        normalizedTarget != 'all_ally') {
      return false;
    }
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
  }
}

final class PsdkStudioStageModCoverageEntry {
  const PsdkStudioStageModCoverageEntry({
    required this.stat,
    required this.stages,
  });

  final String stat;
  final int stages;
}

final class PsdkStudioStatusCoverageEntry {
  const PsdkStudioStatusCoverageEntry({required this.status});

  final String status;
}

Future<List<PsdkStudioMoveCoverageEntry>> loadPsdkStudioMoveCoverageEntries(
  Directory movesDirectory,
) async {
  if (!await movesDirectory.exists()) {
    throw StateError(
      'PSDK Studio moves directory not found: ${movesDirectory.path}',
    );
  }

  final files = <File>[];
  await for (final entity in movesDirectory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
      files.add(entity);
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));

  final moves = <PsdkStudioMoveCoverageEntry>[];
  for (final file in files) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('PSDK Studio move file is not an object: ${file.path}');
    }
    moves.add(_entryFromPayload(decoded, file.path));
  }
  moves.sort((left, right) => left.dbSymbol.compareTo(right.dbSymbol));
  return moves;
}

String generatePsdkAttackCoverageReport({
  required List<PsdkStudioMoveCoverageEntry> moves,
  required List<PsdkMoveRegistryManifestEntry> manifest,
  required String sourceDescription,
}) {
  final manifestByMethod = <String, PsdkMoveRegistryManifestEntry>{
    for (final entry in manifest) entry.battleEngineMethod: entry,
    for (final entry in psdkStudioOnlyBattleMethods)
      entry.battleEngineMethod: entry,
  };
  final rows = <_AttackCoverageRow>[
    for (final move in moves)
      _AttackCoverageRow.fromMove(
        move,
        manifestByMethod[move.battleEngineMethod],
      ),
  ];

  final fait = rows.where((row) => row.coverage == 'fait').length;
  final partiel = rows.where((row) => row.coverage == 'partiel').length;
  final pasFait = rows.where((row) => row.coverage == 'pas_fait').length;
  final unknownMethods =
      rows.where((row) => row.methodStatus == 'unknown_method').length;
  final uniqueMethods = rows.map((row) => row.battleEngineMethod).toSet();

  final buffer = StringBuffer()
    ..writeln('# PSDK Attack Coverage')
    ..writeln()
    ..writeln('Source: `$sourceDescription`')
    ..writeln()
    ..writeln('This report tracks individual Studio move entries against the')
    ..writeln('PSDK battle engine method parity manifest.')
    ..writeln()
    ..writeln('Coverage semantics:')
    ..writeln()
    ..writeln('- `fait`: the move uses a `ported` battle engine method.')
    ..writeln('- `partiel`: the move executes through a partial method.')
    ..writeln('- `pas_fait`: the method is missing or unknown locally.')
    ..writeln(
      '- `s_basic` is counted as `fait` for damaging Studio moves with no '
      'rider, with supported single-target or adjacent spread '
      'stat/major-status/confusion/flinch riders, or Blizzard; unsupported '
      'metadata riders remain `partiel`.',
    )
    ..writeln(
      '- Generic offensive Z-Move placeholders encoded by Studio as zero-power '
      '`s_basic` shells are counted as `fait` only when they match the known '
      'type/category placeholder shape; full Z-Crystal/source-move selection '
      'remains owned by the runtime bridge lot.',
    )
    ..writeln(
      '- Offensive signature `s_z_move` entries are counted as `fait` only '
      'when they match the exact Studio power/type/category/status shape and '
      'the battle engine owns item, species, source-move and once-per-bank '
      'eligibility gates.',
    )
    ..writeln(
      '- Studio `secret_sword` is counted as `fait` through the strict '
      '`s_basic` alias that delegates to the PSDK custom-stat source behavior.',
    )
    ..writeln(
      '- `s_self_stat` is counted as `fait` for status self-stage payloads '
      'and supported single-target or adjacent-foe spread damage self-stage '
      'riders; mixed status riders remain `partiel`.',
    )
    ..writeln(
      '- `s_stat` is counted as `fait` only for status stage-only moves '
      'on supported stats and single-target foe/ally/self targets, '
      'optionally with one supported status rider; other riders remain '
      '`partiel`.',
    )
    ..writeln(
      '- `s_status` is counted as `fait` only for single major-status or '
      'Confusion moves on supported single or adjacent spread targets; '
      'mixed payloads remain `partiel`.',
    )
    ..writeln(
      '- `s_self_status` is counted as `fait` only for single self-applied '
      'major-status or Confusion moves without damage/stat riders.',
    )
    ..writeln(
      '- `s_multi_hit` is counted as `fait` only for plain random 2-5 hit '
      'moves; Water Shuriken and metadata riders remain `partiel`.',
    )
    ..writeln(
      '- `s_2turns` is counted as `fait` for charged damage moves, supported '
      'release-turn status riders, Skull Bash charge boost, Geomancy release '
      'boosts and supported spread release targets; unsupported weather or '
      'custom charge variants remain `partiel`.',
    )
    ..writeln(
      '- `s_reload` is counted as `fait` only for plain damage moves that '
      'require a recharge turn after a successful hit.',
    )
    ..writeln(
      '- `s_recoil` is counted as `fait` only for plain recoil damage moves; '
      'implemented status riders and Studio Mind Blown self-crash are '
      'supported, while other special self-crash or multi-target variants '
      'remain `partiel`.',
    )
    ..writeln(
      '- `s_absorb` is counted as `fait` for plain drain moves, including '
      'implemented adjacent spread drain plus the explicit `oblivion_wing` '
      'Studio alias; unusual target variants remain `partiel`.',
    )
    ..writeln(
      '- Heal/recovery methods are counted as `fait` only for status-only '
      'self recovery moves plus Heal Pulse with Substitute and Mega Launcher '
      'branches; mixed riders remain `partiel`.',
    )
    ..writeln(
      '- `s_protect` is counted as `fait` for Protect, Detect, Endure, '
      'Wide Guard, Quick Guard, Mat Block and implemented contact-punish '
      'variants.',
    )
    ..writeln()
    ..writeln('| Metric | Count |')
    ..writeln('| --- | ---: |')
    ..writeln('| total_attacks | ${rows.length} |')
    ..writeln('| unique_battle_engine_methods | ${uniqueMethods.length} |')
    ..writeln('| fait | $fait |')
    ..writeln('| partiel | $partiel |')
    ..writeln('| pas_fait | $pasFait |')
    ..writeln('| unknown_methods | $unknownMethods |')
    ..writeln()
    ..writeln(
        '| Fait ? | Attack | Battle method | Method status | Dart behavior | Type | Category | Power | Accuracy | PP | Source file |')
    ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | ---: | --- | ---: | --- |');

  for (final row in rows) {
    buffer.writeln(
      '| ${row.coverage} | ${_md(row.dbSymbol)} | ${_md(row.battleEngineMethod)} | '
      '${_md(row.methodStatus)} | ${_md(row.dartBehavior)} | ${_md(row.type)} | '
      '${_md(row.category)} | ${row.power} | ${_md(row.accuracy)} | ${row.pp} | '
      '${_md(row.sourceFile)} |',
    );
  }

  return buffer.toString();
}

const psdkStudioOnlyBattleMethods = <PsdkMoveRegistryManifestEntry>[
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_genesis_supernova',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_genesis_supernova)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_guardian_of_alola',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_guardian_of_alola)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hyperspace_hole',
    rubyClass: 'StudioOnlyMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_hyperspace_hole)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_light_that_burns_the_sky',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior:
        'StaticBasicMoveRegistry.partialBasic(s_light_that_burns_the_sky)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_malicious_moonsault',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_malicious_moonsault)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_self_stat_z_move',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.secondaryOnly(s_self_stat_z_move)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_splintered_stormshards',
    rubyClass: 'StudioOnlyZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior:
        'StaticBasicMoveRegistry.partialBasic(s_splintered_stormshards)',
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[PsdkMoveDependency.runtimeBridge],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_z_move',
    rubyClass: 'StudioZMove',
    rubyPath: 'Data/Studio/moves',
    dartBehavior: 'StaticBasicMoveRegistry.s_z_move',
    status: PsdkPortStatus.ported,
  ),
];

PsdkStudioMoveCoverageEntry _entryFromPayload(
  Map<String, dynamic> payload,
  String sourceFile,
) {
  return PsdkStudioMoveCoverageEntry(
    dbSymbol: _requiredString(payload, 'dbSymbol'),
    battleEngineMethod: _requiredString(payload, 'battleEngineMethod'),
    type: _stringValue(payload['type']),
    category: _stringValue(payload['category']),
    power: _intValue(payload['power']),
    accuracy: _stringValue(payload['accuracy']),
    pp: _intValue(payload['pp']),
    priority: _intValue(payload['priority']),
    criticalRate: _intValue(
      payload['movecriticalRate'] ?? payload['criticalRate'],
    ),
    effectChance: _intValue(payload['effectChance']),
    battleStageModCount: _listLength(payload['battleStageMod']),
    battleStageMods: _stageModCoverageEntries(payload['battleStageMod']),
    moveStatusCount: _listLength(payload['moveStatus']),
    moveStatuses: _statusCoverageEntries(payload['moveStatus']),
    target: _stringValue(payload['battleEngineAimedTarget']),
    protectable: _boolValue(payload['isBlocable'], fallback: true),
    sound: _boolValue(payload['isSoundAttack'], fallback: false),
    ballistics: _boolValue(payload['isBallistics'], fallback: false),
    kingRockUtility: _boolValue(payload['isKingRockUtility'], fallback: false),
    sourceFile: sourceFile,
  );
}

String psdkAttackCoverageForMove(
  PsdkStudioMoveCoverageEntry move,
  PsdkMoveRegistryManifestEntry? manifestEntry,
) {
  return switch (manifestEntry?.status) {
    PsdkPortStatus.ported when move.battleEngineMethod == 's_basic' =>
      move.isStrictPlainBasicDamage ||
              move.isStrictBasicDamageWithSupportedRider ||
              move.isStrictWeatherAccuracyBasic ||
              move.isStrictGenericZMovePlaceholder ||
              move.isStrictSecretSwordStudioAlias
          ? 'fait'
          : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_z_move' =>
      move.isStrictOffensiveSignatureZMove ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_self_stat' =>
      move.isStrictSelfStatBoost || move.isStrictDamagingSelfStatRider
          ? 'fait'
          : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_stat' =>
      move.isStrictTargetStatChange ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_status' =>
      move.isStrictMajorStatus || move.isStrictVolatileStatus
          ? 'fait'
          : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_self_status' =>
      move.isStrictSelfStatus ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_multi_hit' =>
      move.isStrictRandomMultiHit ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_2turns' =>
      move.isStrictTwoTurnDamage ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_reload' =>
      move.isStrictRechargeDamage ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_recoil' =>
      move.isStrictRecoilDamage ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_absorb' =>
      move.isStrictAbsorbDrain ? 'fait' : 'partiel',
    PsdkPortStatus.ported
        when _strictSelfRecoveryMethods.contains(move.battleEngineMethod) =>
      move.isStrictSelfRecovery || move.isStrictTargetHealPulse
          ? 'fait'
          : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_rest' =>
      move.isStrictRestRecovery ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_protect' =>
      move.isStrictProtectBaseVariant ? 'fait' : 'partiel',
    PsdkPortStatus.ported => 'fait',
    PsdkPortStatus.partial => 'partiel',
    PsdkPortStatus.missing || null => 'pas_fait',
  };
}

String _requiredString(Map<String, dynamic> payload, String key) {
  final value = _stringValue(payload[key]).trim();
  if (value.isEmpty) {
    throw StateError('PSDK Studio move is missing required field $key');
  }
  return value;
}

String _stringValue(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return jsonEncode(value);
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

int _listLength(Object? value) {
  if (value is List) {
    return value.length;
  }
  return 0;
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => fallback,
    };
  }
  return fallback;
}

List<PsdkStudioStageModCoverageEntry> _stageModCoverageEntries(Object? value) {
  if (value is! List) {
    return const <PsdkStudioStageModCoverageEntry>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map((entry) {
        return PsdkStudioStageModCoverageEntry(
          stat: _normalizeBattleStage(_stringValue(entry['battleStage'])),
          stages: _intValue(entry['modificator']),
        );
      })
      .where((entry) => entry.stat.isNotEmpty)
      .toList(growable: false);
}

List<PsdkStudioStatusCoverageEntry> _statusCoverageEntries(Object? value) {
  if (value is! List) {
    return const <PsdkStudioStatusCoverageEntry>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map((entry) {
        return PsdkStudioStatusCoverageEntry(
          status: _normalizeMoveStatus(_stringValue(entry['status'])),
        );
      })
      .where((entry) => entry.status.isNotEmpty)
      .toList(growable: false);
}

String _normalizeBattleStage(String value) {
  final normalized = value.trim().toUpperCase();
  return switch (normalized) {
    'ATK_STAGE' => 'attack',
    'DFE_STAGE' => 'defense',
    'ATS_STAGE' => 'specialAttack',
    'DFS_STAGE' => 'specialDefense',
    'SPD_STAGE' => 'speed',
    'ACC_STAGE' => 'accuracy',
    'EVA_STAGE' => 'evasion',
    _ => value.trim(),
  };
}

String _normalizeMoveStatus(String value) {
  final normalized = value.trim().toUpperCase();
  return switch (normalized) {
    'BURN' || 'BURNED' => 'burn',
    'PARALYZED' || 'PARALYSIS' => 'paralysis',
    'POISONED' || 'POISON' => 'poison',
    'TOXIC' => 'toxic',
    'ASLEEP' || 'SLEEP' => 'sleep',
    'FROZEN' || 'FREEZE' => 'freeze',
    'CONFUSED' || 'CONFUSION' => 'confusion',
    'FLINCH' => 'flinch',
    _ => value.trim(),
  };
}

const _strictSelfStatBoostStats = <String>{
  'accuracy',
  'attack',
  'defense',
  'evasion',
  'specialAttack',
  'specialDefense',
  'speed',
};

const _strictStatChangeStats = <String>{
  'accuracy',
  'attack',
  'defense',
  'evasion',
  'specialAttack',
  'specialDefense',
  'speed',
};

const _strictTargetStatChangeTargets = <String>{
  'adjacent_ally',
  'adjacent_foe',
  'adjacent_pokemon',
  'adjacent_all_foe',
  'user',
  'self',
};

const _strictBasicDamageRiderTargets = <String>{
  'adjacent_all_pokemon',
  'adjacent_pokemon',
  'adjacent_foe',
  'adjacent_all_foe',
  'any_other_pokemon',
};

const _strictGenericZMovePlaceholderTypes = <String, String>{
  'acid_downpour': 'poison',
  'acid_downpour2': 'poison',
  'all_out_pummeling': 'fighting',
  'all_out_pummeling2': 'fighting',
  'black_hole_eclipse': 'dark',
  'black_hole_eclipse2': 'dark',
  'bloom_doom': 'grass',
  'bloom_doom2': 'grass',
  'breakneck_blitz': 'normal',
  'breakneck_blitz2': 'normal',
  'continental_crush': 'rock',
  'continental_crush2': 'rock',
  'corkscrew_crash': 'steel',
  'corkscrew_crash2': 'steel',
  'devastating_drake': 'dragon',
  'devastating_drake2': 'dragon',
  'gigavolt_havoc': 'electric',
  'gigavolt_havoc2': 'electric',
  'hydro_vortex': 'water',
  'hydro_vortex2': 'water',
  'inferno_overdrive': 'fire',
  'inferno_overdrive2': 'fire',
  'never_ending_nightmare': 'ghost',
  'never_ending_nightmare2': 'ghost',
  'savage_spin_out': 'bug',
  'savage_spin_out2': 'bug',
  'shattered_psyche': 'psychic',
  'shattered_psyche2': 'psychic',
  'subzero_slammer': 'ice',
  'subzero_slammer2': 'ice',
  'supersonic_skystrike': 'flying',
  'supersonic_skystrike2': 'flying',
  'tectonic_rage': 'ground',
  'tectonic_rage2': 'ground',
  'twinkle_tackle': 'fairy',
  'twinkle_tackle2': 'fairy',
};

const _strictOffensiveSignatureZMoves =
    <String, _StrictOffensiveSignatureZMove>{
  'catastropika': _StrictOffensiveSignatureZMove(
    type: 'electric',
    category: 'physical',
    power: 210,
  ),
  'let_s_snuggle_forever': _StrictOffensiveSignatureZMove(
    type: 'fairy',
    category: 'physical',
    power: 190,
  ),
  'menacing_moonraze_maelstrom': _StrictOffensiveSignatureZMove(
    type: 'ghost',
    category: 'special',
    power: 200,
  ),
  'oceanic_operetta': _StrictOffensiveSignatureZMove(
    type: 'water',
    category: 'special',
    power: 195,
  ),
  'pulverizing_pancake': _StrictOffensiveSignatureZMove(
    type: 'normal',
    category: 'physical',
    power: 210,
  ),
  's10_000_000_volt_thunderbolt': _StrictOffensiveSignatureZMove(
    type: 'electric',
    category: 'special',
    power: 195,
    criticalRate: 3,
  ),
  'searing_sunraze_smash': _StrictOffensiveSignatureZMove(
    type: 'steel',
    category: 'physical',
    power: 200,
    target: 'user',
  ),
  'sinister_arrow_raid': _StrictOffensiveSignatureZMove(
    type: 'ghost',
    category: 'physical',
    power: 180,
  ),
  'soul_stealing_7_star_strike': _StrictOffensiveSignatureZMove(
    type: 'ghost',
    category: 'physical',
    power: 195,
  ),
  'stoked_sparksurfer': _StrictOffensiveSignatureZMove(
    type: 'electric',
    category: 'special',
    power: 175,
    statuses: <String>{'paralysis'},
  ),
};

final class _StrictOffensiveSignatureZMove {
  const _StrictOffensiveSignatureZMove({
    required this.type,
    required this.category,
    required this.power,
    this.criticalRate = 1,
    this.target = 'adjacent_pokemon',
    this.statuses = const <String>{},
  });

  final String type;
  final String category;
  final int power;
  final int criticalRate;
  final String target;
  final Set<String> statuses;
}

const _strictSelfStatDamageTargets = <String>{
  'adjacent_all_foe',
  'adjacent_pokemon',
  'adjacent_foe',
  'any_other_pokemon',
};

const _strictMajorStatuses = <String>{
  'burn',
  'paralysis',
  'poison',
  'toxic',
  'sleep',
  'freeze',
};

const _strictSelfStatuses = <String>{
  ..._strictMajorStatuses,
  'confusion',
};

const _strictTwoTurnDamageMoves = <String>{
  'bounce',
  'dig',
  'dive',
  'fly',
  'freeze_shock',
  'ice_burn',
  'phantom_force',
  'razor_wind',
  'shadow_force',
  'skull_bash',
  'sky_attack',
};

const _strictTwoTurnDamageTargets = <String>{
  'adjacent_all_foe',
  'adjacent_pokemon',
  'adjacent_foe',
  'any_other_pokemon',
};

const _strictRechargeDamageTargets = <String>{
  'adjacent_pokemon',
  'adjacent_foe',
};

const _strictRecoilDamageMoves = <String>{
  'brave_bird',
  'double_edge',
  'flare_blitz',
  'head_charge',
  'head_smash',
  'light_of_ruin',
  'submission',
  'take_down',
  'volt_tackle',
  'wave_crash',
  'wild_charge',
  'wood_hammer',
};

const _strictRecoilDamageTargets = <String>{
  'adjacent_pokemon',
  'adjacent_foe',
  'any_other_pokemon',
};

const _strictAbsorbDrainTargets = <String>{
  'adjacent_all_pokemon',
  'adjacent_pokemon',
  'adjacent_foe',
  'any_other_pokemon',
};

const _strictSelfRecoveryMethods = <String>{
  's_heal',
  's_heal_weather',
  's_shore_up',
};

const _strictSelfRecoveryTargets = <String>{
  'user',
  'self',
  'adjacent_pokemon',
};

const _strictProtectCoveredMoves = <String>{
  'baneful_bunker',
  'burning_bulwark',
  'detect',
  'endure',
  'king_s_shield',
  'mat_block',
  'obstruct',
  'protect',
  'quick_guard',
  'silk_trap',
  'spiky_shield',
  'wide_guard',
};

const _strictMajorStatusTargets = <String>{
  'adjacent_all_pokemon',
  'adjacent_pokemon',
  'adjacent_foe',
  'adjacent_all_foe',
};

bool _sameStatusSet(
  List<PsdkStudioStatusCoverageEntry> actual,
  Set<String> expected,
) {
  return actual.map((status) => status.status).toSet().containsAll(expected) &&
      expected.containsAll(actual.map((status) => status.status));
}

String _md(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('|', r'\|')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .trim();
}

final class _AttackCoverageRow {
  const _AttackCoverageRow({
    required this.coverage,
    required this.dbSymbol,
    required this.battleEngineMethod,
    required this.methodStatus,
    required this.dartBehavior,
    required this.type,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.sourceFile,
  });

  factory _AttackCoverageRow.fromMove(
    PsdkStudioMoveCoverageEntry move,
    PsdkMoveRegistryManifestEntry? manifestEntry,
  ) {
    final methodStatus = manifestEntry?.status.name ?? 'unknown_method';
    return _AttackCoverageRow(
      coverage: psdkAttackCoverageForMove(move, manifestEntry),
      dbSymbol: move.dbSymbol,
      battleEngineMethod: move.battleEngineMethod,
      methodStatus: methodStatus,
      dartBehavior: manifestEntry?.dartBehavior ?? 'TODO',
      type: move.type,
      category: move.category,
      power: move.power,
      accuracy: move.accuracy,
      pp: move.pp,
      sourceFile: move.sourceFile,
    );
  }

  final String coverage;
  final String dbSymbol;
  final String battleEngineMethod;
  final String methodStatus;
  final String dartBehavior;
  final String type;
  final String category;
  final int power;
  final String accuracy;
  final int pp;
  final String sourceFile;
}
