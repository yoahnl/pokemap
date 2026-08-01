import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/services/narrative_diagnostic_suppression_service.dart';
import '../../../application/services/narrative_validator_isolate_executor.dart';
import '../../../application/services/pokemon_project_data_reader.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';

class NarrativeValidatorPokemonCatalogSnapshot {
  NarrativeValidatorPokemonCatalogSnapshot({
    required Set<String>? speciesIds,
    required Set<String>? moveIds,
  })  : speciesIds = speciesIds == null
            ? null
            : Set<String>.unmodifiable(_normalizedIds(speciesIds)),
        moveIds = moveIds == null
            ? null
            : Set<String>.unmodifiable(_normalizedIds(moveIds)) {
    final sortedSpeciesIds = this.speciesIds == null
        ? null
        : (this.speciesIds!.toList(growable: false)..sort());
    final sortedMoveIds = this.moveIds == null
        ? null
        : (this.moveIds!.toList(growable: false)..sort());
    fingerprint = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8({
        'speciesCatalogAvailable': this.speciesIds != null,
        'speciesIds': sortedSpeciesIds ?? const <String>[],
        'moveCatalogAvailable': this.moveIds != null,
        'moveIds': sortedMoveIds ?? const <String>[],
      }),
    );
  }

  final Set<String>? speciesIds;
  final Set<String>? moveIds;
  late final String fingerprint;
}

class NarrativeValidatorPokemonCatalogRequest {
  NarrativeValidatorPokemonCatalogRequest({
    required String projectRootPath,
    required this.pokemon,
  })  : projectRootPath = p.normalize(projectRootPath),
        configFingerprint = narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(pokemon.toJson()),
        );

  factory NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(
    NarrativeValidatorSnapshotRequest request,
  ) {
    return NarrativeValidatorPokemonCatalogRequest(
      projectRootPath: request.projectRootPath,
      pokemon: request.project.pokemon,
    );
  }

  final String projectRootPath;
  final ProjectPokemonConfig pokemon;
  final String configFingerprint;

  @override
  bool operator ==(Object other) =>
      other is NarrativeValidatorPokemonCatalogRequest &&
      other.projectRootPath == projectRootPath &&
      other.configFingerprint == configFingerprint;

  @override
  int get hashCode => Object.hash(projectRootPath, configFingerprint);
}

class NarrativeValidatorSnapshotRequest {
  const NarrativeValidatorSnapshotRequest._({
    required this.projectRootPath,
    required this.snapshotFingerprint,
    required this.contentFingerprint,
    required this.project,
    this.activeMap,
    this.pokemonCatalogFingerprint,
  });

  factory NarrativeValidatorSnapshotRequest.fromProject({
    required String projectRootPath,
    required ProjectManifest project,
    MapData? activeMap,
    String? pokemonCatalogFingerprint,
  }) {
    final contentFingerprint = _narrativeSnapshotContentFingerprint(
      project,
      activeMap,
    );
    return NarrativeValidatorSnapshotRequest._(
      projectRootPath: p.normalize(projectRootPath),
      snapshotFingerprint: _narrativeSnapshotFingerprint(
        contentFingerprint,
        pokemonCatalogFingerprint,
      ),
      contentFingerprint: contentFingerprint,
      project: project,
      activeMap: activeMap,
      pokemonCatalogFingerprint: pokemonCatalogFingerprint,
    );
  }

  final String projectRootPath;
  final String snapshotFingerprint;
  final String contentFingerprint;
  final ProjectManifest project;
  final MapData? activeMap;
  final String? pokemonCatalogFingerprint;

