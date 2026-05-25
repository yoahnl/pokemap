import 'dart:convert';
import 'dart:io';

import 'generated/psdk_ability_effect_manifest.dart';
import 'generated/psdk_item_effect_manifest.dart';
import 'generated/psdk_move_registry_manifest.dart';
import 'psdk_attack_coverage_report.dart';

final _classLinePattern = RegExp(
  r'^\s*class\s+([A-Za-z_][A-Za-z0-9_:]*)(?:\s*<\s*([A-Za-z0-9_:]+))?',
);
final _hookLinePattern = RegExp(r'^\s*def\s+(on_[A-Za-z0-9_!?=]+)');
final _blockStartPattern = RegExp(
  r'^\s*(module|def|if|unless|case|begin|for|while|until)\b|'
  r'\bdo\s*(?:\|[^|]*\|)?\s*$',
);

final class PsdkFightParityAudit {
  const PsdkFightParityAudit({
    required this.sourceDescription,
    required this.attackMetrics,
    required this.methodMetrics,
    required this.effectMetrics,
    this.attackEntries = const <PsdkAttackParityEntry>[],
    this.methodEntries = const <PsdkMoveRegistryManifestEntry>[],
    this.effectEntries = const <PsdkEffectParityEntry>[],
    this.runtimeBridge = const PsdkRuntimeBridgeParity.notMeasured(),
  });

  factory PsdkFightParityAudit.fromEntries({
    required String sourceDescription,
    required List<PsdkStudioMoveCoverageEntry> moves,
    required List<PsdkMoveRegistryManifestEntry> manifest,
    required List<PsdkEffectParityEntry> effects,
  }) {
    final manifestByMethod = _manifestByMethod(manifest);
    return PsdkFightParityAudit(
      sourceDescription: sourceDescription,
      attackMetrics: PsdkAttackParityMetrics.fromEntries(
        moves: moves,
        manifest: manifest,
      ),
      methodMetrics: PsdkMethodParityMetrics.fromManifest(manifest),
      effectMetrics: PsdkEffectParityMetrics.fromEntries(effects),
      attackEntries: <PsdkAttackParityEntry>[
        for (final move in moves)
          PsdkAttackParityEntry.fromMove(
            move,
            manifestByMethod[move.battleEngineMethod],
          ),
      ],
      methodEntries: List<PsdkMoveRegistryManifestEntry>.unmodifiable(
        manifest,
      ),
      effectEntries: List<PsdkEffectParityEntry>.unmodifiable(effects),
    );
  }

  final String sourceDescription;
  final PsdkAttackParityMetrics attackMetrics;
  final PsdkMethodParityMetrics methodMetrics;
  final PsdkEffectParityMetrics effectMetrics;
  final List<PsdkAttackParityEntry> attackEntries;
  final List<PsdkMoveRegistryManifestEntry> methodEntries;
  final List<PsdkEffectParityEntry> effectEntries;
  final PsdkRuntimeBridgeParity runtimeBridge;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sourceDescription': sourceDescription,
      'attacks': <String, Object?>{
        ...attackMetrics.toJson(),
        'entries': attackEntries.map((entry) => entry.toJson()).toList(),
      },
      'methods': <String, Object?>{
        ...methodMetrics.toJson(),
        'entries': methodEntries.map(_methodEntryJson).toList(),
        'backlogBatches': _methodBacklogBatchJson(methodEntries),
      },
      'effects': <String, Object?>{
        ...effectMetrics.toJson(),
        'entries': effectEntries.map((entry) => entry.toJson()).toList(),
      },
      'runtimeBridge': runtimeBridge.toJson(),
    };
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# PSDK Fight Parity Audit')
      ..writeln()
      ..writeln('Source: `${_md(sourceDescription)}`')
      ..writeln()
      ..writeln(
        'Important: `partiel` is executable coverage, not strict PSDK parity.',
      )
      ..writeln()
      ..writeln('## Attack Coverage')
      ..writeln()
      ..writeln('| Metric | Count |')
      ..writeln('| --- | ---: |')
      ..writeln('| Studio attacks total | ${attackMetrics.totalAttacks} |')
      ..writeln('| Studio attacks `fait` | ${attackMetrics.fait} |')
      ..writeln('| Studio attacks `partiel` | ${attackMetrics.partiel} |')
      ..writeln('| Studio attacks `pas_fait` | ${attackMetrics.pasFait} |')
      ..writeln('| Unknown methods | ${attackMetrics.unknownMethods} |')
      ..writeln(
        '| Unique battle engine methods | ${attackMetrics.uniqueBattleEngineMethods} |',
      );
    _writePartialAttacksByMethod(buffer, attackEntries);
    buffer
      ..writeln()
      ..writeln('## Method Coverage')
      ..writeln()
      ..writeln('| Status | Count |')
      ..writeln('| --- | ---: |');
    for (final status in PsdkPortStatus.values) {
      buffer.writeln(
          '| `${status.name}` | ${methodMetrics.byStatus[status] ?? 0} |');
    }
    buffer
      ..writeln('| Total manifest methods | ${methodMetrics.totalMethods} |');
    _writePartialMethodsByDependency(buffer, methodEntries);
    _writePartialMethodBatches(buffer, methodEntries);
    buffer
      ..writeln()
      ..writeln('## Effect Coverage')
      ..writeln()
      ..writeln('| Status | Count |')
      ..writeln('| --- | ---: |');
    for (final status in PsdkPortStatus.values) {
      buffer.writeln(
          '| `${status.name}` | ${effectMetrics.byStatus[status] ?? 0} |');
    }
    buffer
      ..writeln('| Total effect classes | ${effectMetrics.totalEffects} |')
      ..writeln()
      ..writeln('### Effects by Family')
      ..writeln()
      ..writeln('| Family | Ported | Partial | Missing |')
      ..writeln('| --- | ---: | ---: | ---: |');
    final families = effectMetrics.byFamilyAndStatus.keys.toList()..sort();
    for (final family in families) {
      final counts = effectMetrics.byFamilyAndStatus[family]!;
      buffer.writeln(
        '| ${_md(family)} | ${counts[PsdkPortStatus.ported] ?? 0} '
        '| ${counts[PsdkPortStatus.partial] ?? 0} '
        '| ${counts[PsdkPortStatus.missing] ?? 0} |',
      );
    }
    _writeMissingEffectsByFamily(buffer, effectEntries);
    buffer
      ..writeln()
      ..writeln('## Runtime Bridge')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('| --- | --- |')
      ..writeln('| Status | `${runtimeBridge.status}` |')
      ..writeln('| Reason | ${_md(runtimeBridge.reason)} |');
    if (runtimeBridge.status != 'not_measured') {
      buffer
        ..writeln('| Total moves | ${runtimeBridge.totalMoves} |')
        ..writeln('| Bridgeable moves | ${runtimeBridge.bridgeableMoves} |')
        ..writeln('| Rejected moves | ${runtimeBridge.rejectedMoves} |')
        ..writeln(
          '| Explained rejected moves | ${runtimeBridge.explainedRejectedMoves} |',
        )
        ..writeln(
          '| Unexplained rejected moves | ${runtimeBridge.unexplainedRejectedMoves} |',
        );
    }
    return buffer.toString();
  }
}

