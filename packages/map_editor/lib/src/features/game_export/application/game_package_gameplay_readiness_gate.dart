import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/pokemon_validation_report.dart';
import 'runtime_project_projection_builder.dart';

/// Evaluates the exact runtime projection that will be handed to the package
/// builder. It only orchestrates canonical map_core validators and adds the
/// publication invariants that are intentionally stricter than authoring.
final class GamePackageGameplayReadinessGate {
  const GamePackageGameplayReadinessGate();

  NarrativeProjectValidationReport evaluate(
    RuntimeProjectProjection projection, {
    PokemonValidationReport? pokemonValidationReport,
    Object? pokemonValidationFailure,
  }) {
    final project = projection.project;
    final diagnostics = <NarrativeProjectDiagnostic>[];

    try {
      ProjectValidator.validate(project);
    } on Object catch (error) {
      diagnostics.add(
        _diagnostic(
          code: 'exportProjectStructureInvalid',
          message: 'La structure du projet est invalide : $error',
          path: 'project.json',
        ),
      );
    }

    final maps = <MapData>[];
    for (final entry in project.maps) {
      final logicalPath = _projectPayloadPath(entry.relativePath);
      final bytes = projection.payloadFiles[logicalPath];
      if (bytes == null) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapPayloadMissing',
            message:
                'La map « ${entry.name} » est absente de la projection joueur.',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
        continue;
      }

      final MapData map;
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map) {
          throw const FormatException('map JSON root must be an object');
        }
        map = MapData.fromJson(Map<String, dynamic>.from(decoded));
      } on Object catch (error) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapPayloadInvalid',
            message: 'La map « ${entry.name} » ne peut pas être lue : $error',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
        continue;
      }

      maps.add(map);
      if (map.id != entry.id) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapIdMismatch',
            message: 'La map « ${entry.name} » annonce l’identifiant '
                '« ${map.id} » au lieu de « ${entry.id} ».',
            path: '${entry.relativePath}.id',
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
      }
      try {
        MapValidator.validate(
          map,
          projectDialogueContext: project,
        );
      } on Object catch (error) {
        diagnostics.add(
          _diagnostic(
            code: 'exportMapStructureInvalid',
            message: 'La map « ${entry.name} » est invalide : $error',
            path: entry.relativePath,
            domain: NarrativeProjectDiagnosticDomain.map,
            destination: NarrativeProjectDiagnosticDestination.map,
            mapId: entry.id,
          ),
        );
      }
    }

    final speciesIds =
        project.pokemon.enabled ? _projectedSpeciesIds(projection) : null;
    final moveIds =
        project.pokemon.enabled ? _projectedMoveIds(projection) : null;
    _appendPokemonValidationDiagnostics(
      project: project,
      report: pokemonValidationReport,
      failure: pokemonValidationFailure,
      target: diagnostics,
    );
    NarrativeProjectValidationReport? narrativeReport;
    try {
      narrativeReport = validateNarrativeProject(
        project,
        maps: maps,
        knownSpeciesIds: speciesIds,
        knownMoveIds: moveIds,
        requirePokemonCatalogs: project.pokemon.enabled,
      );
      diagnostics.addAll(narrativeReport.diagnostics);
    } on Object catch (error) {
      diagnostics.add(
        _diagnostic(
          code: 'exportNarrativeValidationUnavailable',
          message:
              'La validation de jouabilité n’a pas pu être exécutée : $error',
          path: 'project.json',
        ),
      );
    }

    final runtimeReachability = _runtimeEntryReachability(
      project: project,
      maps: maps,
      narrativeReport: narrativeReport,
      target: diagnostics,
    );
    _appendPublicationInvariants(
      project: project,
      maps: maps,
      runtimeReachability: runtimeReachability,
      target: diagnostics,
    );

    final unique = <String, NarrativeProjectDiagnostic>{};
    for (final diagnostic in diagnostics) {
      unique.putIfAbsent(diagnostic.stableKey, () => diagnostic);
    }
    final sorted = unique.values.toList(growable: false)
      ..sort((left, right) => left.stableKey.compareTo(right.stableKey));
    return NarrativeProjectValidationReport(
      diagnostics: sorted,
      mapEventViews:
          narrativeReport?.mapEventViews ?? const <NarrativeMapEventsView>[],
      symbolicReachability: runtimeReachability,
    );
  }
}