  NarrativeValidatorSnapshotRequest withPokemonCatalogFingerprint(
    String fingerprint,
  ) {
    return NarrativeValidatorSnapshotRequest._(
      projectRootPath: projectRootPath,
      snapshotFingerprint: _narrativeSnapshotFingerprint(
        contentFingerprint,
        fingerprint,
      ),
      contentFingerprint: contentFingerprint,
      project: project,
      activeMap: activeMap,
      pokemonCatalogFingerprint: fingerprint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NarrativeValidatorSnapshotRequest &&
      other.projectRootPath == projectRootPath &&
      other.snapshotFingerprint == snapshotFingerprint;

  @override
  int get hashCode => Object.hash(projectRootPath, snapshotFingerprint);
}

final Expando<String> _projectSnapshotFingerprintCache =
    Expando<String>('narrative-validator-project-fingerprint');
final Expando<String> _mapSnapshotFingerprintCache =
    Expando<String>('narrative-validator-map-fingerprint');

String _narrativeSnapshotContentFingerprint(
  ProjectManifest project,
  MapData? activeMap,
) {
  final projectFingerprint = _projectSnapshotFingerprintCache[project] ??=
      _jsonFingerprint(project.toJson());
  final activeMapFingerprint = activeMap == null
      ? null
      : _mapSnapshotFingerprintCache[activeMap] ??=
          _jsonFingerprint(activeMap.toJson());
  return narrativeEventBytesFingerprint(
    utf8.encode(
      'project=$projectFingerprint\nactiveMap=${activeMapFingerprint ?? ''}',
    ),
  );
}

String _narrativeSnapshotFingerprint(
  String contentFingerprint,
  String? pokemonCatalogFingerprint,
) {
  return narrativeEventBytesFingerprint(
    utf8.encode(
      'content=$contentFingerprint\n'
      'pokemonCatalog=${pokemonCatalogFingerprint ?? ''}',
    ),
  );
}

String _jsonFingerprint(Object? value) {
  // ProjectManifest and MapData are immutable editor snapshots: every edit
  // must replace the root object. Caching that identity keeps rebuilds O(1).
  // This lightweight canonical writer preserves map-order independence
  // without the path construction and I-JSON validation cost of the durable
  // RFC 8785 codec, which is unnecessary for already-validated model JSON.
  final buffer = StringBuffer();
  _writeStableSnapshotJson(value, buffer);
  return narrativeEventBytesFingerprint(utf8.encode(buffer.toString()));
}

void _writeStableSnapshotJson(Object? value, StringBuffer buffer) {
  switch (value) {
    case null || bool() || num() || String():
      buffer.write(jsonEncode(value));
    case List():
      buffer.write('[');
      for (var index = 0; index < value.length; index++) {
        if (index != 0) buffer.write(',');
        _writeStableSnapshotJson(value[index], buffer);
      }
      buffer.write(']');
    case Map():
      final keys = <String>[];
      for (final key in value.keys) {
        if (key is! String) {
          throw const FormatException('Snapshot JSON keys must be strings.');
        }
        keys.add(key);
      }
      keys.sort(compareNarrativeEventUtf16);
      buffer.write('{');
      for (var index = 0; index < keys.length; index++) {
        if (index != 0) buffer.write(',');
        final key = keys[index];
        buffer
          ..write(jsonEncode(key))
          ..write(':');
        _writeStableSnapshotJson(value[key], buffer);
      }
      buffer.write('}');
    default:
      Object? jsonValue;
      try {
        jsonValue = (value as dynamic).toJson();
      } on NoSuchMethodError {
        throw FormatException(
          'Unsupported snapshot JSON value ${value.runtimeType}.',
        );
      }
      _writeStableSnapshotJson(jsonValue, buffer);
  }
}

typedef LoadNarrativeValidatorPokemonCatalogSnapshot
    = Future<NarrativeValidatorPokemonCatalogSnapshot> Function(
  NarrativeValidatorPokemonCatalogRequest request,
);

typedef LoadNarrativeValidatorExecution
    = Future<NarrativeValidatorExecutionResult> Function(
  NarrativeValidatorSnapshotRequest request,
  NarrativeValidatorPokemonCatalogSnapshot pokemonCatalogs,
  String validationId,
);

typedef LoadNarrativeMultidimensionalExecution
    = Future<NarrativeValidatorExecutionResult> Function(
  NarrativeValidatorSnapshotRequest request,
  NarrativeValidatorExecutionResult projectExecution,
);

final narrativeValidatorPokemonCatalogLoaderProvider =
    Provider<LoadNarrativeValidatorPokemonCatalogSnapshot>((ref) {
  return (request) async {
    if (!request.pokemon.enabled) {
      return NarrativeValidatorPokemonCatalogSnapshot(
        speciesIds: const <String>{},
        moveIds: const <String>{},
      );
    }

    final workspace = ProjectFileSystem(request.projectRootPath);
    const reader = PokemonProjectDataReader();
    final speciesFuture = _loadSpeciesIds(reader, workspace);
    final movesFuture = _loadMoveIds(reader, workspace);
    return NarrativeValidatorPokemonCatalogSnapshot(
      speciesIds: await speciesFuture,
      moveIds: await movesFuture,
    );
  };
});

final narrativeValidatorPokemonCatalogSnapshotProvider =
    FutureProvider.autoDispose.family<NarrativeValidatorPokemonCatalogSnapshot,
        NarrativeValidatorPokemonCatalogRequest>((ref, request) {
  return ref.watch(narrativeValidatorPokemonCatalogLoaderProvider)(request);
});

final narrativeValidatorExecutorProvider =
    Provider<NarrativeValidatorExecutor>((ref) {
  final executor = IsolateNarrativeValidatorExecutor();
  ref.onDispose(executor.dispose);
  return executor;
});

/// Replaceable I/O seam: maps are loaded through the attested project session,
/// while the report deliberately validates the current in-memory manifest.
/// The active map replaces its saved version so unsaved authoring changes are
/// visible instead of making the Validator stale or unavailable.
final narrativeValidatorExecutionLoaderProvider =
    Provider<LoadNarrativeValidatorExecution>((ref) {
  final executor = ref.watch(narrativeValidatorExecutorProvider);
  return (request, pokemonCatalogs, validationId) async {
    return executor.execute(
      NarrativeValidatorWork(
        validationId: validationId,
        projectRootPath: request.projectRootPath,
        project: request.project,
        activeMap: request.activeMap,
        knownSpeciesIds: pokemonCatalogs.speciesIds,
        knownMoveIds: pokemonCatalogs.moveIds,
        requirePokemonCatalogs: request.project.pokemon.enabled,
      ),
    );
  };
});

final narrativeValidatorMultidimensionalExecutionLoaderProvider =
    Provider<LoadNarrativeMultidimensionalExecution>((ref) {
  final executor = ref.watch(narrativeValidatorExecutorProvider);
  return (request, projectExecution) {
    return executor.execute(
      NarrativeValidatorWork.multidimensional(
        validationId: _narrativeMultidimensionalValidationId(
          projectExecution.validationId,
        ),
        projectValidationId: projectExecution.validationId,
        projectRootPath: request.projectRootPath,
        project: request.project,
        activeMap: request.activeMap,
        projectReport: projectExecution.report!,
      ),
    );
  };
});

final narrativeValidatorExecutionProvider = FutureProvider.autoDispose.family<
    NarrativeValidatorExecutionResult,
    NarrativeValidatorSnapshotRequest>((ref, request) async {
  final catalogRequest =
      NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(request);
  final executor = ref.watch(narrativeValidatorExecutorProvider);
  final loadExecution = ref.watch(narrativeValidatorExecutionLoaderProvider);
  final pokemonCatalogsFuture = ref.watch(
    narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
  );
  final keepAliveLink = ref.keepAlive();
  var disposed = false;
  String? effectiveValidationId;
  ref.onCancel(keepAliveLink.close);
  ref.onDispose(() {
    disposed = true;
    final validationId = effectiveValidationId;
    if (validationId != null) {
      executor.cancel(validationId);
    }
  });

  try {
    final pokemonCatalogs = await pokemonCatalogsFuture;
    if (disposed) {
      throw NarrativeValidatorCancelledException(
        validationId: request.snapshotFingerprint,
        reason: NarrativeValidatorCancellationReason.providerDisposed,
      );
    }
    final effectiveRequest =
        request.withPokemonCatalogFingerprint(pokemonCatalogs.fingerprint);
    effectiveValidationId = _nextNarrativeValidationId(effectiveRequest);
    return await loadExecution(
      effectiveRequest,
      pokemonCatalogs,
      effectiveValidationId,
    );
  } finally {
    keepAliveLink.close();
  }
});

final narrativeValidatorReportProvider = FutureProvider.autoDispose.family<
    NarrativeProjectValidationReport,
    NarrativeValidatorSnapshotRequest>((ref, request) async {
  final keepAliveLink = ref.keepAlive();
  ref.onCancel(keepAliveLink.close);
  try {
    final execution = await ref.watch(
      narrativeValidatorExecutionProvider(request).future,
    );
    return execution.report ??
        (throw StateError(
          'The Narrative Validator worker returned the wrong phase.',
        ));
  } finally {
    keepAliveLink.close();
  }
});

var _narrativeValidationExecutionSequence = 0;

String _nextNarrativeValidationId(NarrativeValidatorSnapshotRequest request) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({
      'projectRootPath': request.projectRootPath,
      'snapshotFingerprint': request.snapshotFingerprint,
      'executionSequence': ++_narrativeValidationExecutionSequence,
    }),
  );
}

