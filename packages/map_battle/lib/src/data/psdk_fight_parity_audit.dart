import 'dart:convert';
import 'dart:io';

import 'generated/psdk_move_registry_manifest.dart';
import 'psdk_attack_coverage_report.dart';

final _classLinePattern = RegExp(
  r'^\s*class\s+([A-Za-z_][A-Za-z0-9_:]*)(?:\s*<\s*([A-Za-z0-9_:]+))?',
);
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
    this.runtimeBridge = const PsdkRuntimeBridgeParity.notMeasured(),
  });

  factory PsdkFightParityAudit.fromEntries({
    required String sourceDescription,
    required List<PsdkStudioMoveCoverageEntry> moves,
    required List<PsdkMoveRegistryManifestEntry> manifest,
    required List<PsdkEffectParityEntry> effects,
  }) {
    return PsdkFightParityAudit(
      sourceDescription: sourceDescription,
      attackMetrics: PsdkAttackParityMetrics.fromEntries(
        moves: moves,
        manifest: manifest,
      ),
      methodMetrics: PsdkMethodParityMetrics.fromManifest(manifest),
      effectMetrics: PsdkEffectParityMetrics.fromEntries(effects),
    );
  }

  final String sourceDescription;
  final PsdkAttackParityMetrics attackMetrics;
  final PsdkMethodParityMetrics methodMetrics;
  final PsdkEffectParityMetrics effectMetrics;
  final PsdkRuntimeBridgeParity runtimeBridge;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sourceDescription': sourceDescription,
      'attacks': attackMetrics.toJson(),
      'methods': methodMetrics.toJson(),
      'effects': effectMetrics.toJson(),
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
      )
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
      ..writeln('| Total manifest methods | ${methodMetrics.totalMethods} |')
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
    buffer
      ..writeln()
      ..writeln('## Runtime Bridge')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('| --- | --- |')
      ..writeln('| Status | `${runtimeBridge.status}` |')
      ..writeln('| Reason | ${_md(runtimeBridge.reason)} |');
    return buffer.toString();
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
  });

  final String effectName;
  final String family;
  final PsdkPortStatus status;
}

final class PsdkRuntimeBridgeParity {
  const PsdkRuntimeBridgeParity({
    required this.status,
    required this.reason,
  });

  const PsdkRuntimeBridgeParity.notMeasured()
      : status = 'not_measured',
        reason =
            'Runtime bridge diagnostics live in packages/map_runtime and are opened by Lot 04.';

  final String status;
  final String reason;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'status': status,
      'reason': reason,
    };
  }
}

Future<PsdkFightParityAudit> buildPsdkFightParityAudit({
  required Directory movesDirectory,
  required Directory psdkBattleDirectory,
  List<PsdkMoveRegistryManifestEntry> manifest = psdkMoveRegistryManifest,
}) async {
  final moves = await loadPsdkStudioMoveCoverageEntries(movesDirectory);
  final effects = await loadPsdkEffectParityEntries(psdkBattleDirectory);
  return PsdkFightParityAudit.fromEntries(
    sourceDescription:
        'moves=${movesDirectory.path}; effects=${psdkBattleDirectory.path}',
    moves: moves,
    manifest: manifest,
    effects: effects,
  );
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
      rows.add(
        PsdkEffectParityEntry(
          effectName: parsedClass.name,
          family: _effectFamily(relativePath),
          status: _statusForEffect(parsedClass.name),
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

PsdkPortStatus _statusForEffect(String effectName) {
  const partialEffects = <String>{
    'AquaRing',
    'ArenaTrap',
    'Attract',
    'BatonPass',
    'Bind',
    'CantSwitch',
    'Confusion',
    'Curse',
    'Disable',
    'Encore',
    'Flinch',
    'HealBlock',
    'Imprison',
    'Ingrain',
    'LeechSeed',
    'MagnetPull',
    'Protect',
    'SaltCure',
    'ShadowTag',
    'SmackDown',
    'SyrupBomb',
    'Taunt',
    'TarShot',
    'ThroatChop',
    'Torment',
  };
  return partialEffects.contains(effectName)
      ? PsdkPortStatus.partial
      : PsdkPortStatus.missing;
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

final class _ParsedRubyClass {
  const _ParsedRubyClass({required this.name});

  final String name;
}

final class _RubyBlock {
  const _RubyBlock.other() : classIndex = null;

  const _RubyBlock.classBlock(this.classIndex);

  final int? classIndex;
}