void _appendPublicationInvariants({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeSymbolicReachabilityReport? runtimeReachability,
  required List<NarrativeProjectDiagnostic> target,
}) {
  final newGame = project.newGame;
  if (!newGame.enabled) {
    target.add(
      _diagnostic(
        code: 'exportNewGameDisabled',
        message:
            'Activez Nouvelle Partie avant de publier un jeu certifié jouable.',
        path: 'newGame.enabled',
        suggestedFixLabel: 'Activer et configurer Nouvelle Partie.',
      ),
    );
  }

  final startMapId = newGame.startMapId.trim();
  final mapsById = <String, MapData>{
    for (final map in maps) map.id: map,
  };
  if (newGame.enabled &&
      (startMapId.isEmpty || !mapsById.containsKey(startMapId))) {
    target.add(
      _diagnostic(
        code: 'exportNewGameStartMapUnavailable',
        message: startMapId.isEmpty
            ? 'Choisissez une map de départ pour Nouvelle Partie.'
            : 'La map de départ « $startMapId » n’est pas disponible dans la '
                'projection joueur.',
        path: 'newGame.startMapId',
        domain: NarrativeProjectDiagnosticDomain.map,
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: startMapId.isEmpty ? null : startMapId,
        suggestedFixLabel: 'Choisir une map de départ existante.',
      ),
    );
  }

  final startSpawnId = newGame.startSpawnId?.trim();
  if (newGame.enabled && (startSpawnId == null || startSpawnId.isEmpty)) {
    target.add(
      _diagnostic(
        code: 'exportNewGameStartSpawnRequired',
        message: 'Choisissez un point de départ joueur pour Nouvelle Partie.',
        path: 'newGame.startSpawnId',
        domain: NarrativeProjectDiagnosticDomain.map,
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: startMapId.isEmpty ? null : startMapId,
        suggestedFixLabel: 'Choisir un Spawn de rôle playerStart.',
      ),
    );
  }

  final hasInitialParty = newGame.initialParty.isNotEmpty;
  final hasStarterOptions = newGame.starterOptions.isNotEmpty;
  if (newGame.enabled &&
      (hasInitialParty || hasStarterOptions) &&
      !project.pokemon.enabled) {
    target.add(
      _diagnostic(
        code: 'exportPlayablePartyPokemonUnavailable',
        message: 'La création de l’équipe joueur exige le catalogue Pokémon '
            'canonique du projet.',
        path: 'pokemon.enabled',
        suggestedFixLabel: 'Activer et valider les données Pokémon du projet.',
      ),
    );
  }
  if (newGame.enabled && !hasInitialParty && !hasStarterOptions) {
    target.add(
      _diagnostic(
        code: 'exportPlayablePartyUnavailable',
        message: 'Nouvelle Partie ne fournit ni équipe initiale ni choix de '
            'starter : le joueur ne peut pas commencer à jouer.',
        path: 'newGame.initialParty',
        suggestedFixLabel: 'Ajouter une équipe initiale ou un starter.',
      ),
    );
  }
  final starterSceneId = newGame.starterSelectionSceneId?.trim();
  if (newGame.enabled &&
      !hasInitialParty &&
      hasStarterOptions &&
      (starterSceneId == null ||
          starterSceneId.isEmpty ||
          !project.scenes.any((scene) => scene.id == starterSceneId))) {
    target.add(
      _diagnostic(
        code: 'exportStarterSelectionSceneUnavailable',
        message: 'Les starters sont configurés mais aucune Scene de sélection '
            'valide n’est disponible.',
        path: 'newGame.starterSelectionSceneId',
        domain: NarrativeProjectDiagnosticDomain.scene,
        destination: NarrativeProjectDiagnosticDestination.scene,
        sceneId: starterSceneId,
        suggestedFixLabel: 'Choisir une Scene de sélection de starter.',
      ),
    );
  }

  if (!_hasReachableGameEnding(project, runtimeReachability)) {
    target.add(
      _diagnostic(
        code: 'exportStoryEndUnreachable',
        message: 'Aucune conséquence « Terminer le jeu » n’est atteignable '
            'depuis les points d’entrée narratifs du projet.',
        path: 'scenes',
        domain: NarrativeProjectDiagnosticDomain.scene,
        destination: NarrativeProjectDiagnosticDestination.scene,
        suggestedFixLabel:
            'Relier une conséquence Terminer le jeu au parcours principal.',
      ),
    );
  }
}