final class PsdkAttackParityEntry {
  const PsdkAttackParityEntry({
    required this.moveId,
    required this.battleEngineMethod,
    required this.coverage,
    required this.psdkStatus,
    required this.reason,
    required this.sourceFile,
  });

  factory PsdkAttackParityEntry.fromMove(
    PsdkStudioMoveCoverageEntry move,
    PsdkMoveRegistryManifestEntry? manifestEntry,
  ) {
    final coverage = psdkAttackCoverageForMove(move, manifestEntry);
    return PsdkAttackParityEntry(
      moveId: move.dbSymbol,
      battleEngineMethod: move.battleEngineMethod,
      coverage: coverage,
      psdkStatus: manifestEntry?.status.name ?? 'unknown_method',
      reason: _coverageReasonForMove(
        move: move,
        manifestEntry: manifestEntry,
        coverage: coverage,
      ),
      sourceFile: move.sourceFile,
    );
  }

  final String moveId;
  final String battleEngineMethod;
  final String coverage;
  final String psdkStatus;
  final String reason;
  final String sourceFile;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'battleEngineMethod': battleEngineMethod,
      'coverage': coverage,
      'psdkStatus': psdkStatus,
      'reason': reason,
      'sourceFile': sourceFile,
    };
  }
}

final class PsdkAttackParityMetrics {
  const PsdkAttackParityMetrics({
    required this.totalAttacks,
    required this.uniqueBattleEngineMethods,
    required this.fait,
    required this.partiel,
    required this.pasFait,
    required this.unknownMethods,
  });

  factory PsdkAttackParityMetrics.fromEntries({
    required List<PsdkStudioMoveCoverageEntry> moves,
    required List<PsdkMoveRegistryManifestEntry> manifest,
  }) {
    final manifestByMethod = <String, PsdkMoveRegistryManifestEntry>{
      for (final entry in manifest) entry.battleEngineMethod: entry,
      for (final entry in psdkStudioOnlyBattleMethods)
        entry.battleEngineMethod: entry,
    };
    var fait = 0;
    var partiel = 0;
    var pasFait = 0;
    var unknownMethods = 0;
    for (final move in moves) {
      final manifestEntry = manifestByMethod[move.battleEngineMethod];
      final coverage = psdkAttackCoverageForMove(move, manifestEntry);
      switch (coverage) {
        case 'fait':
          fait++;
        case 'partiel':
          partiel++;
        case 'pas_fait':
          pasFait++;
          if (manifestEntry == null) {
            unknownMethods++;
          }
        default:
          throw StateError('Unknown PSDK attack coverage "$coverage".');
      }
    }
    return PsdkAttackParityMetrics(
      totalAttacks: moves.length,
      uniqueBattleEngineMethods:
          moves.map((move) => move.battleEngineMethod).toSet().length,
      fait: fait,
      partiel: partiel,
      pasFait: pasFait,
      unknownMethods: unknownMethods,
    );
  }

  final int totalAttacks;
  final int uniqueBattleEngineMethods;
  final int fait;
  final int partiel;
  final int pasFait;
  final int unknownMethods;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'totalAttacks': totalAttacks,
      'uniqueBattleEngineMethods': uniqueBattleEngineMethods,
      'fait': fait,
      'partiel': partiel,
      'pasFait': pasFait,
      'unknownMethods': unknownMethods,
    };
  }
}

final class PsdkMethodParityMetrics {
  const PsdkMethodParityMetrics({
    required this.totalMethods,
    required this.byStatus,
  });

  factory PsdkMethodParityMetrics.fromManifest(
    List<PsdkMoveRegistryManifestEntry> manifest,
  ) {
    return PsdkMethodParityMetrics(
      totalMethods: manifest.length,
      byStatus: _statusCounts(manifest.map((entry) => entry.status)),
    );
  }

  final int totalMethods;
  final Map<PsdkPortStatus, int> byStatus;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'totalMethods': totalMethods,
      'byStatus': _statusJson(byStatus),
    };
  }
}

final class PsdkEffectParityMetrics {
  const PsdkEffectParityMetrics({
    required this.totalEffects,
    required this.byStatus,
    required this.byFamilyAndStatus,
  });

