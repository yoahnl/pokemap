import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final config = _CliConfig.fromArgs(args);
  const renderer = _PhaseBScaffoldPackCoverageRenderer(
    bridge: RuntimeBattleMoveBridge(),
  );

  final report = await renderer.render(
    bootstrapJsonPath: config.bootstrapJsonPath,
    baselineBootstrapJsonPath: config.baselineBootstrapJsonPath,
    baselineLabel: config.baselineLabel,
    importPackDirectory: config.importPackDirectory,
    level: config.level,
  );

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(report);
  stdout.writeln(
    'Phase B scaffold pack coverage written to ${outputFile.path}',
  );
}

class _CliConfig {
  const _CliConfig({
    required this.bootstrapJsonPath,
    required this.importPackDirectory,
    required this.outputPath,
    required this.level,
    required this.baselineBootstrapJsonPath,
    required this.baselineLabel,
  });

  final String bootstrapJsonPath;
  final String importPackDirectory;
  final String outputPath;
  final int level;
  final String? baselineBootstrapJsonPath;
  final String? baselineLabel;

  static _CliConfig fromArgs(List<String> args) {
    String readRequiredFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        throw ArgumentError('Missing required flag $name');
      }
      return args[index + 1];
    }

    String? readOptionalFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        return null;
      }
      return args[index + 1];
    }

    final rawLevel = readOptionalFlag('--level');
    final level = rawLevel == null ? 10 : int.parse(rawLevel);
    if (level <= 0) {
      throw ArgumentError('--level must be a positive integer');
    }

    return _CliConfig(
      bootstrapJsonPath: readRequiredFlag('--bootstrap-json'),
      importPackDirectory: readRequiredFlag('--import-pack'),
      outputPath: readRequiredFlag('--output'),
      level: level,
      baselineBootstrapJsonPath: readOptionalFlag('--baseline-bootstrap-json'),
      baselineLabel: readOptionalFlag('--baseline-label'),
    );
  }
}

/// Phase B mesure volontairement autre chose que Phase A.
///
/// Phase A mesurait la vérité produit du golden slice versionné.
/// Phase B doit répondre à une autre question :
/// - est-ce qu'un mini-lift bootstrap améliore réellement la battleability du
///   scaffold/import le plus proche de la réalité versionnée aujourd'hui ;
/// - sans pour autant prendre ce pack d'import pour "la vérité produit".
///
/// On reste donc délibérément sur un audit local et borné :
/// - un bootstrap exporté depuis `map_editor` ;
/// - un pack d'import versionné ;
/// - la même helper de sélection de learnset que le runtime ;
/// - le vrai bridge runtime -> battle.
class _PhaseBScaffoldPackCoverageRenderer {
  const _PhaseBScaffoldPackCoverageRenderer({
    required this.bridge,
  });

  final RuntimeBattleMoveBridge bridge;