bool _hasReachableGameEnding(
  ProjectManifest project,
  NarrativeSymbolicReachabilityReport? symbolic,
) {
  if (symbolic == null ||
      symbolic.verdict != NarrativeSymbolicVerdict.pass ||
      symbolic.terminalStates.isEmpty) {
    return false;
  }
  final finishNodes = <String>{
    for (final scene in project.scenes)
      for (final node in scene.graph.nodes)
        if (node.payload
            case SceneActionPayload(
              consequence: SceneFinishGameConsequence(),
            ))
          '${scene.id}\u001f${node.id}',
  };
  if (finishNodes.isEmpty) return false;
  final runtimeStartEventIds = _runtimeStartEventIds(project);
  if (runtimeStartEventIds.isEmpty) return false;
  return symbolic.terminalStates.any(
    (state) {
      final provenance = state.provenance;
      return provenance.any(
            (entry) =>
                finishNodes.contains('${entry.sceneId}\u001f${entry.nodeId}'),
          ) &&
          provenance.any(
            (entry) => runtimeStartEventIds.contains(entry.eventId),
          );
    },
  );
}

Set<String> _runtimeStartEventIds(ProjectManifest project) {
  final startMapId = project.newGame.startMapId.trim();
  if (startMapId.isEmpty) return const <String>{};
  final result = <String>{};
  for (final record
      in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    final definition = record.definitionOrNull;
    if (record.enabledOrNull != true || definition == null) continue;
    final startsOnInitialMap = definition.source.when(
      entityInteract: (mapId, _) => mapId == startMapId,
      triggerEnter: (mapId, _) => mapId == startMapId,
      mapEnter: (mapId) => mapId == startMapId,
      outcomeReceived: (_) => false,
    );
    if (startsOnInitialMap) result.add(definition.id);
  }
  return result;
}

NarrativeSymbolicReachabilityReport? _runtimeEntryReachability({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeProjectValidationReport? narrativeReport,
  required List<NarrativeProjectDiagnostic> target,
}) {
  final starterSceneId = project.newGame.starterSelectionSceneId?.trim();
  if (starterSceneId == null || starterSceneId.isEmpty) {
    return narrativeReport?.symbolicReachability;
  }

  try {
    // The runtime dispatches Event V2 sources, but it does not launch a Scene
    // merely because its id is stored in starterSelectionSceneId. Re-run the
    // symbolic proof without that authoring hint so certification requires an
    // actual runtime-consumable Event source.
    return solveNarrativeSymbolicReachability(
      project.copyWith(
        newGame: _withoutImplicitStarterSceneEntry(project.newGame),
      ),
      maps: maps,
    );
  } on Object catch (error) {
    target.add(
      _diagnostic(
        code: 'exportRuntimeEntryValidationUnavailable',
        message:
            'La route de départ réellement consommée par le runtime n’a pas '
            'pu être validée : $error',
        path: 'eventRegistry',
        suggestedFixLabel:
            'Relier le parcours principal à une source Event V2 valide.',
      ),
    );
    return null;
  }
}

