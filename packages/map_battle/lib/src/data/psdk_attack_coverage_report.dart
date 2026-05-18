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

  bool get isStrictPlainBasicDamage {
    if (battleEngineMethod != 's_basic') {
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
      return mod.stages > 0 && _strictSelfStatBoostStats.contains(mod.stat);
    });
  }

  bool get isStrictTargetStatChange {
    if (battleEngineMethod != 's_stat') {
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
        !_strictTargetStatChangeTargets.contains(normalizedTarget)) {
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
    return battleStageModCount == 0 &&
        moveStatusCount == 0 &&
        effectChance == 0;
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
    return battleStageModCount == 0 &&
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
    if (!_strictProtectBaseMoves.contains(dbSymbol)) {
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
      '- `s_basic` is counted as `fait` only for plain damaging Studio moves; '
      'metadata riders remain `partiel`.',
    )
    ..writeln(
      '- `s_self_stat` is counted as `fait` only for status self-boosts '
      'on supported stats; accuracy/evasion, drops, damage riders and '
      'chance riders remain `partiel`.',
    )
    ..writeln(
      '- `s_stat` is counted as `fait` only for status stage-only moves '
      'on supported stats and targets; accuracy/evasion and status riders '
      'remain `partiel`.',
    )
    ..writeln(
      '- `s_status` is counted as `fait` only for single major-status moves; '
      'volatile statuses and mixed payloads remain `partiel`.',
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
      '- `s_2turns` is counted as `fait` only for plain charged damage moves '
      'with forced release; Power Herb, weather/stat/status and multi-target '
      'variants remain `partiel`.',
    )
    ..writeln(
      '- `s_reload` is counted as `fait` only for plain damage moves that '
      'require a recharge turn after a successful hit.',
    )
    ..writeln(
      '- `s_recoil` is counted as `fait` only for plain recoil damage moves; '
      'status riders, special self-crash, and multi-target variants remain '
      '`partiel`.',
    )
    ..writeln(
      '- `s_absorb` is counted as `fait` only for plain single-target drain '
      'moves; multi-target and unusual target variants remain `partiel`.',
    )
    ..writeln(
      '- Heal/recovery methods are counted as `fait` only for status-only '
      'self recovery moves; Heal Pulse, Substitute/Mega Launcher branches and '
      'mixed riders remain `partiel`.',
    )
    ..writeln(
      '- `s_protect` is counted as `fait` for Protect, Detect, Endure, '
      'Wide Guard, Quick Guard and Mat Block; contact-punish variants remain '
      '`partiel`.',
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
    status: PsdkPortStatus.partial,
    dependencies: <PsdkMoveDependency>[
      PsdkMoveDependency.item,
      PsdkMoveDependency.runtimeBridge,
    ],
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
    sourceFile: sourceFile,
  );
}

String psdkAttackCoverageForMove(
  PsdkStudioMoveCoverageEntry move,
  PsdkMoveRegistryManifestEntry? manifestEntry,
) {
  return switch (manifestEntry?.status) {
    PsdkPortStatus.ported when move.battleEngineMethod == 's_basic' =>
      move.isStrictPlainBasicDamage || move.isStrictWeatherAccuracyBasic
          ? 'fait'
          : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_self_stat' =>
      move.isStrictSelfStatBoost ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_stat' =>
      move.isStrictTargetStatChange ? 'fait' : 'partiel',
    PsdkPortStatus.ported when move.battleEngineMethod == 's_status' =>
      move.isStrictMajorStatus ? 'fait' : 'partiel',
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
      move.isStrictSelfRecovery ? 'fait' : 'partiel',
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
    _ => value.trim(),
  };
}

const _strictSelfStatBoostStats = <String>{
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
};

const _strictStatChangeStats = <String>{
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
};

const _strictTargetStatChangeTargets = <String>{
  'adjacent_foe',
  'adjacent_pokemon',
  'adjacent_all_foe',
  'user',
  'self',
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
  'dig',
  'dive',
  'fly',
  'phantom_force',
  'shadow_force',
};

const _strictTwoTurnDamageTargets = <String>{
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
  'head_charge',
  'head_smash',
  'submission',
  'take_down',
  'wild_charge',
  'wood_hammer',
};

const _strictRecoilDamageTargets = <String>{
  'adjacent_pokemon',
  'adjacent_foe',
  'any_other_pokemon',
};

const _strictAbsorbDrainTargets = <String>{
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

const _strictProtectBaseMoves = <String>{
  'detect',
  'endure',
  'mat_block',
  'protect',
  'quick_guard',
  'wide_guard',
};

const _strictMajorStatusTargets = <String>{
  'adjacent_pokemon',
  'adjacent_foe',
  'adjacent_all_foe',
};

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