  factory PsdkEffectParityMetrics.fromEntries(
    List<PsdkEffectParityEntry> effects,
  ) {
    final byFamilyAndStatus = <String, Map<PsdkPortStatus, int>>{};
    for (final effect in effects) {
      final counts = byFamilyAndStatus.putIfAbsent(
        effect.family,
        () => _emptyStatusCounts(),
      );
      counts[effect.status] = (counts[effect.status] ?? 0) + 1;
    }
    return PsdkEffectParityMetrics(
      totalEffects: effects.length,
      byStatus: _statusCounts(effects.map((entry) => entry.status)),
      byFamilyAndStatus: <String, Map<PsdkPortStatus, int>>{
        for (final entry in byFamilyAndStatus.entries)
          entry.key: Map<PsdkPortStatus, int>.unmodifiable(entry.value),
      },
    );
  }

  final int totalEffects;
  final Map<PsdkPortStatus, int> byStatus;
  final Map<String, Map<PsdkPortStatus, int>> byFamilyAndStatus;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'totalEffects': totalEffects,
      'byStatus': _statusJson(byStatus),
      'byFamilyAndStatus': <String, Object?>{
        for (final entry in byFamilyAndStatus.entries)
          entry.key: _statusJson(entry.value),
      },
    };
  }
}

final class PsdkEffectParityEntry {
  const PsdkEffectParityEntry({
    required this.effectName,
    required this.family,
    required this.status,
    this.rubyPath = '',
    this.hookFamilies = const <String>[],
  });

  final String effectName;
  final String family;
  final PsdkPortStatus status;
  final String rubyPath;
  final List<String> hookFamilies;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'effectName': effectName,
      'family': family,
      'status': status.name,
      'rubyPath': rubyPath,
      'hookFamilies': hookFamilies,
    };
  }
}

final class PsdkRuntimeBridgeParity {
  const PsdkRuntimeBridgeParity({
    required this.status,
    required this.reason,
    this.totalMoves = 0,
    this.bridgeableMoves = 0,
    this.rejectedMoves = 0,
    this.explainedRejectedMoves = 0,
    this.unexplainedRejectedMoves = 0,
    this.moves = const <PsdkRuntimeBridgeMoveEntry>[],
  });

  const PsdkRuntimeBridgeParity.notMeasured()
      : status = 'not_measured',
        reason =
            'Runtime bridge diagnostics live in packages/map_runtime and are opened by Lot 04.',
        totalMoves = 0,
        bridgeableMoves = 0,
        rejectedMoves = 0,
        explainedRejectedMoves = 0,
        unexplainedRejectedMoves = 0,
        moves = const <PsdkRuntimeBridgeMoveEntry>[];

  factory PsdkRuntimeBridgeParity.fromJson(Map<String, Object?> json) {
    final moves =
        (json['moves'] as List<Object?>? ?? const <Object?>[]).map((value) {
      if (value is! Map) {
        throw FormatException('Runtime bridge move entry must be an object.');
      }
      return PsdkRuntimeBridgeMoveEntry.fromJson(
        value.cast<String, Object?>(),
      );
    }).toList(growable: false);
    final bridgeableMoves = _optionalIntValue(json['bridgeableMoves']) ??
        moves.where((move) => move.bridgeable).length;
    final rejectedMoves = _optionalIntValue(json['rejectedMoves']) ??
        moves.where((move) => !move.bridgeable).length;
    final explainedRejectedMoves =
        _optionalIntValue(json['explainedRejectedMoves']) ??
            moves
                .where((move) => !move.bridgeable && move.reason.isNotEmpty)
                .length;
    final totalMoves = _optionalIntValue(json['totalMoves']) ?? moves.length;
    return PsdkRuntimeBridgeParity(
      status: _optionalStringValue(json['status']) ??
          (rejectedMoves == 0 ? 'complete' : 'explained'),
      reason: _optionalStringValue(json['reason']) ??
          'Runtime bridge diagnostics imported from JSON.',
      totalMoves: totalMoves,
      bridgeableMoves: bridgeableMoves,
      rejectedMoves: rejectedMoves,
      explainedRejectedMoves: explainedRejectedMoves,
      unexplainedRejectedMoves:
          _optionalIntValue(json['unexplainedRejectedMoves']) ??
              (rejectedMoves - explainedRejectedMoves),
      moves: List<PsdkRuntimeBridgeMoveEntry>.unmodifiable(moves),
    );
  }

  final String status;
  final String reason;
  final int totalMoves;
  final int bridgeableMoves;
  final int rejectedMoves;
  final int explainedRejectedMoves;
  final int unexplainedRejectedMoves;
  final List<PsdkRuntimeBridgeMoveEntry> moves;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'status': status,
      'reason': reason,
      'totalMoves': totalMoves,
      'bridgeableMoves': bridgeableMoves,
      'rejectedMoves': rejectedMoves,
      'explainedRejectedMoves': explainedRejectedMoves,
      'unexplainedRejectedMoves': unexplainedRejectedMoves,
      'moves': moves.map((move) => move.toJson()).toList(),
    };
  }
}

Future<PsdkFightParityAudit> buildPsdkFightParityAudit({
  required Directory movesDirectory,
  required Directory psdkBattleDirectory,
  List<PsdkMoveRegistryManifestEntry> manifest = psdkMoveRegistryManifest,
  PsdkRuntimeBridgeParity runtimeBridge =
      const PsdkRuntimeBridgeParity.notMeasured(),
}) async {
  final moves = await loadPsdkStudioMoveCoverageEntries(movesDirectory);
  final effects = await loadPsdkEffectParityEntries(psdkBattleDirectory);
  final audit = PsdkFightParityAudit.fromEntries(
    sourceDescription:
        'moves=${movesDirectory.path}; effects=${psdkBattleDirectory.path}',
    moves: moves,
    manifest: manifest,
    effects: effects,
  );
  return PsdkFightParityAudit(
    sourceDescription: audit.sourceDescription,
    attackMetrics: audit.attackMetrics,
    methodMetrics: audit.methodMetrics,
    effectMetrics: audit.effectMetrics,
    attackEntries: audit.attackEntries,
    methodEntries: audit.methodEntries,
    effectEntries: audit.effectEntries,
    runtimeBridge: runtimeBridge,
  );
}