String _narrativeMultidimensionalValidationId(String projectValidationId) {
  return narrativeEventBytesFingerprint(
    utf8.encode('multidimensional=$projectValidationId'),
  );
}

final narrativeDiagnosticSuppressionServiceProvider =
    Provider<NarrativeDiagnosticSuppressionService>((ref) {
  return const NarrativeDiagnosticSuppressionService();
});

/// Publication-oriented report. The historical provider above remains the
/// authoring read model; this provider is the single four-dimensional gate.
final narrativeStudioValidationReportProvider = FutureProvider.autoDispose
    .family<NarrativeMultidimensionalValidationReport,
        NarrativeValidatorSnapshotRequest>((ref, request) async {
  final executor = ref.watch(narrativeValidatorExecutorProvider);
  final loadMultidimensional = ref.watch(
    narrativeValidatorMultidimensionalExecutionLoaderProvider,
  );
  final keepAliveLink = ref.keepAlive();
  var disposed = false;
  String? validationId;
  ref.onCancel(keepAliveLink.close);
  ref.onDispose(() {
    disposed = true;
    final id = validationId;
    if (id != null) {
      executor.cancel(id);
    }
  });
  try {
    final projectExecution = await ref.watch(
      narrativeValidatorExecutionProvider(request).future,
    );
    if (disposed) {
      throw NarrativeValidatorCancelledException(
        validationId: request.snapshotFingerprint,
        reason: NarrativeValidatorCancellationReason.providerDisposed,
      );
    }
    validationId = _narrativeMultidimensionalValidationId(
      projectExecution.validationId,
    );
    final execution = await loadMultidimensional(
      request,
      projectExecution,
    );
    return execution.multidimensionalReport ??
        (throw StateError(
          'The Narrative Validator worker returned the wrong phase.',
        ));
  } finally {
    keepAliveLink.close();
  }
});

Future<Set<String>?> _loadSpeciesIds(
  PokemonProjectDataReader reader,
  ProjectFileSystem workspace,
) async {
  try {
    return {
      for (final entry in await reader.listSpeciesIndexEntries(workspace))
        entry.id,
    };
  } catch (_) {
    return null;
  }
}

Future<Set<String>?> _loadMoveIds(
  PokemonProjectDataReader reader,
  ProjectFileSystem workspace,
) async {
  try {
    final catalog = await reader.readCatalogByKey(workspace, 'moves');
    return {
      for (final entry in catalog.entries)
        if (entry['id'] case final String id) id,
    };
  } catch (_) {
    return null;
  }
}

Set<String> _normalizedIds(Iterable<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet();
