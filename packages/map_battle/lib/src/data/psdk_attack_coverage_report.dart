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
  });

  final String dbSymbol;
  final String battleEngineMethod;
  final String type;
  final String category;
  final int power;
  final String accuracy;
  final int pp;
  final String sourceFile;
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
    sourceFile: sourceFile,
  );
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
      coverage: switch (manifestEntry?.status) {
        PsdkPortStatus.ported => 'fait',
        PsdkPortStatus.partial => 'partiel',
        PsdkPortStatus.missing || null => 'pas_fait',
      },
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