final class PsdkRuntimeBridgeMoveEntry {
  const PsdkRuntimeBridgeMoveEntry({
    required this.moveId,
    required this.bridgeable,
    required this.reason,
    this.battleEngineMethod,
    this.psdkRegistryStatus,
    this.unsupportedReasons = const <String>[],
  });

  factory PsdkRuntimeBridgeMoveEntry.fromJson(Map<String, Object?> json) {
    return PsdkRuntimeBridgeMoveEntry(
      moveId: _requiredStringValue(json['moveId'], 'moveId'),
      bridgeable: _requiredBoolValue(json['bridgeable'], 'bridgeable'),
      reason: _optionalStringValue(json['reason']) ?? '',
      battleEngineMethod: _optionalStringValue(json['battleEngineMethod']),
      psdkRegistryStatus: _optionalStringValue(json['psdkRegistryStatus']),
      unsupportedReasons:
          (json['unsupportedReasons'] as List<Object?>? ?? const <Object?>[])
              .map((value) => value.toString())
              .toList(growable: false),
    );
  }

  final String moveId;
  final bool bridgeable;
  final String reason;
  final String? battleEngineMethod;
  final String? psdkRegistryStatus;
  final List<String> unsupportedReasons;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'bridgeable': bridgeable,
      'reason': reason,
      if (battleEngineMethod != null) 'battleEngineMethod': battleEngineMethod,
      if (psdkRegistryStatus != null) 'psdkRegistryStatus': psdkRegistryStatus,
      'unsupportedReasons': unsupportedReasons,
    };
  }
}

Future<List<PsdkEffectParityEntry>> loadPsdkEffectParityEntries(
  Directory psdkBattleDirectory,
) async {
  if (!await psdkBattleDirectory.exists()) {
    throw StateError(
      'PSDK battle folder not found: ${psdkBattleDirectory.path}',
    );
  }

  final effectRoot =
      _childDir(psdkBattleDirectory, '06 Effects') ?? psdkBattleDirectory;
  final rows = <PsdkEffectParityEntry>[];
  await for (final entity in effectRoot.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.rb')) {
      continue;
    }
    final relativePath = _relativePath(psdkBattleDirectory, entity);
    final classes = _parseRubyClasses(await entity.readAsString());
    for (final parsedClass in classes) {
      if (_isGenericContainerClass(parsedClass.name, classes)) {
        continue;
      }
      final family = _effectFamily(relativePath);
      rows.add(
        PsdkEffectParityEntry(
          effectName: parsedClass.name,
          family: family,
          status: psdkEffectPortStatusFor(
            effectName: parsedClass.name,
            family: family,
            rubyPath: relativePath,
          ),
          rubyPath: relativePath,
          hookFamilies: _hookFamiliesFor(parsedClass.sortedHooks),
        ),
      );
    }
  }
  rows.sort((left, right) {
    final byName = left.effectName.compareTo(right.effectName);
    if (byName != 0) return byName;
    return left.family.compareTo(right.family);
  });
  return List.unmodifiable(rows);
}

Map<PsdkPortStatus, int> _emptyStatusCounts() {
  return <PsdkPortStatus, int>{
    for (final status in PsdkPortStatus.values) status: 0,
  };
}