  Future<String> render({
    required String bootstrapJsonPath,
    required String? baselineBootstrapJsonPath,
    required String? baselineLabel,
    required String importPackDirectory,
    required int level,
  }) async {
    final currentCatalog = await _loadBootstrapCatalog(bootstrapJsonPath);
    final baselineCatalog = baselineBootstrapJsonPath == null
        ? null
        : await _loadBootstrapCatalog(baselineBootstrapJsonPath);
    final speciesSeeds = await _loadImportPackSpeciesSeeds(
      importPackDirectory: importPackDirectory,
      level: level,
    );

    final currentSpeciesRows = speciesSeeds
        .map((seed) => _evaluateSpeciesSeed(seed, currentCatalog))
        .toList(growable: false)
      ..sort((left, right) => left.speciesId.compareTo(right.speciesId));
    final baselineSpeciesRowsById = baselineCatalog == null
        ? const <String, _SpeciesCoverageRow>{}
        : <String, _SpeciesCoverageRow>{
            for (final seed in speciesSeeds)
              seed.speciesId: _evaluateSpeciesSeed(seed, baselineCatalog),
          };

    final moveRows = _buildMoveRows(
      speciesSeeds: speciesSeeds,
      currentCatalog: currentCatalog,
      baselineCatalog: baselineCatalog,
    )..sort((left, right) => left.moveId.compareTo(right.moveId));

    final currentSummary = _summarizeSpeciesRows(currentSpeciesRows);
    final baselineSummary = baselineCatalog == null
        ? null
        : _summarizeSpeciesRows(
            baselineSpeciesRowsById.values.toList(growable: false),
          );
    final deltaRows = baselineCatalog == null
        ? const <_SpeciesDeltaRow>[]
        : currentSpeciesRows
            .map(
              (row) => _SpeciesDeltaRow(
                speciesId: row.speciesId,
                beforeStatus: baselineSpeciesRowsById[row.speciesId]!.status,
                afterStatus: row.status,
                beforeBuiltMoveIds:
                    baselineSpeciesRowsById[row.speciesId]!.builtMoveIds,
                afterBuiltMoveIds: row.builtMoveIds,
                deltaLabel: _classifyDelta(
                  before: baselineSpeciesRowsById[row.speciesId]!.status,
                  after: row.status,
                ),
              ),
            )
            .toList(growable: false);

    final improvedSpecies =
        deltaRows.where((row) => row.deltaLabel != '').toList(growable: false);

    return <String>[
      '# Phase B Scaffold Pack Coverage',
      '',
      '## Executive Summary',
      '',
      '- Import pack directory: `${p.normalize(importPackDirectory)}`',
      '- Level analyzed with the shared runtime learnset helper: `$level`',
      '- Species seeds analyzed: `${speciesSeeds.length}`',
      if (baselineSummary != null && baselineLabel != null)
        '- Baseline descriptor: `$baselineLabel`',
      if (baselineSummary != null) ...<String>[
        '- Baseline fully covered damage-ready species: '
            '`${baselineSummary.fullDamageReady}`',
        '- Baseline partial damage-ready species: '
            '`${baselineSummary.partialDamageReady}`',
        '- Baseline partial status-only species: '
            '`${baselineSummary.partialStatusOnly}`',
        '- Baseline blocked species: `${baselineSummary.blocked}`',
      ],
      '- Current fully covered damage-ready species: '
          '`${currentSummary.fullDamageReady}`',
      '- Current partial damage-ready species: '
          '`${currentSummary.partialDamageReady}`',
      '- Current partial status-only species: '
          '`${currentSummary.partialStatusOnly}`',
      '- Current blocked species: `${currentSummary.blocked}`',
      if (baselineSummary != null)
        '- Species with a strictly better status after the lift: '
            '`${improvedSpecies.length}`',
      '',
      '## Current Candidate Move Coverage',
      '',
      _markdownTable(
        <String>[
          'moveId',
          'occurrences',
          'species',
          if (baselineSummary != null) 'baselineStatus',
          'currentStatus',
          'currentBridgeFailure',
          'currentUnsupportedReasons',
        ],
        moveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.occurrenceCount.toString(),
                row.speciesIds.join(', '),
                if (baselineSummary != null) row.baselineStatus,
                row.currentStatus,
                row.currentBridgeFailure,
                row.currentUnsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Current Species Coverage',
      '',
      _markdownTable(
        const <String>[
          'speciesId',
          'candidateMoveIds',
          'builtMoveIds',
          'missingMoveIds',
          'rejectedMoveIds',
          'status',
        ],
        currentSpeciesRows
            .map(
              (row) => <String>[
                row.speciesId,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.missingMoveIds.join(', '),
                row.rejectedMoveIds.join(', '),
                row.status,
              ],
            )
            .toList(growable: false),
      ),
      if (baselineSummary != null) ...<String>[
        '',
        '## Baseline vs Current Species Delta',
        '',
        _markdownTable(
          const <String>[
            'speciesId',
            'beforeStatus',
            'afterStatus',
            'beforeBuiltMoveIds',
            'afterBuiltMoveIds',
            'delta',
          ],
          deltaRows
              .map(
                (row) => <String>[
                  row.speciesId,
                  row.beforeStatus,
                  row.afterStatus,
                  row.beforeBuiltMoveIds.join(', '),
                  row.afterBuiltMoveIds.join(', '),
                  row.deltaLabel,
                ],
              )
              .toList(growable: false),
        ),
      ],
      '',
      '## Notes',
      '',
      '- This report is **not** a product truth report like Phase A.',
      '- It measures scaffold/import-pack truth with the real bootstrap and the '
          'real runtime bridge.',
      '- `full_damage_ready` means every candidate move is bridgeable and at '
          'least one built move is offensive.',
      '- `partial_damage_ready` means the seed remains usable in battle, but '
          'some candidate moves are still missing or rejected.',
      '- `partial_status_only` means the seed can still be built, but only '
          'with non-offensive moves after filtering.',
      '- `blocked` means no bridgeable move remains after filtering.',
      '',
    ].join('\n');
  }

  Future<_BootstrapCatalog> _loadBootstrapCatalog(String jsonPath) async {
    final decoded = jsonDecode(await File(jsonPath).readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Bootstrap JSON must decode to an object: $jsonPath');
    }

    final entries = (decoded['entries'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .map(PokemonMove.fromJson)
        .toList(growable: false);

    return _BootstrapCatalog(
      movesById: <String, PokemonMove>{
        for (final move in entries) move.id: move,
      },
    );
  }

  Future<List<_ImportPackSpeciesSeed>> _loadImportPackSpeciesSeeds({
    required String importPackDirectory,
    required int level,
  }) async {
    final learnsetsDirectory = Directory(
      p.join(importPackDirectory, 'learnsets'),
    );
    if (!await learnsetsDirectory.exists()) {
      throw StateError(
        'Import pack learnsets directory not found: ${learnsetsDirectory.path}',
      );
    }

    final files = learnsetsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.json')
        .toList(growable: false)
      ..sort((left, right) => left.path.compareTo(right.path));

    final seeds = <_ImportPackSpeciesSeed>[];
    for (final file in files) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError(
          'Learnset JSON must decode to an object: ${file.path}',
        );
      }

      final learnset = RuntimePokemonLearnset(
        startingMoves:
            ((decoded['startingMoves'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false)),
        relearnMoves:
            ((decoded['relearnMoves'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false)),
        levelUp: ((decoded['levelUp'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .map(
              (entry) => RuntimePokemonLevelUpMove(
                moveId: (entry['moveId'] as String?)?.trim() ?? '',
                level: (entry['level'] as num?)?.toInt() ?? 0,
              ),
            )
            .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
            .toList(growable: false)),
      );

      seeds.add(
        _ImportPackSpeciesSeed(
          speciesId: p.basenameWithoutExtension(file.path),
          candidateMoveIds: deriveBattleCandidateMoveIdsFromLearnset(
            learnset: learnset,
            level: level,
          ),
        ),
      );
    }

    return seeds;
  }

  _SpeciesCoverageRow _evaluateSpeciesSeed(
    _ImportPackSpeciesSeed seed,
    _BootstrapCatalog catalog,
  ) {
    final diagnostics = _diagnoseSpeciesSeed(seed, catalog);

    // Point de vérité important pour Gate B :
    // - le statut global du seed ne vient PAS du diagnostic move par move ;
    // - il vient de la helper runtime partagée qui reproduit exactement la
    //   sévérité réelle du handoff seed -> battle ;
    // - les listes `missingMoveIds` / `rejectedMoveIds` restent des indices
    //   explicatifs, mais elles ne doivent plus piloter un verdict optimiste.
    List<String> builtMoveIds;
    var status = 'blocked';
    try {
      final builtMoves = resolveBattleMovesForSeed(
        moveIds: seed.candidateMoveIds,
        combatantLabel: 'Phase B scaffold audit:${seed.speciesId}',
        lookupMove: catalog.lookup,
        battleMoveBridge: bridge,
      );
      builtMoveIds = builtMoves.map((move) => move.id).toList(growable: false);
      final hasOffensiveMove = builtMoveIds.any((moveId) {
        final move = catalog.lookup(moveId);
        return move != null && _isOffensiveMove(move);
      });
      status = switch ((
        hasOffensiveMove,
        seed.candidateMoveIds.length == builtMoveIds.length
      )) {
        (false, true) => 'full_status_only',
        (false, false) => 'partial_status_only',
        (true, true) => 'full_damage_ready',
        (true, false) => 'partial_damage_ready',
      };
    } on RuntimeBattleSetupException {
      builtMoveIds = const <String>[];
    }

    return _SpeciesCoverageRow(
      speciesId: seed.speciesId,
      candidateMoveIds: seed.candidateMoveIds,
      builtMoveIds: List<String>.unmodifiable(builtMoveIds),
      missingMoveIds: List<String>.unmodifiable(diagnostics.missingMoveIds),
      rejectedMoveIds: List<String>.unmodifiable(diagnostics.rejectedMoveIds),
      status: status,
    );
  }

  _SpeciesDiagnostics _diagnoseSpeciesSeed(
    _ImportPackSpeciesSeed seed,
    _BootstrapCatalog catalog,
  ) {
    final missingMoveIds = <String>[];
    final rejectedMoveIds = <String>[];

    for (final moveId in seed.candidateMoveIds) {
      final move = catalog.lookup(moveId);
      if (move == null) {
        missingMoveIds.add(moveId);
        continue;
      }

      try {
        bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Phase B scaffold diagnostic:${seed.speciesId}',
        );
      } on RuntimeBattleSetupException {
        rejectedMoveIds.add(moveId);
      }
    }

    return _SpeciesDiagnostics(
      missingMoveIds: List<String>.unmodifiable(missingMoveIds),
      rejectedMoveIds: List<String>.unmodifiable(rejectedMoveIds),
    );
  }

  List<_MoveCoverageRow> _buildMoveRows({
    required List<_ImportPackSpeciesSeed> speciesSeeds,
    required _BootstrapCatalog currentCatalog,
    required _BootstrapCatalog? baselineCatalog,
  }) {
    final usagesByMoveId = <String, _MoveUsage>{};
    for (final seed in speciesSeeds) {
      for (final moveId in seed.candidateMoveIds) {
        final current = usagesByMoveId[moveId];
        usagesByMoveId[moveId] = current == null
            ? _MoveUsage(
                moveId: moveId,
                occurrenceCount: 1,
                speciesIds: <String>[seed.speciesId],
              )
            : current.addSpecies(seed.speciesId);
      }
    }

    return usagesByMoveId.values.map((usage) {
      final currentEvaluation = _evaluateMoveStatus(
        usage.moveId,
        currentCatalog,
      );
      final baselineEvaluation = baselineCatalog == null
          ? null
          : _evaluateMoveStatus(
              usage.moveId,
              baselineCatalog,
            );
      return _MoveCoverageRow(
        moveId: usage.moveId,
        occurrenceCount: usage.occurrenceCount,
        speciesIds: usage.speciesIds,
        baselineStatus: baselineEvaluation?.statusLabel ?? '',
        currentStatus: currentEvaluation.statusLabel,
        currentBridgeFailure: currentEvaluation.bridgeFailure,
        currentUnsupportedReasons: currentEvaluation.unsupportedReasons,
      );
    }).toList(growable: false);
  }

  _MoveStatusEvaluation _evaluateMoveStatus(
    String moveId,
    _BootstrapCatalog catalog,
  ) {
    final move = catalog.movesById[moveId];
    if (move == null) {
      return const _MoveStatusEvaluation(
        statusLabel: 'missing_from_bootstrap',
        bridgeFailure: '',
        unsupportedReasons: '',
      );
    }

    try {
      bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Phase B scaffold audit move:$moveId',
      );
      return const _MoveStatusEvaluation(
        statusLabel: 'bridgeable',
        bridgeFailure: '',
        unsupportedReasons: '',
      );
    } on RuntimeBattleSetupException catch (error) {
      return _MoveStatusEvaluation(
        statusLabel: 'present_not_bridgeable',
        bridgeFailure: _extractBridgeFailure(error),
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    }
  }

  _CoverageSummary _summarizeSpeciesRows(List<_SpeciesCoverageRow> rows) {
    var fullDamageReady = 0;
    var partialDamageReady = 0;
    var partialStatusOnly = 0;
    var blocked = 0;

    for (final row in rows) {
      switch (row.status) {
        case 'full_damage_ready':
          fullDamageReady++;
        case 'partial_damage_ready':
          partialDamageReady++;
        case 'full_status_only':
        case 'partial_status_only':
          partialStatusOnly++;
        case 'blocked':
          blocked++;
      }
    }

    return _CoverageSummary(
      fullDamageReady: fullDamageReady,
      partialDamageReady: partialDamageReady,
      partialStatusOnly: partialStatusOnly,
      blocked: blocked,
    );
  }

  bool _isOffensiveMove(PokemonMove move) {
    // Garde-fou volontairement simple :
    // - pour ce lot, on cherche surtout à distinguer un vrai move offensif
    //   simple d'un set réduit à des moves de statut ;
    // - on ne tente pas ici de reproduire toute la sémantique Showdown ;
    // - dans le scope Phase B choisi, la catégorie du move suffit.
    return move.category != PokemonMoveCategory.status;
  }

  String _classifyDelta({
    required String before,
    required String after,
  }) {
    if (before == after) {
      return '';
    }
    return switch ((before, after)) {
      ('blocked', 'partial_status_only') => 'unblocked_status_only',
      ('blocked', 'partial_damage_ready') => 'unblocked_damage_ready',
      ('blocked', 'full_damage_ready') => 'fully_unblocked_damage_ready',
      ('partial_status_only', 'partial_damage_ready') =>
        'status_only_to_damage_ready',
      ('partial_status_only', 'full_damage_ready') =>
        'status_only_to_full_damage_ready',
      ('partial_damage_ready', 'full_damage_ready') =>
        'partial_to_full_damage_ready',
      (_, 'full_damage_ready') => 'improved_to_full_damage_ready',
      (_, 'partial_damage_ready') => 'improved_to_damage_ready',
      _ => 'changed',
    };
  }
}

class _BootstrapCatalog {
  const _BootstrapCatalog({
    required this.movesById,
  });

  final Map<String, PokemonMove> movesById;

  PokemonMove? lookup(String moveId) => movesById[moveId.trim()];
}

class _ImportPackSpeciesSeed {
  const _ImportPackSpeciesSeed({
    required this.speciesId,
    required this.candidateMoveIds,
  });

  final String speciesId;
  final List<String> candidateMoveIds;
}

class _SpeciesCoverageRow {
  const _SpeciesCoverageRow({
    required this.speciesId,
    required this.candidateMoveIds,
    required this.builtMoveIds,
    required this.missingMoveIds,
    required this.rejectedMoveIds,
    required this.status,
  });

  final String speciesId;
  final List<String> candidateMoveIds;
  final List<String> builtMoveIds;
  final List<String> missingMoveIds;
  final List<String> rejectedMoveIds;
  final String status;
}

class _SpeciesDiagnostics {
  const _SpeciesDiagnostics({
    required this.missingMoveIds,
    required this.rejectedMoveIds,
  });

  final List<String> missingMoveIds;
  final List<String> rejectedMoveIds;
}

class _SpeciesDeltaRow {
  const _SpeciesDeltaRow({
    required this.speciesId,
    required this.beforeStatus,
    required this.afterStatus,
    required this.beforeBuiltMoveIds,
    required this.afterBuiltMoveIds,
    required this.deltaLabel,
  });

  final String speciesId;
  final String beforeStatus;
  final String afterStatus;
  final List<String> beforeBuiltMoveIds;
  final List<String> afterBuiltMoveIds;
  final String deltaLabel;
}

class _CoverageSummary {
  const _CoverageSummary({
    required this.fullDamageReady,
    required this.partialDamageReady,
    required this.partialStatusOnly,
    required this.blocked,
  });

  final int fullDamageReady;
  final int partialDamageReady;
  final int partialStatusOnly;
  final int blocked;
}

class _MoveUsage {
  const _MoveUsage({
    required this.moveId,
    required this.occurrenceCount,
    required this.speciesIds,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> speciesIds;

  _MoveUsage addSpecies(String speciesId) {
    if (speciesIds.contains(speciesId)) {
      return this;
    }
    return _MoveUsage(
      moveId: moveId,
      occurrenceCount: occurrenceCount + 1,
      speciesIds: <String>[...speciesIds, speciesId],
    );
  }
}

class _MoveCoverageRow {
  const _MoveCoverageRow({
    required this.moveId,
    required this.occurrenceCount,
    required this.speciesIds,
    required this.baselineStatus,
    required this.currentStatus,
    required this.currentBridgeFailure,
    required this.currentUnsupportedReasons,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> speciesIds;
  final String baselineStatus;
  final String currentStatus;
  final String currentBridgeFailure;
  final String currentUnsupportedReasons;
}

class _MoveStatusEvaluation {
  const _MoveStatusEvaluation({
    required this.statusLabel,
    required this.bridgeFailure,
    required this.unsupportedReasons,
  });

  final String statusLabel;
  final String bridgeFailure;
  final String unsupportedReasons;
}

String _extractBridgeFailure(RuntimeBattleSetupException error) {
  final debugDetails = error.debugDetails?.trim() ?? '';
  if (debugDetails.isEmpty) {
    return '';
  }

  final bridgeLimitMatch = RegExp(r'bridgeLimit=([^,]+)').firstMatch(
    debugDetails,
  );
  if (bridgeLimitMatch != null) {
    return bridgeLimitMatch.group(1) ?? '';
  }

  return debugDetails;
}

String _markdownTable(List<String> headers, List<List<String>> rows) {
  final buffer = StringBuffer()
    ..writeln('| ${headers.join(' | ')} |')
    ..writeln('| ${List<String>.filled(headers.length, '---').join(' | ')} |');
  for (final row in rows) {
    buffer.writeln('| ${row.join(' | ')} |');
  }
  return buffer.toString().trimRight();
}