ProjectNewGameConfig _withoutImplicitStarterSceneEntry(
  ProjectNewGameConfig source,
) =>
    ProjectNewGameConfig(
      enabled: source.enabled,
      startMapId: source.startMapId,
      startSpawnId: source.startSpawnId,
      playerName: source.playerName,
      playerAvatarCharacterIds: source.playerAvatarCharacterIds,
      playerPronounSet: source.playerPronounSet,
      startingMoney: source.startingMoney,
      initialBag: source.initialBag,
      initialParty: source.initialParty,
      initialFacts: source.initialFacts,
      initialFactValues: source.initialFactValues,
      existingPartyFactId: source.existingPartyFactId,
      starterSelectionSceneId: null,
      starterOptions: source.starterOptions,
    );

void _appendPokemonValidationDiagnostics({
  required ProjectManifest project,
  required PokemonValidationReport? report,
  required Object? failure,
  required List<NarrativeProjectDiagnostic> target,
}) {
  if (!project.pokemon.enabled) return;
  if (report == null) {
    target.add(
      _diagnostic(
        code: 'exportPokemonValidationUnavailable',
        message: 'Les données Pokémon du projet n’ont pas pu être validées'
            '${failure == null ? '.' : ' : $failure'}',
        path: 'pokemon',
        suggestedFixLabel: 'Réparer puis revalider les données Pokémon.',
      ),
    );
    return;
  }

  for (final issue in report.issues) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'pokemon.${issue.code}',
        severity: switch (issue.severity) {
          PokemonValidationSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          PokemonValidationSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
        },
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message: issue.message,
        path: issue.location,
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: issue.recommendedAction,
      ),
    );
  }
}

Set<String>? _projectedSpeciesIds(RuntimeProjectProjection projection) {
  final directory = projection.project.pokemon.speciesDir.trim();
  if (directory.isEmpty) return null;
  final prefix = '${_projectPayloadPath(directory)}/';
  final ids = <String>{};
  try {
    for (final entry in projection.payloadFiles.entries) {
      if (!entry.key.startsWith(prefix) ||
          !entry.key.toLowerCase().endsWith('.json')) {
        continue;
      }
      final decoded = jsonDecode(utf8.decode(entry.value));
      if (decoded is! Map || decoded['id'] is! String) continue;
      final id = (decoded['id'] as String).trim();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  } on Object {
    return null;
  }
}

Set<String>? _projectedMoveIds(RuntimeProjectProjection projection) {
  final relativePath = projection.project.pokemon.catalogFiles['moves']?.trim();
  if (relativePath == null || relativePath.isEmpty) return null;
  final bytes = projection.payloadFiles[_projectPayloadPath(relativePath)];
  if (bytes == null) return null;
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['entries'] is! List) return null;
    return <String>{
      for (final entry in decoded['entries'] as List)
        if (entry is Map && entry['id'] is String)
          if ((entry['id'] as String).trim().isNotEmpty)
            (entry['id'] as String).trim(),
    };
  } on Object {
    return null;
  }
}

String _projectPayloadPath(String relativePath) {
  final normalized =
      p.posix.normalize(relativePath.trim().replaceAll(r'\', '/'));
  return PackagePathPolicy.normalizeNfc('project/$normalized');
}

NarrativeProjectDiagnostic _diagnostic({
  required String code,
  required String message,
  required String path,
  NarrativeProjectDiagnosticDomain domain =
      NarrativeProjectDiagnosticDomain.runtime,
  NarrativeProjectDiagnosticDestination destination =
      NarrativeProjectDiagnosticDestination.overview,
  String? suggestedFixLabel,
  String? mapId,
  String? sceneId,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: domain,
      message: message,
      path: path,
      destination: destination,
      suggestedFixLabel: suggestedFixLabel,
      mapId: mapId,
      sceneId: sceneId,
    );