Map<PsdkPortStatus, int> _statusCounts(Iterable<PsdkPortStatus> statuses) {
  final counts = _emptyStatusCounts();
  for (final status in statuses) {
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _statusJson(Map<PsdkPortStatus, int> counts) {
  return <String, int>{
    for (final status in PsdkPortStatus.values)
      status.name: counts[status] ?? 0,
  };
}

List<_ParsedRubyClass> _parseRubyClasses(String content) {
  final classes = <_ParsedRubyClass>[];
  final blockStack = <_RubyBlock>[];
  for (final line in content.split('\n')) {
    final classMatch = _classLinePattern.firstMatch(line);
    if (classMatch != null) {
      final index = classes.length;
      classes.add(_ParsedRubyClass(name: classMatch.group(1)!));
      blockStack.add(_RubyBlock.classBlock(index));
      continue;
    }

    final hookMatch = _hookLinePattern.firstMatch(line);
    if (hookMatch != null) {
      final classIndex = _currentClassIndex(blockStack);
      if (classIndex != null) {
        classes[classIndex].hooks.add(hookMatch.group(1)!);
      }
    }

    if (_startsRubyBlock(line)) {
      blockStack.add(const _RubyBlock.other());
      continue;
    }

    if (RegExp(r'^\s*end\b').hasMatch(line) && blockStack.isNotEmpty) {
      blockStack.removeLast();
    }
  }
  return classes;
}

int? _currentClassIndex(List<_RubyBlock> blockStack) {
  for (var index = blockStack.length - 1; index >= 0; index -= 1) {
    final block = blockStack[index];
    if (block.classIndex != null) {
      return block.classIndex;
    }
  }
  return null;
}

bool _startsRubyBlock(String line) {
  if (RegExp(r'^\s*(return|next|break)\s+(if|unless)\b').hasMatch(line)) {
    return false;
  }
  return _blockStartPattern.hasMatch(line);
}

bool _isGenericContainerClass(
  String effectName,
  List<_ParsedRubyClass> parsedClasses,
) {
  const genericContainers = <String>{
    'Ability',
    'FieldTerrain',
    'Item',
    'Status',
    'Weather',
  };
  return genericContainers.contains(effectName) && parsedClasses.length > 1;
}

String _effectFamily(String rubyPath) {
  if (rubyPath.contains('04 Ability Effects')) return 'ability';
  if (rubyPath.contains('05 Item Effects')) return 'item';
  if (rubyPath.contains('03 Status Effects')) return 'status';
  if (rubyPath.contains('06 Weather Effects')) return 'field';
  if (rubyPath.contains('07 Field Terrain Effects')) return 'field';
  if (rubyPath.contains('02 Move Effects')) return 'move';
  return 'mechanics';
}

PsdkPortStatus psdkEffectPortStatusFor({
  required String effectName,
  required String family,
  required String rubyPath,
}) {
  if (family == 'move' &&
      rubyPath.contains('02 Move Effects/001 HelpingHand.rb') &&
      (effectName == 'HelpingHand' || effectName == 'Mark')) {
    return PsdkPortStatus.ported;
  }
  final manifestStatus = _manifestStatusForEffect(
    effectName: effectName,
    family: family,
    rubyPath: rubyPath,
  );
  if (manifestStatus != null && manifestStatus != PsdkPortStatus.missing) {
    return manifestStatus;
  }
  return _explicitEffectStatusFor(effectName);
}

PsdkPortStatus? _manifestStatusForEffect({
  required String effectName,
  required String family,
  required String rubyPath,
}) {
  final normalizedPath = _normalizeEffectManifestPath(rubyPath);
  if (family == 'ability') {
    return _abilityEffectStatusByName[effectName] ??
        _abilityEffectStatusByPath[normalizedPath];
  }
  if (family == 'item') {
    return _itemEffectStatusByName[effectName] ??
        _itemEffectStatusByPath[normalizedPath];
  }
  return null;
}

PsdkPortStatus _explicitEffectStatusFor(String effectName) {
  const portedEffects = <String>{
    'Ability',
    'AbilitySuppressed',
    'Asleep',
    'AttackMultiplier',
    'Attract',
    'AquaRing',
    'ArenaTrap',
    'Autotomize',
    'AuroraVeil',
    'BanefulBunker',
    'BatonPass',
    'Berry',
    'BeakBlast',
    'Bestow',
    'Bind',
    'Burn',
    'BurnUp',
    'BurningBulwark',
    'CantSwitch',
    'CenterOfAttention',
    'ChangeType',
    'Charge',
    'Commanded',
    'Commanding',
    'Confusion',
    'CraftyShield',
    'Curse',
    'DefenseMultiplier',
    'DestinyBond',
    'Disable',
    'DragonCheer',
    'Drowsiness',
    'EffectBase',
    'EffectsHandler',
    'EchoedVoice',
    'Electric',
    'Embargo',
    'Encore',
    'Electrify',
    'Endure',
    'FieldTerrain',
    'FairyLock',
    'Flinch',
    'Fog',
    'FocusEnergy',
    'FocusPunch',
    'ForceNextMoveBase',
    'Foresight',
    'Frozen',
    'FutureSight',
    'FuryCutter',
    'GlaiveRush',
    'Gravity',
    'Grudge',
    'Grassy',
    'Hail',
    'Hardrain',
    'Hardsun',
    'HappyHour',
    'HealBlock',
    'HealingWish',
    'Imposter',
    'Imprison',
    'Instruct',
    'Ingrain',
    'IonDeluge',
    'Item',
    'ItemBurnt',
    'ItemStolen',
    'KingsShield',
    'LaserFocus',
    'LeechSeed',
    'LightScreen',
    'LockOn',
    'LuckyChant',
    'LunarDance',
    'MagnetPull',
    'MagicCoat',
    'MagicRoom',
    'MagnetRise',
    'Mark',
    'Minimize',
    'Misty',
    'Nightmare',
    'MiracleEye',
    'NeutralizingGas',
    'NoRetreat',
    'Obstruct',
    'Octolock',
    'OutOfReachBase',
    'PerishSong',
    'Paralysis',
    'Poison',
    'PokemonTiedEffectBase',
    'PositionTiedEffectBase',
    'Powder',
    'PreventTargetsMove',
    'MatBlock',
    'Mist',
    'MudSport',
    'Protect',
    'Psychic',
    'QuickGuard',
    'Rage',
    'Rainbow',
    'Rain',
    'Reflect',
    'Rollout',
    'Roost',
    'Safeguard',
    'SaltCure',
    'Sandstorm',
    'SeaOfFire',
    'ShadowTag',
    'ShedTail',
    'SilkTrap',
    'ShellTrap',
    'SmackDown',
    'Snatch',
    'Snatched',
    'Snow',
    'SleepPrevention',
    'Spikes',
    'SpikyShield',
    'Status',
    'StealthRock',
    'StickyWeb',
    'Stockpile',
    'StrongWinds',
    'Substitute',
    'Swamp',
    'Sunny',
    'SyrupBomb',
    'Tailwind',
    'TarShot',
    'Taunt',
    'Telekinesis',
    'ThroatChop',
    'Torment',
    'TripleArrows',
    'Toxic',
    'ToxicSpikes',
    'Transform',
    'TrickRoom',
    'UpRoar',
    'WaterSport',
    'Weather',
    'WideGuard',
    'Wish',
    'WonderRoom',
  };
  const partialEffects = <String>{
    'Bide',
    'ParentalBond',
  };
  if (portedEffects.contains(effectName)) {
    return PsdkPortStatus.ported;
  }
  if (partialEffects.contains(effectName)) {
    return PsdkPortStatus.partial;
  }
  return PsdkPortStatus.missing;
}

List<String> _hookFamiliesFor(List<String> hooks) {
  final families = <String>{};
  for (final hook in hooks) {
    final family = _hookFamilyFor(hook);
    if (family != null) {
      families.add(family);
    }
  }
  return families.toList()..sort();
}

String? _hookFamilyFor(String hook) {
  if (hook == 'on_move_ability_immunity') {
    return 'ability_immunity';
  }
  if (hook == 'on_move_priority_change') {
    return 'action_order';
  }
  if (hook == 'on_move_type_change') {
    return 'move_type_change';
  }
  if (hook == 'on_pre_accuracy_check' || hook == 'on_post_accuracy_check') {
    return 'accuracy';
  }
  if (hook == 'on_two_turn_shortcut') {
    return 'two_turn_shortcut';
  }
  if (hook == 'on_move_disabled_check' ||
      hook == 'on_move_failure' ||
      hook.startsWith('on_move_prevention')) {
    return 'move_prevention';
  }
  if (hook == 'on_damage_prevention') {
    return 'damage_prevention';
  }
  if (hook == 'on_post_damage' || hook == 'on_post_damage_death') {
    return 'post_damage';
  }
  if (hook == 'on_drain_prevention' || hook == 'on_pre_drain') {
    return 'drain';
  }
  if (hook.contains('status')) {
    return 'status_prevention';
  }
  if (hook.contains('stat')) {
    return 'stat_change';
  }
  if (hook.contains('weather')) {
    return 'weather_change';
  }
  if (hook.contains('fterrain')) {
    return 'terrain_change';
  }
  if (hook.contains('item')) {
    return 'item_change';
  }
  if (hook.contains('ability_change')) {
    return 'ability_change';
  }
  if (hook.contains('switch') || hook.contains('flee')) {
    return 'switch';
  }
  if (hook == 'on_end_turn_event') {
    return 'end_turn';
  }
  if (hook == 'on_post_action_event') {
    return 'action_order';
  }
  if (hook == 'on_transform_event') {
    return 'transform';
  }
  if (hook == 'on_single_type_multiplier_overwrite') {
    return 'damage_change';
  }
  if (hook.startsWith('on_delete') ||
      hook == 'on_reset_states' ||
      hook == 'on_clear_message' ||
      hook == 'on_increase_message') {
    return 'lifecycle';
  }
  return null;
}

final Map<String, PsdkPortStatus> _abilityEffectStatusByName =
    _buildAbilityEffectStatusByName();
final Map<String, PsdkPortStatus> _abilityEffectStatusByPath =
    _buildAbilityEffectStatusByPath();
final Map<String, PsdkPortStatus> _itemEffectStatusByName =
    _buildItemEffectStatusByName();
final Map<String, PsdkPortStatus> _itemEffectStatusByPath =
    _buildItemEffectStatusByPath();

Map<String, PsdkPortStatus> _buildAbilityEffectStatusByName() {
  final grouped = <String, List<PsdkPortStatus>>{};
  for (final entry in psdkAbilityEffectManifest) {
    grouped
        .putIfAbsent(_pascalCaseManifestId(entry.abilityId), () => [])
        .add(_abilityPortStatus(entry.status));
  }
  return _combineGroupedStatuses(grouped);
}

Map<String, PsdkPortStatus> _buildAbilityEffectStatusByPath() {
  final grouped = <String, List<PsdkPortStatus>>{};
  for (final entry in psdkAbilityEffectManifest) {
    grouped
        .putIfAbsent(_normalizeEffectManifestPath(entry.rubyPath), () => [])
        .add(_abilityPortStatus(entry.status));
  }
  return _combineGroupedStatuses(grouped);
}

Map<String, PsdkPortStatus> _buildItemEffectStatusByName() {
  final grouped = <String, List<PsdkPortStatus>>{};
  for (final entry in psdkItemEffectManifest) {
    grouped
        .putIfAbsent(_itemEffectNameFromId(entry.itemId), () => [])
        .add(_itemPortStatus(entry.status));
  }
  return _combineGroupedStatuses(grouped);
}

Map<String, PsdkPortStatus> _buildItemEffectStatusByPath() {
  final grouped = <String, List<PsdkPortStatus>>{};
  for (final entry in psdkItemEffectManifest) {
    grouped
        .putIfAbsent(_normalizeEffectManifestPath(entry.rubyPath), () => [])
        .add(_itemPortStatus(entry.status));
  }
  return _combineGroupedStatuses(grouped);
}

Map<String, PsdkPortStatus> _combineGroupedStatuses(
  Map<String, List<PsdkPortStatus>> grouped,
) {
  return Map.unmodifiable(<String, PsdkPortStatus>{
    for (final entry in grouped.entries)
      entry.key: _combineStatuses(entry.value),
  });
}

PsdkPortStatus _combineStatuses(List<PsdkPortStatus> statuses) {
  if (statuses.isEmpty ||
      statuses.every((status) => status == PsdkPortStatus.missing)) {
    return PsdkPortStatus.missing;
  }
  if (statuses.every((status) => status == PsdkPortStatus.ported)) {
    return PsdkPortStatus.ported;
  }
  return PsdkPortStatus.partial;
}

PsdkPortStatus _abilityPortStatus(PsdkAbilityPortStatus status) {
  return switch (status) {
    PsdkAbilityPortStatus.ported => PsdkPortStatus.ported,
    PsdkAbilityPortStatus.partial => PsdkPortStatus.partial,
    PsdkAbilityPortStatus.missing ||
    PsdkAbilityPortStatus.outOfScope =>
      PsdkPortStatus.missing,
  };
}

PsdkPortStatus _itemPortStatus(PsdkItemPortStatus status) {
  return switch (status) {
    PsdkItemPortStatus.ported => PsdkPortStatus.ported,
    PsdkItemPortStatus.partial => PsdkPortStatus.partial,
    PsdkItemPortStatus.missing ||
    PsdkItemPortStatus.outOfScope =>
      PsdkPortStatus.missing,
  };
}

String _itemEffectNameFromId(String itemId) {
  if (itemId.endsWith('_berry')) {
    return _pascalCaseManifestId(
      itemId.substring(0, itemId.length - '_berry'.length),
    );
  }
  return _pascalCaseManifestId(itemId);
}

String _pascalCaseManifestId(String id) {
  return id
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

String _normalizeEffectManifestPath(String rubyPath) {
  final normalizedSeparators = rubyPath.replaceAll('\\', '/');
  const marker = '5 Battle/';
  final markerIndex = normalizedSeparators.indexOf(marker);
  if (markerIndex == -1) {
    return normalizedSeparators;
  }
  return normalizedSeparators.substring(markerIndex + marker.length);
}

Directory? _childDir(Directory root, String childName) {
  final child = Directory('${root.path}/$childName');
  return child.existsSync() ? child : null;
}

String _relativePath(Directory root, File file) {
  final rootPath = _withTrailingSeparator(root.absolute.path);
  final filePath = file.absolute.path;
  if (filePath.startsWith(rootPath)) {
    return filePath.substring(rootPath.length);
  }
  return filePath;
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

String _md(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('|', r'\|')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .trim();
}

Map<String, PsdkMoveRegistryManifestEntry> _manifestByMethod(
  List<PsdkMoveRegistryManifestEntry> manifest,
) {
  return <String, PsdkMoveRegistryManifestEntry>{
    for (final entry in manifest) entry.battleEngineMethod: entry,
    for (final entry in psdkStudioOnlyBattleMethods)
      entry.battleEngineMethod: entry,
  };
}

Map<String, Object?> _methodEntryJson(PsdkMoveRegistryManifestEntry entry) {
  return <String, Object?>{
    'battleEngineMethod': entry.battleEngineMethod,
    'rubyClass': entry.rubyClass,
    'rubyPath': entry.rubyPath,
    'dartBehavior': entry.dartBehavior,
    'status': entry.status.name,
    'dependencies':
        entry.dependencies.map((dependency) => dependency.name).toList(),
    if (entry.status != PsdkPortStatus.ported)
      'methodBatch': _methodBacklogBatchFor(entry).id,
  };
}

List<Map<String, Object?>> _methodBacklogBatchJson(
  List<PsdkMoveRegistryManifestEntry> entries,
) {
  return _methodBacklogBatches(entries)
      .map(
        (batch) => <String, Object?>{
          'id': batch.id,
          'label': batch.label,
          'count': batch.methods.length,
          'methods': batch.methods,
        },
      )
      .toList(growable: false);
}

List<_MethodBacklogBatch> _methodBacklogBatches(
  List<PsdkMoveRegistryManifestEntry> entries,
) {
  final byId = <String, _MethodBacklogBatch>{
    for (final definition in _methodBacklogBatchDefinitions)
      definition.id: _MethodBacklogBatch(
        id: definition.id,
        label: definition.label,
        methods: <String>[],
      ),
  };
  for (final entry
      in entries.where((entry) => entry.status != PsdkPortStatus.ported)) {
    byId[_methodBacklogBatchFor(entry).id]!.methods.add(
          entry.battleEngineMethod,
        );
  }
  return <_MethodBacklogBatch>[
    for (final definition in _methodBacklogBatchDefinitions)
      if (byId[definition.id]!.methods.isNotEmpty)
        byId[definition.id]!..methods.sort(),
  ];
}

_MethodBacklogBatchDefinition _methodBacklogBatchFor(
  PsdkMoveRegistryManifestEntry entry,
) {
  final dependencies = entry.dependencies.map((dependency) => dependency.name);
  final dependencySet = dependencies.toSet();
  if (dependencySet.contains('actionOrder')) {
    return _actionQueueMethodBatch;
  }
  if (dependencySet.contains('endTurn') && dependencySet.length == 1) {
    return _multiturnMethodBatch;
  }
  if (dependencySet.intersection(_damageFormulaDependencies).isNotEmpty) {
    return _damageFormulaMethodBatch;
  }
  if (dependencySet.intersection(_failurePreventionDependencies).isNotEmpty &&
      dependencySet.difference(_failurePreventionDependencies).isEmpty) {
    return _failurePreventionMethodBatch;
  }
  if (dependencySet.contains('targetingMulti') && dependencySet.length == 1) {
    return _targetingMethodBatch;
  }
  if (dependencySet.contains('effects')) {
    return _effectManifestSweepMethodBatch;
  }
  return _effectManifestSweepMethodBatch;
}

const _actionQueueMethodBatch = _MethodBacklogBatchDefinition(
  id: 'action_queue_copy_call',
  label: 'Action queue / copy-call residuals',
);
const _targetingMethodBatch = _MethodBacklogBatchDefinition(
  id: 'target_resolution_doubles',
  label: 'Target resolution / doubles topology',
);
const _damageFormulaMethodBatch = _MethodBacklogBatchDefinition(
  id: 'damage_formula_variable_power',
  label: 'Damage formula / variable power',
);
const _failurePreventionMethodBatch = _MethodBacklogBatchDefinition(
  id: 'failure_prevention_immunity',
  label: 'Failure / prevention / immunity',
);
const _multiturnMethodBatch = _MethodBacklogBatchDefinition(
  id: 'multiturn_delayed_state',
  label: 'Multi-turn / delayed state',
);
const _effectManifestSweepMethodBatch = _MethodBacklogBatchDefinition(
  id: 'effect_hook_manifest_sweep',
  label: 'Effect hook / manifest final sweep',
);
const _methodBacklogBatchDefinitions = <_MethodBacklogBatchDefinition>[
  _actionQueueMethodBatch,
  _targetingMethodBatch,
  _failurePreventionMethodBatch,
  _multiturnMethodBatch,
  _damageFormulaMethodBatch,
  _effectManifestSweepMethodBatch,
];
const _damageFormulaDependencies = <String>{
  'accuracy',
  'handlerDamage',
};
const _failurePreventionDependencies = <String>{
  'faintProcess',
  'handlerItem',
  'handlerStat',
  'handlerStatus',
  'handlerSwitch',
};

final class _MethodBacklogBatchDefinition {
  const _MethodBacklogBatchDefinition({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

final class _MethodBacklogBatch {
  _MethodBacklogBatch({
    required this.id,
    required this.label,
    required this.methods,
  });

  final String id;
  final String label;
  final List<String> methods;
}

String _coverageReasonForMove({
  required PsdkStudioMoveCoverageEntry move,
  required PsdkMoveRegistryManifestEntry? manifestEntry,
  required String coverage,
}) {
  if (manifestEntry == null) {
    return 'unknown_method';
  }
  if (manifestEntry.status == PsdkPortStatus.missing) {
    return 'method_missing';
  }
  if (manifestEntry.status == PsdkPortStatus.partial) {
    return 'method_partial';
  }
  if (coverage == 'fait') {
    return 'strict_ported';
  }
  return 'ported_method_metadata_outside_strict_slice';
}

void _writePartialAttacksByMethod(
  StringBuffer buffer,
  List<PsdkAttackParityEntry> entries,
) {
  final counts = <String, int>{};
  for (final entry in entries.where((entry) => entry.coverage == 'partiel')) {
    counts[entry.battleEngineMethod] =
        (counts[entry.battleEngineMethod] ?? 0) + 1;
  }
  buffer
    ..writeln()
    ..writeln('### Partial Attacks by Method')
    ..writeln()
    ..writeln('| Battle method | Partial attacks |')
    ..writeln('| --- | ---: |');
  for (final method in counts.keys.toList()..sort()) {
    buffer.writeln('| ${_md(method)} | ${counts[method]} |');
  }
}

void _writePartialMethodsByDependency(
  StringBuffer buffer,
  List<PsdkMoveRegistryManifestEntry> entries,
) {
  final counts = <String, int>{};
  for (final entry in entries.where(
    (entry) => entry.status == PsdkPortStatus.partial,
  )) {
    final dependencies = entry.dependencies.isEmpty
        ? const <String>['no_dependency_declared']
        : entry.dependencies.map((dependency) => dependency.name);
    for (final dependency in dependencies) {
      counts[dependency] = (counts[dependency] ?? 0) + 1;
    }
  }
  buffer
    ..writeln()
    ..writeln('### Partial Methods by Dependency')
    ..writeln()
    ..writeln('| Dependency | Partial methods |')
    ..writeln('| --- | ---: |');
  final sorted = counts.keys.toList()
    ..sort((left, right) {
      final byCount = counts[right]!.compareTo(counts[left]!);
      return byCount == 0 ? left.compareTo(right) : byCount;
    });
  for (final dependency in sorted) {
    buffer.writeln('| ${_md(dependency)} | ${counts[dependency]} |');
  }
}

void _writePartialMethodBatches(
  StringBuffer buffer,
  List<PsdkMoveRegistryManifestEntry> entries,
) {
  final batches = _methodBacklogBatches(entries);
  if (batches.isEmpty) {
    return;
  }
  buffer
    ..writeln()
    ..writeln('### Partial Method Batches')
    ..writeln()
    ..writeln(
      'Each partial method is assigned to its first actionable Phase 2 batch.',
    )
    ..writeln()
    ..writeln('| Batch | Partial methods | Methods |')
    ..writeln('| --- | ---: | --- |');
  for (final batch in batches) {
    buffer.writeln(
      '| ${_md(batch.label)} | ${batch.methods.length} | '
      '${batch.methods.map((method) => '`$method`').join(', ')} |',
    );
  }
}

void _writeMissingEffectsByFamily(
  StringBuffer buffer,
  List<PsdkEffectParityEntry> entries,
) {
  final counts = <String, int>{};
  for (final entry in entries.where(
    (entry) => entry.status == PsdkPortStatus.missing,
  )) {
    counts[entry.family] = (counts[entry.family] ?? 0) + 1;
  }
  buffer
    ..writeln()
    ..writeln('### Missing Effects by Family')
    ..writeln()
    ..writeln('| Family | Missing effects |')
    ..writeln('| --- | ---: |');
  for (final family in counts.keys.toList()..sort()) {
    buffer.writeln('| ${_md(family)} | ${counts[family]} |');
  }
}

String _requiredStringValue(Object? value, String field) {
  final result = _optionalStringValue(value);
  if (result == null || result.isEmpty) {
    throw FormatException('Missing required runtime bridge field "$field".');
  }
  return result;
}

String? _optionalStringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int? _optionalIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _requiredBoolValue(Object? value, String field) {
  if (value is bool) return value;
  throw FormatException('Missing required runtime bridge bool "$field".');
}

final class _ParsedRubyClass {
  _ParsedRubyClass({required this.name});

  final String name;
  final List<String> hooks = <String>[];

  List<String> get sortedHooks => hooks.toSet().toList()..sort();
}

final class _RubyBlock {
  const _RubyBlock.other() : classIndex = null;

  const _RubyBlock.classBlock(this.classIndex);

  final int? classIndex;
}
