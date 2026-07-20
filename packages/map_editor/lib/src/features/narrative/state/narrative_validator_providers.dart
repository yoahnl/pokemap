import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_authoring_session.dart';
import '../../../application/services/narrative_studio_validation_coordinator.dart';
import '../../../application/services/narrative_diagnostic_suppression_service.dart';
import '../../../application/services/pokemon_project_data_reader.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../../infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';

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
  const NarrativeValidatorSnapshotRequest({
    required this.projectRootPath,
    required this.snapshotFingerprint,
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
    return NarrativeValidatorSnapshotRequest(
      projectRootPath: p.normalize(projectRootPath),
      snapshotFingerprint: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8({
          'project': project.toJson(),
          if (activeMap != null) 'activeMap': activeMap.toJson(),
          if (pokemonCatalogFingerprint != null)
            'pokemonCatalogFingerprint': pokemonCatalogFingerprint,
        }),
      ),
      project: project,
      activeMap: activeMap,
      pokemonCatalogFingerprint: pokemonCatalogFingerprint,
    );
  }

  final String projectRootPath;
  final String snapshotFingerprint;
  final ProjectManifest project;
  final MapData? activeMap;
  final String? pokemonCatalogFingerprint;

  NarrativeValidatorSnapshotRequest withPokemonCatalogFingerprint(
    String fingerprint,
  ) {
    return NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRootPath,
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

typedef LoadNarrativeValidatorPokemonCatalogSnapshot
    = Future<NarrativeValidatorPokemonCatalogSnapshot> Function(
  NarrativeValidatorPokemonCatalogRequest request,
);

typedef LoadNarrativeValidatorReport = Future<NarrativeProjectValidationReport>
    Function(
  NarrativeValidatorSnapshotRequest request,
  NarrativeValidatorPokemonCatalogSnapshot pokemonCatalogs,
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

/// Replaceable I/O seam: maps are loaded through the attested project session,
/// while the report deliberately validates the current in-memory manifest.
/// The active map replaces its saved version so unsaved authoring changes are
/// visible instead of making the Validator stale or unavailable.
final narrativeValidatorReportLoaderProvider =
    Provider<LoadNarrativeValidatorReport>((ref) {
  return (request, pokemonCatalogs) async {
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(request.projectRootPath, 'project.json'),
    );
    final maps = session.maps.toList(growable: true);
    final activeMap = request.activeMap;
    if (activeMap != null) {
      final index = maps.indexWhere((map) => map.id == activeMap.id);
      if (index < 0) {
        maps.add(activeMap);
      } else {
        maps[index] = activeMap;
      }
    }
    return validateNarrativeProject(
      request.project,
      maps: maps,
      knownSpeciesIds: pokemonCatalogs.speciesIds,
      knownMoveIds: pokemonCatalogs.moveIds,
      requirePokemonCatalogs: request.project.pokemon.enabled,
    );
  };
});

final narrativeValidatorReportProvider = FutureProvider.autoDispose.family<
    NarrativeProjectValidationReport,
    NarrativeValidatorSnapshotRequest>((ref, request) {
  final catalogRequest =
      NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(request);
  final loadReport = ref.watch(narrativeValidatorReportLoaderProvider);
  return ref
      .watch(narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest)
          .future)
      .then((pokemonCatalogs) {
    final effectiveRequest =
        request.withPokemonCatalogFingerprint(pokemonCatalogs.fingerprint);
    return loadReport(
      effectiveRequest,
      pokemonCatalogs,
    );
  });
});

final narrativeStudioValidationCoordinatorProvider =
    Provider<NarrativeStudioValidationCoordinator>((ref) {
  return const NarrativeStudioValidationCoordinator();
});

final narrativeDiagnosticSuppressionServiceProvider =
    Provider<NarrativeDiagnosticSuppressionService>((ref) {
  return const NarrativeDiagnosticSuppressionService();
});

final narrativeRuntimeSmokeReceiptRepositoryProvider =
    Provider<NarrativeRuntimeSmokeReceiptRepository>((ref) {
  return const NarrativeRuntimeSmokeReceiptRepository();
});

/// Publication-oriented report. The historical provider above remains the
/// authoring read model; this provider is the single four-dimensional gate.
final narrativeStudioValidationReportProvider = FutureProvider.autoDispose
    .family<NarrativeMultidimensionalValidationReport,
        NarrativeValidatorSnapshotRequest>((ref, request) async {
  final projectReport = await ref.watch(
    narrativeValidatorReportProvider(request).future,
  );
  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(request.projectRootPath, 'project.json'),
  );
  final maps = session.maps.toList(growable: true);
  final activeMap = request.activeMap;
  if (activeMap != null) {
    final index = maps.indexWhere((map) => map.id == activeMap.id);
    if (index < 0) {
      maps.add(activeMap);
    } else {
      maps[index] = activeMap;
    }
  }
  final repository = ref.watch(
    narrativeRuntimeSmokeReceiptRepositoryProvider,
  );
  final fingerprint = await repository.computeProjectFingerprint(
    request.projectRootPath,
  );
  final receipt = await repository.read(
    projectRoot: request.projectRootPath,
    expectedFingerprint: fingerprint,
    profile: selbrumeReleaseV1Profile,
  );
  return ref.watch(narrativeStudioValidationCoordinatorProvider).coordinate(
        project: request.project,
        maps: maps,
        projectReport: projectReport,
        projectFingerprint: fingerprint,
        profile: selbrumeReleaseV1Profile,
        runtimeReceipt: receipt,
      );
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
